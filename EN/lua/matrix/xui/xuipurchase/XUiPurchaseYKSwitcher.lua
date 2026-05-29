local XUiPurchaseYKSwitcher = XClass(XUiNode, "XUiPurchaseYKSwitcher")

function XUiPurchaseYKSwitcher:Ctor(ui, root, card1, card2, selectCard2)
    self._Card1 = card1
    self._Card2 = card2
    self._SelectCard2 = selectCard2
    self.PanelPageL.CallBack = handler(self, self._Switch)
    self.PanelPageR.CallBack = handler(self, self._Switch)

    self._Dot1 = { Transform = self.GridDot }
    self._Dot2 = { Transform = XUiHelper.Instantiate(self.GridDot, self.PanelPageDot) }
    XTool.InitUiObject(self._Dot1)
    XTool.InitUiObject(self._Dot2)
end

function XUiPurchaseYKSwitcher:_Refresh()
    local sel2 = self._SelectCard2
    local sel1 = not sel2
    self._Card1.gameObject:SetActive(sel1)
    self._Card2.gameObject:SetActive(sel2)
    self._Dot1.ImgOff.gameObject:SetActive(sel2)
    self._Dot1.ImgOn.gameObject:SetActive(sel1)
    self._Dot2.ImgOff.gameObject:SetActive(sel1)
    self._Dot2.ImgOn.gameObject:SetActive(sel2)
end

function XUiPurchaseYKSwitcher:_Switch()
    self:Select(not self._SelectCard2)
end

function XUiPurchaseYKSwitcher:Select(selectCard2)
    self._SelectCard2 = selectCard2
    self:_Refresh()
end

return XUiPurchaseYKSwitcher
