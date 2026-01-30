local TableKey = {
    PlotExhibitionRoleGroup = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    PlotExhibitionStoryLine = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    PlotExhibitionForce = { DirPath = XConfigUtil.DirectoryType.Client },
    PlotExhibitionCharacter = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 这虽然是军团系统做的功能，但却是在主线，分支剧情等作为战斗入口使用，所以CacheType为Normal
    StageSpeedrun = { DirPath = XConfigUtil.DirectoryType.Custom, Path = "Share/Fuben/StageSpeedrun.tab", CacheType = XConfigUtil.CacheType.Normal },
}

---@class XPlotExhibitionModel : XModel
local XPlotExhibitionModel = XClass(XModel, "XPlotExhibitionModel")

function XPlotExhibitionModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("PlotExhibition", TableKey)
end

function XPlotExhibitionModel:ClearPrivate()
end

function XPlotExhibitionModel:ResetAll()
end

---@return XTablePlotExhibitionRoleGroup[]
function XPlotExhibitionModel:GetRoleGroupConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.PlotExhibitionRoleGroup)
end

---@return XTablePlotExhibitionRoleGroup
function XPlotExhibitionModel:GetRoleGroupConfig(roleId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PlotExhibitionRoleGroup, roleId)
end

---@return XTablePlotExhibitionStoryLine[]
function XPlotExhibitionModel:GetStoryLineConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.PlotExhibitionStoryLine)
end

---@return XTablePlotExhibitionStoryLine
function XPlotExhibitionModel:GetStoryLineConfig(storyId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PlotExhibitionStoryLine, storyId)
end

---@return XTablePlotExhibitionForce[]
function XPlotExhibitionModel:GetForceConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.PlotExhibitionForce)
end

---@return XTablePlotExhibitionForce
function XPlotExhibitionModel:GetForceConfig(forceId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PlotExhibitionForce, forceId)
end

function XPlotExhibitionModel:GetRoleCover(roleId)
    return self._SaveUtil:GetData("RoleCover" .. roleId)
end

function XPlotExhibitionModel:SetRoleCover(roleId, characterId)
    self._SaveUtil:SaveData("RoleCover" .. roleId, characterId)
end

---@return XTablePlotExhibitionCharacter
function XPlotExhibitionModel:GetCharacterConfig(characterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PlotExhibitionCharacter, characterId)
end

---@return XTablePlotExhibitionCharacter[]
function XPlotExhibitionModel:GetCharacterConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.PlotExhibitionCharacter)
end

---@return XTableStageSpeedrun
function XPlotExhibitionModel:GetStageSpeedrunConfig(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageSpeedrun, stageId, true)
end

-- 根据groupId, 分章节记录速通模式开关的状态
function XPlotExhibitionModel:GetStageGroupId(stageId)
    local config = self:GetStageSpeedrunConfig(stageId)
    if config then
        return config.GroupId
    end
end

return XPlotExhibitionModel