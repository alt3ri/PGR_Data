---@class XUiTheatre6PopupRelicDetail : XLuaUi 遗物详情列表弹窗
---@field _Control XTheatre6Control
local XUiTheatre6PopupRelicDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupRelicDetail")

function XUiTheatre6PopupRelicDetail:OnAwake()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnTanchuangCloseWhite:AddEventListener(handler(self, self.Close))
end

---@param relicIds number[] 遗物Id列表
---@param relicCounts number[] 遗物数量列表
---@param readOnly boolean 是否只读（存档来源等）
---@param modelData Theatre6FileData|nil 非当前局数据（存档/PVP），nil 时取当前局
function XUiTheatre6PopupRelicDetail:OnStart(relicIds, relicCounts, readOnly, modelData)
    ---@type XUiPanelTheatre6BubbleTag
    self._BubbleTag = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6BubbleTag").New(self.BubbleTagDetail, self)
    self._BubbleTag.BtnCloseTagDetail.gameObject:SetActiveEx(true)
    self._BubbleTag:Close()

    self.UiTxtNameNum.text = string.format("/%s", #relicIds)
    XUiHelper.RefreshCustomizedList(self.GridRelic.parent, self.GridRelic, #relicIds, function(i, go)
        ---@type XUiGridTheatre6RelicDetail
        local grid = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6RelicDetail").New(go, self)
        local relicCount = relicCounts and relicCounts[i] or 0
        grid:SetData(relicIds[i], readOnly, modelData)
        grid:SetBtnStatus({ ReadOnly = readOnly })
        grid:ShowOwn(relicCount)

    end)
end

return XUiTheatre6PopupRelicDetail