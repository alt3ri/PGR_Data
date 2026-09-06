local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiTransfiniteTowerRoleGrid = require("XUi/XUiTransfiniteTower/BattleRoleRoom/XUiTransfiniteTowerRoleGrid")

---超限启航·角色详情界面 Proxy：定制领航员强化面板 / Buff·DeBuff 状态区 / 领航员标 / 能量提示常驻
---Proxy 由通用详情框架实例化，数据走 Agency 对外接口 XMVCA.XTransfiniteTower
---@class XUiTransfiniteTowerBattleRoomRoleDetailProxy : XUiBattleRoomRoleDetailDefaultProxy
local XUiTransfiniteTowerBattleRoomRoleDetailProxy = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiTransfiniteTowerBattleRoomRoleDetailProxy")

local COLOR_BUFF_BG = XUiHelper.Hexcolor2Color("2E76BD")
local COLOR_DEBUFF_BG = XUiHelper.Hexcolor2Color("A32F2D")

--region 生命周期钩子

function XUiTransfiniteTowerBattleRoomRoleDetailProxy:GetAutoCloseInfo()
    local agency = XMVCA.XTransfiniteTower
    local endTime = agency:GetTowerUnlockEndTime(agency:GetCurrentChapterId())
    if endTime <= 0 then
        return false
    end
    return true, endTime, handler(self, self.OnTowerClosed)
end

function XUiTransfiniteTowerBattleRoomRoleDetailProxy:OnTowerClosed(isClose)
    if not isClose then
        return
    end
    XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerTowerClosed"))
    self._RootUi:Close()
end

function XUiTransfiniteTowerBattleRoomRoleDetailProxy:AOPOnStartAfter(rootUi)
    self._RootUi = rootUi
    -- DeBuff 详情按钮的回调整个界面共用一条，绑定前缓存一次
    self._DebuffInfoCb = handler(self, self.OnBtnStatusInfoClick)
    -- 超限启航打开时能量提示常驻
    rootUi.PanelEnergyTips.gameObject:SetActiveEx(true)
    -- 词缀详情气泡：BtnStatusInfo 展开，BtnMask 点击空白收起
    rootUi.BtnCloseBubble:AddEventListener(handler(self, self.OnBtnCloseBubbleClick))
    rootUi.BtnCloseBubble.gameObject:SetActiveEx(false)
    rootUi.PanelBubbleTip.gameObject:SetActiveEx(false)
    -- 领航员强化面板的教学跳转按钮
    rootUi.BtnTeach:AddEventListener(handler(self, self.OnBtnTeachClick))
end

---选中角色刷新后：按领航员与否切换强化面板 / 状态区
function XUiTransfiniteTowerBattleRoomRoleDetailProxy:AOPOnCharacterClickAfter(rootUi)
    local entityId = rootUi.CurrentEntityId
    if not XTool.IsNumberValid(entityId) then
        return
    end
    self:HideBubble(rootUi)
    local isLeader = XMVCA.XTransfiniteTower:IsLeaderEntity(entityId)
    rootUi.BattleRoleRoomFormationLeader.gameObject:SetActiveEx(isLeader)
    rootUi.PanelRoleModeBuff.gameObject:SetActiveEx(isLeader)
    rootUi.PanelStatusArea.gameObject:SetActiveEx(not isLeader)
    if isLeader then
        self:RefreshLeaderBuff(rootUi, entityId)
    else
        self:RefreshStatusArea(rootUi, entityId)
    end
end

--endregion

--region 刷新

---领航员专属强化
function XUiTransfiniteTowerBattleRoomRoleDetailProxy:RefreshLeaderBuff(rootUi, entityId)
    rootUi.TxtTitle.text = XMVCA.XTransfiniteTower:GetLeaderBuffName(entityId)
    rootUi.TxtBuffDec.text = XUiHelper.ReplaceTextNewLine(XMVCA.XTransfiniteTower:GetLeaderBuffDesc(entityId))
end

---非领航员状态区：Buff / DeBuff 各最多一条（Buff 在前）
function XUiTransfiniteTowerBattleRoomRoleDetailProxy:RefreshStatusArea(rootUi, entityId)
    self._BuffDesc = XMVCA.XTransfiniteTower:GetRoleBuff(entityId)
    self._DebuffDesc, self._DebuffInfoDesc = XMVCA.XTransfiniteTower:GetRoleDebuff(entityId)
    self._HasBuff = not string.IsNilOrEmpty(self._BuffDesc)
    local hasDebuff = not string.IsNilOrEmpty(self._DebuffDesc)
    local total = (self._HasBuff and 1 or 0) + (hasDebuff and 1 or 0)

    self._StatusGrids = XUiHelper.RefreshUiObjectList(self._StatusGrids, rootUi.GridStatus.transform.parent,
        rootUi.GridStatus, total, handler(self, self.RefreshStatusGrid))
end

function XUiTransfiniteTowerBattleRoomRoleDetailProxy:RefreshStatusGrid(index, grid)
    -- 有 Buff 时它占第一格，DeBuff 排在其后
    local isDebuff = not self._HasBuff or index > 1
    grid.ImgBgBuff.gameObject:SetActiveEx(true)
    grid.ImgBgBuff.color = isDebuff and COLOR_DEBUFF_BG or COLOR_BUFF_BG
    grid.TxtStatusDec.text = XUiHelper.ReplaceTextNewLine(isDebuff and self._DebuffDesc or self._BuffDesc)
    -- Buff 无详情按钮；DeBuff 有，点击弹气泡
    grid.BtnStatusInfo.gameObject:SetActiveEx(isDebuff)
    if isDebuff then
        grid.BtnStatusInfo:AddEventListener(self._DebuffInfoCb)
    end
end

--endregion

--region 气泡

function XUiTransfiniteTowerBattleRoomRoleDetailProxy:OnBtnStatusInfoClick()
    local rootUi = self._RootUi
    rootUi.TxtTip.text = self._DebuffInfoDesc or ""
    rootUi.PanelBubbleTip.gameObject:SetActiveEx(true)
    rootUi.BtnCloseBubble.gameObject:SetActiveEx(true)
end

function XUiTransfiniteTowerBattleRoomRoleDetailProxy:OnBtnCloseBubbleClick()
    self:HideBubble(self._RootUi)
end

function XUiTransfiniteTowerBattleRoomRoleDetailProxy:HideBubble(rootUi)
    rootUi.PanelBubbleTip.gameObject:SetActiveEx(false)
    rootUi.BtnCloseBubble.gameObject:SetActiveEx(false)
end

--endregion

--region 交互

---点击领航员强化面板的教学按钮：打开领航员教学界面并选中当前角色
function XUiTransfiniteTowerBattleRoomRoleDetailProxy:OnBtnTeachClick()
    local entityId = self._RootUi.CurrentEntityId
    if not XTool.IsNumberValid(entityId) then
        return
    end
    local charId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    XMVCA.XTransfiniteTower:OpenTeachWithSelect(charId)
end

---@return boolean 返回 true 拦截上阵
function XUiTransfiniteTowerBattleRoomRoleDetailProxy:AOPOnBtnJoinTeamClickedBefore(rootUi, entityId)
    if XMVCA.XTransfiniteTower:IsEntityEnergyEmpty(entityId) then
        XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerBattleEnergyNotEnough"))
        return true
    end
    return false
end

--endregion

--region 左侧格子

---可选角色列表：自机 + 试用机器人
function XUiTransfiniteTowerBattleRoomRoleDetailProxy:GetEntities(characterType)
    return XMVCA.XTransfiniteTower:GetStageSelectableEntities(characterType)
end

function XUiTransfiniteTowerBattleRoomRoleDetailProxy:GetFilterControllerConfig()
    return XMVCA.XCharacter:GetModelCharacterFilterController()["UiTransfiniteTowerBattleRoomRoleDetail"]
end

---覆写排序：本层可带领航员时把领航员置顶
function XUiTransfiniteTowerBattleRoomRoleDetailProxy:GetFilterSortOverrideFunTable()
    return XMVCA.XTransfiniteTower:GetLeaderFirstSortTable()
end

---左侧选角格子用自定义类（领航员显示 PanelLeader）
function XUiTransfiniteTowerBattleRoomRoleDetailProxy:GetGridProxy()
    return XUiTransfiniteTowerRoleGrid
end

--endregion

return XUiTransfiniteTowerBattleRoomRoleDetailProxy
