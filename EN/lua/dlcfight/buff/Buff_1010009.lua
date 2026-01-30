local Base = require("Common/XFightBase")
---@class XBuffScript1010009 : XFightBase
local XBuffScript1010009 = XDlcScriptManager.RegBuffScript(1010009, "XBuffScript1010009", Base)

function XBuffScript1010009:Init() --初始化
    Base.Init(self)
    -----------------------------Partner配置------------------------
    self.partnerId = 1015--需要召唤的Npc
    self.partnerCamp = self._proxy:GetNpcCamp(self._uuid) --召唤的伙伴阵营跟自己一样
    self.forwardDashPartnerSkillId = 101026  --前闪要放的技能
    self.forwardDashID = 101025 --前闪技能ID，检查
    self.forwardHitMark = 1010055 --前闪伤害判断标记
    self.forwardDamage = 1010513 --前闪伤害
    
    self.backDashPartnerSkillId = 101019  --后闪要放的技能
    self.backDashID = 101018 --后闪技能ID，检查
    self.backHitMark = 1010054--后闪伤害判断标记
    self.backDamage = 1010516--后闪伤害
    
    self.partnerExMagicId1 =1010007 --特效的
    self.currentCallIndex = 1  --叫到第几个NPC了
    self.overTimeMappingList = {  --数组里有几个就判断几个
        0.05,
        0.15,
        0.3,
    }

    self.partnerRotaOffsetList={  --创建时宣传偏移
        -45,
        45,
        -45,
    }
    self.lastSkillIsBackDash = nil
    self.lastSkillIsForwardDash =nil
    self.partnerDict ={}
end

---@param dt number @ delta time 
function XBuffScript1010009:Update(dt)
    Base.Update(self, dt)
    local isForwardDash = self._proxy:CheckNpcCurrentAction(self._uuid,self.forwardDashID)
    local isBackDash = self._proxy:CheckNpcCurrentAction(self._uuid,self.backDashID)
    
    if not (isBackDash or isForwardDash) then
        self.lastSkillIsBackDash = nil
        self.lastSkillIsForwardDash =nil
        self.currentCallIndex = 1
        return
    end
    --判断如果上一个技能是Dash，但这次换了一个，需要重置召唤的Index
    if (self.lastSkillIsBackDash and isForwardDash) or (isBackDash and self.lastSkillIsForwardDash) then
        self.currentCallIndex = 1
    end
    self.lastSkillIsBackDash = isBackDash
    self.lastSkillIsForwardDash = isForwardDash
    
    --------------------在dash这个技能过程的逻辑------------------------------
    local callIndex = self.currentCallIndex
    local overTime = self.overTimeMappingList[callIndex] --当前Index需要判断的时间
    local isGotSkillTime,skillTime = self._proxy:TryGetNpcCurrentActionElapsedTime(self._uuid)

    if callIndex >#self.overTimeMappingList then --超过map的值时就跳过等技能结束吧
        return
    end

    if skillTime >= overTime then --超过技能时间说明要执行
        self.currentCallIndex = self.currentCallIndex + 1 --把Index+1
        self:CallPartner(callIndex,isForwardDash)
    end
end

function XBuffScript1010009:Terminate()
    Base.Terminate(self)
    for partnerUUID, value in pairs(self.partnerDict) do--遍历伙伴组，把所有伙伴干掉
        self:KillPartner(partnerUUID)
    end
    self.partnerDict = nil
end

function XBuffScript1010009:CallPartner(callIndex,isForwardDash)
    local id= self.partnerId
    local camp = self.partnerCamp
    local skillId=self.backDashPartnerSkillId --默认后闪技能
    local mgId1= self.partnerExMagicId1
    local rota = self._proxy:GetNpcRotation(self._uuid)
    local distance = 1
    local euler = {x=0,y=self.partnerRotaOffsetList[callIndex],z=0}
    local pos = self._proxy:GetNpcOffsetPositionByFacing(self._uuid,euler,distance)
    local partnerUUID = self._proxy:GenerateNpc(id,camp,pos,rota)
    local target = self._proxy:GetFightTargetId(self._uuid)
    if isForwardDash then --如果是前闪，就设置为前闪
        skillId=self.forwardDashPartnerSkillId
    end
    
    self._proxy:ApplyMagic(self._uuid,partnerUUID,mgId1,1) --添加特效

    if target == 0 then
        self._proxy:CastAction(partnerUUID,skillId)
    else
        self._proxy:SetNpcFaceToPosition(partnerUUID,self._proxy:GetNpcPosition(target))
        self._proxy:CastActionToTarget(partnerUUID,skillId,target)
        --XLog.Warning("看向目标攻击")
    end
    self.partnerDict[partnerUUID] = true
    -- 0.45s后删除分身
    self._proxy:AddTimerTask(0.45, function()
        self:KillPartner(partnerUUID)
    end)
end

function XBuffScript1010009:KillPartner(partnerUUID) --干掉伙伴
    if self.partnerDict[partnerUUID] then
        self._proxy:DestroyNpc(partnerUUID)
    end
    self.partnerDict[partnerUUID] = false
end

--region EventCallBack
function XBuffScript1010009:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
end

function XBuffScript1010009:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    if npcUUID == self._uuid then --给自己加的就不用管，防止敌方万事打中自己也给自己加伤
        return
    end
    if buffId == self.backHitMark then
        self._proxy:ApplyMagic(self._uuid,npcUUID,self.backDamage,1)
    end
    if buffId == self.forwardHitMark then
        self._proxy:ApplyMagic(self._uuid,npcUUID,self.forwardDamage,1)
    end
end
--endregion

return XBuffScript1010009
