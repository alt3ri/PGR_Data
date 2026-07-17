local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")

---@class XTheatre6Agency : XFubenActivityAgency
---@field private _Model XTheatre6Model
---@field Battle XTheatre6BattleAgency
local XTheatre6Agency = XClass(XFubenSimulationChallengeAgency, "XTheatre6Agency")

function XTheatre6Agency:OnInit()
    self:RegisterChapterAgency()

    self._SkillUpEffectPopupQueue = {}
    self._IsSkillUpEffectPopupOpening = false
    self.RichTextImageCallBack = handler(self, self.OnRichTextImageCallBack)
    self.Battle = self:AddSubAgency(require("XModule/XTheatre6/SubAgency/XTheatre6BattleAgency"))
end

--因为服务端的Buff触发逻辑比较复杂，可能会在进入请求的返回协议前就发一些协议过来，这里做个保底
---包装RPC回调，仅在GetCurPlayModeData()有值时才执行
function XTheatre6Agency:SafeHandler(func)
    return function(data)
        if not self._Model:GetCurPlayModeData() then
            return
        end
        func(self, data)
    end
end

function XTheatre6Agency:InitRpc()
    XRpc.NotifyTheatre6ActivityData = handler(self, self.NotifyTheatre6ActivityData)
    XRpc.NotifyTheatre6NewFloorData = handler(self, self.NotifyTheatre6NewFloorData)
    XRpc.NotifyTheatre6NewRoomData = handler(self, self.NotifyTheatre6NewRoomData)
    XRpc.NotifyTheatre6SanChange = self:SafeHandler(self.NotifyTheatre6SanChange)
    XRpc.NotifyTheatre6HealthChange = self:SafeHandler(self.NotifyTheatre6HealthChange)
    XRpc.NotifyTheatre6GoldChange = self:SafeHandler(self.NotifyTheatre6GoldChange)
    XRpc.NotifyTheatre6GoodsChange = self:SafeHandler(self.NotifyTheatre6GoodsChange)
    XRpc.Theatre6TotalScoreNotify = self:SafeHandler(self.Theatre6TotalScoreNotify)
    XRpc.NotifyTheatre6SettleData = handler(self, self.NotifyTheatre6SettleData)
    XRpc.NotifyTheatre6AddBuff = self:SafeHandler(self.NotifyTheatre6AddBuff)
    XRpc.NotifyTheatre6BuffUpdate = self:SafeHandler(self.NotifyTheatre6BuffUpdate)
    XRpc.NotifyTheatre6DelBuff = self:SafeHandler(self.NotifyTheatre6DelBuff)
    XRpc.NotifyTheatre6AddBgm = self:SafeHandler(self.NotifyTheatre6AddBgm)
    XRpc.NotifyTheatre6DelBgm = self:SafeHandler(self.NotifyTheatre6DelBgm)
    XRpc.NotifyTheatre6AddMessyCode = self:SafeHandler(self.NotifyTheatre6AddMessyCode)
    XRpc.NotifyTheatre6DelMessyCode = self:SafeHandler(self.NotifyTheatre6DelMessyCode)
    XRpc.NotifyTheatre6WarningMsg = handler(self, self.NotifyTheatre6WarningMsg)
    XRpc.NotifyTheatre6TalentLevel = handler(self, self.NotifyTheatre6TalentLevel)
    XRpc.NotifyTheatre6AddSkill = self:SafeHandler(self.NotifyTheatre6AddSkill)
    XRpc.NotifyTheatre6AttrChange = self:SafeHandler(self.NotifyTheatre6AttrChange)
    XRpc.NotifyTheatre6AttrPackChange = self:SafeHandler(self.NotifyTheatre6AttrPackChange)
    XRpc.NotifyTheatre6SkillUpEffect = self:SafeHandler(self.NotifyTheatre6SkillUpEffect)
    XRpc.NotifyTheatre6PvpGetActionPoint = handler(self, self.NotifyTheatre6PvpGetActionPoint)
    XRpc.NotifyTheatre6PvpTinyBattleState = handler(self, self.NotifyTheatre6PvpTinyBattleState)
    XRpc.NotifyTheatre6BattleRecordsUpdate = handler(self, self.NotifyTheatre6BattleRecordsUpdate)
    XRpc.NotifyTheatre6DefenseUpdate = handler(self, self.NotifyTheatre6DefenseUpdate)
    XRpc.NotifyTheatre6ModeChange = handler(self, self.NotifyTheatre6ModeChange)
    XRpc.NotifyTheatre6PvpBattleStatsUpdate = handler(self, self.NotifyTheatre6PvpBattleStatsUpdate)
    XRpc.NotifyMatchPlayersUpdate = handler(self, self.NotifyMatchPlayersUpdate)
    XRpc.NotifyTheatre6PvpScoreUpdate = handler(self, self.NotifyTheatre6PvpScoreUpdate)
end

function XTheatre6Agency:InitEvent()
    XMVCA.XDlcHelper:AddDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.Theatre6, self)
end

function XTheatre6Agency:RemoveEvent()
    XMVCA.XDlcHelper:RemoveDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.Theatre6, self)
end

function XTheatre6Agency:OnRelease()
    self:ClearPendingSettleData()
    self:ClearSkillUpEffectPopupQueue()
end

--region overrride

function XTheatre6Agency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.Theatre6
end

function XTheatre6Agency:ExOpenMainUi()
    if not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.Theatre6) then
        return false
    end

    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre6, true) then
        if self:ExCheckInTime() then
            XLuaUiManager.Open("UiTheatre6Main")
            return true
        else
            XUiManager.TipText("CommonActivityNotStart")
        end
    end

    return false
end

---通用跳转接口（SkipId）
function XTheatre6Agency:ExOnSkip()
    if self:ExOpenMainUi() then
        return true
    end

    return false
end

function XTheatre6Agency:ExGetDlcModelIdByCharacterData(characterData)
    local fashionId = characterData.FashionId
    if XTool.IsNumberValid(fashionId) then
        local fashionConfig = self._Model:GetFashionConfig(fashionId)
        return fashionConfig and fashionConfig.DlcModelId
    end
    return nil
end

---是否有限时显示
function XTheatre6Agency:ExCheckInTimerShow()
    local timeId = self._Model:GetIntClientConfigValue("EntranceTimeId")
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

---限时显示文本
function XTheatre6Agency:ExGetTimerShowStr()
    local timeId = self._Model:GetIntClientConfigValue("EntranceTimeId")
    if XTool.IsNumberValid(timeId) then
        local now = XTime.GetServerNowTimestamp()
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        local leftTime = math.max(endTime - now, 0)
        return XUiHelper.GetText("Theatre6EntranceTimeLabel",
            XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    else
        return ''
    end
end

--endregion

----------public start----------

function XTheatre6Agency:IsPvpInActivityTime()
    local config = self._Model.Pvp:GetActivityConfig()
    local timeId = config and config.TimeId or 0
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XTheatre6Agency:HandlePvpActivityEnd()
    local uiName = "UiTheatre6Main"
    if XLuaUiManager.IsStackUiOpen(uiName) then
        XLuaUiManager.CloseAllUpperUi(uiName)
    else
        XLuaUiManager.RunMain(true)
    end
    XUiManager.TipText("CommonActivityEnd")
end

---获取最新剧情更新时间
---@return number
function XTheatre6Agency:GetLatestStoryUpdateTime()
    local timeStr = self._Model:GetClientConfigValue("StoryUpdateTime")
    if string.IsNilOrEmpty(timeStr) then
        return nil
    end
    return XTime.ParseToTimestamp(timeStr)
end

---获取最后查看剧情时间
---@return number
function XTheatre6Agency:GetLastViewStoryTime()
    return self._Model:GetLastViewStoryTime()
end

---文本组件获取图片路径接口
function XTheatre6Agency:OnRichTextImageCallBack(key, image)
    local url = self._Model:GetClientConfigValue(key)
    if string.IsNilOrEmpty(url) then
        XLog.Error("创建图片失败! Theatre6ClientConfig.stab 未配置主键 = " .. key)
        return
    end
    image:SetSprite(url)
end

function XTheatre6Agency:GetFashionByCharacterId(id)
    local modelData = self._Model:GetCurPlayModeData()
    if modelData and modelData.CharacterId == id then
        return self._Model:GetFashionConfig(modelData.FashionId)
    else
        local characterConfig = self._Model:GetCharacterConfig(id)
        return self._Model:GetFashionConfig(characterConfig.FashionIds[1])
    end
end

function XTheatre6Agency:GetBuildTagConfig(buildTagId)
    return self._Model:GetBuildTagConfig(buildTagId)
end

function XTheatre6Agency:PlayAudioWithoutFight()
    if XFightUtil.IsFighting() then
        return
    end
    self:PlayAudio()
end

---[1]、进入局内时播放，回到局外时停止
---[2]、进入局内商店时停止，离开时恢复播放
---[3]、进入战斗时不停止，等待战斗内自己的音频顶掉，关闭战斗奖励界面时恢复
---[4]、全流程结束，进入结算界面时停止
---[5]、buff音频播放优先级高于san音频
function XTheatre6Agency:PlayAudio()
    local cur = self._Model:GetCurSanCueId()
    local now = self._Model:GetBuffCueId()
    if not now then
        now = self._Model:GetCurSanConfig().CueId
    end

    if cur == now then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, now, false)
        return
    end

    if XTool.IsNumberValid(cur) then
        XLuaAudioManager.StopAudioByCueId(cur)
    end

    if XTool.IsNumberValid(now) then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, now)
    end

    self._Model:SetCurSanCueId(now)
end

function XTheatre6Agency:StopAudio()
    local cur = self._Model:GetCurSanCueId()
    if XTool.IsNumberValid(cur) then
        XLuaAudioManager.StopAudioByCueId(cur)
        self._Model:SetCurSanCueId(nil)
    end
end

function XTheatre6Agency:IsStagePassTimes(stageId, times)
    return self._Model:IsStagePassTimes(stageId, times)
end

function XTheatre6Agency:IsDiffPassTimaes(diffId, times)
    return self._Model:IsDiffPassTimaes(diffId, times)
end

--- 拥有x个存档
---@param needCount number 需要的存档数量
---@return boolean
function XTheatre6Agency:CheckFileDataCount(needCount)
    if needCount <= 0 then
        return false
    end
    local fileDataList = self._Model:GetAllFileData()
    return fileDataList and #fileDataList >= needCount or false
end

--- 检查PVP战斗次数是否满足条件
---@param onlyWin boolean 是否仅统计胜利
---@param includeAdvance boolean 是否包含进阶战斗
---@param targetCount number 需要达到的次数
---@param targetRankId number 限制段位（0=不限制段位）
---@return boolean
function XTheatre6Agency:CheckPvpBattleCount(onlyWin, includeAdvance, targetCount, targetRankId)
    local battleStats = self._Model.Pvp:GetBattleStats()
    if not battleStats then
        return false
    end

    local count = 0
    if onlyWin then
        count = count + self:GetRankRecordCount(battleStats.NormalBattleWinCounts, targetRankId)
        if includeAdvance then
            count = count + self:GetRankRecordCount(battleStats.AdvanceBattleWinCounts, targetRankId)
        end
    else
        count = count + self:GetRankRecordCount(battleStats.NormalBattleCounts, targetRankId)
        if includeAdvance then
            count = count + self:GetRankRecordCount(battleStats.AdvanceBattleCounts, targetRankId)
        end
    end

    return count >= targetCount
end

--- 获取指定段位的战斗记录数量
---@param record table<number, number> 战斗记录表，key为段位Id，value为对应段位的数量
---@param rankId number 限制段位（0=不限制段位）
---@return number
function XTheatre6Agency:GetRankRecordCount(record, rankId)
    if not record then
        return 0
    end
    if rankId == 0 then
        local total = 0
        for _, count in pairs(record) do
            total = total + count
        end
        return total
    end
    return record[rankId] or 0
end

--- PVP段位是否达到
---@param targetRankId number 目标段位Id
---@param activityId number 指定版本Id(0=当前期)
---@return boolean
function XTheatre6Agency:IsPvpRankReached(targetRankId, activityId)
    if not XTool.IsNumberValid(activityId) or activityId == self._Model.Pvp:GetCurActivityId() then
        return self._Model.Pvp:GetCurRankId() >= targetRankId
    end
    local rankRecord = self._Model.Pvp:GetPvpRankRecord(activityId)
    if rankRecord and XTool.IsNumberValid(rankRecord.RankId) then
        return rankRecord.RankId >= targetRankId
    end
    return false
end

function XTheatre6Agency:CheckOpenSettle()
    local data = self._PendingSettleData
    if not data then
        return false
    end
    self:ClearPendingSettleData()
    XLuaUiManager.OpenWithCloseCallback("UiTheatre6Settlement", function()
        self._Model:NotifyTheatre6SettleData()
    end, data, self._Model:GetCurPlayMode())
    return true
end

function XTheatre6Agency:ClearPendingSettleData()
    self._PendingSettleData = nil
end

function XTheatre6Agency:ClearSkillUpEffectPopupQueue()
    self._SkillUpEffectPopupQueue = {}
    self._IsSkillUpEffectPopupOpening = false
end

function XTheatre6Agency:SetSettlementLock(isDelayOpen)
    self._IsDelaySettleOpen = isDelayOpen
end

----------public end----------

---获取有效的商店或任务配置列表
---@param taskShopType number
---@return XTableTheatre6Reward[]
function XTheatre6Agency:GetValidShopOrTaskList(taskShopType)
    return self._Model:GetTaskOrShopCfgs(taskShopType) or {}
end

----------private start----------
function XTheatre6Agency:NotifyTheatre6ActivityData(data)
    self._Model:NotifyTheatre6ActivityData(data)
end

function XTheatre6Agency:NotifyTheatre6NewFloorData(data)
    self._Model:UpdateNewFloorData(data.ModeDataDb)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_ENTER_NEW_ROOM)
end

function XTheatre6Agency:NotifyTheatre6NewRoomData(data)
    self._Model:NotifyTheatre6NewRoomData(data)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_ENTER_NEW_ROOM)
end

function XTheatre6Agency:NotifyTheatre6SanChange(data)
    self._Model:NotifyTheatre6SanChange(data)
    local node = self._Model.StageChain.Curr
    if node and node.RoomType ~= XEnumConst.Theatre6.RoomType.BattleShop then
        self:PlayAudioWithoutFight()
    end
end

function XTheatre6Agency:NotifyTheatre6HealthChange(data)
    self._Model:NotifyTheatre6HealthChange(data)
end

function XTheatre6Agency:NotifyTheatre6GoldChange(data)
    self._Model:NotifyTheatre6GoldChange(data)
end

function XTheatre6Agency:NotifyTheatre6GoodsChange(data)
    self._Model:NotifyTheatre6GoodsChange(data)
end

function XTheatre6Agency:Theatre6TotalScoreNotify(data)
    self._Model:Theatre6TotalScoreNotify(data)
end

function XTheatre6Agency:NotifyTheatre6SettleData(data)
    self:EnterSettleProcess(data.SettleData, data.StoryModeSaveDb)
end

---进入结算流程
function XTheatre6Agency:EnterSettleProcess(settleData, storyModeSaveDb)
    self._Model:UpdateSettleData(settleData, storyModeSaveDb)
    self._PendingSettleData = settleData
    if XFightUtil.IsFighting() then
        return --处于战斗界面时延迟打开
    end
    if self._IsDelaySettleOpen then
        return --处于二择展示弹框期间时延迟打开
    end
    self:CheckOpenSettle()
end

function XTheatre6Agency:NotifyTheatre6AddBuff(data)
    self._Model:NotifyTheatre6AddBuff(data)
    local buffId = data.BuffData.BuffId
    if buffId == self._Model:GetSanDeathBuffId() then
        self:ShowDeathBuff(data.BuffData)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_BUFF_CHANGE)
end

function XTheatre6Agency:ShowDeathBuff(buffData)
    local isFighting = XFightUtil.IsFighting()

    --二择期间获得san值buff 给Theatre6ChooseEventRequest那边处理
    local curr = self._Model.StageChain.Curr
    if not isFighting and curr and curr.RoomType == XEnumConst.Theatre6.RoomType.ChooseOption then
        return
    end

    self._Model:SetShowDeathBuff(buffData)

    if isFighting then
        return
    end

    self:OpenSanDeathBuffPopup()
end

function XTheatre6Agency:NotifyTheatre6BuffUpdate(data)
    self._Model:NotifyTheatre6BuffUpdate(data)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_BUFF_CHANGE)
end

function XTheatre6Agency:NotifyTheatre6DelBuff(data)
    self._Model:NotifyTheatre6DelBuff(data)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_BUFF_CHANGE)
end

function XTheatre6Agency:NotifyTheatre6AddBgm(data)
    self._Model:NotifyTheatre6AddBgm(data)
    self:PlayAudioWithoutFight()
end

function XTheatre6Agency:NotifyTheatre6DelBgm(data)
    self._Model:NotifyTheatre6DelBgm(data)
    self:PlayAudioWithoutFight()
end

function XTheatre6Agency:NotifyTheatre6AddMessyCode(data)
    self._Model:NotifyTheatre6AddMessyCode(data)
end

function XTheatre6Agency:NotifyTheatre6DelMessyCode(data)
    self._Model:NotifyTheatre6DelMessyCode(data)
end

function XTheatre6Agency:NotifyTheatre6WarningMsg(data)
    if XMain.IsEditorDebug then
        XLog.Warning(string.format("肉鸽6服务端警告信息：%s", data.Msg))
    end
end

function XTheatre6Agency:NotifyTheatre6TalentLevel(data)
    self._Model:NotifyTheatre6TalentLevel(data)
end

function XTheatre6Agency:NotifyTheatre6AddSkill(data)
    self._Model:NotifyTheatre6AddSkill(data)

    self._GainTipSkillId, self._IsUpGrade = self._Model.Skill:GetAddSkillGainTipData(data)
    if not XFightUtil.IsFighting() then
        self:TryOpenAddSkillGainTips()
    end
end

function XTheatre6Agency:TryOpenAddSkillGainTips()
    if not XTool.IsNumberValid(self._GainTipSkillId) then
        return
    end
    if XLuaUiManager.IsUiShow("UiTheatre6GainTips") then
        XLuaUiManager.Close("UiTheatre6GainTips")
    end
    XLuaUiManager.Open("UiTheatre6GainTips", 1, self._GainTipSkillId, self._IsUpGrade)
    self:ClearGainTipsParams()
end

function XTheatre6Agency:ClearGainTipsParams()
    self._GainTipSkillId = nil
    self._IsUpGrade = nil
end

function XTheatre6Agency:NotifyTheatre6AttrChange(data)
    self._Model:NotifyTheatre6AttrChange(data)
end

function XTheatre6Agency:NotifyTheatre6AttrPackChange(data)
    self._Model:NotifyTheatre6AttrPackChange(data)
end

function XTheatre6Agency:NotifyTheatre6SkillUpEffect(data)
    if XTool.IsTableEmpty(data.BuffDatas) then
        XLog.Error("肉鸽6技能升级数据异常，BuffDatas为空")
        return
    end
    self:ShowSkillUpEffect(data.BuffDatas)
end

function XTheatre6Agency:NotifyTheatre6ModeChange(data)
    self._Model:NotifyTheatre6ModeChange(data)
end

function XTheatre6Agency:ShowSkillUpEffect(buffDatas, finishCb)
    if XTool.IsTableEmpty(buffDatas) then
        if finishCb then
            finishCb()
        end
        return
    end

    local showUi = false
    for _, slotType in pairs(XEnumConst.Theatre6.SlotType) do
        local defaultSkill = self._Model.Skill:GetCharacterSkills(slotType)[1]

        local skillId = defaultSkill and defaultSkill.SkillId or nil
        showUi = showUi or XTool.IsNumberValid(skillId)
    end

    for _, buffData in ipairs(buffDatas) do
        local buffCfg = self._Model:GetBuffConfig(buffData.BuffId)
        if not buffCfg or XTool.IsTableEmpty(buffCfg.BuffEffectParams) then
            XLog.Error(string.format("肉鸽6技能升级数据异常，BuffId=%s", buffData.BuffId))
        else
            local levelUpCount = buffCfg.BuffEffectParams[1]
            local levelUpLevel = buffCfg.BuffEffectParams[2]
            local levelUpLimit = buffCfg.BuffEffectParams[3]
            local levelUpQuality = buffCfg.BuffEffectParams[4]
            if not showUi or not self:HasAnyBuffUpgradableSkill(levelUpCount, levelUpLimit, levelUpQuality) then
                self:EnqueueSkillUpEffectPopup("UiTheatre6PopupCommon", "",
                    XUiHelper.GetText("Theatre6PopupSkillLevelUpNotShow"))
            else
                self:EnqueueSkillUpEffectPopup("UiTheatre6PopupSkillLevelUp", buffData.Uid, levelUpCount, levelUpLevel,
                    levelUpLimit, levelUpQuality)
            end
        end
    end

    self:TryOpenNextSkillUpEffectPopup(finishCb)
end

---背包/装备槽内是否存在符合本次 buff 升级条件的技能,与 popup 的 ConditionLevelUp 口径一致(不含已升次数 delta)
function XTheatre6Agency:HasAnyBuffUpgradableSkill(levelUpCount, levelUpLimit, levelUpQuality)
    if not levelUpCount or levelUpCount <= 0 then
        return false
    end
    levelUpLimit = levelUpLimit or 0
    levelUpQuality = levelUpQuality or 0
    for _, slotType in pairs(XEnumConst.Theatre6.SlotType) do
        local skills = self._Model.Skill:GetCharacterSkills(slotType)
        for _, skill in pairs(skills or {}) do
            local skillId = skill and skill.SkillId
            if XTool.IsNumberValid(skillId) and XTool.IsNumberValid(self._Model.Skill:GetNextLevelSkillId(skillId)) then
                local cfg = self._Model:GetSkillCfgById(skillId)
                local levelOk = levelUpLimit == 0 or cfg.Level < levelUpLimit
                local qualityOk = levelUpQuality == 0 or cfg.Quality <= levelUpQuality
                if levelOk and qualityOk then
                    return true
                end
            end
        end
    end
    return false
end

function XTheatre6Agency:EnqueueSkillUpEffectPopup(uiName, ...)
    self._SkillUpEffectPopupQueue = self._SkillUpEffectPopupQueue or {}
    table.insert(self._SkillUpEffectPopupQueue, {
        UiName = uiName,
        Args = { ... }
    })
end

function XTheatre6Agency:TryOpenNextSkillUpEffectPopup(finishCb)
    if self._IsSkillUpEffectPopupOpening or XTool.IsTableEmpty(self._SkillUpEffectPopupQueue) then
        if finishCb then
            finishCb()
        end
        return
    end

    local popupData = table.remove(self._SkillUpEffectPopupQueue, 1)
    if not popupData then
        if finishCb then
            finishCb()
        end
        return
    end

    self._IsSkillUpEffectPopupOpening = true
    XLuaUiManager.OpenWithCloseCallback(popupData.UiName, function()
        self._IsSkillUpEffectPopupOpening = false
        self:TryOpenNextSkillUpEffectPopup(finishCb)
    end, table.unpack(popupData.Args))
end

function XTheatre6Agency:OpenSanDeathBuffPopup()
    local buffData = self._Model:GetShowDeathBuffWithClear()
    if not buffData then
        return
    end
    XLuaUiManager.Open("UiTheatre6PopupGetBuff", { buffData }, true)
end

function XTheatre6Agency:CheckTaskRedPoint()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre6, true, true) then
        return false
    end

    local configs = self:GetValidShopOrTaskList(XEnumConst.Theatre6.TaskShopType.Task)
    if XTool.IsTableEmpty(configs) then
        return false
    end

    for _, config in ipairs(configs) do
        if XTool.IsNumberValid(config.TaskTimeLimitId) then
            local taskTimeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(config.TaskTimeLimitId)
            if taskTimeLimitCfg and taskTimeLimitCfg.TaskId then
                local timeId = taskTimeLimitCfg.TimeId
                if not XTool.IsNumberValid(timeId) or XFunctionManager.CheckInTimeByTimeId(timeId) then
                    for _, taskId in pairs(taskTimeLimitCfg.TaskId) do
                        if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function XTheatre6Agency:RunChain(steps, finalCb)
    local index = 1
    local function next()
        local step = steps[index]
        index = index + 1

        if step then
            step(next)
        else
            if finalCb then
                finalCb()
            end
        end
    end
    next()
end

function XTheatre6Agency:NotifyTheatre6PvpGetActionPoint(data)
    self._Model.Pvp:UpdateActionPointInfo(data)
end

function XTheatre6Agency:NotifyTheatre6PvpTinyBattleState(data)
    self._Model.Pvp:UpdateTinyBattleState(data)
end

function XTheatre6Agency:NotifyTheatre6BattleRecordsUpdate(data)
    if not data then
        return
    end
    self._Model.Pvp:AddBattleRecords(data.BattleRecords)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_PVP_RECORD_UPDATE)
end

function XTheatre6Agency:NotifyTheatre6DefenseUpdate(data)
    if not data then
        return
    end
    self._Model.Pvp:UpdateDefenseSlots(data.DefenseBuffId, data.Lineups)
end

function XTheatre6Agency:NotifyTheatre6PvpBattleStatsUpdate(data)
    if not data then
        return
    end
    self._Model.Pvp:UpdateBattleStats(data.BattleStats)
end

function XTheatre6Agency:NotifyMatchPlayersUpdate(data)
    self._Model.Pvp:UpdateMatchResult(data)
end

function XTheatre6Agency:NotifyTheatre6PvpScoreUpdate(data)
    if not data then
        return
    end
    self._Model.Pvp:UpdateRank(data.RankId, data.Score)
end

----------private end----------

return XTheatre6Agency
