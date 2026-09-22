local XUiGridChooseAwarenessResonanceSlot = require("XUi/XUiEquip/XUiEquipChooseAwarenessResonanceSkillPopup/XUiGridChooseAwarenessResonanceSlot")

---@class XUiGridChooseAwarenessResonance : XUiNode
---@field Parent XUiEquipChooseAwarenessResonanceSkillPopup 根弹窗
---@field TargetSlotGrids XUiGridChooseAwarenessResonanceSlot[] 目标共鸣槽位 Grid 列表
---@field OwnSlotGrids XUiGridChooseAwarenessResonanceSlot[] 自身共鸣槽位 Grid 列表
---@field TxtPos UnityEngine.UI.Text 意识穿戴位文本
---@field PanelOwn UnityEngine.RectTransform 自身共鸣区块
---@field GridResonanceSkill1 UnityEngine.RectTransform 目标共鸣槽位 1
---@field GridResonanceSkill2 UnityEngine.RectTransform 目标共鸣槽位 2
---@field GridResonanceSkillOwn1 UnityEngine.RectTransform 自身共鸣槽位 1
---@field GridResonanceSkillOwn2 UnityEngine.RectTransform 自身共鸣槽位 2
local XUiGridChooseAwarenessResonance = XClass(XUiNode, "XUiGridChooseAwarenessResonance")

-- 初始化一行意识的目标共鸣和自身共鸣槽位 Grid
function XUiGridChooseAwarenessResonance:OnStart()
    self.TargetSlotGrids = {
        XUiGridChooseAwarenessResonanceSlot.New(self.GridResonanceSkill1, self, self.Parent, true),
        XUiGridChooseAwarenessResonanceSlot.New(self.GridResonanceSkill2, self, self.Parent, true),
    }
    self.OwnSlotGrids = {
        XUiGridChooseAwarenessResonanceSlot.New(self.GridResonanceSkillOwn1, self, self.Parent, false),
        XUiGridChooseAwarenessResonanceSlot.New(self.GridResonanceSkillOwn2, self, self.Parent, false),
    }
end

-- 刷新一件意识对应的目标共鸣和自身共鸣展示
---@param targetData XUiChooseAwarenessResonanceRowData
---@param ownData XUiChooseAwarenessResonanceRowData
---@param isDisplayCurrent boolean
function XUiGridChooseAwarenessResonance:Refresh(targetData, ownData, isDisplayCurrent)
    self.TxtPos.text = "0" .. tostring(targetData.Site or "")
    self.PanelOwn.gameObject:SetActiveEx(isDisplayCurrent)

    for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        self.TargetSlotGrids[pos]:Open()
        self.TargetSlotGrids[pos]:Refresh(targetData.SlotMap[pos], targetData)
        if isDisplayCurrent then
            self.OwnSlotGrids[pos]:Open()
            self.OwnSlotGrids[pos]:Refresh(ownData.SlotMap[pos], ownData)
        else
            self.OwnSlotGrids[pos]:Close()
        end
    end
    self:RefreshSelected()
end

-- 获取自身共鸣区块高度，用于折叠时修正外层 GridLayoutGroup 高度
---@return number
function XUiGridChooseAwarenessResonance:GetPanelOwnHeight()
    return self.PanelOwn.rect.height
end

-- 刷新当前可选槽位的选中态
function XUiGridChooseAwarenessResonance:RefreshSelected()
    for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        self.TargetSlotGrids[pos]:RefreshSelected()
    end
end

return XUiGridChooseAwarenessResonance
