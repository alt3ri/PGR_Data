---@class XUiMainLine2PopupChooseGender:XLuaUi
---@field private _Control XMainLine2Control
local XUiMainLine2PopupChooseGender = XLuaUiManager.Register(XLuaUi, "UiMainLine2PopupChooseGender")

function XUiMainLine2PopupChooseGender:OnAwake()
    self:RegisterUiEvents()
end

function XUiMainLine2PopupChooseGender:OnStart(stageId)
    self.StageId = stageId
    self.GenderType = self._Control:GetPlayerGender()
end

function XUiMainLine2PopupChooseGender:OnEnable()
    self:Refresh()
end

function XUiMainLine2PopupChooseGender:OnDisable()
end

function XUiMainLine2PopupChooseGender:OnDestroy()
end

function XUiMainLine2PopupChooseGender:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnBgClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self.GenderBtns = {self.BtnGenderMan, self.BtnGenderWoman}
    self.PanelGender:InitBtns(self.GenderBtns, handler(self, self.OnToggleGenderSelect))
end

function XUiMainLine2PopupChooseGender:OnBtnCloseClick()
    self:Close()
end

function XUiMainLine2PopupChooseGender:OnBtnConfirmClick()
    self._Control:SetPlayerGender(self.GenderType)
    local stageId = self.StageId
    self:Close()

    -- 关卡配置机器人
    local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
    local team = XDataCenter.TeamManager.GetXTeamByStageIdEx(stageId)
    local entityIds = {0, 0, 0}
    for i, robotId in pairs(stageCfg.RobotId) do
        entityIds[i] = robotId
    end
    
    -- 指挥官机器人
    local isExit, lineupCfg = XMVCA.XFuben:GetConfigStageLineupType(stageId)
    local order = lineupCfg.PlayerReplaceOrders
    local isMan = self.GenderType == XEnumConst.PLAYER.GENDER_TYPE.MAN
    local playerRobotId = isMan and lineupCfg.PlayerSexRobotMan or lineupCfg.PlayerSexRobotWoman
    entityIds[order] = playerRobotId

    -- 进入战斗
    team:UpdateEntityIds(entityIds)
    team:AutoSelectGeneralSkill(XMVCA.XFuben:GetGeneralSkillIds(stageId))
    XMVCA.XFuben:EnterFightByStageId(stageId, team:GetId())
end

function XUiMainLine2PopupChooseGender:OnToggleGenderSelect(index)
    self.GenderType = index
end

function XUiMainLine2PopupChooseGender:Refresh()
    self:RefreshPlayers()
end

-- 刷新指挥官
function XUiMainLine2PopupChooseGender:RefreshPlayers()
    local isExit, cfg = XMVCA.XFuben:GetConfigStageLineupType(self.StageId)
    local robotIds = {cfg.PlayerSexRobotMan, cfg.PlayerSexRobotWoman}
    for i, robotId in ipairs(robotIds) do
        local btn = self.GenderBtns[i]
        local rebuildNpcId = XRobotManager.GetRebuildNpcId(robotId)
        local bigImg = XRobotManager.GetRobotRebuildNpcBigImage(rebuildNpcId)
        btn:SetRawImage(bigImg)
    end

    self.PanelGender:SelectIndex(self.GenderType, false)
end

return XUiMainLine2PopupChooseGender