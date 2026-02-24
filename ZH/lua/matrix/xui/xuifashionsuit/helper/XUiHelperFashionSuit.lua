---@class XUiHelperFashionSuit 涂装详情界面存在多种状态（角色/武器、是否开启整套购买），创建一个状态管理类进行解耦
local XUiHelperFashionSuit = XClass(nil, "XUiHelperFashionSuit")

local Mask = {
    WeaponFashion = 1 << 0,
    SuitEnabled = 1 << 1,
}

local FashionType = {
    Character = XEnumConst.FashionSuit.FashionType.Character,
    Weapon = XEnumConst.FashionSuit.FashionType.Weapon,
}

local FuncType = {
    GetName = 0,
    GetCharacterName = 1,
    GetDesc = 2,
    GetRewards = 3,
    IsBtnPicVisible = 4,
    IsTagNewVisible = 5,
}

function XUiHelperFashionSuit:Ctor()
    self._Mask = 0
    self._Handlers = {}

    self:RegistHandler(FashionType.Character, FuncType.GetName, self.GetFashionName)
    self:RegistHandler(FashionType.Character, FuncType.GetCharacterName, self.GetFashionCharacterName)
    self:RegistHandler(FashionType.Character, FuncType.GetDesc, self.GetFashionDesc)
    self:RegistHandler(FashionType.Character, FuncType.GetRewards, self.GetFashionRewards)
    self:RegistHandler(FashionType.Character, FuncType.IsBtnPicVisible, self.IsFashionBtnPicVisible)
    self:RegistHandler(FashionType.Character, FuncType.IsTagNewVisible, self.IsFashionTagNewVisible)

    self:RegistHandler(FashionType.Weapon, FuncType.GetName, self.GetFashionWeaponName)
    self:RegistHandler(FashionType.Weapon, FuncType.GetCharacterName, self.GetFashionWeaponCharacterName)
    self:RegistHandler(FashionType.Weapon, FuncType.GetDesc, self.GetWeaponFashionDesc)
    self:RegistHandler(FashionType.Weapon, FuncType.GetRewards, self.GetWeaponFashionRewards)
    self:RegistHandler(FashionType.Weapon, FuncType.IsBtnPicVisible, self.IsWeaponFashionBtnPicVisible)
    self:RegistHandler(FashionType.Weapon, FuncType.IsTagNewVisible, self.IsWeaponFashionTagNewVisible)
end

function XUiHelperFashionSuit:InitData(context)
    ---@type XFashionContext
    self._Context = context
    local id = self._Context.SourceId
    if XWeaponFashionConfigs.IsWeaponFashion(id) then
        self._Mask = self._Mask | Mask.WeaponFashion
    end
end

function XUiHelperFashionSuit:SetGroupSales(isEnable)
    if isEnable then
        self._Mask = self._Mask | Mask.SuitEnabled
    else
        self._Mask = self._Mask & ~Mask.SuitEnabled
    end
end

function XUiHelperFashionSuit:RegistHandler(fashionType, funcType, func)
    if not self._Handlers[fashionType] then
        self._Handlers[fashionType] = {}
    end
    self._Handlers[fashionType][funcType] = handler(self, func)
end

function XUiHelperFashionSuit:ApplyHandler(funcType, ...)
    local type = self:IsWeapon() and FashionType.Weapon or FashionType.Character
    local dict = self._Handlers[type]
    if not dict then
        XLog.Error(string.format("涂装类型未注册：%s", type))
        return nil
    end
    local func = dict[funcType]
    if not func then
        XLog.Error(string.format("方法类型未注册：%s", funcType))
    end
    return func(...)
end

---是否开启整套购买
function XUiHelperFashionSuit:IsEnableGroupSales()
    return (self._Mask & Mask.SuitEnabled) ~= 0
end

---是否展示武器涂装
function XUiHelperFashionSuit:IsWeapon()
    return (self._Mask & Mask.WeaponFashion) ~= 0
end

---@return string
function XUiHelperFashionSuit:GetName()
    return self:ApplyHandler(FuncType.GetName, self._Context.SourceId)
end

---@return string
function XUiHelperFashionSuit:GetCharacterName()
    return self:ApplyHandler(FuncType.GetCharacterName, self._Context.SourceId)
end

---@return string
function XUiHelperFashionSuit:GetDesc()
    return self:ApplyHandler(FuncType.GetDesc, self._Context.SourceId)
end

---@return table
function XUiHelperFashionSuit:GetRewards()
    return self:ApplyHandler(FuncType.GetRewards, self._Context.SourceId)
end

---@return boolean
function XUiHelperFashionSuit:IsBtnPicVisible()
    return self:ApplyHandler(FuncType.IsBtnPicVisible, self._Context.SourceId)
end

---@return boolean
function XUiHelperFashionSuit:IsTagNewVisible()
    return self:ApplyHandler(FuncType.IsTagNewVisible, self._Context.SourceId)
end

function XUiHelperFashionSuit:UseFashion(cb)
    self:ApplyHandler(FuncType.UseFashion, cb)
end

--region 枚举方法

function XUiHelperFashionSuit:GetFashionName(id)
    return XFashionConfigs.GetFashionTemplate(id).Name
end

function XUiHelperFashionSuit:GetFashionWeaponName(id)
    return XWeaponFashionConfigs.GetFashionName(id)
end

function XUiHelperFashionSuit:GetFashionCharacterName(id)
    local cfg = XFashionConfigs.GetFashionTemplate(id)
    return XMVCA.XCharacter:GetCharacterTemplate(cfg.CharacterId).Name
end

function XUiHelperFashionSuit:GetFashionWeaponCharacterName(id)
    return ""
end

function XUiHelperFashionSuit:GetFashionDesc(id)
    if self:IsEnableGroupSales() then
        return XUiHelper.GetText("FashionSuitGroupSalesDesc")
    else
        local cfg = XFashionConfigs.GetFashionTemplate(id)
        return cfg.WorldDescription
    end
end

function XUiHelperFashionSuit:GetWeaponFashionDesc(id)
    return XWeaponFashionConfigs.GetFashionWorldDescription(id)
end

function XUiHelperFashionSuit:GetFashionRewards(id)
    local goodIdList = {}
    --角色涂装
    local fashionId = self._Context.FashionId
    local isHaveFashion = XDataCenter.FashionManager.CheckHasFashion(fashionId) and XDataCenter.FashionManager.IsFashionInTime(fashionId)
    table.insert(goodIdList, { TemplateId = id, Count = 1, ShowReceived = isHaveFashion, Disable = true })
    --武器涂装
    if self:IsEnableGroupSales() then
        local weaponFashionId = self._Context.WeaponFashionId
        local isHaveWeapon = XDataCenter.WeaponFashionManager.CheckHasFashion(weaponFashionId) and not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(weaponFashionId)
        table.insert(goodIdList, { TemplateId = weaponFashionId, Count = 1, ShowReceived = isHaveWeapon, Disable = true })
    end
    --赠品
    local subItems = XDataCenter.FashionManager.GetFashionSubItems(id)
    if subItems then
        for _, itemTemplateId in ipairs(subItems) do
            table.insert(goodIdList, { TemplateId = itemTemplateId, Count = 1, IsSubItem = true, ShowReceived = isHaveFashion })
        end
    end
    local giftId = XFashionConfigs.GetFashionTemplate(id).GiftId
    if XTool.IsNumberValid(giftId) then
        local giftGoodShowData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(giftId)
        giftGoodShowData.IsGift = true
        giftGoodShowData.Count = 1
        giftGoodShowData.ShowReceived = isHaveFashion
        table.insert(goodIdList, giftGoodShowData)
    end
    return goodIdList
end

function XUiHelperFashionSuit:GetWeaponFashionRewards(id)
    local goodIdList = {}
    local isHaveWeapon = XDataCenter.WeaponFashionManager.CheckHasFashion(id) and not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(id)
    table.insert(goodIdList, { TemplateId = id, Count = 1, ShowReceived = isHaveWeapon, Disable = true })
    return goodIdList
end

function XUiHelperFashionSuit:IsFashionBtnPicVisible(id)
    local cfg = XFashionConfigs.GetFashionTemplate(id)
    return not string.IsNilOrEmpty(cfg.FashionSuitPic)
end

function XUiHelperFashionSuit:IsWeaponFashionBtnPicVisible()
    return false
end

function XUiHelperFashionSuit:IsFashionTagNewVisible(id)
    return not XMVCA.XFashionSuit:IsFashionViewed(id)
end

function XUiHelperFashionSuit:IsWeaponFashionTagNewVisible()
    return false
end

--endregion

return XUiHelperFashionSuit