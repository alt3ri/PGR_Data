---Control部分类，此处用于处理局内商店相关逻辑
---@type XTheatre6Control
local XTheatre6Control = XClassPartial('XTheatre6Control')
local ReqMethodName = {
    ShopFresh = "Theatre6ShopFreshRequest",
    EndShop = "Theatre6EndShopRequest",
    ShopGoodLock = "Theatre6ShopGoodLockRequest",
    BuyGood = "Theatre6ShopGoodBuyRequest",
    SellGood = "Theatre6ShopGoodSellRequest",
}

function XTheatre6Control:EnterShop()

end

function XTheatre6Control:GetBSModel()
    return self._Model.BattleShop
end

---商店刷新请求
function XTheatre6Control:ShopFreshRequest(cb)
    if self:GetRefreshPrice() > self:GetCurrentGold() then
            XLuaUiManager.Open("UiTheatre6PopupCommon", "", XUiHelper.GetText("Theatre6CoinNotEnough"))
    
        return
    end
    local req = { ShopFreshCount = self:GetCurRefreshCount() }
    XNetwork.Call(ReqMethodName.ShopFresh, req, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        self:GetBSModel():SetShopFreshCount(self._Model:GetCurPlayMode(), response.ShopFreshCount)
        self:GetBSModel():SetShopGoods(self._Model:GetCurPlayMode(), response.ShopGoods)
        if cb then
            cb()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_SHOP_REFRESH)
    end,nil,nil,nil,true)
end

---离开商店请求
function XTheatre6Control:LeaveShopRequest(cb)
    XNetwork.Call(ReqMethodName.EndShop, nil, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        if cb then
            cb()
        end
    end)
end

---锁定或解锁商品请求
function XTheatre6Control:ShopGoodLockRequest(pos, isLock, cb)
    local req = { Pos = pos, IsLock = isLock }
    XNetwork.Call(ReqMethodName.ShopGoodLock, req, function(response)
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
    return  self:GetBSModel():GetShopGoods()
end



---检查商店中是否有未售出的指定技能商品
function XTheatre6Control:HasShopSkillGood(skillId)
    local shopGoods = self:GetShopGoods()
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

    if not self._Model.Skill:CheckSkillHad(skillId) and self._Model.Skill:IsSkillBagFull() then
        XLuaUiManager.Open("UiTheatre6PopupCommon", "", XUiHelper.GetText("Theatre6SkillMax"))
        return
    end
    local req = { Pos = pos }
    XNetwork.Call(ReqMethodName.BuyGood, req, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        local isGetNewSkill = false
        local isUpGrade = false

        local targetPos = response.SellShopGood.Position
        local result = response.SellShopGood.IsSell
        local isLock = response.SellShopGood.IsLock
        local skillId = response.SellShopGood.GoodId

        if response.SkillUpdates then
            for _, skillUpdateData in ipairs(response.SkillUpdates) do
                self._Model.Skill:UpdateSkillsWithOverQueue(skillUpdateData)
                if skillUpdateData.AddSkill then
                    isGetNewSkill = true
                end
                if skillUpdateData.ReplaceSkills and #skillUpdateData.ReplaceSkills > 0 then
                    --skillData=skillID,Position,SlotType
                    for index, skillData in pairs(skillUpdateData.ReplaceSkills) do
                        local replaceCfg = self:GetSkillCfgById(skillData.SkillId)
                        local buyCfg = self:GetSkillCfgById(skillId)
                        if replaceCfg and buyCfg and replaceCfg.SkillKey == buyCfg.SkillKey and replaceCfg.Level == buyCfg.Level + 1 then
                            isUpGrade = true
                            skillId = skillData.SkillId
                            break
                        end
                    end
                end
            end
        end
        if cb then
            cb()
        end


        self:GetBSModel():UpdateShopGoodIsSell(targetPos, result)
        self:GetBSModel():UpdateShopGoodIsLock(targetPos, isLock)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_BUY_GOOD, targetPos)
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

    -- if not self._Model.Skill:CheckSkillHad(skillId) and self._Model.Skill:IsSkillBagFull() then
    --     XUiManager.TipText("Theatre6SkillBagFull")
    --     return
    -- end
    local req = { Pos = pos }
    XNetwork.Call(ReqMethodName.BuyGood, req, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        local targetPos = response.SellShopGood.Position
        local result = response.SellShopGood.IsSell
        local isLock = response.SellShopGood.IsLock
        local isGetNewRelic = false
        if response.AttrPackId then
            isGetNewRelic = true
        end
        if cb then
            cb()
        end

        self:GetBSModel():UpdateShopGoodIsSell(targetPos, result)
        self:GetBSModel():UpdateShopGoodIsLock(targetPos, isLock)
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
    XNetwork.Call(ReqMethodName.SellGood, req, function(response)
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


---商店商品能否与角色身上同款合并升级(用于商店格子升级箭头)
---@param skillId number 商店技能商品的skillId
function XTheatre6Control:ShopHasCanUpGradeSkills(skillId)
    return self._Model.Skill:CanUpGradeSkill(skillId, true)
end

---角色技能能否在商店买到同款合并升级(用于角色格子升级箭头)
---@param skillId number 角色身上的skillId
function XTheatre6Control:CharacterHasCanUpGradeSkills(skillId)
    return self:HasShopSkillGood(skillId)
end

--endregion
