local XUiFightComic2 = XLuaUiManager.Register(XLuaUi,  "UiFightComic2")

function XUiFightComic2:OnStart(tipsId)
    self.TxtComic.text = CS.XTextManager.GetText(tipsId)
end

function XUiFightComic2:CloseDetailWithAnimation()
    self:PlayAnimation("AnimDisable", function()
        self:Close()
    end)
end

return XUiFightComic2