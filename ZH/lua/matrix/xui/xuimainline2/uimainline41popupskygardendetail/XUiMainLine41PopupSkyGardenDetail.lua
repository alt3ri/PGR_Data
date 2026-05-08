--- 空花跳转弹窗
---@class XUiMainLine41PopupSkyGardenDetail: XLuaUi
---@field protected _Control XMainLine2Control
local XUiMainLine41PopupSkyGardenDetail = XLuaUiManager.Register(XLuaUi, "UiMainLine41PopupSkyGardenDetail")

--region Ui生命周期

function XUiMainLine41PopupSkyGardenDetail:OnAwake()
    self.BtnClose:AddEventListener(function()
        self:Close()
    end)
    
    self.BtnYes:AddEventListener(handler(self, self._OnBtnYesClick))
end

function XUiMainLine41PopupSkyGardenDetail:OnStart()
    self._GridRewards = {}
    
    self.TxtTitle.text = self._Control:GetClientConfigParams("FaoSkyGardenEntry", 2)
    self.TxtStory.text = XUiHelper.ReplaceTextNewLine(self._Control:GetClientConfigParams("FaoSkyGardenEntry", 3))
    self._TaskId = self._Control:GetClientConfigNumber("FaoSkyGardenEntry", 1)
    
    local isValidTask = self._TaskId and self._TaskId > 0
    local rewardId = self._Control:GetClientConfigNumber("FaoSkyGardenEntryRewardId")
    local skipId = 0
    local taskFinished = false
    if isValidTask then
        local taskTemplate = XTaskConfig.GetTaskCfgById(self._TaskId)
        skipId = taskTemplate and taskTemplate.SkipId or 0
        taskFinished = XDataCenter.TaskManager.CheckTaskFinished(self._TaskId)
    end
    
    self._SkipId = skipId
    self._Params = {
        ShowReceived = taskFinished
    }
    
    self:RefreshReward(rewardId)
end

--endregion

function XUiMainLine41PopupSkyGardenDetail:_OnBtnYesClick()
    XFunctionManager.SkipInterface(self._SkipId)
end

function XUiMainLine41PopupSkyGardenDetail:RefreshReward(rewardId)
    if not rewardId or rewardId <= 0 then
        XTool.UpdateDynamicGridCommon(self._GridRewards, nil, self.Grid256)
        self.PanelReward.gameObject:SetActiveEx(false)
    else
        self.PanelReward.gameObject:SetActiveEx(true)
        local rewardGoods = XRewardManager.GetRewardList(rewardId)
        XTool.UpdateDynamicGridCommon(self._GridRewards, rewardGoods, self.Grid256, nil, self._Params)
    end
end

return XUiMainLine41PopupSkyGardenDetail