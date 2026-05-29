---@class XGameCollectionModel : XModel
local XGameCollectionModel = XClass(XModel, "XGameCollectionModel")

local TableKey = {
    GameCollection = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    GameCollectionConfig = { DirPath = XConfigUtil.DirectoryType.Client ,CacheType = XConfigUtil.CacheType.Normal,Identifier = "Key",ReadFunc = XConfigUtil.ReadType.String},
    GameCollectionActivity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal},

    }

function XGameCollectionModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/GameCollection", TableKey)
end

function XGameCollectionModel:ClearPrivate()
    self._PendingExitRecord = nil
    self._SelectedGameType = nil
    self._GameSnapshots = nil
end

function XGameCollectionModel:ResetAll()
    self._ActivityId = nil
    self._GameData = nil
    self:ClearPrivate()
end

--region Config Accessors
function XGameCollectionModel:GetGameCollectionCfgs()
    return self._ConfigUtil:GetByTableKey(TableKey.GameCollection)
end

function XGameCollectionModel:GetGameCollectionCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GameCollection, id)
end

function XGameCollectionModel:GetGameCollectionConfig(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GameCollectionConfig, key)
end
function XGameCollectionModel:GetGameCollectionActivityCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GameCollectionActivity, id)
end

function XGameCollectionModel:GetMaxScore(gameType)
    if XTool.IsTableEmpty(self._GameData) then
        return 0
    end

    return self._GameData[gameType] and self._GameData[gameType].MaxScore or 0
end

function XGameCollectionModel:SetPendingExitRecord(record)
    self._PendingExitRecord = record
end

function XGameCollectionModel:PopPendingExitRecord()
    local record = self._PendingExitRecord
    self._PendingExitRecord = nil
    return record
end

function XGameCollectionModel:SetSelectedGameType(gameType)
    self._SelectedGameType = XTool.IsNumberValid(gameType) and gameType or nil
end

function XGameCollectionModel:GetSelectedGameType()
    return self._SelectedGameType or 0
end

function XGameCollectionModel:SetGameSnapshot(gameType, snapshot)
    if not XTool.IsNumberValid(gameType) then
        return
    end

    self._GameSnapshots = self._GameSnapshots or {}
    self._GameSnapshots[gameType] = snapshot
end

function XGameCollectionModel:GetGameSnapshot(gameType)
    return self._GameSnapshots and self._GameSnapshots[gameType]
end

function XGameCollectionModel:ClearGameSnapshot(gameType)
    if XTool.IsTableEmpty(self._GameSnapshots) then
        return
    end

    if XTool.IsNumberValid(gameType) then
        self._GameSnapshots[gameType] = nil
        return
    end

    self._GameSnapshots = nil
end
--endregion

function XGameCollectionModel:SetActivityId(activityId)
    self._ActivityId = activityId
end

function XGameCollectionModel:GetActivityId()
    if not XTool.IsNumberValid(self._ActivityId) then
        -- XLog.Error("XGameCollectionModel:GetActivityId 无效的活动Id", self._ActivityId)
        return nil
    end
    return self._ActivityId
end

function XGameCollectionModel:GetGameCollectionTaskCfgs()
    if not self:GetActivityId() then
        return nil
    end
    return self:GetGameCollectionActivityCfgById(self:GetActivityId()).TaskTimeLimitIds
end

function XGameCollectionModel:UpdateGameData(gameData)
    self._GameData = self._GameData or {}
    for gameId, score in pairs(gameData) do
        self._GameData[gameId] = score
    end
end

return XGameCollectionModel
