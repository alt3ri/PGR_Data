
local ExActivityTableKey = {
    AccumulateExpendShopActivity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    AccumulateExpendShopSignReward = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },

}
---@class XShopConfigModel 纯配置模块
local XShopConfigModel = XClass(XModel, "XShopConfigModel")

function XShopConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/AccumulateExpendShop", ExActivityTableKey)
end

---@return XTableAccumulateExpendShopActivity
function XShopConfigModel:GetAccumulateExpendShopActivityConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(
    ExActivityTableKey.AccumulateExpendShopActivity, id)
end

---@return XTableAccumulateExpendShopSignReward
function XShopConfigModel:GetAccumulateExpendShopSignRewardConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(
    ExActivityTableKey.AccumulateExpendShopSignReward, id)
end

function XShopConfigModel:GetAccumulateExpendShopSignRewardReward(id,index)
    local config = self:GetAccumulateExpendShopSignRewardConfig(id)
    if config then
      return  config.RewardIds[index]
    end
    return nil
end

return XShopConfigModel
