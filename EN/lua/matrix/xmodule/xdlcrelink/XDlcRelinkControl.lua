local XDlcRelinkFriend = require("XModule/XDlcRelink/XEntity/XDlcRelinkFriend")
local XDlcRelinkOtherMemberControl = require("XModule/XDlcRelink/SubControl/XDlcRelinkOtherMemberControl")
---@class XDlcRelinkControl : XControl
---@field private _Model XDlcRelinkModel
---@field OtherMemberControl XDlcRelinkOtherMemberControl
local XDlcRelinkControl = XClass(XControl, "XDlcRelinkControl")
function XDlcRelinkControl:OnInit()
    self.OtherMemberControl = self:AddSubControl(XDlcRelinkOtherMemberControl)

    self.RequestName = {
        DlcRelinkSwitchOccupationTypeRequest = "DlcRelinkSwitchOccupationTypeRequest", -- 切换职业
        DlcRelinkSwitchBattleCharacterRequest = "DlcRelinkSwitchBattleCharacterRequest", -- 切换出战角色
        DlcRelinkBuyExpRequest = "DlcRelinkBuyExpRequest", -- 购买经验
        DlcRelinkSignRequest = "DlcRelinkSignRequest", -- 签到
        DlcRelinkSetEmojiWheelRequest = "DlcRelinkSetEmojiWheelRequest", -- 设置表情轮盘
        DlcRelinkEquipAbsorbRequest = "DlcRelinkEquipAbsorbRequest", -- 装备吸收
        DlcRelinkLockEquipRequest = "DlcRelinkLockEquipRequest", -- 装备锁定
        DlcRelinkUnlockEquipRequest = "DlcRelinkUnlockEquipRequest", -- 装备解锁
        DlcRelinkWearEquipRequest = "DlcRelinkWearEquipRequest", -- 穿戴装备
        DlcRelinkUnwearEquipRequest = "DlcRelinkUnwearEquipRequest", -- 卸下装备
        DlcRelinkRecordEquipPresetRequest = "DlcRelinkRecordEquipPresetRequest", -- 记录装备预设
        DlcRelinkDeleteEquipPresetRequest = "DlcRelinkDeleteEquipPresetRequest", -- 删除装备预设
        DlcRelinkUseEquipPresetRequest = "DlcRelinkUseEquipPresetRequest", -- 使用装备预设
        DlcRelinkPinEquipPresetRequest = "DlcRelinkPinEquipPresetRequest", -- 置顶装备预设
        DlcRelinkEquipComposeRequest = "DlcRelinkEquipComposeRequest", -- 装备合成
        DlcRelinkEquipBreakRequest = "DlcRelinkEquipBreakRequest", -- 装备分解
        DlcRelinkEquipRemoveFactorRequest = "DlcRelinkEquipRemoveFactorRequest", -- 装备移除属性
        DlcRelinkQueryRankRequest = "DlcRelinkQueryRankRequest", -- 查询排行榜
    }

    self.FriendCache = nil
    ---@type XDlcRelinkFriend[]
    self.FriendMap = {}
    self.FriendInfoSyncTime = 20
    self.LastFriendInfoSyncTime = 0

    ---@type SelectLevelData
    self.CurSelectLevelData = nil -- 当前选择的等级数据

    ---@type XDlcRelinkQueryRank
    self.QueryRankData = nil -- 排行榜数据

    ---@type table<number, number> key:UiSlotIndex value:EquipSlotIndex
    self.EquipSlotIndexMap = nil -- 装备栏位索引映射
    self.EquipSlotIndexMapMeta = nil -- 装备栏位索引映射元表
end

function XDlcRelinkControl:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MATCH, self.OnBeginMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH, self.OnCancelMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MATCH_SUCCESS, self.OnMatchSuccess, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, self.OnPlayerEnterRoom, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_RECEIVE_INVITE, self.OnReceiveInvite, self)
end

function XDlcRelinkControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MATCH, self.OnBeginMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH, self.OnCancelMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MATCH_SUCCESS, self.OnMatchSuccess, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, self.OnPlayerEnterRoom, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_RECEIVE_INVITE, self.OnReceiveInvite, self)
end

function XDlcRelinkControl:OnRelease()
    self.FriendCache = nil
    self.FriendMap = {}
    self.LastFriendInfoSyncTime = 0
    self.CurSelectLevelData = nil
    self.QueryRankData = nil
    self.EquipSlotIndexMap = nil
    self.EquipSlotIndexMapMeta = nil
end

--- 使用UI栈同步control的卸载
function XDlcRelinkControl:UseUiStackOperationRef()
    return true
end

--region 请求协议相关

--- 切换角色职业
---@param characterId number 角色Id
---@param occupationType number 职业类型
---@param cb function 回调函数
function XDlcRelinkControl:RequestSwitchOccupationType(characterId, occupationType, cb)
    local request = {
        CharacterId = characterId,
        OccupationType = occupationType,
    }
    XNetwork.Call(self.RequestName.DlcRelinkSwitchOccupationTypeRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self._Model.ActivityData:SetCharacterOccupationType(res.CharacterId, res.OccupationType)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_SWITCH_OCCUPATION, res.CharacterId)
        if cb then cb() end
    end)
end

--- 切换出战角色
---@param id number 角色Id
---@param cb function 回调函数
function XDlcRelinkControl:RequestSwitchBattleCharacter(id, cb)
    local request = {
        Id = id,
    }
    XNetwork.Call(self.RequestName.DlcRelinkSwitchBattleCharacterRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self._Model.ActivityData:SetFightCharacterId(res.CharacterId)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_SELECT_CHARACTER, res.CharacterId, XEnumConst.DlcRoom.RoomSelect.Character)
        if cb then cb() end
    end)
end

--- 购买经验
---@param cb function 回调函数
function XDlcRelinkControl:RequestBuyExp(cb)
    XNetwork.Call(self.RequestName.DlcRelinkBuyExpRequest, {}, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        local oldLevel = self:GetCurrentPlayerLevel()
        XLuaUiManager.Open("UiDlcRelinkToastResearchUp", oldLevel, res.CurLevel)
        self._Model.ActivityData:SetLevel(res.CurLevel)
        self._Model.ActivityData:SetExp(res.CurExp)
        if cb then cb() end
    end)
end

--- 签到
---@param cb function 回调函数
function XDlcRelinkControl:RequestSign(cb)
    XNetwork.Call(self.RequestName.DlcRelinkSignRequest, {}, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self._Model.ActivityData:SetDailySign(true)
        if cb then cb(res.DlcRelinkRewardList) end
    end)
end

--- 设置表情轮盘
---@param emojiWheelIds table<number> 表情轮盘Id列表
---@param cb function 回调函数
function XDlcRelinkControl:RequestSetEmojiWheel(emojiWheelIds, cb)
    local request = {
        EmojiWheelIds = emojiWheelIds,
    }
    XNetwork.Call(self.RequestName.DlcRelinkSetEmojiWheelRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self._Model.ActivityData:SetEmojiWheelIds(emojiWheelIds)
        if cb then cb() end
    end)
end

--- 装备吸收
---@param equipUid number 装备Uid
---@param absorbEquipUid number 被吸收的装备Uid
---@param cb function 回调函数
function XDlcRelinkControl:RequestEquipAbsorb(equipUid, absorbEquipUid, cb)
    local request = {
        EquipUid = equipUid,
        AbsorbEquipUid = absorbEquipUid,
    }
    XNetwork.Call(self.RequestName.DlcRelinkEquipAbsorbRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self._Model.ActivityData:AddEquipsData(res.EquipData)
        XLuaUiManager.Open("UiDlcRelinkPopupEquipReformResult", res.NewAttributeSlot)
        if cb then cb() end
    end)
end

--- 装备锁定
---@param equipUid number 装备Uid
---@param cb function 回调函数
function XDlcRelinkControl:RequestLockEquip(equipUid, cb)
    local request = {
        EquipUid = equipUid,
    }
    XNetwork.Call(self.RequestName.DlcRelinkLockEquipRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self._Model.ActivityData:SetEquipIsLocked(equipUid, true)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_EQUIP_LOCK_CHANGE, equipUid)
        if cb then cb() end
    end)
end

--- 装备解锁
---@param equipUid number 装备Uid
---@param cb function 回调函数
function XDlcRelinkControl:RequestUnlockEquip(equipUid, cb)
    local request = {
        EquipUid = equipUid,
    }
    XNetwork.Call(self.RequestName.DlcRelinkUnlockEquipRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self._Model.ActivityData:SetEquipIsLocked(equipUid, false)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_EQUIP_LOCK_CHANGE, equipUid)
        if cb then cb() end
    end)
end

--- 穿戴装备
---@param characterId number 角色Id
---@param equipSlotIndex number 装备栏位索引
---@param equipUid number 装备Uid
---@param cb function 回调函数
function XDlcRelinkControl:RequestWearEquip(characterId, equipSlotIndex, equipUid, cb)
    local request = {
        CharacterId = characterId,
        SlotIndex = equipSlotIndex,
        EquipUid = equipUid,
    }
    XNetwork.Call(self.RequestName.DlcRelinkWearEquipRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

--- 卸下装备
---@param characterId number 角色Id
---@param equipSlotIndex number 装备栏位索引
---@param cb function 回调函数
function XDlcRelinkControl:RequestUnWearEquip(characterId, equipSlotIndex, cb)
    local request = {
        CharacterId = characterId,
        SlotIndex = equipSlotIndex,
    }
    XNetwork.Call(self.RequestName.DlcRelinkUnwearEquipRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self._Model.ActivityData:UnWearEquipByCharacterId(characterId, equipSlotIndex)
        if cb then cb() end
    end)
end

--- 记录装备预设
---@param equipPreset table<number, number> 装备预设
---@param equipPresetId number 预设Id
---@param name string 预设名称
---@param cb function 回调函数
function XDlcRelinkControl:RequestRecordEquipPreset(equipPreset, equipPresetId, name, cb)
    XMessagePack.MarkAsTable(equipPreset)
    local request = {
        EquipPreset = equipPreset,
        EquipPresetId = equipPresetId,
        Name = name,
    }
    XNetwork.Call(self.RequestName.DlcRelinkRecordEquipPresetRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self._Model.ActivityData:SetEquipPresetSetByIndex(equipPresetId, equipPreset, name)
        if cb then cb() end
    end)
end

--- 删除装备预设
---@param equipPresetId number 预设Id
---@param cb function 回调函数
function XDlcRelinkControl:RequestDeleteEquipPreset(equipPresetId, cb)
    local request = {
        EquipPresetId = equipPresetId,
    }
    XNetwork.Call(self.RequestName.DlcRelinkDeleteEquipPresetRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        -- 刷新数据
        if cb then cb() end
    end)
end

--- 使用装备预设
---@param equipPresetId number 预设Id
---@param characterId number 角色Id
---@param cb function 回调函数
function XDlcRelinkControl:RequestUseEquipPreset(equipPresetId, characterId, cb)
    local request = {
        EquipPresetId = equipPresetId,
        CharacterId = characterId,
    }
    XNetwork.Call(self.RequestName.DlcRelinkUseEquipPresetRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_USE_EQUIP_PRESET, characterId)
        if cb then cb() end
    end)
end

--- 置顶装备预设
---@param equipPresetId number 预设Id
---@param cb function 回调函数
function XDlcRelinkControl:RequestPinEquipPreset(equipPresetId, cb)
    local request = {
        EquipPresetId = equipPresetId,
    }
    XNetwork.Call(self.RequestName.DlcRelinkPinEquipPresetRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

--- 装备合成
---@param composeId number 合成Id
---@param count number 合成数量
---@param cb function 回调函数
function XDlcRelinkControl:RequestEquipCompose(composeId, count, cb)
    local request = {
        ComposeId = composeId,
        Count = count,
    }
    XNetwork.Call(self.RequestName.DlcRelinkEquipComposeRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        if cb then cb(res.EquipRewardGoodsList) end
    end)
end

--- 装备分解
---@param equipUidList table<number> 装备Uid列表
---@param cb function 回调函数
function XDlcRelinkControl:RequestEquipBreak(equipUidList, cb)
    local request = {
        EquipUidList = equipUidList,
    }
    XNetwork.Call(self.RequestName.DlcRelinkEquipBreakRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        if cb then cb(res.BreakRewardGoodsList) end
    end)
end

--- 装备移除属性
---@param equipUid number 装备Uid
---@param factorIndex number 属性索引
---@param cb function 回调函数
function XDlcRelinkControl:RequestEquipRemoveFactor(equipUid, factorIndex, cb)
    local request = {
        Uid = equipUid,
        SlotId = factorIndex,
    }
    XNetwork.Call(self.RequestName.DlcRelinkEquipRemoveFactorRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self._Model.ActivityData:AddEquipsData(res.EquipData)
        if cb then cb() end
    end)
end

--- 查询排行榜
---@param levelId number 等级Id
---@param cb function 回调函数
function XDlcRelinkControl:RequestQueryRank(levelId, cb)
    local request = {
        LevelId = levelId,
    }
    XNetwork.Call(self.RequestName.DlcRelinkQueryRankRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self:UpdateQueryRankData(res)
        if cb then cb() end
    end)
end

--endregion

--region 好友相关

--- 打开好友邀请UI
---@param uiName string UI名称
function XDlcRelinkControl:OpenFriendInviteUi(uiName)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialFriend) then
        return
    end

    local nowTime = XTime.GetServerNowTimestamp()
    if self:ShouldRefreshFriendCache(nowTime) then
        self:RefreshFriendCache(uiName)
    else
        XLuaUiManager.Open(uiName, self.FriendCache)
    end
end

--- 检查是否需要刷新好友缓存
---@param nowTime number 当前时间
---@return boolean
function XDlcRelinkControl:ShouldRefreshFriendCache(nowTime)
    return not self.FriendCache or self.LastFriendInfoSyncTime + self.FriendInfoSyncTime <= nowTime
end

--- 刷新好友缓存
---@param uiName string UI名称
function XDlcRelinkControl:RefreshFriendCache(uiName)
    local friendList = XDataCenter.SocialManager.GetFriendList()
    if XTool.IsTableEmpty(friendList) then
        self.FriendCache = {}
        self.FriendMap = {}
        XLuaUiManager.Open(uiName, self.FriendCache)
        return
    end

    local playerIds = {}
    for _, friend in pairs(friendList) do
        table.insert(playerIds, friend.FriendId)
    end
    self:RequestFriendInfoFromServer(playerIds, uiName)
end

--- 从服务器请求好友信息
---@param playerIds table<number> 玩家ID列表
---@param uiName string UI名称
function XDlcRelinkControl:RequestFriendInfoFromServer(playerIds, uiName)
    XDataCenter.SocialManager.GetPlayerInfoListByServer(playerIds, function(friendInfoList)
        self:UpdateFriendCache(friendInfoList)
        XLuaUiManager.Open(uiName, self.FriendCache)
    end)
end

--- 更新好友缓存
---@param friendInfoList table 好友信息列表
function XDlcRelinkControl:UpdateFriendCache(friendInfoList)
    self.FriendCache = {}
    self.LastFriendInfoSyncTime = XTime.GetServerNowTimestamp()

    self:SortFriendList(friendInfoList)

    for i, friendInfo in pairs(friendInfoList) do
        local cache = self.FriendMap[friendInfo.Id]
        if not cache then
            cache = XDlcRelinkFriend.New()
        end
        cache:UpdateFriendData(friendInfo)
        self.FriendCache[i] = cache
        self.FriendMap[friendInfo.Id] = cache
    end
end

--- 排序好友列表
---@param friendInfoList table 好友信息列表
---@return table 排序后的好友信息列表
function XDlcRelinkControl:SortFriendList(friendInfoList)
    if not friendInfoList or #friendInfoList <= 1 then
        return friendInfoList or {}
    end
    table.sort(friendInfoList, function(a, b)
        return self:CompareFriends(a, b)
    end)
    return friendInfoList
end

--- 比较两个好友的排序优先级
---@param friendA table 好友A
---@param friendB table 好友B
---@return boolean
function XDlcRelinkControl:CompareFriends(friendA, friendB)
    -- 在线状态优先
    if friendA.IsOnline ~= friendB.IsOnline then
        return friendA.IsOnline
    end

    if friendA.IsOnline then
        return self:CompareOnlineFriends(friendA, friendB)
    else
        return self:CompareOfflineFriends(friendA, friendB)
    end
end

--- 比较在线好友
---@param friendA table 好友A
---@param friendB table 好友B
---@return boolean
function XDlcRelinkControl:CompareOnlineFriends(friendA, friendB)
    -- 都在线，按亲密度、等级降序
    if friendA.FriendExp ~= friendB.FriendExp then
        return friendA.FriendExp > friendB.FriendExp
    end
    return friendA.Level > friendB.Level
end

--- 比较离线好友
---@param friendA table 好友A
---@param friendB table 好友B
---@return boolean
function XDlcRelinkControl:CompareOfflineFriends(friendA, friendB)
    -- 都不在线，按最后登录时间、亲密度、等级降序
    if friendA.LastLoginTime ~= friendB.LastLoginTime then
        return friendA.LastLoginTime > friendB.LastLoginTime
    end
    if friendA.FriendExp ~= friendB.FriendExp then
        return friendA.FriendExp > friendB.FriendExp
    end
    return friendA.Level > friendB.Level
end

--endregion

--region 当前等级数据相关

--- 设置当前选择的等级数据
---@param chapterId number 章节ID
---@param levelId number 等级ID
function XDlcRelinkControl:SetCurrentSelectLevelData(chapterId, levelId)
    if not XTool.IsNumberValid(chapterId) or not XTool.IsNumberValid(levelId) then
        self.CurSelectLevelData = nil
        return
    end

    if self.CurSelectLevelData and self.CurSelectLevelData.ChapterId == chapterId and self.CurSelectLevelData.LevelId == levelId then
        return
    end

    self.CurSelectLevelData = { ChapterId = chapterId, LevelId = levelId }
end

--- 获取当前选择的章节ID
function XDlcRelinkControl:GetCurrentSelectChapterId()
    if XMVCA.XDlcRoom:IsInRoom() then
        ---@type XDlcRoomData
        local roomData = XMVCA.XDlcRoom:GetRoomData()
        if not roomData then
            return nil
        end
        return self:GetLevelChapterId(roomData:GetLevelId())
    end

    if self.CurSelectLevelData then
        return self.CurSelectLevelData.ChapterId
    end

    local defaultLevelId = self:GetDefaultLevelId()
    if XTool.IsNumberValid(defaultLevelId) then
        return self:GetLevelChapterId(defaultLevelId)
    end
    return 0
end

--- 获取当前选择的等级ID
function XDlcRelinkControl:GetCurrentSelectLevelId()
    if XMVCA.XDlcRoom:IsInRoom() then
        ---@type XDlcRoomData
        local roomData = XMVCA.XDlcRoom:GetRoomData()
        if not roomData then
            return nil
        end
        return roomData:GetLevelId()
    end

    if self.CurSelectLevelData then
        return self.CurSelectLevelData.LevelId
    end

    return self:GetDefaultLevelId()
end

--- 获取默认关卡Id 未通关则返回配置默认关卡Id 否则返回0
function XDlcRelinkControl:GetDefaultLevelId()
    local levelId = tonumber(self:GetClientConfig("DefaultLevelId"))
    if XTool.IsNumberValid(levelId) and not self:CheckLevelPassed(levelId) then
        return levelId
    end
    return 0
end

--endregion

--region 活动表相关

--- 检查每日签到状态
function XDlcRelinkControl:CheckDailySign()
    if not self._Model.ActivityData then
        return false
    end
    return self._Model.ActivityData:GetDailySign()
end

-- 获取活动结束时间
function XDlcRelinkControl:GetActivityEndTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

-- 处理活动结束
function XDlcRelinkControl:HandleActivityEnd()
    XLuaUiManager.RunMain(true)
    self:OpenCommonTipMsg(XUiHelper.GetText("CommonActivityEnd"))
end

-- 获取活动名称
function XDlcRelinkControl:GetActivityName()
    local config = self._Model:GetActivityConfig()
    return config and config.Name or ""
end

-- 获取活动世界Id
function XDlcRelinkControl:GetActivityWorldId()
    local config = self._Model:GetActivityConfig()
    return config and config.WorldId or 0
end

-- 获取表情轮盘最大数量
function XDlcRelinkControl:GetActivityEmojiWheelMaxCount()
    local config = self._Model:GetActivityConfig()
    return config and config.EmojiWheelMaxCount or 0
end

-- 获取活动默认签到Id
function XDlcRelinkControl:GetActivityDefaultSignId()
    local config = self._Model:GetActivityConfig()
    return config and config.DefaultSignId or 0
end

-- 获取出战角色Id列表
function XDlcRelinkControl:GetActivityBattleCharacterIds()
    local config = self._Model:GetActivityConfig()
    return config and config.BattleCharacterIds or {}
end

-- 获取活动章节Id列表
function XDlcRelinkControl:GetActivityChapterIds()
    return self._Model:GetActivityChapterIds()
end

-- 获取视频路径
function XDlcRelinkControl:GetActivityVideoUrl()
    local config = self._Model:GetActivityConfig()
    return config and config.VideoUrl or ""
end

-- 获取提示列表
function XDlcRelinkControl:GetActivityTips()
    local config = self._Model:GetActivityConfig()
    return config and config.Tips or {}
end

--endregion

--region 章节表相关

--- 检测章节是否解锁
function XDlcRelinkControl:CheckChapterUnlock(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return false
    end

    local timeId = self:GetChapterTimeId(chapterId)
    if timeId > 0 and not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false
    end

    local conditionIds = self:GetChapterConditionIds(chapterId)
    for _, conditionId in ipairs(conditionIds) do
        if conditionId > 0 and not XConditionManager.CheckCondition(conditionId) then
            return false
        end
    end
    return true
end

--- 检测章节是否通关
function XDlcRelinkControl:CheckChapterPassed(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return false
    end

    local levelIds = self:GetChapterLevelIds(chapterId)
    if XTool.IsTableEmpty(levelIds) then
        return false
    end

    for _, levelId in ipairs(levelIds) do
        if not self:CheckLevelPassed(levelId) then
            return false
        end
    end
    return true
end

--- 获取章节解锁条件描述
function XDlcRelinkControl:GetChapterUnlockDesc(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return ""
    end

    local timeId = self:GetChapterTimeId(chapterId)
    if timeId > 0 and not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return string.format(self:GetClientConfig("ChapterNotOpenDesc"), self:GetChapterName(chapterId))
    end
    return self:GetChapterConditionDesc(chapterId)
end

--- 获取章节条件描述
function XDlcRelinkControl:GetChapterConditionDesc(chapterId)
    local conditionIds = self:GetChapterConditionIds(chapterId)
    if XTool.IsTableEmpty(conditionIds) then
        return ""
    end

    for _, conditionId in ipairs(conditionIds) do
        if conditionId > 0 then
            local isOpen, desc = XConditionManager.CheckCondition(conditionId)
            if not isOpen then
                return desc or ""
            end
        end
    end
    return ""
end

--- 获取最后一个解锁未通过的章节Id
function XDlcRelinkControl:GetLastUnlockedChapterId()
    local chapterIds = self:GetActivityChapterIds()
    if XTool.IsTableEmpty(chapterIds) then
        return 0
    end

    local lastChapterId = 0
    for _, chapterId in ipairs(chapterIds) do
        if self:CheckChapterUnlock(chapterId) then
            if not self:CheckChapterPassed(chapterId) then
                return chapterId
            end
            lastChapterId = chapterId
        end
    end

    return lastChapterId
end

function XDlcRelinkControl:GetChapterTimeId(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.TimeId or 0
end

function XDlcRelinkControl:GetChapterConditionIds(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.Condition or {}
end

function XDlcRelinkControl:GetChapterLevelIds(chapterId)
    return self._Model:GetChapterLevelIds(chapterId)
end

function XDlcRelinkControl:GetChapterName(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetChapterIcon(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.Icon or ""
end

function XDlcRelinkControl:GetChapterRoomIcon(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.RoomIcon or ""
end

function XDlcRelinkControl:GetChapterSkills(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.Skills or {}
end

function XDlcRelinkControl:GetChapterOdSkills(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.OdSkills or {}
end

function XDlcRelinkControl:GetChapterTrueOccupations(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.TrueOccupations or {}
end

--endregion

--region 角色表相关

function XDlcRelinkControl:GetFightCharacterId()
    if not self._Model.ActivityData then
        return 0
    end
    return self._Model.ActivityData:GetFightCharacterId()
end

function XDlcRelinkControl:GetCharacterDataList()
    if not self._Model.ActivityData then
        return {}
    end
    return self._Model.ActivityData:GetCharacterDataList()
end

--- 获取角色数据
function XDlcRelinkControl:GetCharacterDataByCharacterId(characterId)
    if not self._Model.ActivityData then
        return nil
    end
    return self._Model.ActivityData:GetCharacterDataByCharacterId(characterId)
end

--- 获取所有角色Id列表
function XDlcRelinkControl:GetCharacterIdList()
    local charactersData = self:GetCharacterDataList()
    if XTool.IsTableEmpty(charactersData) then
        return {}
    end

    local characterIds = {}
    for _, character in pairs(charactersData) do
        table.insert(characterIds, character:GetCharacterId())
    end
    return characterIds
end

--- 获取角色已穿戴的装备Uid列表
function XDlcRelinkControl:GetWearEquipUidsByCharacterId(characterId)
    local characterData = self:GetCharacterDataByCharacterId(characterId)
    if not characterData then
        return {}
    end
    return characterData:GetEquip()
end

--- 获取所有已穿戴的装备Uid列表
function XDlcRelinkControl:GetAllWearEquipUids()
    local charactersDataList = self:GetCharacterDataList()
    if XTool.IsTableEmpty(charactersDataList) then
        return {}
    end

    local equipUids = {}
    for _, character in pairs(charactersDataList) do
        for _, equipUid in pairs(character:GetEquip()) do
            if XTool.IsNumberValid(equipUid) then
                table.insert(equipUids, equipUid)
            end
        end
    end
    return equipUids
end

--- 获取角色职业类型
function XDlcRelinkControl:GetOccupationTypeByCharacterId(characterId, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetOccupationType()
    end
    local characterData = self:GetCharacterDataByCharacterId(characterId)
    if not characterData then
        return 0
    end
    return characterData:GetOccupationType()
end

--- 获取角色属性列表
---@param characterId number 角色Id
---@param isNotSelf boolean 是否非自己角色（默认为false）
---@return table<string, number> key: 属性名 value: 属性值
function XDlcRelinkControl:GetCharacterAttributesByCharacterId(characterId, isNotSelf)
    if not XTool.IsNumberValid(characterId) then
        return {}
    end

    local occupationType = self:GetOccupationTypeByCharacterId(characterId, isNotSelf)
    local npcId = self:GetCharacterNpcId(characterId, occupationType)
    if not XTool.IsNumberValid(npcId) then
        return {}
    end

    local template = CS.StatusSyncFight.XNpcConfig.GetTemplate(npcId)
    if not template or not XTool.IsNumberValid(template.AttribId) then
        return {}
    end

    local attribConfig = XMVCA.XDlcWorld:GetAttributeConfigById(template.AttribId)
    if not attribConfig then
        return {}
    end

    local attributes = {}
    local enlargedAttribs = XMVCA.XDlcRelink:DlcGetEnlargedAttribs() or {}

    for attrStr, attrValue in pairs(attribConfig) do
        local attribId = XDlcNpcAttribType[attrStr]
        if attribId and XTool.IsNumberValid(attrValue) then
            local value = enlargedAttribs[attribId] and attrValue * 1000 or attrValue
            attributes[attrStr] = math.floor(value + 0.5)
        end
    end

    return attributes
end

--- 获取角色配置列表
---@param characterId number 角色Id
---@return table<number, XTableDlcRelinkCharacter> key: occupationType value: 角色配置
function XDlcRelinkControl:GetCharacterConfigs(characterId)
    if not XTool.IsNumberValid(characterId) then
        return {}
    end

    local configs = {}
    for _, occupationType in pairs(XEnumConst.DlcRelink.OccTypeEnum) do
        local configId = self:GetCharacterConfigId(characterId, occupationType)
        local config = self._Model:GetCharacterConfig(configId, true)
        if config then
            configs[occupationType] = config
        end
    end
    return configs
end

--- 获取角色技能Id列表
---@param characterId number 角色Id
---@param occupationType number 职业类型
---@param isNotSelf boolean 是否非自己角色（默认为false）
---@return table<number> 技能Id列表
function XDlcRelinkControl:GetCharacterSkillIdsByCharacterId(characterId, occupationType, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetCharacterSkillIdsByCharacterId(characterId, occupationType)
    end

    local skillIds = self:GetCharacterSkillIds(characterId, occupationType)
    if XTool.IsTableEmpty(skillIds) then
        return {}
    end

    local equipUids = self:GetWearEquipUidsByCharacterId(characterId)
    local mainEquipUid = equipUids[XEnumConst.DlcRelink.EquipSlotIndex.MainSlot]
    if not XTool.IsNumberValid(mainEquipUid) then
        return skillIds
    end

    local attribute = self:GetEquipMainFactorByUid(mainEquipUid, true)
    if not attribute or not XTool.IsNumberValid(attribute.FactorId) or not XTool.IsNumberValid(attribute.Level) then
        return skillIds
    end

    local affectedSkillId = self:GetFactorAffectedSkillId(attribute.FactorId, attribute.Level)
    local newSkillId = self:GetFactorNewSkillId(attribute.FactorId, attribute.Level)
    if not XTool.IsNumberValid(affectedSkillId) or not XTool.IsNumberValid(newSkillId) then
        return skillIds
    end

    for i, skillId in ipairs(skillIds) do
        if skillId == affectedSkillId then
            skillIds[i] = newSkillId
            break
        end
    end
    return skillIds
end

--- 检查角色职业是否已解锁
function XDlcRelinkControl:CheckCharacterOccupationUnlock(characterId, occupationType)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(occupationType) then
        return false
    end

    local conditionIds = self:GetCharacterConditionIds(characterId, occupationType)
    for _, conditionId in ipairs(conditionIds) do
        if conditionId > 0 and not XConditionManager.CheckCondition(conditionId) then
            return false
        end
    end
    return true
end

--- 获取角色配置Id
function XDlcRelinkControl:GetCharacterConfigId(characterId, occupationType)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(occupationType) then
        return 0
    end
    return characterId * 10 + occupationType
end

function XDlcRelinkControl:GetCharacterCharacterId(characterId, occupationType)
    local configId = self:GetCharacterConfigId(characterId, occupationType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.CharacterId or 0
end

function XDlcRelinkControl:GetCharacterOccupationType(characterId, occupationType)
    local configId = self:GetCharacterConfigId(characterId, occupationType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.OccupationType or 0
end

function XDlcRelinkControl:GetCharacterOccupationDesc(characterId, occupationType)
    local configId = self:GetCharacterConfigId(characterId, occupationType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.OccupationDesc or ""
end

function XDlcRelinkControl:GetCharacterIsDefaultTag(characterId, occupationType)
    local configId = self:GetCharacterConfigId(characterId, occupationType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.IsDefaultTag or 0
end

function XDlcRelinkControl:GetCharacterNpcId(characterId, occupationType)
    local configId = self:GetCharacterConfigId(characterId, occupationType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.NpcId or 0
end

function XDlcRelinkControl:GetCharacterConditionIds(characterId, occupationType)
    local configId = self:GetCharacterConfigId(characterId, occupationType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.Condition or {}
end

function XDlcRelinkControl:GetCharacterSkillIds(characterId, occupationType)
    local configId = self:GetCharacterConfigId(characterId, occupationType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.SkillIds or {}
end

--endregion

--region 职业相关

function XDlcRelinkControl:GetOccupationNameByCharacterId(characterId)
    local occupationType = self:GetOccupationTypeByCharacterId(characterId)
    return self:GetClientConfig("CharacterOccupationName", occupationType) or ""
end

function XDlcRelinkControl:GetOccupationIconByCharacterId(characterId)
    local occupationType = self:GetOccupationTypeByCharacterId(characterId)
    return self:GetClientConfig("CharacterOccupationIcon", occupationType) or ""
end

function XDlcRelinkControl:GetOccupationDescByCharacterId(characterId)
    local occupationType = self:GetOccupationTypeByCharacterId(characterId)
    return self:GetCharacterOccupationDesc(characterId, occupationType)
end

function XDlcRelinkControl:GetOccupationNameByEquipId(equipId)
    local equipOccupationType = self:GetEquipOccupationType(equipId)
    return self:GetClientConfig("EquipOccupationName", equipOccupationType) or ""
end

function XDlcRelinkControl:GetOccupationIconByEquipId(equipId)
    local equipOccupationType = self:GetEquipOccupationType(equipId)
    return self:GetClientConfig("EquipOccupationIcon", equipOccupationType) or ""
end

--endregion

--region 等级表相关

--- 获取等级通关时间
function XDlcRelinkControl:GetLevelFinishTime(levelId)
    if not self._Model.ActivityData then
        return 0
    end
    return self._Model.ActivityData:GetLevelFinishTime(levelId)
end

--- 获取等级通关次数
function XDlcRelinkControl:GetLevelPassTime(levelId)
    if not self._Model.ActivityData then
        return 0
    end
    return self._Model.ActivityData:GetLevelPassTime(levelId)
end

--- 获取排行榜等级Id列表
function XDlcRelinkControl:GetRankLevelIds()
    local chapterIds = self:GetActivityChapterIds()
    if XTool.IsTableEmpty(chapterIds) then
        return {}
    end
    local rankLevelIds = {}
    for _, chapterId in ipairs(chapterIds) do
        local levelIds = self:GetChapterLevelIds(chapterId)
        if not XTool.IsTableEmpty(levelIds) then
            for _, levelId in ipairs(levelIds) do
                if self:GetLevelIsRank(levelId) then
                    table.insert(rankLevelIds, levelId)
                end
            end
        end
    end
    return rankLevelIds
end

--- 获取章节默认选择等级Id
function XDlcRelinkControl:GetDefaultSelectLevelId(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return 0
    end

    local levelIds = self:GetChapterLevelIds(chapterId)
    if XTool.IsTableEmpty(levelIds) then
        return 0
    end

    for i = #levelIds, 1, -1 do
        local levelId = levelIds[i]
        if self:CheckLevelUnlock(levelId) then
            return levelId
        end
    end
    return levelIds[1] or 0
end

--- 获取等级解锁描述
function XDlcRelinkControl:GetLevelUnlockDesc(levelId)
    if not XTool.IsNumberValid(levelId) then
        return ""
    end

    local preLevelId = self:GetLevelPreLevelId(levelId)
    if preLevelId > 0 and not self:CheckLevelPassed(preLevelId) then
        return string.format(self:GetClientConfig("LevelUnlockDesc", 1), self:GetLevelName(preLevelId))
    end

    local timeId = self:GetLevelTimeId(levelId)
    if timeId > 0 and not XFunctionManager.CheckInTimeByTimeId(timeId) then
        local remainTime = XFunctionManager.GetStartTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
        if remainTime > 0 then
            return string.format(self:GetClientConfig("LevelUnlockDesc", 2), XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME))
        end
    end

    local conditionIds = self:GetLevelConditionIds(levelId)
    for _, conditionId in ipairs(conditionIds) do
        if conditionId > 0 then
            local isOpen, desc = XConditionManager.CheckCondition(conditionId)
            if not isOpen then
                return desc or ""
            end
        end
    end
    return ""
end

--- 检查等级是否解锁
function XDlcRelinkControl:CheckLevelUnlock(levelId)
    return self._Model:CheckLevelUnlock(levelId)
end

--- 检查等级是否通关
function XDlcRelinkControl:CheckLevelPassed(levelId)
    return self._Model:CheckLevelPassed(levelId)
end

function XDlcRelinkControl:GetLevelName(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetLevelPreLevelId(levelId)
    return self._Model:GetLevelPreLevelId(levelId)
end

function XDlcRelinkControl:GetLevelChapterId(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.ChapterId or 0
end

function XDlcRelinkControl:GetLevelType(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.Type or 0
end

function XDlcRelinkControl:GetLevelTimeId(levelId)
    return self._Model:GetLevelTimeId(levelId)
end

function XDlcRelinkControl:GetLevelConditionIds(levelId)
    return self._Model:GetLevelConditionIds(levelId)
end

function XDlcRelinkControl:GetLevelIsRank(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.IsRank or false
end

function XDlcRelinkControl:GetLevelFirstDropIds(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.FirstDropIds or {}
end

function XDlcRelinkControl:GetLevelDropIds(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.DropIds or {}
end

function XDlcRelinkControl:GetLevelFirstExp(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.FirstExp or 0
end

function XDlcRelinkControl:GetLevelExp(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.Exp or 0
end

function XDlcRelinkControl:GetLevelFirstCoin(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.FirstCoin or 0
end

function XDlcRelinkControl:GetLevelLevelLimit(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.LevelLimit or 0
end

function XDlcRelinkControl:GetLevelLoadingTips(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.LoadingTips or 0
end

function XDlcRelinkControl:GetLevelFirstShowGroupId(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.FirstShowGroupId or 0
end

function XDlcRelinkControl:GetLevelShowGroupId(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.ShowGroupId or 0
end

--endregion

--region Boss技能描述表相关

function XDlcRelinkControl:GetBossSkillDescName(skillId)
    local config = self._Model:GetBossSkillDescConfig(skillId)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetBossSkillDescVideoUrl(skillId)
    local config = self._Model:GetBossSkillDescConfig(skillId)
    return config and config.VideoUrl or ""
end

function XDlcRelinkControl:GetBossSkillDescDesc(skillId)
    local config = self._Model:GetBossSkillDescConfig(skillId)
    return config and config.Desc or ""
end

function XDlcRelinkControl:GetBossSkillDescTags(skillId)
    local config = self._Model:GetBossSkillDescConfig(skillId)
    return config and config.Tags or {}
end

--endregion

--region 研发表相关

--- 获取当前研发等级
function XDlcRelinkControl:GetCurrentPlayerLevel()
    if not self._Model.ActivityData then
        return 0
    end
    return self._Model.ActivityData:GetLevel()
end

--- 获取当前研发经验
function XDlcRelinkControl:GetCurrentPlayerExp()
    if not self._Model.ActivityData then
        return 0
    end
    return self._Model.ActivityData:GetExp()
end

--- 获取升级所需经验
function XDlcRelinkControl:GetNextPlayerLevelExp(curLevel)
    if not XTool.IsNumberValid(curLevel) then
        curLevel = self:GetCurrentPlayerLevel()
    end
    -- 已达最大等级则返回0
    if self:GetPlayerLevelIsMax(curLevel) then
        return 0
    end
    return self:GetPlayerLevelExp(curLevel + 1)
end

--- 获取升级所需金币
function XDlcRelinkControl:GetUpgradeNeedCostCoin()
    local curLevel = self:GetCurrentPlayerLevel()
    if self:GetPlayerLevelIsMax(curLevel) then
        return 0
    end

    local nextLevel = curLevel + 1
    local nextLevelExp = self:GetPlayerLevelExp(nextLevel)
    if nextLevelExp <= 0 then
        return 0
    end

    local remainExp = nextLevelExp - self:GetCurrentPlayerExp()
    if remainExp <= 0 then
        return 0
    end

    local coinExpTransfer = self:GetPlayerLevelCoinExpTransfer(nextLevel)
    if coinExpTransfer <= 0 then
        return 0
    end

    return remainExp * coinExpTransfer
end

--- 获取研发属性列表
---@param level number 研发等级
---@return table<string, number> key: 属性名 value: 属性值
function XDlcRelinkControl:GetPlayerLevelAttributes(level)
    if not XTool.IsNumberValid(level) then
        return {}
    end

    local attributeNames = self:GetPlayerLevelAttributeNames(level)
    local attributeValues = self:GetPlayerLevelAttributeValues(level)
    if XTool.IsTableEmpty(attributeNames) or XTool.IsTableEmpty(attributeValues) or #attributeNames ~= #attributeValues then
        return {}
    end

    local attributes = {}
    for i = 1, #attributeNames do
        local attrStr = attributeNames[i]
        local attrValue = attributeValues[i]
        if attrStr and XTool.IsNumberValid(attrValue) then
            attributes[attrStr] = attrValue
        end
    end
    return attributes
end

--- 检查升级条件是否满足
---@param level number 研发等级
---@return boolean, string 是否满足, 不满足时的提示
function XDlcRelinkControl:CheckPlayerLevelUpCondition(level)
    if not XTool.IsNumberValid(level) then
        return false, ""
    end

    -- 检查条件
    local conditionId = self:GetPlayerLevelConditionId(level)
    if XTool.IsNumberValid(conditionId) then
        local isOpen, desc = XConditionManager.CheckCondition(conditionId)
        if not isOpen then
            return false, desc
        end
    end

    -- 检查通关条件
    local finishOneOfLevelIds = self:GetPlayerLevelFinishOneOfLevelIds(level)
    if not XTool.IsTableEmpty(finishOneOfLevelIds) then
        for _, levelId in pairs(finishOneOfLevelIds) do
            if self:CheckLevelPassed(levelId) then
                return true, ""
            end
        end
        local levelNameList = {}
        for _, levelId in ipairs(finishOneOfLevelIds) do
            local levelName = self:GetLevelName(levelId)
            if levelName then
                table.insert(levelNameList, levelName)
            end
        end
        local desc = string.format(self:GetClientConfig("PlayerLevelUpConditionDesc"), table.concat(levelNameList, ","))
        return false, desc
    end
    return true, ""
end

function XDlcRelinkControl:GetPlayerLevelExp(level)
    local config = self._Model:GetPlayerLevelConfig(level)
    return config and config.Exp or 0
end

function XDlcRelinkControl:GetPlayerLevelCoinExpTransfer(level)
    local config = self._Model:GetPlayerLevelConfig(level)
    return config and config.CoinExpTransfer or 0
end

function XDlcRelinkControl:GetPlayerLevelNormalSlot(level)
    local config = self._Model:GetPlayerLevelConfig(level)
    return config and config.NormalSlot or 0
end

function XDlcRelinkControl:GetPlayerLevelExtraSlotLimit(level)
    local config = self._Model:GetPlayerLevelConfig(level)
    return config and config.ExtraSlotLimit or 0
end

function XDlcRelinkControl:GetPlayerLevelConditionId(level)
    local config = self._Model:GetPlayerLevelConfig(level)
    return config and config.ConditionId or 0
end

function XDlcRelinkControl:GetPlayerLevelAttributeNames(level)
    local config = self._Model:GetPlayerLevelConfig(level)
    return config and config.AttributeNames or {}
end

function XDlcRelinkControl:GetPlayerLevelAttributeValues(level)
    local config = self._Model:GetPlayerLevelConfig(level)
    return config and config.AttributeValues or {}
end

function XDlcRelinkControl:GetPlayerLevelFinishOneOfLevelIds(level)
    local config = self._Model:GetPlayerLevelConfig(level)
    return config and config.FinishOneOfLevelIds or {}
end

function XDlcRelinkControl:GetPlayerLevelComposeId(level)
    local config = self._Model:GetPlayerLevelConfig(level)
    return config and config.ComposeId or 0
end

function XDlcRelinkControl:GetPlayerLevelIsMax(level)
    local config = self._Model:GetPlayerLevelConfig(level)
    return config and config.IsMax == 1 or false
end

--endregion

--region 装备槽位索引相关

--- 获取装备槽位下标映射
function XDlcRelinkControl:GetEquipSlotIndexMap()
    local maxSlotNum = self:GetEquipSlotMaxNum()
    local expandMaxSlotNum = self:GetExpandEquipSlotMaxNum()
    local normalMaxSlotNum = self:GetNormalEquipSlotMaxNum()

    local meta = self.EquipSlotIndexMapMeta
    if self.EquipSlotIndexMap and meta and meta.max == maxSlotNum and meta.expand == expandMaxSlotNum and meta.normal == normalMaxSlotNum then
        return self.EquipSlotIndexMap
    end

    self.EquipSlotIndexMap = {}
    -- 主槽位
    self.EquipSlotIndexMap[1] = XEnumConst.DlcRelink.EquipSlotIndex.MainSlot
    -- 扩展槽位
    for i = 1, expandMaxSlotNum do
        self.EquipSlotIndexMap[i + 1] = XEnumConst.DlcRelink.EquipSlotIndex.NormalExpandBegin + (i - 1)
    end
    -- 普通槽位（裁剪至最大槽位数）
    local normalCount = math.max(0, math.min(normalMaxSlotNum, maxSlotNum - 1 - expandMaxSlotNum))
    for i = 1, normalCount do
        self.EquipSlotIndexMap[i + 1 + expandMaxSlotNum] = XEnumConst.DlcRelink.EquipSlotIndex.NormalSlotBegin + (i - 1)
    end

    self.EquipSlotIndexMapMeta = {
        max = maxSlotNum,
        expand = expandMaxSlotNum,
        normal = normalMaxSlotNum
    }
    return self.EquipSlotIndexMap
end

--- 获取装备槽位扩展槽位下标列表
---@return table<number> 扩展槽位下标列表
function XDlcRelinkControl:GetEquipExpandSlotIndexList()
    local equipSlotIndexMap = self:GetEquipSlotIndexMap()
    local expandSlotIndexList = {}
    for _, slotIndex in ipairs(equipSlotIndexMap) do
        if slotIndex >= XEnumConst.DlcRelink.EquipSlotIndex.NormalExpandBegin and slotIndex < XEnumConst.DlcRelink.EquipSlotIndex.NormalSlotBegin then
            table.insert(expandSlotIndexList, slotIndex)
        end
    end
    return expandSlotIndexList
end

--- 检查下标是否为扩展槽位
---@param slotIndex number 装备槽位下标
---@return boolean 是否为扩展槽位
function XDlcRelinkControl:CheckIsExpandSlotIndex(slotIndex)
    if not XTool.IsNumberValid(slotIndex) then
        return false
    end
    local equipSlotIndexMap = self:GetEquipSlotIndexMap()
    for _, equipSlotIndex in ipairs(equipSlotIndexMap) do
        if equipSlotIndex == slotIndex then
            return slotIndex >= XEnumConst.DlcRelink.EquipSlotIndex.NormalExpandBegin and slotIndex < XEnumConst.DlcRelink.EquipSlotIndex.NormalSlotBegin
        end
    end
    return false
end

--endregion

--region 装备表相关

---@return XDlcRelinkEquipData[]
function XDlcRelinkControl:GetEquipsDataList()
    if not self._Model.ActivityData then
        return {}
    end
    return self._Model.ActivityData:GetEquipsDataList()
end

---@return XDlcRelinkEquipData
function XDlcRelinkControl:GetEquipDataByUid(equipUid)
    if not self._Model.ActivityData then
        return nil
    end
    return self._Model.ActivityData:GetEquipsDataByUid(equipUid)
end

--- 获取所有的装备Uid列表
function XDlcRelinkControl:GetAllEquipUids()
    local equipsDataList = self:GetEquipsDataList()
    if XTool.IsTableEmpty(equipsDataList) then
        return {}
    end

    local equipUids = {}
    for _, equipData in pairs(equipsDataList) do
        table.insert(equipUids, equipData:GetUid())
    end
    return equipUids
end

--region 装备排序与过滤

--- 通用排序：品质降序 > 等级降序 > Uid升序
---@param entries { Uid:number, Quality:number, Ability:number, WearerId:number }
function XDlcRelinkControl:SortEquipEntriesCommon(entries)
    if XTool.IsTableEmpty(entries) or #entries <= 1 then
        return
    end

    table.sort(entries, function(a, b)
        if a.Quality ~= b.Quality then
            return a.Quality > b.Quality
        end
        if a.Ability ~= b.Ability then
            return a.Ability > b.Ability
        end
        return a.Uid < b.Uid
    end)
end

--- 装备界面：当前角色穿戴置顶，其它角色穿戴置底，其余按通用排序
---@param entries { Uid:number, Quality:number, Ability:number, WearerId:number }
---@param characterId number 当前角色Id
function XDlcRelinkControl:SortEquipEntriesForEquipUi(entries, characterId)
    if XTool.IsTableEmpty(entries) or #entries <= 1 or not XTool.IsNumberValid(characterId) then
        return
    end

    for i = 1, #entries do
        local wearer = entries[i].WearerId or 0
        local isCur = XTool.IsNumberValid(wearer) and wearer == characterId
        local isOther = XTool.IsNumberValid(wearer) and wearer ~= characterId
        entries[i].WearRank = isCur and 0 or (isOther and 2 or 1)
    end

    table.sort(entries, function(a, b)
        if a.WearRank ~= b.WearRank then
            return a.WearRank < b.WearRank
        end
        if a.Quality ~= b.Quality then
            return a.Quality > b.Quality
        end
        if a.Ability ~= b.Ability then
            return a.Ability > b.Ability
        end
        return a.Uid < b.Uid
    end)
end

--- 改造界面：过滤掉当前选中装备，角色穿戴装备置底，其余按通用排序
---@param entries { Uid:number, Quality:number, Ability:number, WearerId:number }
---@param curEquipUid number 当前选中装备Uid
---@return table[] 过滤后的装备列表
function XDlcRelinkControl:FilterAndSortEquipEntriesForReformUi(entries, curEquipUid)
    if XTool.IsTableEmpty(entries) or #entries <= 1 then
        return entries or {}
    end

    local filteredEntries = {}
    for i = 1, #entries do
        local wearer = entries[i].WearerId or 0
        if not XTool.IsNumberValid(curEquipUid) or entries[i].Uid ~= curEquipUid then
            entries[i].WearRank = XTool.IsNumberValid(wearer) and 1 or 0
            table.insert(filteredEntries, entries[i])
        end
    end

    table.sort(filteredEntries, function(a, b)
        if a.WearRank ~= b.WearRank then
            return a.WearRank < b.WearRank
        end
        if a.Quality ~= b.Quality then
            return a.Quality > b.Quality
        end
        if a.Ability ~= b.Ability then
            return a.Ability > b.Ability
        end
        return a.Uid < b.Uid
    end)
    return filteredEntries
end

--- 分解界面：角色穿戴装备置底，其余按通用排序取反
---@param entries { Uid:number, Quality:number, Ability:number, WearerId:number }
function XDlcRelinkControl:SortEquipEntriesForDecomposeUi(entries)
    if XTool.IsTableEmpty(entries) or #entries <= 1 then
        return
    end

    for i = 1, #entries do
        local wearer = entries[i].WearerId or 0
        entries[i].WearRank = XTool.IsNumberValid(wearer) and 1 or 0
    end

    table.sort(entries, function(a, b)
        if a.WearRank ~= b.WearRank then
            return a.WearRank < b.WearRank
        end
        if a.Quality ~= b.Quality then
            return a.Quality < b.Quality
        end
        if a.Ability ~= b.Ability then
            return a.Ability < b.Ability
        end
        return a.Uid > b.Uid
    end)
end

--endregion

--region 装备筛选

--- 检查装备是否匹配筛选条件
---@param equipData XDlcRelinkEquipData 装备数据
---@param filter XDlcRelinkEquipFilterCache 外部传入的筛选缓存
function XDlcRelinkControl:CheckEquipMatchFilter(equipData, filter)
    if not filter then
        return true
    end

    -- 改造类型
    if XTool.IsNumberValid(filter.ReformedType) and filter.ReformedType ~= equipData:IsEquipReformed() then
        return false
    end
    -- 词条删除类型
    if XTool.IsNumberValid(filter.FactorRemovedType) and filter.FactorRemovedType ~= equipData:IsEquipFactorRemoved() then
        return false
    end
    local templateId = equipData:GetTemplateId()
    -- 装备类型
    if XTool.IsNumberValid(filter.EquipType) and filter.EquipType ~= self:GetEquipType(templateId) then
        return false
    end
    -- 词条Id包含筛选（主属性命中即通过）
    if not XTool.IsTableEmpty(filter.FactorIds) then
        local isSet = {}
        for _, id in pairs(filter.FactorIds) do
            isSet[id] = true
        end

        local hit = false
        local mainFactors = equipData:GetMainFactors()
        for _, factor in pairs(mainFactors) do
            if isSet[factor.FactorId] then
                hit = true
                break
            end
        end
        if not hit then
            return false
        end
    end
    return true
end

--endregion

--- 根据职业类型获取装备Uid列表
---@param occupationType number 职业类型
---@param opts { Context:string, CharacterId:number, SelectedEquipUid:number, Filter:XDlcRelinkEquipFilterCache } 可选参数 Context ->"Equip"|"Reform"|"Decompose"
---@return table<number> 装备Uid列表
function XDlcRelinkControl:GetEquipUidListByOccupationType(occupationType, opts)
    if not XTool.IsNumberValid(occupationType) then
        return {}
    end

    local equipDataList = self:GetEquipsDataList()
    if XTool.IsTableEmpty(equipDataList) then
        return {}
    end

    local entries = {}
    opts = opts or {}
    local filter = opts.Filter

    for _, equipData in pairs(equipDataList) do
        local templateId = equipData:GetTemplateId()
        if self:GetEquipOccupationType(templateId) == occupationType and self:CheckEquipMatchFilter(equipData, filter) then
            local equipUid = equipData:GetUid()
            local quality = self:GetEquipQuality(templateId)
            local ability = equipData:GetEquipAbility()
            local wearerId = self:GetEquipWearCharacterId(equipUid)
            table.insert(entries, { Uid = equipUid, Quality = quality, Ability = ability, WearerId = wearerId })
        end
    end

    local context = opts.Context
    if context == "Equip" then
        self:SortEquipEntriesForEquipUi(entries, opts.CharacterId)
    elseif context == "Reform" then
        entries = self:FilterAndSortEquipEntriesForReformUi(entries, opts.SelectedEquipUid)
    elseif context == "Decompose" then
        self:SortEquipEntriesForDecomposeUi(entries)
    else
        self:SortEquipEntriesCommon(entries)
    end

    local equipUids = {}
    for i = 1, #entries do
        equipUids[i] = entries[i].Uid
    end
    return equipUids
end

--- 根据栏位索引获取未穿戴的装备Uid列表
---@param slotIndex number 装备栏位索引，1为主装备，其它为普通装备
---@return table<number> 装备Uid列表
function XDlcRelinkControl:GetUnWearEquipUidListBySlot(slotIndex)
    if not XTool.IsNumberValid(slotIndex) then
        return {}
    end

    local equipDataList = self:GetEquipsDataList()
    if XTool.IsTableEmpty(equipDataList) then
        return {}
    end

    local curEquipType = slotIndex == 1 and XEnumConst.DlcRelink.EquipType.Main or XEnumConst.DlcRelink.EquipType.Normal
    local entries = {}

    for _, equipData in pairs(equipDataList) do
        local templateId = equipData:GetTemplateId()
        local equipUid = equipData:GetUid()
        local wearerId = self:GetEquipWearCharacterId(equipUid)
        if self:GetEquipType(templateId) == curEquipType and not XTool.IsNumberValid(wearerId) then
            local quality = self:GetEquipQuality(templateId)
            local ability = equipData:GetEquipAbility()
            table.insert(entries, { Uid = equipUid, Quality = quality, Ability = ability, WearerId = wearerId })
        end
    end

    self:SortEquipEntriesCommon(entries)

    local equipUids = {}
    for i = 1, #entries do
        equipUids[i] = entries[i].Uid
    end
    return equipUids
end

--- 获取角色所穿戴的装备Uid，未穿戴返回0
---@param characterId number 角色Id
---@param slotIndex number 装备栏位索引
---@return number 装备Uid
function XDlcRelinkControl:GetEquipUidByCharacterId(characterId, slotIndex)
    local characterData = self:GetCharacterDataByCharacterId(characterId)
    if not characterData then
        return 0
    end
    return characterData:GetEquipBySlot(slotIndex)
end

--- 获取装备所穿戴的角色Id，未穿戴返回0
function XDlcRelinkControl:GetEquipWearCharacterId(equipUid)
    if not XTool.IsNumberValid(equipUid) then
        return 0
    end

    local characterDataList = self:GetCharacterDataList()
    if XTool.IsTableEmpty(characterDataList) then
        return 0
    end

    for _, characterData in pairs(characterDataList) do
        if characterData:IsEquipWorn(equipUid) then
            return characterData:GetCharacterId()
        end
    end
    return 0
end

--- 获取装备所穿戴的栏位索引
function XDlcRelinkControl:GetEquipWearSlotIndex(characterId, equipUid, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetEquipWearSlotIndexByEquipUid(equipUid)
    end
    if not XTool.IsNumberValid(equipUid) then
        return 0
    end

    local characterData = self:GetCharacterDataByCharacterId(characterId)
    if not characterData then
        return 0
    end
    return characterData:GetEquipSlotId(equipUid)
end

--- 获取角色身上装备的总战力
function XDlcRelinkControl:GetEquipTotalAbilityByCharacterId(characterId)
    local equipDict = self:GetWearEquipUidsByCharacterId(characterId)
    if XTool.IsTableEmpty(equipDict) then
        return 0
    end

    local totalEquipAbility = 0
    for _, equipUid in pairs(equipDict) do
        totalEquipAbility = totalEquipAbility + self:GetEquipAbilityByUid(equipUid)
    end
    return totalEquipAbility
end

--- 获取装备配置Id
function XDlcRelinkControl:GetEquipTemplateIdByEquipUid(equipUid, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetEquipTemplateIdByEquipUid(equipUid)
    end
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return 0
    end
    return equipData:GetTemplateId()
end

--- 获取装备是否锁定
function XDlcRelinkControl:GetEquipIsLockedByEquipUid(equipUid, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetEquipIsLockedByEquipUid(equipUid)
    end
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return false
    end
    return equipData:GetIsLocked()
end

--- 获取装备词条删除次数
function XDlcRelinkControl:GetEquipFactorRemoveNumByEquipUid(equipUid)
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return 0
    end
    return equipData:GetFactorRemoveNum()
end

--- 获取装备副词条总数量
function XDlcRelinkControl:GetEquipDeputyAttributeTotalCount(equipUid)
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return 0
    end
    return equipData:GetAttributeTotalCount()
end

--- 获取装备主属性
---@param equipUid number 装备Uid
---@param isSkillFactor boolean 是否技能属性
---@return XDlcRelinkEquipAttribute
function XDlcRelinkControl:GetEquipMainFactorByUid(equipUid, isSkillFactor, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetEquipMainFactorByEquipUid(equipUid, isSkillFactor)
    end
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return nil
    end

    local templateId = equipData:GetTemplateId()
    local mainSkillFactorId = self:GetEquipMainSkillFactorId(templateId)
    for _, attribute in pairs(equipData:GetMainFactors()) do
        if isSkillFactor == (attribute.FactorId == mainSkillFactorId) then
            return attribute
        end
    end
    return nil
end

--- 获取装备所有主属性
---@param equipUid number 装备Uid
---@return XDlcRelinkEquipAttribute[]
function XDlcRelinkControl:GetEquipAllMainFactorByUid(equipUid, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetEquipAllMainFactorByEquipUid(equipUid)
    end
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return {}
    end
    return equipData:GetMainFactors()
end

--- 获取装备所有副属性
---@param equipUid number 装备Uid
---@return XDlcRelinkEquipAttributeSlot[]
function XDlcRelinkControl:GetEquipAllDeputyFactorByUid(equipUid, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetEquipAllDeputyFactorByEquipUid(equipUid)
    end
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return {}
    end
    return equipData:GetAttributeSlots()
end

--- 获取装备副属性
---@param equipUid number 装备Uid
---@param slotIndex number 副属性槽位索引，从1开始
---@return XDlcRelinkEquipAttributeSlot
function XDlcRelinkControl:GetEquipDeputyFactorByUid(equipUid, slotIndex, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetEquipDeputyFactorByEquipUid(equipUid, slotIndex)
    end
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return nil
    end

    return equipData:GetAttributeSlotByIndex(slotIndex)
end

--- 获取装备战力
function XDlcRelinkControl:GetEquipAbilityByUid(equipUid, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetEquipAbilityByEquipUid(equipUid)
    end
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return 0
    end
    return equipData:GetEquipAbility()
end

--- 获取装备最大战力
function XDlcRelinkControl:GetEquipMaxAbilityByUid(equipUid, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetEquipMaxAbilityByEquipUid(equipUid)
    end
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return 0
    end

    local templateId = equipData:GetTemplateId()
    local ability = self:GetEquipAbility(templateId)

    -- 主属性战力
    local mainSkillFactorId = self:GetEquipMainSkillFactorId(templateId)
    for _, attribute in pairs(equipData:GetMainFactors()) do
        if mainSkillFactorId ~= attribute.FactorId then
            ability = ability + self:GetAttributeAbilityInternal(attribute)
        end
    end

    -- 副属性战力
    for _, slotsValue in pairs(equipData:GetAttributeSlots()) do
        for _, attribute in pairs(slotsValue.Attributes) do
            ability = ability + self:GetAttributeAbilityInternal(attribute)
        end
    end

    return ability
end

---@param attribute XDlcRelinkEquipAttribute
function XDlcRelinkControl:GetAttributeAbilityInternal(attribute, index)
    local factorAbilityList = self:GetEquipFactorAbility(attribute.EquipTemplate)
    if XTool.IsTableEmpty(factorAbilityList) then
        return 0
    end

    -- index不传则取最大值
    index = XTool.IsNumberValid(index) and index or #factorAbilityList
    return factorAbilityList[index] or 0
end

---@param attribute XDlcRelinkEquipAttribute
function XDlcRelinkControl:GetAttributeLevelInternal(attribute, index)
    local factorLevelList = self:GetEquipMainFactorLevel(attribute.EquipTemplate)
    if XTool.IsTableEmpty(factorLevelList) then
        return 0
    end

    -- index不传则取最大值
    index = XTool.IsNumberValid(index) and index or #factorLevelList
    return factorLevelList[index] or 0
end

--- 计算扩展装备的额外加成属性Id和等级
---@param equipUids table<number, number> 装备Uid列表 key: 装备栏位索引，value: 装备Uid
---@return table<number, number> 额外加成的属性Id和等级 key: FactorId, value: 等级
function XDlcRelinkControl:CalcExtendAddFactor(equipUids, isNotSelf)
    local result = {}
    if XTool.IsTableEmpty(equipUids) then
        return result
    end

    local mainEquipUid = equipUids[XEnumConst.DlcRelink.EquipSlotIndex.MainSlot]
    if not XTool.IsNumberValid(mainEquipUid) then
        return result
    end

    local mainTemplateId = self:GetEquipTemplateIdByEquipUid(mainEquipUid, isNotSelf)
    if not XTool.IsNumberValid(mainTemplateId) then
        return result
    end

    local expandSlotIndexList = self:GetEquipExpandSlotIndexList()
    if XTool.IsTableEmpty(expandSlotIndexList) then
        return result
    end

    local mainOcc = self:GetEquipOccupationType(mainTemplateId)
    local addFactorLevel = self:GetEquipAddFactorLevel(mainTemplateId)
    for _, slotIndex in ipairs(expandSlotIndexList) do
        local extendEquipUid = equipUids[slotIndex]
        if XTool.IsNumberValid(extendEquipUid) then
            local extendTemplateId = self:GetEquipTemplateIdByEquipUid(extendEquipUid, isNotSelf)
            if XTool.IsNumberValid(extendTemplateId) and mainOcc == self:GetEquipOccupationType(extendTemplateId) then
                local extendAttr = self:GetEquipMainFactorByUid(extendEquipUid, false, isNotSelf)
                if extendAttr and XTool.IsNumberValid(extendAttr.FactorId) then
                    result[extendAttr.FactorId] = (result[extendAttr.FactorId] or 0) + addFactorLevel
                end
            end
        end
    end

    return result
end

--- 根据装备Uid列表累计属性并返回属性映射
---@param equipUids table<number> 装备Uid列表
---@param extendAddFactors table<number, number> 额外加成的属性Id和等级 key: FactorId, value: 等级
---@return table<number, { FactorId: number, IsSkill:boolean, CurLevel:number }> key: FactorId, value: 属性信息
function XDlcRelinkControl:AccumulateEquipAttributes(equipUids, extendAddFactors, isNotSelf)
    if XTool.IsTableEmpty(equipUids) then
        return {}
    end

    local attributeMap = {}
    -- 累加逻辑
    local function AddAttr(factorId, isSkill, level, createIfMissing)
        if not XTool.IsNumberValid(factorId) or not XTool.IsNumberValid(level) then
            return
        end
        local entry = attributeMap[factorId]
        if entry then
            entry.CurLevel = entry.CurLevel + level
        elseif createIfMissing then
            attributeMap[factorId] = {
                FactorId = factorId,
                IsSkill = isSkill or false,
                CurLevel = level,
            }
        end
    end

    for _, equipUid in pairs(equipUids) do
        -- 配置Id
        local templateId = self:GetEquipTemplateIdByEquipUid(equipUid, isNotSelf)
        local mainSkillFactorId = self:GetEquipMainSkillFactorId(templateId)

        -- 主属性
        local mainFactors = self:GetEquipAllMainFactorByUid(equipUid, isNotSelf)
        for _, attribute in pairs(mainFactors) do
            local factorId = attribute.FactorId
            AddAttr(factorId, factorId == mainSkillFactorId, attribute.Level, true)
        end

        -- 副属性
        local attributeSlots = self:GetEquipAllDeputyFactorByUid(equipUid, isNotSelf)
        for _, slotsValue in pairs(attributeSlots) do
            for _, attribute in pairs(slotsValue.Attributes) do
                AddAttr(attribute.FactorId, false, attribute.Level, true)
            end
        end
    end

    -- 额外加成属性（仅在已存在该属性时叠加）
    if not XTool.IsTableEmpty(extendAddFactors) then
        for factorId, addLevel in pairs(extendAddFactors) do
            AddAttr(factorId, false, addLevel, false)
        end
    end
    return attributeMap
end

--- 对属性映射进行排序并返回列表
---@param attributeMap table<number, { FactorId:number, IsSkill:boolean, CurLevel:number }>
---@return { FactorId:number, IsSkill:boolean, CurLevel:number }[]
function XDlcRelinkControl:SortEquipAttributeMap(attributeMap)
    if not attributeMap then
        return {}
    end
    local attributeList = {}
    for _, attribute in pairs(attributeMap) do
        table.insert(attributeList, attribute)
    end
    table.sort(attributeList, function(a, b)
        local orderA = self:GetFactorDescOrder(a.FactorId)
        local orderB = self:GetFactorDescOrder(b.FactorId)
        if orderA ~= orderB then
            return orderA < orderB
        end
        return a.FactorId < b.FactorId
    end)
    return attributeList
end

--- 获取角色身上装备的总属性映射
---@param equipUids table<number, number> 装备Uid列表 key: 装备栏位索引，value: 装备Uid
---@return { FactorId: number, IsSkill:boolean, CurLevel:number }[] 属性列表
function XDlcRelinkControl:GetEquipTotalAttributeList(equipUids, isNotSelf)
    local extendAddFactors = self:CalcExtendAddFactor(equipUids, isNotSelf)
    local attributeMap = self:AccumulateEquipAttributes(equipUids, extendAddFactors, isNotSelf)
    return self:SortEquipAttributeMap(attributeMap)
end

--- 获取属性集合 (包含角色基础属性、玩家等级属性、装备属性)
---@param characterId number 角色Id
---@param curPlayerLevel number 当前玩家等级
---@param equipUids table<number, number> 装备Uid列表 key: 装备栏位索引，value: 装备Uid
---@return { AttrStr: string, CharacterValue: number, PlayerValue: number, EquipValue: number }[] 属性列表
function XDlcRelinkControl:GetTotalAttributes(characterId, curPlayerLevel, equipUids, isNotSelf)
    local characterAttributes = self:GetCharacterAttributesByCharacterId(characterId, isNotSelf)
    local playerAttributes = self:GetPlayerLevelAttributes(curPlayerLevel)
    local equipAttributes = self:GetEquipTotalAttributeList(equipUids, isNotSelf)

    local attributeDict = {}
    -- 获取或创建属性项
    local function GetOrCreate(attrStr)
        local entry = attributeDict[attrStr]
        if not entry then
            entry = {
                AttrStr = attrStr,
                CharacterValue = 0,
                PlayerValue = 0,
                EquipValue = 0,
            }
            attributeDict[attrStr] = entry
        end
        return entry
    end

    -- 角色基础属性
    for attrStr, attrValue in pairs(characterAttributes) do
        if XTool.IsNumberValid(attrValue) then
            local entry = GetOrCreate(attrStr)
            entry.CharacterValue = attrValue
        end
    end

    -- 玩家等级属性
    for attrStr, attrValue in pairs(playerAttributes) do
        if XTool.IsNumberValid(attrValue) then
            local entry = GetOrCreate(attrStr)
            entry.PlayerValue = entry.PlayerValue + attrValue
        end
    end

    -- 装备属性（非技能类）
    for _, attribute in pairs(equipAttributes) do
        if not attribute.IsSkill then
            local factorId = attribute.FactorId
            local curLevel = attribute.CurLevel
            local params = self:GetFactorParams(factorId, curLevel)
            local attrStr = self:GetFactorDescAttributeName(factorId)
            local attrValue = (params and params[1]) or 0
            if XTool.IsNumberValid(attrValue) then
                local entry = GetOrCreate(attrStr)
                entry.EquipValue = entry.EquipValue + attrValue
            end
        end
    end

    -- 过滤与排序
    local totalAttributes = {}
    for attrStr, attribute in pairs(attributeDict) do
        if self:CheckCharacterAttribExist(attrStr) then
            attribute.Order = self:GetCharacterAttribOrder(attrStr)
            table.insert(totalAttributes, attribute)
        end
    end
    table.sort(totalAttributes, function(a, b)
        return a.Order < b.Order
    end)

    return totalAttributes
end

--- 获取装备主属性Id列表
---@param equipUidList table<number> 装备Uid列表
---@return table<number> 主属性Id列表
function XDlcRelinkControl:GetEquipMainFactorIds(equipUidList)
    if XTool.IsTableEmpty(equipUidList) then
        return {}
    end

    local factorIdSet = {}
    for _, equipUid in pairs(equipUidList) do
        local equipData = self:GetEquipDataByUid(equipUid)
        if equipData then
            local templateId = equipData:GetTemplateId()
            local mainSkillFactorId = self:GetEquipMainSkillFactorId(templateId)
            for _, attribute in pairs(equipData:GetMainFactors()) do
                if attribute.FactorId ~= mainSkillFactorId then
                    factorIdSet[attribute.FactorId] = true
                end
            end
        end
    end

    local factorIds = {}
    for factorId in pairs(factorIdSet) do
        factorIds[#factorIds + 1] = factorId
    end
    table.sort(factorIds)
    return factorIds
end

--- 获取装备背包当前数量和最大数量
function XDlcRelinkControl:GetEquipBagCurCountAndMaxCount()
    if not self._Model.ActivityData then
        return 0, 0
    end

    local curCount = self._Model.ActivityData:GetEquipsDataCount()
    local maxCount = self:GetEquipBgMaxNum()
    return curCount, maxCount
end

--- 检查装备是否最大战力
function XDlcRelinkControl:CheckEquipIsMaxAbility(equipUid, isNotSelf)
    local curAbility = self:GetEquipAbilityByUid(equipUid, isNotSelf)
    local maxAbility = self:GetEquipMaxAbilityByUid(equipUid, isNotSelf)
    return curAbility >= maxAbility
end

--- 检查装备属性是否满级
---@param attribute XDlcRelinkEquipAttribute
function XDlcRelinkControl:CheckEquipAttributeIsMaxLevel(attribute)
    local maxLevel = self:GetAttributeLevelInternal(attribute)
    return attribute.Level >= maxLevel
end

--- 检查主槽位和扩展槽位的EquipOccupationType类型是否相同
---@param characterId number 角色Id
---@param mainSlotIndex number 主槽位索引
---@param extendSlotIndex number 扩展槽位索引
function XDlcRelinkControl:CheckEquipSlotOccupationTypeSame(characterId, mainSlotIndex, extendSlotIndex, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:CheckEquipSlotOccupationTypeSame(mainSlotIndex, extendSlotIndex)
    end
    local mainEquipUid = self:GetEquipUidByCharacterId(characterId, mainSlotIndex)
    local extendEquipUid = self:GetEquipUidByCharacterId(characterId, extendSlotIndex)
    if not XTool.IsNumberValid(mainEquipUid) or not XTool.IsNumberValid(extendEquipUid) then
        return false
    end

    local mainTemplateId = self:GetEquipTemplateIdByEquipUid(mainEquipUid)
    local extendTemplateId = self:GetEquipTemplateIdByEquipUid(extendEquipUid)
    if not XTool.IsNumberValid(mainTemplateId) or not XTool.IsNumberValid(extendTemplateId) then
        return false
    end

    return self:GetEquipOccupationType(mainTemplateId) == self:GetEquipOccupationType(extendTemplateId)
end

--- 检查装备的副属性槽位是否已满
function XDlcRelinkControl:CheckEquipDeputyFactorSlotsIsFull(equipUid)
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return false
    end

    local quality = self:GetEquipQuality(equipData:GetTemplateId())
    local maxSlotsNum = self:GetEquipQualityDeputyFactorNum(quality)
    local curSlotsNum = equipData:GetAttributeSlotCount()
    return curSlotsNum >= maxSlotsNum
end

--- 检查装备槽位是否解锁
---@param characterId number 角色Id
---@param slotIndex number 装备栏位索引
---@param isNotSelf boolean 是否为他人角色
---@return boolean, string 是否解锁及解锁提示
function XDlcRelinkControl:CheckEquipSlotIsUnlocked(characterId, slotIndex, isNotSelf)
    -- 主槽位默认解锁
    if slotIndex == XEnumConst.DlcRelink.EquipSlotIndex.MainSlot then
        return true, ""
    end

    local curPlayerLevel, mainEquipUid
    if isNotSelf then
        curPlayerLevel = self.OtherMemberControl:GetPlayerLevel()
        mainEquipUid = self.OtherMemberControl:GetEquipWearEquipUidBySlot(XEnumConst.DlcRelink.EquipSlotIndex.MainSlot)
    else
        curPlayerLevel = self:GetCurrentPlayerLevel()
        local equipUids = self:GetWearEquipUidsByCharacterId(characterId)
        mainEquipUid = equipUids[XEnumConst.DlcRelink.EquipSlotIndex.MainSlot]
    end

    -- 普通槽位解锁判断
    if slotIndex >= XEnumConst.DlcRelink.EquipSlotIndex.NormalSlotBegin then
        local normalSlotIndex = slotIndex - XEnumConst.DlcRelink.EquipSlotIndex.NormalSlotBegin + 1
        return normalSlotIndex > 0 and normalSlotIndex <= self:GetPlayerLevelNormalSlot(curPlayerLevel), self:GetClientConfig("EquipSlotNoUnlock", 2)
    end

    -- 扩展槽位解锁判断
    if slotIndex >= XEnumConst.DlcRelink.EquipSlotIndex.NormalExpandBegin and slotIndex < XEnumConst.DlcRelink.EquipSlotIndex.NormalSlotBegin then
        local expandSlotIndex = slotIndex - XEnumConst.DlcRelink.EquipSlotIndex.NormalExpandBegin + 1
        if not XTool.IsNumberValid(mainEquipUid) then
            return false, self:GetClientConfig("EquipSlotNoUnlock", 3)
        end
        local mainTemplateId = self:GetEquipTemplateIdByEquipUid(mainEquipUid, isNotSelf)
        local addSlotNum = self:GetEquipAddSlotNum(mainTemplateId)
        local maxExpandSlot = math.min(self:GetPlayerLevelExtraSlotLimit(curPlayerLevel), addSlotNum)
        return expandSlotIndex > 0 and expandSlotIndex <= maxExpandSlot, self:GetClientConfig("EquipSlotNoUnlock", 2)
    end

    return false, self:GetClientConfig("EquipSlotNoUnlock", 1)
end

function XDlcRelinkControl:GetEquipName(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetEquipIcon(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.Icon or ""
end

function XDlcRelinkControl:GetEquipType(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.Type or 0
end

function XDlcRelinkControl:GetEquipOccupationType(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.EquipOccupationType or 0
end

function XDlcRelinkControl:GetEquipQuality(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.Quality or 0
end

function XDlcRelinkControl:GetEquipMainSkillFactorId(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.MainSkillFactorId or 0
end

function XDlcRelinkControl:GetEquipMainSkillFactorLevel(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.MainSkillFactorLevel or 0
end

function XDlcRelinkControl:GetEquipMainFactorId(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.MainFactorId or 0
end

function XDlcRelinkControl:GetEquipAddSlotNum(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.AddSlotNum or 0
end

function XDlcRelinkControl:GetEquipAddFactorLevel(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.AddFactorLevel or 0
end

function XDlcRelinkControl:GetEquipMainFactorLevel(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.MainFactorLevel or {}
end

function XDlcRelinkControl:GetEquipLevelWeights(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.LevelWeights or {}
end

function XDlcRelinkControl:GetEquipFactorAbility(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.FactorAbility or {}
end

function XDlcRelinkControl:GetEquipAbility(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.Ability or 0
end

--endregion

--region 装备品质表相关

function XDlcRelinkControl:GetEquipQualityAssetsByEquipId(equipId)
    local quality = self:GetEquipQuality(equipId)
    return self:GetEquipQualityAssets(quality)
end

function XDlcRelinkControl:GetEquipQualityAssets(quality)
    local config = self._Model:GetEquipQualityConfig(quality)
    return config and config.QualityAssets or ""
end

function XDlcRelinkControl:GetEquipQualityName(quality)
    local config = self._Model:GetEquipQualityConfig(quality)
    return config and config.QualityName or ""
end

function XDlcRelinkControl:GetEquipQualityDeputyFactorNum(quality)
    local config = self._Model:GetEquipQualityConfig(quality)
    return config and config.DeputyFactorNum or 0
end

function XDlcRelinkControl:GetEquipQualityFactorRemoveNum(quality)
    local config = self._Model:GetEquipQualityConfig(quality)
    return config and config.FactorRemoveNum or 0
end

function XDlcRelinkControl:GetEquipQualityAbsorbFactorWeight(quality)
    local config = self._Model:GetEquipQualityConfig(quality)
    return config and config.AbsorbFactorWeight or 0
end

function XDlcRelinkControl:GetEquipQualityAbsorbFactorPaceMax(quality)
    local config = self._Model:GetEquipQualityConfig(quality)
    return config and config.AbsorbFactorPaceMax or 0
end

--endregion

--region 词条表相关

--- 获取词条配置Id
function XDlcRelinkControl:GetFactorConfigId(factorId, level)
    if not XTool.IsNumberValid(factorId) or not XTool.IsNumberValid(level) then
        return 0
    end
    local maxLevel = self:GetFactorDescMaxLevel(factorId)
    return factorId * 1000 + math.min(level, maxLevel)
end

function XDlcRelinkControl:GetFactorType(factorId, level)
    local configId = self:GetFactorConfigId(factorId, level)
    local config = self._Model:GetFactorConfig(configId)
    return config and config.Type or 0
end

function XDlcRelinkControl:GetFactorParams(factorId, level)
    local configId = self:GetFactorConfigId(factorId, level)
    local config = self._Model:GetFactorConfig(configId)
    return config and config.Params or {}
end

function XDlcRelinkControl:GetFactorDesc(factorId, level)
    local configId = self:GetFactorConfigId(factorId, level)
    local config = self._Model:GetFactorConfig(configId)
    return config and config.Desc or ""
end

function XDlcRelinkControl:GetFactorAffectedSkillId(factorId, level)
    local configId = self:GetFactorConfigId(factorId, level)
    local config = self._Model:GetFactorConfig(configId)
    return config and config.AffectedSkillId or 0
end

function XDlcRelinkControl:GetFactorNewSkillId(factorId, level)
    local configId = self:GetFactorConfigId(factorId, level)
    local config = self._Model:GetFactorConfig(configId)
    return config and config.NewSkillId or 0
end

--endregion

--region 词条描述表相关

function XDlcRelinkControl:GetFactorDescAttributeName(factorId)
    local config = self._Model:GetFactorDescConfig(factorId)
    return config and config.AttributeName or ""
end

function XDlcRelinkControl:GetFactorDescName(factorId)
    local config = self._Model:GetFactorDescConfig(factorId)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetFactorDescDesc(factorId)
    local config = self._Model:GetFactorDescConfig(factorId)
    return config and config.Desc or ""
end

function XDlcRelinkControl:GetFactorDescIsPercent(factorId)
    local config = self._Model:GetFactorDescConfig(factorId)
    return config and config.IsPercent == 1 or false
end

function XDlcRelinkControl:GetFactorDescMaxLevel(factorId)
    local config = self._Model:GetFactorDescConfig(factorId)
    return config and config.MaxLevel or 0
end

function XDlcRelinkControl:GetFactorDescOrder(factorId)
    local config = self._Model:GetFactorDescConfig(factorId)
    return config and config.Order or 0
end

--endregion

--region 装备技能词条表相关

function XDlcRelinkControl:GetEquipSkillFactorName(factorId)
    local config = self._Model:GetEquipSkillFactorConfig(factorId)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetEquipSkillFactorDescription(factorId)
    local config = self._Model:GetEquipSkillFactorConfig(factorId)
    return config and config.Description or ""
end

--endregion

--region 合成表相关

--- 根据物品id和数量计算可合成的最大次数
function XDlcRelinkControl:CalculateComposeMaxCount(composeId)
    local consumeIds = self:GetComposeConsumeIds(composeId)
    local consumeCounts = self:GetComposeConsumeCounts(composeId)
    if XTool.IsTableEmpty(consumeIds) or XTool.IsTableEmpty(consumeCounts) or #consumeIds ~= #consumeCounts then
        return 0
    end

    -- 因物品id是列表，所以需要计算每个物品可合成的次数，取最小值为最终可合成次数
    local minCount = 0
    for i = 1, #consumeIds do
        local itemId = consumeIds[i]
        local needCount = consumeCounts[i]
        if not XTool.IsNumberValid(itemId) or not XTool.IsNumberValid(needCount) then
            return 0
        end
        local haveCount = XDataCenter.ItemManager.GetCount(itemId)
        local curCount = math.floor(haveCount / needCount)
        if i == 1 or curCount < minCount then
            minCount = curCount
        end
    end
    return minCount
end

--- 获取合成需要的物品Id列表
function XDlcRelinkControl:GetComposeConsumeIds(composeId)
    local config = self._Model:GetComposeConfig(composeId)
    return config and config.ConsumeIds or {}
end

--- 获取合成需要的物品数量列表
function XDlcRelinkControl:GetComposeConsumeCounts(composeId)
    local config = self._Model:GetComposeConfig(composeId)
    return config and config.ConsumeCounts or {}
end

--endregion

--region 分解表相关

--- 获取分解奖励物品列表
---@param equipUidList table<number> 装备Uid列表
---@return XRewardGoods[] 奖励物品列表
function XDlcRelinkControl:GetBreakRewardGoods(equipUidList)
    if XTool.IsTableEmpty(equipUidList) then
        return {}
    end

    local itemId2Count = {}
    for _, equipUid in pairs(equipUidList) do
        local equipTemplateId = self:GetEquipTemplateIdByEquipUid(equipUid)
        local subFactorCount = self:GetEquipDeputyAttributeTotalCount(equipUid)
        local fixOutputId = self:GetBreakFixOutputId(equipTemplateId)
        local fixOutputCount = self:GetBreakFixOutputCount(equipTemplateId)
        local factorOutputCount = self:GetBreakFactorOutputCount(equipTemplateId)
        for index, outputId in pairs(fixOutputId) do
            local fixCount = fixOutputCount[index] or 0
            local factorCount = factorOutputCount[index] or 0
            local totalCount = fixCount + subFactorCount * factorCount
            if XTool.IsNumberValid(outputId) and totalCount > 0 then
                itemId2Count[outputId] = (itemId2Count[outputId] or 0) + totalCount
            end
        end
    end

    local rewardGoods = {}
    for itemId, count in pairs(itemId2Count) do
        if XTool.IsNumberValid(itemId) and count > 0 then
            table.insert(rewardGoods, XRewardManager.CreateRewardGoods(itemId, count))
        end
    end
    return rewardGoods
end

function XDlcRelinkControl:GetBreakFixOutputId(breakEquipId)
    local config = self._Model:GetBreakConfig(breakEquipId)
    return config and config.FixOutputId or {}
end

function XDlcRelinkControl:GetBreakFixOutputCount(breakEquipId)
    local config = self._Model:GetBreakConfig(breakEquipId)
    return config and config.FixOutputCount or {}
end

function XDlcRelinkControl:GetBreakFactorOutputCount(breakEquipId)
    local config = self._Model:GetBreakConfig(breakEquipId)
    return config and config.FactorOutputCount or {}
end

--endregion

--region 表情表相关

--- 获取表情轮盘Id列表
function XDlcRelinkControl:GetEmojiWheelIds()
    if not self._Model.ActivityData then
        return {}
    end
    return self._Model.ActivityData:GetEmojiWheelIds()
end

--- 获取指定类型的表情轮盘Id列表
function XDlcRelinkControl:GetEmojiWheelIdsByType(wheelType)
    local configs = self._Model:GetTextEmojiConfigs()
    if XTool.IsTableEmpty(configs) then
        return {}
    end

    local wheelIds = {}
    for id, config in pairs(configs) do
        if config.Type == wheelType and (config.DefaultCanUse or not XTool.IsNumberValid(config.EmojiId) or XDataCenter.ChatManager.IsEmojiValid(config.EmojiId)) then
            table.insert(wheelIds, id)
        end
    end
    table.sort(wheelIds, function(a, b)
        return a < b
    end)
    return wheelIds
end

function XDlcRelinkControl:GetTextEmojiIcon(id)
    local emojiId = self:GetTextEmojiEmojiId(id)
    return XDataCenter.ChatManager.GetEmojiIcon(emojiId) or ""
end

function XDlcRelinkControl:GetTextEmojiConnotationDesc(id)
    local emojiId = self:GetTextEmojiEmojiId(id)
    return XChatConfigs.GetEmojiConnotationDesc(emojiId)
end

function XDlcRelinkControl:GetTextEmojiType(id)
    local config = self._Model:GetTextEmojiConfig(id)
    return config and config.Type or 0
end

function XDlcRelinkControl:GetTextEmojiText(id)
    local config = self._Model:GetTextEmojiConfig(id)
    return config and config.Text or ""
end

function XDlcRelinkControl:GetTextEmojiEmojiId(id)
    local config = self._Model:GetTextEmojiConfig(id)
    return config and config.EmojiId or 0
end

function XDlcRelinkControl:GetTextEmojiDefaultCanUse(id)
    local config = self._Model:GetTextEmojiConfig(id)
    return config and config.DefaultCanUse or false
end

--endregion

--region 装备预设相关

function XDlcRelinkControl:GetEquipPresetSetDataList()
    if not self._Model.ActivityData then
        return {}
    end
    return self._Model.ActivityData:GetEquipPresetSetDataList()
end

function XDlcRelinkControl:GetEquipPresetSetDataByIndex(index)
    if not self._Model.ActivityData then
        return nil
    end
    return self._Model.ActivityData:GetEquipPresetSetDataByIndex(index)
end

--- 获取已使用的装备预设套装数量
function XDlcRelinkControl:GetUsedEquipPresetCount()
    local count = 0
    local presetSetDataList = self:GetEquipPresetSetDataList()
    for _, presetSetData in pairs(presetSetDataList) do
        for _, equipUid in pairs(presetSetData.Slot2EquipUid) do
            if XTool.IsNumberValid(equipUid) then
                count = count + 1
                break
            end
        end
    end
    return count
end

--- 获取预设装备名称
function XDlcRelinkControl:GetEquipPresetSetNameByIndex(index)
    local presetSetData = self:GetEquipPresetSetDataByIndex(index)
    local name = presetSetData and presetSetData.Name or ""
    if string.IsNilOrEmpty(name) then
        name = string.format(self:GetClientConfig("EquipPresetSetDefaultName"), index)
    end
    return name
end

--- 获取预设装备装备Uids
function XDlcRelinkControl:GetEquipPresetSetEquipUidsByIndex(index)
    local presetSetData = self:GetEquipPresetSetDataByIndex(index)
    if not presetSetData then
        return {}
    end
    local equipUids = {}
    for slot, equipUid in pairs(presetSetData.Slot2EquipUid) do
        if XTool.IsNumberValid(equipUid) then
            equipUids[slot] = equipUid
        end
    end
    return equipUids
end

--- 获取预设装备战力
function XDlcRelinkControl:GetEquipPresetSetAbilityByIndex(index)
    local presetSetData = self:GetEquipPresetSetDataByIndex(index)
    if not presetSetData then
        return 0
    end

    local totalAbility = 0
    for _, equipUid in pairs(presetSetData.Slot2EquipUid) do
        totalAbility = totalAbility + self:GetEquipAbilityByUid(equipUid)
    end
    return totalAbility
end

--- 获取预设装备栏位对应的装备Uid，未设置返回0
function XDlcRelinkControl:GetEquipPresetSetEquipUidByIndexAndSlot(index, slot)
    local presetSetData = self:GetEquipPresetSetDataByIndex(index)
    if not presetSetData then
        return 0
    end
    return presetSetData.Slot2EquipUid[slot] or 0
end

--- 检查预设装备里的装备是否为空
function XDlcRelinkControl:CheckEquipPresetSetIsEmpty(index)
    local presetSetData = self:GetEquipPresetSetDataByIndex(index)
    if not presetSetData then
        return true
    end
    for _, equipUid in pairs(presetSetData.Slot2EquipUid) do
        if XTool.IsNumberValid(equipUid) then
            return false
        end
    end
    return true
end

--- 检查预设装备里的装备是否被其它角色穿戴
function XDlcRelinkControl:CheckEquipPresetSetIsWornByOtherCharacter(index, characterId)
    local presetSetData = self:GetEquipPresetSetDataByIndex(index)
    if not presetSetData then
        return false
    end
    for _, equipUid in pairs(presetSetData.Slot2EquipUid) do
        local wearerId = self:GetEquipWearCharacterId(equipUid)
        if XTool.IsNumberValid(wearerId) and wearerId ~= characterId then
            return true
        end
    end
    return false
end

--- 检查装备是否已被预设装备使用
function XDlcRelinkControl:CheckEquipIsPresetByEquipUid(equipUid)
    if not XTool.IsNumberValid(equipUid) then
        return false
    end

    local presetSetDataList = self:GetEquipPresetSetDataList()
    if XTool.IsTableEmpty(presetSetDataList) then
        return false
    end

    for _, presetSetData in pairs(presetSetDataList) do
        for _, uid in pairs(presetSetData.Slot2EquipUid) do
            if uid == equipUid then
                return true
            end
        end
    end
    return false
end

--endregion

--region World表相关

function XDlcRelinkControl:GetWorldId()
    local worldId, levelId = self:GetCurrentWorldIdAndLevelId()
    if not XTool.IsNumberValid(worldId) or not XTool.IsNumberValid(levelId) then
        return nil
    end
    return string.format("%s%s", worldId, levelId)
end

function XDlcRelinkControl:GetCurrentWorldScene(worldId, levelId)
    local id
    if XTool.IsNumberValid(worldId) and XTool.IsNumberValid(levelId) then
        id = string.format("%s%s", worldId, levelId)
    else
        id = self:GetWorldId()
    end
    if not id then
        return ""
    end
    return self._Model:GetWorldSceneUrl(id)
end

function XDlcRelinkControl:GetCurrentWorldSceneModel(worldId, levelId)
    local id
    if XTool.IsNumberValid(worldId) and XTool.IsNumberValid(levelId) then
        id = string.format("%s%s", worldId, levelId)
    else
        id = self:GetWorldId()
    end
    if not id then
        return ""
    end
    return self._Model:GetWorldSceneModelUrl(id)
end

function XDlcRelinkControl:GetCurrentMaskLoadingType(worldId, levelId)
    local id
    if XTool.IsNumberValid(worldId) and XTool.IsNumberValid(levelId) then
        id = string.format("%s%s", worldId, levelId)
    else
        id = self:GetWorldId()
    end
    if not id then
        return ""
    end
    return self._Model:GetWorldMaskLoadingType(id)
end

function XDlcRelinkControl:GetCurrentWorldArtName()
    local id = self:GetWorldId()
    if not id then
        return ""
    end
    return self._Model:GetWorldArtName(id)
end

function XDlcRelinkControl:GetCurrentWorldLoadingBackground()
    local id = self:GetWorldId()
    if not id then
        return ""
    end
    return self._Model:GetWorldLoadingBackground(id)
end

--endregion

--region 勋章标签表相关

function XDlcRelinkControl:GetMedalTagName(tagId)
    local config = self._Model:GetMedalTagConfig(tagId)
    return config and config.Name or ""
end

--endregion

--region 角色属性表相关

function XDlcRelinkControl:CheckCharacterAttribExist(key)
    return self._Model:GetCharacterAttribConfig(key, true) ~= nil
end

function XDlcRelinkControl:GetCharacterAttribName(key)
    local config = self._Model:GetCharacterAttribConfig(key)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetCharacterAttribDesc(key)
    local config = self._Model:GetCharacterAttribConfig(key)
    return config and config.Desc or ""
end

function XDlcRelinkControl:GetCharacterAttribIcon(key)
    local config = self._Model:GetCharacterAttribConfig(key)
    return config and config.Icon or ""
end

function XDlcRelinkControl:GetCharacterAttribIsPercent(key)
    local config = self._Model:GetCharacterAttribConfig(key)
    return config and config.IsPercent == 1 or false
end

function XDlcRelinkControl:GetCharacterAttribOrder(key)
    local config = self._Model:GetCharacterAttribConfig(key)
    return config and config.Order or 0
end

--endregion

--region 技能描述表相关

--- 获取属性值
---@param characterId number 角色Id
---@param attributeName string 属性名称
---@param isNotSelf boolean 是否是自己
---@return number 属性值
function XDlcRelinkControl:GetTotalAttributeValue(characterId, attributeName, isNotSelf)
    local curPlayerLevel, equipUids
    if isNotSelf then
        curPlayerLevel = self.OtherMemberControl:GetPlayerLevel()
        equipUids = self.OtherMemberControl:GetWearEquipUids()
    else
        curPlayerLevel = self:GetCurrentPlayerLevel()
        equipUids = self:GetWearEquipUidsByCharacterId(characterId)
    end

    local totalAttributes = self:GetTotalAttributes(characterId, curPlayerLevel, equipUids, isNotSelf)
    for _, attribute in ipairs(totalAttributes) do
        if attribute.AttrStr == attributeName then
            return (attribute.CharacterValue or 0) + (attribute.PlayerValue or 0) + (attribute.EquipValue or 0)
        end
    end
    return 0
end

--- 获取属性值列表
---@param characterId number 角色Id
---@param attributeNames table<string> 属性名称列表
---@param isNotSelf boolean 是否是自己
---@return table<string, number> 属性值字典 key: 属性名称，value: 属性值
function XDlcRelinkControl:GetTotalAttributeValueList(characterId, attributeNames, isNotSelf)
    local curPlayerLevel, equipUids
    if isNotSelf then
        curPlayerLevel = self.OtherMemberControl:GetPlayerLevel()
        equipUids = self.OtherMemberControl:GetWearEquipUids()
    else
        curPlayerLevel = self:GetCurrentPlayerLevel()
        equipUids = self:GetWearEquipUidsByCharacterId(characterId)
    end

    local totalAttributes = self:GetTotalAttributes(characterId, curPlayerLevel, equipUids, isNotSelf)
    local attributeDict = {}
    for _, attribute in ipairs(totalAttributes) do
        attributeDict[attribute.AttrStr] = (attribute.CharacterValue or 0) + (attribute.PlayerValue or 0) + (attribute.EquipValue or 0)
    end

    local result = {}
    for _, attrName in ipairs(attributeNames) do
        result[attrName] = attributeDict[attrName] or 0
    end
    return result
end

--- 获取技能伤害上限值
---@param skillId number 技能Id
---@param characterId number 角色Id
---@param isNotSelf boolean 是否是自己
---@return number 技能伤害上限值
function XDlcRelinkControl:GetSkillMaxDamageLimit(skillId, characterId, isNotSelf)
    if not XTool.IsNumberValid(skillId) or not XTool.IsNumberValid(characterId) then
        return 0
    end

    local baseDamageLimit = self:GetSkillDescBaseDamageLimit(skillId)
    if not XTool.IsNumberValid(baseDamageLimit) then
        return 0
    end

    local dmgLimitPValue = self:GetTotalAttributeValue(characterId, "DmgLimitP", isNotSelf)
    return math.floor(baseDamageLimit * (1 + dmgLimitPValue / 10000))
end

--- 获取技能属性类型映射
function XDlcRelinkControl:GetSkillAttribTypeMap()
    self.AttrTypeMap = self.AttrTypeMap or {
        [1] = "PhysicalAmpP", -- 物理
        [2] = "Element1AmpP", -- 火
        [3] = "Element2AmpP", -- 雷
        [4] = "Element3AmpP", -- 冰
        [5] = "Element4AmpP", -- 暗
    }
    return self.AttrTypeMap
end

--- 获取技能当前伤害值
--- 计算伤害值 = 技能倍率(Rate) * 总攻击力 * （1+属性伤害提升【对应属性】） * （1+暴击率*（暴击伤害率-1））
---@param skillId number 技能Id
---@param characterId number 角色Id
---@param isNotSelf boolean 是否是自己
---@return number 技能当前伤害值
function XDlcRelinkControl:GetSkillCurrentDamage(skillId, characterId, isNotSelf)
    if not XTool.IsNumberValid(skillId) or not XTool.IsNumberValid(characterId) then
        return 0
    end

    local rate = self:GetSkillDescRate(skillId)
    if not XTool.IsNumberValid(rate) then
        return 0
    end

    local attribType = self:GetSkillDescAttribType(skillId)
    local attrTypeMap = self:GetSkillAttribTypeMap()
    local ampPName = attrTypeMap[attribType]
    if not ampPName then
        return 0
    end

    local attributeValues = self:GetTotalAttributeValueList(characterId, { "Attack", "CritP", "CritDmgRateP", ampPName }, isNotSelf)
    local attack = attributeValues["Attack"]
    local critP = attributeValues["CritP"]
    local critDmgRateP = attributeValues["CritDmgRateP"]
    local attribAmpP = attributeValues[ampPName]

    local damage = rate / 10000 * attack * (1 + attribAmpP / 10000) * (1 + critP / 10000 * (critDmgRateP / 10000 - 1))
    return math.max(math.round(damage), 1)
end

function XDlcRelinkControl:GetSkillDescName(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetSkillDescDesc(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.Desc or ""
end

function XDlcRelinkControl:GetSkillDescSimpleDesc(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.SimpleDesc or ""
end

function XDlcRelinkControl:GetSkillDescTypeDesc(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.TypeDesc or ""
end

function XDlcRelinkControl:GetSkillDescIcon(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.Icon or ""
end

function XDlcRelinkControl:GetSkillDescCd(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.Cd or 0
end

function XDlcRelinkControl:GetSkillDescBaseDamageLimit(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.BaseDamageLimit or 0
end

function XDlcRelinkControl:GetSkillDescRate(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.Rate or 0
end

function XDlcRelinkControl:GetSkillDescAttribType(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.AttribType or 0
end

function XDlcRelinkControl:GetSkillDescTags(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.Tags or {}
end

function XDlcRelinkControl:GetSkillDescEntryName(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.EntryName or {}
end

function XDlcRelinkControl:GetSkillDescEntryDesc(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.EntryDesc or {}
end

function XDlcRelinkControl:GetSkillDescVideoUrl(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.VideoUrl or ""
end

function XDlcRelinkControl:GetSkillDescSecondSkill(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.SecondSkill or {}
end

--endregion

--region 商店任务表相关

--- 获取指定类型的商店任务配置Id列表
function XDlcRelinkControl:GetShopTaskConfigIdsByType(type)
    local configs = self._Model:GetShopTaskConfigs()
    if XTool.IsTableEmpty(configs) then
        return {}
    end

    local ids = {}
    for _, config in pairs(configs) do
        if config.Type == type then
            table.insert(ids, config.Id)
        end
    end
    table.sort(ids, function(a, b)
        return a < b
    end)
    return ids
end

--- 获取第一个未完成的任务Id
function XDlcRelinkControl:GetFirstUnCompleteTaskId()
    local ids = self:GetShopTaskConfigIdsByType(XEnumConst.DlcRelink.ShopTaskType.Task)
    if XTool.IsTableEmpty(ids) then
        return 0
    end

    for _, id in ipairs(ids) do
        local taskIds = self:GetShopTaskParamId(id)
        if not XTool.IsTableEmpty(taskIds) then
            for _, taskId in ipairs(taskIds) do
                local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
                if taskData and taskData.State ~= XDataCenter.TaskManager.TaskState.Finish then
                    return taskId
                end
            end
        end
    end
    return 0
end

function XDlcRelinkControl:GetShopTaskShopId(configId)
    local paramIds = self:GetShopTaskParamId(configId)
    return paramIds and paramIds[1] or 0
end

function XDlcRelinkControl:GetShopTaskType(id)
    local config = self._Model:GetShopTaskConfig(id)
    return config and config.Type or 0
end

function XDlcRelinkControl:GetShopTaskName(id)
    local config = self._Model:GetShopTaskConfig(id)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetShopTaskParamId(id)
    local config = self._Model:GetShopTaskConfig(id)
    return config and config.ParamId or {}
end

--endregion

--region 展示关卡掉落表相关

--- 获取关卡首通奖励列表
function XDlcRelinkControl:GetShowLevelFirstRewardGoods(levelId)
    if not XTool.IsNumberValid(levelId) then
        return {}, {}
    end

    local rewardGoods = {}
    local showRewardIds = {}
    -- 1.经验货币
    local firstExp = self:GetLevelFirstExp(levelId)
    if firstExp > 0 then
        table.insert(rewardGoods, XRewardManager.CreateRewardGoods(XDataCenter.ItemManager.ItemId.DlcRelinkExpCoin, firstExp))
    end
    -- 2.商店货币
    local firstCoin = self:GetLevelFirstCoin(levelId)
    if firstCoin > 0 then
        table.insert(rewardGoods, XRewardManager.CreateRewardGoods(XDataCenter.ItemManager.ItemId.DlcRelinkStoreCoin, firstCoin))
    end
    -- 3.首通掉落
    local firstShowGroupId = self:GetLevelFirstShowGroupId(levelId)
    if firstShowGroupId > 0 then
        local startId = firstShowGroupId * 100 + 1
        local endId = firstShowGroupId * 100 + 99
        for i = startId, endId do
            if not self._Model:GetShowLevelDropConfig(i, true) then
                break
            end
            table.insert(showRewardIds, i)
        end
    end
    return rewardGoods, showRewardIds
end

--- 获取关卡普通掉落列表
function XDlcRelinkControl:GetShowLevelRewardGoods(levelId)
    if not XTool.IsNumberValid(levelId) then
        return {}, {}
    end

    local rewardGoods = {}
    local showRewardIds = {}
    -- 1.经验货币
    local exp = self:GetLevelExp(levelId)
    if exp > 0 then
        table.insert(rewardGoods, XRewardManager.CreateRewardGoods(XDataCenter.ItemManager.ItemId.DlcRelinkExpCoin, exp))
    end
    -- 3.普通掉落
    local showGroupId = self:GetLevelShowGroupId(levelId)
    if showGroupId > 0 then
        local startId = showGroupId * 100 + 1
        local endId = showGroupId * 100 + 99
        for i = startId, endId do
            if not self._Model:GetShowLevelDropConfig(i, true) then
                break
            end
            table.insert(showRewardIds, i)
        end
    end
    return rewardGoods, showRewardIds
end

function XDlcRelinkControl:GetShowLevelDropIcon(id)
    local config = self._Model:GetShowLevelDropConfig(id)
    return config and config.Icon or ""
end

function XDlcRelinkControl:GetShowLevelDropName(id)
    local config = self._Model:GetShowLevelDropConfig(id)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetShowLevelDropDesc(id)
    local config = self._Model:GetShowLevelDropConfig(id)
    return config and config.Desc or ""
end

--endregion

--region 排行榜相关

--- 更新排行榜数据
function XDlcRelinkControl:UpdateQueryRankData(rankData)
    if not rankData then
        self.QueryRankData = nil
        return
    end
    self.QueryRankData = rankData
end

--- 获取排行榜总人数
function XDlcRelinkControl:GetQueryRankTotalCount()
    if not self.QueryRankData then
        return 0
    end
    return self.QueryRankData.TotalCount or 0
end

--- 获取排行榜队伍数据列表
function XDlcRelinkControl:GetQueryRankTeamInfos()
    if not self.QueryRankData then
        return {}
    end
    return self.QueryRankData.RankTeamInfos or {}
end

--- 获取自己的排行榜数据
function XDlcRelinkControl:GetQueryRankMyTeamInfo()
    if not self.QueryRankData then
        return nil
    end
    return self.QueryRankData.SelfTopRankTeamInfos or nil
end

--- 获取自己的排行榜名次
function XDlcRelinkControl:GetQueryRankMyRank()
    if not self.QueryRankData then
        return 0
    end
    return self.QueryRankData.SelfRank or 0
end

--endregion

--region 配置表相关

function XDlcRelinkControl:GetConfig(key, index)
    if not index then
        index = 1
    end
    return self._Model:GetConfig(key, index)
end

--- 仓库装备上限
function XDlcRelinkControl:GetEquipBgMaxNum()
    local num = self:GetConfig("EquipMaxNum")
    return tonumber(num) or 0
end

--- 装备预设套装数量上限
function XDlcRelinkControl:GetEquipPresetMaxNum()
    local num = self:GetConfig("EquipPresetMaxNum")
    return tonumber(num) or 0
end

--- 装备预设套装命名长度上限
function XDlcRelinkControl:GetEquipPresetNameMaxLength()
    local num = self:GetConfig("EquipPresetNameMaxLength")
    return tonumber(num) or 0
end

--- 装备栏位最大数量
function XDlcRelinkControl:GetEquipSlotMaxNum()
    local num = self:GetConfig("EquipSlotMaxNum")
    return tonumber(num) or 0
end

--- 普通装备栏位最大数量
function XDlcRelinkControl:GetNormalEquipSlotMaxNum()
    local num = self:GetConfig("NormalEquipSlotMaxNum")
    return tonumber(num) or 0
end

--- 扩展装备栏位最大数量
function XDlcRelinkControl:GetExpandEquipSlotMaxNum()
    local num = self:GetConfig("ExpandEquipSlotMaxNum")
    return tonumber(num) or 0
end

--- 预设套装ID由此值开始，且被置顶的预设套装的ID也会被设置为此值
function XDlcRelinkControl:GetEquipPresetBeginId()
    local num = self:GetConfig("EquipPresetBeginId")
    return tonumber(num) or 0
end

--endregion

--region 客户端配置表相关

function XDlcRelinkControl:GetClientConfig(key, index)
    if not index then
        index = 1
    end
    return self._Model:GetClientConfig(key, index)
end

function XDlcRelinkControl:GetClientConfigParams(key)
    return self._Model:GetClientConfigParams(key)
end

--endregion

--region 房间相关

function XDlcRelinkControl:OnBeginMatching()
    XLuaUiManager.Open("UiDlcRelinkMatching")
end

function XDlcRelinkControl:OnCancelMatching()
    ---@type XUiDlcRelinkMatching
    local luaUi = XLuaUiManager.GetTopLuaUi("UiDlcRelinkMatching")
    if luaUi then
        luaUi:OnClose()
    end
end

function XDlcRelinkControl:OnMatchSuccess()
    self:OpenCommonTipText("MatchSuccessTips")
end

function XDlcRelinkControl:OnPlayerEnterRoom(playerId)
    if not XMVCA.XDlcRoom:IsInRoom() then
        return
    end
    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    local isSelfLeader = team and team:IsSelfLeader()
    if not isSelfLeader then
        return
    end
    local member = team and team:GetMemberById(playerId)
    if member then
        local playerName = member:GetName()
        local msg = string.format(self:GetClientConfig("PlayerEnterRoomTips"), playerName)
        self:OpenCommonLeftTipDialog(msg)
    end
end

--- 玩家收到邀请处理
function XDlcRelinkControl:OnReceiveInvite()
    if CS.XFight.IsRunning
        or XLuaUiManager.IsUiShow("UiDlcRelinkLoadingNew")
        or XLuaUiManager.IsUiShow("UiDlcRelinkSettlementNew") then
        return
    end
    XMVCA.XDlcRoom:CheckReceiveInvitation()
end

--- 检查是否可以同步数据到匹配服务器
function XDlcRelinkControl:AbleSyncDataToMatchServer()
    if XMVCA.XDlcRoom:IsMatching() then
        self:OpenCommonTipCode(XCode.MatchPlayerIsMatching)
        return false
    end
    if XMVCA.XDlcRoom:IsSelfReady() then
        self:OpenCommonTipCode(XCode.RelinkPlayerIsReady)
        return false
    end
    return true
end

--- 通用返回主界面处理
function XDlcRelinkControl:CommonRunMainUiHandle()
    local isNotDialogTip = true
    if XMVCA.XDlcRoom:IsInRoom() then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        if team then
            isNotDialogTip = team:GetMemberAmount() == 1
        end
    else
        if XMVCA.XDlcRoom:IsMatching() then
            isNotDialogTip = false
        end
    end
    XLuaUiManager.RunMain(isNotDialogTip)
end

--- 打开或返回房间界面
function XDlcRelinkControl:OpenOrReturnRoom()
    local uiName = "UiDlcRelinkRoom"
    if XLuaUiManager.IsStackUiOpen(uiName) then
        XLuaUiManager.CloseAllUpperUi(uiName)
    else
        XLuaUiManager.Open(uiName)
    end
end

--- 打开主界面和打开或返回房间界面
function XDlcRelinkControl:OpenMainAndReturnRoom()
    local uiName = "UiDlcRelinkMain"
    if XLuaUiManager.IsStackUiOpen(uiName) then
        self:OpenOrReturnRoom()
    else
        XLuaUiManager.OpenWithCallback(uiName, function()
            self:OpenOrReturnRoom()
        end)
    end
end

--endregion

--region 通用弹框

--- 获取通用提示弹框不再提示状态
function XDlcRelinkControl:GetCommonTipNoRemind(tipsKey)
    return self._Model.CommonTipNoRemindMap[tipsKey]
end

--- 设置通用提示弹框不再提示状态
function XDlcRelinkControl:SetCommonTipNoRemind(tipsKey, isNoRemind)
    self._Model.CommonTipNoRemindMap[tipsKey] = isNoRemind
end

--- 打开通用提示弹框
---@param title string 标题
---@param content string 内容
---@param closeCallback function 关闭回调
---@param sureCallback function 确认回调
---@param extraData { ConfirmText:string, CancelText:string, NoRemindText:string, TipsKey:string, DefaultNoRemind:boolean } 额外数据
function XDlcRelinkControl:OpenCommonTipDialog(title, content, closeCallback, sureCallback, extraData)
    if string.IsNilOrEmpty(title) or string.IsNilOrEmpty(content) then
        return
    end

    extraData = extraData or {}
    local tipsKey = extraData.TipsKey

    if not string.IsNilOrEmpty(tipsKey) then
        local isNoRemind = self:GetCommonTipNoRemind(tipsKey)
        if isNoRemind then
            if sureCallback then
                sureCallback()
            end
            return
        end
        extraData.NoRemindCallback = function(isValue)
            self:SetCommonTipNoRemind(tipsKey, isValue)
        end
        if extraData.DefaultNoRemind == nil then
            extraData.DefaultNoRemind = false
        end
    end

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_Big)
    XLuaUiManager.Open("UiDlcRelinkPopupCommon", title, content, closeCallback, sureCallback, extraData)
end

--- 打开左上角提示弹框
function XDlcRelinkControl:OpenCommonLeftTipDialog(content)
    if string.IsNilOrEmpty(content) then
        return
    end
    XLuaUiManager.OpenWithCallback("UiDlcRelinkToastCommonSmall", function(ui)
        ui.UiProxy.UiLuaTable:Refresh(content)
    end)
end

--- 打开通用提示消息弹框
function XDlcRelinkControl:OpenCommonTipMsg(msg, type, cb, hideCloseMark, hideUnderlineInfo)
    if string.IsNilOrEmpty(msg) then
        XLog.Error("XDlcRelinkControl:OpenCommonTipMsg msg is nil or empty")
        return
    end

    if not type then
        type = XUiManager.UiTipType.Tip
    end
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_small)
    XLuaUiManager.Open("UiDlcRelinkToastCommon", msg, type, cb, hideCloseMark, hideUnderlineInfo)
end

function XDlcRelinkControl:OpenCommonTipText(key, index, type)
    if string.IsNilOrEmpty(key) then
        return
    end
    local msg = self:GetClientConfig(key, index)
    self:OpenCommonTipMsg(msg, type)
end

function XDlcRelinkControl:OpenCommonTipSuccess(msg, hideCloseMark)
    self:OpenCommonTipMsg(msg, XUiManager.UiTipType.Success, nil, hideCloseMark)
end

function XDlcRelinkControl:OpenCommonTipError(msg)
    self:OpenCommonTipMsg(msg, XUiManager.UiTipType.Wrong)
end

function XDlcRelinkControl:OpenCommonTipCode(code, ...)
    local text = CS.XTextManager.GetCodeText(code, ...)
    if code == XCode.Success then
        self:OpenCommonTipSuccess(text)
    else
        self:OpenCommonTipError(text)
    end
end

--endregion

--region 结算相关

-- 获取结算缓存数据
function XDlcRelinkControl:GetSettlementCacheData()
    return self._Model.SettlementCacheData or {}
end

--endregion

--region 本地信息相关

--- 获取角色职业查看状态的存储Key
function XDlcRelinkControl:GetCharacterOccupationViewedKey(characterId, occupationType)
    local activityId = self._Model.ActivityData and self._Model.ActivityData:GetActivityId() or 0
    return string.format("DlcRelinkCharacterOccupationViewed_%s_%s_%s_%s", XPlayer.Id, activityId, characterId, occupationType)
end

--- 检查角色职业是否已查看
function XDlcRelinkControl:CheckCharacterOccupationViewed(characterId, occupationType)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(occupationType) then
        return false
    end
    local key = self:GetCharacterOccupationViewedKey(characterId, occupationType)
    return XSaveTool.GetData(key) or false
end

--- 记录角色职业为已查看
function XDlcRelinkControl:RecordCharacterOccupationViewed(characterId, occupationType)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(occupationType) then
        return
    end
    local key = self:GetCharacterOccupationViewedKey(characterId, occupationType)
    if not XSaveTool.GetData(key) then
        XSaveTool.SaveData(key, true)
    end
end

--- 获取装备查看状态的存储Key
function XDlcRelinkControl:GetEquipViewedKey()
    local activityId = self._Model.ActivityData and self._Model.ActivityData:GetActivityId() or 0
    return string.format("DlcRelinkEquipViewed_%s_%s", XPlayer.Id, activityId)
end

--- 检查装备是否已查看
function XDlcRelinkControl:CheckEquipViewed(equipUid)
    if not XTool.IsNumberValid(equipUid) then
        return false
    end
    local key = self:GetEquipViewedKey()
    local viewedData = XSaveTool.GetData(key) or {}
    return viewedData[equipUid] or false
end

--- 记录装备为已查看
function XDlcRelinkControl:RecordEquipViewed(equipUid)
    if not XTool.IsNumberValid(equipUid) then
        return
    end
    local key = self:GetEquipViewedKey()
    local viewedData = XSaveTool.GetData(key) or {}
    if not viewedData[equipUid] then
        viewedData[equipUid] = true
        XSaveTool.SaveData(key, viewedData)
    end
end

--- 记录所有装备为已查看
function XDlcRelinkControl:RecordAllEquipViewed()
    local equipUids = self:GetAllEquipUids()
    if XTool.IsTableEmpty(equipUids) then
        return
    end
    local key = self:GetEquipViewedKey()
    local viewedData = XSaveTool.GetData(key) or {}
    local isChanged = false
    for _, equipUid in pairs(equipUids) do
        if XTool.IsNumberValid(equipUid) and not viewedData[equipUid] then
            viewedData[equipUid] = true
            isChanged = true
        end
    end
    if isChanged then
        XSaveTool.SaveData(key, viewedData)
    end
end

--endregion

--region 红点相关

--- 检查关卡是否有新解锁的红点
function XDlcRelinkControl:CheckLevelHasNewUnlock(levelId)
    return self._Model:CheckLevelHasNewUnlock(levelId)
end

--- 检查章节下是否有任何新解锁的关卡
function XDlcRelinkControl:CheckChapterHasAnyNewLevel(chapterId)
    return self._Model:CheckChapterHasAnyNewLevel(chapterId)
end

--- 记录关卡为已查看
function XDlcRelinkControl:RecordLevelViewed(levelId)
    return self._Model:RecordLevelViewed(levelId)
end

--- 检查商店任务红点通过配置Id
function XDlcRelinkControl:CheckShopTaskRedPointByConfigId(configId)
    if not XTool.IsNumberValid(configId) then
        return false
    end

    local type = self:GetShopTaskType(configId)
    if type ~= XEnumConst.DlcRelink.ShopTaskType.Task then
        return false
    end

    local taskIds = self:GetShopTaskParamId(configId)
    if XTool.IsTableEmpty(taskIds) then
        return false
    end

    for _, taskId in ipairs(taskIds) do
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if taskData and taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
    return false
end

--- 检查角色职业是否有新解锁的红点
function XDlcRelinkControl:CheckCharacterOccupationHasNewUnlock(characterId, occupationType)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(occupationType) then
        return false
    end
    -- 职业未解锁，不显示红点
    if not self:CheckCharacterOccupationUnlock(characterId, occupationType) then
        return false
    end
    -- 职业已查看，不显示红点
    if self:CheckCharacterOccupationViewed(characterId, occupationType) then
        return false
    end
    return true
end

--- 检查当前角色是否有新解锁的职业红点
function XDlcRelinkControl:CheckCharacterHasAnyNewOccupation(characterId)
    if not XTool.IsNumberValid(characterId) then
        return false
    end
    for _, occupationType in pairs(XEnumConst.DlcRelink.OccTypeEnum) do
        local configId = self:GetCharacterConfigId(characterId, occupationType)
        local config = self._Model:GetCharacterConfig(configId, true)
        if config and self:CheckCharacterOccupationHasNewUnlock(characterId, occupationType) then
            return true
        end
    end
    return false
end

--- 检查研发等级是否有升级红点
function XDlcRelinkControl:CheckPlayerLevelUpRedPoint()
    local curLevel = self:GetCurrentPlayerLevel()
    -- 已满级，无红点
    if self:GetPlayerLevelIsMax(curLevel) then
        return false
    end
    -- 升级条件未达成，无红点
    local isUp, _ = self:CheckPlayerLevelUpCondition(curLevel + 1)
    if not isUp then
        return false
    end
    -- 消耗材料不足，无红点
    local needCost = self:GetUpgradeNeedCostCoin()
    local hasCost = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.DlcRelinkExpCoin)
    if hasCost < needCost then
        return false
    end
    return true
end

--endregion

return XDlcRelinkControl

---@class SelectLevelData
---@field ChapterId number 章节Id
---@field LevelId number 等级Id

---@class XDlcRelinkEquipFilterCache
---@field ReformedType number 改造类型，0 未选择，1 已改造，2 未改造
---@field FactorRemovedType number 词条删除类型，0 未选择，1 已删除过词条，2 未删除过词条
---@field EquipType number 装备类型 对应 XEnumConst.DlcRelink.EquipType
---@field FactorIds table<number> 词条Id列表

---@class XDlcRelinkSettlementCache
---@field LastLevel number 上次研发等级
---@field LastExp number 上次研发经验
---@field CurLevel number 当前研发等级
---@field CurExp number 当前研发经验

---@class XDlcRelinkQueryRank
---@field TotalCount number 排行榜总队伍数
---@field RankTeamInfos XDlcRelinkRankTeamInfo[]
---@field SelfTopRankTeamInfos XDlcRelinkRankTeamInfo
---@field SelfRank number 个人数据排名
