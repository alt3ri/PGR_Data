local SceneIds = require("XModule/XScene/XScene/XLuaSceneDefine").SceneIds

---@class XTheatre6Control : XControl
---@field private _Model XTheatre6Model
local XTheatre6Control = XClass(XControl, "XTheatre6Control", true)

local RoomType = XEnumConst.Theatre6.RoomType
local EventRewardType = XEnumConst.Theatre6.EventRewardType
local ChooseRoomStatus = XEnumConst.Theatre6.ChooseRoomStatus
local TaskState = XEnumConst.Theatre6.TaskState

--region 部分类初始化
XClassPartialRequire("XModule/XTheatre6/ControlPartial/XTheatre6ControlConfig", "XTheatre6Control")
XClassPartialRequire("XModule/XTheatre6/ControlPartial/XTheatre6ControlNetwork", "XTheatre6Control")
XClassPartialRequire("XModule/XTheatre6/ControlPartial/XTheatre6ControlCharacter", "XTheatre6Control")
XClassPartialRequire("XModule/XTheatre6/ControlPartial/XTheatre6ControlStage", "XTheatre6Control")
XClassPartialRequire("XModule/XTheatre6/ControlPartial/XTheatre6ControlBattleShop", "XTheatre6Control")
--endregion

function XTheatre6Control:OnInit()
    self._RoomUiFuncDict = {
        [RoomType.ChooseTask] = handler(self, self.OpenChooseTask),
        [RoomType.ChooseOption] = handler(self, self.OpenChooseRoom),
        [RoomType.BattleShop] = handler(self, self.OpenBattleShop),
        [RoomType.Monster] = handler(self, self.OpenRoomBoss),
        [RoomType.Boss] = handler(self, self.OpenRoomBoss),
        [RoomType.Avg] = handler(self, self.OpenAvg),
        [RoomType.ChapterPreview] = handler(self, self.OpenChapterPreview),
        [RoomType.NewFloorAvg] = handler(self, self.OpenNewFloorAvg),
    }

    ---不显示初始Buff的房间类型
    self._IgnoreInitBuffRooms = {
        [RoomType.Avg] = true,
        [RoomType.ChapterPreview] = true,
    }

    self._GetRewardIconHandlers = {
        [EventRewardType.Goods] = handler(self, self.GetGoodsIcon),
        [EventRewardType.San] = handler(self, self.GetSanIcon),
        [EventRewardType.Coin] = handler(self, self.GetCoinIcon),
        [EventRewardType.BuffPool] = handler(self, self.GetBuffIcon),
        [EventRewardType.SkillPool] = handler(self, self.GetSkillPoolIcon),
        [EventRewardType.Hp] = handler(self, self.GetHpIcon),
    }

    self._OpenRewardTipHandlers = {
        [EventRewardType.Goods] = handler(self, self.OpenGoodsTip),
        [EventRewardType.Coin] = handler(self, self.OpenGoldTip),
        [EventRewardType.Hp] = handler(self, self.OpenHealthTip),
        [EventRewardType.BuffPool] = handler(self, self.OpenBuffTip),
        [EventRewardType.SkillPool] = handler(self, self.OpenSkillTip),
    }

    self._ChooseRoomHandlers = {
        [ChooseRoomStatus.TaskRecv] = handler(self, self.OpenChooseTask),
        [ChooseRoomStatus.ChooseEvent] = handler(self, self.OpenChooseOption),
        [ChooseRoomStatus.TaskFinish] = handler(self, self.OpenTaskSettlement),
        [ChooseRoomStatus.ChooseRoomFinish] = handler(self, self.OpenTaskSettlement),
    }

    self._OnUiDisable = handler(self, self.OnUiDisable)
    self._ShowSceneUis = {
        ["UiTheatre6Main"] = true,
        ["UiTheatre6ChooseCharacter"] = true,
        ["UiTheatre6Archive"] = true,
    }

    self:OnInitCharacter()
    XMVCA.XTheatre6:PlayBuffAudio()
end

function XTheatre6Control:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_ENTER_NEW_ROOM, self.MoveNext, self)
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_UI_DISABLE, self._OnUiDisable)
end

function XTheatre6Control:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_ENTER_NEW_ROOM, self.MoveNext, self)
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_UI_DISABLE, self._OnUiDisable)
end

function XTheatre6Control:OnRelease()
    XMVCA.XTheatre6:StopBuffAudio()
end

--region 养成

function XTheatre6Control:GetTalentLv()
    local saveMode = self._Model:GetPlayModeSaveData()
    return saveMode and saveMode.TalentLevel or 0 --服务器默认天赋等级是0
end

function XTheatre6Control:GetMaxTalentLv()
    return self._Model:GetMaxTalentLv()
end

function XTheatre6Control:IsTalentMaxLv()
    return self:GetTalentLv() >= self:GetMaxTalentLv()
end

function XTheatre6Control:GetTalentProgress()
    local saveMode = self._Model:GetPlayModeSaveData()
    local exp = saveMode and saveMode.TalentExp or 0

    local lv = self:GetTalentLv()
    local maxLv = self:GetMaxTalentLv()
    local nextLv = math.min(maxLv, lv + 1)
    local targetExp = self._Model:GetTalentConfig(nextLv).NextExp

    return exp, targetExp
end

---Buff是否已查看
function XTheatre6Control:IsBuffBeViewed(buffId)
    return self._Model:IsBuffBeViewed(buffId)
end

function XTheatre6Control:SetBuffBeViewed(buffId)
    self._Model:SetBuffBeViewed(buffId)
end

---获取 排序好的 需要显示的 属性
---@param AttrTypes table key=属性Id value=属性值
---@return XTableTheatre6Attr[]
function XTheatre6Control:GetShowAttributeWithSort(attrTypes)
    ---@type XTableTheatre6Attr[]
    local attrConfigs = {}
    for attrId in pairs(attrTypes) do
        local config = self:GetAttrConfig(attrId)
        if XTool.IsNumberValid(config.Priority) then
            table.insert(attrConfigs, config)
        end
    end
    table.sort(attrConfigs, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority
        end
        return a.Id > b.Id
    end)
    return attrConfigs
end

---获取排序好的属性
---@param attrTypes number[]
---@param attrNums number[]
---@return XTableTheatre6Attr[],number[]
function XTheatre6Control:GetShowAttribute(attrTypes, attrNums)
    ---@type XTableTheatre6Attr[]
    local attrConfigs = {}
    local attrValue = {}
    for i, attrId in ipairs(attrTypes) do
        local config = self:GetAttrConfig(attrId)
        if XTool.IsNumberValid(config.Priority) then
            table.insert(attrConfigs, config)
            table.insert(attrValue, attrNums[i] or 0)
        end
    end
    return attrConfigs, attrValue
end

---获取 排序好的 需要显示的 Tag
---@param buildTags number[]
---@return XTableTheatre6BuildTag[]
function XTheatre6Control:GetShowBuildTagWithSort(buildTags)
    ---@type XTableTheatre6BuildTag[]
    local tagConfigs = {}
    for _, tagId in ipairs(buildTags) do
        local config = self:GetBuildTagConfig(tagId)
        if not config.IsHide then
            table.insert(tagConfigs, config)
        end
    end
    table.sort(tagConfigs, function(a, b)
        return a.Pirority > b.Pirority
    end)
    return tagConfigs
end

function XTheatre6Control:GetBuffDataByUid(uid)
    return self._Model:GetBuffDataByUid(uid)
end

--endregion

--region 界面

---飘字
function XTheatre6Control:TipError(msg)
    XUiManager.TipError(msg)
end

---道具详情
function XTheatre6Control:UiTip(itemId)
    XLuaUiManager.Open("UiTip", itemId)
end

---选择任务
function XTheatre6Control:OpenChooseTask()
    XLuaUiManager.Open("UiTheatre6RoomChooseTask")
end

---战斗商店
function XTheatre6Control:OpenBattleShop()
    if XLuaUiManager.IsUiShow("UiTheatre6BattleShop") then
        XLuaUiManager.PopThenOpen("UiTheatre6BattleShop")
    else
        XLuaUiManager.Open("UiTheatre6BattleShop")
    end
end

---BOSS预览
function XTheatre6Control:OpenBossPreview(roomId, fightId)
    XLuaUiManager.Open("UiTheatre6BossPreview", roomId, fightId)
end

---BOSS选择（选择后进入战斗）
function XTheatre6Control:OpenRoomBoss()
    XLuaUiManager.Open("UiTheatre6RoomBoss")
end

---播放剧情
function XTheatre6Control:OpenAvg()
    local node = self._Model.StageChain.Curr
    local storyDetail = self:GetStoryDetailConfig(node.RoomValues[1])
    XDataCenter.MovieManager.PlayMovie(storyDetail.StoryId, function()
        self:RequestEndAvgRoom()
    end, nil, nil, false)
end

---播放楼层初始剧情
function XTheatre6Control:OpenNewFloorAvg()
    local node = self._Model.StageChain.Curr
    local storyDetailId = self:GetStageFloorConfig(node.FloorId).StartAVG
    local storyDetailConfig = self:GetStoryDetailConfig(storyDetailId)
    XDataCenter.MovieManager.PlayMovie(storyDetailConfig.StoryId, function()
        self:MoveNext()
    end, nil, nil, false)
    self._Model:SetAvgFinish()
end

---报幕
function XTheatre6Control:OpenChapterPreview()
    XLuaUiManager.Open("UiTheatre6ChapterPreview")
end

---任务结算
function XTheatre6Control:OpenTaskSettlement()
    XLuaUiManager.Open("UiTheatre6RoomTaskSettlement")
end

---二择房间（任务选择+二择+任务结算）
function XTheatre6Control:OpenChooseRoom()
    local roomData = self:GetCurRoomData()
    local handler = self._ChooseRoomHandlers[roomData.ChooseRoomStatus]
    if handler then
        handler()
        XMVCA.XTheatre6:OpenSanDeathBuffPopup()
    end
end

---二择
function XTheatre6Control:OpenChooseOption()
    XLuaUiManager.Open("UiTheatre6RoomEitheror")
end

---开始游戏
function XTheatre6Control:StartGame(modelId, stageId, floorIndex, roomIndex)
    self._Model.StageChain:InitChain(modelId, stageId, floorIndex, roomIndex)
    self:OpenStageView()
end

---进入下一关
function XTheatre6Control:MoveNext()
    self._Model.StageChain:MoveNext()

    if XFightUtil.IsFighting() then
        self._Model.StageChain.IsWaitOpenNext = true
        return
    end

    self:OpenStageView()
end

function XTheatre6Control:InitClientStageStatus()
    self._Model:ClearStageViewStatus()
end

---@private
function XTheatre6Control:OpenStageView()
    self._Model.StageChain.IsWaitOpenNext = false

    local node = self._Model.StageChain.Curr
    local openUiFunc = self._RoomUiFuncDict[node.RoomType]

    if not openUiFunc then
        XLog.Error(string.format("房间类型【%s】没有设置对应的UI界面", node.RoomType))
        return
    end

    openUiFunc()
    self:TryOpenGetBuffPopup(node.RoomType)
    XMVCA.XTheatre6:OpenSanDeathBuffPopup()

    if node.RoomType == RoomType.BattleShop then
        XMVCA.XTheatre6:StopSanAudio()
    else
        XMVCA.XTheatre6:PlaySanAudio()
    end
end

function XTheatre6Control:TryOpenStageViewAfterFight()
    if self._Model.StageChain.IsWaitOpenNext then
        self:OpenStageView()
    end
end

---打开获得初始Buff弹窗
function XTheatre6Control:TryOpenGetBuffPopup(roomType)
    if self._IgnoreInitBuffRooms[roomType] then
        return
    end

    if not self._Model:IsGetBuffPopupNeedOpen() then
        return
    end

    local modeData = self:GetCurPlayModeData()
    local floorBuffUid = modeData.FloorBuffUid
    local showFloorBuffData = {}
    for _, uid in ipairs(floorBuffUid) do
        local buffData = self:GetBuffDataByUid(uid)
        local buffConfig = self:GetBuffConfig(buffData.BuffId)
        if not XTool.IsNumberValid(buffConfig.IsNotShow) then
            table.insert(showFloorBuffData, buffData)
        end
    end

    if #showFloorBuffData > 0 then
        XLuaUiManager.Open("UiTheatre6PopupGetBuff", showFloorBuffData)
    end
    self._Model:SetGetBuffPopupFinish()
end

function XTheatre6Control:SetAnnoFinish()
    self._Model:SetAnnoFinish()
end

---提示
function XTheatre6Control:ShowTip(text)
    XLuaUiManager.Open("UiTheatre6ToastCommon", text)
end

---提示
function XTheatre6Control:ShowTipWithKey(textKey)
    self:ShowTip(XUiHelper.GetText(textKey))
end

---弹窗
function XTheatre6Control:ShowPopup(content, confirmCb, cancelCb)
    local title = XUiHelper.GetText("TipTitle")
    XLuaUiManager.Open("UiTheatre6PopupCommon", title, content, nil, confirmCb, cancelCb)
end

---打开物品Tip
function XTheatre6Control:OpenItemTip(rewardType, id, target)
    if not self._OpenRewardTipHandlers[rewardType] then
        return
    end
    self._OpenRewardTipHandlers[rewardType](id, target)
end

function XTheatre6Control:OpenGoodsTip(goodsId)
    XLuaUiManager.Open("UiTheatre6PopupGoodsDetail", EventRewardType.Goods, goodsId)
end

function XTheatre6Control:OpenGoldTip()
    XLuaUiManager.Open("UiTheatre6PopupGoodsDetail", EventRewardType.Coin)
end

function XTheatre6Control:OpenHealthTip()
    XLuaUiManager.Open("UiTheatre6PopupGoodsDetail", EventRewardType.Hp)
end

function XTheatre6Control:OpenPoolTip(rewardType, id)
    XLuaUiManager.Open("UiTheatre6PopupGoodsDetail", rewardType, id)
end

function XTheatre6Control:OpenSkillTip(skillId, target, param, avoidTransforms)
    if param and param.IsBaseSkill then
        XLuaUiManager.Open("UiTheatre6BubbleAttackDetail", skillId, target)
        return
    end
    XLuaUiManager.Open("UiTheatre6BubbleSkillDetail", skillId, target, param, avoidTransforms)
end

function XTheatre6Control:OpenBuffTip(buffId, target)
    XLuaUiManager.Open("UiTheatre6BubbleBuffDetail", buffId, target)
end

function XTheatre6Control:OpenRelicTip(relicId, target, param, avoidTransforms)
    XLuaUiManager.Open("UiTheatre6BubbleRelicDetail", relicId, target, param, avoidTransforms)
end

function XTheatre6Control:OpenTagTip(buildTags, target, keyWordIds)
    if not buildTags or #buildTags == 0 then
        return
    end
    if XLuaUiManager.IsUiShow("UiTheatre6BubbleTagDetail") then
        XLuaUiManager.Close("UiTheatre6BubbleTagDetail")
    end
    XLuaUiManager.Open("UiTheatre6BubbleTagDetail", buildTags, target, keyWordIds)
end

function XTheatre6Control:OnUiDisable()
    local topUiName = XLuaUiManager.GetUIStackTopUiName()
    if string.IsNilOrEmpty(topUiName) then
        return
    end

    ---@type XTheatre6Scene
    local scene = XMVCA.XScene:GetScene(SceneIds.XTheatre6Scene)
    if not scene then
        return
    end

    if self._ShowSceneUis[topUiName] then
        scene:ShowScene()
    else
        scene:HideScene()
    end
end

---打开通用弹窗（无按钮）
function XTheatre6Control:OpenPopupCommonWithoutButton(title, content)
    XLuaUiManager.Open("UiTheatre6PopupCommon", title, content, nil, nil, nil, nil, nil, true, nil, true)
end

--endregion

--region Boss预览
function XTheatre6Control:GetBossIdByRoom(fightId, isHard)
    local stageFightConfig = self._Model:GetStageFightCfgById(fightId)
    return isHard and stageFightConfig.HardMonsterId or stageFightConfig.EasyMonsterId
end

---@return XTableTheatre6Monster
function XTheatre6Control:GetBossConfigByRoom(fightId, isHard)
    isHard = isHard or false
    local monsterId = self:GetBossIdByRoom(fightId, isHard)
    return self._Model:GetMonsterCfgById(monsterId)
end

---获取Boss标签ID列表
function XTheatre6Control:GetBossTagIds(fightId)
    local bossConfig = self:GetBossConfigByRoom(fightId, false)
    return bossConfig.BuildTags
end

function XTheatre6Control:GetRewardPoolsByRoom(fightId, isHard)
    local stageFightConfig = self._Model:GetStageFightCfgById(fightId)
    local rewards = {}
    for i = 1, #stageFightConfig.HardRewardTypes do
        local rewardType = isHard and stageFightConfig.HardRewardTypes[i] or stageFightConfig.EasyRewardTypes[i]
        local rewardId = isHard and stageFightConfig.HardRewardIds[i] or stageFightConfig.EasyRewardIds[i]
        table.insert(rewards, { rewardType, rewardId })
    end
    return rewards
end

function XTheatre6Control:GetDifficultyScore(fightId, isHard)
    local mosterConfig = self:GetBossConfigByRoom(fightId, isHard)
    return self:GetMonsterScore(mosterConfig.Id)
end

---@return XTableTheatre6Skill
function XTheatre6Control:GetSkillCfgById(skillId)
    return self._Model:GetSkillCfgById(skillId)
end

function XTheatre6Control:GetBossSkillIds(fightId, isHard)
    local monsterConfig = self:GetBossConfigByRoom(fightId, isHard)
    return monsterConfig.ShowSkills
end

function XTheatre6Control:GetBossActiveSkills(fightId, isHard)
    local skillIds = self:GetBossSkillIds(fightId, isHard)
    local passiveIds = {}
    for i = 1, #skillIds do
        local skill = self:GetSkillCfgById(skillIds[i])
        if skill.Type == XEnumConst.Theatre6.SkillType.Active then
            table.insert(passiveIds, skill)
        end
    end
    return passiveIds
end

function XTheatre6Control:GetBossPassiveSkills(fightId, isHard)
    local skillIds = self:GetBossSkillIds(fightId, isHard)
    local passiveIds = {}
    for i = 1, #skillIds do
        local skill = self:GetSkillCfgById(skillIds[i])
        if skill.Type == XEnumConst.Theatre6.SkillType.Insert then
            table.insert(passiveIds, skill)
        end
    end
    return passiveIds
end

function XTheatre6Control:GetAttrPackPoolCfgByPoolId(poolId)
    return self._Model:GetAttrPackPoolCfgByPoolId(poolId)
end

function XTheatre6Control:GetSkillPoolCfgByPoolId(poolId)
    return self._Model:GetSkillPoolCfgByPoolId(poolId)
end

function XTheatre6Control:GetStageBuffPoolCfgByPoolId(poolId)
    return self._Model:GetStageBuffPoolCfgByPoolId(poolId)
end

function XTheatre6Control:GetStageBuffCfgById(buffId)
    return self._Model:GetBuffConfig(buffId)
end

---计算BOSS战力
function XTheatre6Control:GetMonsterScore(monsterId)
    return self._Model:GetMonsterScore(monsterId)
end

function XTheatre6Control:GetBossLoseHp(fightId)
    local loseHp = 0
    local fightConfig = self._Model:GetStageFightCfgById(fightId)
    for i, getType in ipairs(fightConfig.DefeatGetTypes) do
        if getType == XEnumConst.Theatre6.FightGetType.ChangeHp then
            return fightConfig.DefeatGetValues[i]
        end
    end
    return loseHp
end

--endregion

--region 主页

function XTheatre6Control:CheckShowUpdatePopup()
    local lastViewTime = self._Model:GetLastViewStoryTime()
    local values = self._Model:GetClientConfigValues("StoryUpdateTime")
    local latestUpdateTime = 0
    if #values ~= 0 then
        latestUpdateTime = XTime.ParseToTimestamp(values[#values])
    end
    return lastViewTime < latestUpdateTime
end

function XTheatre6Control:ShowUpdatePopup()
    -- TODO: 实现打开更新内容弹窗
end

---显示放弃进度确认弹窗
function XTheatre6Control:ShowAbandonConfirm(confirmCb)
    local title = CS.XTextManager.GetText("Theatre6StoryGiveUpTitle")
    local content = CS.XTextManager.GetText("Theatre6StoryGiveUp")
    XLuaUiManager.Open("UiTheatre6PopupCommon", title, content, nil, confirmCb, nil)
end

function XTheatre6Control:SaveLastViewStoryTime()
    self._Model:SaveLastViewStoryTime()
end

function XTheatre6Control:GetPvVideoId()
    return self._Model:GetClientConfigValue("PvId", 1)
end

function XTheatre6Control:IsPvPlayed()
    local videoId = self:GetPvVideoId()
    return self._Model:IsPvPlayed(videoId) == true
end

function XTheatre6Control:SetPvPlayed()
    local videoId = self:GetPvVideoId()
    self._Model:SetPvPlayed(videoId)
end

--endregion

--region 商店&任务

---获取有效商店ID列表
---@return number[]
function XTheatre6Control:GetValidShopIdList()
    local shopConfigs = self:GetValidShopOrTaskList(XEnumConst.Theatre6.TaskShopType.Shop)
    local shopIds = {}
    for _, cfg in ipairs(shopConfigs or {}) do
        if XTool.IsNumberValid(cfg.ShopId) then
            table.insert(shopIds, cfg.ShopId)
        end
    end
    return shopIds
end

---获取有效的商店或任务配置列表
---@param taskShopType number
---@return table[]
function XTheatre6Control:GetValidShopOrTaskList(taskShopType)
    local agency = self:GetAgency()
    return agency:GetValidShopOrTaskList(taskShopType)
end

---获取商店/任务一级页签名称
---@param taskShopType number
---@return string
function XTheatre6Control:GetTaskShopTagName(taskShopType)
    if taskShopType == XEnumConst.Theatre6.TaskShopType.Shop then
        return self._Model:GetClientConfigValue("TaskShopTagName", 1)
    else
        return self._Model:GetClientConfigValue("TaskShopTagName", 2)
    end
end

---获取过期刷新提示文本
---@return string
function XTheatre6Control:GetClientConfigTaskShopUpdateTips()
    return self._Model:GetClientConfigValue("TaskShopUpdateTips") or ""
end

---获取已排序的局内任务数据
---@return XTheatre6StageTaskProtocol[]
function XTheatre6Control:GetStageActivatedTaskSort()
    local modelData = self:GetCurPlayModeData()
    local datas = {}
    for _, data in pairs(modelData.StageTasks) do
        if data.TaskState ~= TaskState.Init then
            table.insert(datas, data)
        end
    end
    table.sort(datas, function(a, b)
        return a.SlotIndex < b.SlotIndex
    end)
    return datas
end

---局内任务是否已经完成
---@param taskData XTheatre6StageTaskProtocol
function XTheatre6Control:IsStageTaskFinish(taskData)
    local config = self:GetTaskConfig(taskData.TaskId)
    if XTool.IsNumberValid(config.ConditionId) then
        if taskData.ConditionState ~= TaskState.Achieved then
            return false
        end
    end
    if #config.RewardIds > 0 then
        if taskData.GoodsState ~= TaskState.Achieved then
            return false
        end
    end
    return true
end

--endregion

--region 结算界面

function XTheatre6Control:GetSanCurValue()
    return self._Model:GetCurPlayModeData().San
end

---获取结算角色Id
---@return number
function XTheatre6Control:GetSettlementRoleId(mode)
    return self._Model:GetPlayModeData(mode).CharacterId
end

---获取结算角色名字
---@return string
function XTheatre6Control:GetSettlementRoleName(mode)
    local characterId = self:GetSettlementRoleId(mode)
    return self._Model:GetCharacterConfig(characterId).Name
end

---获取最大存档槽位数量
function XTheatre6Control:GetMaxArchiveSlotCount()
    return self:GetIntClientConfigValue("MaxArchiveSlot") or 3
end

---获取结算存档列表
---@return table[] 数据格式: {{slotIndex: number, state: number, roleIcon: string, score: number}, ...}
function XTheatre6Control:GetSettlementArchiveList(roleId)
    local archiveList = {}
    local maxSlotCount = self:GetMaxArchiveSlotCount()

    for slotIndex = 1, maxSlotCount do
        local fileData = self._Model:GetFileDataBySlot(roleId, slotIndex)
        local archiveData = {
            slotIndex = slotIndex,
            isEmpty = not fileData,
            tags = {},
        }

        if fileData then
            archiveData.characterId = fileData.CharacterId
            archiveData.score = fileData.Score or 0
            archiveData.tags = fileData.BuildTags or table.empty
            local characterCfg = self:GetCharacterConfig(fileData.CharacterId)
            local defaultFashion = self:GetFashionConfig(characterCfg.FashionIds[1]).Portrait
            archiveData.roleIcon = defaultFashion or ""
        end

        table.insert(archiveList, archiveData)
    end

    return archiveList
end

---获取指定槽位的完整存档数据
---@param slotIndex number
---@return table|nil
function XTheatre6Control:GetFileDataBySlot(roleId, slotIndex)
    return self._Model:GetFileDataBySlot(roleId, slotIndex)
end

---保存存档到指定槽位
---@param slotIndex number
---@param finishCb function
function XTheatre6Control:SaveSettlement(slotIndex, finishCb)
    local modeId = self._Model:GetCurPlayMode()
    self:RequestSaveFile(modeId, slotIndex, finishCb)
end

---放弃结算存档
function XTheatre6Control:GiveUpSettlement(finishCb)
    local modeId = self._Model:GetCurPlayMode()
    self:Theatre6GiveUpSaveFileRequest(modeId, finishCb)
end

---获取回合结算伤害列表
---@param roleData table Theatre6CheckData.MyData 或 EnemyData
---@return table[] {{SkillId, Times, HpDamage, SpDamage, TotalDamage, IsBuff}, ...}
function XTheatre6Control:GetRoundSettlementDamageList(roleData)
    local damageList = {}
    local skillDamageRecord = roleData.DamageRecord and roleData.DamageRecord[0] or table.empty
    local buffDamageRecord = roleData.DamageRecord and roleData.DamageRecord[1] or table.empty
    local skillEnergyRecord = roleData.EnergyCastRecord and roleData.EnergyCastRecord[0] or table.empty
    local buffEnergyRecord = roleData.EnergyCastRecord and roleData.EnergyCastRecord[1] or table.empty
    local skillCountRecord = roleData.SkillCountRecord or table.empty

    for skillId, damage in pairs(skillDamageRecord) do
        table.insert(damageList, {
            SkillId = skillId,
            Times = skillCountRecord[skillId] or 0,
            HpDamage = skillDamageRecord[skillId] or 0,
            SpDamage = skillEnergyRecord[skillId] or 0,
            TotalDamage = roleData.TotalDamage,
            TotalEnergyCast = roleData.TotalEnergyCast,
            IsBuff = false
        })
    end

    for tagId, damage in pairs(buffDamageRecord) do
        if XTool.IsNumberValid(damage) then --buff如果没有造成伤害则不显示
            table.insert(damageList, {
                SkillId = tagId,
                Times = 0,
                HpDamage = damage,
                SpDamage = buffEnergyRecord[tagId] or 0,
                TotalDamage = roleData.TotalDamage,
                TotalEnergyCast = roleData.TotalEnergyCast,
                IsBuff = true
            })
        end
    end

    -- 按伤害降序排序
    table.sort(damageList, function(a, b)
        return a.HpDamage > b.HpDamage
    end)

    return damageList
end

--endregion

--region 战斗奖励

--TagId映射到BuffId
function XTheatre6Control:GetBuffIdByTag(tagId)
    return self:GetTagToBuffConfig(tagId).BuffId
end

---获取当前血量
function XTheatre6Control:GetCurrentHp()
    return self:GetCurPlayModeData().Health
end

---获取当前金币
function XTheatre6Control:GetCurrentGold()
    return self:GetCurPlayModeData().GoldAmount
end

---获取血量详情文本
function XTheatre6Control:GetHpDetail()
    return self:GetClientConfigValue("DescHealth")
end

---获取金币详情文本
function XTheatre6Control:GetGoldDetail()
    return self:GetClientConfigValue("DescGold")
end

---获取当前角色ID
function XTheatre6Control:GetCurrentCharacterId()
    return self:GetCurPlayModeData().CharacterId
end

---获取当前评分
function XTheatre6Control:GetCurrentScore()
    return self:GetCurPlayModeData().ScoreTotal
end

---获取活动展示奖励列表
---@param id number Theatre6Activity表Id
---@return table[] { TemplateId, Count }[]
function XTheatre6Control:GetActivityShowItems(id)
    local config = self._Model:GetActivityConfig(id)
    if not config then return table.empty end
    local result = {}
    for i, itemId in ipairs(config.ShowItems) do
        table.insert(result, { TemplateId = itemId, Count = config.ShowNum[i] })
    end
    return result
end

---获取事件奖励道具的图标
function XTheatre6Control:GetEventRewardIcon(rewardData)
    local rewardType = rewardData.RewardType
    local handler = self._GetRewardIconHandlers[rewardType]
    if not handler then
        return nil
    end
    --SkillPool类型包含了技能和遗物
    if rewardType == EventRewardType.SkillPool then
        return handler(rewardData.AttrPack, rewardData.SkillId)
    end
    return handler(rewardData.TemplateId)
end

function XTheatre6Control:GetEventRewardDesc(rewardData)
    if XTool.IsNumberValid(rewardData.SkillId) then
        return self:GetSkillDesc(rewardData.SkillId, true)
    elseif XTool.IsNumberValid(rewardData.AttrPack) then
        return self:GetAttrPackDesc(rewardData.AttrPack, true)
    elseif rewardData.RewardType == EventRewardType.BuffPool then
        return self:GetBuffDesc(rewardData.TemplateId)
    else
        return ""
    end
end

---排除掉不显示的Buff和属性包
function XTheatre6Control:IsEventRewardShow(rewardData)
    if XTool.IsNumberValid(rewardData.AttrPack) then
        local config = self:GetAttrPackCfgById(rewardData.AttrPack)
        return not config.IsHide
    elseif rewardData.RewardType == EventRewardType.BuffPool then
        local config = self:GetBuffConfig(rewardData.TemplateId)
        return not XTool.IsNumberValid(config.IsNotShow)
    end
    return true
end

function XTheatre6Control:GetGoodsIcon(id)
    return self:GetStageGoodsConfig(id).Icon
end

function XTheatre6Control:GetSanIcon()
    return self:GetClientConfigValue("IconSan")
end

function XTheatre6Control:GetCoinIcon()
    return self:GetClientConfigValue("IconCoin")
end

function XTheatre6Control:GetBuffIcon(id)
    return self:GetBuffConfig(id).Icon
end

function XTheatre6Control:GetSkillPoolIcon(attrPackId, skillId)
    if XTool.IsNumberValid(skillId) then
        return self:GetSkillIcon(skillId)
    elseif XTool.IsNumberValid(attrPackId) then
        return self:GetAttrPackCfgById(attrPackId).Icon
    end
    return nil
end

function XTheatre6Control:GetSkillIcon(id)
    return self._Model:GetSkillCfgById(id).Icon
end

function XTheatre6Control:GetHpIcon()
    return self:GetClientConfigValue("IconHp")
end

--endregion


function XTheatre6Control:GetQualityIcon(quality)
    return self:GetClientConfigValue("Quality" .. quality)
end

function XTheatre6Control:GetRelicQualityIcon(quality)
    return self:GetClientConfigValue("AttrPackBg", quality)
end

--region遗物
function XTheatre6Control:GetCharacterAttrPacks()
    local modelData = self:GetCurPlayModeData()
    return modelData.AttrPacks
end

--endregion

---格式化数值：小于10000直接显示，大于等于10000显示为xK（向下取整保留1位小数，去掉末尾0）
---@param num number
---@return string
function XTheatre6Control:FormatNumberWithUnit(num)
    if not XTool.IsNumberValid(num) then
        return ""
    end
    if num < 10000 then
        return num
    end
    local k = math.floor(num / 100) / 10
    local formatted = string.format("%.1f", k)
    formatted = formatted:gsub("0+$", ""):gsub("%.$", "")
    return string.format("%sK", formatted)
end

return XTheatre6Control
