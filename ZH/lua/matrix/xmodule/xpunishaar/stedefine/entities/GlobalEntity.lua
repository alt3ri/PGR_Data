local STEHelper = require("STEVM/STEHelper")

--- 全局变量
---@class GlobalEntity: STEVM.Entity
local GlobalEntity = XClass(STEHelper.GetClsEntity(), "Entity")

function GlobalEntity:Ctor(id, env, ballSlotCapacity, ballSlotMax, fightId)
    --- 当前时刻触发的卡牌Id
    self.Fields.TickDoneCardList = STEHelper.NewPropertyList(id, env)
    --- 当前时刻CD上限发生改变的卡牌
    self.Fields.TickCardCDMaxChangeList = STEHelper.NewPropertyList(id, env)
    --- 当前时刻产球的实体（不一定是牌）
    self.Fields.TickProductBallEntityList = STEHelper.NewPropertyList(id, env)
    --- 当前时刻消耗球的实体
    self.Fields.TickConsumeBallEntityList = STEHelper.NewPropertyList(id, env)
    --- 当前接收输入的卡牌Id
    self.Fields.TickClickCardIdDict = STEHelper.NewPropertyDict(id, env)

    --- 等待释放的卡牌id列表
    self.Fields.WaittingDoneCardIdList = STEHelper.NewPropertyList(id, env)

    --- 球槽
    self.Fields.BallList = STEHelper.NewPropertyList(id, env)
    --- 球槽容量上限（总容量，外部初始化传入；PropertyModifiedNum min 0 max ballSlotMax，effect 可增容 clamp max）
    self.Fields.BallSlotCapacity = STEHelper.NewPropertyModifiedNum(id, env, ballSlotCapacity, 0, ballSlotMax)

    --- 本场战斗选中的 Fight.Id（场级数据，敌人执行时据此现查 Fight 配置拿 EffectGroupId）。
    self.Fields.FightId = STEHelper.NewPropertySingle(id, env, fightId)
    
    --- 卡牌实体Id列表(方便搜索）
    self.Fields.CardEntityIds = STEHelper.NewPropertyList(id, env)
    ---- Buff实体Id列表（方便搜索）
    self.Fields.BuffEntityIds = STEHelper.NewPropertyList(id, env)

    --- 副卡登记表（主卡uid → 副卡{cardId,level}）。副卡非独立实体，靠此在激发主卡时反查副卡去跑其效果。
    --- 值为 lua 表（非标量），仅装配期写入、战斗内只读不改，故不参与事务快照的标量约定问题。
    self.Fields.SubCardDict = STEHelper.NewPropertyDict(id, env)

    --- 帧级伤害段数字典（entityId → 本帧有效攻击段数）；随 ResetGlobalTickData 每帧清零。
    --- 写入：AttackTarget atk>0 时按 attackTimes 累加；供 CheckDealtDamage Trigger 纯读。
    self.Fields.TickDamageDealtDict = STEHelper.NewPropertyDict(id, env)

    --- 帧级 CD 加速记录（entityId 列表）；随 ResetGlobalTickData 每帧清零。
    --- 写入：AccelerateCardCD 每个推进过的实体登记一条；供未来 Trigger 查询"本帧哪些实体被加速过 CD"。
    self.Fields.TickAccelEntityList = STEHelper.NewPropertyList(id, env)

    --- 加速冷却锁字典（entityId → 解锁 tick 阈值）；持久（不随 ResetGlobalTickData 清零，跨帧留存至该 tick 到期）。
    --- 写入：AccelerateCardCD 成功推进后 PropSet(target, GetTick()+W)；读：_AccelerateOne 顶 gate（GetTick()<阈值则跳过）。
    --- W=TickCDMaxMin 帧，perf 护栏防同卡被高频加速刷次（非玩法机制）。#加速冷却
    self.Fields.AccelLockUntilTickDict = STEHelper.NewPropertyDict(id, env)

    --- 信号球生成总量（埋点统计：4 站点产球循环后一次 Store 累加；事务可回滚，回滚的产耗不计入）
    self.Fields.TotalBallProduced = STEHelper.NewPropertySingle(id, env, 0)
    --- 信号球消费总量（埋点统计：4 站点消球循环后一次 Store 累加）
    self.Fields.TotalBallConsumed = STEHelper.NewPropertySingle(id, env, 0)

    --- 帧级 ATK 快照（cardUid→finalVal）：buff 同帧加成+清除，UI 帧末读时修正已清，快照跨一帧由 ResetGlobalTickData 清。#buff修正快照
    self.Fields.TickAtkSnapshot = STEHelper.NewPropertyDict(id, env)
    --- 帧级 CD 上限快照（同上）
    self.Fields.TickCdMaxSnapshot = STEHelper.NewPropertyDict(id, env)
end

return GlobalEntity