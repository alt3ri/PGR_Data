local XUiGridReviewItem = XClass(nil, "XUiGridReviewItem")

function XUiGridReviewItem:Ctor(ui, data,cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ReviewCallBack = cb
    self.CueId = data.CueId or 0
    XTool.InitUiObject(self)
    self.BtnReview.gameObject:SetActiveEx(self.CueId ~= 0)
    self.BtnReview.CallBack = function() self:OnClickBtnReview() end
    self.TxtWords.onLinkClick = function(arg) self:OnClickTxtWords(arg) end
    if XOverseaManager.IsJP_KRRegion() or XOverseaManager.IsENRegion() and not self.contentSizeFitter then
        self.contentSizeFitter = self.TxtWords:GetComponent("TextContentSizeFitter")
    end
    self:Refresh(data)
end

function XUiGridReviewItem:OnClickBtnReview()
    if self.ReviewCallBack then
        self.ReviewCallBack(self.CueId)
    end
end

function XUiGridReviewItem:OnClickTxtWords(arg)
    XLuaUiManager.Open("UiMovieKeywordTips", arg)
end

function XUiGridReviewItem:Refresh(data)
    self.TxtWords.text = tostring(data.RoleName) .. tostring(data.Content)
    if XOverseaManager.IsJP_KRRegion() or XOverseaManager.IsENRegion() then
        self:AutoSetTextWidth()
    end
end

function XUiGridReviewItem:SetTextColor(color)
    self.TxtWords.color = color
end

function XUiGridReviewItem:GetTextColor()
    return self.TxtWords.color
end

function XUiGridReviewItem:AutoSetTextWidth()
    --延迟一帧以获取Text准确宽度值
    XScheduleManager.ScheduleOnce(function()
        if self.GameObject == nil or self.GameObject:Exist() == false then
            return
        end
        --MASK的宽度应大于TxtName加TxtWords宽度值,否则会爆框
        local maskWidth = self.Transform.parent.parent:GetComponent(typeof(CS.UnityEngine.RectTransform)).rect.width - 150
        if self.TxtName.rectTransform.rect.width + self.TxtWords.rectTransform.rect.width > maskWidth then
        local width = maskWidth - self.TxtName.rectTransform.rect.width
        self.contentSizeFitter:SetWrapWidth(width)
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.TxtWords.rectTransform);
        end
    end, 100)
end

return XUiGridReviewItem