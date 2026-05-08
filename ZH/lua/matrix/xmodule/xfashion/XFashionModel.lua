---@class XFashionModel : XModel
local XFashionModel = XClass(XModel, "XFashionModel")

local TableKey = {
    FashionColor = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Share},
}

function XFashionModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fashion", TableKey)
end

function XFashionModel:ClearPrivate()
end

function XFashionModel:ResetAll()

end

----------public start----------


----------public end----------

----------private start----------

function XFashionModel:NotifyFashionColorData(data)
   if not data or not data.FashionColors then
        XLog.Error("XFashionColor:NotifyFashionColorData data is nil or data.FasionColors is nil")
        return
    end
    if not self.ColorData then
        self.ColorData = require("XModule/XFashion/XEntity/XFashionColor").New()
    end
    self.ColorData:NotifyFashionColorData(data)
end

----------private end----------

----------config start----------



---@return XTableFashionColor
function XFashionModel:GetFashionColorById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FashionColor, id)
end

---@return XTableFashionColor[]
function XFashionModel:GetFashionColorConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.FashionColor)
end


----------config end----------


return XFashionModel