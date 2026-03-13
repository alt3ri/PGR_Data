
---@class XUiMainLineLuosaitaPopupSkyGardenDetail : XLuaUi
---@field _Control XMainLineLuosaitaControl
local XUiMainLineLuosaitaPopupSkyGardenDetail = XLuaUiManager.Register(XLuaUi, "UiMainLineLuosaitaPopupSkyGardenDetail")

function XUiMainLineLuosaitaPopupSkyGardenDetail:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiMainLineLuosaitaPopupSkyGardenDetail:OnStart()
    self._TaskId = self._Control:GetSkyGardenEntryTaskId()
    self._Title, self._Desc = self._Control:GetSkyGardenEntryTitleAndDesc()
    
    self:InitView()
end

function XUiMainLineLuosaitaPopupSkyGardenDetail:InitUi()
    self._GridRewards = {}
end

function XUiMainLineLuosaitaPopupSkyGardenDetail:InitCb()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.BtnYes:AddEventListener(handler(self, self.OnBtnGoClick))
end

function XUiMainLineLuosaitaPopupSkyGardenDetail:InitView()
    local isValidTask = self._TaskId and self._TaskId > 0
    local showBtnGo = false
    local rewardId = self._Control:GetSkyGardenEntryRewardId()
    local skipId = 0
    local taskFinished = false
    if isValidTask then
        local taskTemplate = XTaskConfig.GetTaskCfgById(self._TaskId)
        skipId = taskTemplate and taskTemplate.SkipId or 0
        taskFinished = XDataCenter.TaskManager.CheckTaskFinished(self._TaskId)
        showBtnGo = skipId > 0 and not taskFinished
    else
        showBtnGo = false
    end
    self._SkipId = skipId
    self._Params = {
        ShowReceived = taskFinished
    }
    self.BtnYes.gameObject:SetActiveEx(showBtnGo)
    self.TxtTitle.text = self._Title
    self.TxtStory.text = self._Desc
    self:RefreshReward(rewardId)
end

function XUiMainLineLuosaitaPopupSkyGardenDetail:RefreshReward(rewardId)
    if not rewardId or rewardId <= 0 then
        XTool.UpdateDynamicGridCommon(self._GridRewards, nil, self.Grid256)
        self.PanelReward.gameObject:SetActiveEx(false)
    else
        self.PanelReward.gameObject:SetActiveEx(true)
        local rewardGoods = XRewardManager.GetRewardList(rewardId)
        XTool.UpdateDynamicGridCommon(self._GridRewards, rewardGoods, self.Grid256, nil, self._Params) 
    end
end

function XUiMainLineLuosaitaPopupSkyGardenDetail:OnBtnGoClick()
    if not self._SkipId or self._SkipId <= 0 then
        self.BtnYes.gameObject:SetActiveEx(false)
        return
    end
    local skipId = self._SkipId
    --self:Close()
    XFunctionManager.SkipInterface(skipId)
end