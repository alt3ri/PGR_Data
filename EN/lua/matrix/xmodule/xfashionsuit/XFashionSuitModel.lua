---@class XFashionSuitModel : XModel
local XFashionSuitModel = XClass(XModel, "XFashionSuitModel")

local TableKey = {
    FashionSuit = { CacheType = XConfigUtil.CacheType.Normal },
    FashionSuitNotice = { DirPath = XConfigUtil.DirectoryType.Client },
    FashionSuitClientConfig = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String },
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
        shopIds = {}
        local config = self:GetFashionSuitById(suitId)
        for _, id in pairs(config.FashionIds) do
            local fashion = XFashionConfigs.GetFashionTemplate(id)
            if fashion.FashionGainType == XEnumConst.FashionSuit.GainType.Shop then
                local shopId = fashion.FashionGainParams[1]
                if XTool.IsNumberValid(shopId) and not table.contains(shopIds, shopId) then
                    table.insert(shopIds, shopId)
                end
            end
        end
        self._SuitShopDict[suitId] = shopIds
    end
    return shopIds
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

---@return XTableFashionSuitClientConfig
function XFashionSuitModel:GetClientConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FashionSuitClientConfig, id)
end

----------config end----------


return XFashionSuitModel