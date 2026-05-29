local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript1025101 : XTheatre6SkillBase
local XBuffScript1025101 = XDlcScriptManager.RegBuffScript(1025101, "XBuffScript1025101", XTheatre6SkillBase)

--效果说明：每隔5秒，每有1层点燃造成10点伤害。
--现已废弃，用这种方式实现的点燃太耗了，改为使用点燃控制器控制

function XBuffScript1025101:ScriptInit(isGainControl)
    --初始化
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.burningId = 1025101        --点燃buffid
    self.dmgBuffId = 10251501        --伤害来源buff
    self.signalTime = 5           --定时触发间隔
    self.timer = 0          --计时器
    self.HasBurning = 0          --检查是否有点燃
    ------------执行------------
    --self:LogError(".....初始化点燃")
end

function XBuffScript1025101:Update(dt)
    --每帧执行
    --self:LogError(".....我真的挂上点燃了吗孩子们")
    XTheatre6SkillBase.Update(self, dt)
    ------------执行------------
    --if not self.HasBurning == 0 then return end
    --没有点燃时不计时，避免耗性能
    --self:LogError(".....我真的挂上点燃了吗孩子们")
    self.originAttrib1 = self._proxy:GetBuffStacks( self._npcUUID,self.dmgBuffId)
    if self._proxy:GetNpcTime(self._uuid) > self.timer then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.dmgBuffId, 1)
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.signalTime
        --每隔5秒，给角色发一层1025113
        --self:LogError(".....造成一次点燃伤害")
    end
end

function XBuffScript1025101:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
    --self:LogError(".....注册了吗")
end

function XBuffScript1025101:AfterDamageCalc(eventArgs)
    -- self:LogError(".....发一下点燃伤害")
    if eventArgs.Launcher ~= self._npcUUID then return end
    -- self:LogError(".....发两下点燃伤害")
    if eventArgs.Id ~= self.dmgBuffId then return end
    -- self:LogError(".....发三下点燃伤害")
    self.originAttrib1 = self._proxy:GetBuffStacks( self._npcUUID,1025101)
    local extraDmg = self.originAttrib1 * 10
    self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, extraDmg, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.burningId, 1)
    --1025113造成伤害时，修改造成的伤害量
    -- self:LogError(".....点燃伤害量修正值"..extraDmg)
end

--function XBuffScript1025101:InitEventCallBackRegister()
    --按需求解除注释进行注册
    --self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
--end

--function XBuffScript1015910:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --自己吃到点燃时，设定一次计时器，但想了想没必要，本身这个效果被挂上的时候就肯定吃到点燃了
    --if npcUUID == self._uuid and buffId == self.burningId then
        --self.HasBurning = 1
    --end
--end

return XBuffScript1025101

    