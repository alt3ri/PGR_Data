---@class XUiTheatre6RoomChooseTask : XLuaUi 选择任务
---@field _Control XTheatre6Control
local XUiTheatre6RoomChooseTask = XLuaUiManager.Register(XLuaUi, "UiTheatre6RoomChooseTask")

function XUiTheatre6RoomChooseTask:OnAwake()
    self:InitComponent()
    self.BtnCharacter:AddEventListener(handler(self, self.OnBtnCharacterClick))
    self.BtnYes:AddEventListener(handler(self, self.OnBtnYesClick))
end

function XUiTheatre6RoomChooseTask:OnStart()
    self._ModelData = self._Control:GetCurPlayModeData()
    self._RoomData = self._Control:GetCurRoomData()
    ---@type XUiGridTheatre6TaskDetail[]
    self._TaskGrids = {}
    self._ChooseTaskIndexDict = {}

    local config = self._Control:GetStageTaskGroupConfig(self._ModelData.TaskGroupId)
    self._ChooseNum = config.ChooseNum
    self._TaskNum = config.TaskNum

    --如果可选任务数大于等于3，则全选
    if self._ChooseNum >= 3 then
        for i in ipairs(self._ModelData.TaskSlotData) do
            self._ChooseTaskIndexDict[i] = true
        end
    end
    self:TryOpenSellSkillPanel()
end

function XUiTheatre6RoomChooseTask:OnEnable()
    self:ShowRoleInfo()
    self:UpdateTask()
    self._PanelAsset:Refresh()
    self._PanelBuff:UpdateView()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_SCORE_CHANGE, self.ShowRoleInfo, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_GOLD_CHANGE, self.UpdateTask, self)
end

function XUiTheatre6RoomChooseTask:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_SCORE_CHANGE, self.ShowRoleInfo, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_GOLD_CHANGE, self.UpdateTask, self)
end

function XUiTheatre6RoomChooseTask:InitComponent()
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    ---@type XUiPanelTheatre6TopSan
    self._PanelSan = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopSan").New(self.PanelSan, self)
    ---@type XUiPanelTheatre6Asset
    self._PanelAsset = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6Asset").New(self.PanelAsset, self)
    ---@type XUiPanelTheatre6BottomBuffList
    self._PanelBuff = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6BottomBuffList").New(self.ListBuff, self)

    require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopStage").New(self.PanelStage, self)
    require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6MessyCodeFx").New(self.MessyCodeFx, self)
end

function XUiTheatre6RoomChooseTask:ShowRoleInfo()
    self.BtnCharacter:SetRawImage(self._Control:GetHeadIcon())
    self.BtnCharacter:SetName(self._ModelData.ScoreTotal)
end

function XUiTheatre6RoomChooseTask:UpdateTask()
    for i, data in ipairs(self._ModelData.TaskSlotData) do
        local grid = self._TaskGrids[i]
        if not grid then
            local go = i == 1 and self.GridTask or XUiHelper.Instantiate(self.GridTask, self.GridTask.parent)
            grid = require("XUi/XUiTheatre6/Task/Grid/XUiGridTheatre6TaskDetail").New(go, self)
            self._TaskGrids[i] = grid
        end
        grid:Open()
        grid:SetSlotData(data, self._ModelData.TaskGroupId)
        grid:UpdateChoose(self._ChooseTaskIndexDict[i])
    end
    for i = #self._ModelData.TaskSlotData + 1, #self._TaskGrids do
        self._TaskGrids[i]:Close()
    end
    self.BtnYes:SetNameByGroup(1, string.format("%s/%s", XTool.GetTableCount(self._ChooseTaskIndexDict), self._ChooseNum))
end

function XUiTheatre6RoomChooseTask:ChooseTask(index)
    if self._ChooseNum >= 3 then
        self._Control:ShowTipWithKey("Theatre6ChooseMaxTaskTip")
        return
    end
    if self._ChooseTaskIndexDict[index] then
        self._ChooseTaskIndexDict[index] = nil
    elseif XTool.GetTableCount(self._ChooseTaskIndexDict) < self._ChooseNum then
        self._ChooseTaskIndexDict[index] = true
    else
        self._Control:ShowTipWithKey("Theatre6TaskChooseLimit")
        return
    end
    self:UpdateTask()
end

function XUiTheatre6RoomChooseTask:OnBtnCharacterClick()
    local upgradeSkillIds = self:CollectTaskUpgradeSkillIds()
    XLuaUiManager.Open("UiTheatre6PopupRoleDetail", self.BtnCharacter.transform, nil, upgradeSkillIds)
end

---收集当前 task 奖励中,商店升级箭头会亮起的 SkillId 集合
---@return table<number, true>
function XUiTheatre6RoomChooseTask:CollectTaskUpgradeSkillIds()
    local result = {}
    for _, slotData in ipairs(self._ModelData.TaskSlotData) do
        local taskData = self._ModelData.StageTasks[slotData.TaskId]
        if taskData and taskData.RewardGoods then
            for _, rewardGood in ipairs(taskData.RewardGoods) do
                local skillId = rewardGood.SkillId
                if XTool.IsNumberValid(skillId) and self._Control:ShopHasCanUpGradeSkills(skillId) then
                    result[skillId] = true
                end
            end
        end
    end
    return result
end

function XUiTheatre6RoomChooseTask:OnBtnYesClick()
    if XTool.GetTableCount(self._ChooseTaskIndexDict) < self._ChooseNum then
        self._Control:ShowTip(XUiHelper.GetText("Theatre6TaskChooseCountTip", self._ChooseNum))
        return
    end

    if self:TryOpenSellSkillPanel() then
        return
    end
    local taskIds = {}
    for index in pairs(self._ChooseTaskIndexDict) do
        table.insert(taskIds, self._ModelData.TaskSlotData[index].TaskId)
    end

    self._Control:RequestConfirmTask(taskIds, function()
        local control = self._Control
        self:Close()
        control:OpenChooseRoom()
    end)
end

function XUiTheatre6RoomChooseTask:TryOpenSellSkillPanel()
    return self._Control:CheckForceSellSkillBlock()
end

return XUiTheatre6RoomChooseTask