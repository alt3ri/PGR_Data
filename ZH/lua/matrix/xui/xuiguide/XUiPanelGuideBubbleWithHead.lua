---@class XUiPanelGuideBubbleWithHead : XUiNode
local XUiPanelGuideBubbleWithHead = XClass(XUiNode, 'XUiPanelGuideBubbleWithHead')
local XUiGridGuideBubbleWithHead = require('XUi/XUiGuide/XUiGridGuideBubbleWithHead')

function XUiPanelGuideBubbleWithHead:OnStart()
    ---@type XUiGridGuideBubbleWithHead[]
    self._BubbleGrids = {}

    for i = 1, 4 do
        local go = self['PanelBubble' .. i]

        if go then
            go.gameObject:SetActiveEx(false)
            self._BubbleGrids[i] = XUiGridGuideBubbleWithHead.New(go, self)
            self._BubbleGrids[i]:Close()
        end
    end
end

function XUiPanelGuideBubbleWithHead:ShowBubble(index, textCfg, bubblePosOffset, imgIconId)
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

        curGrid:SetRotateZ(-rootRotateZ)
        curGrid:SetLoccalPosOffset(bubblePosOffset)
        curGrid:SetImgIcon(imgIconId)
    end
end

return XUiPanelGuideBubbleWithHead
