local XPokerGuessing2ConfigModel = require("XModule/XPokerGuessing2/XPokerGuessing2ConfigModel")
local XPokerGuessing2Enum = require("XModule/XPokerGuessing2/XPokerGuessing2Enum")

---@class XPokerGuessing2Model : XPokerGuessing2ConfigModel
local XPokerGuessing2Model = XClass(XPokerGuessing2ConfigModel, "XPokerGuessing2Model")

function XPokerGuessing2Model:OnInit()
    self:_InitTableKey()
    ---@type NotifyPokerGuessing2Data
    self._ServerData = false
end

function XPokerGuessing2Model:ClearPrivate()
end

function XPokerGuessing2Model:ResetAll()
    self:SetServerData(nil)
end

function XPokerGuessing2Model:SetServerData(serverData)
    self._ServerData = serverData
end

function XPokerGuessing2Model:GetActivityId()
    if self._ServerData and self._ServerData.ActivityId and self._ServerData.ActivityId ~= 0 then
        return self._ServerData.ActivityId
    end
    return false
end

function XPokerGuessing2Model:IsActivityOpen()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PokerGuessing2, false, true) then
        return false
    end
    if not self._ServerData then
        return false
    end
    local activityId = self._ServerData.ActivityId
    if not activityId or activityId == 0 then
        return false
    end
    local config = self:GetPokerGuessing2ActivityConfigById(activityId)
    if not config then
        return false
    end
    if not XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
        return false
    end
    return true
end

function XPokerGuessing2Model:IsStagePassed(stageId)
    if not self._ServerData then
        return false
    end
    for i = 1, #self._ServerData.PassStages do
        if self._ServerData.PassStages[i] == stageId then
            return true
        end
    end
    return false
end

function XPokerGuessing2Model:SetStagePassed(stageId)
    self._ServerData = self._ServerData or {}
    self._ServerData.PassStages = self._ServerData.PassStages or {}
    for i = 1, #self._ServerData.PassStages do
        if self._ServerData.PassStages[i] == stageId then
            return
        end
    end
    table.insert(self._ServerData.PassStages, stageId)
end

function XPokerGuessing2Model:IsStageCanChallenge(stageId)
    if self:IsPreStagePassed(stageId) and self:IsStageOnTime(stageId) then
        return true
    end
    return false
end

function XPokerGuessing2Model:IsPreStagePassed(stageId)
    local config = self:GetPokerGuessing2StageConfigById(stageId)
    local preStageId = config.PreStage
    if preStageId ~= 0 then
        if not self:IsStagePassed(preStageId) then
            return false
        end
    end
    return true
end

function XPokerGuessing2Model:IsStageOnTime(stageId)
    local config = self:GetPokerGuessing2StageConfigById(stageId)
    local timeId = config.TimeId
    if timeId ~= 0 then
        if not XFunctionManager.CheckInTimeByTimeId(timeId) then
            return false
        end
    end
    return true
end

function XPokerGuessing2Model:IsStoryUnlock(storyId)
    -- Type=Previous 代表往期角色剧情，默认解锁
    local storyType = self:GetPokerGuessing2StoryTypeById(storyId)
    if storyType == XPokerGuessing2Enum.StoryType.Previous then
        return true
    end
    
    if not self._ServerData.UnlockStorys then
        return false
    end
    for i = 1, #self._ServerData.UnlockStorys do
        if self._ServerData.UnlockStorys[i] == storyId then
            return true
        end
    end
    return false
end

function XPokerGuessing2Model:GetSelectedRole()
    return self._ServerData.CharacterId
end

function XPokerGuessing2Model:GetUnlockStorys()
    return self._ServerData.UnlockStorys
end

function XPokerGuessing2Model:GetAllCharacters()
    local list = {}
    local configs = self:GetPokerGuessing2CharacterConfigs()
    for _, config in pairs(configs) do
        table.insert(list, config)
    end
    table.sort(list, function(a, b)
        --return a.Id < b.Id
        return a.Order < b.Order
    end)
    return list
end

function XPokerGuessing2Model:GetStoryConfig(characterId)
    local storyConfigs = self:GetPokerGuessing2StoryConfigs()
    for _, config in pairs(storyConfigs) do
        if config.CharacterId == characterId then
            return config
        end
    end
    return false
end

function XPokerGuessing2Model:SetStoryUnlock(storyId)
    self._ServerData = self._ServerData or {}
    self._ServerData.UnlockStorys = self._ServerData.UnlockStorys or {}
    for i = 1, #self._ServerData.UnlockStorys do
        if self._ServerData.UnlockStorys[i] == storyId then
            return
        end
    end
    table.insert(self._ServerData.UnlockStorys, storyId)
end

function XPokerGuessing2Model:CheckIsFirstTimeStory()
    return self._SaveUtil:GetData('XPokerGuessing2FirstTimeStory') == true
end

function XPokerGuessing2Model:SetIsFirstTimeStory(data)
    self._SaveUtil:SaveData('XPokerGuessing2FirstTimeStory', data)
end

--- 获取是否显示未播放剧情优先（按activityId区分）
---@param activityId number 活动ID
---@return boolean 是否显示未播放剧情优先，默认true
function XPokerGuessing2Model:GetShowUnplayedStoriesFirst(activityId)
    local saveKey = "PokerGuessing2ShowUnplayedStoriesFirst_" .. tostring(activityId)
    local savedValue = self._SaveUtil:GetData(saveKey)
    -- 默认激活（true），如果savedValue是nil则返回true，否则返回savedValue（可能是true或false）
    if savedValue == nil then
        return true
    else
        return savedValue
    end
end

--- 设置是否显示未播放剧情优先（按activityId区分）
---@param activityId number 活动ID
---@param isOn boolean 是否显示未播放剧情优先
function XPokerGuessing2Model:SetShowUnplayedStoriesFirst(activityId, isOn)
    local saveKey = "PokerGuessing2ShowUnplayedStoriesFirst_" .. tostring(activityId)
    self._SaveUtil:SaveData(saveKey, isOn)
end

return XPokerGuessing2Model