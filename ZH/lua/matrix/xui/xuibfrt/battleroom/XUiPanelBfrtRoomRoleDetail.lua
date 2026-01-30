---@class XUiPanelBfrtRoomRoleDetail
local XUiPanelBfrtRoomRoleDetail = XClass(nil, "XUiPanelBfrtRoomRoleDetail")

local CONDITION_HEX_COLOR = {
    [true] = "000000FF",
    [false] = "BC0F23FF",
}

function XUiPanelBfrtRoomRoleDetail:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    ---@type XUiGridEchelonMemberViewData
    self.ViewData = nil
    ---@type XTeam
    self.Team = nil
    --XUiHelper.RegisterClickEvent(self, self.BtnTeamPrefab, self.OnBtnTeamPrefabClicked)
    self.BtnTeamPrefab.gameObject:SetActive(false) -- 2.14去掉编队详情页面的编队预设功能
end

function XUiPanelBfrtRoomRoleDetail:SetData(viewData, currentEntityId, team, checkIsPassTeamEntityFunc)
    self.ViewData = viewData
    self.Team = team
    self.TxtRequireAbility.text = viewData.RequireAbility
    self.TxtEchelonName.text = XDataCenter.BfrtManager.GetEchelonNameTxt(viewData.EchelonType, viewData.EchelonIndex)
    self._CheckIsPassTeamEntityFunc = checkIsPassTeamEntityFunc
end

function XUiPanelBfrtRoomRoleDetail:Refresh(currentEntityId)
    local curCharacter = XMVCA.XCharacter:GetCharacter(currentEntityId)
    local passed = curCharacter and curCharacter.Ability >= self.ViewData.RequireAbility or false
    self.TxtRequireAbility.color = XUiHelper.Hexcolor2Color(CONDITION_HEX_COLOR[passed])
end

function XUiPanelBfrtRoomRoleDetail:OnBtnTeamPrefabClicked()
    RunAsyn(function()
        local stageId = self.ViewData.StageId
        local limitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
        local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(stageId)
        local stageInfos = XDataCenter.FubenManager.GetStageInfo(stageId)
        local stageType = stageInfos and stageInfos.Type
        XLuaUiManager.Open("UiTeamPrefabMain")
    end)
    
end

return XUiPanelBfrtRoomRoleDetail