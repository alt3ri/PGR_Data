---@class XUiSkyGardenShoppingStreetInsideBuildGridFeedback : XUiNode
---@field RImgHeadIcon UnityEngine.UI.RawImage
---@field TxtFeedback UnityEngine.UI.Text
---@field ImgComplete UnityEngine.UI.Image
local XUiSkyGardenShoppingStreetInsideBuildGridFeedback = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildGridFeedback")

--region 生命周期
function XUiSkyGardenShoppingStreetInsideBuildGridFeedback:OnStart(...)
    self:_RegisterButtonClicks()

    if self.ImgComplete then
        self.ImgComplete.gameObject:SetActive(false)
    end
end
--endregion

function XUiSkyGardenShoppingStreetInsideBuildGridFeedback:Update(data, i)
    if type(data) == "string" then
        self.Paneltalk.gameObject:SetActive(false)
        self.PanelNone.gameObject:SetActive(true)
        self.TxtNone.text = XMVCA.XBigWorldService:GetText("SG_SS_NoFeedback")
        return
    elseif type(data) == "number" then
        if self.Paneltalk then
            self.Paneltalk.gameObject:SetActive(true)
        end
        if self.PanelNone then
            self.PanelNone.gameObject:SetActive(false)
        end

        local reviewCfg = self._Control:GetReviewConfigById(data)
        if self.TxtFeedback then
            self.TxtFeedback.text = reviewCfg.Desc
        end
        if self.TxtGoodFeedback then
            local isGood = reviewCfg.Type == 1
            self.GoodPanelImg.gameObject:SetActive(isGood)
            self.BadPanelImg.gameObject:SetActive(not isGood)
            self.TxtGoodFeedback.gameObject:SetActive(isGood)
            self.TxtBadFeedback.gameObject:SetActive(not isGood)
            if isGood then
                self.TxtGoodFeedback.text = reviewCfg.Desc
            else
                self.TxtBadFeedback.text = reviewCfg.Desc
            end
        end
        self:SetNpcIcon(data)
        return
    end
    if self.Paneltalk then
        self.Paneltalk.gameObject:SetActive(true)
    end
    if self.PanelNone then
        self.PanelNone.gameObject:SetActive(false)
    end

    local parentFunc = self.Parent and self.Parent.GetShopId
    local shopId
    if parentFunc then
        shopId = parentFunc(self.Parent)
    else
        shopId = data.TargetId or data.ShopId
    end
    local desc = self._Control:ParseFeedback(data, shopId)
    self.TxtFeedback.text = desc
    if self.PanelBar then
        local feedbackCfg = self._Control:GetFeedbackConfigsById(data.FeedbackTemplateId)
        if self.ImgBar then
            self.ImgBar.fillAmount = math.min(feedbackCfg.Star / 5, 1)
        end
        local starDiff = data.StarDifference or 0
        if self.ImgUp then
            if starDiff ~= 0 then
                self.ImgUp.gameObject:SetActive(starDiff > 0)
                self.ImgDown.gameObject:SetActive(starDiff < 0)
            else
                self.ImgUp.gameObject:SetActive(false)
                self.ImgDown.gameObject:SetActive(false)
            end
        end
    end

    if data.CustomerId then
        self:SetNpcIcon(data.CustomerId)
    else
        if data.FeedbackTemplateId then
            if not data.Id then
                data.Id = math.random(1, 100)
            end
            self:SetFeedbackIcon(data.FeedbackTemplateId, data.Id)
        end
    end
end

function XUiSkyGardenShoppingStreetInsideBuildGridFeedback:SetNpcIcon(npcId)
    self.RImgHeadIcon:SetRawImage(self._Control:GetCustomerHeadIcon(npcId))
end

function XUiSkyGardenShoppingStreetInsideBuildGridFeedback:SetFeedbackIcon(FeedbackTemplateId, randId)
    self.RImgHeadIcon:SetRawImage(self._Control:GetCustomerFeedHeadIcon(FeedbackTemplateId, randId))
end
--region 私有方法
function XUiSkyGardenShoppingStreetInsideBuildGridFeedback:_RegisterButtonClicks()
    --在此处注册按钮事件
end
--endregion

return XUiSkyGardenShoppingStreetInsideBuildGridFeedback
