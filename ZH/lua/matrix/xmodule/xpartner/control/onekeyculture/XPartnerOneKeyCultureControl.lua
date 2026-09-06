---@class XPartnerOneKeyCultureControl : XControl
---@field private _Model XPartnerModel
---@field private _MainControl XPartnerControl
local XPartnerOneKeyCultureControl = XClass(XControl, "XPartnerOneKeyCultureControl")

function XPartnerOneKeyCultureControl:OnInit()
    self._BaseCostControl = self:AddSubControl(require("XModule/XPartner/Control/OneKeyCulture/XPartnerOneKeyCultureBaseCostControl"))
    self._CommitControl = self:AddSubControl(require("XModule/XPartner/Control/OneKeyCulture/XPartnerOneKeyCultureCommitControl"))
    self._FoodSelectControl = self:AddSubControl(require("XModule/XPartner/Control/OneKeyCulture/XPartnerOneKeyCultureFoodSelectControl"))
end

function XPartnerOneKeyCultureControl:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_DATAUPDATE, self._OnPartnerDataUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_SKILLUNLOCK_CLOSERED, self._OnPartnerDataUpdate, self)
end

function XPartnerOneKeyCultureControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_DATAUPDATE, self._OnPartnerDataUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_SKILLUNLOCK_CLOSERED, self._OnPartnerDataUpdate, self)
end

function XPartnerOneKeyCultureControl:OnRelease()
    self._AssetPanelItemIds = nil
end

---region 全局事件回调
-- 辅助机数据变更（技能升级/解锁/品质变化等），转发为模块内事件通知 UI 刷新
function XPartnerOneKeyCultureControl:_OnPartnerDataUpdate()
    self._BaseCostControl:CalcAllCostData()
    self._MainControl:DispatchEvent(XMVCA.XPartner.EventIds.EVENT_REPLY_PARTNER_DATA_UPDATE)
end
---endregion


 
---region 获取子 Control

---@return XPartnerOneKeyCultureBaseCostControl
function XPartnerOneKeyCultureControl:GetBaseCostControl()
    return self._BaseCostControl
end

---@return XPartnerOneKeyCultureCommitControl
function XPartnerOneKeyCultureControl:GetCommitControl()
    return self._CommitControl
end

---@return XPartnerOneKeyCultureFoodSelectControl
function XPartnerOneKeyCultureControl:GetFoodSelectControl()
    return self._FoodSelectControl
end

--- 获取根 Control（XPartnerControl），供子级 Control 打断链式访问
---@return XPartnerControl
function XPartnerOneKeyCultureControl:GetRootControl()
    return self._MainControl
end

---endregion


---region UI 生命周期

-- 进入一键培养主界面时调用，初始化默认数据
function XPartnerOneKeyCultureControl:OnEnterCultureMainUI()
    if not self._Model:GetOneKeyCultureModel():GetCurPartnerId() then
        local partnerList = XDataCenter.PartnerManager.GetPartnerOverviewDataList(nil, nil, true)
        local firstPartner = partnerList and partnerList[1]
        if firstPartner then
            self:SetCurPartnerId(firstPartner:GetId())
        end
    end

    self:SyncAutoSettingsFromEquip()
    self._BaseCostControl:CalcAllCostData()
end


-- 退出一键培养主界面时调用，清理数据
function XPartnerOneKeyCultureControl:OnExitCultureMainUI()
end

-- 从 XEquip 全局设置拷贝到本模块 Model
function XPartnerOneKeyCultureControl:SyncAutoSettingsFromEquip()
    local XPartnerEnum = XMVCA.XPartner.Enum
    local XEquipEnum = XMVCA.XEquip.Enum
    local oneKeyCultureModel = self._Model:GetOneKeyCultureModel()

    oneKeyCultureModel:SetCultureSelected(XPartnerEnum.CultureType.LevelUp,
        XMVCA.XEquip:GetOneClickAutoSetting(XEquipEnum.OneClickAutoSettingType.PartnerLevel))
    oneKeyCultureModel:SetCultureSelected(XPartnerEnum.CultureType.StarUp,
        XMVCA.XEquip:GetOneClickAutoSetting(XEquipEnum.OneClickAutoSettingType.PartnerQuality))
    oneKeyCultureModel:SetCultureSelected(XPartnerEnum.CultureType.SkillLevelUp,
        XMVCA.XEquip:GetOneClickAutoSetting(XEquipEnum.OneClickAutoSettingType.PartnerSkill))
end
---endregion


---region 辅助机选中

-- 设置当前选中辅助机，写入 Model 并抛事件通知 UI 刷新
---@param partnerId number 辅助机实例 Id
function XPartnerOneKeyCultureControl:SetCurPartnerId(partnerId)
    if self._Model:GetOneKeyCultureModel():GetCurPartnerId() == partnerId then
        return
    end
    self._Model:GetOneKeyCultureModel():SetCurPartnerId(partnerId)
    self._BaseCostControl:CalcAllCostData()
    self._MainControl:DispatchEvent(XMVCA.XPartner.EventIds.EVENT_PARTNER_SELECT_CHANGE, partnerId)
end

---@return number
function XPartnerOneKeyCultureControl:GetCurPartnerId()
    return self._Model:GetOneKeyCultureModel():GetCurPartnerId()
end

---@return XPartner|nil
function XPartnerOneKeyCultureControl:GetCurPartnerEntity()
    local partnerId = self._Model:GetOneKeyCultureModel():GetCurPartnerId()
    if not partnerId then
        return nil
    end
    return XDataCenter.PartnerManager.GetPartnerEntityById(partnerId)
end

---@return number 推荐品质（最大品质）
function XPartnerOneKeyCultureControl:GetRecommendQuality()
    local partner = self:GetCurPartnerEntity()
    if not partner then
        return 0
    end
    return partner:GetQualityLimit()
end
---endregion


---region 自动兑换

---@param isAuto boolean
function XPartnerOneKeyCultureControl:SetAutoExchangeWithNotify(isAuto)
    self._Model:GetOneKeyCultureModel():SetAutoExchange(isAuto)
    self._MainControl:DispatchEvent(XMVCA.XPartner.EventIds.EVENT_AUTO_EXCHANGE_CHANGE)
end

---@return boolean
function XPartnerOneKeyCultureControl:IsAutoExchange()
    return self._Model:GetOneKeyCultureModel():IsAutoExchange()
end
---endregion



---region 升星辅助机选择
-- 获取可作为升星材料的同模板辅助机列表，以及可提升的总阶数
---@return table<XPartner> 辅助机列表
---@return number 可提升的阶数
function XPartnerOneKeyCultureControl:GetQualityUpPartnerListAndClipCount()
    local partner = self:GetCurPartnerEntity()
    if not partner then
        return table.empty, 0
    end

    local list = XDataCenter.PartnerManager.GetPartnerQualityUpDataList(partner:GetId())

    local curQuality = partner:GetQuality()
    local maxQuality = partner:GetQualityLimit()

    local ownFoodChips = 0
    for _, entity in ipairs(list) do
        ownFoodChips = ownFoodChips + entity:GetChipCurCount()
    end

    local chipsFoodCount = XDataCenter.ItemManager.GetCount(partner:GetChipItemId())
    local chipNeedCount = partner:GetChipNeedCount()
    local clipFoodCount = math.floor(chipsFoodCount / chipNeedCount)


    local totalChips = ownFoodChips + clipFoodCount * chipNeedCount 
    local canUpCount = 0
    for q = curQuality, maxQuality - 1 do
        if totalChips >= partner:GetClipMaxCount(q) then
            canUpCount = canUpCount + 1
        else
            break
        end
    end

    return list, canUpCount, clipFoodCount
end
 
---endregion



---region 货币栏
 
---@return number[]
function XPartnerOneKeyCultureControl:GetAssetPanelItemIds()
    if not self._AssetPanelItemIds then
        local itemId = XDataCenter.ItemManager.ItemId
        self._AssetPanelItemIds = {
            itemId.TantalumIronOre,     -- 钽铁合矿
            itemId.RepeatChallengeCoin, -- 拟战绩分
            itemId.Coin,                -- 螺母
        }
    end
    return self._AssetPanelItemIds
end
---endregion


---region 养成进度判定
---@param cultureType XPartnerEnum.CultureType
---@return boolean
function XPartnerOneKeyCultureControl:IsNeedCulture(cultureType)
    local partnerId = self:GetCurPartnerId()
    return not XMVCA.XPartner:GetOneKeyCultureAgency():IsCultureTypeMax(partnerId, cultureType)
end

--- 是否全部养成已达成（没有任何需要培养的项）
---@return boolean
function XPartnerOneKeyCultureControl:IsAllCultureDone()
    local XPartnerEnum = XMVCA.XPartner.Enum
    return not self:IsNeedCulture(XPartnerEnum.CultureType.LevelUp)
        and not self:IsNeedCulture(XPartnerEnum.CultureType.StarUp)
        and not self:IsNeedCulture(XPartnerEnum.CultureType.SkillLevelUp)
end
---endregion

 

return XPartnerOneKeyCultureControl
