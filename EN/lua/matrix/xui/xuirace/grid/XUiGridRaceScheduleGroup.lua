---@class XUiGridRaceScheduleGroup : XUiNode
---@field Parent XUiPanelRaceScheduleTable
---@field _Control XRaceControl
local XUiGridRaceScheduleGroup = XClass(XUiNode, "XUiGridRaceScheduleGroup")

function XUiGridRaceScheduleGroup:OnStart()
    ---@type XUiGridRaceScheduleHead
    self._Heads = {}
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridRaceScheduleGroup:InitPointsRace(pointGroupId)
    self._PointsRace = self._Control:GetPointsRaceData(pointGroupId)
    local roundIds = self._PointsRace:GetRounds()
    for i, roundId in ipairs(roundIds) do
        local cfg = self._Control:GetRaceRoundById(roundId)
        local etcd = self._Control:GetEtcdRoundConfig(roundId)
        if i == 1 then
            self.TxtName.text = cfg.Name
        elseif i == #roundIds then
            self._PromotionNum = etcd.PromotionNum --晋升数量（积分赛每组有多场，第一场策划会配置晋升6人【无人被淘汰】，最后一场配置晋升4人【2人被淘汰】）
        end
        local txtName = string.format("TxtTime%s", i)
        self[txtName].text = XTime.TimestampToGameDateTimeString(etcd.StartTimeLong, "MM/dd")
    end
    self._PointGroupId = pointGroupId
end

function XUiGridRaceScheduleGroup:UpdatePointsRace()
    local isGroupEnd = self._PointsRace:IsGroupEnd()
    for i = 1, self._PointsRace:GetRoleCount() do
        ---@type XUiGridRaceScheduleHead
        local head = self._Heads[i]
        if not head then
            local nodeName = string.format("Node%s", i)
            local go = self.Parent:InstantiateHead(self[nodeName])
            head = require("XUi/XUiRace/Grid/XUiGridRaceScheduleHead").New(go, self)
            self._Heads[i] = head
        end
        local roleId = self._PointsRace:GetShowRoleId(i)
        if not roleId then
            head:SetRoleId()
        elseif isGroupEnd then
            local isUp = self._PointsRace:IsRoleUp(roleId)
            local isDown = self._PointsRace:IsRoleDown(roleId)
            head:SetRoleId(roleId, isUp, isDown)
        else
            head:SetRoleId(roleId, false, false)
        end
    end
end

function XUiGridRaceScheduleGroup:InitEliminator(roundId, isFinal)
    self._Eliminator = self._Control:GetEliminatorData(roundId)
    local cfg = self._Control:GetRaceRoundById(roundId)
    local etcd = self._Control:GetEtcdRoundConfig(roundId)
    self._RoundId = roundId
    self._IsFinal = isFinal
    self._PromotionNum = etcd.PromotionNum
    self.TxtName.text = cfg.Name
    self.TxtTime.text = XTime.TimestampToGameDateTimeString(etcd.StartTimeLong, "MM/dd")
end

function XUiGridRaceScheduleGroup:UpdateEliminator()
    local isMatchEnd = self._Eliminator:IsMatchEnd()
    local roleIds = self._Eliminator:GetShowRoleIds()
    if self._IsFinal then
        --总决赛的角色显示 要把AB和CD组的晋升角色排在同一边
        roleIds = XTool.Clone(roleIds)
        local roleFromDict = {}
        local etcd = self._Control:GetEtcdRoundConfig(self._RoundId)
        for _, roundId in pairs(etcd.FromRoundIds) do
            local data = self._Control:GetEliminatorData(roundId)
            for _, roleId in pairs(data:GetUpRoleIds()) do
                roleFromDict[roleId] = roundId
            end
        end
        table.sort(roleIds, function(a, b)
            local aSort = roleFromDict[a] or 0
            local bSort = roleFromDict[b] or 0
            if aSort ~= bSort then
                return aSort < bSort
            end
            return a < b
        end)
    end
    for i = 1, self._Eliminator:GetRoleCount() do
        ---@type XUiGridRaceScheduleHead
        local head = self._Heads[i]
        if not head then
            local nodeName = string.format("Node%s", i)
            local go = self.Parent:InstantiateHead(self[nodeName])
            head = require("XUi/XUiRace/Grid/XUiGridRaceScheduleHead").New(go, self)
            self._Heads[i] = head
        end
        local roleId = roleIds[i]
        if not roleId then
            head:SetRoleId()
        elseif isMatchEnd then
            local isUp = self._Eliminator:IsRoleUp(roleId)
            local isDown = self._Eliminator:IsRoleDown(roleId)
            head:SetRoleId(roleId, isUp, isDown)
        else
            head:SetRoleId(roleId, false, false)
        end
    end
    --总冠军
    if self._IsFinal then
        if not self._ChampionHead then
            local go = self.Parent:InstantiateHead(self.Champion)
            ---@type XUiGridRaceScheduleHead
            self._ChampionHead = require("XUi/XUiRace/Grid/XUiGridRaceScheduleHead").New(go, self, true)
        end
        local roleId = isMatchEnd and self._Eliminator:GetRankRoleId(1)
        local roleValid = XTool.IsNumberValid(roleId)
        self._ChampionHead:SetRoleId(roleId, true, false)
        self.ImgChampionEmpty.gameObject:SetActiveEx(not roleValid)
        self.ImgChampion.gameObject:SetActiveEx(roleValid)
    end
end

function XUiGridRaceScheduleGroup:OnBtnClick()
    if self._Eliminator then
        if not self._Eliminator:IsOpen() then
            --比赛未开启
            local etcd = self._Control:GetEtcdRoundConfig(self._RoundId)
            local timeStr = XTime.TimestampToGameDateTimeString(etcd.StartTimeLong, XUiHelper.GetText("RaceTimeFormat"))
            self._Control:OpenTip("RaceRoundStartTime", timeStr)
            return
        end
        self.Parent.Parent:JumpToEliminator(self._RoundId)
    else
        self.Parent.Parent:JumpToPointsRace(self._PointGroupId)
    end
end

return XUiGridRaceScheduleGroup
