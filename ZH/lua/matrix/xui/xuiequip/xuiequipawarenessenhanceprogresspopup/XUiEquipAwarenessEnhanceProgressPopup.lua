local XUiPanelAwarenessEnhanceProgressStrengthen = require("XUi/XUiEquip/XUiEquipAwarenessEnhanceProgressPopup/XUiPanelAwarenessEnhanceProgressStrengthen")
local XUiPanelAwarenessEnhanceProgressResonance = require("XUi/XUiEquip/XUiEquipAwarenessEnhanceProgressPopup/XUiPanelAwarenessEnhanceProgressResonance")
local XUiPanelAwarenessEnhanceProgressOverclocking = require("XUi/XUiEquip/XUiEquipAwarenessEnhanceProgressPopup/XUiPanelAwarenessEnhanceProgressOverclocking")
local XUiPanelAwarenessEnhanceProgressMaterialRemain = require("XUi/XUiEquip/XUiEquipAwarenessEnhanceProgressPopup/XUiPanelAwarenessEnhanceProgressMaterialRemain")

---@enum XUiEquipAwarenessEnhanceProgressState
local PROCESS_STATE = {
    Progressing = 1,
    Finished = 2,
    Stopped = 3,
}

local AWARENESS_COUNT = XEnumConst.EQUIP.WEAR_AWARENESS_COUNT
local RESONANCE_SLOT_COUNT = XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT
local OVERCLOCK_SLOT_COUNT = XEnumConst.EQUIP.MAX_AWAKE_COUNT

-- 意识一键培养进度弹窗
---@class XUiEquipAwarenessEnhanceProgressPopup : XLuaUi
---@field _Control XEquipControl 装备控制器
---@field BtnStop XUiComponent.XUiButton 停止按钮
---@field BtnComplete XUiComponent.XUiButton 完成按钮
---@field PanelStrengthen UiObject 强化进度节点
---@field PanelResonance UiObject 共鸣进度节点
---@field PanelOverclocking UiObject 超频进度节点
---@field PanelMaterialRemain UiObject 剩余材料节点
---@field TxtTitleProgressing UnityEngine.UI.Text 养成中标题
---@field TxtTitleComplete UnityEngine.UI.Text 已完成标题
---@field ImgLoading UnityEngine.UI.Image 处理中图标
---@field ImgOK UnityEngine.UI.Image 完成图标
---@field UiPanelStrengthen XUiPanelAwarenessEnhanceProgressStrengthen 强化进度面板实例
---@field UiPanelResonance XUiPanelAwarenessEnhanceProgressResonance 共鸣进度面板实例
---@field UiPanelOverclocking XUiPanelAwarenessEnhanceProgressOverclocking 超频进度面板实例
---@field UiPanelMaterialRemain XUiPanelAwarenessEnhanceProgressMaterialRemain 剩余材料面板实例
---@field StrengthenResult table|nil 强化执行结果
---@field ResonanceResult XUiPanelAwarenessOneClickResonanceResult|nil 共鸣执行结果
---@field OverclockingResult XAwarenessOneClickAwakePreviewResult|nil 超频执行结果
---@field CharacterId number 当前操作的角色 Id
---@field EquipIdBySite table<number, number> 确认执行时六个穿戴位对应的意识 Id
---@field RecordTarget XAwarenessOneClickRecordTarget 埋点目标快照
---@field StepList table[] 流程步骤列表
---@field CurStepIndex number 当前流程步骤下标
---@field ProcessState XUiEquipAwarenessEnhanceProgressState 当前流程状态
---@field StepPrepareTimer number|nil 当前步骤启动等待定时器
local XUiEquipAwarenessEnhanceProgressPopup = XLuaUiManager.Register(XLuaUi, "UiEquipAwarenessEnhanceProgressPopup")

-- 步骤先展示处理中状态，再等待固定时长发起请求，保证各养成阶段的展示节奏一致。
local STEP_PREPARE_TIME = 800

-- 初始化组件绑定
function XUiEquipAwarenessEnhanceProgressPopup:OnAwake()
    self:InitComponents()
end

-- 绑定按钮事件
function XUiEquipAwarenessEnhanceProgressPopup:InitComponents()
    self:RegisterClickEvent(self.BtnStop, function() self:OnBtnStopClick() end)
    self:RegisterClickEvent(self.BtnComplete, function() self:OnBtnCompleteClick() end)

    self.UiPanelStrengthen = XUiPanelAwarenessEnhanceProgressStrengthen.New(self.PanelStrengthen, self)
    self.UiPanelResonance = XUiPanelAwarenessEnhanceProgressResonance.New(self.PanelResonance, self)
    self.UiPanelOverclocking = XUiPanelAwarenessEnhanceProgressOverclocking.New(self.PanelOverclocking, self)
    self.UiPanelMaterialRemain = XUiPanelAwarenessEnhanceProgressMaterialRemain.New(self.PanelMaterialRemain, self)
end

-- 接收一键养成执行参数，并启动流程
---@param args XAwarenessOneClickProgressArgs
function XUiEquipAwarenessEnhanceProgressPopup:OnStart(args)
    self.CharacterId = args.CharacterId
    self.EquipIdBySite = args.EquipIdBySite
    self.RecordTarget = args.RecordTarget
    self.StrengthenResult = args.StrengthenResult
    self.ResonanceResult = args.ResonanceResult
    self.OverclockingResult = args.OverclockingResult
    self.StepList = {}
    self.CurStepIndex = 0
    self.ProcessState = PROCESS_STATE.Progressing
    self.StepPrepareTimer = nil

    self:BuildStepList()
    self:RefreshPanels()
    self:StartProcess()
end

--- 收集六个意识位置的最终等级和突破等级。
---@return number[][]
function XUiEquipAwarenessEnhanceProgressPopup:CollectUpgradeFinalValues()
    local finalValues = {}
    for site = 1, AWARENESS_COUNT do
        local equipId = self.EquipIdBySite[site]
        local equip = equipId and self._Control:GetEquip(equipId)
        finalValues[site] = equip and { equip.Level, equip.Breakthrough } or { 0, 0 }
    end
    return finalValues
end

--- 按意识位置及上、下位顺序收集十二个共鸣槽的最终类型和技能 Id。
---@return number[][]
function XUiEquipAwarenessEnhanceProgressPopup:CollectResonanceFinalSkills()
    local finalSkills = {}
    for site = 1, AWARENESS_COUNT do
        local equipId = self.EquipIdBySite[site]
        local equip = equipId and self._Control:GetEquip(equipId)
        for pos = 1, RESONANCE_SLOT_COUNT do
            local resonanceInfo = equip and equip:GetResonanceInfo(pos)
            finalSkills[#finalSkills + 1] = resonanceInfo
                and { resonanceInfo.Type, resonanceInfo.TemplateId }
                or { 0, 0 }
        end
    end
    return finalSkills
end

--- 分别计算上位和下位的已选目标是否全部达成。
---@param targetList XAwarenessOneClickResonanceRecordTargetData[]
---@return number upperTargetReachedFlag
---@return number lowerTargetReachedFlag
function XUiEquipAwarenessEnhanceProgressPopup:CollectResonanceTargetReachedFlags(targetList)
    local resonancePos = XEnumConst.EQUIP.AWARENESS_RESONANCE_POS
    local resonanceControl = self._Control.ResonanceControl
    local isReachedByPos = {}

    for _, targetData in ipairs(targetList) do
        local pos = targetData.Pos
        if isReachedByPos[pos] == nil then
            isReachedByPos[pos] = true
        end

        local equipId = self.EquipIdBySite[targetData.Site]
        local equip = equipId and self._Control:GetEquip(equipId)
        local resonanceInfo = equip and equip:GetResonanceInfo(pos)
        local targetReached = false
        if equip then
            targetReached = resonanceControl:IsAwarenessResonanceTargetReached(
                targetData.Target,
                self.CharacterId,
                resonanceInfo
            )
        end
        isReachedByPos[pos] = isReachedByPos[pos] and targetReached
    end

    local upperTargetReachedFlag = isReachedByPos[resonancePos.UP] and 1 or 0
    local lowerTargetReachedFlag = isReachedByPos[resonancePos.DOWN] and 1 or 0
    return upperTargetReachedFlag, lowerTargetReachedFlag
end

--- 按意识位置及上、下位顺序收集十二个超频槽的最终状态。
---@return number[]
function XUiEquipAwarenessEnhanceProgressPopup:CollectOverclockFinalSlots()
    local finalSlots = {}
    for site = 1, AWARENESS_COUNT do
        local equipId = self.EquipIdBySite[site]
        for pos = 1, OVERCLOCK_SLOT_COUNT do
            local isOverclocked = equipId and XMVCA.XEquip:IsEquipPosAwaken(equipId, pos)
            finalSlots[#finalSlots + 1] = isOverclocked and 1 or 0
        end
    end
    return finalSlots
end

---@return table
function XUiEquipAwarenessEnhanceProgressPopup:CollectUpgradeRecord()
    local target = self.RecordTarget.Upgrade
    if not target.IsSelected then
        return { is_selected = 0 }
    end

    return {
        is_selected = 1,
        target_level = target.TargetLevel,
        target_breakthrough = target.TargetBreakthrough,
        final_values = self:CollectUpgradeFinalValues(),
    }
end

---@return table
function XUiEquipAwarenessEnhanceProgressPopup:CollectResonanceRecord()
    local target = self.RecordTarget.Resonance
    if not target.IsSelected then
        return { is_selected = 0 }
    end

    local upperTargetReachedFlag, lowerTargetReachedFlag =
        self:CollectResonanceTargetReachedFlags(target.TargetList)
    return {
        is_selected = 1,
        upper_target_index = target.UpperTargetIndex,
        lower_target_index = target.LowerTargetIndex,
        times_index = target.TimesIndex,
        selected_slots = target.SelectedSlots,
        final_skills = self:CollectResonanceFinalSkills(),
        total_count = self.UiPanelResonance:GetCompletedResonanceCount(),
        upper_is_target_reached = upperTargetReachedFlag,
        lower_is_target_reached = lowerTargetReachedFlag,
    }
end

---@return table
function XUiEquipAwarenessEnhanceProgressPopup:CollectOverclockRecord()
    if not self.RecordTarget.Overclock.IsSelected then
        return { is_selected = 0 }
    end

    return {
        is_selected = 1,
        final_slots = self:CollectOverclockFinalSlots(),
    }
end

--- 收集本次一键养成埋点数据。
---@param isManualStop boolean
---@return table
function XUiEquipAwarenessEnhanceProgressPopup:CollectCultureRecordData(isManualStop)
    return {
        character_id = self.CharacterId,
        upgrade = self:CollectUpgradeRecord(),
        resonance = self:CollectResonanceRecord(),
        overclock = self:CollectOverclockRecord(),
        is_manual_stop = isManualStop and 1 or 0,
    }
end

--- 上报停止或完成时的一键养成结果。
---@param isManualStop boolean
function XUiEquipAwarenessEnhanceProgressPopup:RecordCultureFinish(isManualStop)
    local recordData = self:CollectCultureRecordData(isManualStop)
    CS.XRecord.Record(recordData, "1000003", "AwarenessOneClickCulture")
end

-- 根据流程步骤刷新面板显隐和内容
function XUiEquipAwarenessEnhanceProgressPopup:RefreshPanels()
    self.UiPanelStrengthen:Close()
    self.UiPanelResonance:Close()
    self.UiPanelOverclocking:Close()
    self.UiPanelMaterialRemain:Close()

    for _, step in ipairs(self.StepList) do
        step.Panel:Open()
        step.Panel:Refresh(step.Result)
    end
end

-- 按固定顺序构建流程步骤，没有结果的阶段自动跳过
function XUiEquipAwarenessEnhanceProgressPopup:BuildStepList()
    if self.StrengthenResult then
        table.insert(self.StepList, {
            Result = self.StrengthenResult,
            Panel = self.UiPanelStrengthen,
        })
    end

    if self.ResonanceResult then
        table.insert(self.StepList, {
            Result = self.ResonanceResult,
            Panel = self.UiPanelResonance,
        })
    end

    if self.OverclockingResult then
        table.insert(self.StepList, {
            Result = self.OverclockingResult,
            Panel = self.UiPanelOverclocking,
        })
    end
end

-- 启动一键养成流程
function XUiEquipAwarenessEnhanceProgressPopup:StartProcess()
    self:RefreshProgressState()
    self:ExecuteNextStep()
end

-- 执行下一个非空流程步骤：展示 Processing 后延迟发起请求，等待期间允许用户中断流程。
function XUiEquipAwarenessEnhanceProgressPopup:ExecuteNextStep()
    if self.ProcessState ~= PROCESS_STATE.Progressing then
        return
    end

    self.CurStepIndex = self.CurStepIndex + 1
    local step = self.StepList[self.CurStepIndex]
    if not step then
        self:FinishProcess()
        return
    end

    step.Panel:PrepareExecute()
    self.StepPrepareTimer = XScheduleManager.ScheduleOnce(function()
        self.StepPrepareTimer = nil
        self:ExecuteStep(step)
    end, STEP_PREPARE_TIME)
end

-- 延迟结束后执行当前步骤；具体请求和结果处理由各步骤面板负责。
---@param step table 当前流程步骤
function XUiEquipAwarenessEnhanceProgressPopup:ExecuteStep(step)
    step.Panel:Execute(step.Result, {
        onSuccess = function()
            self:OnStepFinished()
        end,
        onFail = function()
            self:OnStepFailed()
        end,
    })
end

-- 取消尚未发起请求的步骤启动等待，避免流程中断后仍执行延迟回调。
function XUiEquipAwarenessEnhanceProgressPopup:CancelStepPrepare()
    if self.StepPrepareTimer then
        XScheduleManager.UnSchedule(self.StepPrepareTimer)
        self.StepPrepareTimer = nil
    end
end

-- 当前步骤完成后推进到下一步
function XUiEquipAwarenessEnhanceProgressPopup:OnStepFinished()
    if self.ProcessState ~= PROCESS_STATE.Progressing then
        return
    end

    self:ExecuteNextStep()
end

-- 当前步骤失败后中止流程
function XUiEquipAwarenessEnhanceProgressPopup:OnStepFailed()
    self.ProcessState = PROCESS_STATE.Stopped
    XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_AWARENESS_ENHANCE_REFRESH)
    self:Close()
end

-- 完成全部流程
function XUiEquipAwarenessEnhanceProgressPopup:FinishProcess()
    self.ProcessState = PROCESS_STATE.Finished
    self:RecordCultureFinish(false)
    self:RefreshMaterialRemainPanel()
    self:RefreshProgressState()
end

-- 根据共鸣执行后的剩余材料刷新完成态面板
function XUiEquipAwarenessEnhanceProgressPopup:RefreshMaterialRemainPanel()
    local remainingMaterialList = self.UiPanelResonance:GetRemainingMaterialList()
    local hasRemainingMaterial = #remainingMaterialList > 0
    if not hasRemainingMaterial then
        self.UiPanelMaterialRemain:Close()
        return
    end

    self.UiPanelMaterialRemain:Open()
    self.UiPanelMaterialRemain:Refresh(remainingMaterialList)
end

-- 刷新养成中和已完成状态
function XUiEquipAwarenessEnhanceProgressPopup:RefreshProgressState()
    local isProgressing = self.ProcessState == PROCESS_STATE.Progressing
    local isFinished = self.ProcessState == PROCESS_STATE.Finished
    self.TxtTitleProgressing.gameObject:SetActiveEx(isProgressing)
    self.ImgLoading.gameObject:SetActiveEx(isProgressing)
    self.TxtTitleComplete.gameObject:SetActiveEx(isFinished)
    self.ImgOK.gameObject:SetActiveEx(isFinished)
    self.BtnStop.gameObject:SetActiveEx(isProgressing)
    self.BtnComplete.gameObject:SetActiveEx(isFinished)
end

-- 中断当前子流程并通知主界面刷新
---@return boolean isStopped 是否成功从执行中切换到停止状态
function XUiEquipAwarenessEnhanceProgressPopup:StopProcess()
    if self.ProcessState ~= PROCESS_STATE.Progressing then
        return false
    end

    self.ProcessState = PROCESS_STATE.Stopped
    self:CancelStepPrepare()
    local step = self.StepList[self.CurStepIndex]
    if step then
        step.Panel:Cancel()
    end

    XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_AWARENESS_ENHANCE_REFRESH)
    return true
end

-- 运行中关闭界面时中断养成流程
function XUiEquipAwarenessEnhanceProgressPopup:OnDestroy()
    self:StopProcess()
end

-- 点击停止按钮
function XUiEquipAwarenessEnhanceProgressPopup:OnBtnStopClick()
    if not self:StopProcess() then
        return
    end

    self:RecordCultureFinish(true)
    self:Close()
    XUiManager.TipText("AwarenessOneClickProgressAbort")
end

-- 点击完成按钮
function XUiEquipAwarenessEnhanceProgressPopup:OnBtnCompleteClick()
    XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_AWARENESS_ENHANCE_REFRESH)
    self:Close()
end

return XUiEquipAwarenessEnhanceProgressPopup
