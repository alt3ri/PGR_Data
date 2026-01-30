---@class XUiPlotExhibitionMainGrid : XUiNode
---@field _Control XPlotExhibitionControl
local XUiPlotExhibitionMainGrid = XClass(XUiNode, "XUiPlotExhibitionMainGrid")

function XUiPlotExhibitionMainGrid:OnStart()
    self.ImgPercentNormal = self.ImgPercentNormal or XUiHelper.TryGetComponent(self.Transform, "PanelCharacter/Jindutiao/ImgPercentNormal", "Image")
    XUiHelper.RegisterClickEvent(self, self.BtnChangeCover, self.OnClickChangeCover)
end

---@param data XPlotExhibitionControlRole
function XUiPlotExhibitionMainGrid:Update(data)
    self._Data = data
    self.TxtName.text = data.Name
    self.RImgHead:SetRawImage(data.Icon)
    self.TxtNum.text = tostring(data.Progress) .. "%"
    self.TxtRight.text = data.Amount
    self.ImgNew.gameObject:SetActiveEx(data.IsNew)
    if self.ImgPercentNormal then
        self.ImgPercentNormal.fillAmount = data.Progress / 100
    end
    
    -- 如果角色只配了一个封面，隐藏换封面按钮
    if self.BtnChangeCover then
        local coverCount = data.Amount or 0
        self.BtnChangeCover.gameObject:SetActiveEx(coverCount > 1)
    end
end

function XUiPlotExhibitionMainGrid:GetRoleId()
    if self._Data then
        return self._Data.Id
    end
end

function XUiPlotExhibitionMainGrid:OnClickChangeCover()
    local roleId = self:GetRoleId()
    if roleId then
        XLuaUiManager.Open("UiPlotExhibitionPopupCoverChange", roleId)
    end
end

return XUiPlotExhibitionMainGrid