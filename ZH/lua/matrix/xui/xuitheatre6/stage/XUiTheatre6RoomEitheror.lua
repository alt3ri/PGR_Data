---@class XUiTheatre6RoomEitheror : XLuaUi 二择房间
---@field _Control XTheatre6Control
local XUiTheatre6RoomEitheror = XLuaUiManager.Register(XLuaUi, "UiTheatre6RoomEitheror")

local DragAction = XEnumConst.Theatre6.DragAction
local Direction = XEnumConst.Theatre6.Direction
local EventRewardType = XEnumConst.Theatre6.EventRewardType

function XUiTheatre6RoomEitheror:OnAwake()
    self._HideMask = handler(self, self.HideMask)
    ---@type table<number, XUiGridTheatre6TaskDemand[]>
    self._TaskDemandGrids = {}
    ---@type table<number,XUiGridTheatre6TaskDetail>
    self._TaskDetailGrids = {}

    self:InitComponent()
    self:InitAnimation()
    self:InitGuide()

    self.BtnTaskDetailClose:AddEventListener(handler(self, self.OnBtnTaskDetailCloseClick))
    self.BtnBossL:AddEventListener(handler(self, self.OnBtnBossLClick))
    self.BtnBossR:AddEventListener(handler(self, self.OnBtnBossRClick))
    self.BtnCharacter:AddEventListener(handler(self, self.OnBtnCharacterClick))
end

function XUiTheatre6RoomEitheror:OnStart()
    self._ModelData = self._Control:GetCurPlayModeData()
    self._RoomData = self._Control:GetCurRoomData()

    self:HideMask()
    self:CheckFightReconnect()
    self:InitBackgroup()
    self:InitDrag()
    self:CheckPlayKamuiGuide()
end

function XUiTheatre6RoomEitheror:OnEnable()
    --二择结束 进入任务结算界面
    if self._IsEnd then
        self._Control:OpenChooseRoom(true)
        return
    end
    self._Drag:InitDragToOriginalPos()
    self:OnLeaveChooseArea()
    self:UpdateTask()
    self._PanelAsset:Refresh()
    self._PanelBuff:UpdateView()
    self.BtnTaskDetailClose.gameObject:SetActiveEx(false)
    self:ShowEvent()
    self:PlayCardEnableAnim()
    self:ShowRoleInfo()
    self:WaitForPlayDragGuideAnim()
    XMVCA.XTheatre6:OpenSanDeathBuffPopup()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_SCORE_CHANGE, self.ShowRoleInfo, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_SAN_CHANGE, self.OnSanChange, self)
    
end

function XUiTheatre6RoomEitheror:OnDisable()
    self:StopMoveBackTimer()
    self:StopAutoCloseMaskTimer()
    self:StopDragGuideAnim()
    self:HideRewardSkillGrid()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_SCORE_CHANGE, self.ShowRoleInfo, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_SAN_CHANGE, self.OnSanChange, self)
end

function XUiTheatre6RoomEitheror:OnDestroy()
    self._Control:ClearTagHighlightSourceTagIds()
end

function XUiTheatre6RoomEitheror:InitComponent()
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    ---@type XUiPanelTheatre6TopSan
    self._PanelSan = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopSan").New(self.PanelSan, self)
    ---@type XUiPanelTheatre6Asset
    self._PanelAsset = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6Asset").New(self.PanelAsset, self)
    ---@type XUiPanelTheatre6BottomBuffList
    self._PanelBuff = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6BottomBuffList").New(self.ListBuff, self)
    ---@type XUiPanelTheatre6MessyCodeFx
    self._MessyCodeFx = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6MessyCodeFx").New(self.MessyCodeFx, self)

    self._PanelTrigger = {}
    XUiHelper.InitUiClass(self._PanelTrigger, self.PanelTrigger)

    require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopStage").New(self.PanelStage, self)
end

function XUiTheatre6RoomEitheror:InitDrag()
    ---@type XUiPanelTheatre6Drag
    self._Drag = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6Drag").New(self.UiPanelDrag, self)
    self._Drag:RegistActionHandler(DragAction.EnterTargetArea, handler(self, self.OnEnterChooseArea))
    self._Drag:RegistActionHandler(DragAction.LeaveTargetArea, handler(self, self.OnLeaveChooseArea))
    self._Drag:RegistActionHandler(DragAction.Dragging, handler(self, self.OnCardDragging))
    self._Drag:RegistActionHandler(DragAction.PlayEnd, handler(self, self.OnPlayEnd))
    self._Drag:SetTargetSelf()
    self._Drag:SetConfirmDistance(self._Control:GetIntClientConfigValue("EitherorChooseDistance"))
    self._Drag:SetScene(self.Transform)
end

function XUiTheatre6RoomEitheror:InitBackgroup()
    local groupConfig = self._Control:GetStageChooseGroupConfig(self._RoomData.ChooseGroupId)
    if string.IsNilOrEmpty(groupConfig.Bg) then
        self.RImgFullBg.gameObject:SetActiveEx(false)
    else
        self.RImgFullBg.gameObject:SetActiveEx(true)
        self.RImgFullBg:SetRawImage(groupConfig.Bg)
    end
    self._TotalEventCount = #groupConfig.ChoosePoolIds
end

function XUiTheatre6RoomEitheror:InitAnimation()
    self.PanelLeft.alpha = 0
    self.PanelRight.alpha = 0
    self.UiPanelCardLeftEnable.gameObject:SetActiveEx(false)
    self.UiPanelCardRightEnable.gameObject:SetActiveEx(false)
    self.UiPanelCardDisable.gameObject:SetActiveEx(false)

    self._DragDistance = 0
    self._DragRotation = 0
    self._MaxDragDistance = self._Control:GetIntClientConfigValue("EitherorMaxDragDistance")
    self._MaxDragRotation = self._Control:GetIntClientConfigValue("EitherorMaxDragRotation")
    self._ShowTextDistance = self._Control:GetIntClientConfigValue("EitherorShowTextDistance")
    self._BackTime = self._Control:GetIntClientConfigValue("EitherorReboundTime")
    self._ChooseTime = self._Control:GetIntClientConfigValue("EitherorCardEnableTime")
    self._ChooseAddMoveX = self._Control:GetIntClientConfigValue("EitherorChooseAddMoveX")
    self._ChooseAddRotationY = self._Control:GetIntClientConfigValue("EitherorChooseAddRotationY")
    self._IdleTime = self._Control:GetIntClientConfigValue("IdleWaitingTime")
end

function XUiTheatre6RoomEitheror:InitGuide()
    --第一次选择二择后播放的引导
    self._GuideId = self._Control:GetIntClientConfigValue("EitherorGuideId")
    --在指定关卡、指定步数触发二择引导
    self._TriggeredStageId = self._Control:GetIntClientConfigValue("EitherorGuide2", 1)
    self._GuideStep = self._Control:GetIntClientConfigValue("EitherorGuide2", 2)
    self._GuideId2 = self._Control:GetIntClientConfigValue("EitherorGuide2", 3)
    --san值变为黄/红时触发引导
    self._SanGuideCondition = self._Control:GetIntClientConfigValue("EitherorGuide3", 1)
    self._SanYellowGuideId = self._Control:GetIntClientConfigValue("EitherorGuide3", 2)
    self._SanYellowEffectId = self._Control:GetIntClientConfigValue("EitherorGuide3", 3)
    self._SanRedGuideId = self._Control:GetIntClientConfigValue("EitherorGuide3", 4)
    self._SanRedEffectId = self._Control:GetIntClientConfigValue("EitherorGuide3", 5)
end

function XUiTheatre6RoomEitheror:ShowRoleInfo()
    self.BtnCharacter:SetRawImage(self._Control:GetHeadIcon())
    self.BtnCharacter:SetName(self._ModelData.ScoreTotal)
end

function XUiTheatre6RoomEitheror:UpdateTask()
    ---@type XTheatre6StageTaskProtocol[]
    self._TaskDatas = {}
    for _, data in pairs(self._ModelData.StageTasks) do
        if data.TaskState ~= XEnumConst.Theatre6.TaskState.Init then
            table.insert(self._TaskDatas, data)
        end
    end

    table.sort(self._TaskDatas, function(a, b)
        return a.SlotIndex < b.SlotIndex
    end)

    if not self._TaskGrids then
        self._TaskGrids = {}
        for i = 1, #self._TaskDatas do
            local go = i == 1 and self.GridTask or XUiHelper.Instantiate(self.GridTask, self.GridTask.parent)
            local uiObj = {}
            XUiHelper.InitUiClass(uiObj, go)
            self._TaskGrids[i] = uiObj
        end
    end

    for i, taskData in ipairs(self._TaskDatas) do
        local uiObject = self._TaskGrids[i]
        local grids = self._TaskDemandGrids[i]
        local taskConfig = self._Control:GetTaskConfig(taskData.TaskId)
        local count = XTool.IsNumberValid(taskConfig.ConditionId) and 1 or #taskData.GoodsSlots
        local isTaskFinish = true
        if grids then
            for index = 1, count do
                local grid = grids[index]
                grid:SetData(taskData, index)
                grid:UpdateView()
                grid:ShowHighLight(false)
                if not grid:IsTaskFinish() then
                    isTaskFinish = false
                end
            end
        else
            self._TaskDemandGrids[i] = {}
            --任务进度
            XUiHelper.RefreshCustomizedList(uiObject.GridDemand.parent, uiObject.GridDemand, count, function(index, slotGo)
                ---@type XUiGridTheatre6TaskDemand
                local grid = require("XUi/XUiTheatre6/Task/Grid/XUiGridTheatre6TaskDemand").New(slotGo, self)
                grid:SetData(taskData, index)
                grid:UpdateView()
                grid:ShowHighLight(false)
                if not grid:IsTaskFinish() then
                    isTaskFinish = false
                end
                self._TaskDemandGrids[i][index] = grid
            end, true)
            --点击事件
            uiObject.GridTask:AddEventListener(function()
                local index = i
                self:OnTaskClick(uiObject.GridTaskDetail, index)
            end)
        end
        uiObject.UiPanelFinsh:SetAsLastSibling()
        uiObject.UiPanelFinsh.gameObject:SetActiveEx(isTaskFinish)
    end
end

function XUiTheatre6RoomEitheror:OnTaskClick(gridTaskDetail, index)
    local taskData = self._TaskDatas[index]
    local taskId = taskData.TaskId
    for _, grid in pairs(self._TaskDetailGrids) do
        if grid:GetTaskId() ~= taskId then
            grid:Close()
        end
    end

    local grid = self._TaskDetailGrids[taskId]
    if not grid then
        gridTaskDetail.gameObject:SetActiveEx(true)
        grid = require("XUi/XUiTheatre6/Task/Grid/XUiGridTheatre6TaskDetail").New(gridTaskDetail, self)
        self._TaskDetailGrids[taskId] = grid
    else
        grid:Open()
    end
    grid:SetData(taskData, false)

    self.BtnTaskDetailClose.gameObject:SetActiveEx(true)
end

function XUiTheatre6RoomEitheror:ShowEvent()
    self._StoryIdDict = {}
    self._FightDict = {}
    self._ShowRewardDict = {}

    self:HideEventReward()
    
    if self._RoomData.CurChoosePoolIdx + 1 > self._TotalEventCount then
        return
    end
    
    local chooseConfig = self._Control:GetStageChooseConfig(self._RoomData.CurChooseId)
    local backgroup = self._Control:GetClientConfigValue("EventBackgroup", chooseConfig.Quality)
    self.RImgBg:SetRawImage(backgroup)

    if string.IsNilOrEmpty(chooseConfig.Image) then
        self.UiRImgStory.gameObject:SetActiveEx(false)
    else
        self.UiRImgStory.gameObject:SetActiveEx(true)
        self.UiRImgStory:SetRawImage(chooseConfig.Image)
    end

    self.PanelBossTipL.gameObject:SetActiveEx(false)
    self.PanelBossTipR.gameObject:SetActiveEx(false)

    self.UiTxtStory.text = XUiHelper.ReplaceTextNewLine(chooseConfig.Desc)
    self.UiTxtNum.text = string.format("%s/%s", self._RoomData.CurChoosePoolIdx + 1, self._TotalEventCount)

    self.UiTxtStoryL.text = XUiHelper.ReplaceTextNewLine(chooseConfig.LeftDesc)
    self.UiTxtStoryR.text = XUiHelper.ReplaceTextNewLine(chooseConfig.RightDesc)

    self._ShowRewardDict[Direction.Left] = self:InitShowRewards(Direction.Left, self._RoomData.LeftRewards)
    self._ShowRewardDict[Direction.Right] = self:InitShowRewards(Direction.Right, self._RoomData.RightRewards)

    self:RefreshTagHighlightSource()
    self:ShowBossInfo(self._FightDict[Direction.Left], self.PanelBossTipL, self.TxtBossNameL)
    self:ShowBossInfo(self._FightDict[Direction.Right], self.PanelBossTipR, self.TxtBossNameR)

    self:CheckPlayGuide2()
    self:CheckPlayGuide3()
end

function XUiTheatre6RoomEitheror:RefreshTagHighlightSource()
    local skillIds = {}
    local attrPackIds = {}
    for _, rewardDatas in pairs(self._ShowRewardDict) do
        for _, rewardGood in ipairs(rewardDatas) do
            if XTool.IsNumberValid(rewardGood.SkillId) then
                table.insert(skillIds, rewardGood.SkillId)
            elseif XTool.IsNumberValid(rewardGood.AttrPack) then
                table.insert(attrPackIds, rewardGood.AttrPack)
            end
        end
    end
    local tagIds = self._Control:CollectShopOrTaskHighlightSourceTags(skillIds, attrPackIds)
    self._Control:SetTagHighlightSourceTagIds(tagIds)
end

function XUiTheatre6RoomEitheror:HideEventReward(direction)
    if self._IsShowEventReward then
        return
    end
    if direction == Direction.Left then
        self.PanelRewardL.gameObject:SetActiveEx(false)
    elseif direction == Direction.Right then
        self.PanelRewardR.gameObject:SetActiveEx(false)
    else
        self.PanelRewardL.gameObject:SetActiveEx(false)
        self.PanelRewardR.gameObject:SetActiveEx(false)
    end
    if self.RewardGrids then
        for _, grid in pairs(self.RewardGrids) do
            grid:Close()
        end
    end
    for _, gridList in pairs(self._TaskDemandGrids) do
        for _, grid in pairs(gridList) do
            grid:ShowHighLight(false)
        end
    end
end


function XUiTheatre6RoomEitheror:ShowEventReward(direction)
    local rewards = self._ShowRewardDict[direction]
    local count = #rewards
    local isLeft = direction == Direction.Left

    self._IsShowEventReward = true
    self.PanelRewardL.gameObject:SetActiveEx(isLeft and count > 0)
    self.PanelRewardR.gameObject:SetActiveEx(not isLeft and count > 0)
    
    self:ShowTaskRewardChange(direction)
    
    local node = isLeft and self.GridRewardL or self.GridRewardR
    ---@type XUiGridTheatre6Eitheror[]
    self.RewardGrids = self.RewardGrids or {}
    XUiHelper.RefreshCustomizedList(node.parent, node, count, function(i, go)
        local grid = self.RewardGrids[go]
        if not grid then
            grid = require("XUi/XUiTheatre6/Stage/Grid/XUiGridTheatre6Eitheror").New(go, self)
            self.RewardGrids[go] = grid
        else
            grid:Open()
        end
        grid:Refresh(rewards[i])
    end)
end

---高亮任务需求中与奖励相关的部分
function XUiTheatre6RoomEitheror:ShowTaskRewardChange(direction)
    local totalRewards = direction == Direction.Left and self._RoomData.LeftRewards or self._RoomData.RightRewards
    local goodsIds = {}

    for _, rewardData in ipairs(totalRewards) do
        if rewardData.RewardType == EventRewardType.Goods then
            goodsIds[rewardData.TemplateId] = true
        end
    end

    for i, grids in pairs(self._TaskDemandGrids) do
        local taskData = self._TaskDatas[i]
        for j, grid in pairs(grids) do
            local taskConfig = self._Control:GetTaskConfig(taskData.TaskId)
            local conditionId = taskConfig.ConditionId
            local isShowHighLight = false
            if XTool.IsNumberValid(conditionId) then
                --条件任务
                local condConfig = self._Control:GetConditionConfig(conditionId)
                if condConfig.Type == XEnumConst.Theatre6.TaskConditionType.Goods then
                    local needGoodsId = condConfig.Params[1]
                    isShowHighLight = needGoodsId and not XTool.IsTableEmpty(goodsIds) and (needGoodsId == 0 or goodsIds[needGoodsId])
                end
            else
                --材料任务
                local goodsSlots = taskData and taskData.GoodsSlots
                local goodsSlot = goodsSlots and goodsSlots[j]
                local goodsId = goodsSlot and goodsSlot.GoodsId
                isShowHighLight = goodsId and goodsIds[goodsId]
            end
            grid:ShowHighLight(isShowHighLight)
        end
    end
end

---只保留技能/遗物/Buff奖励
---@param rewardDatas Theatre6PreviewRewardGoodsProtocol[]
---@return Theatre6PreviewRewardGoodsProtocol[]
function XUiTheatre6RoomEitheror:InitShowRewards(direction, rewardDatas, showRewards)
    showRewards = showRewards or {}
    for _, rewardData in ipairs(rewardDatas) do
        if rewardData.RewardType == EventRewardType.SkillPool or rewardData.RewardType == EventRewardType.BuffPool then
            if self._Control:IsEventRewardShow(rewardData) then
                table.insert(showRewards, rewardData)
            end
        elseif rewardData.RewardType == EventRewardType.Fight then
            self._FightDict[direction] = rewardData.MonsterId
            self:InitShowRewards(direction, rewardData.FightRewards, showRewards)
        elseif rewardData.RewardType == EventRewardType.Avg then
            local config = self._Control:GetStoryDetailConfig(rewardData.TemplateId)
            self._StoryIdDict[direction] = config.StoryId
        end
    end
    return showRewards
end

function XUiTheatre6RoomEitheror:OnBtnTaskDetailCloseClick()
    self.BtnTaskDetailClose.gameObject:SetActiveEx(false)
    for _, grid in pairs(self._TaskDetailGrids) do
        grid:Close()
    end
end

---拖动一定距离后 同时显示文本、奖励和气泡
function XUiTheatre6RoomEitheror:OnCardDragging(posX, _)
    if not self._CurMovePosX then
        self._CurMovePosX = posX
        return
    end

    local distance = math.max(-self._MaxDragDistance, math.min(self._MaxDragDistance, posX - self._CurMovePosX))
    local val = self._ShowTextDistance
    if distance <= -val and self._DragDistance > -val then
        self:PlayLeftCardEnable()
    elseif distance >= -val and self._DragDistance < -val then
        self:PlayLeftCardDisable()
    end

    if distance >= val and self._DragDistance < val then
        self:PlayRightCardEnable()
    elseif distance <= val and self._DragDistance > val then
        self:PlayRightCardDisable()
    end

    self.UiPanelCardPos:SetAnchoredPositionX(distance)
    self._DragDistance = distance
    self._IsShowEventReward = false

    self._DragRotation = -self._MaxDragRotation * distance / self._MaxDragDistance
    self.UiPanelCardPos:SetEulerRotation(0, self._DragRotation, 0)
    self:StopDragGuideAnim()
end

function XUiTheatre6RoomEitheror:OnEnterChooseArea(direction)
    local isMonster = XTool.IsNumberValid(self._FightDict[direction])
    self._PanelTrigger.UiOnlvL.gameObject:SetActiveEx(not isMonster and direction == Direction.Left)
    self._PanelTrigger.UiOnhongL.gameObject:SetActiveEx(isMonster and direction == Direction.Left)
    self._PanelTrigger.UiOnlvR.gameObject:SetActiveEx(not isMonster and direction == Direction.Right)
    self._PanelTrigger.UiOnhongR.gameObject:SetActiveEx(isMonster and direction == Direction.Right)
end

function XUiTheatre6RoomEitheror:OnLeaveChooseArea()
    self._PanelTrigger.UiOnlvL.gameObject:SetActiveEx(false)
    self._PanelTrigger.UiOnhongL.gameObject:SetActiveEx(false)
    self._PanelTrigger.UiOnlvR.gameObject:SetActiveEx(false)
    self._PanelTrigger.UiOnhongR.gameObject:SetActiveEx(false)
end

function XUiTheatre6RoomEitheror:PlayCardDisableAnim(direction)
    self._CurCardAnimDir = direction
    self:PlayTimelineAnimation(self.UiPanelCardDisable)
end

function XUiTheatre6RoomEitheror:PlayCardEnableAnim()
    if not self._CurCardAnimDir then
        return
    end
    if self._CurCardAnimDir == Direction.Left then
        self:PlayTimelineAnimation(self.UiPanelCardRightEnable)
    else
        self:PlayTimelineAnimation(self.UiPanelCardLeftEnable)
    end
    self._CurCardAnimDir = nil
end

function XUiTheatre6RoomEitheror:PlayCardBack(direction)
    self._CurMovePosX = nil
    self:StopMoveBackTimer()

    if self._DragDistance < -self._ShowTextDistance then
        self:PlayLeftCardDisable()
    elseif self._DragDistance > self._ShowTextDistance then
        self:PlayRightCardDisable()
    end

    local targetPosX, targetRotationY = 0, 0
    local startPosX, startRotationY = self._DragDistance, self._DragRotation
    local elapsed, duration = 0, self._BackTime
    
    --卡牌消失为：在0.1秒内，完成最终位置x轴±100位移、±10°倾斜
    if direction then
        self:PlayCardDisableAnim(direction)
        if direction == Direction.Left then
            targetPosX = self._DragDistance - self._ChooseAddMoveX
            targetRotationY = self._DragRotation + self._ChooseAddRotationY
        else
            targetPosX = self._DragDistance + self._ChooseAddMoveX
            targetRotationY = self._DragRotation - self._ChooseAddRotationY
        end
        duration = self._ChooseTime
    end
    
    self._CardMoveBackTimerId = XScheduleManager.ScheduleForever(function()
        elapsed = elapsed + CS.UnityEngine.Time.deltaTime
        local t = math.min(elapsed / duration, 1)

        self.UiPanelCardPos:SetAnchoredPositionX(startPosX + (targetPosX - startPosX) * t)
        self.UiPanelCardPos:SetEulerRotation(0, startRotationY + (targetRotationY - startRotationY) * t, 0)

        if t >= 1 then
            self:StopTimelineAnimation(self.UiPanelCardDisable)
            self:OnPlayCardBackEnd(direction)
        end
    end, 0, 0)
end

function XUiTheatre6RoomEitheror:OnPlayCardBackEnd(direction)
    self._DragDistance = 0
    self._DragRotation = 0
    self:StopMoveBackTimer()
    self:OnEndChoose(direction)
    self:WaitForPlayDragGuideAnim()
end

function XUiTheatre6RoomEitheror:StopMoveBackTimer()
    if self._CardMoveBackTimerId then
        XScheduleManager.UnSchedule(self._CardMoveBackTimerId)
        self._CardMoveBackTimerId = nil
    end
end

function XUiTheatre6RoomEitheror:OnPlayEnd(direction)
    self:PlayCardBack(direction)
    self._Drag:InitDragToOriginalPos()
    self._Drag:ClearStatus()
end

function XUiTheatre6RoomEitheror:OnEndChoose(direction)
    --拖动组件初始化
    self._Drag:InitDragToOriginalPos()
    self:OnLeaveChooseArea()

    if not direction then
        return
    end

    if self:TryOpenSellSkillPanel() then
        self:PlayCardEnableAnim()
        return
    end

    local control = self._Control
    local storyId = self._StoryIdDict and self._StoryIdDict[direction]
    self._Control:RequestChooseEvent(direction, function(isEnd, isFight)
        --游戏结束，进去结算流程
        if XLuaUiManager.IsUiPushing("UiTheatre6Settlement") or XLuaUiManager.IsUiLoad("UiTheatre6Settlement") then
            return
        end
        
        self._IsEnd = isEnd
        --进入战斗
        if isFight then
            XLuaUiManager.Open("UiTheatre6Loading")
            if isEnd then
                self:Close()
            end
            return
        end

        if isEnd then
            self:CheckPlayStory(storyId, function()
                control:OpenChooseRoom(true)
            end)
            return
        end

        --更新界面
        self._PanelAsset:Refresh()
        self._PanelBuff:UpdateView()
        self:UpdateTask()

        --播放Avg
        self:CheckPlayStory(storyId, function()
            self:PlayCardEnableAnim()
            self:ShowEvent()
            self:CheckPlayGuide()
        end)
    end)
end

function XUiTheatre6RoomEitheror:TryOpenSellSkillPanel()
    return self._Control:CheckForceSellSkillBlock()
end

function XUiTheatre6RoomEitheror:CheckPlayStory(storyId, cb)
    if storyId then
        XDataCenter.MovieManager.PlayMovie(storyId, function()
            cb()
        end, nil, nil, false)
    else
        cb()
    end
end

function XUiTheatre6RoomEitheror:CheckFightReconnect()
    if XTool.IsNumberValid(self._RoomData.FightId) and XTool.IsNumberValid(self._RoomData.FightSeed)
            and XTool.IsNumberValid(self._RoomData.SelectedMonsterId) and not XTool.IsTableEmpty(self._RoomData.FightRewards) then
        XLuaUiManager.Open("UiTheatre6Loading")
    end
end

function XUiTheatre6RoomEitheror:OnBtnBossLClick()
    self:OpenBossCompare(Direction.Left)
end

function XUiTheatre6RoomEitheror:OnBtnBossRClick()
    self:OpenBossCompare(Direction.Right)
end

function XUiTheatre6RoomEitheror:OpenBossCompare(direction)
    local params = {
        IsBoss = false,
        MonsterIds = { self._FightDict[direction] },
    }
    XLuaUiManager.Open("UiTheatre6PopupBossCompare", nil, nil, params)
end

---@param animTran UnityEngine.RectTransform
function XUiTheatre6RoomEitheror:PlayTimelineAnimation(animTran)
    self:ShowMask()
    self:StopTimelineAnimation(animTran)
    animTran.gameObject:SetActiveEx(true)
    animTran:PlayTimelineAnimation(function()
        animTran.gameObject:SetActiveEx(false)
        self:HideMask()
        self:TryOpenSellSkillPanel()
    end)
end

---@param animTran UnityEngine.RectTransform
function XUiTheatre6RoomEitheror:StopTimelineAnimation(animTran)
    animTran:StopTimelineAnimation()
end

function XUiTheatre6RoomEitheror:PlayLeftCardEnable()
    self:StopAnimation("PanelLeftDisable")
    self:PlayAnimationWithMaskAuto("PanelLeftEnable")
    self:ShowEventReward(Direction.Left)
end

function XUiTheatre6RoomEitheror:PlayLeftCardDisable()
    self:StopAnimation("PanelLeftEnable")
    self:PlayAnimationWithMaskAuto("PanelLeftDisable")
    self:HideEventReward(Direction.Left)
end

function XUiTheatre6RoomEitheror:PlayRightCardEnable()
    self:StopAnimation("PanelRightDisable")
    self:PlayAnimationWithMaskAuto("PanelRightEnable")
    self:ShowEventReward(Direction.Right)
end

function XUiTheatre6RoomEitheror:PlayRightCardDisable()
    self:StopAnimation("PanelRightEnable")
    self:PlayAnimationWithMaskAuto("PanelRightDisable")
    self:HideEventReward(Direction.Right)
end

function XUiTheatre6RoomEitheror:ShowBossInfo(monsterId, panelBoss, txtBossName)
    if not monsterId then
        panelBoss.gameObject:SetActiveEx(false)
        return
    end
    local characterId = self._Control:GetMonsterConfig(monsterId).CharacterId
    panelBoss.gameObject:SetActiveEx(true)
    txtBossName.text = self._Control:GetCharacterConfig(characterId).Name
end

function XUiTheatre6RoomEitheror:OnBtnCharacterClick()
    XLuaUiManager.Open("UiTheatre6PopupRoleDetail", self.BtnCharacter.transform)
end

---san值变化时播放对应动画
function XUiTheatre6RoomEitheror:OnSanChange(sanChange)
    if sanChange > 0 then
        self:PlayAnimation("HpUpEnable", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
    elseif sanChange < 0 then
        self:PlayAnimation("HpDownEnable", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
    end
end

---玩家一段时间没操作时播放拖动引导动画
function XUiTheatre6RoomEitheror:WaitForPlayDragGuideAnim()
    self:StopDragGuideAnim()
    self._DragGuideTimerId = XScheduleManager.ScheduleOnce(function()
        self.PanelTipsAnim.gameObject:SetActiveEx(true)
        self.PanelTipsAnim.time = 0
        self.PanelTipsAnim:Play()
        self.PanelTipsAnim:Evaluate()
    end, self._IdleTime)
end

---停止播放拖动引导动画
function XUiTheatre6RoomEitheror:StopDragGuideAnim()
    if self._DragGuideTimerId then
        XScheduleManager.UnSchedule(self._DragGuideTimerId)
        self._DragGuideTimerId = nil
    end
    self.PanelTipsAnim:Stop()
    self.PanelTipsAnim.time = self.PanelTipsAnim.duration
    self.PanelTipsAnim:Evaluate()
    self.PanelTipsAnim.gameObject:SetActiveEx(false)
end

function XUiTheatre6RoomEitheror:CheckPlayGuide()
    if not XTool.IsNumberValid(self._GuideId) then
        return
    end
    local isGuidePlayed = XDataCenter.GuideManager.CheckIsGuide(self._GuideId)
    if isGuidePlayed then
        return
    end
    XDataCenter.GuideManager.PlayGuide(self._GuideId)
end

function XUiTheatre6RoomEitheror:CheckPlayGuide2()
    if not XTool.IsNumberValid(self._GuideId2) then
        return
    end
    if XDataCenter.GuideManager.CheckIsGuide(self._GuideId2) then
        return
    end
    if self._ModelData.StageId ~= self._TriggeredStageId then
        return
    end
    if self._RoomData.CurChoosePoolIdx + 1 ~= self._GuideStep then
        return
    end
    XDataCenter.GuideManager.PlayGuide(self._GuideId2)
end

function XUiTheatre6RoomEitheror:CheckPlayGuide3()
    if not XTool.IsNumberValid(self._SanGuideCondition) or not XConditionManager.CheckCondition(self._SanGuideCondition) then
        return
    end
    if self:CheckSanGuide(self._SanYellowGuideId, self._SanYellowEffectId) then
        return
    end
    self:CheckSanGuide(self._SanRedGuideId, self._SanRedEffectId)
end

function XUiTheatre6RoomEitheror:CheckSanGuide(guideId, effectId)
    if not XTool.IsNumberValid(guideId) then
        return false
    end
    if XDataCenter.GuideManager.CheckIsGuide(guideId) then
        return false
    end
    if not self._MessyCodeFx:IsExist(effectId) then
        return false
    end
    XDataCenter.GuideManager.PlayGuide(guideId)
    return true
end

function XUiTheatre6RoomEitheror:HideRewardSkillGrid()
    if XTool.IsTableEmpty(self.RewardGrids) then
        return
    end
    for _, grid in ipairs(self.RewardGrids) do
        grid:Close()
    end
end

---选择神威进入二择界面
function XUiTheatre6RoomEitheror:CheckPlayKamuiGuide()
    local characterId = self._Control:GetIntClientConfigValue("EitherorKamuiGuideId", 1)
    local guideId = self._Control:GetIntClientConfigValue("EitherorKamuiGuideId", 2)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(guideId) then
        return
    end
    if characterId ~= self._ModelData.CharacterId then
        return
    end
    if XDataCenter.GuideManager.CheckIsGuide(guideId) then
        return
    end
    XDataCenter.GuideManager.PlayGuide(guideId)
end

--region Mask

--先锋出现偶现无法点击问题/卡死，暂时定位不到问题（日志无相关报错信息）
--增加保底逻辑：二择不使用通用的Mask功能，改为在界面上放一个Mask对象，在需要的时候显示，并在3秒后自动隐藏
--此Mask对象不会挡住返回按钮，玩家可以通过返回按钮退出界面，避免卡死
function XUiTheatre6RoomEitheror:ShowMask()
    if not self.Mask then
        return
    end
    self:StopAutoCloseMaskTimer()
    self.Mask.gameObject:SetActiveEx(true)
    self._AutoCloseMaskTimerId = XScheduleManager.ScheduleOnce(self._HideMask, 3000)
end

function XUiTheatre6RoomEitheror:PlayAnimationWithMaskAuto(animName)
    self:PlayAnimation(animName, function()
        self:HideMask()
    end, function()
        self:ShowMask()
    end)
end

function XUiTheatre6RoomEitheror:HideMask()
    if not self.Mask then
        return
    end
    self:StopAutoCloseMaskTimer()
    self.Mask.gameObject:SetActiveEx(false)
end

function XUiTheatre6RoomEitheror:StopAutoCloseMaskTimer()
    if self._AutoCloseMaskTimerId then
        XScheduleManager.UnSchedule(self._AutoCloseMaskTimerId)
        self._AutoCloseMaskTimerId = nil
    end
end

--endregion

return XUiTheatre6RoomEitheror
