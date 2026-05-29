---@class XTheatre6SubStageChain : XModel 关卡链表
---@field _MainModel XTheatre6Model
---@field Head XTheatre6StageNode 头节点
---@field Tail XTheatre6StageNode 尾节点
---@field Curr XTheatre6StageNode 当前节点
---@field IsWaitOpenNext boolean 是否等待打开下一关
local XTheatre6SubStageChain = XClass(XModel, "XTheatre6SubStageChain")

local RoomType = XEnumConst.Theatre6.RoomType

function XTheatre6SubStageChain:OnInit()
    
end

function XTheatre6SubStageChain:ClearPrivate()

end

function XTheatre6SubStageChain:ResetAll()

end

---关卡初始化
function XTheatre6SubStageChain:InitChain(modelId, stageId, floorIndex, roomIndex)
    self:Clear()
    self.ModelId = modelId
    
    local stageConfig = self._MainModel:GetStageConfig(stageId)
    for i, floorId in ipairs(stageConfig.FloorIds) do
        if floorIndex > i then
            goto continue1
        end

        local floorConfig = self._MainModel:GetStageFloorConfig(floorId)
        self:CheckAddFloorAvgRoom(i, floorId, floorConfig.StartAVG)
        self:CheckAddAnnoRoom(i, floorId, floorConfig.AnnoId)
        
        for j, roomId in ipairs(floorConfig.RoomIds) do
            if floorIndex == i and roomIndex > j then
                goto continue2
            end
            
            local roomConfig = self._MainModel:GetStageRoomConfig(roomId)
            local roomType = roomConfig.Type
            self:Append(floorId, roomType, roomConfig.Values)

            ::continue2::
        end
        
        ::continue1::
    end
end

---手动添加每层开始的AVG房（客户端特殊处理，服务端没有这个房间）
function XTheatre6SubStageChain:CheckAddFloorAvgRoom(floorIdx, floorId, startAVG)
    if not XTool.IsNumberValid(startAVG) then
        return
    end
    if not self._MainModel:IsAvgNeedOpen(floorIdx - 1) then
        return
    end
    self:Append(floorId, RoomType.NewFloorAvg)
end

---手动添加每层开始的报幕房（客户端特殊处理，服务端没有这个房间）
function XTheatre6SubStageChain:CheckAddAnnoRoom(floorIdx, floorId, annoId)
    if not XTool.IsNumberValid(annoId) then
        return
    end
    if not self._MainModel:IsAnnoNeedOpen(floorIdx - 1) then
        return
    end
    self:Append(floorId, RoomType.ChapterPreview)
end

---新增房间
---@return XTheatre6StageNode
function XTheatre6SubStageChain:Append(floorId, roomType, roomValues)
    ---@type XTheatre6StageNode
    local node = {}
    node.FloorId = floorId
    node.RoomType = roomType
    node.RoomValues = roomValues

    if not self.Head then
        self.Head = node
        self.Tail = node
    else
        self.Tail.Next = node
        node.Prev = self.Tail
        self.Tail = node
    end

    if not self.Curr then
        self.Curr = self.Head
    end

    return node
end

---在同一层中插入房间
---@param room XTheatre6StageNode
---@return XTheatre6StageNode
function XTheatre6SubStageChain:Insert(roomType, roomValues, room)
    room = room or self.Curr

    if not room then
        XLog.Error("插入失败：房间不存在")
        return
    end

    local nextNode = room.Next
    ---@type XTheatre6StageNode
    local node = {}
    node.FloorId = room:GetFloorId()
    node.RoomType = roomType
    node.RoomValues = roomValues
    node.Prev = room
    node.Next = nextNode

    if nextNode then
        nextNode.Prev = node
    else
        self.Tail = node
    end
    
    return node
end

---进入下一个房间
---@return XTheatre6StageNode
function XTheatre6SubStageChain:MoveNext()
    if not self.Curr then
        return nil
    end

    self.Curr = self.Curr.Next
    return self.Curr
end

---清除全部数据
function XTheatre6SubStageChain:Clear()
    self.Head = nil
    self.Tail = nil
    self.Curr = nil
end

return XTheatre6SubStageChain

---@class XTheatre6StageNode 关卡链表节点
---@field Prev XTheatre6StageNode 上一个节点
---@field Next XTheatre6StageNode 下一个节点
---@field FloorId number
---@field RoomType number
---@field RoomValues number