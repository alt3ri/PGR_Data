---@class XUiPanelRaceScheduleRank : XUiNode
---@field Parent XUiRaceCourse
---@field _Control XRaceControl
local XUiPanelRaceScheduleRank = XClass(XUiNode, "XUiPanelRaceScheduleRank")

function XUiPanelRaceScheduleRank:OnStart()
    self._RankCells = {}
    self.BtnToggle.CallBack = handler(self, self.OnClickToggle)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiPanelRaceScheduleRank:OnEnable()
    self:OnBtnCloseClick()
end

function XUiPanelRaceScheduleRank:Switch(format, jumpTo)
    self._IsPointsRace = format == XEnumConst.Race.Format.PointsRace
    self.BtnToggle.gameObject:SetActiveEx(self._IsPointsRace)
    self:InitRoundTab(jumpTo)
end

function XUiPanelRaceScheduleRank:InitRoundTab(jumpTo)
    --小组页签
    ---@type table<XRaceEliminatorData,XUiComponent.XUiButton>
    self._EliminatorTabDict = {}
    local btns = {}
    local count = self._IsPointsRace and #self.Parent._PointGroupIds or #self.Parent._EliminatorIds
    XUiHelper.RefreshCustomizedList(self.GridTags.transform.parent, self.GridTags, count, function(i, go)
        local uiObject = {}
        local roundId
        XUiHelper.InitUiClass(uiObject, go)

        if self._IsPointsRace then
            local data = self._Control:GetPointsRaceData(self.Parent._PointGroupIds[i])
            roundId = data:GetRoundId()
        else
            local data = self._Control:GetEliminatorData(self.Parent._EliminatorIds[i])
            roundId = data:GetRoundId()
            self._EliminatorTabDict[data] = uiObject.GridTags
        end

        local cfg = self._Control:GetRaceRoundById(roundId)
        uiObject.GridTags:SetButtonState(XUiButtonState.Normal)
        uiObject.GridTags:SetNameByGroup(0, cfg.Name)
        table.insert(btns, uiObject.GridTags)
    end)
    self.PanelLeftTags:Init(btns, function(index)
        self:OnSelectTab(index)
    end)
    local selectIndex = 1
    if jumpTo then
        if self._IsPointsRace then
            selectIndex = table.indexof(self.Parent._PointGroupIds, jumpTo)
        else
            selectIndex = table.indexof(self.Parent._EliminatorIds, jumpTo)
        end
    end
    self.PanelLeftTags:SelectIndex(selectIndex)
    --排行榜页签
    self:UpdateRankTab()
end

function XUiPanelRaceScheduleRank:UpdateEliminatorTab()
    if XTool.IsTableEmpty(self._EliminatorTabDict) then
        return
    end
    for data, btn in pairs(self._EliminatorTabDict) do
        if btn.ButtonState ~= CS.UiButtonState.Select then
            btn:SetButtonState(data:IsOpen() and XUiButtonState.Normal or XUiButtonState.Disable)
        end
    end
end

function XUiPanelRaceScheduleRank:UpdateRankTab()
    --页签
    if self._IsPointsRace then
        self.PanelTitle1.gameObject:SetActiveEx(true)
        self.PanelTitle2.gameObject:SetActiveEx(false)
        self.TxtRank1.text = XUiHelper.GetText(self._IsShowTime and "RaceScheduleRankTag12" or "RaceScheduleRankTag11")
        self.TxtRank2.text = XUiHelper.GetText(self._IsShowTime and "RaceScheduleRankTag22" or "RaceScheduleRankTag21")
    else
        self.PanelTitle1.gameObject:SetActiveEx(false)
        self.PanelTitle2.gameObject:SetActiveEx(true)
    end
end

function XUiPanelRaceScheduleRank:UpdateRankData()
    if self._IsPointsRace then
        self:UpdatePointsRaceData()
        self:UpdatePointsRaceReviewBtn()
    else
        self:UpdateEliminatorData()
        self:UpdateEliminatorReviewBtn()
    end
end

function XUiPanelRaceScheduleRank:UpdatePointsRaceData()
    local data = self._Control:GetPointsRaceData(self.Parent._PointGroupIds[self._TabIndex])
    local repeatPoint = {}
    local roleIds = data:GetRankRoleIds()
    if XTool.IsTableEmpty(roleIds) then
        roleIds = data:GetShowRoleIds()
    end

    -- 重复积分的排行项 需要显示tip
    for roleId, v in pairs(data:GetRoleRankDatas()) do
        if v.Point then
            if not repeatPoint[v.Point] then
                repeatPoint[v.Point] = {}
            end
            table.insert(repeatPoint[v.Point], roleId)
        end
    end

    local roleCount = #roleIds
    local totalCount = #self._RankCells
    for i = 1, roleCount do
        local rankCell = self:GetRankGrid(i)
        local roleId = roleIds[i]
        local rankData = data:GetRoleRankData(roleId)
        local point = rankData and rankData.Point
        local isPointRepeat = false
        if point and repeatPoint[point] and #repeatPoint[point] > 1 then
            isPointRepeat = true
        end
        rankCell:Open()
        rankCell:SetPointsRaceData(i, roleId, data, self._IsShowTime, isPointRepeat)
    end
    for i = roleCount + 1, totalCount do
        local rankCell = self:GetRankGrid(i)
        rankCell:Close()
    end
end

function XUiPanelRaceScheduleRank:UpdatePointsRaceReviewBtn()
    local data = self._Control:GetPointsRaceData(self.Parent._PointGroupIds[self._TabIndex])
    local roundIds = data:GetRounds()
    XUiHelper.RefreshCustomizedList(self.Review.parent, self.Review, #roundIds, function(i, go)
        local roundId = roundIds[i]
        local isMatchEnd = data:IsMatchEnd(roundId)
        local startTime = self._Control:GetEtcdRoundConfig(roundId).StartTimeLong
        local dataStr = XTime.TimestampToGameDateTimeString(startTime, "MM-dd")
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.BtnPlayback:SetNameByGroup(0, XUiHelper.GetText("RaceReviewBtn1", i)) --第{0}场
        uiObject.BtnPlayback:SetButtonState(isMatchEnd and XUiButtonState.Normal or XUiButtonState.Disable)
        uiObject.BtnPlayback:SetNameByGroup(1, dataStr)
        uiObject.BtnPlayback.CallBack = function()
            if not isMatchEnd then
                return
            end
            self._Control:OpenPopup("TipTitle", "RaceReviewPopupTitle", nil, function()
                --查看回放
                self._Control:EnterGame(roundId, XEnumConst.Race.GameMode.Playback)
            end)
        end
    end)
end

function XUiPanelRaceScheduleRank:UpdateEliminatorData()
    local data = self._Control:GetEliminatorData(self.Parent._EliminatorIds[self._TabIndex])
    local roleIds = data:GetRankRoleIds()
    if XTool.IsTableEmpty(roleIds) then
        roleIds = data:GetShowRoleIds()
    end
    local roleCount = #roleIds
    local totalCount = #self._RankCells
    for i = 1, roleCount do
        local rankCell = self:GetRankGrid(i)
        local roleId = roleIds[i]
        rankCell:Open()
        rankCell:SetEliminatorData(i, roleId, data)
    end
    for i = roleCount + 1, totalCount do
        local rankCell = self:GetRankGrid(i)
        rankCell:Close()
    end
end

function XUiPanelRaceScheduleRank:UpdateEliminatorReviewBtn()
    local data = self._Control:GetEliminatorData(self.Parent._EliminatorIds[self._TabIndex])
    XUiHelper.RefreshCustomizedList(self.Review.parent, self.Review, 1, function(i, go)
        local roundId = data:GetRoundId()
        local isMatchEnd = data:IsMatchEnd()
        local roundCfg = self._Control:GetRaceRoundById(roundId)
        local startTime = self._Control:GetEtcdRoundConfig(roundId).StartTimeLong
        local dataStr = XTime.TimestampToGameDateTimeString(startTime, "MM-dd")
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.BtnPlayback:SetNameByGroup(0, roundCfg.Name)
        uiObject.BtnPlayback:SetButtonState(isMatchEnd and XUiButtonState.Normal or XUiButtonState.Disable)
        uiObject.BtnPlayback:SetNameByGroup(1, dataStr)
        uiObject.BtnPlayback.CallBack = function()
            if not isMatchEnd then
                return
            end
            self._Control:OpenPopup("TipTitle", "RaceReviewPopupTitle", nil, function()
                --查看回放
                self._Control:EnterGame(roundId, XEnumConst.Race.GameMode.Playback)
            end)
        end
    end)
end

function XUiPanelRaceScheduleRank:GetRankGrid(index)
    ---@type XUiGridRaceScheduleRankCell
    local rankCell = self._RankCells[index]
    if not rankCell then
        local go = index == 1 and self.GridRaceDetail or XUiHelper.Instantiate(self.GridRaceDetail, self.GridRaceDetail.parent)
        rankCell = require("XUi/XUiRace/Grid/XUiGridRaceScheduleRankCell").New(go, self)
        self._RankCells[index] = rankCell
    end
    return rankCell
end

function XUiPanelRaceScheduleRank:OnSelectTab(index)
    if not self._IsPointsRace then
        -- 淘汰赛未开启
        local roundId = self.Parent._EliminatorIds[index]
        local data = self._Control:GetEliminatorData(roundId)
        if not data:IsOpen() then
            local etcd = self._Control:GetEtcdRoundConfig(roundId)
            local timeStr = XTime.TimestampToGameDateTimeString(etcd.StartTimeLong, XUiHelper.GetText("RaceTimeFormat"))
            self._Control:OpenTip("RaceRoundStartTime", timeStr)
            return
        end
    end
    self._TabIndex = index
    self:UpdateRankData()
    self.Parent:PlayAnimationWithMask("QieHuan")
end

function XUiPanelRaceScheduleRank:ShowPointTip(dimObj)
    self.BtnClose.gameObject:SetActiveEx(true)
    self.ImgTips.gameObject:SetActiveEx(true)
    local pos = self.ImgTips.parent:InverseTransformPoint(dimObj.position)
    self.ImgTips.localPosition = Vector3(pos.x, pos.y, 0)
end

function XUiPanelRaceScheduleRank:OnClickToggle()
    self._IsShowTime = self.BtnToggle:GetToggleState()
    self:UpdateRankTab()
    self:UpdateRankData()
end

function XUiPanelRaceScheduleRank:OnBtnCloseClick()
    self.BtnClose.gameObject:SetActiveEx(false)
    self.ImgTips.gameObject:SetActiveEx(false)
end

return XUiPanelRaceScheduleRank
