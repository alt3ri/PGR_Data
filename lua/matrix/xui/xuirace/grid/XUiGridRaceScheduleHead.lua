---@class XUiGridRaceScheduleHead : XUiNode
---@field Parent XUiGridRaceScheduleGroup
---@field _Control XRaceControl
local XUiGridRaceScheduleHead = XClass(XUiNode, "XUiGridRaceScheduleHead")

---@param isFinal boolean 是否总冠军
function XUiGridRaceScheduleHead:OnStart(isChampion)
    self._IsChampion = isChampion
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    self.Transform.localPosition = CS.UnityEngine.Vector3.zero
end

function XUiGridRaceScheduleHead:SetRoleId(roleId, isUp, isDown)
    self._RoleId = roleId
    if XTool.IsNumberValid(roleId) then
        local roleCfg = self._Control:GetRaceCharacterById(roleId)
        self.PanelRole.gameObject:SetActiveEx(true)
        self.RImgHead:SetRawImage(roleCfg.Icon)
        self.ImgMask.gameObject:SetActiveEx(isDown)--淘汰
        self.ImgWinBg.gameObject:SetActiveEx(not self._IsChampion and isUp)--晋升
    else
        self.PanelRole.gameObject:SetActiveEx(false)
    end
end

function XUiGridRaceScheduleHead:OnBtnClick()
    if XTool.IsNumberValid(self._RoleId) then
        local align = self.Parent.Transform.anchoredPosition.x < 0 and XEnumConst.Race.TipAlign.Left or XEnumConst.Race.TipAlign.Right
        XLuaUiManager.Open("UiRaceMemberDetail", self._RoleId, self.Parent.Transform, align)
    end
end

return XUiGridRaceScheduleHead
