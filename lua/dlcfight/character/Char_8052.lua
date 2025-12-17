local Base = require("Character/FightCharBase/XRelinkMonsterBase")
local SkillConfig = require("TempSkillConfigs/SkillConfig_8052")
---小辉辉BOSS脚本
---@class XChar8052 : XRelinkMonsterBase
local XChar8052 = XDlcScriptManager.RegCharScript(8052, "XChar8052", Base)

--region 怪物配置

---配置主入口
function XChar8052:MonsterConfigMain() --怪物配置用
    Base.MonsterConfigMain(self)
    --self:SetOverDriveActive(false) --关闭OD系统
    --self:SetBreakGaugeActive(false) --关闭韧性系统
    --self:SetAiActive(false) --关闭AI
    
    self:SkillConnectInit() --自己的技能衔接
    self.isSkillConnectLocked = true --技能连招锁
end

function XChar8052:SkillCastConfig()
    self.selectSkillType = Base.SelectSkillType.CastGroup --按照技能释放组去放技能
    --爆气优先技能列表
    --转阶段优先技能列表。
    self.castGroup={
        --{--二阶段优先判断技能
        --    [805202] = 10,--反身拳
        --    [805216] = 10,--地面蓄力炮
        --    [805224] = 10, --二连刃
        --    [805229] =10,--重火锤
        --},
        --{--二阶段普通释放技能
        --    [805230] = 10,--后退斩
        --    [805230]=10,--升龙斩
        --    [805207] = 10,--交叉射击
        --},
        {--一阶段优先释放技能
            [805232] = 10,  --远距离：瑟提锤追击
            [805208] = 10,  --中远距离：推进拳
            [805221] = 10,    --超远距离：移动射击
            [805201] = 10,  --近距离：格挡
        },
        {--一阶段普通技能释放组
            [805203]=10,--上勾拳
            [805234]=10,--二连拳
            [805202]=10,--反身拳
            [805208]=10,--推进拳
            [805204]=10,--欧拉拳
        }
    }
end

---技能测试配置
function XChar8052:SkillTestConfig()
    self.isSkillTestOpen= false --技能测试开关
    self.skillTestId = 805225
    self.skillTestInitialCd = 2 --测试初始CD
    self.skillTestCd = 10
end

---韧性系统配置
function XChar8052:BreakGaugeConfig()
    self.brokenSkill = 805236 --被破韧技能
    self.brokenRange = 40 --多少米内的玩家可以受到破韧信号
end

---OverDrive配置
function XChar8052:OverDriveConfig()
    self.enterOverDriveSkill = 805235 --OD技能
    self.breakStartSkill = 805236 --配置：进入虚弱技能
    self.breakLoopSkill = 805237 --配置：虚弱循环技能
    self.breakEndSkill = 805238 --配置：退出虚弱时技能
end

--endregion

--region 事件系统管理
function XChar8052:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
end
function XChar8052:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if casterNpcUUID~=self._uuid then --下面只检查自己添加出去的buff
        return
    end
    self:ParryMainLogic(npcUUID,buffId)--拼刀主检测
    self:SkillConnectMainLogic(buffId) --技能衔接主逻辑
end
--endregion

--region 武器控制
--endregion

--region 拼刀控制

---检查是否要对Npc使用格挡(npc)
function XChar8052:CheckParryByNpc(npc)
    local angle = 135
    local buffKind = 8052001
    
    if not self._proxy:CheckNpcInAngle(self._uuid,npc,angle) then--在自己角度范围内
        return false
    end

    if not  self._proxy:CheckBuffByKind(self._uuid,buffKind) then--可以格挡标记
        return false
    end
    return true
end

---被Npc触发格挡（npc）
function XChar8052:TriggerParryByNpc(triggerNpc)
    self._proxy:SetNpcFaceToPosition(self._uuid, self._proxy:GetNpcPosition(triggerNpc))--看向触发格挡的Npc
    self:SetTarget(triggerNpc)--设置为战斗目标
    self:ForceSkillToTarget(805205)--对战斗目标放格挡技能
end

---拼刀主逻辑(npcuuid，buffuuid）
function XChar8052:ParryMainLogic(npcUUID,buffId)
    if (buffId == 8052026) and self:CheckDeflectByNpc(npcUUID) then--拼刀检查
        self:TriggerDeflectByNpc(npcUUID)--检查通过，被Npc触发弹反
    end
end

---对Npc检查拼刀条件(npc)
function XChar8052:CheckDeflectByNpc(npc)
    return self._proxy:CheckBuffByKind(npc,105234) or self._proxy:CheckBuffByKind(npc,105233)--检查Npc身上是否有这几个标记
end

---被Npc触发弹刀(npc)
function XChar8052:TriggerDeflectByNpc(triggerNpc)
    local buffCountBuffId = 8052033
    local maxCount = 2 --最大层数
    local haveBuff = self._proxy:CheckBuffByKind(self._uuid,buffCountBuffId) --之前有没有拼刀标记
    local buffCount = 0 --当前拼刀次数
    local phase1Skill = 805214 --再来一次
    local phase2Skill = 805233 --被小击飞
    self:SetTarget(triggerNpc)--设置为战斗目标
    if haveBuff then--如果有标记Buff
        --self:HandleDeflect(805233,triggerNpc)--大击飞
        buffCount = self._proxy:GetBuffStacks(self._uuid,buffCountBuffId)
        XLog.Warning(buffCount)
        if buffCount >= maxCount then
            self:HandleDeflect(805233,triggerNpc)--被击飞，结束拼刀流程
            self._proxy:ApplyMagic(self._uuid,self._uuid,8052037,1)--清空拼刀次数
        else
            self._proxy:ApplyMagic(self._uuid,self._uuid,buffCountBuffId,1)--拼刀层数增加一层
            self:HandleDeflect(phase1Skill,triggerNpc)--飞上天，再来拼刀
        end
    else--如果没有标记Buff
        self._proxy:ApplyMagic(self._uuid,self._uuid,buffCountBuffId,1)--拼刀层数增加一层
        self:HandleDeflect(phase1Skill,triggerNpc)--飞上天，再来拼刀
    end
end

---处理拼刀（skill,npc）
function XChar8052:HandleDeflect(skill,npc)
    self._proxy:SetNpcFaceToPosition(self._uuid, self._proxy:GetNpcPosition(npc))--看向触发弹刀的Npc
    self._proxy:LaunchMissile(npc,self._uuid,80520521,1)--目标对自己发特效
    self:ForceSkillToNpc(skill,npc)--对触发弹反的Npc释放拼刀技能
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052029,1)--对自己顿帧
    self._proxy:ApplyMagic(self._uuid,npc,8052030,1)--对目标顿帧
    self._proxy:ApplyMagic(npc,npc,8052031,1)--调整镜头广角
end

--endregion

--region 连招控制

---衔接初始化
function XChar8052:SkillConnectInit() --技能衔接初始化
    self.maxConnectCount = 2-- 连招上限
    self.curConnectCount = 1 --当前连招段数
end

---技能衔接主逻辑
function XChar8052:SkillConnectMainLogic(buffId)
    if buffId == 8052025 then--格挡后衔接（）
        self:ParryConnect() 
    end
    -----------------以上的固定衔接，肯定会接的---------------------------------------
    
    if not self:HandleConnectCount() then --不可衔接连招时返回
        return
    end
    
    if buffId == 8052003 then --上勾拳
        self:ShangGouQuanConnect()
    end
    if buffId == 8052004 then --反身拳
        self:FanShenQuanConnect()
    end
    if buffId == 8052005 then --交叉射击
        
    end
    if buffId == 8052006 then --下段斩
        
    end
    if buffId == 8052007 then --推进1随机衔接

    end
    if buffId == 8052008 then --推进1攻击衔接

    end
    if buffId == 8052009 then --推进2攻击衔接

    end
    if buffId == 8052010 then --地面蓄力炮衔接
        self:GroundLaserConnect()
    end
    if buffId == 8052011 then --空中喷气衔接
        self:AirPushConnect() 
    end
    if buffId == 8052012 then --移动射击衔接
        self:MoveFireConnect()
    end
    if buffId == 8052013 then --光刃上天衔接

    end
    if buffId == 8052014 then --光刃二连衔接

    end
    if buffId == 8052015 then --胸炮浮空版衔接
        --self:AirLaserConnect()
    end
    if buffId == 8052016 then --胸炮地面衔接
        --self:JumpLaserConnect()
    end
    if buffId == 8052017 then --空落锤

    end
    if buffId == 8052018 then --后退斩

    end
    if buffId == 8052019 then --瑟提锤

    end
    if buffId == 8052020 then --二连拳
        self:DoubleFistConnect()
    end
    if buffId == 8052021 then --空中喷气衔接流星冲坠
        self:AirPushConnectDown()
    end
    
end

---检查和处理是否能衔接技能
function XChar8052:HandleConnectCount()
    if not self.isSkillConnectLocked then
        return false
    end
    
    if self.curConnectCount<self.maxConnectCount then--小于最大值
        self.curConnectCount = self.curConnectCount + 1
        return true
    end

    self.curConnectCount = 1 --不足以衔接，重置成1
    return false
    
end

---上勾拳衔接
function XChar8052:ShangGouQuanConnect() --上勾拳衔接
    
end

---反身拳衔接
function XChar8052:FanShenQuanConnect() 

end

---二连拳衔接衔接
function XChar8052:DoubleFistConnect() 
    local target = self._proxy:GetFightTargetId(self._uuid)
    local SkillGroup={
        [805203]=10,--上勾拳
        [805207]=10,--交叉射击
        --缺一个连续推进
    }
    if self:CastSkillToTargetByWeights(SkillGroup) then
        XLog.Warning("二连拳技能衔接成功")
    end
end

---地面激光衔接
function XChar8052:GroundLaserConnect()
    
end

---空中激光衔接
function XChar8052:AirLaserConnect()
    
end

---空中衔接
function XChar8052:AirPushConnect()--空中喷气衔接
    local skillId1 = 805217 --左推轻
    local skillId2 = 805218 --右推轻
    if self._proxy:Random(0,100) >=50 then --50概率放左推
        self:ForceSkillToTarget(skillId1)
        return
    end
    self:ForceSkillToTarget(skillId2)
end

---空中喷气衔接落地
function XChar8052:AirPushConnectDown()--空中喷气衔接流星坠
    local skillId = 805206
    self:ForceSkillToTarget(skillId)
end

---跳跃激光衔接/胸炮地面版衔接
function XChar8052:JumpLaserConnect()
    local skills = {--要判断的技能释放列表
        [805228]=1,
    }
    --如果有CD或不满足条件的技能就没办法放，会在满足释放条件的技能里选择。
    --self:ForceCastSkillToTargetByWeights(skills) --根据权重组释放技能
    self:ForceSkillToTarget(805219) 
    XLog.Warning("What")
    return
    --self:CastSkillToTargetByWeights(skills) --根据权重组判断条件地去筛技能
    --self:ForceSkillToTarget(805228) --强制释放空落锤
end

---移动射击衔接
function XChar8052:MoveFireConnect()
    local target = self.target
    local SkillGroup={}
    XLog.Warning("和目标的距离是"..self.targetDistance)
    --八方向障碍检查
    if self:CheckDisByTarget(5) then--近距离
        if self.curPhase == 1 then--近距离一阶段
            SkillGroup = {
                [805207] = 10,--交叉射击,用来后退
                [805203] = 10,--上勾拳
                [805234] = 10,--二连拳
            }
        end
        if self.curPhase == 2 then--近距离二阶段
            SkillGroup = {
                [805230] = 10,--后退斩,用来后退
                [805216] = 10,--地面蓄力炮
            }
        end
        return self:CastSkillToTargetByWeights(SkillGroup)
    end

    if self:CheckDisByTarget(10) then--中距离
        if self.curPhase == 1 then--中距离一阶段
            SkillGroup = {
                [805208] = 10,--推进拳
            }
        end

        if self.curPhase == 2 then--中距离二阶段
            SkillGroup = {
                [805227] = 10,--升龙腿
                [805224] = 10,--光刃二连
                [805209] = 10,--下段斩
            }
        end
        return self:CastSkillToTargetByWeights(SkillGroup)
    end
    
    self:ForceSkillToTarget(805221)--远距离继续放移动射击
end

---推进拳衔接
function XChar8052:PushFistFistConnect()
    
end

---Parry格挡衔接
function XChar8052:ParryConnect()
    self:ForceSkillToTarget(805205)--释放格挡反击
end

--endregion

return XChar8052