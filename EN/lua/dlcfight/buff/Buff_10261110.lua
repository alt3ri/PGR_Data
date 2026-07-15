local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10261110 : XTheatre6SkillBase
local XBuffScript10261110 = XDlcScriptManager.RegBuffScript(10261110, "XBuffScript10261110", XTheatre6SkillBase)

--效果说明：
--若是自身的<坚毅>层数>=3层，自身每有10点【体力】属性，额外提高5/10/15%攻击伤害。

function XBuffScript10261110:ScriptInit(isGainControl) --初始化
    --注册技能伤害id
    self._damageMagicId = {
        [1] = 1026514,
        [2] = 1026515,
        [3] = 1026516
    }
    --所需体力
    self._needTL = 10
    --所需坚毅层数
    self._targetBlock = 3
    --是否满足条件，满足后才会修改伤害
    self._trigger = false

    --提升伤害比例(万分比）
    self.dictExtraDamage = {
        [1] = 500,
        [2] = 1000,
        [3] = 1500
    }
    --伤害段数
    self._damageTimes = 12
    
    self._blockController = self:GetNpc():GetBlockController()
    
end

function XBuffScript10261110:OnLuaSkillStart(eventArgs)
    ------------执行------------
    --保底处理，如果不是自己/技能id不对，直接退出
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end

    --判断格挡层数
    local _nowBlock = self._blockController:GetStackBuffCount()
    if _nowBlock < self._targetBlock then return end
    
    self._trigger = true
end

function XBuffScript10261110:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

--实际调整伤害
function XBuffScript10261110:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    -- 1. 遍历自建的技能伤害ID列表，校验 eventArgs.Id 是否符合
    local isMatch = false
    for _, magicId in ipairs(self._damageMagicId) do
        if eventArgs.Id == magicId then
            isMatch = true
            break
        end
    end
    -- 2. 如果不匹配任何一个ID，直接退出
    if not isMatch then return end
    
    --如果没有满足条件，或者已经修改过伤害了，直接返回
    if self._trigger == false then return end
    --判断要改多少伤害
    local curStamina = self._proxy:GetNpcGameplayAttribMaxValue(self._npcUUID, ETheatre6AttribType.Stamina)
    --按照伤害段数，将增伤进行平铺
    local extraPermyriad = curStamina / self._needTL * self.dictExtraDamage[self._lv] / self._damageTimes
    local newPermyriad = eventArgs.PhysicalPermyriad + extraPermyriad
    --调整伤害
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, newPermyriad, eventArgs.ElementPermyriad,
        eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
    
end

function XBuffScript10261110:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --本技能放完后，取消加伤
    if self._trigger == true then self._trigger = false end
end

return XBuffScript10261110
