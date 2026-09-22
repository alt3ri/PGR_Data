local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---超限启航任务格（沿用通用任务格结构，本界面只需展示 + 领取 + 跳转）
---@class XUiGridTransfiniteTowerTask : XUiNode
---@field Parent XUiTransfiniteTowerTask
local XUiGridTransfiniteTowerTask = XClass(XUiNode, "XUiGridTransfiniteTowerTask")

local ButtonState = {
    Normal = CS.UiButtonState.Normal,
    Disable = CS.UiButtonState.Disable
}

--region 初始化

function XUiGridTransfiniteTowerTask:OnStart()
    self.RewardPanelList = {}
    self.GridCommon.gameObject:SetActiveEx(false)
    self.ImgComplete.gameObject:SetActiveEx(false)
    self.PanelAnimation.gameObject:SetActiveEx(true)
    self:PlayAnimation()
    self.BtnFinish:AddEventListener(handler(self, self.OnBtnFinishClick))
    self.BtnSkip:AddEventListener(handler(self, self.OnBtnSkipClick))
    self.BtnSkip:SetButtonState(ButtonState.Disable)
end

function XUiGridTransfiniteTowerTask:PlayAnimation()
    if self.IsAnimation then
        return
    end

    self.IsAnimation = true
    self.GridTaskEnable:PlayTimelineAnimation()
end

--endregion

--region 数据更新

function XUiGridTransfiniteTowerTask:ResetData(data)
    self.Data = data

    local config = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    self.tableData = config
    -- 未完成时是否支持跳转
    self.BtnSkip:SetButtonState(config.SkipId and ButtonState.Normal or ButtonState.Disable)
    self.TxtTaskName.text = config.Title
    self.TxtTaskDescribe.text = config.Desc
    self.TxtSubTypeTip.text = config.Suffix or ""
    self.RImgTaskType:SetRawImage(config.Icon)
    self:UpdateProgress(data, config)
    self:RefreshRewards(config.RewardId)
end

---奖励格：首个复用模板节点，其余克隆（XUiGridCommon 是老式类，无法走 RefreshUiObjectList）
function XUiGridTransfiniteTowerTask:RefreshRewards(rewardId)
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end
    local rewards = XRewardManager.GetRewardList(rewardId)
    if not rewards then
        return
    end
    for i = 1, #rewards do
        local panel = self.RewardPanelList[i]
        if not panel then
            if i == 1 then
                panel = XUiGridCommon.New(self.Parent, self.GridCommon)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                ui.transform:SetParent(self.GridCommon.parent, false)
                panel = XUiGridCommon.New(self.Parent, ui)
            end
            self.RewardPanelList[i] = panel
        end
        panel:Refresh(rewards[i])
    end
end

function XUiGridTransfiniteTowerTask:UpdateProgress(data, config)
    self.Data = data
    config = config or self.tableData
    -- 多条件任务不显示进度条
    local isShowProgress = #config.Condition < 2
    self.ImgProgress.transform.parent.gameObject:SetActiveEx(isShowProgress)
    self.TxtTaskNumQian.gameObject:SetActiveEx(isShowProgress)
    if isShowProgress then
        self._ProgressResult = config.Result > 0 and config.Result or 1
        XTool.LoopMap(data.Schedule, handler(self, self.OnLoopSchedule))
    end

    self.BtnFinish.gameObject:SetActiveEx(false)
    self.BtnSkip.gameObject:SetActiveEx(false)
    self.ImgComplete.gameObject:SetActiveEx(false)

    local TaskState = XDataCenter.TaskManager.TaskState
    if data.State == TaskState.Achieved then
        self.BtnFinish.gameObject:SetActiveEx(true)
    elseif data.State ~= TaskState.Finish then
        self.BtnSkip.gameObject:SetActiveEx(true)
    else
        self.ImgComplete.gameObject:SetActiveEx(true)
    end
end

function XUiGridTransfiniteTowerTask:OnLoopSchedule(_, pair)
    local result = self._ProgressResult
    self.ImgProgress.fillAmount = pair.Value / result
    pair.Value = (pair.Value >= result) and result or pair.Value
    self.TxtTaskNumQian.text = pair.Value .. "/" .. result
end

--endregion

--region 事件处理

function XUiGridTransfiniteTowerTask:OnBtnFinishClick()
    local weaponCount = 0
    local chipCount = 0
    local rewards = XRewardManager.GetRewardList(self.tableData.RewardId)
    for i = 1, #rewards do
        local rewardsId = self.RewardPanelList[i].TemplateId
        if XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
            weaponCount = weaponCount + 1
        elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
            chipCount = chipCount + 1
        end
    end
    if weaponCount > 0 and XMVCA.XEquip:CheckBagCount(weaponCount, XEnumConst.EQUIP.CLASSIFY.WEAPON) == false or
            chipCount > 0 and XMVCA.XEquip:CheckBagCount(chipCount, XEnumConst.EQUIP.CLASSIFY.AWARENESS) == false then
        return
    end
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        for i = 1, #rewards do
            if rewards[i].RewardType == XRewardManager.XRewardType.Nameplate then
                return
            end
        end
        XUiManager.OpenUiObtain(rewardGoodsList, nil, handler(self, self.OnObtainClose))
    end)
end

function XUiGridTransfiniteTowerTask:OnObtainClose()
    self.Parent:RefreshTasks()
end

function XUiGridTransfiniteTowerTask:OnBtnSkipClick()
    -- 在房间内跳转需先退房间，故二次确认
    if XDataCenter.RoomManager.RoomData ~= nil then
        local title = XUiHelper.GetText("TipTitle")
        local cancelMatchMsg = XUiHelper.GetText("OnlineInstanceQuitRoom")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, handler(self, self.OnQuitRoomConfirm))
        return
    end
    self:DoSkip()
end

function XUiGridTransfiniteTowerTask:OnQuitRoomConfirm()
    XLuaUiManager.RunMain()
    self:DoSkip()
end

function XUiGridTransfiniteTowerTask:DoSkip()
    XFunctionManager.SkipInterface(self.tableData.SkipId)
end

--endregion

return XUiGridTransfiniteTowerTask
