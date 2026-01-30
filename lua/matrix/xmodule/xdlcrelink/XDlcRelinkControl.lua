local XDlcRelinkFriend = require("XModule/XDlcRelink/XEntity/XDlcRelinkFriend")
local XDlcRelinkOtherMemberControl = require("XModule/XDlcRelink/SubControl/XDlcRelinkOtherMemberControl")
---@class XDlcRelinkControl : XControl
---@field private _Model XDlcRelinkModel
---@field OtherMemberControl XDlcRelinkOtherMemberControl
local XDlcRelinkControl = XClass(XControl, "XDlcRelinkControl")
function XDlcRelinkControl:OnInit()
    --性能大盘内存标记
    CS.XProfilingLuaUtils.PerfSightRelinkProcessEnter()
    CS.XProfilingLuaUtils.MarkPerfSightRelinkProcessInStart()
    self.OtherMemberControl = self:AddSubControl(XDlcRelinkOtherMemberControl)

    self.RequestName = {
        DlcRelinkSwitchStyleTypeRequest = "DlcRelinkSwitchStyleTypeRequest", -- 切换风格
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
        DlcRelinkSwitchGlobalMatchFlagRequest = "DlcRelinkSwitchGlobalMatchFlagRequest", -- 切换全局匹配标记
        DlcRelinkLikeRequest = "DlcRelinkLikeRequest", -- 点赞
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

    self:InitEnum()
end

function XDlcRelinkControl:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MATCH, self.OnBeginMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH, self.OnCancelMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MATCH_SUCCESS, self.OnMatchSuccess, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, self.OnPlayerEnterRoom, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_RECEIVE_INVITE, self.OnReceiveInvite, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_RELINK_MATE_LOAD_FAIL, self.OnMateLoadFail, self)
end

function XDlcRelinkControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MATCH, self.OnBeginMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH, self.OnCancelMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MATCH_SUCCESS, self.OnMatchSuccess, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, self.OnPlayerEnterRoom, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_RECEIVE_INVITE, self.OnReceiveInvite, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_RELINK_MATE_LOAD_FAIL, self.OnMateLoadFail, self)
end

function XDlcRelinkControl:OnRelease()
    self.FriendCache = nil
    self.FriendMap = {}
    self.LastFriendInfoSyncTime = 0
    self.CurSelectLevelData = nil
    self.QueryRankData = nil
    self.EquipSlotIndexMap = nil
    self.EquipSlotIndexMapMeta = nil
    CS.XProfilingLuaUtils.MarkPerfSightRelinkProcessInEnd()
    CS.XProfilingLuaUtils.PerfSightRelinkProcessExit()
end

--- 使用UI栈同步control的卸载
function XDlcRelinkControl:UseUiStackOperationRef()
    return true
end

function XDlcRelinkControl:InitEnum()
    -- 装备标签类型
    self.EquipTagType = {
        All = 0, -- 全部
        Attack = 1, -- 进攻
        Armor = 2, -- 装甲
        Amplitude = 3, -- 增幅
    }
    -- 装备界面类型
    self.EquipUiType = {
        Bg = 1, -- 背包
        Reform = 2, -- 改造
        Decompose = 3, -- 分解
    }
    -- 结算称号比较类型
    self.SettleTitleCompareType = {
        Bigger = 1,
        BiggerEquals = 2,
        Equals = 3,
        Smaller = 4,
        SmallerEquals = 5,
        --- 是否将数值转换为比例值
        PercentInMembers = 10,
        --- 当前玩家该值是否全员最大
        MaxInMembers = 100,
        --- 当前玩家该值是否全员最小
        MinInMembers = 200,
        --- 指定全员对应key一起比较（且逻辑）
        AllMembersCompareWithAnd = 300,
        --- 指定全员对应key一起比较（或逻辑）
        AllMembersCompareWithOr = 400,
    }
end

--region 请求协议相关

--- 切换角色风格
---@param characterId number 角色Id
---@param styleType number 风格类型
---@param cb function 回调函数
function XDlcRelinkControl:RequestSwitchStyleType(characterId, styleType, cb)
    local request = {
        CharacterId = characterId,
        StyleType = styleType,
    }
    XNetwork.Call(self.RequestName.DlcRelinkSwitchStyleTypeRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self._Model.ActivityData:SetCharacterStyleType(res.CharacterId, res.StyleType)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_SWITCH_STYLE, res.CharacterId)
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
---@param factorId number 定向合成时选择的词条Id
---@param cb function 回调函数
function XDlcRelinkControl:RequestEquipCompose(composeId, count, factorId, cb)
    local request = {
        ComposeId = composeId,
        Count = count,
        SelectedFactorId = factorId,
    }
    XNetwork.Call(self.RequestName.DlcRelinkEquipComposeRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_EQUIP_COMPOSE_SUCCESS)
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

--- 切换全局匹配标记
---@param enabled boolean 全局匹配标记
---@param cb function 回调函数
function XDlcRelinkControl:RequestSwitchGlobalMatchFlag(enabled, cb)
    local request = {
        Enabled = enabled,
    }
    XNetwork.Call(self.RequestName.DlcRelinkSwitchGlobalMatchFlagRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            if cb then cb() end
            return
        end
        self._Model.GlobalMatchEnabled = enabled
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_GLOBAL_MATCH_FLAG_CHANGE)
        if cb then cb() end
    end)
end

--- 点赞
---@param playerId number 玩家Id
---@param cb function 回调函数
function XDlcRelinkControl:RequestLike(playerId, cb)
    local request = {
        PlayerId = playerId,
    }
    XNetwork.Call(self.RequestName.DlcRelinkLikeRequest, request, function(res)
        if res.Code ~= XCode.Success then
            self:OpenCommonTipCode(res.Code)
            return
        end
        self._Model:AddLikeInfoCache(XPlayer.Id, playerId)
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
    self:RecordSelectLevelDataCache(chapterId, levelId)
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

    if self:IsGlobalMatchEnabled() then
        return 0
    end

    if not self.CurSelectLevelData then
        self.CurSelectLevelData = self:GetSelectLevelDataCache()
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

    if self:IsGlobalMatchEnabled() then
        return 0
    end

    if not self.CurSelectLevelData then
        self.CurSelectLevelData = self:GetSelectLevelDataCache()
    end

    if self.CurSelectLevelData then
        return self.CurSelectLevelData.LevelId
    end

    return self:GetDefaultLevelId()
end

--- 获取默认关卡Id 未通关则返回配置默认关卡Id 否则返回0
function XDlcRelinkControl:GetDefaultLevelId()
    local levelId = self:GetTeachingLevelId()
    if XTool.IsNumberValid(levelId) and not self:CheckLevelPassed(levelId) then
        return levelId
    end
    return 0
end

---是否教学/训练关
function XDlcRelinkControl:IsTutorialChapter()
    local levelId = self:GetCurrentSelectLevelId()
    if XTool.IsNumberValid(levelId) then
        local chapterId = self:GetLevelChapterId(levelId)
        local config = self._Model:GetChapterConfig(chapterId)
        return config.IsTutorial
    end
    return false
end

---获取当前关卡强制选择的角色Id
function XDlcRelinkControl:GetCurLevelLockCharacter()
    local levelId = self:GetCurrentSelectLevelId()
    if XTool.IsNumberValid(levelId) then
        local levelCfg = self._Model:GetLevelConfig(levelId)
        if XTool.IsNumberValid(levelCfg.LockCharacterId) then
            local charCfg = self._Model:GetCharacterConfig(levelCfg.LockCharacterId)
            return charCfg.CharacterId
        end
    end
    return nil
end

function XDlcRelinkControl:IsCurLevelLockCharacter()
    return XTool.IsNumberValid(self:GetCurLevelLockCharacter())
end

---教学关是否通关
function XDlcRelinkControl:IsTeachingLevelPass()
    local levelId = self:GetTeachingLevelId()
    if XTool.IsNumberValid(levelId) then
        return self._Model:IsTutorialPassed()
    end
    return true
end

function XDlcRelinkControl:GetTeachingLevelId()
    return self._Model:GetTeachingLevelId()
end

function XDlcRelinkControl:GetTrainingLevelId()
    return self._Model:GetTrainingLevelId()
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
    XUiManager.TipText("CommonActivityEnd")
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

-- 获取视频配置Id
function XDlcRelinkControl:GetActivityVideoConfigId()
    local config = self._Model:GetActivityConfig()
    return config and config.VideoConfigId or 0
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
    return self._Model:CheckChapterUnlock(chapterId)
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
    return self._Model:GetChapterTimeId(chapterId)
end

function XDlcRelinkControl:GetChapterConditionIds(chapterId)
    return self._Model:GetChapterConditionIds(chapterId)
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

function XDlcRelinkControl:GetChapterIsTutorial(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.IsTutorial or false
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

--- 获取角色风格类型
function XDlcRelinkControl:GetStyleTypeByCharacterId(characterId, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetStyleType()
    end
    local characterData = self:GetCharacterDataByCharacterId(characterId)
    if not characterData then
        return 0
    end
    return characterData:GetStyleType()
end

--- 获取角色属性列表
---@param characterId number 角色Id
---@param isNotSelf boolean 是否非自己角色（默认为false）
---@return table<string, number> key: 属性名 value: 属性值
function XDlcRelinkControl:GetCharacterAttributesByCharacterId(characterId, isNotSelf)
    if not XTool.IsNumberValid(characterId) then
        return {}
    end

    local styleType = self:GetStyleTypeByCharacterId(characterId, isNotSelf)
    local npcId = self:GetCharacterNpcId(characterId, styleType)
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
---@return table<number, XTableDlcRelinkCharacter> key: styleType value: 角色配置
function XDlcRelinkControl:GetCharacterConfigs(characterId)
    if not XTool.IsNumberValid(characterId) then
        return {}
    end

    local configs = {}
    for _, styleType in pairs(XEnumConst.DlcRelink.StyleTypeEnum) do
        local configId = self:GetCharacterConfigId(characterId, styleType)
        local config = self._Model:GetCharacterConfig(configId, true)
        if config then
            configs[styleType] = config
        end
    end
    return configs
end

--- 获取角色技能Id列表
---@param characterId number 角色Id
---@param styleType number 风格类型
---@param isNotSelf boolean 是否非自己角色（默认为false）
---@return table<number> 技能Id列表
function XDlcRelinkControl:GetCharacterSkillIdsByCharacterId(characterId, styleType, isNotSelf)
    if isNotSelf then
        return self.OtherMemberControl:GetCharacterSkillIdsByCharacterId(characterId, styleType)
    end

    local skillIds = self:GetCharacterSkillIds(characterId, styleType)
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

    local affectedSkillIds = self:GetFactorAffectedSkillIds(attribute.FactorId, attribute.Level)
    local newSkillIds = self:GetFactorNewSkillIds(attribute.FactorId, attribute.Level)
    if XTool.IsTableEmpty(affectedSkillIds) or XTool.IsTableEmpty(newSkillIds) then
        return skillIds
    end

    local skillReplaceMap = {}
    for i, affectedSkillId in ipairs(affectedSkillIds) do
        local newSkillId = newSkillIds[i]
        if XTool.IsNumberValid(affectedSkillId) and XTool.IsNumberValid(newSkillId) then
            skillReplaceMap[affectedSkillId] = newSkillId
        end
    end

    for index, skillId in ipairs(skillIds) do
        local newSkillId = skillReplaceMap[skillId]
        if XTool.IsNumberValid(newSkillId) then
            skillIds[index] = newSkillId
        end
    end
    return skillIds
end

--- 检查角色风格是否已解锁
function XDlcRelinkControl:CheckCharacterStyleUnlock(characterId, styleType)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(styleType) then
        return false
    end

    local conditionIds = self:GetCharacterConditionIds(characterId, styleType)
    for _, conditionId in ipairs(conditionIds) do
        if conditionId > 0 and not XConditionManager.CheckCondition(conditionId) then
            return false
        end
    end
    return true
end

--- 获取角色配置Id
function XDlcRelinkControl:GetCharacterConfigId(characterId, styleType)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(styleType) then
        return 0
    end
    return characterId * 10 + styleType
end

function XDlcRelinkControl:GetCharacterStyleName(characterId, styleType)
    local configId = self:GetCharacterConfigId(characterId, styleType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.StyleName or ""
end

function XDlcRelinkControl:GetCharacterStyleIcon(characterId, styleType)
    local configId = self:GetCharacterConfigId(characterId, styleType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.StyleIcon or ""
end

function XDlcRelinkControl:GetCharacterStyleDesc(characterId, styleType)
    local configId = self:GetCharacterConfigId(characterId, styleType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.StyleDesc or ""
end

function XDlcRelinkControl:GetCharacterOccupationType(characterId, styleType)
    local configId = self:GetCharacterConfigId(characterId, styleType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.OccupationType or 0
end

function XDlcRelinkControl:GetCharacterIsDefaultTag(characterId, styleType)
    local configId = self:GetCharacterConfigId(characterId, styleType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.IsDefaultTag or 0
end

function XDlcRelinkControl:GetCharacterNpcId(characterId, styleType)
    local configId = self:GetCharacterConfigId(characterId, styleType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.NpcId or 0
end

function XDlcRelinkControl:GetCharacterConditionIds(characterId, styleType)
    local configId = self:GetCharacterConfigId(characterId, styleType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.Condition or {}
end

function XDlcRelinkControl:GetCharacterSkillIds(characterId, styleType)
    local configId = self:GetCharacterConfigId(characterId, styleType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.SkillIds or {}
end

function XDlcRelinkControl:GetCharacterJumpWikiId(characterId, styleType)
    local configId = self:GetCharacterConfigId(characterId, styleType)
    local config = self._Model:GetCharacterConfig(configId)
    return config and config.JumpWikiId
end

--endregion

--region 风格和职业相关

function XDlcRelinkControl:GetCharacterOccupationName(characterId, styleType)
    local occupationType = self:GetCharacterOccupationType(characterId, styleType)
    return self:GetClientConfig("CharacterOccupationName", occupationType) or ""
end

function XDlcRelinkControl:GetCharacterOccupationIcon(characterId, styleType)
    local occupationType = self:GetCharacterOccupationType(characterId, styleType)
    return self:GetClientConfig("CharacterOccupationIcon", occupationType) or ""
end

function XDlcRelinkControl:GetCharacterOccupationIconTwo(characterId, styleType)
    local occupationType = self:GetCharacterOccupationType(characterId, styleType)
    return self:GetClientConfig("CharacterOccupationIconTwo", occupationType) or ""
end

function XDlcRelinkControl:GetEquipOccupationName(equipId)
    local equipOccupationType = self:GetEquipOccupationType(equipId)
    return self:GetClientConfig("EquipOccupationName", equipOccupationType) or ""
end

function XDlcRelinkControl:GetEquipOccupationIcon(equipId)
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
function XDlcRelinkControl:GetLevelPassCount(levelId)
    if not self._Model.ActivityData then
        return 0
    end
    return self._Model.ActivityData:GetLevelPassCount(levelId)
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

function XDlcRelinkControl:GetLevelFirstCoin(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.FirstCoin or 0
end

function XDlcRelinkControl:GetLevelCoin(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.Coin or 0
end

function XDlcRelinkControl:GetLevelFirstGold(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.FirstGold or 0
end

function XDlcRelinkControl:GetLevelGold(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.Gold or 0
end

function XDlcRelinkControl:GetLevelAbilityLimit(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.AbilityLimit or 0
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

function XDlcRelinkControl:GetBossSkillDescVideoConfigId(skillId)
    local config = self._Model:GetBossSkillDescConfig(skillId)
    return config and config.VideoConfigId or 0
end

function XDlcRelinkControl:GetBossSkillDescDesc(skillId)
    local config = self._Model:GetBossSkillDescConfig(skillId)
    local desc = config and config.Desc or ""
    return XUiHelper.ConvertLineBreakSymbol(desc)
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

    -- 检查通关条件
    local finishOneOfLevelIds = self:GetPlayerLevelFinishOneOfLevelIds(level)
    if not XTool.IsTableEmpty(finishOneOfLevelIds) then
        for _, levelId in pairs(finishOneOfLevelIds) do
            if self:CheckLevelPassed(levelId) then
                return true, ""
            end
        end
        -- 目前配置保证都是同难度关卡，名字只取第一个
        local showLevelName = ''
        for _, levelId in ipairs(finishOneOfLevelIds) do
            local levelName = self:GetLevelName(levelId)

            if string.IsNilOrEmpty(showLevelName) then
                showLevelName = levelName
            end
        end
        local desc = string.format(self:GetClientConfig("PlayerLevelUpConditionDesc"), showLevelName)
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

--- 装备排序方法
--- 规则：当前角色置顶（可以为空）、其它角色置底、类型降序 > 品质降序 > 等级降序 > 职业(tagType为All时才有)升序 > Uid升序
---@param entries { Uid:number, Type:number, Quality:number, Ability:number, OccupationType:number, WearerId:number } 装备列表
---@param tagType number 标签类型
---@param uiType string 界面类型
---@param characterId number 当前角色Id
function XDlcRelinkControl:SortEquipEntriesUnified(entries, tagType, uiType, characterId)
    if XTool.IsTableEmpty(entries) or #entries <= 1 then
        return
    end

    local isReverse = uiType and uiType == self.EquipUiType.Decompose  -- 分解界面排序取反
    local hasTagType = tagType and tagType == self.EquipTagType.All  -- 是否需要按职业排序

    -- 设置穿戴优先级
    for i = 1, #entries do
        local wearer = entries[i].WearerId or 0
        if uiType == self.EquipUiType.Bg and XTool.IsNumberValid(characterId) then
            -- 装备界面：当前角色穿戴置顶(0)，其它角色穿戴置底(2)，未穿戴居中(1)
            local isCur = XTool.IsNumberValid(wearer) and wearer == characterId
            local isOther = XTool.IsNumberValid(wearer) and wearer ~= characterId
            entries[i].WearRank = isCur and 0 or (isOther and 2 or 1)
        else
            -- 改造/分解界面：未穿戴置顶(0)，已穿戴置底(1)    
            entries[i].WearRank = XTool.IsNumberValid(wearer) and 1 or 0
        end
    end

    -- 排序
    table.sort(entries, function(a, b)
        -- 1. 穿戴优先级
        if a.WearRank ~= b.WearRank then
            return a.WearRank < b.WearRank
        end
        -- 2. 类型降序
        if a.Type and b.Type and a.Type ~= b.Type then
            if isReverse then
                return a.Type < b.Type
            else
                return a.Type > b.Type
            end
        end
        -- 3. 品质降序
        if a.Quality ~= b.Quality then
            if isReverse then
                return a.Quality < b.Quality
            else
                return a.Quality > b.Quality
            end
        end
        -- 4. 等级降序
        if a.Ability ~= b.Ability then
            if isReverse then
                return a.Ability < b.Ability
            else
                return a.Ability > b.Ability
            end
        end
        -- 5. 职业升序（仅当tagType为All时）
        if hasTagType and a.OccupationType and b.OccupationType and a.OccupationType ~= b.OccupationType then
            if isReverse then
                return a.OccupationType > b.OccupationType
            else
                return a.OccupationType < b.OccupationType
            end
        end
        -- 6. Uid升序/降序
        if isReverse then
            return a.Uid > b.Uid
        else
            return a.Uid < b.Uid
        end
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

--- 根据标签类型获取装备Uid列表
---@param tagType number 标签类型
---@param uiType number 界面类型
---@param filter XDlcRelinkEquipFilterCache 筛选缓存
---@param characterId number 角色Id
---@return table<number> 装备Uid列表
function XDlcRelinkControl:GetEquipUidListByTagType(tagType, uiType, filter, characterId)
    local equipDataList = self:GetEquipsDataList()
    if XTool.IsTableEmpty(equipDataList) then
        return {}
    end

    local entries = {}
    for _, equipData in pairs(equipDataList) do
        local templateId = equipData:GetTemplateId()
        local occupationType = self:GetEquipOccupationType(templateId)

        -- 检查是否匹配标签类型
        local isMatchTag = tagType == self.EquipTagType.All or tagType == occupationType
        if not isMatchTag then
            goto CONTINUE
        end

        if self:CheckEquipMatchFilter(equipData, filter) then
            local equipUid = equipData:GetUid()
            local type = self:GetEquipType(templateId)
            local quality = self:GetEquipQuality(templateId)
            local ability = equipData:GetEquipAbility()
            local wearerId = self:GetEquipWearCharacterId(equipUid)
            table.insert(entries, { Uid = equipUid, Type = type, Quality = quality, Ability = ability, WearerId = wearerId, OccupationType = occupationType })
        end

        :: CONTINUE ::
    end

    -- 排序
    self:SortEquipEntriesUnified(entries, tagType, uiType, characterId)

    -- 提取Uid列表
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
    for _, attribute in pairs(equipData:GetMainFactors()) do
        local mainSkillFactorId = self:GetEquipMainSkillFactorId(attribute.EquipTemplate)
        if mainSkillFactorId ~= attribute.FactorId then
            ability = ability + self:GetAttributeAbilityInternal(attribute)
        else
            ability = ability + self:GetEquipMainSkillFactorAbility(attribute.EquipTemplate)
        end
    end

    -- 副属性战力
    for _, slotsValue in pairs(equipData:GetAttributeSlots()) do
        for _, attribute in pairs(slotsValue.Attributes) do
            local mainSkillFactorId = self:GetEquipMainSkillFactorId(attribute.EquipTemplate)
            if mainSkillFactorId ~= attribute.FactorId then
                ability = ability + self:GetAttributeAbilityInternal(attribute)
            else
                ability = ability + self:GetEquipMainSkillFactorAbility(attribute.EquipTemplate)
            end
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
                local extendAttrs = self:GetEquipAllMainFactorByUid(extendEquipUid, isNotSelf)
                for _, attribute in pairs(extendAttrs) do
                    result[attribute.FactorId] = (result[attribute.FactorId] or 0) + addFactorLevel
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
            -- 根据叠加类型累加等级
            local levelOverlyingType = self:GetFactorDescLevelOverlyingType(factorId)
            if levelOverlyingType == XEnumConst.DlcRelink.FactorLevelOverlyingType.Overlying then
                entry.CurLevel = entry.CurLevel + level
            elseif levelOverlyingType == XEnumConst.DlcRelink.FactorLevelOverlyingType.UseMax then
                entry.CurLevel = math.max(entry.CurLevel, level)
            end
        elseif createIfMissing then
            attributeMap[factorId] = { FactorId = factorId, IsSkill = isSkill or false, CurLevel = level }
        end
    end

    for _, equipUid in pairs(equipUids) do
        -- 主属性
        local mainFactors = self:GetEquipAllMainFactorByUid(equipUid, isNotSelf)
        for _, attribute in pairs(mainFactors) do
            local mainSkillFactorId = self:GetEquipMainSkillFactorId(attribute.EquipTemplate)
            local factorId = attribute.FactorId
            AddAttr(factorId, factorId == mainSkillFactorId, attribute.Level, true)
        end

        -- 副属性
        local attributeSlots = self:GetEquipAllDeputyFactorByUid(equipUid, isNotSelf)
        for _, slotsValue in pairs(attributeSlots) do
            for _, attribute in pairs(slotsValue.Attributes) do
                local mainSkillFactorId = self:GetEquipMainSkillFactorId(attribute.EquipTemplate)
                local factorId = attribute.FactorId
                AddAttr(factorId, factorId == mainSkillFactorId, attribute.Level, true)
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

    -- 角色基础属性
    for attrStr, attrValue in pairs(characterAttributes) do
        if XTool.IsNumberValid(attrValue) then
            attributeDict[attrStr] = { AttrStr = attrStr, CharacterValue = attrValue, PlayerValue = 0, EquipValue = 0 }
        end
    end

    -- 玩家等级属性
    for attrStr, attrValue in pairs(playerAttributes) do
        if XTool.IsNumberValid(attrValue) then
            local entry = attributeDict[attrStr]
            if entry then
                entry.PlayerValue = entry.PlayerValue + attrValue
            else
                attributeDict[attrStr] = { AttrStr = attrStr, CharacterValue = 0, PlayerValue = attrValue, EquipValue = 0 }
            end
        end
    end

    -- 装备属性数据结构: { [attrStr] = { [attrType] = value } }
    local equipAttrData = {}
    -- 装备属性（非技能属性）
    for _, attribute in pairs(equipAttributes) do
        if not attribute.IsSkill then
            local factorId = attribute.FactorId
            local curLevel = attribute.CurLevel
            local params = self:GetFactorParams(factorId, curLevel)
            local attrValue = (params and params[1]) or 0

            if XTool.IsNumberValid(attrValue) then
                local attrStr = self:GetFactorDescAttributeName(factorId)
                local attrType = self:GetFactorDescAttributeType(factorId)

                if not string.IsNilOrEmpty(attrStr) then
                    -- 初始化属性数据结构
                    if not equipAttrData[attrStr] then
                        equipAttrData[attrStr] = {}
                    end
                    equipAttrData[attrStr][attrType] = (equipAttrData[attrStr][attrType] or 0) + attrValue
                end
            end
        end
    end

    -- 计算装备属性值
    -- 公式: 最终值 = (CharacterValue * (1 + 类型2百分比) + PlayerValue + 类型1基础值) * (1 + 类型4百分比) + 类型3固定值
    -- 装备值 = 最终值 - CharacterValue - PlayerValue
    for attrStr, values in pairs(equipAttrData) do
        local origin = values[XEnumConst.DlcRelink.FactorAttributeType.Origin] or 0
        local basePercentage = values[XEnumConst.DlcRelink.FactorAttributeType.BasePercentage] or 0
        local extraFixed = values[XEnumConst.DlcRelink.FactorAttributeType.ExtraFixed] or 0
        local extraPercentage = values[XEnumConst.DlcRelink.FactorAttributeType.ExtraPercentage] or 0

        local entry = attributeDict[attrStr]
        if not entry then
            entry = { AttrStr = attrStr, CharacterValue = 0, PlayerValue = 0, EquipValue = 0 }
            attributeDict[attrStr] = entry
        end

        -- 根据公式计算装备值
        local finalValue = (entry.CharacterValue * (1 + basePercentage / 10000) + entry.PlayerValue + origin) * (1 + extraPercentage / 10000) + extraFixed
        entry.EquipValue = math.floor(finalValue + 0.5) - entry.CharacterValue - entry.PlayerValue
    end

    -- 转换为列表返回
    local totalAttributes = {}
    for _, attribute in pairs(attributeDict) do
        table.insert(totalAttributes, attribute)
    end
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
            for _, attribute in pairs(equipData:GetMainFactors()) do
                factorIdSet[attribute.FactorId] = true
            end
        end
    end

    local factorIds = {}
    for factorId in pairs(factorIdSet) do
        table.insert(factorIds, factorId)
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

function XDlcRelinkControl:GetEquipMainSkillFactorAbility(equipId)
    local config = self._Model:GetEquipConfig(equipId)
    return config and config.MainSkillFactorAbility or 0
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

---@return XTableDlcRelinkEquip
function XDlcRelinkControl:GetMaxQualityEquipByFactor(factor)
    return self._Model:GetMaxQualityEquipByFactor(factor)
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

function XDlcRelinkControl:GetFactorSkillDesc(factorId, level)
    local configId = self:GetFactorConfigId(factorId, level)
    local config = self._Model:GetFactorConfig(configId)
    return config and config.SkillDesc or ""
end

function XDlcRelinkControl:GetFactorAffectedSkillIds(factorId, level)
    local configId = self:GetFactorConfigId(factorId, level)
    local config = self._Model:GetFactorConfig(configId)
    return config and config.AffectedSkillIds or {}
end

function XDlcRelinkControl:GetFactorNewSkillIds(factorId, level)
    local configId = self:GetFactorConfigId(factorId, level)
    local config = self._Model:GetFactorConfig(configId)
    return config and config.NewSkillIds or {}
end

--endregion

--region 词条描述表相关

function XDlcRelinkControl:GetFactorDescAttributeName(factorId)
    local config = self._Model:GetFactorDescConfig(factorId)
    return config and config.AttributeName or ""
end

function XDlcRelinkControl:GetFactorDescAttributeDetailShowType(factorId)
    local config = self._Model:GetFactorDescConfig(factorId)
    return config and config.DetailShowType or 1
end

function XDlcRelinkControl:GetFactorDescName(factorId)
    local config = self._Model:GetFactorDescConfig(factorId)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetFactorDescDesc(factorId)
    local config = self._Model:GetFactorDescConfig(factorId)
    local desc = config and config.Desc or ""
    return XUiHelper.ConvertLineBreakSymbol(desc)
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

function XDlcRelinkControl:GetFactorDescAttributeType(factorId)
    local config = self._Model:GetFactorDescConfig(factorId)
    return config and config.AttributeType or 0
end

function XDlcRelinkControl:GetFactorDescLevelOverlyingType(factorId)
    local config = self._Model:GetFactorDescConfig(factorId)
    return config and config.LevelOverlyingType or 0
end

function XDlcRelinkControl:GetFactorDescConfigs()
    return self._Model:GetFactorDescConfigs()
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
        -- 装备副词条分解
        local attributeSlots = self:GetEquipAllDeputyFactorByUid(equipUid)
        for _, slotsValue in pairs(attributeSlots) do
            for _, attribute in pairs(slotsValue.Attributes) do
                local fixOutputId = self:GetBreakFixOutputId(attribute.EquipTemplate)
                local factorOutputCount = self:GetBreakFactorOutputCount(attribute.EquipTemplate)
                for index, outputId in pairs(fixOutputId) do
                    local factorCount = factorOutputCount[index] or 0
                    if XTool.IsNumberValid(outputId) and factorCount > 0 then
                        itemId2Count[outputId] = (itemId2Count[outputId] or 0) + factorCount
                    end
                end
            end
        end
        -- 装备本身分解
        local equipTemplateId = self:GetEquipTemplateIdByEquipUid(equipUid)
        local fixOutputId = self:GetBreakFixOutputId(equipTemplateId)
        local fixOutputCount = self:GetBreakFixOutputCount(equipTemplateId)
        for index, outputId in pairs(fixOutputId) do
            local fixCount = fixOutputCount[index] or 0
            if XTool.IsNumberValid(outputId) and fixCount > 0 then
                itemId2Count[outputId] = (itemId2Count[outputId] or 0) + fixCount
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
function XDlcRelinkControl:GetEquipPresetSetNameByIndex(index, isDefault)
    local presetSetData = self:GetEquipPresetSetDataByIndex(index)
    local name = presetSetData and presetSetData.Name or ""
    if string.IsNilOrEmpty(name) and isDefault then
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

function XDlcRelinkControl:GetCharacterAttributeList(characterId, isNotSelf)
    local curPlayerLevel, equipUids
    if isNotSelf then
        curPlayerLevel = self.OtherMemberControl:GetPlayerLevel()
        equipUids = self.OtherMemberControl:GetWearEquipUids()
    else
        curPlayerLevel = self:GetCurrentPlayerLevel()
        equipUids = self:GetWearEquipUidsByCharacterId(characterId)
    end

    local totalAttributes = self:GetTotalAttributes(characterId, curPlayerLevel, equipUids, isNotSelf)
    local attributeList = {}
    for _, attribute in pairs(totalAttributes) do
        if self:CheckCharacterAttribExist(attribute.AttrStr) then
            attribute.Order = self:GetCharacterAttribOrder(attribute.AttrStr)
            table.insert(attributeList, attribute)
        end
    end
    table.sort(attributeList, function(a, b)
        return a.Order < b.Order
    end)
    return attributeList
end

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

function XDlcRelinkControl:GetSkillDescSubtitle(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.Subtitle or ""
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

function XDlcRelinkControl:GetSkillDescVideoConfigId(id)
    local config = self._Model:GetSkillDescConfig(id)
    return config and config.VideoConfigId or 0
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
        local params = self:GetShopTaskParamId(id)
        local taskTimelineId = params and params[1] or 0
        if XTool.IsNumberValidEx(taskTimelineId) then
            local taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskTimelineId)
            if not XTool.IsTableEmpty(taskDataList) then
                for _, taskData in ipairs(taskDataList) do
                    local taskId = taskData.Id
                    if taskData and taskData.State ~= XDataCenter.TaskManager.TaskState.Finish then
                        return taskId
                    end
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
    -- 1.货币
    local firstCoin = self:GetLevelFirstCoin(levelId)
    if firstCoin > 0 then
        table.insert(rewardGoods, XRewardManager.CreateRewardGoods(XDataCenter.ItemManager.ItemId.DlcRelinkStoreCoin, firstCoin))
    end
    -- 2.金币
    local firstGold = self:GetLevelFirstGold(levelId)
    if firstGold > 0 then
        table.insert(rewardGoods, XRewardManager.CreateRewardGoods(XDataCenter.ItemManager.ItemId.DlcRelinkGameplayCoin, firstGold))
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
    -- 1.货币
    local coinCount = self:GetLevelCoin(levelId)
    if coinCount > 0 then
        table.insert(rewardGoods, XRewardManager.CreateRewardGoods(XDataCenter.ItemManager.ItemId.DlcRelinkStoreCoin, coinCount))
    end
    -- 2.金币
    local goldCount = self:GetLevelGold(levelId)
    if goldCount > 0 then
        table.insert(rewardGoods, XRewardManager.CreateRewardGoods(XDataCenter.ItemManager.ItemId.DlcRelinkGameplayCoin, goldCount))
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

function XDlcRelinkControl:GetShowLevelDropQuality(id)
    local config = self._Model:GetShowLevelDropConfig(id)
    return config and config.Quality or 0
end

function XDlcRelinkControl:GetShowLevelDropQualityIcon(id)
    local quality = self:GetShowLevelDropQuality(id)
    return self:GetEquipQualityAssets(quality)
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

---定向合成出现条件（返回值是string[]需要转成number[]）
function XDlcRelinkControl:GetTargetingComposeConsumeConditionIds()
    return self._Model:GetConfigParams("TargetingComposeConsumeConditionIds")
end

--- 全局匹配开启条件 (返回值是string[]需要转成number[]）
function XDlcRelinkControl:GetGlobalMatchEnableConditionIds()
    return self._Model:GetConfigParams("GlobalMatchEnableCondition")
end

--- 全局匹配奖励每日掉落次数
function XDlcRelinkControl:GetTotalGlobalMatchRewardTimes()
    local num = self:GetConfig("GlobalMatchRewardTimes")
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
    XDataCenter.GuideManager.SetDisableGuide(true)
    XLuaUiManager.Open("UiDlcRelinkMatching")
end

function XDlcRelinkControl:OnCancelMatching()
    ---@type XUiDlcRelinkMatching
    local luaUi = XLuaUiManager.GetTopLuaUi("UiDlcRelinkMatching")
    if luaUi then
        luaUi:OnClose()
    end
    XDataCenter.GuideManager.SetDisableGuide(false)
end

function XDlcRelinkControl:OnMatchSuccess()
    --self:OpenCommonTipText("MatchSuccessTips")
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
    -- 引导中不处理邀请
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    -- 只在主界面和房间界面处理邀请
    if not XLuaUiManager.IsUiShow("UiDlcRelinkMain") and not XLuaUiManager.IsUiShow("UiDlcRelinkRoom") then
        return
    end
    XMVCA.XDlcRoom:CheckReceiveInvitation()
end

--- 匹配加载失败处理
function XDlcRelinkControl:OnMateLoadFail()
    self:CommonRunRelinkRoomUiHandle(self:GetClientConfig("LoadingReturnRoomTips"))
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

--- 通用返回Relink主界面处理
function XDlcRelinkControl:CommonRunRelinkMainUiHandle(tipContent, callback)
    local uiName = "UiDlcRelinkMain"
    local function openMainCallback()
        if not string.IsNilOrEmpty(tipContent) then
            self:OpenCommonTipMsg(tipContent)
        end
        if callback then
            callback()
        end
    end
    if XLuaUiManager.IsStackUiOpen(uiName) then
        XLuaUiManager.CloseAllUpperUiWithCallback(uiName, openMainCallback)
    else
        XLuaUiManager.OpenWithCallback(uiName, openMainCallback)
    end
end

--- 通过返回Relink房间界面处理
function XDlcRelinkControl:CommonRunRelinkRoomUiHandle(tipContent, callback)
    local mainUiName = "UiDlcRelinkMain"
    local roomUiName = "UiDlcRelinkRoom"
    local function openRoomCallback()
        if not string.IsNilOrEmpty(tipContent) then
            self:OpenCommonTipMsg(tipContent)
        end
        if callback then
            callback()
        end
    end
    if XLuaUiManager.IsStackUiOpen(mainUiName) then
        if XLuaUiManager.IsStackUiOpen(roomUiName) then
            XLuaUiManager.CloseAllUpperUiWithCallback(roomUiName, openRoomCallback)
        else
            XLuaUiManager.OpenWithCallback(roomUiName, openRoomCallback)
        end
    else
        XLuaUiManager.OpenWithCallback(mainUiName, function()
            XLuaUiManager.OpenWithCallback(roomUiName, openRoomCallback)
        end)
    end
end

--- 检查当前队伍职业是否合理
---@param team XDlcTeam 队伍对象
---@param chapterId number 章节Id
---@return boolean, number[] 是否合理, 缺少的职业列表
function XDlcRelinkControl:CheckTeamOccupationRational(team, chapterId)
    if not team then
        return false, {}
    end

    local trueOccupationList = self:GetChapterTrueOccupations(chapterId)
    if XTool.IsTableEmpty(trueOccupationList) then
        return true, {}
    end

    -- 收集队伍中已有的职业类型
    local occupationMap = {}
    local amount = team:GetMemberNumber()
    for pos = 1, amount do
        local member = team:GetMember(pos)
        if member and not member:IsEmpty() then
            local occupationType = self:GetCharacterOccupationType(member:GetCharacterId(), member:GetStyleType())
            occupationMap[occupationType] = true
        end
    end

    -- 检查缺失的职业类型
    local lackOccupationList = {}
    for _, occupationType in ipairs(trueOccupationList) do
        if not occupationMap[occupationType] then
            table.insert(lackOccupationList, occupationType)
        end
    end

    return #lackOccupationList == 0, lackOccupationList
end

--- 检查当前队伍装备战力是否合理
---@param team XDlcTeam 队伍对象
---@param abilityLimit number 战力限制
---@return boolean 是否合理
function XDlcRelinkControl:CheckTeamEquipAbilityRational(team, abilityLimit)
    if not team then
        return false
    end

    local amount = team:GetMemberNumber()
    for pos = 1, amount do
        local member = team:GetMember(pos)
        if member and not member:IsEmpty() then
            local totalAbility = member:GetRelinkEquipTotalAbility()
            if totalAbility < abilityLimit then
                return false
            end
        end
    end
    return true
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

function XDlcRelinkControl:OpenCommonTipSuccess(msg, cb, hideCloseMark)
    self:OpenCommonTipMsg(msg, XUiManager.UiTipType.Success, cb, hideCloseMark)
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

-- 设置结算缓存关卡数据
function XDlcRelinkControl:SetSettlementCacheLevelData(levelId)
    self._Model.SettlementCacheData = self._Model.SettlementCacheData or {}
    self._Model.SettlementCacheData.LevelId = levelId
    self._Model.SettlementCacheData.IsPassed = self:CheckLevelPassed(levelId)
end

-- 检查结算缓存关卡数据是否为首次通关
function XDlcRelinkControl:CheckSettlementCacheLevelFirstPass(levelId)
    local cacheData = self:GetSettlementCacheData()
    local isValid = cacheData and XTool.IsNumberValid(cacheData.LevelId) and cacheData.LevelId == levelId
    return isValid and not cacheData.IsPassed and self:CheckLevelPassed(levelId) or false
end

--endregion

--region 百科全书相关

---@return XTableDlcRelinkWiki
function XDlcRelinkControl:GetWikiConfigById(id)
    return self._Model:GetWikiConfigById(id)
end

---@return XTableDlcRelinkWiki[]
function XDlcRelinkControl:GetWikiConfigs()
    return self._Model:GetWikiConfigs()
end

function XDlcRelinkControl:GetHasWikiBeenViewed(wikiId)
    return self._Model:GetHasWikiBeenViewed(wikiId)
end

function XDlcRelinkControl:SetWikiHasBeenViewed(wikiId)
    self._Model:SetWikiHasBeenViewed(wikiId)
end

--endregion

--region 机制教学相关

---@return XTableDlcRelinkMechanismTeach
function XDlcRelinkControl:GetMechanismTeachById(id)
    return self._Model:GetMechanismTeachById(id)
end

---@return XTableDlcRelinkMechanismTeach
function XDlcRelinkControl:GetMechanismTeachByLevelId(levelId)
    return self._Model:GetMechanismTeachByLevelId(levelId)
end

function XDlcRelinkControl:SetMechanismTeachHasBeenViewed(id)
    self._Model:SetMechanismTeachHasBeenViewed(id)
end

--endregion

--region 本地信息相关

--- 获取角色风格查看状态的存储Key
function XDlcRelinkControl:GetCharacterStyleViewedKey(characterId, styleType)
    local activityId = self._Model.ActivityData and self._Model.ActivityData:GetActivityId() or 0
    return string.format("DlcRelinkCharacterStyleViewed_%s_%s_%s_%s", XPlayer.Id, activityId, characterId, styleType)
end

--- 检查角色风格是否已查看
function XDlcRelinkControl:CheckCharacterStyleViewed(characterId, styleType)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(styleType) then
        return false
    end
    local key = self:GetCharacterStyleViewedKey(characterId, styleType)
    return XSaveTool.GetData(key) or false
end

--- 记录角色风格为已查看
function XDlcRelinkControl:RecordCharacterStyleViewed(characterId, styleType)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(styleType) then
        return
    end
    local key = self:GetCharacterStyleViewedKey(characterId, styleType)
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

--- 获取缓存的关卡和章节的存储Key
function XDlcRelinkControl:GetSelectLevelDataKey()
    local activityId = self._Model.ActivityData and self._Model.ActivityData:GetActivityId() or 0
    return string.format("DlcRelinkSelectLevelData_%s_%s", XPlayer.Id, activityId)
end

--- 获取缓存的关卡和章节
function XDlcRelinkControl:GetSelectLevelDataCache()
    local key = self:GetSelectLevelDataKey()
    local data = XSaveTool.GetData(key)
    if data and XTool.IsNumberValid(data.ChapterId) and XTool.IsNumberValid(data.LevelId) and not self:GetChapterIsTutorial(data.ChapterId) then
        if not self:CheckLevelPassed(data.LevelId) then
            return nil
        end
        return data
    end
    return nil
end

--- 记录缓存的关卡和章节
function XDlcRelinkControl:RecordSelectLevelDataCache(chapterId, levelId)
    local key = self:GetSelectLevelDataKey()
    local data = false
    if XTool.IsNumberValid(chapterId) and XTool.IsNumberValid(levelId) and not self:GetChapterIsTutorial(chapterId) then
        data = { ChapterId = chapterId, LevelId = levelId }
    end
    XSaveTool.SaveData(key, data)
end

--- 获取技能描述是否为详细
function XDlcRelinkControl:GetSkillDescIsDetail()
    return self._Model:GetSkillDescIsDetail()
end

--- 设置技能描述是否为详细
function XDlcRelinkControl:SetSkillDescIsDetail(isDetail)
    self._Model:SetSkillDescIsDetail(isDetail)
end

--- 获取装备描述是否为详细
function XDlcRelinkControl:GetEquipAttrDescIsDetail()
    return self._Model:GetEquipAttrDescIsDetail()
end

--- 设置装备描述是否为详细
function XDlcRelinkControl:SetEquipAttrDescIsDetail(isDetail)
    self._Model:SetEquipAttrDescIsDetail(isDetail)
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

    local taskTimelineIds = self:GetShopTaskParamId(configId)
    if XTool.IsTableEmpty(taskTimelineIds) then
        return false
    end

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
    return false
end

--- 检查角色风格是否有新解锁的红点
function XDlcRelinkControl:CheckCharacterStyleHasNewUnlock(characterId, styleType)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(styleType) then
        return false
    end
    -- 风格未解锁，不显示红点
    if not self:CheckCharacterStyleUnlock(characterId, styleType) then
        return false
    end
    -- 风格已查看，不显示红点
    if self:CheckCharacterStyleViewed(characterId, styleType) then
        return false
    end
    return true
end

--- 检查当前角色是否有新解锁的风格红点
function XDlcRelinkControl:CheckCharacterHasAnyNewStyle(characterId)
    if not XTool.IsNumberValid(characterId) then
        return false
    end
    for _, styleType in pairs(XEnumConst.DlcRelink.StyleTypeEnum) do
        local configId = self:GetCharacterConfigId(characterId, styleType)
        local config = self._Model:GetCharacterConfig(configId, true)
        if config and self:CheckCharacterStyleHasNewUnlock(characterId, styleType) then
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
    local hasCost = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.DlcRelinkGameplayCoin)
    if hasCost < needCost then
        return false
    end
    return true
end

--endregion

--region 网络切换提示

function XDlcRelinkControl:CheckNeedPopWifiTips()
    -- 有引导时不弹
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    local isWifi = CS.XNetworkReachability.IsViaLocalArea()

    -- 当前网络连接wifi或者不需要提示则跳过
    if isWifi or not self._Model:CheckNeedPopWifiTips() then
        return
    end
    local title = self:GetClientConfig("TipTitle")
    local data = self:GetClientConfig("WifiSwitchTips")

    -- 只弹提示, 确认和取消都不需要其他动作
    self:OpenCommonTipDialog(title, data)
    self._Model:ClearWifiTipsPopMark()
end

--endregion

--region 战斗称号
function XDlcRelinkControl:GetBattleTitleIdsByCustomData(customDatas, ownPlayerId)
    if not customDatas then
        return
    end

    local cfgs = self._Model:GetMedalTagConfigs()

    local battleTitleIdMap = {}
    local player2Data = {}

    if cfgs then
        -- 遍历规则要求：
        -- 配置上Id按照连续流水配，并且高级的在低级的后面
        -- 这样才能确保按顺序遍历，且高级称号能够覆盖掉低级称号
        for i, v in pairs(cfgs) do
            local isSatisfy = true

            if not XTool.IsTableEmpty(v.CompareKeys) then
                for index, key in pairs(v.CompareKeys) do
                    local targetVal = v.CompareValues[index] or 0
                    local opType = v.CompareTypes[index] or 0

                    if not self:_CheckResult(customDatas, key, opType, targetVal, ownPlayerId, player2Data) then
                        isSatisfy = false
                        break
                    end
                end
            end

            if isSatisfy then
                battleTitleIdMap[v.Id] = true

                if not XTool.IsTableEmpty(v.CoverIds) then
                    for _, coverId in pairs(v.CoverIds) do
                        battleTitleIdMap[coverId] = nil
                    end
                end
            end
        end
    end

    -- 转成列表
    local list = nil

    if not XTool.IsTableEmpty(battleTitleIdMap) then
        list = {}

        for id, _ in pairs(battleTitleIdMap) do
            table.insert(list, id)
        end

        -- 按照Id降序排序
        table.sort(list, function(a, b)
            local aCfg = self._Model:GetMedalTagConfig(a)
            local bCfg = self._Model:GetMedalTagConfig(b)

            local aPriority = aCfg and aCfg.Priority or 0
            local bPriority = bCfg and bCfg.Priority or 0

            return aPriority > bPriority
        end)

        local curCount = XTool.GetTableCount(list)
        local maxCount = self._Model:GetClientConfigBattleSettleShowTitleMaxCount()

        if curCount > maxCount then
            for i = maxCount + 1, curCount do
                list[i] = nil
            end
        end
    end

    return list
end

---@param player2ValueData table<number, number> @用于table复用的对象，存的是各个玩家用于比较的值
function XDlcRelinkControl:_CheckResult(customDatas, key, opType, rightVal, ownPlayerId, player2ValueData)
    local customData = customDatas[ownPlayerId]
    local ownReocrd = customData and customData.Dict or {}
    local leftValue = ownReocrd[key] or 0

    local totalValue = 0
    local maxValue = 0
    local minValue = math.maxinteger
    local leftPercentValue = leftValue

    local leftValOp = math.floor((math.fmod(opType, 100)))

    player2ValueData = player2ValueData or {}


    -- 默认收集所有玩家该key的总值和上下限
    for playerId, v in pairs(customDatas) do
        if v.Dict then
            local val = v.Dict[key] or 0

            totalValue = totalValue + val

            if val > maxValue then
                maxValue = val
            end

            if val < minValue then
                minValue = val
            end

            player2ValueData[playerId] = val
        else
            player2ValueData[playerId] = 0
        end
    end

    -- 判断是否需要对左操作数进行处理
    -- 后续扩展时从最大的十位数开始向下依次判断
    if leftValOp >= self.SettleTitleCompareType.PercentInMembers then
        -- 需要将各个玩家该key值转换为比例数
        if totalValue > 0 then
            -- 配置表整型，比例数*100
            for playerId, _ in pairs(customDatas) do
                player2ValueData[playerId] = player2ValueData[playerId] / totalValue * 100
            end
            leftPercentValue = player2ValueData[ownPlayerId] or 0
        end
    end

    -- 获取表示比较运算符的部分
    local compareOp = opType

    if compareOp >= 100 then
        compareOp = math.fmod(compareOp, 100)
    end

    if compareOp >= 10 then
        compareOp = math.fmod(compareOp, 10)
    end

    -- 判断是否有特殊的判断
    if opType >= self.SettleTitleCompareType.AllMembersCompareWithOr then
        -- 判断全员中任意值是否满足运算
        for i, value in pairs(player2ValueData) do
            if self:_CheckCompareResult(value, compareOp, rightVal) then
                return true
            end
        end

        -- 没有值或不满足
        return false
    elseif opType >= self.SettleTitleCompareType.AllMembersCompareWithAnd then
        -- 没有值则不满足
        if XTool.IsTableEmpty(player2ValueData) then
            return false
        end

        -- 判断全员中所有值是否满足运算
        for i, value in pairs(player2ValueData) do
            if not self:_CheckCompareResult(value, compareOp, rightVal) then
                return false
            end
        end

        return true

    elseif opType >= self.SettleTitleCompareType.MinInMembers then
        -- 如果全都是0的话则不生效
        if maxValue == 0 and minValue == 0 then
            return false
        end

        return leftValue <= minValue
    elseif opType >= self.SettleTitleCompareType.MaxInMembers then
        -- 如果全都是0的话则不生效
        if maxValue == 0 and minValue == 0 then
            return false
        end

        return leftValue >= maxValue
    else
        -- 右侧变量初始化时已经赋值为leftValue，如果没有经过百分比处理，这里不影响数值
        leftValue = leftPercentValue

        return self:_CheckCompareResult(leftValue, compareOp, rightVal)
    end
end

function XDlcRelinkControl:_CheckCompareResult(leftVal, opType, rightVal)
    if opType == self.SettleTitleCompareType.Bigger then
        return leftVal > rightVal
    elseif opType == self.SettleTitleCompareType.BiggerEquals then
        return leftVal >= rightVal
    elseif opType == self.SettleTitleCompareType.Equals then
        return leftVal == rightVal
    elseif opType == self.SettleTitleCompareType.Smaller then
        return leftVal < rightVal
    elseif opType == self.SettleTitleCompareType.SmallerEquals then
        return leftVal <= rightVal
    end

    return false
end

---@param customData table<any, any>
function XDlcRelinkControl:GetFixedScore(customData)
    local score = 0

    local battleReocrd = customData and customData.Dict or nil

    if not XTool.IsTableEmpty(battleReocrd) then
        for key, value in pairs(battleReocrd) do
            local fixedVal = self:GetFixedValue(key, value)

            score = score + fixedVal
        end
    end

    return math.ceil(score)
end

function XDlcRelinkControl:GetFixedValue(key, value)
    if not XTool.IsNumberValidEx(value) then
        return 0
    end

    local factorCfg = self._Model:GetDlcRelinkSummaryFactorConfig(key, true)

    if factorCfg then
        local factor = factorCfg.Factor or 0

        return value * factor
    else
        -- 没有配置视为不计入分数
        return 0
    end
end
--endregion

--region 全局匹配相关

--- 获取今日全局匹配奖励获取次数
function XDlcRelinkControl:GetGlobalMatchRewardTimes()
    if not self._Model.ActivityData then
        return 0
    end
    return self._Model.ActivityData:GetGlobalMatchRewardTimes()
end

--- 检查全局匹配开启条件是否达成
function XDlcRelinkControl:CheckGlobalMatchEnableCondition()
    local conditionIds = self:GetGlobalMatchEnableConditionIds()
    if XTool.IsTableEmpty(conditionIds) then
        return true
    end
    for _, conditionId in ipairs(conditionIds) do
        if not XConditionManager.CheckCondition(tonumber(conditionId)) then
            return false
        end
    end
    return true
end

--- 是否开启了全局匹配
function XDlcRelinkControl:IsGlobalMatchEnabled()
    return self._Model.GlobalMatchEnabled
end

--endregion

--region 点赞相关

--- 获取玩家被点赞次数
---@param playerId number 玩家Id
function XDlcRelinkControl:GetPlayerLikeCount(playerId)
    if not self._Model.LikeInfoCache then
        return 0
    end

    local count = 0
    for _, toPlayerMap in pairs(self._Model.LikeInfoCache) do
        if toPlayerMap and toPlayerMap[playerId] then
            count = count + 1
        end
    end
    return count
end

--- 清理点赞缓存数据
function XDlcRelinkControl:ClearLikeInfoCache()
    self._Model.LikeInfoCache = nil
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
---@field LevelId number 关卡Id
---@field IsPassed boolean 关卡是否已通关

---@class XDlcRelinkQueryRank
---@field TotalCount number 排行榜总队伍数
---@field RankTeamInfos XDlcRelinkRankTeamInfo[]
---@field SelfTopRankTeamInfos XDlcRelinkRankTeamInfo
---@field SelfRank number 个人数据排名
