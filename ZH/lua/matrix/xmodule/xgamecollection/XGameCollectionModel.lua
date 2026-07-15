---@class XGameCollectionModel : XModel
local XGameCollectionModel = XClass(XModel, "XGameCollectionModel")

local TableKey = {
    GameCollection = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal ,Identifier = "GameType",ReadFunc = XConfigUtil.ReadType.String},
    GameCollectionConfig = { DirPath = XConfigUtil.DirectoryType.Client ,CacheType = XConfigUtil.CacheType.Normal,Identifier = "Key",ReadFunc = XConfigUtil.ReadType.String},
    GameCollectionActivity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal},

    }

function XGameCollectionModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/GameCollection", TableKey)
end
function XGameCollectionModel:ClearPrivate()
end
function XGameCollectionModel:ClearData()
    self._PendingExitRecords = nil
    self._SelectedGameType = nil
end

function XGameCollectionModel:ResetAll()
    self._ActivityId = nil
    self._GameData = nil
    self:ClearData()
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
    if XTool.IsTableEmpty(record) then
        return
    end
    self._PendingExitRecords = self._PendingExitRecords or {}
    table.insert(self._PendingExitRecords, record)
end

function XGameCollectionModel:PopPendingExitRecord()
    if XTool.IsTableEmpty(self._PendingExitRecords) then
        return nil
    end
    return table.remove(self._PendingExitRecords, 1)
end

function XGameCollectionModel:SetSelectedGameType(gameType)
    self._SelectedGameType = XTool.IsNumberValid(gameType) and gameType or nil
end

function XGameCollectionModel:GetSelectedGameType()
    return self._SelectedGameType or 0
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

-- 比较新旧 MaxScore，返回新破纪录列表;首次同步(_GameData 为 nil)不产记录,避免初始化误弹
function XGameCollectionModel:UpdateGameData(gameData)
    gameData = gameData or {}
    local oldData = self._GameData
    local newRecords = {}
    if oldData then
        for gameId, score in pairs(gameData) do
            local oldScore = oldData[gameId]
            local newMax = score and score.MaxScore or 0
            local oldMax = oldScore and oldScore.MaxScore or 0
            if oldScore and newMax > oldMax then
                local cfg = self:GetGameCollectionCfgById(gameId)
                if not XTool.IsTableEmpty(cfg) then
                    table.insert(newRecords, {
                        GameName = cfg.Name,
                        NewScore = newMax,
                    })
                end
            end
        end
    end
    self._GameData = self._GameData or {}
    for gameId, score in pairs(gameData) do
        self._GameData[gameId] = score
    end
    return newRecords
end

return XGameCollectionModel
