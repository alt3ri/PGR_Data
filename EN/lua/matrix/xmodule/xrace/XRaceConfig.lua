---@class XRaceConfig : XModel
local XRaceConfig = XClass(XModel, "XRaceConfig")

local TableKey = {
    RaceActivity = { CacheType = XConfigUtil.CacheType.Normal },
    RaceBroadcast = { CacheType = XConfigUtil.CacheType.Normal },
    RaceRoundClient = { DirPath = XConfigUtil.DirectoryType.Client },
    RaceGuess = { CacheType = XConfigUtil.CacheType.Normal },
    RaceGuessOption = {},
    RaceCharacter = {},
    RaceCharacterSkill = {},
    RaceCharacterGrade = {},
    RaceClientConfig = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String },
    RaceHomeNews = { DirPath = XConfigUtil.DirectoryType.Client },
    RaceSignalBall = {},
    RaceRoundPointGroupAuto = { DirPath = XConfigUtil.DirectoryType.Client },
    RaceCharacterGroupAuto = { DirPath = XConfigUtil.DirectoryType.Client },
    RaceMap = {},
    RacePoint = {},
    RaceGuessType = { CacheType = XConfigUtil.CacheType.Normal },
}

function XRaceConfig:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Race", TableKey)
end

function XRaceConfig:ClearPrivate()
end

function XRaceConfig:ResetAll()
end

----------config start----------

---@return XTableRaceActivity
function XRaceConfig:GetActivityById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RaceActivity, id)
end

---@return XTableRaceClientConfig
function XRaceConfig:GetClintConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RaceClientConfig, id)
end

---@return XTableRaceHomeNews[]
function XRaceConfig:GetRaceHomeNewsConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RaceHomeNews)
end

---@return XTableRaceCharacter
function XRaceConfig:GetRaceCharacterById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RaceCharacter, id)
end

---@return XTableRaceCharacter[]
function XRaceConfig:GetRaceCharacterConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RaceCharacter)
end

---@return XTableRaceCharacterSkill
function XRaceConfig:GetRaceCharacterSkillById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RaceCharacterSkill, id)
end

---@return XTableRaceSignalBall
function XRaceConfig:GetRaceSignalBallById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RaceSignalBall, id)
end

---@return XTableRaceGuess
function XRaceConfig:GetRaceGuessById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RaceGuess, id)
end

---@return XTableRaceGuessOption
function XRaceConfig:GetRaceGuessParamsById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RaceGuessOption, id)
end

---@return XTableRaceRoundClient
function XRaceConfig:GetRaceRoundById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RaceRoundClient, id)
end

---@return XTableRaceRoundClient[]
function XRaceConfig:GetRaceRoundConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RaceRoundClient)
end

---@return XTableRaceRoundPointGroupAuto
function XRaceConfig:GetRaceRoundPointGroupAutoById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RaceRoundPointGroupAuto, id)
end

---@return XTableRaceRoundPointGroupAuto[]
function XRaceConfig:GetRaceRoundPointGroupAutoConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RaceRoundPointGroupAuto)
end

---@return XTableRaceCharacterGroupAuto
function XRaceConfig:GetRaceCharacterGroupById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RaceCharacterGroupAuto, id)
end

---@return XTableRaceMap
function XRaceConfig:GetRaceMapById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RaceMap, id)
end

---@return XTableRacePoint
function XRaceConfig:GetRacePointById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RacePoint, id)
end

---@return XTableRaceGuessType
function XRaceConfig:GetRaceGuessTypeById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RaceGuessType, id)
end

---@return XTableRaceCharacterGrade[]
function XRaceConfig:GetRaceCharacterGradeConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RaceCharacterGrade)
end

---@return XTableRaceBroadcast[]
function XRaceConfig:GetRaceBroadcastConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.RaceBroadcast)
end

----------config end----------


return XRaceConfig