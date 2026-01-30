---@class XMainLineLuosaitaBlockInfo
local XMainLineLuosaitaBlockInfo = XClass(nil, "XMainLineLuosaitaBlockInfo")

function XMainLineLuosaitaBlockInfo:Ctor(id)
    ---@type number 块Id
    self._Id = id
    ---@type number 块状态
    self._BlockStatus = XMVCA.XMainLineLuosaita.EnumConst.BLOCK_STATUS.NONE
end

-- 刷新整个阶段数据
function XMainLineLuosaitaBlockInfo:RefreshData(data)
    self._BlockStatus = data.BlockStatus
end

-- 获取块Id
function XMainLineLuosaitaBlockInfo:GetId()
    return self._Id
end

-- 获取块状态
function XMainLineLuosaitaBlockInfo:GetBlockStatus()
    return self._BlockStatus
end

-- 是否被占领
function XMainLineLuosaitaBlockInfo:IsOccupied()
    return self._BlockStatus == XMVCA.XMainLineLuosaita.EnumConst.BLOCK_STATUS.OCCUPIED
end

return XMainLineLuosaitaBlockInfo
