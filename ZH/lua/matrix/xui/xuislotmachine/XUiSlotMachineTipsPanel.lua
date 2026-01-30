---@class XUiSlotMachineTipsPanel
local XUiSlotMachineTipsPanel = XClass(nil, "XUiSlotMachineTipsPanel")

function XUiSlotMachineTipsPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiSlotMachineTipsPanel:Refresh(machineId)
    self.CurMachineEntity = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityById(machineId)
    
    ---@type XTableSlotMachines
    local cfg = XSlotMachineConfigs.GetSlotMachinesTemplateById(machineId)
    
    local machineState = XDataCenter.SlotMachineManager.CheckSlotMachineState(machineId)
    if machineState == XSlotMachineConfigs.SlotMachineState.Finish then
        self.GameObject:SetActiveEx(false)
    elseif machineState == XSlotMachineConfigs.SlotMachineState.Locked then
        self.GameObject:SetActiveEx(true)
        self.LockTips.gameObject:SetActiveEx(true)
        self.UnLockTips.gameObject:SetActiveEx(false)
        self.TxtLock.text = not string.IsNilOrEmpty(cfg.LockTips) and cfg.LockTips or XUiHelper.GetText("SlotMachineTipsLock")
    elseif machineState == XSlotMachineConfigs.SlotMachineState.Running then
        self.GameObject:SetActiveEx(true)
        self.LockTips.gameObject:SetActiveEx(false)
        self.UnLockTips.gameObject:SetActiveEx(true)
        self.TxtDesc.text = not string.IsNilOrEmpty(cfg.UnlockTips) and cfg.UnlockTips or XUiHelper.GetText("SlotMachineTipsUnLockDesc")
        self.TxtGuaranteed.text = XUiHelper.GetText("SlotMachineTipsUnLock", self.CurMachineEntity:GetRockTimes(), self.CurMachineEntity:GetPrixBottomTimes() + 1)
    end
end

return XUiSlotMachineTipsPanel