---Model部分类，此处用于定义和本地缓存相关的读写逻辑
---@type XTheatre6Model
local XTheatre6Model = XClassPartial('XTheatre6Model')

local SAVE_KEY_PERSISTENT = "SAVE_KEY_PERSISTENT" --持久化
local SAVE_KEY_ACTIVITY = "SAVE_KEY_ACTIVITY" --跟随活动期数变化

local GET_BUFF = 1
local AVG = 2
local ANNO = 3

function XTheatre6Model:OnInitSave()
    self._SaveUtil:SetCustomVersionGetFunc(handler(self, self.GetPersistentVersion), SAVE_KEY_PERSISTENT)
    self._SaveUtil:SetCustomVersionGetFunc(handler(self, self.GetActivityVersion), SAVE_KEY_ACTIVITY)
end

function XTheatre6Model:GetPersistentVersion()
    return 1
end

function XTheatre6Model:GetActivityVersion()
    return self._ActivityId
end

---是否使用肉鸽涂装
---@param roleId number 角色Id
---@return boolean
function XTheatre6Model:IsUseRogueFashion(roleId)
    local value = self._SaveUtil:GetDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("Theatre6UseRogueFashion_%s", roleId))
    if value == nil then
        return true
    end
    return value
end

function XTheatre6Model:SetUseRogueFashion(roleId, bo)
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("Theatre6UseRogueFashion_%s", roleId), bo)
end

function XTheatre6Model:IsBuffBeViewed(buffId)
    local value = self._SaveUtil:GetDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("Theatre6BuffBeViewed_%s", buffId))
    return value == true
end

function XTheatre6Model:SetBuffBeViewed(buffId)
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("Theatre6BuffBeViewed_%s", buffId), true)
end

function XTheatre6Model:GetSelectRoleId(mode)
    return self._SaveUtil:GetDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("Theatre6SelectRoleId_%s", mode))
end

function XTheatre6Model:SetSelectRoleId(mode, roleId)
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("Theatre6SelectRoleId_%s", mode), roleId)
end

function XTheatre6Model:IsPvPlayed(videoId)
    return self._SaveUtil:GetDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("Theatre6PV_%s", videoId))
end

function XTheatre6Model:SetPvPlayed(videoId)
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("Theatre6PV_%s", videoId), true)
end

---获取最后查看剧情时间
---@return number
function XTheatre6Model:GetLastViewStoryTime()
    return self._SaveUtil:GetDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("Theatre6_LastViewStoryTime_%d", XPlayer.Id)) or 0
end

---保存最后查看剧情时间
function XTheatre6Model:SaveLastViewStoryTime()
    local key = string.format("Theatre6_LastViewStoryTime_%d", XPlayer.Id)
    local timestamp = XTime.GetServerNowTimestamp()
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_PERSISTENT, key, timestamp)
end

function XTheatre6Model:GetStageViewStatusKey()
    return string.format("Theatre6StageViewStatus_%s", self._CurrentMode)
end

function XTheatre6Model:ClearStageViewStatus()
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_ACTIVITY, self:GetStageViewStatusKey(), nil)
end

function XTheatre6Model:SetStageViewStatus(uiType, isFinish)
    local blockKey = self:GetStageViewStatusKey()
    local modelData = self:GetCurPlayModeData()
    local saveData = self._SaveUtil:GetDataByBlockKey(SAVE_KEY_ACTIVITY, blockKey)
    if not saveData then
        saveData = {}
    else
        saveData = XTool.Clone(saveData)
    end
    local key = modelData.CurFloorIdx * 100 + uiType --楼层+界面类型
    saveData[key] = isFinish
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_ACTIVITY, blockKey, saveData)
end

---@return boolean
function XTheatre6Model:GetStageViewStatus(uiType, floorIdx)
    local modelData = self:GetCurPlayModeData()
    local saveData = self._SaveUtil:GetDataByBlockKey(SAVE_KEY_ACTIVITY, self:GetStageViewStatusKey())
    floorIdx = floorIdx or modelData.CurFloorIdx
    local key = floorIdx * 100 + uiType
    return saveData and saveData[key]
end

function XTheatre6Model:SetGetBuffPopupFinish()
    self:SetStageViewStatus(GET_BUFF, true)
end

---在进入新楼层时打开初始Buff弹窗
function XTheatre6Model:IsGetBuffPopupNeedOpen()
    return not self:GetStageViewStatus(GET_BUFF)
end

function XTheatre6Model:SetAvgFinish()
    self:SetStageViewStatus(AVG, true)
end

---在进入新楼层时播放Avg
function XTheatre6Model:IsAvgNeedOpen(floorIdx)
    return not self:GetStageViewStatus(AVG, floorIdx)
end

function XTheatre6Model:SetAnnoFinish()
    self:SetStageViewStatus(ANNO, true)
end

---在进入新楼层时打开报幕界面
function XTheatre6Model:IsAnnoNeedOpen(floorIdx)
    return not self:GetStageViewStatus(ANNO, floorIdx)
end

return XTheatre6Model