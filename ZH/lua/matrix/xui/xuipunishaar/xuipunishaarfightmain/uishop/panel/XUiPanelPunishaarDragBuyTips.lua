--- 商店拖拽购买提示组件（独立 XUiNode）。
--- 两个实例：ComBottomBag 的（主卡）+ PanelBagLayout 的（副卡），同一类不同 cardType。
--- 主卡态：Invalid(背包满→TxtCardNoneSlot+ImgDisable) / Neutral(未到购买位→TxtDragBuyTips+ImgNormal) / BuyZone(到购买位→TxtDragBuyPriceTips+ImgNormal|ImgDisable按canComplete)
--- 副卡态：Invalid(无可放置主卡→TxtSubCardNoneSlot+ImgDisable) / Neutral(未到购买区→TxtDragCancelBuyTips+ImgNormal) / BuyZone(到购买区→TxtDragBuyTips+ImgNormal)
---@class XUiPanelPunishaarDragBuyTips: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field ImgNormal UnityEngine.UI.Image 中性/有效背景
---@field ImgDisable UnityEngine.UI.Image 无效背景（背包满/金币不足/无可放置主卡）
---@field TxtDragBuyTips UnityEngine.UI.Text 主卡中性(未到购买位)；副卡有效(到购买区)
---@field TxtDragBuyPriceTips UnityEngine.UI.Text 主卡到购买位（显价格，TODO金币数量）
---@field TxtDragCancelBuyTips UnityEngine.UI.Text 副卡中性(未到购买区)
---@field TxtCardNoneSlot UnityEngine.UI.Text 主卡无效(背包满)
---@field TxtSubCardNoneSlot UnityEngine.UI.Text 副卡无效(无可放置主卡)
local XUiPanelPunishaarDragBuyTips = XClass(XUiNode, "XUiPanelPunishaarDragBuyTips")

local CardType = { MainCard = 1, SubCard = 2 }
local State = { Invalid = 1, Neutral = 2, BuyZone = 3 }

-- 所有 @field 名（用于 _Show 遍历隐显）
local ALL_FIELDS = { "ImgNormal", "ImgDisable", "TxtDragBuyTips", "TxtDragBuyPriceTips", "TxtDragCancelBuyTips", "TxtCardNoneSlot", "TxtSubCardNoneSlot" }

function XUiPanelPunishaarDragBuyTips:OnStart()
    for _, name in ipairs(ALL_FIELDS) do
        if self[name] then
            self[name].gameObject:SetActiveEx(false)
        end
    end
end

--- 显示拖拽购买提示（由 _OnDragBegin 调）。
---@param cardType number CardType.MainCard / SubCard
function XUiPanelPunishaarDragBuyTips:Show(cardType)
    self._CardType = cardType or CardType.MainCard
    self:Open()
    self:_ApplyState(State.Neutral, true)
end

--- 隐藏（拖拽结束由 _OnDragEnd 调；幂等）。
function XUiPanelPunishaarDragBuyTips:Hide()
    self:Close()
end

--- 按拖拽状态刷新提示态。
---@param state number State.Invalid / Neutral / BuyZone
---@param canComplete boolean|nil 操作能否完成（仅 BuyZone 影响 ImgNormal/ImgDisable；Invalid 恒 ImgDisable）
function XUiPanelPunishaarDragBuyTips:RefreshState(state, canComplete)
    self:_ApplyState(state, canComplete)
end

--- 统一应用状态。
---@param state number
---@param canComplete boolean|nil
function XUiPanelPunishaarDragBuyTips:_ApplyState(state, canComplete)
    if self._CardType == CardType.SubCard then
        self:_ApplySubCard(state, canComplete)
    else
        self:_ApplyMainCard(state, canComplete)
    end
end

--- 主卡：Invalid→TxtCardNoneSlot+ImgDisable；Neutral→TxtDragBuyTips+ImgNormal；BuyZone→TxtDragBuyPriceTips+(金币够?ImgNormal:ImgDisable)
--- BuyZone 金币判定内聚于 _RefreshBuyPrice（算 price+gold 返回 enough，背景按 enough）；canComplete 参数主卡 BuyZone 不用（副卡 _ApplySubCard 用 canMount）
function XUiPanelPunishaarDragBuyTips:_ApplyMainCard(state, canComplete)
    if state == State.Invalid then
        self:_Show("ImgDisable", "TxtCardNoneSlot")
    elseif state == State.BuyZone then
        local enough = self:_RefreshBuyPrice()
        self:_Show(enough and "ImgNormal" or "ImgDisable", "TxtDragBuyPriceTips")
    else
        self:_Show("ImgNormal", "TxtDragBuyTips")
    end
end

--- 副卡：Invalid→TxtSubCardNoneSlot+ImgDisable；Neutral→TxtDragCancelBuyTips+ImgNormal；BuyZone→TxtDragBuyPriceTips+(金币够?ImgNormal:ImgDisable)
--- BuyZone 显价格+金币差异化（同主卡 _RefreshBuyPrice 算 price+gold+BuyTips 1/2 返回 enough）；canComplete 参数副卡 BuyZone 不用（canMount 在容器 _OnDragFocusChange 守卫，不可装配保持上一态不进 BuyZone）
function XUiPanelPunishaarDragBuyTips:_ApplySubCard(state, canComplete)
    if state == State.Invalid then
        self:_Show("ImgDisable", "TxtSubCardNoneSlot")
    elseif state == State.BuyZone then
        local enough = self:_RefreshBuyPrice()
        self:_Show(enough and "ImgNormal" or "ImgDisable", "TxtDragBuyPriceTips")
    else
        self:_Show("ImgNormal", "TxtDragCancelBuyTips")
    end
end

--- 显示指定背景+文本，隐其余。
---@param bgName string|nil @field 名（"ImgNormal"/"ImgDisable"）
---@param textName string|nil @field 名
function XUiPanelPunishaarDragBuyTips:_Show(bgName, textName)
    for _, name in ipairs(ALL_FIELDS) do
        if self[name] then
            local show = (name == bgName) or (name == textName)
            self[name].gameObject:SetActiveEx(show)
        end
    end
end

--- 刷新主卡购买价格文本+判金币（BuyZone 态调）#PanelDragBuyTips
--- 算 Buy 价 + 当前金币 → enough；BuyTips 插值配置 1=够/2=不够，插值 price 设 TxtDragBuyPriceTips；返回 enough 供背景切 ImgNormal/ImgDisable
---@return boolean enough 金币是否够购买（数据缺失兜底 true 不切灰）
function XUiPanelPunishaarDragBuyTips:_RefreshBuyPrice()
    if not self.TxtDragBuyPriceTips then
        return true
    end
    local gc = self._Control and self._Control.GameControl
    if not gc then
        return true
    end
    local goods = gc:GetDraggingCardData()
    local cardId = goods and goods.CardId
    if not cardId then
        return true
    end
    local cardCfg = self._Control:GetTablePunishaarCard(cardId, true)
    if not cardCfg then
        return true
    end
    local saleKey = cardCfg.Type * 100 + cardCfg.Size * 10 + (goods.Level or 1)
    local saleCfg = gc:GetTablePunishaarCardSale(saleKey, true)
    local price = saleCfg and saleCfg.Buy or 0
    local gold = self._Control:GetCurrentGold() or 0
    local enough = gold >= price
    local tmpl = XMVCA.XPunishaar:GetClientStringByKey("BuyTips", enough and 1 or 2)
    if not string.IsNilOrEmpty(tmpl) then
        self.TxtDragBuyPriceTips.text = XUiHelper.FormatTextEx(tmpl, tostring(price))
    else
        self.TxtDragBuyPriceTips.text = tostring(price)
    end
    return enough
end

-- CardType/State 为 file-local 仅供本类内部用（项目禁类静态字段 ClassName.Field 直接访问，
-- 容器本地镜像枚举值对齐，见 ComBottomBagBase/PanelBagLayoutBase 顶部 DragBuyCardType/DragBuyState）

return XUiPanelPunishaarDragBuyTips
