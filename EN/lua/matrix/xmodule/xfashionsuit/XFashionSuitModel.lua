---@class XFashionSuitModel : XModel
local XFashionSuitModel = XClass(XModel, "XFashionSuitModel")

local TableKey = {
    FashionSuit = { CacheType = XConfigUtil.CacheType.Normal },
    FashionSuitNotice = { DirPath = XConfigUtil.DirectoryType.Client },
    FashionSuitClientConfig = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String },
    FashionGroup = { CacheType = XConfigUtil.CacheType.Normal }, --涂装组（角色涂装+武器涂装）
    FashionGroupAuto = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, Identifier = "FashionId" }, --key:角色涂装/武器涂装 value:FashionGroup表Id

    FashionSuitUiConfig = { DirPath = XConfigUtil.DirectoryType.Client}
}

function XFashionSuitModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fashion", TableKey)
end

function XFashionSuitModel:ClearPrivate()
    self._SuitShopDict = {}
end

function XFashionSuitModel:ResetAll()
    self._FashionSuitDict = nil
end

----------public start----------

---涂装套装收集奖励是否已领取
function XFashionSuitModel:IsSuitRewardGain(id)
    return self._FashionSuitDict and self._FashionSuitDict[id] and self._FashionSuitDict[id].IsReward
end

function XFashionSuitModel:SetSuitRewardGain(id)
    if not self._FashionSuitDict then
        self._FashionSuitDict = {}
    end
    if self._FashionSuitDict[id] then
        self._FashionSuitDict[id].IsReward = true
    else
        local data = {}
        data.Id = id
        data.IsReward = true
        self._FashionSuitDict[id] = data
    end
end

function XFashionSuitModel:SetFashionViewed(fashionId)
    XSaveTool.SaveData(string.format("FashionSuitViewed_%s_%s", XPlayer.Id, fashionId), 1)
end

function XFashionSuitModel:IsFashionViewed(fashionId)
    return XSaveTool.GetData(string.format("FashionSuitViewed_%s_%s", XPlayer.Id, fashionId)) == 1
end

function XFashionSuitModel:GetSuitShopIds(suitId)
    if not self._SuitShopDict then
        self._SuitShopDict = {}
    end
    local shopIds = self._SuitShopDict[suitId]
    if not shopIds then
        local shopIdDict = {}
        local config = self:GetFashionSuitById(suitId)
        for _, id in pairs(config.FashionIds) do
            local fashion = self:GetFashionGroupByFashionId(id)
            if fashion.GainType == XEnumConst.FashionSuit.GainType.Shop then
                local shopId = fashion.FashionGainParams[1]
                if XTool.IsNumberValid(shopId) then
                    shopIdDict[shopId] = true
                end
                shopId = fashion.WeaponFashionGainParams[1]
                if XTool.IsNumberValid(shopId) then
                    shopIdDict[shopId] = true
                end
            end
        end
        shopIds = {}
        for shopId in pairs(shopIdDict) do
            table.insert(shopIds, shopId)
        end
        self._SuitShopDict[suitId] = shopIds
    end
    return shopIds
end

function XFashionSuitModel:GetFashionGroupByFashionId(fashionId)
    local groupId = self:GetGroupIdByFashion(fashionId)
    if not groupId then
        return nil
    end
    return self:GetFashionGroupById(groupId)
end

---该套装是否支持整套购买
function XFashionSuitModel:IsSupportGroupSales(fashionId)
    local config = self:GetFashionGroupByFashionId(fashionId)
    return config and XTool.IsNumberValid(config.GainType)
end

---该套装是否允许整套购买
function XFashionSuitModel:IsAllowGroupSales(fashionId)
    if not self:IsSupportGroupSales(fashionId) then
        --配置不支持
        return
    end
    local config = self:GetFashionGroupByFashionId(fashionId)
    local isHaveFashion = XDataCenter.FashionManager.CheckHasFashion(config.FashionId) and
            XDataCenter.FashionManager.IsFashionInTime(config.FashionId)
    local isHaveWeaponFashion = XDataCenter.WeaponFashionManager.CheckHasFashion(config.WeaponFashionId) and
            not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(config.WeaponFashionId)
    if isHaveFashion and isHaveWeaponFashion then
        --已全部拥有
        return false
    end
    if config.GainType == XEnumConst.FashionSuit.GainType.Shop then
        if not isHaveFashion and not self:CheckGoodsValid(config.FashionGainParams[1], config.FashionGainParams[2]) then
            --角色涂装商品无效
            return false
        end
        if not isHaveWeaponFashion and not self:CheckGoodsValid(config.WeaponFashionGainParams[1], config.WeaponFashionGainParams[2]) then
            --武器涂装商品无效
            return false
        end
    elseif config.GainType == XEnumConst.FashionSuit.GainType.Purchase then
        if not self:CheckPurchageValid(config.FashionGainParams[1]) then
            --角色涂装礼包无效
            return false
        end
        if not self:CheckPurchageValid(config.WeaponFashionGainParams[1]) then
            --武器涂装礼包无效
            return false
        end
    end
    return true
end

---检查套装里的商品是否处于有效时间内
function XFashionSuitModel:CheckGoodsValid(shopId, goodsId)
    if not XShopManager.IsShopOpen(shopId) then
        --商店未开启
        return false
    end
    local data = XShopManager.GetShopGoodsInfo(shopId, goodsId)
    if not data then
        --商品信息不存在
        return false
    end
    local selloutTime = data.SelloutTime
    if selloutTime and selloutTime > 0 and XShopManager.GetLeftTime(selloutTime) <= 0 then
        --涂装商品已下架
        return false
    end
    if data.ConditionIds then
        for _, id in pairs(data.ConditionIds) do
            local ret, desc = XConditionManager.CheckCondition(id)
            if not ret then
                --未达到购买条件
                return false
            end
        end
    end
    return true
end

---检查套装里的礼包是否处于有效时间内
function XFashionSuitModel:CheckPurchageValid(packageId)
    local data = XDataCenter.PurchaseManager.GetPurchaseDataById(packageId)
    if not data then
        --礼包信息不存在
        return false
    end
    local nowTime = XTime.GetServerNowTimestamp()
    local timeToInvalid = data.TimeToInvalid
    if timeToInvalid and timeToInvalid > 0 and timeToInvalid <= nowTime then
        --礼包已过生效时间
        return false
    end
    local timeToUnShelve = data.TimeToUnShelve
    if timeToUnShelve and timeToUnShelve > 0 and timeToUnShelve > nowTime then
        --礼包已下架
        return false
    end
    return true
end

----------public end----------

----------private start----------

function XFashionSuitModel:SetFashionSuitData(data)
    if XTool.IsTableEmpty(data) then
        return
    end

    self._FashionSuitDict = {}
    for _, v in pairs(data) do
        self._FashionSuitDict[v.Id] = v
    end
end

function XFashionSuitModel:SaveData(data)
    self._SaveUtil:SaveData("NoticeFashionSuitIds", data)
end

function XFashionSuitModel:GetData()
    return self._SaveUtil:GetData("NoticeFashionSuitIds") or {}
end

----------private end----------

----------config start----------

---@return XTableFashionSuit[]
function XFashionSuitModel:GetFashionSuitConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.FashionSuit)
end

---@return XTableFashionSuit
function XFashionSuitModel:GetFashionSuitById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FashionSuit, id)
end

---@return XTableFashionSuitNotice[]
function XFashionSuitModel:GetFashionSuitNoticeConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.FashionSuitNotice)
end

---@return XTableFashionSuitNotice
function XFashionSuitModel:GetFashionSuitNoticeConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FashionSuitNotice, id)
end

---@return XTableFashionSuitClientConfig
function XFashionSuitModel:GetClientConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FashionSuitClientConfig, id)
end

---@return XTableFashionGroup
function XFashionSuitModel:GetFashionGroupById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FashionGroup, id)
end

---@return XTableFashionGroup[]
function XFashionSuitModel:GetFashionGroupConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.FashionGroup)
end

function XFashionSuitModel:GetGroupIdByFashion(fashionId)
    ---@type XTableFashionGroupAuto
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FashionGroupAuto, fashionId, true)
    return cfg and cfg.GroupId
end

---@return XTableFashionSuitUiConfig
function XFashionSuitModel:GetFashionSuitUiConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FashionSuitUiConfig, id)
end

----------config end----------


return XFashionSuitModel