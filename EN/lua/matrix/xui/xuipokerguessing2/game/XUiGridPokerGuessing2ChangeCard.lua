--- 修改界面里显示的牌
---@class XUiGridPokerGuessing2ChangeCard: XUiNode
---@field protected _Control XPokerGuessing2Control
local XUiGridPokerGuessing2ChangeCard = XClass(XUiNode, 'XUiGridPokerGuessing2ChangeCard')

function XUiGridPokerGuessing2ChangeCard:OnStart()
    self.GridBtn:AddEventListener(handler(self, self.OnClickEvent))
end

function XUiGridPokerGuessing2ChangeCard:Refresh(cardId)
    self.CardId = cardId
    
    local imgPath = self._Control:GetPokerGuessing2CardSmallAssetPathById(cardId)

    if not string.IsNilOrEmpty(imgPath) then
        self.ImgBg:SetImage(imgPath)
    end
end

function XUiGridPokerGuessing2ChangeCard:OnClickEvent()
    self.Parent:OnChangeCardClick(self.CardId)
end

return XUiGridPokerGuessing2ChangeCard