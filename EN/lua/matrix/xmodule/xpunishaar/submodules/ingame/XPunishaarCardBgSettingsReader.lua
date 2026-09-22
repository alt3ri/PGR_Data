--- 卡牌显示 BgSettings Reader：纯函数 module（非 XClass，不持状态）。
--- 维度拼 Id（内联 10000+100*color+level，参项目 Id 拼接范式不设 helper）→ gameControl:GetTablePunishaarCardBgSettings(id)
---   → Type 分发 Role/Partner → [Size] 下标 → nil 守护（行/字段空返 nil，调用方隐节点）。
--- 对齐 STEProjection 范式（纯函数 + control 首参）。#64
local XPunishaarCardBgSettingsReader = {}

local CardType = XMVCA.XPunishaar.EnumConst.CardType

-- Id 公式：10000（占位基）+ 100*Color + Level；Color=0/Level=0 = 该维度无关
local ID_BASE = 10000
local ID_COLOR_SLOT = 100

--- Type 分发：Character→Role*，Weapon→Partner*（用枚举非魔数）。返回行内对应数组字段。
---@param row XTablePunishaarCardBgSettings
---@param cardType number CardType
---@param fieldPrefix string "RoleMainCard" / "PartnerMainCard"
---@return string|nil
local function GetSizeArray(row, cardType, fieldPrefix)
    if not row then
        return nil
    end
    -- Type→Role/Partner 前缀
    local prefix
    if cardType == CardType.Character then
        prefix = "RoleMainCard"
    elseif cardType == CardType.Weapon then
        prefix = "PartnerMainCard"
    else
        return nil
    end
    local arr = row[prefix .. fieldPrefix]
    return arr  -- 数组，调用方再 [Size] 下标
end

--- 底图：Id=10000+0+Level（Level 维度），Type→Role/PartnerMainCardSizeBgs[Size]。
---@param gameControl XPunishaarGameControl
---@param cardType number CardType
---@param cardSize number 1/2/3
---@param level number 卡牌等级（≥1）
---@return string|nil sprite 路径（nil=配置缺，调用方隐节点）
function XPunishaarCardBgSettingsReader.GetBgSprite(gameControl, cardType, cardSize, level)
    local id = ID_BASE + (level or 0)
    local row = gameControl:GetTablePunishaarCardBgSettings(id, true)
    local arr = GetSizeArray(row, cardType, "SizeBgs")
    return arr and arr[cardSize] or nil
end

--- 主卡详情头像背景图：Id=10000+Level（Level 维度），Type→RoleMainDetailHeadBg/PartnerMainDetailHeadBg（单值，不分 Size）。
---@param gameControl XPunishaarGameControl
---@param cardType number CardType
---@param level number 卡牌等级（≥1）
---@return string|nil 背景图路径（nil=配置缺，调用方隐节点）
function XPunishaarCardBgSettingsReader.GetMainDetailHeadBg(gameControl, cardType, level)
    local id = ID_BASE + (level or 0)
    local row = gameControl:GetTablePunishaarCardBgSettings(id, true)
    if not row then
        return nil
    end
    if cardType == CardType.Character then
        return row.RoleMainDetailHeadBg or nil
    elseif cardType == CardType.Weapon then
        return row.PartnerMainDetailHeadBg or nil
    end
    return nil
end

--- 前遮：Id=10000（无依赖），Type→Role/PartnerMainCardFrontSizeBgs[Size]。
---@param gameControl XPunishaarGameControl
---@param cardType number
---@param cardSize number
---@return string|nil
function XPunishaarCardBgSettingsReader.GetFrontSprite(gameControl, cardType, cardSize)
    local row = gameControl:GetTablePunishaarCardBgSettings(ID_BASE, true)
    local arr = GetSizeArray(row, cardType, "FrontSizeBgs")
    return arr and arr[cardSize] or nil
end

--- 遮罩：Id=10000（无依赖），Type→Role/PartnerMainCardMaskBgs[Size]。
---@param gameControl XPunishaarGameControl
---@param cardType number
---@param cardSize number
---@return string|nil
function XPunishaarCardBgSettingsReader.GetMaskSprite(gameControl, cardType, cardSize)
    local row = gameControl:GetTablePunishaarCardBgSettings(ID_BASE, true)
    local arr = GetSizeArray(row, cardType, "MaskBgs")
    return arr and arr[cardSize] or nil
end

--- 描边：Id=10000（无依赖），Type→Role/PartnerMainCardOutlineBgs[Size]。
---@param gameControl XPunishaarGameControl
---@param cardType number
---@param cardSize number
---@return string|nil
function XPunishaarCardBgSettingsReader.GetOutlineSprite(gameControl, cardType, cardSize)
    local row = gameControl:GetTablePunishaarCardBgSettings(ID_BASE, true)
    local arr = GetSizeArray(row, cardType, "OutlineBgs")
    return arr and arr[cardSize] or nil
end

--- 激活态火焰材质球路径：Id=10000（无依赖，仅 Type+Size 维度），Type→Role/PartnerMainCardActiveVFX[Size]。
---@param gameControl XPunishaarGameControl
---@param cardType number
---@param cardSize number
---@return string|nil 材质球路径（nil=配置缺失/误删，调用方 Error）
function XPunishaarCardBgSettingsReader.GetActiveVFXMaterialPath(gameControl, cardType, cardSize)
    local row = gameControl:GetTablePunishaarCardBgSettings(ID_BASE, true)
    local arr = GetSizeArray(row, cardType, "ActiveMat")
    return arr and arr[cardSize] or nil
end

--- 球值标签：Id=10000+100*Color+0（Color 维度），返回消/产球显隐 + 底图 + 球数图标。
--- 约定：每卡必产或消、互斥（ballConsume/ballOutPut 恰一非 0），无无球色卡（Color≥1）。
---@param gameControl XPunishaarGameControl
---@param ballConsume number 消球数（0=非消球）
--- 取球显示数据。isConsume 判定基于**配置值**（configConsume/configOutPut，不受 buff 改 0 影响），
--- count 显示用**实时值**（realConsume/realOutPut，含 buff）。config 非 0 但 real=0 时显底图 + 数字 "0"。
---@param configConsume number 配置消球数（levelCfg.BallConsume，判型用，不受 buff 影响）
---@param configOutPut number 配置产球数（levelCfg.BallOutPut，判型用）
---@param realConsume number 实时消球数（reader:GetCardBallConsume，含 buff，显数用）
---@param realOutPut number 实时产球数（reader:GetCardBallProduct，含 buff，显数用）
---@param color number 球色（PunishaarCard.Color，≥1）
---@return table {showIn:boolean, showOut:boolean, count:number, bgSprite:string|nil, iconSprite:string|nil}
function XPunishaarCardBgSettingsReader.GetBallDisplay(gameControl, configConsume, configOutPut, realConsume, realOutPut, color)
    local isConsume = (configConsume or 0) ~= 0
    if not isConsume and (configOutPut or 0) == 0 then
        -- 配置非消非产 → 隐球区
        return { showIn = false, showOut = false, count = 0, bgSprite = nil, iconSprite = nil }
    end
    local count = isConsume and (realConsume or 0) or (realOutPut or 0)
    local id = ID_BASE + ID_COLOR_SLOT * (color or 0)
    local row = gameControl:GetTablePunishaarCardBgSettings(id, true)
    local bgSprite = row and row.BallCountBg or nil
    local iconArr = row and row.BallPointIcons or nil
    local iconSprite = iconArr and iconArr[count] or nil
    return {
        showIn = isConsume,
        showOut = not isConsume,
        count = count,
        bgSprite = bgSprite,
        iconSprite = iconSprite,
    }
end

function XPunishaarCardBgSettingsReader.GetCollectionSelectSprite(gameControl, cardType, cardSize)
    local row = gameControl:GetTablePunishaarCardBgSettings(ID_BASE, true)

    if not row then
        return nil
    end

    local arr
    if cardType == CardType.Character then
        arr = row.RoleCollectionSelectBgs
    elseif cardType == CardType.Weapon then
        arr = row.PartnerCollectionSelectBgs
    end

    return arr and arr[cardSize] or nil
end

function XPunishaarCardBgSettingsReader.GetCollectionLockSprite(gameControl, cardType, cardSize)
    local row = gameControl:GetTablePunishaarCardBgSettings(ID_BASE, true)

    if not row then
        return nil
    end

    local arr

    if cardType == CardType.Character then
        arr = row.RoleCollectionLockBgs
    elseif cardType == CardType.Weapon then
        arr = row.PartnerCollectionLockBgs
    end

    return arr and arr[cardSize] or nil
end

return XPunishaarCardBgSettingsReader
