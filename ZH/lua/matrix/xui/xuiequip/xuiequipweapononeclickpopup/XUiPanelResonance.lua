-- 共鸣栏
---@class XUiPanelResonance:XUiNode
---@field Parent XUiEquipWeaponOneClickPopup
---@field BgTitleChoose UnityEngine.RectTransform
---@field BgTitleNotChoose UnityEngine.RectTransform
---@field UiTxtPreview UnityEngine.UI.Text
---@field BtnDesc XUiComponent.XUiButton
---@field BtnChoose XUiComponent.XUiButton
---@field TxtChoosePreview UnityEngine.UI.Text
---@field BtnEditTarget XUiComponent.XUiButton
---@field GridChooseMaterial UnityEngine.RectTransform
---@field PanelChooseMaterial UnityEngine.RectTransform
---@field PanelNone UnityEngine.RectTransform
local XUiPanelResonance = XClass(XUiNode, "XUiPanelResonance")

local XUiGridChooseMaterial = require("XUi/XUiEquip/XUiEquipWeaponOneClickPopup/XUiGridChooseMaterial")

function XUiPanelResonance:OnStart()
    self._MaterialGrids = {}
    self.IsChoose = true
    self.GridChooseMaterial.gameObject:SetActiveEx(false)
    self.BtnChoose:AddEventListener(handler(self, self.OnBtnChooseClick))
    self.BtnDesc:AddEventListener(handler(self, self.OnBtnDescClick))
    self.BtnEditTarget:AddEventListener(handler(self, self.OnBtnEditTargetClick))
end

--- @param data table { PreviewText, ChoosePreviewText, MaterialList }
function XUiPanelResonance:Refresh(data)
    self.Data = data
    self:RefreshChooseState()

    local hasTarget = (data.ResonanceCount or 0) > 0
    local isMaterialLack = hasTarget and data.IsMaterialLack == true
    local isBgChoose = self.IsChoose and hasTarget and not isMaterialLack
    if isMaterialLack then
        self.UiTxtPreview.text = CS.XTextManager.GetText("AwarenessOneClickResonanceMaterialNotSelected")
    elseif hasTarget then
        self.UiTxtPreview.text = CS.XTextManager.GetText("EquipWeaponOneClickResonancePreview", data.ResonanceCount or 0)
    else
        self.UiTxtPreview.text = CS.XTextManager.GetText("AwarenessOneClickResonanceTargetSettingPending")
    end
    self.BgTitleChoose.gameObject:SetActiveEx(isBgChoose)
    self.BgTitleNotChoose.gameObject:SetActiveEx(not isBgChoose)
    self.TxtChoosePreview.text = string.format("%d/%d", data.ResonanceCount or 0, data.TargetCount or 0)

    local materialList = data.MaterialList or table.empty
    XTool.UpdateDynamicItem(self._MaterialGrids, materialList, self.GridChooseMaterial, XUiGridChooseMaterial, self)

    -- 需要消耗的共鸣材料 = 首绑槽数（选了技能但都是换技能/已达成时为 0，不消耗则不展示材料列表与空态）
    local needMaterial = (data.MaxWeaponSelectCount or 0) > 0
    self.PanelChooseMaterial.gameObject:SetActiveEx(hasTarget and needMaterial)
    self.PanelNone.gameObject:SetActiveEx(false)
end

function XUiPanelResonance:RefreshChooseState()
    self.BgTitleChoose.gameObject:SetActiveEx(self.IsChoose)
    self.BgTitleNotChoose.gameObject:SetActiveEx(not self.IsChoose)
    self.BtnChoose:SetButtonState(self.IsChoose and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.ImgArrow1.gameObject:SetActiveEx(self.IsChoose)
    self.UiTxtPreview.gameObject:SetActiveEx(self.IsChoose)
end

function XUiPanelResonance:OnBtnChooseClick()
    self.IsChoose = not self.IsChoose
    self:RefreshChooseState()
    self.Parent:OnModuleChooseChanged()
end

function XUiPanelResonance:OnBtnDescClick()
    self.Parent:ShowBubbleResonanceDetail(self.BtnDesc)
end

function XUiPanelResonance:OnBtnEditTargetClick()
    -- 打开共鸣技能选择弹窗，确认后回写已选技能并刷新
    local parent = self.Parent
    XLuaUiManager.Open("UiEquipChooseWeaponResonanceSkillPopup",
        parent.EquipId,
        parent.TargetData,
        parent:GetChosenResonanceSkillMap(),
        handler(self, self.OnResonanceSkillChosen))
end

--- 共鸣技能选择确认回调
function XUiPanelResonance:OnResonanceSkillChosen(selectedSkillMap)
    self.Parent:SetChosenResonanceSkillMap(selectedSkillMap)
end

function XUiPanelResonance:GetIsChoose()
    return self.IsChoose
end

---@param isChoose boolean
function XUiPanelResonance:SetIsChoose(isChoose)
    self.IsChoose = isChoose and true or false
    self:RefreshChooseState()
end

return XUiPanelResonance
