---@class XUiFubenBossSingleSettlementGridSelectableFeature : XUiNode
---@field TxtName UnityEngine.UI.Text
---@field TxtDesc UnityEngine.UI.Text
---@field TxtScoreRate UnityEngine.UI.Text  -- v4.2 新增：讨伐值倍率显示
---@field RImgIcon UnityEngine.UI.RawImage  -- v4.2 新增：词缀图标
local XUiFubenBossSingleSettlementGridSelectableFeature = XClass(XUiNode, "XUiFubenBossSingleSettlementGridSelectableFeature")

-- region 生命周期

function XUiFubenBossSingleSettlementGridSelectableFeature:OnStart()
    self._FeatureConfig = nil
end

-- endregion

---刷新显示
---@param featureConfig XTableBossSingleChallengeFeature
function XUiFubenBossSingleSettlementGridSelectableFeature:Refresh(featureConfig)
    if not featureConfig then
        return
    end
    
    self._FeatureConfig = featureConfig
    
    -- v4.2 新增：显示讨伐值倍率
    if self.TxtNum then
        local scoreRate = featureConfig.ScoreRate or 0
        self.TxtNum.text = string.format("+%.1f%%", scoreRate / 100)
    end
    
    -- v4.2 新增：设置词缀图标
    if self.RImgIcom and featureConfig.Icon then
        self.RImgIcom:SetRawImage(featureConfig.Icon)
    end
end

---获取词缀配置
---@return XTableBossSingleChallengeFeature
function XUiFubenBossSingleSettlementGridSelectableFeature:GetFeatureConfig()
    return self._FeatureConfig
end

return XUiFubenBossSingleSettlementGridSelectableFeature

