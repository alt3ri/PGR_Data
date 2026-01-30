local XArenaDataBase = require("XModule/XArena/XData/XArenaDataBase")
local XArenaAreaShowData = require("XModule/XArena/XData/XArenaAreaShowData")

---@class XArenaAreaData : XArenaDataBase
local XArenaAreaData = XClass(XArenaDataBase, "XArenaAreaData")

function XArenaAreaData:_InitData(data)
    local arenaList = data.AreaList

    self._TotalPoint = data.TotalPoint
    self._GroupFightEvents = data.GroupFightEvents
    ---@type XArenaAreaShowData[]
    self._AreaShowList = {}
    ---@type table<number, XArenaAreaShowData>
    self._AreaShowMap = {}
    self._GroupFightEventsMap = {}

    if not XTool.IsTableEmpty(arenaList) then
        for i, arena in pairs(arenaList) do
            ---@type XArenaAreaShowData
            local showData = XArenaAreaShowData.New(arena)
            
            self._AreaShowList[i] = showData
            self._AreaShowMap[showData:GetAreaId()] = showData
            self._GroupFightEventsMap[showData:GetAreaId()] = self._GroupFightEvents[i]
        end
    end
end

function XArenaAreaData:_ClearData()
    self._TotalPoint = nil
    self._GroupFightEvent = nil
    self._AreaShowList = nil
    self._AreaShowMap = {}
end

function XArenaAreaData:GetTotalPoint()
    return self._TotalPoint
end

function XArenaAreaData:GetGroupFightEvents()
    return self._GroupFightEvents
end

function XArenaAreaData:GetGroupFightEventIdByAreaId(areaId)
    return self._GroupFightEventsMap[areaId]
end

---@return XArenaAreaShowData[]
function XArenaAreaData:GetArenaShowList()
    return self._AreaShowList
end

---@return XArenaAreaShowData
function XArenaAreaData:GetAreaShowDataByIndex(index)
    return self._AreaShowList[index]
end

function XArenaAreaData:GetAreaShowDataAmount()
    return self._AreaShowList and #self._AreaShowList or 0
end

---@return XArenaAreaShowData
function XArenaAreaData:GetAreaShowDataByAreaId(areaId)
    return self._AreaShowMap[areaId]
end

function XArenaAreaData:SetAreaShowDataPointByAreaId(areaId, point)
    local arenaShowData = self:GetAreaShowDataByAreaId(areaId)

    if arenaShowData and not arenaShowData:IsClear() then
        arenaShowData:SetPoint(point)
    end
end

return XArenaAreaData
