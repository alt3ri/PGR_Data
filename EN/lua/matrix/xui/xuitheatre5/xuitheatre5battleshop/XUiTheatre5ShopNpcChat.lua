--- 商店npc说话
---@class XUiTheatre5ShopNpcChat: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5ShopNpcChat = XClass(XUiNode, 'XUiTheatre5ShopNpcChat')

function XUiTheatre5ShopNpcChat:OnStart()
    local isPvp = self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP

    self.ListCup.gameObject:SetActiveEx(isPvp)
    self.ListStar.gameObject:SetActiveEx(not isPvp)
end

function XUiTheatre5ShopNpcChat:OnEnable()
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_GOLD_SHOW, self.RefreshCoinShow, self)
end

function XUiTheatre5ShopNpcChat:OnDisable()
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_GOLD_SHOW, self.RefreshCoinShow, self)
end

function XUiTheatre5ShopNpcChat:OnDestroy()
    
end

return XUiTheatre5ShopNpcChat