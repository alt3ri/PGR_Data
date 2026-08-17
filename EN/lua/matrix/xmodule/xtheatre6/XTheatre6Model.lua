---@class XTheatre6Model : XModel
---@field Skill XTheatre6SubSkillModel
---@field StageChain XTheatre6SubStageChain
---@field BattleShop XTheatre6SubBattleShopModel
---@field Pvp XTheatre6SubPvpModel
local XTheatre6Model = XClass(XModel, "XTheatre6Model", true)

local StageStatus = XEnumConst.Theatre6.StageStatus
local PlayMode = XEnumConst.Theatre6.PlayMode

--region 部分类初始化
XClassPartialRequire("XModule/XTheatre6/ModelPartial/XTheatre6ModelConfig", "XTheatre6Model")
XClassPartialRequire("XModule/XTheatre6/ModelPartial/XTheatre6ModelPvpConfig", "XTheatre6Model")
XClassPartialRequire("XModule/XTheatre6/ModelPartial/XTheatre6ModelSave", "XTheatre6Model")
--endregion

function XTheatre6Model:OnInit()
    self:OnInitConfig()
    self:OnInitPvpConfig()
    self:OnInitSave()

    self._ActivityId = nil --当前活动ID
    self._CurrentMode = nil --当前游玩模式
    self._ModeDataDict = {} --正在进行中的模式数据（可同时进行多个）
    self._ModeSaveDict = {} --全局数据
    self._CurRoomData = nil --当前房间数据
    self._StoryLineDatas = nil --故事线数据
    self._FileDatas = nil --存档数据
    self._PassStageRecords = nil --通关记录 k=关卡Id v=通关次数
    self._PassDiffRecords = nil --通关难度记录 k=难度Id v=通关次数

    self.Skill = self:AddSubModel(require("XModule/XTheatre6/SubModel/XTheatre6SubSkillModel"))
    self.StageChain = self:AddSubModel(require("XModule/XTheatre6/SubModel/XTheatre6SubStageChain"))
    self.BattleShop = self:AddSubModel(require("XModule/XTheatre6/SubModel/XTheatre6SubBattleShopModel"))
    self.Pvp = self:AddSubModel(require("XModule/XTheatre6/SubModel/XTheatre6SubPvpModel"))
end

function XTheatre6Model:ClearPrivate()
    self:ConfigClearPrivate()
    self:PvpConfigClearPrivate()
    self._ConsumeId = nil
    self._SanDeathBuffDict = nil
end

function XTheatre6Model:ResetAll()
    self:ConfigResetAll()
    self:PvpConfigResetAll()
end

----------public start----------

function XTheatre6Model:GetConsumeId()
    if not self._ConsumeId then
        self._ConsumeId = self:GetIntConfigValue("TalentCoin")
    end
    return self._ConsumeId
end

function XTheatre6Model:GetStoryLineStageStatus(characterId, stageIndex)
    local storyLineId = self:GetStoryLineId(characterId)
    local stageId = self:GetStoryLineConfig(storyLineId).StageIds[stageIndex]

    if self:IsStageNeedPurchase(storyLineId, stageIndex) and not self:IsStoryLineStageHasBuy(storyLineId, stageIndex) then
        return StageStatus.Purchased
    end
    
    if self:IsStagePass(storyLineId, stageIndex) then
        return StageStatus.Passed
    end
    
    return StageStatus.Normal
end

function XTheatre6Model:GetSanValue()
    local modelData = self:GetCurPlayModeData()
    return modelData.San
end

function XTheatre6Model:GetMinSanValue()
    local modelData = self:GetCurPlayModeData()
    return modelData.MinSan
end

function XTheatre6Model:GetMaxSanValue()
    local modelData = self:GetCurPlayModeData()
    return modelData.MaxSan
end

function XTheatre6Model:GetSanIds()
    local sanGroupId = self:GetSanGroupId()
    return self:GetSanIdsByGroupId(sanGroupId)
end

---@return XTableTheatre6StageSan
function XTheatre6Model:GetCurSanConfig()
    local sanGroupId = self:GetSanGroupId()
    return self:GetSanConfigBySanValue(sanGroupId, self:GetSanValue())
end

function XTheatre6Model:GetSanDeathBuffId()
    if not self._SanDeathBuffDict then
        self._SanDeathBuffDict = {}
    end

    local sanGroupId = self:GetSanGroupId()
    local buffId = self._SanDeathBuffDict[sanGroupId]

    if not buffId then
        buffId = self:GetSanDeathBuffIdByGroupId(sanGroupId)
        self._SanDeathBuffDict[sanGroupId] = buffId
    end
    return buffId
end

function XTheatre6Model:GetCurPlayMode()
    return self._CurrentMode
end

---@return XTheatre6StoryModeSaveDbProtocol
function XTheatre6Model:GetStorySaveData()
    return self._ModeSaveDict[PlayMode.Story]
end

---@return XTheatre6PlayModeSaveDbProtocol
function XTheatre6Model:GetPlayModeSaveData()
    return self._ModeSaveDict[PlayMode.GamePlay]
end

---@return XTheatre6ModeBaseProtocol
function XTheatre6Model:GetCurPlayModeData()
    return self._ModeDataDict[self._CurrentMode]
end

---@return XTheatre6ModeBaseProtocol
function XTheatre6Model:GetPlayModeData(playMode)
    return self._ModeDataDict[playMode]
end

function XTheatre6Model:ClearPlayModeData(playMode)
    self._ModeDataDict[playMode] = nil
    self.BattleShop:ClearPlayModeData(playMode)
    self.Skill:ClearSkillData(playMode)
    self:SetShowDeathBuff(nil, playMode)
end

---@return XTheatre6StageRoomProtocol
function XTheatre6Model:GetCurRoomData()
    return self._CurRoomData
end

---清除当前房间的战斗相关数据（主要用于二择战斗）
function XTheatre6Model:ClearRoomFightInfo()
    if not self._CurRoomData then
        return
    end
    self._CurRoomData.FightId = nil
    self._CurRoomData.SelectedMonsterId = nil
    self._CurRoomData.FightRewards = nil
end

---@return XTheatre6BuffProtocol
function XTheatre6Model:GetBuffDataByUid(uid)
    local modelData = self:GetCurPlayModeData()
    if modelData then
        return modelData.Buffs[uid] or modelData.DestroyedBuffs[uid]
    end
    return nil
end

---Buff是否已被销毁
function XTheatre6Model:IsBuffDestory(buffUid)
    local modelData = self:GetCurPlayModeData()
    return modelData.DestroyedBuffs[buffUid] ~= nil
end

---计算BOSS战力
function XTheatre6Model:GetMonsterScore(monsterId)
    --使用策划配置的战力
    local monsterConfig = self:GetMonsterCfgById(monsterId)
    if XTool.IsNumberValid(monsterConfig.Score) then
        return monsterConfig.Score
    end
    --没有配置时需要客户端计算
    local score = 0
    --属性
    for attrId, attrValue in pairs(monsterConfig.AttrTypes) do
        local attrConfig = self:GetAttrConfig(attrId)
        score = score + attrValue * attrConfig.SaveScore
    end
    --技能
    for i, id in ipairs(monsterConfig.SkillIds) do
        local skillConfig = self:GetSkillCfgById(id)
        score = score + skillConfig.SaveScore
    end
    --遗物
    for i, id in ipairs(monsterConfig.AttrPacks) do
        local attrPackConfig = self:GetAttrPackConfig(id)
        score = score + monsterConfig.AttrPackNums[i] * attrPackConfig.SaveScore
    end
    return math.ceil(score) --向上取整
end

function XTheatre6Model:GetFileDataBySlot(roleId, slotIndex)
    if not XTool.IsTableEmpty(self._FileDatas) then
        for _, fileData in ipairs(self._FileDatas) do
            if fileData.CharacterId == roleId and fileData.SlotId == slotIndex then
                return fileData
            end
        end
    end
    return nil
end

function XTheatre6Model:UpdateFileDatas(fileDatas)
    self._FileDatas = fileDatas
end

---@param fileData Theatre6FileDataProtocol
function XTheatre6Model:UpdateFileDataToSlot(fileData)
    if not self._FileDatas then
        self._FileDatas = {}
    end
    for i, data in ipairs(self._FileDatas) do
        if data.SlotId == fileData.SlotId and data.CharacterId == fileData.CharacterId then
            self._FileDatas[i] = fileData
            return
        end
    end
    table.insert(self._FileDatas, fileData)
end

function XTheatre6Model:GetWorldId()
    return self:GetActivityConfig(self._ActivityId).WorldId
end

function XTheatre6Model:GetBuffCueId()
    local cueId = nil
    local priority = nil
    local modelData = self:GetCurPlayModeData()
    if modelData then
        for _, data in pairs(modelData.Bgms) do
            if not priority or priority < data.Priority then
                cueId = data.CueId
                priority = data.Priority
            end
        end
    end
    return cueId
end

function XTheatre6Model:SetCurBuffCueId(id)
    self._CurBuffCueId = id
end

function XTheatre6Model:GetCurBuffCueId()
    return self._CurBuffCueId
end

---@return table<number,number> key=buff uid value=特效Id
function XTheatre6Model:GetMessyCodes()
    local modelData = self:GetCurPlayModeData()
    return modelData.MessyCodes
end

function XTheatre6Model:SetCurSanCueId(id)
    if not self._CurSanCueDict then
        self._CurSanCueDict = {}
    end
    self._CurSanCueDict[self._CurrentMode] = id
end

function XTheatre6Model:GetCurSanCueId()
    if self._CurSanCueDict then
        return self._CurSanCueDict[self._CurrentMode]
    end
    return nil
end

---条件：通关活动x关卡y次
function XTheatre6Model:IsStagePassTimes(stageId, times)
    if self._PassStageRecords and self._PassStageRecords[stageId] then
        return self._PassStageRecords[stageId] >= times
    end
    return false
end

---条件：通关活动x难度y次
function XTheatre6Model:IsDiffPassTimaes(diffId, times)
    if self._PassDiffRecords and self._PassDiffRecords[diffId] then
        return self._PassDiffRecords[diffId] >= times
    end
    return false
end

function XTheatre6Model:GetTaskFreeRefreshTimes(taskGroupId)
    local times = self:GetStageTaskGroupConfig(taskGroupId).FreeRefresh --默认免刷次数
    ---@type table<number,XTheatre6BuffProtocol>
    local buffs = self:GetCurPlayModeData().Buffs
    for _, buff in pairs(buffs) do
        times = times + buff.TaskFreeRefreshCount
    end
    return times
end

function XTheatre6Model:SetShowDeathBuff(buffData, mode)
    if not self._ShowDeathBuff then
        self._ShowDeathBuff = {}
    end
    mode = mode or self._CurrentMode
    self._ShowDeathBuff[mode] = buffData
end

function XTheatre6Model:GetShowDeathBuffWithClear()
    local buffData = self._ShowDeathBuff and self._ShowDeathBuff[self._CurrentMode]
    if buffData then
        self._ShowDeathBuff[self._CurrentMode] = nil
    end
    return buffData
end

----------public end----------

----------private start----------

---关卡是否通关
function XTheatre6Model:IsStagePass(storyLineId, stageIndex)
    if self._StoryLineDatas then
        for _, data in ipairs(self._StoryLineDatas) do
            if data.StoryLineId == storyLineId then
                return data.StageIndex > stageIndex - 1
            end
        end
    end
    return false
end

---剧情关是否已购买
function XTheatre6Model:IsStoryLineStageHasBuy(storyLineId, stageIndex)
    if self._StoryLineDatas then
        for _, data in ipairs(self._StoryLineDatas) do
            if data.StoryLineId == storyLineId then
                return table.contains(data.BuyIndex, stageIndex - 1)
            end
        end
    end
    return false
end

---关卡是否需要购买
function XTheatre6Model:IsStageNeedPurchase(storyLineId, stageIndex)
    local config = self:GetStoryLineConfig(storyLineId)
    return XTool.IsNumberValid(config.ConsumeCounts[stageIndex])
end

function XTheatre6Model:UpdateStoryLineData(newData)
    if not self._StoryLineDatas then
        self._StoryLineDatas = {}
    end

    for i, data in ipairs(self._StoryLineDatas) do
        if data.StoryLineId == newData.StoryLineId then
            self._StoryLineDatas[i] = newData
            return
        end
    end

    table.insert(self._StoryLineDatas, newData)
end

function XTheatre6Model:GetSanGroupId()
    local modelData = self:GetCurPlayModeData()
    return self:GetStageConfig(modelData.StageId).SanGroupId
end

function XTheatre6Model:IsStoryAvgAlreadyPlayed(avgId)
    local saveData = self:GetStorySaveData(XEnumConst.Theatre6.PlayMode.Story)
    return table.contains(saveData.StoryIds, avgId)
end

----------private end----------

---登陆下发活动数据
function XTheatre6Model:NotifyTheatre6ActivityData(data)
    self._ActivityId = data.ActivityId
    self._CurrentMode = data.CurrentMode
    ---@type XTheatre6ModeBaseProtocol[]
    self._ModeDataDict[PlayMode.Story] = data.StoryModeDataDb
    self._ModeDataDict[PlayMode.GamePlay] = data.PlayModeDataDb
    ---@type Theatre6FileDataProtocol[]
    self._FileDatas = data.FileDatas
    self._StoryLineDatas = data.StoryLineDatas
    ---@type XTheatre6StoryModeSaveDbProtocol[]
    self._ModeSaveDict[PlayMode.Story] = data.StoryModeSaveDb
    self._ModeSaveDict[PlayMode.GamePlay] = data.PlayModeSaveDb
    if self.Skill then
        self.Skill:OnNotifySkillData(data.StoryModeDataDb or nil)
        self.Skill:OnNotifySkillData(data.PlayModeDataDb or nil)
    end
    if self.BattleShop then
        self.BattleShop:NotifyTheatre6ActivityData(
            data.StoryModeDataDb and data.StoryModeDataDb.CurrentRoomDataDb or nil, PlayMode.Story)
        self.BattleShop:NotifyTheatre6ActivityData(
            data.PlayModeDataDb and data.PlayModeDataDb.CurrentRoomDataDb or nil, PlayMode.GamePlay)
    end
    self._PassStageRecords = data.PassStageRecords
    self._PassDiffRecords = data.PassDiffRecords
  
end

---下发下一层的数据
function XTheatre6Model:UpdateNewFloorData(modeDataDb)
    self._ModeDataDict[self._CurrentMode] = modeDataDb
    self._CurRoomData = modeDataDb.CurrentRoomDataDb
end

---下发新的房间数据
function XTheatre6Model:NotifyTheatre6NewRoomData(data)
    local modelData = self:GetCurPlayModeData()
    modelData.CurrentRoomDataDb = data.RoomDataDb
    modelData.StageTasks = data.StageTasks
    modelData.TaskSlotData = data.TaskSlotData
    ---@type XTheatre6StageRoomProtocol
    self._CurRoomData = data.RoomDataDb

  
    self.BattleShop:NotifyTheatre6NewRoomData(data.RoomDataDb, self._CurrentMode)
    self:UpdateTaskGroupId(data.TaskGroupId)
end

---下发san值改变
function XTheatre6Model:NotifyTheatre6SanChange(data)
    local modelData = self:GetCurPlayModeData()
    modelData.San = data.San
    modelData.MaxSan = data.MaxSan
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_SAN_CHANGE, data.SanChange)
end

---下发心数改变
function XTheatre6Model:NotifyTheatre6HealthChange(data)
    local modelData = self:GetCurPlayModeData()
    modelData.Health = data.Health
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_HEALTH_CHANGE, data.HealthChange)
end

function XTheatre6Model:NotifyTheatre6GoldChange(data)
    local modelData = self:GetCurPlayModeData()
    modelData.GoldAmount = data.GoldAmount
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_GOLD_CHANGE, data.GoldChange)
end

---下发材料改变
function XTheatre6Model:NotifyTheatre6GoodsChange(data)
    local modelData = self:GetCurPlayModeData()
    local goodsDict = modelData.Goods
    for _, v in ipairs(data.GoodsList) do
        goodsDict[v.GoodsId] = v
    end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_GOODS_CHANGE)
end

---玩家战力推送
function XTheatre6Model:Theatre6TotalScoreNotify(data)
    local modelData = self:GetCurPlayModeData()
    if modelData then
        modelData.ScoreTotal = data.TotalScoreNew
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_SCORE_CHANGE, data.TotalScoreOld, data.TotalScoreNew)
    end
    --data.TotalScoreOld
    --data.TotalScoreNew
end

---下发整局结算数据（健康值=0、流程结束）
function XTheatre6Model:NotifyTheatre6SettleData()
    self:ModelSettle(self._CurrentMode)
    if self.StageChain.ModelId == self._CurrentMode then
        self.StageChain:Clear()
    end
end

function XTheatre6Model:NotifyTheatre6AddBuff(data)
    local modelData = self:GetCurPlayModeData()
    modelData.Buffs[data.BuffData.Uid] = data.BuffData
end

function XTheatre6Model:NotifyTheatre6BuffUpdate(data)
    local modelData = self:GetCurPlayModeData()
    for _, buffData in ipairs(data.BuffDatas) do
        local uid = buffData.Uid
        if modelData.Buffs[uid] then
            modelData.Buffs[uid] = buffData
        elseif modelData.DestroyedBuffs[uid] then
            modelData.DestroyedBuffs[uid] = buffData
        end
    end
end

function XTheatre6Model:NotifyTheatre6DelBuff(data)
    local modelData = self:GetCurPlayModeData()
    local buff = modelData.Buffs[data.BuffUid]
    modelData.Buffs[data.BuffUid] = nil
    if data.DeathType == XEnumConst.Theatre6.BuffDeathType.AddToDestroyedBuffs then
        modelData.DestroyedBuffs[data.BuffUid] = buff
    end
end

---增加BGM
function XTheatre6Model:NotifyTheatre6AddBgm(data)
    local modelData = self:GetCurPlayModeData()
    for buffId, bgmData in pairs(data.Bgms) do
        modelData.Bgms[buffId] = bgmData
    end
end

---删除BGM
function XTheatre6Model:NotifyTheatre6DelBgm(data)
    local modelData = self:GetCurPlayModeData()
    for buffId, bgmData in pairs(data.Bgms) do
        modelData.Bgms[buffId] = nil
    end
end

---增加乱码特效
function XTheatre6Model:NotifyTheatre6AddMessyCode(data)
    local modelData = self:GetCurPlayModeData()
    modelData.MessyCodes = data.MessyCodes or table.empty
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_MESSY_CODE_ADD, data.CurCodeId)
end

---删除乱码特效
function XTheatre6Model:NotifyTheatre6DelMessyCode(data)
    local modelData = self:GetCurPlayModeData()
    modelData.MessyCodes = data.MessyCodes or table.empty
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_MESSY_CODE_DEL, data.CurCodeId)
end

function XTheatre6Model:NotifyTheatre6TalentLevel(data)
    local saveData = self:GetPlayModeSaveData() or {}
    saveData.TalentLevel = data.Level
    saveData.TalentExp = data.Exp
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_TALENT_LEVEL_CHANGE)
end

---技能添加推送
function XTheatre6Model:NotifyTheatre6AddSkill(data)
    local skillUpdates = data and data.SkillUpdates
    local hasUpgradeReplace = false
    -- local hasLowLevelToBag = false
    local playModeId = self:GetCurPlayMode()
    for _, skillUpdateData in ipairs(skillUpdates or {}) do
        local upgrade, toBag = self.Skill:CollectAddSkillToastFlags(skillUpdateData)
        hasUpgradeReplace = hasUpgradeReplace or upgrade
        -- hasLowLevelToBag = hasLowLevelToBag or toBag
        self.Skill:UpdateSkillsWithOverQueue(skillUpdateData, playModeId)
    end
    if hasUpgradeReplace then
        XUiManager.TipMsg(XUiHelper.GetText("Theatre6SkillReplaceHigh"))
    end
    -- if hasLowLevelToBag then
    --     XUiManager.TipMsg(XUiHelper.GetText("Theatre6SkillAutoToBag"))
    -- end
    if self.Skill:IsForceSellSkillBlock() then
        self.Skill:OpenSellSkillPanel(self.Skill:GetForceSellSkillOverQueue())
    end
end

---属性变更推送
function XTheatre6Model:NotifyTheatre6AttrChange(data)
    local modelData = self:GetCurPlayModeData()
    
    local newAttrDict = {}
    for _, attr in ipairs(data.AttrList) do
        newAttrDict[attr.AttrId] = attr
    end
    
    for attrId, attr in ipairs(modelData.Attrs) do
        local newAttr = newAttrDict[attrId]
        if newAttr then
            modelData.Attrs[attrId] = newAttr
        end
    end
end

---遗物变更推送
function XTheatre6Model:NotifyTheatre6AttrPackChange(data)
    local modelData = self:GetCurPlayModeData()
    modelData.AttrPacks[data.AttrPack.PackId] = data.AttrPack
end

function XTheatre6Model:NotifyTheatre6ModeChange(data)
    self._CurrentMode = data.ModeId
end

function XTheatre6Model:UpdatePlayModeStartFight(data)
    self._CurrentMode = PlayMode.GamePlay
    self._ModeDataDict[PlayMode.GamePlay] = data.PlayModeDataDb
    self._CurRoomData = data.PlayModeDataDb.CurrentRoomDataDb
end

function XTheatre6Model:UpdateStoryLineStartFight(data)
    self._CurrentMode = PlayMode.Story
    self._ModeDataDict[PlayMode.Story] = data.StoryModeDataDb
    self._CurRoomData = data.StoryModeDataDb.CurrentRoomDataDb
    self:UpdateStoryLineData(data.StoryLineData)
end

function XTheatre6Model:UpdateRefreshTask(oldTaskId, index, data)
    local modelData = self:GetCurPlayModeData()
    modelData.StageTasks[oldTaskId] = nil
    modelData.StageTasks[data.NewTask.TaskId] = data.NewTask

    ---@type XTheatre6StageTaskSlotDataProtocol
    local taskData = modelData.TaskSlotData[index]
    taskData.RefreshCount = data.RefreshCount
    taskData.TaskId = data.NewTask.TaskId
end

function XTheatre6Model:UpdateTaskSelect(taskIds)
    local modelData = self:GetCurPlayModeData()
    for _, taskId in ipairs(taskIds) do
        modelData.StageTasks[taskId].TaskState = XEnumConst.Theatre6.TaskState.Activated
    end
end

function XTheatre6Model:UpdateChooseEvent(nextChooseId, stageTasks, leftRewards, rightRewards)
    local roomData = self:GetCurRoomData()
    roomData.CurChoosePoolIdx = roomData.CurChoosePoolIdx + 1
    roomData.CurChooseId = nextChooseId
    roomData.LeftRewards = leftRewards
    roomData.RightRewards = rightRewards
    
    local modelData = self:GetCurPlayModeData()
    modelData.StageTasks = stageTasks
end

function XTheatre6Model:UpdateFightRoomSelect(selectMonsterId, fightId)
    local roomData = self:GetCurRoomData()
    roomData.SelectedMonsterId = selectMonsterId
    if XTool.IsNumberValid(fightId) then
        roomData.FightId = fightId
    end
end

function XTheatre6Model:ModelSettle(modeId)
    self._ModeDataDict[modeId] = nil
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_MODE_END)
    self:ClearPlayModeData(modeId)
end

function XTheatre6Model:ContinueGame(modeId)
    self._CurrentMode = modeId
    local modelData = self:GetCurPlayModeData()
    self._CurRoomData = modelData.CurrentRoomDataDb
    self.BattleShop:NotifyTheatre6NewRoomData(self._CurRoomData, modeId)
end

function XTheatre6Model:UpdateChooseRoomStatus(nextRoomStatus)
    local roomData = self:GetCurRoomData()
    roomData.ChooseRoomStatus = nextRoomStatus
end

function XTheatre6Model:UpdateTaskRoomReward(taskSlotData, newStageTasks)
    local modelData = self:GetCurPlayModeData()
    modelData.StageTasks = newStageTasks
    modelData.TaskSlotData = taskSlotData
end

function XTheatre6Model:UpdateSettleData(settleData, storyModeSaveDb)
    self._PassStageRecords = settleData.PassStageRecords
    self._PassDiffRecords = settleData.PassDiffRecords
    self._ModeSaveDict[PlayMode.Story] = storyModeSaveDb
    self._StoryLineDatas = storyModeSaveDb.StoryLineDatas
    local modelData = self:GetCurPlayModeData()
    modelData.SettleData = settleData
    modelData.IsSettle = true
end

function XTheatre6Model:UpdateEndGame(mode, storyModeSaveDb, settleData)
    self._CurrentMode = mode
    self._ModeSaveDict[PlayMode.Story] = storyModeSaveDb
    self._StoryLineDatas = storyModeSaveDb.StoryLineDatas
    self._PassStageRecords = settleData.PassStageRecords
    self._PassDiffRecords = settleData.PassDiffRecords
    local modelData = self:GetCurPlayModeData()
    modelData.SettleData = settleData
    modelData.IsSettle = true
end

function XTheatre6Model:UpdateStoryModeGuideFinished(storyId)
    local saveData = self:GetStorySaveData(XEnumConst.Theatre6.PlayMode.Story)
    table.insert(saveData.StoryIds, storyId)
end

function XTheatre6Model:UpdateTaskGroupId(id)
    local modelData = self:GetCurPlayModeData()
    modelData.TaskGroupId = id
end

function XTheatre6Model:UpdateShopBuySan(data)
    local roomData = self:GetCurRoomData()
    roomData.BuySanTimes = data.BuySanTimes
end

--region Pvp

function XTheatre6Model:GetAllFileData()
    return self._FileDatas
end

--endregion

return XTheatre6Model
