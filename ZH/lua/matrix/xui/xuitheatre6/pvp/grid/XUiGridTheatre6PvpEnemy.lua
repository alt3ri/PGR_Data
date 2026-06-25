---@class XUiGridTheatre6PvpEnemy : XUiNode
---@field _Control XTheatre6Control
---@field Parent XUiTheatre6PVPMain
local XUiGridTheatre6PvpEnemy = XClass(XUiNode, "XUiGridTheatre6PvpEnemy")

local XUiGridTheatre6PvpMember = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpMember")
local XUiGridTheatre6PvpRole = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRole")
local XUiGridTheatre6PvpRank = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRank")

function XUiGridTheatre6PvpEnemy:OnStart()
    self.GridPVPRole.gameObject:SetActiveEx(false)
    self.BtnEnemyDetail:AddEventListener(handler(self, self.OnBtnEnemyDetailClick))

    ---@type XUiGridTheatre6PvpMember
    self._MemberGrid = nil
    ---@type XUiGridTheatre6PvpRank
    self._RankGrid = nil
    ---@type table<number, XUiGridTheatre6PvpRole>
    self._RoleGrids = {}
end

---@param data XTheatre6PvpMatchEnemy
function XUiGridTheatre6PvpEnemy:Update(data, index)
    self.Data = data
    self.Index = index
    self:RefreshContent()
end

function XUiGridTheatre6PvpEnemy:RefreshContent()
    local battleData = self.Data and self.Data.BattleData or nil
    if not battleData then
        return
    end
    local mistNum = self.Data.MistNum or 0
    self:RefreshCharacter(battleData, mistNum)
    self:RefreshMember(battleData)
    self:RefreshRank(battleData)
    self:RefreshRoles(battleData, mistNum)
end

---@param battleData XTheatre6PvpPlayerBattleDb
function XUiGridTheatre6PvpEnemy:RefreshCharacter(battleData, mistNum)
    local fileDataList = self._Control:GetEnemySaveFiles(battleData)
    local icon = self._Control:GetPvpPlayerBigPortrait(fileDataList, mistNum, 1)
    self.RImgCharacter:SetRawImageEx(icon)
end

---@param battleData XTheatre6PvpPlayerBattleDb
function XUiGridTheatre6PvpEnemy:RefreshMember(battleData)
    if not self._MemberGrid then
        self._MemberGrid = XUiGridTheatre6PvpMember.New(self.GridMember, self)
    end
    self._MemberGrid:Open()
    self._MemberGrid:Refresh(battleData.Name, battleData.HeadPortraitId, battleData.HeadFrameId, battleData.PlayerId)
end

---@param battleData XTheatre6PvpPlayerBattleDb
function XUiGridTheatre6PvpEnemy:RefreshRank(battleData)
    if not self._RankGrid then
        self._RankGrid = XUiGridTheatre6PvpRank.New(self.GridRank, self)
    end
    self._RankGrid:Open()
    self._RankGrid:SetData(battleData.RankId)
    self._RankGrid:SetRankScore(battleData.Score)
end

---@param battleData XTheatre6PvpPlayerBattleDb
function XUiGridTheatre6PvpEnemy:RefreshRoles(battleData, mistNum)
    local fileDataList = self._Control:GetEnemySaveFiles(battleData)
    local roleCount = #fileDataList
    local hasRole = roleCount > 0
    self.ListRole.gameObject:SetActiveEx(hasRole)

    for index = 1, roleCount do
        local grid = self._RoleGrids[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridPVPRole, self.ListRole)
            grid = XUiGridTheatre6PvpRole.New(go, self)
            self._RoleGrids[index] = grid
        end
        grid:Open()
        local isMist = self._Control:IsPVPSlotMist(fileDataList, mistNum, index)
        grid:Refresh(fileDataList[index], isMist)
    end
    for i = roleCount + 1, #self._RoleGrids do
        local grid = self._RoleGrids[i]
        if grid then
            grid:Close()
        end
    end
end

function XUiGridTheatre6PvpEnemy:OnBtnEnemyDetailClick()
    XLuaUiManager.Open("UiTheatre6PVPAttackDefend", XEnumConst.Theatre6.Pvp.LineupMode.Attack, self.Data)
end

return XUiGridTheatre6PvpEnemy
