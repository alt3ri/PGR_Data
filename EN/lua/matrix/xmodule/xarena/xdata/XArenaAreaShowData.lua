local XArenaDataBase = require("XModule/XArena/XData/XArenaDataBase")
local XArenaLordPlayerData = require("XModule/XArena/XData/XArenaLordPlayerData")
local XArenaStageData = require("XModule/XArena/XData/XArenaStageData")

---@class XArenaAreaShowData : XArenaDataBase
local XArenaAreaShowData = XClass(XArenaDataBase, "XArenaAreaShowData")

function XArenaAreaShowData:_InitData(data)
    local lordList = data.LordList
    local stageInfo = data.StageInfos and data.StageInfos[1] or nil

    self._AreaId = data.AreaId
    self._IsLock = data.Lock == 1
    self._Point = data.Point
    ---@type XArenaStageData
    self._StageInfo = XArenaStageData.New(stageInfo)
    ---@type XArenaLordPlayerData[]
    self._LordList = {}

    if not XTool.IsTableEmpty(lordList) then
        for i, lord in pairs(lordList) do
            self._LordList[i] = XArenaLordPlayerData.New(lord)
        end
    end
end

function XArenaAreaShowData:_ClearData()
    self._AreaId = nil
    self._IsLock = nil
    self._Point = nil

    self._LordList = {}
end

function XArenaAreaShowData:GetAreaId()
    return self._AreaId
end

function XArenaAreaShowData:GetIsLock()
    return self._IsLock
end

function XArenaAreaShowData:GetPoint()
    return self._Point
end

function XArenaAreaShowData:SetPoint(value)
    self._Point = value or 0
end

function XArenaAreaShowData:GetLordList()
    return self._LordList
end

---@return XArenaStageData
function XArenaAreaShowData:GetStageInfo()
    return self._StageInfo
end

function XArenaAreaShowData:GetLordPlayerDataByIndex(index)
    return self._LordList[index]
end

function XArenaAreaShowData:CheckHasStagePoint()
    local stageInfo = self:GetStageInfo()
    local point = stageInfo:GetPoint()

    return stageInfo ~= nil and not stageInfo:IsClear() and point ~= 0
end

return XArenaAreaShowData
