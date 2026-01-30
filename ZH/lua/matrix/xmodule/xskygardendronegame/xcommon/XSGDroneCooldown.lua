---@class XSGDroneCooldown
local XSGDroneCooldown = XClass(nil, "XSGDroneCooldown")

function XSGDroneCooldown:Ctor()
    self.Cooldown = 0
    self.Count = 0
end

function XSGDroneCooldown:IsCoolingdown()
    return self.Count <= 0 or self.Cooldown > 0
end

function XSGDroneCooldown:Use(count, cooldown)
    self.Count = math.max(0, count or 0)
    self.Cooldown = math.max(0, cooldown or 0)
end

return XSGDroneCooldown