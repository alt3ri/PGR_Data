---@class XFashionColor
local XFashionColor = XClass(nil, "XFashionColor")

local FashionColorDic = {} -- key:fashionId value:colorId
function XFashionColor:Ctor()
end

function XFashionColor:NotifyFashionColorData(data)
    FashionColorDic = FashionColorDic or {}
    for id, colors in pairs(data.FashionColors) do
        for index, color in ipairs(colors) do
            FashionColorDic[id] = FashionColorDic[id] or {}
            if color and not table.contains(FashionColorDic[id], color) then
                table.insert(FashionColorDic[id], color)
            end
        end
    end
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

function XFashionColor:ClearData()
    FashionColorDic = nil
end

return XFashionColor
