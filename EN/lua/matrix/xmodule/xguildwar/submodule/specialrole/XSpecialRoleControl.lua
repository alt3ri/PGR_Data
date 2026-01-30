--- 公会战特攻角色相关控制器，用于封装特攻角色系统在XGuildWarControl上的接口
---@class XSpecialRoleControl: XControl
---@field private _Model XGuildWarModel
local XSpecialRoleControl = XClass(XControl, 'XSpecialRoleControl')

function XSpecialRoleControl:OnInit()

end


function XSpecialRoleControl:OnRelease()

end

--===============
--获取所有特攻角色列表
--@return 角色Id列表 (默认索引1是主攻角色)
--===============
function XSpecialRoleControl:GetSpecialRoleList()
    return self._Model.SpecialRoleModel:GetSpecialRoleList()
end

function XSpecialRoleControl:GetSpecialRoleTeamNameBySpecialTeamId(specialTeamId)
    if not specialTeamId then
        return ''
    end

    return XGuildWarConfig.GetClientConfigValue("SpecialRoleTeamName", "string", specialTeamId)
end

return XSpecialRoleControl