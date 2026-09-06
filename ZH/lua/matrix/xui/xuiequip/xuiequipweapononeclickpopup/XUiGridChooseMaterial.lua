-- 共鸣可选材料 Grid：道具（GridCostItem）或武器展示，点击选择消耗
---@class XUiGridChooseMaterial:XUiNode
---@field Parent XUiPanelResonance
---@field Button XUiComponent.XUiButton
---@field GridCostItem UnityEngine.RectTransform
---@field _TxtCountCenter UnityEngine.UI.Text 居中数量文本
---@field _TxtCountScrolling UnityEngine.UI.Text 跑马灯数量文本
---@field _CountTextMask UnityEngine.RectTransform 数量文本显示区域
---@field _CountScrolling XUiTaikoMasterFlowText 数量文本跑马灯
---@field _CountScrollingTimerId number|nil 跑马灯下一帧定时器 Id
local XUiGridChooseMaterial = XClass(XUiNode, "XUiGridChooseMaterial")

local XUiTextScrolling = require("XUi/XUiTaikoMaster/XUiTaikoMasterFlowText")

function XUiGridChooseMaterial:OnStart()
    self.Button:AddEventListener(handler(self, self.OnBtnClick))
    self._CountScrollingTimerId = nil
    self._TxtCountCenter = self.GridCostItem:GetObject("TxtCountCenter")
    self._TxtCountScrolling = self.GridCostItem:GetObject("TxtCountScrolling")
    self._CountTextMask = self.GridCostItem:GetObject("PanelTxt").transform
    self._TxtCountScrolling.horizontalOverflow = CS.UnityEngine.HorizontalWrapMode.Overflow
    self._TxtCountScrolling.supportRichText = true
    self._CountScrolling = XUiTextScrolling.New(self._TxtCountScrolling, self._CountTextMask)
    self._CountScrolling:SetUseRectWidth(true)
    self._CountScrolling:Stop()
end

---@param data table { ItemId, NeedCount, HaveCount, IsWeaponMaterial }
function XUiGridChooseMaterial:Update(data)
    self.Data = data
    self:_RefreshIcon(data)
    self:_RefreshCount(data)
end

function XUiGridChooseMaterial:_RefreshIcon(data)
    local grid = self.GridCostItem
    local icon, quality
    if data.IsWeaponMaterial then
        icon = XMVCA.XEquip:GetEquipIconPath(data.ItemId)
        quality = XMVCA.XEquip:GetEquipStar(data.ItemId)
    else
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(data.ItemId)
        icon = goodsShowParams.Icon
        quality = goodsShowParams.Quality
    end
    grid:GetObject("RImgIcon"):SetRawImage(icon)
    XUiHelper.SetQualityIcon(self.Parent.Parent, grid:GetObject("ImgQuality"), quality or 0)
end

function XUiGridChooseMaterial:_RefreshCount(data)
    self:_ResetCountScrolling()
    local ownText = CS.XTextManager.GetText("ItemOwn")
    local chosenText = CS.XTextManager.GetText("ItemChoose")

    local countText
    local isSelect
    if data.IsWeaponMaterial then
        -- 合并展示：选中态按全局选中武器总数（不分模板），有选则该 grid 显选中
        local mainPopup = self.Parent.Parent
        local selectedEquipMap = mainPopup:GetResonanceSelectedEquips()
        local selectedCount = 0
        for _, isSelected in pairs(selectedEquipMap or table.empty) do
            if isSelected then
                selectedCount = selectedCount + 1
            end
        end
        if selectedCount > 0 then
            -- 选中：已选/合并武器总数
            countText = string.format("%s %d/%d", chosenText, selectedCount, data.HaveCount or 0)
            isSelect = true
        else
            countText = string.format("%s %d", ownText, data.HaveCount or 0)
            isSelect = false
        end
    else
        local mainPopup = self.Parent.Parent
        local tokenSelected = mainPopup:GetResonanceSelectedTokenCount()
        if tokenSelected > 0 then
            countText = string.format("%s %d/%d", chosenText, tokenSelected, data.HaveCount or 0)
            isSelect = true
        else
            countText = string.format("%s %d", ownText, data.HaveCount or 0)
            isSelect = false
        end
    end

    self._TxtCountCenter.text = countText
    self._TxtCountScrolling.text = countText
    self._TxtCountCenter.gameObject:SetActiveEx(true)
    self._TxtCountScrolling.gameObject:SetActiveEx(false)
    self:_SetSelectState(isSelect)

    -- CV意识同款跑马灯
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

function XUiGridChooseMaterial:_ResetCountScrolling()
    if self._CountScrollingTimerId then
        XScheduleManager.UnSchedule(self._CountScrollingTimerId)
        self._CountScrollingTimerId = nil
    end
    self._CountScrolling:Reset()
end

function XUiGridChooseMaterial:OnDisable()
    self:_ResetCountScrolling()
end

function XUiGridChooseMaterial:_SetSelectState(isSelect)
    local state = isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.Button:SetButtonState(state)
    self.Button.TempState = state
end

function XUiGridChooseMaterial:OnBtnClick()
    local data = self.Data
    if not data then
        return
    end
    if data.IsWeaponMaterial then
        -- 打开选武器弹窗多选本次要消耗的武器（候选=全部同星级可吃武器）
        local mainPopup = self.Parent.Parent
        local mainEquipId = mainPopup.EquipId
        if not XTool.IsNumberValid(mainEquipId) then
            return
        end
        local candidateIds = mainPopup._Control:GetWeaponResonanceCanEatEquipIds(mainEquipId)
        if XTool.IsTableEmpty(candidateIds) then
            XUiManager.TipError("错误：没有武器材料")
            return
        end
        local selectedEquipIdMap = mainPopup:GetResonanceSelectedEquips()
        local selectedWeaponCount = 0
        for _ in pairs(selectedEquipIdMap or table.empty) do
            selectedWeaponCount = selectedWeaponCount + 1
        end
        local selectedTokenCount = mainPopup:GetResonanceSelectedTokenCount()
        local maxWeaponSelect = self.Parent.Data and self.Parent.Data.MaxWeaponSelectCount or 0
        -- 剩余需要为 0 且没有武器被选中时不再打开选武器弹窗（材料已满且无武器可换）；有武器选中时允许打开（换/取消武器）
        local remainNeed = maxWeaponSelect - selectedWeaponCount - selectedTokenCount
        if remainNeed <= 0 and selectedWeaponCount == 0 then
            return
        end
        -- 选武器上限 = 首绑槽数 − 已选代币数（武器与代币共享上限）
        local maxSelectCount = maxWeaponSelect - selectedTokenCount
        XLuaUiManager.Open("UiEquipChooseCostWeaponPopup", candidateIds, selectedEquipIdMap, maxSelectCount, function(newSelectedMap)
            -- 回写全局选中态
            mainPopup:SetResonanceSelectedEquips(newSelectedMap)
        end)
    else
        -- 代币材料：点击直接选中 min(持有, 剩余需要)；已选再点取消
        local mainPopup = self.Parent.Parent
        local maxWeaponSelect = self.Parent.Data and self.Parent.Data.MaxWeaponSelectCount or 0
        local currentToken = mainPopup:GetResonanceSelectedTokenCount()
        if currentToken > 0 then
            mainPopup:SetResonanceSelectedTokenCount(0)
            return
        end
        -- 剩余需要 = 首绑槽数 − 已选武器数 − 已选代币数
        local selectedEquipMap = mainPopup:GetResonanceSelectedEquips()
        local selectedWeaponCount = 0
        for _ in pairs(selectedEquipMap or table.empty) do
            selectedWeaponCount = selectedWeaponCount + 1
        end
        local remainNeed = maxWeaponSelect - selectedWeaponCount - currentToken
        if remainNeed <= 0 then
            return
        end
        local tokenSelected = math.min(data.HaveCount or 0, remainNeed)
        if tokenSelected > 0 then
            mainPopup:SetResonanceSelectedTokenCount(tokenSelected)
        end
    end
end

return XUiGridChooseMaterial
