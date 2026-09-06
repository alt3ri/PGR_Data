-- 意识一键养成完成后的剩余材料面板
---@class XUiPanelAwarenessEnhanceProgressMaterialRemain : XUiNode
---@field Parent XUiEquipAwarenessEnhanceProgressPopup 所属进度弹窗
---@field GridCostItem UiObject 材料格子模板
---@field CostItemGridList UiObject[] 材料格子缓存
local XUiPanelAwarenessEnhanceProgressMaterialRemain = XClass(XUiNode, "XUiPanelAwarenessEnhanceProgressMaterialRemain")

local CSInstantiate = CS.UnityEngine.Object.Instantiate

-- 初始化材料格子缓存并隐藏模板
function XUiPanelAwarenessEnhanceProgressMaterialRemain:OnStart()
    self.CostItemGridList = {}
    self.GridCostItem.gameObject:SetActiveEx(false)
end

-- 刷新剩余材料格子
---@param remainingMaterialList XUiAwarenessEnhanceRemainingMaterial[]
function XUiPanelAwarenessEnhanceProgressMaterialRemain:Refresh(remainingMaterialList)
    for index, remainingMaterial in ipairs(remainingMaterialList) do
        local grid = self:GetOrCreateCostItemGrid(index)
        self:RefreshCostItemGrid(grid, remainingMaterial.MaterialData, remainingMaterial.RemainCount)
        grid.gameObject:SetActiveEx(true)
    end

    for index = #remainingMaterialList + 1, #self.CostItemGridList do
        self.CostItemGridList[index].gameObject:SetActiveEx(false)
    end
end

-- 获取指定下标的材料格子，不存在时按模板创建
---@param index number 格子下标
---@return UiObject
function XUiPanelAwarenessEnhanceProgressMaterialRemain:GetOrCreateCostItemGrid(index)
    local grid = self.CostItemGridList[index]
    if grid then
        return grid
    end

    local ui = CSInstantiate(self.GridCostItem, self.GridCostItem.transform.parent)
    grid = ui:GetComponent(typeof(CS.UiObject))
    self.CostItemGridList[index] = grid
    return grid
end

-- 刷新单个材料格子的图标、品质和剩余数量
---@param grid UiObject 材料格子
---@param materialData table 材料显示数据
---@param remainCount number 剩余数量
function XUiPanelAwarenessEnhanceProgressMaterialRemain:RefreshCostItemGrid(grid, materialData, remainCount)
    local icon
    local quality
    if materialData.Type == XEnumConst.EQUIP.RESONANCE_COST_TYPE.AWARENESS then
        icon = XMVCA.XEquip:GetEquipIconPath(materialData.IconTemplateId)
        quality = materialData.Star
    else
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(materialData.ItemId)
        icon = goodsShowParams.Icon
        quality = goodsShowParams.Quality
    end

    grid:GetObject("RImgIcon"):SetRawImage(icon)
    XUiHelper.SetQualityIcon(self.Parent, grid:GetObject("ImgQuality"), quality)
    grid:GetObject("TxtHaveCount").text = string.format("x%d", remainCount)
end

return XUiPanelAwarenessEnhanceProgressMaterialRemain
