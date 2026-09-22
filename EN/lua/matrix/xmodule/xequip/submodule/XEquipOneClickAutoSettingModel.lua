---@class XEquipOneClickAutoSettingModel : XModelBase
--- 一键养成自动设置的数据存储（存档态，SaveUtil 持久化，退出模块不清）
local XEquipOneClickAutoSettingModel = XClass(XModelBase, "XEquipOneClickAutoSettingModel")

---@param settingType XEquipEnum.OneClickAutoSettingType
---@return boolean
local function IsGlobalOneClickAutoSettingType(settingType)
    for _, globalSettingType in ipairs(XMVCA.XEquip.Enum.OneClickAutoSettingGlobalTypeList) do
        if globalSettingType == settingType then
            return true
        end
    end

    return false
end

---@param value boolean|number|table|nil
---@return boolean|number|table|nil
local function CloneSettingValue(value)
    if type(value) == "table" then
        return XTool.Clone(value)
    end

    return value
end

---@param settingType XEquipEnum.OneClickAutoSettingType
---@return boolean|number|table
local function GetDefaultOneClickAutoSetting(settingType)
    local defaultValue = XMVCA.XEquip.Enum.OneClickAutoSettingDefaultValue[settingType]
    return CloneSettingValue(defaultValue)
end

function XEquipOneClickAutoSettingModel:OnInit()
end

function XEquipOneClickAutoSettingModel:ClearPrivate()
    self._SaveKeyDic = nil
end

function XEquipOneClickAutoSettingModel:ResetAll()

end

---region ----------public start----------

---@param settingType XEquipEnum.OneClickAutoSettingType
---@param value boolean
function XEquipOneClickAutoSettingModel:SetSetting(settingType, value)
    self._SaveUtil:SaveData(self:_GetSaveKey(settingType), value and true or false)
end

---@param settingType XEquipEnum.OneClickAutoSettingType
---@return boolean
function XEquipOneClickAutoSettingModel:GetSetting(settingType)
    local value = self._SaveUtil:GetData(self:_GetSaveKey(settingType))
    if value == nil then
        return GetDefaultOneClickAutoSetting(settingType)
    end
    return CloneSettingValue(value)
end

---endregion ----------public end----------

---region ----------character setting start----------

--- 按角色缓存、自动设置和默认值的优先级获取一键养成设置值
---@param characterId number 角色 Id
---@param settingType XEquipEnum.OneClickAutoSettingType
---@return boolean|number|table
function XEquipOneClickAutoSettingModel:GetCharacterSetting(characterId, settingType)
    local value = self._SaveUtil:GetData(self:_GetCharacterSettingSaveKey(characterId, settingType))
    if value ~= nil then
        return CloneSettingValue(value)
    end

    if IsGlobalOneClickAutoSettingType(settingType) then
        return self:GetSetting(settingType)
    end

    return GetDefaultOneClickAutoSetting(settingType)
end

--- 保存角色对指定一键养成设置项的覆写值
---@param characterId number 角色 Id
---@param settingType XEquipEnum.OneClickAutoSettingType
---@param value boolean|number|table|nil nil 时删除角色覆写，恢复到全局设置或默认值
function XEquipOneClickAutoSettingModel:SetCharacterSetting(characterId, settingType, value)
    local key = self:_GetCharacterSettingSaveKey(characterId, settingType)
    self._SaveUtil:SaveData(key, CloneSettingValue(value))
end

---@param characterId number 角色 Id
---@param settingType XEquipEnum.OneClickAutoSettingType
---@return string
function XEquipOneClickAutoSettingModel:_GetCharacterSettingSaveKey(characterId, settingType)
    return "OneClickAutoCharacterSetting_" .. tostring(characterId) .. "_" .. tostring(settingType)
end

---endregion ----------character setting end----------

---@param settingType XEquipEnum.OneClickAutoSettingType
---@return string
function XEquipOneClickAutoSettingModel:_GetSaveKey(settingType)
    if not self._SaveKeyDic then
        self._SaveKeyDic = {}
    end
    local key = self._SaveKeyDic[settingType]
    if not key then
        key = "OneClickAutoSetting" .. tostring(settingType)
        self._SaveKeyDic[settingType] = key
    end
    return key
end

return XEquipOneClickAutoSettingModel
