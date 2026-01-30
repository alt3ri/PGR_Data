local Dropdown = CS.UnityEngine.UI.Dropdown

---@class XUiPanelRaceChoose : XUiNode 预测项目的选项列表
---@field Parent XUiRacePredict
---@field _Control XRaceControl
local XUiPanelRaceChoose = XClass(XUiNode, "XUiPanelRaceChoose")

local Sort = XEnumConst.Race.Sort

local RoleSortName = { "RaceDefault", "RaceSupport", "RaceSpeed", "RaceAcc", "RaceDrift", "RaceLuck" }
local OptionSortName = { "RaceDefault", "RaceSupport" }

function XUiPanelRaceChoose:OnStart()
    self._RoleIds = self._Control:GetRoleIdsByRoundId(self.Parent._RoundId)
    self._HistoryChooses = {}
    self:InitDrdSort()
    self:RecordGridSize()
end

function XUiPanelRaceChoose:InitDrdSort()
    self.DrdSort.onValueChanged:AddListener(function(index)
        if self._SortRule == index then
            return
        end
        self._SortRule = index
        if self._IsRole then
            self:UpdateSortRole(true)
        else
            self:UpdateSortOption()
        end
    end)
end

function XUiPanelRaceChoose:RecordGridSize()
    self._MemberSize = self.GridMember.sizeDelta.y
    self._OptionSize = self.GridOption.sizeDelta.y
end

function XUiPanelRaceChoose:ShowList(isRole, guessId)
    self._CurGuessId = guessId
    self._IsRole = isRole
    self._SortRule = XEnumConst.Race.Sort.Id
    if isRole then
        self:ShowRoleList()
    else
        self:ShowOptionList()
        self.Parent:CloseRoleDetail()
    end

    self.DrdSort:ClearOptions()
    local sortName = isRole and RoleSortName or OptionSortName
    for _, key in ipairs(sortName) do
        local op = Dropdown.OptionData()
        op.text = XUiHelper.GetText(key)
        self.DrdSort.options:Add(op)
    end
    self.DrdSort:RefreshShownValue()
    self.DrdSort.value = XEnumConst.Race.Sort.Id
end

--region 角色列表

function XUiPanelRaceChoose:ShowRoleList()
    self.ListMember.gameObject:SetActiveEx(true)
    self.ListOption.gameObject:SetActiveEx(false)

    if #self._RoleIds == 0 then
        XLog.Error("角色列表为空！")
        return
    end

    if not self._RoleGrids or not self._RoleDatas then
        ---@type XTableRaceCharacter[]
        self._RoleDatas = {}
        ---@type XUiGridRaceRoleOption[]
        self._RoleGrids = {}
        local buttons = {}
        XUiHelper.RefreshCustomizedList(self.GridMember.parent, self.GridMember, #self._RoleIds, function(i, go)
            local grid = require("XUi/XUiRace/Grid/XUiGridRaceRoleOption").New(go, self)
            local cfg = self._Control:GetRaceCharacterById(self._RoleIds[i])
            table.insert(self._RoleGrids, grid)
            table.insert(self._RoleDatas, cfg)
            table.insert(buttons, grid.GridMember)
        end)
        self.PanelMemberGroup:Init(buttons, function(index)
            self:OnSelectMemberTab(index)
        end)
    end

    self:UpdateSortRole()

    local scrollToRole = self._HistoryChooses[self._CurGuessId]
    if not scrollToRole then
        -- 主界面点击角色 ＞ 预测角色
        scrollToRole = self.Parent._SelectRoleId
        if not scrollToRole then
            scrollToRole = self.Parent:GetGuessProjectOption(self._CurGuessId)
        end
    end
    self:RoleSelect(scrollToRole)
end

---按照某种顺序显示角色列表
function XUiPanelRaceChoose:UpdateSortRole(isDrd)
    table.sort(self._RoleDatas, function(a, b)
        local valueA, valueB
        if self._SortRule == Sort.Support then
            valueA = self.Parent:GetVotingRate(a.Id)
            valueB = self.Parent:GetVotingRate(b.Id)
        elseif self._SortRule == Sort.Speed then
            valueA, valueB = a.ShowSpeed, b.ShowSpeed
        elseif self._SortRule == Sort.Acc then
            valueA, valueB = a.ShowAcc, b.ShowAcc
        elseif self._SortRule == Sort.Drift then
            valueA, valueB = a.ShowDrift, b.ShowDrift
        elseif self._SortRule == Sort.Luck then
            valueA, valueB = a.ShowLuck, b.ShowLuck
        end
        if valueA and valueB and valueA ~= valueB then
            return valueA > valueB
        end
        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority
        end
        return a.Id < b.Id
    end)

    -- 刷新角色
    local curIndex
    for i, data in ipairs(self._RoleDatas) do
        self._RoleGrids[i]:SetRoleId(data.Id, self._SortRule)
        if data.Id == self._CurRoleId then
            curIndex = i
        end
    end
    if isDrd and curIndex then
        self.PanelMemberGroup:SelectIndex(curIndex)
    end
end

function XUiPanelRaceChoose:OnSelectMemberTab(i)
    self._CurRoleId = self._RoleDatas[i].Id
    self._HistoryChooses[self._CurGuessId] = self._CurRoleId
    self.Parent:OnClickPredictOption(true, self._CurRoleId)
    --动效
    for i, v in ipairs(self._RoleGrids) do
        v:PlayTween()
    end
end

--endregion

--region 选项列表

function XUiPanelRaceChoose:ShowOptionList()
    self.ListMember.gameObject:SetActiveEx(false)
    self.ListOption.gameObject:SetActiveEx(true)

    self._OptionDatas = {}
    ---@type table<number,XUiComponent.XUiButton>
    self._OptionItemDict = {}
    local buttons = {}
    local guessCfg = self._Control:GetRaceGuessById(self._CurGuessId)
    local options = guessCfg.GuessOptions
    for _, v in ipairs(options) do
        table.insert(self._OptionDatas, v)
    end
    XUiHelper.RefreshCustomizedList(self.GridOption.parent, self.GridOption, #options, function(i, go)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        local btn = uiObject.GridOption
        table.insert(buttons, btn)
        self._OptionItemDict[i] = btn
    end)
    self.PanelProjectGroup:Init(buttons, function(index)
        self:OnSelectOptionTab(index)
    end)

    self:UpdateSortOption()

    local selectIndex
    local history = self._HistoryChooses[self._CurGuessId]
    if history then
        selectIndex = table.indexof(self._OptionDatas, history)
    else
        local mineOption = self.Parent:GetGuessProjectOption(self._CurGuessId)
        selectIndex = XTool.IsNumberValid(mineOption) and table.indexof(self._OptionDatas, mineOption) or 1
    end
    self:OptionSelect(selectIndex)
end

function XUiPanelRaceChoose:UpdateSortOption()
    table.sort(self._OptionDatas, function(aId, bId)
        if self._SortRule == Sort.Support then
            local rateA = self.Parent:GetVotingRate(aId)
            local rateB = self.Parent:GetVotingRate(bId)
            if rateA and rateB and rateA ~= rateB then
                return rateA > rateB
            end
        end
        local priorityA = self._Control:GetRaceGuessParamsById(aId).Priority
        local priorityB = self._Control:GetRaceGuessParamsById(bId).Priority
        if priorityA ~= priorityB then
            return priorityA > priorityB
        end
        return aId < bId
    end)

    for i, optionId in ipairs(self._OptionDatas) do
        local btn = self._OptionItemDict[i]
        btn:SetNameByGroup(0, self._Control:GetGuessParamDesc(optionId))
        local rate = self.Parent:GetVotingRate(optionId)
        local rateStr
        if XTool.IsNumberValid(rate) then
            rateStr = string.format("%s%%", rate)
        else
            rateStr = "-%"
        end
        btn:SetNameByGroup(1, rateStr)
    end
end

function XUiPanelRaceChoose:OnSelectOptionTab(index)
    local id = self._OptionDatas[index]
    self._HistoryChooses[self._CurGuessId] = id
    self.Parent:OnClickPredictOption(false, id)
end

--endregion

--region 列表定位

function XUiPanelRaceChoose:RoleSelect(roleId)
    local index = 1
    if roleId then
        for i, cfg in ipairs(self._RoleDatas) do
            if cfg.Id == roleId then
                index = i
                break
            end
        end
    end

    self.PanelMemberGroup:SelectIndex(index)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.MemberLayout.transform)
    if index == 1 then
        self.ListMember.horizontalNormalizedPosition = 0
        return
    end

    XScheduleManager.ScheduleNextFrame(function()
        local total = self.MemberLayout.transform.rect.width
        local content = self.ListMember.transform.rect.width
        local scrollArea = total - content
        local curPos = (index - 1) * (self._MemberSize + self.MemberLayout.spacing)
        local needOffset = curPos - content
        self.ListMember.horizontalNormalizedPosition = needOffset <= 0 and 0 or needOffset / scrollArea
    end)
end

function XUiPanelRaceChoose:OptionSelect(index)
    self.PanelProjectGroup:SelectIndex(index)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.OptionLayout.transform)
    if not index or index <= 1 then
        self.ListOption.horizontalNormalizedPosition = 0
        return
    end

    XScheduleManager.ScheduleNextFrame(function()
        local total = self.OptionLayout.transform.rect.width
        local content = self.ListOption.transform.rect.width
        local scrollArea = total - content
        local curPos = (index - 1) * (self._OptionSize + self.OptionLayout.spacing)
        local needOffset = curPos - content
        self.ListOption.horizontalNormalizedPosition = needOffset <= 0 and 0 or needOffset / scrollArea
    end)
end

--endregion

return XUiPanelRaceChoose