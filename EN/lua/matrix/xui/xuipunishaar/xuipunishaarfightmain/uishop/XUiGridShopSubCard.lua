--- 商店/装备栏副卡显示（对称于 UiFighting/XUiGridBattleSubCard）。
--- 局外副卡数据来源为 Server.XPunishaarMasterCard.SubCardId，仅按配置展示图标。
---
--- **意识 / 共鸣双轨（#71，#67 改 GroupControl）**：GroupControl 切 Role/Pet 组——有副卡按 _IsRoleTrack
---   （Type==Awareness→Role / Resonance→Pet）切 + SetRawImage 设图；空态按 hostCardType 切显对应空底图（底图在 GroupControl Group 内）。
---   PanelNone/PanelSubCard（空态/有副卡）显隐仍手动控制，GroupControl 只管各自内部 Role/Pet 轨。
---@class XUiGridShopSubCard: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field PanelNone @无副卡时的空状态根节点（空态 Role/Pet 底图受 GroupControl 控制）
---@field PanelSubCard @具体副卡显示的根节点（有副卡 Role/Pet grid+icon 受 GroupControl 控制）
---@field GroupControl XUiGroupControl 头像分组控制器（Role/Pet 两 Group：空态底图 + 有副卡 grid/icon 均按轨切；有副卡时 SetRawImage 设图）#67 #71
---@field PnlFrozen @冻结态根节点（本组件用于装备态副卡展示，无商品冻结语义 → 恒隐，防共用预制露出 #71）
local XUiGridShopSubCard = XClass(XUiNode, "XUiGridShopSubCard")

--- 装备态/详情槽位不表达商品冻结，通用预制的 PnlFrozen 恒隐（商品栏冻结走 XUiComShopSubCardItem）。
function XUiGridShopSubCard:OnStart()
    if self.PnlFrozen then
        self.PnlFrozen.gameObject:SetActiveEx(false)
    end
end

--- 判定副卡是否为"意识"轨（宿主=角色）。非意识（共鸣）走 Pats 轨。
---@param cardCfg XTablePunishaarCard|nil
---@return boolean
function XUiGridShopSubCard:_IsRoleTrack(cardCfg)
    return cardCfg ~= nil and cardCfg.Type == XMVCA.XPunishaar.EnumConst.CardType.Awareness
end

---@param subCardId number|nil 副卡模板 Id
---@param hostCardType number|nil 宿主主卡 Type（空态分轨用；无副卡时据此决定显哪张空态底图）
function XUiGridShopSubCard:Refresh(subCardId, hostCardType)
    if not subCardId or subCardId == 0 then
        self:_ShowNone(hostCardType)
        return
    end
    self:_ShowSubCard(subCardId)
end

---@param subCardId number
function XUiGridShopSubCard:_ShowSubCard(subCardId)
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

    -- 副卡头像：GroupControl 按 _IsRoleTrack（意识轨=Role / 共鸣轨=Pet）切 Group + SetRawImage 设图
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
--- hostCardType 未传时两张空底图都隐（无上下文，不猜）。
---@param hostCardType number|nil 宿主主卡 Type
function XUiGridShopSubCard:_ShowNone(hostCardType)
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

--- 显技能图标（敌人侧专用，与副卡 Refresh 区分：PanelNone 隐 + PanelSubCard 显 + GroupControl 设 SkillIcon）。
--- 不区分 Role/Pet 轨（技能图标无宿主 Type 关联），默认 Role 组显。
---@param skillIcon string 技能图标路径
function XUiGridShopSubCard:RefreshSkill(skillIcon)
    if self.PanelNone then
        self.PanelNone.gameObject:SetActiveEx(false)
    end
    if self.PanelSubCard then
        self.PanelSubCard.gameObject:SetActiveEx(true)
    end
    if self.GroupControl and not string.IsNilOrEmpty(skillIcon) then
        self.GroupControl:ChangeGroup("Role")
        self.GroupControl:SetRawImage(0, skillIcon)
    end
end

return XUiGridShopSubCard
