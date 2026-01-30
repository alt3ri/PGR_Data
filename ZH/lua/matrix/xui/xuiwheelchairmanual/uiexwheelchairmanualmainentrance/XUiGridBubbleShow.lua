---@class XWheelchairManual.XUiGridBubbleShow
---@field _Control XWheelchairManualControl
local XUiGridBubbleShow = XClass(XUiNode, 'XUiGridBubbleShow')

---@param rootUi XLuaUi
function XUiGridBubbleShow:OnStart(rootUi)
    self.RootUi = rootUi
    ---@type XUiGridCommon[]
    self.UiCommonGrids = {}
end

function XUiGridBubbleShow:RefreshBubbleShow(showList)
    XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, showList and #showList or 0, function(index, go)
        local grid = self.UiCommonGrids[go]

        if not grid then
            grid = XUiHelper.XUiGridCommon(self.RootUi, go)
            
            self.UiCommonGrids[go] = grid
        end
        
        grid:Refresh(showList[index])
    end)

    if self.BubbleBg then
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.BubbleBg)
    end
    
    if self.BubbleText then
        self.BubbleText.text = XMVCA.XWheelchairManual:GetWheelchairManualConfigString('ExMainEntranceBubbleText')
    end
end


return XUiGridBubbleShow