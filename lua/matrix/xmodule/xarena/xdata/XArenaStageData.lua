local XArenaDataBase = require("XModule/XArena/XData/XArenaDataBase")

---@class XArenaStageData : XArenaDataBase
local XArenaStageData = XClass(XArenaDataBase, "XArenaStageData")

function XArenaStageData:_InitData(data)
    self._StageId = data.StageId
    self._Point = data.Point
end

function XArenaStageData:_ClearData()
    self._StageId = nil
    self._Point = nil
end

function XArenaStageData:GetStageId()
    return self._StageId
end

function XArenaStageData:GetPoint()
    return self._Point
end

return XArenaStageData
