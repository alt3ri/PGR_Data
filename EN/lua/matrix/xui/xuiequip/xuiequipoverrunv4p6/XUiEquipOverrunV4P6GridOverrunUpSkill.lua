local XUiEquipOverrunV4P6GridOverrunBase = require("XUi/XUiEquip/XUiEquipOverrunV4P6/XUiEquipOverrunV4P6GridOverrunBase")

---@class XUiEquipOverrunV4P6GridOverrunUpSkill : XUiEquipOverrunV4P6GridOverrunBase
---@field _Control XEquipControl
---@field Parent XUiEquipOverrunV4P6
---@field BtnlLevel CS.XUiButton
---@field ImgBgLevelOn UnityEngine.GameObject
---@field ImgBgLevelOff UnityEngine.GameObject
---@field ImgSkill UnityEngine.UI.Image
---@field ImgBgLock UnityEngine.GameObject
local XUiEquipOverrunV4P6GridOverrunUpSkill = XClass(XUiEquipOverrunV4P6GridOverrunBase, "UiEquipOverrunV4P6GridOverrunUpSkill")

function XUiEquipOverrunV4P6GridOverrunUpSkill:OnStart(index, overrunCfgId)
    self.Index = index
    self.OverrunCfgId = overrunCfgId
    self:InitComponents()
end

function XUiEquipOverrunV4P6GridOverrunUpSkill:OnEnable()
    self:Refresh()
end

function XUiEquipOverrunV4P6GridOverrunUpSkill:InitComponents()
    self.BtnlLevel:AddEventListener(function() self:OnBtnlLevelClick() end)
end

function XUiEquipOverrunV4P6GridOverrunUpSkill:OnBtnlLevelClick()
    self.Parent:OnClickGridOverrun(self.Index)
end

function XUiEquipOverrunV4P6GridOverrunUpSkill:Refresh()
    local overrunCfg = self:GetOverrunConfig()
    self:RefreshName(overrunCfg)
    self:RefreshActiveBg(overrunCfg)
    self:RefreshSelectState()
    self:RefreshNextTag(overrunCfg)
    self:RefreshLine(overrunCfg)
end

return XUiEquipOverrunV4P6GridOverrunUpSkill
