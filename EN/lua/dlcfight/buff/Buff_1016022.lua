local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016022 : XBuffBase
local XBuffScript1016022 = XDlcScriptManager.RegBuffScript(1016022, "XBuffScript1016022", Base)
--效果说明：【浑身】期间，场地内每秒随机触发落雷，命中自身增加伤害（Buff仅在浑身期间生效），命中敌人造成伤害

function XBuffScript1016022:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.missileId = { 10210111, 10210126, 10210127, 10210128, 10210129, 10210130, 10210131 }
    self.damageMagicId = 1021003
    self.atkBuffId = 1021002
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.signalId = 1015903 --【浑身】标记
    self.targetId = 0
    self.cd = 1
    self.timer = 0
    self.prob = 50
    self.enhBuffId = 1016239    --【浑身】通用强化buff标记
    self.enhLevel = 0
    ------------执行------------

end
---@param dt number @ delta time
function XBuffScript1016022:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --Buff不存在时，不运行后续逻辑
    if not self._proxy:CheckBuffByKind(self._uuid, self.signalId) then
        return
    end
    if not self._proxy:CheckBuffByKind(self._uuid, self.battleStartBuffId) then
        return
    end
    if self.targetId == 0 then
        return
    end
    local selfPos = self._proxy:GetNpcPosition(self._uuid)
    local targetPos = self._proxy:GetNpcPosition(self.targetId)
    if self._proxy:GetNpcTime(self._uuid) >= self.timer then
        local seed = self._proxy:Random(1, 100)
        if seed > self.prob then
            self._proxy:LaunchMissileFromPosToPos(self._uuid, self.missileId[self.enhLevel], self.missileId[self.enhLevel], targetPos, targetPos, self.magicLevel)
        else
            self._proxy:LaunchMissileFromPosToPos(self._uuid, self.missileId[self.enhLevel], self.missileId[self.enhLevel], selfPos, selfPos, self.magicLevel)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.atkBuffId, self.enhLevel)
        end
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.cd
    end

end

--region EventCallBack
function XBuffScript1016022:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1016022:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.cd
        --更新强化Buff标记层数
        self.enhLevel = self._proxy:GetBuffStacks(self._uuid, self.enhBuffId)
    end

end


--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016022:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016022:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016022
