---@class XFashionControl : XControl
---@field private _Model XFashionSuitModel
local XFashionControl = XClass(XControl, "XFashionControl")

XFashionControl.FashionSuitType = {
    Lock = 1,
    Unlock = 2,
}

XFashionControl.FashionType = {
    Normal = 0, -- 普通时装
    Weapon = 1, -- 武器投影
    Color = 2,  -- FashionColor（涂装换色）
}
function XFashionControl:OnInit()

end

function XFashionControl:AddAgencyEvent()

end

function XFashionControl:RemoveAgencyEvent()

end

function XFashionControl:OnRelease()

end

function XFashionControl:GetFashionColorResourcesId(colorId)
    local colorConfig = self._Model:GetFashionColorById(colorId)
    return colorConfig.ResourcesId
end

function XFashionControl:GetFashionColorName(colorId)
    local colorConfig = self._Model:GetFashionColorById(colorId)
    return colorConfig.FashionName or ""
end



function XFashionControl:UseFashion(fashionId, colorId, cb)
    --当前时装是否穿戴，如果是则直接切换颜色
    local status = XDataCenter.FashionManager.GetFashionStatus(fashionId)
    local fashionStatus = XDataCenter.FashionManager.FashionStatus
    if status == fashionStatus.Dressed then
        self:SwitchColor(fashionId, colorId, cb)
        return
    end
    --未穿戴则穿戴时装
    XDataCenter.FashionManager.UseFashion(fashionId, function()
        --穿戴时装后，colorId不为空则切换颜色
        if colorId ~= nil then
            self:SwitchColor(fashionId, colorId, cb)
        else
            if cb then
                cb()
            end
        end
    end)
end


function XFashionControl:SwitchColor(fashionId, colorId, cb)
    if colorId == nil then
        if cb then
            cb()
        end
        return
    end

    if colorId ~= 0 and not self._Model.ColorData:IsFashionColorHas(fashionId, colorId) then
        XUiManager.TipText("FashionColorLock")
        if cb then
            cb()
        end
        return
    end
    XMVCA.XFashion:FashionSwitchColorRequest(fashionId, colorId, cb)
end

return XFashionControl
