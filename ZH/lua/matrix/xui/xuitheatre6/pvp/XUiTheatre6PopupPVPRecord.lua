---@class XUiTheatre6PopupPVPRecord : XLuaUi 对战记录
---@field _Control XTheatre6Control
local XUiTheatre6PopupPVPRecord = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupPVPRecord")

function XUiTheatre6PopupPVPRecord:OnAwake()
    ---@type XUiGridTheatre6PvpRecord[]
    self._Grid = {}
    self._MaxCount = self._Control:GetIntPvpConfigValue("MaxBattleRecordCount")
    self.BtnTanchuangCloseWhite:AddEventListener(handler(self, self.Close))
end

function XUiTheatre6PopupPVPRecord:OnStart()
    self.UiTheatre6PVPEnemyDetail.gameObject:SetActiveEx(false)
    self:UpdateView()
end

function XUiTheatre6PopupPVPRecord:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_PVP_RECORD_UPDATE, self.UpdateView, self)
end

function XUiTheatre6PopupPVPRecord:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_PVP_RECORD_UPDATE, self.UpdateView, self)
end

function XUiTheatre6PopupPVPRecord:UpdateView()
    ---@type XTheatre6PvpBattleRecord[]
    local list = {}
    local dict = self._Control:GetBattleRecords()
    if not XTool.IsTableEmpty(dict) then
        for _, data in pairs(dict) do
            table.insert(list, data)
        end
        table.sort(list, function(a, b)
            return a.BattleTime > b.BattleTime
        end)
    end

    local showCount = math.min(self._MaxCount, #list)
    for i = 1, showCount do
        local grid = self._Grid[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.UiTheatre6PVPEnemyDetail, self.UiTheatre6PVPEnemyDetail.parent)
            grid = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRecord").New(go, self)
            self._Grid[i] = grid
        end
        grid:Open()
        grid:SetData(list[i])
    end

    for i = showCount + 1, #self._Grid do
        self._Grid[i]:Close()
    end
end

return XUiTheatre6PopupPVPRecord