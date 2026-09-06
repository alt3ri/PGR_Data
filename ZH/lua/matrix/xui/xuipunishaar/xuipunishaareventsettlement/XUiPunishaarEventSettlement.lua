local XUiPunishaarEventSettlementPanelOption = require("XUi/XUiPunishaar/XUiPunishaarEventSettlement/XUiPunishaarEventSettlementPanelOption")
local XUiPunishaarEventSettlementPanelReward = require("XUi/XUiPunishaar/XUiPunishaarEventSettlement/XUiPunishaarEventSettlementPanelReward")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiPunishaarEventSettlement : XLuaUi
---@field _Control XPunishaarControl
---@field PanelRole UnityEngine.RectTransform
---@field RImgRole UnityEngine.UI.RawImage
---@field TxtRoleName UnityEngine.UI.Text
---@field TxtRoleContent UnityEngine.UI.Text
---@field TxtTitle UnityEngine.UI.Text
---@field PanelOption UnityEngine.RectTransform
---@field PanelReward UnityEngine.RectTransform
---@field RoleEffect UnityEngine.RectTransform
---@field TxtCoinNum UnityEngine.UI.Text
---@field TxtList UnityEngine.RectTransform 文本区总节点，控制其显隐（非奖励阶段显/奖励阶段藏）
---@field TxtDesc UnityEngine.UI.Text 事件描述文本（非奖励阶段显示，挂在 TxtList 下）
-- ======== AUTO FIELDS END ========
--- v3 剧情事件面板（Event 节点 Processing 态）。
--- OnStart(node) 接收 Server 节点：node.EventInfo.SelectedEventId → EventGroup → EventId → EventContent 显内容。
--- 内容链：每条内容的 ConfirmContent 按钮（PanelOption.BtnComfirm）推进；推进到下一条时若下一条是最后一条
---   （NextEvent 为空）→ 立即预取 FinishEvent 拿奖励 + 显示奖励 grid（PanelReward），最后一条的"结束"按钮即退出。
--- 退出：最后一条内容点"结束"→ _FinishEventThenExit（RewardReplace 走暂存卡处理 / Finished 直退）+ Close。
--- 关键：奖励在"进最后一条"时就请求+展示，玩家只需再点一次"结束"即退出，无二次按钮。
local XUiPunishaarEventSettlement = XLuaUiManager.Register(XLuaUi, "UiPunishaarEventSettlement")

function XUiPunishaarEventSettlement:OnAwake()
    self:InitChildUis()
end

function XUiPunishaarEventSettlement:InitChildUis()
    ---@type XUiPunishaarEventSettlementPanelOption
    self._PanelOption = XUiPunishaarEventSettlementPanelOption.New(self.PanelOption, self)
    ---@type XUiPunishaarEventSettlementPanelReward
    self._PanelReward = XUiPunishaarEventSettlementPanelReward.New(self.PanelReward, self)
end

--- @param node table Server.XPunishaarNode（Processing 态）
function XUiPunishaarEventSettlement:OnStart(node)
    if not node then
        XLog.Error("[PunishaarEventSettlement] OnStart: node 为空")
        return
    end
    self._Node = node
    self._EventInfo = node.EventInfo

    -- 解析选中事件内容：SelectedEventId(EventGroup.Id) → EventGroup.EventId → EventContent
    local selectedId = self._EventInfo and self._EventInfo.SelectedEventId
    if not XTool.IsNumberValid(selectedId) then
        XLog.Error("[PunishaarEventSettlement] OnStart: SelectedEventId 无效，节点未选定事件")
        return
    end
    -- Event 三表为关卡级（GameConfigControl），经 GameControl 读取（EventSettlement 开启时 GameControl 必存活）
    local gc = self._Control and self._Control.GameControl
    if not gc then
        XLog.Error("[PunishaarEventSettlement] OnStart: GameControl 不可用")
        return
    end
    local eventGroupCfg = gc:GetTablePunishaarEventGroup(selectedId)
    if not eventGroupCfg then
        XLog.Error("[PunishaarEventSettlement] OnStart: EventGroup 配置缺失，id=" .. tostring(selectedId))
        return
    end
    self._EventGroupCfg = eventGroupCfg

    local contentId = eventGroupCfg.EventId
    if not XTool.IsNumberValid(contentId) then
        XLog.Error("[PunishaarEventSettlement] OnStart: EventGroup.EventId 无效，groupId=" .. tostring(selectedId))
        return
    end
    local contentCfg = gc:GetTablePunishaarEventContent(contentId)
    if not contentCfg then
        XLog.Error("[PunishaarEventSettlement] OnStart: EventContent 配置缺失，id=" .. tostring(contentId))
        return
    end
    self._CurrentContentCfg = contentCfg

    -- 注入子面板回调：PanelOption 的 BtnComfirm 点击 → AdvanceChain（推进链/退出）
    self._PanelOption:SetAdvanceHandler(Handler(self, self.AdvanceChain))

    -- 进入内容阶段（PanelOption 显，PanelReward 藏）
    self:_ShowContentStage()
    self:RefreshContent(contentCfg)
    -- 若首条即最后一条（NextEvent 为空，单内容事件）→ 立即预取奖励
    if not XTool.IsNumberValid(contentCfg.NextEvent) then
        self:_EnterRewardStage()
    end
end

function XUiPunishaarEventSettlement:OnEnable()
end

function XUiPunishaarEventSettlement:OnDisable()
end

function XUiPunishaarEventSettlement:OnDestroy()
    self._Node = nil
    self._EventInfo = nil
    self._EventGroupCfg = nil
    self._CurrentContentCfg = nil
    self._FinishInFlight = nil
    self._RewardFetched = nil
    self._PendingExit = nil
    self._IsExiting = nil
end

--region ----------内容阶段----------

--- 取 list 字段首项；list 为 nil/空表返回 nil（#21 不用三元，提前 return）。
---@param list table|nil
---@return string|nil
function XUiPunishaarEventSettlement:_FirstListItem(list)
    if not list then return nil end
    if XTool.IsTableEmpty(list) then return nil end
    return list[1]
end

function XUiPunishaarEventSettlement:_ShowContentStage()
    self.PanelOption.gameObject:SetActiveEx(true)
    self.PanelReward.gameObject:SetActiveEx(false)
    -- 内容阶段显 TxtList 文本区（含 TxtDesc）
    if self.TxtList then
        self.TxtList.gameObject:SetActiveEx(true)
    end
end

--- 刷新事件内容（内容阶段）。
---@param contentCfg XTablePunishaarEventContent
function XUiPunishaarEventSettlement:RefreshContent(contentCfg)
    if not contentCfg then return end
    self._CurrentContentCfg = contentCfg

    -- 标题/描述
    if self.TxtTitle then
        self.TxtTitle.text = contentCfg.Name or ""
    end
    if self.TxtDesc then
        self.TxtDesc.text = XUiHelper.ReplaceTextNewLine(contentCfg.Desc or "")
    end

    -- 角色：RoleIcons/RoleNames/RoleContents 均为 list，取首项按存在性显隐
    local firstIcon = self:_FirstListItem(contentCfg.RoleIcons)
    local firstName = self:_FirstListItem(contentCfg.RoleNames)
    local firstContent = self:_FirstListItem(contentCfg.RoleContents)

    local hasIcon = not string.IsNilOrEmpty(firstIcon)
    local hasName = not string.IsNilOrEmpty(firstName)
    local hasContent = not string.IsNilOrEmpty(firstContent)
    -- PanelRole 同时含立绘与对话框，内部子节点无独立 XUiNode 引用；
    -- 无任何角色对话（图标/名字/台词皆空）→ 隐藏整个容器等价隐藏对话框。
    local hasAnyRole = hasIcon or hasName or hasContent
    if self.PanelRole then
        self.PanelRole.gameObject:SetActiveEx(hasAnyRole)
    end
    if hasAnyRole then
        if self.RImgRole then
            self.RImgRole.gameObject:SetActiveEx(hasIcon)
            if hasIcon then
                self.RImgRole:SetRawImage(firstIcon)
            end
        end
        if self.TxtRoleName then
            self.TxtRoleName.gameObject:SetActiveEx(hasName)
            if hasName then
                self.TxtRoleName.text = firstName
            end
        end
        if self.TxtRoleContent then
            self.TxtRoleContent.gameObject:SetActiveEx(hasContent)
            if hasContent then
                self.TxtRoleContent.text = XUiHelper.ReplaceTextNewLine(firstContent)
            end
        end
    end

    -- 当前货币量（HUD 常显）
    if self.TxtCoinNum then
        local gold = self._Control:GetCurrentGold()
        self.TxtCoinNum.text = tostring(gold or 0)
    end

    -- ConfirmContent 按钮
    self._PanelOption:Refresh(contentCfg.ConfirmContent)
end

--- 推进内容链（PanelOption.BtnComfirm 点击触发）。
--- 当前内容 NextEvent 非空 → 刷下一条 Content；若下一条是最后一条（NextEvent 为空）→ 预取奖励。
--- 当前内容 NextEvent 为空（已是最后一条）→ 点"结束"退出节点。
function XUiPunishaarEventSettlement:AdvanceChain()
    if self._IsExiting then return end
    local contentCfg = self._CurrentContentCfg
    if not contentCfg then return end
    local gc = self._Control and self._Control.GameControl
    if not gc then
        XLog.Error("[PunishaarEventSettlement] AdvanceChain: GameControl 不可用")
        return
    end

    local nextEvent = contentCfg.NextEvent
    if XTool.IsNumberValid(nextEvent) then
        local nextCfg = gc:GetTablePunishaarEventContent(nextEvent)
        if not nextCfg then
            XLog.Error("[PunishaarEventSettlement] AdvanceChain: 下一 Content 配置缺失，id=" .. tostring(nextEvent))
            return
        end
        self:RefreshContent(nextCfg)
        -- 下一条是最后一条 → 立即预取奖励（FinishEvent）并显奖励 grid
        if not XTool.IsNumberValid(nextCfg.NextEvent) then
            self:_EnterRewardStage()
        end
    else
        -- 已是最后一条：点"结束"退出
        self:_DoExit()
    end
end

--- 进入最后一条内容时预取奖励：FinishEvent → 回调显奖励 grid。
--- 幂等：_RewardFetched 已真或 _FinishInFlight 进行中则不重入。
function XUiPunishaarEventSettlement:_EnterRewardStage()
    if self._RewardFetched or self._FinishInFlight then return end
    local gc = self._Control and self._Control.GameControl
    if not gc then
        XLog.Error("[PunishaarEventSettlement] _EnterRewardStage: GameControl 不可用")
        return
    end
    self._FinishInFlight = true
    gc:FinishEvent(Handler(self, self._OnRewardFetchedCb))
end

--- FinishEvent 回调：node 为更新后的当前节点（终端态）；nil=失败。
--- 显奖励 grid（PanelReward）；若玩家在 FinishEvent 未回时已点"结束"（_PendingExit）则续退。
---@param node table|nil
function XUiPunishaarEventSettlement:_OnRewardFetchedCb(node)
    self._FinishInFlight = false
    if not node then
        XLog.Error("[PunishaarEventSettlement] _OnRewardFetchedCb: FinishEvent 失败")
        return
    end
    self._Node = node
    self._RewardFetched = true
    self:_ShowRewardGrid()
    -- 货币量刷新（奖励下发后可能变动）
    if self.TxtCoinNum then
        local gold = self._Control:GetCurrentGold()
        self.TxtCoinNum.text = tostring(gold or 0)
    end
    if self._PendingExit then
        self._PendingExit = false
        self:_DoExit()
    end
end

--endregion ----------内容阶段----------

--region ----------奖励/退出----------

--- 显奖励 grid：PanelReward 区显，读 EventReward 配置分发 grid；PanelOption（"结束"按钮）保持显。
function XUiPunishaarEventSettlement:_ShowRewardGrid()
    self.PanelReward.gameObject:SetActiveEx(true)
    -- 奖励阶段藏 TxtList 文本区，描述文本改由 PanelReward.TxtContent 承接
    if self.TxtList then
        self.TxtList.gameObject:SetActiveEx(false)
    end
    local eventRewardCfg = nil
    if self._EventGroupCfg and XTool.IsNumberValid(self._EventGroupCfg.EventRewardId) then
        local gc = self._Control and self._Control.GameControl
        if gc then
            eventRewardCfg = gc:GetTablePunishaarEventReward(self._EventGroupCfg.EventRewardId)
        end
    end
    if not eventRewardCfg then
        XLog.Warning("[PunishaarEventSettlement] _ShowRewardGrid: EventReward 配置缺失，奖励区无内容")
    end
    -- 最后一条内容描述（奖励阶段在最后一条触发，_CurrentContentCfg 即最后一条）
    local descText = self._CurrentContentCfg and self._CurrentContentCfg.Desc or ""
    self._PanelReward:Refresh(eventRewardCfg, descText)
end

--- 退出节点（最后一条"结束"按钮触发）。
--- FinishEvent 进行中（_FinishInFlight）→ 挂 _PendingExit，回调里续退；否则直接 _FinishEventThenExit + Close。
function XUiPunishaarEventSettlement:_DoExit()
    if self._IsExiting then return end
    if self._FinishInFlight then
        self._PendingExit = true
        return
    end
    self._IsExiting = true
    local gc = self._Control and self._Control.GameControl
    if not gc then
        XLog.Error("[PunishaarEventSettlement] _DoExit: GameControl 不可用")
        self._IsExiting = nil
        return
    end
    local node = self._Node
    if not node then
        XLog.Error("[PunishaarEventSettlement] _DoExit: 当前节点为空")
        self._IsExiting = nil
        return
    end
    gc:_FinishEventThenExit(node)
    -- TODO: 先盖后关——待下一节点面板就位再关可杜绝底层闪现；暂同步关闭。
    self:Close()
end

--endregion ----------奖励/退出----------

return XUiPunishaarEventSettlement
