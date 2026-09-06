---@class XUiGridMemberSlot : XUiNode
---@field private _Control XTransfiniteTowerControl
---@field ImgSlotType UnityEngine.UI.Image
---@field Head UnityEngine.GameObject
---@field PanelEnergy UnityEngine.GameObject
---@field ImgEnergy1 UnityEngine.UI.Image
---@field ImgEnergy2 UnityEngine.UI.Image
---@field ImgEnergy3 UnityEngine.UI.Image
---@field ImgIconInfinite UnityEngine.UI.Image
local XUiGridMemberSlot = XClass(XUiNode, "XUiGridMemberSlot")

function XUiGridMemberSlot:OnStart()
    ---@type UnityEngine.UI.Image[] 索引即体力点数
    self._EnergyImgs = { self.ImgEnergy1, self.ImgEnergy2, self.ImgEnergy3 }
    -- Head 为通用头像子 prefab，展开一次以访问其 StandIcon
    self._HeadUi = XTool.InitUiObjectByUi({}, self.Head)
end

---刷新成员槽位
---@param slotData table { IsEmpty, SlotType, IsPilot, EnergyPoint, FightId }
function XUiGridMemberSlot:Refresh(slotData)
    if slotData.IsEmpty then
        self:ShowEmptySlot(slotData.SlotType)
    else
        self:ShowMember(slotData)
    end
end

---空槽：显示槽位类型底纹
function XUiGridMemberSlot:ShowEmptySlot(slotType)
    self.Head.gameObject:SetActiveEx(false)
    self.PanelEnergy.gameObject:SetActiveEx(false)
    local icon = self._Control:GetSlotTypeIcon(slotType)
    local hasIcon = not string.IsNilOrEmpty(icon)
    self.ImgSlotType.gameObject:SetActiveEx(hasIcon)
    if hasIcon then
        self.ImgSlotType:SetSprite(icon)
    end
end

---通关态：显示上阵成员
function XUiGridMemberSlot:ShowMember(slotData)
    self.ImgSlotType.gameObject:SetActiveEx(false)
    self.PanelEnergy.gameObject:SetActiveEx(true)

    local icon = self._Control:GetFightHeadIcon(slotData.FightId)
    self.Head.gameObject:SetActiveEx(icon ~= nil)
    if icon then
        self._HeadUi.StandIcon:SetRawImage(icon)
    end
    self:RefreshEnergy(slotData.IsPilot, slotData.EnergyPoint)
end

---刷新体力显示：领航员显示无限标志，非领航员按点数显示对应体力槽
function XUiGridMemberSlot:RefreshEnergy(isPilot, energyPoint)
    self.ImgIconInfinite.gameObject:SetActiveEx(isPilot)
    for i = 1, #self._EnergyImgs do
        self._EnergyImgs[i].gameObject:SetActiveEx(not isPilot and i > energyPoint-1)
    end
end

return XUiGridMemberSlot
