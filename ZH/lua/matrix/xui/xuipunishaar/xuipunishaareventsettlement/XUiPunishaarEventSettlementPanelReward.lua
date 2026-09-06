local XUiPunishaarEventSettlementGridCard = require("XUi/XUiPunishaar/XUiPunishaarEventSettlement/XUiPunishaarEventSettlementGridCard")
local XUiPunishaarEventSettlementGridSubCard = require("XUi/XUiPunishaar/XUiPunishaarEventSettlement/XUiPunishaarEventSettlementGridSubCard")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiPunishaarEventSettlementPanelReward : XUiNode
---@field TxtContent UnityEngine.UI.Text
---@field PanelReward UnityEngine.RectTransform
---@field PanelIcon UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
--- v3 奖励 grid 展示：读 EventReward 配置（GoldCount/CardId/CardLevel）按类型分发单一 grid。
--- 三模板（GridCard/GridSubCard/GridCoin）为 PanelIcon(content) 下子物体，prefab 未挂 UiObject，
--- 故经 TryGetComponent 按"GridCard/GridSubCard/GridCoin"取 Transform。
--- 单一奖励（一行 EventReward）→ 仅展示一个 grid，无需 Instantiate 克隆。
--- 退出动作不在本面板：v3 把退出归到最后一条内容的 ConfirmContent"结束"按钮（主面板 AdvanceChain 处理），
--- 故 BtnEnd 隐藏不用，本面板只负责 grid 展示。
local XUiPunishaarEventSettlementPanelReward = XClass(XUiNode, "XUiPunishaarEventSettlementPanelReward")

function XUiPunishaarEventSettlementPanelReward:OnStart()
    -- 取三模板 Transform（content 下子物体）
    local cardTr = XUiHelper.TryGetComponent(self.PanelIcon, "GridCard")
    local subTr = XUiHelper.TryGetComponent(self.PanelIcon, "GridSubCard")
    local coinTr = XUiHelper.TryGetComponent(self.PanelIcon, "GridCoin")

    self._GridCard = nil
    if cardTr then
        self._GridCard = XUiPunishaarEventSettlementGridCard.New(cardTr, self)
    end
    self._GridSubCard = nil
    if subTr then
        self._GridSubCard = XUiPunishaarEventSettlementGridSubCard.New(subTr, self)
    end
    self._GridCoinTr = coinTr

    -- GridCoin 无独立类：内联取图标/数量文本（图标走预制体默认 sprite，仅刷数量）
    if coinTr then
        local coinText = XUiHelper.TryGetComponent(coinTr, "Text", "Text")
        if not coinText then
            coinText = XUiHelper.TryGetComponent(coinTr, "Text (Legacy)", "Text")
        end
        self._CoinText = coinText
    end

    -- 初始全部隐藏，Refresh 时按类型只显一个
    self:_HideAllGrids()

    -- BtnEnd 不再作为退出按钮（v3：退出动作归最后一条内容的 ConfirmContent"结束"按钮），
    -- 整个 BtnEnd 隐藏；保留取用以备后续需要。本面板只负责奖励 grid 展示。
    self._BtnEnd = XUiHelper.TryGetComponent(self.Transform, "BtnEnd", "XUiButton")
    if self._BtnEnd then
        self._BtnEnd.gameObject:SetActiveEx(false)
    end
end

function XUiPunishaarEventSettlementPanelReward:OnEnable()
end

function XUiPunishaarEventSettlementPanelReward:OnDisable()
end

function XUiPunishaarEventSettlementPanelReward:OnDestroy()
    self._GridCard = nil
    self._GridSubCard = nil
    self._GridCoinTr = nil
    self._CoinText = nil
    self._BtnEnd = nil
end

--- 刷新奖励展示：按 EventReward 配置分发单一 grid，并把最后一条事件描述写入 TxtContent。
---@param eventRewardCfg XTablePunishaarEventReward Id/GoldCount/CardId/CardLevel
---@param descText string 最后一条事件内容描述（奖励阶段显示在 TxtContent）
function XUiPunishaarEventSettlementPanelReward:Refresh(eventRewardCfg, descText)
    -- 文本赋值先于 reward 守护：即使 reward 配置缺失，描述文本仍显示
    if self.TxtContent then
        self.TxtContent.text = XUiHelper.ReplaceTextNewLine(descText or "")
    end
    if not eventRewardCfg then return end
    self:_HideAllGrids()

    local goldCount = eventRewardCfg.GoldCount
    local cardId = eventRewardCfg.CardId
    local level = eventRewardCfg.CardLevel

    if XTool.IsNumberValid(goldCount) then
        -- 金币奖励：显 GridCoin + 数量（图标走预制体默认）
        if self._GridCoinTr then
            self._GridCoinTr.gameObject:SetActiveEx(true)
        end
        if self._CoinText then
            self._CoinText.text = tostring(goldCount)
        end
    elseif XTool.IsNumberValid(cardId) then
        -- 卡牌奖励：按主/副卡分发
        if self._Control:IsMasterCard(cardId) then
            if self._GridCard then
                self._GridCard:Open()
                self._GridCard:Refresh({ CardId = cardId, Level = level })
            end
        elseif self._Control:IsSubCard(cardId) then
            if self._GridSubCard then
                self._GridSubCard:Open()
                self._GridSubCard:Refresh({ CardId = cardId, Level = level })
            end
        else
            XLog.Warning("[PunishaarEventSettlement] PanelReward:Refresh 未知卡牌类型，cardId=" .. tostring(cardId))
        end
    else
        XLog.Warning("[PunishaarEventSettlement] PanelReward:Refresh EventReward 无有效奖励字段，id=" .. tostring(eventRewardCfg.Id))
    end
end

function XUiPunishaarEventSettlementPanelReward:_HideAllGrids()
    if self._GridCard then self._GridCard:Close() end
    if self._GridSubCard then self._GridSubCard:Close() end
    if self._GridCoinTr then self._GridCoinTr.gameObject:SetActiveEx(false) end
end

return XUiPunishaarEventSettlementPanelReward
