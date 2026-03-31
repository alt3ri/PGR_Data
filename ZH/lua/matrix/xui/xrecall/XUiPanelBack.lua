--- 回归玩家专属界面
---@class XUiPanelBack: XUiNode
---@field protected _Control XReCallActivityControl
---@field Parent
local XUiPanelBack = XClass(XUiNode, "XUiPanelBack")
local XUiGridBackTask = require("XUi/XReCall/XUiGridBackTask")

function XUiPanelBack:OnStart()
    self._SkipTypeCount = 2
    self:Init()
end

function XUiPanelBack:Init()
    self._GridList = {}
    
    for i = 1, self._SkipTypeCount do
        local go = self["GridTask" .. i]

        if go then
            local grid = XUiGridBackTask.New(go, self, i)
            grid:Open()
            
            table.insert(self._GridList, grid)
        end
    end
end

function XUiPanelBack:Refresh()
    if not XTool.IsTableEmpty(self._GridList) then
        for i, v in pairs(self._GridList) do
            v:Refresh()
        end
    end
end

return XUiPanelBack