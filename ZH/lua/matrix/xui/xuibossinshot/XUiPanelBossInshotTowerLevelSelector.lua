local XBossInshotModel = require("XModule/XBossInshot/XBossInshotModel")

local XUiGridBossInshotTowerLevelSelectorBtn = require(
    "XUi/XUiBossInshot/XUiGridBossInshotTowerLevelSelectorBtn")

---@class XUiPanelBossInshotTowerLevelSelector : XUiNode
---@field private _Ctrl XBossInshotControl

local XUiPanelBossInshotTowerLevelSelector = XClass(
    XUiNode, "XUiPanelBossInshotTowerLevelSelector")

local LevelRedPointKey = "XUiPanelBossInshotTowerLevelSelector.LevelRedPoint_"

function XUiPanelBossInshotTowerLevelSelector:OnStart(
    onSelectLevelCb,
    control)

    self._OnSelectLevelCallback = onSelectLevelCb
    self._Ctrl = control
end

-- 已读记录的存档Key
function XUiPanelBossInshotTowerLevelSelector:_GetRedPointKey()
    local activityId = self._Control:GetActivityId()
    return LevelRedPointKey .. activityId .. "_" .. XPlayer.Id
end

function XUiPanelBossInshotTowerLevelSelector:_PopToast()
    local toastData = self._Control:GetAndClearToastData()

    if toastData then
        XLuaUiManager.Open("UiBossInshotToastTower", toastData, function()
            self:Refresh()
            self:FocusOnCurrentLevel()
            self:_TryEnterNextLevel()
        end)
    end
end

function XUiPanelBossInshotTowerLevelSelector:OnEnable()
    XEventManager.AddEventListener(
        XEventId.EVENT_BOSS_INSHOT_TOWER_DATA_NOTIFY,
        self._PopToast,
        self)

    self:Refresh()
    self:_TryEnterNextLevel()

    self:FocusOnCurrentLevel()
    self._FocusOnCurrentLevelSchedule = XScheduleManager.ScheduleNextFrame(function()
        XScheduleManager.UnSchedule(self._FocusOnCurrentLevelSchedule)
        self._FocusOnCurrentLevelSchedule = nil

        self:FocusOnCurrentLevel()
    end)
end

function XUiPanelBossInshotTowerLevelSelector:FocusOnCurrentLevel()
    for _, btn in pairs(self._LevelGridBtns) do
        if btn:GetLevelConf().Id == self._SelectedLevel then
            XUiHelper.ScrollTo(
                self.ScrollRectSelf,
                btn.Transform,
                false)
            break
        end
    end
end

function XUiPanelBossInshotTowerLevelSelector:OnDisable()
    XEventManager.RemoveEventListener(
        XEventId.EVENT_BOSS_INSHOT_TOWER_DATA_NOTIFY,
        self._PopToast,
        self)
    self:_ClearNewLevelRedPoint()
end

-- 清除新关卡蓝点
function XUiPanelBossInshotTowerLevelSelector:_ClearNewLevelRedPoint()
    local redPointKey = self:_GetRedPointKey()
    local redPointCancelledLevel = tonumber(XSaveTool.GetData(redPointKey)) or 0
    local currentLevel = self._Control:GetBossTowerCurrentLevel()

    if currentLevel > redPointCancelledLevel then
        XSaveTool.SaveData(redPointKey, currentLevel)
    end
end

function XUiPanelBossInshotTowerLevelSelector:Refresh(keepLevelSelect)
    if not self._LevelGridBtns then
        self._LevelGridBtns = {}
    end

    local redPointCancelledLevel = tonumber(XSaveTool.GetData(self:_GetRedPointKey()))

    XTool.SetDataForGenericGrid(
        self._LevelGridBtns,
        self._Ctrl:GetConfigBossInshotTowerAllLevels(),
        self.GridTab.gameObject,
        self.PanelContent,
        self,
        XUiGridBossInshotTowerLevelSelectorBtn,
        {
            RedPointCancelledLevel = redPointCancelledLevel or 0,
            OnClickCallback = function(btn) self:OnButtonClicked(btn) end,
            Control = self._Ctrl
        })

    if keepLevelSelect then
        self._SelectedLevel = self._SelectedLevel or self._Ctrl:GetBossTowerCurrentLevel()
    else
        self._SelectedLevel = self._Ctrl:GetBossTowerCurrentLevel()
    end

    if self._OnSelectLevelCallback then
        for _, btn in pairs(self._LevelGridBtns) do
            if btn:GetLevelConf().Id == self._SelectedLevel then
                self._OnSelectLevelCallback(
                    btn:GetLevelConf(),
                    btn:GetBossTowerData())
                break
            end
        end
    end

    self:_RefreshSelectedLevel()
end

function XUiPanelBossInshotTowerLevelSelector:_TryEnterNextLevel()
    if self._Ctrl:HasNeedTryEnterNextLevel() then
        self._Ctrl:TryEnterNextLevel(function(resp)
            if resp.Code ~= XCode.Success then
                XUiManager.TipCode(resp.Code)
                return
            end

            self:Refresh()
            self:_TryEnterNextLevel()
        end)
    else
        self:_PopToast()
    end
end

function XUiPanelBossInshotTowerLevelSelector:_RefreshSelectedLevel()
    local currentLevel = self._Ctrl:GetBossTowerCurrentLevel()

    if self._SelectedLevel > currentLevel then
        self._SelectedLevel = currentLevel
    end

    for _, btn in pairs(self._LevelGridBtns) do
        local levelConf = btn:GetLevelConf()
        if levelConf.Id == self._SelectedLevel then
            btn:SetSelected(true)

            local isChallengeLevel =
                levelConf.Type == XBossInshotModel.TowerLevelType.ChallengeLevel

            self.PanelBgLow.gameObject:SetActiveEx(not isChallengeLevel)
            self.PanelBgHigh.gameObject:SetActiveEx(isChallengeLevel)
        else
            btn:SetSelected(false)
        end
    end
end

function XUiPanelBossInshotTowerLevelSelector:OnButtonClicked(btn)
    local lockReason = btn:GetLockReason()
    local levelConf = btn:GetLevelConf()

    local redPointKey = self:_GetRedPointKey()
    local redPointCancelledLevel = tonumber(XSaveTool.GetData(redPointKey)) or 0
    local currentLevel = self._Control:GetBossTowerCurrentLevel()

    if currentLevel >= levelConf.Id and levelConf.Id > redPointCancelledLevel then
        redPointCancelledLevel = levelConf.Id
        XSaveTool.SaveData(redPointKey, redPointCancelledLevel)

        if self._LevelGridBtns then
            for _, btn in pairs(self._LevelGridBtns) do
                btn:RefreshRedPoint(redPointCancelledLevel)
            end
        end
    end

    if lockReason ~= btn.LockReason.NotLocked then
        if lockReason == btn.LockReason.NotInTime then
            XUiManager.TipText(
                "BossInshotTowerLevelLockedBecauseNotInTime",
                XUiManager.UiTipType.Tip,
                false)
        elseif lockReason == btn.LockReason.NotReach then
            local prevLevelId = levelConf.Id - 1

            local prevLevelConf =
                self._Ctrl:GetConfigBossInshotTowerAllLevels()[prevLevelId]

            XUiManager.TipText(
                "BossInshotTowerLevelLockedBecauseNotReach",
                XUiManager.UiTipType.Tip,
                false,
                prevLevelId,
                prevLevelConf.PassScore)
        else
            XUiManager.TipText(
                "BossInshotTowerLevelLockedBecauseUnknown",
                XUiManager.UiTipType.Tip,
                false)
        end

        return
    end

    self._SelectedLevel = levelConf.Id
    self:_RefreshSelectedLevel()

    if self._OnSelectLevelCallback then
        self._OnSelectLevelCallback(
            btn:GetLevelConf(),
            btn:GetBossTowerData())
    end
end

return XUiPanelBossInshotTowerLevelSelector
