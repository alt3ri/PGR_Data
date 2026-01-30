--- 公会战特攻角色系统agency
---@class XSpecialRoleAgency : XAgency
---@field private _Model XGuildWarModel
local XSpecialRoleAgency = XClass(XAgency, "XSpecialRoleAgency")

function XSpecialRoleAgency:OnInit()

end

function XSpecialRoleAgency:OnRelease()

end

--根据实体Id获取特攻角色的Buff数据
--若传入非特攻角色的Id，返回nil
--@return buffData = { Icon = 图标地址, Name = Buff名称, Desc = Buff描述 }
--===============
function XSpecialRoleAgency:GetSpecialRoleBuff(entityId)
    if not entityId then
        return nil
    end
    local characterId = 0
    if XRobotManager.CheckIsRobotId(entityId) then
        characterId = XRobotManager.GetCharacterId(entityId)
    else
        characterId = entityId
    end
    local roleCfg = XGuildWarConfig.GetSpecialRole(characterId)
    if not roleCfg then
        return nil
    end
    local fightEventId = roleCfg.FightEventId
    if not fightEventId or (fightEventId == 0) then
        return nil
    end
    local cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId)
    if not cfg then
        return nil
    end
    local buffData = { Icon = cfg.Icon, Name = cfg.Name, Desc = cfg.Description }
    return buffData
end

--===============
--获取特攻角色队伍Buff数据
--@return buffData = { Icon = 图标地址, Name = Buff名称, Desc = Buff描述 }
--===============
--- 过时的
function XSpecialRoleAgency:GetSpecialTeamBuff()
    local teamCfg = XGuildWarConfig.GetCfgByIdKey(
            XGuildWarConfig.TableKey.SpecialTeam,
            1
    )
    local fightEventId = teamCfg.FightEventId
    if not fightEventId or (fightEventId == 0) then
        return nil
    end
    local cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId)
    if not cfg then
        return nil
    end
    local buffData = { Icon = cfg.Icon, Name = cfg.Name, Desc = cfg.Description }
    return buffData
end

---@param members XGuildWarMember[]
function XSpecialRoleAgency:GetSpecialTeamBuffByMembers(members)
    -- 找到角色占比最多的配置Id
    ---@type XTableGuildWarSpecialRoleTeam
    local specialTeamCfg = nil
    local maxRoleCount = 0
    
    local cfgs = self._Model:GetGuildWarSpecialRoleTeamCfgs()

    for i, v in pairs(cfgs) do
        local roleCount = 0

        for i, member in pairs(members) do
            local entityId = member:GetEntityId()
            local characterId = XRobotManager.GetCharacterId(entityId)

            if XTool.IsNumberValidEx(characterId) then
                if table.contains(v.CharacterIds, characterId) then
                    roleCount = roleCount + 1
                end
            end
        end

        if roleCount > maxRoleCount then
            maxRoleCount = roleCount
            specialTeamCfg = v
        elseif specialTeamCfg == nil then
            -- 默认显示配置表遍历到的第一个
            specialTeamCfg = v
        end
    end
    
    if specialTeamCfg then
        -- 判断当前是不是激活了
        local maxCount = 0
        local isActive = false

        for i, v in pairs(specialTeamCfg.EnableNum) do
            if maxRoleCount >= v then
                isActive = true
            end

            if v > maxCount then
                maxCount = v
            end
        end
        
        local buffData = { 
            Id = specialTeamCfg.Id,
            Icon = specialTeamCfg.BuffIcon, 
            Name = specialTeamCfg.BuffName, 
            Desc = isActive and specialTeamCfg.BuffDesc or specialTeamCfg.BuffSimpleDesc,
            CurCount = maxRoleCount,
            MaxCount = maxCount,
            IsActive = isActive,
        }
        return buffData
    end
end

--region Should be control method - 接口由改造而来，大量非XUiNode的UI对象使用，暂时先在agency里供访问

--- 根据实体Id检查是否特攻角色
function XSpecialRoleAgency:CheckIsSpecialRole(entityId)
    if not entityId then
        return false
    end
    local characterId = 0
    if XRobotManager.CheckIsRobotId(entityId) then
        characterId = XRobotManager.GetCharacterId(entityId)
    else
        characterId = entityId
    end
    local roles = XGuildWarConfig.GetSpecialRoles()
    local roleCfg = roles[characterId]
    return roleCfg ~= nil
end

--- 根据实体Id检查是否头牌特攻角色
function XSpecialRoleAgency:CheckIsCenterSpecialRole(entityId)
    if not entityId then
        return false
    end
    local characterId = 0
    if XRobotManager.CheckIsRobotId(entityId) then
        characterId = XRobotManager.GetCharacterId(entityId)
    else
        characterId = entityId
    end
    local roles = XGuildWarConfig.GetSpecialRoles()
    local spRoleCfg = roles[characterId]
    if spRoleCfg == nil then
        return false
    end
    return spRoleCfg.CenterCharacter == 1
end

--- 获得特攻角色专属图标
function XSpecialRoleAgency:GetSpecialRoleIcon(entityId)
    if not entityId then
        return false
    end
    local characterId = 0
    if XRobotManager.CheckIsRobotId(entityId) then
        characterId = XRobotManager.GetCharacterId(entityId)
    else
        characterId = entityId
    end
    local roleCfg = XGuildWarConfig.GetSpecialRole(characterId)
    if roleCfg == nil then
        return false
    end
    
    -- 约定配置每个角色只属于一个特攻组，所以直接遍历查找配置在哪个组上
    local specialTeamId = self._Model.SpecialRoleModel:GetSpecialTeamIdByCharacterId(characterId) or 1
    
    if roleCfg.CenterCharacter == 1 then
        return XGuildWarConfig.GetClientConfigValue("SpecialRoleIcon1", "string", specialTeamId)
    end
    return XGuildWarConfig.GetClientConfigValue("SpecialRoleIcon2", "string", specialTeamId)
end

function XSpecialRoleAgency:GetSpecialRoleIconBySpecialTeamId(specialTeamId)
    if not specialTeamId then
        return ''
    end

    return XGuildWarConfig.GetClientConfigValue("SpecialRoleIcon2", "string", specialTeamId)
end

--- 获得特攻角色专属图标底图
function XSpecialRoleAgency:GetSpecialRoleIconBgByRoleId(entityId)
    if not entityId then
        return false
    end
    local characterId = 0
    if XRobotManager.CheckIsRobotId(entityId) then
        characterId = XRobotManager.GetCharacterId(entityId)
    else
        characterId = entityId
    end
    local roleCfg = XGuildWarConfig.GetSpecialRole(characterId)
    if roleCfg == nil then
        return false
    end

    -- 约定配置每个角色只属于一个特攻组，所以直接遍历查找配置在哪个组上
    local specialTeamId = self._Model.SpecialRoleModel:GetSpecialTeamIdByCharacterId(characterId) or 1

    return XGuildWarConfig.GetClientConfigValue("SpeicalRoleIconBg", "string", specialTeamId)
end

function XSpecialRoleAgency:GetSpecialRoleIconBgBySpecialTeamId(specialTeamId)
    if not specialTeamId then
        return ''
    end

    return XGuildWarConfig.GetClientConfigValue("SpeicalRoleIconBg", "string", specialTeamId)
end

--endregion

return XSpecialRoleAgency