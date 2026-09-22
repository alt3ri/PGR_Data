local XUiPanelPunishaarCollectionCard = XClass(XUiNode, "XUiPanelPunishaarCollectionCard")
local XUiPunishaarCollectionCardBgApplier = require("XUi/XUiPunishaar/Panel/XUiPunishaarCollectionCardBgApplier")
local XUiPunishaarCollectionCardHead = require("XUi/XUiPunishaar/Panel/XUiPunishaarCollectionCardHead")
local CardBgSettingsReader = require("XUi/XUiPunishaar/Panel/XUiPunishaarCollectionCardBgSettingsReader")
local XUiGridPunishaarCollectionCardSubCard = require("XUi/XUiPunishaar/Grid/XUiGridPunishaarCollectionCardSubCard")

function XUiPanelPunishaarCollectionCard:OnStart()
    -- PanelDisable 已弃用（#71 改为 PanelNormal 内 PnlDisable 半透明遮罩控显隐）
    self.StatusPanels = { self.PanelCollectionLock, self.PanelNormal, self.PanelNone }

    self._BgApplier = XUiPunishaarCollectionCardBgApplier.New(self)
    
    self.BtnClick:AddEventListener(function ()
        self:OnClick()
    end)

    self._HeadRole = XUiPunishaarCollectionCardHead.New(
        self.UiPunishaarCardHeadRole,
        self
    )
    self._HeadRole:Close()

    self._HeadPets = XUiPunishaarCollectionCardHead.New(
        self.UiPunishaarCardHeadPets,
        self
    )
    self._HeadPets:Close()

    self.SubCard = XUiGridPunishaarCollectionCardSubCard.New(
        self.UiPunishaarSubCard,
        self
    )
    self.SubCard:Close()
end

function XUiPanelPunishaarCollectionCard:Refresh(data)
    self._Data = data

    self._HeadRole:Close()
    self._HeadPets:Close()

    if self.SubCard then
        self.SubCard:Close()
    end
    
    for _, panel in pairs(self.StatusPanels) do
        panel.gameObject:SetActiveEx(false)
    end

    if not data then
        self.PanelNone.gameObject:SetActiveEx(true)
        return
    end

    local cfg = data.Config or self._Control:GetTablePunishaarCard(data.Id, true)

    if not cfg then
        self.PanelNone.gameObject:SetActiveEx(true)
        return
    end

    self._CardType = cfg.Type

    local selectSprite = CardBgSettingsReader.GetCollectionSelectSprite(
        self._Control,
        cfg.Type,
        cfg.Size
    )

    self._HasSelectSprite = not string.IsNilOrEmpty(selectSprite)

    local CardType = XMVCA.XPunishaar.EnumConst.CardType

    if self._HasSelectSprite then
        if cfg.Type == CardType.Character then
            self.ImgCollectionSelectRole:SetRawImage(selectSprite)
        elseif cfg.Type == CardType.Weapon then
            self.ImgCollectionSelectPets:SetRawImage(selectSprite)
        end
    end

    local isUnlocked = data.IsUnlocked == true

    self.PanelNormal.gameObject:SetActiveEx(isUnlocked)
    self.PanelCollectionLock.gameObject:SetActiveEx(not isUnlocked)

    if not isUnlocked then
        local isRole = cfg.Type == CardType.Character
        local isPets = cfg.Type == CardType.Weapon

        self.PanelCollectionLockRole.gameObject:SetActiveEx(isRole)
        self.PanelCollectionLockPets.gameObject:SetActiveEx(isPets)

        local lockSprite = CardBgSettingsReader.GetCollectionLockSprite(self._Control, cfg.Type, cfg.Size)

        if not string.IsNilOrEmpty(lockSprite) then
            if isRole then
                self.RImgCollectionLockRole:SetRawImage(lockSprite)
            elseif isPets then
                self.RImgCollectionLockPets:SetRawImage(lockSprite)
            end
        end

        return
    end

    if self.SubCard then
        self.SubCard:Open()
        self.SubCard:Refresh(cfg.Type)
    end
    
    self:RefreshCardHead(cfg)

    local level = data.Level or 1
    local levelCfg = self._Control:GetTablePunishaarCardLevelByCardIdAndLevel(cfg.Id, level, true)
    self._BgApplier:Refresh(
        self._Control,
        cfg.Type,
        cfg.Size,
        level,
        cfg.Color,
        levelCfg and levelCfg.BallConsume or 0,
        levelCfg and levelCfg.BallOutPut or 0
    )

    self.TxtDamage.text = levelCfg and tostring(levelCfg.ATK or 0) or "0"

    local cd = levelCfg and levelCfg.CD or 0
    self.TxtCD.text = string.format("%.1f", cd / 1000)
end

function XUiPanelPunishaarCollectionCard:Update(data, index)
    self:Refresh(data)
end

function XUiPanelPunishaarCollectionCard:OnClick()
    if not self._Data then
        return
    end

    -- 未解锁卡也允许选中，用于显示“首次获得后解锁”。
    self.Parent:OnCardClick(self._Data, self)
end

function XUiPanelPunishaarCollectionCard:SetSelected(value)
    self._IsSelected = value == true

    local CardType = XMVCA.XPunishaar.EnumConst.CardType
    local show = self._IsSelected and self._HasSelectSprite == true

    self.PanelCollectionGridCardSelect.gameObject:SetActiveEx(show)

    self.ImgCollectionSelectRole.gameObject:SetActiveEx(
        show and self._CardType == CardType.Character
    )

    self.ImgCollectionSelectPets.gameObject:SetActiveEx(
        show and self._CardType == CardType.Weapon
    )
end

function XUiPanelPunishaarCollectionCard:RefreshCardHead(cfg)
    local CardType = XMVCA.XPunishaar.EnumConst.CardType
    local activeHead
    local inactiveHead

    if cfg.Type == CardType.Character then
        activeHead = self._HeadRole
        inactiveHead = self._HeadPets
    else
        activeHead = self._HeadPets
        inactiveHead = self._HeadRole
    end

    if inactiveHead then
        inactiveHead:Close()
    end

    if activeHead then
        activeHead:Open()
        activeHead:Refresh(
            cfg.Icon,
            cfg.Id
        )
    else
        XLog.Warning(
            "[PunishaarCollection] 头像节点缺失, cardId=%s, type=%s",
            tostring(cfg.Id),
            tostring(cfg.Type)
        )
    end
end

return XUiPanelPunishaarCollectionCard
