--- 副卡显示（战斗中）
--- 通用副卡预制结构与商店侧同构（#71，#67 改 GroupControl）：
---   GroupControl 切 Role/Pet 组——有副卡按 _IsRoleTrack（Type==Awareness→Role / Resonance→Pet）切 + SetRawImage 设图；
---   空态按 hostCardType 切显对应空底图（底图在 GroupControl Group 内）。
---   PanelNone/PanelSubCard（空态/有副卡）显隐仍手动控制，GroupControl 只管各自内部 Role/Pet 轨。
---@class XUiGridBattleSubCard: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field PanelNone @无副卡时的空状态根节点（空态 Role/Pet 底图受 GroupControl 控制）
---@field PanelSubCard @具体副卡显示的根节点（有副卡 Role/Pet grid+icon 受 GroupControl 控制）
---@field GroupControl XUiGroupControl 头像分组控制器（Role/Pet 两 Group：空态底图 + 有副卡 grid/icon 均按轨切；有副卡时 SetRawImage 设图）#67 #71
local XUiGridBattleSubCard = XClass(XUiNode, "XUiGridBattleSubCard")

--- 判定副卡是否为"意识"轨（宿主=角色）。非意识（共鸣）走 Pats 轨。
---@param cardCfg XTablePunishaarCard|nil
---@return boolean
function XUiGridBattleSubCard:_IsRoleTrack(cardCfg)
    return cardCfg ~= nil and cardCfg.Type == XMVCA.XPunishaar.EnumConst.CardType.Awareness
end

---@param subCardId number|nil 副卡模板 Id
---@param hostCardType number|nil 宿主主卡 Type（空态分轨用；无副卡时据此决定显哪张空态底图）
function XUiGridBattleSubCard:Refresh(subCardId, hostCardType)
    if not subCardId or subCardId == 0 then
        self:_ShowNone(hostCardType)
        return
    end
    self:_ShowSubCard(subCardId)
end

---@param subCardId number
function XUiGridBattleSubCard:_ShowSubCard(subCardId)
    local cardCfg = self._Control:GetTablePunishaarCard(subCardId, true)
    if not cardCfg then
        self:_ShowNone()
        return
    end
    if self.PanelNone then
        self.PanelNone.gameObject:SetActiveEx(false)
    end
    if self.PanelSubCard then
        self.PanelSubCard.gameObject:SetActiveEx(true)
    end

    -- 副卡头像：GroupControl 按 _IsRoleTrack（意识轨=Role / 共鸣轨=Pet）切组 + SetRawImage 设图
    if not self.GroupControl then
        return
    end
    local isRole = self:_IsRoleTrack(cardCfg)
    self.GroupControl:ChangeGroup(isRole and "Role" or "Pet")
    if not string.IsNilOrEmpty(cardCfg.Icon) then
        self.GroupControl:SetRawImage(0, cardCfg.Icon)
    end
end

--- 空态：按宿主主卡类型分轨显空底图（角色宿主→收意识，武器宿主→收共鸣）。
--- hostCardType 未传时 GroupControl 不切（无上下文，不猜）。
---@param hostCardType number|nil 宿主主卡 Type
function XUiGridBattleSubCard:_ShowNone(hostCardType)
    if self.PanelNone then
        self.PanelNone.gameObject:SetActiveEx(true)
    end
    if self.PanelSubCard then
        self.PanelSubCard.gameObject:SetActiveEx(false)
    end

    -- 空态 Role/Pet 底图用 GroupControl 切（空底图在 GroupControl Group 内，按宿主主卡 Type）
    if not self.GroupControl then
        return
    end
    local CardType = XMVCA.XPunishaar.EnumConst.CardType
    local isRoleHost = hostCardType == CardType.Character
    self.GroupControl:ChangeGroup(isRoleHost and "Role" or "Pet")
end

return XUiGridBattleSubCard
