
---@class XBigWorldLevelPlayData 副本玩法数据
local XBigWorldLevelPlayData = XClass(nil, "XBigWorldLevelPlayData")

function XBigWorldLevelPlayData:Ctor(playId)
    if not playId or not XTool.IsNumberValid(playId) then
        XLog.Error("XBigWorldLevelPlayData:Ctor error: playId is invalid")
        return
    end
    self._PlayId = playId
    self._IsFullCleared = false
end

function XBigWorldLevelPlayData:UpdateData(data)
    if not data then
        return
    end
    
    self._IsFullCleared = data.IsFullCleared or false
end

function XBigWorldLevelPlayData:IsFullCleared()
    return self._IsFullCleared
end

return XBigWorldLevelPlayData