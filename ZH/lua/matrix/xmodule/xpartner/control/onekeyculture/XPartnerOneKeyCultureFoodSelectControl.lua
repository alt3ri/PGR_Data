---@class XPartnerOneKeyCultureFoodSelectControl : XControl
---@field private _Model XPartnerModel
---@field private _MainControl XPartnerOneKeyCultureControl
--- 职责：狗粮选择的临时数据管理（ViewModel 生命周期 + 选中/查询/消耗计算）
local XPartnerOneKeyCultureFoodSelectControl = XClass(XControl, "XPartnerOneKeyCultureFoodSelectControl")

function XPartnerOneKeyCultureFoodSelectControl:OnInit()
    self._OneKeyCultureModel = self._Model:GetOneKeyCultureModel()
    self._CostItemModel = self._Model:GetOneKeyCultureModel():GetBaseCostItemModel()
    self._FoodSelectVM = self._OneKeyCultureModel:GetFoodSelectViewModel()
    --- true=选择弹窗模式(读VM), false=预览模式(读CommitModel)
    self._IsSelectMode = false
end

function XPartnerOneKeyCultureFoodSelectControl:OnRelease()
end



--region 生命周期

--- 打开狗粮选择弹窗时调用，从 CommitModel 拷贝当前选中到 ViewModel
function XPartnerOneKeyCultureFoodSelectControl:OpenFoodSelect()
    self._IsSelectMode = true
    local commitModel = self._OneKeyCultureModel:GetCommitModel()
    self._FoodSelectVM:Init(
            commitModel:GetSelectFoodDic(),
            commitModel:GetSelectClipDic(),
            commitModel:GetSelectOreExchangeClipDic(),
            commitModel:GetOreExchangeRemainChipCount()
    )
end

--- 确认选择，将 ViewModel 数据写回 CommitModel
function XPartnerOneKeyCultureFoodSelectControl:ConfirmFoodSelect()
    local commitModel = self._OneKeyCultureModel:GetCommitModel()
    commitModel:ClearSelectFood()

    local vmFoodDic = self._FoodSelectVM:GetSelectDic()
    for partnerId, isSelect in pairs(vmFoodDic) do
        commitModel:SetSelectFood(partnerId, isSelect)
    end

    local vmClipDic = self._FoodSelectVM:GetSelectClipDic()
    for index, isSelect in pairs(vmClipDic) do
        commitModel:SetSelectClip(index, isSelect)
    end

    local vmOreExchangeClipDic = self._FoodSelectVM:GetSelectOreExchangeClipDic()
    for index, isSelect in pairs(vmOreExchangeClipDic) do
        commitModel:SetSelectOreExchangeClip(index, isSelect)
    end
    commitModel:SetOreExchangeRemainChipCount(self._FoodSelectVM:GetOreExchangeRemainChipCount())

    self._FoodSelectVM:Init()
    self._MainControl:GetRootControl():DispatchEvent(XMVCA.XPartner.EventIds.EVENT_PARTNER_FOOD_CHANGE)
end

--- 取消选择，清空 ViewModel 数据
function XPartnerOneKeyCultureFoodSelectControl:CancelFoodSelect()
    self._IsSelectMode = false
    self._FoodSelectVM:Init()
end

function XPartnerOneKeyCultureFoodSelectControl:CloseFoodSelect()
    self._IsSelectMode = false
end

--endregion

--region 内部 - 数据路由

--- 根据模式路由到 VM 或 CommitModel
function XPartnerOneKeyCultureFoodSelectControl:_GetSelectDic()
    if self._IsSelectMode then
        return self._FoodSelectVM:GetSelectDic()
    end
    return self._OneKeyCultureModel:GetCommitModel():GetSelectFoodDic()
end

function XPartnerOneKeyCultureFoodSelectControl:_GetSelectClipCount()
    if self._IsSelectMode then
        return self._FoodSelectVM:GetSelectClipCount()
    end
    return self._OneKeyCultureModel:GetCommitModel():GetSelectClipCount()
end

function XPartnerOneKeyCultureFoodSelectControl:_GetSelectClipDic()
    if self._IsSelectMode then
        return self._FoodSelectVM:GetSelectClipDic()
    end
    return self._OneKeyCultureModel:GetCommitModel():GetSelectClipDic()
end

function XPartnerOneKeyCultureFoodSelectControl:_GetSelectOreExchangeClipDic()
    if self._IsSelectMode then
        return self._FoodSelectVM:GetSelectOreExchangeClipDic()
    end
    return self._OneKeyCultureModel:GetCommitModel():GetSelectOreExchangeClipDic()
end

function XPartnerOneKeyCultureFoodSelectControl:_GetOreExchangeRemainChipCount()
    if self._IsSelectMode then
        return self._FoodSelectVM:GetOreExchangeRemainChipCount()
    end
    return self._OneKeyCultureModel:GetCommitModel():GetOreExchangeRemainChipCount()
end

--endregion



--region 选中读写

---@param partnerId number
---@param isSelect boolean
function XPartnerOneKeyCultureFoodSelectControl:SetFoodSelect(partnerId, isSelect)
    self._FoodSelectVM:SetSelect(partnerId, isSelect)
    self._MainControl:GetRootControl():DispatchEvent(XMVCA.XPartner.EventIds.EVENT_FOOD_SELECT_PREVIEW_CHANGE)
end

---@param partnerId number
---@return boolean
function XPartnerOneKeyCultureFoodSelectControl:IsFoodSelect(partnerId)
    if self._IsSelectMode then
        return self._FoodSelectVM:IsSelect(partnerId)
    end
    return self._OneKeyCultureModel:GetCommitModel():IsSelectFood(partnerId)
end

---@return number
function XPartnerOneKeyCultureFoodSelectControl:GetFoodSelectCount()
    if self._IsSelectMode then
        return self._FoodSelectVM:GetSelectCount()
                + self._FoodSelectVM:GetSelectClipCount()
                + self:GetSelectOreExchangeClipCount()
    end
    local commitModel = self._OneKeyCultureModel:GetCommitModel()
    return commitModel:GetSelectFoodCount()
            + commitModel:GetSelectClipCount()
            + self:GetSelectOreExchangeClipCount()
end

---@param index number 碎片序号（1-based）
---@param isSelect boolean
function XPartnerOneKeyCultureFoodSelectControl:SetClipSelect(index, isSelect)
    self._FoodSelectVM:SetClipSelect(index, isSelect)
    self._MainControl:GetRootControl():DispatchEvent(XMVCA.XPartner.EventIds.EVENT_FOOD_SELECT_PREVIEW_CHANGE)
end

---@param index number
---@return boolean
function XPartnerOneKeyCultureFoodSelectControl:IsClipSelect(index)
    if self._IsSelectMode then
        return self._FoodSelectVM:IsClipSelect(index)
    end
    return self._OneKeyCultureModel:GetCommitModel():IsSelectClip(index)
end

---@return number 选中的碎片数量
function XPartnerOneKeyCultureFoodSelectControl:GetSelectClipCount()
    return self:_GetSelectClipCount()
end

---@param index number
---@param isSelect boolean
function XPartnerOneKeyCultureFoodSelectControl:SetOreExchangeClipSelect(index, isSelect)
    self._FoodSelectVM:SetOreExchangeClipSelect(index, isSelect)
    self._MainControl:GetRootControl():DispatchEvent(XMVCA.XPartner.EventIds.EVENT_FOOD_SELECT_PREVIEW_CHANGE)
end

---@param index number
---@return boolean
function XPartnerOneKeyCultureFoodSelectControl:IsOreExchangeClipSelect(index)
    if self._IsSelectMode then
        return self._FoodSelectVM:IsOreExchangeClipSelect(index)
    end
    return self._OneKeyCultureModel:GetCommitModel():IsSelectOreExchangeClip(index)
end

---@return number
function XPartnerOneKeyCultureFoodSelectControl:GetSelectOreExchangeClipCount()
    if not self._MainControl:IsAutoExchange() then
        return 0
    end
    if self._IsSelectMode then
        return self._FoodSelectVM:GetSelectOreExchangeClipCount()
    end
    return self._OneKeyCultureModel:GetCommitModel():GetSelectOreExchangeClipCount()
end

---@param remainChipCount number
function XPartnerOneKeyCultureFoodSelectControl:InitOreExchangeRemainChipCount(remainChipCount)
    if self._FoodSelectVM:GetOreExchangeRemainChipCount() == nil then
        self._FoodSelectVM:SetOreExchangeRemainChipCount(remainChipCount)
    end
end

---@return number|nil
function XPartnerOneKeyCultureFoodSelectControl:GetOreExchangeRemainChipCount()
    return self:_GetOreExchangeRemainChipCount()
end

--endregion



--region 消耗计算

---@return number 散碎碎片持有数
function XPartnerOneKeyCultureFoodSelectControl:GetLooseChipCount()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end
    return XDataCenter.ItemManager.GetCount(partner:GetChipItemId())
end

---@return number 散碎碎片可换算的狗粮数
function XPartnerOneKeyCultureFoodSelectControl:GetLooseChipPartnerCount()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end
    local chipCount = XDataCenter.ItemManager.GetCount(partner:GetChipItemId())
    local chipNeedCount = partner:GetChipNeedCount()
    if not chipNeedCount or chipNeedCount <= 0 then
        return 0
    end
    return math.floor(chipCount / chipNeedCount)
end

--- 可由矿石兑换补足的碎片格数量（包含仓库余片与兑换碎片组成的混合格）
---@return number foodCount
function XPartnerOneKeyCultureFoodSelectControl:GetOreExchangePartnerCount()
    if not self._MainControl:IsAutoExchange() then
        return 0
    end
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end
    local chipNeedCount = partner:GetChipNeedCount()
    if not chipNeedCount or chipNeedCount <= 0 then
        return 0
    end
    local chipItemId = partner:GetChipItemId()
    local ownChipCount = XMVCA.XPartner.Util.GetChipHaveCount(chipItemId)
    local exchangeChipCount = XMVCA.XPartner.Util.GetOreExchangeChipCount(chipItemId)
    local ownPartnerCount = math.floor(ownChipCount / chipNeedCount)
    local totalPartnerCount = math.floor((ownChipCount + exchangeChipCount) / chipNeedCount)
    return math.max(0, totalPartnerCount - ownPartnerCount)
end

--- 指定矿石兑换格实际需要兑换的碎片数；第一个格子可能与仓库余片组成混合格
---@param index number
---@return number
function XPartnerOneKeyCultureFoodSelectControl:GetOreExchangeClipNeedChipCount(index)
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end
    local chipNeedCount = partner:GetChipNeedCount()
    if not chipNeedCount or chipNeedCount <= 0 then
        return 0
    end
    if index ~= 1 then
        return chipNeedCount
    end
    local remainChipCount = self:_GetOreExchangeRemainChipCount()
    if remainChipCount == nil then
        local ownChipCount = XMVCA.XPartner.Util.GetChipHaveCount(partner:GetChipItemId())
        remainChipCount = ownChipCount % chipNeedCount
    end
    return chipNeedCount - remainChipCount
end

--- 已选矿石兑换格实际需要兑换的碎片数
---@return number
function XPartnerOneKeyCultureFoodSelectControl:GetSelectOreExchangeChipCount()
    if not self._MainControl:IsAutoExchange() then
        return 0
    end
    local selectDic = self:_GetSelectOreExchangeClipDic()
    local selectChipCount = 0
    for index in pairs(selectDic) do
        selectChipCount = selectChipCount + self:GetOreExchangeClipNeedChipCount(index)
    end
    return selectChipCount
end

--- 散碎碎片是否有选中
---@return boolean
function XPartnerOneKeyCultureFoodSelectControl:IsLooseChipSelected()
    return self:_GetSelectClipCount() > 0
end

---@return number 选中狗粮提供的经验数（含散碎碎片）
function XPartnerOneKeyCultureFoodSelectControl:GetFoodSelectExpCount()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end

    local selectFoodExp = 0

    -- 选中狗粮的碎片
    local selectFoodDic = self:_GetSelectDic()
    if next(selectFoodDic) then
        local list = XDataCenter.PartnerManager.GetPartnerQualityUpDataList(partner:GetId())
        for _, entity in ipairs(list) do
            if selectFoodDic[entity:GetId()] then
                selectFoodExp = selectFoodExp + entity:GetChipCurCount()
            end
        end
    end

    if self:IsLooseChipSelected() then
        local chipNeedCount = partner:GetChipNeedCount() 
        selectFoodExp = selectFoodExp + self:_GetSelectClipCount() * chipNeedCount
    end
    selectFoodExp = selectFoodExp + self:GetSelectOreExchangeClipCount() * partner:GetChipNeedCount()

    return selectFoodExp
end

---@return boolean 当前选择是否已足够达到品质上限
function XPartnerOneKeyCultureFoodSelectControl:IsFoodSelectFull()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return false
    end
    return partner:GetQuality() + self:GetFoodSelectCanUpCount() >= partner:GetQualityLimit()
end

---@return number 选中狗粮可升的阶数
function XPartnerOneKeyCultureFoodSelectControl:GetFoodSelectCanUpCount()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end

    local selectFoodDic = self:_GetSelectDic()
    local selectFoodChips = 0

    -- 选中狗粮
    if next(selectFoodDic) then
        local list = XDataCenter.PartnerManager.GetPartnerQualityUpDataList(partner:GetId())
        for _, entity in ipairs(list) do
            if selectFoodDic[entity:GetId()] then
                selectFoodChips = selectFoodChips + entity:GetChipCurCount()
            end
        end
    end

    -- 选中的散碎片（按 index 独立计数）
    if self:IsLooseChipSelected() then
        local chipNeedCount = partner:GetChipNeedCount() or 0
        local totalChips = self:GetLooseChipCount()
        local clipFoodCount = (chipNeedCount > 0) and math.ceil(totalChips / chipNeedCount) or 0
        local selectClipDic = self:_GetSelectClipDic()
        for index, isSelect in pairs(selectClipDic) do
            if isSelect then
                if index < clipFoodCount then
                    selectFoodChips = selectFoodChips + chipNeedCount
                else
                    selectFoodChips = selectFoodChips + (totalChips - (clipFoodCount - 1) * chipNeedCount)
                end
            end
        end
    end

    selectFoodChips = selectFoodChips + self:GetSelectOreExchangeClipCount() * (partner:GetChipNeedCount() or 0)


    local curQuality = partner:GetQuality()
    local maxQuality = partner:GetQualityLimit()
    local canUpCount = 0
    local previewStarSchedule = partner:GetStarSchedule() + selectFoodChips

    for quality = curQuality, maxQuality - 1 do
        local maxClipCount = partner:GetClipMaxCount(quality)
        if previewStarSchedule >= maxClipCount then
            canUpCount = canUpCount + 1
        else
            break
        end
    end

    return canUpCount
end

---@return number 选中狗粮可升阶消耗的螺母总数
function XPartnerOneKeyCultureFoodSelectControl:GetFoodSelectCostMoney()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end

    local selectFoodDic = self:_GetSelectDic()

    -- 选中狗粮折算的碎片数
    local selectFoodChips = 0
    local list = XDataCenter.PartnerManager.GetPartnerQualityUpDataList(partner:GetId())
    for _, entity in ipairs(list) do
        if selectFoodDic[entity:GetId()] then
            selectFoodChips = selectFoodChips + entity:GetChipCurCount()
        end
    end
    if self:IsLooseChipSelected() then
        local chipNeedCount = partner:GetChipNeedCount() or 0
        local totalChips = self:GetLooseChipCount()
        local clipFoodCount = (chipNeedCount > 0) and math.ceil(totalChips / chipNeedCount) or 0
        local selectClipDic = self:_GetSelectClipDic()
        for index, isSelect in pairs(selectClipDic) do
            if isSelect then
                if index < clipFoodCount then
                    selectFoodChips = selectFoodChips + chipNeedCount
                else
                    selectFoodChips = selectFoodChips + (totalChips - (clipFoodCount - 1) * chipNeedCount)
                end
            end
        end
    end
    selectFoodChips = selectFoodChips + self:GetSelectOreExchangeClipCount() * (partner:GetChipNeedCount() or 0)
    local totalChips = selectFoodChips

    local chipPerPartner = partner:GetChipNeedCount()
    if not chipPerPartner or chipPerPartner <= 0 then
        return 0
    end
    local availablePartnerCount = math.floor(totalChips / chipPerPartner)

    -- 遍历 StarUp MOList，逐个消耗 partner 数，累加螺母
    local XPartnerEnum = XMVCA.XPartner.Enum
    local moList = self._CostItemModel:GetStarUpMOList()
    local costMoney = 0

    for _, mo in ipairs(moList) do
        local needPartnerCount = 0
        local moneyCost = 0
        for _, item in ipairs(mo:GetNeedList()) do
            if item.Id == XPartnerEnum.XPartnerQualityClip then
                needPartnerCount = item.Count
            else
                moneyCost = moneyCost + item.Count
            end
        end
        if availablePartnerCount >= needPartnerCount then
            availablePartnerCount = availablePartnerCount - needPartnerCount
            costMoney = costMoney + moneyCost
        else
            break
        end
    end

    return costMoney
end

--- 选中狗粮可升阶消耗的货币材料列表（螺母等，按出现顺序聚合）
--- 基于选中狗粮换算出的可升阶数，逐阶取升阶货币消耗（与可升阶数展示同口径）
---@return {Id:number, Count:number}[]
function XPartnerOneKeyCultureFoodSelectControl:GetFoodSelectMoneyCostList()
    local costList = {}
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return costList
    end

    local canUpCount = self:GetFoodSelectCanUpCount()
    if canUpCount <= 0 then
        return costList
    end

    local curQuality = partner:GetQuality()
    local costMap = {}
    for quality = curQuality, curQuality + canUpCount - 1 do
        local money = partner:GetQualityEvolutionMoney(quality)
        if money and money.Count > 0 then
            local entry = costMap[money.Id]
            if not entry then
                entry = { Id = money.Id, Count = 0 }
                costMap[money.Id] = entry
                table.insert(costList, entry)
            end
            entry.Count = entry.Count + money.Count
        end
    end

    return costList
end

---@param partner XPartner
---@param attrType number XNpcAttribType
---@return number
function XPartnerOneKeyCultureFoodSelectControl:GetPartnerAttrValue(partner, attrType)
    if not partner then
        return 0
    end

    for _, attrInfo in pairs(partner:GetPartnerAttrMap()) do
        if attrInfo.AttrIndex == attrType then
            return attrInfo.Value
        end
    end

    return 0
end

---@return number 选中狗粮后预览的攻击力
function XPartnerOneKeyCultureFoodSelectControl:GetPreviewAttack()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end

    local canUpCount = self:GetFoodSelectCanUpCount()
    local targetQuality = math.min(partner:GetQuality() + canUpCount, partner:GetQualityLimit())
    local previewEntity = partner
    if targetQuality ~= partner:GetQuality() then
        local data = XTool.Clone(partner)
        data.Quality = targetQuality
        data.StarSchedule = 0
        previewEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(data, true) or partner
    end

    return self:GetPartnerAttrValue(previewEntity, XNpcAttribType.AttackNormal)
end

---@return number 选中狗粮后预览的战力
function XPartnerOneKeyCultureFoodSelectControl:GetPreviewAbility()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end

    local canUpCount = self:GetFoodSelectCanUpCount()
    local targetQuality = math.min(partner:GetQuality() + canUpCount, partner:GetQualityLimit())

    if targetQuality == partner:GetQuality() then
        return partner:GetAbility()
    end

    local data = XTool.Clone(partner)
    data.Quality = targetQuality
    data.StarSchedule = 0

    local previewEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(data, true)
    if previewEntity then
        return previewEntity:GetAbility()
    end

    return partner:GetAbility()
end

--endregion

return XPartnerOneKeyCultureFoodSelectControl
