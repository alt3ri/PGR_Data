local XUiMainLine2PanelEntranceList = require("XUi/XUiMainLine2/XUiMainLine2PanelEntranceList")

---@class XUiMainLine2PanelChapter4P5: XUiMainLine2PanelEntranceList
---@field protected _Control XMainLine2Control
---@field Parent
local XUiMainLine2PanelChapter4P5 = XClass(XUiMainLine2PanelEntranceList, "XUiMainLine2PanelChapter4P5")

function XUiMainLine2PanelChapter4P5:InitUi()
    XUiMainLine2PanelEntranceList.InitUi(self)
    
    -- 初始化空花入口
    if self.BtnGarden then
        self.BtnGarden:AddEventListener(handler(self, self._OnBtnSkyGardenClick))
    end
end

function XUiMainLine2PanelChapter4P5:OnEnable()
    XUiMainLine2PanelEntranceList.OnEnable(self)
    self:_RefreshSkyGardenEntranceShow()
end

function XUiMainLine2PanelChapter4P5:_OnBtnSkyGardenClick()
    XLuaUiManager.Open("UiMainLine41PopupSkyGardenDetail")
end

function XUiMainLine2PanelChapter4P5:_RefreshSkyGardenEntranceShow()
    -- 1. 检查是否显示
    local showCondition = self._Control:GetClientConfigNumber("FaoSkyGardenEntryCondition")

    if (XTool.IsNumberValidEx(showCondition) and not XConditionManager.CheckCondition(showCondition)) or not self:_CheckSkyGardenTaskCanSkip() then
        if self.BtnGarden then
            self.BtnGarden.gameObject:SetActiveEx(false)
        end
        return
    end
    
    -- 2. 显示完成状态
    local isComplete = self:_CheckSkyGardenTaskFinish()

    if self.BtnGarden then
        self.BtnGarden:ShowReddot(not isComplete)
        self.BtnGarden:SetButtonState(isComplete and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    end
end

function XUiMainLine2PanelChapter4P5:_CheckSkyGardenTaskCanSkip()
    local taskId = self._Control:GetClientConfigNumber("FaoSkyGardenEntry", 1)

    if XTool.IsNumberValidEx(taskId) then
        local taskTemplate = XTaskConfig.GetTaskCfgById(taskId)

        return taskTemplate and XTool.IsNumberValidEx(taskTemplate.SkipId)
    end
    
    return false
end

function XUiMainLine2PanelChapter4P5:_CheckSkyGardenTaskFinish()
    local taskId = self._Control:GetClientConfigNumber("FaoSkyGardenEntry", 1)

    if XTool.IsNumberValidEx(taskId) then
        return XDataCenter.TaskManager.CheckTaskFinished(taskId)
    end
    
    return false
end

return XUiMainLine2PanelChapter4P5