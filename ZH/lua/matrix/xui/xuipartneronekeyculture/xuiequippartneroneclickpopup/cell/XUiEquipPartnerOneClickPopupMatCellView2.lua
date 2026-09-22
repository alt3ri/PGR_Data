---@class XUiEquipPartnerOneClickPopupMatCellView2 : XUiNode
---@field _Control XPartnerControl
---@field GridEquip UnityEngine.RectTransform
---@field GridExpItem UnityEngine.RectTransform
---@field ImgExchange UnityEngine.RectTransform
local XUiEquipPartnerOneClickPopupMatCellView2 = XClass(XUiNode, "XUiEquipPartnerOneClickPopupMatCellView2")

function XUiEquipPartnerOneClickPopupMatCellView2:InitNode(ui, parent, ...)
    self.Super.InitNode(self, ui, parent, ...)
    self._EquipGrid = XTool.InitUiObjectByUi({}, self.GridEquip)
end

---@param data table { ItemId, Count, IsExchange }
function XUiEquipPartnerOneClickPopupMatCellView2:Update(data)
    self.GridEquip.gameObject:SetActiveEx(true)
    self.GridExpItem.gameObject:SetActiveEx(false)
    self:_RefreshItem(data)
    self.ImgExchange.gameObject:SetActiveEx(data.IsExchange == true)
end

function XUiEquipPartnerOneClickPopupMatCellView2:_RefreshItem(data)
    local itemId = data.ItemId
    if not XTool.IsNumberValid(itemId) then
        XLog.Error("XUiEquipPartnerOneClickPopupMatCellView2._RefreshItem: ItemId is invalid")
        return
    end

    self._EquipGrid.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
    local quality = XDataCenter.ItemManager.GetItemQuality(itemId)
    self._EquipGrid.ImgEquipQuality:SetSprite(XArrangeConfigs.GeQualityPath(quality))
    self._EquipGrid.TxtLevel.text = "x" .. tostring(data.Count or 0)
end

return XUiEquipPartnerOneClickPopupMatCellView2
