local TableKey = {
    LineArithmeticCell = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    LineArithmeticMap = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    LineArithmeticActivity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    LineArithmeticChapter = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    LineArithmeticStage = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    LineArithmeticCar = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    LineArithmetic3Help = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    LineArithmeticClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key", },
}

---@class XLineArithmetic3Model : XModel
local XLineArithmetic3Model = XClass(XModel, "XLineArithmetic3Model")

function XLineArithmetic3Model:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/LineArithmetic", TableKey)

    -- 服务器数据
    self._ActivityId = 0
    self._PassedStages = {}  -- 已通关的关卡 {stageId = starCount}
end

function XLineArithmetic3Model:ClearPrivate()
    self:SetCurrentGameStageId(nil)
end

function XLineArithmetic3Model:ResetAll()
    self._ActivityId = 0
    self._PassedStages = {}
    self._CurrentGameStageId = nil
end

----------public start----------

--- 设置服务器数据
---@param data table 服务器活动数据
function XLineArithmetic3Model:SetDataFromServer(data)
    if not data then
        return
    end

    self._ActivityId = data.ActivityId or 0

    -- 解析已通关关卡数据
    self._PassedStages = {}
    if data.StageRecords then
        for _, stageData in ipairs(data.StageRecords) do
            if stageData.StageId then
                self._PassedStages[stageData.StageId] = stageData.Star or 0
            end
        end
    end
end

--- 获取活动ID
---@return number
function XLineArithmetic3Model:GetActivityId()
    return self._ActivityId or 0
end

---@return boolean
function XLineArithmetic3Model:CheckHasValidActivityId()
    return XTool.IsNumberValidEx(self._ActivityId)
end

--- 获取关卡星数
---@param stageId number 关卡ID
---@return number 星数，未通关返回0
function XLineArithmetic3Model:GetStageStar(stageId)
    return self._PassedStages[stageId] or 0
end

--- 关卡是否已通关
---@param stageId number 关卡ID
---@return boolean
function XLineArithmetic3Model:IsStagePassed(stageId)
    return self._PassedStages[stageId] ~= nil
end

--- 设置关卡通关记录（结算成功后刷新本地记录）
---@param stageId number 关卡ID
---@param star number 星数
function XLineArithmetic3Model:SetStagePassed(stageId, star)
    if not stageId or stageId == 0 then
        return
    end
    local oldStar = self._PassedStages[stageId] or 0
    self._PassedStages[stageId] = math.max(oldStar, star or 0)
end

--- 根据关卡ID获取地图数据
---@param stageId number 关卡ID
---@return table 地图数据，key为Row
function XLineArithmetic3Model:GetMapByStageId(stageId)
    local stageConfig = self:GetStageConfig(stageId)
    if not stageConfig then
        return {}
    end
    return self:GetMapConfig(stageConfig.MapId)
end

--- 获取关卡名称
---@param stageId number 关卡ID
---@return string
function XLineArithmetic3Model:GetStageName(stageId)
    local config = self:GetStageConfig(stageId)
    if not config then
        return ""
    end
    return config.Name or ""
end

----------public end----------

----------private start----------

--- 解析地图数据，转换为游戏逻辑需要的格式
---@param mapData table 地图配置数据（key为Row）
---@return table[][] 二维数组，[y][x]格式
function XLineArithmetic3Model:ParseMapData(mapData)
    local map = {}

    for row, rowConfig in pairs(mapData) do
        local y = row
        map[y] = {}

        for x, cellId in ipairs(rowConfig.Column) do
            if cellId > 0 then
                local cellConfig = self:GetCellConfig(cellId)
                if cellConfig then
                    map[y][x] = {
                        Type = cellConfig.Type,
                        Color = cellConfig.Color,
                        CharacterId = cellConfig.CharacterId,
                        CellId = cellId,
                    }
                end
            end
        end
    end

    return map
end

--- 查找起点格位置
---@param mapData table 地图配置数据
---@return table|nil 起点位置 {x, y}，如果没找到返回nil
function XLineArithmetic3Model:FindStartPosition(mapData)
    local XLineArithmetic3Enum = require("XModule/XLineArithmetic3/XLineArithmetic3Enum")

    for row, rowConfig in pairs(mapData) do
        local y = row
        for x, cellId in ipairs(rowConfig.Column) do
            if cellId > 0 then
                local cellConfig = self:GetCellConfig(cellId)
                if cellConfig and cellConfig.Type == XLineArithmetic3Enum.GridType.Start then
                    return { x = x, y = y }
                end
            end
        end
    end

    return nil
end

--- 获取起点格的完整信息
---@param stageId number 关卡ID
---@return table|nil 起点信息 {x, y, gridName, cellId}
function XLineArithmetic3Model:GetStartInfo(stageId)
    local mapData = self:GetMapByStageId(stageId)
    local startPos = self:FindStartPosition(mapData)

    if not startPos then
        return nil
    end

    local rowConfig = mapData[startPos.y]
    if not rowConfig then
        return nil
    end

    local cellId = rowConfig.Column[startPos.x]
    local cellConfig = self:GetCellConfig(cellId)

    if not cellConfig then
        return nil
    end

    return {
        x = startPos.x,
        y = startPos.y,
        gridName = cellConfig.GridName,
        cellId = cellId,
    }
end

----------private end----------

----------config start----------

--- 获取关卡配置
---@param stageId number 关卡ID
---@return XTableLineArithmeticStage|nil
function XLineArithmetic3Model:GetStageConfig(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticStage, stageId)
end

--- 获取地图配置（按MapId获取）
---@param mapId number 地图ID
---@return table 地图数据，key为Row，value为配置
function XLineArithmetic3Model:GetMapConfig(mapId)
    local map = {}
    local configs = self._ConfigUtil:GetByTableKey(TableKey.LineArithmeticMap)

    for _, config in pairs(configs) do
        if config.MapId == mapId then
            map[config.Row] = config
        end
    end

    return map
end

--- 获取格子配置
---@param cellId number 格子ID
---@return XTableLineArithmeticCell|nil
function XLineArithmetic3Model:GetCellConfig(cellId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticCell, cellId)
end

--- 获取车辆配置
---@param carId number 车辆ID
---@return XTableLineArithmeticCar|nil
function XLineArithmetic3Model:GetCarConfig(carId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticCar, carId)
end

--- 获取帮助配置
---@param helpId number 帮助ID
---@return table|nil
function XLineArithmetic3Model:GetHelpConfig(helpId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmetic3Help, helpId, true)
end

---@return XTableLineArithmeticClientConfig
function XLineArithmetic3Model:GetClientConfigCfgByKey(key, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticClientConfig, key, notips)
end

function XLineArithmetic3Model:GetClientConfigTextByKey(key, index)
    index = index or 1

    local cfg = self:GetClientConfigCfgByKey(key)

    if cfg then
        return cfg.Values[index] or ''
    end

    return ''
end

function XLineArithmetic3Model:GetClientConfigNumberByKey(key, index)
    index = index or 1
    
    local cfg = self:GetClientConfigCfgByKey(key)

    if cfg then
        local valStr = cfg.Values[index]

        if not string.IsNilOrEmpty(valStr) and string.IsFloatNumber(valStr) then
            return tonumber(valStr)
        end
    end
    
    return 0
end

--- 根据地图ID获取帮助配置列表（ID 规则：mapId*1000+1, mapId*1000+2, ... 直到无配置）
---@param mapId number 地图ID
---@return table[] 帮助配置数组，按序号 0001、0002... 顺序
function XLineArithmetic3Model:GetHelpConfigsByMapId(mapId)
    local list = {}
    local baseId = (mapId or 0) * 1000
    local index = 1
    while true do
        local helpId = baseId + index
        local cfg = self:GetHelpConfig(helpId)
        if not cfg then
            break
        end
        list[#list + 1] = cfg
        index = index + 1
    end
    return list
end

--- 获取格子配置（适配XLineArithmetic3Game的接口）
---@param gridId number 格子ID
---@return XTableLineArithmeticCell|nil
function XLineArithmetic3Model:GetGridById(gridId)
    return self:GetCellConfig(gridId)
end

--- 获取乘客配置（适配XLineArithmetic3Game的接口）
--- 当前设计中乘客信息直接在Cell配置中，返回nil让Game使用gridCfg中的信息
---@param _passengerId number 乘客ID（未使用）
---@return table|nil
function XLineArithmetic3Model:GetPassengerById(_passengerId)
    -- 如果未来有单独的Passenger表，在这里实现
    return nil
end

--- 获取格子配置（适配XLineArithmetic3Game的接口）
---@param characterId number 角色ID
---@return XTableLineArithmeticCell|nil
function XLineArithmetic3Model:GetCellConfigByCharacterId(characterId)
    local configs = self._ConfigUtil:GetByTableKey(TableKey.LineArithmeticCell)
    for _, config in pairs(configs) do
        if config.CharacterId == characterId then
            return config
        end
    end
    return nil
end

--- 获取章节配置
---@param chapterId number 章节ID
---@return XTableLineArithmeticChapter|nil
function XLineArithmetic3Model:GetChapterConfig(chapterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticChapter, chapterId)
end

--- 获取所有章节配置
---@return XTableLineArithmeticChapter[]
function XLineArithmetic3Model:GetAllChapterConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.LineArithmeticChapter)
    local chapters = {}

    for _, config in pairs(configs) do
        table.insert(chapters, config)
    end

    -- 按ChapterIndex排序
    table.sort(chapters, function(a, b)
        return (a.Id or 0) < (b.Id or 0)
    end)

    return chapters
end

--- 判断章节是否解锁
---@param chapterId number 章节ID
---@return boolean
function XLineArithmetic3Model:IsChapterUnlock(chapterId)
    local chapterConfig = self:GetChapterConfig(chapterId)
    if not chapterConfig then
        return false
    end
    
    -- 如果有时间，则需要在时间内
    if XTool.IsNumberValidEx(chapterConfig.TimeId) and not XFunctionManager.CheckInTimeByTimeId(chapterConfig.TimeId, false) then
        local startTime = XFunctionManager.GetStartTimeByTimeId(chapterConfig.TimeId)
        local leftTime = math.max(0, startTime - XTime.GetServerNowTimestamp())
        return false, XUiHelper.FormatTextEx(self:GetClientConfigTextByKey('ChapterTimeUnlockFormat'), XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    end

    -- 如果没有解锁条件，默认解锁
    if not chapterConfig.UnlockCondition or #chapterConfig.UnlockCondition == 0 then
        return true
    end

    -- 检查解锁条件
    for _, conditionId in ipairs(chapterConfig.UnlockCondition) do
        if not XConditionManager.CheckCondition(conditionId) then
            return false, XConditionManager.GetConditionDescById(conditionId)
        end
    end

    return true
end

--- 获取章节下的所有关卡
---@param chapterId number 章节ID
---@return XTableLineArithmeticStage[]
function XLineArithmetic3Model:GetStagesByChapterId(chapterId)
    local configs = self._ConfigUtil:GetByTableKey(TableKey.LineArithmeticStage)
    local stages = {}

    for _, config in pairs(configs) do
        if config.ChapterId == chapterId then
            table.insert(stages, config)
        end
    end

    -- 按 Id 从小到大排序
    table.sort(stages, function(a, b)
        return (a.Id or 0) < (b.Id or 0)
    end)

    return stages
end

--- 判断关卡是否解锁
---@param stageId number 关卡ID
---@return boolean
function XLineArithmetic3Model:IsStageUnlock(stageId)
    local stageConfig = self:GetStageConfig(stageId)
    if not stageConfig then
        return false
    end

    local preStageId = stageConfig.PreStageId
    if preStageId and preStageId > 0 and not self:IsStagePassed(preStageId) then
        return false
    end

    -- 如果没有解锁条件，默认解锁
    if not stageConfig.UnlockCondition or #stageConfig.UnlockCondition == 0 then
        return true
    end

    -- 检查解锁条件
    for _, conditionId in ipairs(stageConfig.UnlockCondition) do
        if not XConditionManager.CheckCondition(conditionId) then
            return false
        end
    end

    return true
end

--- 获取下一关ID
---@param currentStageId number 当前关卡ID
---@return number|nil 下一关ID，如果没有下一关返回nil
function XLineArithmetic3Model:GetNextStageId(currentStageId)
    local currentConfig = self:GetStageConfig(currentStageId)
    if not currentConfig then
        return nil
    end

    -- 获取同章节的所有关卡
    local stages = self:GetStagesByChapterId(currentConfig.ChapterId)

    -- 找到当前关卡的索引
    local currentIndex = 0
    for i, stage in ipairs(stages) do
        if stage.Id == currentStageId then
            currentIndex = i
            break
        end
    end

    -- 返回下一关
    if currentIndex > 0 and currentIndex < #stages then
        return stages[currentIndex + 1].Id
    end

    return nil
end

----------config end----------

--- 获取当前活动的所有章节配置
---@return XTableLineArithmeticChapter[]
function XLineArithmetic3Model:GetAllChaptersCurrentActivity()
    local activityId = self._ActivityId or 0
    if activityId == 0 then
        return {}
    end

    local allChapters = self:GetAllChapterConfigs()
    local result = {}
    for _, config in ipairs(allChapters) do
        if config.ActivityId == activityId then
            result[#result + 1] = config
        end
    end
    return result
end

--- 判断章节是否开放（解锁且活动未过期）
---@param chapterId number 章节ID
---@return boolean
function XLineArithmetic3Model:IsChapterOpen(chapterId)
    return self:IsChapterUnlock(chapterId)
end

--- 判断章节是否为新章节（已解锁但旗下无任何关卡通关）
---@param chapterId number 章节ID
---@return boolean
function XLineArithmetic3Model:IsNewChapter(chapterId)
    if not self:IsChapterUnlock(chapterId) then
        return false
    end

    local stages = self:GetStagesByChapterId(chapterId)
    for _, stage in ipairs(stages) do
        if self:IsStagePassed(stage.Id) then
            return false
        end
    end
    return true
end

--- 是否过期
---@return boolean
function XLineArithmetic3Model:GetActivityConfig(notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticActivity, self._ActivityId, notips)
end

function XLineArithmetic3Model:IsExpire()
    local activityConfig = self:GetActivityConfig(true)
    if not activityConfig then
        return false
    end
    local timeId = activityConfig.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    if not endTime then
        return false
    end
    if XTime.GetServerNowTimestamp() > endTime then
        return true
    end
    return false
end

function XLineArithmetic3Model:GetTaskList()
    if not XTool.IsNumberValidEx(self._ActivityId) then
        return {}
    end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LineArithmeticActivity, self._ActivityId)
    if not config then
        return {}
    end
    return config.TaskIds
end

function XLineArithmetic3Model:SetCurrentGameStageId(stageId)
    self._CurrentGameStageId = stageId
end

function XLineArithmetic3Model:IsOnGame(stageId)
    return self._CurrentGameStageId == stageId
end

return XLineArithmetic3Model