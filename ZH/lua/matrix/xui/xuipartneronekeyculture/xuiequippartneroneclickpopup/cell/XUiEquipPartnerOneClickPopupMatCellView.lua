--[[--
-- XUiEquipPartnerOneClickPopupMatCellView.lua
-- 一键培养弹窗 - 材料格子 CellView
-- 预制体结构：Button > GridCostItem，外层 Button 用于选中，内层 GridCostItem 负责显示
--]]

---@class XUiEquipPartnerOneClickPopupMatCellView : XUiNode
---@field _Control XPartnerControl
---@field Button XUiComponent.XUiButton 选中按钮
---@field GridCostItem UnityEngine.RectTransform 内层消耗道具格子
---@field GoExchange UnityEngine.RectTransform 兑换材料标识
---@field TxtCountCenter UnityEngine.UI.Text 从内层 UI 跨 UI 绑定的居中数量文本
local XUiEquipPartnerOneClickPopupMatCellView = XClass(XUiNode, "XUiEquipPartnerOneClickPopupMatCellView")

function XUiEquipPartnerOneClickPopupMatCellView:InitNode(ui, parent, ...)
    self.Super.InitNode(self, ui, parent, ...)
    local XUiGridCostItem = require("XUi/XUiEquipBreakThrough/XUiGridCostItem")
    self._GridCostItem = XUiGridCostItem.New(self, self.GridCostItem)
    self.Button.CallBack = function()
        self:OnButtonClick()
    end
end

function XUiEquipPartnerOneClickPopupMatCellView:OnStart(...)
end

function XUiEquipPartnerOneClickPopupMatCellView:OnEnable()
end

function XUiEquipPartnerOneClickPopupMatCellView:OnDisable()
end

function XUiEquipPartnerOneClickPopupMatCellView:OnDestroy()
end

---region ui event

function XUiEquipPartnerOneClickPopupMatCellView:OnButtonClick()
    if self._CustomClickFunc then
        self._CustomClickFunc(self._CustomClickObj)
        return
    end
    -- self._GridCostItem:OnBtnClickClick()
end

---endregion

---region event

---endregion

--- 转接到内部 GridCostItem
function XUiEquipPartnerOneClickPopupMatCellView:Refresh(itemId, needCount)
    self._GridCostItem:Refresh(itemId, needCount)
    self.TxtCountCenter.text = needCount
end

--- 转接到内部 GridCostItem
function XUiEquipPartnerOneClickPopupMatCellView:RefreshCustom(icon, quality, needCount, haveCount)
    self._GridCostItem:RefreshCustom(icon, quality, needCount, haveCount)
    self.TxtCountCenter.text = needCount
end

--- 设置当前 Cell 的颜色模板
---@param colorDic table<boolean, UnityEngine.Color> {[true]=满足色, [false]=不满足色}
function XUiEquipPartnerOneClickPopupMatCellView:SetConditionColorOverride(colorDic)
    self._ConditionColorOverride = colorDic
end

--- 按外部数据刷新（不读 ItemManager，不做颜色判断）
function XUiEquipPartnerOneClickPopupMatCellView:RefreshByData(icon, quality, needCount, haveCount, isExchange)
    self._GridCostItem:RefreshByData(icon, quality, needCount, haveCount)
    self.TxtCountCenter.text = needCount
    self.GoExchange.gameObject:SetActiveEx(isExchange == true)
end

function XUiEquipPartnerOneClickPopupMatCellView:RefreshByStringData(icon, quality, customText, isSatisfied)
    self._GridCostItem:RefreshByStringData(icon, quality, customText)
    self.TxtCountCenter.text = customText
end

--- 设置自定义点击回调，覆盖默认的转发行为
---@param func function
---@param obj any
function XUiEquipPartnerOneClickPopupMatCellView:SetCustomClick(func, obj)
    self._CustomClickFunc = func
    self._CustomClickObj = obj
end

 
return XUiEquipPartnerOneClickPopupMatCellView
