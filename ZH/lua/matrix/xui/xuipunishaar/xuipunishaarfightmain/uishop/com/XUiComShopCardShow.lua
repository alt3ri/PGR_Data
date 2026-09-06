--- 商店卡牌内容通用显示组件（商品模式 / 装备栏模式共用，内部按模式分支）。
--- 对称于 UiFighting/Com/XUiComBattleCardShow，商店内所有需要展示卡牌内容的地方均通过本组件。
---
--- 惰性刷新：对外 RefreshAsGoods / RefreshAsEquipped 只缓存数据 + 置脏，
---   仅当自身显示中(IsNodeShow)才立刻刷新；隐藏时只缓存不刷，等 OnEnable 补刷。
---   （父节点 XUiGridShopCard 现只挂唯一一份本组件于 PanelNormal；#71 起禁用态改由
---    PanelNormal 内 PnlDisable 半透明遮罩表达，不再有 PanelDisable 双实例。惰性刷新
---    仍有效：grid 在副卡商品态会 Close 本组件，切回主卡态 Open 时借 OnEnable 补刷。）
---@class XUiComShopCardShow: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field UiPunishaarCardHeadRole UnityEngine.RectTransform 角色类主卡头像节点（结构同 Pets，独立 GameObject）#67
---@field UiPunishaarCardHeadPets UnityEngine.RectTransform 辅助机类主卡头像节点（结构同 Role，独立 GameObject）#67
-- atk/cd 数值显示迁卡牌根节点 TagDamage/TagCD（XUiPunishaarCardValueTag，grid 层 #79），本组件不再含
---@field TxtLevel TMPro.TextMeshProUGUI 卡牌等级
---@field LevelupGroup XUiPanelPunishaarLevelupGroup 升级组（控制节点始终显；含 CanLevelup+Levelup 子节点；可升级显 CanLevelup+TagLevelupEnable loop，升级执行显 Levelup+LevelupSweep 播完隐，无升级状态都隐）
---@field UiPunishaarSubCard @副卡显示节点
---@field RImgQualityBg @卡牌底图
---@field RImgFrontBg @卡牌前景遮罩图
---@field ImgBallInBg @消球底图，当卡牌有消球配置时（不为0）显示，否则隐藏
---@field ImgBallOutBg @产球底图，当卡牌有产球配置时（不为0）显示，否则隐藏
---@field ImgBall @球（产/消）数图标
---@field TxtRed UnityEngine.UI.Text 红球数字（配置缺图标时显数字，与 ImgBall 互斥）
---@field TxtYellow UnityEngine.UI.Text 黄球数字（同上）
---@field TxtBlue UnityEngine.UI.Text 蓝球数字（同上）
---@field PnlDisable @禁用态半透明遮罩根节点（#71 起替代已弃用的 PanelDisable 整套重复节点；仅控显隐）
---@field RImgDisable UnityEngine.UI.RawImage 禁用态遮罩图（与战中 CD 遮罩共用 MaskBgs 配置，按 Role/Partner+Size 取图）#71
---@field TagLevelUpEffectMask UnityEngine.UI.RawImage 升级特效遮罩图（与 RImgDisable 共用 MaskBgs 配置字段，按 cardCfg.Type+Size 取图；显隐归 prefab/CanLevelup(LevelupGroup) 联动，本组件只按样式设图）#升级特效遮罩
---@field RImgOutlineGroup @外描边选中态Group（点击打开 Tips 期间显）
---@field RImgOutline XUiComponent.XUiRawImage 外描边子图（Group 下，按 Size/Type 取 OutlineBgs 设图）
local XUiComShopCardShow = XClass(XUiNode, "XUiComShopCardShow")

local XUiGridShopSubCard = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopSubCard")
local XUiCardBgApplier = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiCardBgApplier")
local XUiPunishaarCardHead = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarCardHead")
local CardBgSettingsReader = require("XModule/XPunishaar/SubModules/InGame/XPunishaarCardBgSettingsReader")
local XUiPanelPunishaarLevelupGroup = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/Com/XUiPanelPunishaarLevelupGroup")

function XUiComShopCardShow:OnStart()
    if self.UiPunishaarSubCard then
        ---@type XUiGridShopSubCard
        self.SubCard = XUiGridShopSubCard.New(self.UiPunishaarSubCard, self)
        self.SubCard:Open()
    end
    -- 升级组：XUiNode 初始化但不 Open（控制节点始终显示，GO 随父 CardShow 显隐；PlayAnimation 只需 GO activeInHierarchy 不需 Open）
    if self.LevelupGroup then
        ---@type XUiPanelPunishaarLevelupGroup
        self._LevelupGroup = XUiPanelPunishaarLevelupGroup.New(self.LevelupGroup, self)
    end
    -- 主卡头像：Role/Pets 两个独立 head XUiNode（各绑 ImgHead+ImgFrozen），RefreshPair 按 Type 二选一显隐。#67
    if self.UiPunishaarCardHeadRole then
        self._HeadRole = XUiPunishaarCardHead.New(self.UiPunishaarCardHeadRole, self)
        self._HeadRole:Close()
    end
    if self.UiPunishaarCardHeadPets then
        self._HeadPets = XUiPunishaarCardHead.New(self.UiPunishaarCardHeadPets, self)
        self._HeadPets:Close()
    end
    -- 卡牌视觉框 Applier（底图/前遮/球值标签，#64）
    self._BgApplier = XUiCardBgApplier.New(self)
    -- 禁用态遮罩默认隐（#71）；遮罩图在 _RefreshBase 按卡型设置
    self._IsDisableMaskOn = false
    if self.PnlDisable then
        self.PnlDisable.gameObject:SetActiveEx(false)
    end
end

--- 禁用态半透明遮罩显隐（#71 起替代 PanelDisable 双实例互斥方案）。
--- 由父 grid 的 SetDisable 转发；遮罩节点在本组件子树内，故控制权在此。
--- 遮罩图由 _RefreshDisableMaskSprite 在刷新时按卡型设好，此处只管显隐。
---@param isDisable boolean
function XUiComShopCardShow:SetDisableMask(isDisable)
    self._IsDisableMaskOn = isDisable == true
    self:_ApplyDisableMaskActive()
end

--- 升级执行后调（仅装备态玩家拥有卡；商品态商品是升级材料被消耗不"被升级"不调）。
--- 转发 LevelupGroup:OnLevelupEvent：对称隐 CanLevelup + 显 Levelup + 播 LevelupSweep（播完隐）。
--- 调用时机由升级事件 hook（XUiGridShopCard 升级后调 OnLevelupEvent，等级变化判断）。
function XUiComShopCardShow:OnLevelupEvent()
    -- 仅装备态（玩家拥有卡）执行升级动画；商品态商品不被升级
    if self._PendingMode ~= "Equipped" then
        return
    end
    if self._LevelupGroup then
        self._LevelupGroup:OnLevelupEvent()
    end
end

--- 刷新禁用态遮罩图：与战中 CD 遮罩（GridBattleCard 的 PnlMask）**共用 MaskBgs 配置字段**，
--- 按 Role/Partner（cardCfg.Type）+ Size 取对应尺寸的遮罩图。图变跳过（per-card-change 非热路径）。
--- 配置缺失（返 nil）时遮罩恒隐——无图的遮罩显示出来是纯色块，不如不显。
---@param cardCfg XTablePunishaarCard|nil
function XUiComShopCardShow:_RefreshDisableMaskSprite(cardCfg)
    if not self.RImgDisable then
        return
    end
    local gc = self._Control and self._Control.GameControl
    local sprite = (gc and cardCfg)
            and CardBgSettingsReader.GetMaskSprite(gc, cardCfg.Type, cardCfg.Size)
            or nil
    if self._LastDisableMaskSprite ~= sprite then
        self._LastDisableMaskSprite = sprite
        if sprite and sprite ~= "" then
            self.RImgDisable:SetRawImage(sprite)
        end
    end
    self:_ApplyDisableMaskActive()
end

--- 刷新升级特效遮罩图：与禁用态遮罩（RImgDisable）**共用 MaskBgs 配置字段**，按 cardCfg.Type+Size 取对应遮罩图。
--- 显隐归 prefab/CanLevelup(LevelupGroup) 联动（升级特效触发时显），本方法只按样式设遮罩图，图变跳过（per-card-change 非热路径）。
---@param cardCfg XTablePunishaarCard|nil
function XUiComShopCardShow:_RefreshLevelUpEffectMaskSprite(cardCfg)
    if not self.TagLevelUpEffectMask then
        return
    end
    local gc = self._Control and self._Control.GameControl
    local sprite = (gc and cardCfg)
            and CardBgSettingsReader.GetMaskSprite(gc, cardCfg.Type, cardCfg.Size)
            or nil
    if self._LastLevelUpEffectMaskSprite ~= sprite then
        self._LastLevelUpEffectMaskSprite = sprite
        if sprite and sprite ~= "" then
            self.TagLevelUpEffectMask:SetRawImage(sprite)
        end
    end
end

--- 遮罩实际显隐 = 置灰态开启 且 有图（两者任一不满足则隐）。
function XUiComShopCardShow:_ApplyDisableMaskActive()
    if not self.PnlDisable then
        return
    end
    local hasSprite = self._LastDisableMaskSprite ~= nil and self._LastDisableMaskSprite ~= ""
    self.PnlDisable.gameObject:SetActiveEx(self._IsDisableMaskOn == true and hasSprite)
end

--- 产球消球组（GroupBall）显隐总开关。
--- 控父节点而非单独控子节点：GroupBall 下含 ImgBallInBg/OutBg/Img + 纯效果节点，纯效果节点不受 _BgApplier 控，
--- 故控父节点整组显隐（主卡商品显 / 副卡商品隐）。#80
--- 父节点用已有球子节点引用 .transform.parent 取（代码未绑 GroupBall @field，基于代码引用推父）。
---@param active boolean
function XUiComShopCardShow:SetBallGroupActive(active)
    local ballNode = self.ImgBallInBg or self.ImgBallOutBg or self.ImgBall
    if not ballNode then return end
    local groupBall = ballNode.transform.parent
    if not XTool.UObjIsNil(groupBall) then
        groupBall.gameObject:SetActiveEx(active)
    end
end

--- 显隐真实生命周期钩子：显示时补刷缓存的最新数据（惰性刷新的兑现点）。
function XUiComShopCardShow:OnEnable()
    -- Open LevelupGroup（触发 OnStart 首次初始隐 CanLevelup/Levelup；后续 OnEnable 幂等）
    -- 必须 Open：#108 不 Open 致 OnStart 不触发，CanLevelup/Levelup 不隐 prefab 默认显异常
    if self._LevelupGroup and not self._LevelupGroup:IsNodeShow() then
        self._LevelupGroup:Open()
    end
    self:_FlushIfDirty()
end

function XUiComShopCardShow:OnDisable()
    -- Close 两个 head + LevelupGroup：避 Open 态子节点挂 activeSelf=false 祖先下，容器 re-enable 时 EnableChildNodes 级联报错。#67
    if self._HeadRole then self._HeadRole:Close() end
    if self._HeadPets then self._HeadPets:Close() end
    if self._LevelupGroup then self._LevelupGroup:Close() end
end

--- 商品模式（商店待售卡牌，含商店专属标签）。对外入口：只缓存 + 置脏，显示中才立刻刷。
---@param goods table Server.XPunishaarGoods
function XUiComShopCardShow:RefreshAsGoods(goods)
    self._PendingMode = "Goods"
    self._PendingData = goods
    self._Dirty = true
    if self:IsNodeShow() then
        self:_FlushIfDirty()
    end
end

--- 装备栏模式（对战区已有卡牌，不显示商店专属标签）。对外入口：只缓存 + 置脏，显示中才立刻刷。
---@param card table Server.XPunishaarMasterCard
function XUiComShopCardShow:RefreshAsEquipped(card)
    self._PendingMode = "Equipped"
    self._PendingData = card
    self._Dirty = true
    if self:IsNodeShow() then
        self:_FlushIfDirty()
    end
end

--- 脏则按缓存的模式分派到对应私有刷新，再清脏。分派读缓存，但真正的 _DoRefreshAsXxx 无数据感知。
function XUiComShopCardShow:_FlushIfDirty()
    if not self._Dirty then
        return
    end
    if self._PendingMode == "Goods" then
        self:_DoRefreshAsGoods(self._PendingData)
    elseif self._PendingMode == "Equipped" then
        self:_DoRefreshAsEquipped(self._PendingData)
    end
    self._Dirty = false
end

--- 商品模式实际刷新（无数据感知：只吃入参 goods，不读实例缓存字段）。
---@param goods table Server.XPunishaarGoods
function XUiComShopCardShow:_DoRefreshAsGoods(goods)
    if not goods or goods.CardId == 0 then
        return
    end
    local cardCfg = self._Control:GetTablePunishaarCard(goods.CardId)
    local levelCfg = self._Control:GetTablePunishaarCardLevel(goods.CardId * 100 + goods.Level)
    self:_RefreshBase(cardCfg, levelCfg, goods.Level, goods.Frozen == true)
    self:_RefreshShopTags(goods)
    if self.SubCard then
        -- 商品态不显副卡；传宿主 Type 供空态底图分轨（意识/共鸣 #71）
        self.SubCard:Refresh(nil, cardCfg and cardCfg.Type)
    end
end

--- 装备栏模式实际刷新（无数据感知：只吃入参 card，不读实例缓存字段）。
---@param card table Server.XPunishaarMasterCard
function XUiComShopCardShow:_DoRefreshAsEquipped(card)
    if not card or card.TemplateId == 0 then
        return
    end
    local cardCfg = self._Control:GetTablePunishaarCard(card.TemplateId)
    local levelCfg = self._Control:GetTablePunishaarCardLevel(card.TemplateId * 100 + card.Level)
    -- 装备态球数走投影（装备即生效 effect 改产球/消球经 targetFieldEnum=8/9 投影反映），对称 ATK/CD grid 层投影范式 #88 球维度
    -- atk/cd 投影在 grid 层 XUiPunishaarCardValueTag（#79），球数经 _BgApplier 在本组件显，故此处自取投影球值
    local ballConsume = levelCfg and levelCfg.BallConsume or 0
    local ballOutPut = levelCfg and levelCfg.BallOutPut or 0
    local gc = self._Control.GameControl
    if gc then
        local proj = gc:GetCardRealtimeAtkCd(card.TemplateId, card.Level, card)
        -- GetCardRealtimeAtkCd 内部对非 FightArea/无 stage 走 _ProjectionFallback（球 base=levelCfg，delta=0），此处直接取
        ballConsume = (proj.ballConsumeBase or ballConsume) + (proj.ballConsumeDelta or 0)
        ballOutPut = (proj.ballOutPutBase or ballOutPut) + (proj.ballOutPutDelta or 0)
    end
    self:_RefreshBase(cardCfg, levelCfg, card.Level, false, ballConsume, ballOutPut)
    -- 装备栏升级标记：玩家主卡能被商店商品合成升级时 LevelupGroup 显 CanLevelup（_RefreshEquippedTags 算 canUpgrade）
    self:_RefreshEquippedTags(card)
    if self.SubCard then
        -- 传宿主主卡 Type：有副卡时副卡自身 Type 决定轨，无副卡时据宿主 Type 显对应空态底图（#71）
        self.SubCard:Refresh(card.SubCardId, cardCfg and cardCfg.Type)
    end
end

--- 主卡头像按 Type 二选一显隐（Character→Role / Weapon(辅助机)→Pets）+ 刷新图标 + 冻结态。
--- 私有方法：head 对是本 CardShow 的子节点，选型逻辑归父对象管（项目禁类静态方法）。#67
---@param cardCfg XTablePunishaarCard|nil
---@param frozen boolean
function XUiComShopCardShow:_RefreshCardHead(cardCfg, frozen)
    local isRole = cardCfg and cardCfg.Type == XMVCA.XPunishaar.EnumConst.CardType.Character
    -- 显式 if/else 取 active/inactive：避 Lua `cond and a or b` 在 a 为 nil 时回退到 b 的陷阱
    -- （Character 卡缺 Role head 时本应 Warning，需显式分支避免误显 Pets）
    local active, inactive
    if isRole then
        active = self._HeadRole
        inactive = self._HeadPets
    else
        active = self._HeadPets
        inactive = self._HeadRole
    end
    if inactive then
        inactive:Close()
    end
    if active then
        active:Open()
        active:Refresh(cardCfg and cardCfg.Icon, frozen, cardCfg and cardCfg.Id)
    elseif cardCfg then
        -- 诊断：匹配 Type 的 head 节点缺失（prefab 未挂该 head 的 UiObject 引用）
        XLog.Warning("[ComShopCardShow] _RefreshCardHead: 匹配 head 缺失 cardId=%s Type=%s isRole=%s roleExist=%s petsExist=%s",
            tostring(cardCfg.Id), tostring(cardCfg.Type), tostring(isRole),
            tostring(self._HeadRole ~= nil), tostring(self._HeadPets ~= nil))
    end
end

function XUiComShopCardShow:_RefreshBase(cardCfg, levelCfg, level, frozen, ballConsume, ballOutPut)
    -- 主卡头像：Role/Pets 按 Type 二选一，冻结态走 head 内 ImgFrozen（弃用卡牌根 PanelShopFreeze）#67
    self:_RefreshCardHead(cardCfg, frozen)

    -- 禁用态遮罩图：与战中 CD 遮罩共用 MaskBgs 配置（按 Role/Partner + Size 取图）#71
    self:_RefreshDisableMaskSprite(cardCfg)
    -- 升级特效遮罩图：与禁用态遮罩共用 MaskBgs 配置字段（按 cardCfg.Type+Size 取图，显隐归 prefab/CanLevelup(LevelupGroup) 联动）#升级特效遮罩
    self:_RefreshLevelUpEffectMaskSprite(cardCfg)

    if self.TxtLevel then
        self.TxtLevel.text = tostring(level)
    end

    -- atk/cd 数值显示迁卡牌根节点 TagDamage/TagCD（grid 层 XUiPunishaarCardValueTag #79），本组件不再含

    -- 卡牌视觉框（底图/前遮/球值标签，替代停用的 _RefreshConsumeBalls，#64）
    -- 球数数据源：调用方传值（装备态=投影 base+delta 反映装备即生效 effect 改产球/消球；商品态=levelCfg base）；未传 fallback levelCfg base #88 球维度
    if self._BgApplier then
        local configConsume = levelCfg and levelCfg.BallConsume or 0
        local configOutPut = levelCfg and levelCfg.BallOutPut or 0
        local realConsume = ballConsume or configConsume
        local realOutPut = ballOutPut or configOutPut
        self._BgApplier:Refresh(
            self._Control.GameControl,
            cardCfg and cardCfg.Id,
            cardCfg and cardCfg.Type,
            cardCfg and cardCfg.Size,
            level,
            cardCfg and cardCfg.Color,
            configConsume, configOutPut,
            realConsume, realOutPut)
    end
end


--- 商品模式升级标记：可升级时 LevelupGroup:SetCanLevelUp(true) 显 CanLevelup + 播 TagLevelupEnable loop。
function XUiComShopCardShow:_RefreshShopTags(goods)
    -- 升级组 LevelupGroup：可升级时 SetCanLevelUp(true) 显 CanLevelup + 播 TagLevelupEnable loop；
    -- 不可升级 SetCanLevelUp(false) 隐停。LevelupGroup 控制节点始终显（不 Open/Close），CanLevelup 子节点控显隐。
    local canUpgrade = false
    if self._LevelupGroup then
        canUpgrade = self._Control.GameControl:CanGoodsUpgradeOwnedCard(goods)
    end
    if self._LevelupGroup then
        self._LevelupGroup:SetCanLevelUp(canUpgrade)
    end
end

--- 装备栏模式升级标记（对称 _RefreshShopTags）：玩家主卡能被商店商品合成升级时 LevelupGroup:SetCanLevelUp(true)。
---@param card table Server.XPunishaarMasterCard
function XUiComShopCardShow:_RefreshEquippedTags(card)
    -- 升级组 LevelupGroup：对称 _RefreshShopTags，可升级 SetCanLevelUp(true) 显 CanLevelup + 播 loop / 不可升级隐停
    local canUpgrade = false
    if self._LevelupGroup then
        canUpgrade = self._Control.GameControl:CanOwnedCardUpgradeByShop(card)
    end
    if self._LevelupGroup then
        self._LevelupGroup:SetCanLevelUp(canUpgrade)
    end
end

return XUiComShopCardShow
