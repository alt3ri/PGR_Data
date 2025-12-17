local XBWSettingBase = require("XModule/XBigWorldSet/XSetting/XBWSettingBase")
-- local XBWSettingValue = require("XModule/XBigWorldSet/XSetting/XBWSettingValue")

---@class XBWInputSetting : XBWSettingBase
local XBWInputSetting = XClass(XBWSettingBase, "XBWInputSetting")

function XBWInputSetting:InitValue()
end

function XBWInputSetting:GetControllerMapIds()
    if not self._InputSettingShowMapIds then
        self._InputSettingShowMapIds = {}
        local ids = XMVCA.XBigWorldSet:GetBigWorldShowInputMapIds()
        for _, id in pairs(ids) do
            self._InputSettingShowMapIds[id] = true
        end
    end
    return self._InputSettingShowMapIds
end

function XBWInputSetting:GetControllerMapCfg()
    if not self._InputSettingMap then
        self._InputSettingMap = {}
        local maps = self:GetControllerMapIds()
        local allCfg = XSetConfigs.GetControllerMapCfg()
        for _id, cfg in pairs(allCfg) do
            if maps[cfg.InputMapId] then
                table.insert(self._InputSettingMap, cfg)
            end
        end
        
        table.sort(self._InputSettingMap, function(a, b)
            if a.InputMapId ~= b.InputMapId then
                return a.InputMapId < b.InputMapId
            end
            return a.Id < b.Id
        end)
    end
    return self._InputSettingMap
end

function XBWInputSetting:SetUiCallback(saveCb, resetCb, isChangeCb, cancelSaveCb)
    self.SaveCb = saveCb
    self.ResetCb = resetCb
    self.IsChangeCb = isChangeCb
    self.CancelSaveCb = cancelSaveCb
end

function XBWInputSetting:Reset()
    if self.CancelSaveCb then self.CancelSaveCb() end
end

function XBWInputSetting:RestoreDefault()
    if self.ResetCb then self.ResetCb() end
end

function XBWInputSetting:SaveChange()
    if self.SaveCb then self.SaveCb() end
end

function XBWInputSetting:IsChanged()
    if self.IsChangeCb then return self.IsChangeCb() end
    return false
end

--region Getter/Setter

--endregion

--region Init

--endregion

return XBWInputSetting
