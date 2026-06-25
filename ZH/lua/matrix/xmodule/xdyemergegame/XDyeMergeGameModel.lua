---@class XDyeMergeGameModel : XModelBase
local XDyeMergeGameModel = XClass(XModelBase, "XDyeMergeGameModel")
function XDyeMergeGameModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
end

function XDyeMergeGameModel:ClearPrivate()
    self:CacheCurGamingStageId(nil)
end

function XDyeMergeGameModel:ResetAll()

end

function XDyeMergeGameModel:UpdateFUllActivityData(data)
    self._ActivityId = data.ActivityId
    self._StageRecord = data.StageRecord
end

function XDyeMergeGameModel:GetCurActivityId()
    return self._ActivityId
end

function XDyeMergeGameModel:CheckHasValidActivityId()
    return XTool.IsNumberValidEx(self._ActivityId)
end

function XDyeMergeGameModel:GetStageRecord()
    return self._StageRecord
end

function XDyeMergeGameModel:UpdateStageRecord(stageId)
    if self._StageRecord == nil then
        self._StageRecord = {}
    end

    if not table.contains(self._StageRecord, stageId) then
        table.insert(self._StageRecord, stageId)
    end
end

function XDyeMergeGameModel:CacheCurGamingStageId(stageId)
    self._CurGamingStageId = stageId
end

function XDyeMergeGameModel:GetCurGamingStageId()
    return self._CurGamingStageId
end

--region 本地缓存

function XDyeMergeGameModel:_GetChapterMarkKey(chapterId)
    return "NewChapter" .. tostring(chapterId)
end

function XDyeMergeGameModel:GetNewChapterIsMarked(chapterId)
    local key = self:_GetChapterMarkKey(chapterId)
    return self._SaveUtil:GetData(key) or false
end

function XDyeMergeGameModel:MarkNewChapter(chapterId)
    local key = self:_GetChapterMarkKey(chapterId)
    
    self._SaveUtil:SaveData(key, true)
end

--endregion

return XDyeMergeGameModel