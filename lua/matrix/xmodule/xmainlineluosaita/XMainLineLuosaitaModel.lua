---@class XMainLineLuosaitaModel : XModel
local XMainLineLuosaitaModel = XClass(XModel, "XMainLineLuosaitaModel")

function XMainLineLuosaitaModel:OnInit()
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._Config = require("XModule/XMainLineLuosaita/XMainLineLuosaitaConfig").New(self._ConfigUtil)

    ---@type table<number, XMainLineLuosaitaSection> 阶段数据哈希表
    self._SectionInfoDic = {}
    ---@type table<number, boolean> 击杀敌人哈希表
    self._KillEnemyDic = {}

    self._CacheDataDic = {} -- 缓存数据
end

-- 退出玩法清理内部数据
function XMainLineLuosaitaModel:ClearPrivate()
    self._Config:ClearPrivate()
end

-- 重登清理数据
function XMainLineLuosaitaModel:ResetAll()
    self._Config:ResetAll()
    self._SectionInfoDic = {}
    self._KillEnemyDic = {}
    self._CacheDataDic = {}
end

--region Config

---@return XMainLineLuosaitaConfig
function XMainLineLuosaitaModel:GetConfig()
    return self._Config
end

--endregion

--region RpcData

-- 获取阶段数据
---@return XMainLineLuosaitaSection
function XMainLineLuosaitaModel:GetSectionInfo(sectionId)
    return self._SectionInfoDic[sectionId]
end

-- 获取阶段数据哈希表
---@return table<number, XMainLineLuosaitaSection> 
function XMainLineLuosaitaModel:GetSectionInfoDic()
    return self._SectionInfoDic
end

-- 获取位置数据
---@param posId number 位置Id
---@return XMainLineLuosaitaPositionInfo
function XMainLineLuosaitaModel:GetPositionInfo(posId)
    local blockId = self:GetConfig():GetPositionBlockId(posId)
    local sectionId = self:GetConfig():GetBlockSectionId(blockId)
    local sectionInfo = self:GetSectionInfo(sectionId)
    local posInfo = sectionInfo:GetPositionInfo(posId)
    return posInfo
end

-- 设置击败敌人
function XMainLineLuosaitaModel:SetKillEnemy(enemyId)
    self._KillEnemyDic[enemyId] = true
end

-- 是否击败敌人
function XMainLineLuosaitaModel:IsKillEnemy(enemyId)
    return self._KillEnemyDic[enemyId] == true
end

-- 刷新多个阶段数据
function XMainLineLuosaitaModel:RefreshActivityData(data)
    self._SectionInfoDic = {}
    for _, sectionData in ipairs(data.SectionInfos) do
        self:RefreshSectionInfo(sectionData)
    end
    self._KillEnemyDic = {}
    for _, enemyId in ipairs(data.KillEnemySet) do
        self._KillEnemyDic[enemyId] = true
    end
end

-- 刷新单个阶段数据
function XMainLineLuosaitaModel:RefreshSectionInfo(sectionData)
    local sectionId = sectionData.SectionId
    ---@type XMainLineLuosaitaSection
    local sectionInfo = self._SectionInfoDic[sectionId]
    if not sectionInfo then
        local XMainLineLuosaitaSection = require("XModule/XMainLineLuosaita/XEntity/XMainLineLuosaitaSection")
        sectionInfo = XMainLineLuosaitaSection.New(sectionId)
        self._SectionInfoDic[sectionId] = sectionInfo
    end
    sectionInfo:RefreshData(sectionData)
end

--endregion

--region 本地缓存
--- 缓存文件回顾蓝点
function XMainLineLuosaitaModel:SetDocumentReviewRed(isRed)
    self._SaveUtil:SaveData("DocumentReviewRed", isRed)
end

--- 获取文件回顾蓝点缓存
function XMainLineLuosaitaModel:GetDocumentReviewRed()
    return self._SaveUtil:GetData("DocumentReviewRed") or false
end
--endregion

--region 登陆缓存
-- 设置缓存
function XMainLineLuosaitaModel:SetCacheData(key, value)
    self._CacheDataDic[key] = value
end

-- 获取缓存
function XMainLineLuosaitaModel:GetCacheData(key)
    return self._CacheDataDic[key]
end
--endregion

return XMainLineLuosaitaModel