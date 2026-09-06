--- 主卡内容显示组件（详情 Tips 内的卡牌本体展示）。
--- 对称于 UiShop/Com/XUiComShopCardShow 的卡牌内容部分，但不带商品/装备模式分支。
---@class XUiPanelPunishaarMainCard: XUiNode
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
local XUiPanelPunishaarMainCard = XClass(XUiNode, "XUiPanelPunishaarMainCard")
local CardBgSettingsReader = require("XModule/XPunishaar/SubModules/InGame/XPunishaarCardBgSettingsReader")
local XUiGridCardTag = require("XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/XUiGridCardTag")

-- ATK/CD 实时预览显示文案的字段下标约定：1=ATK、2=CD（与 ClientConfigKey.RealtimeValueShow* 的 Values 下标对齐）
local FIELD_INDEX_ATK = 1
local FIELD_INDEX_CD = 2

local function SetActive(node, value)
    node.gameObject:SetActiveEx(value)
end

function XUiPanelPunishaarMainCard:OnStart()
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

function XUiPanelPunishaarMainCard:OnDisable()
    -- 双 head 已移除，基类 OnDisable 接管（原 Close 双 head 防级联报错的逻辑随双 head 删除）
end

--- 主卡头像按 Type 切 Role/Pet 状态 + 设图（GroupControl 替代双 head）。#67
--- GroupControl:ChangeGroup("Role"/"Pet") 切状态（互斥显隐该组 GO）；SetRawImage(0, icon) 设当前组头像 RawImage（icon=cardCfg.Icon 路径 string，C# XUiGroupControl.SetRawImage 已接 string 路径）。
--- 双 head 已从详情移除（用户 2026-08-07 确认 prefab 节点不用守卫）；XUiPunishaarCardHead 类别处仍用，本 Panel 不再依赖。
---@param cardCfg XTablePunishaarCard|nil
function XUiPanelPunishaarMainCard:_RefreshCardHead(cardCfg, level, collectionMode)
    if not self.GroupControl then
        return
    end
    local isRole = cardCfg and cardCfg.Type == XMVCA.XPunishaar.EnumConst.CardType.Character
    local key = isRole and "Role" or "Pet"
    self.GroupControl:ChangeGroup(key)
    if cardCfg and not string.IsNilOrEmpty(cardCfg.Icon) then
        self.GroupControl:SetRawImage(0, cardCfg.Icon)
    end
    -- 主卡详情头像背景图：按等级从 PunishaarCardBgSettings 取 Role/PartnerMainDetailHeadBg，SetRawImage(1, bg)
    local bgSprite

    if collectionMode then
        bgSprite = CardBgSettingsReader.GetMainDetailHeadBg(
                self._Control,
                cardCfg and cardCfg.Type,
                level
        )
    else
        bgSprite = self._Control.GameControl:GetMainDetailHeadBg(
                cardCfg and cardCfg.Type,
                level
        )
    end

    if not string.IsNilOrEmpty(bgSprite) then
        self.GroupControl:SetRawImage(1, bgSprite)
    end
end

--- 刷新主卡内容。
---@param detail table 详情契约：{ cardId, level, masterCard? }；masterCard 非空且处 FightArea 走投影，否则显 base
function XUiPanelPunishaarMainCard:Refresh(detail)
    if not detail or not detail.cardId or detail.cardId == 0 then
        return
    end
    local cardId = detail.cardId
    local level = detail.level or 1
    local cardCfg = self._Control:GetTablePunishaarCard(cardId)
    -- 主卡头像：Role/Pets 按 Type 二选一（详情无冻结 frozen=false）#67
    self:_RefreshCardHead(cardCfg, level, detail.collectionMode)

    -- 卡牌名称（对应 PunishaarCard.Name）；镜像副卡 XUiPanelPunishaarSubCard.TxtCardName
    if self.TxtCardName and cardCfg then
        self.TxtCardName.text = cardCfg.Name or ""
    end

    -- ATK/CD 实时投影（装备即生效）：FightArea 走投影，商品态/Bag 走 fallback 显 base（delta=0）
    local proj

    if detail.collectionMode then
        -- 图鉴固定显示配置表一级数据，不计算局内加成。
        local levelCfg = self._Control:GetTablePunishaarCardLevel(
                cardId * 100 + level,
                true
        )

        proj = {
            atkBase = levelCfg and levelCfg.ATK or 0,
            atkDelta = 0,
            cdBaseMs = levelCfg and levelCfg.CD or 0,
            cdDeltaMs = 0,
        }
    else
        proj = self._Control.GameControl:GetCardRealtimeAtkCd(cardId, level, detail.masterCard)
    end

    -- ATK：最终值 = base + delta；floor 取整显隐浮点漂移，文案 format {0}=最终值文本
    -- Equal 用 Mathf.Approximately 在访问器内判定（吸收浮点漂移），故传 cur+base 而非 delta
    if self.TxtDamageNum then
        local atkCur = proj.atkBase + proj.atkDelta
        local atkValText = tostring(math.floor(atkCur))
        local atkFmt = self._Control:GetRealtimeValueShowText(atkCur, proj.atkBase, FIELD_INDEX_ATK)
        if not string.IsNilOrEmpty(atkFmt) then
            self.TxtDamageNum.text = XUiHelper.FormatTextEx(atkFmt, atkValText)
        else
            self.TxtDamageNum.text = atkValText
        end
    end

    -- CD：配置毫秒/1000=秒，保留一位小数；文案下标用 FIELD_INDEX_CD 与 ATK 分离
    if self.TxtCDNum then
        local cdCurMs = proj.cdBaseMs + proj.cdDeltaMs
        local cdValText = string.format("%.1f", cdCurMs / 1000)
        local cdFmt = self._Control:GetRealtimeValueShowText(cdCurMs, proj.cdBaseMs, FIELD_INDEX_CD)
        if not string.IsNilOrEmpty(cdFmt) then
            self.TxtCDNum.text = XUiHelper.FormatTextEx(cdFmt, cdValText)
        else
            self.TxtCDNum.text = cdValText
        end
    end

    -- 效果/构筑标签组：按 cardCfg.Tag 数量克隆 CardTag grid #78
    self:_RefreshCardTags(cardCfg)
end

--- 刷新卡牌标签组（GroupCardTag）：按 cardCfg.Tag 数组克隆 CardTag grid 显 Tag 图标+名称 #78。
--- Tag 数组读取：cardCfg.Tag 为 stab Tag[1]/Tag[2] 数组字段读成的 table，ipairs 遍历
---   （同 EnemySkill 范式，见 FightConfigControl:GetEnemyEffectGroupIds）。
--- 空 Tag / tagCfg 查不到（PunishaarCardTag 表数据未填）→ GroupCardTag 隐藏。
--- 访问链：self._Control（根 XPunishaarControl）:GetTablePunishaarCardTag 直达根 Control #78 修正，
---   局外图鉴模式（collectionMode）也走根 Control，无需 GameControl 存在性守卫。
---@param cardCfg XTablePunishaarCard|nil
function XUiPanelPunishaarMainCard:_RefreshCardTags(cardCfg)
    if not self.GroupCardTag then
        return
    end

    local count = 0

    if cardCfg and not XTool.IsTableEmpty(cardCfg.Tag) then
        count = #cardCfg.Tag
    end

    self.GroupCardTag.gameObject:SetActiveEx(count)

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

function XUiPanelPunishaarMainCard:SetCollectionSubCardMode(isSubCard, cardCfg)
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

function XUiPanelPunishaarMainCard:RefreshCollectionSubCard(cardId)
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

return XUiPanelPunishaarMainCard
