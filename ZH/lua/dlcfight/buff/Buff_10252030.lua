local BurnBuff = require("Gameplay/Theatre6/AffixController/XTheatre6BurnController").StackBuff
local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10252030 : XTheatre6SkillBase
local XBuffScript10252030 = XDlcScriptManager.RegBuffScript(10252030, "XBuffScript10252030", XTheatre6SkillBase)

--效果说明：自身对处于【点燃】状态的对手使用3次技能时触发：造成击飞

function XBuffScript10252030:ScriptInit(isGainControl) --初始化
    self._damageTimer = 0
    -- self._stackCountAtk = 20
    --self:LogError("....【插入式技能3】初始化完成")
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript10252030:HandleEvent(eventType, eventArgs)
    XTheatre6SkillBase.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript10252030:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript10252030:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    local targetNpc = self._enemyUUID
    if eventArgs._skillId == self._skillId then
        self._HitFlyController:AddSkillCount(self._stackCount)
    end
    if not self._proxy:CheckBuffByKind(targetNpc,BurnBuff) then return end
    self._damageTimer = self._damageTimer + 1
    if self._damageTimer >= 3 then
        self._level:RequestInsertSkill(self._npcUUID,self._skillId)
        --self:LogError("....【插入式技能3】进入队列")
        self._damageTimer = 0
    end
end

    -- self._proxy:ApplyMagic(self._uuid, self._uuid, 1025904,1,0,self._stackCountAtk)

return XBuffScript10252030

