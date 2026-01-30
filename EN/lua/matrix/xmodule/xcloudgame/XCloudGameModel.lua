local TableKey = {
    CloudGameConfig = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private, ReadFunc = XConfigUtil.ReadType.String },
}

---@class XCloudGameModel : XModel
local XCloudGameModel = XClass(XModel, "XCloudGameModel")

function XCloudGameModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("CloudGame", TableKey)
end

function XCloudGameModel:ClearPrivate()
end

function XCloudGameModel:ResetAll()
end

function XCloudGameModel:GetConfig(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CloudGameConfig, key)
end

return XCloudGameModel