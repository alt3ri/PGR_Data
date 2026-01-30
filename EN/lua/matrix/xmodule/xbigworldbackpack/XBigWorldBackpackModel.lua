local XBigWorldBackpackConfigModel = require("XModule/XBigWorldBackpack/XBigWorldBackpackConfigModel")

---@class XBigWorldBackpackModel : XBigWorldBackpackConfigModel
local XBigWorldBackpackModel = XClass(XBigWorldBackpackConfigModel, "XBigWorldBackpackModel")

function XBigWorldBackpackModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._RecordItemIds = {}

    self:_InitTableKey()
    self:_InitRecordItemIds()
end

function XBigWorldBackpackModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
    self:_SaveRecordItemIds()
end

function XBigWorldBackpackModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

function XBigWorldBackpackModel:CheckItemIsRecord(itemId)
    return self._RecordItemIds[itemId] or false
end

function XBigWorldBackpackModel:AddRecordItemId(itemId)
    self._RecordItemIds[itemId] = true
end

function XBigWorldBackpackModel:_InitRecordItemIds()
    local record = XSaveTool.GetData(self:_GetRecordItemIdKey())

    self._RecordItemIds = {}
    if record then
        local records = string.Split(record, "|")

        if not XTool.IsTableEmpty(records) then
            for _, itemId in pairs(records) do
                self._RecordItemIds[tonumber(itemId)] = true
            end
        end
    end
end

function XBigWorldBackpackModel:_SaveRecordItemIds()
    local record = ""
    local isBegin = true

    if not XTool.IsTableEmpty(self._RecordItemIds) then
        for itemId, _ in pairs(self._RecordItemIds) do
            if isBegin then
                isBegin = false
                record = tostring(itemId)
            else
                record = record .. "|" .. tostring(itemId)
            end
        end
    end

    XSaveTool.SaveData(self:_GetRecordItemIdKey(), record)
end

function XBigWorldBackpackModel:_GetRecordItemIdKey()
    return string.format("BW_BACKPACK_ITEM_NEW_%d", XPlayer.Id)
end

return XBigWorldBackpackModel
