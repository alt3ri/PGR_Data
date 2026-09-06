local Trigger = require("XModule/XPunishaar/STEDefine/Trigger")
local Effect = require("XModule/XPunishaar/STEDefine/Effect")
local Selector = require("XModule/XPunishaar/STEDefine/Selector")

--- Selector,Effect,Trigger的数字枚举，用于配合配置表映射
---@class STEDefine
local STEDefine = {}

STEDefine.Trigger = {}
STEDefine.Effect = {}
STEDefine.Selector = {}

--region Trirgger枚举

STEDefine.Trigger[1] = Trigger.CheckSelfPosMatch            -- 主体是否处于某位置(绝对/相对自身/最左/最右)。参数：mode(PosMode), param(绝对=索引/相对=偏移左负右正/最左右忽略)
STEDefine.Trigger[2] = Trigger.CheckDoneCardPosIn           -- 本帧触发的牌是否有在指定位置的。参数：index 紧凑索引, color(0=不限), cardType(0=不限) #4.8
STEDefine.Trigger[3] = Trigger.CheckOwnCardFinalValueRange  -- 判断所属牌的某个属性值(最终值）是否在指定区间（左闭右开）
STEDefine.Trigger[4] = Trigger.CheckRandomHit               -- 进行概率判定
STEDefine.Trigger[5] = Trigger.CheckBallColorCount          -- 判断指定颜色球数量是否满足比较。参数：color, op(OpType), count
STEDefine.Trigger[6] = Trigger.CheckHpPercent               -- 判断玩家/敌人血量百分比是否满足比较。参数：targetType(1玩家/2敌人), op(OpType), percent(0~100)
STEDefine.Trigger[7] = Trigger.CheckAnyCardCdChanged        -- 本帧是否有任意牌CD上限变化
STEDefine.Trigger[8] = Trigger.CheckBallProduced            -- 本帧是否有实体产球（紧凑邻接）。参数：color(0=不限), cardType(0=不限), side(0=不限 AdjacentSide)
STEDefine.Trigger[9] = Trigger.CheckBallConsumed            -- 本帧是否有实体消球（紧凑邻接）。参数：color(0=不限), cardType(0=不限), side(0=不限 AdjacentSide)
STEDefine.Trigger[10] = Trigger.CheckBallProducedSpatial    -- 本帧是否有实体产球（空间邻接：PosIndex+Size 无缝隙）。参数：color(0=不限), cardType(0=不限), side(0=不限 AdjacentSide)
STEDefine.Trigger[11] = Trigger.CheckBallConsumedSpatial    -- 本帧是否有实体消球（空间邻接：PosIndex+Size 无缝隙）。参数：color(0=不限), cardType(0=不限), side(0=不限 AdjacentSide)
STEDefine.Trigger[12] = Trigger.CheckNeighborMainCardMatch  -- 空间邻居（主卡）Color/Type 是否满足约束。参数：side(AdjacentSide), color(0=不限), cardType(0=不限)
STEDefine.Trigger[13] = Trigger.CheckOwnCardColor           -- 判断所属卡牌的颜色是否符合要求. 参数：color
STEDefine.Trigger[14] = Trigger.CheckDealtDamage            -- 本帧是否有满足约束的实体造成了有效攻击。参数：minHits(段数下限), color(0=不限), cardType(0=不限), side(0=任意 AdjacentSide)
STEDefine.Trigger[15] = Trigger.CheckNthTrigger             -- 目标实体激活次数(DoneTimes)是否满足"本次激发后命中 n 的倍数"。参数：n(每多少次触发), color(0=不限), cardType(0=不限), side(0=自身 AdjacentSide)
STEDefine.Trigger[16] = Trigger.CheckAccelCard              -- 本帧是否有牌的 CD 被加速推进过。参数：scope(0=任意牌/1=自身)
STEDefine.Trigger[17] = Trigger.CheckBuffSelfTargetTickDone -- buff专用，判断buff作用目标是否在当帧触发过
--endregion

--region Selector枚举

STEDefine.Selector[1] = Selector.GetOwnerEntityId         -- 选中执行者自身。参数：无
STEDefine.Selector[2] = Selector.GetCardIdByPos           -- 选中处于某位置的卡牌(绝对/相对自身/最左/最右)。参数：mode(PosMode), param(绝对=索引/相对=偏移左负右正/最左右忽略), color(0=不限), cardType(0=不限) #4.8
STEDefine.Selector[3] = Selector.GetPlayer                -- 选中玩家。参数：无
STEDefine.Selector[4] = Selector.GetEnemy                 -- 选中敌人。参数：无
STEDefine.Selector[5] = Selector.GetCardsByFieldCompare   -- 选中指定属性值满足比较条件的所有牌。参数：fieldEnum(FieldNameEnum), op(OpType), value
STEDefine.Selector[6] = Selector.GetCardsByConfigFilter      -- 选中满足配置属性约束的所有牌。参数：color(0=不限), cardType(0=不限), includeSelf(0=排除所属牌/非0=包括)
STEDefine.Selector[7] = Selector.GetAdjacentCardsByIndex    -- 选中所属牌的紧凑邻居（Index ±1）。参数：side(AdjacentSide)
STEDefine.Selector[8] = Selector.GetAdjacentCardsBySpatial  -- 选中所属牌的空间邻居（PosIndex+Size 无缝隙）。参数：side(AdjacentSide)
STEDefine.Selector[9] = Selector.GetGlobal                -- 选中全局
--endregion

--region Effect枚举

STEDefine.Effect[1] = Effect.ModifyNumberField  --[1] 修改目标数值字段。参数：entityIds 目标, targetFieldEnum 字段枚举(FieldNameEnum), op 运算(ValChangeType), rightVal 运算数
STEDefine.Effect[2] = Effect.AttackTarget       --[2] 对目标造成伤害。参数：entityIds 目标, attackType 攻击类型(ConfigATKType), attackTimes 段数, damageType 伤害来源(ConfigDamageType), value 数值/倍率/Alpha不用配
STEDefine.Effect[3] = Effect.TempModifyNumberField  --[3] 临时修正目标数值字段(挂buff)。参数：entityIds 目标, targetFieldEnum 字段枚举(FieldNameEnum), op 运算(ValChangeType), rightVal 运算数, buffId Buff配置Id
STEDefine.Effect[4] = Effect.CreateBuff         --[4] 直接生成一个buff(无modifier，效果由buff表Ex字段驱动)。参数：entityIds 目标, buffId Buff配置Id
STEDefine.Effect[5] = Effect.AddNoConsumeBallTag  --[5] 给指定卡牌加「下次触发不消耗球」标签(一次性)。参数：entityIds 目标卡牌
STEDefine.Effect[6] = Effect.ConsumeBallByColor  --[6] 消耗指定颜色数量的球(有多少消多少)。参数：color, count
STEDefine.Effect[7] = Effect.ProduceBallByColor  --[7] 产出指定颜色数量的球(满溢出丢弃)。参数：color, count
STEDefine.Effect[8] = Effect.EmitEvent           --[8] 向事件总线派发指定事件(低语义函数的事件补足)。参数：eventType(EventEnum)
STEDefine.Effect[9] = Effect.SetCardCDEnd       --[9] 让指定牌的CD归零
STEDefine.Effect[10] = Effect.AccelerateCardCD  --[10] 加速指定牌的CD（毫秒域运算，帧↔毫秒基于 BaseLogicFrame 忽略二倍速）。参数：entityIds 目标, amount(模式0=毫秒/模式1=浮点比例0.5=50%CDMax), mode(0=Fixed固定毫秒/1=Ratio基于CDMax比例)
STEDefine.Effect[11] = Effect.SnapshotFieldToBuff  --[11] 字段镜像（读实体字段终值 math.floor→按 op 写入 buff 自身字段）。普通 on-tick effect，配在 buff 的 ExEffectGroup 里 TickBuffEx 分发跑（OwnBuffId 由 TickBuffEx:264 设）。参数：entityIds(selector 取，被忽略), srcOrTgt(ConfigFieldSource 1=buff源/2=buff目标), entityField(FieldNameEnum), buffField(FieldNameEnum, buff 图标数值显示用 Layer=16), op(ValChangeType)
--endregion

return STEDefine