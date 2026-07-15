---Control部分类，此处用于发送协议
---@type XTheatre6Control
local XTheatre6Control = XClassPartial('XTheatre6Control')

---玩法模式开始游戏
function XTheatre6Control:RequestPlayModeStartFight(characterId, fashionId, initBuffId, difficultyId, cb)
    local req = {}
    req.CharacterId = characterId
    req.FashionId = fashionId
    req.InitBuffId = initBuffId
    req.DifficultyId = difficultyId
    XNetwork.CallWithAutoHandleErrorCode("Theatre6PlayModeStartFightRequest", req, function(res)
        self._Model:UpdatePlayModeStartFight(res)
        self:InitClientStageStatus()
        self:StartGame(XEnumConst.Theatre6.PlayMode.GamePlay, res.PlayModeDataDb.StageId, 1, 1)
        if self._Model.BattleShop then
            self._Model.BattleShop:NotifyTheatre6ActivityData(res.PlayModeDataDb and res.PlayModeDataDb.CurrentRoomDataDb or nil,
                XEnumConst.Theatre6.PlayMode.GamePlay)
        end
        if cb then
            cb()
        end
    end)
end

---进入故事线请求
---@param replayStageId number 复刷（故事线未完成,不需要上传此字段,服务器也自动忽略）
function XTheatre6Control:RequestEnterStoryLine(storyLineId, replayStageId, cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6EnterStoryLineRequest", { StoryLineId = storyLineId, ReplayStageId = replayStageId }, function(res)
        self._Model:UpdateStoryLineStartFight(res)
        self:InitClientStageStatus()
        self:StartGame(XEnumConst.Theatre6.PlayMode.Story, res.StoryModeDataDb.StageId, 1, 1)
        if self._Model.BattleShop then
            self._Model.BattleShop:NotifyTheatre6ActivityData(res.StoryModeDataDb and res.StoryModeDataDb.CurrentRoomDataDb or nil,
                XEnumConst.Theatre6.PlayMode.Story)
        end
        if cb then
            cb()
        end
    end)
end

---继续游戏
function XTheatre6Control:RequestContinueGame(modeId, cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6ContinueGameRequest", { ModeId = modeId }, function(res)
        self._Model:ContinueGame(modeId)
        local modelData = self:GetCurPlayModeData()
        local roomData = self:GetCurRoomData()
        self:StartGame(modeId, modelData.StageId, modelData.CurFloorIdx + 1, roomData.RoomIdx + 1) --服务器从0开始
        if cb then
            cb()
        end
    end)
end

---终止游戏
function XTheatre6Control:RequestEndGame(modeId, cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6EndGameRequest", { ModeId = modeId }, function(res)
        self._Model:UpdateEndGame(modeId, res.StoryModeSaveDb, res.SettleData)
        if cb then
            cb(res)
        end
    end)
end

---刷新任务
---@param index number 第几个任务，从1开始
function XTheatre6Control:RequestRefreshTask(oldTaskId, index, cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6RefreshTaskRequest", { Index = index }, function(res)
        self._Model:UpdateRefreshTask(oldTaskId, index, res)
        if cb then
            cb()
        end
    end)
end

---确认任务
---@param taskIds number[]
function XTheatre6Control:RequestConfirmTask(taskIds, cb)
    self._Model:UpdateTaskSelect(taskIds)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6ConfirmTaskRequest", { TaskIds = taskIds }, function(res)
        self._Model:UpdateChooseRoomStatus(res.NextRoomStatus)
        if cb then
            cb()
        end
    end)
end

---二择房间结束后，领取任务奖励
function XTheatre6Control:RequestRecvTaskRoomReward(cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6RecvTaskRoomRewardRequest", nil, function(res)
        self._Model:UpdateChooseRoomStatus(res.NextRoomStatus)
        self._Model:UpdateTaskRoomReward(res.TaskSlotData, res.NewStageTasks)
        self._Model:UpdateTaskGroupId(res.TaskGroupId)
        if cb then
            cb()
        end
    end)
end

---二择事件选择奖励
function XTheatre6Control:RequestChooseEvent(selectType, cb)
    --NotifyTheatre6SettleData协议会比Theatre6ChooseEventRequest的返回协议更快收到，这里需要拦截下
    XMVCA.XTheatre6:SetSettlementLock(true)
    XNetwork.Call("Theatre6ChooseEventRequest", { SelectType = selectType }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            XMVCA.XTheatre6:SetSettlementLock(false)
            if not XMVCA.XTheatre6:CheckOpenSettle() then
                cb(false, false)
            end
            return
        end
        
        local historyStatus = self:GetCurRoomData().ChooseRoomStatus
        self._Model:UpdateChooseEvent(res.NextChooseId, res.StageTasks, res.LeftRewards, res.RightRewards)
        self._Model:UpdateChooseRoomStatus(res.NextRoomStatus)
        local isEnd = res.IsEnd or historyStatus ~= res.NextRoomStatus
        local isFight = false
        for _, rewardGoods in ipairs(res.RewardGoodsList) do
            if XTool.IsNumberValid(rewardGoods.FightId) then
                self._Model:UpdateFightRoomSelect(rewardGoods.MonsterId, rewardGoods.FightId)
                isFight = true
                break
            end
        end

        local queue = {}
        --触发技能升级
        table.insert(queue, function(next)
            XMVCA.XTheatre6:ShowSkillUpEffect(res.SkillUpBuffDatas, next)
        end)
        --显示San值buff弹窗
        if not XTool.IsTableEmpty(res.SanBuffDatas) then
            for _, buffData in ipairs(res.SanBuffDatas) do
                if buffData.BuffId == self._Model:GetSanDeathBuffId() then
                    table.insert(queue, function(next)
                        XLuaUiManager.Open("UiTheatre6PopupGetBuff", { buffData }, true, next)
                    end)
                    break
                end
            end
        end
        --最后更新二择界面
        XMVCA.XTheatre6:RunChain(queue, function()
            XMVCA.XTheatre6:SetSettlementLock(false)
            if not XMVCA.XTheatre6:CheckOpenSettle() then
                cb(isEnd, isFight)
            end
        end)
    end)
end

---战斗房间左右滑动请求
function XTheatre6Control:RequestFightRoomSlide(selectType, selectMonsterId, cb)
    local roomData = self:GetCurRoomData()
    if roomData.SelectedMonsterId > 0 then
        if cb then
            cb()
        end
        return
    end
    
    XNetwork.CallWithAutoHandleErrorCode("Theatre6FightRoomSlideRequest", { SelectType = selectType }, function(res)
        self._Model:UpdateFightRoomSelect(selectMonsterId)
        if cb then
            cb()
        end
    end)
end

function XTheatre6Control:RequestEndAvgRoom(cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6EndAvgRoomRequest", nil, function(res)
        if cb then
            cb()
        end
    end)
end

---保存存档
---@param modeId number 玩法模式
---@param slotId number 存档位置编号，从1开始，存档数量在config表
function XTheatre6Control:RequestSaveFile(modeId, slotId, cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6SaveFileRequest", { ModeId = modeId, SlotId = slotId }, function(res)
        self._Model:UpdateFileDataToSlot(res.FileData)
        self._Model:ModelSettle(modeId)
        if cb then
            cb()
        end
    end)
end

---放弃存档
function XTheatre6Control:Theatre6GiveUpSaveFileRequest(modeId, cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6GiveUpSaveFileRequest", { ModeId = modeId }, function(res)
        if cb then
            cb()
        end
        self._Model:ModelSettle(modeId)
    end)
end

---首次进入剧情模式，播放AVG
function XTheatre6Control:RequestStoryModeGuideFinished(storyId, cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6StoryModeGuideFinishedRequest", { StoryId = storyId }, function(res)
        self._Model:UpdateStoryModeGuideFinished(storyId)
        cb()
    end)
end

---购买San值
function XTheatre6Control:RequestShopBuySan(cb)
    local req = {}
    req.BuySanTimes = self:GetPurchaseSanTimes()
    XNetwork.CallWithAutoHandleErrorCode("Theatre6ShopBuySanRequest", req, function(res)
        self._Model:UpdateShopBuySan(res)
        if cb then
            cb()
        end
    end)
end

---是否进入额外楼层
function XTheatre6Control:RequestExFloorConfirm(isEnter, cb)
    local req = {}
    req.IsEnter = isEnter
    XNetwork.CallWithAutoHandleErrorCode("Theatre6ExFloorConfirmRequest", req, function(res)
        if isEnter then
            self._Model:UpdateNewFloorData(res.ModeDataDb) --后续还会收到NotifyTheatre6NewFloorData
        else
            XMVCA.XTheatre6:EnterSettleProcess(res.SettleData, res.StoryModeSaveDb)
        end
        if cb then
            cb()
        end
    end)
end

return XTheatre6Control
