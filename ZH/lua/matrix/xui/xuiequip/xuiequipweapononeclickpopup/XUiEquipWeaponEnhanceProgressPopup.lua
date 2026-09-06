---@class XUiEquipWeaponEnhanceProgressPopup : XLuaUi
---@field _Control XEquipControl
---@field ImgLoading UnityEngine.UI.Image
---@field ImgOK UnityEngine.UI.Image
---@field Effect UnityEngine.RectTransform
--- 武器一键养成进度弹窗：复用角色养成同款 prefab，展示 升级/共鸣/谐振 三单元的强化中→完成动画
local XUiEquipWeaponEnhanceProgressPopup = XLuaUiManager.Register(XLuaUi, "UiEquipWeaponEnhanceProgressPopup")
local XUiGridEnhanceProgressUnit = require("XUi/XUiEquip/XUiEquipEnhanceProgress/XUiGridEnhanceProgressUnit")

local FAKE_WAIT_TIME = 500
local TITLE_DOT_INTERVAL = 400
local TITLE_DOT_MAX = 3

function XUiEquipWeaponEnhanceProgressPopup:OnAwake()
    self.UnitGrids = {}
    self.UnitIndexByKey = {}
    self:RegisterButtonEvent()

    self.PanelUnitItem.gameObject:SetActiveEx(false)
    self.PanelResonateDetail.gameObject:SetActiveEx(false)
    self.PanelMaterialRemain.gameObject:SetActiveEx(false)
end

function XUiEquipWeaponEnhanceProgressPopup:RegisterButtonEvent()
    self.BtnTongRed:AddEventListener(handler(self, self.OnBtnAbortClick))
    self.BtnClose:AddEventListener(handler(self, self.OnBtnFinishClick))
end

--- params = { Result = XWeaponOneClickCultureResult, OnClose = fun, HideAbort = bool }
function XUiEquipWeaponEnhanceProgressPopup:OnStart(params)
    self.Result = params.Result
    self.OnCloseCb = params.OnClose
    self.HideAbort = params.HideAbort
    self.IsFinished = false
    self.CurProcessingKey = nil

    self:BuildUnits()
    self:RefreshTitle(false)
    self:RefreshBottomButton()
    self:StartExecute()
end

function XUiEquipWeaponEnhanceProgressPopup:OnDestroy()
    self:StopTitleAnim()
    self:CancelFakeWait()
    self:StopAllUnitRotate()
    self._Control.OneClickCultureControl:ReleaseWeaponOneClickCulture()
end

function XUiEquipWeaponEnhanceProgressPopup:StopAllUnitRotate()
    for i = 1, #self.UnitGrids do
        self.UnitGrids[i]:StopRotate()
    end
end

function XUiEquipWeaponEnhanceProgressPopup:BuildUnits()
    local units = self._Control.OneClickCultureControl:GetWeaponOneClickCultureUnits(self.Result)
    self.Units = units
    self.UnitIndexByKey = {}
    for i = 1, #units do
        self.UnitIndexByKey[units[i].Key] = i
    end
    XTool.UpdateDynamicItem(self.UnitGrids, units, self.PanelUnitItem, XUiGridEnhanceProgressUnit, self)
end

function XUiEquipWeaponEnhanceProgressPopup:StartExecute()
    self._Control.OneClickCultureControl:StartWeaponOneClickCulture(self.Result, {
        onLevelStart = handler(self, self.OnLevelStart),
        onResonanceStart = handler(self, self.OnResonanceStart),
        onOverrunStart = handler(self, self.OnOverrunStart),
        onAllDone = handler(self, self.OnAllDone),
        onAbort = handler(self, self.OnExecuteAbort),
    })
end

--region 阶段开始回调（节奏控制：置强化中 → 0.5s 假等待 → resume 放行请求）

function XUiEquipWeaponEnhanceProgressPopup:OnLevelStart(resume)
    self:EnterUnitProcessing("Level", resume)
end

function XUiEquipWeaponEnhanceProgressPopup:OnResonanceStart(resume)
    self:EnterUnitProcessing("Resonance", resume)
end

function XUiEquipWeaponEnhanceProgressPopup:OnOverrunStart(resume)
    self:EnterUnitProcessing("Overrun", resume)
end

function XUiEquipWeaponEnhanceProgressPopup:EnterUnitProcessing(key, resume)
    self:MarkCurProcessingDone()

    local index = self.UnitIndexByKey[key]
    if not index then
        resume()
        return
    end
    self.CurProcessingKey = key
    local grid = self.UnitGrids[index]
    grid:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Processing)

    self:CancelFakeWait()
    self.FakeWaitTimer = XScheduleManager.ScheduleOnce(function()
        self.FakeWaitTimer = nil
        resume()
    end, FAKE_WAIT_TIME)
end

function XUiEquipWeaponEnhanceProgressPopup:MarkCurProcessingDone()
    if not self.CurProcessingKey then
        return
    end
    local index = self.UnitIndexByKey[self.CurProcessingKey]
    self.CurProcessingKey = nil
    if index then
        self.UnitGrids[index]:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Done)
    end
end

--endregion

function XUiEquipWeaponEnhanceProgressPopup:OnAllDone()
    self:MarkCurProcessingDone()

    for i = 1, #self.UnitGrids do
        self.UnitGrids[i]:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Done)
    end
    self.IsFinished = true
    self:RefreshTitle(true)
    self:RefreshBottomButton()
end

function XUiEquipWeaponEnhanceProgressPopup:OnExecuteAbort()
    XUiManager.TipText("RoleCultureProgressAbort")
    self:CloseWithResult(false)
end

--region 标题（省略号循环 / 完毕态）

function XUiEquipWeaponEnhanceProgressPopup:RefreshTitle(isDone)
    self:RefreshProgressIcon(isDone)
    if isDone then
        self:StopTitleAnim()
        self.TxtTitle.text = CS.XTextManager.GetText("RoleCultureProgressTitleDone")
        return
    end
    self.TitleBase = CS.XTextManager.GetText("RoleCultureProgressTitle")
    self.TitleDotCount = 0
    self:RefreshTitleDots()
    self.TitleTimer = XScheduleManager.ScheduleForever(function()
        self.TitleDotCount = (self.TitleDotCount + 1) % (TITLE_DOT_MAX + 1)
        self:RefreshTitleDots()
    end, TITLE_DOT_INTERVAL)
end

function XUiEquipWeaponEnhanceProgressPopup:RefreshTitleDots()
    self.TxtTitle.text = self.TitleBase .. string.rep(".", self.TitleDotCount)
end

function XUiEquipWeaponEnhanceProgressPopup:StopTitleAnim()
    if self.TitleTimer then
        XScheduleManager.UnSchedule(self.TitleTimer)
        self.TitleTimer = nil
    end
end

function XUiEquipWeaponEnhanceProgressPopup:RefreshProgressIcon(isDone)
    self.ImgLoading.gameObject:SetActiveEx(not isDone)
    self.ImgOK.gameObject:SetActiveEx(isDone)
    self.Effect.gameObject:SetActiveEx(isDone)
end

--endregion

function XUiEquipWeaponEnhanceProgressPopup:CancelFakeWait()
    if self.FakeWaitTimer then
        XScheduleManager.UnSchedule(self.FakeWaitTimer)
        self.FakeWaitTimer = nil
    end
end

function XUiEquipWeaponEnhanceProgressPopup:RefreshBottomButton()
    self.BtnTongRed.gameObject:SetActiveEx(not self.IsFinished and not self.HideAbort)
    self.BtnClose.gameObject:SetActiveEx(self.IsFinished)
    self.TxtCloseTip.gameObject:SetActiveEx(self.IsFinished)
end

function XUiEquipWeaponEnhanceProgressPopup:OnBtnAbortClick()
    self._Control.OneClickCultureControl:ReleaseWeaponOneClickCulture()
    XUiManager.TipText("RoleCultureProgressAbort")
    self:CloseWithResult(false)
end

function XUiEquipWeaponEnhanceProgressPopup:OnBtnFinishClick()
    self:CloseWithResult(true)
end

function XUiEquipWeaponEnhanceProgressPopup:CloseWithResult(isSuccess)
    if self.OnCloseCb then
        local cb = self.OnCloseCb
        self.OnCloseCb = nil
        cb(isSuccess)
    end
    self:Close()
end

return XUiEquipWeaponEnhanceProgressPopup
