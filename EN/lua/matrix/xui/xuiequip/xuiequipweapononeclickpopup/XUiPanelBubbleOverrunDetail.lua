-- 谐振升级效果预览气泡
---@class XUiPanelBubbleOverrunDetail:XUiNode
---@field Parent XUiEquipWeaponOneClickPopup
---@field BtnOverrunDetailClose XUiComponent.XUiButton
---@field TxtActiveStageNum UnityEngine.UI.Text
---@field GridUiEquipOverrunLevel UnityEngine.RectTransform
local XUiPanelBubbleOverrunDetail = XClass(XUiNode, "XUiPanelBubbleOverrunDetail")

local XUiGridUiEquipOverrunLevel = require("XUi/XUiEquip/XUiEquipWeaponOneClickPopup/XUiGridUiEquipOverrunLevel")

local ACTIVE_STAGE_COLOR = "3B9AE8" -- x（已激活+本次将激活）标蓝

function XUiPanelBubbleOverrunDetail:OnStart()
    self._LevelGrids = {}
    self.GridUiEquipOverrunLevel.gameObject:SetActiveEx(false)
    self.BtnOverrunDetailClose:AddEventListener(handler(self, self.Hide))
end

function XUiPanelBubbleOverrunDetail:Show(data)
    self:Open()
    self:Refresh(data)
end

function XUiPanelBubbleOverrunDetail:Hide()
    self:Close()
end

--- @param data table { ActiveStage, TotalStage, LevelList }
function XUiPanelBubbleOverrunDetail:Refresh(data)
    data = data or {}
    -- x/y：x（已激活+本次将激活的等级）标蓝
    local activeStage = data.ActiveStage or 0
    local totalStage = data.TotalStage or 0
    self.TxtActiveStageNum.text = string.format("<color=#%s>%d</color>/%d", ACTIVE_STAGE_COLOR, activeStage, totalStage)
    self.TxtRecommendTips.text = CS.XTextManager.GetText("EquipWeaponOneClickOverrunRecommend",data.TotalStage)

    XTool.UpdateDynamicItem(self._LevelGrids, data.LevelList or {}, self.GridUiEquipOverrunLevel, XUiGridUiEquipOverrunLevel, self)
end

return XUiPanelBubbleOverrunDetail
