local XUiTheatre5MissionPanel = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiTheatre5MissionPanel')

--- 角色信息查看界面特殊的任务面板
---@class XUiTheatre5MissionPanelInCheck: XUiTheatre5MissionPanel
---@field _Control XTheatre5Control
local XUiTheatre5MissionPanelInCheck = XClass(XUiTheatre5MissionPanel, 'XUiTheatre5MissionPanelInCheck')



--region Overrdie

--- 重写点击逻辑，未接取任务时不弹提示
function XUiTheatre5MissionPanelInCheck:OnBtnRewardClick()
    if self._Control.MissionControl:CheckHasMission() then
        if self._IsDetailShow then
            self:OnBtnDetailCloseClick()
            return
        end

        local mission = self._Control.MissionControl:GetCurMission()

        if mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasFinish then
            XUiManager.TipMsg(self._Control.MissionControl:GetClientConfigMissionFinishTipsInSkillChoicePart())
        end

        self.DetailRoot.gameObject:SetActiveEx(true)
        self.BtnDetailClose.gameObject:SetActiveEx(true)
        self.TaskDetail:Open()
        self.TaskDetail:Refresh(XMVCA.XTheatre5.EnumConst.UITaskDetailShowType.InProgress, self._Control.MissionControl:GetCurMission(), mission.MissionRelicId)
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
        self._IsDetailShow = true
    end
end

function XUiTheatre5MissionPanelInCheck:Refresh()
    XUiTheatre5MissionPanel.Refresh(self)
    -- 始终不显示升级按钮
    self.BtnUpgrade.gameObject:SetActiveEx(false)

end

--endregion

return XUiTheatre5MissionPanelInCheck