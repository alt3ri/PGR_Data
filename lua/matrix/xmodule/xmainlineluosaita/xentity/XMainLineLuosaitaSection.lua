local tableInsert = table.insert
local tableSort = table.sort

---@class XMainLineLuosaitaSection
local XMainLineLuosaitaSection = XClass(nil, "XMainLineLuosaitaSection")

function XMainLineLuosaitaSection:Ctor(sectionId)
    ---@type number 阶段Id
    self._SectionId = sectionId
    ---@type table<number, XMainLineLuosaitaBlockInfo> 块数据哈希表
    self._BlockInfoDic = {}
    ---@type table<number, XMainLineLuosaitaPositionInfo> 位置数据哈希表
    self._PositionInfoDic = {}
    ---@type table<number, XMainLineLuosaitaDoc>  已解锁文件哈希表
    self._UnlockDocInfoDic = {}
    ---@type table<number, boolean> 已完成的移动哈希表
    self._CompletedMoveDic = {}
    ---@type boolean
    self._Status = false
end

-- 获取块数据哈希表
---@return table<number, XMainLineLuosaitaBlockInfo>
function XMainLineLuosaitaSection:GetBlockInfoDic()
    return self._BlockInfoDic
end

-- 获取块数据
---@return XMainLineLuosaitaBlockInfo
function XMainLineLuosaitaSection:GetBlockInfo(blockId)
    local blockInfo = self._BlockInfoDic[blockId]
    if not blockInfo then
        XLog.Error(string.format("未在SectionId:%s 内找到位置blockId:%s ，请检查配置！", self._SectionId, blockId))
    end
    return blockInfo
end

-- 获取位置数据哈希表
---@return table<number, XMainLineLuosaitaPositionInfo>
function XMainLineLuosaitaSection:GetPositionInfoDic()
    return self._PositionInfoDic
end

-- 获取位置数据哈希表
---@return XMainLineLuosaitaPositionInfo[]
function XMainLineLuosaitaSection:GetPositionInfos()
    ---@type XMainLineLuosaitaPositionInfo[]
    local result = {}
    for _, info in pairs(self._PositionInfoDic) do
        tableInsert(result, info)
    end
    tableSort(result, function(a, b)
        return a:GetPosId() < b:GetPosId()
    end)
    return result
end

-- 获取位置数据哈希表
---@return XMainLineLuosaitaPositionInfo[]
function XMainLineLuosaitaSection:GetPositionInfosByType(type)
    local result = {}
    for _, positionInfo in pairs(self._PositionInfoDic) do
        if positionInfo:GetType() == type then
            tableInsert(result, positionInfo)
        end
    end
    return result
end

-- 获取位置数据
---@return XMainLineLuosaitaPositionInfo
function XMainLineLuosaitaSection:GetPositionInfo(posId)
    return self._PositionInfoDic[posId]
end

-- 获取所有的角色Id
---@return table<number, boolean>
function XMainLineLuosaitaSection:GetCharacterIdDic()
    local result = {}
    for _, posInfo in pairs(self._PositionInfoDic) do
        if posInfo:IsCharacter() then
            local characterId = posInfo:GetCharacterId()
            result[characterId] = true
        end
    end
    return result
end

-- 获取角色的位置Id
function XMainLineLuosaitaSection:GetCharacterPosId(characterId)
    for _, posInfo in pairs(self._PositionInfoDic) do
        if posInfo:IsCharacter() and posInfo:GetCharacterId() == characterId then
            return posInfo:GetPosId()
        end
    end
    return 0
end

-- 角色移动是否已经完成
function XMainLineLuosaitaSection:IsMoveComplete(moveId)
    return self._CompletedMoveDic[moveId] == true
end

-- 文件是否解锁
function XMainLineLuosaitaSection:IsDocUnlock(docId)
    return self._UnlockDocInfoDic[docId] ~= nil
end

-- 文件是否使用
function XMainLineLuosaitaSection:IsDocUse(docId)
    local docInfo = self._UnlockDocInfoDic[docId]
    if docInfo then
        return docInfo.Used
    end
    return false
end

-- 获取未解锁的文件Id
function XMainLineLuosaitaSection:GetUnUseDocId()
    ---@type XMainLineLuosaitaDoc[]
    local result = {}
    for _, docInfo in pairs(self._UnlockDocInfoDic) do
        if not docInfo.Used then
            tableInsert(result, docInfo.Id)
        end
    end
    if #result > 1 then
        tableSort(result, function(a, b)
            return a < b
        end)
    end
    return result[1]
end

-- 是否所有的文件都已使用
function XMainLineLuosaitaSection:IsAllDocUse()
    for _, doc in pairs(self._UnlockDocInfoDic) do
        if not doc.Used then
            return false
        end
    end
    return true
end

-- 获取解锁的文件Id列表
function XMainLineLuosaitaSection:GetUnlockDocIds()
    local result = {}
    for id, _ in ipairs(self._UnlockDocInfoDic) do
        tableInsert(result, id)
    end
    tableSort(result)
    return result
end

-- 是否完成
function XMainLineLuosaitaSection:IsFinish()
    return self._Status == XMVCA.XMainLineLuosaita.EnumConst.SECTION_STATUS.FINISH
end

--region 刷新数据
-- 刷新整个阶段数据
function XMainLineLuosaitaSection:RefreshData(data)
    self:RefreshBlockInfos(data.BlockInfos)
    self:RefreshPosInfos(data.SectionMembers)
    self:RefreshDocInfos(data.DocList)
    self:RefreshCompleteMoveIds(data.CharacterMoveIds)
    self._Status = data.SectionStatus
end

-- 刷新块数据
function XMainLineLuosaitaSection:RefreshBlockInfos(blockDatas)
    local XMainLineLuosaitaBlockInfo = require("XModule/XMainLineLuosaita/XEntity/XMainLineLuosaitaBlockInfo")
    self._BlockInfoDic = {}
    for _, blockData in pairs(blockDatas) do
        local blockId = blockData.Id
        ---@type XMainLineLuosaitaBlockInfo
        local blockInfo = XMainLineLuosaitaBlockInfo.New(blockId)
        blockInfo:RefreshData(blockData)
        self._BlockInfoDic[blockId] = blockInfo
    end
end

-- 刷新位置数据列表
function XMainLineLuosaitaSection:RefreshPosInfos(posDatas)
    local XMainLineLuosaitaPositionInfo = require("XModule/XMainLineLuosaita/XEntity/XMainLineLuosaitaPositionInfo")
    self._PositionInfoDic = {}
    for _, posData in pairs(posDatas) do
        local posId = posData.PosId
        ---@type XMainLineLuosaitaPositionInfo
        local posInfo = XMainLineLuosaitaPositionInfo.New(posId)
        posInfo:RefreshData(posData)
        self._PositionInfoDic[posId] = posInfo
    end
end

-- 刷新文件数据列表
---@param docDatas XMainLineLuosaitaDoc[]
function XMainLineLuosaitaSection:RefreshDocInfos(docDatas)
    self._UnlockDocInfoDic = {}
    for _, docData in pairs(docDatas) do
        self._UnlockDocInfoDic[docData.Id] = docData
    end
end

-- 刷新已完成的移动Id
---@param moveIds number[] 
function XMainLineLuosaitaSection:RefreshCompleteMoveIds(moveIds)
    self._CompletedMoveDic = {}
    for _, moveId in pairs(moveIds) do
        self._CompletedMoveDic[moveId] = true
    end
end
--endregion

return XMainLineLuosaitaSection
