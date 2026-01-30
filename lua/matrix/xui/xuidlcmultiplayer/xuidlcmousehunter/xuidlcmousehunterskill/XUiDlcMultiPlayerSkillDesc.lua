local XUiDlcMultiPlayerSkillDescGrid = require(
    "XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMouseHunterSkill/XUiDlcMultiPlayerSkillDescGrid")
---@class XUiDlcMultiPlayerSkillDesc : XUiNode
---@field private _Control XDlcMultiMouseHunterControl
---@field Parent XUiDlcMultiPlayerSkill
local XUiDlcMultiPlayerSkillDesc = XClass(XUiNode, "XUiDlcMultiPlayerSkillDesc")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMouseHunterCamp
-- 每个阵营必须选择的技能数量
local MAX_SKILL_COUNT = 2


function XUiDlcMultiPlayerSkillDesc:OnStart(camp)
    self._CurCamp = camp
    self.CurStatus = self.Parent.ViewStatus.Normal
    self:InitCampData()
    self:InitView()
    self:RegisterUiEvents()
end

function XUiDlcMultiPlayerSkillDesc:InitCampData()
    local _, skillData = self._Control:TryGetSkillData()
    local activityConfig = self._Control:GetDlcMultiplayerActivityConfig()

    local isCat = self._CurCamp == CampEnum.Cat
    local serverSkillIds = isCat and skillData.SelectCatSkillIds or skillData.SelectMouseSkillIds

    -- 初始化选择的技能列表
    self.SelectSkillIdList = {}
    local skillCount = #serverSkillIds
    if skillCount > MAX_SKILL_COUNT then
        XLog.Error("XUiDlcMultiPlayerSkillDesc:InitCampData error: select skill count exceed max limit, camp:" ..
            tostring(self._CurCamp))
        skillCount = MAX_SKILL_COUNT
    end
    for i = 1, skillCount do
        self.SelectSkillIdList[i] = serverSkillIds[i]
    end

    self._SkillGroupConfig = self._Control:GetDlcMultiplayerSkillGroupConfigById(isCat and activityConfig.CatSkillGroup or
        activityConfig.MouseSkillGroup)
    self.TxtTitle.text = XUiHelper.GetText(isCat and "MultiMouseHunterSkillCatTitle" or "MultiMouseHunterSkillMouseTitle")
    self._CurSelectSkillId = self.SelectSkillIdList[1] or -1
end

function XUiDlcMultiPlayerSkillDesc:RegisterUiEvents()

end

function XUiDlcMultiPlayerSkillDesc:InitView()
    self.SkillBtns = {}
    self._SkillGridList = {}
    for index, skillId in ipairs(self._SkillGroupConfig.SkillIdList) do
        local grid = self._SkillGridList[index]
        if not grid then
            local go = index == 1 and self.SkillGrid or
                XUiHelper.Instantiate(self.SkillGrid.gameObject, self.SkillContent.transform)
            grid = XUiDlcMultiPlayerSkillDescGrid.New(go, self, handler(self, self.OnClickChangeSkill))
            table.insert(self._SkillGridList, grid)
        end
        grid:Open()
        grid:Refresh(skillId)
        grid:SetUsing(table.contains(self.SelectSkillIdList, skillId))

        table.insert(self.SkillBtns, grid.BtnBuffIcon)
    end

    self.SkillContent:Init(self.SkillBtns, function(index)
        local grid = self._SkillGridList[index]
        if self.CurStatus == self.Parent.ViewStatus.ChangeSkill then
            local count = table.findElementCout(self.SelectSkillIdList, 0)
            grid:OnBtnBuffIconClick()
            grid.BtnBuffIcon:SetButtonState(CS.UiButtonState.Normal)
        
            if count > 0 then
                self:SelectSkillGrid(index)
                self:RefreshSkillDetail(grid:GetSkillConfig())
            end
        end
        if self.CurStatus ~= self.Parent.ViewStatus.ChangeSkill then
            self:SelectSkillGrid(index)
            self:RefreshSkillDetail(grid:GetSkillConfig())
        end

        self:Refresh()
    end)
    local tagetIndex = 1
    if self._CurSelectSkillId ~= -1 then
        for index, skillId in ipairs(self._SkillGroupConfig.SkillIdList) do
            local isSelect = skillId == self._CurSelectSkillId
            if isSelect then
                tagetIndex = index
                break
            end
        end
    end

    self.SkillContent:SelectIndex(tagetIndex)
end

function XUiDlcMultiPlayerSkillDesc:SelectSkillGrid(clickindex)
    local skillId = self._SkillGroupConfig.SkillIdList[clickindex]
    self._CurSelectSkillId = skillId
    -- local grid = self._SkillGridList[clickindex]
    -- 检查技能解锁条件
    -- local skillConfig = grid:GetSkillConfig()
    if not self._Control:CheckSkillUnlock(skillId) then
        -- XUiManager.TipMsg(XConditionManager.GetConditionDescById(skillConfig.Condition))
        return
    end
    -- 移除新技能标记
    self._Control:RemoveNewSkill(skillId)
end

function XUiDlcMultiPlayerSkillDesc:OnClickChangeSkill(grid)
    local skillId = grid:GetSkillId()
    local isContain, index = table.contains(self.SelectSkillIdList, skillId)
    if isContain then
        self.SelectSkillIdList[index] = 0
        grid:SetUsing(false)
    else
        local iszero, zeroIndex = table.contains(self.SelectSkillIdList, 0)
        if iszero then
            self.SelectSkillIdList[zeroIndex] = skillId
            grid:SetUsing(true, zeroIndex)
        end
    end
end

function XUiDlcMultiPlayerSkillDesc:RefreshSkillDetail(skillConfig)
    -- 刷新技能描述和基本信息
    self.TxtSkillName.text = skillConfig.Name
    self.TxtDes.text = skillConfig.Des
    local cdDesFormat = self._Control:GetDlcMultiplayerConfigConfigByKey("SkillCdDes").Values[1]
    self.TxtCd.text = string.format(cdDesFormat, skillConfig.SkillCd)
    local timesDesFormat = self._Control:GetDlcMultiplayerConfigConfigByKey("SkillUseTimesDes").Values[1]
    self.TxtTimes.text = string.format(timesDesFormat, skillConfig.SkillCnt)
end

function XUiDlcMultiPlayerSkillDesc:OnClickSKillChange()
    self:SetStatus(self.Parent.ViewStatus.ChangeSkill)
    self.Parent:SetRejectOther(self._CurCamp)
end

function XUiDlcMultiPlayerSkillDesc:SetStatus(newStatus)
    self.CurStatus = newStatus
    self:Refresh()
    local refreshState = CS.UiButtonState.Select
    if self.CurStatus == self.Parent.ViewStatus.ChangeSkill then
        refreshState = CS.UiButtonState.Normal
    end
    for index, skillId in ipairs(self._SkillGroupConfig.SkillIdList) do
        local isSelect = skillId == self._CurSelectSkillId
        if isSelect then
            local grid = self._SkillGridList[index]
            grid.BtnBuffIcon:SetButtonState(refreshState)
            break
        end
    end
    for _, grid in ipairs(self._SkillGridList) do
        grid:SetNormalState()
    end
end

function XUiDlcMultiPlayerSkillDesc:Refresh()
    if self.Parent == nil then
        return
    end
    if self.CurStatus == self.Parent.ViewStatus.Normal then
        self:RefreshNormal()
    elseif self.CurStatus == self.Parent.ViewStatus.ChangeSkill then
        self:RefreshChangeSkill()
    end
end

function XUiDlcMultiPlayerSkillDesc:RefreshNormal()
    self.TxtDesChange.gameObject:SetActiveEx(false)
    self.TxtNum.text = (MAX_SKILL_COUNT - table.findElementCout(self.SelectSkillIdList, 0)) .. "/" .. MAX_SKILL_COUNT
    for index, grid in ipairs(self._SkillGridList) do
        local isContain = table.contains(self.SelectSkillIdList, grid:GetSkillId())
        grid:SetChangeState(isContain)
        local skillId = self._SkillGroupConfig.SkillIdList[index]
        grid:SetMask(not self._Control:CheckSkillUnlock(skillId))
    end
end

function XUiDlcMultiPlayerSkillDesc:RefreshChangeSkill()
    self.TxtDesChange.gameObject:SetActiveEx(true)
    local curSkillCount = (MAX_SKILL_COUNT - table.findElementCout(self.SelectSkillIdList, 0))
    local curSkillCountStr = tostring(curSkillCount)
    if curSkillCount < MAX_SKILL_COUNT then
        curSkillCountStr = string.format("<color=#FF0000>%s</color>", curSkillCountStr)
    end
    self.TxtNum.text = curSkillCountStr .. "/" .. MAX_SKILL_COUNT
    local lockExit = table.contains(self.SelectSkillIdList, 0)
    self.Parent:SetCommitStatus()

    for _, grid in ipairs(self._SkillGridList) do
        local isContain = table.contains(self.SelectSkillIdList, grid:GetSkillId())
        grid:SetChangeState(isContain)

        if lockExit then
            grid:SetMask(false)
        else
            grid:SetMask(not isContain)
        end
    end
end

function XUiDlcMultiPlayerSkillDesc:GetSelectSkillIdList()
    return XTool.Clone(self.SelectSkillIdList)
end

function XUiDlcMultiPlayerSkillDesc:ShowChangeAnim()

    for _, grid in ipairs(self._SkillGridList) do
        grid:SetChangeSkillState()
    end
end

return XUiDlcMultiPlayerSkillDesc
