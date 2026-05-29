XTeamConfig = XTeamConfig or {}

local TABLE_TEAMTYPE = "Share/Team/TeamType.tab"
local TABLE_PATH = "Share/Team/Team.tab"
local TABLE_TEAM_PREFAB_TAG = "Share/Team/TeamPrefabTag.tab"
local TeamTypeCfg
local TeamCfg
local TeamTypeDic = {}
local TeamPrefabTagCfg

XTeamConfig.MEMBER_AMOUNT = 3

function XTeamConfig.Init()
    TeamTypeCfg = XTableManager.ReadByIntKey(TABLE_TEAMTYPE, XTable.XTableTeamType, "TeamId")
    TeamCfg = XTableManager.ReadByIntKey(TABLE_PATH, XTable.XTableTeam, "Id")
    if TeamTypeCfg == nil then
        XLog.Error("XTeamManager Init 错误, 配置表读取失败, 配置表的路径是: " .. TABLE_TEAMTYPE)
        return
    end

    XTeamConfig.ConstructTeamCfg()

    TeamPrefabTagCfg = XTableManager.ReadByIntKey(TABLE_TEAM_PREFAB_TAG, XTable.XTableTeamPrefabTag, "Id")
end


function XTeamConfig.ConstructTeamCfg()
    TeamTypeDic = {}
    for _, tcfg in pairs(TeamTypeCfg) do
        local typeId = tcfg.TypeId
        if typeId > 0 then
            if TeamTypeDic[typeId] == nil then
                TeamTypeDic[typeId] = {}
            end

            table.insert(TeamTypeDic[typeId], tcfg)
        end
    end
end

function XTeamConfig.GetTeamCfg()
    return TeamCfg
end

function XTeamConfig.GetTeamCfgById(id)
    return TeamCfg[id]
end

function XTeamConfig.GetTeamTypeCfg(type)
    return TeamTypeCfg[type]
end

-- 通过类型获取限定的队伍配置
function XTeamConfig.GetTeamsByTypeId(typeId)
    if TeamTypeDic[typeId] == nil then
        return nil
    end
    return TeamTypeDic[typeId]
end

--region TeamPrefabTag
function XTeamConfig.GetTeamPrefabTagCfgById(id)
    return TeamPrefabTagCfg and TeamPrefabTagCfg[id]
end

function XTeamConfig.GetAllTeamPrefabTagCfg()
    return TeamPrefabTagCfg
end
--endregion