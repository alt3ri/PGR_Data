--[[--
-- XUiEquipPartnerOneClickPopupCostItemCellView.lua
-- 一键培养弹窗 - 标题选项 CellView
--]]

---@class XUiEquipPartnerOneClickPopupCostItemCellView : XUiNode
---@field _Control XPartnerControl
---@field UiTxtTitle UnityEngine.UI.Text
---@field UiTxtPreview UnityEngine.UI.Text
---@field ImgArrow UnityEngine.UI.Image
---@field GoBgTitleChoose UnityEngine.RectTransform
---@field GoBgTitleNotChoose UnityEngine.RectTransform
---@field BtnChoose XUiComponent.XUiButton
---@field BtnDesc XUiComponent.XUiButton
---@field GoMaterialCell UnityEngine.RectTransform 进化消耗格子模板
---@field GridConsume UnityEngine.RectTransform 等级/技能消耗格子模板
---@field GoMaterialList UnityEngine.RectTransform
---@field GoPanelNone UnityEngine.RectTransform
---@field TxtNone UnityEngine.UI.Text 无可用材料时的定制提示文本
---@field GoPreview UnityEngine.RectTransform 养成结果预览节点
---@field ImgBreakIcon UnityEngine.UI.Image 突破阶级图标
---@field TxtSkillPlan UnityEngine.UI.Text 主动技/被动技装配数量文本（如 主动技1/1 被动技2/4）
---@field BtnSkillSwitch XUiComponent.XUiButton 打开技能选中面板按钮
local XUiEquipPartnerOneClickPopupCostItemCellView = XClass(XUiNode, "XUiEquipPartnerOneClickPopupCostItemCellView")

local LACK_MATERIAL_COLOR = XUiHelper.Hexcolor2Color("A1A1A1")

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
    self._OriginImgArrowColor = self.ImgArrow.color
    self._OriginPreviewColor = self.UiTxtPreview.color
    self._OriginTitleColor = self.UiTxtTitle.color
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
    self:Refresh(self._CultureType)
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
    self:_InitCostGrid()

    local XPartnerEnum = XMVCA.XPartner.Enum
    local isLackMaterial = false

    if cultureType == XPartnerEnum.CultureType.LevelUp then
        isLackMaterial = self:_RefreshLevelUp()
    elseif cultureType == XPartnerEnum.CultureType.StarUp then
        isLackMaterial = self:_RefreshStarUp()
    elseif cultureType == XPartnerEnum.CultureType.SkillLevelUp then
        isLackMaterial = self:_RefreshSkillLevelUp()
    end

    local isSelected = self._Control:GetOneKeyCultureMainControl():GetCommitControl():IsCultureSelected(cultureType)
    self:_SetLackMaterialColor(isLackMaterial)
    self:_SetSelected(isSelected, isLackMaterial)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_InitCostGrid()
    if self._CostGridTemplate then
        return
    end

    local XPartnerEnum = XMVCA.XPartner.Enum
    self._IsCommonConsumeGrid = self._CultureType == XPartnerEnum.CultureType.LevelUp
            or self._CultureType == XPartnerEnum.CultureType.SkillLevelUp
    self._CostGridTemplate = self._IsCommonConsumeGrid and self.GridConsume or self.GoMaterialCell

    local firstGrid = self:_NewCostGrid(self._CostGridTemplate)
    table.insert(self._CostGridList, firstGrid)
    self._CostGridTemplate.gameObject:SetActiveEx(false)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_RefreshLevelUp()
    local mainControl = self._Control:GetOneKeyCultureMainControl()
    local commitControl = mainControl:GetCommitControl()
    self.UiTxtTitle.text = XUiHelper.GetText("PartnerOneKeyLevelUpTitle")
    local partner = mainControl:GetCurPartnerEntity()
    local isLackMaterial = false
    if partner and self:_IsCurCultureSelected() then
        isLackMaterial = commitControl:GetLevelUpConsumeIndex() <= 0
        if isLackMaterial then
            self.UiTxtPreview.text = XUiHelper.GetText("PartnerOneKeyMaterialNotEnough")
        else
            local canReachLevel = commitControl:GetCanReachLevel()
            self.UiTxtPreview.text = XUiHelper.GetText("PartnerOneKeyLevelUpPreview", canReachLevel)
        end
        local targetBreakthrough = commitControl:GetCanReachBreakthrough()
        local breakthroughIcon = XPartnerConfigs.GetPartnerBreakThroughIcon(targetBreakthrough)
        if breakthroughIcon then
            self.ImgBreakIcon:SetSprite(breakthroughIcon)
        end
    else
        self.ImgBreakIcon:SetSprite(partner:GetBreakthroughIcon())
        self.UiTxtPreview.text = ""
    end
    local isSelected = self:_IsCurCultureSelected()
    local costList
    local exchangedList
    local hasConsume
    if isSelected then
        costList = commitControl:GetLevelUpConsumedList()
        exchangedList = commitControl:GetLevelUpExchangedList()
        hasConsume = commitControl:GetLevelUpConsumeIndex() > 0
    else
        costList = commitControl:GetLevelUpPreviewConsumedList()
        exchangedList = table.empty
        hasConsume = commitControl:GetLevelUpPreviewConsumeIndex() > 0
    end
    self:_RefreshCostList(costList, exchangedList, hasConsume)
    return isLackMaterial
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_RefreshStarUp()
    local mainControl = self._Control:GetOneKeyCultureMainControl()
    local commitControl = mainControl:GetCommitControl()
    self.UiTxtTitle.text = XUiHelper.GetText("PartnerOneKeyStarUpTitle")
    local partner = mainControl:GetCurPartnerEntity()
    local isLackMaterial = false
    if partner and self:_IsCurCultureSelected() then
        local selectedCount = commitControl:GetSelectFoodCount()
        isLackMaterial = selectedCount <= 0
        if isLackMaterial then
            local haveCount = mainControl:GetFoodSelectControl():GetSelectableFoodCount()
            local textKey = haveCount > 0 and "PartnerOneKeyWaitSelectFood" or "PartnerOneKeyFoodNotEnough"
            self.UiTxtPreview.text = XUiHelper.GetText(textKey)
        else
            local canReachQuality = commitControl:GetCanReachQuality()
            local qualityString = XPartnerConfigs.GetQualityString(canReachQuality)
            self.UiTxtPreview.text = XUiHelper.GetText("PartnerOneKeyStarUpPreview", qualityString)
        end
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
    return isLackMaterial
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_RefreshSkillLevelUp()
    local mainControl = self._Control:GetOneKeyCultureMainControl()
    local commitControl = mainControl:GetCommitControl()
    self.UiTxtTitle.text = XUiHelper.GetText("PartnerOneKeySkillUpTitle")
    local partner = mainControl:GetCurPartnerEntity()
    local isLackMaterial = false
    if partner and self:_IsCurCultureSelected() then
        local skillMOList = mainControl:GetBaseCostControl():GetSkillMOList()
        isLackMaterial = #skillMOList > 0 and commitControl:GetSkillConsumeIndex() <= 0
        if isLackMaterial then
            self.UiTxtPreview.text = XUiHelper.GetText("PartnerOneKeyMaterialNotEnough")
        else
            local avgLevel = commitControl:GetCanReachSkillAvgLevel()
            self.UiTxtPreview.text = XUiHelper.GetText("PartnerOneKeySkillUpPreview", avgLevel)
        end
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
    return isLackMaterial
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
    local XPartnerEnum = XMVCA.XPartner.Enum
    local showNone = (self:_IsCurCultureSelected()
        or self._CultureType == XPartnerEnum.CultureType.LevelUp)
        and not hasDisplayCost
    self.GoMaterialList.gameObject:SetActiveEx(true)
    self.GoPanelNone.gameObject:SetActiveEx(showNone)

    if showNone then
        if self._CultureType == XPartnerEnum.CultureType.LevelUp then
            local levelUpMOList = self._Control:GetOneKeyCultureMainControl():GetBaseCostControl():GetLevelUpMOList()
            local firstMO = levelUpMOList[1]
            local isCoinLack = false
            if firstMO then
                local coinId = XDataCenter.ItemManager.ItemId.Coin
                for _, item in ipairs(firstMO:GetNeedList()) do
                    if item.Id == coinId and XDataCenter.ItemManager.GetCount(coinId) < item.Count then
                        isCoinLack = true
                        break
                    end
                end
            end
            local textKey = isCoinLack and "PartnerOneKeyLackCoin" or "PartnerOneKeyLackLevelUpMaterial"
            self.TxtNone.text = XUiHelper.GetText(textKey)
        elseif self._CultureType == XPartnerEnum.CultureType.SkillLevelUp then
            local skillMOList = self._Control:GetOneKeyCultureMainControl():GetBaseCostControl():GetSkillMOList()
            local firstMO = skillMOList[1]
            local isNonCoinCostEnough = firstMO ~= nil
            if firstMO then
                local coinId = XDataCenter.ItemManager.ItemId.Coin
                for _, item in ipairs(firstMO:GetNeedList()) do
                    if item.Id ~= coinId and XDataCenter.ItemManager.GetCount(item.Id) < item.Count then
                        isNonCoinCostEnough = false
                        break
                    end
                end
            end
            local textKey = isNonCoinCostEnough and "PartnerOneKeyLackCoin" or "PartnerOneKeyLackSkillUpMaterial"
            self.TxtNone.text = XUiHelper.GetText(textKey)
        end
    end

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
            local customText
            local haveCount = self._Control:GetOneKeyCultureMainControl():GetFoodSelectControl():GetSelectableFoodCount()
            local selectedCount = commitControl:GetSelectFoodCount()
            if selectedCount > 0 then
                customText = XUiHelper.GetText("PartnerOneKeyFoodSelectedCount", selectedCount, haveCount)
            else
                customText = XUiHelper.GetText("PartnerOneKeyFoodOwnedCount", haveCount)
            end
            grid:RefreshByStringData(item.Icon, item.Quality, customText, selectedCount)
            grid:SetCustomClick(self._OnPartnerCostClick, self)
        else
            if self._IsCommonConsumeGrid then
                grid:Update({
                    ItemId = item.Id,
                    Count = item.Count,
                    NeedCount = item.Count,
                    IsEquip = false,
                    IsExchange = item.IsExchange,
                })
            else
                local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(item.Id)
                grid:RefreshByData(goodsShowParams.Icon, goodsShowParams.Quality, item.Count, item.Count, item.IsExchange)
            end
        end
        grid.GameObject:SetActiveEx(true)
    end

    for i = displayCount + 1, #self._CostGridList do
        self._CostGridList[i].GameObject:SetActiveEx(false)
    end
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_EnsureCostGridCount(needCount)
    while #self._CostGridList < needCount do
        local ui = CS.UnityEngine.Object.Instantiate(self._CostGridTemplate, self.GoMaterialList)
        ui.gameObject:SetActiveEx(false)
        local grid = self:_NewCostGrid(ui)
        table.insert(self._CostGridList, grid)
    end
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_NewCostGrid(ui)
    if self._IsCommonConsumeGrid then
        local XUiEquipPartnerOneClickPopupMatCellView2 = require("XUi/XUiPartnerOneKeyCulture/XUiEquipPartnerOneClickPopup/cell/XUiEquipPartnerOneClickPopupMatCellView2")
        return XUiEquipPartnerOneClickPopupMatCellView2.New(ui, self)
    end

    local XUiEquipPartnerOneClickPopupMatCellView = require("XUi/XUiPartnerOneKeyCulture/XUiEquipPartnerOneClickPopup/cell/XUiEquipPartnerOneClickPopupMatCellView")
    return XUiEquipPartnerOneClickPopupMatCellView.New(ui, self)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_SetLackMaterialColor(isLackMaterial)
    self.ImgArrow.color = isLackMaterial and LACK_MATERIAL_COLOR or self._OriginImgArrowColor
    self.UiTxtPreview.color = isLackMaterial and LACK_MATERIAL_COLOR or self._OriginPreviewColor
    self.UiTxtTitle.color = isLackMaterial and LACK_MATERIAL_COLOR or self._OriginTitleColor
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_SetSelected(isSelected, isLackMaterial)
    local isShowChooseBg = isSelected and not isLackMaterial
    self.GoBgTitleChoose.gameObject:SetActiveEx(isShowChooseBg)
    self.GoBgTitleNotChoose.gameObject:SetActiveEx(not isShowChooseBg)
    self.GoPreview.gameObject:SetActiveEx(isSelected)
    self.BtnChoose:SetButtonState(isSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiEquipPartnerOneClickPopupCostItemCellView:_OnPartnerCostClick()
    XLuaUiManager.Open("UiEquipPartnerOneKeyCultureSelectClipPopup")
end

return XUiEquipPartnerOneClickPopupCostItemCellView
