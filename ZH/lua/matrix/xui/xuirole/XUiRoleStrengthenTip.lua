---@class XUiRoleStrengthenTip : XLuaUi
---@field _Control XCharacterControl
local XUiRoleStrengthenTip = XLuaUiManager.Register(XLuaUi, "UiRoleStrengthenTip")
local XUiCultureStarGroup = require("XUi/XUiRole/XUiRoleCulture/XUiCultureStarGroup")

function XUiRoleStrengthenTip:OnAwake()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
end

function XUiRoleStrengthenTip:OnStart(params)
    self:Refresh(params)
end

function XUiRoleStrengthenTip:Refresh(params)
    self:RefreshProperty(self.TxtLife, self.TxtLifeAfter, params.BeforeAttribs.Life, params.AfterAttribs.Life)
    self:RefreshProperty(self.TxtAttack, self.TxtAttackAfter, params.BeforeAttribs.Attack, params.AfterAttribs.Attack)
    self:RefreshProperty(self.TxtDefense, self.TxtDefenseAfter, params.BeforeAttribs.Defense, params.AfterAttribs.Defense)
    self:RefreshProperty(self.TxtCrit, self.TxtCritAfter, params.BeforeAttribs.Crit, params.AfterAttribs.Crit)
    self:RefreshProperty(self.TxtPower, self.TxtPowerAfter, params.BeforeAttribs.Power, params.AfterAttribs.Power)
end

function XUiRoleStrengthenTip:RefreshProperty(txtBefore, txtAfter, before, after)
    if type(before) == "number" then
        after = after or before
    else
        before = FixToInt(before)
        after = FixToInt(after)
    end
    txtBefore.text = before
    local hasGain = after ~= before
    txtAfter.gameObject:SetActiveEx(hasGain)
    if hasGain then
        txtAfter.text = after
    end
end

function XUiRoleStrengthenTip:OnBtnCloseClick()
    self:Close()
end

return XUiRoleStrengthenTip
