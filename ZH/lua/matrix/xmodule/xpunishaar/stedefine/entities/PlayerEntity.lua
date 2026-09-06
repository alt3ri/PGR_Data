local STEHelper = require("STEVM/STEHelper")

---@class PlayerEntity: STEVM.Entity
local PlayerEntity = XClass(STEHelper.GetClsEntity(), "Entity")

function PlayerEntity:Ctor(id, env, initHp)
    ---@type PropertyModifiedNum
    self.Fields.HPMax = STEHelper.NewPropertyModifiedNum(id, env, initHp, 0)
    ---@type PropertyModifiedNum
    self.Fields.HP = STEHelper.NewPropertyModifiedNum(id, env, initHp, 0)
    ---@type PropertyModifiedNum
    self.Fields.NoHurtTimes = STEHelper.NewPropertyModifiedNum(id, env, 0, 0)
end

return PlayerEntity