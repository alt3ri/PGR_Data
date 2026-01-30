---@type XFightBase
local Base = require("Common/XFightBase")

---Relink-公共NPC脚本
---@class XChar1200 : XFightBase
local XChar1200 = XDlcScriptManager.RegCharScript(1200, "XChar1200", Base)
function XChar1200:Ctor(proxy)
    self._proxy = proxy
end

function XChar1200:Init()
    Base.Init(self)
    XLog.Warning("公共NPC加载完成")
end

---@param dt number @ delta time
function XChar1200:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar1200:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
    if eventType == EWorldEvent.FullChainSkillStart then
        self:OnFullChainSkillStart(eventArgs.GamePlayActive, eventArgs.IsInChain, eventArgs.ChainRemainTime, eventArgs.ChainNpc, eventArgs.ChainLevel)
    end
    if eventType == EWorldEvent.FullChainSkillEnd then
        self:OnFullChainSkillEnd(eventArgs.GamePlayActive, eventArgs.IsInChain, eventArgs.ChainRemainTime, eventArgs.ChainNpc, eventArgs.ChainLevel)
    end
    if eventType == EWorldEvent.CastFullChainFinalSkill then
        self:OnCastFullChainFinalSkill(eventArgs.GamePlayActive, eventArgs.IsInChain, eventArgs.ChainRemainTime, eventArgs.ChainNpc, eventArgs.ChainLevel)
    end
    if eventType == EWorldEvent.FullChainStageEnd then
        self:OnFullChainStageEnd(eventArgs.GamePlayActive, eventArgs.IsInChain, eventArgs.ChainRemainTime, eventArgs.ChainNpc, eventArgs.ChainLevel)
    end
end

---FullChain开启连锁
---@param gameplayActive number 是否开启玩法
---@param isInChain number 是否在连锁状态
---@param chainRemainTime number 连锁剩余时间
---@param chainNpc number 正在锁链的Npc
---@param chainLevel number 当前连锁段数
function XChar1200:OnFullChainSkillStart(gameplayActive, isInChain, chainRemainTime, chainNpc, chainLevel)
    if( chainLevel == 1) then
        XLog.Warning("1阶段连携")
        local players = self._proxy:GetPlayerNpcList()
        for k, playerID in ipairs(players) do
            self._proxy:ApplyMagic(self._uuid, playerID, 12001001, 100)
        end
    elseif ( chainLevel == 2) then
        XLog.Warning("2阶段连携")
        local players = self._proxy:GetPlayerNpcList()
        for k, playerID in ipairs(players) do
            self._proxy:ApplyMagic(self._uuid, playerID, 12002001, 100)
        end
    elseif ( chainLevel == 3) then
        XLog.Warning("3阶段连携")
        local players = self._proxy:GetPlayerNpcList()
        for k, playerID in ipairs(players) do
            self._proxy:ApplyMagic(self._uuid, playerID, 12003001, 100)
        end
    end
end

---FullChain连锁结束
---@param gameplayActive number 是否开启玩法
---@param isInChain number 是否在连锁状态
---@param chainRemainTime number 连锁剩余时间
---@param chainNpc number 正在锁链的Npc
---@param chainLevel number 当前连锁段数
function XChar1200:OnFullChainSkillEnd(gameplayActive, isInChain, chainRemainTime, chainNpc, chainLevel)
    XLog.Warning("奥义连携结束" .. chainLevel)
end

---FullChainSkill释放！
---@param gameplayActive number 是否开启玩法
---@param isInChain number 是否在连锁状态
---@param chainRemainTime number 连锁剩余时间
---@param chainNpc number 正在锁链的Npc
---@param chainLevel number 当前连锁段数
function XChar1200:OnCastFullChainFinalSkill(gameplayActive, isInChain, chainRemainTime, chainNpc, chainLevel)
local players = self._proxy:GetPlayerNpcList()
    for k, playerID in ipairs(players) do
        self._proxy:ApplyMagic(self._uuid, playerID, 12003002, 100)
        self._proxy:ApplyMagic(self._uuid, playerID, 12002002, 100)
        self._proxy:ApplyMagic(self._uuid, playerID, 12001002, 100)
    end
    
    XLog.Warning("释放奥义连携终结技" .. chainLevel)
    local targetNpc = self._proxy:SearchNpc(self._uuid, ENpcCampType.Camp2, 4, 100, -1)
    -- --无战斗目标释放技能
    if (targetNpc == 0) or (not targetNpc) then
        self._proxy:CastAction(self._uuid, 1200001)
        return
    end

    --有战斗目标释放技能
    local targetPos = self._proxy:GetNpcPosition(targetNpc)
    
    self._proxy:SetFightTarget(self._uuid, targetNpc)      --设置战斗目标
    self._proxy:CastActionToTarget(self._uuid, 1200001, targetNpc)
end

---FullChainSkill释放！
---@param gameplayActive number 是否开启玩法
---@param isInChain number 是否在连锁状态
---@param chainRemainTime number 连锁剩余时间
---@param chainNpc number 正在锁链的Npc
---@param chainLevel number 当前连锁段数
function XChar1200:OnFullChainStageEnd(gameplayActive, isInChain, chainRemainTime, chainNpc, chainLevel)
    XLog.Warning("奥义连携阶段结束" .. chainLevel)
    local players = self._proxy:GetPlayerNpcList()
    for k, playerID in ipairs(players) do
        self._proxy:ApplyMagic(self._uuid, playerID, 12003002, 100)
        self._proxy:ApplyMagic(self._uuid, playerID, 12002002, 100)
        self._proxy:ApplyMagic(self._uuid, playerID, 12001002, 100)
    end
end

function XChar1200:InitEventCallBackRegister()
    --按需求解除注释进行注册
    XLog.Warning("开始注册")

    --self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore)         -- OnNpcCastActionBeforeEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)         -- OnNpcCastActionAfterEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionByInputActionBefore)         -- OnNpcCastActionByInputActionBeforeEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcExitAction)         -- OnNpcExitActionEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcDie)               -- OnNpcDieEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcRevive)            -- OnNpcReviveEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcLoadComplete)      -- OnNpcLoadCompleteEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcDodge)               --OnNpcDodge
    --self._proxy:RegisterEvent(EWorldEvent.Behavior2ScriptMsg)   -- OnBehavior2ScriptMsgEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)        -- OnNpcRemoveBuffEvent
    --self._proxy:RegisterEvent(EWorldEvent.MissileHit)           -- OnMissileHitEvent
    --self._proxy:RegisterEvent(EWorldEvent.MissileDead)          -- OnMissileDeadEvent
    --self._proxy:RegisterEvent(EWorldEvent.MissileCreate)        -- OnMissileCreateEvent
    self._proxy:RegisterEvent(EWorldEvent.LockTargetChanged)      -- OnLockTargetChanged
    self._proxy:RegisterEvent(EWorldEvent.FullChainSkillStart)      --OnFullChainSkillStart
    self._proxy:RegisterEvent(EWorldEvent.FullChainSkillEnd)        --OnFullChainSkillEnd
    self._proxy:RegisterEvent(EWorldEvent.CastFullChainFinalSkill)        --OnCastFullChainFinalSkill
    self._proxy:RegisterEvent(EWorldEvent.FullChainStageEnd)        --OnFullChainStageEnd
    XLog.Warning("Relink基类注册事件")
end

function XChar1200:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    if (buffId == 12000106) then
        local players = self._proxy:GetPlayerNpcList()
        for k, playerID in ipairs(players) do
            self._proxy:ApplyMagic(self._uuid, playerID, 12000106, 100)
        end
    end
    
    if (buffId == 12000103) then
        local players = self._proxy:GetPlayerNpcList()
        for k, playerID in ipairs(players) do
            self._proxy:ApplyMagic(self._uuid, playerID, 12000103, 100)
        end
    end

    if (buffId == 12000104) then
        local players = self._proxy:GetPlayerNpcList()
        for k, playerID in ipairs(players) do
            self._proxy:ApplyMagic(self._uuid, playerID, 12000104, 100)
        end
    end

    if (buffId == 12000105) then
        local players = self._proxy:GetPlayerNpcList()
        for k, playerID in ipairs(players) do
            self._proxy:ApplyMagic(self._uuid, playerID, 12000105, 100)
        end
    end
end

return XChar1200
