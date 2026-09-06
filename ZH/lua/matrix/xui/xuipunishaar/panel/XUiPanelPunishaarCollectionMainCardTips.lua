local XUiPanelPunishaarCollectionMainCard = require("XUi/XUiPunishaar/Panel/XUiPanelPunishaarCollectionMainCard")

---@class XUiPanelPunishaarCollectionMainCardTips: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
local XUiPanelPunishaarCollectionMainCardTips = XClass(XUiNode, "XUiPanelPunishaarCollectionMainCardTips")

local function SetActive(node, active)
    if node then
        node.gameObject:SetActiveEx(active)
    end
end

function XUiPanelPunishaarCollectionMainCardTips:OnStart()
    if self.PanelTop then
        self.MainCardPanel = XUiPanelPunishaarCollectionMainCard.New(self.PanelTop, self)
        self.MainCardPanel:Open()
    else
        XLog.Warning("[Punishaar] XUiPanelPunishaarCollectionMainCardTips: PanelTop节点缺失")
    end

    -- 图鉴详情不使用局内的标签栏、副卡装备槽和操作按钮。
    SetActive(self.PanelCardTag, false)
    SetActive(self.PanelSubCardSlot, false)
    SetActive(self.BtnLock, false)
    SetActive(self.PanelBuy, false)
    SetActive(self.PanelSell, false)
end

function XUiPanelPunishaarCollectionMainCardTips:RefreshCollection(detail)
    if not detail or not detail.cardId or detail.cardId == 0 then
        return
    end

    local collectionLocked = detail.collectionLocked == true

    SetActive(
        self.PanelTop_Collectionlock,
        collectionLocked
    )

    if collectionLocked then
        if self.MainCardPanel then
            self.MainCardPanel:Close()
        end

        if self.TxtDesc then
            SetActive(self.TxtDesc, true)

            local desc = self._Control:GetCollectionLockDesc() or ""

            self.TxtDesc.text = XUiHelper.ReplaceTextNewLine(desc)
        end

        return
    end

    local cardCfg = self._Control:GetTablePunishaarCard(
        detail.cardId,
        true
    )

    if not cardCfg then
        return
    end

    if self.MainCardPanel then
        self.MainCardPanel:Open()

        if detail.collectionSubCard == true then
            self.MainCardPanel:RefreshCollectionSubCard(detail.cardId)
        else
            self.MainCardPanel:SetCollectionSubCardMode(false, cardCfg)
            self.MainCardPanel:Refresh(detail)
        end
    end

    if self.TxtDesc then
        SetActive(self.TxtDesc, true)
        self.TxtDesc.text = self._Control:GetCardDesc(detail.cardId)
    end
end

return XUiPanelPunishaarCollectionMainCardTips