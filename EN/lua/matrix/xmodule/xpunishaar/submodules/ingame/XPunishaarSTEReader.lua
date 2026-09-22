--- 大巴扎 STE 表现层只读视图
---
--- 定位：给表现层（UI/动画）一个直接、快捷、且带业务语义的读接口。
---   - 不经 STEHelper.RunStep / 不开事务：读是纯操作，事务是为"写可回滚"准备的开销，读不需要。
---   - 不经 vm：vm 的读会 _Error（事务态触发回滚），且需借黑板/ExecContext。表现层读残缺态是常态，
---     本类读不到直接返回 nil/默认值，不报错、不产生副作用。
---   - 读链：env:GetScope(id):GetField(key):GetFinalVal()，与 vm 读同一条链，只是剥掉事务与报错。
---
--- 结构：与 STEControl 平级的子控制器（同为 FightControl 的子 Control）。env 是 STE 内部资产，
---   归 STEControl（STE 门面）持有，本类不缓存 env，每次读时向 STEControl:GetEnv() 现取——
---   换局时 STEControl 换 env，本类下次读自然是新 env，零同步。
---
--- 用法：FightControl 在 OnInit 中 BindSTEControl 注入门面；表现层通过 FightControl.STEReader 调用。
---
--- 【业务语义 + 只读不变量】本类只暴露业务语义接口（GetPlayerHp / GetCardTickCd / FillBallList…），
---   不暴露通用 (entityId, fieldKey) 读——因为只有本类（逻辑层）确切知道每个数据的业务形状，
---   才能主动选最安全的传递方式：
---   - 标量业务读：直接返回值（number/bool/id，无泄漏风险）。
---   - 集合业务读：填充式 Fill*(out) —— 调用方传入 table，本类按序把【标量】写入并返回个数。
---     本类绝不返回自己持有的 table，内部引用永不出门；调用方复用同一 buffer 亦零 GC。
---     清空语义：Fill* 只按序覆写 out[1..count] 并返回 count，不清理 out 尾部残留，
---     调用方自行按 count 截断或复用前自清。
---@class XPunishaarSTEReader : XControl
---@field _STEControl XPunishaarSTEControl
local XPunishaarSTEReader = XClass(XControl, "XPunishaarSTEReader")

local XDictionary = require("XCommon/XDictionary")

local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")

local FieldNameType = STECustomEnum.FieldNameType
local GlobalIds     = STECustomEnum.GlobalEntityIds

function XPunishaarSTEReader:OnInit()
    -- 球色统计缓冲（XDictionary 复用，避免每次 GetMaxColorBall 新建 colorCounter）
    ---@type XDictionary
    self._ColorCounterDict = XDictionary.New()
end

function XPunishaarSTEReader:AddAgencyEvent()

end

function XPunishaarSTEReader:RemoveAgencyEvent()

end

function XPunishaarSTEReader:OnRelease()

end

--- 绑定 STE 门面（由 FightControl 在 OnInit 注入）。
---@param steControl XPunishaarSTEControl
function XPunishaarSTEReader:BindSTEControl(steControl)
    self._STEControl = steControl
end

--region 私有基础件（不对外；业务接口在其上组装）--------------------------------

--- 取当前局 env（向 STE 门面现取，不缓存）。未绑定/未开局返回 nil。
---@return STEEnv|nil
function XPunishaarSTEReader:_GetEnv()
    return self._STEControl and self._STEControl:GetEnv()
end

--- 取字段对象（handle）；找不到返回 nil，不报错。
---@param entityId any
---@param fieldKey any
---@return PropertyBase|nil
function XPunishaarSTEReader:_GetField(entityId, fieldKey)
    local env = self:_GetEnv()
    if env == nil then
        return nil
    end
    local scope = env:GetScope(entityId)
    if scope == nil then
        return nil
    end
    return scope:GetField(fieldKey)
end

--- 读标量字段最终值（经修正队列 + 夹紧）。找不到返回 default（缺省 0）。
---@param entityId any
---@param fieldKey any
---@param default number|nil
---@return number
function XPunishaarSTEReader:_GetFinalVal(entityId, fieldKey, default)
    local field = self:_GetField(entityId, fieldKey)
    if field == nil or type(field.GetFinalVal) ~= "function" then
        return default or 0
    end
    return field:GetFinalVal()
end

--- 填充式读 PropertyList（元素恒为标量）到 out：按序覆写 out[1..count]，返回 count。
--- 不清 out 尾部（调用方自清）；元素若为 table 视为违反标量约定，报错并以该处截断。
---@param entityId any
---@param fieldKey any
---@param out any[] 调用方持有的 buffer（本类只写入标量，不交出内部 table）
---@return number count 写入个数
function XPunishaarSTEReader:_FillList(entityId, fieldKey, out)
    if type(out) ~= "table" then
        XLog.Error("[XPunishaarSTEReader] _FillList 需要传入 out table")
        return 0
    end
    local field = self:_GetField(entityId, fieldKey)
    if field == nil or type(field.Len) ~= "function" or type(field.GetByKey) ~= "function" then
        return 0
    end
    local len = field:Len()
    for i = 1, len do
        local v = field:GetByKey(i)
        if type(v) == "table" then
            XLog.Error(string.format("[XPunishaarSTEReader] _FillList 元素为 table，违反标量约定，截断于 %d：field=%s",
                    i, tostring(fieldKey)))
            return i - 1
        end
        out[i] = v
    end
    return len
end
--endregion

--region 卡牌攻击动画（本帧激活卡列表）-----------------------------------------

--- 填充本帧激活卡 entityId 列表到 out（只读 Fill 式，不外泄内部 list）#71
---@param out number[] 调用方持有的 buffer
---@return number count 写入个数
function XPunishaarSTEReader:FillTickDoneCards(out)
    return self:_FillList(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickDoneCardList, out)
end

--endregion

--region 玩家 ----------------------------------------------------------------

---@return number
function XPunishaarSTEReader:GetPlayerHp()
    return self:_GetFinalVal(GlobalIds.Player, FieldNameType.HP)
end

---@return number
function XPunishaarSTEReader:GetPlayerHpMax()
    return self:_GetFinalVal(GlobalIds.Player, FieldNameType.HPMax)
end

--- 玩家护盾（免伤次数）。
---@return number
function XPunishaarSTEReader:GetPlayerShield()
    return self:_GetFinalVal(GlobalIds.Player, FieldNameType.NoHurtTimes)
end
--endregion

--region 敌人 ----------------------------------------------------------------

---@return number
function XPunishaarSTEReader:GetEnemyHp()
    return self:_GetFinalVal(GlobalIds.Enemy, FieldNameType.HP)
end

---@return number
function XPunishaarSTEReader:GetEnemyHpMax()
    return self:_GetFinalVal(GlobalIds.Enemy, FieldNameType.HPMax)
end

---@return number
function XPunishaarSTEReader:GetEnemyAtk()
    return self:_GetFinalVal(GlobalIds.Enemy, FieldNameType.ATK)
end

--- 敌人当前 CD（执行 Effect 的 CD，单位逻辑帧）。
---@return number
function XPunishaarSTEReader:GetEnemyTickCd()
    return self:_GetFinalVal(GlobalIds.Enemy, FieldNameType.TickCD)
end

--- 敌人 CD 上限（单位逻辑帧）。
---@return number
function XPunishaarSTEReader:GetEnemyTickCdMax()
    return self:_GetFinalVal(GlobalIds.Enemy, FieldNameType.TickCDMax)
end

--- 敌人护盾（免伤次数）。
---@return number
function XPunishaarSTEReader:GetEnemyShield()
    return self:_GetFinalVal(GlobalIds.Enemy, FieldNameType.NoHurtTimes)
end
--endregion

--region buff 聚合读取（供 buff 图标列表显示）------------------------------

--- 取 targetId 身上某 BuffId 的聚合值（Σ Layer，同 BuffId 多实例求和）。
--- 遍历 Global.BuffEntityIds，过滤 Target==target && BuffId==buffId，累加 Layer。
--- 读不到/无 buff 返 0（表现层据此判不显该图标）。
---@param targetId any
---@param buffId number
---@return number
function XPunishaarSTEReader:GetDotBuffLayers(targetId, buffId)
    local list = self:_GetField(GlobalIds.Global, FieldNameType.BuffEntityIds)
    if not list then
        return 0
    end
    local sum = 0
    for i = 1, list:Len() do
        local uid = list:GetByKey(i)
        if self:_GetFinalVal(uid, FieldNameType.TargetEntityId) == targetId
                and self:_GetFinalVal(uid, FieldNameType.BuffId) == buffId then
            sum = sum + self:_GetFinalVal(uid, FieldNameType.Layer)
        end
    end
    return sum
end

--- 填充 targetId 身上所有 buff 的 BuffId（去重）到 out[1..count]，返回 count。
--- 供 PanelEnemyHp:RefreshBuffList 在 DotBuffLayerChanged 时发现需显示的 buffId 集合（含新增 + 已撤）。
--- 输出顺序 = buff 挂载顺序（BuffEntityIds 是有序 PropertyList，按下标遍历首次出现即写入）。
--- 只写标量（buffId），不交出内部 table；清空语义见类头（不清理 out 尾部，按 count 截断）。
---@param targetId any
---@param out number[] 调用方 buffer
---@return number count
function XPunishaarSTEReader:FillTargetBuffIds(targetId, out)
    if type(out) ~= "table" then
        return 0
    end
    local list = self:_GetField(GlobalIds.Global, FieldNameType.BuffEntityIds)
    if not list then
        return 0
    end
    -- 复用 set 去重（_DotBuffIdSet 懒建，跨调用复用，clear 走 pairs-erase）
    self._DotBuffIdSet = self._DotBuffIdSet or {}
    for k in pairs(self._DotBuffIdSet) do
        self._DotBuffIdSet[k] = nil
    end
    local count = 0
    for i = 1, list:Len() do
        local uid = list:GetByKey(i)
        if self:_GetFinalVal(uid, FieldNameType.TargetEntityId) == targetId then
            local buffId = self:_GetFinalVal(uid, FieldNameType.BuffId)
            if buffId and not self._DotBuffIdSet[buffId] then
                self._DotBuffIdSet[buffId] = true
                count = count + 1
                out[count] = buffId
            end
        end
    end
    return count
end
--endregion

--region 球槽 ----------------------------------------------------------------

--- 球槽容量上限。
---@return number
function XPunishaarSTEReader:GetBallSlotCapacity()
    return self:_GetFinalVal(GlobalIds.Global, FieldNameType.BallSlotCapacity)
end

--- 读球槽（有序，队头=最早产）到 out：按序写入球值（数值），返回个数。
--- out 由调用方持有并复用；本类只写标量，不交出内部 table。清空语义见类头。
---@param out number[] 调用方 buffer
---@return number count
function XPunishaarSTEReader:FillBallList(out)
    return self:_FillList(GlobalIds.Global, FieldNameType.BallList, out)
end

--- 读取球槽中数量最多的球的颜色
function XPunishaarSTEReader:GetMaxCountColorInSlot()
    ---@type PropertyList
    local list = self:_GetField(GlobalIds.Global, FieldNameType.BallList)

    if not list then
        return 0
    end
    
    -- 统计各个颜色数量（_ColorCounterDict 复用，XDictionary 零 per-call GC）
    self._ColorCounterDict:Clear()

    for i = 1, list:Len() do
        local color = list:GetByKey(i)
        local count = self._ColorCounterDict:GetValueByKey(color)
        if count then
            self._ColorCounterDict:SetValueByKey(color, count + 1)
        else
            self._ColorCounterDict:SetValueByKey(color, 1)
        end
    end

    -- 找出数量最多的
    local maxColor = 0
    local maxCount = 0

    for k, v in pairs(self._ColorCounterDict) do
        if v > maxCount then
            maxColor = k
            maxCount = v
        end
    end
    
    return maxColor
end
--endregion

--region 卡牌 ----------------------------------------------------------------

--- 卡牌实体是否存在（uid）。
---@param uid any
---@return boolean
function XPunishaarSTEReader:IsCardExist(uid)
    local env = self:_GetEnv()
    return env ~= nil and env:GetScope(uid) ~= nil
end

--- 读实体是否含某标签（找不到实体/标签集返回 false，不报错）。
---@param entityId any
---@param tag any
---@return boolean
function XPunishaarSTEReader:_HasTag(entityId, tag)
    local env = self:_GetEnv()
    if env == nil then
        return false
    end
    local scope = env:GetScope(entityId)
    if scope == nil or type(scope.GetTags) ~= "function" then
        return false
    end
    local tags = scope:GetTags()
    return tags ~= nil and tags:HasTag(tag)
end

--- 卡牌是否手动驱动（需玩家点击才激发）。
---@param uid any
---@return boolean
function XPunishaarSTEReader:IsCardByHand(uid)
    return self:_HasTag(uid, STECustomEnum.EntityTags.ByHand)
end

--- 卡牌是否处于「CD 已到、等待激发」态（手动牌据此显示可点击箭头/提示）。
---@param uid any
---@return boolean
function XPunishaarSTEReader:IsCardWaitingDone(uid)
    return self:_HasTag(uid, STECustomEnum.EntityTags.WaittingDone)
end

--- 卡牌配置 Id。
---@param uid any
---@return number
function XPunishaarSTEReader:GetCardId(uid)
    return self:_GetFinalVal(uid, FieldNameType.CardId)
end

--- 卡牌攻击力（含 buff 临时修正的最终值）。
---@param uid any
---@return number
function XPunishaarSTEReader:GetCardAtk(uid)
    return self:_GetFinalVal(uid, FieldNameType.ATK)
end

--- 卡牌当前 CD（单位：逻辑帧）。
---@param uid any
---@return number
function XPunishaarSTEReader:GetCardTickCd(uid)
    return self:_GetFinalVal(uid, FieldNameType.TickCD)
end

--- 卡牌 CD 上限（单位：逻辑帧）。
---@param uid any
---@return number
function XPunishaarSTEReader:GetCardTickCdMax(uid)
    return self:_GetFinalVal(uid, FieldNameType.TickCDMax)
end

function XPunishaarSTEReader:GetCardTickCdMaxMs(uid)
    local tick = self:GetCardTickCdMax(uid) or 0

    -- 用基准帧间隔计算毫秒
    local ms = tick * STECustomEnum.MsPerLogicFrame

    return ms
end

--- 卡牌 ATK 快照（buff 修正当帧值，跨一帧供 UI 显示）。无快照返 nil——0 是有效修正值需区分（Lua or 不回退 0、回退 nil）。#buff修正快照
---@param uid any
---@return number|nil
function XPunishaarSTEReader:GetCardAtkSnapshot(uid)
    local dict = self:_GetField(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickAtkSnapshot)
    if not dict or type(dict.GetByKey) ~= "function" then return nil end
    return dict:GetByKey(uid)
end

--- 卡牌 CD 上限快照（逻辑帧→Ms，跨一帧供 UI 显示）。无快照返 nil，0 有效（CD 改 0）。#buff修正快照
---@param uid any
---@return number|nil
function XPunishaarSTEReader:GetCardTickCdMaxMsSnapshot(uid)
    local dict = self:_GetField(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickCdMaxSnapshot)
    if not dict or type(dict.GetByKey) ~= "function" then return nil end
    local tick = dict:GetByKey(uid)
    if tick == nil then return nil end
    return tick * STECustomEnum.MsPerLogicFrame
end

--- 卡牌产球数。
---@param uid any
---@return number
function XPunishaarSTEReader:GetCardBallProduct(uid)
    local productCount = math.floor(self:_GetFinalVal(uid, FieldNameType.BallProductCount))

    if XTool.IsNumberValidEx(productCount) then
        return productCount
    end
    
    return 0
end

--- 卡牌消球数。
---@param uid any
---@return number
function XPunishaarSTEReader:GetCardBallConsume(uid)
    local consumeCount = math.floor(self:_GetFinalVal(uid, FieldNameType.BallConsumeCount))
    
    if XTool.IsNumberValidEx(consumeCount) then
        return consumeCount
    end

    return 0
end

--- 卡牌一维紧凑索引（== CardEntityIds 下标）。
---@param uid any
---@return number
function XPunishaarSTEReader:GetCardIndex(uid)
    return self:_GetFinalVal(uid, FieldNameType.Index)
end

--- 卡牌等级（底图 Level 维度）。Level 不在 STE 字段，经 GetCardIndex→STEControl 开战契约取。#64
---@param uid any
---@return number|nil
function XPunishaarSTEReader:GetCardLevel(uid)
    local index = self:_GetFinalVal(uid, FieldNameType.Index)
    if not index then return nil end
    return self._STEControl:GetCardLevelByIndex(index)
end

--- 卡牌空间位置
---@param uid any
---@return number
function XPunishaarSTEReader:GetCardPosIndex(uid)
    return self:_GetFinalVal(uid, FieldNameType.PosIndex)
end

--- 卡牌开局至今触发次数。
---@param uid any
---@return number
function XPunishaarSTEReader:GetCardDoneTimes(uid)
    return self:_GetFinalVal(uid, FieldNameType.DoneTimes)
end

--- 读全部卡牌 uid（按 Index 有序）到 out：按序写入 uid（数值），返回个数。
--- out 由调用方持有并复用；本类只写标量。清空语义见类头。
---@param out number[] 调用方 buffer
---@return number count
function XPunishaarSTEReader:FillCardEntityIds(out)
    return self:_FillList(GlobalIds.Global, FieldNameType.CardEntityIds, out)
end

--- 读主卡携带的副卡信息（cardId only，副卡无 level #43）。无副卡/读不到返回 nil。
--- 副卡登记在 Global.SubCardDict（主卡uid → {cardId}，装配期写、战斗内只读）；
--- 本类按标量约定拆出 cardId 返回，不外泄内部 table。
---@param uid any 主卡实体 uid
---@return number|nil subCardId
function XPunishaarSTEReader:GetCardSubCardInfo(uid)
    local field = self:_GetField(GlobalIds.Global, FieldNameType.SubCardDict)
    if field == nil or type(field.GetByKey) ~= "function" then
        return nil
    end
    local subCard = field:GetByKey(uid)
    if type(subCard) ~= "table" then
        return nil
    end
    return subCard.cardId
end
--endregion

return XPunishaarSTEReader
