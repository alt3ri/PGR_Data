---@class XFashionAgency : XAgency
---@field private _Model XFashionModel
local XFashionAgency = XClass(XAgency, "XFashionAgency")

function XFashionAgency:OnInit()
    --初始化一些变量
end

function XFashionAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.FashionSyncNotify = handler(self, self.FashionSyncNotify)
end

function XFashionAgency:FashionSyncNotify(data)
    XDataCenter.FashionManager.NotifyFashionDict(data)
    self:SetFashionColorDic(data)
end

function XFashionAgency:LoginNotify(data)
    self:SetFashionColorDic(data)
end

function XFashionAgency:SetFashionColorDic(data)
    self._Model:NotifyFashionColorData(data)
end

function XFashionAgency:FashionSwitchColorRequest(fashionId, colorId, cb)
    local req = { FashionId = fashionId, ColorId = colorId }
    XNetwork.Call("FashionSwitchColorRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

function XFashionAgency:InitEvent()

end

----------public start----------

function XFashionAgency:GetOwnFashionColorResourcesId(fashionId, colorId)
    if colorId == nil then
        local fashionData = XDataCenter.FashionManager.GetOwnFashionDataById(fashionId)
        colorId = fashionData and fashionData.ColorId or nil
    end
    if XTool.IsNumberValid(colorId) and colorId ~= 0 then
        return self:GetFashionColorResourcesId(colorId)
    end
    return XDataCenter.FashionManager.GetResourcesId(fashionId)
end

function XFashionAgency:GetFashionColorById(colorId)
    return self._Model:GetFashionColorById(colorId)
end

function XFashionAgency:GetFashionColorResourcesId(colorId)
    local colorConfig = self._Model:GetFashionColorById(colorId)
    return colorConfig.ResourcesId
end

function XFashionAgency:GetFashionColorHex(colorId)
    local colorConfig = self._Model:GetFashionColorById(colorId)
    return colorConfig.ColorHex
end

function XFashionAgency:GetFashionColorName(colorId)
    local colorConfig = self._Model:GetFashionColorById(colorId)
    return colorConfig.FashionName or ""
end

function XFashionAgency:GetFashionColorIcon(colorId)
    local colorConfig = self._Model:GetFashionColorById(colorId)
    return colorConfig.FashionIcon or ""
end

function XFashionAgency:GetFashionColorOriginalFashionId(colorId)
    local colorConfig = self._Model:GetFashionColorById(colorId)
    return colorConfig.OriginalFashionId
end

function XFashionAgency:IsFashionColorHas(fashionId, colorId)
    if not self._Model.ColorData then
        return false, nil
    end
    return self._Model.ColorData:IsFashionColorHas(fashionId, colorId)
end

--endregion



----------public end----------

----------private start----------


----------private end----------

return XFashionAgency
