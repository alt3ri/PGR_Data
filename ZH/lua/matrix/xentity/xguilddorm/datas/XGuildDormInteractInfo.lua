---@class XGuildDormInteractInfo
---@field Id @所属家具的ID
---@field ButtonType
---@field ShowButtonName
---@field BehaviorType
---@field ButtonArg @自定义参数
local XGuildDormInteractInfo = XClass(nil, 'XGuildDormInteractInfo')

function XGuildDormInteractInfo:GetShowBtnName()
    if self.ButtonType == XGuildDormConfig.FurnitureButtonType.FurnitureMovie then
        local cfg = XGuildDormConfig.GetFurnitureInteraction(self.Id)
        if cfg and cfg.NeedMark then
            if XDataCenter.GuildDormManager.CheckFurnitureInteracted(self.Id) then
                return cfg.ShowButtonNames[2] or ''
            else
                return cfg.ShowButtonNames[1]
            end
        end
    end
    
    return self.ShowButtonName or ''
end

function XGuildDormInteractInfo:HasCustomButtonName()
    if self.ButtonType == XGuildDormConfig.FurnitureButtonType.FurnitureMovie then
        local cfg = XGuildDormConfig.GetFurnitureInteraction(self.Id)
        if cfg then
            return not XTool.IsTableEmpty(cfg.ShowButtonNames)
        end
    end
    
    return not string.IsNilOrEmpty(self.ShowButtonName)
end

return XGuildDormInteractInfo