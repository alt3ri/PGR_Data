local Base = require("Common/XFightBase")

---@class XBuffScript1015426 : XFightBase
local XBuffScript1015426 = XDlcScriptManager.RegBuffScript(1015426, "XBuffScript1015426", Base)

--效果说明：冰伤提升20点，自身每有一个技能带来的增益效果，角色冰伤额外提升30点，上限200点（无人机视作角色增益）
function XBuffScript1015426:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015427      --Buff id
    self.magicLevel = 1         --buff等级
    self.magicMaxLevel = 7      --最大buff等级
    self.buffKind = 100         --检测的buff种类
    self.buffCount = 0          --初始化Buff计数
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --基础增伤效果
end

---@param dt number @ delta time 
function XBuffScript1015426:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015426:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)        -- OnNpcRemoveBuffEvent
end

function XBuffScript1015426:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --有新Buff时检查一下
    self:UpdateMagicLevel()
end

function XBuffScript1015426:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --有Buff失效时检查一下
    self:UpdateMagicLevel()
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015426:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015426:Terminate()
    Base.Terminate(self)
end

--更新Buff等级逻辑
function XBuffScript1015426:UpdateMagicLevel()
    --看当前buff数量，如果Buff数量没变化，就不走后续流程了
    local buffCountTemp = self._proxy:GetBuffCountByKind(self._uuid, self.buffKind)
    if buffCountTemp == self.buffCount then
        return
    end
    --如果Buff数量发生变化，则更新等级
    self._proxy:RemoveBuff(self._uuid,self.magicId)     --删除旧Buff
    self.magicLevel = math.min(self.buffCount, self.magicMaxLevel)      --更新Buff等级
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --更新Buff
end

return XBuffScript1015426
