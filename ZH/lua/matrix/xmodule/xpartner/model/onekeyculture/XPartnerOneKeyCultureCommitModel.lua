---@class XPartnerOneKeyCultureCommitModel : XModelBase
local XPartnerOneKeyCultureCommitModel = XClass(XModelBase, "XPartnerOneKeyCultureCommitModel")

function XPartnerOneKeyCultureCommitModel:OnInit()
    self._SelectFoodDic = {}
    self._SelectClipIndexDic = {}
    self._SelectOreExchangeClipIndexDic = {}
    self._OreExchangeRemainChipCount = nil
end

function XPartnerOneKeyCultureCommitModel:ClearPrivate()
    table.clear(self._SelectFoodDic)
    table.clear(self._SelectClipIndexDic)
    table.clear(self._SelectOreExchangeClipIndexDic)
    self._OreExchangeRemainChipCount = nil
end

function XPartnerOneKeyCultureCommitModel:ResetAll()
    table.clear(self._SelectFoodDic)
    table.clear(self._SelectClipIndexDic)
    table.clear(self._SelectOreExchangeClipIndexDic)
    self._OreExchangeRemainChipCount = nil
end

---region ----------public start----------

---@param partnerId number
---@param isSelect boolean
function XPartnerOneKeyCultureCommitModel:SetSelectFood(partnerId, isSelect)
    self._SelectFoodDic[partnerId] = isSelect or nil
end

---@param partnerId number
---@return boolean
function XPartnerOneKeyCultureCommitModel:IsSelectFood(partnerId)
    return self._SelectFoodDic[partnerId] or false
end

---@return number
function XPartnerOneKeyCultureCommitModel:GetSelectFoodCount()
    local count = 0
    for _, isSelect in pairs(self._SelectFoodDic) do
        if isSelect then
            count = count + 1
        end
    end
    return count
end

---@return table<number, boolean>
function XPartnerOneKeyCultureCommitModel:GetSelectFoodDic()
    return self._SelectFoodDic
end

function XPartnerOneKeyCultureCommitModel:ClearSelectFood()
    table.clear(self._SelectFoodDic)
    table.clear(self._SelectClipIndexDic)
    table.clear(self._SelectOreExchangeClipIndexDic)
    self._OreExchangeRemainChipCount = nil
end

---@param index number
---@param isSelect boolean
function XPartnerOneKeyCultureCommitModel:SetSelectClip(index, isSelect)
    self._SelectClipIndexDic[index] = isSelect or nil
end

---@param index number
---@return boolean
function XPartnerOneKeyCultureCommitModel:IsSelectClip(index)
    return self._SelectClipIndexDic[index] or false
end

---@return number
function XPartnerOneKeyCultureCommitModel:GetSelectClipCount()
    local count = 0
    for _, isSelect in pairs(self._SelectClipIndexDic) do
        if isSelect then
            count = count + 1
        end
    end
    return count
end

---@return table<number, boolean>
function XPartnerOneKeyCultureCommitModel:GetSelectClipDic()
    return self._SelectClipIndexDic
end

---@param index number
---@param isSelect boolean
function XPartnerOneKeyCultureCommitModel:SetSelectOreExchangeClip(index, isSelect)
    self._SelectOreExchangeClipIndexDic[index] = isSelect or nil
end

---@param index number
---@return boolean
function XPartnerOneKeyCultureCommitModel:IsSelectOreExchangeClip(index)
    return self._SelectOreExchangeClipIndexDic[index] or false
end

---@return number
function XPartnerOneKeyCultureCommitModel:GetSelectOreExchangeClipCount()
    local count = 0
    for _, isSelect in pairs(self._SelectOreExchangeClipIndexDic) do
        if isSelect then
            count = count + 1
        end
    end
    return count
end

---@return table<number, boolean>
function XPartnerOneKeyCultureCommitModel:GetSelectOreExchangeClipDic()
    return self._SelectOreExchangeClipIndexDic
end

---@param count number|nil
function XPartnerOneKeyCultureCommitModel:SetOreExchangeRemainChipCount(count)
    self._OreExchangeRemainChipCount = count
end

---@return number|nil
function XPartnerOneKeyCultureCommitModel:GetOreExchangeRemainChipCount()
    return self._OreExchangeRemainChipCount
end

--- 批量追加兑换出来的辅助机 Id 到选中狗粮列表
---@param ids number[]
function XPartnerOneKeyCultureCommitModel:AddExchangedFoodIds(ids)
    for _, id in ipairs(ids) do
        self._SelectFoodDic[id] = true
    end
end

--- 清理选中的碎片索引（兑换完成后调用）
function XPartnerOneKeyCultureCommitModel:ClearSelectClip()
    table.clear(self._SelectClipIndexDic)
    table.clear(self._SelectOreExchangeClipIndexDic)
    self._OreExchangeRemainChipCount = nil
end

--- 从选中狗粮列表中移除已消耗的辅助机 Id
---@param ids number[]
function XPartnerOneKeyCultureCommitModel:RemoveSelectFood(ids)
    for _, id in ipairs(ids) do
        self._SelectFoodDic[id] = nil
    end
end

---endregion ----------public end----------

return XPartnerOneKeyCultureCommitModel