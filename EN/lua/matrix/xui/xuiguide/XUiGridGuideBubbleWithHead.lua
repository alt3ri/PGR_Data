---@class XUiGridGuideBubbleWithHead : XUiGridGuideBubble
local XUiGridGuideBubble = require('XUi/XUiGuide/XUiGridGuideBubble')
local XUiGridGuideBubbleWithHead = XClass(XUiGridGuideBubble, 'XUiGridGuideBubbleWithHead')

function XUiGridGuideBubbleWithHead:SetImgIcon(iconId)
    if not iconId or iconId == 0 then
        return
    end
    local iconPath = XDataCenter.GuideManager.GetGuideIcon(iconId)
    if not iconPath or string.IsNilOrEmpty(iconPath) then
        return
    end
    
    self.ImgRole:SetSprite(iconPath)
end

return XUiGridGuideBubbleWithHead
