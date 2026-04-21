--- 控制对应章节背景图的节点
---@class XUiLineArithmetic3.XUiPanelFurnitureBG: XUiNode
---@field protected _Control XLineArithmetic3Control
---@field Parent
local XUiPanelFurnitureBG = XClass(XUiNode, "XUiPanelFurnitureBG")

function XUiPanelFurnitureBG:SetChapterBgShow(chapterIndex, isUnlock)
    local prex = "Furniture" .. tostring(chapterIndex) .. '_'
    local color = self:_GetChapterBgColor(isUnlock)
    
    for i = 1, 10 do
        local ui = self[prex .. i]

        if ui then
            ui.color = color
        else
            break
        end
    end
end

---@return UnityEngine.Color
function XUiPanelFurnitureBG:_GetChapterBgColor(isUnlock)
    local colorStr = self._Control:GetClientConfigText('UiMainChapterBgColor', isUnlock and 1 or 2)

    if not string.IsNilOrEmpty(colorStr) then
        colorStr = string.gsub(colorStr, "#", "")
    
        return XUiHelper.Hexcolor2Color(colorStr) or CS.UnityEngine.Color.white
    end
    
    return CS.UnityEngine.Color.white
end

return XUiPanelFurnitureBG