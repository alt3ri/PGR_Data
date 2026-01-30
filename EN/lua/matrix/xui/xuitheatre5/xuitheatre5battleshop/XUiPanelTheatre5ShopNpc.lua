---@class XUiPanelTheatre5ShopNpc: XUiNode
---@field private _Control XTheatre5Control
---@field Parent XUiTheatre5BattleShop
local XUiPanelTheatre5ShopNpc = XClass(XUiNode, 'XUiPanelTheatre5ShopNpc')

function XUiPanelTheatre5ShopNpc:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnNpc, self.OnClickNpc,true,true,0.5) --限制频繁点击对话
    self.PanelTalk.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre5ShopNpc:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SHOP_BUY, self.OnShopBuy, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SHOP_SELL, self.OnShopSell, self)
end

function XUiPanelTheatre5ShopNpc:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SHOP_BUY, self.OnShopBuy, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SHOP_SELL, self.OnShopSell, self)
end

function XUiPanelTheatre5ShopNpc:OnClickNpc()
    local npcChatCfg = self._Control.ShopControl:GetShopChatCfg(XMVCA.XTheatre5.EnumConst.ShopNpcTriggerChatType.Click)
    self:UpdateNpcChat(npcChatCfg)
end

function XUiPanelTheatre5ShopNpc:OnShopBuy()
    local npcChatCfg = self._Control.ShopControl:GetShopChatCfg(XMVCA.XTheatre5.EnumConst.ShopNpcTriggerChatType.Buy)
    self:UpdateNpcChat(npcChatCfg)
end

function XUiPanelTheatre5ShopNpc:OnShopSell()
    local npcChatCfg = self._Control.ShopControl:GetShopChatCfg(XMVCA.XTheatre5.EnumConst.ShopNpcTriggerChatType.Sell)
    self:UpdateNpcChat(npcChatCfg)
end

function XUiPanelTheatre5ShopNpc:UpdateNpcChat(npcChatCfg)
    self.PanelTalk.gameObject:SetActiveEx(npcChatCfg ~= nil)
    if not npcChatCfg then
        return
    end
    self.TxtTalk.text = npcChatCfg.Chat   
end

return XUiPanelTheatre5ShopNpc