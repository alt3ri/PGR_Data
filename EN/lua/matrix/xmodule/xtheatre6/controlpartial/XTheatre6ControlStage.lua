---Control部分类，此处用于处理关卡相关逻辑
---@type XTheatre6Control
local XTheatre6Control = XClassPartial('XTheatre6Control')

local StageStatus = XEnumConst.Theatre6.StageStatus

---模式
---@return number
function XTheatre6Control:GetCurPlayMode()
    return self._Model:GetCurPlayMode()
end

---楼层数据
---@return XTheatre6ModeBaseProtocol
function XTheatre6Control:GetCurPlayModeData()
    return self._Model:GetCurPlayModeData()
end

---@return XTheatre6ModeBaseProtocol
function XTheatre6Control:GetPlayModeData(playMode)
    return self._Model:GetPlayModeData(playMode)
end

---房间数据
---@return XTheatre6StageRoomProtocol
function XTheatre6Control:GetCurRoomData()
    return self._Model:GetCurRoomData()
end

---获取故事线关卡状态
function XTheatre6Control:GetStoryLineStatus(characterId, stageIndex)
    return self._Model:GetStoryLineStageStatus(characterId, stageIndex)
end

---剧情进度
function XTheatre6Control:GetStoryProgress(characterId)
    local stageIds = self._Model:GetStageIds(characterId)
    local finish = 0
    local total = #stageIds
    for i = 1, total do
        if self:GetStoryLineStatus(characterId, i) == StageStatus.Passed then
            finish = finish + 1
        end
    end
    return finish, total
end

---角色的剧情关卡是否已全部通关
function XTheatre6Control:IsAllStoryPass(characterId)
    local finish, total = self:GetStoryProgress(characterId)
    return finish >= total
end

---当前可以挑战的剧情模式关卡索引
function XTheatre6Control:GetPlayStoryStageIndex(characterId)
    local stageIds = self._Model:GetStageIds(characterId)
    if not stageIds then
        return nil
    end
    local total = #stageIds
    for i = 1, total do
        if self:GetStoryLineStatus(characterId, i) ~= StageStatus.Passed then
            return i
        end
    end
    return total
end

---当前房间（只有XEnumConst.Theatre6.RoomType里的房间才在链表里）
function XTheatre6Control:GetCurStageNode()
    return self._Model.StageChain.Curr
end

---是否显示玩法模式按钮（共通线首通后）
---@return boolean
function XTheatre6Control:CheckOpenGamePlayModeCond()
    local conditionId = self._Model:GetIntConfigValue("PlayModeConditionId")
    return not XTool.IsNumberValid(conditionId) or XConditionManager.CheckCondition(conditionId)
end

function XTheatre6Control:CheckHasStoryProgress()
    return self._Model:GetPlayModeData(XEnumConst.Theatre6.PlayMode.Story) ~= nil
end

function XTheatre6Control:CheckHasPlayProgress()
    return self._Model:GetPlayModeData(XEnumConst.Theatre6.PlayMode.GamePlay) ~= nil
end

---San值
function XTheatre6Control:GetSanValue()
    return self._Model:GetSanValue()
end

---当前全量乱码特效 key=buff uid value=特效Id
function XTheatre6Control:GetMessyCodes()
    return self._Model:GetMessyCodes()
end

---最小San值
function XTheatre6Control:GetMinSanValue()
    return self._Model:GetMinSanValue()
end

---最大San值
function XTheatre6Control:GetMaxSanValue()
    return self._Model:GetMaxSanValue()
end

---获取San值列表
function XTheatre6Control:GetSanIds()
    return self._Model:GetSanIds()
end

---@return XTableTheatre6StageSan
function XTheatre6Control:GetCurSanConfig()
    return self._Model:GetCurSanConfig()
end

---获取当前San分组下所有San配置（已按展示顺序排序）
---@return XTableTheatre6StageSan[]
function XTheatre6Control:GetAllSanConfigs()
    local sanIds = self._Model:GetSanIds()
    local configs = {}
    for _, sanId in ipairs(sanIds) do
        table.insert(configs, self:GetSanConfigById(sanId))
    end
    return configs
end

---获取当前SanType（1=正常 2=小于 3=大于 4=死亡）
---@return number
function XTheatre6Control:GetCurrentSanType()
    local curConfig = self:GetCurSanConfig()
    return curConfig and curConfig.SanType or 1
end

---获取San配置
---@return XTableTheatre6StageSan
function XTheatre6Control:GetSanConfigById(id)
    return self._Model:GetSanConfig(id)
end

---获取San分组Id
function XTheatre6Control:GetSanGroupId()
    return self._Model:GetSanGroupId()
end

---获取San详情弹窗所需的排序卡片列表
---排序规则：死亡(MinSan=0) → 小于(从大到小) → 正常 → 大于(从小到大) → 死亡(MaxSan=max)
---@return XTableTheatre6StageSan[]
function XTheatre6Control:GetSortedSanCardsForDetail()
    local allConfigs = self:GetAllSanConfigs()
    --san值范围从小到大排序
    table.sort(allConfigs, function(a, b)
        return a.MinSan < b.MinSan
    end)
    return allConfigs
end

---检查某个San配置是否处于当前激活状态
---@param sanConfig XTableTheatre6StageSan
---@return boolean
function XTheatre6Control:IsSanConfigActive(sanConfig)
    local curConfig = self:GetCurSanConfig()
    if not curConfig then
        return false
    end
    return curConfig.Id == sanConfig.Id
end


---获取San标题文案
---@return string
function XTheatre6Control:GetSanTitleText()
    local curConfig = self:GetCurSanConfig()
    if curConfig and curConfig.SanTitleDes and #curConfig.SanTitleDes > 0 then
        return curConfig.SanTitleDes
    end
    if curConfig then
        if curConfig.SanType == 1 then
            return XUiHelper.GetText("Theatre6SanTitleNormal")
        elseif curConfig.SanType == 4 then
            return XUiHelper.GetText("Theatre6SanTitleDeath")
        else
            return XUiHelper.GetText("Theatre6SanTitleAbnormal")
        end
    end
    return ""
end

function XTheatre6Control:IsStoryAvgAlreadyPlayed(avgId)
    return self._Model:IsStoryAvgAlreadyPlayed(avgId)
end

function XTheatre6Control:IsStagePass(storyLineId, stageIndex)
    return self._Model:IsStagePass(storyLineId, stageIndex)
end

return XTheatre6Control