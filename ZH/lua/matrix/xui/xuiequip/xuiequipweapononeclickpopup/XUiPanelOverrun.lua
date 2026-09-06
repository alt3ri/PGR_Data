-- 谐振栏
---@class XUiPanelOverrun:XUiNode
---@field Parent XUiEquipWeaponOneClickPopup
---@field BgTitleChoose UnityEngine.RectTransform
---@field BgTitleNotChoose UnityEngine.RectTransform
---@field UiTxtPreview UnityEngine.UI.Text
---@field BtnDesc XUiComponent.XUiButton
---@field BtnCheck XUiComponent.XUiButton
---@field BtnChoose XUiComponent.XUiButton
---@field PanelTitleDetail UnityEngine.RectTransform
---@field BtnSub XUiComponent.XUiButton
---@field BtnAdd XUiComponent.XUiButton
---@field TxtActiveNum UnityEngine.UI.Text
---@field PanelBindAwareness UnityEngine.RectTransform
---@field TxtAfter UnityEngine.UI.Text
---@field TxtBefore UnityEngine.UI.Text
---@field ImgArrow UnityEngine.RectTransform
---@field PanelCosume UnityEngine.RectTransform
---@field PanelNone UnityEngine.RectTransform
---@field GridConsume UnityEngine.RectTransform
local XUiPanelOverrun = XClass(XUiNode, "XUiPanelOverrun")

local XUiGridConsume = require("XUi/XUiEquip/XUiEquipWeaponOneClickPopup/XUiGridConsume")

function XUiPanelOverrun:OnStart()
    self._ConsumeGrids = {}
    self._DisplayList = {}
    self.IsChoose = true
    self.GridConsume.gameObject:SetActiveEx(false)
    self.BtnChoose:AddEventListener(handler(self, self.OnBtnChooseClick))
    self.BtnCheck:AddEventListener(handler(self, self.OnBtnCheckClick))
    self.BtnSub:AddEventListener(handler(self, self.OnBtnSubClick))
    self.BtnAdd:AddEventListener(handler(self, self.OnBtnAddClick))
    self:SetCheckReddot(false)
end

--- @param data table { ActiveNum, MinLevel, TotalNode, CanAdd, IsShowTitleDetail, IsShowBindAwareness,
---   TargetSuitName, CurrentSuitName, HasCurrentSuit, CostList }
function XUiPanelOverrun:Refresh(data)
    self.Data = data
    self:RefreshChooseState()

    -- 谐振目标激活等级状态：最低=当前谐振等级，最高=总节点数
    self.ActiveNum = data.ActiveNum or 0
    self.MinLevel = data.MinLevel or 0
    self.MaxLevel = data.TotalNode or 0
    self.PanelTitleDetail.gameObject:SetActiveEx(data.IsShowTitleDetail == true)
    self:RefreshActiveNum()

    self:RefreshBindAwareness(data)

    local costList = data.CostList or table.empty
    local displayList = self:BuildDisplayList(costList)
    local hasCost = not XTool.IsTableEmpty(displayList)
    self.PanelCosume.gameObject:SetActiveEx(hasCost)
    -- 仅换绑（目标套装已激活、无新升级档）时 CostList 为空，本就不消耗材料，不算空态
    self.PanelNone.gameObject:SetActiveEx(not XTool.IsTableEmpty(costList) and not hasCost)
    if hasCost then
        XTool.UpdateDynamicItem(self._ConsumeGrids, displayList, self.GridConsume, XUiGridConsume, self)
    end
    self:RefreshPreviewText(data)
end

--- 刷新预览文本 + BgTitle 显隐（按 6 个 bool 算）
function XUiPanelOverrun:RefreshPreviewText(data)
    local isNowLevel = data.IsNowLevel == true
    local canBind = data.CanBind == true
    local canUpdate = data.CanUpdate == true
    -- 已绑定目标意识时 NeedBindSuit 为 false，此时 CanBind 也为 false，
    -- 但那是"无需再绑"而非材料不足，不能算进材料不足判定
    local needBindSuit = data.NeedBindSuit == true
    local bindBlocked = needBindSuit and not canBind
    local key
    if not isNowLevel then
        -- 步进器 != 真实等级（已+号过）→ 默认预览
        key = "EquipWeaponOneClickOverrunPreview"
    elseif isNowLevel and canBind and self.ActiveNum >= 1 then
        -- 步进器=真实，会绑套装（已激活+材料够+没绑）→ 仅绑定
        key = "EquipWeaponOneClickBind"
    elseif isNowLevel and (not canUpdate or bindBlocked) then
        -- 步进器=真实，升级材料不足、或需要绑定却绑不了 → 材料不足
        key = "EquipOneClickCultureMaterialNotEnough"
    elseif isNowLevel and canUpdate then
        -- 步进器=真实，升级材料够且无待绑阻塞 → 待设置
        key = "AwarenessOneClickResonanceTargetSettingPending"
    else
        key = "EquipWeaponOneClickOverrunPreview"
    end
    -- 默认预览带 ActiveNum/MaxLevel 参数；其他文本无参
    if key == "EquipWeaponOneClickOverrunPreview" then
        self.UiTxtPreview.text = CS.XTextManager.GetText(key, self.ActiveNum, self.MaxLevel)
    else
        self.UiTxtPreview.text = CS.XTextManager.GetText(key)
    end
    -- BgTitle: 未勾选 或 (材料不足/待设置) → NotChoose；否则 Choose
    local showNotChoose = (not self.IsChoose)
        or key == "EquipOneClickCultureMaterialNotEnough"
        or key == "AwarenessOneClickResonanceTargetSettingPending"
    self.BgTitleChoose.gameObject:SetActiveEx(not showNotChoose)
    self.BgTitleNotChoose.gameObject:SetActiveEx(showNotChoose)
end

--- 把每个谐振材料拆成"已有格 + 兑换格"：已有格显 min(持有,需求)，兑换格显缺口(仅需兑换补足时)
function XUiPanelOverrun:BuildDisplayList(costList)
    local displayList = self._DisplayList
    for i = #displayList, 1, -1 do
        displayList[i] = nil
    end
    for _, cost in ipairs(costList) do
        -- 已有格：数量>0 才显示（玩家一个都没有时不显示已有格，只显兑换格）
        local ownCount = math.min(cost.HaveCount or 0, cost.NeedCount or 0)
        if ownCount > 0 then
            table.insert(displayList, {
                ItemId = cost.ItemId,
                Count = ownCount,
                IsExchange = false,
            })
        end
        if (cost.ExchangeCount or 0) > 0 then
            table.insert(displayList, {
                ItemId = cost.ItemId,
                Count = cost.ExchangeCount,
                IsExchange = true,
            })
        end
    end
    return displayList
end

-- 刷新激活等级相关显示（数值 / 增减按钮禁用态；预览文本由 RefreshPreviewText 设）
function XUiPanelOverrun:RefreshActiveNum()
    self.TxtActiveNum.text = tostring(self.ActiveNum)
    self.BtnSub:SetDisable(self.ActiveNum <= self.MinLevel)
    -- 加号 Disable = !(CanUpdate && CanActivate && !IsMaxLevel)
    local d = self.Data
    local canAdd = d and d.CanUpdate == true and d.CanActivate == true and d.IsMaxLevel ~= true
    self.BtnAdd:SetDisable(not canAdd)
end

-- 绑定意识展示：目标套装 vs 当前绑定套装
function XUiPanelOverrun:RefreshBindAwareness(data)
    self.PanelBindAwareness.gameObject:SetActiveEx(data.IsShowBindAwareness == true)
    if not data.IsShowBindAwareness then
        return
    end
    self.TxtAfter.text = data.TargetSuitName or ""
    -- 当前无绑定套装时隐藏箭头与当前套装名
    self.ImgArrow.gameObject:SetActiveEx(data.HasCurrentSuit == true)
    self.TxtBefore.gameObject:SetActiveEx(data.HasCurrentSuit == true)
    if data.HasCurrentSuit then
        self.TxtBefore.text = data.CurrentSuitName or ""
    end
end

function XUiPanelOverrun:RefreshChooseState()
    self.BgTitleChoose.gameObject:SetActiveEx(self.IsChoose)
    self.BgTitleNotChoose.gameObject:SetActiveEx(not self.IsChoose)
    self.BtnChoose:SetButtonState(self.IsChoose and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.ImgArrow1.gameObject:SetActiveEx(self.IsChoose)
    self.UiTxtPreview.gameObject:SetActiveEx(self.IsChoose)
end

function XUiPanelOverrun:OnBtnChooseClick()
    self.IsChoose = not self.IsChoose
    self:RefreshChooseState()
    self.Parent:OnModuleChooseChanged()
end

function XUiPanelOverrun:OnBtnCheckClick()
    self:SetCheckReddot(false)
    self.Parent:ShowBubbleOverrunDetail()
end

function XUiPanelOverrun:SetCheckReddot(isShow)
    self.BtnCheck:ShowReddot(isShow)
end

function XUiPanelOverrun:OnBtnSubClick()
    if self.ActiveNum <= self.MinLevel then
        return
    end
    self.ActiveNum = self.ActiveNum - 1
    if self.ActiveNum <= self.MinLevel then
        self:SetCheckReddot(false)
    end
    self:RefreshActiveNum()
    self.Parent:OnOverrunTargetChanged(self.ActiveNum)
end

function XUiPanelOverrun:OnBtnAddClick()
    -- 满级直接返回，不弹提示
    if self.ActiveNum >= self.MaxLevel then
        return
    end
    -- 升级或激活材料不足：弹 toast
    local d = self.Data
    if not (d and d.CanUpdate == true and d.CanActivate == true) then
        XUiManager.TipMsg(CS.XTextManager.GetText("EquipWeaponOneClickMaterialNotEnough"))
        return
    end
    self.ActiveNum = self.ActiveNum + 1
    self:SetCheckReddot(true)
    self:RefreshActiveNum()
    self.Parent:OnOverrunTargetChanged(self.ActiveNum)
end

function XUiPanelOverrun:GetIsChoose()
    return self.IsChoose
end

---@param isChoose boolean
function XUiPanelOverrun:SetIsChoose(isChoose)
    self.IsChoose = isChoose and true or false
    self:RefreshChooseState()
end

return XUiPanelOverrun
