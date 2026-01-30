local CSDGTweeningEase_Linear = CS.DG.Tweening.Ease.Linear
local Vector3 = CS.UnityEngine.Vector3

local tableInsert = table.insert

---@class XUiSlotMachinePanel
local XUiSlotMachinePanel = XClass(nil, "XUiSlotMachinePanel")

local ROLL_ONE_CIRCLE_TIME = 0.5 -- 匀速滚动一圈时间
local ICON_LAST_ROLL_TIME = 0.8
local ICON_LIST01_ROLL_COUNT = 4
local ICON_LIST02_ROLL_COUNT = 6
local ICON_LIST03_ROLL_COUNT = 8

---@param rootUi XUiSlotMachine
function XUiSlotMachinePanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClick)
    self:SetBtnSkipActive(false)
end

function XUiSlotMachinePanel:Init()
    self.TweenSequencePool1 = nil
    self.TweenSequencePool2 = nil
    self.TweenSequencePool3 = nil
    self.IsSkipAnim = false
end

function XUiSlotMachinePanel:Refresh(machineId)
    self.CurMachineEntity = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityById(machineId)
    self.MachineState = XDataCenter.SlotMachineManager.CheckSlotMachineState(machineId)

    if self.MachineState == XSlotMachineConfigs.SlotMachineState.Locked then
        self.SlotmachineLock:SetRawImage(self.CurMachineEntity:GetMachineLockImage())
        self.SlotmachineLock.gameObject:SetActiveEx(true)
        self.SlotmachineBg.gameObject:SetActiveEx(false)
    else
        self.SlotmachineBg:SetRawImage(self.CurMachineEntity:GetMachineImage())
        self.SlotmachineBg.gameObject:SetActiveEx(true)
        self.SlotmachineLock.gameObject:SetActiveEx(false)
    end
end


function XUiSlotMachinePanel:RollUniformSpeed(gameObject, rollCount, cb)
    gameObject.transform.localPosition = Vector3(gameObject.transform.localPosition.x, 0, 0)
    gameObject.transform:DOLocalMoveY(-self.MaxIconListHeight, ROLL_ONE_CIRCLE_TIME):SetLoops(rollCount):SetEase(CSDGTweeningEase_Linear):OnComplete(function()
        if cb then cb() end
    end)
end

function XUiSlotMachinePanel:GetReverseTable(arr) -- 翻转数组（只能是数组）
    local tmp = {}
    for i = #arr, 1, -1 do
        tableInsert(tmp, arr[i])
    end

    return tmp
end

function XUiSlotMachinePanel:KillSequence()
    if self.TweenSequencePool1 then
        self.TweenSequencePool1:Kill()
        self.TweenSequencePool1 = nil
    end
    if self.TweenSequencePool2 then
        self.TweenSequencePool2:Kill()
        self.TweenSequencePool2 = nil
    end
    if self.TweenSequencePool3 then
        self.TweenSequencePool3:Kill()
        self.TweenSequencePool3 = nil
    end
end

function XUiSlotMachinePanel:AsynWaitTime(second, cb)
    if self.IsSkipAnim then
        if cb then cb() end
        return
    end
    self.WaitCb = cb
    self.WaitTime = XScheduleManager.ScheduleOnce(function()
        local tempCb = self.WaitCb
        self.WaitCb = nil
        self.WaitTime = nil
        if tempCb then
            tempCb()
        end
    end, second * XScheduleManager.SECOND)
end

function XUiSlotMachinePanel:KillWaitTime()
    if self.WaitTime then
        XScheduleManager.UnSchedule(self.WaitTime)
        self.WaitTime = nil
    end
    local tempCb = self.WaitCb
    self.WaitCb = nil
    if tempCb then
        tempCb()
    end
end

function XUiSlotMachinePanel:OnBtnSkipClick()
    if self.IsSkipAnim then
        return
    end
    self:SetIsSkipActive(true)
    self:SetBtnSkipActive(false)
    self:KillSequence()
    self:KillWaitTime()
    self.RootUi:StopAnimation("SlotmachineEnable2")
end

function XUiSlotMachinePanel:SetBtnSkipActive(value)
    self.BtnSkip.gameObject:SetActiveEx(value)
end

function XUiSlotMachinePanel:SetIsSkipActive(value)
    self.IsSkipAnim = value
end

function XUiSlotMachinePanel:GetIsSkipAnim()
    return self.IsSkipAnim
end

function XUiSlotMachinePanel:SetIconCardTmp(iconCfgId)
    local iconAssetPath = XSlotMachineConfigs.GetSlotMachinesIconTemplateById(iconCfgId).IconTiltImage
    if string.IsNilOrEmpty(iconAssetPath) then return end
    self.IconCardTmp:SetSprite(iconAssetPath)
end

function XUiSlotMachinePanel:ShowIconCardTmp()
    self.IconCardTmp.gameObject:SetActiveEx(true)

    if self.Making then
        self.Making.gameObject:SetActiveEx(false)
    end
end

function XUiSlotMachinePanel:SetShowCardSound(isPrix)
    self.SoundRootPrix.gameObject:SetActiveEx(isPrix)
    self.SoundRootNormal.gameObject:SetActiveEx(not isPrix)
end

return XUiSlotMachinePanel