
local XUiTeamPrefabPopupCover = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabPopupCover")

function XUiTeamPrefabPopupCover:OnAwake()
    self:InitButton()
end

function XUiTeamPrefabPopupCover:InitButton()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnCancel.CallBack = function() self:Close() end
    self.BtnCover.CallBack = function() self:OnBtnCoverClick() end
end

---@param xTeam XTeam
---@param XTeamPrefab XTeamPrefab
---@param continueCb function    
function XUiTeamPrefabPopupCover:OnStart(xRealTeam, XTeamPrefab, continueCb)
    self.XRealTeam = xRealTeam
    self.XTeamPrefab = XTeamPrefab
    self.ContinueCb = continueCb
end

function XUiTeamPrefabPopupCover:OnEnable()
    local XUiGridCoverMember = require("XUi/XUiTeamPrefab/XUiTeamPrefabPopupCover/Grid/XUiGridCoverMember")

    local teamMaxPos = XDataCenter.TeamManager.GetMaxPos()
    for pos = 1, teamMaxPos do
        local grid = XUiGridCoverMember.New(self["GridRTMember"..pos], self)
        grid:RefreshByRealTeam(self.XRealTeam, pos)
    end

    for pos = 1, teamMaxPos do
        local grid = XUiGridCoverMember.New(self["GridTPMember"..pos], self)
        grid:RefreshByTeamPrefab(self.XTeamPrefab, pos)
    end
end

function XUiTeamPrefabPopupCover:OnBtnCoverClick()
    self.XTeamPrefab:CoverFromRealTeamData(self.XRealTeam, function ()
        if self.ContinueCb then
            self.ContinueCb()
        end
    end)
    self:Close()
end
