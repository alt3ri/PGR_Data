local XLifeTreeConfigModel = require("XModule/XLifeTree/XLifeTreeConfigModel")
local tableInsert = table.insert

---@class XLifeTreeModel : XLifeTreeConfigModel
local XLifeTreeModel = XClass(XLifeTreeConfigModel, "XLifeTreeModel")
function XLifeTreeModel:OnInit()
    self:_InitTableKey()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
end

function XLifeTreeModel:ClearPrivate()
    --这里执行内部数据清理
    --XLog.Error("请对内部数据进行清理")
end

function XLifeTreeModel:ResetAll()
    --这里执行重登数据清理
    --XLog.Error("重登数据清理")
    self.LifeTreeData = nil
    self.FinishChapterIdDic = nil
    self.CacheCharacterConditionIndex = nil
end


--region rpc

---@param data CS.XLifeTreeDataDb
function XLifeTreeModel:RefreshLifeTreeData(data)
    self.LifeTreeData = data
    self.FinishChapterIdDic = nil
end

-- 完成操作相关刷新数据
function XLifeTreeModel:RefreshProcessData(data)
    self.LifeTreeData = self.LifeTreeData or {}
    self.LifeTreeData.IsFinishGuide = data.IsFinishGuide or {}
    self.LifeTreeData.IsFinishLifeTreePv = data.IsFinishLifeTreePv or {}
    self.LifeTreeData.FinishedChapters = data.FinishedChapters or {}
    self.FinishChapterIdDic = nil
end

function XLifeTreeModel:RefreshUnlockCharacterData(characterData)
    if not self.LifeTreeData then
        self.LifeTreeData = {}
        self.LifeTreeData.UnlockCharacterData = {}
    end
    self.LifeTreeData.UnlockCharacterData[characterData.Id] = characterData
end

---@return boolean 是否完成引导
function XLifeTreeModel:IsFinishGuide()
    return self.LifeTreeData and self.LifeTreeData.IsFinishGuide == true
end

---@return boolean 是否完成Pv
function XLifeTreeModel:IsFinishPv()
    return self.LifeTreeData and self.LifeTreeData.IsFinishLifeTreePv == true
end

--- 角色是否解锁
---@param characterId number
function XLifeTreeModel:IsCharacterUnlock(characterId, unlockCount)
    local curUnlockCount = self:GetCharacterUnlockCount(characterId)
    return curUnlockCount >= unlockCount
end

--- 获取角色解锁次数
---@param catalogId number
---@return number count
function XLifeTreeModel:GetCharacterUnlockCountByCatalogId(catalogId)
    -- 未上线(未配置CharacterId)
    local config = self:GetLifeTreeCharacterCatalogConfigById(catalogId)
    if not XTool.IsNumberValidEx(config.CharacterId) then return 0 end

    return self:GetCharacterUnlockCount(config.CharacterId)
end

--- 获取角色解锁次数
---@param characterId number
---@return number status
function XLifeTreeModel:GetCharacterUnlockCount(characterId)
    -- 没有服务端数据
    if not self.LifeTreeData or not self.LifeTreeData.UnlockCharacterData then return 0 end

    local charData = self.LifeTreeData.UnlockCharacterData[characterId]
    return charData and charData.UnlockStatus or 0
end

-- 章节是否完成弹窗
function XLifeTreeModel:IsChapterFinish(chapterId)
    -- 没有服务端数据
    if not self.LifeTreeData or not self.LifeTreeData.FinishedChapters then return false end

    -- 第一次判断时才初始化哈希表
    if not self.FinishChapterIdDic then
        ---@type table<number, boolean>
        self.FinishChapterIdDic = {}
        if self.LifeTreeData.FinishedChapters then
            for _, tempChapterId in pairs(self.LifeTreeData.FinishedChapters) do
                self.FinishChapterIdDic[tempChapterId] = true
            end
        end
    end

    return self.FinishChapterIdDic[chapterId] == true
end

-- 获取缓存角色条件下标
function XLifeTreeModel:GetCacheCharacterConditionIndex(id)
    if self.CacheCharacterConditionIndex then
        return self.CacheCharacterConditionIndex[id]
    end
end

-- 获取缓存角色条件下标
function XLifeTreeModel:SetCacheCharacterConditionIndex(id, index)
    self.CacheCharacterConditionIndex = self.CacheCharacterConditionIndex or {}
    self.CacheCharacterConditionIndex[id] = index
end

--endregion

--region config

---获取星座神卡CatalogId
---@param constellationId number 星座Id
---@return number CatalogId
function XLifeTreeModel:GetConstellationDivineCharacterCatalogId(constellationId)
    local constellationConfig = self:GetLifeTreeConstellationConfigById(constellationId)
    for _, catalogId in ipairs(constellationConfig.CharacterCatalogIds) do
        local catalogConfig = self:GetLifeTreeCharacterCatalogConfigById(catalogId)
        if catalogConfig.CardType == XMVCA.XLifeTree.EnumConst.CARD_TYPE.DIVINE then
            return catalogId
        end
    end
end

-- 获取任务Id列表
---@param constellationId number
function XLifeTreeModel:GetTaskIds(constellationId)
    if XTool.IsNumberValidEx(constellationId) then
        local config = self:GetLifeTreeConstellationConfigById(constellationId)
        return config.TaskIds
    else
        local result = {}
        local configs = self:GetLifeTreeConstellationConfigs()
        for _, config in pairs(configs) do
            for _, taskId in pairs(config.TaskIds) do
                tableInsert(result, taskId)
            end
        end
        return result
    end
end

--endregion config


return XLifeTreeModel