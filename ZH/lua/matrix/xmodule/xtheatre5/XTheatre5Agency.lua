local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")

---@class XTheatre5Agency : XFubenActivityAgency
---@field private _Model XTheatre5Model
---@field FlowController XTheatre5FlowController
---@field PVEAgency XTheatre5PVEAgency
local XTheatre5Agency = XClass(XFubenSimulationChallengeAgency, "XTheatre5Agency")

function XTheatre5Agency:OnInit()
    self.EnumConst = require('XModule/XTheatre5/XTheatre5EnumConst')
    self.EventId = require('XModule/XTheatre5/XTheatre5EventId')

    ---@type XTheatre5PVPAgencyCom
    self.PVPCom = require('XModule/XTheatre5/PVP/XTheatre5PVPAgencyCom').New()
    self.PVPCom:Init(self, self._Model)
    self.PVEAgency = require('XModule/XTheatre5/PVE/XTheatre5PVEAgency').New()
    self.PVEAgency:Init(self, self._Model)

    ---@type XTheatre5BattleAgencyCom
    self.BattleCom = require('XModule/XTheatre5/Common/XTheatre5BattleAgencyCom').New()
    self.BattleCom:Init(self, self._Model)

    self:RegisterChapterAgency()

    self._TimerCheckLevelUpdate = nil
    self._TimerCheckInterrupt = nil
end

function XTheatre5Agency:InitRpc()
    XRpc.NotifyTheatre5ActivityData = handler(self, self.OnNotifyTheatre5ActivityData)
    XRpc.NotifyTheatre5UnlockCharacter = handler(self, self.OnNotifyTheatre5UnlockCharacter)
    XRpc.NotifyTheatre5AdventureData = handler(self, self.OnNotifyTheatre5AdventureData)
    XRpc.NotifyTheatre5ShopUpdate = handler(self, self.OnNotifyTheatre5ShopUpdate)
    XRpc.NotifyTheatre5SkillChoiceUpdate = handler(self, self.OnNotifyTheatre5SkillChoiceUpdate)
    XRpc.NotifyPveStoryLineUnlock = handler(self, self.OnNotifyPveStoryLineUnlock)
    XRpc.NotifyTheatre5AddItem = handler(self, self.OnNotifyTheatre5AddItem)
    XRpc.NotifyTheatre5BagDataUpdate = handler(self, self.OnNotifyTheatre5BagDataUpdate)
    XRpc.NotifyTheatre5Effect = handler(self, self.OnNotifyTheatre5Effect)
    XRpc.NotifyTheatre5Mission = handler(self, self.OnNotifyTheatre5Mission)
end

function XTheatre5Agency:InitEvent()
    XMVCA.XDlcHelper:AddDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.AutoChess, self)
end

function XTheatre5Agency:RemoveEvent()

end

function XTheatre5Agency:ResetAll()
    self:ClearDataInGame()
end

function XTheatre5Agency:OnRelease()
    self.PVPCom:Release()
    self.PVPCom = nil
    self.PVEAgency:Release()
    self.PVEAgency = nil
    self.BattleCom:Release()
    self.BattleCom = nil

    self:ClearDataInGame()

    XMVCA.XDlcHelper:RemoveDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.AutoChess, self)

end

function XTheatre5Agency:ClearDataInGame()
    -- 清空定时器相关
    if self._TimerCheckInterrupt then
        XScheduleManager.UnSchedule(self._TimerCheckInterrupt)
        self._TimerCheckInterrupt = nil
    end
    if self._TimerCheckLevelUpdate then
        XScheduleManager.UnSchedule(self._TimerCheckLevelUpdate)
        self._TimerCheckLevelUpdate = nil
    end

    self._LockMissionFinishPop = nil
    self._LockMissionReward = nil
    self._LockMissionChoose = nil
end

--region overrride

function XTheatre5Agency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.Theatre5
end

function XTheatre5Agency:ExOpenMainUi()
    if not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.Theatre5) then
        return false
    end

    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre5, true) then
        if self:ExCheckInTime() and self._Model:GetHasActivityData() then
            self:PlayMainVideo(function()
                XLuaUiManager.Open('UiTheatre5Main')
            end)
            return true
        else
            XUiManager.TipText('CommonActivityNotStart')
        end
    end

    return false
end

function XTheatre5Agency:GetMainVideoId()
    return self._Model:GetTheatre5ConfigValByKey('MainVideoId')
end

function XTheatre5Agency:IsNeedPlayMainVideo()
    local videoId = self:GetMainVideoId()
    if not XTool.IsNumberValid(videoId) then
        return false
    end
    local result = XSaveTool.GetData(string.format("Theatre5_MainVideo_%s", XPlayer.Id))
    if result == true then
        return false
    end
    return true
end

function XTheatre5Agency:PlayMainVideo(cb)
    if self:IsNeedPlayMainVideo() then
        XLuaVideoManager.PlayUiVideo(self:GetMainVideoId(), function()
            XSaveTool.SaveData(string.format("Theatre5_MainVideo_%s", XPlayer.Id), true)
            if cb then
                cb()
            end
        end, true, true)
    else
        if cb then
            cb()
        end
    end
end

--- 通用跳转接口（SkipId）
---@param skipDatas XTable.XTableSkipFunctional
function XTheatre5Agency:ExOnSkip()
    if self:ExOpenMainUi() then
        return true
    end

    return false
end

--endregion

--region ViewModel

--- 是否有限时显示
function XTheatre5Agency:ExCheckInTimerShow()
    local timeId = self:GetPVPActivityTimeId()

    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

--- 限时显示文本
function XTheatre5Agency:ExGetTimerShowStr()
    local timeId = self:GetPVPActivityTimeId()

    if XTool.IsNumberValid(timeId) then
        local now = XTime.GetServerNowTimestamp()
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        local leftTime = math.max(endTime - now, 0)

        return XUiHelper.FormatText(self._Model:GetTheatre5ClientConfigText('EntranceTimeLabel'), XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    else
        return ''
    end
end

--endregion

--region Network - BattleShop

--- 技能三选一
function XTheatre5Agency:RequestTheatre5SkillChoice(instanceId, isEquipped, targetIndex, cb)
    XNetwork.Call("XTheatre5SkillChoiceRequest", { InstanceId = instanceId, IsEquipped = isEquipped, TargetIndex = targetIndex }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            -- 保底同步状态
            if XTool.IsNumberValid(res.Status) then
                self._Model.CurAdventureData:UpdateCurPlayStatus(res.Status)

                if res.Status == XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping then
                    self._Model.CurAdventureData:UpdateFullSkillChoiceData(nil)
                end
            end

            if cb then
                cb(false)
            end

            return
        end

        local newStatus = XTool.IsNumberValid(res.Status) and res.Status or XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping

        self._Model.CurAdventureData:UpdateChooseMissions(res.ChooseMissions)
        self._Model.CurAdventureData:UpdateCurPlayStatus(newStatus, true)
        -- 清空技能三选一数据
        self._Model.CurAdventureData:UpdateFullSkillChoiceData(nil)

        if cb then
            cb(true)
        end
    end)
end

--- 购买背包槽位
function XTheatre5Agency:RequestTheatre5ShopUnlockGridRequest(itemType)
    XNetwork.Call("XTheatre5ShopUnlockGridRequest", { GridType = itemType }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(false)
            end
            return
        end

        self._Model.CurAdventureData:UpdateFullBagData(res.BagData)
        self._Model.CurAdventureData:UpdateGoldNum(res.GoldNum)
        self._Model.CurAdventureData:UpdateIsCanFreeUnlockGrid(res.IsCanFreeUnlockGrid)
        XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_EQUIP_SHOW)
        XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_GOLD_SHOW)
    end)
end

--- 请求进入商店
function XTheatre5Agency:RequestTheatre5EnterShop(cb)
    XNetwork.Call("Theatre5EnterShopRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end
        self._Model.CurAdventureData:UpdateEnterShopCnt(res.EnterShopCnt)
        self._Model.CurAdventureData:UpdateCurPlayStatus(res.Status)
        self._Model.CurAdventureData:UpdateChooseMissions(res.ChooseMissions)

        -- 每回合进商店清空升级次数
        self._Model.CurAdventureData:UpdateMissionLevelUpForRound(0)

        if cb then
            cb(true)
        end
    end)
end

--- 请求购买商品
function XTheatre5Agency:RequestTheatre5ShopBuyItem(instanceId, isEquipped, targetIndex, cb)
    XNetwork.Call("XTheatre5ShopBuyItemRequest", { InstanceId = instanceId, IsEquipped = isEquipped, TargetIndex = targetIndex }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateGoldNum(res.GoldNum)
        self._Model.CurAdventureData:UpdateFullBagData(res.BagData)
        self._Model.CurAdventureData:UpdateFullShopData(res.ShopData)
        self._Model.CurAdventureData:UpdateRuneAutoStrengthenCnt(res.RuneAutoStrengthenCnt)

        if cb then
            cb(true)
        end
    end)
end

--- 请求卖出商品
function XTheatre5Agency:RequestTheatre5ShopSellItem(instanceId, itemType, isEquipped, cb)
    XNetwork.Call("XTheatre5ShopSellItemRequest", { InstanceId = instanceId, IsEquipped = isEquipped, ItemType = itemType }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateGoldNum(res.GoldNum)
        self._Model.CurAdventureData:UpdateFullBagData(res.BagData)
        self._Model.CurAdventureData:UpdateFullShopData(res.ShopData)

        if cb then
            cb(true)
        end
    end)
end

--- 请求刷新商店
function XTheatre5Agency:RequestTheatre5ShopRefresh(cb)
    XNetwork.Call("XTheatre5ShopRefreshRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateFullShopData(res.ShopData)
        self._Model.CurAdventureData:UpdateGoldNum(res.GoldNum)
        self._Model.CurAdventureData:UpdateEffectFreeRefreshCnt(res.UpdateEffectFreeRefreshCnt)

        if cb then
            cb(true)
        end
    end)
end

--- 请求整理背包中物品的位置
function XTheatre5Agency:RequestTheatre5BagItemMove(instanceId, itemType, srcEquipped, srcIndex, srcIsTempItem, targetEquipped, targetIndex, cb)
    local content = {
        InstanceId = instanceId,
        ItemType = itemType,
        SrcEquipped = srcEquipped,
        SrcIndex = srcIndex,
        SrcIsTempItem = srcIsTempItem,
        TargetEquipped = targetEquipped,
        TargetIndex = targetIndex
    }

    XNetwork.Call("XTheatre5BagItemMoveRequest", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateFullBagData(res.BagData)

        if cb then
            cb(true)
        end
    end)
end

--- 请求设置商品冻结状态
function XTheatre5Agency:RequestTheatre5ShopFreeze(instanceId, isFreeze, cb)
    XNetwork.Call("XTheatre5ShopFreezeRequest", { InstanceId = instanceId, IsFreeze = isFreeze }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateFullShopData(res.ShopData)

        if cb then
            cb(true)
        end
    end)
end

function XTheatre5Agency:RequestPveOrPvpChange(cb)
    XNetwork.Call("PveOrPvpChangeRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end
        self._Model:ChangePlayingMode()
        if cb then
            cb(true)
        end
    end)
end

--endregion

--region Network - Fight
function XTheatre5Agency:RequestDlcSingleEnterFight(worldId, levelId, cb)
    XNetwork.Call("DlcSingleEnterFightRequest", { WorldId = worldId, LevelId = levelId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        if cb then
            cb(true, res.WorldData)
        end
    end)
end
--endregion

--region Network - Rpc

function XTheatre5Agency:OnNotifyTheatre5ActivityData(data)
    if XTool.IsTableEmpty(data) then
        self._Model:SetHasActivityData(false)
        return
    end

    local theatre5DataDb = data.Theatre5DataDb

    self._Model:SetHasActivityData(not XTool.IsTableEmpty(data.Theatre5DataDb))
    self._Model:SetActivityId(theatre5DataDb.ActivityId)
    self._Model:SetCurPlayingMode(theatre5DataDb.PvpType)
    self._Model.PVPAdventureData:UpdatePVPAdventureData(theatre5DataDb.PvpAdventureData)
    self._Model.PVPCharacterData:UpdatePVPCharacters(theatre5DataDb.Characters)
    self._Model.PVEAdventureData:UpdatePVEAdventureData(theatre5DataDb.PveAdventureData)

    self._Model.PVPAdventureData:UpdateChooseMissionBounty(theatre5DataDb.PvpChooseMissionBounty)
    self._Model.PVEAdventureData:UpdateChooseMissionBounty(theatre5DataDb.PveChooseMissionBounty)

    --rouge
    self._Model.PVERougeData:UpdatePveCharacters(theatre5DataDb.PveCharacters)
    self._Model.PVERougeData:UpdateCurStoryLineId(theatre5DataDb.CurPveStoryLineId)
    self._Model.PVERougeData:UpdateCurStoryEntranceId(theatre5DataDb.CurStoryEntranceId)
    self._Model.PVERougeData:UpdatePveStoryLines(theatre5DataDb.PveStoryLines)
    self._Model.PVERougeData:UpdatePveClues(theatre5DataDb.PveClues)
    self._Model.PVERougeData:UpdatePveScripts(theatre5DataDb.PveScripts)
    self._Model.PVERougeData:UpdateHistoryChapters(theatre5DataDb.HistoryChapters)

    self._Model:SetCharacterWinGameCountData(theatre5DataDb.CommonFightCnt)
    self._Model:UpdateRelicCollects(theatre5DataDb.RelicCollects)

    self.PVEAgency:AfterActivityDataNotify()
end

function XTheatre5Agency:OnNotifyTheatre5UnlockCharacter(data)
    self._Model.PVPCharacterData:UpdatePVPCharacters(data.PvpCharacters)
    self._Model.PVERougeData:UpdatePveCharacters(data.PveCharacters)
end

function XTheatre5Agency:OnNotifyTheatre5AdventureData(data)
    self._Model.PVPAdventureData:UpdatePVPAdventureData(data.PvpAdventureData)
end

function XTheatre5Agency:OnNotifyTheatre5ShopUpdate(data)
    self._Model.CurAdventureData:UpdateGoldNum(data.GoldNum)
    self._Model.CurAdventureData:UpdateFullShopData(data.ShopData)
    self._Model.CurAdventureData:UpdateFullBagData(data.BagData)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE5_UPDATE_BAG)
end

function XTheatre5Agency:OnNotifyTheatre5SkillChoiceUpdate(data)
    self._Model.CurAdventureData:UpdateGoldNum(data.GoldNum)
    self._Model.CurAdventureData:UpdateFullBagData(data.BagData)
    self._Model.CurAdventureData:UpdateFullSkillChoiceData(data.SkillChoiceData)
end

function XTheatre5Agency:OnNotifyPveStoryLineUnlock(data)
    self._Model.PVERougeData:UpdateUnlockStoryLine(data.PveStoryLines)
end

function XTheatre5Agency:OnNotifyTheatre5AddItem(data)

end

function XTheatre5Agency:OnNotifyTheatre5BagDataUpdate(data)
    self._Model.CurAdventureData:UpdateCurPlayStatus(data.Status)
    self._Model.CurAdventureData:UpdateGoldNum(data.GoldNum)
    self._Model.CurAdventureData:UpdateFullBagData(data.BagData)
end

function XTheatre5Agency:OnNotifyTheatre5Mission(data)
    self._Model.CurAdventureData:UpdateCurMissioning(data.Mission)
    self:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_CUR_MISSION)

    -- 只在商店阶段，可以自由触发
    if self._Model.CurAdventureData:GetCurPlayStatus() == self.EnumConst.PlayStatus.Shopping then
        self:TriggerInterruptEvent()
    end
end
--endregion

--region Network - Characters

function XTheatre5Agency:RequestTheatre5CharacterSkinSet(characterId, fashionId, cb)
    XNetwork.Call('Theatre5CharacterSkinSetRequest', { CharacterId = characterId, FashionId = fashionId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        --todo 角色定义抽取基类
        if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
            self._Model.PVPCharacterData:UpdateCharacterFashionId(characterId, fashionId)
        else

        end

        if cb then
            cb(true)
        end
    end)
end

--endregion

--region Network - Mission

--- 任务选择刷新任务
function XTheatre5Agency:RequestTheatre5MissionFresh(positionId, cb)
    XNetwork.Call("Theatre5MissionFreshRequest", { PositionId = positionId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model.CurAdventureData:UpdateFreshMissionCnt(res.FreshMissionCnt, positionId)
        self._Model.CurAdventureData:UpdateMissionInChoose(positionId, res.FreshMission)

        if cb then
            cb()
        end
    end)
end

--- 选择任务
function XTheatre5Agency:RequestTheatre5MissionChoose(positionId, cb)
    if self._LockMissionChoose then
        return
    end

    self._LockMissionChoose = true

    XNetwork.Call("Theatre5MissionChooseRequest", { PositionId = positionId }, function(res)
        self._LockMissionChoose = false

        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model.CurAdventureData:ClearChooseMissionsAfterEndChoose()
        self._Model.CurAdventureData:UpdateCurMissioning(res.ChooseMission)
        -- 更新已解锁任务客户端缓存
        if res.ChooseMission then
            local bounty = res.ChooseMission.MissionBounty.Bounty
            self._Model.CurAdventureData:AddChooseMissionBounty(bounty)
        end

        self:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_CUR_MISSION)
        if cb then
            cb()
        end
    end)
end

--- 升级任务
function XTheatre5Agency:RequestTheatre5MissionLevelUp(curLevel, cb)
    XNetwork.Call("Theatre5MissionLevelUpRequest", { CurLevel = curLevel }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        -- 刷新数据
        self._Model.CurAdventureData:UpdateCurMissionLevel(res.CurLevel)

        if XTool.IsNumberValidEx(res.CostGoldNum) then
            local newGoldNum = math.max(0, self._Model.CurAdventureData:GetGoldNum() - res.CostGoldNum)
            self._Model.CurAdventureData:UpdateGoldNum(newGoldNum)
        end

        -- 当前回合刷新次数+1
        self._Model.CurAdventureData:UpdateMissionLevelUpForRound(self._Model.CurAdventureData:GetMissionLevelUpForRound() + 1)

        if cb then
            cb()
        end
    end)
end

-- 请求领取任务奖励
function XTheatre5Agency:RequestTheatre5MissionReward(chooseItemId, cb)
    -- 锁定
    if self._LockMissionReward then
        return
    end

    -- 判断任务状态
    local mission = self._Model.CurAdventureData:GetCurMission()

    if not mission or mission.MissionState ~= XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasFinish then
        return
    end

    self._LockMissionReward = true

    XNetwork.Call("Theatre5MissionRewardRequest", { ChooseItemId = chooseItemId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(false)
            end

            self._LockMissionReward = nil
            return
        end

        self._Model.CurAdventureData:UpdateCurMissionState(res.MissionState)
        self._Model.CurAdventureData:UpdateCurMissionGetItemId(chooseItemId)

        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE5_UPDATE_BAG)
        self:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_CUR_MISSION)

        if cb then
            cb(true)
        end

        self._LockMissionReward = nil
    end)
end
--endregion

--region Config - Battle

function XTheatre5Agency:GetTheatre5ItemCfgById(id)
    return self._Model:GetTheatre5ItemCfgById(id)
end

function XTheatre5Agency:GetTheatre5ItemTypeById(id)
    local config = self._Model:GetTheatre5ItemCfgById(id)
    if config then
        return config.Type
    end
end

function XTheatre5Agency:GetTheatre5ItemTagCfgById(id)
    return self._Model:GetTheatre5ItemTagCfgById(id)
end

function XTheatre5Agency:GetTheatre5ItemRuneAttrCfgById(id)
    return self._Model:GetTheatre5ItemRuneAttrCfgById(id)
end

function XTheatre5Agency:GetTheatre5AttrShowCfgByType(type)
    return self._Model:GetTheatre5AttrShowCfgByType(type)
end

function XTheatre5Agency:GetTheatre5ItemKeyWordCfgById(id)
    return self._Model:GetTheatre5ItemKeyWordCfgById(id)
end

--- 宝珠品质颜色配置
function XTheatre5Agency:GetClientConfigGemQualityColor(quality)
    return self._Model:GetClientConfigGemQualityColor(quality)
end
--endregion

--region getData
function XTheatre5Agency:GetCurPlayingMode()
    return self._Model:GetCurPlayingMode()
end

function XTheatre5Agency:GetPVPActivityTimeId()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetTheatre5ActivityCfgById(activityId)

        if cfg then
            return cfg.TimeId
        end
    end
end

function XTheatre5Agency:CheckInPVPActivityTime()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetTheatre5ActivityCfgById(activityId)

        if cfg then
            return XFunctionManager.CheckInTimeByTimeId(cfg.TimeId)
        end
    end

    return false
end

--- 判断指定角色是否达成指定的段位
function XTheatre5Agency:CheckCharacterIsAchieveAimRank(charaId, rankId)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre5, true, true) then
        return false
    end

    -- PVP未开启时默认未达成
    if not self:CheckInPVPActivityTime() then
        return false
    end

    -- 指定段位对应的下限积分
    ---@type XTableTheatre5Rank
    local rankCfg = self._Model:GetTheatre5RankCfgById(rankId)

    if rankCfg then
        if XTool.IsNumberValid(charaId) then
            ---@type XTheatre5PVPCharacter
            local charaData = self._Model.PVPCharacterData:GetPVPCharacterById(charaId)

            if charaData then
                return charaData.Rating >= rankCfg.Rating
            end
        else
            local charaDataList = self._Model.PVPCharacterData:GetPVPCharacters()

            if not XTool.IsTableEmpty(charaDataList) then
                for i, v in pairs(charaDataList) do
                    if v.Rating >= rankCfg.Rating then
                        return true
                    end
                end
            end
        end
    end

    return false
end

--- 判断指定角色的胜利次数是否达到指定值
function XTheatre5Agency:CheckCharacterIsAchieveAimWinFightCount(charaId, winCount)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre5, true, true) then
        return false
    end

    if XTool.IsNumberValid(charaId) then
        return self._Model:GetCharacterWinGameCountById(charaId) >= winCount
    else
        -- 不指定角色时表示所有角色合计胜利次数
        local totalWinCount = 0
        local data = self._Model:GetCharacterWinGameCountData()

        if not XTool.IsTableEmpty(data) then
            for i, v in pairs(data) do
                totalWinCount = totalWinCount + v
            end

            return totalWinCount >= winCount
        end
    end

    return false
end
--endregion

function XTheatre5Agency:TryPopupDialog(title, content, closeCb, sureCb, cancelCb, needDailyIgnoreCheck, dailyIgnoreKey, hideFullClose, hideCancel, showTxtTips, tipContent, tipColor, showEndBtn, endCb, hideSureBtn, showOvertimeBtn, overtimeCb)
    if needDailyIgnoreCheck then
        --todo: 暂无具体需求，先不处理
    end

    XLuaUiManager.Open('UiTheatre5PopupCommon', title, content, closeCb, sureCb, cancelCb, dailyIgnoreKey, hideFullClose, hideCancel, showTxtTips, tipContent, tipColor, showEndBtn, endCb, hideSureBtn, showOvertimeBtn, overtimeCb)
end

function XTheatre5Agency:TryPopupDialogWithOneBtn(title, content, closeCb, sureCb, needDailyIgnoreCheck, dailyIgnoreKey, hideFullClose)
    if needDailyIgnoreCheck then
        --todo: 暂无具体需求，先不处理
    end

    XLuaUiManager.Open('UiTheatre5PopupCommon', title, content, closeCb, sureCb, nil, dailyIgnoreKey, hideFullClose, true)
end

--- 根据玩法自定义的fashionId返回模型Id
function XTheatre5Agency:GetModelIdByFashionId(fashionId)
    local fashionCfg = self._Model:GetTheatre5CharacterFashionCfgById(fashionId)

    if fashionCfg then
        return fashionCfg.DlcModelId
    end
end

--- 根据玩法自定义的fashionId返回头像
function XTheatre5Agency:GetPortraitByFashionId(fashionId)
    local fashionCfg = self._Model:GetTheatre5CharacterFashionCfgById(fashionId)

    if fashionCfg then
        return fashionCfg.Portrait
    end
end

function XTheatre5Agency:ExGetDlcModelIdByCharacterData(characterData)
    local fashionId = characterData.FashionId

    if XTool.IsNumberValid(fashionId) then
        return self:GetModelIdByFashionId(fashionId)
    end
end

function XTheatre5Agency:ExGetDlcPortraitByCharacterIdAndFashionId(templateId, fashionId)
    if not XTool.IsNumberValid(fashionId) then
        local cfg = self._Model:GetTheatre5CharacterCfgById(templateId)

        if cfg then
            fashionId = cfg.FashionIds[XMVCA.XTheatre5.EnumConst.CharacterFashionIndexType.Default]
        end
    end

    if XTool.IsNumberValid(fashionId) then
        return self:GetPortraitByFashionId(fashionId)
    end
end

function XTheatre5Agency:CheckShopConfigCanBuyGoods(shopCfg)
    --商店过期
    if not XFunctionManager.CheckInTimeByTimeId(shopCfg.TimeLimitId) then
        return false
    end
    local currencyCoinId = self:GetActivityCoinInActivity()
    --货币过期
    if not XTool.IsNumberValid(currencyCoinId) then
        return false
    end
    --取消掉打印，防止策划前后端配置不一致，红点每秒检测打印    
    local shopDatas = XShopManager.GetShopGoodsList(shopCfg.ShopId, true)
    if XTool.IsTableEmpty(shopDatas) then
        return false
    end
    for _, shopData in pairs(shopDatas) do
        --还有购买次数
        if shopData.TotalBuyTimes < shopData.BuyTimesLimit then
            --解锁了
            local isLock = false
            for _, v in pairs(shopData.ConditionIds) do
                local ret = XConditionManager.CheckCondition(v)
                if not ret then
                    isLock = true
                    break
                end
            end
            if not isLock then
                for _, priceData in pairs(shopData.ConsumeList) do
                    local itemCount = XDataCenter.ItemManager.GetCount(priceData.Id)
                    --钱够了
                    if itemCount >= priceData.Count then
                        return true
                    end
                end
            end
        end
    end
    return false
end

--限时能对换商品
---@return XTableTheatre5Shop
function XTheatre5Agency:GetLimitShopConfig()
    local limitShopId = self._Model:GetTheatre5ConfigValByKey('Theatre5LimitShop')
    if not XTool.IsNumberValid(limitShopId) then
        return false
    end
    local shopCfg = self._Model:GetTaskOrShopCfg(limitShopId)
    if not shopCfg then
        return false
    end
    return shopCfg
end

function XTheatre5Agency:CheckLimitShopCanBuyGoods()
    local shopCfg = self:GetLimitShopConfig()
    if not shopCfg then
        return false
    end
    return self:CheckShopConfigCanBuyGoods(shopCfg)
end

--获取活动时间内的限时货币
function XTheatre5Agency:GetActivityCoinInActivity()
    local activityId = self._Model:GetActivityId()
    if XTool.IsNumberValid(activityId) then
        local activityCfg = self._Model:GetTheatre5ActivityCfgById(activityId)
        if XFunctionManager.CheckInTimeByTimeId(activityCfg.TimeId) and XTool.IsNumberValid(activityCfg.ActivityCoin) then
            return activityCfg.ActivityCoin
        end
    end
end

--当前是否是教学故事线
function XTheatre5Agency:IsInTeachingStoryLine()
    local teachingStoryLineId = self._Model:GetTheatre5ConfigValByKey('TeachingPveStoryLineId')
    if not XTool.IsNumberValid(teachingStoryLineId) then
        return false
    end

    local curContentId = self._Model.PVERougeData:GetStoryLineContentId(teachingStoryLineId)
    if not curContentId or curContentId > 0 then
        --教学线完成，初始时contentId是nil
        return true
    end
    return false
end


--region 蓝点相关

--- 活动初见未进入的蓝点
function XTheatre5Agency:CheckHasNoEnterReddot()
    return self._Model:CheckHasNoEnterReddot()
end

--- 新赛季开放蓝点
function XTheatre5Agency:CheckHasNewPVPActivityReddot()
    return self._Model:CheckHasNewPVPActivityReddot()
end

function XTheatre5Agency:CheckHasNewPVEActivityReddot()
    return self._Model:CheckHasNewPVEActivityReddot()
end

function XTheatre5Agency:CheckLimitShopReddot()
    return self._Model:CheckLimitShopReddot()
end

function XTheatre5Agency:CheckShopNewGoods()
    local shopConfigs = self._Model:GetTaskOrShopCfgs(XMVCA.XTheatre5.EnumConst.TaskShopType.Shop)
    for i = 1, #shopConfigs do
        local shopConfig = shopConfigs[i]
        if self:CheckShopNewGoodsByShopConfig(shopConfig) then
            return true
        end
    end
    return false
end

-- 有新增的任务
---@param taskCfg XTableTheatre5TaskShop
function XTheatre5Agency:CheckNewTaskByTaskConfig(taskCfg)
    local taskTimeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(taskCfg.TaskTimeLimitId)
    if taskTimeLimitCfg and taskTimeLimitCfg.TaskId then
        for _, taskId in pairs(taskTimeLimitCfg.TaskId) do
            if self._Model:CheckTaskNewReddot(taskId) then
                return true
            end
        end
    end
    return false
end

-- 有新增的商品
---@param taskCfg XTableTheatre5TaskShop
function XTheatre5Agency:CheckShopNewGoodsByShopConfig(shopCfg)
    --商店过期
    if shopCfg.TimeLimitId ~= 0 then
        if not XFunctionManager.CheckInTimeByTimeId(shopCfg.TimeLimitId) then
            return false
        end
    end
    --local currencyCoinId = self:GetActivityCoinInActivity()
    ----货币过期
    --if not XTool.IsNumberValid(currencyCoinId) then
    --    return false
    --end
    --取消掉打印，防止策划前后端配置不一致，红点每秒检测打印    
    local shopDatas = XShopManager.GetShopGoodsList(shopCfg.ShopId, true)
    if XTool.IsTableEmpty(shopDatas) then
        return false
    end
    for _, shopData in pairs(shopDatas) do
        if self._Model:CheckShopNewReddot(shopData.Id) then
            return true
        end
    end
    return false
end

--endregion

---@return XTableTheatre5TaskShop[]
function XTheatre5Agency:GetValidShopOrTaskList(type)
    local validTaskShopCfgs = {}
    local taskShopCfgs = self._Model:GetTaskOrShopCfgs(type)
    if XTool.IsTableEmpty(taskShopCfgs) then
        return validTaskShopCfgs
    end
    for _, taskShopCfg in pairs(taskShopCfgs) do
        if XFunctionManager.CheckInTimeByTimeId(taskShopCfg.TimeLimitId, true) then
            table.insert(validTaskShopCfgs, taskShopCfg)
        end
    end
    return validTaskShopCfgs
end

-- 角色升级
function XTheatre5Agency:XTheatre5CharacterLevelUpRequest()
    if self._TimerCheckLevelUpdate then
        return
    end
    XNetwork.Call("XTheatre5CharacterLevelUpRequest", { }, function(res)
        if self._TimerCheckLevelUpdate then
            XScheduleManager.UnSchedule(self._TimerCheckLevelUpdate)
        end
        self._TimerCheckLevelUpdate = XScheduleManager.ScheduleOnce(function()
            self._TimerCheckLevelUpdate = false
            self:TriggerInterruptEvent()

        end, XScheduleManager.SECOND)

        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.CurAdventureData:UpdateCharacterLevelData(res)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE5_REFRESH_LEVEL_EXP)
    end)
end

-- 刷新饰品
function XTheatre5Agency:XTheatre5RelicRefreshRequest(callback)
    XNetwork.Call("XTheatre5RelicRefreshRequest", { }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.CurAdventureData:UpdateRelicUseRefreshCount(res.UseRefreshCount)
        self._Model.CurAdventureData:UpdateRandomRelics(res.RandomRelics)
        if callback then
            callback()
        end
    end)
end

function XTheatre5Agency:XTheatre5RelicChooseRequest(instanceId, callback)
    XNetwork.Call("XTheatre5RelicChooseRequest", { InstanceId = instanceId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.CurAdventureData:UpdateCurPlayStatus(res.Status)
        self._Model.CurAdventureData:UpdateRelicUseRefreshCount(res.UseRefreshCount)
        self._Model.CurAdventureData:UpdateRandomRelics(res.RandomRelics)
        if res.ChooseRelic then
            self._Model.CurAdventureData:UpdateOneRelic(res.ChooseRelic)
            self._Model:UpdateOneRelicCollect(res.ChooseRelic.ItemId)
            XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_RELIC_UPDATE)
        else
            XLog.Error("[XTheatre5Agency] 获取的已选饰品为空")
        end
        if callback then
            callback()
        end
    end)
end

function XTheatre5Agency:XTheatre5HammerStrengthenRequest(hammerId, runeId, callback)
    XNetwork.Call("XTheatre5HammerStrengthenRequest", { HammerId = hammerId, RuneId = runeId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.CurAdventureData:RemoveItem(res.HammerId, true)
        self._Model.CurAdventureData:UpdateRune(res.Rune)
        if callback then
            callback()
        end
    end)
end

function XTheatre5Agency:XTheatre5BuyExpRequest(exp)
    XNetwork.Call("XTheatre5BuyExpRequest", { Exp = exp }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local buyExp = res.BuyExp
        local exp = self._Model.CurAdventureData:GetCharacterExp()
        self._Model.CurAdventureData:UpdateCharacterExp(exp + buyExp)

        local costGold = res.CostGold
        local gold = self._Model.CurAdventureData:GetGoldNum()
        self._Model.CurAdventureData:UpdateGoldNum(gold - costGold)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE5_REFRESH_LEVEL_EXP)
    end)
end

-- 角色升级，需要客户端主动判断
function XTheatre5Agency:CheckLevelUpdate()
    if self._TimerCheckLevelUpdate then
        return false
    end
    if not XLuaUiManager.IsUiShow("UiTheatre5BattleShop") then
        XLog.Debug("[XTheatre5Agency] 不在商店界面中，不能检查角色升级")
        return false
    end
    if XMVCA.XTheatre5:HasRelicToSelect() then
        XLog.Debug("[XTheatre5Agency] 角色升级，需要选择饰品")
        return false
    end
    local levelConfig = self._Model:GetCharacterLevelConfig(self._Model.CurAdventureData)
    if not levelConfig then
        XLog.Error("[XTheatre5Model] 角色检测升级，但是对应等级的配置数据为空")
        return false
    end
    local nextLevel = self._Model:GetCharacterLevelConfig(self._Model.CurAdventureData, levelConfig.Level + 1)
    if not nextLevel then
        --XLog.Error("[XTheatre5Model] 已经满级")
        return false
    end
    local exp = self._Model.CurAdventureData:GetCharacterExp()
    if exp >= levelConfig.Exp then
        XMVCA.XTheatre5:XTheatre5CharacterLevelUpRequest()
        return true
    end
    return false
end

-- 饰品未选择
function XTheatre5Agency:HasRelicToSelect()
    if self._Model.CurAdventureData then
        if self._Model.CurAdventureData.RandomRelics then
            if #self._Model.CurAdventureData.RandomRelics > 0 then
                return true
            end
        end
    end
    return false
end

-- 任务未选择
function XTheatre5Agency:HasMissionToSelect()
    if self._Model.CurAdventureData then
        return self._Model.CurAdventureData:HasChooseMissions()
    end
end

--- 任务可结算
function XTheatre5Agency:CheckMissionCanGetReward()
    -- 任务只能在商店状态下才能结算
    if self._Model.CurAdventureData:GetCurPlayStatus() ~= XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping then
        return
    end

    local mission = self._Model.CurAdventureData:GetCurMission()

    if mission and mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasFinish then
        if self._LockMissionFinishPop then
            return
        end
        -- 锁住防止弹多次
        self._LockMissionFinishPop = true
        -- 打开选择界面
        if self._Model:CheckMissionHasMultyRewards(mission.MissionBounty.Bounty, mission.MissionBounty.BountyLevel) then
            XLuaUiManager.OpenWithCloseCallback('UiTheatre5PopupTaskSettlement', function()
                XLuaUiManager.OpenWithCloseCallback('UiTheatre5PopupChooseTaskReward', function()
                    self._LockMissionFinishPop = nil
                end, mission)
            end)
        else
            local bountyId = self._Model:GetMissionBountyComboId(mission.MissionBounty.Bounty, mission.MissionBounty.BountyLevel)
            local bountyCfg = self._Model:GetTheatre5MissionBountyCfgById(bountyId)

            if bountyCfg then
                XLuaUiManager.OpenWithCloseCallback('UiTheatre5PopupTaskSettlement', function()
                    self:RequestTheatre5MissionReward(bountyCfg.BountyItem[1], function(success)
                        self._LockMissionFinishPop = nil
                    end)
                end)

            end
        end
    end
end

function XTheatre5Agency:OnNotifyTheatre5Effect(data)
    self._Model.CurAdventureData:UpdateEffectQueue(data.EffectQueue)
    self:HandleEvents()
    -- 只在商店阶段，可以自由触发
    if self._Model.CurAdventureData:GetCurPlayStatus() == self.EnumConst.PlayStatus.Shopping then
        self:TriggerInterruptEvent()
    end
end

-- 服务端下推一堆事件下来，客户端找合适的时机，更新这一切事件
function XTheatre5Agency:HandleEvents()
    self._Model.CurAdventureData:ClearEventData()
    local events = self._Model.CurAdventureData:GetEffectQueue()
    local isSendBagUpdateEvent = false
    for i = 1, #events do
        if self:_HandleEvent(events[i]) then
            isSendBagUpdateEvent = true
        end
    end
    -- 清空
    for i = 1, #events do
        events[i] = nil
    end
    if isSendBagUpdateEvent then
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE5_UPDATE_BAG)
    end
end

---XTheatre5Effect 这个类来自XTheatre5Define
function XTheatre5Agency:_HandleEvent(event)
    -- 进入战斗时获得指定Buff
    if event.Type == self.EnumConst.Theatre5EffectType.AddBuff then
        local data = event.AddBuffResult
        self._Model.CurAdventureData:AddBuff(data.Buffs)
        return
    end
    -- 在指定的RandomGroup中进行一次抽取,抽取时需排除[商店][临时背包][背包][装备中]达到数量上限的商品
    if event.Type == self.EnumConst.Theatre5EffectType.RandomItemGroup then
        local data = event.RandomItemGroupEffectResult
        self._Model.CurAdventureData:HandleBagUpdates(data.UpdateItems)
        return true
    end
    -- 获得指定的道具
    if event.Type == self.EnumConst.Theatre5EffectType.AddItem then
        local data = event.AddItemGroupEffectResult
        self._Model.CurAdventureData:HandleBagUpdate(data.UpdateItem)
        return true
    end
    -- 获得金币.期待可配负值,等同于扣除金币.扣除时最多扣到0.(最终数量=参数1+参数2*参数3)
    if event.Type == self.EnumConst.Theatre5EffectType.ChangeGold then
        local data = event.ChangeGoldResult
        self._Model.CurAdventureData:UpdateGoldNum(data.NewGold)
        return
    end
    -- 获得免费刷新次数(刷新价格固定为0,刷新时不计入已刷新次数)
    if event.Type == self.EnumConst.Theatre5EffectType.AddFreeFreshCnt then
        local data = event.AddFreeShopFreshCntResult
        self._Model.CurAdventureData:UpdateEffectFreeRefreshCnt(data.NewEffectFreeRefreshCnt)
        return
    end
    -- 获得经验
    if event.Type == self.EnumConst.Theatre5EffectType.AddExp then
        local data = event.AddExpResult
        self._Model.CurAdventureData:UpdateCharacterExp(data.NewExp)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE5_REFRESH_LEVEL_EXP)
        return
    end
    -- 随机偷取商店内的符纹(不消耗金币,随机购买)
    if event.Type == self.EnumConst.Theatre5EffectType.RandomStealShopRune then
        local data = event.RandomStealRuneResult
        if data then
            self._Model.CurAdventureData:HandleBagUpdates(data.UpdateItems)
            self._Model.CurAdventureData:SetShopItemBuy(data.UpdateItems)
            return true
        else
            XLog.Error("[XTheatre5Agency] 随机偷取商店内符纹错误")
        end
        return
    end
    -- 将后续x次购买的符纹替换为强化状态的符纹
    if event.Type == self.EnumConst.Theatre5EffectType.AddAutoStrengthenCnt then
        local data = event.AddAutoStrengthenCntResult
        self._Model.CurAdventureData:UpdateRuneAutoStrengthenCnt(data.NewAutoStrengthenCnt)
        return
    end
    -- 进入战斗时获得属性(期待数值和比例可配负值)
    if event.Type == self.EnumConst.Theatre5EffectType.AddAttr then
        local data = event.AddAttrResult
        self._Model.CurAdventureData:AddCharacterAttr(data)
        return
    end
    -- 出售指定位置的符纹(不对技能操作)
    if event.Type == self.EnumConst.Theatre5EffectType.AutoSellRune then
        local data = event.AutoSellRuneResult
        self._Model.CurAdventureData:HandleBagUpdate(data.UpdateItem)
        local gold = self._Model.CurAdventureData:GetGoldNum()
        self._Model.CurAdventureData:UpdateGoldNum(gold + data.SellGold)
        return true
    end
    -- 将指定位置的符纹删除,并根据删除符纹的稀有度抽取对应的RandomGroup(不对技能操作)
    if event.Type == self.EnumConst.Theatre5EffectType.AutoReplaceRune then
        local data = event.AutoRuneReplaceResult
        self._Model.CurAdventureData:HandleBagUpdates(data.UpdateItems)
        return true
    end
    -- 心数增加、减少
    if event.Type == self.EnumConst.Theatre5EffectType.ChangeHp then
        local data = event.ChangeHpEffectResult
        self._Model.CurAdventureData:UpdateHealth(data.NewHp)
        return
    end
    -- 在指定{randomGroup}去重抽取{x}次以替换当前商店货物
    if event.Type == self.EnumConst.Theatre5EffectType.ReplaceShopGoods then
        local data = event.ReplaceShopGoodsResult

        if data then
            local replaceGoods = data.ReplaceShopGoods
            self._Model.CurAdventureData:UpdateShopGoodsByReplaced(replaceGoods)
        end
        return
    end
    XLog.Error("[XTheatre5Agency] 未处理的事件：" .. tostring(event.Type))
end

-- 检查一些事情是否满足条件, 满足条件则触发
-- 但是加在这里，需要担心一些问题，比如 打断了当前流程
function XTheatre5Agency:TriggerInterruptEvent(callback)
    if self._TimerCheckInterrupt then
        return
    end
    -- 延迟一帧检测,避免因为数据更新导致多次请求
    self._TimerCheckInterrupt = XScheduleManager.ScheduleNextFrame(function()
        self._TimerCheckInterrupt = nil
        --print("检查额外流程")

        -- 如果确定是PVP，则执行需要检查时间
        if self:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
            if not self:CheckInPVPActivityTime() then
                return
            end
        end

        -- pvp没有做流程, 只能在商店界面插入
        if XMVCA.XTheatre5:HasRelicToSelect() then
            --print("弹出选择饰品")
            if not XLuaUiManager.IsStackUiOpen("UiTheatre5PVEPopupChooseReward") then
                XLuaUiManager.Open("UiTheatre5PVEPopupChooseReward", XMVCA.XTheatre5.EnumConst.ChooseRewardType.Relic, callback)
            end
            return
        end

        -- 任务相关需要进了商店再弹出
        if XLuaUiManager.IsStackUiOpen('UiTheatre5BattleShop') then
            -- 任务选择
            if self:HasMissionToSelect() then
                if not XLuaUiManager.IsStackUiOpen('UiTheatre5ChooseTask') then
                    XLuaUiManager.OpenWithCloseCallback('UiTheatre5ChooseTask', callback)
                end
            end

            -- 任务结算
            self:CheckMissionCanGetReward()
        end

        -- 自动升级
        if XMVCA.XTheatre5:CheckLevelUpdate() then
            --print("因为自动升级而拦截了解锁")
            return
        end

        -- 自动解锁技能槽
        if not self._Model:HasEnoughExpToAutoUpgrade() then
            self:CheckFreeUnlockRuneSlot()
            return
        end
    end)
end

-- 检查是否可解锁技能槽
function XTheatre5Agency:CheckFreeUnlockRuneSlot()
    if not XLuaUiManager.IsUiShow("UiTheatre5BattleShop") then
        XLog.Debug("[XTheatre5Agency] 不在商店界面中，不能检查解锁格子")
        return false
    end
    if self._Model.CurAdventureData:GetIsCanFreeUnlockGrid() then
        XMVCA.XTheatre5:RequestTheatre5ShopUnlockGridRequest(XMVCA.XTheatre5.EnumConst.ItemType.Equip)
        XLog.Debug("自动解锁技能槽")
        return true
    end
    return false
end

function XTheatre5Agency:GetText(key, ...)
    local text = self._Model:GetTheatre5ClientConfigText(key, 1)
    if not text then
        XLog.Error("[XTheatre5Agency] 获取文本失败：" .. tostring(key))
        return ""
    end
    return XUiHelper.FormatText(text, ...)
end

function XTheatre5Agency:GetClientConfig(key, index, ...)
    local text = self._Model:GetTheatre5ClientConfigText(key, index)
    if not text then
        XLog.Error("[XTheatre5Agency] 获取文本失败：" .. tostring(key))
        return ""
    end
    return XUiHelper.FormatText(text, ...)
end

function XTheatre5Agency:SaveData(data)
    self._Data = data
end

function XTheatre5Agency:GetData()
    return self._Data
end

return XTheatre5Agency
