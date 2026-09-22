---@class XPartnerOneKeyCultureModel : XModelBase
local XPartnerOneKeyCultureModel = XClass(XModelBase, "XPartnerOneKeyCultureModel")

function XPartnerOneKeyCultureModel:OnInit()
    self._CurPartnerId = nil
    self._CultureSelectedDic = {}
    self._BaseCostItemModel = self:AddSubModel(require("XModule/XPartner/Model/OneKeyCulture/XPartnerOneKeyCultureBaseCostItemModel"))
    self._CommitModel = self:AddSubModel(require("XModule/XPartner/Model/OneKeyCulture/XPartnerOneKeyCultureCommitModel"))
    self._FoodSelectViewModel = self:AddSubModel(require("XModule/XPartner/Model/OneKeyCulture/XPartnerOneKeyCultureFoodSelectViewModel"))
end

function XPartnerOneKeyCultureModel:ClearPrivate()
    self._CurPartnerId = nil
    table.clear(self._CultureSelectedDic)
end

function XPartnerOneKeyCultureModel:ResetAll()
    self._CurPartnerId = nil
    table.clear(self._CultureSelectedDic)
end

---region ----------public start----------

function XPartnerOneKeyCultureModel:SetCurPartnerId(partnerId)
    self._CurPartnerId = partnerId
end

function XPartnerOneKeyCultureModel:GetCurPartnerId()
    return self._CurPartnerId
end

function XPartnerOneKeyCultureModel:SetCultureSelected(cultureType, isSelected)
    self._CultureSelectedDic[cultureType] = isSelected
end

function XPartnerOneKeyCultureModel:IsCultureSelected(cultureType)
    return self._CultureSelectedDic[cultureType] or false
end

function XPartnerOneKeyCultureModel:SetAutoExchange(isAuto)
    self._SaveUtil:SaveData("PartnerOneKeyCultureAutoExchange", isAuto and true or false)
end

function XPartnerOneKeyCultureModel:IsAutoExchange()
    return self._SaveUtil:GetData("PartnerOneKeyCultureAutoExchange") == true
end

---@return XPartnerOneKeyCultureBaseCostItemModel
function XPartnerOneKeyCultureModel:GetBaseCostItemModel()
    return self._BaseCostItemModel
end

---@return XPartnerOneKeyCultureCommitModel
function XPartnerOneKeyCultureModel:GetCommitModel()
    return self._CommitModel
end

---@return XPartnerOneKeyCultureFoodSelectViewModel
function XPartnerOneKeyCultureModel:GetFoodSelectViewModel()
    return self._FoodSelectViewModel
end

---endregion ----------public end----------

return XPartnerOneKeyCultureModel
