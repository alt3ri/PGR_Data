--- 图鉴卡牌背景配置读取器。
--- 只读取图鉴显示需要的静态配置，不读取局内实时数据。
local XUiPunishaarCollectionCardBgSettingsReader = {}

local CardType = XMVCA.XPunishaar.EnumConst.CardType

-- Id = 10000 + 100 * Color + Level
local ID_BASE = 10000
local ID_COLOR_SLOT = 100

--- 根据卡牌类型读取对应尺寸数组。
---@param row XTablePunishaarCardBgSettings
---@param cardType number
---@param fieldSuffix string
---@return table|nil
local function GetSizeArray(row, cardType, fieldSuffix)
    if not row then
        return nil
    end

    local prefix

    if cardType == CardType.Character then
        prefix = "RoleMainCard"
    elseif cardType == CardType.Weapon then
        prefix = "PartnerMainCard"
    else
        return nil
    end

    return row[prefix .. fieldSuffix]
end

--- 读取卡牌品质底图。
---@param control XPunishaarControl
---@param cardType number
---@param cardSize number
---@param level number
---@return string|nil
function XUiPunishaarCollectionCardBgSettingsReader.GetBgSprite(
    control,
    cardType,
    cardSize,
    level
)
    local id = ID_BASE + (level or 0)
    local row = control:GetTablePunishaarCardBgSettings(id, true)
    local arr = GetSizeArray(row, cardType, "SizeBgs")

    return arr and arr[cardSize] or nil
end

--- 读取卡牌前景图。
---@param control XPunishaarControl
---@param cardType number
---@param cardSize number
---@return string|nil
function XUiPunishaarCollectionCardBgSettingsReader.GetFrontSprite(
    control,
    cardType,
    cardSize
)
    local row = control:GetTablePunishaarCardBgSettings(ID_BASE, true)
    local arr = GetSizeArray(row, cardType, "FrontSizeBgs")

    return arr and arr[cardSize] or nil
end

--- 读取图鉴卡牌的静态球显示。
--- 球类型和数量均读取 PunishaarCardLevel 表，不使用局内实时数值。
---@param control XPunishaarControl
---@param ballConsume number
---@param ballOutPut number
---@param color number
---@return table
function XUiPunishaarCollectionCardBgSettingsReader.GetBallDisplay(
    control,
    ballConsume,
    ballOutPut,
    color
)
    local isConsume = (ballConsume or 0) ~= 0

    if not isConsume and (ballOutPut or 0) == 0 then
        return {
            showIn = false,
            showOut = false,
            count = 0,
            bgSprite = nil,
            iconSprite = nil,
        }
    end

    local count = isConsume and ballConsume or ballOutPut
    local id = ID_BASE + ID_COLOR_SLOT * (color or 0)
    local row = control:GetTablePunishaarCardBgSettings(id, true)

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

--- 读取图鉴卡牌选中框。
---@param control XPunishaarControl
---@param cardType number
---@param cardSize number
---@return string|nil
function XUiPunishaarCollectionCardBgSettingsReader.GetCollectionSelectSprite(
    control,
    cardType,
    cardSize
)
    local row = control:GetTablePunishaarCardBgSettings(ID_BASE, true)

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

--- 读取图鉴未解锁卡牌图片。
---@param control XPunishaarControl
---@param cardType number
---@param cardSize number
---@return string|nil
function XUiPunishaarCollectionCardBgSettingsReader.GetCollectionLockSprite(
    control,
    cardType,
    cardSize
)
    local row = control:GetTablePunishaarCardBgSettings(ID_BASE, true)

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

return XUiPunishaarCollectionCardBgSettingsReader