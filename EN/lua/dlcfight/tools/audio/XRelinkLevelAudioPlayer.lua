---@class XRelinkLevelAudioPlayer Relink关卡交互语音播放器
local XRelinkLevelAudioPlayer = XClass(nil, "XRelinkLevelAudioPlayer")
local EFightCVAction = require("Enum/XFightCVAction")

--region 生命周期
---构造器
---@param proxy XDlcCSharpFuncs
function XRelinkLevelAudioPlayer:Ctor(proxy)
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end

---初始化
---@param cvKind number @关卡使用的CV种类(一般使用1200)
function XRelinkLevelAudioPlayer:Init(cvKind)
    --- cv种类
    self._cvKind = cvKind

    -- cv种类如果不合法则默认设置为1200
    if self._cvKind == nil or math.type(cvKind) ~= "integer" then
        self._cvKind = 1200
    end

    self._cvEventMagics = {
        CastTeamworkSkill = 1000500,
        MultiQTESupport = 1000501,
        MultiQTEUltimate = 1000502,
        TwoChainSuccess = 1000503,
        FullChainSuccess = 1000504,
        MultiQTEWarning = 1000505,
        MultiQTESuccess = 1000506,
        CounterWarning = 1000507,
        HighDmgSkillWarning = 1000508,
        PraiseCounterSuccess = 1000509,
        PlayerLowLife = 1000511
    }

    ---@class CVActionCoolDown
    ---@field coolDown number
    ---@field timer number
    ---@field beginTimer number

    ---@type table<int, CVActionCoolDown>
    self._actionCDs = {
        [EFightCVAction.CounterWarning] = { coolDown = 14, timer = 0, beginTimer = 0 },
        [EFightCVAction.PraiseCounterSuccess] = { coolDown = 10, timer = 0, beginTimer = 0 },
        [EFightCVAction.HighDmgSkillWarning] = { coolDown = 14, timer = 0, beginTimer = 0 }
    }

    ---@type table<int, bool>
    self._actionValidations = {}
    for k, actionId in pairs(EFightCVAction) do
        self._actionValidations[actionId] = true
    end

    for actionType, coolDown in pairs(self._actionCDs) do
        coolDown.timer = coolDown.beginTimer
    end

    --- 上一个说弹刀警告的NpcUUID
    self._counterWarningLastNpcUUID = nil

    self._bufferedChainLevel = 2

    self._canPraiseFullChainSuccess = false
    self._praiseFullChainSuccessTimer = 0

    self._praiseFullChainSuccessSelicaDelay = 1.7
    self._hasSelicaPraiseFullChainSuccess = false
    self._praiseFullChainSuccessMemberADelay = 2.75
    self._hasMemberAPraiseFullChainSuccess = false
    self._praiseFullChainSuccessMemberA = nil
    self._praiseFullChainSuccessMemberBDelay = 4
    self._hasMemberBPraiseFullChainSuccess = false
    self._praiseFullChainSuccessMemberB = nil

    self._hasFullChainShowCv = true
    self._fullChainShowCvTimer = 0
    self._fullChainShowCvDelay = 2
    self._chainNpcListBuffer = {}

    -- 注册事件
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcEnterOverDrive)
    self._proxy:RegisterEvent(EWorldEvent.NpcODBreakAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcWaitReboot)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.CastFullChainFinalSkill)
    self._proxy:RegisterEvent(EWorldEvent.FullChainShowStart)
end

---更新
function XRelinkLevelAudioPlayer:Update(dt)
    if self._canPraiseFullChainSuccess then
        if not self._hasSelicaPraiseFullChainSuccess and self._praiseFullChainSuccessTimer >= self._praiseFullChainSuccessSelicaDelay then
            self:PlayLevelCV(self._cvKind, EFightCVAction.PraiseFullChainSuccess, EAudioLuaFuncSyncType.All)
            self._hasSelicaPraiseFullChainSuccess = true
        end

        if self._praiseFullChainSuccessMemberA ~= nil and
                not self._hasMemberAPraiseFullChainSuccess and
                self._praiseFullChainSuccessTimer >= self._praiseFullChainSuccessMemberADelay then
            self:PlayNpcCV(self._praiseFullChainSuccessMemberA, 0, EFightCVAction.PraiseLinkTime, EAudioLuaFuncSyncType.All)
            self._hasMemberAPraiseFullChainSuccess = true
        end

        if self._praiseFullChainSuccessMemberB ~= nil and
                not self._hasMemberBPraiseFullChainSuccess and
                self._praiseFullChainSuccessTimer >= self._praiseFullChainSuccessMemberBDelay then
            self:PlayNpcCV(self._praiseFullChainSuccessMemberB, 0, EFightCVAction.PraiseLinkTime, EAudioLuaFuncSyncType.All)
            self._hasMemberBPraiseFullChainSuccess = true
        end

        self._praiseFullChainSuccessTimer = self._praiseFullChainSuccessTimer + dt
        if self._hasSelicaPraiseFullChainSuccess and self._hasMemberAPraiseFullChainSuccess and self._hasMemberBPraiseFullChainSuccess then
            self._canPraiseFullChainSuccess = false
        end
    end

    if not self._hasFullChainShowCv then
        if self._fullChainShowCvTimer <= 0 then
            for index, player in ipairs(self._chainNpcListBuffer) do
                if self._bufferedChainLevel == 2 then
                    self:PlayNpcCV(player, 0, EFightCVAction.TwoChainSuccess, EAudioLuaFuncSyncType.All)
                elseif self._bufferedChainLevel == 3 then
                    self:PlayNpcCV(player, 0, EFightCVAction.FullChainSuccess, EAudioLuaFuncSyncType.All)
                end
            end
            self._hasFullChainShowCv = true
        end

        self._fullChainShowCvTimer = self._fullChainShowCvTimer - dt
    end

    self:CoolDownUpdate(dt)
end

---结束
function XRelinkLevelAudioPlayer:Terminate()
    -- 避免关卡其他地方注册事件，不进行取消注册，关卡生命周期结束自动取消
end
--endregion

--region 事件处理
---事件处理入口
---@param eventType @事件类型
---@param eventArgs @事件数据
function XRelinkLevelAudioPlayer:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcBrokenAfter then
        self:OnNpcBrokenAfter(eventArgs.LauncherUUID, eventArgs.TargetUUID, eventArgs.MagicId)
    end
    if eventType == EWorldEvent.NpcEnterOverDrive then
        self:OnNpcEnterOverDrive(eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcODBreakAfter then
        self:OnNpcODBreakAfter(eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcWaitReboot then
        self:OnNpcWaitRebootEvent(eventArgs.NpcId, eventArgs.NpcPlaceId, eventArgs.NpcKind, eventArgs.IsPlayer, eventArgs.KillerUUID, eventArgs.MagicId, eventArgs.DeathType, eventArgs.DeathId, eventArgs.RebootType, eventArgs.RebootId)
    end
    if eventType == EWorldEvent.NpcAddBuff then
        self:OnNpcAddBuffEvent(eventArgs.CasterUUID, eventArgs.NpcUUID, eventArgs.BuffTableId, eventArgs.BuffKinds, eventArgs.BuffId)
    end
    if eventType == EWorldEvent.CastFullChainFinalSkill then
        self:OnCastFullChainFinalSkill(eventArgs.GamePlayActive, eventArgs.IsInChain, eventArgs.ChainRemainTime, eventArgs.ChainNpcList, eventArgs.ChainLevel)
    end
    if eventType == EWorldEvent.FullChainShowStart then
        self:OnFullChainShowStart(eventArgs.GamePlayActive, eventArgs.ChainNpcList, eventArgs.ChainLevel)
    end
end

---Npc破韧后
---@param launcherUUID number 发起者的UUID
---@param targetUUID number 目标的UUID
---@param magicId number Magic的配表Id
function XRelinkLevelAudioPlayer:OnNpcBrokenAfter(launcherUUID, targetUUID, magicId)
    self:PlayLevelCV(self._cvKind, EFightCVAction.Broken, EAudioLuaFuncSyncType.All)
end

---Npc 进入OD
---@param targetUUID number 目标的UUID
function XRelinkLevelAudioPlayer:OnNpcEnterOverDrive(targetUUID)
    self:PlayLevelCV(self._cvKind, EFightCVAction.EnterOverDriveWarning, EAudioLuaFuncSyncType.All)
end


---Npc OD Break后
---@param targetUUID number 目标的UUID
function XRelinkLevelAudioPlayer:OnNpcODBreakAfter(targetUUID)
    self:PlayLevelCV(self._cvKind, EFightCVAction.OverDriveBreak, EAudioLuaFuncSyncType.All)
end

---Npc等待复活
---@param npcUUID number
---@param npcPlaceId number
---@param npcKind number
---@param isPlayer boolean
---@param killerUUID number
---@param magicId number
---@param deathType number
---@param deathId number
---@param rebootType number
---@param rebootId number
function XRelinkLevelAudioPlayer:OnNpcWaitRebootEvent(npcUUID, npcPlaceId, npcKind, isPlayer, killerUUID, magicId, deathType, deathId, rebootType, rebootId)
    -- 存货玩家大于1时才考虑播放
    if #self:GetValidPlayers(true, nil) <= 1 then
        return
    end
    self:PlayLevelCV(self._cvKind, EFightCVAction.TeammateDown, EAudioLuaFuncSyncType.All)
end

---Npc添加Buff
---@param casterNpcUUID number
---@param npcUUID number
---@param buffId number
---@param buffKinds table
---@param buffUUId number
function XRelinkLevelAudioPlayer:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    -- 弹刀技警告
    if buffId == self._cvEventMagics.CounterWarning then
        self:PlayNpcCV(npcUUID, 0, EFightCVAction.CounterWarning, EAudioLuaFuncSyncType.All)
    end

    -- 弹刀成功的提示
    if buffId == self._cvEventMagics.PraiseCounterSuccess then
        local playerId = self:GetArrRandomEle(self:GetValidPlayers(true, { npcUUID }))
        if playerId ~= nil then
            self:PlayNpcCV(playerId, 0, EFightCVAction.PraiseCounterSuccess, EAudioLuaFuncSyncType.All)
        end
    end

    -- 高强度普通技能警告
    if buffId == self._cvEventMagics.HighDmgSkillWarning then
        self:PlayLevelCV(self._cvKind, EFightCVAction.HighDmgSkillWarning, EAudioLuaFuncSyncType.All)
    end

    -- 角力联弹警告
    if buffId == self._cvEventMagics.MultiQTEWarning then
        self:PlayLevelCV(self._cvKind, EFightCVAction.MultiQTEWarning, EAudioLuaFuncSyncType.All)
    end

    -- 角力联弹成功夸夸
    if buffId == self._cvEventMagics.MultiQTESuccess then
        self:PlayLevelCV(self._cvKind, EFightCVAction.NotifyMultiQTESuccess, EAudioLuaFuncSyncType.All)
    end

    -- 角力联弹支援
    if buffId == self._cvEventMagics.MultiQTESupport then
        self:PlayNpcCV(npcUUID, 0, EFightCVAction.MultiQTESupport, EAudioLuaFuncSyncType.All)
    end

    -- 角力联弹终结
    if buffId == self._cvEventMagics.MultiQTEUltimate then
        self:PlayNpcCV(npcUUID, 0, EFightCVAction.MultiQTEUltimate, EAudioLuaFuncSyncType.All)
    end

    -- 残血提醒
    if buffId == self._cvEventMagics.PlayerLowLife then
        local targetPlayer = self:GetArrRandomEle(self:GetValidPlayers(true, { npcUUID }))
        if targetPlayer ~= nil then
            self:PlayNpcCV(targetPlayer, 0, EFightCVAction.LowLifeWarning, EAudioLuaFuncSyncType.All)
        end
    end

    --[[
    -- TwoChain
    if buffId == self._cvEventMagics.TwoChainSuccess and self._bufferedChainLevel == 2 then
        self:PlayNpcCV(npcUUID, 0, EFightCVAction.TwoChainSuccess, EAudioLuaFuncSyncType.All)
    end

    -- FullChain
    if buffId == self._cvEventMagics.FullChainSuccess and self._bufferedChainLevel == 3 then
        self:PlayNpcCV(npcUUID, 0, EFightCVAction.FullChainSuccess, EAudioLuaFuncSyncType.All)
    end
    ]]

    -- 团队极限技
    if buffId == self._cvEventMagics.CastTeamworkSkill then
        self:PlayNpcCV(npcUUID, 0, EFightCVAction.CastTeamworkSkill, EAudioLuaFuncSyncType.All)
    end
end

---FullChainSkill释放！
---@param gameplayActive number 是否开启玩法
---@param isInChain number 是否在连锁状态
---@param chainRemainTime number 连锁剩余时间
---@param chainNpcList number 正在锁链的Npc
---@param chainLevel number 当前连锁段数
function XRelinkLevelAudioPlayer:OnCastFullChainFinalSkill(gameplayActive, isInChain, chainRemainTime, chainNpcList, chainLevel)
    -- 缓存连锁段数
    self._bufferedChainLevel = chainLevel

    self._canPraiseFullChainSuccess = true
    self._hasSelicaPraiseFullChainSuccess = false

    self._hasMemberAPraiseFullChainSuccess = false
    self._praiseFullChainSuccessMemberA = self:GetArrRandomEle(self:GetValidPlayersInList(chainNpcList, true, { }))

    self._hasMemberBPraiseFullChainSuccess = false
    if self._praiseFullChainSuccessMemberA ~= nil then
        self._praiseFullChainSuccessMemberB = self:GetArrRandomEle(self:GetValidPlayersInList(chainNpcList, true, {self._praiseFullChainSuccessMemberA}))
    end

    self._praiseFullChainSuccessTimer = 0
end
--endregion

--region 关卡音效播放接口
--- 关卡播放语音接口：战斗胜利
function XRelinkLevelAudioPlayer:PlayAudioFightWin()
    self:PlayLevelCV(self._cvKind, EFightCVAction.NotifyEnemyDead, EAudioLuaFuncSyncType.All)
end

--- 关卡播放语音接口：战斗失败（玩家团灭）
function XRelinkLevelAudioPlayer:PlayAudioFightLose()
    self:PlayLevelCV(self._cvKind, EFightCVAction.AllCharacterEliminated, EAudioLuaFuncSyncType.All)
end

---FullChainSkill表演开始
---@param gameplayActive number 是否开启玩法
---@param chainNpcList number 正在锁链的Npc
---@param chainLevel number 当前连锁段数
function XRelinkLevelAudioPlayer:OnFullChainShowStart(gameplayActive, chainNpcList, chainLevel)
    self._fullChainShowCvTimer = self._fullChainShowCvDelay
    self._bufferedChainLevel = chainLevel
    self._chainNpcListBuffer = chainNpcList
    self._hasFullChainShowCv = false
end
--endregion

--region音效播放
---播放关卡CV，代理无效则不执行逻辑
function XRelinkLevelAudioPlayer:PlayLevelCV(npcCvKind, actionId, syncType)
    if self._proxy == nil then
        return
    end
    if self:IsActionInCD(actionId) then
        return
    end
    if not self:CheckCvActionValidation(actionId) then
        return
    end

    self._proxy:PlayLevelCV(npcCvKind, actionId, syncType)
    self:EnterCD(actionId)
end

---播放角色CV，代理无效则不执行逻辑
function XRelinkLevelAudioPlayer:PlayNpcCV(npcUUID, npcCvKind, actionId, syncType)
    if self._proxy == nil then
        return
    end
    if self:IsActionInCD(actionId) then
        return
    end
    if not self:CheckCvActionValidation(actionId) then
        return
    end

    self._proxy:PlayNpcCV(npcUUID, npcCvKind, actionId, syncType)
    self:EnterCD(actionId)
end
--endregion

--region 音效冷却
function XRelinkLevelAudioPlayer:CoolDownUpdate(dt)
    for actionType, coolDown in pairs(self._actionCDs) do
        coolDown.timer = coolDown.timer - dt
    end
end

function XRelinkLevelAudioPlayer:IsActionInCD(actionId)
    local coolDown = self._actionCDs[actionId]

    if coolDown == nil then
        return false
    end

    return coolDown.timer > 0
end

function XRelinkLevelAudioPlayer:EnterCD(actionId)
    local coolDown = self._actionCDs[actionId]

    if coolDown == nil then
        return
    end

    coolDown.timer = coolDown.coolDown
end
--endregion

--region 工具
---数组里随机选择一个元素
---@param list table
function XRelinkLevelAudioPlayer:GetArrRandomEle(array)
    if array == nil or #array == 0 then
        return nil
    end

    if #array == 1 then
        return array[1]
    end

    return array[self._proxy:Random(1, #array)]
end

function XRelinkLevelAudioPlayer:GetValidPlayersInList(players, checkDeath, exceptedTargets)
    local validPlayers = {}
    for i, player in ipairs(players) do
        if self:CheckPlayer(player, checkDeath) and not self:Contain(exceptedTargets, player) then
            table.insert(validPlayers, player)
        end
    end

    return validPlayers
end

function XRelinkLevelAudioPlayer:GetValidPlayers(checkDeath, exceptedTargets)
    return self:GetValidPlayersInList(self._proxy:GetPlayerNpcList(), checkDeath, exceptedTargets)
end

function XRelinkLevelAudioPlayer:CheckPlayer(npcUUID, checkDeath)
    local result = npcUUID ~= nil and npcUUID ~= 0
    if checkDeath and result then
        result = result and not self._proxy:IsNpcDead(npcUUID)
    end
    return result
end

function XRelinkLevelAudioPlayer:Contain(tableToCheck, target)
    if tableToCheck == nil then
        return false
    end

    for k, v in pairs(tableToCheck) do
        if v == target then
            return true
        end
    end

    return false
end

--- 设置CvAction可用性
--- @param actionId int @ CvAction的ID
--- @param isValid bool @ 是否可用
function XRelinkLevelAudioPlayer:SetCvActionValidation(actionId, isValid)
    if self._actionValidations[actionId] == nil then
        return false
    end
    self._actionValidations[actionId] = isValid
end

--- 检测指定CvAction是否可用
function XRelinkLevelAudioPlayer:CheckCvActionValidation(actionId)
    if self._actionValidations[actionId] == nil then
        return true
    end
    return self._actionValidations[actionId]
end
--endregion

--region 调试
function XRelinkLevelAudioPlayer:Log(text)
    XLog.Debug("Relink关卡音频播放器: " .. tostring(text))
end
--endregion

return XRelinkLevelAudioPlayer