local STEHelper = require("STEVM/STEHelper")

---@class EnemyEntity: STEVM.Entity
local EnemyEntity = XClass(STEHelper.GetClsEntity(), "Entity")

function EnemyEntity:Ctor(id, env, initHp, initAtk, initTickCd)
    ---@type PropertyModifiedNum
    self.Fields.HPMax = STEHelper.NewPropertyModifiedNum(id, env, initHp, 0)
    ---@type PropertyModifiedNum
    self.Fields.HP = STEHelper.NewPropertyModifiedNum(id, env, initHp, 0)
    ---@type PropertyModifiedNum
    self.Fields.ATK = STEHelper.NewPropertyModifiedNum(id, env, initAtk, 0)
    -- 敌人本质是特殊卡牌：CD 到点执行 EffectGroup（非普攻）。单位逻辑帧，与卡牌 TickCD 同名同义。
    ---@type PropertyModifiedNum
    self.Fields.TickCDMax = STEHelper.NewPropertyModifiedNum(id, env, initTickCd, 0)
    ---@type PropertyModifiedNum
    self.Fields.TickCD = STEHelper.NewPropertyModifiedNum(id, env, initTickCd, 0)
    ---@type PropertyModifiedNum
    self.Fields.NoHurtTimes = STEHelper.NewPropertyModifiedNum(id, env, 0, 0)

    --- 敌人激活次数（Trigger[15] CheckNthTrigger 预判依赖，敌人激发后+1；对齐 CardEntity.DoneTimes）#4.8
    self.Fields.DoneTimes = STEHelper.NewPropertySingle(id, env, 0)
end

return EnemyEntity