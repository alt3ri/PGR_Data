---@class XBigWorldAlbumModel : XModel
local XBigWorldAlbumModel = XClass(XModel, "XBigWorldAlbumModel")

local TableKey = {
    BigWorldPhotographActions = { CacheType = XConfigUtil.CacheType.Normal, },
    BigWorldPhotographCharacterActions = {},
    BigWorldPhotographFilters = { CacheType = XConfigUtil.CacheType.Normal, },
    BigWorldPhotographParams = {},
    BigWorldPhotographFunctionalUnlock = { CacheType = XConfigUtil.CacheType.Normal, },
    -- BigWorldPhotographParams = { DirPath = XConfigUtil.DirectoryType.Client },
}

function XBigWorldAlbumModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Photograph", TableKey)
    self._RedDotKey = XPlayer.Id .. "_PG__RedDot_"
    self._RefId2PhotoIdNormal = {}
    self._RefId2PhotoIdTask = {}
end

function XBigWorldAlbumModel:ClearPrivate()
    --这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldAlbumModel:ResetAll()
    --这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self._photoDatas = nil
    self._RefId2PhotoIdNormal = nil
    self._RefId2PhotoIdTask = nil
end

function XBigWorldAlbumModel:GetParamConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldPhotographParams, id)
end

function XBigWorldAlbumModel:GetAnimationConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldPhotographActions, id)
end

function XBigWorldAlbumModel:GetFilterConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldPhotographFilters, id)
end

function XBigWorldAlbumModel:GetUnlockConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldPhotographFunctionalUnlock, id)
end

function XBigWorldAlbumModel:GetFiltersConfig()
    local filtersList = {}
    local filters = self._ConfigUtil:GetByTableKey(TableKey.BigWorldPhotographFilters)
    for _, filter in pairs(filters) do
        table.insert(filtersList, filter)
    end
    return filtersList
end

function XBigWorldAlbumModel:GetCharacterActionsConfig(characterId)
    local charAction = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldPhotographCharacterActions, characterId)
    local list = {}
    for _, actionId in pairs(charAction.ActionId) do
        table.insert(list, self:GetAnimationConfigById(actionId))
    end
    return list
end

function XBigWorldAlbumModel:IsUnlock(unlockId)
    local unlockConfig = self:GetUnlockConfigById(unlockId)
    if unlockConfig.ConditionId == 0 then return true end
    return XMVCA.XBigWorldService:CheckCondition(unlockConfig.ConditionId)
end

----------public start----------

--region 获取相册数据

function XBigWorldAlbumModel:SetPhotoDatas(photoDatas)
    if not XTool.IsTableEmpty(photoDatas) then
        for _, photoData in pairs(photoDatas) do
            self:AddPhotoData(photoData)
        end
    end
end

function XBigWorldAlbumModel:SetTaskPhotoDatas(photoDatas)
    if not XTool.IsTableEmpty(photoDatas) then
        for _, photoData in pairs(photoDatas) do
            self:AddTaskPhotoData(photoData)
        end
    end
end

function XBigWorldAlbumModel:GetTaskPhotoDataByShotId(shotId)
    if not self._taskPhotoDatas then return end
    return self._taskPhotoDatas[shotId]
end

function XBigWorldAlbumModel:GetPhotoDatas()
    return self._photoDatas
end

function XBigWorldAlbumModel:UpdatePhotoData(photoData)
    if photoData.IsTaskHidePhoto then
        if photoData.MessageRefId > 0 then
            self._RefId2PhotoIdTask[photoData.MessageRefId] = photoData
        end
        for j = 1, #self._taskPhotoDatas do
            if self._taskPhotoDatas[j].Id == photoData.Id then
                self._taskPhotoDatas[j] = photoData
                break
            end
        end
        return
    end
    if photoData.MessageRefId > 0 then
        self._RefId2PhotoIdNormal[photoData.MessageRefId] = photoData
    end
    for j = 1, #self._photoDatas do
        if self._photoDatas[j].Id == photoData.Id then
            self._photoDatas[j] = photoData
            break
        end
    end
end

function XBigWorldAlbumModel:GetPhotoDataByMessageRefId(messageRefId)
    -- if not self._photoDatas then
    --     return
    -- end
    -- for j = 1, #self._photoDatas do
    --     if self._photoDatas[j].MessageRefId == messageRefId then
    --         return self._photoDatas[j]
    --     end
    -- end
    return self._RefId2PhotoIdNormal[messageRefId]
end

function XBigWorldAlbumModel:GetTaskPhotoDataByMessageRefId(messageRefId)
    -- if not self._taskPhotoDatas then
    --     return
    -- end
    -- for j = 1, #self._taskPhotoDatas do
    --     if self._taskPhotoDatas[j].MessageRefId == messageRefId then
    --         return self._taskPhotoDatas[j]
    --     end
    -- end
    return self._RefId2PhotoIdTask[messageRefId]
end

function XBigWorldAlbumModel:AddPhotoData(photoData)
    if not self._photoDatas then self._photoDatas = {} end
    table.insert(self._photoDatas, photoData)
    self._RefId2PhotoIdNormal[photoData.MessageRefId] = photoData
    return photoData
end

function XBigWorldAlbumModel:AddTaskPhotoData(photoData)
    if not self._taskPhotoDatas then self._taskPhotoDatas = {} end
    table.insert(self._taskPhotoDatas, photoData)
    self._RefId2PhotoIdTask[photoData.MessageRefId] = photoData
    return photoData
end

function XBigWorldAlbumModel:DeletePhotoDatas(photoIdList)
    for i = 1, #photoIdList do
        local id = photoIdList[i]
        for j = 1, #self._photoDatas do
            if self._photoDatas[j].Id == id then
                table.remove(self._photoDatas, j)
                break
            end
        end
    end
end

function XBigWorldAlbumModel:UpdatePhotoDatas(photoId, remake)
    for j = 1, #self._photoDatas do
        if self._photoDatas[j].Id == photoId then
            self._photoDatas[j].Remark = remake
            break
        end
    end
end

function XBigWorldAlbumModel:ReadUnlock(unlockId, subId, isNew)
    local ext = string.format("_%s_%s", unlockId, subId or 0)
    local key = self._RedDotKey .. ext
    local isLocalUnlock = XSaveTool.GetData(key)
    if isLocalUnlock then return end
    local isUnlock = self:IsUnlock(unlockId)
    if not isUnlock then return end
    XSaveTool.SaveData(key, not isNew)
end

function XBigWorldAlbumModel:IsShowRedDotContent(unlockId, subId)
    local ext = string.format("_%s_%s", unlockId, subId or 0)
    local isUnlock = XSaveTool.GetData(self._RedDotKey .. ext)
    if isUnlock then return true, false end
    
    isUnlock = self:IsUnlock(unlockId)
    return isUnlock, true
end

function XBigWorldAlbumModel:UpdateBigWorldPhotographData(bigWorldPhotographData, isInit)
    if not isInit and bigWorldPhotographData then
        if self._bigWorldPhotographData then
            local lastUnlockedCameraFiltersCnt = 0
            if self._bigWorldPhotographData.UnlockedCameraFilters then
                lastUnlockedCameraFiltersCnt = #self._bigWorldPhotographData.UnlockedCameraFilters
            end
            if bigWorldPhotographData.UnlockedCameraFilters and lastUnlockedCameraFiltersCnt ~= #bigWorldPhotographData.UnlockedCameraFilters then
                self:ReadUnlock(3, 0, true)
            end
            local lastUnlockedCharacterActionsCnt = 0
            if self._bigWorldPhotographData.UnlockedCharacterActions then
                lastUnlockedCharacterActionsCnt = #self._bigWorldPhotographData.UnlockedCharacterActions
            end
            if bigWorldPhotographData.UnlockedCharacterActions and lastUnlockedCharacterActionsCnt ~= #bigWorldPhotographData.UnlockedCharacterActions then
                self:ReadUnlock(2, 0, true)
            end
        else
            if bigWorldPhotographData.UnlockedCameraFilters then
                self:ReadUnlock(3, 0, true)
            end
            if bigWorldPhotographData.UnlockedCharacterActions then
                self:ReadUnlock(2, 0, true)
            end
        end
    end
    self._bigWorldPhotographData = bigWorldPhotographData
end

function XBigWorldAlbumModel:GetUnlockedCameraFilters()
    if not self._bigWorldPhotographData then return end
    return self._bigWorldPhotographData.UnlockedCameraFilters
end

function XBigWorldAlbumModel:GetUnlockedCharacterActions()
    if not self._bigWorldPhotographData then return end
    return self._bigWorldPhotographData.UnlockedCharacterActions
end

--endregion

----------public end----------

----------private start----------


----------private end----------

----------config start----------


----------config end----------


return XBigWorldAlbumModel