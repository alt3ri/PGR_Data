---@class XUiSkyGardenShoppingStreetBuildGridAttribute : XUiNode
---@field ImgAttribute UnityEngine.UI.Image
---@field TxtDetailNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetBuildGridAttribute = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuildGridAttribute")
local XUiSkyGardenShoppingStreetEmpty = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetEmpty")

function XUiSkyGardenShoppingStreetBuildGridAttribute:OnStart()
    if self.TipsCloseArea then
        self.TipsCloseArea.gameObject:SetActive(false)
    end
    if self.ImgDetail then
        self.ImgDetail:AddEventListener(handler(self, self.ShowBubbleTips))
    end
    self._TxtNum = self.TxtDetailNum or self.TxtNum
end

function XUiSkyGardenShoppingStreetBuildGridAttribute:Update(data)
    local resCfgs = self._Control:GetStageResConfigs()
    local resCfg = resCfgs[data.ResConfigId]
    self.ImgAttribute:SetSprite(resCfg.Icon)
    if resCfg.IconColor then
        self.ImgAttribute.color = XUiHelper.Hexcolor2Color(resCfg.IconColor)
    end
    local isStarShow = 30001 == resCfg.Id
    if data.BaseValue then
        if not self._IconList then self._IconList = {} end
        if isStarShow then
            local count = self._Control:GetShopCustomerStar(data.ShopId, data.Value)
            if count <= 0 then
                self:Close()
                return
            end
            count = math.min(count, 10)
            local array = {}
            for i = 1, count do
                table.insert(array, 1)
            end
            XTool.UpdateDynamicItem(self._IconList, array, self.ImgAttribute.gameObject, XUiSkyGardenShoppingStreetEmpty, self)
            if count == 1 then
                self._TxtNum.text = ""
            else
                self._TxtNum.text = "+"
                self._TxtNum.color = CS.UnityEngine.Color.black
                -- self._TxtNum.gameObject.transform:SetSiblingIndex(count)
                for j = 1, count - 1 do
                    self._IconList[j].Transform:SetAsFirstSibling()
                end
            end
        else
            XTool.UpdateDynamicItem(self._IconList, nil, self.ImgAttribute.gameObject, XUiSkyGardenShoppingStreetEmpty, self)
            local baseInfo = self._Control:GetValueByResConfig(data.BaseValue, resCfg)
            local addInfo = self._Control:GetValueByResConfig(data.Value - data.BaseValue, resCfg)
            if not string.IsNilOrEmpty(resCfg.FormatStr) then
                baseInfo = string.format(resCfg.FormatStr, baseInfo)
                addInfo = string.format(resCfg.FormatStr, addInfo)
            end
            if data.BaseValue > 0 then
                self._TxtNum.text = baseInfo .. "+" .. addInfo
            else
                self._TxtNum.text = "+" .. addInfo
            end
            self._TxtNum.color = XUiHelper.Hexcolor2Color(resCfg.Color)
        end
    else
        if not self._IconList then self._IconList = {} end
        if isStarShow then
            local count = self._Control:GetShopCustomerStar(data.ShopId, data.Value)
            if count <= 0 then
                self:Close()
                return
            end
            count = math.min(count, 10)
            local array = {}
            for i = 1, count do
                table.insert(array, 1)
            end
            XTool.UpdateDynamicItem(self._IconList, array, self.ImgAttribute.gameObject, XUiSkyGardenShoppingStreetEmpty, self)
            self._TxtNum.text = ""
        else
            XTool.UpdateDynamicItem(self._IconList, nil, self.ImgAttribute.gameObject, XUiSkyGardenShoppingStreetEmpty, self)
            
            local textInfo = self._Control:GetValueByResConfig(data.Value, resCfg)
            if not string.IsNilOrEmpty(resCfg.FormatStr) then
                textInfo = string.format(resCfg.FormatStr, textInfo)
            end
            self._TxtNum.text = textInfo
            self._TxtNum.color = XUiHelper.Hexcolor2Color(resCfg.Color)
        end
    end
    self.ImgAttribute.gameObject:SetActive(not isStarShow)
    if data.IsNew ~= nil and self.TxtNew then
        self.TxtNew.gameObject:SetActive(data.IsNew)
    end
    if self.ImgUp then
        self.ImgUp.gameObject:SetActive(data.IsUp)
        self.ImgUp.transform:SetAsLastSibling()
    end
    if self.ImgDetail then
        if resCfg.HasBubble then
            self._BubbleDesc = resCfg.BubbleDesc
        end
        self.ImgDetail.gameObject:SetActive(resCfg.HasBubble)
        self.ImgDetail.transform:SetAsLastSibling()
    end
end

function XUiSkyGardenShoppingStreetBuildGridAttribute:ShowBubbleTips()
    if self.PanelAttributeDetail then
        self.TxtTalk.text = self._BubbleDesc
        XUiManager.MoveToTopAuto(self.PanelAttributeDetail.gameObject, self.TipsCloseArea)
        return
    end
    XMVCA.XSkyGardenShoppingStreet:ShowBubbleTips(self._BubbleDesc, self.ImgDetail.transform.position)
end

return XUiSkyGardenShoppingStreetBuildGridAttribute
