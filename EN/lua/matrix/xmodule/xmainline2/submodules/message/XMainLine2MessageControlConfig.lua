---@type XMainLine2MessageControl
local XMainLine2MessageControl = XClassPartial("XMainLine2MessageControl")

local TableKey = {
    MainLine2MessageGroups = { ReadFunc = XConfigUtil.ReadType.Int, DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id" },
    MainLine2MessagePosition = { ReadFunc = XConfigUtil.ReadType.Int, DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Id" },
    MainLine2MessageContents = { ReadFunc = XConfigUtil.ReadType.Int, DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id" },
}

function XMainLine2MessageControl:_InitConfigs()
    self:InitConfigByTabKey("Fuben/MainLine2", TableKey)
end

---@return XTableMainLine2MessageGroups
function XMainLine2MessageControl:GetTableMainLine2MessageGroupsCfgById(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.MainLine2MessageGroups, id, notips)
end

---@return XTableMainLine2MessagePosition
function XMainLine2MessageControl:GetTableMainLine2MessagePositionCfgById(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.MainLine2MessagePosition, id, notips)
end

---@return XTableMainLine2MessageContents
function XMainLine2MessageControl:GetTableMainLine2MessageContentsCfgById(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.MainLine2MessageContents, id, notips)
end

--- 获取指定章节对应的message配置Id
--- 关联MainLine2MessagePosition表
---@return number[]
function XMainLine2MessageControl:GetCfgMessagePositionIdsById(chapterId)
    local cfg = self:GetTableMainLine2MessageGroupsCfgById(chapterId)

    if cfg then
        return cfg.MessageIds
    end
end

--- 获取指定Message的UI位置索引
function XMainLine2MessageControl:GetCfgMessagePosIndexById(messagePosId)
    local cfg = self:GetTableMainLine2MessagePositionCfgById(messagePosId)

    if cfg then
        return cfg.UiPosIndex
    end

    return 0
end

function XMainLine2MessageControl:GetCfgMessageIconById(messagePosId)
    local cfg = self:GetTableMainLine2MessagePositionCfgById(messagePosId)

    if not cfg then
        return ''
    end

    local type = cfg.Type

    -- message的图标跟类型关联
    return self._Model:GetClientConfigParams('MessageTypeIcon', type) or ''
end

function XMainLine2MessageControl:GetCfgMessageBeginContentIdById(messagePosId)
    local cfg = self:GetTableMainLine2MessagePositionCfgById(messagePosId)

    if not cfg then
        return 0
    end
    
    return cfg.BeginContentId
end

return XMainLine2MessageControl