---@class XUiPanelGuideBubble: XUiNode
local XUiPanelGuideBubble = XClass(XUiNode, 'XUiPanelGuideBubble')
local XUiGridGuideBubble = require('XUi/XUiGuide/XUiGridGuideBubble')

function XUiPanelGuideBubble:OnStart()
    ---@type XUiGridGuideBubble[]
    self._BubbleGrids = {}

    for i = 1, 4 do
        local go = self['PanelBubble' .. i]

        if go then
            go.gameObject:SetActiveEx(false)
            self._BubbleGrids[i] = XUiGridGuideBubble.New(go, self)
            self._BubbleGrids[i]:Close()
        end
    end
end

function XUiPanelGuideBubble:ShowBubble(index, textCfg, bubblePosOffset)
    if self._CurIndex then
        local curGrid = self._BubbleGrids[self._CurIndex]

        if curGrid then
            curGrid:Close()
        end
    end
    
    self._CurIndex = index

    local curGrid = self._BubbleGrids[self._CurIndex]

    if curGrid then
        curGrid:Open()
        curGrid:SetContent(textCfg.Content)
        
        local rootRotateX, rootRotateY, rootRotateZ = self.Parent.BtnPass.transform:GetLocalRotation()
        
        curGrid:SetRotateZ(- rootRotateZ)
        curGrid:SetLoccalPosOffset(bubblePosOffset)
    end
end

return XUiPanelGuideBubble