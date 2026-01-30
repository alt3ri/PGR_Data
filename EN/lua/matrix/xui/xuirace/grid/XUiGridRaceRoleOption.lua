---@class XUiGridRaceRoleOption : XUiNode 角色列表项
---@field Parent XUiPanelRaceChoose
---@field _Control XRaceControl
local XUiGridRaceRoleOption = XClass(XUiNode, "XUiGridRaceRoleOption")

local Sort = XEnumConst.Race.Sort
local Tween = {
    None = 0,
    Expand = 1,
    Storage = 2,
}

function XUiGridRaceRoleOption:OnStart()
    self.GridMember:SetButtonState(XUiButtonState.Normal)
    self._Storage = self.Transform:FindTransform("Storage")
    self._Expand = self.Transform:FindTransform("Expand")
    self._CurTween = Tween.None
end

function XUiGridRaceRoleOption:OnDestroy()
    if not XTool.UObjIsNil(self._Storage) then
        self._Storage:StopTimelineAnimation()
    end
    if not XTool.UObjIsNil(self._Expand) then
        self._Expand:StopTimelineAnimation()
    end
end

function XUiGridRaceRoleOption:SetRoleId(roleId, sortRule)
    self._RoleId = roleId
    local roleCfg = self._Control:GetRaceCharacterById(roleId)
    local isObsolete = self.Parent.Parent:IsCharacterObsoleteNow(roleId)

    local rate = self.Parent.Parent:GetVotingRate(roleId)
    if XTool.IsNumberValid(rate) then
        self.TxtNum.text = string.format("%s%%", rate)
    else
        self.TxtNum.text = "-%"
    end
    self.RImgHead:SetRawImage(roleCfg.Icon)
    self.ImgFail.gameObject:SetActiveEx(isObsolete)

    if sortRule == Sort.Id or sortRule == Sort.Support then
        self.ImgAttribute.gameObject:SetActiveEx(false)
    else
        local icon = ""
        if sortRule == Sort.Speed then
            icon = self._Control:GetCharacterGradeIcon(roleCfg.ShowSpeed)
        elseif sortRule == Sort.Luck then
            icon = self._Control:GetCharacterGradeIcon(roleCfg.ShowLuck)
        elseif sortRule == Sort.Drift then
            icon = self._Control:GetCharacterGradeIcon(roleCfg.ShowDrift)
        elseif sortRule == Sort.Acc then
            icon = self._Control:GetCharacterGradeIcon(roleCfg.ShowAcc)
        end
        self.ImgAttribute.gameObject:SetActiveEx(true)
        self.ImgAttribute:SetSprite(icon)
    end
end

function XUiGridRaceRoleOption:GetRoleId()
    return self._RoleId
end

function XUiGridRaceRoleOption:PlayTween()
    if self.GridMember.ButtonState == CS.UiButtonState.Select then
        if self._CurTween ~= Tween.Expand then
            if not XTool.UObjIsNil(self._Expand) then
                self._Expand:PlayTimelineAnimation()
                self._CurTween = Tween.Expand
            end
        end
    else
        if self._CurTween ~= Tween.Storage then
            if not XTool.UObjIsNil(self._Storage) then
                self._Storage:PlayTimelineAnimation()
                self._CurTween = Tween.Storage
            end
        end
    end
end

return XUiGridRaceRoleOption
