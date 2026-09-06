local XUiGridPunishaarCollectionSubCard = XClass(XUiNode, "XUiGridPunishaarCollectionSubCard")

local function SetActive(node, value)
    node.gameObject:SetActiveEx(value)
end

function XUiGridPunishaarCollectionSubCard:OnStart()
    self.BtnClick:AddEventListener(function()
        self:OnClick()
    end)

    SetActive(self.PnlFrozen, false)
    SetActive(self.SelectEffect, false)
    SetActive(self.TagCheck, false)
    self:SetSelected(false)
end

function XUiGridPunishaarCollectionSubCard:Refresh(data)
    self._Data = data

    if not data then
        SetActive(self.PanelNone, true)
        SetActive(self.PanelCollectionLock, false)
        SetActive(self.PanelSubCard, false)
        return
    end

    local CardType = XMVCA.XPunishaar.EnumConst.CardType
    local isAwareness = data.Type == CardType.Awareness
    local isUnlocked = data.IsUnlocked == true

    SetActive(self.PanelNone, false)
    SetActive(self.PnlFrozen, false)
    SetActive(self.SelectEffect, false)
    SetActive(self.TagCheck, false)

    -- 未解锁状态
    SetActive(self.PanelCollectionLock, not isUnlocked)
    SetActive(
        self.GridSubCardRoleNone,
        not isUnlocked and isAwareness
    )
    SetActive(
        self.GridSubCardPatsNone,
        not isUnlocked and not isAwareness
    )

    -- 已解锁状态
    SetActive(self.PanelSubCard, isUnlocked)
    SetActive(
        self.GridSubCardRoleCollectionBg,
        isUnlocked and isAwareness
    )
    SetActive(
        self.GridSubCardPatsCollectionBg,
        isUnlocked and not isAwareness
    )
    SetActive(
        self.GridSubCardRole,
        isUnlocked and isAwareness
    )
    SetActive(
        self.GridSubCardPats,
        isUnlocked and not isAwareness
    )

    if not isUnlocked then
        return
    end

    local cfg = data.Config
        or self._Control:GetTablePunishaarCard(data.Id, true)

    if not cfg or string.IsNilOrEmpty(cfg.Icon) then
        return
    end

    local icon
    if isAwareness then
        icon = self.IconSubCardRole
    else
        icon = self.IconSubCardPats
    end


    if icon then
        icon:SetRawImage(cfg.Icon)
    end
end

function XUiGridPunishaarCollectionSubCard:Update(data)
    self:Refresh(data)
end

function XUiGridPunishaarCollectionSubCard:OnClick()
    if self._Data then
        self.Parent:OnSubCardClick(self._Data, self)
    end
end

function XUiGridPunishaarCollectionSubCard:SetSelected(value)
    SetActive(
        self.PanelCollectionSubCardSelect,
        value == true
    )
end


return XUiGridPunishaarCollectionSubCard