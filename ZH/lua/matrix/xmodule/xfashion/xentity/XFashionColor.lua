---@class XFashionColor
local XFashionColor = XClass(nil, "XFashionColor")

local FashionColorDic = {} -- key:fashionId value:colorId
function XFashionColor:Ctor()
end

function XFashionColor:NotifyFashionColorData(data)
    FashionColorDic = data.FashionColors or {}
end

function XFashionColor:GetFashionColorIds(fashionId)
    local colorIds = FashionColorDic[fashionId]
    return colorIds or {}
end

function XFashionColor:IsFashionColorHas(fashionId, colorId)
    local colorIds = self:GetFashionColorIds(fashionId)
    if not colorIds or not table.contains(colorIds, colorId) then
        return false, nil
    end
    return true, colorId
end

return XFashionColor
