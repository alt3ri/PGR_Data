--- 卡牌内部通用内容显示组件。因为卡牌多个状态的逻辑结构完全一致
---@class XUiComBattleCardShow: XUiNode
---@field protected _Control
---@field Parent
-- atk/cd 数值显示迁卡牌根节点 TagDamage/TagCD（grid 层 #79），本组件不再含
---@field ImgArrow @战斗专属节点，手动牌待激发时显示
---@field UiPunishaarCardHeadRole UnityEngine.RectTransform 角色类主卡头像节点（结构同 Pets，独立 GameObject）#67
---@field UiPunishaarCardHeadPet UnityEngine.RectTransform 辅助机类主卡头像节点（结构同 Role，独立 GameObject）#67
---@field UiPunishaarSubCard @副卡显示节点
---@field GroupLevelup @商店专属节点，战斗内默认隐藏
---@field LevelupGroup XUiPanelPunishaarLevelupGroup 升级组（prefab 有此节点时接，OnStart New 隐 CanLevelup/Levelup 防异常显；战斗不显可升级保持隐）
---@field RImgQualityBg @卡牌底图
---@field RImgFrontBg @卡牌前景遮罩图
---@field ImgBallInBg @消球底图，当卡牌有消球配置时（不为0）显示，否则隐藏
---@field ImgBallOutBg @产球底图，当卡牌有产球配置时（不为0）显示，否则隐藏
---@field ImgBall @球（产/消）数图标
---@field TxtRed UnityEngine.UI.Text 红球数字（配置缺图标时显数字，与 ImgBall 互斥）
---@field TxtYellow UnityEngine.UI.Text 黄球数字（同上）
---@field TxtBlue UnityEngine.UI.Text 蓝球数字（同上）
---@field RImgOutlineGroup @外描边Group（待激发态显隐）
---@field RImgOutline XUiComponent.XUiRawImage 外描边子图（Group 下，按 Size/Type 取 SizeOutline 设图）
---@field RImgLevelupFire UnityEngine.UI.RawImage 激活态火焰材质球节点（按 Type/Size 取 ActiveVFX 材质球赋 .material）#LevelupFire
local XUiComBattleCardShow = XClass(XUiNode, "XUiComBattleCardShow")

local XUiGridBattleSubCard = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiGridBattleSubCard")
local XUiCardBgApplier = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiCardBgApplier")
local XUiPunishaarCardHead = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarCardHead")
local CardBgSettingsReader = require("XModule/XPunishaar/SubModules/InGame/XPunishaarCardBgSettingsReader")
local XUiPanelPunishaarLevelupGroup = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/Com/XUiPanelPunishaarLevelupGroup")

function XUiComBattleCardShow:OnStart()
    self:_HideShopNodes()

    -- LevelupGroup（prefab 有此节点时接，OnStart 隐 CanLevelup/Levelup 防异常显；战斗不显可升级保持隐）
    if self.LevelupGroup then
        ---@type XUiPanelPunishaarLevelupGroup
        self._LevelupGroup = XUiPanelPunishaarLevelupGroup.New(self.LevelupGroup, self)
    end

    if self.UiPunishaarSubCard then
        ---@type XUiGridBattleSubCard
        self.SubCard = XUiGridBattleSubCard.New(self.UiPunishaarSubCard, self)
        self.SubCard:Open()
    end
    -- 主卡头像：Role/Pets 两个独立 head XUiNode（各绑 ImgHead+ImgFrozen），战中无冻结 frozen=false。#67
    if self.UiPunishaarCardHeadRole then
        self._HeadRole = XUiPunishaarCardHead.New(self.UiPunishaarCardHeadRole, self)
        self._HeadRole:Close()
    end
    if self.UiPunishaarCardHeadPet then
        self._HeadPets = XUiPunishaarCardHead.New(self.UiPunishaarCardHeadPet, self)
        self._HeadPets:Close()
    end
    -- 卡牌视觉框 Applier（底图/前遮/球值标签，#64）
    self._BgApplier = XUiCardBgApplier.New(self)
    
end

function XUiComBattleCardShow:OnEnable()
    -- Open LevelupGroup（触发 OnStart 首次初始隐 CanLevelup/Levelup；战斗不 SetCanLevelUp 保持隐）
    -- 必须 Open：#108 不 Open 致 OnStart 不触发，CanLevelup/Levelup 不隐 prefab 默认显异常（违背"战斗不显可升级保持隐"）
    if self._LevelupGroup and not self._LevelupGroup:IsNodeShow() then
        self._LevelupGroup:Open()
    end
end

function XUiComBattleCardShow:OnDisable()
    -- Close 两个 head + LevelupGroup：避 Open 态子节点挂 activeSelf=false 祖先下 re-enable 级联报错。#67
    if self._HeadRole then self._HeadRole:Close() end
    if self._HeadPets then self._HeadPets:Close() end
    if self._LevelupGroup then self._LevelupGroup:Close() end
end

--- 主卡头像按 Type 二选一显隐（Character→Role / Weapon(辅助机)→Pets）+ 刷新图标。
--- 私有方法：head 对是本 CardShow 子节点，选型归父对象管（项目禁类静态方法）。战中无冻结 frozen=false。#67
---@param cardCfg XTablePunishaarCard|nil
function XUiComBattleCardShow:_RefreshCardHead(cardCfg)
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
        active:Refresh(cardCfg and cardCfg.Icon, false, cardCfg and cardCfg.Id)
    elseif cardCfg then
        XLog.Warning("[ComBattleCardShow] _RefreshCardHead: 匹配 head 缺失 cardId=%s Type=%s isRole=%s roleExist=%s petsExist=%s",
            tostring(cardCfg.Id), tostring(cardCfg.Type), tostring(isRole),
            tostring(self._HeadRole ~= nil), tostring(self._HeadPets ~= nil))
    end
end

--- 仅刷球数显示（消球/产球变化，不全量 Refresh 避 Close all + 重建 grid）。
---@param uid number
---@param reader XPunishaarSTEReader
---@param cardCfg XTablePunishaarCard
function XUiComBattleCardShow:RefreshBallCount(uid, reader, cardCfg)
    if self._BgApplier and cardCfg then
        local gc = self._Control.GameControl
        local level = reader:GetCardLevel(uid)
        local levelCfg = gc.FightControl:GetTablePunishaarCardLevel((cardCfg.Id or 0) * 100 + level)
        local configConsume = levelCfg and levelCfg.BallConsume or 0
        local configOutPut = levelCfg and levelCfg.BallOutPut or 0
        self._BgApplier:Refresh(gc, cardCfg.Id, cardCfg.Type, cardCfg.Size, level, cardCfg.Color,
            configConsume, configOutPut,
            reader:GetCardBallConsume(uid) or 0, reader:GetCardBallProduct(uid) or 0)
    end
end

---@param uid number 卡牌实体 uid
---@param reader XPunishaarSTEReader 只读视图
---@param cardCfg XTablePunishaarCard 卡牌配置
function XUiComBattleCardShow:Refresh(uid, reader, cardCfg)
    -- 主卡头像：Role/Pets 按 Type 二选一（战中无冻结 frozen=false）#67
    self:_RefreshCardHead(cardCfg)

    -- atk/cd 数值显示迁卡牌根节点 TagDamage/TagCD（grid 层 #79），本组件不再含

    if self.ImgArrow then
        local showArrow = reader:IsCardByHand(uid) and reader:IsCardWaitingDone(uid)
        self.ImgArrow.gameObject:SetActiveEx(showArrow)
    end

    -- 卡牌视觉框（底图/前遮/球值标签，替代停用的 _RefreshConsumeBalls，#64）
    -- 数据源：reader（运行时实体，effect 作用后最终值——球数可能被 ModifyNumberField 改）
    if self._BgApplier then
        local level = reader:GetCardLevel(uid)
        local fightControl = self._Control.GameControl.FightControl
        local levelCfg = fightControl:GetTablePunishaarCardLevel((cardCfg and cardCfg.Id or 0) * 100 + level)
        local configConsume = levelCfg and levelCfg.BallConsume or 0
        local configOutPut = levelCfg and levelCfg.BallOutPut or 0
        self._BgApplier:Refresh(
            self._Control.GameControl,
            cardCfg and cardCfg.Id,
            cardCfg and cardCfg.Type,
            cardCfg and cardCfg.Size,
            level,
            cardCfg and cardCfg.Color,
            configConsume, configOutPut,
            reader:GetCardBallConsume(uid) or 0,
            reader:GetCardBallProduct(uid) or 0)
    end

    -- 外描边 Group 显隐 + RImgOutline 子图设图（按 Type/Size 取 SizeOutline 外发光图）#64
    if self.RImgOutlineGroup then
        local gc = self._Control.GameControl
        local outlineSprite = gc and cardCfg and CardBgSettingsReader.GetOutlineSprite(gc, cardCfg.Type, cardCfg.Size) or nil
        local showOutline = (reader:IsCardByHand(uid) and reader:IsCardWaitingDone(uid)) and outlineSprite ~= nil
        if outlineSprite and self.RImgOutline then
            self.RImgOutline:SetRawImage(outlineSprite)
        end
        self.RImgOutlineGroup.gameObject:SetActiveEx(showOutline)
    end

    if self.SubCard then
        local subCardId = reader:GetCardSubCardInfo(uid)
        -- 传宿主主卡 Type：有副卡时副卡自身 Type 决定轨，无副卡时据宿主 Type 显对应空态底图（#71）
        self.SubCard:Refresh(subCardId, cardCfg and cardCfg.Type)
    end
end


function XUiComBattleCardShow:_HideShopNodes()
    if self.GroupLevelup then self.GroupLevelup.gameObject:SetActiveEx(false) end
end

return XUiComBattleCardShow
