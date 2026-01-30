---@class XUiGridBWGoodsBase : XUiNode
local XUiGridBWGoodsBase = XClass(XUiNode, "XUiGridBWGoodsBase")

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

function XUiGridBWGoodsBase:RefreshIcon(icon)
    self:_RefreshImage(self.RImgIcon, icon)
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

function XUiGridBWGoodsBase:_RefreshImage(component, value)
    if XTool.UObjIsNil(component) then
        return
    end

    local invalid = string.IsNilOrEmpty(value)

    self:_RefreshActive(component, not invalid)

    if not invalid then
        component:SetImage(value)
    end
end

return XUiGridBWGoodsBase
