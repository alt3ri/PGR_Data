--[[--
-- XUiEquipPartnerOneClickPopupCostItemCellView.lua
-- 一键培养弹窗 - 标题选项 CellView
--]]

---@class XUiEquipPartnerOneClickPopupCostItemCellView : XUiNode
---@field _Control XPartnerControl
---@field UiTxtTitle UnityEngine.UI.Text
---@field UiTxtPreview UnityEngine.UI.Text
---@field GoBgTitleChoose UnityEngine.RectTransform
---@field GoBgTitleNotChoose UnityEngine.RectTransform
---@field BtnChoose XUiComponent.XUiButton
---@field BtnDesc XUiComponent.XUiButton
---@field GoMaterialCell UnityEngine.RectTransform
---@field GoMaterialList UnityEngine.RectTransform
---@field GoPanelNone UnityEngine.RectTransform
---@field ImgBreakIcon UnityEngine.UI.Image 突破阶级图标
---@field TxtSkillPlan UnityEngine.UI.Text 主动技/被动技装配数量文本（如 主动技1/1 被动技2/4）
---@field BtnSkillSwitch XUiComponent.XUiButton 打开技能选中面板按钮
local XUiEquipPartnerOneClickPopupCostItemCellView = XClass(XUiNode, "XUiEquipPartnerOneClickPopupCostItemCellView")

function XUiEquipPartnerOneClickPopupCostItemCellView:InitComponents()
    self.BtnChoose:AddEventListener(function()
        self:OnBtnChooseClick()
    end)
    self.BtnDesc:AddEventListener(function()
        self:OnBtnDescClick()
    end)
    if self.BtnSkillSwitch then
        self.BtnSkillSwitch:AddEventListener(function()
            self:OnBtnSkillSwitchClick()
        end)
    end

    self._CostGridList = {}
    self._CostList = {}
    self._DisplayCostList = {}
    self._ExchangeCountDic = {}
    -- 第一个格子直接用 GoMaterialCell 本身
    local firstGrid = self:_NewCostGrid(self.GoMaterialCell)
    table.insert(self._CostGridList, firstGrid)
    self.GoMaterialCell.gameObject:SetActiveEx(false)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:OnStart(...)
    self:InitComponents()
end

function XUiEquipPartnerOneClickPopupCostItemCellView:OnEnable()
    self:_SetEvent(true)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:OnDisable()
    self:_SetEvent(false)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:OnDestroy()
end

---region ui event

function XUiEquipPartnerOneClickPopupCostItemCellView:OnBtnChooseClick()
    local commitControl = self._Control:GetOneKeyCultureMainControl():GetCommitControl()
    local isSelected = commitControl:IsCultureSelected(self._CultureType)
    commitControl:SetCultureSelectedWithNotify(self._CultureType, not isSelected)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:OnBtnDescClick()
    local XPartnerEnum = XMVCA.XPartner.Enum
    if self._CultureType == XPartnerEnum.CultureType.StarUp then
        self._Control:DispatchEvent(XMVCA.XPartner.EventIds.EVENT_VIEW_PARTNER_POPUP_OPEN_STARUP_PREVIEW)
    end
end

-- 打开技能选中面板，和 MainView 技能列表点击行为一致
function XUiEquipPartnerOneClickPopupCostItemCellView:OnBtnSkillSwitchClick()
    local partner = self._Control:GetOneKeyCultureMainControl():GetCurPartnerEntity()
    if not partner then
        return
    end

    -- 主动技有装配就默认打开被动技页，否则默认打开主动技页
    local skillType = self._Control:GetConfigControl():GetSkillType()
    local carryMainList = partner:GetCarryMainSkillGroupList()
    local initialSkillType = carryMainList and #carryMainList > 0 and skillType.PassiveSkill or skillType.MainSkill
    XLuaUiManager.Open("UiEquipOneClickCulturePartnerSkillPopup", partner:GetId(), initialSkillType)
end

---endregion

---region event

function XUiEquipPartnerOneClickPopupCostItemCellView:_IsCurCultureSelected()
    return self._Control:GetOneKeyCultureMainControl():GetCommitControl():IsCultureSelected(self._CultureType)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_SetEvent(flag)
    local XPartnerEventId = XMVCA.XPartner.EventIds
    if flag then
        self._Control:AddEventListener(XPartnerEventId.EVENT_CULTURE_SELECT_CHANGE, self._OnCultureSelectChange, self)
        self._Control:AddEventListener(XPartnerEventId.EVENT_PARTNER_FOOD_CHANGE, self._OnPartnerFoodChange, self)
        self._Control:AddEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_DATA_UPDATE, self._OnPartnerDataUpdate, self)
    else
        self._Control:RemoveEventListener(XPartnerEventId.EVENT_CULTURE_SELECT_CHANGE, self._OnCultureSelectChange, self)
        self._Control:RemoveEventListener(XPartnerEventId.EVENT_PARTNER_FOOD_CHANGE, self._OnPartnerFoodChange, self)
        self._Control:RemoveEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_DATA_UPDATE, self._OnPartnerDataUpdate, self)
    end
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_OnCultureSelectChange(cultureType)
    if cultureType ~= self._CultureType then
        return
    end
    local isSelected = self._Control:GetOneKeyCultureMainControl():GetCommitControl():IsCultureSelected(self._CultureType)
    self:_SetSelected(isSelected)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_OnPartnerFoodChange()
    self:Refresh(self._CultureType)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_OnPartnerDataUpdate()
    self:Refresh(self._CultureType)
end

---endregion

function XUiEquipPartnerOneClickPopupCostItemCellView:Refresh(cultureType)
    self._CultureType = cultureType

    local XPartnerEnum = XMVCA.XPartner.Enum

    if cultureType == XPartnerEnum.CultureType.LevelUp then
        self:_RefreshLevelUp()
    elseif cultureType == XPartnerEnum.CultureType.StarUp then
        self:_RefreshStarUp()
    elseif cultureType == XPartnerEnum.CultureType.SkillLevelUp then
        self:_RefreshSkillLevelUp()
    end

    local isSelected = self._Control:GetOneKeyCultureMainControl():GetCommitControl():IsCultureSelected(cultureType)
    self:_SetSelected(isSelected)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_RefreshLevelUp()
    local mainControl = self._Control:GetOneKeyCultureMainControl()
    local commitControl = mainControl:GetCommitControl()
    self.UiTxtTitle.text = XUiHelper.GetText("PartnerOneKeyLevelUpTitle")
    local partner = mainControl:GetCurPartnerEntity()
    if partner and self:_IsCurCultureSelected() then
        local canReachLevel = commitControl:GetCanReachLevel()
        self.UiTxtPreview.text = XUiHelper.GetText("PartnerOneKeyLevelUpPreview", canReachLevel)
        local targetBreakthrough = commitControl:GetCanReachBreakthrough()
        local breakthroughIcon = XPartnerConfigs.GetPartnerBreakThroughIcon(targetBreakthrough)
        if breakthroughIcon then
            self.ImgBreakIcon:SetSprite(breakthroughIcon)
        end
    else
        self.ImgBreakIcon:SetSprite(partner:GetBreakthroughIcon())
        self.UiTxtPreview.text = ""
    end
    local costList = commitControl:GetLevelUpConsumedList()
    self:_RefreshCostList(costList, commitControl:GetLevelUpExchangedList(), commitControl:GetLevelUpConsumeIndex() > 0)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_RefreshStarUp()
    local mainControl = self._Control:GetOneKeyCultureMainControl()
    local commitControl = mainControl:GetCommitControl()
    self.UiTxtTitle.text = XUiHelper.GetText("PartnerOneKeyStarUpTitle")
    local partner = mainControl:GetCurPartnerEntity()
    if partner and self:_IsCurCultureSelected() then
        local canReachQuality = commitControl:GetCanReachQuality()
        local qualityString = XPartnerConfigs.GetQualityString(canReachQuality)
        self.UiTxtPreview.text = XUiHelper.GetText("PartnerOneKeyStarUpPreview", qualityString)
    else
        self.UiTxtPreview.text = ""
    end

    local XPartnerEnum = XMVCA.XPartner.Enum
    local needPartnerCount = commitControl:GetCurCostPartnerChipCount()

    local costList = self._CostList
    table.clear(costList)

    for _, item in ipairs(commitControl:GetStarUpConsumedList()) do
        if item.Id == XPartnerEnum.XPartnerQualityClip then
            needPartnerCount = item.Count
        else
            table.insert(costList, item)
        end
    end

    if partner then
        table.insert(costList, 1, {
            IsPartner = true,
            Icon = partner:GetIcon(),
            Quality = XMVCA.XPartner.Util.GetGoodsQualityByPartnerQuality(partner:GetInitQuality()),
            NeedCount = needPartnerCount,
        })
    end

    self:_RefreshCostList(costList, commitControl:GetStarUpExchangedList(), partner ~= nil)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_RefreshSkillLevelUp()
    local mainControl = self._Control:GetOneKeyCultureMainControl()
    local commitControl = mainControl:GetCommitControl()
    self.UiTxtTitle.text = XUiHelper.GetText("PartnerOneKeySkillUpTitle")
    local partner = mainControl:GetCurPartnerEntity()
    if partner and self:_IsCurCultureSelected() then
        local avgLevel = commitControl:GetCanReachSkillAvgLevel()
        self.UiTxtPreview.text = XUiHelper.GetText("PartnerOneKeySkillUpPreview", avgLevel)
    else
        self.UiTxtPreview.text = ""
    end
    if partner then
        local maxPassiveCount = partner:GetQualitySkillColumnCount()
        local carryMainCount = #partner:GetCarryMainSkillGroupList()
        local carryPassiveCount = #partner:GetCarryPassiveSkillGroupList()
        self.TxtSkillPlan.text = XUiHelper.GetText("PartnerOneKeySkillPlan", carryMainCount, carryPassiveCount, maxPassiveCount)
    else
        self.UiTxtPreview.text = ""
        self.TxtSkillPlan.text = ""
    end
    local costList = commitControl:GetSkillConsumedList()
    self:_RefreshCostList(costList, commitControl:GetSkillExchangedList(), commitControl:GetSkillConsumeIndex() > 0)
end

---@param costList table
---@param exchangedList table
---@param hasConsume boolean
function XUiEquipPartnerOneClickPopupCostItemCellView:_RefreshCostList(costList, exchangedList, hasConsume)
    local coinId = XDataCenter.ItemManager.ItemId.Coin
    local exchangeCountDic = self._ExchangeCountDic
    table.clear(exchangeCountDic)
    for _, item in ipairs(exchangedList) do
        exchangeCountDic[item.Id] = (exchangeCountDic[item.Id] or 0) + item.Count
    end

    local displayList = self._DisplayCostList
    table.clear(displayList)
    for _, item in ipairs(costList) do
        if item.IsPartner then
            table.insert(displayList, item)
        elseif item.Id ~= coinId then
            local exchangeCount = math.min(item.Count, exchangeCountDic[item.Id] or 0)
            local ownCount = item.Count - exchangeCount
            if ownCount > 0 then
                table.insert(displayList, {
                    Id = item.Id,
                    Count = ownCount,
                    IsExchange = false,
                })
            end
        end
    end

    for _, item in ipairs(costList) do
        if not item.IsPartner and item.Id ~= coinId then
            local exchangeCount = math.min(item.Count, exchangeCountDic[item.Id] or 0)
            if exchangeCount > 0 then
                table.insert(displayList, {
                    Id = item.Id,
                    Count = exchangeCount,
                    IsExchange = true,
                })
            end
        end
    end

    local displayCount = #displayList

    local hasDisplayCost = hasConsume and displayCount > 0
    local showNone = self:_IsCurCultureSelected() and not hasDisplayCost
    self.GoMaterialList.gameObject:SetActiveEx(true)
    self.GoPanelNone.gameObject:SetActiveEx(showNone)
    if not hasDisplayCost then
        for _, grid in ipairs(self._CostGridList) do
            grid.GameObject:SetActiveEx(false)
        end
        return
    end

    self:_EnsureCostGridCount(displayCount)

    local displayIndex = 0
    for _, item in ipairs(displayList) do
        displayIndex = displayIndex + 1
        local grid = self._CostGridList[displayIndex]
        if item.IsPartner then
            local commitControl = self._Control:GetOneKeyCultureMainControl():GetCommitControl()
            local selectedCount = commitControl:GetSelectFoodCount()
            local haveText = selectedCount > 0 and selectedCount or XUiHelper.GetText("PartnerOneKeyNotSelected")
            local needText = "/" .. item.NeedCount
            local isSatisfied = selectedCount >= item.NeedCount
            grid:RefreshByStringData(item.Icon, item.Quality, haveText,  isSatisfied)
            grid:SetCustomClick(self._OnPartnerCostClick, self)
        else
            local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(item.Id)
            grid:RefreshByData(goodsShowParams.Icon, goodsShowParams.Quality, item.Count, item.Count, item.IsExchange)
        end
        grid.GameObject:SetActiveEx(true)
    end

    for i = displayCount + 1, #self._CostGridList do
        self._CostGridList[i].GameObject:SetActiveEx(false)
    end
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_EnsureCostGridCount(needCount)
    while #self._CostGridList < needCount do
        local ui = CS.UnityEngine.Object.Instantiate(self.GoMaterialCell, self.GoMaterialList)
        ui.gameObject:SetActiveEx(false)
        local grid = self:_NewCostGrid(ui)
        table.insert(self._CostGridList, grid)
    end
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_NewCostGrid(ui)
    local XUiEquipPartnerOneClickPopupMatCellView = require("XUi/XUiPartnerOneKeyCulture/XUiEquipPartnerOneClickPopup/cell/XUiEquipPartnerOneClickPopupMatCellView")
    return XUiEquipPartnerOneClickPopupMatCellView.New(ui, self)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_SetSelected(isSelected)
    self.GoBgTitleChoose.gameObject:SetActiveEx(isSelected)
    self.GoBgTitleNotChoose.gameObject:SetActiveEx(not isSelected)
    self.BtnChoose:SetButtonState(isSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_OnPartnerCostClick()
    XLuaUiManager.Open("UiEquipPartnerOneKeyCultureSelectClipPopup")
end

return XUiEquipPartnerOneClickPopupCostItemCellView
