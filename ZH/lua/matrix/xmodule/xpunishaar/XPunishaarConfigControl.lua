---@type XPunishaarControl 配置部分类
local XPunishaarControl = XClassPartial("XPunishaarControl")

-- Unity 数学工具（Mathf.Approximately 用作浮点近似相等判断：相对容差按量级缩放，
-- 规避 CD 投影 frames/20*1000 换算与 ATK/CD 经 Multiply/Divide 后 1e-7 量级漂移被误判为变化）
local Mathf = CS.UnityEngine.Mathf

local CARD_LEVEL_ID_FACTOR = 100
-- ClientConfig Key 常量
local ClientConfigKey = {
    ShopBuySuccess     = "ShopBuySuccess",      -- 购买成功提示文本
    ShopSellSuccess    = "ShopSellSuccess",     -- 卖出成功提示文本
    ShopRefreshSuccess = "ShopRefreshSuccess",  -- 刷新成功提示文本
    ShopPriceText      = "ShopPriceText",       -- 商品价格富文本模板：Values[1]=金币够、[2]=不够，{0}=价格数字；策划用 <color> 标签配颜色
    BagCapacityText    = "BagCapacityText",     -- 背包容量文本模板：Values[1]=格式，{0}=当前占用、{1}=总容量（如 "{0}/{1}"）
    VsNotifyDuration   = "VsNotifyDuration",     -- 战斗开始 VSNotify 停留时长（秒）
    TipsMainCardPrefab = "TipsMainCardPrefab",  -- 主卡详情 prefab 路径
    TipsSubCardPrefab  = "TipsSubCardPrefab",   -- 副卡详情 prefab 路径
    TipsEnemyPrefab    = "TipsEnemyPrefab",     -- 敌人详情 prefab 路径
    DisplayReward =  "DisplayReward", --主界面奖励显示列表
    NodeIcon           = "NodeIcon",           -- 节点类型图标：Values[NodeType] = 图标路径（Shop/Event/Fight/ChoiceFight/Story）
    StageNotOpenTip = "StageNotOpenTip",                 -- 未解锁关卡的提示文本
    StageInProgressText = "StageInProgressText",         -- 普通关卡存在存档时的状态文本
    StageEndlessRoundText = "StageEndlessRoundText",     -- 无尽关卡存在存档时的轮次文本
    StageProgressText = "StageProgressText",             -- 关卡存档进度文本
    StageDetailNameText = "StageDetailNameText",         -- 关卡详情标题
    -- ATK/CD 实时预览（装备即生效投影）：format {0}=最终值文本，代码侧格式化数值，用户后填文本如 "↑{0}"/"↓{0}"/"{0}"
    -- ATK 与 CD 共用此三 key，以 Values 下标区分：约定 1=ATK、2=CD；
    --   同一 Key 行 Values[1] 填 ATK 文案、Values[2] 填 CD 文案，分离两者显示文案
    --   （如 CD 减小为正面却显示 ↓、ATK 增大显示 ↑，语义方向可独立配置，不再强绑同一文案）。
    RealtimeValueShowUp    = "RealtimeValueShowUp",    -- 最终值 > 配置值（Values[1]=ATK / [2]=CD）
    RealtimeValueShowDown  = "RealtimeValueShowDown",  -- 最终值 < 配置值（Values[1]=ATK / [2]=CD）
    RealtimeValueShowEqual = "RealtimeValueShowEqual", -- 最终值 == 配置值（Values[1]=ATK / [2]=CD）
    CollectionProgressColors = "CollectionProgressColors", --图鉴进度的文字颜色,
    CollectionLockDesc = "CollectionLockDesc", --图鉴锁定详情显示文案
    BattleEffectTangentHeight = "BattleEffectTangentHeight", --飞弹弧度高度（Y轴）：Values[1]=min, Values[2]=max
    BattleEffectTangentWidth = "BattleEffectTangentWidth", --飞弹水平偏移（X轴）：Values[1]=min, Values[2]=max（可为负/0，0=无偏移）
    MainShowCardIds = "MainShowCardIds", ---主界面模型站位显示主卡
    MainShowAnimas = "MainShowAnimas", ---主界面模型动作
    ShopRefreshCDTip = "ShopRefreshCDTip", --商店刷新CD拦截飘窗提示文本
    InitBallSlotCount = "InitBallSlotCount", --战斗初始球槽容量（_PrepareBattleData 设 initData:SetBallSlotCapacity）
    BallSlotMax = "BallSlotMax",             --球槽最大容量上限（initData 暂存，后续 effect 增容 clamp max）
    SaveCountLimitTipCode = "SaveCountLimitTipCode", -- 存档达到上限提示码
    StageUnlockTimeTip = "StageUnlockTimeTip", --关卡时间未开放文本提示
    BuffIcons = "BuffIcons",                 --状态图标：Values[1]=护盾（敌我共用）、[2]=敌人持续受伤（仅敌人）
}

-- ShareConfig（PunishaarConfig）Key 常量
local ConfigKey = {
    HPValue       = "HPValue",        -- 关卡开始时指挥官的初始血量值
    HPGrowthValue = "HPGrowthValue",  -- 每战斗胜利1次增加的指挥官血量值
    ShopRefresh   = "ShopRefresh",    -- 商店刷新费用：Param[1]=基础花费、Param[2]=每刷新一次增量
    EndlessStageBuff = "EndlessStageBuff", --无尽关多轮次敌人加成：Values[1]=额外HP, [2]=额外ATK（round>1 时 base+(round-1)×buff 累加，首轮不加）
    RemedyShopHudGroupId = "RemedyShopHudGroupId", --补强商店默认 HUD group：Param[1]=groupId（补强非独立节点无法配 StageContent.HudGroupId，共用此默认 group）#补强HUD
    MaxSaveCount = "MaxSaveCount", -- 最大存档数量
}

local TableKey = {
    PunishaarCardLevel = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PunishaarCardModel = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PunishaarCardBgSettings = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    -- 卡牌标签配置（Client 表 Id/Icon/Name）：主/副卡详情 Tag 显示接入 #78。
    -- 上提根 Control（同 CardBgSettings 语义，局外图鉴也需访问），FightControl 不再登记 #78 修正。
    PunishaarCardTag = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    -- Fight/Enemy/EnemySkill/Shop/CardSale + Effect/EffectGroup/Trigger 已上提到 GameControl（GameConfigControl）单点登记（#60 根治）。
    -- 本 Control 仅留玩法级表：Card/CardLevel（卡牌模板/等级，探索/选关/详情全期共用）+ CardModel（卡牌 3D 模型配置，#63）+ CardBgSettings/CardTag（卡牌显示配置，局外局内统一 #78）。
}

function XPunishaarControl:InitConfig()
    --初始化配置表
    self:InitConfigByTabKey("Punishaar", TableKey)
end

function XPunishaarControl:GetTablePunishaarCard(id, notips)
    return self:GetAgency():GetTablePunishaarCard(id, notips)
end

function XPunishaarControl:GetTablePunishaarCardCfgs()
    return self:GetAgency():GetTablePunishaarCardCfgs()
end

--- 等级配置 key = cardId * 100 + level
---@return XTablePunishaarCardLevel
function XPunishaarControl:GetTablePunishaarCardLevel(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarCardLevel, id, notips)
end

--- 卡牌 3D 模型配置（Id=卡牌模板Id key, ModelId=模型名string, NormalIdleAnima/AttackAnima=动画名string）。
--- 仅主卡 cardId 有行；非主卡/无行返回 nil（调用方 fallback 2D Icon）。#63
---@return XTablePunishaarCardModel
function XPunishaarControl:GetTablePunishaarCardModel(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarCardModel, id, notips)
end

--- 卡牌标签配置（Client 表 Id/Icon/Name），主/副卡详情 Tag 显示接入 #78。
--- 上提根 Control（局外图鉴也可访问），FightControl 不再登记 #78 修正。
---@return XTablePunishaarCardTag
function XPunishaarControl:GetTablePunishaarCardTag(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarCardTag, id, notips)
end

-- Effect/Trigger/Fight/Enemy/EnemySkill/Shop/CardSale 访问器已移至 GameControl（GameConfigControl），本 Control 不再提供（#60）。
-- 局外投影经 GetCardRealtimeAtkCd 传 GameControl；RunControl 路由/ControlShop 经 _MainControl 或 self.GameControl 借。

--- 卡牌模板的主/副大类（CarMainType）。查 PunishaarCard.Type 交由 Agency 按配置列表映射。
---@param cardId number 卡牌模板 Id
---@return number|nil CarMainType（Main/Sub），配置缺失返回 nil
function XPunishaarControl:GetCardMainType(cardId)
    local cardCfg = self:GetTablePunishaarCard(cardId, true)
    if not cardCfg then return nil end
    return XMVCA.XPunishaar:GetPunishaarCardMainType(cardCfg.Type)
end

--- 卡牌描述（含 DescParams 占位符替换 + 换行处理）。
--- Desc 用 {0}{1} 占位符引用数字，DescParams(string[]) 配置对应数字；各语言 tab 自配占位符语序，方便本地化拆分。
--- 无占位符或 DescParams 空 → 原样返回（FormatTextEx 自带 {0} 检测守卫兜底，过渡期老 desc 安全不报错）。
---@param cardId number 卡牌模板 Id
---@return string 描述文本（已替换占位符 + 换行处理；cardId 无效/Desc 空返回 ""）
function XPunishaarControl:GetCardDesc(cardId)
    local cardCfg = self:GetTablePunishaarCard(cardId, true)
    if not cardCfg or string.IsNilOrEmpty(cardCfg.Desc) then
        return ""
    end
    -- 顺序对齐 Theatre6 范式：先 ReplaceTextNewLine，再 Format 占位符
    local desc = XUiHelper.ReplaceTextNewLine(cardCfg.Desc)
    local params = cardCfg.DescParams
    if not XTool.IsTableEmpty(params) then
        desc = XUiHelper.FormatTextEx(desc, table.unpack(params))
    end
    return desc
end

--- 指定卡牌模板是否为主卡。
---@param cardId number 卡牌模板 Id
---@return boolean
function XPunishaarControl:IsMasterCard(cardId)
    return self:GetCardMainType(cardId) == XMVCA.XPunishaar.EnumConst.CarMainType.Main
end

--- 指定卡牌模板是否为副卡。
---@param cardId number 卡牌模板 Id
---@return boolean
function XPunishaarControl:IsSubCard(cardId)
    return self:GetCardMainType(cardId) == XMVCA.XPunishaar.EnumConst.CarMainType.Sub
end

-- GetTablePunishaarCardSale 已移至 GameControl（GameConfigControl）；ControlShop/UI 经 self.GameControl 借。


--- 获取关卡总节点数（StageContentIds 数组长度）。
---@param stageId number
---@return number
function XPunishaarControl:GetStageTotalNodeCount(stageId)
    local group = XMVCA.XPunishaar:GetTablePunishaarStageContentGroup(stageId, true)
    if not group or not group.StageContentIds then return 0 end
    return #group.StageContentIds
end

--- 获取当前节点序号：#stage.HistoryNodeList + 1（已过节点数 +1 = 当前所在节点）。
--- 数据源：服务端 stage.HistoryNodeList（BsonElement "hnl"，当前轮次已过节点列表）。
---@return number 无 stage 返回 0；无历史返回 1（首节点）
function XPunishaarControl:GetCurrentNodeIndex()
    local stage = self._Model:GetCurrentStage()
    if not stage then return 0 end
    local history = stage.HistoryNodeList or {}
    return #history + 1
end

--- 获取指定关卡第 index 个节点的类型（ContentType，见 NodeType 枚举）。
---@param stageId number
---@param index number 1-based
---@return number|nil ContentType
function XPunishaarControl:GetNodeContentType(stageId, index)
    local group = XMVCA.XPunishaar:GetTablePunishaarStageContentGroup(stageId, true)
    if not group or not group.StageContentIds then return nil end
    local contentId = group.StageContentIds[index]
    if not contentId then return nil end
    local content = XMVCA.XPunishaar:GetTablePunishaarStageContent(contentId, true)
    return content and content.ContentType or nil
end

--- 获取关卡类型（StageGroup.Type 配置字段）。
---@param stageId number
---@return number|nil Type 值（配置缺失返回 nil）
function XPunishaarControl:GetStageType(stageId)
    local cfg = XMVCA.XPunishaar:GetTablePunishaarStageGroupById(stageId, true)
    return cfg and cfg.Type or nil
end

--- 是否无尽关（挑战记录/破纪录模块仅无尽关显示）。
---@param stageId number
---@return boolean
function XPunishaarControl:IsEndlessStage(stageId)
    return self:GetStageType(stageId) == XMVCA.XPunishaar.EnumConst.StageType.Endless
end

--- 无尽关多轮次敌人加成倍率：(round-1)；非无尽关或 round<=1（首轮）返 0。
--- 供 GetEnemyExtraHp/Atk 共用（DRY 单源，PreFight 显示 + _PrepareBattleData initData extra 都走此）。
---@return number
function XPunishaarControl:_GetEndlessBuffScale()
    local stageId = self:GetCurrentStageId()
    if not stageId or not self:IsEndlessStage(stageId) then return 0 end
    local round = self:GetCurrentRound() or 0
    if round <= 1 then return 0 end
    return round - 1
end

--- 无尽关多轮次敌人额外 HP（EndlessStageBuff[1]×(round-1)；首轮/普通关返 0）。
--- PreFight 敌人 HP 显示 + _PrepareBattleData initData extra 共用（镜像 GetPlayerBattleHp 范式：局外算、单源）。
--- EndlessStageBuff 是 ShareConfig/PunishaarConfig key（ConfigKey 表），走 GetConfigNumberByKey（非 ClientConfig 的 GetClientNumberByKey）。
---@return number
function XPunishaarControl:GetEnemyExtraHp()
    local scale = self:_GetEndlessBuffScale()
    if scale <= 0 then return 0 end
    return (XMVCA.XPunishaar:GetConfigNumberByKey(ConfigKey.EndlessStageBuff, 1) or 0) * scale
end

--- 同 GetEnemyExtraHp，ATK（EndlessStageBuff[2]）。
---@return number
function XPunishaarControl:GetEnemyExtraAtk()
    local scale = self:_GetEndlessBuffScale()
    if scale <= 0 then return 0 end
    return (XMVCA.XPunishaar:GetConfigNumberByKey(ConfigKey.EndlessStageBuff, 2) or 0) * scale
end

--- 商店刷新费用（金币）= 基础花费 + 增量 × 已刷新次数。
--- 读 Share 端 PunishaarConfig.ShopRefresh：Param[1]=基础花费、Param[2]=每刷新一次增量；
--- 已刷新次数取服务端 ShopInfo.RefreshTimes（见 XPunishaarControl:GetCurrentShopRefreshTimes）。
---@return number
function XPunishaarControl:GetShopRefreshCost()
    local refreshTimes = self:GetCurrentShopRefreshTimes() or 0
    local base      = XMVCA.XPunishaar:GetConfigNumberByKey(ConfigKey.ShopRefresh, 1)
    local increment = XMVCA.XPunishaar:GetConfigNumberByKey(ConfigKey.ShopRefresh, 2)
    return (base or 0) + (increment or 0) * refreshTimes
end

--- 战斗初始球槽容量（PunishaarClientConfig.InitBallSlotCount Param[1]）
---@return number
function XPunishaarControl:GetInitBallSlotCount()
    return XMVCA.XPunishaar:GetClientNumberByKey(ClientConfigKey.InitBallSlotCount, 1) or 0
end

--- 球槽最大容量上限（PunishaarClientConfig.BallSlotMax Param[1]）
---@return number
function XPunishaarControl:GetBallSlotMax()
    return XMVCA.XPunishaar:GetClientNumberByKey(ClientConfigKey.BallSlotMax, 1) or 0
end

--- 补强商店默认 HUD group（PunishaarConfig.RemedyShopHudGroupId Param[1]=groupId）。
--- 补强商店是战斗节点 Remedy 状态非独立节点，无法配 StageContent.HudGroupId，所有补强商店共用此默认 group 显 HUD。#补强HUD
---@return number
function XPunishaarControl:GetRemedyShopHudGroupId()
    return XMVCA.XPunishaar:GetConfigNumberByKey(ConfigKey.RemedyShopHudGroupId, 1) or 0
end

--- 购买成功提示文本，读 PunishaarClientConfig.ShopBuySuccess Values[1]
---@return string
function XPunishaarControl:GetShopBuySuccessText()
    return XMVCA.XPunishaar:GetClientStringByKey(ClientConfigKey.ShopBuySuccess, 1)
end

--- 卖出成功提示文本，读 PunishaarClientConfig.ShopSellSuccess Values[1]
---@return string
function XPunishaarControl:GetShopSellSuccessText()
    return XMVCA.XPunishaar:GetClientStringByKey(ClientConfigKey.ShopSellSuccess, 1)
end

--- 刷新成功提示文本，读 PunishaarClientConfig.ShopRefreshSuccess Values[1]
---@return string
function XPunishaarControl:GetShopRefreshSuccessText()
    return XMVCA.XPunishaar:GetClientStringByKey(ClientConfigKey.ShopRefreshSuccess, 1)
end

--- 商品价格显示文本（富文本含颜色标签）：金币够取 Values[1]、不够取 Values[2]，{0}=价格数字。
--- 颜色由策划在 PunishaarClientConfig.ShopPriceText 用 <color=#xxx>...</color> 富文本标签配置，代码只按金币够否选 index。
---@param affordable boolean 金币是否够买
---@return string 富文本模板（空则调用方兜底纯数字）
function XPunishaarControl:GetShopPriceText(affordable)
    return XMVCA.XPunishaar:GetClientStringByKey(
        ClientConfigKey.ShopPriceText,
        affordable and 1 or 2
    )
end

--- 背包容量显示文本模板：Values[1] 含 {0}=当前占用、{1}=总容量（如 "{0}/{1}"）。策划在 PunishaarClientConfig.BagCapacityText 配置格式。
---@return string 格式模板（空则调用方兜底拼接 used/total）
function XPunishaarControl:GetBagCapacityText()
    return XMVCA.XPunishaar:GetClientStringByKey(
        ClientConfigKey.BagCapacityText,
        1
    )
end

--- 获取未解锁关卡的提示文本。
--- 读取 PunishaarClientConfig.StageNotOpenTip 的 Values[1]。
---@return string
function XPunishaarControl:GetStageNotOpenTipText()
    return XMVCA.XPunishaar:GetClientStringByKey(
        ClientConfigKey.StageNotOpenTip,
        1
    )
end

--- 获取关卡未到解锁时间时的提示文本
---@return string
function XPunishaarControl:GetStageUnlockTimeTipText()
    return XMVCA.XPunishaar:GetClientStringByKey(
        ClientConfigKey.StageUnlockTimeTip,
        1
    )
end

--- 获取普通关卡存在存档时的状态文本。
--- 读取 PunishaarClientConfig.StageInProgressText 的 Values[1]。
---@return string
function XPunishaarControl:GetStageInProgressText()
    return XMVCA.XPunishaar:GetClientStringByKey(
        ClientConfigKey.StageInProgressText,
        1
    )
end

--- 获取无尽关卡存在存档时的轮次文本。
--- 读取 PunishaarClientConfig.StageEndlessRoundText 的 Values[1]，其中 {0} 表示当前轮次。
---@return string
function XPunishaarControl:GetStageEndlessRoundText()
    return XMVCA.XPunishaar:GetClientStringByKey(
        ClientConfigKey.StageEndlessRoundText,
        1
    )
end

--- 获取关卡存档进度文本。
--- 读取 PunishaarClientConfig.StageProgressText 的 Values[1]。
--- 格式化参数：{0}=当前节点序号，{1}=关卡总节点数。
---@return string
function XPunishaarControl:GetStageProgressText()
    return XMVCA.XPunishaar:GetClientStringByKey(
        ClientConfigKey.StageProgressText,
        1
    )
end

--- 获取关卡详情标题文本。
--- 读取 PunishaarClientConfig.StageDetailNameText 的 Values[1]。
--- 格式化参数：{0}=关卡序号，{1}=关卡名称。
---@return string
function XPunishaarControl:GetStageDetailNameText()
    return XMVCA.XPunishaar:GetClientStringByKey(
        ClientConfigKey.StageDetailNameText,
        1
    )
end

--- 获取图鉴收集率颜色
---@param isFull boolean 是否达到100%
---@return string 十六进制颜色字符串
function XPunishaarControl:GetCollectionProgressColor(isFull)
    local index = isFull and 2 or 1

    return XMVCA.XPunishaar:GetClientStringByKey(
        ClientConfigKey.CollectionProgressColors,
        index
    )
end

---@return string
function XPunishaarControl:GetCollectionLockDesc()
    return XMVCA.XPunishaar:GetClientStringByKey(
        ClientConfigKey.CollectionLockDesc,
        1
    )
end

---@return XTablePunishaarCardBgSettings
function XPunishaarControl:GetTablePunishaarCardBgSettings(id, notips)
    return self:GetConfigByTabKeyAndIdKey(
        TableKey.PunishaarCardBgSettings,
        id,
        notips
    )
end

--- 战斗开始 VSNotify 停留时长（秒），读 PunishaarClientConfig.VsNotifyDuration Values[1]。
--- 配置未填或 ≤0 时兜底 1.5 秒。
---@return number
function XPunishaarControl:GetVsNotifyDuration()
    local dur = XMVCA.XPunishaar:GetClientNumberByKey(ClientConfigKey.VsNotifyDuration, 1)
    return (dur and dur > 0) and dur or 1.5
end

--- 主卡详情 prefab 路径（读 PunishaarClientConfig.TipsMainCardPrefab Values[1]）
---@return string
function XPunishaarControl:GetTipsMainCardPrefabPath()
    return XMVCA.XPunishaar:GetClientStringByKey(ClientConfigKey.TipsMainCardPrefab, 1)
end

--- 副卡详情 prefab 路径
---@return string
function XPunishaarControl:GetTipsSubCardPrefabPath()
    return XMVCA.XPunishaar:GetClientStringByKey(ClientConfigKey.TipsSubCardPrefab, 1)
end

--- 敌人详情 prefab 路径
---@return string
function XPunishaarControl:GetTipsEnemyPrefabPath()
    return XMVCA.XPunishaar:GetClientStringByKey(ClientConfigKey.TipsEnemyPrefab, 1)
end

--- 节点类型图标路径：读 PunishaarClientConfig.NodeIcon Values[nodeType]。
--- 单 Key 多值，下标即 XPunishaarEnum.NodeType（Shop=1/Event=2/Fight=3/ChoiceFight=4/Story=5）。
---@param nodeType number XPunishaarEnum.NodeType
---@return string 图标路径，配置缺失返回空串
function XPunishaarControl:GetNodeIconPath(nodeType)
    return XMVCA.XPunishaar:GetClientStringByKey(ClientConfigKey.NodeIcon, nodeType)
end

--- 状态图标路径：读 PunishaarClientConfig.BuffIcons Values[iconIndex]。
--- 单 Key 多值，下标语义见 XPunishaarEnum.BuffIconIndex（Shield=1 敌我共用 / EnemyDot=2 仅敌人）。
--- 护盾严格来说不是 buff，但与 buff 共用图标预制，故图标配置也收在同一 key 下。
---@param iconIndex number XPunishaarEnum.BuffIconIndex
---@return string 图标路径，配置缺失返回空串
function XPunishaarControl:GetBuffIconPath(iconIndex)
    return XMVCA.XPunishaar:GetClientStringByKey(ClientConfigKey.BuffIcons, iconIndex)
end

--- ATK/CD 实时预览显示文案：按 cur 与 base 的相对大小选 Up/Down/Equal key，读 Values[fieldIndex]。
--- 单 Key 多值：约定 fieldIndex 1=ATK、2=CD（同一 Key 行 Values[1]=ATK 文案、Values[2]=CD 文案，分离 ATK/CD 文本）。
--- Equal 用 Mathf.Approximately(cur, base) 判定——相对容差按量级缩放，吸收 CD 投影帧/毫秒换算与
--- Multiply/Divide 运算产生的 1e-7 量级浮点漂移；1 帧的 50ms 实际变化远大于容差不会被误吞。
---@param cur number 当前值（proj.atkBase + proj.atkDelta / proj.cdBaseMs + proj.cdDeltaMs）
---@param base number 配置值（proj.atkBase / proj.cdBaseMs）
---@param fieldIndex number 1=ATK、2=CD
---@return string 配置缺失返回空串
function XPunishaarControl:GetRealtimeValueShowText(cur, base, fieldIndex)
    local key
    if Mathf.Approximately(cur, base) then
        key = ClientConfigKey.RealtimeValueShowEqual
    elseif cur > base then
        key = ClientConfigKey.RealtimeValueShowUp
    else
        key = ClientConfigKey.RealtimeValueShowDown
    end
    return XMVCA.XPunishaar:GetClientStringByKey(key, fieldIndex)
end
--- 主界面展示奖励包Id，读取 PunishaarClientConfig.DisplayReward Values[1]
---@return number
function XPunishaarControl:GetDisplayRewardId()
    return XMVCA.XPunishaar:GetClientNumberByKey(
        ClientConfigKey.DisplayReward
    )
end

--- 主界面指定站位展示的主卡Id
---@param index number 站位下标1~4
---@return number
function XPunishaarControl:GetMainShowCardId(index)
    return XMVCA.XPunishaar:GetClientNumberByKey(
        ClientConfigKey.MainShowCardIds,
        index
    )
end

--- 主界面指定站位模型的动作名
---@param index number 站位下标1~4
---@return string
function XPunishaarControl:GetMainShowAnimaName(index)
    return XMVCA.XPunishaar:GetClientStringByKey(
        ClientConfigKey.MainShowAnimas,
        index
    )
end

--- 根据卡牌模板Id和等级读取等级配置。
---@param cardId number
---@param level number
---@param notips boolean
---@return XTablePunishaarCardLevel
function XPunishaarControl:GetTablePunishaarCardLevelByCardIdAndLevel(
    cardId,
    level,
    notips
)
    if not cardId or not level then
        return nil
    end

    local id = cardId * CARD_LEVEL_ID_FACTOR + level
    return self:GetTablePunishaarCardLevel(id, notips)
end

--- 最大存档数量
---@return number
function XPunishaarControl:GetMaxSaveCount()
    return XMVCA.XPunishaar:GetConfigNumberByKey(
        ConfigKey.MaxSaveCount,
        1
    )
end

--- 存档达到上限时的客户端提示码
---@return number
function XPunishaarControl:GetSaveCountLimitTipCode()
    return XMVCA.XPunishaar:GetClientNumberByKey(
        ClientConfigKey.SaveCountLimitTipCode,
        1
    )
end

--- 指挥官战斗初始血量：HPValue + 战斗胜利次数 × HPGrowthValue（与耐久度 Durability 无关）。
---@param fightWinCount number 本局已胜利的战斗节点次数（Stage.FightWinCount）
---@return number
function XPunishaarControl:GetPlayerBattleHp(fightWinCount)
    local baseHp = XMVCA.XPunishaar:GetConfigNumberByKey(ConfigKey.HPValue, 1)
    local growth = XMVCA.XPunishaar:GetConfigNumberByKey(ConfigKey.HPGrowthValue, 1)
    return baseHp + (fightWinCount or 0) * growth
end

--- 当前局已胜利战斗节点次数（Stage.FightWinCount），供 GetPlayerBattleHp 等。
---@return number
function XPunishaarControl:GetCurrentFightWinCount()
    local stage = self._Model:GetCurrentStage()
    return stage and stage.FightWinCount or 0
end

return XPunishaarControl
