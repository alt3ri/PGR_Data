---@class XUiGridPunishaarCollectionCardSubCard: XUiNode
local XUiGridPunishaarCollectionCardSubCard = XClass(XUiNode, "XUiGridPunishaarCollectionCardSubCard")

local GROUP_KEY_ROLE = "Role"
local GROUP_KEY_PET = "Pet"

function XUiGridPunishaarCollectionCardSubCard:OnStart()
    if self.PnlFrozen then
        self.PnlFrozen.gameObject:SetActiveEx(false)
    end
end

---@param hostCardType number
function XUiGridPunishaarCollectionCardSubCard:Refresh(hostCardType)
    if self.PanelNone then
        self.PanelNone.gameObject:SetActiveEx(true)
    end

    if self.PanelSubCard then
        self.PanelSubCard.gameObject:SetActiveEx(false)
    end

    if not self.GroupControl then
        return
    end

    local CardType = XMVCA.XPunishaar.EnumConst.CardType
    local groupKey = hostCardType == CardType.Character and GROUP_KEY_ROLE or GROUP_KEY_PET

    self.GroupControl:ChangeGroup(groupKey)
end

return XUiGridPunishaarCollectionCardSubCard