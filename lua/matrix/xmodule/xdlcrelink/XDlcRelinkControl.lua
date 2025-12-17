---@class SelectLevelData
---@field ChapterId number 章节Id
---@field LevelId number 等级Id

local XDlcRelinkFriend = require("XModule/XDlcRelink/XEntity/XDlcRelinkFriend")
---@class XDlcRelinkControl : XControl
---@field private _Model XDlcRelinkModel
local XDlcRelinkControl = XClass(XControl, "XDlcRelinkControl")
function XDlcRelinkControl:OnInit()
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
    }

    self.FriendCache = nil
    ---@type XDlcRelinkFriend[]
    self.FriendMap = {}
    self.FriendInfoSyncTime = 20
    self.LastFriendInfoSyncTime = 0

    self.TempLevelId = 0  -- 临时存储当前等级Id

    ---@type SelectLevelData
    self.CurSelectLevelData = nil -- 当前选择的等级数据
end

function XDlcRelinkControl:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MATCH, self.OnBeginMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH, self.OnCancelMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MATCH_SUCCESS, self.OnMatchSuccess, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, self.OnPlayerEnterRoom, self)
end

function XDlcRelinkControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MATCH, self.OnBeginMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH, self.OnCancelMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MATCH_SUCCESS, self.OnMatchSuccess, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, self.OnPlayerEnterRoom, self)
end

function XDlcRelinkControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
    self.FriendCache = nil
    self.FriendMap = {}
    self.LastFriendInfoSyncTime = 0

    self.CurSelectLevelData = nil
end

--region 请求协议相关

--- 切换出战角色
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
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新数据
        if cb then cb() end
    end)
end

--- 切换出战角色
---@param id number 角色配置Id
---@param cb function 回调函数
function XDlcRelinkControl:RequestSwitchBattleCharacter(id, cb)
    local request = {
        Id = id,
    }
    XNetwork.Call(self.RequestName.DlcRelinkSwitchBattleCharacterRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.ActivityData:SetFightCharacterId(res.CharacterId)
        -- TODO OccupationType
        if cb then cb() end
    end)
end

--- 购买经验
---@param cb function 回调函数
function XDlcRelinkControl:RequestBuyExp(cb)
    XNetwork.Call(self.RequestName.DlcRelinkBuyExpRequest, {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新数据
        if cb then cb() end
    end)
end

--- 签到
---@param cb function 回调函数
function XDlcRelinkControl:RequestSign(cb)
    XNetwork.Call(self.RequestName.DlcRelinkSignRequest, {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新数据
        if cb then cb() end
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
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新数据
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
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新数据
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
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新数据
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
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新数据
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
        EquipSlotIndex = equipSlotIndex,
        EquipUid = equipUid,
    }
    XNetwork.Call(self.RequestName.DlcRelinkWearEquipRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新数据
        if cb then cb() end
    end)
end

--- 卸下装备
---@param characterId number 角色Id
---@param equipSlotIndex number 装备栏位索引
---@param equipUid number 装备Uid
---@param cb function 回调函数
function XDlcRelinkControl:RequestUnwearEquip(characterId, equipSlotIndex, equipUid, cb)
    local request = {
        CharacterId = characterId,
        EquipSlotIndex = equipSlotIndex,
        EquipUid = equipUid,
    }
    XNetwork.Call(self.RequestName.DlcRelinkUnwearEquipRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新数据
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
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新数据
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
            XUiManager.TipCode(res.Code)
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
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新数据
        if cb then cb() end
    end)
end

--endregion

--region 好友相关

function XDlcRelinkControl:OpenFriendInviteUi(uiName)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialFriend) then
        return
    end

    local nowTime = XTime.GetServerNowTimestamp()
    if not self.FriendCache or self.LastFriendInfoSyncTime + self.FriendInfoSyncTime <= nowTime then
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

        XDataCenter.SocialManager.GetPlayerInfoListByServer(playerIds, function(friendInfoList)
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
            XLuaUiManager.Open(uiName, self.FriendCache)
        end)
    else
        XLuaUiManager.Open(uiName, self.FriendCache)
    end
end

function XDlcRelinkControl:SortFriendList(friendInfoList)
    if not friendInfoList or #friendInfoList <= 1 then
        return friendInfoList or {}
    end
    table.sort(friendInfoList, function(a, b) return self:SortFriendListHandler(a, b) end)
    return friendInfoList
end

function XDlcRelinkControl:SortFriendListHandler(friendA, friendB)
    if friendA.IsOnline ~= friendB.IsOnline then
        return friendA.IsOnline
    end

    if friendA.IsOnline then
        -- 都在线，按亲密度、等级降序
        if friendA.FriendExp ~= friendB.FriendExp then
            return friendA.FriendExp > friendB.FriendExp
        end
        return friendA.Level > friendB.Level
    else
        -- 都不在线，按最后登录时间、亲密度、等级降序
        if friendA.LastLoginTime ~= friendB.LastLoginTime then
            return friendA.LastLoginTime > friendB.LastLoginTime
        end
        if friendA.FriendExp ~= friendB.FriendExp then
            return friendA.FriendExp > friendB.FriendExp
        end
        return friendA.Level > friendB.Level
    end
end

--endregion

--region 临时等级Id

function XDlcRelinkControl:SetCurrentLevelId(levelId)
    if not XTool.IsNumberValid(levelId) then
        return
    end
    self.TempLevelId = levelId
end

function XDlcRelinkControl:GetCurrentLevelId()
    if not XTool.IsNumberValid(self.TempLevelId) then
        return 90002 -- 默认等级ID
    end
    return self.TempLevelId
end

function XDlcRelinkControl:GetCurrentWorldIdAndLevelId()
    local worldId = self:GetActivityWorldId()
    local levelId = self:GetCurrentLevelId()
    return worldId, levelId
end

--endregion

--region 当前等级数据相关

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

function XDlcRelinkControl:GetCurrentSelectChapterId()
    if XMVCA.XDlcRoom:IsInRoom() then
        ---@type XDlcRoomData
        local roomData = XMVCA.XDlcRoom:GetRoomData()
        if not roomData then
            return nil
        end
        return self:GetLevelChapterId(roomData:GetLevelId())
    end
    return self.CurSelectLevelData and self.CurSelectLevelData.ChapterId or 0
end

function XDlcRelinkControl:GetCurrentSelectLevelId()
    if XMVCA.XDlcRoom:IsInRoom() then
        ---@type XDlcRoomData
        local roomData = XMVCA.XDlcRoom:GetRoomData()
        if not roomData then
            return nil
        end
        return roomData:GetLevelId()
    end
    return self.CurSelectLevelData and self.CurSelectLevelData.LevelId or 0
end

--endregion

--region 通用

function XDlcRelinkControl:CheckPlayerInRoom(playerId)
    if not XTool.IsNumberValid(playerId) then
        return false
    end
    if XMVCA.XDlcRoom:IsInRoom() then
        local team = XMVCA.XDlcRoom:GetTeam()
        return team and team:IsPlayerInTeam(playerId) or false
    end
    return false
end

function XDlcRelinkControl:GetLoadingTips()
    local tips = self._Model:GetClientConfigParams("LoadingTips")
    return XTool.RandomArray(tips, os.time())
end

--endregion

--region 活动表相关

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

-- 获取活动商店Id
function XDlcRelinkControl:GetActivityShopId()
    local config = self._Model:GetActivityConfig()
    return config and config.ShopId or 0
end

-- 获取活动章节Id列表
function XDlcRelinkControl:GetActivityChapterIds()
    local config = self._Model:GetActivityConfig()
    return config and config.ChapterIds or {}
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
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.LevelIds or {}
end

function XDlcRelinkControl:GetChapterName(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetChapterIcon(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.Icon or ""
end

function XDlcRelinkControl:GetChapterSkills(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.Skills or {}
end

function XDlcRelinkControl:GetChapterOdSkills(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.OdSkills or {}
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

function XDlcRelinkControl:GetCharacterDataByCharacterId(characterId)
    if not self._Model.ActivityData then
        return nil
    end
    return self._Model.ActivityData:GetCharacterDataByCharacterId(characterId)
end

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

function XDlcRelinkControl:GetOccupationTypeByCharacterId(characterId)
    local characterData = self:GetCharacterDataByCharacterId(characterId)
    if not characterData then
        return 0
    end
    return characterData:GetOccupationType()
end

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

function XDlcRelinkControl:GetLevelFinishTime(levelId)
    if not self._Model.ActivityData then
        return 0
    end
    return self._Model.ActivityData:GetLevelFinishTime(levelId)
end

function XDlcRelinkControl:GetLevelFinishCount(levelId)
    return 0 -- TODO
end

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

function XDlcRelinkControl:CheckLevelUnlock(levelId)
    if not XTool.IsNumberValid(levelId) then
        return false
    end

    local preLevelId = self:GetLevelPreLevelId(levelId)
    if preLevelId > 0 and not self:CheckLevelPassed(preLevelId) then
        return false
    end

    local timeId = self:GetLevelTimeId(levelId)
    if timeId > 0 and not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false
    end

    local conditionIds = self:GetLevelConditionIds(levelId)
    for _, conditionId in ipairs(conditionIds) do
        if conditionId > 0 and not XConditionManager.CheckCondition(conditionId) then
            return false
        end
    end
    return true
end

function XDlcRelinkControl:CheckLevelPassed(levelId)
    if not XTool.IsNumberValid(levelId) or not self._Model.ActivityData then
        return false
    end
    return self._Model.ActivityData:IsLevelPassed(levelId)
end

function XDlcRelinkControl:GetLevelName(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.Name or ""
end

function XDlcRelinkControl:GetLevelPreLevelId(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.PreLevelId or 0
end

function XDlcRelinkControl:GetLevelChapterId(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.ChapterId or 0
end

function XDlcRelinkControl:GetLevelTimeId(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.TimeId or 0
end

function XDlcRelinkControl:GetLevelConditionIds(levelId)
    local config = self._Model:GetLevelConfig(levelId)
    return config and config.Condition or {}
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

--region 装备表相关

function XDlcRelinkControl:GetEquipsDataList()
    if not self._Model.ActivityData then
        return {}
    end
    return self._Model.ActivityData:GetEquipsDataList()
end

function XDlcRelinkControl:GetEquipDataByUid(equipUid)
    if not self._Model.ActivityData then
        return nil
    end
    return self._Model.ActivityData:GetEquipsDataByUid(equipUid)
end

function XDlcRelinkControl:GetEquipUidListBySlotAndOccType(characterId, slotIndex, occupationType)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(slotIndex) or not XTool.IsNumberValid(occupationType) then
        return {}
    end

    local equipDataList = self:GetEquipsDataList()
    if XTool.IsTableEmpty(equipDataList) then
        return {}
    end

    local equipUids = {}
    local curEquipType = slotIndex == 1 and XEnumConst.DlcRelink.EquipType.Main or XEnumConst.DlcRelink.EquipType.Normal
    for _, equipData in pairs(equipDataList) do
        local templateId = equipData:GetTemplateId()
        if self:GetEquipType(templateId) == curEquipType and self:GetEquipOccupationType(templateId) == occupationType then
            table.insert(equipUids, equipData:GetUid())
        end
    end
    -- TODO 排序
    return equipUids

end

--- 获取角色所穿戴的装备Uid，未穿戴返回0
function XDlcRelinkControl:GetEquipUIdByCharacterId(characterId, index)
    local characterData = self:GetCharacterDataByCharacterId(characterId)
    if not characterData then
        return 0
    end
    return characterData:GetEquipBySlot(index)
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

function XDlcRelinkControl:GetEquipTotalAbilityByCharacterId(characterId)
    local characterData = self:GetCharacterDataByCharacterId(characterId)
    if not characterData then
        return 0
    end

    local equipDict = characterData:GetEquip()
    if XTool.IsTableEmpty(equipDict) then
        return 0
    end

    local totalEquipAbility = 0
    for _, equipUid in pairs(equipDict) do
        totalEquipAbility = totalEquipAbility + self:GetEquipAbilityByUid(equipUid)
    end
    return totalEquipAbility
end

function XDlcRelinkControl:GetEquipTemplateIdByEquipUId(equipUid)
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return 0
    end
    return equipData:GetTemplateId()
end

function XDlcRelinkControl:GetEquipIsLockedByEquipUId(equipUid)
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return false
    end
    return equipData:GetIsLocked()
end

function XDlcRelinkControl:GetEquipAbilityByUid(equipUid)
    local equipData = self:GetEquipDataByUid(equipUid)
    if not equipData then
        return 0
    end
    return equipData:GetEquipAbility()
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
    XLuaUiManager.Close("UiDlcRelinkMatching")
end

function XDlcRelinkControl:OnMatchSuccess()
    XUiManager.TipMsg(self._Model:GetClientConfig("MatchSuccess", 1))
end

function XDlcRelinkControl:OnPlayerEnterRoom()
    -- TODO 当有队友加入房间时,无论玩家在哪个界面,都需要有侧边toast:xxx加入房间
    XUiManager.TipMsg("测试-进入房间")
end

--endregion

return XDlcRelinkControl
