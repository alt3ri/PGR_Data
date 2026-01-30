local XUiTheatre5PopupStrengthenItem = require("XUi/XUiTheatre5/XUiTheatre5PopupStrengthen/XUiTheatre5PopupStrengthenItem")

---@class XUiTheatre5PopupStrengthen : XLuaUi
---@field _Control XTheatre5Control
local XUiTheatre5PopupStrengthen = XLuaUiManager.Register(XLuaUi, "UiTheatre5PopupStrengthen")

function XUiTheatre5PopupStrengthen:OnAwake()
    self:BindExitBtns()
    self.GridDetail.gameObject:SetActiveEx(false)
    self.DynamicTableNormal = XUiHelper.DynamicTableNormal(self, self.ListGem, XUiTheatre5PopupStrengthenItem)
    self._HammerItemData = false
end

---@param hammerItemData XTheatre5Item
function XUiTheatre5PopupStrengthen:OnStart(hammerItemData, items)
    if hammerItemData then
        self._HammerItemData = hammerItemData
        items = items or self._Control:GetItemsCanStrengthen(hammerItemData)
        self.DynamicTableNormal:SetDataSource(items)
        self.DynamicTableNormal:ReloadDataSync()
    else
        XLog.Error("XUiTheatre5PopupStrengthen:OnStart 参数错误, 强化锤数据为空")
    end
end

---@param grid XUiTheatre5PopupStrengthenItem
function XUiTheatre5PopupStrengthen:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTableNormal:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        for _, v in pairs(self.DynamicTableNormal:GetGrids()) do
            if v ~= grid then
                v:SetSelected(false)
            end
        end
        if grid:GetSelected() then
            grid:SetSelected(false)
        else
            grid:SetSelected(true)
        end
    end
end

---@param rune XTheatre5Item
function XUiTheatre5PopupStrengthen:Confirm(rune)
    -- 强化
    if self._HammerItemData then
        if rune then
            XMVCA.XTheatre5:XTheatre5HammerStrengthenRequest(self._HammerItemData.InstanceId, rune.InstanceId, function()
                XUiManager.PopupLeftTip(XMVCA.XTheatre5:GetText("StrengthenSuccess"))
                self:Close()
            end)
        end
    end
end

return XUiTheatre5PopupStrengthen