local XUiEquipOverrunV4P6GridOverrunBase = require("XUi/XUiEquip/XUiEquipOverrunV4P6/XUiEquipOverrunV4P6GridOverrunBase")

---@class XUiEquipOverrunV4P6GridOverrunAttr : XUiEquipOverrunV4P6GridOverrunBase
---@field _Control XEquipControl
---@field Parent XUiEquipOverrunV4P6
---@field BtnlLevel CS.XUiButton
---@field ImgBgLevelOn UnityEngine.GameObject
---@field ImgBgLevelOff UnityEngine.GameObject
---@field OverrunCfgId XTableWeaponOverrun
local XUiEquipOverrunV4P6GridOverrunAttr = XClass(XUiEquipOverrunV4P6GridOverrunBase, "UiEquipOverrunV4P6GridOverrunAttr")

function XUiEquipOverrunV4P6GridOverrunAttr:OnStart(index, overrunCfgId)
    self.Index = index
    self.OverrunCfgId = overrunCfgId
    self:InitComponents()
end

function XUiEquipOverrunV4P6GridOverrunAttr:OnEnable()
    self:Refresh()
end

function XUiEquipOverrunV4P6GridOverrunAttr:InitComponents()
    self.BtnlLevel:AddEventListener(function() self:OnBtnlLevelClick() end)
end

function XUiEquipOverrunV4P6GridOverrunAttr:OnBtnlLevelClick()
    self.Parent:OnClickGridOverrun(self.Index)
end

function XUiEquipOverrunV4P6GridOverrunAttr:Refresh()
    local overrunCfg = self:GetOverrunConfig()
    self:RefreshName(overrunCfg)
    self:RefreshActiveBg(overrunCfg)
    self:RefreshSelectState()
    self:RefreshNextTag(overrunCfg)
    self:RefreshDesc(overrunCfg)
    self:RefreshLine(overrunCfg)
end

function XUiEquipOverrunV4P6GridOverrunAttr:RefreshDesc(overrunCfg)
    local isActive = self:IsOverrunActive(overrunCfg)

    -- 谐振被动技能
    local skillCfg = XMVCA.XEquip:GetWeaponOverrunSkillConfigById(overrunCfg.ShowOverrunSkillId)
    self.ImgSkill.gameObject:SetActiveEx(isActive)
    self.BtnlLevel:SetNameByGroup(1, skillCfg.Name)
    self.ImgSkill:SetSprite(skillCfg.Icon)

    -- 上锁状态
    self.ImgBgLock.gameObject:SetActiveEx(not isActive)
end

return XUiEquipOverrunV4P6GridOverrunAttr
