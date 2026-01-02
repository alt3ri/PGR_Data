---@class XBigWorldNewsModel : XModel
local XBigWorldNewsModel = XClass(XModel, "XBigWorldNewsModel")

local TableKey = {
    BigWorldNews = { 
        CacheType = XConfigUtil.CacheType.Normal
    }
}

function XBigWorldNewsModel:OnInit()
    self._PopupNews = {}
    self._NewsTag = {}
    self._QuestNewsTag = {}
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/News", TableKey)
end

function XBigWorldNewsModel:ClearPrivate()
end

function XBigWorldNewsModel:ResetAll()
    self:ClearData()
end

function XBigWorldNewsModel:ClearData()
    self._NewsIds = nil
end

---@return XTableBigWorldNews
function XBigWorldNewsModel:GetNewsTemplate(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldNews, id)
end

function XBigWorldNewsModel:GetNewsIds()
    if self._NewsIds then
        return self._NewsIds
    end
    local ids = {}
    ---@type table<number, XTableBigWorldNews>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.BigWorldNews)
    for id, _ in pairs(templates) do
        ids[#ids + 1] = id
    end
    self._NewsIds = ids

    return ids
end

function XBigWorldNewsModel:CheckNewsPopup(newsId)
    return self._PopupNews[newsId] ~= nil
end

function XBigWorldNewsModel:SetNewsPopup(newsId)
    self._PopupNews[newsId] = true
end

function XBigWorldNewsModel:InitPopupNews(data)
    if not data then
        return
    end
    for _, id in pairs(data) do
        self._PopupNews[id] = true
    end
end

function XBigWorldNewsModel:GetLocalData(key)
    return self._SaveUtil:GetData(key)
end

function XBigWorldNewsModel:SaveLocalData(key, value)
    self._SaveUtil:SaveData(key, value)
end

function XBigWorldNewsModel:CheckNewsTagNew(newsId)
    local value = self._NewsTag[newsId]
    if value == nil then
        value = self:GetLocalData("NEWS_TAG_NEW_" .. newsId)
        self._NewsTag[newsId] = value
    end
    if not value then
        self._NewsTag[newsId] = false
        return true
    end
    return false
end

function XBigWorldNewsModel:MarkNewsTagNew(newsId)
    self._NewsTag[newsId] = true
end

function XBigWorldNewsModel:CheckQuestNewsPreConditionTag(newsId, lockIndex)
    local value = self._QuestNewsTag[newsId]
    if value == nil then
        value = self:GetLocalData(string.format("QUEST_NEWS_PRE_CONDITION_INDEX_%s", newsId))
        self._QuestNewsTag[newsId] = value
    end
    if not value then
        self._QuestNewsTag[newsId] = false
        return true
    end
    return value ~= lockIndex
end

function XBigWorldNewsModel:MarkQuestNewsPreConditionTag(newsId, lockIndex)
    self._QuestNewsTag[newsId] = lockIndex
end

function XBigWorldNewsModel:SaveAllLocalData()
    if not XTool.IsTableEmpty(self._NewsTag) then
        for newsId, _ in pairs(self._NewsTag) do
            self:SaveLocalData("NEWS_TAG_NEW_" .. newsId, true)
            self._NewsTag[newsId] = nil
        end
    end
    if not XTool.IsTableEmpty(self._QuestNewsTag) then
        for newsId, index in pairs(self._QuestNewsTag) do
            self:SaveLocalData(string.format("QUEST_NEWS_PRE_CONDITION_INDEX_%s", newsId), index)
            self._QuestNewsTag[newsId] = nil
        end
    end
    
end

return XBigWorldNewsModel