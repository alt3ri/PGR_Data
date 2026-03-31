--- Agency的组件，封装PVP相关的接口
---@class XTheatre5PVPAgencyCom
---@field private _OwnerAgency XTheatre5Agency
---@field private _Model XTheatre5Model
local XTheatre5PVPAgencyCom = XClass(nil, 'XTheatre5PVPAgencyCom')

--- 排行榜请求cd
local RankReqInterval = 5

function XTheatre5PVPAgencyCom:Init(ownerAgency, model)
    self._OwnerAgency = ownerAgency
    self._Model = model
    self._RankDataCache = {}
    self._RankDataLastReqTime = {}

    self._OwnerAgency:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_COMMON_BATTLE_SETTLE, self.OnCommonBattleSettleEvent, self)

    -- 初始化cd的配置
    local rankRequestCd = self._Model:GetTheatre5ClientConfigNum('RankRequestCd')

    if XTool.IsNumberValid(rankRequestCd) then
        RankReqInterval = rankRequestCd
    end
end

function XTheatre5PVPAgencyCom:Release()
    self._OwnerAgency:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_COMMON_BATTLE_SETTLE, self.OnCommonBattleSettleEvent, self)

    self._OwnerAgency = nil
    self._Model = nil
    self._AdvanceSettleContent = nil
    self._RankDataCache = nil
    self._RankDataLastReqTime = nil

end


--region Network

--- 请求开始游戏
function XTheatre5PVPAgencyCom:RequestTheatre5InitGame(characterId, cb)
    XNetwork.Call("Theatre5InitGameRequest", { CharacterId = characterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.PVPAdventureData:UpdatePVPAdventureData(res.PvpAdventureData)

        if cb then
            cb(true)
        end
    end)
end

--- 请求排行榜数据
function XTheatre5PVPAgencyCom:RequestTheatre5QueryRank(characterId, cb)
    local now = XTime.GetServerNowTimestamp()
    local lastReqTime = self._RankDataLastReqTime[characterId] or 0

    if self._RankDataCache[characterId] and (now - lastReqTime) < RankReqInterval then
        if cb then
            cb(true, self._RankDataCache[characterId])
        end

        return
    end

    XNetwork.Call("XTheatre5QueryRankRequest", { CharacterId = characterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._RankDataCache[characterId] = res
        self._RankDataLastReqTime[characterId] = XTime.GetServerNowTimestamp()

        if cb then
            cb(true, res)
        end
    end)
end
--endregion

function XTheatre5PVPAgencyCom:OnCommonBattleSettleEvent(autoChessResult)
    if self._Model:GetCurPlayingMode() ~= XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        return
    end

    -- 更新奖杯数、是否为额外对局、原始段位积分
    self._Model.PVPAdventureData:UpdateTrophyNum(autoChessResult.TrophyNum)
    self._Model.PVPAdventureData:UpdateIsPvpExtra(autoChessResult.IsPvpExtra)
    self._Model.PVPAdventureData:UpdateNormalOriginRating(autoChessResult.NormalOriginRating)

    -- 只有在游戏结束时才更新段位积分
    if not autoChessResult.IsFinish then
        return
    end

    local oldRating = self:_UpdateCharacterRating(autoChessResult.Rating, autoChessResult.RankProtectNum)

    --- 根据积分变化累计量和实际变化量判断是否触发段位保护
    local isUsedRankProtect = false

    if oldRating + autoChessResult.ProcessRating < autoChessResult.Rating then
        isUsedRankProtect = true
    end

    autoChessResult.IsUsedRankProtect = isUsedRankProtect
    autoChessResult.OldRating = oldRating
end

--- 更新角色段位积分
function XTheatre5PVPAgencyCom:_UpdateCharacterRating(rating, rankProtectNum)
    if rating == nil then
        return
    end

    local characterId = self._Model.PVPAdventureData:GetCharacterId()

    if XTool.IsNumberValid(characterId) then
        -- 获取旧的积分
        local oldRating = self._Model.PVPCharacterData:GetCharacterRankRatingById(characterId)

        self._Model.PVPCharacterData:UpdatePVPCharacterRating(characterId, rating)
        self._Model.PVPCharacterData:UpdatePVPCharacterRankProtectNum(characterId, rankProtectNum)

        return oldRating
    end
end

return XTheatre5PVPAgencyCom
