---@class XUiGridRaceScheduleRankCell : XUiNode
---@field Parent XUiPanelRaceScheduleRank
---@field _Control XRaceControl
local XUiGridRaceScheduleRankCell = XClass(XUiNode, "XUiGridRaceScheduleRankCell")

local Empty = "/"

function XUiGridRaceScheduleRankCell:OnStart()
    self.BtnHead.CallBack = handler(self, self.OnBtnHeadClick)
    self.BtnTips.CallBack = handler(self, self.OnBtnTipsClick)
end

---@param data XRacePointsRaceData
function XUiGridRaceScheduleRankCell:SetPointsRaceData(index, roleId, data, isShowTime, isShowBtnTip)
    local rankData = data:GetRoleRankData(roleId)
    self._Index = index
    self._RoleId = roleId
    self._IsUp = data:IsRoleUp(roleId)
    self._IsDown = data:IsRoleDown(roleId)

    local rank1 = Empty
    local rank2 = Empty
    local time1 = Empty
    local time2 = Empty
    local point = Empty

    if rankData then
        rank1 = data:GetInRoleRank(roleId, 1) or Empty
        rank2 = data:GetInRoleRank(roleId, 2) or Empty
        time1 = self._Control:GetPassTimeStr(data:GetRoleTime(roleId, 1)) or Empty
        time2 = self._Control:GetPassTimeStr(data:GetRoleTime(roleId, 2)) or Empty
        point = data:GetRoleTotalPoint(roleId) or Empty
    end

    self.TxtRank1.text = rank1
    self.TxtRank1Fail.text = rank1
    self.TxtRank2.text = rank2
    self.TxtRank2Fail.text = rank2
    self.TxtTime1.text = time1
    self.TxtTime1Fail.text = time1
    self.TxtTime2.text = time2
    self.TxtTime2Fail.text = time2
    self.TxtPoint.text = point
    self.TxtPointFail.text = point
    
    self:ShowRankIndex()
    self:ShowRole()
    self:ShowResult()
    self:ShowNode(true, isShowTime, isShowBtnTip)
end

---@param data XRaceEliminatorData
function XUiGridRaceScheduleRankCell:SetEliminatorData(index, roleId, data)
    self._Index = index
    self._RoleId = roleId
    self._IsUp = data:IsRoleUp(roleId)
    self._IsDown = data:IsRoleDown(roleId)

    local time3 = self._Control:GetPassTimeStr(data:GetRolePassTime(roleId)) or Empty
    self.TxtTime3.text = time3
    self.TxtTime3Fail.text = time3

    self:ShowRankIndex()
    self:ShowRole()
    self:ShowResult(data:IsFinal())
    self:ShowNode(false)
end

function XUiGridRaceScheduleRankCell:ShowRankIndex()
    self.ImgRank:SetSprite(self._Control:GetClientConfig("RankNumIcon", self._Index))
end

function XUiGridRaceScheduleRankCell:ShowRole()
    local cfg = self._Control:GetRaceCharacterById(self._RoleId)
    self.BtnHead:SetRawImage(cfg.Icon)
    self.BtnHead:SetNameByGroup(0, cfg.Name)
end

function XUiGridRaceScheduleRankCell:ShowResult(isFinal)
    self.PanelWin.gameObject:SetActiveEx(not self._IsDown)
    self.PanelFail.gameObject:SetActiveEx(self._IsDown)
    self.Win.gameObject:SetActiveEx(self._IsUp)
    self.Fail.gameObject:SetActiveEx(self._IsDown and not isFinal)
    self.TxtWin1.gameObject:SetActiveEx(self._IsUp and not isFinal)
    self.TxtWin2.gameObject:SetActiveEx(self._IsUp and isFinal)
end

function XUiGridRaceScheduleRankCell:ShowNode(isPointRace, isShowTime, isShowBtnTip)
    local isShowRank = isPointRace and not isShowTime
    local isShowPointRaceTime = isPointRace and isShowTime
    self.TxtRank1.gameObject:SetActiveEx(isShowRank)
    self.TxtRank1Fail.gameObject:SetActiveEx(isShowRank)
    self.TxtRank2.gameObject:SetActiveEx(isShowRank)
    self.TxtRank2Fail.gameObject:SetActiveEx(isShowRank)
    self.TxtTime1.gameObject:SetActiveEx(isShowPointRaceTime)
    self.TxtTime1Fail.gameObject:SetActiveEx(isShowPointRaceTime)
    self.TxtTime2.gameObject:SetActiveEx(isShowPointRaceTime)
    self.TxtTime2Fail.gameObject:SetActiveEx(isShowPointRaceTime)
    self.TxtTime3.gameObject:SetActiveEx(not isPointRace)
    self.TxtTime3Fail.gameObject:SetActiveEx(not isPointRace)
    self.TxtPoint.gameObject:SetActiveEx(isPointRace)
    self.TxtPointFail.gameObject:SetActiveEx(isPointRace)
    self.BtnTips.gameObject:SetActiveEx(isPointRace and isShowBtnTip)
end

function XUiGridRaceScheduleRankCell:OnBtnHeadClick()
    XLuaUiManager.Open("UiRaceMemberDetail", self._RoleId, self.BtnHead.transform)
end

function XUiGridRaceScheduleRankCell:OnBtnTipsClick()
    self.Parent:ShowPointTip(self.BtnTips.transform)
end

return XUiGridRaceScheduleRankCell
