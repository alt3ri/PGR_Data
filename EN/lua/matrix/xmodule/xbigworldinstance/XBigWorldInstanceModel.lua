---@class XBigWorldInstanceModel : XModel
---@field _LevelPlayData table<number, XBigWorldLevelPlayData>
local XBigWorldInstanceModel = XClass(XModel, "XBigWorldInstanceModel")

local XBigWorldLevelPlayData

local TableKey = {
    BigWorldSettle = {
        CacheType = XConfigUtil.CacheType.Normal,
        DirPath = XConfigUtil.DirectoryType.Client,
    }
}
function XBigWorldInstanceModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Instance", TableKey)
    self._LevelPlayData = {}
end

function XBigWorldInstanceModel:ClearPrivate()
end

function XBigWorldInstanceModel:ResetAll()
    self._LevelPlayData = nil
end

---@return XTableBigWorldSettle
function XBigWorldInstanceModel:GetSettleTemplate(settleId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldSettle, settleId)
end

function XBigWorldInstanceModel:GetSettleUiName(settleId)
    local t = self:GetSettleTemplate(settleId)
    return t and t.UiName or nil
end

---@return XBigWorldLevelPlayData
function XBigWorldInstanceModel:GetLevelPlayData(levelPlayId)
    if not levelPlayId or not XTool.IsNumberValid(levelPlayId) then
        XLog.Error("XBigWorldInstanceModel:GetLevelPlayData error: levelPlayId is invalid")
        return nil
    end

    if not self._LevelPlayData[levelPlayId] then
        if not XBigWorldLevelPlayData then
            XBigWorldLevelPlayData = require("XModule/XBigWorldInstance/Data/XBigWorldLevelPlayData")
        end
        self._LevelPlayData[levelPlayId] = XBigWorldLevelPlayData.New(levelPlayId)
    end

    return self._LevelPlayData[levelPlayId]
end

function XBigWorldInstanceModel:CheckLevelPlayFullCleared(levelPlayId)
    if not levelPlayId or not XTool.IsNumberValid(levelPlayId) then
        XLog.Error("XBigWorldInstanceModel:CheckLevelPlayFullCleared error: levelPlayId is invalid")
        return false
    end
    -- 没有数据则认为未完成
    local levelPlay = self._LevelPlayData[levelPlayId]
    if not levelPlay then
        return false
    end

    return levelPlay:IsFullCleared()
end

function XBigWorldInstanceModel:CheckLevelPlayCleared(levelPlayId)
    if not levelPlayId or not XTool.IsNumberValid(levelPlayId) then
        XLog.Error("XBigWorldInstanceModel:CheckLevelPlayCleared error: levelPlayId is invalid")
        return false
    end
    return self._LevelPlayData[levelPlayId] ~= nil
end

function XBigWorldInstanceModel:InitLevelPlayData(dataList)
    if XTool.IsTableEmpty(dataList) then
        return
    end
    for levelPlayId, data in pairs(dataList) do
        local levelPlay = self:GetLevelPlayData(levelPlayId)
        levelPlay:UpdateData(data)
    end
end

function XBigWorldInstanceModel:UpdateLevelPlayData(notifyData)
    if XTool.IsTableEmpty(notifyData) then
        XLog.Error("XBigWorldInstanceModel:UpdateLevelPlayData error: notifyData is empty")
        return
    end
    local levelPlayId, data = notifyData.PlayId, notifyData.LevelPlayData
    if not levelPlayId or not XTool.IsNumberValid(levelPlayId) then
        XLog.Error("XBigWorldInstanceModel:UpdateLevelPlayData error: levelPlayId is invalid")
        return
    end

    local levelPlay = self:GetLevelPlayData(levelPlayId)
    if not levelPlay then
        return
    end
    levelPlay:UpdateData(data)
end

return XBigWorldInstanceModel