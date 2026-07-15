local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---首席指挥官角色脚本
---@class XChar8058 : XFightBase
local XChar8058 = XDlcScriptManager.RegCharScript(8058, "XChar8058", Base)
--region 函数: 脚本生命周期

function XChar8058:Init() --初始化
    Base.Init(self)
    --[[   self.zidan = true
       self.cishu = true
       self.targetPos = self._proxy:GetNpcPosition(self._uuid)
       self._proxy:LaunchMissileFromPosToPos(self._uuid,80530115,80580101,self.targetPos,self.targetPos,1)--从目标位置向目标位置发特效
       self.texiao1,self.texiao11 = self._proxy:LaunchMissileFromPosToPos(self._uuid,80530115,80580106,self.targetPos,self.targetPos,1)--从目标位置向目标位置发特效]]
    self.targetPos = self._proxy:GetNpcPosition(self._uuid)
    self._proxy:LaunchMissileFromPosToPos(self._uuid,82100704,80580109,self.targetPos,self.targetPos,1)--闪光特效
    local Luojian1 , var2 =self._proxy:LaunchMissileFromPosToPos(self._uuid,82100704,80580107,self.targetPos,self.targetPos,1)--落剑出场特效
    self.Luojian1 = var2
    self._proxy:AddTimerTask(1.9, function()--延迟5秒后，释放影牌技能
        self._proxy:LaunchMissileFromPosToPos(self._uuid,82100704,80580108,self.targetPos,self.targetPos,1)--从目标位置向目标位置发特效
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053012, 1)
        local FenTan1 , FenTan2 =  self._proxy:LaunchMissileFromPosToPos(self._uuid,82100704,80580110,self.targetPos,self.targetPos,1)--从目标位置向目标位置发特效
        self.Fentan = FenTan2
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8072006, 1)
        --[[self._proxy:ApplyMagic(self._uuid, self._uuid, 8058002, 1)]]
    end)
    self.PlayUUID =  self._proxy:GetPlayerNpcList()

    local Target = self.PlayUUID[1]
    self.LianXian = self._proxy:AddLink(self._uuid, Target, self._uuid,"Root","Root", "FxJianTouLianXian01")
    self.YuJing1 = true
    self.YuJing2 = true
    self.JuLiJianCe = true
    self.KaiGuan = true
    self.juli1 = false
    self.juli2 = false
    self.juli3 = false
end


function XChar8058:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- 添加buff
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess,self._uuid) --注册反击
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore) --注册技能释放事件
end

function XChar8058:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8058:Update(dt)
    Base.Update(self, dt)
    self.PlayUUID =  self._proxy:GetPlayerNpcList()

    if self.JuLiJianCe ~= true then
        return
    end

    if #self.PlayUUID == 1 then
        self.juli1 = self._proxy:CheckNpcDistance(self._uuid, self.PlayUUID[1],5)
    end

    if #self.PlayUUID == 2 then
        self.juli1 = self._proxy:CheckNpcDistance(self._uuid, self.PlayUUID[1],5)
        self.juli2 = self._proxy:CheckNpcDistance(self._uuid, self.PlayUUID[2],5)
    end

    if #self.PlayUUID == 3 then
        self.juli1 = self._proxy:CheckNpcDistance(self._uuid, self.PlayUUID[1],5)
        self.juli2 = self._proxy:CheckNpcDistance(self._uuid, self.PlayUUID[2],5)
        self.juli3 = self._proxy:CheckNpcDistance(self._uuid, self.PlayUUID[3],5)
    end

    if self.juli1 == true or self.juli2 == true or self.juli3 ==true then
        if self.KaiGuan == true then
            self.KaiGuan = false
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053010, 1)
            self.zidan2 = true
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8072007, 1)
            --[[ self._proxy:ApplyMagic(self._uuid, self._uuid, 8058001, 1)]]
            self._proxy:DestroyMissileByUUID(self.Fentan)
            local FenTan , FenTan3 =  self._proxy:LaunchMissileFromPosToPos(self._uuid,82100704,80580122,self.targetPos,self.targetPos,1)--从目标位置向目标位置发特效
            self.Fentanliang = FenTan3
        end
    else
        if self.KaiGuan == false then
            self.KaiGuan = true
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053011, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8072006, 1)
            --[[self._proxy:ApplyMagic(self._uuid, self._uuid, 8058002, 1)]]
            self._proxy:DestroyMissileByUUID(self.Fentanliang)
            local FenTan1 , FenTan2 =  self._proxy:LaunchMissileFromPosToPos(self._uuid,82100704,80580110,self.targetPos,self.targetPos,1)--从目标位置向目标位置发特效
            self.Fentan = FenTan2
        end
    end

  --[[  if self.YuJing1 == true and  self.YuJing2 == true and not self._proxy:CheckBuffByKind(self._uuid, 8053010) then
        self.YuJing1 = false
        self._proxy:AddTimerTask(1.5, function()--延迟5秒后，释放影牌技能
            self._proxy:LaunchMissile(self._uuid, self._uuid, 80530115, 80530511,1)
            self.YuJing1 = true
        end)
    end]]
end

function XChar8058:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end

    if buffId == 8053015  then
        if self._proxy:GetBuffStacks(self._uuid, 8053015) == 1  then
            self._proxy:DestroyMissileByUUID(self.Luojian1)
            local Luojian2, var3  = self._proxy:LaunchMissileFromPosToPos(self._uuid,82100704,80580112,self.targetPos,self.targetPos,1)--落剑破碎特效2
            self.Luojian2 = var3
        elseif self._proxy:GetBuffStacks(self._uuid, 8053015) == 2  then
            self._proxy:DestroyMissileByUUID(self.Luojian2)
            local Luojian3, var4  = self._proxy:LaunchMissileFromPosToPos(self._uuid,82100704,80580113,self.targetPos,self.targetPos,1)--落剑破碎特效2
            self.Luojian3 = var4
        elseif self._proxy:GetBuffStacks(self._uuid, 8053015) == 3 then
            self._proxy:DestroyMissileByUUID(self.Luojian3)
            local Luojian3, var5  = self._proxy:LaunchMissileFromPosToPos(self._uuid,82100704,80580120,self.targetPos,self.targetPos,1)--落剑破碎特效2
            self.Luojian3 = var5
            self._proxy:AddTimerTask(1, function()--延迟5秒后，释放影牌技能
                self._proxy:DestroyNpc(self._uuid)
            end)
        end
    end

    if buffId == 8053028 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053015, 1)
    end

    if buffId == 8053020  then
        self._proxy:DestroyMissileByUUID(self.Fentan)
        self._proxy:DestroyMissileByUUID(self.Fentanliang)
        self.YuJing2 = false
        self.JuLiJianCe = false
        self._proxy:RemoveLink(self._uuid,self.LianXian)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053011, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8072008, 1)
    end

end


    ---@param dt number @ delta time

    ---@param eventType number
    ---@param eventArgs userdata

return XChar8058