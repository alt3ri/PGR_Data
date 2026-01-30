---@class XUiGridGoldenMinerSuspendItem: XUiNode
local XUiGridGoldenMinerSuspendItem = XClass(XUiNode, 'XUiGridGoldenMinerSuspendItem')
local XUiGoldenMinerDisplayGrid = require("XUi/XUiGoldenMiner/Grid/XUiGoldenMinerDisplayGrid")

function XUiGridGoldenMinerSuspendItem:OnStart()
    ---@type XUiGoldenMinerDisplayGrid
    self.MainDetail = XUiGoldenMinerDisplayGrid.New(self.PanelDetail, self)
end

function XUiGridGoldenMinerSuspendItem:RefreshShow(mainIcon, mainDesc, additionalDescList)
    self.MainDetail:Refresh(mainIcon, mainDesc)

    if not XTool.IsTableEmpty(additionalDescList) then
        self.ListUpdate.gameObject:SetActiveEx(true)
        
        self._UpdateGridList = XUiHelper.RefreshUiObjectList(self._UpdateGridList, self.ListUpdate.transform, self.GridUpdate, additionalDescList and #additionalDescList or 0, function(index, grid)
            grid.TxtUpdate.text = additionalDescList[index]
        end)
    else
        self.ListUpdate.gameObject:SetActiveEx(false)    
    end
end

return XUiGridGoldenMinerSuspendItem