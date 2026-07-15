local XDlcActivityAgency = require("XModule/XBase/XDlcActivityAgency")
local XDlcRelinkRoom = require("XModule/XDlcRelink/XEntity/XDlcRelinkRoom")
local XDlcRelinkWorldFight = require("XModule/XDlcRelink/XEntity/XDlcRelinkWorldFight")
---@class XDlcRelinkAgency : XDlcActivityAgency
---@field private _Model XDlcRelinkModel
local XDlcRelinkAgency = XClass(XDlcActivityAgency, "XDlcRelinkAgency")
function XDlcRelinkAgency:OnInit()
    --初始化一些变量
    self._IsWorldLaunched = false
    self:DlcRegisterActivity()
end

function XDlcRelinkAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyDlcRelinkData = handler(self, self.NotifyDlcRelinkData)
    XRpc.NotifyDlcRelinkNewEquip = handler(self, self.NotifyDlcRelinkNewEquip)
    XRpc.NotifyDlcRelinkRemoveEquip = handler(self, self.NotifyDlcRelinkRemoveEquip)
    XRpc.NotifyDlcRelinkEquipPreset = handler(self, self.NotifyDlcRelinkEquipPreset)
    XRpc.NotifyDlcRelinkCharacterData = handler(self, self.NotifyDlcRelinkCharacterData)
    XRpc.NotifyDlcRelinkDailyReset = handler(self, self.NotifyDlcRelinkDailyReset)
    XRpc.DlcRelinkLikeNotify = handler(self, self.DlcRelinkLikeNotify)
end

function XDlcRelinkAgency:InitEvent()
    XMVCA.XDlcHelper:AddDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.Relink, self)
end

function XDlcRelinkAgency:RemoveEvent()
    XMVCA.XDlcHelper:RemoveDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.Relink, self)
end

--region 服务端信息更新

--- 更新活动数据
function XDlcRelinkAgency:NotifyDlcRelinkData(data)
    if not data or not data.DlcRelinkData then
        return
    end
    -- 结算数据记录
    if data.IsSettleFuben then
        local level = data.DlcRelinkData.Level or 0
        local exp = data.DlcRelinkData.Exp or 0
        self._Model:RecordSettlementLevelAndExp(level, exp)
    end
    self._Model:NotifyActivityData(data.DlcRelinkData)
end

--- 新增装备数据
function XDlcRelinkAgency:NotifyDlcRelinkNewEquip(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    for _, v in pairs(data.EquipDatas) do
        self._Model.ActivityData:AddEquipsData(v)
    end
end

--- 删除装备数据
function XDlcRelinkAgency:NotifyDlcRelinkRemoveEquip(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    for _, v in pairs(data.EquipUids) do
        self._Model.ActivityData:RemoveEquipsData(v)
    end
end

--- 装备预设同步（全量）
function XDlcRelinkAgency:NotifyDlcRelinkEquipPreset(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    self._Model.ActivityData:SetEquipPresetSets(data.EquipPresetSets)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_SYNC_EQUIP_PRESET)
end

--- 角色数据同步
function XDlcRelinkAgency:NotifyDlcRelinkCharacterData(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    for _, v in pairs(data.Character) do
        self._Model.ActivityData:AddCharacters(v)
    end
end

--- 每日重置通知
function XDlcRelinkAgency:NotifyDlcRelinkDailyReset(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    self._Model.ActivityData:SetDailySign(data.DailySign)
    self._Model.ActivityData:SetGlobalMatchRewardTimes(data.GlobalMatchRewardTimes)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_DAILY_RESET)
end

--- 点赞通知
function XDlcRelinkAgency:DlcRelinkLikeNotify(data)
    if not data then
        return
    end
    self._Model:AddLikeInfoCache(data.FromPlayerId, data.TargetPlayerId)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_LIKE_NOTIFY, data.FromPlayerId, data.TargetPlayerId)
end

--endregion

--region 通用

function XDlcRelinkAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DlcRelink, false, noTips) then
        return false
    end
    if not self._Model.ActivityData or not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipText('CommonActivityNotStart')
        end
        return false
    end
    return true
end

function XDlcRelinkAgency:OpenMainUi()
    if not self:GetIsOpen() then
        return false
    end

    -- 玩法重连检查
    XMVCA.XDlcRoom:ReqPreCheckReconnect(self:DlcGetWorldType(), function()
        -- 重连处理
        if XMVCA.XDlcWorld:OnReconnectFight() then
            return
        end

        local loadingType = self._Model:GetClientConfig("RoomUiLoadingType", 1)
        XLuaUiManager.Open("UiLoading", loadingType)
        XScheduleManager.ScheduleOnce(function()
            -- TODO 战斗初始化，先临时放在这里，后续等战斗那边优化后在调整。
            XMVCA.XDlcRelink:DlcInitFight()
            XLuaUiManager.Open("UiDlcRelinkRoom")
            XLuaUiManager.Remove("UiLoading")
        end, 2000)
    end)
    return true
end

--endregion

--region Dlc

function XDlcRelinkAgency:DlcGetRoomProxy()
    return XDlcRelinkRoom.New()
end

function XDlcRelinkAgency:DlcGetFightEvent()
    return XDlcRelinkWorldFight.New()
end

function XDlcRelinkAgency:DlcGetWorldType()
    return XEnumConst.DlcWorld.WorldType.Relink
end

function XDlcRelinkAgency:DlcCheckActivityInTime()
    return self:ExCheckInTime()
end

function XDlcRelinkAgency:DlcReconnect()
    local title = XUiHelper.GetText("TipTitle")
    local message = XUiHelper.GetText("OnlineInstanceReconnect")

    XUiManager.DialogTip(title, message, XUiManager.DialogType.Normal, function()
        XMVCA.XDlcRoom:CancelReconnectToWorld()
    end, function()
        self:DlcInitFight()
        XMVCA.XDlcRoom:ReconnectToWorld()
    end)
end

--- 打开邀请UI
---@param inviteData XChatData 邀请数据
function XDlcRelinkAgency:DlcOpenInviteUi(inviteData)
    if self:DlcCheckInInviteRoom(inviteData.Content) then
        XLog.Debug("已在邀请的房间内，无需再次打开邀请界面")
        return
    end
    XLuaUiManager.Open("UiDlcRelinkPopupInvitation", inviteData)
end

--- 检查是否已在邀请的房间内
---@param content string 邀请内容
---@return boolean
function XDlcRelinkAgency:DlcCheckInInviteRoom(content)
    local params = XChatData.DecodeRoomMsg(content)
    if not params then
        return false
    end

    if not XMVCA.XDlcRoom:IsInRoom() then
        return false
    end

    local roomData = XMVCA.XDlcRoom:GetRoomData()
    if not roomData then
        return false
    end

    local worldId = tonumber(params[3])
    local roomId = params[4]
    local levelId = tonumber(params[8])
    if roomData:GetWorldId() == worldId and roomData:GetId() == roomId and roomData:GetLevelId() == levelId then
        return true
    end
    return false
end

--- 检测邀请UI是否打开
function XDlcRelinkAgency:DlcCheckInviteUiShow()
    return XLuaUiManager.IsUiShow("UiDlcRelinkPopupInvitation")
end

--- 自定义进入条件检测
function XDlcRelinkAgency:DlcCheckCustomEnterCondition(roomId, nodeId, worldId, levelId, createTime)
    -- 未完成教学, 跳转到房间并提示
    local teachingLevelId = self._Model:GetTeachingLevelId()
    if XTool.IsNumberValid(teachingLevelId) and not self._Model:IsTutorialPassed() then
        local tipContext = self._Model:GetClientConfig("TeachingNotPassedTips", 1)
        if XLuaUiManager.IsUiShow("UiDlcRelinkRoom") then
            XUiManager.TipMsg(tipContext)
            return false
        end
        self:CommonRunRelinkRoomUiHandle(function()
            XUiManager.TipMsg(tipContext)
        end)
        return false
    end
    return true
end

--- 战斗侧获取角色模型Id
function XDlcRelinkAgency:ExGetDlcModelIdByCharacterData(characterData)
    -- 4.2没有换装需求 暂时不处理
end

--- 战斗侧获取角色头像
---@param worldNpcData XWorldNpcData
---@return string
function XDlcRelinkAgency:GetFightCharHeadIcon(worldNpcData)
    if not worldNpcData then
        return ""
    end
    local character = worldNpcData.Character
    if not character then
        return ""
    end

    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(character.Id).DefaultNpcFashtionId
    return XDataCenter.FashionManager.GetFashionSmallHeadIcon(fashionId)
end

--endregion

--region 副本扩展入口

function XDlcRelinkAgency:ExCheckInTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

--function XDlcRelinkAgency:ExGetChapterType()
--    return XEnumConst.FuBen.ChapterType.DlcRelink
--end

function XDlcRelinkAgency:ExGetProgressTip()
    local passCount, totalCount = self:GetLevelPassProgress()
    local progressStr = string.format("%d/%d", passCount, totalCount)
    local progressTip = self._Model:GetClientConfig("LevelPassProgressTip", 1)
    return string.format(progressTip, progressStr)
end

function XDlcRelinkAgency:ExCheckIsShowRedPoint()
    if not self:GetIsOpen(true) then
        return false
    end
    if self:CheckAllLevelHasNewUnlock() then
        return true
    end
    if self:CheckAllTaskRedPoint() then
        return true
    end
    return false
end

--endregion

--region 玩法相关

--- 获取关卡通过进度
function XDlcRelinkAgency:GetLevelPassProgress()
    local passCount, totalCount = 0, 0
    local chapterIds = self._Model:GetActivityChapterIds()
    for _, chapterId in pairs(chapterIds) do
        local levelIds = self._Model:GetChapterLevelIds(chapterId)
        for _, levelId in pairs(levelIds) do
            totalCount = totalCount + 1
            if self._Model:CheckLevelPassed(levelId) then
                passCount = passCount + 1
            end
        end
    end
    return passCount, totalCount
end

--- 检查所有关卡是否有新解锁
function XDlcRelinkAgency:CheckAllLevelHasNewUnlock()
    local teachingLevelId = self._Model:GetTeachingLevelId()
    if XTool.IsNumberValid(teachingLevelId) and not self._Model:IsTutorialPassed() then
        return false
    end
    local chapterIds = self._Model:GetActivityChapterIds()
    for _, chapterId in pairs(chapterIds) do
        if self._Model:CheckChapterHasAnyNewLevel(chapterId) then
            return true
        end
    end
    return false
end

--- 检查任务红点 已完成未领取奖励
function XDlcRelinkAgency:CheckAllTaskRedPoint()
    local configs = self._Model:GetShopTaskConfigs()
    if XTool.IsTableEmpty(configs) then
        return false
    end
    for _, config in pairs(configs) do
        if config.Type == XEnumConst.DlcRelink.ShopTaskType.Task then
            local taskTimelineIds = config.ParamId or {}
            for _, taskTimelineId in ipairs(taskTimelineIds) do
                local taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskTimelineId)
                if not XTool.IsTableEmpty(taskDataList) then
                    for _, taskData in ipairs(taskDataList) do
                        if taskData and taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

--endregion

--region 房间逻辑

--- 回到房间界面
function XDlcRelinkAgency:CommonRunRelinkRoomUiHandle(callback)
    local roomUiName = "UiDlcRelinkRoom"
    if XLuaUiManager.IsStackUiOpen(roomUiName) then
        XLuaUiManager.CloseAllUpperUiWithCallback(roomUiName, callback)
    else
        XLuaUiManager.OpenWithCallback(roomUiName, callback)
    end
end

--endregion

--region 埋点相关

---教学关结束时发送教学引导相关的埋点信息
function XDlcRelinkAgency:RecordTeachingLevel(settleData)
    if not settleData or not settleData.ResultData or not settleData.ResultData.WorldData then
        return
    end

    local levelId = settleData.ResultData.WorldData.LevelId
    if levelId ~= self._Model:GetTeachingLevelId() then
        return
    end

    local guideId = tonumber(self._Model:GetClientConfig("TeachingLevelGuideId", 1))
    local state = 0
    if XTool.IsNumberValid(guideId) and XDataCenter.GuideManager.CheckIsGuide(guideId) then
        state = 1
    end
    local dict = {
        guide_id = guideId,
        guide_state = state,
    }
    CS.XRecord.Record(dict, "1000012", "DlcRelinkTeachingLevelGuide")
end

--endregion

--region Condition相关

--- 章节通关次数
---@param chapterId number 章节Id 为 0 表示 任意章节
---@param levelId number 关卡Id 为 0 表示 某章节下的 任意关卡
---@param count number 通关次数
---@return boolean
function XDlcRelinkAgency:CheckChapterPassCount(chapterId, levelId, count)
    if not self._Model.ActivityData then
        return false
    end

    local levelDict = self._Model.ActivityData:GetLevelDict()
    if XTool.IsTableEmpty(levelDict) then
        return false
    end

    local totalPassCount = 0
    for _, levelInfo in pairs(levelDict) do
        local levelCfg = self._Model:GetLevelConfig(levelInfo.Level)
        if levelCfg then
            local isChapterMatch = (chapterId == 0) or (levelCfg.ChapterId == chapterId)
            local isLevelMatch = (levelId == 0) or (levelInfo.Level == levelId)
            if isChapterMatch and isLevelMatch then
                totalPassCount = totalPassCount + levelInfo.PassCount
            end
        end
    end

    return totalPassCount >= count
end

--- 角色研发等级
---@param level number 等级
---@return boolean
function XDlcRelinkAgency:CheckCharacterResearchLevel(level)
    if not self._Model.ActivityData then
        return false
    end

    local playerLevel = self._Model.ActivityData:GetLevel()
    return playerLevel >= level
end

--- 使用指定的角色ID通过关卡X次
---@param characterId number 角色Id
---@param styleType number 角色风格类型 为0 表示任意风格
---@param chapterId number 章节Id 为 0 表示 任意章节
---@param levelId number 关卡Id 为 0 表示 某章节下的 任意关卡
---@param times number 次数
---@return boolean
function XDlcRelinkAgency:CheckUseCharacterPassLevelTimes(characterId, styleType, chapterId, levelId, times)
    if not self._Model.ActivityData then
        return false
    end

    local characterInfo = self._Model.ActivityData:GetCharacterDataByCharacterId(characterId)
    if not characterInfo then
        return false
    end

    local characterPassInfo = characterInfo:GetCharacterStyleTypePassInfoDict()
    if XTool.IsTableEmpty(characterPassInfo) then
        return false
    end

    local totalCount = 0
    for _, passInfo in pairs(characterPassInfo) do
        if styleType == 0 or styleType == passInfo.StyleType then
            local levelAndPassCountDict = passInfo.LevelAndPassCountDict or {}
            for levelIdKey, passCount in pairs(levelAndPassCountDict) do
                local levelCfg = self._Model:GetLevelConfig(levelIdKey)
                if levelCfg then
                    local isChapterMatch = (chapterId == 0) or (levelCfg.ChapterId == chapterId)
                    local isLevelMatch = (levelId == 0) or (levelIdKey == levelId)
                    if isChapterMatch and isLevelMatch then
                        totalCount = totalCount + passCount
                    end
                end
            end
        end
    end

    return totalCount >= times
end

--- 背包界面引导条件检测
--- 1. 研发等级达到指定等级
--- 2. 背包界面已打开并且主槽位有装备
---@param level number 等级
---@return boolean
function XDlcRelinkAgency:CheckBagUiGuideCondition(level)
    if not self._Model.ActivityData then
        return false
    end

    local playerLevel = self._Model.ActivityData:GetLevel()
    if playerLevel < level then
        return false
    end

    ---@type XUiDlcRelinkEquipBag
    local luaUi = XLuaUiManager.GetTopLuaUi("UiDlcRelinkEquipBag")
    if not luaUi then
        return false
    end

    local characterId = luaUi.CharacterId
    local characterInfo = self._Model.ActivityData:GetCharacterDataByCharacterId(characterId)
    if not characterInfo then
        return false
    end

    local equipUid = characterInfo:GetEquipBySlot(XEnumConst.DlcRelink.EquipSlotIndex.MainSlot)
    if XTool.IsNumberValid(equipUid) then
        return true
    end
    return false
end

--- 是否显示网络切换提示
--- 1. 仅在房间界面显示
--- 2. 当前网络为非wifi且之前未弹过提示则显示
---@param isShow boolean 是否显示
---@return boolean
function XDlcRelinkAgency:IsShowNetworkSwitchTip(isShow)
    if not XLuaUiManager.IsUiShow("UiDlcRelinkRoom") then
        return false
    end

    local isWifi = CS.XNetworkReachability.IsViaLocalArea()
    local needPopTip = not isWifi and self._Model:CheckNeedPopWifiTips()
    return isShow == needPopTip
end

--endregion

--region 其他

function XDlcRelinkAgency:InitWorld()
    if self._IsWorldLaunched then
        return
    end
    self._IsWorldLaunched = true
    CS.XWorldEngine.Launch()
end

function XDlcRelinkAgency:DisposeWorld()
    if not self._IsWorldLaunched then
        return
    end
    self._IsWorldLaunched = false
    CS.XWorldEngine.Exit()
end

--endregion

return XDlcRelinkAgency
