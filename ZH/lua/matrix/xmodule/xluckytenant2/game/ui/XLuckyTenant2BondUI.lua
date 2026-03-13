local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local SkillType = XLuckyTenant2Enum.Skill

---羁绊UI数据处理模块
---整合羁绊相关的UI数据处理逻辑
---@class XLuckyTenant2BondUI
local BondUI = {}

---羁绊等级对应 icon/字色（0~4），等级>4 使用等级4颜色
local BondLevelColors = { [0] = "8893a4", [1] = "dcc0b7", [2] = "eaeaea", [3] = "fff8e5", [4] = "ffffff" }

---获取羁绊等级对应的颜色十六进制值
---@param level number 羁绊等级
---@return string 颜色十六进制值
function BondUI.GetBondLevelColorHex(level)
    return BondLevelColors[math.min(level or 0, 4)] or BondLevelColors[4]
end

---获取羁绊等级颜色配置表
---@return table 颜色配置表
function BondUI.GetBondLevelColors()
    return BondLevelColors
end

---获取关卡显示羁绊ID顺序
---@param model XLuckyTenant2Model 模型实例
---@param game XLuckyTenant2Game|nil 游戏实例
---@return number[] 羁绊ID顺序列表
function BondUI.GetStageShowBondIdOrder(model, game)
    local stageId = model and model.GetPlayingStageId and model:GetPlayingStageId()
    if (not stageId or stageId <= 0) and game and game.GetStageId then
        stageId = game:GetStageId()
    end
    if not stageId or stageId <= 0 then
        return {}
    end
    local str = model:GetLuckyTenant2StageShowBondIdById(stageId) or ""
    local order = {}
    for idStr in string.gmatch(str, "([^|]+)") do
        local id = tonumber(idStr)
        if id then
            table.insert(order, id)
        end
    end
    return order
end

---羁绊是否应在当前关卡显示
---等级>0 必定显示；
---等级=0 时，若背包中拥有任意一个该羁绊关联棋子也显示；
---否则仅当在关卡 ShowBondId 配置中时显示；配置为空则显示全部
---@param bondId number 羁绊ID
---@param level number 羁绊等级
---@param stageShowBondIdOrder number[] 关卡显示羁绊ID顺序
---@param model XLuckyTenant2Model|nil 用于读取羁绊关联棋子）
---@param bag XLuckyTenant2Bag|nil 用于判断是否拥有关联棋子）
---@return boolean
function BondUI.ShouldShowBond(bondId, level, stageShowBondIdOrder, model, bag)
    if level and level > 0 then
        return true
    end

    -- 0级兜底显示：背包中有任一关联棋子时显示
    if model and bag and bondId and bondId > 0 then
        local relatedChessStr = model:GetLuckyTenant2BondRelatedChessById(bondId) or ""
        if relatedChessStr ~= "" then
            local ownedPieceIdSet = {}
            local bagPieces = bag:GetAllPieces() or {}
            for _, piece in ipairs(bagPieces) do
                if piece and (not piece.IsDeleted or not piece:IsDeleted()) then
                    local pieceId = piece:GetId()
                    if pieceId and pieceId > 0 then
                        ownedPieceIdSet[pieceId] = true
                    end
                end
            end

            for idStr in string.gmatch(relatedChessStr, "([^|]+)") do
                local relatedId = tonumber(idStr)
                if relatedId and ownedPieceIdSet[relatedId] then
                    return true
                end
            end
        end
    end

    if not stageShowBondIdOrder or #stageShowBondIdOrder == 0 then
        return true
    end
    for _, id in ipairs(stageShowBondIdOrder) do
        if id == bondId then
            return true
        end
    end
    return false
end

---获取羁绊在关卡配置顺序中的下标（用于排序，不在配置中的排最后）
---@param bondId number 羁绊ID
---@param stageShowBondIdOrder number[] 关卡显示羁绊ID顺序
---@return number
function BondUI.GetBondDisplayOrderIndex(bondId, stageShowBondIdOrder)
    if stageShowBondIdOrder then
        for idx, id in ipairs(stageShowBondIdOrder) do
            if id == bondId then
                return idx
            end
        end
    end
    return 9999
end

---格式化技能描述（将参数填入描述模板）
---@param skillDesc string 技能描述模板
---@param params table 技能参数
---@param skillType number|nil 技能类型（用于特殊处理）
---@return string 格式化后的描述
function BondUI.FormatSkillDesc(skillDesc, params, skillType)
    if not skillDesc or skillDesc == "" then
        return ""
    end
    if not params or #params == 0 then
        return skillDesc
    end

    -- 对于某些技能（Type205、Type207），第一个参数是子虫ID，描述应该从第二个参数开始
    local formatParams = params
    if skillType == SkillType.Type205 or skillType == SkillType.Type207 then
        formatParams = { table.unpack(params, 2) }
    end

    -- 使用pcall安全地调用FormatText，避免格式化错误导致崩溃
    local success, formattedDesc = pcall(function()
        return XUiHelper.FormatText(skillDesc, table.unpack(formatParams))
    end)
    if success then
        return formattedDesc
    else
        XLog.Warning("[BondUI] FormatSkillDesc格式化失败，skillDesc:", skillDesc, "params:", params)
        return skillDesc
    end
end

---获取羁绊被动技能描述列表
---@param bondId number 羁绊ID
---@param bondLevel number 羁绊等级
---@param model XLuckyTenant2Model 模型实例
---@return string[] 被动技能描述列表
function BondUI.GetBondPassiveSkillDescs(bondId, bondLevel, model)
    if not bondId or not model then
        return {}
    end

    local level = bondLevel or 1
    if level <= 0 then
        level = 1
    end

    local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, level)
    local passiveSkillDescs = {}

    for _, bondSkillConfig in ipairs(bondSkillConfigs) do
        if bondSkillConfig.IsPassive then
            local skillId = bondSkillConfig.SkillId
            if skillId and skillId > 0 then
                local skillDesc = model:GetLuckyTenant2ChessSkillDescById(skillId) or ""
                if skillDesc ~= "" then
                    local params = model:GetLuckyTenant2ChessSkillParamsById(skillId) or {}
                    local skillType = model:GetLuckyTenant2ChessSkillTypeById(skillId)
                    local formattedDesc = BondUI.FormatSkillDesc(skillDesc, params, skillType)
                    table.insert(passiveSkillDescs, formattedDesc)
                end
            end
        end
    end

    -- 如果没有找到当前等级的被动技能，尝试使用等级1的被动技能
    if #passiveSkillDescs == 0 and level ~= 1 then
        local level1Configs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, 1)
        for _, bondSkillConfig in ipairs(level1Configs) do
            if bondSkillConfig.IsPassive then
                local skillId = bondSkillConfig.SkillId
                if skillId and skillId > 0 then
                    local skillDesc = model:GetLuckyTenant2ChessSkillDescById(skillId) or ""
                    if skillDesc ~= "" then
                        local params = model:GetLuckyTenant2ChessSkillParamsById(skillId) or {}
                        local formattedDesc = BondUI.FormatSkillDesc(skillDesc, params, nil)
                        table.insert(passiveSkillDescs, formattedDesc)
                    end
                end
            end
        end
    end

    -- 替换换行符
    for i = 1, #passiveSkillDescs do
        passiveSkillDescs[i] = XUiHelper.ReplaceTextNewLine(passiveSkillDescs[i])
    end

    return passiveSkillDescs
end

---获取羁绊升级需求描述
---@param bondId number 羁绊ID
---@param model XLuckyTenant2Model 模型实例
---@return string 升级需求描述
function BondUI.GetBondUpgradeRequireDesc(bondId, model)
    if not bondId or not model then
        return ""
    end

    local bondConfig = model:GetLuckyTenant2BondConfigById(bondId)
    if bondConfig and bondConfig.UpgradeRequireDesc and bondConfig.UpgradeRequireDesc ~= "" then
        return bondConfig.UpgradeRequireDesc
    end

    return ""
end

---获取羁绊当前生效的技能列表（用于显示 Buff 列表）
---@param bondId number 羁绊ID
---@param bondLevel number 羁绊等级
---@param model XLuckyTenant2Model 模型实例
---@return table[] 技能列表，每个元素包含 Index, Desc, Require 字段
function BondUI.GetBondActiveSkills(bondId, bondLevel, model)
    local result = {}
    if not bondId or bondLevel <= 0 or not model then
        return result
    end

    local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bondLevel)
    local index = 1

    for _, bondSkillConfig in ipairs(bondSkillConfigs) do
        local skillId = bondSkillConfig.SkillId
        if skillId and skillId > 0 then
            local skillDesc = model:GetLuckyTenant2ChessSkillDescById(skillId) or ""
            if skillDesc ~= "" then
                local params = model:GetLuckyTenant2ChessSkillParamsById(skillId) or {}
                local formattedDesc = BondUI.FormatSkillDesc(skillDesc, params, nil)
                table.insert(result, {
                    Index = index,
                    Desc = formattedDesc,
                    Require = bondSkillConfig.SkillRequire,
                })
                index = index + 1
            end
        end
    end

    return result
end

---获取羁绊所有等级的技能列表（用于显示未拥有羁绊的所有 Buffs）
---@param bondId number 羁绊ID
---@param model XLuckyTenant2Model 模型实例
---@return table[] 技能列表，每个元素包含 Index, Desc, Require, Level, ImageBg 字段
function BondUI.GetBondAllSkills(bondId, model)
    local result = {}
    if not bondId or not model then
        return result
    end

    local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondId(bondId)
    local index = 1

    for _, bondSkillConfig in ipairs(bondSkillConfigs) do
        -- 过滤掉被动技能
        if not bondSkillConfig.IsPassive or bondSkillConfig.IsPassive == 0 then
            local skillId = bondSkillConfig.SkillId
            if skillId and skillId > 0 then
                local skillDesc = model:GetLuckyTenant2ChessSkillDescById(skillId) or ""
                if skillDesc ~= "" then
                    local params = model:GetLuckyTenant2ChessSkillParamsById(skillId) or {}
                    local skillType = model:GetLuckyTenant2ChessSkillTypeById(skillId)
                    local formattedDesc = BondUI.FormatSkillDesc(skillDesc, params, skillType)

                    local level = bondSkillConfig.Level or 0
                    local qualityId = bondSkillConfig.SkillQualityId or 0
                    local imageBg = model:GetLuckyTenant2BondQualityBgById(qualityId) or ""

                    table.insert(result, {
                        Index = index,
                        Desc = formattedDesc,
                        Require = bondSkillConfig.SkillRequire,
                        Level = level,
                        ImageBg = imageBg,
                        SkillQualityId = bondSkillConfig.SkillQualityId,
                    })
                    index = index + 1
                end
            end
        end
    end

    return result
end

---获取羁绊关联的棋子列表
---@param bondId number 羁绊ID
---@param model XLuckyTenant2Model 模型实例
---@param bag XLuckyTenant2Bag|nil 背包实例（用于判断是否拥有）
---@return table[] 棋子列表
function BondUI.GetBondRelatedChessList(bondId, model, bag)
    local result = {}
    if not bondId or not model then
        return result
    end

    local relatedChessStr = model:GetLuckyTenant2BondRelatedChessById(bondId) or ""
    if relatedChessStr == "" then
        return result
    end

    -- 解析棋子ID列表并去重
    local chessIds = {}
    local chessIdSet = {}
    for chessIdStr in string.gmatch(relatedChessStr, "([^|]+)") do
        local chessId = tonumber(chessIdStr)
        if chessId and chessId > 0 and not chessIdSet[chessId] then
            chessIdSet[chessId] = true
            table.insert(chessIds, chessId)
        end
    end

    -- 获取背包中的棋子
    local bagPiecesMap = {}
    if bag then
        local bagPieces = bag:GetAllPieces()
        for _, piece in ipairs(bagPieces) do
            local pieceId = piece:GetId()
            if pieceId and pieceId > 0 then
                bagPiecesMap[pieceId] = true
            end
        end
    end

    -- 构建棋子数据列表
    for _, chessId in ipairs(chessIds) do
        local chessConfig = model:GetLuckyTenant2ChessConfigById(chessId)
        if chessConfig then
            local chessData = {
                Id = chessId,
                Icon = model:GetLuckyTenant2ChessIconById(chessId) or "",
                Quality = chessConfig.Quality or "",
                QualityValue = chessConfig.QualityValue or 0,
                IsOwned = bagPiecesMap[chessId] or false
            }
            table.insert(result, chessData)
        end
    end

    return result
end

---生成羁绊等级文本（带颜色标记）
---@param bondId number 羁绊ID
---@param currentLevel number 当前羁绊等级
---@param model XLuckyTenant2Model 模型实例
---@return string 等级文本
function BondUI.GenerateBondLevelText(bondId, currentLevel, model)
    if not bondId or not model then
        return ""
    end

    local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondId(bondId)
    if not bondSkillConfigs or #bondSkillConfigs == 0 then
        return ""
    end

    -- 从所有配置中收集 SkillRequire 值（每个 level 只取第一个配置）
    local skillRequireMap = {}
    for _, bondSkillConfig in ipairs(bondSkillConfigs) do
        local skillRequire = bondSkillConfig.SkillRequire
        local configLevel = bondSkillConfig.Level
        if skillRequire and skillRequire > 0 and configLevel and configLevel > 0 then
            if not skillRequireMap[configLevel] then
                skillRequireMap[configLevel] = skillRequire
            end
        end
    end

    -- 转换为列表并按 level 排序
    local allSkillRequires = {}
    for configLevel, skillRequire in pairs(skillRequireMap) do
        table.insert(allSkillRequires, { level = configLevel, require = skillRequire })
    end
    table.sort(allSkillRequires, function(a, b) return a.level < b.level end)

    if #allSkillRequires == 0 then
        return ""
    end

    -- 生成等级文本：已激活用#f1d158，未激活保持BondLevelColors[0]
    local levelParts = {}
    local partColors = {}
    for j = 1, #allSkillRequires do
        local skillRequireData = allSkillRequires[j]
        local requireText = tostring(skillRequireData.require)
        local configLevel = skillRequireData.level
        local colorHex = (configLevel <= currentLevel) and "f1d58f" or BondLevelColors[0]
        partColors[j] = colorHex
        requireText = string.format("<color=#%s>%s</color>", colorHex, requireText)
        table.insert(levelParts, requireText)
    end

    local levelText = ""
    for j = 1, #levelParts do
        if j > 1 then
            levelText = levelText .. string.format("<color=#%s>/</color>", partColors[j])
        end
        levelText = levelText .. levelParts[j]
    end

    return levelText
end

---构建单个羁绊的UI数据
---@param bond XLuckyTenant2Bond 羁绊对象
---@param model XLuckyTenant2Model 模型实例
---@param bag XLuckyTenant2Bag|nil 背包实例
---@return table|nil 羁绊UI数据
function BondUI.BuildBondData(bond, model, bag)
    if not bond or not model then
        return nil
    end

    local bondId = bond:GetBondId()
    local level = bond:GetLevel()
    local bondConfig = model:GetLuckyTenant2BondConfigById(bondId)
    if not bondConfig then
        return nil
    end

    -- 生成等级文本
    local levelText = BondUI.GenerateBondLevelText(bondId, level, model)
    if levelText == "" and bondConfig.UpgradeRequireDesc and bondConfig.UpgradeRequireDesc ~= "" then
        levelText = bondConfig.UpgradeRequireDesc
    end

    -- 从当前等级对应的羁绊技能配置取品质ID（GetLuckyTenant2BondQualityBgById 需 BondQuality 表 id，即 SkillQualityId）
    local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, level)
    local bondSkillConfig = bondSkillConfigs and bondSkillConfigs[1]
    local qualityId = (bondSkillConfig and bondSkillConfig.SkillQualityId) or 0
    local imageBg = model:GetLuckyTenant2BondQualityBgById(qualityId) or ""

    -- 计算当前羁绊的棋子数量
    local pieceCount = 0
    if bag then
        pieceCount = bond:CalculateSatisfyCount(bag)
    end

    ---@class XUiLuckyTenant2GameGridBondsData
    local bondData = {
        BondId = bondId,
        Name = bond:GetName() or bondConfig.BondName or "",
        Icon = bond:GetIcon() or bondConfig.Icon or "",
        Level = level,
        LevelText = levelText,
        LevelColor = BondUI.GetBondLevelColorHex(bondSkillConfig.SkillQualityId),
        ImageBg = imageBg,
        PieceCount = pieceCount,
        SkillQualityId = qualityId,
        Buffs = {},
        ChessRequires = {},
    }

    -- 获取技能列表
    bondData.Buffs = BondUI.GetBondAllSkills(bondId, model)
    -- 为每个 Buff 添加 IsOwned、未拥有时用 0 级背景、等级对应字色
    for i = 1, #bondData.Buffs do
        local buff = bondData.Buffs[i]
        local buffLevel = buff.Level or 0
        local isOwned = level > 0 and level >= buffLevel
        buff.IsOwned = isOwned
        if not isOwned then
            buff.ImageBg = model:GetLuckyTenant2BondQualityBgById(0) or ""
            buff.LevelColor = BondLevelColors[0]
        else
            buff.LevelColor = BondUI.GetBondLevelColorHex(buff.SkillQualityId)
        end
    end

    -- 获取关联的棋子列表
    bondData.ChessRequires = BondUI.GetBondRelatedChessList(bondId, model, bag)

    return bondData
end

---构建羁绊得分记录数据
---@param bond XLuckyTenant2Bond 羁绊对象
---@param score number 得分
---@param model XLuckyTenant2Model 模型实例
---@param bag XLuckyTenant2Bag|nil 背包实例
---@return table|nil 羁绊得分记录数据
function BondUI.BuildBondIncomeData(bond, score, model, bag)
    if not bond or not model then
        return nil
    end

    local bondId = bond:GetBondId()
    local level = bond:GetLevel()
    local bondConfig = model:GetLuckyTenant2BondConfigById(bondId)
    if not bondConfig then
        return nil
    end

    local pieceCount = 0
    if bag then
        pieceCount = bond:CalculateSatisfyCount(bag)
    end

    -- 从当前等级对应的羁绊技能配置取品质ID（GetLuckyTenant2BondQualityBgById 需 BondQuality 表 id，即 SkillQualityId；无配置时用 0）
    local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, level)
    local bondSkillConfig = bondSkillConfigs and bondSkillConfigs[1]
    local qualityId = (bondSkillConfig and bondSkillConfig.SkillQualityId) or 0
    local imageBg = model:GetLuckyTenant2BondQualityBgById(qualityId) or ""

    return {
        BondId = bondId,
        Name = bondConfig.BondName or "",
        Icon = bondConfig.Icon or "",
        Level = level,
        LevelColor = BondUI.GetBondLevelColorHex(bondSkillConfig.SkillQualityId),
        PieceCount = pieceCount,
        Score = score or 0,
        ImageBg = imageBg,
    }
end

---获取羁绊详情数据（用于关卡详情弹窗）
---@param bondId number 羁绊ID
---@param model XLuckyTenant2Model 模型实例
---@return table|nil 羁绊详情数据
function BondUI.GetBondDetailDataForStagePopup(bondId, model)
    if not bondId or not model then
        return nil
    end

    local bondConfig = model:GetLuckyTenant2BondConfigById(bondId)
    if not bondConfig then
        return nil
    end

    local bondData = {
        BondId = bondId,
        Name = bondConfig.BondName or "",
        BondName = bondConfig.BondName or "",
        BondDesc = bondConfig.BondDesc or "",
        Icon = model:GetLuckyTenant2BondIconById(bondId) or bondConfig.Icon or "",
        BondIcon = bondConfig.Icon or "",
        CurrentLevel = 0,
        PieceCount = 0,
        Buffs = {},
        ChessRequires = {},
    }

    -- 获取所有技能列表
    bondData.Buffs = BondUI.GetBondAllSkills(bondId, model)
    -- 关卡详情中全部标记为未拥有
    local imageBgLevel0 = model:GetLuckyTenant2BondQualityBgById(0) or ""
    for i = 1, #bondData.Buffs do
        bondData.Buffs[i].IsOwned = false
        bondData.Buffs[i].ImageBg = imageBgLevel0
        bondData.Buffs[i].LevelColor = BondLevelColors[0]
    end

    -- 获取关联的棋子列表
    bondData.ChessRequires = BondUI.GetBondRelatedChessList(bondId, model, nil)

    return bondData
end

---排序羁绊列表（按关卡配置顺序、等级、BondId）
---@param bondsData table[] 羁绊数据列表
---@param stageShowBondIdOrder number[] 关卡显示羁绊ID顺序
---@param sortByScore boolean|nil 是否按得分排序（用于得分记录）
function BondUI.SortBondsData(bondsData, stageShowBondIdOrder, sortByScore)
    if not bondsData or #bondsData == 0 then
        return
    end

    table.sort(bondsData, function(a, b)
        local orderA = BondUI.GetBondDisplayOrderIndex(a.BondId, stageShowBondIdOrder)
        local orderB = BondUI.GetBondDisplayOrderIndex(b.BondId, stageShowBondIdOrder)

        if sortByScore then
            local scoreA = a.Score or 0
            local scoreB = b.Score or 0
            if scoreA ~= scoreB then
                return scoreA > scoreB
            end

            local pieceCountA = a.PieceCount or 0
            local pieceCountB = b.PieceCount or 0
            if pieceCountA ~= pieceCountB then
                return pieceCountA > pieceCountB
            end

            if orderA ~= orderB then
                return orderA < orderB
            end
        else
            if orderA ~= orderB then
                return orderA < orderB
            end
            if a.Level ~= b.Level then
                return a.Level > b.Level
            end
        end

        return a.BondId < b.BondId
    end)
end

return BondUI
