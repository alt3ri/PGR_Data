---@class XUiGridDyeMergeColorTips: XUiNode
---@field protected _Control
---@field Parent
local XUiGridDyeMergeColorTips = XClass(XUiNode, "XUiGridDyeMergeColorTips")

---@param icons string[]
function XUiGridDyeMergeColorTips:RefreshIcons(icons)
    for i = 1, 10 do
        local ui = self["RImgColor" .. i]

        if ui then
            if not string.IsNilOrEmpty(icons[i]) then
                ui.gameObject:SetActiveEx(true)
                ui:SetRawImage(icons[i])
            else
                ui.gameObject:SetActiveEx(false)    
            end
        else
            -- 索引是连续的
            break
        end
    end
end

return XUiGridDyeMergeColorTips