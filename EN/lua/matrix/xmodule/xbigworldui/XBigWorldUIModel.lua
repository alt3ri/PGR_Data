local XBigWorldUiImpactType = require("XModule/XBigWorldUI/Impact/XBigWorldUiImpactType")

---@class XBigWorldUIModel : XModel
local XBigWorldUIModel = XClass(XModel, "XBigWorldUIModel")

local TableKey = {
    BigWorldUi = {
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "UiName",
    },
    BigWorldPopupUi = {
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "UiName",
    },
    BigWorldUiImpact = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XBigWorldUIModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Ui", TableKey)

    ---@type table<string, XBigWorldUiImpactBase[]>
    self._UiImpacts = {}

    -- 是否不重复弹出确认框
    self._IsNotRepeatConfirmPopup = {}
end

function XBigWorldUIModel:ClearPrivate()
end

function XBigWorldUIModel:ResetAll()
    self._UiImpacts = {}
    self._IsNotRepeatConfirmPopup = {}
end

---@return XTableBigWorldUi
function XBigWorldUIModel:GetUiTemplate(uiMame)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldUi, uiMame, true)
end

---@return XTableBigWorldPopupUi
function XBigWorldUIModel:GetPopupUiTemplate(uiMame)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldPopupUi, uiMame, true)
end

---@return XTableBigWorldUiImpact
function XBigWorldUIModel:GetUiImpactTemplate(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldUiImpact, id, true)
end

-- region Ui

function XBigWorldUIModel:IsPauseFight(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.IsPauseFight or false
end

function XBigWorldUIModel:IsChangeInput(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.IsChangeInput or false
end

function XBigWorldUIModel:IsQueue(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.IsQueue or false
end

function XBigWorldUIModel:IsHideFightUi(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.IsHideFightUi or false
end

function XBigWorldUIModel:IsCloseCameraControl(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.IsCloseCameraControl or false
end

function XBigWorldUIModel:IsVirtual(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.IsVirtual or false
end

function XBigWorldUIModel:GetUiImpactIds(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.ImpactIds or false
end

-- endregion

-- region PopupUi

function XBigWorldUIModel:IsPopupModality(uiName)
    local t = self:GetPopupUiTemplate(uiName)

    return t and t.IsModality or false
end

function XBigWorldUIModel:GetPopupPriority(uiName)
    local t = self:GetPopupUiTemplate(uiName)

    return t and t.Priority or 0
end

function XBigWorldUIModel:GetPopupCustomModalityParams(uiName)
    local t = self:GetPopupUiTemplate(uiName)

    return t and t.CustomModalityParams or nil
end

function XBigWorldUIModel:GetPopupSpecificModalityUi(UiName)
    local t = self:GetPopupUiTemplate(UiName)

    return t and t.SpecificModalityUi or nil
end

-- endregion

-- region UiImpact

function XBigWorldUIModel:GetUiImpactType(id)
    local t = self:GetUiImpactTemplate(id)

    return t and t.Type or 0
end

function XBigWorldUIModel:GetUiImpactParams(id)
    local t = self:GetUiImpactTemplate(id)

    return t and t.Params or nil
end

function XBigWorldUIModel:TryAdditionImpact(uiName)
    if self._UiImpacts[uiName] then
        return
    end

    local impactIds = self:GetUiImpactIds(uiName)

    self._UiImpacts[uiName] = {}
    if not XTool.IsTableEmpty(impactIds) then
        for _, id in pairs(impactIds) do
            local impact = self:CreateImpact(uiName, id)

            if impact then
                table.insert(self._UiImpacts[uiName], impact)
            end
        end
    end
end

function XBigWorldUIModel:TryRemoveImpact(uiName)
    self._UiImpacts[uiName] = nil
end

---@return XBigWorldUiImpactBase
function XBigWorldUIModel:CreateImpact(uiName, impactId)
    local impactType = self:GetUiImpactType(impactId)
    local typeName = XBigWorldUiImpactType[impactType]

    if string.IsNilOrEmpty(typeName) then
        XLog.Error("XBigWorldUIModel:CreateImpact, not found impact type, impactId = " .. tostring(impactId) .. ", uiName = ".. tostring(uiName) .. ", impactType = ".. tostring(impactType))
        return nil
    end

    local impactClass = require("XModule/XBigWorldUI/Impact/Components/XBigWorldUi" .. typeName .. "Impact")

    return impactClass.New(uiName, impactId)
end

function XBigWorldUIModel:CheckAllowOpenWithImpact(uiName)
    for _, impacts in pairs(self._UiImpacts) do
        for _, impact in pairs(impacts) do
            if not impact:IsAllowOpen(uiName) then
                return false
            end
        end
    end

    return true
end

function XBigWorldUIModel:OnUiOpeningWithImpact(uiName)
    local impacts = self._UiImpacts[uiName]

    if not XTool.IsTableEmpty(impacts) then
        for _, impact in pairs(impacts) do
            impact:OnOpening()
        end
    end
end

-- endregion

function XBigWorldUIModel:SetIsNotRepeatConfirmPopup(key, value)
    if not key then
        return
    end
    self._IsNotRepeatConfirmPopup[key] = value
end

function XBigWorldUIModel:IsNotRepeatConfirmPopup(key)
    if not key then
        return false
    end
    return self._IsNotRepeatConfirmPopup[key] or false
end

return XBigWorldUIModel
