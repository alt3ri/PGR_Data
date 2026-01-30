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

local QuestViewShield = {
    --领取时屏蔽
    ShieldWhenReceive = 1,
    --完成时屏蔽
    ShieldWhenFinish = 2,
}

local PopViewType = {
    --通用
    Small = 1,
    
    --全屏通用
    FullScreenNormal = 2,
    
    --全屏好感
    FullScreenFavorable = 3,
}

local PopViewType2UiName = {
    [PopViewType.Small] = "UiBigWorldTaskObtain",
    [PopViewType.FullScreenNormal] = "UiBigWorldTaskObtainDrama",
    [PopViewType.FullScreenFavorable] = "UiBigWorldTaskObtainDramaHeart",
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
    self._TrackQuestDict = {}
    self._ConfigUtil:InitConfigByTableKey("DlcWorld/QuestSystem", TableQuestKey)
end

function XBigWorldQuestModel:ClearPrivate()
end

function XBigWorldQuestModel:ResetAll()
    self:ClearTemplate()
    self._QuestDataDict = false
    self._FinishQuest = false
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

function XBigWorldQuestModel:UpdateTrackIds(traceQuestIds)
    local dict = traceQuestIds
    if not dict then
        return
    end
    for category, questId in pairs(dict) do
        self._TrackQuestDict[category] = questId
    end
end

--- 当前正在追踪的任务
---@return number
--------------------------
function XBigWorldQuestModel:GetTrackQuestId(category)
    local questId = self._TrackQuestDict[category] or 0
    return questId
end

--- 设置当前类型的追踪的任务Id
function XBigWorldQuestModel:SetTrackQuestId(category, questId)
    self._TrackQuestDict[category] = questId
end

function XBigWorldQuestModel:IsTrackQuest(questId)
    if not questId or questId <= 0 then
        return false
    end
    local category = self:GetQuestCategory(questId)
    return self:GetTrackQuestId(category) == questId
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

--- 获取步骤流程配置
---@param objectiveId number
---@return XTableDlcQuestStepObjective
--------------------------
function XBigWorldQuestModel:GetQuestStepObjectiveTemplate(objectiveId)
    local template = CsQuestConfig.GetQuestStepObjectiveTemplate(objectiveId)
    if not template then
        XLog.Error(string.format("ProcessId：%s不存在或CS.StatusSyncFight.XQuestConfig未初始化!", objectiveId))
        return {}
    end
    return template
end

function XBigWorldQuestModel:GetObjectiveType(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    return template and template.Type or 0
end

-- function XBigWorldQuestModel:GetObjectiveStepId(objectiveId)
--     local template = self:GetQuestStepObjectiveTemplate(objectiveId)
--     return template and template.StepId or 0
-- end

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

--- 获取任务步骤列表, 从C#获取内容，只能在初始化调用，后续需要获取通过XSGQuest
---@param questId number
---@return number[]
--------------------------
function XBigWorldQuestModel:GetQuestStepIdsByQuestId(questId)
    local csList = CsQuestConfig.GetQuestStepIdsByQuestId(questId)
    if not csList or csList.Count <= 0 then
        return {}
    end
    local list = {}

    for i = 0, csList.Count - 1 do
        list[#list + 1] = csList[i]
    end
    return list
end

--- 获取任务步骤流程列表,从C#获取内容，只能在初始化调用，后续需要获取通过XSGStep
---@param stepId number
---@return number[]
--------------------------
function XBigWorldQuestModel:GetStepObjectiveIdsByStepId(stepId)
    local csList = CsQuestConfig.GetStepObjectiveIdsByStepId(stepId)
    local list = {}

    for i = 0, csList.Count - 1 do
        list[#list + 1] = csList[i]
    end
    return list
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

function XBigWorldQuestModel:PopupTaskObtain(questId, isFinish)
    local isShield = isFinish and self:CheckPopViewOpenWhenQuestFinish(questId)
            or self:CheckPopViewOpenWhenQuestReceive(questId) 
    if isShield then
        return
    end
    local t = self:GetQuestTemplate(questId)
    local popViewType = t and t.PopViewType or PopViewType.Small
    local uiName = PopViewType2UiName[popViewType]
    if string.IsNilOrEmpty(uiName) then
        XLog.Error(string.format("任务:%s, 弹窗类型:%s, 不存在对应弹窗类型", questId, popViewType))
        return
    end
    XMVCA.XBigWorldUI:OpenWithFightSequence(uiName, questId, isFinish)
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


---@class XTableDlcQuestStep
---@field Id number
---@field PreStep number[]
---@field IsEndStep boolean
---@field StepText string
---@field LocationText string
---@field RewardId number
---@field InternalDesc string
---@field FirstObjectiveId number


---@class XTableDlcQuestStepObjective
---@field Id number
---@field Type number
---@field MaxProgress number
---@field Title string
---@field Description string
---@field QuestItemId number[]
---@field ItemGetType number[]
---@field ItemGetUnit number[]
---@field ItemGetCount number[]
---@field InternalDesc string

--endregion 数据表定义

return XBigWorldQuestModel