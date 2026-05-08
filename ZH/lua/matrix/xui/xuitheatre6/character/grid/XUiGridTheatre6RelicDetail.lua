---@class XUiGridTheatre6RelicDetail : XUiNode 遗物详情
---@field _Control XTheatre6Control
---@field ImgQuality UnityEngine.UI.RawImage
---@field UiTxtName UnityEngine.UI.Text
---@field UiTxtType UnityEngine.UI.Text
---@field UiRImgIcon UnityEngine.UI.RawImage
---@field UiTxtDescEffect XUiComponent.XUiRichTextCustomRender
---@field UiTxtDesc UnityEngine.UI.Text
---@field GridTag UnityEngine.RectTransform
---@field PanelBtn UnityEngine.RectTransform
---@field BtnFreeze XUiComponent.XUiButton
---@field BtnBuy XUiComponent.XUiButton
---@field BtnSell XUiComponent.XUiButton
---@field BtnDiscard XUiComponent.XUiButton
---@field BtnRemove XUiComponent.XUiButton
---@field BtnEquip XUiComponent.XUiButton
---@field GridAttribute UnityEngine.RectTransform
---@field PanelOwn UnityEngine.RectTransform
---@field UiTxtNum UnityEngine.UI.Text
---@field BtnDescList XUiComponent.XUiButton
local XUiGridTheatre6RelicDetail = XClass(XUiNode, "XUiGridTheatre6RelicDetail")

function XUiGridTheatre6RelicDetail:OnStart()
    self:InitComponents()
end

function XUiGridTheatre6RelicDetail:InitComponents()
    if self.BtnFreeze then
        self.BtnFreeze:AddEventListener(handler(self, self.OnBtnFreezeClick))
    end
    if self.BtnBuy then
        self.BtnBuy:AddEventListener(handler(self, self.OnBtnBuyClick))
        self.BtnBuy:SetSprite(self._Control:GetCoinIcon())
    end
    self.BtnSell:SetSprite(self._Control:GetCoinIcon())
    self.UiTxtDescEffect.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
end

function XUiGridTheatre6RelicDetail:SetData(id)
    self._Id = id
    self._Config = self._Control:GetAttrPackCfgById(id)

    self:ShowBaseInfo()
    self:ShowAttribute()
    self:ShowDesc()
    self:ShowBuildTag()
    self:ShowOwn()
end

---@param cb fun(tagId:number, allTagConfigs:XTableTheatre6BuildTag[], keyWordIds:number[])
function XUiGridTheatre6RelicDetail:SetClickBuildTagCb(cb)
    self._ClickBuildTagCb = cb
end

function XUiGridTheatre6RelicDetail:ShowBaseInfo()
    local spriteName = self._Control:GetQualityIcon(self._Config.Quality)
    self.ImgQuality:SetRawImage(spriteName)
    self.UiTxtName.text = self._Config.Name
    self.UiTxtType.text = XUiHelper.GetText("Theatre6AttrPackTypeName")
    self.UiRImgIcon:SetSprite(self._Config.Icon)
end

function XUiGridTheatre6RelicDetail:ShowAttribute()
    local attrConfigs, attrValues = self._Control:GetShowAttribute(self._Config.AttrTypes, self._Config.AttrNums)
    self._AttrGrids = XUiHelper.RefreshUiObjectList(self._AttrGrids, self.GridAttribute.parent, self.GridAttribute, #attrConfigs, function(i, grid)
        local config = attrConfigs[i]
        local attrValue = attrValues[i]
        grid.ImgIcon:SetSprite(config.Icon)
        if attrValue >= 0 then
            grid.TxtName.text = string.format("%s + %s", config.Name, self._Control:FormatNumberWithUnit(attrValue))
        else
            grid.TxtName.text = string.format("%s %s", config.Name, self._Control:FormatNumberWithUnit(attrValue))
        end
    end)
end

function XUiGridTheatre6RelicDetail:ShowDesc()
    self.UiTxtDescEffect.text = self._Control:GetAttrPackDesc(self._Id, false)
    self.UiTxtDesc.text = self._Config.PlotDesc
    if self.BtnBuy then
        self.BtnBuy:SetNameByGroup(0, self._Config.BuyPrice)
    end
end

function XUiGridTheatre6RelicDetail:ShowBuildTag()
    local buildTagConfigs = self._Control:GetShowBuildTagWithSort(self._Config.BuildTags)
    local keyWordIds = self._Config.KeyWordIds
    self._TagGrids = XUiHelper.RefreshUiObjectList(self._TagGrids, self.GridTag.parent, self.GridTag, #buildTagConfigs,
        function(i, grid)
            local config = buildTagConfigs[i]
            grid.ImgIcon:SetSprite(config.Icon)
            grid.TxtName.text = config.Name
            grid.GridTag:AddEventListener(function()
                if self._ClickBuildTagCb then
                    self._ClickBuildTagCb(config.Id, buildTagConfigs, keyWordIds)
                end
            end)
        end)
end

function XUiGridTheatre6RelicDetail:ShowOwn(count)
    if not count then
        self.PanelOwn.gameObject:SetActiveEx(false)
        return
    end
    self.PanelOwn.gameObject:SetActiveEx(self._Control:IsOwnRelic(self._Id) and count > 1)
    self.UiTxtNum.text = count
end

function XUiGridTheatre6RelicDetail:SetBtnStatus(params)
    local readOnly = true
    if params then
        self.IsLock = params.IsLock or false
        self.IsInShop = params.IsInShop or false
        self.Pos = params.Pos or 0
        readOnly = params.ReadOnly ~= nil and params.ReadOnly or false
    end
    self:SetBtnFreezeVisible(false)
    self:SetBtnBuyVisible(false)
    self.BtnSell.gameObject:SetActiveEx(false)
    self.BtnDiscard.gameObject:SetActiveEx(false)
    self.BtnRemove.gameObject:SetActiveEx(false)
    self.BtnEquip.gameObject:SetActiveEx(false)
    self:SetPanelBtnVisible(not readOnly)

    if not readOnly then
        self:SetBtnFreezeVisible(self.IsInShop, self.IsLock and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        self:SetBtnBuyVisible(self.IsInShop)
        self.PanelOwn.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre6RelicDetail:OnBtnFreezeClick()
    self._Control:ShopGoodLockRequest(self.Pos, self.IsLock, function(lockStatus)
        self.Parent:Close()
    end)
end

function XUiGridTheatre6RelicDetail:OnBtnBuyClick()
    self._Control:BuyRelicGood(self._Id, self.Pos, function()
        self.Parent:Close()
    end)
end

function XUiGridTheatre6RelicDetail:Refresh(id, param)
    self:SetData(id)
    self:SetBtnStatus(param)
end

function XUiGridTheatre6RelicDetail:SetBtnBuyVisible(isVisible)
    if not self.BtnBuy then
        return
    end
    self.BtnBuy.gameObject:SetActiveEx(isVisible)
end

function XUiGridTheatre6RelicDetail:SetBtnFreezeVisible(isVisible, buttonStatus)
    if not self.BtnFreeze then
        return
    end
    self.BtnFreeze.gameObject:SetActiveEx(isVisible)
    if buttonStatus then
        self.BtnFreeze:SetButtonState(buttonStatus)
    end
end

function XUiGridTheatre6RelicDetail:SetPanelBtnVisible(isVisible)
    if not self.PanelBtn then
        return
    end
    self.PanelBtn.gameObject:SetActiveEx(isVisible)
end

return XUiGridTheatre6RelicDetail
