local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelRecallTask
---@field _Control XReCallActivityControl
local XUiPanelRecallTask = XClass(XUiNode, "XUiPanelRecallTask")
local XUiReCallTaskGrid = require("XUi/XReCall/XUiReCallTaskGrid")

function XUiPanelRecallTask:OnStart()
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelRecallTask:InitAutoScript()
    self:InitDynamicTable()
    self:AutoAddListener()
end

function XUiPanelRecallTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XUiReCallTaskGrid, self.Parent)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelRecallTask:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshTask(self.Tasks[index])
    end
end

function XUiPanelRecallTask:AutoAddListener()
    self.BtnCopy.CallBack = function() self:OnBtnCopyClick() end
end

function XUiPanelRecallTask:OnBtnCopyClick()
    XTool.CopyToClipboard(XMVCA.XReCallActivity:PlayIdToHexUpper())
end

function XUiPanelRecallTask:Refresh()
    self.Tasks = self._Control:GetTaskList()
    self.DynamicTable:SetDataSource(self.Tasks)
    self.DynamicTable:ReloadDataASync()
    self.GridNewbieTaskItem.gameObject:SetActiveEx(false)
    self.CodeText.text = CS.XTextManager.GetText("HoldRegressionInviteCode", XMVCA.XReCallActivity:PlayIdToHexUpper())
    self.InviteCountText.text = CS.XTextManager.GetText("HoldRegressionInvitenumber",self._Control:GetInviteCount())
end

return XUiPanelRecallTask