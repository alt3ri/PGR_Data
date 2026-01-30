---@class XBigWorldQuestModel : XModel
---@field private _QuestDataDict table<number, XBigWorldQuest>
local XBigWorldQuestModel = XClass(XModel, "XBigWorldQuestModel")

local XBigWorldQuest

local tableSort = table.sort
local pairs = pairs

---@type StatusSyncFight.XQuestConfig
local CsQuestConfig = CS.StatusSyncFight.XQuestConfig

local TableQuestKey = {
    DlcQuestItem = { CacheType = XConfigUtil.CacheType.Normal },
    DlcQuestType = { 
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcQuestGroup = { CacheType = XConfigUtil.CacheType.Normal },
    DlcQuestChapter = { DirPath = XConfigUtil.DirectoryType.Client },
    DlcQuestArchive = { DirPath = XConfigUtil.DirectoryType.Client },
}

local TableInviteQuestKey = {
    DlcInviteQuest = {
        ReadFunc = XConfigUtil.ReadType.IntAll,
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcInviteQuestResult = {
        CacheType = XConfigUtil.CacheType.Normal
    },
}

local TableEnvironmentQuestKey = {
    DlcEnvironmentQuest = {
        CacheType = XConfigUtil.CacheType.Normal,
        ReadFunc = XConfigUtil.ReadType.IntAll,
        DirPath = XConfigUtil.DirectoryType.Client 
    },
}

local QuestViewShield = {
    --领取时屏蔽
    ShieldWhenReceive = 1,
    --完成时屏蔽
    ShieldWhenFinish = 2,
}

local PopViewType = {
    --不开弹窗
    None = 0,
    
    --通用
    Small = 1,
    
    --全屏通用
    FullScreenNormal = 2,
    
    --全屏好感
    FullScreenFavorable = 3,
    
    --邀约任务
    Invitation = 4,
}

local PopViewType2UiName = {
    [PopViewType.Small] = "UiBigWorldTaskObtain",
    [PopViewType.FullScreenNormal] = "UiBigWorldTaskObtainDrama",
    [PopViewType.FullScreenFavorable] = "UiBigWorldTaskObtainDramaHeart",
    [PopViewType.Invitation] = "UiBigWorldTaskObtainInvitation",
}

local QuestViewShieldTypeList = {
    [0] = 0,
    [1] = QuestViewShield.ShieldWhenReceive,
    [2] = QuestViewShield.ShieldWhenFinish,
    [3] = QuestViewShield.ShieldWhenReceive | QuestViewShield.ShieldWhenFinish
}

local FavorableQuestType = 1

function XBigWorldQuestModel:OnInit()
    self._QuestDataDict = false
    self._FinishQuest = false
    self._QuestRedDict = false
    self:InitQuestRed()
    -- 当前追踪的Id
    self._CurrentTrackQuestId = 0
    -- 上一次追踪的Id
    self._LastTrackQuestId = 0
    self._FinishInviteResultDict = {}
    self._ReceiveInviteReward = false
    self._PopUiViewDataPool = {}
    self._PopUiViewDataQueue = {}
    self._ConfigUtil:InitConfigByTableKey("DlcWorld/QuestSystem", TableQuestKey)
    self._ConfigUtil:InitConfigByTableKey("DlcWorld/QuestSystem/InviteQuest", TableInviteQuestKey)
    self._ConfigUtil:InitConfigByTableKey("DlcWorld/QuestSystem/EnvironmentQuest", TableEnvironmentQuestKey)
end

function XBigWorldQuestModel:ClearPrivate()
end

function XBigWorldQuestModel:ResetAll()
    self:ClearTemplate()
    self._QuestDataDict = false
    self._FinishQuest = false
    self._FinishInviteResultDict = false
    self._ReceiveInviteReward = false
    self._EnvironmentIds = 0
    self._InviteQuestIds = 0
    self._PopUiViewDataPool = false
    self._PopUiViewDataQueue = false
end

function XBigWorldQuestModel:ClearTemplate()
    self._TypeIds = nil
    self._Type2GroupIds = nil
    self._QuestId2GroupId = nil
end

function XBigWorldQuestModel:ResetData()
    self._QuestDataDict = false
end

--- 获取任务数据
---@param questId number 任务Id  
---@return XBigWorldQuest
--------------------------
function XBigWorldQuestModel:GetQuestData(questId)
    if not self._QuestDataDict then
        self._QuestDataDict = {}
    end
    if not XBigWorldQuest then
        XBigWorldQuest = require("XModule/XBigWorldQuest/Model/XBigWorldQuest")
    end
    local questData = self._QuestDataDict[questId]
    if not questData then
        questData = XBigWorldQuest.New(questId)
        self._QuestDataDict[questId] = questData
    end

    return questData
end

function XBigWorldQuestModel:UpdateFinishQuest(questIds)
    if not self._FinishQuest then
        self._FinishQuest = {}
    end
    if not XTool.IsTableEmpty(questIds) then
        for _, questId in pairs(questIds) do
            self._FinishQuest[questId] = true
        end
    end
end

function XBigWorldQuestModel:InitTrackData(currentTrackId, lastTrackId)
    self._CurrentTrackQuestId = currentTrackId
    self._LastTrackQuestId = lastTrackId
end

function XBigWorldQuestModel:GetTrackQuestId()
    return self._CurrentTrackQuestId
end

function XBigWorldQuestModel:SetTrackQuestId(questId)
    self._LastTrackQuestId = self._CurrentTrackQuestId
    self._CurrentTrackQuestId = questId
end

function XBigWorldQuestModel:SetTrackQuestIdLocal(questId)
    self._CurrentTrackQuestId = questId
end

function XBigWorldQuestModel:IsTrackQuest(questId)
    if not questId or questId <= 0 then
        return false
    end
    return self._CurrentTrackQuestId == questId
end

function XBigWorldQuestModel:TryRevertTrackQuest()
    if not self._IsRevert then
        return false
    end
    self._CurrentTrackQuestId = self._LastTrackQuestId
    self._LastTrackQuestId = 0
    self._IsRevert = false
    return true
end

function XBigWorldQuestModel:MarkRevertTrackQuest()
    self._IsRevert = true
    self._LastTrackQuestId = self._CurrentTrackQuestId
end

function XBigWorldQuestModel:CheckQuestFinish(questId)
    if self._FinishQuest and self._FinishQuest[questId] then
        return true
    end
    local quest = self:GetQuestData(questId)
    return quest:IsFinish()
end

function XBigWorldQuestModel:CheckQuestInProgress(questId)
    if self._FinishQuest and self._FinishQuest[questId] then
        return false
    end

    local quest = self:GetQuestData(questId)

    return quest:GetState() == XMVCA.XBigWorldQuest.QuestState.InProgress
end

function XBigWorldQuestModel:CheckQuestReady(questId)
    if self._FinishQuest and self._FinishQuest[questId] then
        return false
    end

    local quest = self:GetQuestData(questId)

    return quest:GetState() == XMVCA.XBigWorldQuest.QuestState.Ready
end

--- 获取所有接取的任务Id
---@return number[]
--------------------------
function XBigWorldQuestModel:GetReceiveQuestIds()
    if not self._QuestDataDict then
        return
    end
    local list = {}
    for id, data in pairs(self._QuestDataDict) do
        if data:IsShowInList() then
            list[#list + 1] = id
        end
    end

    return list
end

--- 获取接取切默认追踪的
---@return number[]
function XBigWorldQuestModel:GetReceiveAndDefaultTrackQuestIds()
    if not self._QuestDataDict then
        return
    end
    local list
    for id, data in pairs(self._QuestDataDict) do
        if data:IsShowInList() and self:IsDefaultTrackQuest(id) then
            if not list then
                list = {}
            end
            list[#list + 1] = id
        end
    end
    return list
end

function XBigWorldQuestModel:CheckPopViewOpenWhenQuestReceive(questId)
    local t = self:GetQuestTemplate(questId)
    if not t then
        return false
    end
    local shieldViewType = t.ShieldPopViewType
    local value = QuestViewShieldTypeList[shieldViewType]
    return (value & QuestViewShield.ShieldWhenReceive) ~= 0
end

function XBigWorldQuestModel:CheckPopViewOpenWhenQuestFinish(questId)
    local t = self:GetQuestTemplate(questId)
    if not t then
        return false
    end
    local shieldViewType = t.ShieldPopViewType
    local value = QuestViewShieldTypeList[shieldViewType]
    return (value & QuestViewShield.ShieldWhenFinish) ~= 0
end

--region Config
---@return XTableDlcQuestItem
function XBigWorldQuestModel:GetQuestItemTemplate(templateId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableQuestKey.DlcQuestItem, templateId)
end

--- 获取任务配置
---@param questId number
---@return XTableDlcQuest
--------------------------
function XBigWorldQuestModel:GetQuestTemplate(questId)
    local template = CsQuestConfig.GetQuestTemplate(questId)
    if not template then
        XLog.Error(string.format("QuestId：%s不存在或CS.StatusSyncFight.XQuestConfig未初始化!", questId))
        return {}
    end
    return template
end

function XBigWorldQuestModel:IsFirstStatusBarPlay(questId)
    local t = self:GetQuestTemplate(questId)
    return t and t.FirstStatusBarPlay or false
end

function XBigWorldQuestModel:GetQuestCategory(questId)
    if not questId or questId <= 0 then
        return 0
    end
    local t = self:GetQuestTemplate(questId)
    return t and t.Category:GetHashCode() or 0
end

function XBigWorldQuestModel:GetQuestType(questId)
    local template = self:GetQuestTemplate(questId)
    return template and template.Type or 0
end

function XBigWorldQuestModel:IsFavorableQuestType(questId)
    return self:GetQuestType(questId) == FavorableQuestType
end

function XBigWorldQuestModel:IsDefaultTrackQuest(questId)
    local t = self:GetQuestTemplate(questId)

    return t and t.IsDefaultTrack or false
end

function XBigWorldQuestModel:GetQuestFinishTip(questId)
    local t = self:GetQuestTemplate(questId)

    return t and t.FinishTip
end

function XBigWorldQuestModel:GetQuestTrackPriority(questId)
    local t = self:GetQuestTemplate(questId)

    return t and t.TrackPriority or 0
end

function XBigWorldQuestModel:GetQuestSystemUiStyleId(questId)
    local t = self:GetQuestTemplate(questId)

    return t and t.SystemUiStyleId or 0
end

--- 获取任务步骤配置
---@param stepId number
---@return XTableDlcQuestStep
--------------------------
function XBigWorldQuestModel:GetQuestStepTemplate(stepId)
    local template = CsQuestConfig.GetQuestStepTemplate(stepId)
    if not template then
        XLog.Error(string.format("StepId：%s不存在或CS.StatusSyncFight.XQuestConfig未初始化!", stepId))
        return {}
    end
    return template
end

function XBigWorldQuestModel:GetQuestStepText(stepId)
    local template = self:GetQuestStepTemplate(stepId)
    return template and template.StepText
end

function XBigWorldQuestModel:GetQuestStepExecMode(stepId)
    if not stepId or stepId <= 0 then
        return -1
    end
    local mode = CsQuestConfig.GetQuestStepExecMode(stepId)
    return mode:GetHashCode()
end

function XBigWorldQuestModel:GetQuestIdByStepId(stepId)
    local questId = CsQuestConfig.GetQuestIdByStepId(stepId)
    return questId
end

function XBigWorldQuestModel:GetQuestIdByObjectiveId(stepId)
    local questId = CsQuestConfig.GetQuestIdByObjectiveId(stepId)
    return questId
end

function XBigWorldQuestModel:GetStepObjectiveIdsByStepId(stepId)
    return CsQuestConfig.GetStepObjectiveIdsByStepId(stepId)
end

--- 获取步骤流程配置
---@param objectiveId number
---@return XTableDlcQuestObjective
--------------------------
function XBigWorldQuestModel:GetQuestStepObjectiveTemplate(objectiveId)
    local template = CsQuestConfig.GetQuestStepObjectiveTemplate(objectiveId)
    if not template then
        XLog.Error(string.format("ProcessId：%s不存在或CS.StatusSyncFight.XQuestConfig未初始化!", objectiveId))
        return {}
    end
    return template
end

function XBigWorldQuestModel:GetObjectiveMaxProgress(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    return template and template.MaxProgress or 0
end

function XBigWorldQuestModel:GetObjectiveTitle(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    return template and template.Title or ""
end

function XBigWorldQuestModel:GetObjectiveDesc(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    return template and template.Description or ""
end

function XBigWorldQuestModel:GetObjectiveType(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    return template and template.ObjectiveType or -1
    end

function XBigWorldQuestModel:GetObjectiveDeliveryItemDict(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    local dict = template and template.RequiredItemInfoDict or nil
    if not dict then
        return
    end
    return XTool.CsMap2LuaTable(dict)
end

function XBigWorldQuestModel:GetObjectiveDeliveryTitle(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    return template and template.DeliverTitle or ""
end

function XBigWorldQuestModel:GetObjectiveDeliveryDesc(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    return template and template.DeliverDesc or ""
end

function XBigWorldQuestModel:GetObjectiveItemsDeliverType(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    local type = template and template.ItemsDeliverType or nil
    if not type or not type.GetHashCode then
        return XMVCA.XBigWorldQuest.EItemsDeliverType.Normal
    end
    return type:GetHashCode()
end

function XBigWorldQuestModel:GetObjectivePhotoKey(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    return template and template.PhotoKey or 0
end

--region Quest Group

---@return XTableDlcQuestGroup
function XBigWorldQuestModel:GetGroupTemplate(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableQuestKey.DlcQuestGroup, groupId)
end

function XBigWorldQuestModel:GetGroupType(groupId)
    local template = self:GetGroupTemplate(groupId)
    return template and template.Type or 0
end

function XBigWorldQuestModel:GetGroupName(groupId)
    local template = self:GetGroupTemplate(groupId)
    return template and template.Name or ""
end

function XBigWorldQuestModel:GetGroupPriority(groupId)
    local template = self:GetGroupTemplate(groupId)
    return template and template.Priority or 0
end

function XBigWorldQuestModel:GetGroupIncompleteText(groupId)
    local template = self:GetGroupTemplate(groupId)
    return template and template.IncompleteText or ""
end

function XBigWorldQuestModel:GetGroupIcon(groupId)
    local template = self:GetGroupTemplate(groupId)
    return template and template.Icon or ""
end

function XBigWorldQuestModel:GetGroupQuestIds(groupId)
    local template = self:GetGroupTemplate(groupId)
    return template and template.Quest or {}
end

function XBigWorldQuestModel:GetGroupIdsByTypeId(typeId)
    if self._Type2GroupIds and self._Type2GroupIds[typeId] then
        return self._Type2GroupIds[typeId]
    end
    if not self._Type2GroupIds then
        self._Type2GroupIds = {}
    end
    local list = {}
    local isAll = typeId == XMVCA.XBigWorldQuest.QuestType.All
    ---@type table<number, XTableDlcQuestGroup>
    local templates = self._ConfigUtil:GetByTableKey(TableQuestKey.DlcQuestGroup)
    for id, template in pairs(templates) do
        if isAll or template.Type == typeId then
            list[#list + 1] = id
        end
    end

    tableSort(list, function(a, b)
        local pA = self:GetGroupPriority(a)
        local pB = self:GetGroupPriority(b)
        if pA ~= pB then
            return pA < pB
        end

        return a < b
    end)
    self._Type2GroupIds[typeId] = list

    return list
end

function XBigWorldQuestModel:GetGroupIdByQuestId(questId, noTips)
    if self._QuestId2GroupId and self._QuestId2GroupId[questId] then
        return self._QuestId2GroupId[questId]
    end

    if not self._QuestId2GroupId then
        self._QuestId2GroupId = {}
    end
    local dict = {}
    ---@type table<number, XTableDlcQuestGroup>
    local templates = self._ConfigUtil:GetByTableKey(TableQuestKey.DlcQuestGroup)
    for id, template in pairs(templates) do
        local questIds = template.Quest
        if not XTool.IsTableEmpty(questIds) then
            for _, qId in ipairs(questIds) do
                dict[qId] = id
            end
        end
    end
    self._QuestId2GroupId = dict
    if dict[questId] then
        return dict[questId]
    end
    if not noTips then
        XLog.Error("不存在任务组, QuestId = " .. questId)
    end
    return 0
end

---@return XTableDlcQuestChapter
function XBigWorldQuestModel:GetChapterTemplate(chapterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableQuestKey.DlcQuestChapter, chapterId)
end

---@return XTableDlcQuestArchive
function XBigWorldQuestModel:GetArchiveTemplate(archiveId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableQuestKey.DlcQuestArchive, archiveId)
end

--endregion Quest Group

function XBigWorldQuestModel:GetQuestTypeIds()
    if self._TypeIds then
        return self._TypeIds
    end
    local list = {}
    ---@type table<number, XTableDlcQuestType>
    local templates = self._ConfigUtil:GetByTableKey(TableQuestKey.DlcQuestType)
    for id, _ in pairs(templates) do
        list[#list + 1] = id
    end

    tableSort(list, function(a, b)
        local templateA = self:GetQuestTypeTemplate(a)
        local templateB = self:GetQuestTypeTemplate(b)
        local pA = templateA and templateA.Priority or 0
        local pB = templateB and templateB.Priority or 0
        if pA ~= pB then
            return pA < pB
        end

        return a < b
    end)

    self._TypeIds = list

    return self._TypeIds
end

---@return XTableDlcQuestType
function XBigWorldQuestModel:GetQuestTypeTemplate(typeId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableQuestKey.DlcQuestType, typeId)
end

function XBigWorldQuestModel:GetQuestTypePriority(typeId)
    local t = self:GetQuestTypeTemplate(typeId)
    return t and t.Priority or math.maxinteger
end

function XBigWorldQuestModel:PopupTaskObtain(questId, isFinish)
    local t = self:GetQuestTemplate(questId)
    local isShield
    if isFinish then
        isShield = self:CheckPopViewOpenWhenQuestFinish(questId)
    else
        isShield = self:CheckPopViewOpenWhenQuestReceive(questId)
    end
    local popViewType = t and t.PopViewType or PopViewType.None
    if isShield or popViewType == PopViewType.None then
        return
    end
    local uiName = PopViewType2UiName[popViewType]
    if string.IsNilOrEmpty(uiName) then
        XLog.Error(string.format("任务:%s, 弹窗类型:%s, 不存在对应弹窗类型", questId, popViewType))
        return
    end
    --锁住打脸
    XMVCA.XBigWorldFunction:FreezeFunctionEvent()
    XMVCA.XBigWorldUI:OpenWithFightSequence(uiName, false, questId, isFinish)
end

--endregion Config


function XBigWorldQuestModel:GetCookieKey(key)
    return string.format("BIG_WORLD_QUEST_%s_%s", tostring(XPlayer.Id), key)
end

function XBigWorldQuestModel:InitQuestRed()
    if self._QuestRedDict then
        return
    end
    local key = self:GetCookieKey("NEW_QUEST_UNDERTAKEN")
    local dict
    local data = XSaveTool.GetData(key)
    if data then
        dict = data
    else
        dict = {}
    end

    self._QuestRedDict = dict
end

function XBigWorldQuestModel:SaveQuestRed()
    if not self._QuestRedDict then
        return
    end
    local key = self:GetCookieKey("NEW_QUEST_UNDERTAKEN")
    XSaveTool.SaveData(key, self._QuestRedDict)
end

function XBigWorldQuestModel:CheckQuestRed()
    local typeIds = self:GetQuestTypeIds()
    for _, type in pairs(typeIds) do
        if self:CheckQuestRedWithQuestType(type) then
            return true
        end
    end
    return false
end

function XBigWorldQuestModel:CheckQuestRedWithQuestType(type)
    if XTool.IsTableEmpty(self._QuestDataDict) then
        return false
    end
    local isCheckAll = type == XMVCA.XBigWorldQuest.QuestType.All or not type
    for id, data in pairs(self._QuestDataDict) do
        if data:IsShowInList() and (isCheckAll or self:GetQuestType(id) == type) and self:GetGroupIdByQuestId(id, true) > 0 then
            if self:CheckQuestRedWithQuestId(id) then
                return true
            end
        end
    end
    return false
end

function XBigWorldQuestModel:CheckQuestRedWithQuestId(questId)
    if not questId or questId <= 0 then
        return false
    end
    local data = self:GetQuestData(questId)
    if not data:IsShowInList() then
        return false
    end
    return not self._QuestRedDict[questId]
end

function XBigWorldQuestModel:MarkQuestRedPoint(questId)
    if not questId or questId <= 0 then
        return
    end
    if self._QuestRedDict[questId] then
        return
    end
    self._QuestRedDict[questId] = true
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_RED_POINT_REFRESH)
end

function XBigWorldQuestModel:RemoveQuestRedPoint(questId)
    if not questId or questId <= 0 then
        return
    end
    if not self._QuestRedDict[questId] then
        return
    end
    self._QuestRedDict[questId] = nil
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_RED_POINT_REFRESH)
end

--region 邀约任务
---@return XTableDlcInviteQuest
function XBigWorldQuestModel:GetInviteQuestTemplate(id, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableInviteQuestKey.DlcInviteQuest, id, noTips)
end

function XBigWorldQuestModel:GetInviteIds()
    if self._InviteQuestIds then
        return self._InviteQuestIds
    end
    local list = {}
    ---@type table<number, XTableDlcInviteQuest>
    local templates = self._ConfigUtil:GetByTableKey(TableInviteQuestKey.DlcInviteQuest)
    for id, _ in pairs(templates) do
        list[#list + 1] = id
    end
    self._InviteQuestIds = list

    return list
end

function XBigWorldQuestModel:GetInviteQuestName(id)
    local t = self:GetInviteQuestTemplate(id)
    return t and t.Name
end

function XBigWorldQuestModel:GetInviteQuestPriority(id)
    local t = self:GetInviteQuestTemplate(id)
    return t and t.Priority or 0
end

function XBigWorldQuestModel:GetInviteQuestCondition(id)
    local t = self:GetInviteQuestTemplate(id)
    return t and t.Condition or 0
end

function XBigWorldQuestModel:GetInviteQuestModelId(id)
    local t = self:GetInviteQuestTemplate(id)
    return t and t.ModelId
end

function XBigWorldQuestModel:GetInviteQuestRolePath(id)
    local t = self:GetInviteQuestTemplate(id)
    return t and t.RolePath
end

function XBigWorldQuestModel:GetInviteQuestRoleIcon(id, noTips)
    local t = self:GetInviteQuestTemplate(id, noTips)
    return t and t.RoleIcon
end

function XBigWorldQuestModel:GetInviteQuestTotalRewardId(id)
    local t = self:GetInviteQuestTemplate(id)
    return t and t.TotalRewardId or 0
end

function XBigWorldQuestModel:GetInviteQuestResultIds(id)
    local t = self:GetInviteQuestTemplate(id)
    return t and t.ResultIds
end

function XBigWorldQuestModel:GetInviteQuestTipText(id)
    local t = self:GetInviteQuestTemplate(id)
    return t and t.TipText
end

function XBigWorldQuestModel:GetInviteQuestPopTipText(id)
    local t = self:GetInviteQuestTemplate(id)
    return t and t.PopTipText
end

---@return XTableDlcInviteQuestResult
function XBigWorldQuestModel:GetInviteQuestResultTemplate(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableInviteQuestKey.DlcInviteQuestResult, id)
end

function XBigWorldQuestModel:GetInviteQuestResultName(id)
    local t = self:GetInviteQuestResultTemplate(id)
    return t and t.Name
end

function XBigWorldQuestModel:GetInviteQuestResultBanner(id)
    local t = self:GetInviteQuestResultTemplate(id)
    return t and t.Banner
end

function XBigWorldQuestModel:GetInviteQuestResultDesc(id)
    local t = self:GetInviteQuestResultTemplate(id)
    return t and t.Desc
end

function XBigWorldQuestModel:GetInviteQuestResultCGAsset(id)
    local t = self:GetInviteQuestResultTemplate(id)
    return t and t.CGAsset
end

function XBigWorldQuestModel:GetInviteQuestResultRewardId(id)
    local t = self:GetInviteQuestResultTemplate(id)
    return t and t.RewardId or 0
end

function XBigWorldQuestModel:AddFinishInviteResult(resultId)
    self._FinishInviteResultDict[resultId] = true
end

function XBigWorldQuestModel:CheckInviteResultFinish(resultId)
    return self._FinishInviteResultDict[resultId] ~= nil
end

function XBigWorldQuestModel:IsFirstFinishResult()
    local res = true
    local cnt = 0
    for resId, status in pairs(self._FinishInviteResultDict) do
        if status then
            cnt = cnt + 1
        end

        if cnt >= 2 then
            res = false
            break
        end
    end
    return res
end

function XBigWorldQuestModel:ReceiveInviteReward(questId, count)
    if not self._ReceiveInviteReward then
        self._ReceiveInviteReward = {}
    end
    self._ReceiveInviteReward[questId] = count
end

function XBigWorldQuestModel:CheckInviteRewardReceived(questId)
    if not self._ReceiveInviteReward then
        return false
    end
    return self._ReceiveInviteReward[questId] ~= nil
end

function XBigWorldQuestModel:InitInviteInfo(inviteInfo)
    if not inviteInfo then
        return
    end
    local unlockResultIds = inviteInfo.UnlockedInviteQuestResultIds
    if not XTool.IsTableEmpty(unlockResultIds) then
        for _, v in ipairs(unlockResultIds) do
            self._FinishInviteResultDict[v] = true
        end
    end

    self._ReceiveInviteReward = inviteInfo.ReceivedRewardInviteQuestIds or {}
end

function XBigWorldQuestModel:IsUnderTakenInviteQuest()
    if XTool.IsTableEmpty(self._QuestDataDict) then
        return false
    end
    for questId, quest in pairs(self._QuestDataDict) do
        if quest:IsInProgress() 
                and self:GetQuestCategory(questId) == XMVCA.XBigWorldQuest.QuestCategory.InviteQuest then
            return true
        end
    end
    return false
end

function XBigWorldQuestModel:CheckPhotoQuestNeedUpload()
    if not self._QuestDataDict or XTool.IsTableEmpty(self._QuestDataDict) then
        return false
    end

    local objId = 0
    local isNeedUpload = false
    for _, quest in pairs(self._QuestDataDict) do
        if quest:IsInProgress() then
            local objectDict = quest:GetStepObjectiveIds()
            if objectDict then
                for objectiveId, _ in pairs(objectDict) do
                    local photoKey = self:GetObjectivePhotoKey(objectiveId)
                    if photoKey ~= 0 then
                        isNeedUpload = true
                        objId = objectiveId
                        break
                    end
                end
            end
        end
        if isNeedUpload then break end
    end
    return isNeedUpload, objId
end

--endregion 邀约任务配置

--region 环境剧情

---@return XTableDlcEnvironmentQuest
function XBigWorldQuestModel:GetEnvironmentQuestTemplate(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableEnvironmentQuestKey.DlcEnvironmentQuest, id)
end

function XBigWorldQuestModel:GetEnvironmentIds()
    if self._EnvironmentIds then
        return self._EnvironmentIds
    end
    local ids = {}
    local index = 0
    local templates = self._ConfigUtil:GetByTableKey(TableEnvironmentQuestKey.DlcEnvironmentQuest)
    for id, _ in pairs(templates) do
        ids[index + 1] = id
        index = index + 1
    end
    self._EnvironmentIds = ids
    return ids
end

function XBigWorldQuestModel:GetEnvironmentQuestName(id)
    local t = self:GetEnvironmentQuestTemplate(id)
    return t and t.Name or ""
end

function XBigWorldQuestModel:GetEnvironmentQuestRoleIcon(id)
    local t = self:GetEnvironmentQuestTemplate(id)
    return t and t.RoleIcon or nil
end

function XBigWorldQuestModel:GetEnvironmentQuestPriority(id)
    local t = self:GetEnvironmentQuestTemplate(id)
    return t and t.Priority or 0
end

function XBigWorldQuestModel:GetEnvironmentQuestObjectiveIds(id)
    local t = self:GetEnvironmentQuestTemplate(id)
    return t and t.ObjectiveIds
end

function XBigWorldQuestModel:GetEnvironmentQuestShowReward(id)
    local t = self:GetEnvironmentQuestTemplate(id)
    return t and t.ShowReward or 0
end

function XBigWorldQuestModel:GetEnvironmentQuestSkipId(id)
    local t = self:GetEnvironmentQuestTemplate(id)
    return t and t.SkipId or 0
end

--endregion 环境剧情

--region 数据表定义

---@class XTableDlcQuest
---@field Id number
---@field GameplayType number
---@field Type number
---@field Category number
---@field LevelId number
---@field QuestIcon string
---@field QuestBanner string
---@field Name string
---@field Desc string
---@field Condition number
---@field IsDefaultActivate boolean
---@field AutoUndertake boolean
---@field IsDefaultTrack boolean
---@field ScriptId number
---@field RewardId number
---@field InternalDesc string
---@field FirstStepId number
---@field ShieldPopViewType number
---@field PopViewType number
---@field FirstStatusBarPlay boolean
---@field FinishTip boolean
---@field TrackPriority number
---@field SystemUiStyleId number 任务相关界面样式表Id


---@class XTableDlcQuestStep
---@field Id number
---@field PreStep number[]
---@field IsEndStep boolean
---@field StepText string
---@field LocationText string
---@field RewardId number
---@field InternalDesc string
---@field FirstObjectiveId number


---@class XTableDlcQuestObjective
---@field Id number
---@field ObjectiveType number
---@field MaxProgress number
---@field Title string
---@field Description string
---@field DeliveryItemsTargetDict table<number, number> 需要交付的道具(ObjectiveType == DeliverItems)
---@field DeliverTitle string 交付Title(ObjectiveType == DeliverItems)
---@field DeliverDesc string 交付Title(ObjectiveType == DeliverItems)
---@field ItemsDeliverType number 交付Title(ObjectiveType == DeliverItems)

--endregion 数据表定义

return XBigWorldQuestModel