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
    
    -- 获取并缓存两个 Panel 的 Canvas 组件
    self._CanvasPlayer = XUiHelper.TryGetComponent(self.PanelBigCardPlayer.transform, "", "Canvas")
    self._CanvasEnemy = XUiHelper.TryGetComponent(self.PanelBigCardEnemy.transform, "", "Canvas")
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
    
    -- 通过交换 Canvas 的 sortingOrder 来控制层级
    if self._CanvasPlayer and self._CanvasEnemy then
        local playerOrder = self._CanvasPlayer.sortingOrder
        local enemyOrder = self._CanvasEnemy.sortingOrder
        
        -- 判断原本哪个order更高
        local needSwap = false
        if not isPlayerSide then
            -- 玩家侧：需要 Enemy 在上层（order更高）
            -- 如果原本 Player 的 order 更高，需要交换
            if playerOrder > enemyOrder then
                needSwap = true
            end
        else
            -- 敌人侧：需要 Player 在上层（order更高）
            -- 如果原本 Enemy 的 order 更高，需要交换
            if enemyOrder > playerOrder then
                needSwap = true
            end
        end
        
        -- 如果需要交换，则交换两个 Canvas 的 sortingOrder
        if needSwap then
            local temp = playerOrder
            self._CanvasPlayer.sortingOrder = enemyOrder
            self._CanvasEnemy.sortingOrder = temp
        end
    end

    -- 设置位置
    if isPlayerSide then
        self.Transform.position = self.SelfChangePanelPos.transform.position
    else
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