--- Control部分类，此处用于处理局内商店相关逻辑
---@type XTheatre6Control
local XTheatre6Control = XClassPartial('XTheatre6Control')
local ReqMethodName = {
    ShopFresh = "Theatre6ShopFreshRequest",
    EndShop = "Theatre6EndShopRequest",
    ShopGoodLock = "Theatre6ShopGoodLockRequest",
    BuyGood = "Theatre6ShopGoodBuyRequest",
    SellGood = "Theatre6ShopGoodSellRequest"
}

function XTheatre6Control:EnterShop()
end

function XTheatre6Control:GetBSModel()
    return self._Model.BattleShop
end

--- 商店刷新请求
function XTheatre6Control:ShopFreshRequest(cb)
    local hasRefreshable = false
    for _, good in ipairs(self:GetShopGoods()) do
        if not good.IsLock then
            hasRefreshable = true
            break
        end
    end
    if not hasRefreshable then
        XUiManager.TipText("Theatre6BattleShopAllLocked")
        return
    end
    if self:GetRefreshPrice() > self:GetCurrentGold() then
        XLuaUiManager.Open("UiTheatre6PopupCommon", "", XUiHelper.GetText("Theatre6CoinNotEnough"))

        return
    end
    self:SetDelayMask("ShopFreshRequest")
    local req = { ShopFreshCount = self:GetCurRefreshCount() }
    XNetwork.Call(ReqMethodName.ShopFresh, req, function (response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        self:GetBSModel():SyncCurRoomShopData(response.ShopGoods, response.ShopFreshCount)
        if cb then
            cb()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_SHOP_REFRESH)
    end)
end

--- 离开商店请求
function XTheatre6Control:LeaveShopRequest(cb)
    XNetwork.Call(ReqMethodName.EndShop, nil, function (response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

--- 锁定或解锁商品请求
function XTheatre6Control:ShopGoodLockRequest(pos, isLock, cb)
    self:SetDelayMask("ShopGoodLockRequest")
    local req = { Pos = pos, IsLock = isLock }
    XNetwork.Call(ReqMethodName.ShopGoodLock, req, function (response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        if cb then
            cb(response.IsLock)
        end

        self:GetBSModel():UpdateShopGoodIsLock(pos, response.IsLock)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_LOCK_GOOD, response.IsLock, pos)
    end)
end

function XTheatre6Control:GetCurRefreshCount()
    return self:GetBSModel():GetShopFreshCount()
end

function XTheatre6Control:GetShopGoods()
    return self:GetBSModel():GetShopGoods()
end

--- 检查商店中是否有未售出的指定技能商品
function XTheatre6Control:HasShopSkillGood(skillId)
    local shopGoods = self:GetShopGoods()
    if not shopGoods then
        return false
    end
    for _, good in pairs(shopGoods) do
        if good.Type == 1 and not good.IsSell and good.GoodId == skillId then
            return true
        end
    end
    return false
end

function XTheatre6Control:BuySkillGood(skillId, pos, cb)
    local skillConfig = self:GetSkillCfgById(skillId)
    if not self:IsCoinEnough(skillConfig.BuyPrice) then
        XLuaUiManager.Open("UiTheatre6PopupCommon", "", XUiHelper.GetText("Theatre6SkillCoinNotEnough"))
        return
    end

    if not self._Model.Skill:CheckSkillHad(skillId) then
        local skillModel = self._Model.Skill
        local installSlots = skillModel:GetSkillInstallSlots(skillId)
        local hasEquipSpace = false
        if installSlots then
            for _, slotType in ipairs(installSlots) do
                if not skillModel:IsSlotFull(nil, slotType) then
                    hasEquipSpace = true
                    break
                end
            end
        end
        if not hasEquipSpace and skillModel:IsSkillBagFull() then
            XLuaUiManager.Open("UiTheatre6PopupCommon", "", XUiHelper.GetText("Theatre6SkillMax"))
            return
        end
    end
    self:SetDelayMask("BuySkillGood")
    local req = { Pos = pos }
    XNetwork.Call(ReqMethodName.BuyGood, req, function (response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        local isGetNewSkill = false
        local isUpGrade = false

        local targetPos = response.SellShopGood.Position
        local skillId = response.SellShopGood.GoodId

        self:GetBSModel():UpdateShopGoodData(response.SellShopGood)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_BUY_GOOD, targetPos)

        if response.SkillUpdates then
            local hasUpgradeReplace = false
            -- local hasLowLevelToBag = false
            for _, skillUpdateData in ipairs(response.SkillUpdates) do
                local upgrade, toBag = self._Model.Skill:CollectAddSkillToastFlags(skillUpdateData)
                hasUpgradeReplace = hasUpgradeReplace or upgrade
                -- hasLowLevelToBag = hasLowLevelToBag or toBag
                self._Model.Skill:UpdateSkillsWithOverQueue(skillUpdateData)
                if skillUpdateData.AddSkill then
                    isGetNewSkill = true
                end
                if skillUpdateData.ReplaceSkills and #skillUpdateData.ReplaceSkills > 0 then
                    -- skillData=skillID,Position,SlotType
                    for index, skillData in pairs(skillUpdateData.ReplaceSkills) do
                        local replaceCfg = self:GetSkillCfgById(skillData.SkillId)
                        local buyCfg = self:GetSkillCfgById(skillId)
                        if replaceCfg and buyCfg
                            and replaceCfg.SkillKey == buyCfg.SkillKey and replaceCfg.Level > buyCfg.Level then
                            isUpGrade = true
                            skillId = skillData.SkillId
                            break
                        end
                    end
                end
            end
            if hasUpgradeReplace then
                XUiManager.TipMsg(XUiHelper.GetText("Theatre6SkillReplaceHigh"))
            end
            -- if hasLowLevelToBag then
            -- XUiManager.TipMsg(XUiHelper.GetText("Theatre6SkillAutoToBag"))
            -- end
        end
        if cb then
            cb()
        end

        if isGetNewSkill or isUpGrade then
            if XLuaUiManager.IsUiShow("UiTheatre6GainTips") then
                XLuaUiManager.Close("UiTheatre6GainTips")
            end
            XLuaUiManager.Open("UiTheatre6GainTips", 1, skillId, isUpGrade)
        end
    end)
end

function XTheatre6Control:BuyRelicGood(relicId, pos, cb)
    local attrPackConfig = self:GetAttrPackCfgById(relicId)
    if not self:IsCoinEnough(attrPackConfig.BuyPrice) then
        XLuaUiManager.Open("UiTheatre6PopupCommon", "", XUiHelper.GetText("Theatre6CoinNotEnough"))
        return
    end

    if self:CheckBuyLvUpRelicButMaxLv(relicId) then
        XLuaUiManager.Open("UiTheatre6PopupCommon", "", XUiHelper.GetText("Theatre6BattleShopBuyLvUpRelicTip"))
        return
    end

    -- if not self._Model.Skill:CheckSkillHad(skillId) and self._Model.Skill:IsSkillBagFull() then
    -- XUiManager.TipText("Theatre6SkillBagFull")
    -- return
    -- end
    self:SetDelayMask("BuyRelicGood")
    local req = { Pos = pos }
    XNetwork.Call(ReqMethodName.BuyGood, req, function (response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        local targetPos = response.SellShopGood.Position
        local isGetNewRelic = false
        if response.AttrPackId then
            isGetNewRelic = true
        end
        if cb then
            cb()
        end

        self:GetBSModel():UpdateShopGoodData(response.SellShopGood)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_BUY_GOOD, targetPos)
        if isGetNewRelic then
            if XLuaUiManager.IsUiShow("UiTheatre6GainTips") then
                XLuaUiManager.Close("UiTheatre6GainTips")
            end
            XLuaUiManager.Open("UiTheatre6GainTips", 2, response.AttrPackId, false)
        end
    end)
end

function XTheatre6Control:SellSkillGood(skill, cb)
    local req = { SkillId = skill }
    self:SetDelayMask("SellSkillGood")
    XNetwork.Call(ReqMethodName.SellGood, req, function (response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        if response.SkillUpdates then
            self._Model.Skill:UpdateSkillListWithOverQueue(response.SkillUpdates)
        end
        if cb then
            cb()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_SELL_GOOD, skill)
    end)
end

function XTheatre6Control:GetCurShopId()
    return self:GetBSModel():GetCurShopId()
end

function XTheatre6Control:GetShopCfg()
    local cfg = self._Model:GetStageShopConfig(self:GetCurShopId())
    if not cfg then
        XLog.Error("XTheatre6Control:GetShopCfg error: cfg is nil, shopId is ", self:GetCurShopId())
        return nil
    end
    return cfg
end

function XTheatre6Control:GetRefreshPrice()
    local cfg = self:GetShopCfg()
    local price = cfg.BaseRereshPrice + self:GetCurRefreshCount() * cfg.RefreshAddPrice

    return price
end

function XTheatre6Control:GetShopRefreshCount()
    local cfg = self:GetShopCfg()

    local refreshTime = cfg.RefreshTime - self:GetCurRefreshCount()
    return refreshTime
end

function XTheatre6Control:IsCoinEnough(price)
    return self:GetCurrentGold() >= price
end

--- 商店商品能否与角色身上同款合并升级(用于商店格子升级箭头)
---@param skillId number 商店技能商品的skillId
function XTheatre6Control:ShopHasCanUpGradeSkills(skillId)
    return self._Model.Skill:CanUpGradeSkill(skillId, true)
end

--- 角色技能能否在商店买到同款合并升级(用于角色格子升级箭头)
---@param skillId number 角色身上的skillId
function XTheatre6Control:CharacterHasCanUpGradeSkills(skillId)
    return self:HasShopSkillGood(skillId)
end

-- endregion

function XTheatre6Control:SetDelayMask(maskKey)
    XLuaUiManager.SetMask(true, maskKey)
    XScheduleManager.ScheduleOnce(function ()
        if XLuaUiManager.IsMaskShow(maskKey) then
            XLuaUiManager.SetMask(false, maskKey)
        end
    end, 100)
end

function XTheatre6Control:ClearDelayMask(maskKey)
    if XLuaUiManager.IsMaskShow(maskKey) then
        XLuaUiManager.SetMask(false, maskKey)
    end
end

--region 购买san值

---当前商店能购买的San值数量
function XTheatre6Control:GetShopSanNum()
    local cfg = self:GetShopCfg()
    return cfg and cfg.BuySanNum
end

---是否能购买San值
function XTheatre6Control:CanPurchaseSan()
    local num = self:GetShopSanNum()
    return XTool.IsNumberValid(num)
end

---当前购买San值的次数
function XTheatre6Control:GetPurchaseSanTimes()
    local roomData = self:GetCurRoomData()
    return roomData.BuySanTimes
end

---当前购买San值的剩余次数
function XTheatre6Control:GetPurchaseSanLeftTimes()
    local cfg = self:GetShopCfg()
    if not cfg then
        return 0
    end
    return cfg.BuySanMaxTimes - self:GetPurchaseSanTimes()
end

---当前购买San值的价格
function XTheatre6Control:GetPurchaseSanPrice()
    local cfg = self:GetShopCfg()
    if not cfg then
        return 0
    end
    local times = self:GetPurchaseSanTimes()
    return cfg.BuySanBasePrice + times * cfg.BuySanAddPrice
end

---是否金币不足
function XTheatre6Control:IsPurchaseSanCoinNoEnough()
    local cfg = self:GetShopCfg()
    if not cfg then
        return true
    end
    return self:GetPurchaseSanPrice() > self:GetCurrentGold()
end

---是否已达购买San值的最大次数
function XTheatre6Control:IsPurchaseSanMaxTimes()
    local cfg = self:GetShopCfg()
    if not cfg then
        return true
    end
    return self:GetPurchaseSanTimes() >= cfg.BuySanMaxTimes
end

---是否已达San值上限
function XTheatre6Control:IsSanMax()
    local modelData = self:GetCurPlayModeData()
    return modelData.San >= self:GetMaxSanValue()
end

--endregion

---商店购买技能升级遗物时，是否有可升级的技能
function XTheatre6Control:CheckBuyLvUpRelicButMaxLv(relicId)
    local skillUpAttrPackIds = self._Model:GetConfigValues("SkillUpAttrPackId")
    if table.contains(skillUpAttrPackIds, tostring(relicId)) then
        local cfg = self:GetAttrPackCfgById(relicId)
        local buffCfg = self:GetBuffConfig(cfg.BuffIds[1])
        local levelUpCount = buffCfg.BuffEffectParams[1]
        local levelUpLimit = buffCfg.BuffEffectParams[3]
        local levelUpQuality = buffCfg.BuffEffectParams[4]
        if not XMVCA.XTheatre6:HasAnyBuffUpgradableSkill(levelUpCount, levelUpLimit, levelUpQuality) then
            return true
        end
    end
    return false
end

return XTheatre6Control
