---@class XUiPanelGoldenMinerOwnHex: XUiNode
---@field protected _Control XGoldenMinerControl
local XUiPanelGoldenMinerOwnHex = XClass(XUiNode, 'XUiPanelGoldenMinerOwnHex')

function XUiPanelGoldenMinerOwnHex:OnStart()
    self.BtnOverview:AddEventListener(handler(self, self.OnBtnOverviewClickEvent))
end

function XUiPanelGoldenMinerOwnHex:OnEnable()
    self:RefreshOwnHexShow()
end

function XUiPanelGoldenMinerOwnHex:OnBtnOverviewClickEvent()
    XLuaUiManager.Open("UiGoldenMinerSuspend", nil, nil, true)
end

function XUiPanelGoldenMinerOwnHex:RefreshOwnHexShow()
    local hexList = self._Control:GetSelectedCoreHexList()
    
    local commonHexCount = self._Control:GetSelectedCommonHexCount()
    local hexSlotCount = self._Control:GetClientHexOwnCount()

    self._GridHexList = XUiHelper.RefreshUiObjectList(self._GridHexList, self.ListChange.transform, self.GridChange, hexSlotCount, function(index, grid)
        local hasHex = hexList and XTool.IsNumberValid(hexList[index]) or false
        grid.ImgEmpty.gameObject:SetActiveEx(not hasHex)
        grid.ImgIcon.gameObject:SetActiveEx(hasHex)
        
        if hasHex then
            grid.ImgIcon:SetImage(self._Control:GetCfgHexIcon(hexList[index]))
        end
    end)
    
    self.TxtHexNum.text = commonHexCount
end

return XUiPanelGoldenMinerOwnHex