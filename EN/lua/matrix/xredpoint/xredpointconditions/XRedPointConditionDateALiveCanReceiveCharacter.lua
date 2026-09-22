---@class XRedPointConditionDateALiveCanReceiveCharacter 当存在可领取的角色时
local XRedPointConditionDateALiveCanReceiveCharacter = {}

function XRedPointConditionDateALiveCanReceiveCharacter.Check()
    local cfgs = XDrawConfigs.GetDateALiveActivityCfg()
    for _, cfg in pairs(cfgs) do
        for _, drawId in ipairs(cfg.DrawIds) do
            local count = XDataCenter.DrawManager:CheckIsCanReceiveLinkageRole(drawId)
            if XTool.IsNumberValid(count) then
                return true
            end
        end
    end
    return false
end

return XRedPointConditionDateALiveCanReceiveCharacter