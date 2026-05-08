---@class XUiTheatre6PopupGetBuff : XLuaUi 获得Buff弹框
---@field _Control XTheatre6Control
local XUiTheatre6PopupGetBuff = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupGetBuff")

function XUiTheatre6PopupGetBuff:OnAwake()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.BtnYes:AddEventListener(handler(self, self.Close))
end

---@param buffDatas XTheatre6BuffProtocol[]
function XUiTheatre6PopupGetBuff:OnStart(buffDatas, isSanDeathBuff)
    XUiHelper.RefreshCustomizedList(self.BuffDetail.parent, self.BuffDetail, #buffDatas, function(i, go)
        local buffData = buffDatas[i]
        ---@type XUiPanelTheatre6BuffDetail
        local buffDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6BuffDetail").New(go, self)
        local info = self._Control:GetActiveBuffInfo(buffData)
        buffDetail:SetBuffInfo(info)
        buffDetail:IsBuffCanClick(true)
    end)
    self.PanelTitle.gameObject:SetActiveEx(not isSanDeathBuff)
end

return XUiTheatre6PopupGetBuff