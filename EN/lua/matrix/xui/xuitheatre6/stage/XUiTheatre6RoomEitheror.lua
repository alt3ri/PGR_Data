---@class XUiTheatre6RoomEitheror : XLuaUi 二择房间
---@field _Control XTheatre6Control
local XUiTheatre6RoomEitheror = XLuaUiManager.Register(XLuaUi, "UiTheatre6RoomEitheror")

local DragAction = XEnumConst.Theatre6.DragAction
local Direction = XEnumConst.Theatre6.Direction
local EventRewardType = XEnumConst.Theatre6.EventRewardType

function XUiTheatre6RoomEitheror:OnAwake()
    ---@type table<number, XUiGridTheatre6TaskDemand[]>
    self._TaskDemandGrids = {}
    ---@type table<number,XUiGridTheatre6TaskDetail>
    self._TaskDetailGrids = {}

    self:InitComponent()
    self:InitAnimation()

    self.BtnTaskDetailClose:AddEventListener(handler(self, self.OnBtnTaskDetailCloseClick))
    self.BtnBossL:AddEventListener(handler(self, self.OnBtnBossLClick))
    self.BtnBossR:AddEventListener(handler(self, self.OnBtnBossRClick))
    self.BtnCharacter:AddEventListener(handler(self, self.OnBtnCharacterClick))
end

function XUiTheatre6RoomEitheror:OnStart()
    self._ModelData = self._Control:GetCurPlayModeData()
    self._RoomData = self._Control:GetCurRoomData()

    self:CheckFightReconnect()
    self:InitBackgroup()
    self:InitDrag()
    self:TryOpenSellSkillPanel()

end

function XUiTheatre6RoomEitheror:OnEnable()
    --二择结束 进入任务结算界面
    if self._IsEnd then
        local control = self._Control
        self:Close()
        control:OpenChooseRoom()
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
    self:StopDragGuideAnim()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_SCORE_CHANGE, self.ShowRoleInfo, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_SAN_CHANGE, self.OnSanChange, self)
end

function XUiTheatre6RoomEitheror:InitComponent()
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    ---@type XUiPanelTheatre6TopSan
    self._PanelSan = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopSan").New(self.PanelSan, self)
    ---@type XUiPanelTheatre6Asset
    self._PanelAsset = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6Asset").New(self.PanelAsset, self)
    ---@type XUiPanelTheatre6BottomBuffList
    self._PanelBuff = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6BottomBuffList").New(self.ListBuff, self)

    self._PanelTrigger = {}
    XUiHelper.InitUiClass(self._PanelTrigger, self.PanelTrigger)

    require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopStage").New(self.PanelStage, self)
    require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6MessyCodeFx").New(self.MessyCodeFx, self)
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

    self:ShowBossInfo(self._FightDict[Direction.Left], self.PanelBossTipL, self.TxtBossNameL)
    self:ShowBossInfo(self._FightDict[Direction.Right], self.PanelBossTipR, self.TxtBossNameR)
end

function XUiTheatre6RoomEitheror:HideEventReward()
    if not self._IsShowEventReward then
        return
    end
    self._IsShowEventReward = false
    self.PanelRewardL.gameObject:SetActiveEx(false)
    self.PanelRewardR.gameObject:SetActiveEx(false)
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
    XUiHelper.RefreshCustomizedList(node.parent, node, count, function(i, go)
        local grid = {}
        XUiHelper.InitUiClass(grid, go)
        self:ShowReward(grid, rewards[i])
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
            if XTool.IsNumberValid(conditionId) then
                --条件任务
                local condConfig = self._Control:GetConditionConfig(conditionId)
                if condConfig.Type == XEnumConst.Theatre6.TaskConditionType.Goods then
                    local needGoodsId = condConfig.Params[1]
                    if needGoodsId and (needGoodsId == 0 or goodsIds[needGoodsId]) then
                        grid:ShowHighLight(true)
                    end
                end
            else
                --材料任务
                local goodsSlots = taskData and taskData.GoodsSlots
                local goodsSlot = goodsSlots and goodsSlots[j]
                local goodsId = goodsSlot and goodsSlot.GoodsId
                grid:ShowHighLight(goodsId and goodsIds[goodsId])
            end
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

---@param rewardData Theatre6PreviewRewardGoodsProtocol
function XUiTheatre6RoomEitheror:ShowReward(grid, rewardData)
    local icon = self._Control:GetEventRewardIcon(rewardData)
    grid.TxtDesc.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
    grid.TxtDesc.text = self._Control:GetEventRewardDesc(rewardData)
    grid.RImgReward.gameObject:SetActiveEx(true)
    grid.ImgBg.gameObject:SetActiveEx(true)
    grid.RImgReward:SetRawImage(icon)
    grid.BtnClick.gameObject:SetActiveEx(false)
    --遗物显示加成属性
    if XTool.IsNumberValid(rewardData.AttrPack) then
        grid.PanelAttr.gameObject:SetActiveEx(true)
        local attrPackConfig = self._Control:GetAttrPackCfgById(rewardData.AttrPack)
        local attrConfigs, attrValues = self._Control:GetShowAttribute(attrPackConfig.AttrTypes, attrPackConfig.AttrNums)
        XUiHelper.RefreshCustomizedList(grid.PanelAttr, grid.GridAttr, #attrConfigs, function(i, go)
            local config = attrConfigs[i]
            local attrValue = attrValues[i]
            local uiObj = {}
            XUiHelper.InitUiClass(uiObj, go)
            uiObj.ImgIcon:SetRawImage(config.Icon)
            if attrValue >= 0 then
                uiObj.TxtNum.text = string.format("%s + %s", config.Name, self._Control:FormatNumberWithUnit(attrValue))
            else
                uiObj.TxtNum.text = string.format("%s %s", config.Name, self._Control:FormatNumberWithUnit(attrValue))
            end
        end)
    else
        grid.PanelAttr.gameObject:SetActiveEx(false)
    end
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
        return
    end

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
            return
        end

        if isEnd then
            self:CheckPlayStory(storyId, function()
                local control = self._Control
                self:Close()
                control:OpenChooseRoom()
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
    XLuaUiManager.SetMask(true)
    animTran.gameObject:SetActiveEx(true)
    animTran:PlayTimelineAnimation(function()
        animTran.gameObject:SetActiveEx(false)
        XLuaUiManager.SetMask(false)
    end)
end

---@param animTran UnityEngine.RectTransform
function XUiTheatre6RoomEitheror:StopTimelineAnimation(animTran)
    animTran:StopTimelineAnimation()
    animTran.gameObject:SetActiveEx(false)
end

function XUiTheatre6RoomEitheror:PlayLeftCardEnable()
    self:StopAnimation("PanelLeftDisable")
    self:PlayAnimation("PanelLeftEnable")
    self:ShowEventReward(Direction.Left)
end

function XUiTheatre6RoomEitheror:PlayLeftCardDisable()
    self:StopAnimation("PanelLeftEnable")
    self:PlayAnimationWithMask("PanelLeftDisable")
    self:HideEventReward()
end

function XUiTheatre6RoomEitheror:PlayRightCardEnable()
    self:StopAnimation("PanelRightDisable")
    self:PlayAnimation("PanelRightEnable")
    self:ShowEventReward(Direction.Right)
end

function XUiTheatre6RoomEitheror:PlayRightCardDisable()
    self:StopAnimation("PanelRightEnable")
    self:PlayAnimationWithMask("PanelRightDisable")
    self:HideEventReward()
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
        self:PlayAnimation("HpUpEnable")
    elseif sanChange < 0 then
        self:PlayAnimation("HpDownEnable")
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

return XUiTheatre6RoomEitheror
