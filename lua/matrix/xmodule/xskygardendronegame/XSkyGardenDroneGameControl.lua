local XSGDroneChapterEntity = require("XModule/XSkyGardenDroneGame/XEntity/XSGDroneChapterEntity")

---@class XSkyGardenDroneGameControl : XEntityControl
---@field private _Model XSkyGardenDroneGameModel
local XSkyGardenDroneGameControl = XClass(XEntityControl, "XSkyGardenDroneGameControl")

function XSkyGardenDroneGameControl:OnInit()
    -- 初始化内部变量
    ---@type XSGDroneChapterEntity[]
    self._ChapterEntities = false

    self.DroneType = {
        Normal = 1,
        Magnetic = 2,
        Supercomputing = 3,
        LaunchDrone = 4,
    }

    self.KeyPromptedType = {
        Accelerate = 1,
        UTurn = 2,
        Jump = 3,
        Supercomputing = 4,
        Launch = 5,
        LockOn = 6,
    }

    self.SettleType = {
        Win = 1,
        Lose = 2,
        Leave = 3,
    }

    self._Dialogues = false

    self._PcPressHandle = Handler(self, self.OnPressPCKeyHandle)

    self:SendEnterGameCmd()
end

function XSkyGardenDroneGameControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XSkyGardenDroneGameControl:RemoveAgencyEvent()

end

function XSkyGardenDroneGameControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
    self._Dialogues = false
    self:SendLeaveGameCmd()
end

---@return XSGDroneChapterEntity[]
function XSkyGardenDroneGameControl:GetChapterEntities()
    if not self._ChapterEntities then
        local chapters = self._Model:GetSgDroneGameChapterConfigs()

        self._ChapterEntities = {}
        for id, _ in pairs(chapters) do
            table.insert(self._ChapterEntities, self:AddEntity(XSGDroneChapterEntity, id))
        end
    end

    return self._ChapterEntities
end

function XSkyGardenDroneGameControl:GetChapterTotalStarCount(chapterType)
    local chapterEntities = self:GetChapterEntities()
    local totalStarCount = 0

    for _, chapterEntity in pairs(chapterEntities) do
        if chapterEntity:GetType() == chapterType then
            totalStarCount = totalStarCount + chapterEntity:GetTotalStarCount()
        end
    end

    return totalStarCount
end

function XSkyGardenDroneGameControl:GetChapterCurrentStarCount(chapterType)
    local chapterEntities = self:GetChapterEntities()
    local currentStarCount = 0

    for _, chapterEntity in pairs(chapterEntities) do
        if chapterEntity:GetType() == chapterType then
            currentStarCount = currentStarCount + chapterEntity:GetCurrentStarCount()
        end
    end

    return currentStarCount
end

---@return XSGDroneStageEntity
function XSkyGardenDroneGameControl:GetStageEntity(stageId)
    local chapterEntities = self:GetChapterEntities()

    if not XTool.IsTableEmpty(chapterEntities) then
        for _, chapterEntity in pairs(chapterEntities) do
            local stageEntity = chapterEntity:GetStageEntity(stageId)

            if stageEntity then
                return stageEntity
            end
        end
    end

    return nil
end

function XSkyGardenDroneGameControl:GetChapterStarProgressText(chapterType)
    local totalStarCount = self:GetChapterTotalStarCount(chapterType)
    local currentStarCount = self:GetChapterCurrentStarCount(chapterType)

    return string.format("<color=#f8fffd>%d</color>/%d", currentStarCount, totalStarCount)
end

function XSkyGardenDroneGameControl:GetDroneTeachingVideoId(droneId)
    return self._Model:GetSgDroneGameDroneDisplayTeachingVideoIdById(droneId)
end

function XSkyGardenDroneGameControl:GetDroneDescription(droneId)
    local description = self._Model:GetSgDroneGameDroneDisplayDescriptionById(droneId)

    if not description then
        return ""
    end

    return XUiHelper.ReplaceTextNewLine(description)
end

function XSkyGardenDroneGameControl:GetDroneName(droneId)
    return self._Model:GetSgDroneGameDroneDisplayNameById(droneId)
end

function XSkyGardenDroneGameControl:GetStageTargetIds(stageId)
    return self._Model:GetSgDroneGameStageStarTargetsById(stageId)
end

function XSkyGardenDroneGameControl:GetStageTargetRewardIds(stageId)
    return self._Model:GetSgDroneGameStageStarRewardIdsById(stageId)
end

function XSkyGardenDroneGameControl:GetTargetType(targetId)
    return self._Model:GetSgDroneGameStarTargetTypeById(targetId)
end

function XSkyGardenDroneGameControl:GetTargetParams(targetId)
    return self._Model:GetSgDroneGameStarTargetParamsById(targetId)
end

function XSkyGardenDroneGameControl:GetTargetDescription(targetId)
    return self._Model:GetSgDroneGameStarTargetDescById(targetId)
end

function XSkyGardenDroneGameControl:GetTargetProgressDescription(targetId)
    return self._Model:GetSgDroneGameStarTargetProgressDescById(targetId)
end

function XSkyGardenDroneGameControl:GetStageObjectUrl()
    local values = self._Model:GetSgDroneGameConfigValuesByKey("StageObjectBaseUrl")

    if XTool.IsTableEmpty(values) then
        return ""
    end

    return values[1]
end

function XSkyGardenDroneGameControl:GetShopId()
    local values = self._Model:GetSgDroneGameConfigValuesByKey("ShopId")

    if XTool.IsTableEmpty(values) then
        return 0
    end

    return tonumber(values[1])
end

function XSkyGardenDroneGameControl:GetShopItemIds()
    local values = self._Model:GetSgDroneGameConfigValuesByKey("ShopItemIds")
    local result = {}

    if not XTool.IsTableEmpty(values) then
        for _, itemId in pairs(values) do
            table.insert(result, tonumber(itemId))
        end
    end

    return result
end

function XSkyGardenDroneGameControl:GetShopRewardGoodId()
    local values = self._Model:GetSgDroneGameConfigValuesByKey("ShowRewardGoodId")

    if XTool.IsTableEmpty(values) then
        return 0
    end

    return tonumber(values[1])
end

function XSkyGardenDroneGameControl:GetCameraFollowConfig()
    local values = self._Model:GetSgDroneGameConfigValuesByKey("CameraFollowConfig")
    local config = {
        Width = 0,
        Height = 0,
        OffsetX = 0,
        OffsetY = 0,
        IsUseSmoothFollow = false,
        SmoothFollowSpeed = 0,
    }

    if not XTool.IsTableEmpty(values) and #values >= 6 then
        config.Width = tonumber(values[1]) or 0
        config.Height = tonumber(values[2]) or 0
        config.OffsetX = tonumber(values[3]) or 0
        config.OffsetY = tonumber(values[4]) or 0
        config.IsUseSmoothFollow = tonumber(values[5]) == 1 and true or false
        config.SmoothFollowSpeed = tonumber(values[6]) or 0
    end

    return config
end

function XSkyGardenDroneGameControl:GetCurrentStagaTips(stageId)
    local values = self._Model:GetSgDroneGameConfigValuesByKey("CurrentStageTips")

    if XTool.IsTableEmpty(values) then
        return ""
    end

    return string.format(values[1], self._Model:GetSgDroneGameStageNameById(stageId))
end

function XSkyGardenDroneGameControl:GetGiveUpFightText()
    local values = self._Model:GetSgDroneGameConfigValuesByKey("GiveUpFightText")

    if XTool.IsTableEmpty(values) then
        return ""
    end

    return values[1]
end

function XSkyGardenDroneGameControl:GetHiddenUTurnStages()
    local values = self._Model:GetSgDroneGameConfigValuesByKey("HiddenUTurnStage")
    local result = {}

    if XTool.IsTableEmpty(values) then
        return result
    end

    for _, stageId in pairs(values) do
        result[tonumber(stageId)] = true
    end

    return result
end

function XSkyGardenDroneGameControl:GetChapterLockTip(index)
    local values = self._Model:GetSgDroneGameConfigValuesByKey("ChapterLockTips")

    if XTool.IsTableEmpty(values) then
        return ""
    end

    return values[index] or ""
end

---@return XTableSgDroneGameDialogue[]
function XSkyGardenDroneGameControl:GetDialoguesByType(type)
    if not self._Dialogues then
        local configs = self._Model:GetSgDroneGameDialogueConfigs()

        self._Dialogues = {}
        for _, config in pairs(configs) do
            if self._Dialogues[config.Type] == nil then
                self._Dialogues[config.Type] = {}
            end

            table.insert(self._Dialogues[config.Type], config)
        end
    end

    return self._Dialogues[type]
end

function XSkyGardenDroneGameControl:GetTriggeredDialogues()
    local dialogues = self:GetDialoguesByType(XMVCA.XSkyGardenDroneGame.DialogueType.Trigger)
    local result = {}

    if not XTool.IsTableEmpty(dialogues) then
        for _, dialogue in pairs(dialogues) do
            if not string.IsNilOrEmpty(dialogue.TriggerTag) then
                if result[dialogue.TriggerTag] == nil then
                    result[dialogue.TriggerTag] = {}
                end

                table.insert(result[dialogue.TriggerTag], dialogue)
            end
        end
    end

    return result
end

function XSkyGardenDroneGameControl:GetTimerDialogues()
    local dialogues = self:GetDialoguesByType(XMVCA.XSkyGardenDroneGame.DialogueType.Timer)
    local result = {}

    if not XTool.IsTableEmpty(dialogues) then
        for _, dialogue in pairs(dialogues) do
            table.insert(result, dialogue)
        end
    end

    return result
end

function XSkyGardenDroneGameControl:GetRandomDialogues()
    local dialogues = self:GetDialoguesByType(XMVCA.XSkyGardenDroneGame.DialogueType.Random)
    local result = {}

    if not XTool.IsTableEmpty(dialogues) then
        for _, dialogue in pairs(dialogues) do
            table.insert(result, dialogue)
        end
    end

    return result
end

function XSkyGardenDroneGameControl:GetStageRewardsByTargets(stageId, targetMap)
    local rewardIds = self:GetStageTargetRewardIds(stageId)
    local targetIds = self:GetStageTargetIds(stageId)
    local rewards = {}

    for index, targetId in pairs(targetIds) do
        if targetMap[targetId] then
            local rewardId = rewardIds[index]

            if XTool.IsNumberValid(rewardId) then
                local rewardDatas = XMVCA.XBigWorldService:GetRewardDataList(rewardId)

                if not XTool.IsTableEmpty(rewardDatas) then
                    for _, rewardData in pairs(rewardDatas) do
                        table.insert(rewards, rewardData)
                    end
                end
            end
        end
    end

    return rewards
end

function XSkyGardenDroneGameControl:GetStorageStageData()
    return self._Model:GetStorageStageData()
end

function XSkyGardenDroneGameControl:CheckHaveArchive()
    local curStageData = self:GetStorageStageData()

    return curStageData and curStageData.SaveData
end

function XSkyGardenDroneGameControl:OpenShopUi()
    local shopId = self:GetShopId()

    if not XTool.IsNumberValid(shopId) then
        return
    end

    XMVCA.XBigWorldService:RequestShopInfo(shopId, function()
        XMVCA.XBigWorldUI:Open("UiSkyGardenSGDroneShop", shopId)
    end)
end

function XSkyGardenDroneGameControl:TryRestoreStageUI(stageEntity)
    if not stageEntity then
        return
    end

    local chapterEntity = stageEntity:GetChapterEntity()

    if not chapterEntity then
        return
    end

    if not XMVCA.XBigWorldUI:IsUiLoad("UiSkyGardenSGDroneChapter") then
        XMVCA.XBigWorldUI:Open("UiSkyGardenSGDroneChapter")
    end
    if not XMVCA.XBigWorldUI:IsUiLoad("UiSkyGardenSGDroneStage") then
        XMVCA.XBigWorldUI:Open("UiSkyGardenSGDroneStage", chapterEntity)
    else
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_SKY_GARDEN_DRONE_GAME_STAGE_UI_REFRESH,
            chapterEntity)
    end
    if not XMVCA.XBigWorldUI:IsUiLoad("UiSkyGardenSGDroneStageDetail") then
        XMVCA.XBigWorldUI:Open("UiSkyGardenSGDroneStageDetail", stageEntity)
    else
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId
                                        .EVENT_SKY_GARDEN_DRONE_GAME_STAGE_DETAIL_UI_REFRESH, stageEntity)
    end
end

function XSkyGardenDroneGameControl:RecordStage(stageId, recordData, collectCount, settleType)
    if not recordData then
        return
    end

    if not XTool.IsNumberValid(stageId) then
        return
    end

    local stageType = self._Model:GetSgDroneGameStageTypeById(stageId)

    local record = {
        ["i_stage_id"] = stageId, -- 关卡Id
        ["i_stage_type"] = stageType, -- 关卡类型 1普通 3困难
        ["i_node_id"] = recordData.Seed or 0, -- 种子Id
        ["i_collect_count"] = collectCount or 0, -- 收集数量
        ["i_demage_count"] = recordData.DamageCount or 0, -- 无人机损毁次数
        ["i_injure_count"] = recordData.InjuryCount or 0, -- 无人机受伤次数
        ["i_restore_count"] = recordData.RestorationCount or 0, -- 重新开始或从存档点开始次数
        ["i_settle_type"] = settleType or self.SettleType.Lose, -- 结算类型 1成功 2失败 3暂离
    }

    CS.XRecord.Record(record, "1100101", "SkyGardenDroneGame")
end

function XSkyGardenDroneGameControl:RegisterPCEvent()
    CS.XInputManager.RegisterOnPress(CS.XInputManager.XOperationType.System, self._PcPressHandle)
end

function XSkyGardenDroneGameControl:UnregisterPCEvent()
    CS.XInputManager.UnregisterOnPress(CS.XInputManager.XOperationType.System, self._PcPressHandle)
end

function XSkyGardenDroneGameControl:OnPressPCKeyHandle(inputDeviceType, key, operationType)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_SKY_GARDEN_DRONE_KEY_PRESS_NOTIFY,
        inputDeviceType, key, operationType)
end

--- region X3C

function XSkyGardenDroneGameControl:SendLeaveGameCmd()
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_UAV_LEAVE_GAMEPLAY)
end

function XSkyGardenDroneGameControl:SendEnterGameCmd()
    local info = {
        ChapterList = {},
    }
    local chapterEntities = self:GetChapterEntities()

    if not XTool.IsTableEmpty(chapterEntities) then
        for _, chapterEntity in pairs(chapterEntities) do
            local stageEntities = chapterEntity:GetStageList()

            if not XTool.IsTableEmpty(stageEntities) then
                local chapterInfo = {}

                for _, stageEntity in pairs(stageEntities) do
                    if stageEntity:GetType() == XMVCA.XSkyGardenDroneGame.StageType.Normal then
                        local stageInfo = {
                            StageId = stageEntity:GetStageId(),
                            IsStageClear = stageEntity:IsComplete(),
                            StageType = stageEntity:GetType(),
                            PreStageId = stageEntity:GetPreStageId(),
                            IsFirstStage = stageEntity:IsFirst(),
                        }

                        table.insert(chapterInfo, stageInfo)
                    end
                end

                table.insert(info.ChapterList, {
                    ChapterId = chapterEntity:GetChapterId(),
                    StageList = chapterInfo,
                })
            end
        end
    end

    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_UAV_PUSH_ENTRANCE_DATA, {
        Data = info,
    })
end

function XSkyGardenDroneGameControl:SendRequestStagePositionCmd(stageId)
    local data = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_UAV_TRY_GET_STAGE_ENTRANCE_POSITON, {
        StageId = stageId,
    })

    if not data or not data.IsSuccess then
        return nil
    end

    return data.Position
end

function XSkyGardenDroneGameControl:SendSwitchMainViewCmd()
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_UAV_SWITCH_TO_MAIN_VIEW)
end

function XSkyGardenDroneGameControl:SendSwitchChapterSelectViewCmd()
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_UAV_SWITCH_TO_CHAPTER_SELECT_VIEW)
end

function XSkyGardenDroneGameControl:SendSwitchChapterViewCmd(chapterId)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_UAV_SWITCH_TO_CHAPTER_VIEW, {
        ChapterId = chapterId,
    })
end

function XSkyGardenDroneGameControl:SendUpdateStageClearStatusCmd(stageId, isClear)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_UAV_UPDATE_STAGE_CLEAR_STATE, {
        StageId = stageId,
        IsClear = isClear,
    })
end

--- endregion

--- region 协议

function XSkyGardenDroneGameControl:RequestStageSuspend(stageId, stageData)
    local collectStageObjects = XTool.CsHashSet2LuaTable(stageData.CollectObjects)
    local targetProgress = XTool.CsMap2LuaTable(stageData.TargetProgress)
    local triggeredBehaviorIds = XTool.CsHashSet2LuaTable(stageData.TriggeredBehavior)

    local objectDataMap = {}

    XTool.LoopMap(stageData.ObjectDatas, function(objectId, objectData)
        objectDataMap[objectId] = {
            Durability = objectData.Durability,
            ActivateTime = objectData.ActiveTime,
            IsTriggered = objectData.IsTriggered,
            GenerateExecutionsCount = objectData.GenerateExecutionsCount,
        }
    end)

    XMessagePack.MarkAsTable(targetProgress)
    XMessagePack.MarkAsTable(objectDataMap)

    local curStageData = {
        StageId = stageId,
        StageSuspendSaveData = {
            DroneId = CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.Instance.DroneManager.DroneId,
            RelayObjectId = stageData.RelayObjectId,
            RunningTime = stageData.RunningTime,
            Score = stageData.Score,
            StageObjectDataDict = objectDataMap,
            CollectStageObjects = collectStageObjects,
            TriggeredBehaviorIds = triggeredBehaviorIds,
            TargetProgress = targetProgress,
        },
    }

    XNetwork.Call("SgDroneGameStageSuspendRequest", curStageData, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.ReleaseGame()
            return
        end

        self._Model:UpdateStorageStageSaveData(curStageData)
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_SKY_GARDEN_DRONE_GAME_SUSPEND)
    end)
end

function XSkyGardenDroneGameControl:RequestStageStart(stageId, isHardMode, callback)
    XNetwork.Call("SgDroneGameStageStartRequest", {
        StageId = stageId,
        IsHardMode = isHardMode,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if callback then
            callback(res.CurStageData)
        end

        self._Model:UpdateStorageStageData(res.CurStageData)
    end)
end

function XSkyGardenDroneGameControl:RequestStageGiveUp(callback)
    XNetwork.Call("SgDroneGameStageGiveUpRequest", {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:ClearStorageStageData()

        if callback then
            callback()
        end
    end)
end

function XSkyGardenDroneGameControl:RequestStageSettle(stageId, stageData, callback)
    local targetProgress = XTool.CsMap2LuaTable(stageData.TargetProgress)

    XMessagePack.MarkAsTable(targetProgress)
    XNetwork.Call("SgDroneGameStageSettleRequest", {
        StageId = stageId,
        CostTime = math.floor(stageData.RunningTime),
        Score = stageData.Score,
        TargetProgress = targetProgress,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if callback then
            callback(res.StageInfo)
        end

        self._Model:ClearStorageStageData()
        self._Model:UpdateStageData(res.StageInfo)
        self:_NotifyStageClear()
    end)
end

--- endregion

--- region Private

function XSkyGardenDroneGameControl:_NotifyStageClear()
    local chapterEntities = self:GetChapterEntities()

    if not XTool.IsTableEmpty(chapterEntities) then
        for _, chapterEntity in pairs(chapterEntities) do
            local stageEntities = chapterEntity:GetStageList()

            if not XTool.IsTableEmpty(stageEntities) then
                for _, stageEntity in pairs(stageEntities) do
                    if stageEntity:GetType() == XMVCA.XSkyGardenDroneGame.StageType.Normal then
                        self:SendUpdateStageClearStatusCmd(stageEntity:GetStageId(), stageEntity:IsComplete())
                    end
                end
            end
        end
    end
end

--- endregion

return XSkyGardenDroneGameControl
