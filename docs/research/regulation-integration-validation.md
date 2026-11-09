# 规程·序列Ⅰ接入与复验

## 集成范围

2026-11-09 将 fork 的 `f07b8965061bbc311ad7aa815879b09264a1e47d` 快进至上游 dev 的 `b1ca5efba9ea1749bcfcd282694c69b94bc89639`，保留完整提交历史。规程组件、数据和测试来自上游；本次额外提供来源审计、复验步骤与本机执行记录，没有另写一套规则或修改 golden 基准。

接入后的测试修正提交为 `54bd1022`。AI 接管测试改为等待将被接管的那个机器人就绪，避免另一队友先就绪造成竞态；指令 UI 测试明确点击冷却按钮以验证拒绝操作，并从本局未禁用干员中选测试目标；目录链接测试在 Windows 使用不要求管理员权限的 junction。没有改变游戏运行逻辑。

新房间默认使用 `act3autochess@V3_1`。已有四个历史版本仍可选；旧记录缺少版本标记时仍按原来的 `act2autochess` 解释。接入包含单人极速和等级 1–20、多人四档、独立五格装备区、盟约选组、策略指令及本期干员、装备、盟约和敌人。

规则来源和待核实事项见 [来源与验收矩阵](regulation-sequence-i.md)。通过本仓库的测试说明实现内部一致、既定场景没有回归，并不证明所有规则与官服逐帧一致。隐藏核心阈值、抽取权重、高等级选组等仍需按矩阵补官服对照证据。

## Linux 训练环境复验

训练目标平台为 Linux。本次使用 Ubuntu（WSL2）、Linux 原生 Node.js v24.13.1 和 Python 3.12.3，在 Linux 文件系统中的副本验收；Windows 的 Node.js v24.13.1 / npm 11.8.0 作为补充结果。原生 Node 安装包校验了官网同版本 `SHASUMS256.txt` 中的 SHA-256。以下命令在 Linux 仓库根目录执行。

全仓检查除 Node 外需要 `python3`、`zip`、`unzip` 等命令行工具；它们用于工具链和打包测试，不是游戏美术。Ubuntu 可通过系统软件包安装这些工具。本次将发行版提供的 zip 包校验后解压到临时验收目录并加入该进程的 PATH，没有改系统安装。

```bash
node --version
python3 --version
npm ci --no-audit --no-fund
node tools/setup.mjs --no-assets --no-local --no-scenes
node --test test/versions-regulation.test.js test/match/bond-groups.test.js test/match/version-equipment.test.js test/bands/regulation-*.test.js test/bonds/regulation.test.js test/garrisons/regulation.test.js test/items/regulation.test.js test/kits/regulation-*.test.js test/sim/regulation-enemies.test.js
npm run ci
npm run golden -- --version act3autochess@V3_1
npm run golden -- --version act3autochess@V3_1 --twice
npm run golden
node --test test/docs-consistency.test.js test/docs-paths.test.js
```

结构化状态/动作训练和纯战斗模拟不需要美术资源，以上流程不下载游戏图片、模型和音频。美术资源仅影响可视化及截图输入的视觉模型路线。本次 Linux 副本复用了 `npm ci` 按锁文件安装的纯 JavaScript 依赖，正式训练机应按上述命令独立安装。

本机 WSL 的原有网络配置导致最小 HTTP 示例也出现 `127.0.0.1 ECONNREFUSED`。复验使用 `unshare -Urn` 临时用户/网络命名空间，先 `ip link set lo up` 再运行 CI，让测试中的 HTTP/WebSocket 服务在自己的回环网络中通信；没有修改全局 WSL 配置。正常 Linux 机器无需此步骤。中断的原 WSL 网络试跑不计为有效验收。

普通规程 golden 命令与仓库中的基准比较；`--twice` 将规程完整场景在同一个进程中计算两遍，第二遍反转场景顺序，检查残留状态及随机性污染。上游工具的 `--twice` 模式只比较这两次结果，不比较存盘基准，所以这两个命令均需执行。最后一条 golden 命令回归默认旧版本。不要为消除失败直接运行 `golden:update`。

## 可选浏览器验收

浏览器指令验收需要 Chrome 和本地美术资源，不是无界面训练的前置条件。本次尝试使用 Windows 已安装的 Chrome，测试会创建和关闭独立的无界面浏览器，不操作用户浏览器资料。

```powershell
$env:SP_E2E = '1'
$env:CHROME_PATH = 'C:/Program Files/Google/Chrome/Application/chrome.exe'
node --test test/ui/regulation-commands.e2e.test.js
Remove-Item Env:SP_E2E
Remove-Item Env:CHROME_PATH
```

此用例在真实本地服务器和规程对局中点击及拖拽策略指令。本次已完成执行、拒绝重复执行及目标选择断言，最终 `problemsOf` 断言因缺少美术、音频、字体资源失败；整个浏览器用例记为未通过，未移除该断言或屏蔽资源错误。按用户确定的无界面训练方向，不继续下载美术资源。

## 执行结果

日志均保存在本次 Windows 工作副本被忽略的 `.cache/verification/` 下，未提交大体积原始日志或游戏素材。

| 检查 | 实际结果 | 日志 |
|---|---|---|
| 规程定向测试（Windows） | 221 通过，0 失败 | `regulation-tests.log` |
| 规程完整 golden（Linux，2 workers） | 256 场景全部匹配，336,523 ms；roster 62、bonds 52、fields 34、matches 14、standins 12、diy 82 | `golden-regulation-linux.log` |
| 规程完整双次确定性（Windows，单进程） | 256 场景各运行两遍，第二遍反序，结果 identical；621,099 + 509,311 ms | `golden-regulation.log` |
| 默认旧版完整 golden（Windows） | 291 场景全部匹配，未更新基准 | `golden-legacy.log` |
| 接入修正和文档定向检查（Windows） | 53 通过，0 失败 | `integration-fixes.log` |
| Linux 全量首轮 | 10,884 项，10,743 通过，4 失败，137 按上游条件跳过，0 取消 | `ci-linux-isolated.log` |
| Linux 性能独立复验 | 2 通过，0 失败；首领战三次 0.1813 / 0.1402 / 0.1596 ms/tick，原阈值 0.5 ms/tick；机器人准备也通过原 300 ms CPU 阈值 | `linux-performance.log` |
| Linux 打包复验 | 补齐 zip 后，2 通过，0 失败 | `linux-package.log` |
| Linux 其余 CI 步骤 | setup、服务冒烟、CI 守卫、lint、导入边界、类型检查全部通过 | `linux-tooling.log` |
| Windows 全量首轮 | 10,884 项，10,689 通过，78 失败，117 跳过；不能称 Windows 全仓通过 | `ci.log` |

Linux 全量首轮的 4 项失败分别为两个打包用例缺少 Linux `zip`，以及两个性能阈值用例（机器人准备 CPU 375.5 ms 超过 300 ms、首领战 1.072 ms/tick 超过 0.5 ms/tick）。这轮与 golden 同机运行，性能结果包含并行负载；按原阈值在长任务结束后独立复测，不放宽断言。Windows 首轮还存在符号链接权限、`python3` 商店占位程序以及测试竞态等问题，不能把这 78 项全部解释成美术缺失。

失败项的独立复验命令如下，保留全部原断言。Linux 全量集合没有缩减；定向命令用于验证首轮失败原因和修复后的结果。

```bash
node --test --test-concurrency=1 --test-name-pattern='cost guard:|performance: heavy' test/match/bot-smarter.test.js test/sim/robustness.test.js
node --test test/package-smoke.test.js
node tools/ci.mjs --only setup,smoke,guards,lint,imports,typecheck
```

4 个失败项独立复验均通过，未修改游戏规则、性能阈值或 golden 基准。全量首轮与定向复验分开记录，不能把首轮描述为一次全绿的 CI。137 个按上游条件跳过的用例（包括未启用的浏览器/资源相关用例）也不计为已通过。当前结论支持将这套规程实现用作 Linux 无界面训练的环境基线；与官服规则的等价性仍按来源矩阵逐项验收。

## 启动与后续官服验收

```bash
node tools/setup.mjs --no-assets --no-local --no-scenes
npm start
```

打开 `http://localhost:3000`，确认大厅的默认版本为规程·序列Ⅰ。需要完整美术资源时使用项目既有 `npm run setup` 流程。

训练前的官服对照按来源矩阵逐项取证，记录模式 ID、初始状态、逐步动作、预期/实际结果及录像或表字段。优先核实会改变策略价值的抽取权重、隐藏核心条件、禁用盟约数、装备溢出，再逐项核实技能结算。每个确认的差异补定向测试、修改构建器或规则实现、说明证据，并重新运行相关用例与两套 golden；预期行为变化才更新基准。
