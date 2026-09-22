local RESONANCE_COST_TYPE = XEnumConst.EQUIP.RESONANCE_COST_TYPE
local XUiTextScrolling = require("XUi/XUiTaikoMaster/XUiTaikoMasterFlowText")
local OWNED_COUNT_TEXT_KEY = "AwarenessOneClickResonanceMaterialOwnedCount"
local SELECTED_COUNT_TEXT_KEY = "AwarenessOneClickResonanceMaterialSelectedCount"

---@class XUiGridAwarenessOneClickResonanceMaterial : XUiNode
---@field Parent XUiPanelAwarenessOneClickResonance 所属一键养成共鸣面板
---@field UiRoot XUiEquipAwarenessOneClickPopup 根弹窗，用于注册点击事件和设置通用品质图标
---@field GridCostItem UiObject 材料展示内容节点
---@field MaterialButton XUiComponent.XUiButton 材料入口按钮，用于显示选中态
---@field Data table|nil 当前展示的共鸣材料数据
---@field IsDisabled boolean 当前材料是否禁止选择
---@field ClickCb fun(data:table) 材料点击回调
---@field _TxtCountCenter UnityEngine.UI.Text 居中材料数量文本
---@field _TxtCountScrolling UnityEngine.UI.Text 跑马灯材料数量文本
---@field _CountTextMask UnityEngine.RectTransform 材料数量文本显示区域
---@field _CountScrolling XUiTaikoMasterFlowText 材料数量文本跑马灯
---@field _CountScrollingTimerId number|nil 材料数量文本跑马灯下一帧定时器 Id
local XUiGridAwarenessOneClickResonanceMaterial = XClass(XUiNode, "XUiGridAwarenessOneClickResonanceMaterial")

-- 初始化材料格子的点击事件。
---@param uiRoot XUiEquipAwarenessOneClickPopup 根弹窗
---@param clickCb fun(data:table) 材料点击回调
function XUiGridAwarenessOneClickResonanceMaterial:OnStart(uiRoot, clickCb)
    self.UiRoot = uiRoot
    self.ClickCb = clickCb
    self.IsDisabled = false
    self._CountScrollingTimerId = nil
    self.MaterialButton = self.Transform:GetComponent(typeof(CS.XUiComponent.XUiButton))
    self._TxtCountCenter = self.GridCostItem:GetObject("TxtCountCenter")
    self._TxtCountScrolling = self.GridCostItem:GetObject("TxtCountScrolling")
    self._CountTextMask = self.GridCostItem:GetObject("PanelTxt").transform
    self._TxtCountScrolling.horizontalOverflow = CS.UnityEngine.HorizontalWrapMode.Overflow
    self._TxtCountScrolling.supportRichText = true
    self._CountScrolling = XUiTextScrolling.New(self._TxtCountScrolling, self._CountTextMask)
    self._CountScrolling:SetUseRectWidth(true)
    self._CountScrolling:Stop()

    self.UiRoot:RegisterClickEvent(self.MaterialButton, function()
        self:OnClick()
    end)
end

-- 按材料类型刷新图标、品质、数量和选中态。
---@param data table 材料显示数据
---@param isSelected boolean 是否已被选为本次一键共鸣消耗材料
---@param isDisabled boolean 是否禁止选择
---@param selectedCount number 当前已选中的材料数量
---@param needCount number 当前预计消耗的材料数量
function XUiGridAwarenessOneClickResonanceMaterial:Refresh(data, isSelected, isDisabled, selectedCount, needCount)
    self.Data = data
    self.IsDisabled = isDisabled
    self:RefreshButtonState(isSelected, isDisabled)

    local icon
    local quality
    if data.Type == RESONANCE_COST_TYPE.AWARENESS then
        icon = XMVCA.XEquip:GetEquipIconPath(data.IconTemplateId)
        quality = data.Star
    else
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(data.ItemId)
        icon = goodsShowParams.Icon
        quality = goodsShowParams.Quality
    end

    self.GridCostItem:GetObject("RImgIcon"):SetRawImage(icon)
    XUiHelper.SetQualityIcon(self.UiRoot, self.GridCostItem:GetObject("ImgQuality"), quality)
    self:RefreshCountText(data.Type, isSelected, selectedCount, data.Count, needCount)
end

-- 刷新材料数量文本，并在布局更新后按实际宽度启动跑马灯。
---@param costType number 共鸣材料类型
---@param isSelected boolean 是否选中
---@param selectedCount number 当前已选或可用的材料数量
---@param totalCount number 当前入口可展示的材料总数量
---@param needCount number 当前展示的预计消耗数量
function XUiGridAwarenessOneClickResonanceMaterial:RefreshCountText(costType, isSelected, selectedCount, totalCount, needCount)
    self:_ResetCountScrolling()
    local countText

    if not isSelected then
        countText = XUiHelper.GetText(OWNED_COUNT_TEXT_KEY, totalCount)
    elseif costType == RESONANCE_COST_TYPE.AWARENESS then
        -- 意识材料仅展示已选数量/总数量，不展示预计消耗。
        local selectedCountText = string.format("%d/%d", selectedCount, totalCount)
        countText = XUiHelper.GetText(SELECTED_COUNT_TEXT_KEY, selectedCountText)
    else
        -- 定向共鸣材料的分子展示拥有数量，其他材料展示当前已选数量。
        local displayNumeratorCount = selectedCount
        if costType == RESONANCE_COST_TYPE.TARGETED then
            displayNumeratorCount = totalCount
        end

        countText = string.format("%d/%d", displayNumeratorCount, needCount)
    end

    self._TxtCountCenter.text = countText
    self._TxtCountScrolling.text = countText
    self._TxtCountCenter.gameObject:SetActiveEx(true)
    self._TxtCountScrolling.gameObject:SetActiveEx(false)
    -- 等待布局更新后，按普通文本的实际宽度决定是否切换到跑马灯文本。
    self._CountScrollingTimerId = XScheduleManager.ScheduleNextFrame(function()
        self._CountScrollingTimerId = nil
        local textWidth = XUiHelper.CalcTextWidth(self._TxtCountCenter)
        local isNeedScrolling = textWidth > self._CountTextMask.rect.width
        self._TxtCountCenter.gameObject:SetActiveEx(not isNeedScrolling)
        self._TxtCountScrolling.gameObject:SetActiveEx(isNeedScrolling)

        if isNeedScrolling then
            self._CountScrolling:Play()
        end
    end)
end

-- 取消待执行的跑马灯启动，并复位文本内容和位置。
function XUiGridAwarenessOneClickResonanceMaterial:_ResetCountScrolling()
    if self._CountScrollingTimerId then
        XScheduleManager.UnSchedule(self._CountScrollingTimerId)
        self._CountScrollingTimerId = nil
    end

    self._CountScrolling:Reset()
end

-- 格子关闭时停止数量文本跑马灯并复位文本位置。
function XUiGridAwarenessOneClickResonanceMaterial:OnDisable()
    self:_ResetCountScrolling()
end

-- 刷新材料入口按钮状态，禁用态优先于选中态。
---@param isSelected boolean 是否选中
---@param isDisabled boolean 是否禁止选择
function XUiGridAwarenessOneClickResonanceMaterial:RefreshButtonState(isSelected, isDisabled)
    local state
    if isDisabled then
        state = CS.UiButtonState.Disable
    elseif isSelected then
        state = CS.UiButtonState.Select
    else
        state = CS.UiButtonState.Normal
    end

    self.MaterialButton:SetButtonState(state)
    self.MaterialButton.TempState = state
end

-- 点击材料格子，将当前材料数据交回父面板处理选择业务。
function XUiGridAwarenessOneClickResonanceMaterial:OnClick()
    if not self.Data then
        XLog.Error("XUiGridAwarenessOneClickResonanceMaterial clicked without material data.")
        return
    end

    if self.IsDisabled then
        XUiManager.TipText("AwarenessOneClickResonanceMaterialSingleCostNotEnough")
        return
    end

    self.ClickCb(self.Data)
end

return XUiGridAwarenessOneClickResonanceMaterial
