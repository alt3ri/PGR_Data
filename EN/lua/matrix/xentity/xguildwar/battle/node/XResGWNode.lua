--[[4.2 五期驻守炮击玩法，直到九期都未再用过，注释掉
local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
-- 资源点
local XReslGWNode = XClass(XNormalGWNode, "XReslGWNode")

function XReslGWNode:Ctor(id)

end

function XReslGWNode:GetIsActiveBuff()
    ---@type XGuildWarGarrisonData
    local garrisonData = XMVCA.XGuildWar:GetGarrisonData()
    
    return #self.Config.ShowFightEventId > 0 and not garrisonData:IsDefensePointRebuilding(self._Id)
end

function XReslGWNode:GetBuffIcon()
    local cfg = self:GetFirstFightEventCfg()
    return cfg and cfg.Icon or nil
end

function XReslGWNode:GetBuffName()
    local cfg = self:GetFirstFightEventCfg()
    return cfg and cfg.Name or ''
end

function XReslGWNode:GetBuffDesc()
    local cfg = self:GetFirstFightEventCfg()
    return cfg and cfg.Description or ''
end

function XReslGWNode:GetFirstFightEventCfg()
    return XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(self.Config.ShowFightEventId[1])
end

return XReslGWNode

--]]