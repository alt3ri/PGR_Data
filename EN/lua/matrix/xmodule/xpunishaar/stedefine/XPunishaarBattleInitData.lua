--- 大巴扎「开战数据契约」（对象式，可复用）
---
--- 战斗对外的唯一输入端口：外部（真实关卡 / 测试 / 回放）经 set 接口逐项写入本对象的字段，
--- 再交给 FightControl:StartBattle 开局。战斗内部只认本契约对象，不认识任何来源。
---
--- 为何是「对象 + 唯一字段复用」而非每局新建 table：契约实例在 Model 生命周期内常驻，
---   换局只 Reset() 清字段复用，不产生每局临时 table，减少 GC 分配（与 BuffEntity 对象池同取向）。
---   顶层标量/容器复用；cards/initBalls 容器本身复用（清空不重建数组），元素每局重填。
---
--- 依赖倒置：装配层不认识任何来源，只调本对象的 Get 接口读数据。
--- 只读边界：进入战斗后（StartBattle 起）不再写本对象；写只发生在开局前的 set 阶段。
---
--- 字段（经 Get 读、Set/Add 写）：
---   seed             RNG 种子。确定性根：真实局服务器下发、回放复用。留空则 GetSeed 兜底取服务器时间戳。
---   ballSlotCapacity 球槽总容量。缺省 DEFAULT_BALL_SLOT_CAPACITY。
---   initBalls        开局预置球（扁平颜色列表，与 BallList 内部 1:1，逐个入队；超容量溢出丢弃）。
---   player           { hp }
---   enemy            { hp, atk, atkCd }
---   cards            每元素 { cardId, level, posIndex, subCardId? }
---                    index（紧凑索引）不在契约：装配按数组序自动生成。posIndex（离散坐标）必填。
---                    subCardId 可选：副卡非实体，激发时先跑其 effectGroup（无 level/ATK #43）。
---@class XPunishaarBattleInitData
local XPunishaarBattleInitData = XClass(nil, "XPunishaarBattleInitData")

-- 球槽容量缺省值（外部未指定时使用）
local DEFAULT_BALL_SLOT_CAPACITY = 10

function XPunishaarBattleInitData:Ctor()
    -- 容器本身只建一次，换局 Reset 只清空不重建
    self._InitBalls = {}   -- { color, ... }
    self._Cards = {}       -- { {cardId,level,posIndex,subCardId?}, ... } #43: 副卡无 level
    self:Reset()
end

--- 换局清空（复用实例）：标量归缺省，容器清空不重建。
function XPunishaarBattleInitData:Reset()
    self._Seed = nil                                  -- 留空，GetSeed 兜底
    self._BallSlotCapacity = DEFAULT_BALL_SLOT_CAPACITY
    self._BallSlotMax = nil  -- 球槽最大容量上限（_PrepareBattleData 经 ClientConfig 设）
    self._PlayerHp = nil
    self._FightId = nil          -- 本场选中的 Fight.Id（敌人 HP/ATK/CD/技能全由 Fight 表查出）
    self._EnemyExtraHp = 0       -- 无尽关多轮次敌人额外 HP（局外 _PrepareBattleData 算好经契约传，装配层 fightCfg.HP + extra）
    self._EnemyExtraAtk = 0      -- 无尽关多轮次敌人额外 ATK（同上）
    self._SortedCards = nil       -- posIndex 排序后卡列表（BuildSortedCards 构造期产出，供 SetupBattle 建实体 + GetCardLevelByIndex 读 level）

    -- 容器复用：清元素不换表
    for i = #self._InitBalls, 1, -1 do
        self._InitBalls[i] = nil
    end
    for i = #self._Cards, 1, -1 do
        self._Cards[i] = nil
    end
end

--region 写入接口（外部 / C# 逐项调）------------------------------------------

function XPunishaarBattleInitData:SetSeed(seed)
    self._Seed = seed
end

function XPunishaarBattleInitData:SetBallSlotCapacity(cap)
    if cap then
        self._BallSlotCapacity = cap
    end
end

--- 球槽最大容量上限（后续 effect 增容 clamp max 用）。
function XPunishaarBattleInitData:SetBallSlotMax(max)
    if max then
        self._BallSlotMax = max
    end
end

function XPunishaarBattleInitData:SetPlayer(hp)
    self._PlayerHp = hp
end

--- 本场选中的 Fight.Id。敌人 HP/ATK/CD/技能全由 Fight 表查出（模式A：敌人配置驱动，不手传数值）。
function XPunishaarBattleInitData:SetFightId(fightId)
    self._FightId = fightId
end

--- 无尽关多轮次敌人额外 HP（局外 _PrepareBattleData 算好经契约传，装配层 fightCfg.HP + extra）。
function XPunishaarBattleInitData:SetEnemyExtraHp(extraHp)
    self._EnemyExtraHp = extraHp or 0
end

--- 无尽关多轮次敌人额外 ATK（同 SetEnemyExtraHp）。
function XPunishaarBattleInitData:SetEnemyExtraAtk(extraAtk)
    self._EnemyExtraAtk = extraAtk or 0
end

--- 追加一个开局球（数组复用）。
function XPunishaarBattleInitData:AddInitBall(color)
    self._InitBalls[#self._InitBalls + 1] = color
end

--- 追加一张卡。subCardId 给即视为带副卡（副卡无 level #43）。
function XPunishaarBattleInitData:AddCard(cardId, level, posIndex, subCardId)
    local card = {
        cardId = cardId,
        level = level,
        posIndex = posIndex,
    }
    if subCardId then
        card.subCardId = subCardId
    end
    self._Cards[#self._Cards + 1] = card
end

--- 构造期排序：拷贝 _Cards 引用 → 按 posIndex 排序 → _SortedCards。
--- _Cards（pairs 序）不动；_SortedCards 是 posIndex 排序后副本（紧凑数组序，== 装配 Index 序）。
--- 供 SetupBattle 建实体（Index=i ← _SortedCards[i]）+ GetSortedCardLevelByIndex 读 level（底图 Level 维度 #82）。
--- 调用时机：_PrepareBattleData AddCard 循环后（set 阶段，StartBattle 前，合规）。
function XPunishaarBattleInitData:BuildSortedCards()
    self._SortedCards = {}
    for i = 1, #self._Cards do
        self._SortedCards[i] = self._Cards[i]
    end
    table.sort(self._SortedCards, function(a, b) return a.posIndex < b.posIndex end)
end
--endregion

--region 读取接口（StartBattle / 装配层调）-----------------------------------

--- 种子：外部未 set 则兜底取服务器时间戳（唯一的时间获取点，战斗内部不再碰时间）。
function XPunishaarBattleInitData:GetSeed()
    return self._Seed or XTime.GetServerNowTimestamp()
end

function XPunishaarBattleInitData:GetBallSlotCapacity()
    return self._BallSlotCapacity
end

function XPunishaarBattleInitData:GetBallSlotMax()
    return self._BallSlotMax
end

function XPunishaarBattleInitData:GetPlayerHp()
    return self._PlayerHp
end

function XPunishaarBattleInitData:GetFightId()
    return self._FightId
end

function XPunishaarBattleInitData:GetEnemyExtraHp()
    return self._EnemyExtraHp or 0
end

function XPunishaarBattleInitData:GetEnemyExtraAtk()
    return self._EnemyExtraAtk or 0
end

function XPunishaarBattleInitData:GetInitBallCount()
    return #self._InitBalls
end

function XPunishaarBattleInitData:GetInitBall(i)
    return self._InitBalls[i]
end

function XPunishaarBattleInitData:GetCardCount()
    return #self._Cards
end

--- 取第 i 张卡的数据表（内部表，调用方只读不持有）。
---@return table {cardId, level, posIndex, subCardId?}  #43: 副卡无 level
function XPunishaarBattleInitData:GetCard(i)
    return self._Cards[i]
end

--- 按紧凑索引 index 取该卡的 level（O(1)：index == _Cards 数组下标 == 装配序）。
--- index 是唯一键（同 cardId 可有多张，不能用 cardId 反查）。找不到返回 nil。
---@param index number
---@return number|nil
function XPunishaarBattleInitData:GetCardLevelByIndex(index)
    local c = self._Cards[index]
    return c and c.level
end

--- 取 posIndex 排序后第 i 张卡（== 装配 Index=i 实体自身卡）。
---@param i number 1-based
---@return table|nil {cardId, level, posIndex, subCardId?}
function XPunishaarBattleInitData:GetSortedCard(i)
    return self._SortedCards and self._SortedCards[i]
end

--- 按 posIndex 排序后紧凑索引取该卡 level（底图 Level 维度 #82）。
--- sorted[index] 即 Index=index 实体自身卡 level（不经 pairs 序 _Cards，避错位）。
---@param index number
---@return number|nil
function XPunishaarBattleInitData:GetSortedCardLevelByIndex(index)
    local c = self._SortedCards and self._SortedCards[index]
    return c and c.level
end
--endregion

--- 提交前校验必填项。缺失即 XLog.Error 并返回 false（脏数据挡在开局前）。
---@return boolean
function XPunishaarBattleInitData:Validate()
    if not self._PlayerHp then
        XLog.Error("[BattleInitData] 缺少 player.hp")
        return false
    end
    if not self._FightId then
        XLog.Error("[BattleInitData] 缺少 fightId（敌人 HP/ATK/CD/技能全由 Fight 表查出）")
        return false
    end
    for i = 1, #self._Cards do
        local c = self._Cards[i]
        if not c.cardId or not c.level or not c.posIndex then
            XLog.Error(string.format("[BattleInitData] cards[%d] 缺少 cardId/level/posIndex", i))
            return false
        end
    end
    return true
end

return XPunishaarBattleInitData
