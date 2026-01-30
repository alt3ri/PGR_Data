--- 左侧结算进度奖励显示
---@class XUiPanelTheatre5SettleReward: XUiNode
---@field private _Control XTheatre5Control
local XUiPanelTheatre5SettleReward = XClass(XUiNode, 'XUiPanelTheatre5SettleReward')
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridTheatre5SettleRank = require('XUi/XUiTheatre5/XUiTheatre5Settlement/XUiGridTheatre5SettleRank')

---@param resultData XDlcFightSettleData
function XUiPanelTheatre5SettleReward:OnStart(resultData)
    self.ResultData = resultData

    self.UiTheatre5GridDan.gameObject:SetActiveEx(false)
    ---@type XUiGridTheatre5SettleRank
    self.GridRank = XUiGridTheatre5SettleRank.New(self.UiTheatre5GridDan, self)

    self.BtnAgain:AddEventListener(handler(self, self.OnBtnAgainClickEvent))
    self.BtnLeave:AddEventListener(handler(self, self.OnBtnLeaveClickEvent))
    self.BtnPreviousPage:AddEventListener(handler(self, self.OnBtnPreviousPageClickEvent))
     --pve再次挑战是否显示
    local invisible = self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVE and not self._Control.PVEControl:CanAgainBattle(resultData)
    self.BtnAgain.gameObject:SetActiveEx(not invisible)
    self:RefreshShow()
    
    XDataCenter.MedalManager.SetNewNameplateAutoWinLock(false)
end

function XUiPanelTheatre5SettleReward:RefreshShow()
    -- 差异化显示
    local isPVP = self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP
    self.PanelPVP.gameObject:SetActiveEx(isPVP)
    self.PanelPVE.gameObject:SetActiveEx(not isPVP)

    if isPVP then
        self:RefreshPVPRewardShow()
    else
        self:RefreshPVERewardShow()
    end
end

function XUiPanelTheatre5SettleReward:RefreshPVPRewardShow()
     -- 刷新奖励显示
    if not XTool.IsTableEmpty(self.ResultData.RewardGoodsList) then
        self.PanelReward.gameObject:SetActiveEx(true)
        
        XUiHelper.RefreshCustomizedList(self.ListReward.transform, self.Grid256New, #self.ResultData.RewardGoodsList, function(index, go)
            ---@type XUiGridCommon
            local grid = XUiGridCommon.New(self.Parent, go)
            grid:Refresh(self.ResultData.RewardGoodsList[index])
        end)
    else
        self.PanelReward.gameObject:SetActiveEx(false)
    end
    self.GridRank:Open()
    self.GridRank:Refresh(self.ResultData.XAutoChessGameplayResult)
        
    local charaCfg = self._Control:GetCurCharacterCfg()

    if charaCfg then
        self.GridRank:SetCharacterConfigId(charaCfg.Id)
    end
end

function XUiPanelTheatre5SettleReward:ShowRankAnimation()
    self.GridRank:PlayTweenAnimations(self.ResultData.XAutoChessGameplayResult)
end

function XUiPanelTheatre5SettleReward:RefreshPVERewardShow()
    local pveRewardShow = self.ResultData.XAutoChessGameplayResult.RewardShow
    --服务器不发自己构建
    if not pveRewardShow then
        pveRewardShow = 
        {
            TotalCoin = 0,
            IsWin = false,
            BaseRewardCoin = 0,
            FinishLevel = 0,
            LevelRewardCoin = 0,
            HpRewardCoin = 0,
            LeftHp = 0,
            LossRewardFactor = 0,
        }
    end    
    local hasReward = pveRewardShow and pveRewardShow.TotalCoin >= 0 --0也要显示
    self.ListReward.gameObject:SetActiveEx(hasReward)
    self.CoinLayer.gameObject:SetActiveEx(hasReward)
    if hasReward then
        XUiHelper.RefreshCustomizedList(self.ListReward.transform, self.Grid256New, 1, function(index, go)
            ---@type XUiGridCommon
            local grid = XUiGridCommon.New(self.Parent, go)
            local currencyId = XDataCenter.ItemManager.ItemId.Theatre5Coin
            grid:ShowIcon(XDataCenter.ItemManager.GetItemIcon(currencyId))
            grid:ShowCount(true)
            grid:SetCount(pveRewardShow.TotalCoin)
            grid:SetUiActive(grid.ImgQuality, false)
            grid:SetProxyClickFunc(function()
            XLuaUiManager.Open("UiTheatre5PopupRewardDetail", currencyId, XMVCA.XTheatre5.EnumConst.ItemType.Common)
            end)
        end)   

        local goldRewardLayers
        if pveRewardShow.IsWin then
            goldRewardLayers = {pveRewardShow.BaseRewardCoin, 
            pveRewardShow.FinishLevel*pveRewardShow.LevelRewardCoin, pveRewardShow.HpRewardCoin*pveRewardShow.LeftHp}
        else
            local baseCoin = math.floor(pveRewardShow.BaseRewardCoin*pveRewardShow.LossRewardFactor/10000)
            goldRewardLayers = {baseCoin, pveRewardShow.FinishLevel*pveRewardShow.LevelRewardCoin}
        end
        XUiHelper.RefreshCustomizedList(self.ListCoin.transform, self.GridCoin, #goldRewardLayers, function(index, go)
            local grid = XTool.InitUiObjectByUi({}, go)
            --grid.RImgIcon:SetRawImage(currencyCfg.IconRes)
            grid.TxtNum.gameObject:SetActiveEx(false)
            grid.TxtTitle.text = self._Control.PVEControl:GetPveGoldLayerDesc(index)
            grid.TxtScoreNum.text = string.format("+%d", goldRewardLayers[index])
        end)  
    end
    
    local curContentId = self._Control.PVEControl:GetCurRunningNodeStoryLineContentId()  --contentId为空时复刷章节
    local storyLineContentCfg = self._Control.PVEControl:GetStoryLineContentCfg(curContentId, true)
    local isDeduce = storyLineContentCfg and storyLineContentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.DeduceBattle 
        and XTool.IsNumberValid(storyLineContentCfg.NextScript)
    self.PanelClue.gameObject:SetActiveEx(isDeduce)
    if not isDeduce then
        return
    end

    local scriptCfg = self._Control.PVEControl:GetDeduceScriptCfg(storyLineContentCfg.NextScript)
    local clueCfgs = self._Control.PVEControl:GetDeduceClueGroupCfgs(scriptCfg.PreClueGroupId)
    local unLockCount = self._Control.PVEControl:GetUnlockDeduceScriptCount(storyLineContentCfg.NextScript)
    self.TxtNum.text = string.format("%d/%d", unLockCount, #clueCfgs)  

end

function XUiPanelTheatre5SettleReward:OnBtnAgainClickEvent()
    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        XLuaUiManager.PopThenOpen('UiTheatre5ChooseCharacter', self._Control:GetCurPlayingMode())
    else
        --self.Parent:Close()
        XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_WHOLE_BATTLE_AGAIN, self.ResultData)
    end    
end

function XUiPanelTheatre5SettleReward:OnBtnLeaveClickEvent()
    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        self._Control:ReturnTheatre5Main()
    else
        XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_WHOLE_BATTLE_EXIT, self.ResultData)
    end
end

function XUiPanelTheatre5SettleReward:OnBtnPreviousPageClickEvent()
    self.Parent:OnRewardPreEvent()
end

function XUiPanelTheatre5SettleReward:StopRankChangeSFX()
    -- 关闭循环音效
    if self.SFX_PiontUp_Loop then
        self.SFX_PiontUp_Loop.gameObject:SetActiveEx(false)
    end

    if self.SFX_PiontDown_Loop then
        self.SFX_PiontDown_Loop.gameObject:SetActiveEx(false)
    end
end

function XUiPanelTheatre5SettleReward:PlayRatingChangeSFX(isAdd)
    if isAdd then
        if self.SFX_PiontUp_Loop then
            self.SFX_PiontUp_Loop.gameObject:SetActiveEx(false)
            self.SFX_PiontUp_Loop.gameObject:SetActiveEx(true)
        end
    else
        if self.SFX_PiontDown_Loop then
            self.SFX_PiontDown_Loop.gameObject:SetActiveEx(false)
            self.SFX_PiontDown_Loop.gameObject:SetActiveEx(true)
        end
    end
end

function XUiPanelTheatre5SettleReward:PlayRankDownSFX()
    if self.SFX_Star_Down then
        self.SFX_Star_Down.gameObject:SetActiveEx(false)
        self.SFX_Star_Down.gameObject:SetActiveEx(true)
    end
end

function XUiPanelTheatre5SettleReward:PlayRankUpSFX()
    if self.SFX_Star_Up then
        self.SFX_Star_Up.gameObject:SetActiveEx(false)
        self.SFX_Star_Up.gameObject:SetActiveEx(true)
    end
end

return XUiPanelTheatre5SettleReward