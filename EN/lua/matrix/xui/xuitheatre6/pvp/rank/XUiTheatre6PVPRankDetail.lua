local XUiTheatre6PVPRankDetailGrid = require("XUi/XUiTheatre6/PVP/Rank/Grid/XUiTheatre6PVPRankDetailGrid")

---@class XUiTheatre6PVPRankDetail: XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6PVPRankDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre6PVPRankDetail")

function XUiTheatre6PVPRankDetail:OnAwake()
    ---@type XUiTheatre6PVPRankDetailGrid[]
    self._Grids = {}

    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainClick))

    self:InitUi()
end

function XUiTheatre6PVPRankDetail:InitUi()
    self.GridRankDetail.gameObject:SetActiveEx(false)
end

function XUiTheatre6PVPRankDetail:OnEnable()
    self:Refresh()
end

function XUiTheatre6PVPRankDetail:OnBtnBackClick()
    self:Close()
end

function XUiTheatre6PVPRankDetail:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiTheatre6PVPRankDetail:Refresh()
    local index = 1
    local configs = self._Control:GetPvpRankConfigs(true)
    local score = self._Control:GetPvpCurScore()

    for _, config in pairs(configs) do
        local grid = self._Grids[index]

        if not grid then
           local gridUi = index == 1 and self.GridRankDetail or XUiHelper.Instantiate(self.GridRankDetail, self.ListRank)

           grid = XUiTheatre6PVPRankDetailGrid.New(gridUi, self)
           self._Grids[index] = grid
        end

        index = index + 1
        grid:Open()
        grid:Refresh(config, score)
    end
    for i = index, #self._Grids do
        self._Grids[i]:Close()
    end
end

return XUiTheatre6PVPRankDetail
