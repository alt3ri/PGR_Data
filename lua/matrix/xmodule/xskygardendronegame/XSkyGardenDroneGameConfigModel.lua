---@class XSkyGardenDroneGameConfigModel : XModel
local XSkyGardenDroneGameConfigModel = XClass(XModel, "XSkyGardenDroneGameConfigModel")

local SgDroneGameTableKey = {
    SgDroneGameChapter = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    SgDroneGameConfig = {
        Identifier = "Key",
        ReadFunc = XConfigUtil.ReadType.String,
        CacheType = XConfigUtil.CacheType.Normal,
    },
    SgDroneGameStage = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    SgDroneGameStarTarget = {},
    SgDroneGameDroneDisplay = {
        DirPath = XConfigUtil.DirectoryType.Client,
    },
    SgDroneGameDialogue = {
        DirPath = XConfigUtil.DirectoryType.Client,
    },
}

function XSkyGardenDroneGameConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/SkyGarden/SgDroneGame", SgDroneGameTableKey)
end

---@return XTableSgDroneGameChapter[]
function XSkyGardenDroneGameConfigModel:GetSgDroneGameChapterConfigs()
    return self._ConfigUtil:GetByTableKey(SgDroneGameTableKey.SgDroneGameChapter) or {}
end

---@return XTableSgDroneGameChapter
function XSkyGardenDroneGameConfigModel:GetSgDroneGameChapterConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(SgDroneGameTableKey.SgDroneGameChapter, id, false) or {}
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameChapterNameById(id)
    local config = self:GetSgDroneGameChapterConfigById(id)

    return config.Name
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameChapterTypeById(id)
    local config = self:GetSgDroneGameChapterConfigById(id)

    return config.Type
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameChapterTimeIdById(id)
    local config = self:GetSgDroneGameChapterConfigById(id)

    return config.TimeId
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameChapterConditionById(id)
    local config = self:GetSgDroneGameChapterConfigById(id)

    return config.Condition
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameChapterTeachDroneIdById(id)
    local config = self:GetSgDroneGameChapterConfigById(id)

    return config.TeachDroneId
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameChapterHardModeTextById(id)
    local config = self:GetSgDroneGameChapterConfigById(id)

    return config.HardModeText
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameChapterEasyDroneHpById(id)
    local config = self:GetSgDroneGameChapterConfigById(id)

    return config.EasyDroneHp
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameChapterIsEnableAssistanceById(id)
    local config = self:GetSgDroneGameChapterConfigById(id)

    return config.IsEnableAssistance
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameChapterIconUrlById(id)
    local config = self:GetSgDroneGameChapterConfigById(id)

    return config.IconUrl
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameChapterStageIdsById(id)
    local config = self:GetSgDroneGameChapterConfigById(id)

    return config.StageIds
end

---@return XTableSgDroneGameConfig[]
function XSkyGardenDroneGameConfigModel:GetSgDroneGameConfigConfigs()
    return self._ConfigUtil:GetByTableKey(SgDroneGameTableKey.SgDroneGameConfig) or {}
end

---@return XTableSgDroneGameConfig
function XSkyGardenDroneGameConfigModel:GetSgDroneGameConfigConfigByKey(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(SgDroneGameTableKey.SgDroneGameConfig, key, false) or {}
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameConfigValuesByKey(key)
    local config = self:GetSgDroneGameConfigConfigByKey(key)

    return config.Values
end

---@return XTableSgDroneGameStage[]
function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageConfigs()
    return self._ConfigUtil:GetByTableKey(SgDroneGameTableKey.SgDroneGameStage) or {}
end

---@return XTableSgDroneGameStage
function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(SgDroneGameTableKey.SgDroneGameStage, id, false) or {}
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageNameById(id)
    local config = self:GetSgDroneGameStageConfigById(id)

    return config.Name
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageDescById(id)
    local config = self:GetSgDroneGameStageConfigById(id)

    return config.Desc
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageTypeById(id)
    local config = self:GetSgDroneGameStageConfigById(id)

    return config.Type
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStagePreStageIdById(id)
    local config = self:GetSgDroneGameStageConfigById(id)

    return config.PreStageId
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageConditionById(id)
    local config = self:GetSgDroneGameStageConfigById(id)

    return config.Condition
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageMapIdById(id)
    local config = self:GetSgDroneGameStageConfigById(id)

    return config.MapId
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageSkipIdById(id)
    local config = self:GetSgDroneGameStageConfigById(id)

    return config.SkipId
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageIconUrlById(id)
    local config = self:GetSgDroneGameStageConfigById(id)

    return config.IconUrl
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageIsFirstById(id)
    local config = self:GetSgDroneGameStageConfigById(id)

    return config.IsFirst
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageObjectiveIdById(id)
    local config = self:GetSgDroneGameStageConfigById(id)

    return config.ObjectiveId
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageStarTargetsById(id)
    local config = self:GetSgDroneGameStageConfigById(id)

    return config.StarTargets
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStageStarRewardIdsById(id)
    local config = self:GetSgDroneGameStageConfigById(id)

    return config.StarRewardIds
end

---@return XTableSgDroneGameStarTarget[]
function XSkyGardenDroneGameConfigModel:GetSgDroneGameStarTargetConfigs()
    return self._ConfigUtil:GetByTableKey(SgDroneGameTableKey.SgDroneGameStarTarget) or {}
end

---@return XTableSgDroneGameStarTarget
function XSkyGardenDroneGameConfigModel:GetSgDroneGameStarTargetConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(SgDroneGameTableKey.SgDroneGameStarTarget, id, false) or {}
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStarTargetDescById(id)
    local config = self:GetSgDroneGameStarTargetConfigById(id)

    return config.Desc
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStarTargetProgressDescById(id)
    local config = self:GetSgDroneGameStarTargetConfigById(id)

    return config.ProgressDesc
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStarTargetTypeById(id)
    local config = self:GetSgDroneGameStarTargetConfigById(id)

    return config.Type
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameStarTargetParamsById(id)
    local config = self:GetSgDroneGameStarTargetConfigById(id)

    return config.Params
end

---@return XTableSgDroneGameDroneDisplay[]
function XSkyGardenDroneGameConfigModel:GetSgDroneGameDroneDisplayConfigs()
    return self._ConfigUtil:GetByTableKey(SgDroneGameTableKey.SgDroneGameDroneDisplay) or {}
end

---@return XTableSgDroneGameDroneDisplay
function XSkyGardenDroneGameConfigModel:GetSgDroneGameDroneDisplayConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(SgDroneGameTableKey.SgDroneGameDroneDisplay, id, false) or {}
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameDroneDisplayNameById(id)
    local config = self:GetSgDroneGameDroneDisplayConfigById(id) 

    return config.Name
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameDroneDisplayDescriptionById(id)
    local config = self:GetSgDroneGameDroneDisplayConfigById(id) 

    return config.Description
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameDroneDisplayTeachingVideoIdById(id)
    local config = self:GetSgDroneGameDroneDisplayConfigById(id) 

    return config.TeachingVideoId
end


---@return XTableSgDroneGameDialogue[]
function XSkyGardenDroneGameConfigModel:GetSgDroneGameDialogueConfigs()
    return self._ConfigUtil:GetByTableKey(SgDroneGameTableKey.SgDroneGameDialogue) or {}
end

---@return XTableSgDroneGameDialogue
function XSkyGardenDroneGameConfigModel:GetSgDroneGameDialogueConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(SgDroneGameTableKey.SgDroneGameDialogue, id, false) or {}
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameDialogueTriggerTagById(id)
    local config = self:GetSgDroneGameDialogueConfigById(id)

    return config.TriggerTag
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameDialogueTypeById(id)
    local config = self:GetSgDroneGameDialogueConfigById(id)

    return config.Type
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameDialogueDelayById(id)
    local config = self:GetSgDroneGameDialogueConfigById(id)

    return config.Delay
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameDialoguePriorityById(id)
    local config = self:GetSgDroneGameDialogueConfigById(id)

    return config.Priority
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameDialogueHeadIconById(id)
    local config = self:GetSgDroneGameDialogueConfigById(id)

    return config.HeadIcon
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameDialogueDurationById(id)
    local config = self:GetSgDroneGameDialogueConfigById(id)

    return config.Duration
end

function XSkyGardenDroneGameConfigModel:GetSgDroneGameDialogueDialogueById(id)
    local config = self:GetSgDroneGameDialogueConfigById(id)

    return config.Dialogue
end

return XSkyGardenDroneGameConfigModel
