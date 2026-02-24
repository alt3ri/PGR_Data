---@class XLuckyTenant2RandomPool
local XLuckyTenant2RandomPool = XClass(nil, "XLuckyTenant2RandomPool")

function XLuckyTenant2RandomPool:Ctor()
    self._TypeQuality = {}
    self._TypeQualityId = {}
    self._Type = {}
    self._Uid = 0
end

---@param model XLuckyTenant2Model
function XLuckyTenant2RandomPool:Init(model)
    local pieces = model:GetLuckyTenant2ChessConfigs()
    for i, config in pairs(pieces) do
        self._TypeQuality[config.Type] = self._TypeQuality[config.Type] or {}
        if not self._TypeQuality[config.Type][config.Quality] then
            self._Uid = self._Uid + 1
            self._TypeQuality[config.Type][config.Quality] = {}
            self._TypeQualityId[config.Type] = self._TypeQualityId[config.Type] or {}
            self._TypeQualityId[config.Type][config.Quality] = self._TypeQualityId[config.Type][config.Quality] or {}
        end
        local bucket = self._TypeQuality[config.Type][config.Quality]
        bucket[#bucket + 1] = config.Id
    end

    for i, config in pairs(pieces) do
        self._Type[config.Type] = self._Type[config.Type] or {}
        local bucket = self._Type[config.Type]
        bucket[#bucket + 1] = config.Id
    end
end

function XLuckyTenant2RandomPool:GetRandomBucket(pieceType, pieceQuality)
    if not self._TypeQuality[pieceType] then
        return false
    end
    if not self._TypeQualityId[pieceType] then
        return false
    end

    local bucket = self._TypeQuality[pieceType][pieceQuality]
    local id = self._TypeQualityId[pieceType][pieceQuality]
    return bucket, id
end

function XLuckyTenant2RandomPool:GetRandomPieceIdByType(type)
    local bucket = self._Type[type]
    if not bucket then
        return false
    end
    return bucket[math.random(1, #bucket)]
end

function XLuckyTenant2RandomPool:GetRandomPieceId(pieceType)
    local bucket = self._Type[pieceType]
    if bucket then
        return bucket[math.random(1, #bucket)]
    end
    return bucket
end

return XLuckyTenant2RandomPool

