--- 排行榜中负责处理排行列表和自己排行信息的部分
---@class XUiPanelTheatre5PVPRankList: XUiNode
---@field private _Control XTheatre5Control
local XUiPanelTheatre5PVPRankList = XClass(XUiNode, 'XUiPanelTheatre5PVPRankList')
local XUiGridTheatre5PVPRankItem = require('XUi/XUiTheatre5/XUiTheatre5PVPRank/XUiGridTheatre5PVPRankItem') 

local DynamicAnimaDelayFirstIn = 0.5 -- 初次进入界面时延时播放列表动画

function XUiPanelTheatre5PVPRankList:OnStart()
    ---@type XUiGridTheatre5PVPRankItem
    self.GridSelfRank = XUiGridTheatre5PVPRankItem.New(self.PanelSelfRank, self)
    
    ---@type XDynamicTableNormal
    self.RankDynamicTable = XUiHelper.DynamicTableNormal(self, self.SViewRank, XUiGridTheatre5PVPRankItem)
    
    self._SelfPlayerData = {}

    if self.GridArenaSelfRank then
        self.GridArenaSelfRank.gameObject:SetActiveEx(false)
    end
end

function XUiPanelTheatre5PVPRankList:OnDisable()
    self:_StopDynamicGridAnimation()
end

function XUiPanelTheatre5PVPRankList:_StopDynamicGridAnimation()
    if self.CurAnimationTimerId then
        XScheduleManager.UnSchedule(self.CurAnimationTimerId)
        self.CurAnimationTimerId = nil

        if XLuaUiManager.IsMaskShow() then
            XLuaUiManager.SetMask(false)
        end
    end
end

function XUiPanelTheatre5PVPRankList:RefreshShow(data, characterId)
    local isLimitCharacter = XTool.IsNumberValid(characterId)

    -- 刷新自己的排名
    self._SelfPlayerData.HeadPortraitId = XPlayer.CurrHeadPortraitId
    self._SelfPlayerData.HeadFrameId = XPlayer.CurrHeadFrameId
    self._SelfPlayerData.Name = XPlayer.Name
    self._SelfPlayerData.Id = XPlayer.Id


    local characterData = nil

    if not isLimitCharacter or self._Control.PVPControl:CheckHasPVPCharacterDataById(characterId) then
        characterData = self._Control.PVPControl:GetCharacterDataForRank(characterId)
    end

    if characterData then
        self._SelfPlayerData.Score = characterData.Rating
        self._SelfPlayerData.Theatre5RankCharacterId = characterData.Id
        
        if data.SelfRank <= 100 then
            -- 上榜时，需要判断是否角色同积分，同积分时以上榜角色Id为准
            if self._Control.PVPControl:GetIsCharactersMultyMaxRating() then
                local selfRankData = self:_FindSelfDataFromRankList(data)

                if selfRankData then
                    self._SelfPlayerData.Theatre5RankCharacterId = selfRankData.Theatre5RankCharacterId
                end
            end
        end
    end

    self.GridSelfRank:RefreshShow(data.SelfRank, self._SelfPlayerData, isLimitCharacter)

    if data.SelfRank > 100 then
        self.GridSelfRank:RefreshRankPercentShow(data.SelfRank, data.TotalCount)
    end
    
    -- 显示排行列表
    if not XTool.IsTableEmpty(data.RankPlayerInfos) then
        self.ImgEmpty.gameObject:SetActiveEx(false)
        self.RankDynamicTable.Imp.gameObject:SetActiveEx(true)
        self.RankDynamicTable:SetDataSource(data.RankPlayerInfos)
        self.RankDynamicTable:ReloadDataSync(1)
    else
        self.RankDynamicTable:RecycleAllTableGrid()
        self.RankDynamicTable.Imp.gameObject:SetActiveEx(false)
        self.ImgEmpty.gameObject:SetActiveEx(true)
    end
end

function XUiPanelTheatre5PVPRankList:_FindSelfDataFromRankList(data)
    if data and not XTool.IsTableEmpty(data.RankPlayerInfos) then
        for i, v in pairs(data.RankPlayerInfos) do
            if v.Id == XPlayer.Id then
                return v
            end
        end
    end
end

---@param grid XUiGridTheatre5PVPRankItem
function XUiPanelTheatre5PVPRankList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Open()
        grid:RefreshShow(index, self.RankDynamicTable.DataSource[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()    
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grids = self.RankDynamicTable:GetGrids()
        self.GridCount = XTool.GetTableCount(grids)
        
        self.GridIndex = 1
        
        -- 先隐藏所有
        for i, v in pairs(grids) do
            v:Close()
        end
        
        local item = grids[self.GridIndex]
        if not item then
            return
        end
        
        self:_StopDynamicGridAnimation()

        XLuaUiManager.SetMask(true)
        local interval = self._Control.PVPControl:GetClientConfigRankListGridAnimationInterval()
        
        local delay = not self._IsPlayed and DynamicAnimaDelayFirstIn * XScheduleManager.SECOND or 0 
        
        self.CurAnimationTimerId = XScheduleManager.Schedule(function()
            item = grids[self.GridIndex]
            if item then
                item:Open()
            end
            self.GridIndex = self.GridIndex + 1

            if self.GridIndex > self.GridCount then
                XLuaUiManager.SetMask(false)
                self.CurAnimationTimerId = nil
            end
        end, interval * XScheduleManager.SECOND, self.GridCount, delay)
        
        self._IsPlayed = true
    end
end


return XUiPanelTheatre5PVPRankList