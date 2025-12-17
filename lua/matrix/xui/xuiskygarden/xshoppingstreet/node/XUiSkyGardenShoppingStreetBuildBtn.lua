---@class XUiSkyGardenShoppingStreetBuildBtn : XUiNode
---@field ImgAttribute UnityEngine.UI.Image
---@field TxtDetailNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetBuildBtn = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuildBtn")

function XUiSkyGardenShoppingStreetBuildBtn:OnStart()
    self.GridBuild:AddEventListener(handler(self, self.OnGridBuildClick))
    self.PanelBuild.gameObject:SetActive(false)
end

function XUiSkyGardenShoppingStreetBuildBtn:SetSelect(isSelect)
    -- self.PanelBuild.gameObject:SetActive(isSelect)
    self.GridBuild:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiSkyGardenShoppingStreetBuildBtn:OnGridBuildClick()
    if self.Parent.OnGridBuildClick then
        self.Parent:OnGridBuildClick(self._Data.Id)
    end
end

function XUiSkyGardenShoppingStreetBuildBtn:GetShopId()
    return self._Data.Id
end

function XUiSkyGardenShoppingStreetBuildBtn:Update(data)
    self._Data = data
    self.GridBuild:SetSprite(data.SignboardImg)

    local hasBuilding = self._Control:GetAreaIdByShopId(self._Data.Id)
    if self.Disable then
        self.Disable.gameObject:SetActive(hasBuilding)
    end

    local area = self._Control:GetShopAreaByShopId(self._Data.Id)
    if area then
        local func = self.Parent.IsShowBtnUpgrade
        local isShowUpgradeBtn = false
        if func then isShowUpgradeBtn = func(self.Parent) end
        self.GridBuild:ShowReddot(isShowUpgradeBtn and area:CanShowUpgradeTips())
    else
        self.GridBuild:ShowReddot(false)
    end
end

return XUiSkyGardenShoppingStreetBuildBtn
