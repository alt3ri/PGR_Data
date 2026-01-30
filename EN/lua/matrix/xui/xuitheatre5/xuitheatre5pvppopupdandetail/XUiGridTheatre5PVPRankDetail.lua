local XUiGridTheatre5PVPRank = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/PVP/XUiGridTheatre5PVPRank')

---@class XUiGridTheatre5PVPRankDetail: XUiGridTheatre5PVPRank
---@field private _Control XTheatre5Control
---@field Parent XUiTheatre5PVPPopupDanDetail
local XUiGridTheatre5PVPRankDetail = XClass(XUiGridTheatre5PVPRank, 'XUiGridTheatre5PVPRankDetail')
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiGridTheatre5PVPRankDetail:OnStart()
    self:InitStars()
end

function XUiGridTheatre5PVPRankDetail:Update()
    
end

function XUiGridTheatre5PVPRankDetail:RefreshShow(majorCfg, charaCfgId, state)
    ---@type XTableTheatre5RankMajor
    self.MajorCfg = majorCfg
    
    self.CharaId = charaCfgId
    
    self:ResetShow()
    
    if state == XMVCA.XTheatre5.EnumConst.RankMajorState.Beyond then
        -- 超出直接显示满星
        self:ShowMaxRank()
    elseif state == XMVCA.XTheatre5.EnumConst.RankMajorState.Below then
        -- 低于则显示0星   
        self:ShowEmptyRank()
    elseif state == XMVCA.XTheatre5.EnumConst.RankMajorState.Belong then
        -- 否则显示当前状态 
        self:ShowCurRankState(charaCfgId)
    end
    
    -- 显示奖励
    self:RefreshReward()
end

function XUiGridTheatre5PVPRankDetail:ShowMaxRank()
    local rankCfg = self._Control.PVPControl:GetPVPRankCfgById(self.MajorCfg.MaxRank)

    if rankCfg then
        self.RImgDan:SetRawImage(rankCfg.IconRes)
        self:ShowRankName(true, rankCfg.RankName)

        for i, uiObject in ipairs(self.StarGrids) do
            local imgStarOn = uiObject:GetObject('ImgStarOn')

            if imgStarOn then
                imgStarOn.gameObject:SetActiveEx(i <= rankCfg.RankStar)
            end
        end
    else
        self:ShowRankName(false)
    end
end

function XUiGridTheatre5PVPRankDetail:ShowEmptyRank()
    local rankCfg = self._Control.PVPControl:GetPVPRankCfgById(self.MajorCfg.MinRank)

    if rankCfg then
        self.RImgDan:SetRawImage(rankCfg.IconRes)
        self:ShowRankName(true, rankCfg.RankName)
        -- 这里显示的是大段位，约定最高小段位独占一个大段位，否则此处逻辑需要调整
        local isMaxRank = self.MajorCfg.MinRank == self.MajorCfg.MaxRank

        self.ListStar.gameObject:SetActiveEx(not isMaxRank)

        if not isMaxRank then
            for i, uiObject in ipairs(self.StarGrids) do
                local imgStarOn = uiObject:GetObject('ImgStarOn')

                if imgStarOn then
                    imgStarOn.gameObject:SetActiveEx(false)
                end
            end
        end
    else
        self:ShowRankName(false)
    end
end

function XUiGridTheatre5PVPRankDetail:ShowCurRankState(charaCfgId)
    self.TagNow.gameObject:SetActiveEx(true)
    
    self:Refresh(charaCfgId, true)
end

function XUiGridTheatre5PVPRankDetail:ResetShow()
    if self.TagNow then
        self.TagNow.gameObject:SetActiveEx(false)
    end
    
    if self.PanelBar then
        self.PanelBar.gameObject:SetActiveEx(false)
    end
    
    if self.ListReward then
        self.ListReward.gameObject:SetActiveEx(false)
    end
    
    if self.PanelScore then
        self.PanelScore.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre5PVPRankDetail:RefreshReward()
    -- 奖励列表缓存
    if self._RewardIdList == nil then
        self._RewardIdList = {}
    elseif not XTool.IsTableEmpty(self._RewardIdList) then
        for i = #self._RewardIdList, 1, -1 do
            self._RewardIdList[i] = nil
        end
    end

    -- 是否获得的缓存
    if self._RewardIsGotList == nil then
        self._RewardIsGotList = {}
    elseif not XTool.IsTableEmpty(self._RewardIsGotList) then
        for i = #self._RewardIsGotList, 1, -1 do
            self._RewardIsGotList[i] = nil
        end
    end

    if not XTool.IsTableEmpty(self._RewardList) then
        for i = #self._RewardList, 1, -1 do
            self._RewardList[i] = nil
        end
    end

    if not XTool.IsTableEmpty(self._RewardGrids) then
        for i, v in pairs(self._RewardGrids) do
            v.GameObject:SetActiveEx(false)
        end
    end
    
    -- 收集所有小段位奖励Id
    for i = self.MajorCfg.MinRank, self.MajorCfg.MaxRank do
        ---@type XTableTheatre5Rank
        local rankCfg = self._Control.PVPControl:GetPVPRankCfgById(i)

        if rankCfg and XTool.IsNumberValid(rankCfg.RewardId) then
            table.insert(self._RewardIdList, rankCfg.RewardId)
            -- 获取奖励获取状态
            table.insert(self._RewardIsGotList, self._Control.PVPControl:CheckCharacterIsGetRankReward(self.CharaId, rankCfg.Id))
        end
    end
    
    -- 显示所有奖励Id
    if not XTool.IsTableEmpty(self._RewardIdList) then
        self.ListReward.gameObject:SetActiveEx(true)
        
        self._RewardList = self._RewardList or {}
        
        for i, rewardId in pairs(self._RewardIdList) do
            local rewardList = XRewardManager.GetRewardList(rewardId)

            for i, v in ipairs(rewardList) do
                v.CustomIsGot = self._RewardIsGotList[i]
                table.insert(self._RewardList, v)
            end
        end

        self._RewardGrids = self._RewardGrids or {}
        
        XUiHelper.RefreshCustomizedList(self.ListReward, self.Grid256New, #self._RewardList, function(index, go)
            local grid = self._RewardGrids[go]

            if not grid then
                grid = XUiGridCommon.New(self.Parent, go)
                self._RewardGrids[go] = grid
            end
            
            grid.GameObject:SetActiveEx(true)
            grid:Refresh(self._RewardList[index])
            
            -- 目前奖励按照大段位设计
            grid:SetReceived(self._RewardList[index].CustomIsGot)
        end)
    end
end

return XUiGridTheatre5PVPRankDetail