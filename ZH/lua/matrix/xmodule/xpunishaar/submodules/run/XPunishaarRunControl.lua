--- 局内流程状态机：统一管理局内节点推进与 UI 面板生命周期。
--- 职责：EnterRun 单一入口 → _PrepareBattleData 翻译服务端数据 → TransitionTo 驱动面板切换 → 监听 BattleEnded 触发结算。
--- 不持有战斗引擎引用；战斗由 XPunishaarControl 的 FightControl 子控制器执行，通过 XPunishaarControl 的事件转发解耦。
---@class XPunishaarRunControl : XControl
---@field _MainControl XPunishaarGameControl
---@field private _Model XPunishaarModel
---@field private _CurrentFightState number|nil 当前 FightState（nil = 尚未进入任何面板）
---@field private _CurrentPanelName string|nil 当前打开的面板名（nil = 无面板）
local XPunishaarRunControl = XClass(XControl, "XPunishaarRunControl")

--- 局内流程事件（RunControl 派发 → FightMain 等常驻面板订阅；与局内 FightControl.EventIds、
--- 局外 ShopEventId/DragEventId 分开）。
XPunishaarRunControl.RunEventId = {
    -- FightMain 子态切换：payload = fightState（FightState 枚举）。
    -- 局内循环节点推进时，FightMain 已在栈中，靠此事件复用实例刷新子面板，避免重开界面。
    FightStateChanged = "PunishaarRunFightStateChanged",
}

-- 枚举访问统一走 XMVCA.XPunishaar.EnumConst（禁局部变量接收，见工程约定）

-- BattleResult 枚举定义在 FightControl 类对象上（XPunishaarFightControl.BattleResult），此处引用其常量替代魔法数
local XPunishaarFightControl = require("XModule/XPunishaar/SubModules/InGame/XPunishaarFightControl")
local BattleResult = XPunishaarFightControl.BattleResult

--- ╔══════════════════════════════════════════════════════════════════╗
--- ║  服务端节点类型 → 进入该节点时的初始 FightState                 ║
--- ║  联调时只需改此表；UI FightState 枚举本身保持不变               ║
--- ╚══════════════════════════════════════════════════════════════════╝
local ServerNodeToFightState = {
    [XMVCA.XPunishaar.EnumConst.NodeType.Shop] = XMVCA.XPunishaar.EnumConst.FightState.Shopping,
    [XMVCA.XPunishaar.EnumConst.NodeType.Fight] = XMVCA.XPunishaar.EnumConst.FightState.PreFight, -- 战斗节点先进战前准备
    [XMVCA.XPunishaar.EnumConst.NodeType.ChoiceFight] = XMVCA.XPunishaar.EnumConst.FightState.PreFight, -- 选择战斗暂定同路径
    -- [XMVCA.XPunishaar.EnumConst.NodeType.Event]    → 独立面板，不走 FightMain，TODO
    -- [XMVCA.XPunishaar.EnumConst.NodeType.Story]    → 独立面板，不走 FightMain，TODO
}

--- FightState → 是否在 TransitionTo 前准备战斗契约数据
--- PreFight 进入时不准备：ChoiceFight 节点此时 SelectedFightId=0；
--- 数据统一在玩家点击"开始战斗"（OnPlayerStartFight）时准备。
local FightStateNeedsBattleData = {
    [XMVCA.XPunishaar.EnumConst.FightState.Fighting] = true,
}

-- 面板过渡策略
local Strategy = {
    OpenRemove = "OpenRemove",
    PopThenOpen = "PopThenOpen",
    CloseOpen = "CloseOpen",
}

--- FightState → 目标面板信息（panel 名 + 过渡策略；substate 直接用 FightState 值透传）
local FightStateToPanelInfo = {
    [XMVCA.XPunishaar.EnumConst.FightState.Base] = { panel = "UiPunishaarFightMain", strategy = Strategy.OpenRemove },
    [XMVCA.XPunishaar.EnumConst.FightState.Shopping] = { panel = "UiPunishaarFightMain", strategy = Strategy.OpenRemove },
    [XMVCA.XPunishaar.EnumConst.FightState.PreFight] = { panel = "UiPunishaarFightMain", strategy = Strategy.OpenRemove },
    [XMVCA.XPunishaar.EnumConst.FightState.Fighting] = { panel = "UiPunishaarFightMain", strategy = Strategy.OpenRemove },
    -- TODO: Event / Story → 独立面板接入后在此补充
}

function XPunishaarRunControl:OnInit()
    self._CurrentFightState = nil
    self._CurrentPanelName = nil
    self._IsTestMode = false  -- 测试工具路径标记：OnBattleEnded 据此走测试结算，不调服务端 FinishFight
    self._PendingRouteNode = nil  -- #OpenAfterAnim
end

function XPunishaarRunControl:OnRelease()
    self._CurrentFightState = nil
    self._CurrentPanelName = nil
    self._IsTestMode = false
    self._PendingRouteNode = nil  -- #OpenAfterAnim
end

--region ----------public start----------

--- 进入一局（外部唯一入口，接收 StartStage 响应的 Server.XPunishaarStage 数据）。
--- 流程：读取 Model 中已存 Stage → 翻译开战契约 → 按首节点类型切换面板。
--- 注意：Stage 数据已由 NetworkAgency:DoStartStage 存入 Model，本函数不缓存原始数据。
---@param gameData table Server.XPunishaarStage（与 Model 中相同引用，仅供首次调用路径 fallback）
function XPunishaarRunControl:EnterRun(gameData)
    local stage = self._Model:GetCurrentStage()
    if not stage then
        XLog.Error("[PunishaarRun] EnterRun: Model 中无当前 Stage 数据，gameData 为 fallback 路径")
        stage = gameData
    end
    local node = stage and stage.CurrentNode
    if not node then
        XLog.Error("[PunishaarRun] EnterRun: Stage 无 CurrentNode")
        return
    end
    -- #66 先开 FightMain 到 Base 态作 UI 基底（常驻背景，杜绝 NormalPop 透明部分露选关）。
    -- #OpenAfterAnim：不再用 OpenWithCallback onReady 路由（onReady 在 await InitAsync 含 AnimEnable 动画完成后
    --   才触发，致 FightMain 已显 Base 却等入场动画 ~2秒才切目标态）。改缓存待路由节点，由 FightMain OnEnable
    --   就绪后主动调 OnFightMainReady→_RouteNode：同面板子态切换走 DispatchEvent sync 不经操作队列立即切消 2 秒；
    --   新独立面板分支 OpenWithCallback 受 OperatingMask(operating=true) 自动排队等动画，无冲突。框架天然分流。
    self._PendingRouteNode = node
    self:TransitionTo(XMVCA.XPunishaar.EnumConst.FightState.Base)
end

--- FightMain OnEnable 就绪后主动触发节点路由（替代 OpenWithCallback onReady）。#OpenAfterAnim
--- 仅首次进入（EnterRun 设 _PendingRouteNode）触发；局内推进（AdvanceNode 直接 _RouteNode，FightMain 已在栈）不经此。
--- 去重：消费即清 _PendingRouteNode，压栈恢复二次 OnEnable 时 nil return 不重复路由。
function XPunishaarRunControl:OnFightMainReady()
    local node = self._PendingRouteNode
    if not node then
        return
    end
    self._PendingRouteNode = nil
    self:_RouteNode(node)
end

--- 推进到下一节点（ExitNode 回调落 Model 后调用）。
--- 与 EnterRun 逻辑对称：读 Model 新 CurrentNode → 查映射 → TransitionTo。
function XPunishaarRunControl:AdvanceNode()
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.CurrentNode then
        XLog.Error("[PunishaarRun] AdvanceNode: Model 中无 Stage 或 CurrentNode 数据")
        return
    end
    -- 节点推进选 HUD + 缓存（切态前选，FightMain SwitchToState 显时读 GetDisplayHud 显，规则3a）#86
    self._GameControl:OnHudNodeAdvance()
    self:_RouteNode(stage.CurrentNode)
end

--- RunControl 唯一的面板切换入口（初次进入与局内节点切换共用）。
---@param fightState number FightState 枚举值
---@param onReady function|nil 面板就绪回调 onReady(reused)：首次 Open 走异步、加载完成后触发 onReady(false)；
---   局内刷态同步、立即触发 onReady(true)。reused 告知目标面板是复用（未压栈）还是新开（已压栈），
---   供调用方决定关闭覆盖弹窗用 Close（栈顶）还是 Remove（非栈顶）。
function XPunishaarRunControl:TransitionTo(fightState, onReady)
    local info = FightStateToPanelInfo[fightState]
    if not info then
        XLog.Error("[PunishaarRun] TransitionTo: 无面板映射，fightState=" .. tostring(fightState))
        return
    end
    -- 状态字段必须在 _ExecuteTransition 之前更新：_ExecuteTransition 内部（同面板 DispatchEvent、
    -- 首次异步 Open 完成回调、onReady 里的 Close 弹栈）都可能触发 FightMain 的 OnEnable 去读
    -- GetCurrentFightState() 主动同步子态——那一刻字段必须已是新目标态，否则会同步到旧态。
    -- fromPanel 用局部快照传入，_ExecuteTransition 据它判断同面板/跨面板与清理旧面板，不受字段前移影响。
    local fromPanel = self._CurrentPanelName
    self._CurrentFightState = fightState
    self._CurrentPanelName = info.panel
    self:_ExecuteTransition(fromPanel, info.panel, fightState, info.strategy, onReady)
end

--- 当前 FightState（供 FightMain 在 OnEnable 主动同步子面板到正确状态）。
--- nil = 尚未进入任何面板（异常兜底：调用方读到 nil 应跳过切态）。
---@return number|nil FightState 枚举
function XPunishaarRunControl:GetCurrentFightState()
    return self._CurrentFightState
end

--- 玩家在战前准备界面点击"开始战斗"后由 Control.EnterFight 回调触发。
--- 准备战斗契约数据（此时 SelectedFightId 已确定），然后切换到战中状态。
function XPunishaarRunControl:OnPlayerStartFight()
    self:_PrepareBattleData()
    self:TransitionTo(XMVCA.XPunishaar.EnumConst.FightState.Fighting)
end

--- 结束当前局，移除 FightMain 并重置局内状态。
--- 收到 settleInfo 时由 Control 调用，确保 FightMain 在结算界面打开前已关闭。
function XPunishaarRunControl:ExitRun()
    if self._CurrentPanelName then
        XLuaUiManager.Remove(self._CurrentPanelName)
        self._CurrentPanelName = nil
    end
    self._CurrentFightState = nil
    self._PendingRouteNode = nil  -- 清待路由节点（防跨局残留）#OpenAfterAnim
end

--- 战斗结束回调（由 XPunishaarControl 监听 FightControl.BattleEnded 事件后转发）。
---@param result number BattleResult 枚举（Win=1 / Lose=2）
---@param loseMaxColor number 战败时信号球最多颜色（XPunishaarSignalBallColor，胜利传0）
function XPunishaarRunControl:OnBattleEnded(result, loseMaxColor)
    local isWin = result == BattleResult.Win
    -- 测试工具路径（_IsTestMode 或无 FightState）：无服务端 session，直接打开结算界面，不调 FinishFight
    -- 仅 Editor 环境走测试豁免（非 Editor 静默跳过，走正常 FinishFight——可能是 bug 误入此分支）
    if (self._IsTestMode or not self._CurrentFightState) and XMain.IsWindowsEditor then
        XLuaUiManager.Open("UiPunishaarBattleSettlement", isWin, nil, function()
            -- 测试模式：确认即退出整个战斗界面（FightMain），GameControl 留存供下次 debug 复用
            XLuaUiManager.Close("UiPunishaarFightMain")
        end)
        return
    end
    -- 正式路径：采集战斗埋点统计后通知主 Control 上报结果，后续状态切换由 FinishFight 回调驱动
    -- _MainControl 为 GameControl（含 lazy 建的 FightControl 字段）；FightControl 战斗刚结束仍存活，防御性 nil 守卫
    local stats = nil
    local fightControl = self._MainControl.FightControl
    if fightControl then
        stats = fightControl:CollectBattleStats()
    end
    self._MainControl:FinishFight(isWin, loseMaxColor, stats)
end

--endregion ----------public end----------

--region ----------private start----------

--- 节点路由核心：EnterRun / AdvanceNode 的共同出口。
--- Shop+WaitSelectShop 先弹选择框，选完再过渡到 Shopping；其余节点直接按类型映射跳 FightMain。
--- #66 二选一/Event/Story/ChoiceFight(未选) 节点前插 TransitionTo(Base)：把 FightMain 切到基底态
---   （显背包编排 + 隐上一态内容），NormalPop 叠其上透明部分露场景背景不穿帮。Fight/ChoiceFight(已选) 仍切对应子态。
---@param node table Server.XPunishaarNode
function XPunishaarRunControl:_RouteNode(node)
    local FightState = XMVCA.XPunishaar.EnumConst.FightState

    -- 状态滞留兜底：当前节点已 Finished（闪退/断线重连致服务端回包 CurrentNode 仍 Finished）→
    -- 切基底态 + 推进节点，不落默认映射进 PreFight（战斗节点 Finished 进战前面板无有效 FightId 会卡死）。
    -- 与 Event else / AutoPassthroughStory 范式一致（Finished 即应 ExitNode），统一在此收口补 Fight/ChoiceFight 缺口。#状态滞留推进
    if node.Status == XMVCA.XPunishaar.EnumConst.NodeStatus.Finished then
        self:TransitionTo(FightState.Base)
        self._MainControl:ExitNode()
        return
    end

    -- Shop 节点且尚未选定商店 → 先切 Base 再弹二选一，选完再开 FightMain Shopping 态
    if node.Type == XMVCA.XPunishaar.EnumConst.NodeType.Shop and node.Status == XMVCA.XPunishaar.EnumConst.NodeStatus.WaitSelectShop then
        self:TransitionTo(FightState.Base)
        self:_OpenShopSelection(node)
        return
    end

    -- 事件节点：按 Status 分流——WaitSelect 弹二选一；Processing 开内容+奖励面板；异常 fallback 透传。
    if node.Type == XMVCA.XPunishaar.EnumConst.NodeType.Event then
        local status = node.Status
        if status == XMVCA.XPunishaar.EnumConst.NodeStatus.WaitSelect then
            self:TransitionTo(FightState.Base)
            self:_OpenEventSelection(node)
        elseif status == XMVCA.XPunishaar.EnumConst.NodeStatus.Processing then
            self:TransitionTo(FightState.Base)
            XLuaUiManager.Open("UiPunishaarEventSettlement", node)
        else
            -- RewardReplace/Finished 等异常态：fallback 自动透传
            self:TransitionTo(FightState.Base)
            self._MainControl:AutoPassthroughEvent(node)
        end
        return
    end

    -- 剧情节点(AvgNode)：进入即 Processing、不经 Finished（服务端语义），当前无 AVG 面板。
    -- TODO: 临时透传逃生，正式方案需接入 AVG 剧情播放面板后再推进节点。
    if node.Type == XMVCA.XPunishaar.EnumConst.NodeType.Story then
        self:TransitionTo(FightState.Base)
        self._MainControl:AutoPassthroughStory(node)
        return
    end

    -- 选择战斗节点(ChoiceFight)且尚未选定战斗：弹通用二选一让玩家从 RandomFightIds 挑选一场。
    -- 候选不足 2 时 fallback 自动选首个（见 _OpenChoiceFightSelection）。
    if node.Type == XMVCA.XPunishaar.EnumConst.NodeType.ChoiceFight and node.Status == XMVCA.XPunishaar.EnumConst.NodeStatus.WaitSelect then
        self:TransitionTo(FightState.Base)
        self:_OpenChoiceFightSelection(node)
        return
    end

    -- 战斗节点(Fight/ChoiceFight) + 补强状态 → 补强商店（Shopping 态复用商店 UI，读 node.ShopInfo）。
    -- 与局内 FinishFight 的 Remedy 分支一致；外部进关卡（EnterRun）也走此路径，避免误进 PreFight。
    -- ChoiceFight 对齐 Fight（#81）：选择战斗节点失败补强同走补强商店，原仅判 Fight 致 ChoiceFight+Remedy fall through 到 PreFight。
    if (node.Type == XMVCA.XPunishaar.EnumConst.NodeType.Fight
            or node.Type == XMVCA.XPunishaar.EnumConst.NodeType.ChoiceFight)
            and node.Status == XMVCA.XPunishaar.EnumConst.NodeStatus.Remedy then
        self:TransitionTo(FightState.Shopping)
        return
    end

    local fightState = ServerNodeToFightState[node.Type]
    if not fightState then
        XLog.Warning("[PunishaarRun] _RouteNode: 节点类型暂未实现，type=" .. tostring(node.Type))
        return
    end
    if FightStateNeedsBattleData[fightState] then
        self:_PrepareBattleData()
    end
    self:TransitionTo(fightState)
end

--- Shop WaitSelectShop 专属：直接弹出商店二选一，选定后触发 SelectShop RPC，
--- 成功后 TransitionTo(Shopping) 让 FightMain 进入商店态。FightMain 此时节点已是 Processing。
--- 关闭时机：#66 FightMain 已作基底常驻（_RouteNode 进 Base 态，FightMain 已开），切 Shopping 是同面板 sync，
---   选定后同步 TransitionTo(Shopping) + Close 二选一——关后底即 FightMain(Shopping)，不再需要 onReady 先盖后关。
---@param node table Server.XPunishaarNode
function XPunishaarRunControl:_OpenShopSelection(node)
    local candidateIds = node.ShopInfo and node.ShopInfo.CandidateShopIds
    if not candidateIds or #candidateIds < 1 then
        XLog.Error("[PunishaarRun] _OpenShopSelection: CandidateShopIds 为空，fallback 直接进商店")
        self:TransitionTo(XMVCA.XPunishaar.EnumConst.FightState.Shopping)
        return
    end

    -- 只取前 2 个候选（二选一界面最多 2 选项 #49）
    local optionCount = math.min(2, #candidateIds)
    local options = {}
    for i = 1, optionCount do
        local cfg = self._MainControl:GetTablePunishaarShop(candidateIds[i])
        options[i] = { Name = cfg and cfg.Name or "", Desc = cfg and cfg.Desc or "" }
    end

    XLuaUiManager.Open("UiPunishaarEventSelection", nil, options, function(selectedIndex)
        self._MainControl:SelectShop(candidateIds[selectedIndex], function(success)
            if not success then
                return
            end
            -- #66 FightMain 已作基底常驻（_RouteNode 进 Base 态），切 Shopping 是同面板 sync，
            -- 二选一关后底即 FightMain(Shopping)，不再需要 onReady 先盖后关（底已是正确基底非选关）。
            self:TransitionTo(XMVCA.XPunishaar.EnumConst.FightState.Shopping)
            XLuaUiManager.Close("UiPunishaarEventSelection")
        end)
    end)
end

--- Event WaitSelect 专属：弹通用二选一让玩家从 RandomEventIds 中选一个候选事件，
--- 选定后 SelectEvent(EventGroup.Id) → 节点进 Processing → 开 UiPunishaarEventSettlement。
--- 选项文案：RandomEventIds[i] → EventGroup.EventId → PunishaarEventContent.Name + LocationDescUnselect。
--- 关闭时机：#66 FightMain 已作基底常驻（_RouteNode 进 Base 态），选定后同步 Close 二选一 + Open EventSettlement，
---   加载期底为 FightMain(Base) 场景不穿帮，不再需要 OpenWithCallback 先盖后关。
--- TODO: 通用二选一面板固定 2 按钮，候选 >2 暂只显示前 2 项（与商店/选择战斗一致）。
---@param node table Server.XPunishaarNode
function XPunishaarRunControl:_OpenEventSelection(node)
    local candidateIds = node.EventInfo and node.EventInfo.RandomEventIds
    if not candidateIds or #candidateIds < 1 then
        XLog.Error("[PunishaarRun] _OpenEventSelection: RandomEventIds 为空，fallback 自动透传")
        self._MainControl:AutoPassthroughEvent(node)
        return
    end

    local optionCount = math.min(2, #candidateIds)
    local options = {}
    for i = 1, optionCount do
        local groupCfg = self._MainControl:GetTablePunishaarEventGroup(candidateIds[i])
        local name = ""
        local desc = ""
        if groupCfg and XTool.IsNumberValid(groupCfg.EventId) then
            local contentCfg = self._MainControl:GetTablePunishaarEventContent(groupCfg.EventId)
            if contentCfg then
                name = contentCfg.Name or ""
                desc = contentCfg.LocationDescUnselect or ""
            end
        end
        options[i] = { Name = name, Desc = desc }
    end

    -- TODO: title 文案待 ClientConfig 配置（PanelTitle/EventSelectionTitle），暂传 nil 用默认空串
    XLuaUiManager.Open("UiPunishaarEventSelection", nil, options, function(selectedIndex)
        local chosenId = candidateIds[selectedIndex]
        if not chosenId then
            XLog.Error("[PunishaarRun] _OpenEventSelection: 选中索引越界，selectedIndex=" .. tostring(selectedIndex))
            return
        end
        self._MainControl:SelectEvent(chosenId, function(success)
            if not success then
                return
            end
            -- 节点已进 Processing；读 Model 更新后的当前节点开 EventSettlement。
            -- #66 FightMain 已作基底常驻（_RouteNode 进 Base 态），二选一关后底即 FightMain(Base) 场景，
            -- 不再需要 OpenWithCallback 先盖后关——同步 Close 二选一 + Open EventSettlement，加载期底为 FightMain(Base) 不穿帮。
            local stage = self._Model:GetCurrentStage()
            local updatedNode = stage and stage.CurrentNode
            if not updatedNode then
                XLog.Error("[PunishaarRun] _OpenEventSelection: SelectEvent 后 Model 无 CurrentNode")
                return
            end
            XLuaUiManager.Close("UiPunishaarEventSelection")
            XLuaUiManager.Open("UiPunishaarEventSettlement", updatedNode)
        end)
    end)
end

--- ChoiceFight WaitSelect 专属：弹通用二选一让玩家从 RandomFightIds 中挑选一场战斗，
--- 选定后 SelectFight → 进战前准备。Name 取候选战斗对应敌人名（Fight.EnemyId→Enemy.EnemyName），
--- Desc 暂留空（Fight/Enemy 表无描述字段）。
--- 候选规则与 _OpenShopSelection 一致：≥1 即显示选择（候选=1 显单选项），仅候选为空时 fallback 自动选首个。
--- 关闭时机：#66 FightMain 基底常驻，切 PreFight 同面板 sync + 同步 Close 二选一，不再需要 onReady 先盖后关。
--- TODO: 通用二选一面板固定 2 按钮，若 FightRandomAmount>2 暂只显示前 2 项（与商店一致），面板支持 N 选项后再补。
---@param node table Server.XPunishaarNode
function XPunishaarRunControl:_OpenChoiceFightSelection(node)
    local candidateIds = node.FightInfo and node.FightInfo.RandomFightIds
    if not candidateIds or #candidateIds < 1 then
        XLog.Error("[PunishaarRun] _OpenChoiceFightSelection: RandomFightIds 为空，fallback 自动选首个")
        self:_AutoSelectFirstChoiceFight(node)
        return
    end

    -- 只取前 2 个候选（二选一界面最多 2 选项，与 _OpenShopSelection 一致；候选=1 显单选项）
    local optionCount = math.min(2, #candidateIds)
    local options = {}
    for i = 1, optionCount do
        local fightId = candidateIds[i]
        options[i] = { Name = self:_GetEnemyNameByFightId(fightId), Desc = self:_GetFightDescByFightId(fightId) }
    end

    XLuaUiManager.Open("UiPunishaarEventSelection", nil, options, function(selectedIndex)
        self._MainControl:SelectFight(candidateIds[selectedIndex], function(success)
            if not success then
                return
            end
            -- #66 FightMain 基底常驻，切 PreFight 同面板 sync + 同步关二选一（底即 FightMain(PreFight) 不穿帮）。
            self:TransitionTo(XMVCA.XPunishaar.EnumConst.FightState.PreFight)
            XLuaUiManager.Close("UiPunishaarEventSelection")
        end)
    end)
end

--- 【#61 链式】调起主卡合成升级副卡保留选择弹窗（表现层 UiPunishaarMainCardLevelupTip）。
--- 逻辑层↔表现层接缝：BuyGoods 预判升级（含链式）且涉及 ≥2 张副卡时经此入口异步调起 UI，
--- UI 通过 onConfirm(chosenSubCardId) 回传玩家选定的保留副卡、onCancel 回传取消。
--- 参照 _OpenChoiceFightSelection 的 XLuaUiManager.Open 转发模式（不挂 ControlShop，跨 Panel 编排归 RunControl）。
---@param subCardIds number[] 涉及的全部副卡模板 Id 列表（≥2，UI 列出让玩家选保留 1 张）
---@param nextLevelCardId number 升级后新卡 TemplateId（同卡升级，= goods.CardId）
---@param displayLevel number 升级后最终等级（链式合成=最终级，单合=商品级+1）
---@param onConfirm function(chosenSubCardId: number) 玩家选定保留副卡回调
---@param onCancel function() 玩家取消回调
function XPunishaarRunControl:OpenMainCardLevelupTip(subCardIds, nextLevelCardId, displayLevel, onConfirm, onCancel)
    XLuaUiManager.Open("UiPunishaarMainCardLevelupTip", subCardIds, nextLevelCardId, displayLevel, onConfirm, onCancel)
end

--- 由战斗流水 Id 取敌人名：fightId → PunishaarFight.EnemyId → PunishaarEnemy.EnemyName。
--- 任一环节缺失返回空串（Name 有数据才显示，无数据留空）。
---@param fightId number
---@return string
function XPunishaarRunControl:_GetEnemyNameByFightId(fightId)
    if not fightId or fightId == 0 then
        return ""
    end
    -- Fight/Enemy 已归 GameControl（即时父），单跳借用
    local fightCfg = self._MainControl:GetTablePunishaarFight(fightId, true)
    if not fightCfg or not fightCfg.EnemyId or fightCfg.EnemyId == 0 then
        return ""
    end
    local enemyCfg = self._MainControl:GetTablePunishaarEnemy(fightCfg.EnemyId, true)
    return (enemyCfg and enemyCfg.EnemyName) or ""
end

function XPunishaarRunControl:_GetFightDescByFightId(fightId)
    if not fightId or fightId == 0 then
        return ""
    end
    -- Fight/Enemy 已归 GameControl（即时父），单跳借用
    ---@type XTablePunishaarFight
    local fightCfg = self._MainControl:GetTablePunishaarFight(fightId, true)
    
    if not fightCfg or XTool.IsTableEmpty(fightCfg.EnemySkill) then
        return ""
    end
    
    local descList = {}

    for i, enemySkillId in ipairs(fightCfg.EnemySkill) do
        local enemySkillCfg = self._MainControl:GetTablePunishaarEnemySkill(enemySkillId)

        if enemySkillCfg and not string.IsNilOrEmpty(enemySkillCfg.SkillDesc) then
            table.insert(descList, enemySkillCfg.SkillDesc)
        end
    end
    
    local desc = XUiHelper.FormatTextEx(fightCfg.EventDescFormat, table.unpack(descList))
    
    return desc
end

--- 【fallback】选择战斗节点 WaitSelect 候选不足 2 时：默认选中第一个候选战斗，成功后进战前准备。
--- ChoiceFight 进入时 SelectedFightId=0，若不先选定，PreFight 界面"开始战斗"无有效 FightId 会卡死。
---@param node table Server.XPunishaarNode
function XPunishaarRunControl:_AutoSelectFirstChoiceFight(node)
    local candidateIds = node.FightInfo and node.FightInfo.RandomFightIds
    local firstFightId = candidateIds and candidateIds[1]
    if not firstFightId or firstFightId == 0 then
        XLog.Error("[PunishaarRun] _AutoSelectFirstChoiceFight: 无有效候选战斗 Id，NodeType=" .. tostring(node.Type))
        return
    end

    self._MainControl:SelectFight(firstFightId, function(success)
        if not success then
            XLog.Error("[PunishaarRun] _AutoSelectFirstChoiceFight: SelectFight 失败，fightId=" .. tostring(firstFightId))
            return
        end
        self:TransitionTo(XMVCA.XPunishaar.EnumConst.FightState.PreFight)
    end)
end

--- 面板过渡执行器：面板过渡(Open/Remove/Pop)的统一执行器。
--- 注意：仅收口"过渡语义"的面板切换；弹窗(_OpenShopSelection 的 Open)、单点移除(ExitRun 的 Remove)、
--- 结算界面打开(OnBattleEnded 的 Open)等非过渡语义的 XLuaUiManager 调用不经此处。
---@param fromPanel string|nil 当前面板名（nil = 初次进入）
---@param toPanel string 目标面板名
---@param toSubstate number|nil 透传给 Open/PopThenOpen 的参数
---@param strategy string Strategy 枚举值
---@param onReady function|nil 面板就绪回调 onReady(reused)：reused=true 表示复用现有面板（同面板刷态，
---   未压栈，目标面板仍在原栈位、其上弹窗仍是栈顶）；reused=false 表示新开面板已压栈（目标面板成为
---   新栈顶，其下旧弹窗已非栈顶）。调用方据此决定关闭覆盖弹窗用 Close（栈顶）还是 Remove（非栈顶）。
function XPunishaarRunControl:_ExecuteTransition(fromPanel, toPanel, toSubstate, strategy, onReady)
    -- 同面板子状态切换：FightMain 已在栈中，复用实例、派发事件刷新子面板，不碰 UI 栈（同步，避 PopThenOpen 弹栈重开在栈顶有弹窗时重复开出 FightMain）。
    if fromPanel == toPanel then
        self:DispatchEvent(self.RunEventId.FightStateChanged, toSubstate)
        if onReady then
            onReady(true)
        end
        return
    end

    -- 跨面板：目标面板此前未打开（当前仅首次进入 fromPanel=nil 这一路径），Open 可能异步加载，
    -- 须用 OpenWithCallback 等加载完成后再清理旧面板并触发 onReady，避免调用方在面板显示前
    -- 过早操作（如关闭覆盖其上的弹窗）露出底层界面。
    local onOpened = function()
        if fromPanel then
            if strategy == Strategy.CloseOpen then
                XLuaUiManager.Close(fromPanel)
            else
                XLuaUiManager.Remove(fromPanel)  -- OpenRemove / 兜底
            end
        end
        if onReady then
            onReady(false)
        end
    end

    if strategy == Strategy.PopThenOpen and fromPanel then
        -- 当前不可达（同面板已被上方拦截）；保留给将来独立面板接入
        XLuaUiManager.PopThenOpen(toPanel, toSubstate)
        if onReady then
            onReady(false)
        end
    else
        XLuaUiManager.OpenWithCallback(toPanel, onOpened, toSubstate)
    end
end

--- 从 Model 读取 Stage 数据翻译开战契约，填充 Model._BattleInitData。
--- 调用时机：EnterRun 确认为战斗节点后，TransitionTo 之前。
function XPunishaarRunControl:_PrepareBattleData()
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.CurrentNode then
        XLog.Error("[PunishaarRun] _PrepareBattleData: Model 中 Stage 数据异常")
        return
    end

    local node = stage.CurrentNode
    local fightInfo = node.FightInfo
    if not fightInfo then
        XLog.Error("[PunishaarRun] _PrepareBattleData: FightInfo 为空，NodeType=" .. tostring(node.Type))
        return
    end

    -- fightId：优先取已选定的，否则取第一候选（普通战斗节点只随机1个）
    local fightId = fightInfo.SelectedFightId
    if not fightId or fightId == 0 then
        fightId = fightInfo.RandomFightIds and fightInfo.RandomFightIds[1]
    end
    if not fightId or fightId == 0 then
        XLog.Error("[PunishaarRun] _PrepareBattleData: 无有效 FightId")
        return
    end

    local data = self._Model:ResetBattleInitData()
    data:SetFightId(fightId)
    -- 玩家战斗生命值 = 指挥官血量（HPValue + 胜利次数×HPGrowthValue），非外部耐久度 Durability
    data:SetPlayer(self._GameControl:GetControl():GetPlayerBattleHp(stage.FightWinCount))

    -- 无尽关多轮次敌人加成（经 GetEnemyExtraHp/Atk accessor 算好，PreFight 显示同源 DRY）
    -- 局外算好 extra 经契约传，STE 装配层只 fightCfg+extra 相加；镜像 SetPlayer 范式（局外算、契约传、局内消费）
    local control = self._GameControl:GetControl()
    data:SetEnemyExtraHp(control:GetEnemyExtraHp())
    data:SetEnemyExtraAtk(control:GetEnemyExtraAtk())
    -- 球槽容量：初始值 + 最大上限（PunishaarClientConfig.InitBallSlotCount / BallSlotMax）
    data:SetBallSlotCapacity(control:GetInitBallSlotCount())
    data:SetBallSlotMax(control:GetBallSlotMax())

    -- 对战区卡牌装配（背包卡不参战）
    -- TotalMasterCards 是 Dictionary<int,MasterCard>，必须用 pairs 遍历
    local cards = stage.TotalMasterCards
    if cards then
        for _, card in pairs(cards) do
            if card.AreaType == XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea then
                data:AddCard(card.TemplateId, card.Level, card.StartPos, card.SubCardId)
            end
        end
    end

    -- 构造期排序：_Cards(pairs 序) → _SortedCards(posIndex 序)，供 SetupBattle 建实体 + GetCardLevelByIndex 读 level（#82）
    data:BuildSortedCards()

    -- 进入战斗节点：打印 FightID + 玩家阵容配置（对战区卡）#战斗节点日志
    local lineup = {}
    if cards then
        for _, card in pairs(cards) do
            if card.AreaType == XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea then
                lineup[#lineup + 1] = string.format("[cid=%s lv=%s pos=%s sub=%s]",
                        tostring(card.TemplateId), tostring(card.Level), tostring(card.StartPos), tostring(card.SubCardId))
            end
        end
    end
    XLog.Debug(string.format("[Punishaar] 进入战斗节点 FightID=%s 阵容(%d):%s",
            tostring(fightId), #lineup, table.concat(lineup, " ")))
end

--endregion ----------private end----------

return XPunishaarRunControl
