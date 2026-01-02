--- 公会战
---@class XGuildWarModel : XModel
local XGuildWarModel = XClass(XModel, "XGuildWarModel")

local XGuildWarRound = require("XEntity/XGuildWar/Round/XGuildWarRound")


local TableNormal = {
    GuildWarPlayThrough = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    GuildWarDragonRage = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    GuildWarDragonRageNodeChange = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    GuildWarClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key" },

    GuildWarSpecialRoleTeam = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
}

function XGuildWarModel:OnInit()
    -- 初始化配置表
    self._ConfigUtil:InitConfigByTableKey("GuildWar", TableNormal, XConfigUtil.CacheType.Normal)
    
    -- 初始化驻守玩法数据管理对象
    self._GarrisonData = require('XModule/XGuildWar/Entity/XGuildWarGarrisonData').New()
    -- 初始化龙怒系统玩法数据管理对象
    self._DragonRageData = require('XModule/XGuildWar/Entity/XGuildWarDragonRageData').New()
    
    ---@type XSpecialRoleModel @特攻角色系统子model
    self.SpecialRoleModel = self:AddSubModel(require('XModule/XGuildWar/SubModule/SpecialRole/XSpecialRoleModel'))
    
    ---@type XActionQueueModel @行为队列子model
    self.ActionQueueModel = self:AddSubModel(require('XModule/XGuildWar/SubModule/ActionQueue/XActionQueueModel'))
    
    ---@type XRoleStationModel @角色驻扎玩法子model
    self.RoleStationModel = self:AddSubModel(require('XModule/XGuildWar/SubModule/RoleStation/XRoleStationModel'))
    
    self:InitRoundData()
end

function XGuildWarModel:ClearPrivate()

end

function XGuildWarModel:ResetAll()
    self._DragonRageData:ResetData()
    self:InitRoundData()
end

function XGuildWarModel:InitRoundData()
    -- 轮次源数据
    self._RoundDatas = {}
    self._BattleManager = nil
end

function XGuildWarModel:GetGarrisonData()
    return self._GarrisonData
end

---@return XGuildWarDragonRageData
function XGuildWarModel:GetDragonRageData()
    return self._DragonRageData
end

--region 轮次数据相关

--================
--用轮次Id获取轮次管理器
--@param roundId:轮次Id
--若roundId为nil或为0会返回空
--================
---@return XGuildWarRound
function XGuildWarModel:GetRoundByRoundId(roundId)
    if not roundId or (roundId == 0) then
        return nil
    end
    if not self._RoundDatas[roundId] then
        self._RoundDatas[roundId] = XGuildWarRound.New(roundId)
    end
    return self._RoundDatas[roundId]
end

--- 只有当前轮次进入公会战地图需要用到该对象
--[[ todo 先不生效BattleManager改造
function XGuildWarModel:GetBattleManager()
    if self._BattleManager == nil then
        --todo 混合结构临时交叉访问
        ---@type XGuildWarRound
        local curRoundData = XDataCenter.GuildWarManager.GetCurrentRound()
        
        ---@type XGWBattleManager
        self._BattleManager = require("XEntity/XGuildWar/Battle/XGWBattleManager").New(curRoundData:GetDifficulty())
        self._BattleManager:UpdateCurrentRoundData(curRoundData)
    end
    
    
    return self._BattleManager
end
--]]

--endregion


--region Configs

function XGuildWarModel:GetDragonRageCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.GuildWarDragonRage, id)
end

function XGuildWarModel:GetDragonRageNodeChangeCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.GuildWarDragonRageNodeChange, id)
end

function XGuildWarModel:GetDragonRagePlayThroughCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.GuildWarPlayThrough, id)
end

function XGuildWarModel:GetGuildWarClientConfig(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.GuildWarClientConfig, key)
end

---@return XTableGuildWarSpecialRoleTeam[]
function XGuildWarModel:GetGuildWarSpecialRoleTeamCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.GuildWarSpecialRoleTeam)
end
--endregion

--region 龙怒玩法相关

function XGuildWarModel:GetDragonRageOpenIsMark()
    return self._SaveUtil:GetData('DragonRageMark')
end

function XGuildWarModel:SetDragonRageOpenMark(mark)
    self._SaveUtil:SaveData('DragonRageMark', mark)
end

function XGuildWarModel:GetIsDragonRageHideSweepTips(roundId, gameThough)
    local data = tostring(roundId)..'_'..tostring(gameThough)
    
    return self._SaveUtil:GetData('DragonRageHideSweepTipsMark') == data
end

function XGuildWarModel:SetDragonRageHideSweepTips(roundId, gameThough)
    local data = tostring(roundId)..'_'..tostring(gameThough)

    self._SaveUtil:SaveData('DragonRageHideSweepTipsMark', data)
end
--endregion

return XGuildWarModel