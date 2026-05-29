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
end

function XTheatre6Agency:InitEvent()
    XMVCA.XDlcHelper:AddDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.Theatre6, self)
end

function XTheatre6Agency:OnRelease()
    self:ClearPendingSettleData()
    self:ClearSkillUpEffectPopupQueue()
    XMVCA.XDlcHelper:RemoveDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.Theatre6, self)
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
        return XUiHelper.GetText("Theatre6EntranceTimeLabel", XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    else
        return ''
    end
end

--endregion

----------public start----------

---获取最新剧情更新时间
---@return number
function XTheatre6Agency:GetLatestStoryUpdateTime()
    local values = self._Model:GetConfigValues("StoryUpdateTime")
    if #values ~= 0 then
        return XTime.ParseToTimestamp(values[#values])
    end
    return 0
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

function XTheatre6Agency:PlayBuffAudio()
    local cur = self._Model:GetCurBuffCueId()
    local now = self._Model:GetBuffCueId()
    if cur == now then
        return
    end

    if XTool.IsNumberValid(cur) then
        XLuaAudioManager.StopAudioByCueId(cur)
    end

    if XTool.IsNumberValid(now) then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, now)
    end

    self._Model:SetCurBuffCueId(now)
end

function XTheatre6Agency:StopBuffAudio()
    local cur = self._Model:GetCurBuffCueId()
    if XTool.IsNumberValid(cur) then
        XLuaAudioManager.StopAudioByCueId(cur)
        self._Model:SetCurBuffCueId(nil)
    end
end

function XTheatre6Agency:PlaySanAudio()
    local cur = self._Model:GetCurSanCueId()
    local now = self._Model:GetCurSanConfig().CueId
    if cur == now then
        return
    end

    if XTool.IsNumberValid(cur) then
        XLuaAudioManager.StopAudioByCueId(cur)
    end

    if XTool.IsNumberValid(now) then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, now)
    end

    self._Model:SetCurSanCueId(now)
end

function XTheatre6Agency:StopSanAudio()
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

function XTheatre6Agency:OpenSettle()
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

----------public end----------

---@return XTableTheatre6Reward[]
function XTheatre6Agency:GetValidShopOrTaskList(taskShopType)
    return self._Model:GetTaskOrShopCfgs(taskShopType) or {}
end

----------private start----------
function XTheatre6Agency:NotifyTheatre6ActivityData(data)
    self._Model:NotifyTheatre6ActivityData(data)
end

function XTheatre6Agency:NotifyTheatre6NewFloorData(data)
    self._Model:NotifyTheatre6NewFloorData(data)
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
        self:PlaySanAudio()
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
    self._Model:UpdateSettleData(data)
    self._PendingSettleData = data.SettleData
    if not XFightUtil.IsFighting() then
        self:OpenSettle()
    end
end

function XTheatre6Agency:NotifyTheatre6AddBuff(data)
    self._Model:NotifyTheatre6AddBuff(data)
    local buffId = data.BuffData.BuffId
    if buffId == self._Model:GetSanDeathBuffId() then
        self._Model:SetShowDeathBuff(data.BuffData)
        self:OpenSanDeathBuffPopup()
    end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_BUFF_CHANGE)
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
    self:PlayBuffAudio()
end

function XTheatre6Agency:NotifyTheatre6DelBgm(data)
    self._Model:NotifyTheatre6DelBgm(data)
    self:PlayBuffAudio()
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

function XTheatre6Agency:ShowSkillUpEffect(buffDatas, finishCb)
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
        elseif not showUi then
            self:EnqueueSkillUpEffectPopup("UiTheatre6PopupCommon", "", XUiHelper.GetText("Theatre6PopupSkillLevelUpNotShow"))
        else
            local levelUpCount = buffCfg.BuffEffectParams[1]
            local levelUpLevel = buffCfg.BuffEffectParams[2]
            local levelUpLimit = buffCfg.BuffEffectParams[3]
            local levelUpQuality = buffCfg.BuffEffectParams[4]

            self:EnqueueSkillUpEffectPopup("UiTheatre6PopupSkillLevelUp", levelUpCount, levelUpLevel, levelUpLimit, levelUpQuality)
        end
    end

    self:TryOpenNextSkillUpEffectPopup(finishCb)
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
        self:TryOpenNextSkillUpEffectPopup()
    end, table.unpack(popupData.Args))
end

function XTheatre6Agency:OpenSanDeathBuffPopup()
    if XFightUtil.IsFighting() then
        return
    end
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
                for _, taskId in pairs(taskTimeLimitCfg.TaskId) do
                    if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

----------private end----------

return XTheatre6Agency
