---@class XUiEquipEnhanceProgressPopup : XLuaUi
---@field _Control XCharacterControl
---@field ImgLoading UnityEngine.UI.Image
---@field ImgOK UnityEngine.UI.Image
---@field Effect UnityEngine.RectTransform
local XUiEquipEnhanceProgressPopup = XLuaUiManager.Register(XLuaUi, "UiEquipEnhanceProgressPopup")
local XUiGridEnhanceProgressUnit = require("XUi/XUiEquip/XUiEquipEnhanceProgress/XUiGridEnhanceProgressUnit")

local FAKE_WAIT_TIME = 500
local TITLE_DOT_INTERVAL = 400
local TITLE_DOT_MAX = 3

function XUiEquipEnhanceProgressPopup:OnAwake()
    self.UnitGrids = {}
    self.UnitIndexByKey = {}
    self:RegisterButtonEvent()

    self.PanelUnitItem.gameObject:SetActiveEx(false)
    self.PanelResonateDetail.gameObject:SetActiveEx(false)
    self.PanelMaterialRemain.gameObject:SetActiveEx(false)
end

function XUiEquipEnhanceProgressPopup:RegisterButtonEvent()
    self.BtnTongRed:AddEventListener(handler(self, self.OnBtnAbortClick))
    self.BtnClose:AddEventListener(handler(self, self.OnBtnFinishClick))
end

--- params = { Pd = XRoleCultureResult, OnClose = fun, IsSpecialTraining = bool, HideAbort = bool }
function XUiEquipEnhanceProgressPopup:OnStart(params)
    self.Pd = params.Pd
    self.OnCloseCb = params.OnClose
    self.IsSpecialTraining = params.IsSpecialTraining
    self.HideAbort = params.HideAbort
    self.IsFinished = false
    self.CurProcessingKey = nil

    self:BuildUnits()
    self:RefreshTitle(false)
    self:RefreshBottomButton()
    self:StartExecute()
end

function XUiEquipEnhanceProgressPopup:OnDestroy()
    self:StopTitleAnim()
    self:CancelFakeWait()
    self:StopAllUnitRotate()
    self._Control:ReleaseRoleCultureExecute()
end

function XUiEquipEnhanceProgressPopup:StopAllUnitRotate()
    for i = 1, #self.UnitGrids do
        self.UnitGrids[i]:StopRotate()
    end
end

function XUiEquipEnhanceProgressPopup:BuildUnits()
    local units
    if self.IsSpecialTraining then
        units = self._Control:GetRoleCultureSpecialTrainingUnits(self.Pd.CharacterId)
    else
        units = self._Control:GetRoleCultureUnits(self.Pd)
    end
    self.Units = units
    self.UnitIndexByKey = {}
    for i = 1, #units do
        self.UnitIndexByKey[units[i].Key] = i
    end
    XTool.UpdateDynamicItem(self.UnitGrids, units, self.PanelUnitItem, XUiGridEnhanceProgressUnit, self)
end

function XUiEquipEnhanceProgressPopup:StartExecute()
    if self.IsSpecialTraining then
        -- 特训道具：三模块同时置强化中，请求成功后由 onAllDone 一起置完成
        for i = 1, #self.UnitGrids do
            self.UnitGrids[i]:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Processing)
        end
        self._Control:RunRoleCultureSpecialTraining(self.Pd.CharacterId, {
            onAllDone = handler(self, self.OnAllDone),
            onAbort = handler(self, self.OnExecuteAbort),
        })
        return
    end

    self._Control:RunRoleCultureExecute(self.Pd, {
        onLevelStart = handler(self, self.OnLevelStart),
        onGradeStart = handler(self, self.OnGradeStart),
        onSkillStart = handler(self, self.OnSkillStart),
        onAllDone = handler(self, self.OnAllDone),
        onAbort = handler(self, self.OnExecuteAbort),
    })
end

--region 阶段开始回调（节奏控制：置强化中 → 0.5s 假等待 → resume 放行请求）

function XUiEquipEnhanceProgressPopup:OnLevelStart(resume)
    self:EnterUnitProcessing("Level", resume)
end

function XUiEquipEnhanceProgressPopup:OnGradeStart(resume)
    self:EnterUnitProcessing("Grade", resume)
end

function XUiEquipEnhanceProgressPopup:OnSkillStart(resume)
    self:EnterUnitProcessing("Skill", resume)
end

function XUiEquipEnhanceProgressPopup:EnterUnitProcessing(key, resume)
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

function XUiEquipEnhanceProgressPopup:MarkCurProcessingDone()
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

function XUiEquipEnhanceProgressPopup:OnAllDone()
    self:MarkCurProcessingDone()

    for i = 1, #self.UnitGrids do
        self.UnitGrids[i]:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Done)
    end
    self.IsFinished = true
    self:RefreshTitle(true)
    self:RefreshBottomButton()
end

function XUiEquipEnhanceProgressPopup:OnExecuteAbort()
    XUiManager.TipText("RoleCultureProgressAbort")
    self:CloseWithResult(false)
end

--region 标题（省略号循环 / 完毕态）

function XUiEquipEnhanceProgressPopup:RefreshTitle(isDone)
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

function XUiEquipEnhanceProgressPopup:RefreshTitleDots()
    self.TxtTitle.text = self.TitleBase .. string.rep(".", self.TitleDotCount)
end

function XUiEquipEnhanceProgressPopup:StopTitleAnim()
    if self.TitleTimer then
        XScheduleManager.UnSchedule(self.TitleTimer)
        self.TitleTimer = nil
    end
end

function XUiEquipEnhanceProgressPopup:RefreshProgressIcon(isDone)
    self.ImgLoading.gameObject:SetActiveEx(not isDone)
    self.ImgOK.gameObject:SetActiveEx(isDone)
    self.Effect.gameObject:SetActiveEx(isDone)
end

--endregion

function XUiEquipEnhanceProgressPopup:CancelFakeWait()
    if self.FakeWaitTimer then
        XScheduleManager.UnSchedule(self.FakeWaitTimer)
        self.FakeWaitTimer = nil
    end
end

function XUiEquipEnhanceProgressPopup:RefreshBottomButton()
    self.BtnTongRed.gameObject:SetActiveEx(not self.IsFinished and not self.HideAbort)
    self.BtnClose.gameObject:SetActiveEx(self.IsFinished)
    self.TxtCloseTip.gameObject:SetActiveEx(self.IsFinished)
end

function XUiEquipEnhanceProgressPopup:OnBtnAbortClick()
    self._Control:ReleaseRoleCultureExecute()
    XUiManager.TipText("RoleCultureProgressAbort")
    self:CloseWithResult(false)
end

function XUiEquipEnhanceProgressPopup:OnBtnFinishClick()
    self:CloseWithResult(true)
end

function XUiEquipEnhanceProgressPopup:CloseWithResult(isSuccess)
    self:Close()
    if self.OnCloseCb then
        local cb = self.OnCloseCb
        self.OnCloseCb = nil
        cb(isSuccess)
    end
end

return XUiEquipEnhanceProgressPopup
