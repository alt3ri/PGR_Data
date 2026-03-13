---@class XLuckyTenant2ConfigModel : XModel
local XLuckyTenant2ConfigModel = XClass(XModel, "XLuckyTenant2ConfigModel")

-- 新增的羁绊相关表
local LuckyTenant2BondTableKey = {
    LuckyTenant2Bond = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenant2BondSkill = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenant2BondQuality = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenant2ChessCondition = { DirPath = XConfigUtil.DirectoryType.Share, },
}

local LuckyTenant2TestTableKey = {
    LuckyTenant2TestCase = { DirPath = XConfigUtil.DirectoryType.Client, },
}

-- 随机池相关表
local LuckyTenant2RandomTableKey = {
    LuckyTenant2ChessRound = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenant2ChessRandomGroup = { DirPath = XConfigUtil.DirectoryType.Share, },
}

-- 修改的现有表
local LuckyTenant2TableKey = {
    LuckyTenant2Chess = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenant2ChessSkill = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenant2ChessType = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenant2Stage = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    LuckyTenant2StageTask = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenant2Activity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    LuckyTenant2Chapter = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenant2Quality = { DirPath = XConfigUtil.DirectoryType.Client, },
}

function XLuckyTenant2ConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/LuckyTenant2", LuckyTenant2BondTableKey)
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/LuckyTenant2", LuckyTenant2TableKey)
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/LuckyTenant2/LuckyTenant2Random", LuckyTenant2RandomTableKey)
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/LuckyTenant2/Test", LuckyTenant2TestTableKey)
end

function XLuckyTenant2ConfigModel:GetTestCase(id)
    self._ConfigUtil:Clear("Client/MiniActivity/LuckyTenant2/Test/LuckyTenant2TestCase.tab")
    local configs = self._ConfigUtil:GetByTableKey(LuckyTenant2TestTableKey.LuckyTenant2TestCase)
    local find = 0
    for i = 1, #configs do
        local config = configs[i]
        if config.SkillId == id then
            find = i
            break
        end
    end
    if find == 0 then
        return false
    end
    
    local result = {}
    local maxRows = 4  -- 5x5棋盘最多5行
    local currentRow = 0
    
    -- 从找到的行开始，顺序读取同一SkillId的行（最多5行）
    for i = find, #configs do
        if currentRow >= maxRows then
            break
        end
        local config = configs[i]
        -- 检查SkillId是否匹配，不匹配则停止
        if config.SkillId ~= id then
            break
        end
        -- 读取这一行的5个位置
        local pos = config.Pos
        for j = 1, 5 do
            local pieceId = pos[j] or 0
            table.insert(result, pieceId)
        end
        currentRow = currentRow + 1
    end
    
    -- 如果不足5行，用0填充至25个位置
    while #result < 25 do
        table.insert(result, 0)
    end
    
    return result
end

-- ==================== 羁绊表相关 ====================

---@return XTableLuckyTenant2Bond[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2BondConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenant2BondTableKey.LuckyTenant2Bond)
end

---@return XTableLuckyTenant2Bond
function XLuckyTenant2ConfigModel:GetLuckyTenant2BondConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2BondTableKey.LuckyTenant2Bond, id, false)
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2BondNameById(id)
    local config = self:GetLuckyTenant2BondConfigById(id)
    return config and config.BondName or ""
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2BondIconById(id)
    local config = self:GetLuckyTenant2BondConfigById(id)
    return config and config.Icon or ""
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2BondRelatedChessById(id)
    local config = self:GetLuckyTenant2BondConfigById(id)
    return config and config.RelatedChess or ""
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2BondRelatedChessForScoreById(id)
    local config = self:GetLuckyTenant2BondConfigById(id)
    return config and config.RelatedChessForScore or ""
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2BondUpgradeRequireById(id)
    local config = self:GetLuckyTenant2BondConfigById(id)
    return config and config.UpgradeRequire or 0
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2BondUpgradeRequireDescById(id)
    local config = self:GetLuckyTenant2BondConfigById(id)
    return config and config.UpgradeRequireDesc or ""
end

-- ==================== 羁绊技能管理表相关 ====================

---@return XTableLuckyTenant2BondSkill[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2BondSkillConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenant2BondTableKey.LuckyTenant2BondSkill)
end

---@return XTableLuckyTenant2BondSkill
function XLuckyTenant2ConfigModel:GetLuckyTenant2BondSkillConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2BondTableKey.LuckyTenant2BondSkill, id, false)
end

---@param bondId number
---@return XTableLuckyTenant2BondSkill[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2BondSkillConfigsByBondId(bondId)
    local allConfigs = self:GetLuckyTenant2BondSkillConfigs()
    local result = {}
    for _, config in pairs(allConfigs) do
        if config.BondId == bondId then
            table.insert(result, config)
        end
    end
    return result
end

---获取某个羁绊在某个等级下应该添加的所有技能配置
---@param bondId number 羁绊ID
---@param maxLevel number 最大羁绊等级
---@return XTableLuckyTenant2BondSkill[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, maxLevel)
    local allConfigs = self:GetLuckyTenant2BondSkillConfigs()
    local result = {}
    for _, config in pairs(allConfigs) do
        if config.BondId == bondId and config.Level and config.Level <= maxLevel then
            -- 检查生效结束等级（EffectiveLevelEnd）
            -- 如果 EffectiveLevelEnd > 0 且 maxLevel > EffectiveLevelEnd，则跳过
            local effectiveLevelEnd = config.EffectiveLevelEnd or 0
            if effectiveLevelEnd > 0 and maxLevel > effectiveLevelEnd then
                goto continue
            end
            table.insert(result, config)
        end
        ::continue::
    end
    -- 按Level和Id排序，确保添加顺序一致（从高等级到低等级）
    table.sort(result, function(a, b)
        if a.Level ~= b.Level then
            return a.Level > b.Level  -- 按等级降序排序（从高到低）
        end
        return a.Id < b.Id
    end)
    return result
end

---获取某个羁绊的所有SkillRequire值（用于计算等级）
---@param bondId number 羁绊ID
---@return number[] SkillRequire列表（按Level升序排序）
function XLuckyTenant2ConfigModel:GetLuckyTenant2BondSkillRequiresByBondId(bondId)
    local allConfigs = self:GetLuckyTenant2BondSkillConfigs()
    local skillRequireMap = {}  -- {level: skillRequire}
    
    for _, config in pairs(allConfigs) do
        if config.BondId == bondId and config.SkillRequire and config.SkillRequire > 0 then
            local level = config.Level or 0
            if level > 0 then
                -- 如果同一等级有多个配置，使用第一个SkillRequire值
                if not skillRequireMap[level] then
                    skillRequireMap[level] = config.SkillRequire
                end
            end
        end
    end
    
    -- 转换为列表并按Level排序
    local result = {}
    for level, skillRequire in pairs(skillRequireMap) do
        table.insert(result, {level = level, skillRequire = skillRequire})
    end
    table.sort(result, function(a, b)
        return a.level < b.level
    end)
    
    -- 只返回SkillRequire值列表
    local skillRequireList = {}
    for _, item in ipairs(result) do
        table.insert(skillRequireList, item.skillRequire)
    end
    
    return skillRequireList
end

-- ==================== 羁绊品质表相关 ====================

---@return XTableLuckyTenant2BondQuality[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2BondQualityConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenant2BondTableKey.LuckyTenant2BondQuality)
end

---@return XTableLuckyTenant2BondQuality
function XLuckyTenant2ConfigModel:GetLuckyTenant2BondQualityConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2BondTableKey.LuckyTenant2BondQuality, id, false)
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2BondQualityBgById(id)
    local config = self:GetLuckyTenant2BondQualityConfigById(id)
    return config and config.BgPath or ""
end

-- ==================== Condition表相关 ====================

---@return XTableLuckyTenant2ChessCondition[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessConditionConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenant2BondTableKey.LuckyTenant2ChessCondition)
end

---@return XTableLuckyTenant2ChessCondition
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessConditionConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2BondTableKey.LuckyTenant2ChessCondition, id, false)
end

-- ==================== 随机池Round表相关 ====================

---@return XTable.XTableLuckyTenant2ChessRound[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessRoundConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenant2RandomTableKey.LuckyTenant2ChessRound)
end

---@return XTable.XTableLuckyTenant2ChessRound
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessRoundConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2RandomTableKey.LuckyTenant2ChessRound, id, true)
end

-- ==================== 随机池RandomGroup表相关 ====================

---@return XTable.XTableLuckyTenant2ChessRandomGroup[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessRandomGroupConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenant2RandomTableKey.LuckyTenant2ChessRandomGroup)
end

---@return XTable.XTableLuckyTenant2ChessRandomGroup
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessRandomGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2RandomTableKey.LuckyTenant2ChessRandomGroup, id, true)
end

-- ==================== 棋子表相关（新增字段） ====================

---@return XTableLuckyTenant2Chess[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenant2TableKey.LuckyTenant2Chess)
end

---@return XTableLuckyTenant2Chess
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessConfigById(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2TableKey.LuckyTenant2Chess, id, true)
    if not config then
        -- 拦截错误，改为警告
        XLog.Warning(string.format("ModuleId:XLuckyTenant2警告:找不到唯一Id数据。搜索路径: Share/MiniActivity/LuckyTenant2/LuckyTenant2Chess.tab 索引唯一Id = %s", tostring(id)))
    end
    return config
end

---检查无 bondId 的棋子（id 1=金币 2=子虫 3=4级武器碎片 4=6级武器碎片）是否已正确配置 StateSkillId
---@return number[] 未正确配置 StateSkillId 的棋子 id 列表
---@return string[] 对应说明信息，便于在配置表 LuckyTenant2Chess.tab 中修正
function XLuckyTenant2ConfigModel:ValidateNoBondIdPieceStateSkillIds()
    local noBondIdPieceIds = { 1, 2, 3, 4 }
    local invalidIds = {}
    local messages = {}
    for _, pieceId in ipairs(noBondIdPieceIds) do
        local config = self:GetLuckyTenant2ChessConfigById(pieceId)
        if not config then
            invalidIds[#invalidIds + 1] = pieceId
            messages[#messages + 1] = string.format("棋子 ID=%d 配置不存在", pieceId)
        else
            local bondIdStr = config.BondId and tostring(config.BondId):gsub("^%s*(.-)%s*$", "%1") or ""
            if bondIdStr == "" or bondIdStr == "0" then
                local raw = config.StateSkillId
                local ids = (type(raw) == "number" and raw > 0) and { raw } or (raw or {})
                local hasValid = false
                for i = 1, #ids do
                    if ids[i] and ids[i] > 0 then hasValid = true break end
                end
                if not hasValid then
                    invalidIds[#invalidIds + 1] = pieceId
                    messages[#messages + 1] = string.format("棋子 ID=%d（无 bondId）未配置 StateSkillId，请在 LuckyTenant2Chess.tab 中为该行填写 StateSkillId", pieceId)
                end
            end
        end
    end
    return invalidIds, messages
end

-- 新增字段：羁绊id
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessBondIdById(id)
    local config = self:GetLuckyTenant2ChessConfigById(id)
    return config and config.BondId or ""
end

-- 新增字段：是否可应用到凑羁绊中
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessCanUseForBondById(id)
    local config = self:GetLuckyTenant2ChessConfigById(id)
    return config and config.CanUseForBond == 1 or false
end

-- 新增字段：默认等级
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessDefaultLevelById(id)
    local config = self:GetLuckyTenant2ChessConfigById(id)
    return config and config.DefaultLevel or 0
end

-- 新增字段：是否可升级
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessCanUpgradeById(id)
    local config = self:GetLuckyTenant2ChessConfigById(id)
    return config and config.CanUpgrade == 1 or false
end

-- 新增字段：是否可被消除
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessCanBeEliminatedById(id)
    local config = self:GetLuckyTenant2ChessConfigById(id)
    return config and config.CanBeEliminated == 1 or false
end

-- 新增字段：状态SkillId
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessStateSkillIdById(id, index)
    local config = self:GetLuckyTenant2ChessConfigById(id)
    if not config then return 0 end
    local stateSkillIds = config.StateSkillId or {}
    return stateSkillIds[index or 1] or 0
end

-- 保留一期的方法（兼容性）
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessTypeById(id)
    local config = self:GetLuckyTenant2ChessConfigById(id)
    return config and config.Type or 0
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessQualityById(id)
    local config = self:GetLuckyTenant2ChessConfigById(id)
    return config and config.Quality or 0
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessNameById(id)
    local config = self:GetLuckyTenant2ChessConfigById(id)
    return config and config.Name or ""
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessValueById(id)
    local config = self:GetLuckyTenant2ChessConfigById(id)
    return config and config.Value or 0
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessIconById(id)
    local config = self:GetLuckyTenant2ChessConfigById(id)
    return config and config.Icon or ""
end

---获取棋子详情背景（来自 LuckyTenant2Quality 配置表 BgChessDetail 字段，按棋子品质查）
---@param id number 棋子ID
---@return string
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessBgChessDetailById(id)
    local quality = self:GetLuckyTenant2ChessQualityById(id)
    return self:GetLuckyTenant2QualityBgChessDetailById(quality)
end

---获取品质对应的详情背景（来自 LuckyTenant2Quality 配置表 BgChessDetail 字段）
---@param qualityId number 品质ID
---@return string
function XLuckyTenant2ConfigModel:GetLuckyTenant2QualityBgChessDetailById(qualityId)
    if not qualityId or qualityId <= 0 then
        return ""
    end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2TableKey.LuckyTenant2Quality, qualityId, true)
    return config and config.BgChessDetail or ""
end

---获取棋子描述
---@param id number 棋子ID
---@return string[] 描述数组
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessDescById(id)
    local config = self:GetLuckyTenant2ChessConfigById(id)
    if config and config.Desc then
        return config.Desc
    end
    return {}
end

---获取棋子类型名称
---@param typeId number 类型ID
---@return string
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessTypeNameById(typeId)
    local config = self:GetLuckyTenant2ChessTypeConfigById(typeId)
    if config then
        return config.Name or ""
    end
    return ""
end

---获取品质图标（方形）
---@param quality number 品质值
---@return string
function XLuckyTenant2ConfigModel:GetQualityIconQuad(quality)
    quality = tonumber(quality)
    if not quality or quality < 0 then
        return ""
    end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2TableKey.LuckyTenant2Quality, quality, true)
    if not config then
        -- 拦截错误，改为警告
        XLog.Warning(string.format("ModuleId:XLuckyTenant2警告:找不到唯一Id数据。搜索路径: Client/MiniActivity/LuckyTenant2/LuckyTenant2Quality.tab 索引唯一Id = %s", tostring(quality)))
        return ""
    end
    return config.IconQuad or ""
end

---获取品质图标（圆形）
---@param quality number 品质值
---@return string
function XLuckyTenant2ConfigModel:GetQualityIconCircle(quality)
    quality = tonumber(quality)
    if not quality or quality < 0 then
        return ""
    end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2TableKey.LuckyTenant2Quality, quality, true)
    if not config then
        -- 拦截错误，改为警告
        XLog.Warning(string.format("ModuleId:XLuckyTenant2警告:找不到唯一Id数据。搜索路径: Client/MiniActivity/LuckyTenant2/LuckyTenant2Quality.tab 索引唯一Id = %s", tostring(quality)))
        return ""
    end
    return config.IconCircle or ""
end

-- ==================== 技能表相关（新增condition字段） ====================

---@return XTableLuckyTenant2ChessSkill[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessSkillConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenant2TableKey.LuckyTenant2ChessSkill)
end

---@return XTableLuckyTenant2ChessSkill
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessSkillConfigById(id)
    -- 因为会尝试查找skillId，所以不提示错误 
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2TableKey.LuckyTenant2ChessSkill, id, true)
end

-- 新增字段：condition
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessSkillConditionById(id)
    local config = self:GetLuckyTenant2ChessSkillConfigById(id)
    return config and config.Condition or ""
end

-- 保留一期的方法
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessSkillTypeById(id)
    local config = self:GetLuckyTenant2ChessSkillConfigById(id)
    return config and config.Type or 0
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessSkillNameById(id)
    local config = self:GetLuckyTenant2ChessSkillConfigById(id)
    return config and config.Name or ""
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessSkillDescById(id)
    local config = self:GetLuckyTenant2ChessSkillConfigById(id)
    return config and config.Desc or ""
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessSkillParamsById(id)
    local config = self:GetLuckyTenant2ChessSkillConfigById(id)
    return config and config.Params or {}
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessSkillPriorityById(id)
    local config = self:GetLuckyTenant2ChessSkillConfigById(id)
    return config and config.Priority or 0
end

-- ==================== 关卡表相关（新增字段） ====================

---@return XTableLuckyTenant2Stage[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2StageConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenant2TableKey.LuckyTenant2Stage)
end

---@return XTableLuckyTenant2Stage
function XLuckyTenant2ConfigModel:GetLuckyTenant2StageConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2TableKey.LuckyTenant2Stage, id, false)
end

-- 新增字段：显示的羁绊ID（id 为 nil 或 0 时不查表，配置表无该 Id）
function XLuckyTenant2ConfigModel:GetLuckyTenant2StageShowBondIdById(id)
    if not id or id <= 0 then
        return ""
    end
    local config = self:GetLuckyTenant2StageConfigById(id)
    return config and config.ShowBondId or ""
end

-- 新增字段：完美通关描述（PerfectDesc）
function XLuckyTenant2ConfigModel:GetLuckyTenant2StagePerfectDescById(id)
    local config = self:GetLuckyTenant2StageConfigById(id)
    return config and config.PerfectDesc or ""
end

-- 新增字段：首进打开图文教程页数
function XLuckyTenant2ConfigModel:GetLuckyTenant2StageTutorialPageById(id)
    local config = self:GetLuckyTenant2StageConfigById(id)
    return config and config.TutorialPage or 0
end

-- 保留一期的方法
function XLuckyTenant2ConfigModel:GetLuckyTenant2StageNameById(id)
    local config = self:GetLuckyTenant2StageConfigById(id)
    return config and config.Name or ""
end

-- ==================== 章节表相关 ====================

---@return XTable.XTableLuckyTenant2Chapter[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChapterConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenant2TableKey.LuckyTenant2Chapter)
end

---@return XTable.XTableLuckyTenant2Chapter
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChapterConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2TableKey.LuckyTenant2Chapter, id, false)
end

-- ==================== 其他表相关 ====================

---@return XTableLuckyTenant2ChessType[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessTypeConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenant2TableKey.LuckyTenant2ChessType)
end

---@return XTableLuckyTenant2ChessType
function XLuckyTenant2ConfigModel:GetLuckyTenant2ChessTypeConfigById(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2TableKey.LuckyTenant2ChessType, id, true)
    if not config then
        -- 拦截错误，改为警告（常见情况：PropId 98/99 等道具类型配置可能不存在）
        XLog.Warning(string.format("ModuleId:XLuckyTenant2警告:找不到唯一Id数据。搜索路径: Share/MiniActivity/LuckyTenant2/LuckyTenant2ChessType.tab 索引唯一Id = %s", tostring(id)))
    end
    return config
end

---@return XTableLuckyTenant2StageTask[]
function XLuckyTenant2ConfigModel:GetLuckyTenant2StageTaskConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenant2TableKey.LuckyTenant2StageTask)
end

---@return XTableLuckyTenant2StageTask
function XLuckyTenant2ConfigModel:GetLuckyTenant2StageTaskConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2TableKey.LuckyTenant2StageTask, id, true)
end

function XLuckyTenant2ConfigModel:GetLuckyTenant2ActivityById(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenant2TableKey.LuckyTenant2Activity, id, true)
    return config
end

return XLuckyTenant2ConfigModel

