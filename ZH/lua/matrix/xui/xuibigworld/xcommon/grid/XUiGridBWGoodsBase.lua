---@class XUiGridBWGoodsBase : XUiNode
local XUiGridBWGoodsBase = XClass(XUiNode, "XUiGridBWGoodsBase")
local XUiPanelNameplate = require("XUi/XUiNameplate/XUiPanelNameplate")

function XUiGridBWGoodsBase:GetTemplateId()
    if self._ItemsParams then
        return self._ItemsParams.TemplateId or 0
    end

    return 0
end

function XUiGridBWGoodsBase:Refresh(data)
    self._ItemsParams = XMVCA.XBigWorldService:GetItemsShowParams(data)

    if not self._ItemsParams then
        self:Close()
        return
    end

    self._GoodsParams = XMVCA.XBigWorldService:GetGoodsShowParamsByTemplateId(self:GetTemplateId())

    if not self._GoodsParams then
        self:Close()
        return
    end

    self:RefreshName(self._GoodsParams.Name)
    self:RefreshCount(self._ItemsParams.Count)
    self:RefreshIcon(self._ItemsParams.IsUseBigIcon and self._GoodsParams.BigIcon or self._GoodsParams.Icon)
    self:RefreshQuality(self._GoodsParams.QualityIcon)
    self:RefreshNameplate()
    self:RefreshOther(data)
end

function XUiGridBWGoodsBase:RefreshOther(data)
end

function XUiGridBWGoodsBase:RefreshName(name)
    self:_RefreshText(self.TxtName, name)
end

function XUiGridBWGoodsBase:RefreshCount(count)
    if not count then
        self:_RefreshActive(self.PanelCount, false)
        self:_RefreshActive(self.TxtCount, false)
        return
    end

    self:_RefreshActive(self.PanelCount, true)
    self:_RefreshText(self.TxtCount, tostring(count))
end

function XUiGridBWGoodsBase:RefreshCountColor(color)
    self:_RefreshColor(self.TxtCount, color)
end

function XUiGridBWGoodsBase:RefreshIcon(icon)
    self:_RefreshImage(self.RImgIcon, icon)
end

function XUiGridBWGoodsBase:RefreshNameplate()
    if self._GoodsParams.RewardType == XRewardManager.XRewardType.Nameplate then
        self:_RefreshActive(self.ImgQuality, false)
        self:_RefreshActive(self.RImgIcon, false)
        self:_RefreshNameplate()
    else
        if self.PanelNamePlate then
            self.PanelNamePlate.GameObject:SetActiveEx(false)
        end
    end
end

function XUiGridBWGoodsBase:RefreshQuality(qualityIcon)
    if string.IsNilOrEmpty(qualityIcon) then
        self:RefreshQualityByQuality(self._GoodsParams.Quality)
        return
    end

    self:RefreshQualityByIcon(qualityIcon)
end

function XUiGridBWGoodsBase:RefreshQualityByQuality(quality)
    if not quality then
        self:_RefreshActive(self.ImgQuality, false)
        return 
    end

    self:RefreshQualityByIcon(XMVCA.XBigWorldService:GetQualityIcon(quality))
end

function XUiGridBWGoodsBase:RefreshQualityByIcon(qualityIcon)
    self:_RefreshImage(self.ImgQuality, qualityIcon)
end

function XUiGridBWGoodsBase:_RefreshActive(component, isActive)
    if XTool.UObjIsNil(component) then
        return
    end

    component.gameObject:SetActiveEx(isActive)
end

function XUiGridBWGoodsBase:_RefreshText(component, value)
    if XTool.UObjIsNil(component) then
        return
    end

    local invalid = string.IsNilOrEmpty(value)

    self:_RefreshActive(component, not invalid)

    if not invalid then
        component.text = value
    end
end

function XUiGridBWGoodsBase:_RefreshColor(component, value)
    if XTool.UObjIsNil(component) then
        return
    end
    
    component.color = value
end

function XUiGridBWGoodsBase:_RefreshImage(component, value)
    if XTool.UObjIsNil(component) then
        return
    end
    if not self._GoodsParams or self._GoodsParams.RewardType ~= XRewardManager.XRewardType.Nameplate then
        local invalid = string.IsNilOrEmpty(value)

        self:_RefreshActive(component, not invalid)

        if not invalid then
            component:SetImage(value)
        end
    end

end

function XUiGridBWGoodsBase:_RefreshNameplate()
    local btnSiblingIndex = 0
    if self.BtnClick then
        btnSiblingIndex = self.BtnClick.transform:GetSiblingIndex()
    end
    if not self.PanelNamePlate then
        local prefab = self.GameObject:LoadPrefab(XMedalConfigs.XNameplatePanelPath)
        prefab.transform:SetSiblingIndex(btnSiblingIndex)
        local rectTransform = prefab.transform:GetComponent(typeof(CS.UnityEngine.RectTransform))
        if rectTransform then
            local vX = 0
            local vY = 15
            local scale = CS.UnityEngine.Vector3(0.6, 0.6, 0.6)
            if self.RImgIcon then
                local tmpTrans = self.RImgIcon:GetComponent(typeof(CS.UnityEngine.RectTransform))
                local vect = tmpTrans.anchoredPosition
                rectTransform.anchorMin = tmpTrans.anchorMin
                rectTransform.anchorMax = tmpTrans.anchorMax
                vX = vect.x
                vY = vect.y
                local bgX= self.RImgIcon:GetComponent(typeof(CS.UnityEngine.RectTransform)).sizeDelta.x
                local bgScale = self.RImgIcon.transform.localScale.x
                local realBgWidth = bgX * bgScale
                local tempX = rectTransform.sizeDelta.x
                local scaleNum = 0.9 * realBgWidth/tempX
                scale = CS.UnityEngine.Vector3(scaleNum, scaleNum, scaleNum)  -- 铭牌大小为标准背景宽高的90%防止超出格子
            end
            rectTransform.anchoredPosition = CS.UnityEngine.Vector2(vX, vY)
            rectTransform.localScale = scale
        end
        self.PanelNamePlate = XUiPanelNameplate.New(prefab, self.RootUi)
    end
    self.PanelNamePlate.GameObject:SetActiveEx(true)
    self.PanelNamePlate:UpdateDataById(self:GetTemplateId())
end

function XUiGridBWGoodsBase:SetClickState(value)
    if not self.BtnClick then
        return
    end
    self.BtnClick.gameObject:SetActiveEx(value)
end

function XUiGridBWGoodsBase:RefreshReceive(isReceive)
    self:_RefreshActive(self.PanelReceive, isReceive)
end

return XUiGridBWGoodsBase
