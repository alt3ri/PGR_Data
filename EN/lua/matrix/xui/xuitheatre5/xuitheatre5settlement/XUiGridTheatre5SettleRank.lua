local XUiGridTheatre5PVPRank = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/PVP/XUiGridTheatre5PVPRank')

---@class XUiGridTheatre5SettleRank: XUiGridTheatre5PVPRank
---@field Parent XUiPanelTheatre5SettleReward
local XUiGridTheatre5SettleRank = XClass(XUiGridTheatre5PVPRank, 'XUiGridTheatre5SettleRank')

local SettleRatingChangedAnimaTotalTime = nil

function XUiGridTheatre5SettleRank:OnStart()
    XUiGridTheatre5PVPRank.OnStart(self)
    
    if SettleRatingChangedAnimaTotalTime == nil or XMain.IsEditorDebug then
        SettleRatingChangedAnimaTotalTime = self._Control:GetClientConfigSettleRatingChangedAnimaTotalTime()
    end    
end

function XUiGridTheatre5SettleRank:SetCharacterConfigId(configId)
    self.CharaConfigId = configId
end

---@param gameplayResult XAutoChessGameplayResult
function XUiGridTheatre5SettleRank:Refresh(gameplayResult)
    self.TagProtect.gameObject:SetActiveEx(false)
    --self:PlayTweenAnimations(gameplayResult)
    self:RefreshShowOrigin(gameplayResult)
end

function XUiGridTheatre5SettleRank:OnDisable()
    if self._Sequence then
        self._Sequence:Kill()
        self._Sequence = nil
    end
end

---@param gameplayResult XAutoChessGameplayResult
function XUiGridTheatre5SettleRank:RefreshShowOrigin(gameplayResult)
    local isAdds = gameplayResult.ProcessRating > 0
    self.PanelScore.gameObject:SetActiveEx(true)

    self.TxtNumAdd.gameObject:SetActiveEx(isAdds)
    self.TxtNumMinus.gameObject:SetActiveEx(not isAdds)

    self._ShowTxtNum = isAdds and self.TxtNumAdd or self.TxtNumMinus

    local addsRating = gameplayResult.ProcessRating
    local tmpRating = gameplayResult.OldRating

    -- 显示段位积分变化
    if XTool.IsNumberValid(addsRating) then
        self._ShowTxtNum.text = XUiHelper.FormatText(self._Control.PVPControl:GetRatingProcessLabelFromClientConfig(addsRating > 0), math.abs(addsRating))
    else
        self.PanelScore.gameObject:SetActiveEx(false)
        self._ShowTxtNum.gameObject:SetActiveEx(false)
    end

    -- 显示当前段位（未提升前）
    self:_ShowRankStaticByRating(tmpRating)
end

--- 播放动画序列
---@param gameplayResult XAutoChessGameplayResult
function XUiGridTheatre5SettleRank:PlayTweenAnimations(gameplayResult)
    -- 控制只播一次
    if self.IsPlayed then
        return
    else
        self.IsPlayed = true
    end
    
    if self._Sequence then
        self._Sequence:Kill()
        self._Sequence = nil
    end

    self._Sequence = CS.DG.Tweening.DOTween.Sequence()
    local isAdds = gameplayResult.ProcessRating > 0
    self.PanelScore.gameObject:SetActiveEx(true)

    self.TxtNumAdd.gameObject:SetActiveEx(isAdds)
    self.TxtNumMinus.gameObject:SetActiveEx(not isAdds)

    self._ShowTxtNum = isAdds and self.TxtNumAdd or self.TxtNumMinus
    
    local addsRating = gameplayResult.ProcessRating
    local tmpRating = gameplayResult.OldRating

    while XTool.IsNumberValid(addsRating) do
        self:_AddSequenceCb(tmpRating, addsRating)
        
        ---@type XTableTheatre5Rank
        local rankCfg = self._Control.PVPControl:GetPVPRankCfgByRatingScore(tmpRating)

        if addsRating > 0 then
            ---@type XTableTheatre5Rank
            local nextRankCfg = self._Control.PVPControl:GetPVPNextRankCfgByRankId(rankCfg.Id)
            local levelUpNeedScore = nextRankCfg ~= nil and math.max(nextRankCfg.Rating - rankCfg.Rating, 0) or 0
            
            local curVal = nextRankCfg ~= nil and tmpRating - rankCfg.Rating or tmpRating
            local finalVal = curVal + addsRating
            
            if nextRankCfg then
                finalVal = math.min(levelUpNeedScore, finalVal)

                if finalVal == levelUpNeedScore then
                    -- 将要升级
                    --todo 播放升级特效
                    self._Sequence:AppendCallback(function()
                        self.Parent:PlayRankUpSFX()
                    end)
                end
            end
            
            -- 距离下一个段位还需要的积分
            local levelUpLeftVal = XTool.IsNumberValid(levelUpNeedScore) and levelUpNeedScore - curVal or 0
            -- 为了升级而消耗掉的增量
            local levelUsedAdds = (XTool.IsNumberValid(levelUpLeftVal) and addsRating > levelUpLeftVal) and levelUpLeftVal or addsRating

            -- 插值动画时长由数值占比决定
            local animaTime = math.abs(levelUsedAdds / gameplayResult.ProcessRating) * SettleRatingChangedAnimaTotalTime

            self:_AddSequenceNumTo(finalVal, levelUpNeedScore, levelUsedAdds, addsRating, nextRankCfg ~= nil, animaTime)
            
            -- 更新变化后的值
            tmpRating = finalVal + rankCfg.Rating
            addsRating = addsRating - levelUsedAdds
        else
            -- 获取当前段位的积分范围
            local nextRankCfg = self._Control.PVPControl:GetPVPNextRankCfgByRankId(rankCfg.Id)
            local levelUpNeedScore = nextRankCfg ~= nil and math.max(nextRankCfg.Rating - rankCfg.Rating, 0) or 0
            
            ---@type XTableTheatre5Rank
            local lastRankCfg = self._Control.PVPControl:GetPVPLastRankCfgByRankId(rankCfg.Id)
            
            -- 获取处于当前段位下的积分, 用于积分显示，需要区分最高段位时显示总积分的情况
            local curRankRating = nextRankCfg ~= nil and tmpRating - rankCfg.Rating or tmpRating
            
            -- 获取处于当前段位下的积分，用于扣分计算，涉及掉段判定
            local curRankRatingForCheckDown = tmpRating - rankCfg.Rating

            -- 下跌段位而消耗掉的增量，是否大于当前段位拥有的积分，即是否会触发掉段
            local isAddsValMoreThanCurRankRating = curRankRatingForCheckDown < math.abs(addsRating)
            
            -- 获取当前段位下需要扣除的分数，只取未超出的部分
            local levelUsedAdds = not isAddsValMoreThanCurRankRating and addsRating or - curRankRatingForCheckDown

            local finalVal = math.max(curRankRating + levelUsedAdds, 0)

            -- 插值动画时长由数值占比决定
            local animaTime = math.abs(levelUsedAdds / gameplayResult.ProcessRating) * SettleRatingChangedAnimaTotalTime

            self:_AddSequenceNumTo(finalVal, levelUpNeedScore, levelUsedAdds, addsRating, nextRankCfg ~= nil, animaTime)

            -- 更新变化后的值
            tmpRating = tmpRating + levelUsedAdds
            addsRating = addsRating - levelUsedAdds
            
            -- 判定当前积分是否跌落到当前段位最低
            local isMinRatingInCurRank = nextRankCfg ~= nil and finalVal == 0 or finalVal == rankCfg.Rating
            
            -- 进行掉段判定
            -- 如果当前段位下的目标分数到达最低值，且分数变化量还有余量，则可能会掉段
            if isMinRatingInCurRank and addsRating ~= 0 then
                if not lastRankCfg then
                    -- 如果没有上一个段位了，则表示已经是最低段位了，直接清空变化量
                    addsRating = 0
                elseif isAddsValMoreThanCurRankRating then
                    if gameplayResult.IsUsedRankProtect then
                        -- 如果触发了段位保护，则需要清空变化量，并显示对应UI
                        addsRating = 0
                        self._Sequence:AppendCallback(function()
                            self.TagProtect.gameObject:SetActiveEx(true)
                        end)
                    else
                        -- 否则正常掉段，播放相关效果
                        self._Sequence:AppendCallback(function()
                            self:_ShowRankImgAndStarsStaticByCfg(lastRankCfg, rankCfg)
                            --todo: 播放降级特效
                            self.Parent:PlayRankDownSFX()
                        end)
                        -- 手动-1积分表示掉段，否则会始终-0
                        tmpRating = tmpRating - 1
                        addsRating = addsRating + 1
                    end
                end
            end
        end
    end

    self:_AddSequenceCb(gameplayResult.Rating, 0)

end

-- 添加动画序列回调-根据指定的积分和变化量进行显示
function XUiGridTheatre5SettleRank:_AddSequenceCb(rating, adds)
    self._Sequence:AppendCallback(function()
        -- 显示段位积分变化
        if XTool.IsNumberValid(adds) then
            self._ShowTxtNum.text = XUiHelper.FormatText(self._Control.PVPControl:GetRatingProcessLabelFromClientConfig(adds > 0), math.abs(adds))
        else
            self.PanelScore.gameObject:SetActiveEx(false)
            self._ShowTxtNum.gameObject:SetActiveEx(false)
        end

        -- 显示当前段位（未提升前）
        self:_ShowRankStaticByRating(rating)
        
        -- 关闭循环音效
        self.Parent:StopRankChangeSFX()
    end)
end

-- 添加动画序列数字滚动动画
function XUiGridTheatre5SettleRank:_AddSequenceNumTo(finalVal, levelUpNeedScore, usedAdds, adds, hasNextRank, time)
    local isAdds = adds > 0
    local targetAdds = adds - usedAdds
    
    self._Sequence:Append(CS.DG.Tweening.DOTween.To(function()
        self.Parent:PlayRatingChangeSFX(isAdds)
        
        return adds
    end, function(newNum)
        -- 当前值变化
        local curRating = XMath.ToInt(finalVal - newNum + targetAdds)

        if hasNextRank then
            self.ImgBar.fillAmount = curRating / levelUpNeedScore
            self.TxtScore.text = XUiHelper.FormatText(self._Control.PVPControl:GetPVPRankScoreLabelFromClientConfig(), curRating, levelUpNeedScore)
        else
            -- 否则直接显示积分
            self.ImgBar.fillAmount = 1
            self.TxtScore.text = curRating
            self.TxtLegendNum.text = curRating
        end

        -- 增量显示变化
        self._ShowTxtNum.text = XUiHelper.FormatText(self._Control.PVPControl:GetRatingProcessLabelFromClientConfig(isAdds), math.abs(XMath.ToInt(newNum)))
    end, targetAdds, time))
end

--- 显示段位信息
function XUiGridTheatre5SettleRank:_ShowRankStaticByRating(rating)
    ---@type XTableTheatre5Rank
    local rankCfg = self._Control.PVPControl:GetPVPRankCfgByRatingScore(rating)
    ---@type XTableTheatre5Rank
    local nextRankCfg = self._Control.PVPControl:GetPVPNextRankCfgByRankId(rankCfg.Id)

    --设置段位显示
    self:_ShowRankImgAndStarsStaticByCfg(rankCfg, nextRankCfg)

    if nextRankCfg then
        -- 有下一级则显示升级进度
        local levelUpNeedScore = math.max(nextRankCfg.Rating - rankCfg.Rating, 0)
        local overflowScore = math.max(rating - rankCfg.Rating, 0)
        overflowScore = math.min(overflowScore, levelUpNeedScore)

        self.ImgBar.fillAmount = overflowScore / levelUpNeedScore
        self.TxtScore.text = XUiHelper.FormatText(self._Control.PVPControl:GetPVPRankScoreLabelFromClientConfig(), overflowScore, levelUpNeedScore)
    else
        -- 否则直接显示积分
        self.ImgBar.fillAmount = 1
        self.TxtScore.text = rating
        self.TxtLegendNum.text = rating
    end
end

--- 显示段位图标和星级
function XUiGridTheatre5SettleRank:_ShowRankImgAndStarsStaticByCfg(rankCfg, nextRankCfg)
    self.RImgDan:SetRawImage(rankCfg.IconRes)
    self:ShowRankName(true, rankCfg.RankName)
    
    for i, uiObject in ipairs(self.StarGrids) do
        local imgStarOn = uiObject:GetObject('ImgStarOn')

        if imgStarOn then
            imgStarOn.gameObject:SetActiveEx(i <= rankCfg.RankStar)
        end
    end

    local hasNextRank = nextRankCfg and true or false
    self.PanelBar.gameObject:SetActiveEx(hasNextRank)
    self.TxtLegendNum.gameObject:SetActiveEx(not hasNextRank)

    if self.ImgLegendNum then
        self.ImgLegendNum.gameObject:SetActiveEx(not hasNextRank)
    end
    
    self.ListStar.gameObject:SetActiveEx(hasNextRank)
end

--- 检查段位是否发生变化
---@param gameplayResult XAutoChessGameplayResult
function XUiGridTheatre5SettleRank:_CheckRankIsChanged(gameplayResult)
    local oldRating = gameplayResult.Rating - gameplayResult.ProcessRating
    local newRating = gameplayResult.Rating
    
    local oldRankCfg = self._Control.PVPControl:GetPVPRankCfgByRatingScore(oldRating)
    local newRankCfg = self._Control.PVPControl:GetPVPRankCfgByRatingScore(newRating)

    if oldRankCfg and newRankCfg then
        return oldRankCfg.Id ~= newRankCfg.Id
    end
    
    XLog.Error('段位配置不存在:', oldRankCfg, newRankCfg)
    
    return false
end

--- 检查积分是否处于段位起始
---@param gameplayResult XAutoChessGameplayResult
function XUiGridTheatre5SettleRank:_CheckMinRatingInRank(gameplayResult)
    ---@type XTableTheatre5Rank
    local rankCfg = self._Control.PVPControl:GetPVPRankCfgByRatingScore(gameplayResult.Rating)

    if rankCfg then
        return rankCfg.Rating == gameplayResult.Rating
    end

    XLog.Error('段位配置不存在:', rankCfg)

    return false
end

return XUiGridTheatre5SettleRank