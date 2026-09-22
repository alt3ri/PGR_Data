local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10282100 : XTheatre6SkillBase
local XBuffScript10282100 = XDlcScriptManager.RegBuffScript(10282100, "XBuffScript10282100", XTheatre6SkillBase)

--效果说明：  累计消耗150【战意值】后触发：
--· 获得1层<暴击>；
--· 造成1/2/3点【魅惑】。


function XBuffScript10282100:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self._StackBuffCrit = 1
    self._StackBuffHypno = {
        [1] = 1,
        [2] = 2,
        [3] = 3
    }
    self._critController = self:GetNpc():GetCritController()
    self._nowCostTL = 0
    self._targetTL = 150
    self._nowCostTL2 = 0
    self.ChanceCheck = 0
    self._totalCostTL = 0
end

function XBuffScript10282100:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
end

function XBuffScript10282100:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if self.ChanceCheck == 0 then
        self._nowCostTL2 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
        self.ChanceCheck = 1
    end
    if eventArgs._launcherUUID == self._npcUUID then
        if eventArgs._skillId ~= self._skillId then return end
        self._hypnoController:CastStackBuff(self._StackBuffHypno[self._lv],self._npcUUID)
    end
end

function XBuffScript10282100:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID == self._npcUUID then
        local skillConfig = self._proxy:Theatre6GetSkillConfig(eventArgs._skillId)
        local TLCost = skillConfig.CostTL
        self._totalCostTL = self._totalCostTL + TLCost
        --self:LogError("现在记录体力=***"..self._totalCostTL)
        if self._totalCostTL >= self._targetTL then
            self._level:RequestInsertSkill(self._npcUUID,self._skillId)
            self._totalCostTL = self._totalCostTL - self._targetTL
            return
        end
        if eventArgs._skillId ~= self._skillId then return end
        self._critController:AddSkillCount(self._StackBuffCrit)
    end
end


--function XBuffScript10282100:Update(dt) -- 抄一下瑛哲的实现逻辑，唉我草怎么我这边实现不了，换种实现方式
    --确保玩家能被赋值
    --local _nowTL = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
    --self:LogError("现在体力=***".._nowTL)
    --当前体力值
    --local _nowTL2 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
    --self:LogError("保存体力=***".._nowTL2)

    --体力消耗记录
    --if _nowTL2 > _nowTL then
        --_nowTL = _nowTL2
        --return
    --end
    --if _nowTL2 < _nowTL then
        --self._nowCostTL = self._nowCostTL + _nowTL - _nowTL2
        --_nowTL = _nowTL2
        --如果超过目标，就插入技能
        --if self._nowCostTL >= self._targetTL then
            --self._level:RequestInsertSkill(self._npcUUID,self._skillId)
            --self._nowCostTL = 0
            --return
        --end
    --end
--end

return XBuffScript10282100