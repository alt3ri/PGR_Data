
---@class XUiBigWorldPopupAdvance : XBigWorldUi
---@field _Control XBigWorldCourseControl
local XUiBigWorldPopupAdvance = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupAdvance")

local XUiGridBWQuestSmall = require("XUi/XUiBigWorld/XQuest/Grid/XUiGridBWQuestSmall")
local DlcEventId = XMVCA.XBigWorldService.DlcEventId

function XUiBigWorldPopupAdvance:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldPopupAdvance:OnStart(skipIds, customParamId, occupyQuestIds)
    self._IsOccupyMode = not XTool.IsTableEmpty(occupyQuestIds)
    if self._IsOccupyMode then
        self._OccupyQuestIds = occupyQuestIds
        self:SetText(self.TxtTitle, XMVCA.XBigWorldService:GetText("BigWorldPrecedenceTitle"))
        self:SetText(self.TxtSubtitle, XMVCA.XBigWorldService:GetText("BigworldPrecedenceSubtitle"))
        self:SetText(self.TxtDetail, XUiHelper.ReplaceTextNewLine(XMVCA.XBigWorldService:GetText("BigWorldPrecedenceDetail")))
        self.PanelBtn.gameObject:SetActiveEx(false)
    else
        self._SkipIds = self:SortSkipIds(skipIds)
        self._CustomParamId = customParamId
    end
    self:SetupDynamicTable()
end

function XUiBigWorldPopupAdvance:InitUi()
    self:SetText(self.TxtTitle, XMVCA.XBigWorldService:GetText("EarlyAccessTitle"))
    self:SetText(self.TxtSubtitle, XMVCA.XBigWorldService:GetText("EarlyAccessSubtitle"))
    self:SetText(self.TxtDetail, XUiHelper.ReplaceTextNewLine(XMVCA.XBigWorldService:GetText("EarlyAccessContent")))

    self.GridTask.gameObject:SetActiveEx(false)

    self._DynamicTable = XUiHelper.DynamicTableNormal(self, self.ListTask, XUiGridBWQuestSmall)
end

function XUiBigWorldPopupAdvance:InitCb()
    self.BtnCancel:AddEventListener(handler(self, self.OnBtnCancelClick))
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnCancelClick))
    self.BtnYes:AddEventListener(handler(self, self.OnBtnYesClick))
end

function XUiBigWorldPopupAdvance:OnBtnYesClick()
    local paramId = self._CustomParamId
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():RequestBigWorldMarkParam(paramId, false, function()
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_ADVANCE_UPDATE, true)
        self:Close()
        XMVCA.XBigWorldUI:SafeClose("UiBigWorldProcess")
    end)
end

function XUiBigWorldPopupAdvance:OnBtnCancelClick()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_ADVANCE_UPDATE, false)
    self:Close()
end

function XUiBigWorldPopupAdvance:SetupDynamicTable()
    local dataSource = self._IsOccupyMode and self._OccupyQuestIds or self._SkipIds
    self._DynamicTable:SetDataSource(dataSource)
    self._DynamicTable:ReloadDataSync()
end

---@param grid XUiGridBWQuestSmall
function XUiBigWorldPopupAdvance:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self._IsOccupyMode then
            grid:Update(self._OccupyQuestIds[index])
            grid:SetClickCallback(handler(self, self.OnOccupyQuestClick))
        else
            grid:SetClickCallback(nil)
            grid:RefreshSkip(self._SkipIds[index])
        end
    end
end

function XUiBigWorldPopupAdvance:OnOccupyQuestClick(questId)
    XMVCA.XBigWorldUI:PopToAndOpen("UiBigWorldTaskMain")
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_REFRESH_MAIN_SELECT, questId)
end

function XUiBigWorldPopupAdvance:SetText(component, value)
    if string.IsNilOrEmpty(value) then
        component.gameObject:SetActiveEx(false)
    else
        component.text = value
        component.gameObject:SetActiveEx(true)
    end
end

function XUiBigWorldPopupAdvance:SortSkipIds(skipIds)
    if XTool.IsTableEmpty(skipIds) then
        return skipIds
    end
    table.sort(skipIds, function(a, b)
        local unlockA = XMVCA.XBigWorldSkipFunction:CheckUnlock(a)
        local unlockB = XMVCA.XBigWorldSkipFunction:CheckUnlock(b)
        if unlockA ~= unlockB then
            return unlockA
        end
        local finishA = XMVCA.XBigWorldSkipFunction:CheckFinish(a)
        local finishB = XMVCA.XBigWorldSkipFunction:CheckFinish(b)

        if finishA ~= finishB then
            return finishB
        end
        return a < b
    end)
    return skipIds
end