---@class XTheatre5PVPControl : XControl
---@field private _Model XTheatre5Model
---@field _MainControl XTheatre5Control
local XTheatre5PVPControl = XClass(XControl, "XTheatre5PVPControl")

function XTheatre5PVPControl:OnInit()
 
end

function XTheatre5PVPControl:AddAgencyEvent()

end

function XTheatre5PVPControl:RemoveAgencyEvent()

end

function XTheatre5PVPControl:OnRelease()
    self:StopPVPTimer()
end

--region 服务端数据

--- 获取角色数据
function XTheatre5PVPControl:GetPVPCharacterDataById(configId, notips)
    return self._Model.PVPCharacterData:GetPVPCharacterById(configId, notips)
end

--- 判断是否有指定角色的数据
function XTheatre5PVPControl:CheckHasPVPCharacterDataById(id)
    local data = self._Model.PVPCharacterData:GetPVPCharacterById(id, true)
    
    return not XTool.IsTableEmpty(data)
end

function XTheatre5PVPControl:GetCurMatchedEnemy()
    return self._Model.PVPAdventureData:GetCurMatchedEnemy()
end

-- 清空PVP数据缓存
function XTheatre5PVPControl:ClearAdventureData()
    self._Model.PVPAdventureData:ClearData()
end

--- 排行榜获取指定角色数据
function XTheatre5PVPControl:GetCharacterDataForRank(charaId)
    if XTool.IsNumberValid(charaId) then
        return self._Model.PVPCharacterData:GetPVPCharacterById(charaId)
    else
        local characterDatas = self._Model.PVPCharacterData:GetPVPCharacters()

        if not XTool.IsTableEmpty(characterDatas) then
            local score = -1
            local charaData = nil
            
            for i, v in pairs(characterDatas) do
                if v.Rating > score then
                    score = v.Rating
                    charaData = v
                end
            end
            
            return charaData
        end
    end
end

--- 排行榜判断本地数据，是否有多个最高积分的角色（用于指导总榜角色显示）
function XTheatre5PVPControl:GetIsCharactersMultyMaxRating()
    local characterDatas = self._Model.PVPCharacterData:GetPVPCharacters()

    if not XTool.IsTableEmpty(characterDatas) then
        local sameCount = 0
        local score = -1

        for i, v in pairs(characterDatas) do
            if v.Rating > score then
                score = v.Rating
                sameCount = 1
            elseif v.Rating == score then
                sameCount = sameCount + 1    
            end
        end

        return sameCount > 1
    end
    
    -- 没数据当成积分一样
    return true
end

--- 判断指定角色是否获得了对应段位的奖励
function XTheatre5PVPControl:CheckCharacterIsGetRankReward(charaId, rankId)
    return self._Model.PVPCharacterData:CheckCharacterIsGetRankReward(charaId, rankId)
end
--endregion

--region 配置表 - 角色选择

--- 获取指定段位配置
function XTheatre5PVPControl:GetPVPRankCfgById(id)
    return self._Model:GetTheatre5RankCfgById(id)
end

--- 根据分数获取所属段位配置
function XTheatre5PVPControl:GetPVPRankCfgByRatingScore(score)
    -- 先遍历大段位，找出玩家所处的区间
    ---@type XTableTheatre5RankMajor[]
    local majorCfgs = self._Model:GetTheatre5RankMajorCfgs()

    if not XTool.IsTableEmpty(majorCfgs) then
        for i, majorCfg in pairs(majorCfgs) do
            local minRankCfg = self._Model:GetTheatre5RankCfgById(majorCfg.MinRank)

            if minRankCfg and score >= minRankCfg.Rating then
                local maxRankCfg = self._Model:GetTheatre5RankCfgById(majorCfg.MaxRank)

                if maxRankCfg and score <= maxRankCfg.Rating then
                    -- 确定玩家分数在这个范围内，再逐一找到最接近的段位
                    local nearestRankCfg = minRankCfg
                    
                    -- 这里必须Id连续，否则需要调整逻辑.
                    -- 遍历从最小段位的下一个段位开始
                    for i = 1, majorCfg.StarCount - 1 do
                        local rankCfg = self._Model:GetTheatre5RankCfgById(majorCfg.MinRank + i)

                        if score >= rankCfg.Rating then
                            nearestRankCfg = rankCfg
                        else
                            break
                        end
                    end
                    
                    return nearestRankCfg
                end
            end
        end
    end
    
    --- 以下逻辑保留，作为保底逻辑
    ---@type XTableTheatre5Rank[]
    local cfgs = self._Model:GetTheatre5RankCfgs()

    if not XTool.IsTableEmpty(cfgs) then
        local nearestRankCfg = nil
        
        for i, v in pairs(cfgs) do
            if score >= v.Rating then
                nearestRankCfg = v
            else
                break
            end    
        end
        
        return nearestRankCfg
    end
end

--- 获取下一等级段位的配置
function XTheatre5PVPControl:GetPVPNextRankCfgByRankId(rankId)
    return self._Model:GetTheatre5RankCfgById(rankId + 1, true)
end

--- 获取上一个等级段位的配置
function XTheatre5PVPControl:GetPVPLastRankCfgByRankId(rankId)
    return self._Model:GetTheatre5RankCfgById(rankId - 1, true)
end

--- 获取段位进度插值文本
function XTheatre5PVPControl:GetPVPRankScoreLabelFromClientConfig()
    return self._Model:GetTheatre5ClientConfigText('RankScoreLabel')
end

--- 获取段位详情描述
function XTheatre5PVPControl:GetPVPRankDetailDescFromClientConfig()
    return self._Model:GetTheatre5ClientConfigText('RankDetailDesc')
end

--- 获取所有大段位的配置
function XTheatre5PVPControl:GetPVPRankMajorCfgs()
    return self._Model:GetTheatre5RankMajorCfgs()
end

--- 获取指定大段位的底图（以最大小段位的底图资源为主)
function XTheatre5PVPControl:GetPVPRankMajorIconResById(majorId)
    local majorCfg = self._Model:GetTheatre5RankMajorCfgById(majorId)

    if majorCfg then
        local rankCfg = self._Model:GetTheatre5RankCfgById(majorCfg.MaxRank)

        if rankCfg then
            return rankCfg.IconRes
        end
    end
    
    return ''
end

--- 根据当前分数获取所属大段位Id
function XTheatre5PVPControl:GetPVPRankMajorIdByRatingScore(score)
    -- 先遍历大段位，找出玩家所处的区间
    ---@type XTableTheatre5RankMajor[]
    local majorCfgs = self._Model:GetTheatre5RankMajorCfgs()

    local majorId = 0
    
    if not XTool.IsTableEmpty(majorCfgs) then
        for i, majorCfg in pairs(majorCfgs) do
            local minRankCfg = self._Model:GetTheatre5RankCfgById(majorCfg.MinRank)

            if minRankCfg and score >= minRankCfg.Rating then
                local maxRankCfg = self._Model:GetTheatre5RankCfgById(majorCfg.MaxRank)

                -- 当积分大于该大段位的最低段位时，标记为候补
                majorId = majorCfg.Id
                
                if maxRankCfg and score <= maxRankCfg.Rating then
                    return majorCfg.Id
                end
            end
        end
    end
    
    --- 在这里返回表示没有找到有效大段位，或处于大段位最高段位
    return majorId
end

--endregion

--region 配置表 - 局内信息

--- 获取奖杯总数配置
function XTheatre5PVPControl:GetPVPTargetCountFromConfig()
    return self._Model:GetTheatre5ConfigValByKey('PvpTarget')
end

--- 获取生命最大值
function XTheatre5PVPControl:GetPVPHealthMaxFromConfig()
    return self._Model:GetTheatre5ConfigValByKey('PvpHealth')
end

--- 获取生命值余量显示插值文本
function XTheatre5PVPControl:GetHealthShowTextFromClientConfig()
    return self._Model:GetTheatre5ClientConfigText('TopHealthLabel')
end

--- 获取商店格子总数
function XTheatre5PVPControl:GetShopGridsTotalCount()
    return self._Model:GetTheatre5ConfigValByKey('PvpShopGridsTotalCount')
end

--- 获取商店详情升级提示文本
function XTheatre5PVPControl:GetShopLevelUpTips()
    return self._Model:GetTheatre5ClientConfigText('ShopLevelUpTips')
end

--- 获取宝珠栏格子总数
function XTheatre5PVPControl:GetGemMaxSlot()
    return self._Model:GetTheatre5ConfigValByKey('RuneGridMaxNum')
end

--endregion

--region 配置表 - 结算相关

--- 获取段位积分变化文本
function XTheatre5PVPControl:GetRatingProcessLabelFromClientConfig(isAdds)
    local index = isAdds and 1 or 2
    
    local format = self._Model:GetTheatre5ClientConfigText('RatingProcessLabel', index)
    
    format = string.gsub(format, '\\', '')
    
    return format
end


--endregion

--region 杂项表

function XTheatre5PVPControl:GetClientConfigRankPercentLabel()
    return self._Model:GetTheatre5ClientConfigText('RankPercentLabel')
end

function XTheatre5PVPControl:GetClientConfigRankListGridAnimationInterval()
    return self._Model:GetTheatre5ClientConfigNum('RankListGridAnimationInterval')
end

--endregion

--region 踢出检查

function XTheatre5PVPControl:StopPVPTimer()
    if self._PVPTimerId then
        XScheduleManager.UnSchedule(self._PVPTimerId)
        self._PVPTimerId = nil
    end
end

function XTheatre5PVPControl:StartPVPTimer(tickCb)
    self:StopPVPTimer()
    
    self._TickoutCallBack = tickCb
    self.PVPTimeId = XMVCA.XTheatre5:GetPVPActivityTimeId()

    if XTool.IsNumberValid(self.PVPTimeId) and XFunctionManager.CheckInTimeByTimeId(self.PVPTimeId) then
        self:UpdatePVPTimer()
        self._PVPTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdatePVPTimer), XScheduleManager.SECOND)
    else
        self:DoTickoutCallBack()
    end
end

function XTheatre5PVPControl:UpdatePVPTimer()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.PVPTimeId)

    if endTime <= 0 then
        XLog.Error('PVP结束时间异常，结束时间：'..tostring(endTime)..' TimeId:'..tostring(self.PVPTimeId))
        self:StopPVPTimer()
        self:DoTickoutCallBack()
    end

    local now = XTime.GetServerNowTimestamp()
    local leftTime = math.max(endTime - now, 0)

    if leftTime <= 0 then
        self:StopPVPTimer()
        self:DoTickoutCallBack()
    end
end

function XTheatre5PVPControl:CheckPVPInTime()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.PVPTimeId)

    if endTime <= 0 then
        return false
    end

    local now = XTime.GetServerNowTimestamp()
    local leftTime = math.max(endTime - now, 0)

    if leftTime <= 0 then
        return false
    end
    
    return true
end

function XTheatre5PVPControl:DoTickoutCallBack()
    if self._TickoutCallBack then
        self._TickoutCallBack()
        self._TickoutCallBack = nil
    end
    
    XLuaUiManager.CloseAllUpperUiWithCallback('UiTheatre5Main')

    XUiManager.TipText('ActivityMainLineEnd')
end
--endregion

return XTheatre5PVPControl