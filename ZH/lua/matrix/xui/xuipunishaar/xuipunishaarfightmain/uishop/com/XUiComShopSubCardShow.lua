--- 商店单独的副卡显示的外壳。
--- 挂在 XUiGridShopCard.PanelShopSubCard 下，内含 XUiComShopSubCardItem（副卡本体+拖拽主体）。
--- 仅商品栏售卖副卡时显示（grid Refresh IsSubCard 分流显隐）；副卡无置灰（仅商店单独显示，其余依附主卡）。
--- 副卡轨空底图（ImgNoneBgPets/ImgNoneBgRole）：按副卡 Type 互斥显——
---   意识(Awareness)用在角色→显 ImgNoneBgRole / 共鸣(Resonance)用在辅助机→显 ImgNoneBgPets（对齐 SubCardItem GroupControl Role/Pet 分轨）。
local XUiComShopSubCardItem = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/Com/XUiComShopSubCardItem")

---@class XUiComShopSubCardShow: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field UiPunishaarSubCard @副卡显示项节点（挂 XUiComShopSubCardItem，副卡本体+拖拽主体）
---@field ImgNoneBgRole UnityEngine.UI.RawImage 角色轨空底图（副卡 Type=意识 Awareness 用在角色→显，与 ImgNoneBgPets 互斥）
---@field ImgNoneBgPets UnityEngine.UI.RawImage 辅助机轨空底图（副卡 Type=共鸣 Resonance 用在辅助机→显，与 ImgNoneBgRole 互斥）
local XUiComShopSubCardShow = XClass(XUiNode, "XUiComShopSubCardShow")

function XUiComShopSubCardShow:OnStart()
    if self.UiPunishaarSubCard then
        ---@type XUiComShopSubCardItem
        self.SubCardItem = XUiComShopSubCardItem.New(self.UiPunishaarSubCard, self)
        self.SubCardItem:Open()
        -- 副卡拖拽主体 = UiPunishaarSubCard 节点（self.SubCardItem.Transform）；商品栏来源 Shop
        self.SubCardItem:EnableDrag(self._Control.GameControl.DragArea.Shop)
    end
    -- 轨空底图初始隐，由 Refresh 按副卡 Type 互斥显
    if self.ImgNoneBgRole then
        self.ImgNoneBgRole.gameObject:SetActiveEx(false)
    end
    if self.ImgNoneBgPets then
        self.ImgNoneBgPets.gameObject:SetActiveEx(false)
    end
end

--- 刷新副卡商品显示。
--- 轨空底图按副卡 Type 互斥显（意识→角色 / 共鸣→辅助机）；无副卡（goods/CardId=0）两者皆隐。
---@param goods table Server.XPunishaarGoods
---@param goodsIndex number 服务端槽位索引（0-based，供 SubCardItem 拖拽 _DragSourcePos）
function XUiComShopSubCardShow:Refresh(goods, goodsIndex)
    local hasCard = goods ~= nil and goods.CardId ~= 0
    local isRole = false
    if hasCard then
        local cardCfg = self._Control:GetTablePunishaarCard(goods.CardId, true)
        isRole = cardCfg ~= nil and cardCfg.Type == XMVCA.XPunishaar.EnumConst.CardType.Awareness
    end
    -- 互斥显轨空底图：有副卡时按 Type 二选一，无副卡两者皆隐
    if self.ImgNoneBgRole then
        self.ImgNoneBgRole.gameObject:SetActiveEx(hasCard and isRole)
    end
    if self.ImgNoneBgPets then
        self.ImgNoneBgPets.gameObject:SetActiveEx(hasCard and not isRole)
    end

    if self.SubCardItem then
        self.SubCardItem:Refresh(goods, goodsIndex)
    end
end

return XUiComShopSubCardShow
