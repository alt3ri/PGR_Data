---@class XPartnerOneKeyCultureFoodSelectViewModel : XModelBase
local XPartnerOneKeyCultureFoodSelectViewModel = XClass(XModelBase, "XPartnerOneKeyCultureFoodSelectViewModel")

function XPartnerOneKeyCultureFoodSelectViewModel:OnInit()
    self._SelectFoodDic = {}
    self._SelectClipIndexDic = {}
    self._SelectOreExchangeClipIndexDic = {}
    self._OreExchangeRemainChipCount = nil
end

function XPartnerOneKeyCultureFoodSelectViewModel:ClearPrivate()
    table.clear(self._SelectFoodDic)
    table.clear(self._SelectClipIndexDic)
    table.clear(self._SelectOreExchangeClipIndexDic)
    self._OreExchangeRemainChipCount = nil
end

function XPartnerOneKeyCultureFoodSelectViewModel:ResetAll()
    table.clear(self._SelectFoodDic)
    table.clear(self._SelectClipIndexDic)
    table.clear(self._SelectOreExchangeClipIndexDic)
    self._OreExchangeRemainChipCount = nil
end

---region ----------public start----------

--- 从 CommitModel 拷贝初始数据
---@param selectFoodDic table<number, boolean>|nil
---@param selectClipDic table<number, boolean>|nil
---@param selectOreExchangeClipDic table<number, boolean>|nil
---@param oreExchangeRemainChipCount number|nil
function XPartnerOneKeyCultureFoodSelectViewModel:Init(selectFoodDic, selectClipDic, selectOreExchangeClipDic, oreExchangeRemainChipCount)
    table.clear(self._SelectFoodDic)
    table.clear(self._SelectClipIndexDic)
    table.clear(self._SelectOreExchangeClipIndexDic)
    self._OreExchangeRemainChipCount = oreExchangeRemainChipCount
    if selectFoodDic then
        for partnerId, isSelect in pairs(selectFoodDic) do
            self._SelectFoodDic[partnerId] = isSelect
        end
    end
    if selectClipDic then
        for index, isSelect in pairs(selectClipDic) do
            self._SelectClipIndexDic[index] = isSelect
        end
    end
    if selectOreExchangeClipDic then
        for index, isSelect in pairs(selectOreExchangeClipDic) do
            self._SelectOreExchangeClipIndexDic[index] = isSelect
        end
    end
end

---@param partnerId number
---@param isSelect boolean
function XPartnerOneKeyCultureFoodSelectViewModel:SetSelect(partnerId, isSelect)
    self._SelectFoodDic[partnerId] = isSelect or nil
end

---@param partnerId number
---@return boolean
function XPartnerOneKeyCultureFoodSelectViewModel:IsSelect(partnerId)
    return self._SelectFoodDic[partnerId] or false
end

---@return number
function XPartnerOneKeyCultureFoodSelectViewModel:GetSelectCount()
    local count = 0
    for _, isSelect in pairs(self._SelectFoodDic) do
        if isSelect then
            count = count + 1
        end
    end
    return count
end

---@return table<number, boolean>
function XPartnerOneKeyCultureFoodSelectViewModel:GetSelectDic()
    return self._SelectFoodDic
end

---@param index number 碎片序号（1-based）
---@param isSelect boolean
function XPartnerOneKeyCultureFoodSelectViewModel:SetClipSelect(index, isSelect)
    self._SelectClipIndexDic[index] = isSelect or nil
end

---@param index number
---@return boolean
function XPartnerOneKeyCultureFoodSelectViewModel:IsClipSelect(index)
    return self._SelectClipIndexDic[index] or false
end

---@return number 选中的碎片数量
function XPartnerOneKeyCultureFoodSelectViewModel:GetSelectClipCount()
    local count = 0
    for _, isSelect in pairs(self._SelectClipIndexDic) do
        if isSelect then
            count = count + 1
        end
    end
    return count
end

---@return table<number, boolean>
function XPartnerOneKeyCultureFoodSelectViewModel:GetSelectClipDic()
    return self._SelectClipIndexDic
end

---@param index number
---@return boolean
function XPartnerOneKeyCultureFoodSelectViewModel:IsOreExchangeClipSelect(index)
    return self._SelectOreExchangeClipIndexDic[index] or false
end

---@param index number
---@param isSelect boolean
function XPartnerOneKeyCultureFoodSelectViewModel:SetOreExchangeClipSelect(index, isSelect)
    self._SelectOreExchangeClipIndexDic[index] = isSelect or nil
end

---@return number
function XPartnerOneKeyCultureFoodSelectViewModel:GetSelectOreExchangeClipCount()
    local count = 0
    for _, isSelect in pairs(self._SelectOreExchangeClipIndexDic) do
        if isSelect then
            count = count + 1
        end
    end
    return count
end

---@return table<number, boolean>
function XPartnerOneKeyCultureFoodSelectViewModel:GetSelectOreExchangeClipDic()
    return self._SelectOreExchangeClipIndexDic
end

---@param count number|nil
function XPartnerOneKeyCultureFoodSelectViewModel:SetOreExchangeRemainChipCount(count)
    self._OreExchangeRemainChipCount = count
end

---@return number|nil
function XPartnerOneKeyCultureFoodSelectViewModel:GetOreExchangeRemainChipCount()
    return self._OreExchangeRemainChipCount
end

---endregion ----------public end----------

return XPartnerOneKeyCultureFoodSelectViewModel
