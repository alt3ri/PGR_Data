local XBigWorldModel = require("XModule/XBigWorld/XBigWorldModel")

local GuideTableKey = {
    SkyGardenGuideText = "Client/BigWorld/SkyGarden/Guide/SkyGardenGuideText.tab",
    SkyGardenGuideIcon = "Client/BigWorld/SkyGarden/Guide/SkyGardenGuideIcon.tab",
}

---@class XSkyGardenModel : XBigWorldModel
local XSkyGardenModel = XClass(XBigWorldModel, "XSkyGardenModel")
function XSkyGardenModel:OnInit()
    XBigWorldModel.OnInit(self)

    local identifier = "Id"
    local readInt = XConfigUtil.ReadType.Int
    local config = {
        [GuideTableKey.SkyGardenGuideText] = {
            readInt,
            XTable.XTableGuideText,
            identifier,
            XConfigUtil.CacheType.Normal,
        },
        [GuideTableKey.SkyGardenGuideIcon] = {
            readInt,
            XTable.XTableGuideIcon,
            identifier,
            XConfigUtil.CacheType.Normal,
        }
    }
    self._ConfigUtil:InitConfig(config)
end

function XSkyGardenModel:ClearPrivate()
    XBigWorldModel.ClearPrivate(self)
end

function XSkyGardenModel:ResetAll()
    XBigWorldModel.ResetAll(self)
end

---@return string
function XSkyGardenModel:GetGuideIcon(iconId)
    local t = self._ConfigUtil:GetCfgByPathAndIdKey(GuideTableKey.SkyGardenGuideIcon, iconId)
    return t.Image
end

---@return XTableGuideText
function XSkyGardenModel:GetGuideTextTemplate(textId)
    return self._ConfigUtil:GetCfgByPathAndIdKey(GuideTableKey.SkyGardenGuideText, textId)
end

return XSkyGardenModel