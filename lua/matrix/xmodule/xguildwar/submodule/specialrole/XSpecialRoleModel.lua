--- 公会战- 负责特攻角色系统相关数据及配置的子model
---@class XSpecialRoleModel : XModel
local XSpecialRoleModel = XClass(XModel, "XSpecialRoleModel")

function XSpecialRoleModel:OnInit()
    -- 特攻角色配置表二次处理配置
    self._SpecialRoleList = nil
    -- 主要特攻角色
    self._MainSpecialRoleId = nil
end

function XSpecialRoleModel:ClearPrivate()

end

function XSpecialRoleModel:ResetAll()
    self._SpecialRoleList = nil
    self._MainSpecialRoleId = nil
end


--===============
--获取所有特攻角色列表
--@return 角色Id列表 (默认索引1是主攻角色)
--===============
function XSpecialRoleModel:GetSpecialRoleList()
    if not self._SpecialRoleList then
        local tempList = {}
        local roles = XGuildWarConfig.GetSpecialRoles()
        for _, role in pairs(roles) do
            local data = { Center = role.CenterCharacter == 1, CharacterId = role.Id }
            table.insert(tempList, data)
        end
        table.sort(tempList, function(roleDataA, roleDataB)
            if roleDataA.Center then
                return true
            end
            if roleDataB.Center then
                return false
            end
            return roleDataA.CharacterId < roleDataB.CharacterId
        end)
        self._SpecialRoleList = {}
        --主要特攻角色
        self._MainSpecialRoleId = tempList[1].CharacterId
        for i = 1, #tempList do
            table.insert(self._SpecialRoleList, tempList[i].CharacterId)
        end
    end
    
    return self._SpecialRoleList
end


--region Config

--- 查找指定角色属于哪个特攻组
function XSpecialRoleModel:GetSpecialTeamIdByCharacterId(characterId)
    if XTool.IsNumberValidEx(characterId) then
        local cfgs = self._MainModel:GetGuildWarSpecialRoleTeamCfgs()

        for i, v in pairs(cfgs) do
            if table.contains(v.CharacterIds, characterId) then
                return i
            end
        end
    end
end

--endregion

return XSpecialRoleModel