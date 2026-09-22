-- 武器升级与突破栏
---@class XUiPanelUpgrade:XUiNode
---@field Parent XUiEquipWeaponOneClickPopup
---@field BgTitleChoose UnityEngine.RectTransform
---@field BgTitleNotChoose UnityEngine.RectTransform
---@field UiTxtPreview UnityEngine.UI.Text
---@field ImgBreakIcon UnityEngine.UI.Image
---@field BtnDesc XUiComponent.XUiButton
---@field BtnChoose XUiComponent.XUiButton
---@field PanelCosume UnityEngine.RectTransform
---@field PanelNone UnityEngine.RectTransform
---@field TxtNone UnityEngine.UI.Text
---@field GridConsume UnityEngine.RectTransform
local XUiPanelUpgrade = XClass(XUiNode, "XUiPanelUpgrade")

local XUiGridConsume = require("XUi/XUiEquip/XUiEquipWeaponOneClickPopup/XUiGridConsume")

function XUiPanelUpgrade:OnStart()
    self._ConsumeGrids = {}
    self._DisplayList = {}
    self.IsChoose = true
    self.GridConsume.gameObject:SetActiveEx(false)
    self.BtnChoose:AddEventListener(handler(self, self.OnBtnChooseClick))
    self.BtnDesc:AddEventListener(handler(self, self.OnBtnDescClick))
end

--- @param data table { PreviewText, BreakIcon, CostList }
function XUiPanelUpgrade:Refresh(data)
    self.Data = data
    self:RefreshChooseState()

    local displayList = self:BuildDisplayList(data.CostList or table.empty)
    local hasCost = not XTool.IsTableEmpty(displayList)
    if hasCost then
        self.UiTxtPreview.text = CS.XTextManager.GetText("EquipWeaponOneClickUpgradePreview", data.MaxLevel or 0)
    else
        self.UiTxtPreview.text = CS.XTextManager.GetText("EquipOneClickCultureMaterialNotEnough")
    end
    self.ImgBreakIcon.gameObject:SetActiveEx(hasCost and self.IsChoose)
    if hasCost and data.BreakIcon and data.BreakIcon ~= "" then
        self.Parent:SetUiSprite(self.ImgBreakIcon, data.BreakIcon)
    end
    self.PanelCosume.gameObject:SetActiveEx(hasCost)
    self.PanelNone.gameObject:SetActiveEx(not hasCost)
    if hasCost then
        XTool.UpdateDynamicItem(self._ConsumeGrids, displayList, self.GridConsume, XUiGridConsume, self)
    else
        self:RefreshNoneText()
    end
end

--- 空态提示：按「突破材料 → 升级材料 → 螺母」的优先级区分缺什么
function XUiPanelUpgrade:RefreshNoneText()
    local preview = self.Data and self.Data.NextPreview
    local textKey = "EquipOneClickCultureMaterialNotEnough"
    if preview then
        if preview.CanBreakThroughCondition and not preview.CanBreakThrough then
            -- 已满足突破条件但材料不足，优先提示突破材料
            textKey = "AwarenessOneClickStrengthenLackBreakthroughMaterial"
        elseif not preview.CanLevelUp then
            -- 突破材料充足后，继续提示升级材料不足
            textKey = "AwarenessOneClickStrengthenLackLevelUpMaterial"
        elseif not preview.IsMoneyEnough then
            -- 材料都够，只差螺母
            textKey = "AwarenessOneClickStrengthenLackCoin"
        end
    end
    self.TxtNone.text = XUiHelper.GetText(textKey)
end

--- 把每个材料拆成"已有格 + 兑换格"：已有格显 min(持有,需求)，兑换格显缺口(仅需兑换补足时)
function XUiPanelUpgrade:BuildDisplayList(costList)
    local displayList = self._DisplayList
    for i = #displayList, 1, -1 do
        displayList[i] = nil
    end
    for _, cost in ipairs(costList) do
        -- 经验项是特殊材料区，不拆已有/兑换，沿用需求量显示
        if cost.IsExp then
            table.insert(displayList, {
                ItemId = cost.ItemId,
                Count = cost.NeedCount,
                IsExchange = false,
            })
        else
            -- 已有格：数量>0 才显示（玩家一个都没有时不显示已有格，只显兑换格）
            local ownCount = math.min(cost.HaveCount or 0, cost.NeedCount or 0)
            if ownCount > 0 then
                table.insert(displayList, {
                    ItemId = cost.ItemId,
                    IsEquip = cost.IsWeaponMaterial == true,
                    Count = ownCount,
                    IsExchange = false,
                    IsStarMerged = cost.IsStarMerged == true,
                    Star = cost.Star,
                })
            end
            if (cost.ExchangeCount or 0) > 0 then
                table.insert(displayList, {
                    ItemId = cost.ItemId,
                    IsEquip = cost.IsWeaponMaterial == true,
                    Count = cost.ExchangeCount,
                    IsExchange = true,
                    IsStarMerged = cost.IsStarMerged == true,
                    Star = cost.Star,
                })
            end
        end
    end
    return displayList
end

function XUiPanelUpgrade:RefreshChooseState()
    self.BgTitleChoose.gameObject:SetActiveEx(self.IsChoose)
    self.BgTitleNotChoose.gameObject:SetActiveEx(not self.IsChoose)
    self.BtnChoose:SetButtonState(self.IsChoose and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.ImgArrow1.gameObject:SetActiveEx(self.IsChoose)
    self.UiTxtPreview.gameObject:SetActiveEx(self.IsChoose)
    self.ImgBreakIcon.gameObject:SetActiveEx(self.IsChoose)
end

function XUiPanelUpgrade:OnBtnChooseClick()
    self.IsChoose = not self.IsChoose
    self:RefreshChooseState()
    self.Parent:OnModuleChooseChanged()
end

function XUiPanelUpgrade:OnBtnDescClick()
    self.Parent:ShowBubbleDetail()
    self.Parent.UiTxtDesc.text = CS.XTextManager.GetText("AwarenessOneClickStrengthenTips")
end

--- 当前是否勾选养成此项
function XUiPanelUpgrade:GetIsChoose()
    return self.IsChoose
end

---@param isChoose boolean
function XUiPanelUpgrade:SetIsChoose(isChoose)
    self.IsChoose = isChoose and true or false
    self:RefreshChooseState()
end

return XUiPanelUpgrade
