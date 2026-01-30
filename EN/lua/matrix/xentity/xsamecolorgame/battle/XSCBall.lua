---@class XSCBall
local XSCBall = XClass(nil, "XSCBall")

function XSCBall:Ctor(id)
    self.BallId = id
end

function XSCBall:GetBallId()
    return self.BallId
end

---是否道具球
function XSCBall:IsPropBall()
    return self:GetCfg().Type == XEnumConst.SAME_COLOR_GAME.BallType.Prop
end

---是否破绽球
function XSCBall:IsWeakBall()
    return self:GetCfg().Type == XEnumConst.SAME_COLOR_GAME.BallType.Weak
end

-------------------------------------配置--------------------------------
function XSCBall:GetCfg()
    return XSameColorGameConfigs.GetBallConfig(self.BallId)
end

function XSCBall:GetName()
    return self:GetCfg().Name
end

function XSCBall:GetColor()
    return self:GetCfg().Color
end

function XSCBall:GetScore()
    return self:GetCfg().Score
end

function XSCBall:GetIcon()
    return self:GetCfg().Icon
end

function XSCBall:GetBg()
    return self:GetCfg().Bg
end

function XSCBall:GetEffectTime()
    return self:GetCfg().PropEffectTime or 0
end

return XSCBall