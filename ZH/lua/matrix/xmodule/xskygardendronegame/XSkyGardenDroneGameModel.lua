local XSGDroneStageData = require("XModule/XSkyGardenDroneGame/XData/XSGDroneStageData")
local XSkyGardenDroneGameConfigModel = require("XModule/XSkyGardenDroneGame/XSkyGardenDroneGameConfigModel")

---@class XSkyGardenDroneGameModel : XSkyGardenDroneGameConfigModel
local XSkyGardenDroneGameModel = XClass(XSkyGardenDroneGameConfigModel, "XSkyGardenDroneGameModel")

function XSkyGardenDroneGameModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    ---@type table<number, XSGDroneStageData>
    self._StageDatas = {}
    self._StorageStageData = false

    self._ChapterFirstUnlockHash = false

    self:_InitTableKey()
end

function XSkyGardenDroneGameModel:ClearPrivate()
    --这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
    self:__SaveChapterFirstUnlockHash()
end

function XSkyGardenDroneGameModel:ResetAll()
    --这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

function XSkyGardenDroneGameModel:UpdateStageData(stageInfos)
    self._StageDatas = {}

    if not XTool.IsTableEmpty(stageInfos) then
        for stageId, stageInfo in pairs(stageInfos) do
            local stageData = XSGDroneStageData.New()

            stageData:Update(stageId, stageInfo)
            self._StageDatas[stageId] = stageData
        end
    end
end

function XSkyGardenDroneGameModel:UpdateStorageStageData(storageStageData)
    self._StorageStageData = storageStageData
end

function XSkyGardenDroneGameModel:UpdateStorageStageSaveData(saveData)
    if self._StorageStageData then
        self._StorageStageData.SaveData = saveData
    end
end

function XSkyGardenDroneGameModel:ClearStorageStageData()
    self._StorageStageData = false
end

function XSkyGardenDroneGameModel:GetStorageStageData()
    return self._StorageStageData
end

---@return XSGDroneStageData
function XSkyGardenDroneGameModel:GetStageData(stageId)
    return self._StageDatas[stageId]
end

function XSkyGardenDroneGameModel:CheckChapterFirstUnlock(chapterId)
    if not self._ChapterFirstUnlockHash then
        self._ChapterFirstUnlockHash = XSaveTool.GetData(self:__GetChapterFirstUnlockHashKey())
    end

    if not self._ChapterFirstUnlockHash then
        return true
    end

    return not self._ChapterFirstUnlockHash[chapterId]
end

function XSkyGardenDroneGameModel:RecordChapterUnlock(chapterId)
    if not self._ChapterFirstUnlockHash then
        self._ChapterFirstUnlockHash = {}
    end

    self._ChapterFirstUnlockHash[chapterId] = true
end

function XSkyGardenDroneGameModel:__GetChapterFirstUnlockHashKey()
    return "BW_SG_DRONE_GAME_CHAPTER_FIRST_UNLOCK_" .. tostring(XPlayer.Id)
end

function XSkyGardenDroneGameModel:__SaveChapterFirstUnlockHash()
    if not self._ChapterFirstUnlockHash then
        return
    end

    XSaveTool.SaveData(self:__GetChapterFirstUnlockHashKey(), self._ChapterFirstUnlockHash)
end

return XSkyGardenDroneGameModel