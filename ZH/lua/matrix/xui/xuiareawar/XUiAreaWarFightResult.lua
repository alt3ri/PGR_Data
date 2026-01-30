local handler = handler
local ToInt = XMath.ToInt
--local CsXTextManagerGetText = CsXTextManagerGetText
--local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

---@class XUiAreaWarFightResult
---@field _Control XAreaWarControl
local XUiAreaWarFightResult = XLuaUiManager.Register(XLuaUi, "UiAreaWarFightResult")
local XUiGridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiAreaWarFightResult:OnAwake()
    self:AutoAddListener()
    self.GridRewards = {}
end

function XUiAreaWarFightResult:OnStart(data, closeCb)
    self.WinData = data
    self.CloseCb = closeCb
    self:ConfirmRequest()
    local endTime = XDataCenter.AreaWarManager.GetEndTime()
    self.EndTime = endTime
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
    self.BtnEndExplore.gameObject:SetActiveEx(false)
end

function XUiAreaWarFightResult:OnEnable()
    self:UpdateView()
end

function XUiAreaWarFightResult:OnDestroy()
    self:StopAudio()
    if self.CloseCb then
        self.CloseCb()
    end
    XDataCenter.AntiAddictionManager.EndFightAction()
end

function XUiAreaWarFightResult:UpdateView()
    local info = XDataCenter.AreaWarManager.GetPersonal():GetFightData()
    local isQuest = info.IsQuest
    self.GridScoreInfo1.gameObject:SetActiveEx(not isQuest)
    self.GridScoreInfo2.gameObject:SetActiveEx(not isQuest)
    self.GridScoreInfo3.gameObject:SetActiveEx(not isQuest)
    -- self.AllScore.gameObject:SetActiveEx(not isQuest)
    self.PanelSearch.gameObject:SetActiveEx(isQuest)
    self.TxtConsumeAgain.gameObject:SetActiveEx(not isQuest)
    self.BtnConsumeAgain.gameObject:SetActiveEx(not isQuest)
    self.GridScoreInfo1.transform.parent.gameObject:SetActiveEx(not isQuest)
    if isQuest then
        self:RefreshQuest(info)
    else
        self:RefreshBlock(info)
    end
end

function XUiAreaWarFightResult:RefreshBlock(info)
    local data = self.WinData.SettleData.AreaWarFightResult
    local blockId = XAreaWarConfigs.GetBlockIdByStageId(self.WinData.StageId)
    local fightCount = 1
    if info and info.FightCount then
        fightCount = info.FightCount
    end
    --区块名称
    self.TxtTile.text = XAreaWarConfigs.GetBlockName(blockId)
    self.BtnConsume.gameObject:SetActiveEx(false)
    -- --确认消耗
    -- self.RImgConsume:SetRawImage(XDataCenter.AreaWarManager.GetActionPointItemIcon())
    -- self.TxtConsume.text = XAreaWarConfigs.GetBlockActionPoint(blockId) * fightCount

    self.RImgConsumeAgain:SetRawImage(XDataCenter.AreaWarManager.GetActionPointItemIcon())
    self.TxtConsumeAgain.text = XAreaWarConfigs.GetBlockActionPoint(blockId) * fightCount
    
    self.TxtFightCount.text = fightCount

    -- 播放音效
    self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)

    --根据活动时期决定显示哪些内容
    local isRepeatTime=data.IsRepeatChallenge==1 and true or false
    self.GridScoreInfo1.gameObject:SetActiveEx(not isRepeatTime)
    self.GridScoreInfo2.gameObject:SetActiveEx(not isRepeatTime)
    self.GridScoreInfo3.gameObject:SetActiveEx(true)
    self.Desc.gameObject:SetActiveEx(not isRepeatTime)
    self.BaseScoreDesc.gameObject:SetActiveEx(not isRepeatTime)
    self.Desc2.gameObject:SetActiveEx(isRepeatTime)
    self.TxtHighScore.gameObject:SetActiveEx(not isRepeatTime)
    self.TxtPoint.gameObject:SetActiveEx(not isRepeatTime)

    if isRepeatTime then
        self:ShowReward(fightCount)
    end

    
    local totalScore = data.TotalScore * fightCount
    local totalPurification = data.TotalPurification + totalScore - data.TotalScore
    local damageScore = data.DamageScore * fightCount
    local damageHurt = data.DamageHurt * fightCount
    local baseScore = data.BaseScore * fightCount
    --分数动画
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    XUiHelper.Tween(time, function(f)
                if XTool.UObjIsNil(self.Transform) then
                    return
                end
                if not isRepeatTime then
                    --本次积分
                    self.TxtPoint.text = ToInt(f * totalScore)
                    --累计净化贡献
                    self.TxtHighScore.text = ToInt(f * totalPurification)
                    --伤害积分
                    self.TxtHitScore.text = ToInt(f * damageScore)
                    --伤害量
                    self.TxtHitCombo.text = ToInt(f * damageHurt)
                    --参与积分
                    self.TxtRemainHpScore.text = ToInt(f * baseScore)
                end
                --通关时间
                self.TxtCostTime.text = XUiHelper.GetTime(ToInt(f * data.UseTime))

            end,
            function()
                if XTool.UObjIsNil(self.Transform) then
                    return
                end
                self:StopAudio()
                if not isRepeatTime then
                    self:ShowReward(fightCount)
                end
            end
    )
    
end

function XUiAreaWarFightResult:RefreshQuest(info)
    local data = self.WinData.SettleData.AreaWarFightResult
    --区块名称
    self.TxtTile.text = XMVCA.XFuben:GetStageName(self.WinData.StageId)

    self:ShowQuestReward()
    --分数动画
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        --通关时间
        self.TxtCostTime.text = XUiHelper.GetTime(ToInt(f * data.UseTime))
    end)
end

function XUiAreaWarFightResult:ShowReward(fightCount)
    self.GridAreawarItem.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)

    if not self.Confirm then
        self.RewardShow = true
        return
    end

    fightCount = fightCount or 1
    --奖励物品
    self.RewardGrids = self.RewardGrids or {}
    for index, reward in pairs(self.rewardGoodsList) do
        local grid = self.RewardGrids[index]
        if not grid then
            local gridUi = XUiHelper.Instantiate(self.GridReward, self.PanelRewardContent)
            gridUi.gameObject:SetActiveEx(true)
            grid = XUiGridCommon.New(self,gridUi)
            table.insert(self.RewardGrids, grid)
            grid.BtnClick = gridUi.gameObject:AddComponent(typeof(CS.XUiComponent.XUiButton))
            grid:AutoAddListener()
        end
        grid:Refresh(reward)
        grid:SetUiActive(grid.TxtName, false)
    end

    local isPlayItemAudio = false
    self.AreaItemGrids = self.AreaItemGrids or {}
    for index, reward in pairs(self.areaWarItems) do
        local grid = self.AreaItemGrids[index]
        if not grid then
            local gridUi = XUiHelper.Instantiate(self.GridAreawarItem, self.PanelRewardContent)
            gridUi.gameObject:SetActiveEx(true)
            grid = XUiGridAreaWarItem.New(gridUi, self)
            table.insert(self.AreaItemGrids, grid)
        end
        grid:RefreshItem(reward.ItemId ,reward.Num)
        grid:SetDefaultClickCallBack()

        -- 掉落超过金色品质的道具，播放音效
        local quality = self._Control:GetConfig():GetItemQuality(reward.ItemId)
        if quality > XMVCA.XAreaWar.EnumConst.ITEM_QUALITY.GOLD then
            isPlayItemAudio = true
        end
    end

    if isPlayItemAudio then
        self:PlaySound("awardplus")
    end
end

function XUiAreaWarFightResult:ShowQuestReward()
    for _, grid in pairs(self.GridRewards) do
        grid.GameObject:SetActiveEx(false)
    end
    local data = self.WinData.SettleData.AreaWarFightResult
    --奖励物品
    local rewards = data.RewardGoods
    for index, reward in ipairs(rewards) do
        local grid = self.GridRewards[index]
        if not grid then
            local gridUi = XUiHelper.Instantiate(self.GridReward, self.PanelRewardContent)
            gridUi.gameObject:SetActiveEx(true)
            grid = XUiGridCommon.New(self, gridUi)
            table.insert(self.GridRewards, grid)
            grid.BtnClick = gridUi.gameObject:AddComponent(typeof(CS.XUiComponent.XUiButton))
            grid:AutoAddListener()
        end
        grid:Refresh(reward)
        grid:SetUiActive(grid.TxtName, false)
    end
end

function XUiAreaWarFightResult:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

function XUiAreaWarFightResult:AutoAddListener()
    -- self.BtnExitFight.CallBack = function()
    --     if XDataCenter.AreaWarManager.OnActivityEnd() then
    --         return
    --     end
    --     self:Close()
    -- end
    self.BtnExitFight.CallBack = handler(self, self.OnClickBtnConsume)
    -- self.BtnConsume.CallBack = handler(self, self.OnClickBtnConsume)
    -- self.BtnEndExplore.CallBack = handler(self, self.OnClickBtnConsume)
    self.BtnConsumeAgain.CallBack=handler(self,self.OnClickBtnConsumeAgain)
end

function XUiAreaWarFightResult:OnClickBtnConsume()
    if XDataCenter.AreaWarManager.OnActivityEnd() then
        return
    end
    --self:ShowObtain()
    self:Close()
end

function XUiAreaWarFightResult:OnClickBtnConsumeAgain()
    if XDataCenter.AreaWarManager.OnActivityEnd() then
        return
    end
    local stageId = self.WinData.StageId
    XLuaUiManager.PopThenOpen(
            "UiBattleRoleRoom",
            stageId,
            XDataCenter.AreaWarManager.GetTeam(),
            require("XUi/XUiAreaWar/XUiAreaWarBattleRoleRoom")
    )
    --self:ShowObtain()
end

function XUiAreaWarFightResult:ShowObtain()
    if not XTool.IsTableEmpty(self.rewardGoodsList) or not XTool.IsTableEmpty(self.areaWarItems) then
        XMVCA.XAreaWar:OpenUiAreaWarObtain(self.rewardGoodsList, self.areaWarItems)
    end
end
function XUiAreaWarFightResult:OnCheckActivity(isClose)
    if not isClose then
        return
    end

    XDataCenter.AreaWarManager.OnActivityEnd()
end

function XUiAreaWarFightResult:ConfirmRequest() 
       local stageId = self.WinData.StageId
        local info = XDataCenter.AreaWarManager.GetPersonal():GetFightData()
        local questId = info.IsQuest and info.Id or 0
        local fightCount = info.FightCount
   
        XDataCenter.AreaWarManager.AreaWarConfirmFightResultRequest(
                stageId, questId, fightCount,
                function(rewardGoodsList,areaWarItems)
                    self.rewardGoodsList = rewardGoodsList
                    self.areaWarItems = areaWarItems
                    local info = XDataCenter.AreaWarManager.GetPersonal():GetFightData()
                    self.Confirm = true
                    if self.RewardShow == true and info and info.FightCount then
                        fightCount = info.FightCount
                        self:ShowReward(fightCount)
                    end
                end
        )
end

-- 播放音效
function XUiAreaWarFightResult:PlaySound(name)
    self.AudioPlayer = self.AudioPlayer or self.Transform:GetComponent(typeof(CS.XAudioObjectPlayer))
    if self.AudioPlayer then
        self.AudioPlayer:PlayByKeyName(name)
    end
end

return XUiAreaWarFightResult
