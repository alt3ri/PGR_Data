local Base = require("Character/Char_8005")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---白龙（教学版）
---@class XChar8006 : XFightBase
local XChar8006 = XDlcScriptManager.RegCharScript(8006, "XChar8006", Base)

function XChar8006:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    -- 定义特殊教学技能轴
    self._intendSkillSeqs = {
        [1] = {         -- 发呆技能表
            [1] = {
            },
            [2] = {
                {1, 0},     -- OD吼
            }
        },
        [2] = {         -- 普攻技能表
            [1] = {
                {28, 0},
                {3, 0},
                {4, 0},
                {15, 0},
                {7, 0},
            },
            [2] = {
                {1, 0},     -- OD吼
            }
        },
        [3] = {         -- 普攻+弹刀技能表 -> 转OD
            [1] = {
                {24, 0},    -- 黄圈左扫(50%) or 黄圈右扫(50%)
                {3, 0},     -- 二连前咬
                {4, 0},     -- 右扫爪+拍地板
                {11, 0},    -- 左刺
                {28, 0},    -- 小挥爪
            },
            [2] = {
                {1, 0},     -- OD吼
                {9, 0},     -- 龙车
                {12, 0},    -- 左右刺
                {30, 0},    -- 全场三连喷火
                {14, 0},    -- 浮游炮射击
                {16, 0},    -- 大喷火
                {21, 0},    -- ！多人弹刀技能！
                {28, 0},    -- 小挥爪
                {10, 0.5}   -- 黄圈扫+砸地
            }
        }
    }

    self._skillSeqLoopKeys = {
        [1] = 1,
        [2] = 2,
        [3] = 3
    }

    -- 禁止白龙软狂暴机制
    self._enableSoftFury = false

    -- 禁止白龙使用强制释放技能
    self._maxRectifyIrritation = math.maxinteger
    self._irritationSkills = {}

    -- 白龙入场语音magic设置
    self._cvMagics.EnterScene = 8005755

    -- 创建教学关状态机
    self._tutorialSM = RelinkStateMachine.New("教学关状态机")

    -- 定义教学关状态
    self._tutorialSMStates = {
        NoSkill = 0,
        CommonSkill = 1,
        CommonAndParrySkill = 2,
        OD = 3
    }

    -- 定义教学关触发器
    self._tutorialSMTriggers = {
        ToCommonSkill = 0,
        ToCommonAndParrySkill = 1,
        ToOD = 2
    }

    self._enterNoSkill = function()
        self._bb:SetSyncVar(self._syncKeys.battleLoopIdx, 1)
        self._bb:SetSyncVar(self._syncKeys.curSeqIdx, 0)
        self._bb:SetSyncVar(self._syncKeys.nextSeqIdx, 1)
        self._curSkillSeq = self._intendSkillSeqs[1][1]
        self:RefreshSkillCD(false)
    end
    self._enterCommonSkill = function()
        self._bb:SetSyncVar(self._syncKeys.battleLoopIdx, 2)
        self._bb:SetSyncVar(self._syncKeys.curSeqIdx, 0)
        self._bb:SetSyncVar(self._syncKeys.nextSeqIdx, 1)
        self._curSkillSeq = self._intendSkillSeqs[2][1]
        self:RefreshSkillCD(false)
    end
    self._enterCommonAndParrySkill = function()
        self._bb:SetSyncVar(self._syncKeys.battleLoopIdx, 3)
        self._bb:SetSyncVar(self._syncKeys.curSeqIdx, 0)
        self._bb:SetSyncVar(self._syncKeys.nextSeqIdx, 1)
        self._curSkillSeq = self._intendSkillSeqs[3][1]
        self:RefreshSkillCD(false)
    end

    -- 添加状态
    self._tutorialSM:AddState(self._tutorialSMStates.NoSkill, "无技能教学阶段",  self._enterNoSkill, nil, nil, math.huge)
    self._tutorialSM:AddState(self._tutorialSMStates.CommonSkill, "普攻教学阶段", self._enterCommonSkill, nil, nil, math.huge)
    self._tutorialSM:AddState(self._tutorialSMStates.CommonAndParrySkill, "弹刀教学阶段", self._enterCommonAndParrySkill, nil, nil, math.huge)
    self._tutorialSM:AddState(self._tutorialSMStates.OD, "OD教学阶段", nil, nil, nil, math.huge)

    -- 添加触发器
    for k, v in pairs(self._tutorialSMTriggers) do
        self._tutorialSM:AddTrigger(v)
    end

    -- 添加转换
    self._noSkillToCommonSkill = function()
        return self._tutorialSM:CheckTrigger(self._tutorialSMTriggers.ToCommonSkill)
    end
    self._commonSkillToCommonAndParrySkill = function()
        return self._tutorialSM:CheckTrigger(self._tutorialSMTriggers.ToCommonAndParrySkill)
    end
    self._commonAndParrySkillToOD = function()
        return self._tutorialSM:CheckTrigger(self._tutorialSMTriggers.ToOD)
    end

    self._tutorialSM:AddTransition(self._tutorialSMStates.NoSkill, self._tutorialSMStates.CommonSkill, 0, self._noSkillToCommonSkill, 0, 0)
    self._tutorialSM:AddTransition(self._tutorialSMStates.CommonSkill, self._tutorialSMStates.CommonAndParrySkill, 0, self._commonSkillToCommonAndParrySkill, 0, 0)
    self._tutorialSM:AddTransition(self._tutorialSMStates.CommonAndParrySkill, self._tutorialSMStates.OD, 0, self._commonAndParrySkillToOD, 0, 0)

    -- 激活状态机
    self._tutorialSM:Activate()

    -- 定制进入普通的条件
    self._enterNormal = function()
        if self._tutorialSM:GetCurStateId() ~= self._tutorialSMStates.OD then
            return
        end

        -- 不刷新大轴，仅确保重置技能索引和CD
        self._bb:SetSyncVar(self._syncKeys.curSeqIdx, 0)
        self._bb:SetSyncVar(self._syncKeys.nextSeqIdx, 1)
        self._curSkillSeq = self._intendSkillSeqs[3][1]
        self:RefreshSkillCD(false)
    end
    local fightNormalState = self._fightSM:GetState(Base.EFightState.Normal)
    if fightNormalState ~= nil then
        fightNormalState.enter = self._enterNormal
    end

    -- 为战斗状态机定制转换条件（只有3阶，也就是放普攻和弹刀技能的时候才能进入OD，否则不允许进入）
    self._normalToOD = function()
        return (self._tutorialSM:GetCurStateId() == self._tutorialSMStates.OD) and
                (self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.OverDrive) >= self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.OverDrive))
    end
    self._fightSM:SetTransition(Base.EFightState.Normal, 0, self._normalToOD, 0, 0)

    -- 取消交互QTE修正
    self._enableQTEInteractFix = false
end

---@param dt number @ delta time
function XChar8006:Update(dt)
    Base.Update(self, dt)

    self._tutorialSM:Update(dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar8006:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8006:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
end

function XChar8006:CustomSelectSkillLogic()
    Base.CustomSelectSkillLogic(self)

    if self._proxy:CheckBuffByKind(self._uuid, 8005974) then
        local isSuccess = self._proxy:CastAction(self._uuid, 8005518)
        if isSuccess then
            -- 成功释放后，移除该效果
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8005975, 1)
        end
    end
end

function XChar8006:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then return end

    if buffId == 8005962 then
        self._tutorialSM:SetTrigger(self._tutorialSMTriggers.ToCommonSkill)
    end

    if buffId == 8005963 then
        self._tutorialSM:SetTrigger(self._tutorialSMTriggers.ToCommonAndParrySkill)
    end

    if buffId == 8005964 then
        self._tutorialSM:SetTrigger(self._tutorialSMTriggers.ToOD)
    end
end

function XChar8006:Terminate()
    -- 教学状态机注销
    self._tutorialSM:Terminate()

    Base.Terminate(self)
end
--endregion



return XChar8006