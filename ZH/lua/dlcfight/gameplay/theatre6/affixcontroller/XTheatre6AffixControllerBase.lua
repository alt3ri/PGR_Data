local XTheatre6FightBase = require("Gameplay/Theatre6/XTheatre6FightBase")

---词条控制器基类
---提供技能计数逻辑
---提供叠层buff逻辑
---提供更新逻辑
---@class XTheatre6AffixControllerBase:XTheatre6FightBase
---@field UpdateType ETheatre6AffixControllerUpdateType 更新类型
---@field Name string 类型名
---@field StackBuff integer 叠层buffId
---@field HitAffixTag integer [受击效果tag, 只能为Missle.Theatre6.HitAffixType的子tag](https://kurogame.feishu.cn/wiki/UadMwIczpirAH9k22YPcOI7WnJc#share-Pyibd6tS5oSwOAxOLvMccKmmn2c)
local XTheatre6AffixControllerBase = XClass(XTheatre6FightBase, "XTheatre6ControllerBase")

XTheatre6AffixControllerBase.Name2Path = {
    Crit = "Gameplay/Theatre6/AffixController/XTheatre6CritController",
    HitFly = "Gameplay/Theatre6/AffixController/XTheatre6HitFlyController",
    HitDown = "Gameplay/Theatre6/AffixController/XTheatre6HitDownController",
    Burn = "Gameplay/Theatre6/AffixController/XTheatre6BurnController",
    Block = "Gameplay/Theatre6/AffixController/XTheatre6BlockController",
}

---肉鸽6词条控制器更新类型
---@enum ETheatre6AffixControllerUpdateType
local EUpdateType = {
    None = 0, --不更新或自定义更新
    Buff = 1, --当且仅当存在叠层buff时更新
    Force = 2 --强制持续更新, 不论是否存在叠层buff
}
XTheatre6AffixControllerBase.EAffixControllerUpdateType = EUpdateType

---肉鸽6词条攻击tag生效类型
---@enum ETheatre6AffixControllerHitTagSourceType
local EHitTagSourceType = {
    None = 0,       --无效果
    StaticAtk = 1,  --静态攻击效果
    DynamicAtk = 2, --动态添加的攻击效果
    DynamicDef = 4, --动态添加的受击效果
}
XTheatre6AffixControllerBase.EHitTagSourceType = EHitTagSourceType

---@type table<string, XTheatre6AffixControllerBase>
XTheatre6AffixControllerBase.Name2Class = {}

local XGameplayTag = require "Enum/XGameplayTag"
---@type table<EGameplayTag, string>
XTheatre6AffixControllerBase.Tag2Name = {
    [XGameplayTag.Missile_Theatre6_HitAffixType_Burn] = "Burn",
    [XGameplayTag.Missile_Theatre6_HitAffixType_Crit] = "Crit",
    [XGameplayTag.Missile_Theatre6_HitAffixType_HitFly] = "HitFly",
    [XGameplayTag.Missile_Theatre6_HitAffixType_HitDown] = "HitDown",
    [XGameplayTag.Missile_Theatre6_HitAffixType_Block] = "Block",
}


---@param name string
---@return XTheatre6AffixControllerBase
function XTheatre6AffixControllerBase:GetAffixControllerClass(name)
    return self.Name2Class[name] or self:AddAffixControllerClass(name)
end

function XTheatre6AffixControllerBase:AddAffixControllerClass(name)
    local class = self.Name2Class[name]
    if class then return class end
    local path = self.Name2Path[name]
    if not path then
        self:LogError("GetOrAddControllerClass Error: Unkown Controller " .. tostring(name))
        return nil
    end

    class = require(path)
    if not class then
        self:LogError("GetOrAddControllerClass Error: Unkown Path " .. tostring(path))
        return nil
    end

    return self:RegisterCotrollerClass(class, name)
end

---注册一个新的控制器类
---@param class XTheatre6AffixControllerBase
---@param name string
function XTheatre6AffixControllerBase:RegisterCotrollerClass(class, name)
    class.Name = name
    self.Name2Class[name] = class
    local tag = class.HitAffixTag
    if tag then self.Tag2Name[tag] = name end
    return class
end

--region 初始化

---@param proxy XDlcCSharpFuncs
---@param npc XTheatre6CharBase
function XTheatre6AffixControllerBase:Ctor(proxy, npc)
    self._proxy = proxy
    self._npc = npc                                            --宿主单位对象, 和叠层buff的目标单位一致

    self._atkCount = 0                                         --剩余攻击附魔次数
    self._defCount = 0                                         --剩余防御附魔次数
    self._buffCount = 0                                        --剩余buff层数
    self._hasRegisterAtkModifier = false                       --是否已经激活攻击附魔
    self._hasRegisterDefModifier = false                       --是否已经激活防御附魔
    self._isTriggered = false                                  --当前技能内是否已经触发并消耗次数

    self._npcUUID = self._npc:GetUUID()                        --宿主单位UUID
    self._uuid = self._npcUUID                                 --宿主单位UUID
    self._npcId = self._proxy:GetNpcTemplate(self._npcUUID).Id --宿主单位配置ID

    -- self:InitEnemyUUID()
    -- self._level = self._proxy:GetLevelScriptObject(EScriptType.LevelLogic, self._proxy:GetCurrentLevelId()) --[[@as XLevelScript.1081]]

    self._name = self._npcId .. "." .. self._npcUUID .. ".AffixController." .. self.__cname
    -- self:LogError("Ctor is called")
end

function XTheatre6AffixControllerBase:PostInit()
    self:OnEnterLevel(self._proxy:GetCurrentLevelId())
    self:InitLuaEvent()
    self:InitEventCallBackRegister()
    self:InitDefaultEventCallBackRegister()

    if self.UpdateType == EUpdateType.Force then
        self:RegisterUpdate()
    end
end

function XTheatre6AffixControllerBase:InitDefaultEventCallBackRegister()
    XTheatre6FightBase.InitDefaultEventCallBackRegister(self)
    if not self.StackBuff then return end
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

---注册Lua事件
---@param eventType number 来自EFightLuaEvent
function XTheatre6AffixControllerBase:RegisterLuaEvent(eventType)
    if self._luaEventDict[eventType] then
        return
    end
    self._luaEventDict[eventType] = true

    self._npc:RegisterLuaEvent(eventType)
end

--endregion

--region 接口

---检查是否可以触发打击效果(触发效果是指是否消耗效果次数, 实际是否生效还要参考冲突关系)
---@param missileUUID integer
---@param launcherNpcUUID integer
---@param targetNpcUUID integer
---@param srcType ETheatre6AffixControllerHitTagSourceType 触发来源类型
---@param isActivate boolean 是否为特殊hit
---@param hitCount integer 这是该子弹的第几次命中
function XTheatre6AffixControllerBase:CheckCanTriggerByHit(missileUUID, launcherNpcUUID, targetNpcUUID, srcType,
                                                           isActivate, hitCount)
    --通过静态标签触发
    if (srcType & EHitTagSourceType.StaticAtk ~= 0) and launcherNpcUUID == self._npcUUID then return true end

    --通过动态标签触发
    if not isActivate then return false end
    if (srcType & EHitTagSourceType.DynamicAtk ~= 0) and launcherNpcUUID == self._npcUUID then return true end
    if (srcType & EHitTagSourceType.DynamicDef ~= 0) and targetNpcUUID == self._npcUUID then return true end
    return false
end

function XTheatre6AffixControllerBase:AddAtkSkillCount(count)
    if count == 0 then return end
    local oldCount = self._atkCount
    count = count or 1
    self._atkCount = oldCount + count
    self:OnAtkSkillCountChange(oldCount, self._atkCount)
end

function XTheatre6AffixControllerBase:AddDefSkillCount(count)
    if count == 0 then return end
    local oldCount = self._defCount
    count = count or 1
    self._defCount = oldCount + count
    self:OnDefSkillCountChange(oldCount, self._defCount)
end

function XTheatre6AffixControllerBase:RemoveAtkSkillCount(count)
    if count == 0 then return end
    local oldCount = self._atkCount
    count = count or 1
    local newCount = oldCount - count
    if newCount < 0 then newCount = 0 end
    if newCount == oldCount then return end
    self._atkCount = newCount
    self:OnAtkSkillCountChange(oldCount, newCount)
end

function XTheatre6AffixControllerBase:RemoveDefSkillCount(count)
    if count == 0 then return end
    local oldCount = self._defCount
    count = count or 1
    local newCount = oldCount - count
    if newCount < 0 then newCount = 0 end
    if newCount == oldCount then return end
    self._defCount = newCount
    self:OnDefSkillCountChange(oldCount, newCount)
end

function XTheatre6AffixControllerBase:CastStackBuff(count, casterUUID)
    if count == 0 then return end
    casterUUID = casterUUID or self._npcUUID
    self._casterUUID = casterUUID
    count = count or 1
    -- self:LogError("Apply Magic count is " .. count)
    self._proxy:ApplyMagic(casterUUID, self._npcUUID, self.StackBuff, 0, 0, count)
end

function XTheatre6AffixControllerBase:RemoveStackBuff(count)
    if count == 0 then return end
    count = count or 1
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.StackBuff, count)
end

function XTheatre6AffixControllerBase:ClearStackBuff()
    self._proxy:RemoveBuff(self._npcUUID, self.StackBuff)
end

function XTheatre6AffixControllerBase:SetAtkCountByBuff()
    local delta = self._buffCount - self._atkCount
    if delta >= 0 then
        return self:AddAtkSkillCount(delta)
    else
        return self:RemoveAtkSkillCount(-delta)
    end
end

function XTheatre6AffixControllerBase:SetDefCountByBuff()
    local delta = self._buffCount - self._defCount
    if delta >= 0 then
        return self:AddDefSkillCount(delta)
    else
        return self:RemoveDefSkillCount(-delta)
    end
end

function XTheatre6AffixControllerBase:SetBuffByAtkCount()
    local delta = self._atkCount - self._buffCount
    if delta >= 0 then
        return self:CastStackBuff(delta, self._casterUUID)
    else
        return self:RemoveStackBuff(-delta)
    end
end

function XTheatre6AffixControllerBase:SetBuffByDefCount()
    local delta = self._defCount - self._buffCount
    if delta >= 0 then
        return self:CastStackBuff(delta, self._casterUUID)
    else
        return self:RemoveStackBuff(-delta)
    end
end

function XTheatre6AffixControllerBase:RegisterUpdate()
    self._npc:RegisterAffixControllerUpdate(self.Name)
end

function XTheatre6AffixControllerBase:UnregisterUpdate()
    self._npc:UnRegisterAffixControllerUpdate(self.Name)
end

--Todo:这里注册打击修改器的方式无法延申到技能之外, 因此会对脱手伤害失真

function XTheatre6AffixControllerBase:RegisterAtkModifier()
    if self._hasRegisterAtkModifier then return end
    self._hasRegisterAtkModifier = true
    self._npc:RegisterAtkModifier(self.HitAffixTag)
end

function XTheatre6AffixControllerBase:UnregisterAtkModifier()
    if not self._hasRegisterAtkModifier then return end
    self._hasRegisterAtkModifier = false
    self._npc:UnregisterAtkModifier(self.HitAffixTag)
end

function XTheatre6AffixControllerBase:RegisterDefModifier()
    if self._hasRegisterDefModifier then return end
    self._hasRegisterDefModifier = true
    self._npc:RegisterDefModifier(self.HitAffixTag)
end

function XTheatre6AffixControllerBase:UnregisterDefModifier()
    if not self._hasRegisterDefModifier then return end
    self._hasRegisterDefModifier = false
    self._npc:UnregisterDefModifier(self.HitAffixTag)
end

---获取叠层buff层数
---@return integer
function XTheatre6AffixControllerBase:GetStackBuffCount()
    return self._buffCount
end

---获取叠层BuffId
---@return integer
function XTheatre6AffixControllerBase:GetStackBuffId()
    return self.StackBuff
end

--endregion

--region 数据维护

function XTheatre6AffixControllerBase:UpdateBuffCount()
    local newCount = self._proxy:GetBuffStacks(self._npcUUID, self.StackBuff)
    -- self:LogError("UdpateBuffCount is called and new Count is " .. newCount .. ", stack buff is " .. self.StackBuff)
    local oldCount = self._buffCount
    if newCount == oldCount then return end
    self._buffCount = newCount
    return self:OnBuffCountChange(oldCount, newCount)
end

--endregion

--region 事件

--Todo:这里要验证下面两个Buff事件的时机, 现已知OnNpcRemoveBuffEvent是不准确的

function XTheatre6AffixControllerBase:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    -- self:LogError("OnNpcAddBuffEvent")
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= self.StackBuff then return end
    self:UpdateBuffCount()
end

function XTheatre6AffixControllerBase:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    -- self:LogError("OnNpcRemoveBuffEvent")
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= self.StackBuff then return end
    self:UpdateBuffCount()
end

function XTheatre6AffixControllerBase:OnBuffCountChange(oldCount, newCount)
    -- self:LogError("buff count change to " .. tostring(newCount))
    if self.UpdateType ~= EUpdateType.Buff then return end
    if oldCount == 0 then
        self:RegisterUpdate()
        return
    elseif newCount == 0 then
        self:UnregisterUpdate()
        return
    end
end

function XTheatre6AffixControllerBase:OnAtkSkillCountChange(oldCount, newCount)
end

function XTheatre6AffixControllerBase:OnDefSkillCountChange(oldCount, newCount)
end

function XTheatre6AffixControllerBase:OnLuaSkillStart(eventArgs)
    self._isTriggered = false
end

function XTheatre6AffixControllerBase:OnLuaSkillEnd(eventArgs)
    if not self._isTriggered then return end
    local launcherUUID = eventArgs._launcherUUID
    -- self:LogError("OnLuaSkillEnd is called , luancherUUID = " .. launcherUUID .. ", self._npcUUID = " .. self._npcUUID)
    if launcherUUID == self._npcUUID then
        self:RemoveAtkSkillCount()
    else
        self:RemoveDefSkillCount()
    end
    self._isTriggered = false
end

---受击触发词条效果的通知
---@param missileUUID integer
---@param launcherNpcUUID integer
---@param targetNpcUUID integer
---@param isActivate boolean 是否为特殊hit
---@param srcType ETheatre6AffixControllerHitTagSourceType 触发来源类型
---@param triggeredTags table<EGameplayTag, boolean> 成功触发的全部效果列表
---@param actionId integer 触发攻击的动作id
---@param skillId integer 触发攻击的技能id
---@param hitCount integer 这是该子弹的第几次命中
function XTheatre6AffixControllerBase:OnLuaHitModify(missileUUID, launcherNpcUUID, targetNpcUUID, isActivate,
                                                     srcType, triggeredTags, actionId, skillId, hitCount)
    if not self._isTriggered then self._isTriggered = true end
end

--endregion

function XTheatre6AffixControllerBase:DispatchLuaEvent(eventType, eventArgs, targetType)
    return self._npc:DispatchLuaEvent(eventType, eventArgs, targetType)
end

return XTheatre6AffixControllerBase
