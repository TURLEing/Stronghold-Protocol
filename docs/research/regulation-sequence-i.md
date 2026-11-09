# 规程·序列Ⅰ实现差分与验收矩阵

审计日期 2026-11-09。fork 起点与上游 master 为 `f07b8965061bbc311ad7aa815879b09264a1e47d`。审计中发现上游 dev 已实现本期，读取的固定提交为 `b1ca5efba9ea1749bcfcd282694c69b94bc89639`。本文对照两个快照，记录规则证据、待核实项及建议验收。本文为资料审计，表中是建议验收用例；实际执行结果另见 [接入与复验记录](regulation-integration-validation.md)。

## 来源和证据等级

- **数据已核实**表示直接读取版本固定的客户端数据镜像字段。来源为 ArknightsAssets/ArknightsGamedata `b1031d1035e8df3042f601e33d5c1dfab8345d59` 的 `cn/gamedata/excel/activity_table.json`，赛季路径 `activity.AUTOCHESS.act3autochess.V3_1`。[固定数据](https://github.com/ArknightsAssets/ArknightsGamedata/blob/b1031d1035e8df3042f601e33d5c1dfab8345d59/cn/gamedata/excel/activity_table.json)
- **维基已核实**表示 PRTS 页面当前修订明确写出，仍应以数据或实机确认细节。主页面 revision `449139`，API 时间 `2026-11-09T08:18:21Z`；盟约记录 revision `449026`。[主页面固定修订](https://prts.wiki/index.php?oldid=449139) · [盟约记录固定修订](https://prts.wiki/index.php?oldid=449026)
- **上游实现**表示 dev 代码或维护者文档已有方案，不自动等于官方事实。`docs/history/0.3.4.md` §37.100–§37.104 列出数据转换、规则及推定。[上游历史](https://github.com/sganggs/Stronghold-Protocol/blob/b1ca5efba9ea1749bcfcd282694c69b94bc89639/docs/history/0.3.4.md)
- **待核实 / [ASSUMED]**表示客户端字段和本次读取的 PRTS 内容尚未确定，不将沿用旧版的值表述为新赛季官方值。

## 上游工作应优先复用

master 未提供本期，但 dev 已有 `act3autochess@V3_1`、`family: regulation`、独立版本数据、地图转换、等级选择、指令系统、装备区、新盟约/技能/敌人及测试。相关提交包括 `aeb68340` 的盟约选组、`4a6fe1d0` 的简报等级名、`e0d5bfc4` 和 `b1ca5efb` 的实现文档。无需在 master 上重做整套支持。应固定 dev 基线、验证其现有测试，再围绕实际缺陷修改。[版本表](https://github.com/sganggs/Stronghold-Protocol/blob/b1ca5efba9ea1749bcfcd282694c69b94bc89639/shared/versions.js) · [版本构建配置](https://github.com/sganggs/Stronghold-Protocol/blob/b1ca5efba9ea1749bcfcd282694c69b94bc89639/tools/versions/act3autochess-v3_1.mjs)

本次 GitHub 开放 PR 列表未看到本期整包 PR，但 dev 提交已存在。因此只查询开放 PR 或 master 会漏掉维护者的进展。上游 #921 是更新第三期的需求，#914 是策略阶段选择自选编组的需求，#916 是加入新干员的需求，均不能作为完整规则定义。[#921](https://github.com/sganggs/Stronghold-Protocol/issues/921) · [#914](https://github.com/sganggs/Stronghold-Protocol/issues/914) · [#916](https://github.com/sganggs/Stronghold-Protocol/issues/916)

## 差分和验收

| 范围 | 核实的本期规则或数据 | master 差分与 dev 状态 | 验收用例 |
|---|---|---|---|
| 数据来源 | 表位于 `AUTOCHESS.act3autochess.V3_1`，共 26 个模式。镜像将一些空数组写为 `{}` | master 读 `AUTOCHESS_SEASON`；dev `sources.mjs` 正规化镜像，profile 固定镜像提交 | 固定输入离线构建逐字节重现；空数组/空对象保持语义；不能静默把旧赛季研究默认值当新赛季实测 |
| 版本身份 | 本期 ID `act3autochess@V3_1`，和旧赛季重复的实体 ID 不保证同一含义 | dev 新增版本并改大厅默认；缺失版本的旧数据仍按 act2 解释 | 新房间显式版本贯穿欢迎、房间、BattleSpec、内容哈希、结果、回放；旧记录加载保持原语义；跨版本知识缓存不混用 |
| 单人模式 | `mode_single_funny` 名称极速模拟、FAST、倍率 1；`mode_single_1..20`；等级20为 ABYSS、倍率1.5 | master 四档难度；dev 用 room.modeId 和 officialModeId | 逐个创建21种单人模式，检查模板、敌人、血量、资金、升级价、回合与名称；等级1/4/5/8/9/12/13/20边界分别覆盖 |
| 多人模式 | `mode_multi_funny/normal/hard/abyss`，仍为四档；另有 LOCAL 教程 `mode_training_2` | dev 按模式解析，不能将多人难度编号当单人规程等级 | 人数1/2/3/4的联防、领袖场和生命合并；教程不混入正式奖励或训练目标 |
| 手牌与部署 | constData 的干员手牌10、装备手牌5、部署上限8、每回合扣血上限10、刷新费1 | dev 开启独立装备行；旧版共用手牌不能直接套用 | 干员10装备0、干员0装备5、双满、合成释放位、卸装备、强制获得、拖拽交换、断线重连，逐项检查类型、容量、库存守恒 |
| 借用与自选 | borrowCount30；storeCntMax6；diyCharLimitForLevels 的5阶和6阶各为2 | #914 的“5/6新增到6位”为用户期望，不能直接采用；策略阶段选组需独立核实 | 限额以字段作用域解释，禁止把借用数当自选槽数；分别验证等级5/6上限、禁用名单、选择后商店实际可见内容 |
| 核心盟约抽选 | dev 引用客户端教学及维护者实机，单人等级1每组4个核心、选择一组；多人10核心灰5。灰核心成员全部排除；附加盟约全部灰才排除干员 | dev §37.104 已实现选组、池子延迟建立、公共/私有状态及回放 | 固定种子重现组别；换组前无商店；选组后共享池、奖励、赠送、自选一致排除；非法编号拒绝；重连保留；多人共同禁用一致 |
| 盟约与名单 | 数据有26个盟约，含乌萨斯、伊比利亚、莱塔尼亚、聚合；PRTS记录其新效果 | dev 按效果ID区分复用的旧盟约，含策略覆盖 | 核对名单和效果ID；策略将效果切回旧版时使用对应安装器；跨版本同ID不会串技能；伤害追加禁止自递归 |
| 指令 | 数据 `skillInfoDataDict` 带 skillType/skillCost/skillAvailType/unlockType/targetType 等，而非纯被动策略 | dev 新增 `g.command`、`g.commandChoice`，公开观察/执行器/训练动作必须覆盖 | 费用不足、未解锁、冷却、错误目标、重复请求、选择阶段失效、重连均有验证；合法时恰好扣一次费且效果一次 |
| 地图与路线 | dev 从官方36×55拼图及5×9/5×17/6×17回合区域重构19×21内部场 | dev layouts.mjs 已实现，地图尺寸说法来自上游转换说明 | 每格核对红蓝门、传送、禁用地形、手牌和装备行；普通/联防/领袖分别做定向路线与部署例；同BattleSpec浏览器/Node结果一致 |
| 新干员与敌人 | PRTS本期名单含奥尔佳、冻河、塔露拉；dev 称37新干员专属技能、新领袖械/茧/鳍/矩兽等已实现 | 单有目录条目不能证明复杂技能保真 | 每名新干员至少正常/精锐技能、模组、控制、退场、召唤物回归；新首领阶段切换、血池、召唤与多场同步检查 |
| 报酬 | constData.itemMaxCount6250；PRTS写关键目标另算，积分按回合和倍率结算 | dev是否完整覆盖奖励流程需另外核对；战斗训练应直接观测真实终局 | 打败领袖和普通失败分别核算；模式倍率隔离；训练reward不把奖励货币估值冒充生存或胜利 |

以上数值均可回溯至固定数据、PRTS修订或明确标记的上游实现。模式表可用 `modeDataDict` 遍历检查，不硬编码仅四个难度。[客户端数据](https://github.com/ArknightsAssets/ArknightsGamedata/blob/b1031d1035e8df3042f601e33d5c1dfab8345d59/cn/gamedata/excel/activity_table.json) · [上游实现说明](https://github.com/sganggs/Stronghold-Protocol/blob/b1ca5efba9ea1749bcfcd282694c69b94bc89639/docs/history/0.3.4.md)

## 仍需证据的规则

| 未定项 | dev 当前处理 | 对训练的影响 | 获取证据与验收 |
|---|---|---|---|
| 隐秘核心门槛 | 单人350、多人1200沿用盟约，明确 [ASSUMED] | 终局奖励和堆层策略可能学错 | 实机控制层数，在门槛左右与生命边界复现；找到本期客户端条件字段后替换 |
| 商店库存、抽取与悬赏权重 | 不套旧版实测表，profile tables四项为null；上游说明均匀抽取为推定 | 采购概率、刷新价值及跨局策略偏差 | 区分候选条目权重、剩余副本权重、库存初值；固定模式多次采样，与实机/解包字段对照 |
| 附加盟约禁用数量 | FUNNY/FAST禁1，NORMAL/HARD/ABYSS禁4，教程0，沿用旧版推定 | 可用卡池和策略概率不同 | 对每个模式/规程等级记录开局灰名单，覆盖静态不开放与随机禁用的区分 |
| 高级单人选组与奇数边界 | 等级5–20采用5+5，奇数多余常亮，未选择取第一组 | 开局策略与断线默认行为 | 官服等级5、20及可用数变化的回放；默认选择应明确记录来源 |
| 装备区溢出 | 强制获得放暂存、空位移入、备战结束清理，维护者推定 | 装备获取、丢失与售卖优化容易利用偏差 | 五装备满位获得第六件、卸装、合成、结束回合，观察暂存顺序与清理/返库/销毁效果 |
| 战场名字 | 暂写战场#NN(规程) | 对策略影响低，但名称映射可能误导实机桥 | 直接读取本期场景或wiki地图名，地图ID作为稳定主键 |
| 单项技能时序 | 各代码仍有ASSUMED | 模型可能利用复刻缺陷 | 建立单技能定向例，重点测伤害追加链、召唤、目标优先级、控制时间、退场返回、层数结算 |

这些项是校验队列。上游已明确记录其不确定性，合入时应保留注释和可配置来源，不以运行无异常替代规则准确性。[上游构建配置](https://github.com/sganggs/Stronghold-Protocol/blob/b1ca5efba9ea1749bcfcd282694c69b94bc89639/tools/versions/act3autochess-v3_1.mjs) · [§37.100–§37.104](https://github.com/sganggs/Stronghold-Protocol/blob/b1ca5efba9ea1749bcfcd282694c69b94bc89639/docs/history/0.3.4.md)

## 进入训练前的最小门槛

建议先跑已有 `test/versions-regulation.test.js`、`test/match/bond-groups.test.js` 及指令/装备相关用例，确认单人极速、等级1/5/12/20与多人四档均能无界面完成。同一版本和种子应重现结果；相同动作应走真人的规则校验。策略观察须包含装备区、选组、指令费用/解锁/冷却/目标以及精确modeId，动作也要支持这些决策。随后记录非法动作、异常、回退和吞吐，使用未训练种子评价。旧四版本的golden、数据重建和默认记录语义应一并回归。具体测试执行与结果由实施任务记录，此文仅给出验收标准。
