---@class XEquipLevelUpConsume
local XEquipLevelUpConsume = XClass(nil, "XEquipLevelUpConsume")

function XEquipLevelUpConsume:Ctor()
    self.Type = 0 --类型（0道具,1装备）
    self.Id = 0
    self.TemplateId = 0
    self.SelectCount = 0 --已选择数量
    self.Count = 0 --可用数量快照
    self.AddExp = 0 --提供经验值
    self.CostMoney = 0 --消耗货币（被吃掉时）
    self.CanAutoSelect = true --是否可以被自动选取
end

--以道具类型初始化
function XEquipLevelUpConsume:InitItem(itemId, count)
    self.Type = 0
    self.Id = itemId
    self.TemplateId = itemId
    self.Count = count or XDataCenter.ItemManager.GetCount(itemId)
    self.AddExp = XDataCenter.ItemManager.GetItemsAddEquipExp(itemId)
    self.CostMoney = XDataCenter.ItemManager.GetItemsAddEquipCost(itemId)
    self.CanAutoSelect = true
end

--以装备类型初始化
function XEquipLevelUpConsume:InitEquip(equipId, canAutoSelect, count)
    self.Type = 1
    self.Id = equipId
    self.TemplateId = XMVCA.XEquip:GetEquipTemplateId(equipId)
    self.Count = count or 1
    self.AddExp = XMVCA.XEquip:GetEquipAddExp(equipId)

    local equipCfg = XMVCA.XEquip:GetConfigEquip(self.TemplateId)
    self.CostMoney = XMVCA.XEquip:GetEatEquipCostMoney(equipCfg.Site, equipCfg.Star)
    self.CanAutoSelect = canAutoSelect == true
end

function XEquipLevelUpConsume:IsItem()
    return self.Type == 0
end

function XEquipLevelUpConsume:IsEquip()
    return self.Type == 1
end

--获取消耗项唯一键（Type + Id，避免道具 Id 和装备 Id 碰撞）
function XEquipLevelUpConsume:GetConsumeKey()
    return tostring(self.Type) .. "_" .. tostring(self.Id)
end

--获取品质
function XEquipLevelUpConsume:GetQuality()
    if self:IsItem() then
        return XDataCenter.ItemManager.GetItemQuality(self.TemplateId)
    else
        return XMVCA.XEquip:GetEquipQuality(self.TemplateId)
    end
end

--获取星级
function XEquipLevelUpConsume:GetStar()
    if self:IsItem() then
        return 0
    else
        return XMVCA.XEquip:GetEquipStar(self.TemplateId)
    end
end

--获取等级
function XEquipLevelUpConsume:GetLevel()
    if self:IsItem() then
        return 0
    else
        return XMVCA.XEquip:GetEquipLevel(self.Id)
    end
end

--获取优先级
function XEquipLevelUpConsume:GetPriority()
    if self:IsItem() then
        return XDataCenter.ItemManager.GetItemPriority(self.TemplateId)
    else
        return XMVCA.XEquip:GetEquipPriority(self.TemplateId)
    end
end

--获取可用数量快照
function XEquipLevelUpConsume:GetCount()
    return self.Count
end

function XEquipLevelUpConsume:CheckSelectCount()
    return self:GetCount() > self.SelectCount
end

--获取剩余数量（总数量 - 已选择数量）
function XEquipLevelUpConsume:GetLeftCount()
    if not self:CheckSelectCount() then
        return 0
    end
    return self:GetCount() - self.SelectCount
end

--获取经验
function XEquipLevelUpConsume:GetAddExp()
    return self.AddExp
end

--获取消耗螺母
function XEquipLevelUpConsume:GetCostMoney()
    return self.CostMoney
end

--吃掉一个
function XEquipLevelUpConsume:Eat()
    if not self:CheckSelectCount() then
        return
    end
    self.SelectCount = self.SelectCount + 1
end

--吐出一个
function XEquipLevelUpConsume:Vomit()
    if self.SelectCount < 1 then
        return
    end
    self.SelectCount = self.SelectCount - 1
end

function XEquipLevelUpConsume:IsSelect()
    return self.SelectCount > 0
end

--重置选择
function XEquipLevelUpConsume:Reset()
    self.SelectCount = 0
end

return XEquipLevelUpConsume
