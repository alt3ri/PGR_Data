--- 主卡内容显示组件（详情 Tips 内的卡牌本体展示）。
--- 对称于 UiShop/Com/XUiComShopCardShow 的卡牌内容部分，但不带商品/装备模式分支。
---@class XUiPanelPunishaarCollectionMainCard: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field GroupControl XUiGroupControl 头像分组控制器（Role/Pet 两 Group，按 Type ChangeGroup 切状态 + SetRawImage 设图）#67
---@field TxtCardName UnityEngine.UI.Text 卡牌名称文本（对应 PunishaarCard.Name）
---@field GroupStar @星级容器（正式 UI 不再通过星星数表示等级，整组隐藏 #57）
---@field GroupCardTag @效果/构筑标签组根节点（按 cardCfg.Tag 数量克隆 CardTag grid 显 Tag 图标+名称 #78）
---@field CardTag @单 Tag grid 模板节点（XUiGridCardTag，按 PunishaarCardTag.Id 显 Icon/Name #78）
---@field private _TagGridDict table<UnityEngine.GameObject, XUiGridCardTag> Tag grid 缓存（按 go 复用，零 GC #78）
---@field TxtDamageNum UnityEngine.UI.Text 伤害/攻击力数值（对应 PunishaarCardLevel.ATK）
---@field TxtCDNum UnityEngine.UI.Text CD 数值（对应 PunishaarCardLevel.CD）
local XUiPanelPunishaarCollectionMainCard = XClass(XUiNode, "XUiPanelPunishaarCollectionMainCard")
local XUiGridCardTag = require("XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/XUiGridCardTag")

local GROUP_KEY_ROLE = "Role"
local GROUP_KEY_PET = "Pet"

local function SetActive(node, value)
    node.gameObject:SetActiveEx(value)
end

function XUiPanelPunishaarCollectionMainCard:OnStart()
    -- 正式 UI 不再通过星星数表示等级，星级容器整组隐藏 #57
    if self.GroupStar then
        self.GroupStar.gameObject:SetActiveEx(false)
    end
    if self.GroupCardTag then
        -- GroupCardTag 容器默认隐藏，由 Refresh:_RefreshCardTags 按 Tag 数量显隐 #78
        self.GroupCardTag.gameObject:SetActiveEx(false)
    end
    -- CardTag 模板节点隐藏（克隆由 _RefreshCardTags 经 RefreshCustomizedList 接管）#78
    if self.CardTag then
        self.CardTag.gameObject:SetActiveEx(false)
    end
    -- 主卡头像：详情用 GroupControl（_RefreshCardHead 切 Role/Pet + SetRawImage），双 head 已移除 #67
end

--- 主卡头像按 Type 切 Role/Pet 状态 + 设图（GroupControl 替代双 head）。#67
--- GroupControl:ChangeGroup("Role"/"Pet") 切状态（互斥显隐该组 GO）；SetRawImage(0, icon) 设当前组头像 RawImage（icon=cardCfg.Icon 路径 string）。
---@param cardCfg XTablePunishaarCard|nil
function XUiPanelPunishaarCollectionMainCard:_RefreshCardHead(cardCfg)
    if not self.GroupControl or not cardCfg then
        return
    end
    local CardType = XMVCA.XPunishaar.EnumConst.CardType
    local groupKey = cardCfg.Type == CardType.Character and GROUP_KEY_ROLE or GROUP_KEY_PET
    self.GroupControl:ChangeGroup(groupKey)
    if not string.IsNilOrEmpty(cardCfg.Icon) then
        self.GroupControl:SetRawImage(0, cardCfg.Icon)
    end
end

--- 刷新主卡内容。
---@param detail table 详情契约：{ cardId, level }
function XUiPanelPunishaarCollectionMainCard:Refresh(detail)
    if not detail or not detail.cardId or detail.cardId == 0 then
        return
    end

    local cardId = detail.cardId
    local level = detail.level or 1
    local cardCfg = self._Control:GetTablePunishaarCard(cardId, true)

    if not cardCfg then
        return
    end

    self:_RefreshCardHead(cardCfg)

    if self.TxtCardName then
        self.TxtCardName.text = cardCfg.Name or ""
    end

    local levelCfg = self._Control:GetTablePunishaarCardLevelByCardIdAndLevel(cardId, level, true)
    if self.TxtDamageNum then
        local atk = levelCfg and levelCfg.ATK or 0
        self.TxtDamageNum.text = tostring(math.floor(atk))
    end

    if self.TxtCDNum then
        local cd = levelCfg and levelCfg.CD or 0
        self.TxtCDNum.text = string.format("%.1f", cd / 1000)
    end

    self:_RefreshCardTags(cardCfg)
end

--- 刷新卡牌标签组（GroupCardTag）：按 cardCfg.Tag 数组克隆 CardTag grid 显 Tag 图标+名称 #78。
--- Tag 数组读取：cardCfg.Tag 为 stab Tag[1]/Tag[2] 数组字段读成的 table，ipairs 遍历
---   （同 EnemySkill 范式，见 FightConfigControl:GetEnemyEffectGroupIds）。
--- 空 Tag / tagCfg 查不到（PunishaarCardTag 表数据未填）→ GroupCardTag 隐藏。
--- 访问链：self._Control（根 XPunishaarControl）:GetTablePunishaarCardTag 直达根 Control #78 修正，
---@param cardCfg XTablePunishaarCard|nil
function XUiPanelPunishaarCollectionMainCard:_RefreshCardTags(cardCfg)
    if not self.GroupCardTag then
        return
    end

    local count = 0

    if cardCfg and not XTool.IsTableEmpty(cardCfg.Tag) then
        count = #cardCfg.Tag
    end

    self.GroupCardTag.gameObject:SetActiveEx(count > 0)

    self.CardTag.gameObject:SetActiveEx(false)
    if self._TagGridDict == nil then
        self._TagGridDict = {}
    else
        for _, v in pairs(self._TagGridDict) do
            v:Close()
        end
    end
    
    XUiHelper.RefreshCustomizedList(self.GroupCardTag.transform, self.CardTag, count, function(index, go)
        local grid = self._TagGridDict[go]
        if not grid then
            grid = XUiGridCardTag.New(go, self)
            self._TagGridDict[go] = grid
        end
        grid:Open()
        local tagId = cardCfg.Tag[index]
        local tagCfg = self._Control:GetTablePunishaarCardTag(tagId)
        grid:Refresh(tagCfg)
    end)
end

function XUiPanelPunishaarCollectionMainCard:SetCollectionSubCardMode(isSubCard, cardCfg)
    local CardType = XMVCA.XPunishaar.EnumConst.CardType
    local isAwareness = cardCfg and cardCfg.Type == CardType.Awareness

    SetActive(
            self.GridSubCardRoleBg,
            isSubCard and isAwareness
    )

    SetActive(
            self.GridSubCardPatsBg,
            isSubCard and not isAwareness
    )

    SetActive(
            self.ImgQualityBgRole,
            not isSubCard and cardCfg and cardCfg.Type == CardType.Character
    )

    SetActive(
            self.ImgQualityBgPets,
            not isSubCard and cardCfg and cardCfg.Type == CardType.Weapon
    )

    SetActive(self.StatDamage, not isSubCard)
    SetActive(self.StatCD, not isSubCard)
end

function XUiPanelPunishaarCollectionMainCard:RefreshCollectionSubCard(cardId)
    local cardCfg = self._Control:GetTablePunishaarCard(cardId, true)

    if not cardCfg then
        return
    end

    self:SetCollectionSubCardMode(true, cardCfg)

    local CardType = XMVCA.XPunishaar.EnumConst.CardType
    local isAwareness = cardCfg.Type == CardType.Awareness

    local icon
    if isAwareness then
        icon = self.IconSubCardRole
    else
        icon = self.IconSubCardPats
    end

    if icon and not string.IsNilOrEmpty(cardCfg.Icon) then
        icon:SetSprite(cardCfg.Icon)
    end

    if self.TxtCardName then
        self.TxtCardName.text = cardCfg.Name or ""
    end
end

return XUiPanelPunishaarCollectionMainCard
