local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10282090 : XTheatre6SkillBase
local XBuffScript10282090 = XDlcScriptManager.RegBuffScript(10282090, "XBuffScript10282090", XTheatre6SkillBase)

--效果说明：  本场战斗中我方生命值首次低于30%时触发：
--· 清空双方的<格挡><暴击>【怒火】【狂暴】【点燃】【护盾】【曦光值】【剧毒】【魅惑】；
--· 造成【失心】；
--· 恢复20/40/60点【战意值】。
--草了，真是设计一时爽实现火葬场


function XBuffScript10282090:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self.ChanceCheck = 0
    self._TLRecover = {
        --不同等级的默认魅惑层数
        [1] = 20,
        [2] = 40,
        [3] = 60
    }
    self.LostHeart = self:GetNpc():GetHypnoController().LostHeartTriggerBuff
end

function XBuffScript10282090:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
end

function XBuffScript10282090:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID == self._npcUUID then
        if eventArgs._skillId ~= self._skillId then return end
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID,self._TLRecover[self._lv])
        self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,self.LostHeart,1,1,1)

        --处理格挡与暴击，从10262100抄的

        self._blockBuffId = self:GetNpc():GetBlockController().StackBuff
        self._critBuffId = self:GetNpc():GetCritController().StackBuff

        local _myBlock = self._proxy:GetBuffStacks(self._npcUUID,self._blockBuffId)
        if _myBlock > 0 then                                                           --试了下，如果不加判断全执行完，这个技能放出来会很卡，加了个if
            self._proxy:RemoveBuffByKindAndCount(self._npcUUID,self._blockBuffId,_myBlock)
            self:GetNpc():GetBlockController():RemoveDefSkillCount(_myBlock)
        end
        local _myCrit = self._proxy:GetBuffStacks(self._npcUUID,self._critBuffId)
        if _myCrit > 0 then
            self._proxy:RemoveBuffByKindAndCount(self._npcUUID,self._critBuffId,_myCrit)
            self:GetNpc():GetCritController():RemoveAtkSkillCount(_myCrit)
        end
        local _enemyBlock = self._proxy:GetBuffStacks(self._enemyUUID,self._blockBuffId)
        if _enemyBlock > 0 then
            self._proxy:RemoveBuffByKindAndCount(self._enemyUUID,self._blockBuffId,_enemyBlock)
            self:GetEnemyNpc():GetBlockController():RemoveDefSkillCount(_enemyBlock)
        end
        local _enemyCrit = self._proxy:GetBuffStacks(self._enemyUUID,self._critBuffId)
        if _enemyCrit > 0 then
            self._proxy:RemoveBuffByKindAndCount(self._enemyUUID,self._critBuffId,_enemyCrit)
            self:GetEnemyNpc():GetCritController():RemoveAtkSkillCount(_enemyCrit)
        end

        --处理怒火和狂暴，因为涅缇亚自己没有怒火狂暴，不处理自己，只检测对面有没有

        self._angerBuffId = self:GetEnemyNpc():GetAngerController().StackBuffAnger
        self._angryBuffId = self:GetEnemyNpc():GetAngerController().StackBuffAngry
        local _enemyAnger = self._proxy:GetBuffStacks(self._enemyUUID,self._angerBuffId)
        if _enemyAnger > 0 then
            self._proxy:RemoveBuffByKindAndCount(self._enemyUUID,self._angerBuffId,_enemyAnger)
        end
        local _enemyAngry = self._proxy:GetBuffStacks(self._enemyUUID,self._angryBuffId)
        if _enemyAngry > 0 then
            self._proxy:RemoveBuffByKindAndCount(self._enemyUUID,self._angryBuffId,_enemyAngry)
        end

        --处理点燃，只处理自己
        self._burningBuffId = self:GetEnemyNpc():GetBurnController().StackBuff
        local _myBurn = self._proxy:GetBuffStacks(self._npcUUID,self._burningBuffId)
        if _myBurn > 0 then
            self._proxy:RemoveBuffByKindAndCount(self._npcUUID,self._burningBuffId,_myBurn)
        end

        --护盾和耀斑，只处理对面
        self._sunBuffId = self:GetEnemyNpc():GetSunController().StackBuff
        local _mySun = self._proxy:GetBuffStacks(self._enemyUUID,self._sunBuffId)
        if _mySun > 0 then
            self._proxy:RemoveBuffByKindAndCount(self._enemyUUID,self._sunBuffId,_mySun)
        end
        if self._proxy:GetNpcProtector(self._enemyUUID) > 0 then
            self._proxy:RemoveBuff(self._enemyUUID, 111)
        end

        --剧毒和魅惑，两边都处理
        self._poisonBuffId = self:GetNpc():GetPoisonedController().StackBuff
        self._hypnoBuffId = self:GetNpc():GetHypnoController().StackBuff

        local _myPoison = self._proxy:GetBuffStacks(self._npcUUID,self._poisonBuffId)
        if _myPoison > 0 then
            self._proxy:RemoveBuffByKindAndCount(self._npcUUID,self._poisonBuffId,_myPoison)
        end
        local _myHypno = self._proxy:GetBuffStacks(self._npcUUID,self._hypnoBuffId)
        if _myHypno > 0 then
            self._proxy:RemoveBuffByKindAndCount(self._npcUUID,self._hypnoBuffId,_myHypno)
        end
        local _enemyPoison = self._proxy:GetBuffStacks(self._enemyUUID,self._poisonBuffId)
        if _enemyPoison > 0 then
            self._proxy:RemoveBuffByKindAndCount(self._enemyUUID,self._poisonBuffId,_enemyPoison)
        end
        local _enemyHypno = self._proxy:GetBuffStacks(self._enemyUUID,self._hypnoBuffId)
        if _enemyHypno > 0 then
            self._proxy:RemoveBuffByKindAndCount(self._enemyUUID,self._hypnoBuffId,_enemyHypno)
        end


    end
end

function XBuffScript10282090:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcAttribValue(self._npcUUID,ENpcAttrib.Life)
    --self:LogError("Life*5=***"..self.originAttrib1)
    self.originAttrib2 = self._proxy:GetNpcAttribMaxValue(self._npcUUID,ENpcAttrib.Life) * 0.3
    --self:LogError("MaxLife=***"..self.originAttrib2)
    if self.originAttrib1 <= self.originAttrib2 then
        if self.ChanceCheck == 0 then
            self._level:RequestInsertSkill(self._npcUUID,self._skillId)
            --self:LogError("RequestHappened***")
            self.ChanceCheck = 1
        end
    end
end

return XBuffScript10282090