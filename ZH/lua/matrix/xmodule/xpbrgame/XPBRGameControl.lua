---@class XPBRGameControl : XControl
---@field private _Model XPBRGameModel
local XPBRGameControl = XClass(XControl, "XPBRGameControl")

function XPBRGameControl:OnInit()
    ---@type XPBRCharacterControl
    self.CharacterControl = self:AddSubControl(require('XModule/XPBRGame/SubModules/Character/XPBRCharacterControl'))
    ---@type XPBRInGameControl
    self.InGameControl = self:AddSubControl(require('XModule/XPBRGame/SubModules/InGame/XPBRInGameControl'))
    
    ---@type XPBRCollectionControl
    self.CollectionControl = self:AddSubControl(require('XModule/XPBRGame/SubModules/Collections/XPBRCollectionControl'))
    ---@type XPBRGeniusControl
    self.GeniusControl = self:AddSubControl(require('XModule/XPBRGame/SubModules/Genius/XPBRGeniusControl'))
    
    ---@type XPBRTaskControl
    self.TaskControl = self:AddSubControl(require('XModule/XPBRGame/SubModules/Task/XPBRTaskControl'))
    
    ---@type XPBRMusicControl
    self.MusicControl = self:AddSubControl(require("XModule/XPBRGame/SubModules/Music/XPBRMusicControl"))

    ---@type XPBRCalibrateControl
    self.CalibrateControl = self:AddSubControl(require("XModule/XPBRGame/SubModules/Music/XPBRCalibrateControl"))

    self:StartActivityTimer()
end

function XPBRGameControl:AddAgencyEvent()

end

function XPBRGameControl:RemoveAgencyEvent()

end

function XPBRGameControl:OnRelease()
    self:StopActivityTimer()

    self:_StopTickOutTimer()
end

function XPBRGameControl:GetClientPBRText(key, index)
    return self._Model:GetClientPBRText(key, index)
end

function XPBRGameControl:GetClientPBRTextArray(key)
    return self._Model:GetClientPBRTextArray(key)
end

function XPBRGameControl:GetClientPBRNumber(key, index)
    return self._Model:GetClientPBRNumber(key, index)
end

function XPBRGameControl:GetClientPBRNumberArray(key)
    return self._Model:GetClientPBRNumberArray(key)
end


---@return XTablePBRStage
function XPBRGameControl:GetStageCfgById(stageId)
    return self._Model:GetTablePBRStageCfgById(stageId)
end

function XPBRGameControl:GetStageNameById(stageId)
    local stageCfg = self._Model:GetTablePBRStageCfgById(stageId)

    if stageCfg then
        return stageCfg.StageName or ''
    end
    
    return ''
end

function XPBRGameControl:GetMainUIRewardPreview()
    local rewardId = self:GetClientPBRNumber('MainShowRewardId')

    if XTool.IsNumberValidEx(rewardId) then
        local rewardList = XRewardManager.GetRewardList(rewardId)
        -- do others
        
        return rewardList
    end
end

--- 判断是否有未完成的游戏进度
function XPBRGameControl:GetIsHasLastFightProgress()
    return self._Model:GetIsHasSegmentSettleData()
end

function XPBRGameControl:GetCurActivityStageIds()
    local cfg = self._Model:GetCurActivityCfg()

    if cfg then
        return cfg.StageIds
    end
end

--- 基础的自动聚焦关卡规则
function XPBRGameControl:GetJumpStageIndexByBaseRule()
    local activityCfg = self._Model:GetCurActivityCfg()

    if not activityCfg then
        return
    end
    
    -- 所有关卡未解锁时，默认聚焦第一关
    if not XMVCA.XPBRGame:GetIsAnyStageIsPassed() then
        return 1
    end

    -- 所有已解锁关卡都通关时，默认聚焦已解锁中的最后一关
    -- 否则聚焦顺位第一个未通关的关卡
    local hasLatestUnpassedStage, stageId = self:GetLatestUnpassedStage()

    for i, v in pairs(activityCfg.StageIds) do
        if v == stageId then
            return i
        end
    end

    return 1
end

--- 获取最新最近的未通关的关卡（即最后通关关卡的下一关），如果有，返回它，否则返回最后通关的关卡
---@return boolean, number @has, stageId
function XPBRGameControl:GetLatestUnpassedStage()
    local activityCfg = self._Model:GetCurActivityCfg()
    
    local lastestPassedStageId = nil
    
    -- 按顺序找到第一个未通关的关卡id
    if activityCfg and not XTool.IsTableEmpty(activityCfg.StageIds) then
        for i, stageId in ipairs(activityCfg.StageIds) do
            if XMVCA.XPBRGame:GetIsStageUnlockById(stageId) then
                if not XMVCA.XFuben:CheckStageIsPass(stageId) then
                    return true, stageId
                else
                    lastestPassedStageId = stageId
                end
            end
        end
    end
    
    -- 如果都通关了就返回最后一个通关的
    if XTool.IsNumberValidEx(lastestPassedStageId) then
        return false, lastestPassedStageId
    end
    
    -- 否则就是全都没解锁，返回第一个关卡
    return false, activityCfg and activityCfg.StageIds[1] or 0
end

function XPBRGameControl:SetCurSelectCharId(customCharId)
    self._Model:SetCurSelectCharId(customCharId)
end

---@return number, number @玩家记录波次，关卡目标波次
function XPBRGameControl:GetStageProgressByStageId(stageId)
    local stageCfg = self._Model:GetTablePBRStageCfgById(stageId)
    local stageRecord = self._Model:GetStageRecordById(stageId)
    
    local curWave = stageRecord and stageRecord.HistoryMaxWave or 0
    local maxWave = stageCfg and stageCfg.FinishWaves or 0
    
    if stageRecord and curWave > 0 then
        -- 服务端记录的当前波次是到达的最大波次，而不是完成的最大波次
        -- 如果该关卡没有通关，则表示最大波次失败了，完成的波次为最大波次-1
        if not stageRecord.IsPassWave then
            curWave = curWave - 1
        end
    end
    
    return curWave, maxWave
end

--- 判断指定关卡是否是无尽关类型且已通关
function XPBRGameControl:CheckIsEndlessStagePassed(stageId)
    local stageCfg = self._Model:GetTablePBRStageCfgById(stageId)
    if not stageCfg or stageCfg.StageType ~= XMVCA.XPBRGame.EnumConst.StageCustomType.Challenge then
        return false
    end
    return XMVCA.XPBRGame:CheckPassedByStageId(stageId)
end

--- 根据ItemId获取PBR道具配置
---@return XTablePBRItem
function XPBRGameControl:GetPBRItemCfgById(itemId)
    return self._Model:GetTablePBRItemCfgById(itemId)
end

--- 根据ItemGroupId获取PBR道具组配置
---@return XTablePBRItemGroup
function XPBRGameControl:GetPBRItemGroupCfgById(itemGroupId)
    return self._Model:GetTablePBRItemGroupCfgById(itemGroupId)
end

function XPBRGameControl:ClearInGameData()
    self._Model:UpdateFullSegmentSettleData(nil)
end

--- 本地改关卡进度缓存
---@return number, number @玩家记录波次，关卡目标波次
function XPBRGameControl:SetStageProgressByStageId(stageId, newHistoryMaxWave)
    self._Model:SetStageProgressByStageId(stageId, newHistoryMaxWave)
end

--- 获取当前货币数量
function XPBRGameControl:GetGeniusCoinCount()
    return self._Model:GetGeniusCoinCount()
end

--- 获取当前天赋货币ItemId
function XPBRGameControl:GetGeniusCoinItemId()
    return self._Model:GetConfigPBRNumber('PbrCoin')
end

function XPBRGameControl:GetRichTextImageRequestHandler()
    if self._RichTextImageRequestHandler == nil then
        self._RichTextImageRequestHandler = function(key, image)
            if self:GetIsRelease() then
                return
            end
            
            local cfg = self._Model:GetTablePBRRichTextIconConfigByKey(key)

            if cfg and not string.IsNilOrEmpty(cfg) and image then
                image:SetImage(cfg.IconRes)
            end
        end
    end
    
    return self._RichTextImageRequestHandler
end

function XPBRGameControl:GetShowCharacterIdInMain()
    -- 先拿缓存
    local charId = self._Model:GetLastPassStageCharId()

    if not XTool.IsNumberValidEx(charId) then
        -- 再拿解锁顺位第一个
        charId = self.CharacterControl:GetFirstOneUnlockCharId()
    end
    
    return charId
end

function XPBRGameControl:GetCuteModelNameShowInMain()
    -- 先拿缓存
    local charId = self._Model:GetLastPassStageCharId()

    if not XTool.IsNumberValidEx(charId) then
        -- 再拿解锁顺位第一个
        charId = self.CharacterControl:GetFirstOneUnlockCharId()
    end

    if XTool.IsNumberValidEx(charId) then
        local cfg = self._Model:GetTablePBRCharacterCfgById(charId)

        if cfg then
            return cfg.CuteModelName
        end
    end
end

--- 判断当前关卡的下一关是否存在且解锁
function XPBRGameControl:CheckNextStageExistAndUnlockByStageId(stageId)
    -- 找当前活动配置
    local activityCfg = self._Model:GetCurActivityCfg()

    if not activityCfg or XTool.IsTableEmpty(activityCfg.StageIds) then
        return false
    end
    
    -- 找到该关卡在列表中的索引
    local index = 0

    for i, id in pairs(activityCfg.StageIds) do
        if id == stageId then
            index = i
            break
        end
    end

    if not XTool.IsNumberValidEx(index) then
        return false
    end
    
    -- 查找下一关是否存在
    local nextStageId = activityCfg.StageIds[index + 1]

    if not XTool.IsNumberValidEx(nextStageId) then
        return false
    end
    
    -- 判断下一关是否解锁
    return XMVCA.XPBRGame:GetIsStageUnlockById(nextStageId), nextStageId
end

--region 本地缓存

function XPBRGameControl:ReddoSetStageMark(stageId)
    -- 不重复写入
    if not self._Model:ReddotGetIsMarkStage(stageId) then
        self._Model:ReddoSetStageMark(stageId)
    end
end

--endregion

--region 活动时间定时器

function XPBRGameControl:StopActivityTimer()
    if self._ActivityTimerId then
        XScheduleManager.UnSchedule(self._ActivityTimerId)
        self._ActivityTimerId = nil
    end
    self._TimeTickOutCallBack = nil
end

function XPBRGameControl:StartActivityTimer()
    self:StopActivityTimer()
    
    self:UpdateActivityTimer()
    
    self._ActivityTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateActivityTimer), XScheduleManager.SECOND)
end

function XPBRGameControl:GetIsActivityTimerStart()
    return XTool.IsNumberValidEx(self._ActivityTimerId)
end

function XPBRGameControl:UpdateActivityTimer()
    local activityId = self._Model:GetActivityId()
    local activityCfg = nil
    
    if not XTool.IsNumberValidEx(activityId) then
        goto TICK_OUT
    end
    
    activityCfg = self._Model:GetTablePBRActivityCfgById(activityId)

    if not activityCfg then
        goto TICK_OUT
    end

    if XTool.IsNumberValidEx(activityCfg.TimeId) then
        self:DispatchEvent(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_ACTIVITY_TIMER_UPDATE, activityCfg.TimeId)
    end
    
    if not XFunctionManager.CheckInTimeByTimeId(activityCfg.TimeId) then
        goto TICK_OUT
    else
        return
    end
    
    :: TICK_OUT::

    if self:TryDoTimeTickOut() then
        self:StopActivityTimer()
    end
end

function XPBRGameControl:TryDoTimeTickOut()
    if self._IsLockTimeTickOut then
        return false
    end

    if self._TimeTickOutCallBack then
        self._TimeTickOutCallBack()
    else
        self:_StopTickOutTimer()

        if XMVCA.XPBRGame:DoSafeFightExit() then
            self.InGameControl:SetFightExitType(XMVCA.XPBRGame.EnumConst.FightExitType.GiveUp)
            XLuaUiManager.SetMask(true)
            self._TickOutTimerId = XScheduleManager.ScheduleNextFrame(function()
                XLuaUiManager.RunMain()
                XLuaUiManager.SetMask(false)
                self._TickOutTimerId = nil
            end)
        else
            XLuaUiManager.RunMain()
        end
        
        XUiManager.TipText('ActivityMainLineEnd')
    end
    
    return true
end

function XPBRGameControl:LockPBRActivityTimerTickOut()
    self._IsLockTimeTickOut = true
end

function XPBRGameControl:UnLockPBRActivityTimerTickOut()
    self._IsLockTimeTickOut = false
end

function XPBRGameControl:SetTimeTickOutCallBack(cb)
    self._TimeTickOutCallBack = cb
end

function XPBRGameControl:AddTimeEventListener(func, obj)
    self:AddEventListener(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_ACTIVITY_TIMER_UPDATE, func, obj)
    
    -- 注册监听后立刻刷新一次
    if self:GetIsActivityTimerStart() then
        self:UpdateActivityTimer()
    end
end

function XPBRGameControl:RemoveTimeEventListener(func, obj)
    self:RemoveEventListener(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_ACTIVITY_TIMER_UPDATE, func, obj)
end

function XPBRGameControl:_StopTickOutTimer()
    if self._TickOutTimerId then
        XScheduleManager.UnSchedule(self._TickOutTimerId)
        XLuaUiManager.SetMask(false)
        
        self._TickOutTimerId = nil
    end
end
--endregion

--region SkinPopup（涂装打脸弹窗）

function XPBRGameControl:GetSkinTaskId()
    return self:GetClientPBRNumber("PBRSkinTaskId")
end

--- 任务条件已达成（可领取）
function XPBRGameControl:IsSkinTaskAchieved()
    local taskId = self:GetSkinTaskId()
    if not XTool.IsNumberValidEx(taskId) then
        return false
    end
    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    return taskData and taskData.State == XDataCenter.TaskManager.TaskState.Achieved
end

--- 涂装奖励已领取
function XPBRGameControl:IsSkinRewardClaimed()
    local taskId = self:GetSkinTaskId()
    if not XTool.IsNumberValidEx(taskId) then
        return true
    end
    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    return taskData and taskData.State == XDataCenter.TaskManager.TaskState.Finish
end

--- 双闸门判定：是否应自动弹出涂装弹窗
function XPBRGameControl:CheckShowSkinPopup()
    if self:IsSkinRewardClaimed() then
        return false
    end
    if XLuaUiManager.IsUiShow("UiPBRPopupSkin") then
        return false
    end
    local guideId = self:GetClientPBRNumber("PBRPopupSkinCheckGuide")
    if XTool.IsNumberValidEx(guideId) then
        return XDataCenter.GuideManager.CheckIsGuide(guideId)
    end
    return true
end

--- 领取涂装奖励
function XPBRGameControl:RequestClaimSkinReward(cb)
    local taskId = self:GetSkinTaskId()
    if not XTool.IsNumberValidEx(taskId) then
        return
    end
    XDataCenter.TaskManager.FinishTask(taskId, function(rewardGoodsList)
        if rewardGoodsList then
            XUiManager.OpenUiObtain(rewardGoodsList)
        end
        if cb then
            cb()
        end
    end)
end

--endregion

--region ClientConfig

---@return string, string, string @正文，左按钮文本，右按钮文本
function XPBRGameControl:GetClientBattleShopBackTips()
    local content = self._Model:GetClientPBRText("BattleShopBackTips", 1)
    local btnLeftTxt = self._Model:GetClientPBRText("BattleShopBackTips", 2)
    local btnRightTxt = self._Model:GetClientPBRText("BattleShopBackTips", 3)

    return content, btnLeftTxt, btnRightTxt
end

--endregion

return XPBRGameControl