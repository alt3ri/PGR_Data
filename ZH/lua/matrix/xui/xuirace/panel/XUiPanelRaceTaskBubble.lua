---@class XUiPanelRaceTaskBubble : XUiNode 主界面任务气泡
---@field Parent XUiRaceMain
---@field _Control XRaceControl
local XUiPanelRaceTaskBubble = XClass(XUiNode, "XUiPanelRaceTaskBubble")

function XUiPanelRaceTaskBubble:OnStart()
    local itemIds = self.Parent._ActivityConfig.ShowItemId
    local itemCounts = self.Parent._ActivityConfig.ShowItemCount
    XUiHelper.RefreshCustomizedList(self.PanelItem, self.Grid256New, #itemIds, function(i, go)
        ---@type XUiGridCommon
        local grid = require("XUi/XUiObtain/XUiGridCommon").New(self.Parent, go)
        grid:Refresh({ TemplateId = itemIds[i], Count = itemCounts[i] })
        grid:SetName("")
    end)
end

function XUiPanelRaceTaskBubble:OnEnable()
    self._BubbleCloseTime = XTime.GetServerNowTimestamp() + self._Control:GetIntClientConfig("TaskBubbleCloseTime")
    self:Open()
end

function XUiPanelRaceTaskBubble:Update()
    if not self._BubbleCloseTime then
        return
    end

    if XTime.GetServerNowTimestamp() > self._BubbleCloseTime then
        self:Close()
        self._BubbleCloseTime = nil
    end
end

return XUiPanelRaceTaskBubble
