---@class XEquipOneClickAutoSettingControl : XControl
---@field private _Model XEquipModel
---@field private _MainControl XEquipControl
---@field private _SettingModel XEquipOneClickAutoSettingModel
--- 一键养成自动设置的控制层
local XEquipOneClickAutoSettingControl = XClass(XControl, "XEquipOneClickAutoSettingControl")

function XEquipOneClickAutoSettingControl:OnInit()
    self._SettingModel = self._Model:GetOneClickAutoSettingModel()
end

function XEquipOneClickAutoSettingControl:AddAgencyEvent()
end

function XEquipOneClickAutoSettingControl:RemoveAgencyEvent()
end

function XEquipOneClickAutoSettingControl:OnRelease()
end

---@param settingType XEquipEnum.OneClickAutoSettingType
---@param value boolean
function XEquipOneClickAutoSettingControl:SetSetting(settingType, value)
    local oldValue = self._SettingModel:GetSetting(settingType)
    if oldValue == value then
        return
    end
    self._SettingModel:SetSetting(settingType, value)
    XMVCA.XEquip:SendAgencyEvent(XAgencyEventId.EVENT_ONE_KEY_AUTO_COMMONSETTING_CHANGE, settingType, value)
end

---@param settingType XEquipEnum.OneClickAutoSettingType
---@return boolean
function XEquipOneClickAutoSettingControl:GetSetting(settingType)
    return self._SettingModel:GetSetting(settingType)
end

--- 按角色缓存、自动设置和默认值的优先级获取一键养成设置值
---@param characterId number 角色 Id
---@param settingType XEquipEnum.OneClickAutoSettingType
---@return boolean|number|table
function XEquipOneClickAutoSettingControl:GetCharacterSetting(characterId, settingType)
    return self._SettingModel:GetCharacterSetting(characterId, settingType)
end

--- 保存角色对指定一键养成设置项的覆写值
---@param characterId number 角色 Id
---@param settingType XEquipEnum.OneClickAutoSettingType
---@param value boolean|number|table|nil nil 时删除角色覆写，恢复到全局设置或默认值
function XEquipOneClickAutoSettingControl:SetCharacterSetting(characterId, settingType, value)
    self._SettingModel:SetCharacterSetting(characterId, settingType, value)
end

return XEquipOneClickAutoSettingControl
