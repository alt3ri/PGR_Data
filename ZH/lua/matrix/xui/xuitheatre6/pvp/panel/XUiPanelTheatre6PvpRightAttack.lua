local XUiPanelTheatre6PvpRightBase = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpRightBase")
local XUiGridTheatre6PvpRole = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRole")

---@class XUiPanelTheatre6PvpRightAttack : XUiPanelTheatre6PvpRightBase
---@field private _Control XTheatre6Control
local XUiPanelTheatre6PvpRightAttack = XClass(XUiPanelTheatre6PvpRightBase, "XUiPanelTheatre6PvpRightAttack")

function XUiPanelTheatre6PvpRightAttack:OnStart()
    XUiPanelTheatre6PvpRightAttack.Super.OnStart(self)
    self.GridPVPRoleEnemy.gameObject:SetActiveEx(false)
    self.BtnEnvironmentMe:AddEventListener(handler(self, self.OnBtnEnvironmentMeClick))
    self.BtnEnvironmentEnemy:AddEventListener(handler(self, self.OnBtnEnvironmentEnemyClick))

    ---@type table<number, XUiGridTheatre6PvpRole>
    self._EnemyRoleGrids = {}
end

function XUiPanelTheatre6PvpRightAttack:GetLineupMode()
    return XEnumConst.Theatre6.Pvp.LineupMode.Attack
end

function XUiPanelTheatre6PvpRightAttack:Refresh()
    self:RefreshBtn()
    self:RefreshRoleMe()
    self:RefreshRoleEnemy()
    self:SelectDefaultSlot()
end

function XUiPanelTheatre6PvpRightAttack:RefreshBtn()
    self.BtnEnvironmentMe.gameObject:SetActiveEx(self._Control:IsPvpBuffGroupIdValid())
    self.BtnEnvironmentEnemy.gameObject:SetActiveEx(self.Parent:HasDefenseBuffId())
    local buffId = self._Control:GetPvpCurrentLineupBuffId(self:GetLineupMode())
    if not XTool.IsNumberValid(buffId) then
        return
    end
    local buffConfig = self._Control:GetPvpBuffConfig(buffId)
    if buffConfig then
        self.BtnEnvironmentMe:SetRawImageEx(buffConfig.Icon)
    end
end

function XUiPanelTheatre6PvpRightAttack:RefreshRoleEnemy()
    local fileDataList = self.Parent:GetFileDataList()
    local mistNum = self.Parent:GetMistNum()
    for index = 1, 3 do
        local grid = self._EnemyRoleGrids[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridPVPRoleEnemy, self.ListRoleEnemy)
            grid = XUiGridTheatre6PvpRole.New(go, self, handler(self, self.OnEnemyRoleGridClick))
            grid:SetBtnEnabled(true)
            self._EnemyRoleGrids[index] = grid
        end
        grid:Open()
        local isMist = self._Control:IsPVPSlotMist(fileDataList, mistNum, index)
        grid:Refresh(fileDataList[index], isMist, index)
    end
end

---@param grid XUiGridTheatre6PvpRole
function XUiPanelTheatre6PvpRightAttack:OnEnemyRoleGridClick(grid)
    local fileDataList = self.Parent:GetFileDataList()
    local mistNum = self.Parent:GetMistNum()
    local lineupDataList = {}
    for index = 1, 3 do
        lineupDataList[index] = {
            MyFileData = self._MyFileDataList[index],
            EnemyFileData = fileDataList[index],
            IsMist = self._Control:IsPVPSlotMist(fileDataList, mistNum, index),
        }
    end
    XLuaUiManager.Open("UiTheatre6PopupPVPCompare", grid.Index, lineupDataList)
end

function XUiPanelTheatre6PvpRightAttack:OnBtnEnvironmentMeClick()
    XLuaUiManager.OpenWithCloseCallback("UiTheatre6PopupChooseEnvironment", function()
        self:RefreshBtn()
    end, self.Parent:GetLineupMode())
end

function XUiPanelTheatre6PvpRightAttack:OnBtnEnvironmentEnemyClick()
    self._Control:ShowTip(self._Control:GetPvpClientConfigValue("EnemyEnvironmentTip"))
end

return XUiPanelTheatre6PvpRightAttack
