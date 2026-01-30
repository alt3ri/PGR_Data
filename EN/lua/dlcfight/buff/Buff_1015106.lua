local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015106 : XBuffBase
local XBuffScript1015106 = XDlcScriptManager.RegBuffScript(1015106, "XBuffScript1015106", Base)

--效果说明：每释放一次技能，提升【雷属性伤害提升】X%（上限4X点）

------------配置------------
local ConfigMagicIdDict = {
    [1015106] = 1015107,
    [1015160] = 1015161,
    [1015162] = 1015163,
    [1015164] = 1015165,
    [1016114] = 1016115
}
local ConfigRuneIdDict = {
    [1015106] = 20106,
    [1015160] = 20160,
    [1015162] = 20162,
    [1015164] = 20164,
    [1016114] = 20164
}

function XBuffScript1015106:Init() --初始化
    Base.Init(self)
    ------------配置------------
    self.initialBuffLevel = 1  -- 初始buff等级
    self.BuffId = ConfigMagicIdDict[self._buffId]     -- 雷伤BUFF
    self.buffCount = 0         -- buff叠加计数器
    self.triggerCD = 1            -- BUFF叠加间隔（秒）
    self.maxCount = 4  --最大叠加次数
    self.skillStartType = 2    --起手技能的标记
    self.runeId = ConfigRuneIdDict[self._buffId]
    ------------执行------------
    self.cdTimer = 0  --计算宝珠CD的Timer
end

---@param dt number @ delta time 
function XBuffScript1015106:Update(dt) --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015106:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)         -- OnNpcCastSkillEvent
end

function XBuffScript1015106:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if self.buffCount >= self.maxCount then return end
    if self._proxy:GetNpcTime(self._uuid) < self.cdTimer then return end
    --判断一下是不是自己释放的
    if launcherId ~= self._uuid then
        return
    end
    local skillType = self._proxy:GetActionType(skillId)
    --判断一下是不是技能起手，待定
    if skillType ~= self.skillStartType then
        return
    end
    self._proxy:ApplyMagic(self._uuid,self._uuid,self.BuffId,self.initialBuffLevel)
    self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
    self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    self.buffCount = self.buffCount + 1
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015106:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015106:Terminate()
    Base.Terminate(self)
end


return XBuffScript1015106
