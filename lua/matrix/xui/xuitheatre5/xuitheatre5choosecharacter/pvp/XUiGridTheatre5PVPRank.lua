---@class XUiGridTheatre5PVPRank: XUiNode
---@field protected _Control XTheatre5Control
---@field Parent XUiPanelTheatre5CharacterDetail
local XUiGridTheatre5PVPRank = XClass(XUiNode, 'XUiGridTheatre5PVPRank')

function XUiGridTheatre5PVPRank:OnStart(noDetailClick)
    self:InitStars()

    if self.GridBtn and not noDetailClick then
        self.GridBtn:AddEventListener(handler(self, self.OnBtnDetailClickEvent))
    end

    if self.PanelScore then
        self.PanelScore.gameObject:SetActiveEx(false)
    end

    if self.TagProtect then
        self.TagProtect.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre5PVPRank:InitStars()
    self.StarGrids = {}

    for i = 1, 10 do
        local go = self['GridStar'..i]

        if go then
            ---@type UiObject
            local uiObject = go:GetComponent(typeof(CS.UiObject))

            if uiObject then
                table.insert(self.StarGrids, uiObject)
            end
        end
    end
end

function XUiGridTheatre5PVPRank:Refresh(configId, isShowName)
    self.CharaConfigId = configId
    local characterData = self._Control.PVPControl:GetPVPCharacterDataById(configId, true)

    local rating = 0
    
    if characterData then
        rating = characterData.Rating or 0
    end

    self:RefreshByScore(rating, nil, isShowName or false)
end

function XUiGridTheatre5PVPRank:RefreshByScore(rating, notShowProgress, isShowName)
    ---@type XTableTheatre5Rank
    local rankCfg = self._Control.PVPControl:GetPVPRankCfgByRatingScore(rating)
    ---@type XTableTheatre5Rank
    local nextRankCfg = self._Control.PVPControl:GetPVPNextRankCfgByRankId(rankCfg.Id)

    --设置段位显示
    self.RImgDan:SetRawImage(rankCfg.IconRes)
    self:ShowRankName(isShowName or false, rankCfg.RankName)

    for i, uiObject in ipairs(self.StarGrids) do
        local imgStarOn = uiObject:GetObject('ImgStarOn')

        if imgStarOn then
            imgStarOn.gameObject:SetActiveEx(i <= rankCfg.RankStar)
        end
    end
    

    local hasNextRank = nextRankCfg and true or false
    
    if self.PanelBar then
        self.PanelBar.gameObject:SetActiveEx(hasNextRank)
    end

    if self.TxtLegendNum then
        self.TxtLegendNum.gameObject:SetActiveEx(not hasNextRank)
    end

    if self.ImgLegendNum then
        self.ImgLegendNum.gameObject:SetActiveEx(not hasNextRank)
    end

    if self.ListStar then
        self.ListStar.gameObject:SetActiveEx(hasNextRank)
    end

    if notShowProgress then
        -- 不显示积分进度
        if self.PanelBar then
            self.PanelBar.gameObject:SetActiveEx(false)
        end

        if self.TxtLegendNum then
            self.TxtLegendNum.gameObject:SetActiveEx(false)
        end

        if self.ImgLegendNum then
            self.ImgLegendNum.gameObject:SetActiveEx(false)
        end
        
        return
    end

    if nextRankCfg then
        -- 有下一级则显示升级进度
        local levelUpNeedScore = math.max(nextRankCfg.Rating - rankCfg.Rating, 0)
        local overflowScore = math.max(rating - rankCfg.Rating, 0)
        overflowScore = math.min(overflowScore, levelUpNeedScore)

        if self.ImgBar then
            self.ImgBar.fillAmount = overflowScore / levelUpNeedScore
        end

        if self.TxtScore then
            self.TxtScore.text = XUiHelper.FormatText(self._Control.PVPControl:GetPVPRankScoreLabelFromClientConfig(), overflowScore, levelUpNeedScore)
        end
    else
        -- 否则直接显示积分
        if self.ImgBar then
            self.ImgBar.fillAmount = 1
        end
        
        if self.TxtScore then
            self.TxtScore.text = rating
        end

        if self.TxtLegendNum then
            self.TxtLegendNum.text = rating
        end
    end
end

function XUiGridTheatre5PVPRank:ShowRankName(isShow, rankName)
    --if isShow == nil then
    --    isShow = true
    --end
    -- 总是显示段位
    isShow = true
    if self.TxtNameRank then
        self.TxtNameRank.gameObject:SetActiveEx(isShow)

        if isShow then
            self.TxtNameRank.text = rankName
        end
    end
end

function XUiGridTheatre5PVPRank:OnBtnDetailClickEvent()
    XLuaUiManager.Open('UiTheatre5PVPPopupDanDetail', self.CharaConfigId)
end

return XUiGridTheatre5PVPRank