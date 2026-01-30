---@class XUiSkyGardenShoppingStreetGameTargetTips : XLuaUi
local XUiSkyGardenShoppingStreetGameTargetTips = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetGameTargetTips")
local XUiSkyGardenShoppingStreetTargetGridTarget = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetTargetGridTarget")

function XUiSkyGardenShoppingStreetGameTargetTips:OnStart(...)
    self:_RegisterButtonClicks()
    
    self._TargetList = {}
    local stageId = self._Control:GetCurrentStageId()
    local config = self._Control:GetStageConfigsByStageId(stageId)
    XTool.UpdateDynamicItem(self._TargetList, config.TargetTaskIds, self.GridTarget, XUiSkyGardenShoppingStreetTargetGridTarget, self)
end

function XUiSkyGardenShoppingStreetGameTargetTips:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

return XUiSkyGardenShoppingStreetGameTargetTips
