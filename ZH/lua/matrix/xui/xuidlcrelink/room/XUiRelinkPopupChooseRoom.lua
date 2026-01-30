---@class XUiRelinkPopupChooseRoom : XLuaUi
---@field private _Control XDlcRelinkControl
---@field LevelIdDropdown UnityEngine.UI.Dropdown
local XUiRelinkPopupChooseRoom = XLuaUiManager.Register(XLuaUi, "UiRelinkPopupChooseRoom")

function XUiRelinkPopupChooseRoom:OnAwake()
    self:RegisterUiEvents()
    self.LevelIdDropdown.onValueChanged:AddListener(function(value)
        local levelId = self.LevelIdDropdown.options[value].text
        self._Control:SetCurrentLevelId(tonumber(levelId))
    end)
end

function XUiRelinkPopupChooseRoom:OnEnable()
    self:RefreshButtonState()
    self.LevelIdDropdown.value = 0
end

function XUiRelinkPopupChooseRoom:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_ROOM_MATCH,
        XEventId.EVENT_DLC_ROOM_CANCEL_MATCH,
    }
end

function XUiRelinkPopupChooseRoom:OnNotify(event, ...)
    if event == XEventId.EVENT_DLC_ROOM_MATCH then
        self:OnMatching(0)
    elseif event == XEventId.EVENT_DLC_ROOM_CANCEL_MATCH then
        self:OnCancelMatching()
    end
end

function XUiRelinkPopupChooseRoom:OnDisable()
    self:RemoveMatchingTimer()
end

function XUiRelinkPopupChooseRoom:RefreshButtonState()
    local isMatching = XMVCA.XDlcRoom:IsMatching()
    self.BtnAddRoom.gameObject:SetActiveEx(not isMatching)
    self.BtnMatching.gameObject:SetActiveEx(isMatching)
end

function XUiRelinkPopupChooseRoom:RefreshBtnMatchingTimer(time)
    local timeStr = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    self.BtnMatching:SetNameByGroup(1, timeStr)
end

function XUiRelinkPopupChooseRoom:OnCancelMatching()
    self:RemoveMatchingTimer()
    self:RefreshButtonState()
end

function XUiRelinkPopupChooseRoom:OnMatching(startTime)
    self:RegisterMatchingTimer(startTime)
    self:RefreshButtonState()
end

function XUiRelinkPopupChooseRoom:RegisterMatchingTimer(time)
    self:RemoveMatchingTimer()
    self:RefreshBtnMatchingTimer(time)
    self.MatchingTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:RemoveMatchingTimer()
            return
        end
        time = time + 1
        self:RefreshBtnMatchingTimer(time)
    end, XScheduleManager.SECOND)
end

function XUiRelinkPopupChooseRoom:RemoveMatchingTimer()
    if self.MatchingTimer then
        XScheduleManager.UnSchedule(self.MatchingTimer)
        self.MatchingTimer = nil
    end
end

function XUiRelinkPopupChooseRoom:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnAddRoom, self.OnBtnAddRoomClick)
    self:RegisterClickEvent(self.BtnMatching, self.OnBtnMatchingClick)
    self:RegisterClickEvent(self.BtnBuildRoom, self.OnBtnBuildRoomClick)
end

function XUiRelinkPopupChooseRoom:OnBtnCloseClick()
    if XMVCA.XDlcRoom:IsMatching() then
        XUiManager.TipCode(XCode.MatchPlayerIsMatching)
        return
    end

    self:Close()
end

function XUiRelinkPopupChooseRoom:OnBtnAddRoomClick()
    local currentWorldId, currentLevelId = self._Control:GetCurrentWorldIdAndLevelId()
    if XTool.IsNumberValid(currentWorldId) and XTool.IsNumberValid(currentLevelId) then
        XMVCA.XDlcRoom:ReqMatch(currentWorldId, currentLevelId, true)
    end
end

function XUiRelinkPopupChooseRoom:OnBtnMatchingClick()
    XMVCA.XDlcRoom:ReqCancelMatch()
end

function XUiRelinkPopupChooseRoom:OnBtnBuildRoomClick()
    if XMVCA.XDlcRoom:IsMatching() then
        XUiManager.TipCode(XCode.MatchPlayerIsMatching)
        return
    end

    local worldId, levelId = self._Control:GetCurrentWorldIdAndLevelId()
    if XTool.IsNumberValid(worldId) and XTool.IsNumberValid(levelId) then
        XMVCA.XDlcRoom:CreateRoom(worldId, levelId, 1, true)
    end
end

return XUiRelinkPopupChooseRoom
