local XUiLeftTip = XLuaUiManager.Register(XLuaUi, "UiLeftTip")

function XUiLeftTip:OnStart(content, closeCb, setMask)
    self.TxtDes.text = content
    self.CloseCb = closeCb
    self.SetMask = setMask
end

function XUiLeftTip:OnEnable()
    if self.SetMask then
        self:PlayAnimationWithMask("AnimShow", function()
            self:CloseSelf()
        end)
    else
        self:PlayAnimation("AnimShow", function()
            self:CloseSelf()
        end)
    end
end

function XUiLeftTip:CloseSelf()
    if not self.GameObject.activeInHierarchy then return end
    self:Close()
    if self.CloseCb then self.CloseCb() end
end

return XUiLeftTip