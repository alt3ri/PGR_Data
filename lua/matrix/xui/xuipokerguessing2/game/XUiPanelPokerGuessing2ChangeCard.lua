--- 改牌的界面
---@class XUiPanelPokerGuessing2ChangeCard: XUiNode
---@field protected _Control XPokerGuessing2Control
local XUiPanelPokerGuessing2ChangeCard = XClass(XUiNode, 'XUiPanelPokerGuessing2ChangeCard')
local XUiGridPokerGuessing2ChangeCard = require('XUi/XUiPokerGuessing2/Game/XUiGridPokerGuessing2ChangeCard')

function XUiPanelPokerGuessing2ChangeCard:OnStart(btnMask)
    self.BtnClose = btnMask
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClickEvent))
    
    self.GridSmallCard.gameObject:SetActiveEx(false)
    self.CardGrids = {}
end

function XUiPanelPokerGuessing2ChangeCard:OnEnable()
    self.BtnClose.gameObject:SetActiveEx(true)
end

function XUiPanelPokerGuessing2ChangeCard:OnDisable()
    self.BtnClose.gameObject:SetActiveEx(false)

    self.PanelBigCardPlayer.transform:SetAsLastSibling()
    self.PanelBigCardEnemy.transform:SetAsLastSibling()
end

function XUiPanelPokerGuessing2ChangeCard:OnBtnCloseClickEvent()
    self:Close()
end

function XUiPanelPokerGuessing2ChangeCard:RefreshShowWithSide(isPlayerSide, originId)
    self._OriginId = originId
    self._IsPlayerSide = isPlayerSide
    
    -- 设置位置
    if isPlayerSide then
        self.PanelBigCardEnemy.transform:SetAsFirstSibling()
        
        self.Transform.position = self.SelfChangePanelPos.transform.position
    else
        self.PanelBigCardPlayer.transform:SetAsFirstSibling()
        
        self.Transform.position = self.EnemyChangePanelPos.transform.position
    end
    
    -- 刷新显示可改的牌
    local cardGroup = self._Control:GetCardGroup()

    if not XTool.IsTableEmpty(self.CardGrids) then
        for i, v in pairs(self.CardGrids) do
            v:Close()
        end
    end
    
    XUiHelper.RefreshCustomizedList(self.ListCard.transform, self.GridSmallCard, cardGroup and #cardGroup or 0, function(index, go)
        local grid = self.CardGrids[go]

        if not grid then
            grid = XUiGridPokerGuessing2ChangeCard.New(go, self)
            self.CardGrids[go] = grid
        end
        
        grid:Open()
        grid:Refresh(cardGroup[index])
    end)
end

function XUiPanelPokerGuessing2ChangeCard:OnChangeCardClick(changeId)
    if XTool.IsNumberValid(changeId) then
        self._Control:TrySummitSkillChange(self._IsPlayerSide, self._OriginId, changeId, function() 
            self:Close()
        end)
    end
end

return XUiPanelPokerGuessing2ChangeCard