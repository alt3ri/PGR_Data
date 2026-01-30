---@type XFightBase
local Base = require("Common/XFightBase")

---Relink-公共NPC脚本
---@class XChar1200 : XFightBase
local XChar1200 = XDlcScriptManager.RegCharScript(1200, "XChar1200", Base)
function XChar1200:Ctor(proxy)
    self._proxy = proxy
end

function XChar1200:ScriptInit(isGainControl)
    if not isGainControl then
        -- 公共Npc标记
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000510, 1)
    end
end

---@param dt number @ delta time
function XChar1200:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar1200:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar1200:InitEventCallBackRegister()
    --按需求解除注释进行注册
    --XLog.Warning("开始注册")

    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore)              -- OnNpcCastActionBeforeEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)               -- OnNpcCastActionAfterEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionByInputActionBefore) -- OnNpcCastActionByInputActionBeforeEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcDodge)      --OnNpcDodge
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)    -- OnNpcAddBuffEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff) -- OnNpcRemoveBuffEvent
    self._proxy:RegisterEvent(EWorldEvent.FullChainSkillStart)     --OnFullChainSkillStart
    self._proxy:RegisterEvent(EWorldEvent.FullChainSkillEnd)       --OnFullChainSkillEnd
    self._proxy:RegisterEvent(EWorldEvent.CastFullChainFinalSkill) --OnCastFullChainFinalSkill
    self._proxy:RegisterEvent(EWorldEvent.FullChainStageEnd)       --OnFullChainStageEnd
    self._proxy:RegisterEvent(EWorldEvent.FullChainShowStart)
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcEnterOverDrive)
    self._proxy:RegisterEvent(EWorldEvent.NpcODBreakAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcWaitReboot)

    self._proxy:RegisterEventByTarget(EWorldEvent.NpcAfterSyncCounterSuccess, self._uuid) -- OnNpcAfterSyncCounterSuccess

    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkCounterSuccess)
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkCastCounterSkill)
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkMonsterCastPowerfulSkill)
    --XLog.Warning("Relink基类注册事件")
end

--region 事件回调

function XChar1200:OnFullChainSkillStart(gameplayActive, isInChain, chainRemainTime, chainNpcList, chainLevel, curChainStartNpcId)
    --添加充能限制
    self._proxy:ApplyMagic(self._uuid, curChainStartNpcId, 1200008)

    local players = self._proxy:GetPlayerNpcList()
    for i, playerID in pairs(players) do
        if playerID == curChainStartNpcId then goto continue end
        --XLog.Warning("添加能量 " .. tostring(curChainStartNpcId) .. " " .. tostring(playerID))
        if self._proxy:CheckBuffByKind(playerID, 1200008) then goto continue end
        --XLog.Error("添加能量" .. playerID)
        self._proxy:ApplyMagic(self._uuid, playerID, 12000109)
        ::continue::
    end
end

function XChar1200:OnFullChainSkillEnd(gameplayActive, isInChain, chainRemainTime, chainNpcList, chainLevel)
    --XLog.Warning("奥义连携结束" .. chainLevel)
end

function XChar1200:OnCastFullChainFinalSkill(gameplayActive, isInChain, chainRemainTime, chainNpcList, chainLevel)
    --XLog.Warning("释放奥义连携终结技" .. chainLevel)
    local targetNpc = self._proxy:SearchNpc(self._uuid, ENpcCampType.Camp2, 4, 999, -1)
    -- --无战斗目标释放技能
    if (targetNpc == 0) or (not targetNpc) then
        XLog.Warning("无目标释放爆炸")
        self._proxy:CastAction(self._uuid, 1200001)
        return
    end
    --有战斗目标释放技能
    local targetPos = self._proxy:GetNpcPosition(targetNpc)
    XLog.Warning("有目标释放爆炸")
    self._proxy:CastActionToPosition(self._uuid,1200001,targetPos)
    self._proxy:ApplyMagic(self._uuid, targetNpc, 12000110)
end

-- function XChar1200:OnFullChainStageEnd(gameplayActive, isInChain, chainRemainTime, chainNpc, chainLevel)
--     --XLog.Warning("奥义连携阶段结束" .. chainLevel)
--     self:ApplyMagicsToAllPlayer({12003002, 12002002, 12001002}, 100)
-- end

function XChar1200:OnFullChainShowStart(gameplayActive, chainNpcList, chainLevel)
    --给所有人加无敌
    self:ApplyMagicToAllPlayer(12001001,1)
end

function XChar1200:OnFullChainStageEnd(gameplayActive, isInChain, chainRemainTime, chainNpcList, chainLevel)
    --删除充能限制
    self:ApplyMagicToAllPlayer(1200009, 1)
end

function XChar1200:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end
    if buffId == 12001002 then
        self:ApplyMagicToAllPlayer(12001002, 1)
    end
    if buffId == 12000106 then
        self:ApplyMagicToAllPlayer(12000106, 1)
    end

    if buffId == 12000103 then
        self:ApplyMagicToAllPlayer(12000103, 1)
    end

    if buffId == 12000104 then
        self:ApplyMagicToAllPlayer(12000104, 1)
    end

    if buffId == 12000105 then
        self:ApplyMagicToAllPlayer(12000105, 1)
    end
end

function XChar1200:OnNpcAfterSyncCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
end
--endregion

--region 效果相关封装
function XChar1200:ApplyMagicToTarget(targetId, magicId, level)
    if targetId == nil or not self._proxy:CheckNpc(targetId) then
        return
    end

    self._proxy:ApplyMagic(self._uuid, targetId, magicId, level)
end

function XChar1200:ApplyMagicToAllPlayer(magicId, level)
    for i, player in ipairs(self._proxy:GetPlayerNpcList()) do
        self:ApplyMagicToTarget(player, magicId, level)
    end
end

function XChar1200:ApplyMagicsToAllPlayer(magicIds, level)
    for i, player in ipairs(self._proxy:GetPlayerNpcList()) do
        for j, magicId in ipairs(magicIds) do
            self:ApplyMagicToTarget(player, magicId, level)
        end
    end
end
--endregion

return XChar1200
