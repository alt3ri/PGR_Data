local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiGridBattleRoleEnergy = require("XUi/XUiTransfiniteTower/BattleRoleRoom/XUiGridBattleRoleEnergy")
local XUiTransfiniteTowerBattleRoomRoleDetailProxy = require("XUi/XUiTransfiniteTower/BattleRoleRoom/XUiTransfiniteTowerBattleRoomRoleDetailProxy")

---超限启航进战编队界面 Proxy：在通用 UiBattleRoleRoom 上定制领航员标记、体力槽、上阵要求、词缀、回溯提醒 + 进战校验
---Proxy 由通用战斗框架实例化，对本模块而言是外部调用方，数据统一走 Agency 对外接口 XMVCA.XTransfiniteTower
---@class XUiTransfiniteTowerBattleRoleRoomProxy : XUiBattleRoleRoomDefaultProxy
local XUiTransfiniteTowerBattleRoleRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, "XUiTransfiniteTowerBattleRoleRoomProxy")

local POS_COUNT = 3

function XUiTransfiniteTowerBattleRoleRoomProxy:Ctor(team, stageId, proxyArg)
    proxyArg = proxyArg or table.empty
    self._TowerCfgId = proxyArg.TowerCfgId
    self._StageCfgId = proxyArg.StageCfgId
    -- 重新挑战时沿用上次阵容，不允许换人
    self._IsTeamLocked = proxyArg.IsTeamLocked
    XMVCA.XTransfiniteTower:SetCurrentChapterId(self._TowerCfgId)
    XMVCA.XTransfiniteTower:SetCurrentStageCfgId(self._StageCfgId)
end

---队伍锁定时拦掉点角色位（点了会打开角色详情换人）
---@return boolean 返回 true 拦截
function XUiTransfiniteTowerBattleRoleRoomProxy:AOPOnCharacterClickBefore(rootUi, index)
    if self._IsTeamLocked then
        XUiManager.TipText("BattleRoleRoomRoleCannotEditTips")
        return true
    end
    return false
end

---角色详情界面用超限启航定制 Proxy
function XUiTransfiniteTowerBattleRoleRoomProxy:GetRoleDetailProxy()
    return XUiTransfiniteTowerBattleRoomRoleDetailProxy
end

function XUiTransfiniteTowerBattleRoleRoomProxy:GetValidEntityIdList(stageId, team)
    if self._IsTeamLocked then
        local entityIds = {}
        for i = 1, POS_COUNT do
            local entityId = team:GetEntityIdByTeamPos(i)
            if XTool.IsNumberValid(entityId) then
                entityIds[#entityIds + 1] = entityId
            end
        end
        return entityIds
    end
    return XUiBattleRoleRoomDefaultProxy.GetValidEntityIdList(self, stageId, team)
end

--region 生命周期钩子

function XUiTransfiniteTowerBattleRoleRoomProxy:GetAutoCloseInfo()
    local endTime = XMVCA.XTransfiniteTower:GetTowerUnlockEndTime(self._TowerCfgId)
    if endTime <= 0 then
        return false
    end
    return true, endTime, handler(self, self.OnTowerClosed)
end

function XUiTransfiniteTowerBattleRoleRoomProxy:OnTowerClosed(isClose)
    if not isClose then
        return
    end
    XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerTowerClosed"))
    self._RootUi:Close()
end

function XUiTransfiniteTowerBattleRoleRoomProxy:AOPOnStartAfter(rootUi)
    self:InitEnergyGrids(rootUi)
    self:KickOutExhaustedRoles(rootUi)
    self:RefreshTrait(rootUi)
    self:RefreshFormationTip(rootUi)
    self:RefreshEnterWarn(rootUi)
    self:RestoreGeneralSkill(rootUi)
    self._RootUi = rootUi
    self._OnDataChangeCb = handler(self, self.OnTowerDataChange)
    XEventManager.AddEventListener(XEventId.EVENT_TRANSFINITE_TOWER_DATA_CHANGE, self._OnDataChangeCb)
end

---读效应
function XUiTransfiniteTowerBattleRoleRoomProxy:RestoreGeneralSkill(rootUi)
    if not XTool.IsNumberValid(self._TowerCfgId) then
        return
    end
    local skillId = XMVCA.XTransfiniteTower:GetLastGeneralSkill(self._TowerCfgId)
    if not XTool.IsNumberValid(skillId) then
        return
    end
    rootUi.Team:UpdateSelectGeneralSkill(skillId, true)
    if rootUi.PanelGeneralSkill then
        rootUi.PanelGeneralSkill:Refresh(true)
    end
end

---记录效应
function XUiTransfiniteTowerBattleRoleRoomProxy:SaveGeneralSkill()
    if not XTool.IsNumberValid(self._TowerCfgId) then
        return
    end
    local team = self._RootUi and self._RootUi.Team
    if not team then
        return
    end
    XMVCA.XTransfiniteTower:SaveLastGeneralSkill(self._TowerCfgId, team:GetCurGeneralSkill())
end

function XUiTransfiniteTowerBattleRoleRoomProxy:KickOutExhaustedRoles(rootUi)
    -- 重新挑战时队伍锁定为原阵容，不做剔除
    if self._IsTeamLocked then
        return
    end
    local team = rootUi.Team
    local hasKickOut = false
    for i = 1, POS_COUNT do
        local entityId = team:GetEntityIdByTeamPos(i)
        if XTool.IsNumberValid(entityId) and XMVCA.XTransfiniteTower:IsEntityEnergyEmpty(entityId) then
            team:UpdateEntityTeamPos(entityId, i, false)
            hasKickOut = true
        end
    end
    if hasKickOut then
        local agency = XMVCA.XTransfiniteTower
        local progress = agency:GetStageProgressIndex(self._TowerCfgId)
        if not agency:HasKickTipShown(self._TowerCfgId, progress) then
            XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerBattleEnergyEmptyKick"))
            agency:MarkKickTipShown(self._TowerCfgId, progress)
        end
    end
end

function XUiTransfiniteTowerBattleRoleRoomProxy:AOPOnDestroyAfter(rootUi)
    if self._OnDataChangeCb then
        XEventManager.RemoveEventListener(XEventId.EVENT_TRANSFINITE_TOWER_DATA_CHANGE, self._OnDataChangeCb)
        self._OnDataChangeCb = nil
    end
    self._RootUi = nil
end

function XUiTransfiniteTowerBattleRoleRoomProxy:OnTowerDataChange()
    local rootUi = self._RootUi
    if rootUi and not XTool.UObjIsNil(rootUi.GameObject) then
        rootUi:RefreshRoleInfos()
    end
end

---刷新每个角色位的领航员标记 + 体力槽
function XUiTransfiniteTowerBattleRoleRoomProxy:AOPRefreshRoleInfosAfter(rootUi)
    for i = 1, POS_COUNT do
        local entityId = rootUi.Team:GetEntityIdByTeamPos(i)
        local hasRole = XTool.IsNumberValid(entityId)
        local isLeader = hasRole and XMVCA.XTransfiniteTower:IsLeaderEntity(entityId)
        self._LeaderPanels[i].gameObject:SetActiveEx(hasRole and isLeader)
        self._EnergyPanels[i].gameObject:SetActiveEx(hasRole)
        if hasRole then
            local energy
            if isLeader then
                energy = 0
            elseif self._IsTeamLocked then
                energy = XMVCA.XTransfiniteTower:GetEntityEnergyBeforeStage(self._TowerCfgId, self._StageCfgId, entityId)
            else
                energy = XMVCA.XTransfiniteTower:GetEntityEnergy(self._TowerCfgId, entityId)
            end
            self._EnergyGrids[i]:Refresh(isLeader, energy)
        end
    end
    local towerCfgId = self._TowerCfgId
    if not XTool.IsNumberValid(towerCfgId)
        or not XMVCA.XTransfiniteTower:IsLastSettleTower(towerCfgId) then
        rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
    end
end

--endregion

--region 初始化 / 刷新

---每个体力槽面板 New 一个体力格；同时缓存按位节点，避免刷新时反复拼接节点名
function XUiTransfiniteTowerBattleRoleRoomProxy:InitEnergyGrids(rootUi)
    ---@type XUiGridBattleRoleEnergy[]
    self._EnergyGrids = {}
    self._LeaderPanels = {}
    self._EnergyPanels = {}
    for i = 1, POS_COUNT do
        self._LeaderPanels[i] = rootUi["PanelFormationLeader" .. i]
        self._EnergyPanels[i] = rootUi["PanelEnergy" .. i]
        self._EnergyGrids[i] = XUiGridBattleRoleEnergy.New(self._EnergyPanels[i], rootUi)
    end
end

---词缀组：按词缀数量动态实例化 PanelTraitTips（纯展示格，用 RefreshUiObjectList）
function XUiTransfiniteTowerBattleRoleRoomProxy:RefreshTrait(rootUi)
    local traits = XMVCA.XTransfiniteTower:GetStageTraitList(self._StageCfgId)
    local hasTrait = not XTool.IsTableEmpty(traits)
    rootUi.PanelTraitGroup.gameObject:SetActiveEx(hasTrait)
    if not hasTrait then
        return
    end
    self._Traits = traits
    self._TraitGrids = XUiHelper.RefreshUiObjectList(self._TraitGrids, rootUi.PanelTraitGroup.transform,
        rootUi.PanelTraitTips, #traits, handler(self, self.RefreshTraitGrid))
end

function XUiTransfiniteTowerBattleRoleRoomProxy:RefreshTraitGrid(index, grid)
    local trait = self._Traits[index]
    grid.ImgTrait:SetSprite(trait.Icon)
    grid.TxtTraitName.text = trait.Name
    grid.BtnTrait:AddEventListener(self:GetTraitClickCb(index))
end

---点击回调按下标缓存：格子复用时不重复生成闭包
function XUiTransfiniteTowerBattleRoleRoomProxy:GetTraitClickCb(index)
    if not self._TraitClickCbs then
        self._TraitClickCbs = {}
    end
    local cb = self._TraitClickCbs[index]
    if not cb then
        cb = function()
            self:OnTraitClick(self._Traits[index])
        end
        self._TraitClickCbs[index] = cb
    end
    return cb
end

---上阵要求（与选关界面 TxtFormationTips 同源）
function XUiTransfiniteTowerBattleRoleRoomProxy:RefreshFormationTip(rootUi)
    local tip = XMVCA.XTransfiniteTower:GetStageFormationTip(self._StageCfgId)
    local hasTip = not string.IsNilOrEmpty(tip)
    rootUi.PanelFormationTips.gameObject:SetActiveEx(hasTip)
    if hasTip then
        rootUi.TxtFormationTips.text = tip
    end
end

---回溯点失效提醒
function XUiTransfiniteTowerBattleRoleRoomProxy:RefreshEnterWarn(rootUi)
    local isShow = XMVCA.XTransfiniteTower:IsShowEnterWarn(self._TowerCfgId, self._StageCfgId)
    rootUi.PanelEnterWarn.gameObject:SetActiveEx(isShow)
end

--endregion

--region 交互

---点击词缀：打开词缀详情
function XUiTransfiniteTowerBattleRoleRoomProxy:OnTraitClick(traitData)
    XLuaUiManager.Open("UiTransfiniteTowerHide", self._StageCfgId)
end

---进战校验：体力不足 / 领航员数量不满足本层要求，任一不满足弹 toast 并拦截
---@return boolean 返回 true 拦截默认进战
function XUiTransfiniteTowerBattleRoleRoomProxy:AOPOnClickFight(rootUi)
    local team = rootUi.Team
    local leaderCount = 0
    for i = 1, POS_COUNT do
        local entityId = team:GetEntityIdByTeamPos(i)
        if XTool.IsNumberValid(entityId) then
            if XMVCA.XTransfiniteTower:IsLeaderEntity(entityId) then
                leaderCount = leaderCount + 1
            elseif XMVCA.XTransfiniteTower:IsEntityEnergyEmpty(entityId) then
                XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerBattleEnergyNotEnough"))
                return true
            end
        end
    end

    local leaderTip = XMVCA.XTransfiniteTower:GetLeaderCountInvalidTip(self._StageCfgId, leaderCount)
    if leaderTip then
        XUiManager.TipMsg(leaderTip)
        return true
    end

    -- 校验通过，记下本场队伍供结算界面【重新挑战】原地重打，并缓存本塔效应选择
    XMVCA.XTransfiniteTower:SetLastFightTeamId(team:GetId(), self._StageCfgId)
    self:SaveGeneralSkill()
    return false
end

--endregion

return XUiTransfiniteTowerBattleRoleRoomProxy
