local Base = require("Buff/BuffBase/XBuffBase")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")

---@class XBuffScript8060030 : XBuffBase
local XBuffScript8060030 = XDlcScriptManager.RegBuffScript(8060030, "XBuffScript8060030", Base)
--效果说明：自动复活有CD

function XBuffScript8060030:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicLevel=1 --等新接口直接获取自己的BUFF等级
    self.magicId=8060031 --复活BUFF

    self.hasBuff=false
    self.hasLevel=false
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript8060030:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if not self._proxy :CheckNpc(self._uuid)  then return end
    if self.hasLevel==false then
        self.hasLevel,self.magicLevel=self._proxy:TryQueryBuffLevel(self._uuid,8060030)--获取自身的BUFF等级
        self.hasLevel=true
    end
end

--region EventCallBack
function XBuffScript8060030:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcDamageBefore)
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcDamageAfter)
end

function XBuffScript8060030:BeforeDamageCalc(eventArgs)
    local damageMagicId=eventArgs.Id
    local damageTags=self._proxy:GetMagicTags(damageMagicId)
    if damageTags[1]==EGameplayTag.Magic_RelinkDamage_HitType_Break --tag是破韧技伤害
            and not
    self._proxy:CheckBuffByKind(self._uuid,self.magicId)--没上过BUFF
    then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel) --上BUFF
    else
        if self._proxy:CheckBuffByKind(self._uuid,self.magicId) then
            self._proxy:RemoveBuff(self._uuid,self.magicId) --伤害类型不对就删BUFF
        end
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript8060030:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060030:Terminate()
    Base.Terminate(self)
end

return XBuffScript8060030
