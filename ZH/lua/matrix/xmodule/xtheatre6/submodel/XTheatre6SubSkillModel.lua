---@class XTheatre6SubSkillModel : XModel 角色技能
---@field _MainModel XTheatre6Model
---@field _SkillsByMode table<number, table<number, table<number, XTheatre6Skill>>> 技能数据，第一层key是玩法Id，第二层key是槽位类型，第三层key是槽位位置
---@field _CurrentSkills table<number, table<number, XTheatre6Skill>> 当前玩法技能缓存，第一层key是槽位类型，第二层key是槽位位置
local XTheatre6SubSkillModel = XClass(XModel, "XTheatre6SubSkillModel")

local SkillType = XEnumConst.Theatre6.SkillType
local SlotType = XEnumConst.Theatre6.SlotType
local SyncSlotTypes = {
    SlotType.Active,
    SlotType.Insert,
    SlotType.Special,
    SlotType.Bag,
}

--region Lifecycle / Cache

function XTheatre6SubSkillModel:OnInit()
    self._SkillSlotDict = {
        [SkillType.Active] = { SlotType.Active },
        [SkillType.Parry] = { SlotType.Special },
        [SkillType.OverClock] = { SlotType.Special },
        [SkillType.Insert] = { SlotType.Insert, SlotType.Special },
    }

    self._SkillMaxLevel = 999 -- todo
    self._SkillsByMode = {}
    self._ForceSellSkillFlagByMode = {}
    self._CurrentSkills = {
        [SlotType.Active] = {},
        [SlotType.Insert] = {},
        [SlotType.Special] = {},
        [SlotType.Bag] = {},
    }
    self._NewSkillIdSet = {}
end

function XTheatre6SubSkillModel:ClearPrivate()
    self._SkillsByMode = {}
    self._CurrentSkills = {
        [SlotType.Active] = {},
        [SlotType.Insert] = {},
        [SlotType.Special] = {},
        [SlotType.Bag] = {},
    }
    self._BaseSkillCache = nil
    self._BaseSkillCharacterId = nil
    self._ForceSellSkillFlagByMode = {}
    self._NewSkillIdSet = {}
end

function XTheatre6SubSkillModel:ResetAll()
    self:ClearPrivate()
end

function XTheatre6SubSkillModel:ClearSkillData(playModeId)
    if self._SkillsByMode then
        self._SkillsByMode[playModeId] = nil
    end

    if self._MainModel:GetCurPlayMode() == playModeId then
        self._CurrentSkills = {
            [SlotType.Active] = {},
            [SlotType.Insert] = {},
            [SlotType.Special] = {},
            [SlotType.Bag] = {},
        }
    end

    self._BaseSkillCache = nil
    self._BaseSkillCharacterId = nil
    self:ClearSkillOverQueue(playModeId)
end

--endregion

--region Skill Cache / Sync / Update

function XTheatre6SubSkillModel:SetCharacterSkills(playModeId, skills)
    if not self._SkillsByMode then
        self._SkillsByMode = {}
    end

    local modeSkills = {
        [SlotType.Active] = {},
        [SlotType.Insert] = {},
        [SlotType.Special] = {},
        [SlotType.Bag] = {},
    }

    for _, skillData in pairs(skills or {}) do
        if not modeSkills[skillData.SlotType] then
            XLog.Error("技能数据槽位类型错误， skillId:" .. skillData.SkillId .. " slotType:" .. skillData.SlotType)
        else
            modeSkills[skillData.SlotType][skillData.Position] = skillData
        end
    end

    self._SkillsByMode[playModeId] = modeSkills
    if self._MainModel:GetCurPlayMode() == playModeId then
        self._CurrentSkills = modeSkills
    end
end

---角色所有技能包括已穿戴和未穿戴的
---@param slotType number 槽位类型，不传表示获取所有槽位上的技能
---@param force boolean 是否强制重新获取技能数据
---@return table<number, XTheatre6Skill> 技能数据，第一层key是槽位类型，第二层key是槽位位置
function XTheatre6SubSkillModel:GetCharacterSkills(slotType)
    local playModeId = self._MainModel:GetCurPlayMode()
    local modeSkills = self._SkillsByMode and self._SkillsByMode[playModeId]
    if not modeSkills then
        local modelData = self._MainModel:GetCurPlayModeData()
        if modelData then
            self:SetCharacterSkills(modelData.ModeId, modelData.Skills)
        else
            XLog.Error("XTheatre6SubSkillModel:GetCharacterSkills error: model data is nil for playModeId ", playModeId)
        end
    else
        self._CurrentSkills = modeSkills
    end

    if slotType then
        return self._CurrentSkills[slotType] or {}
    end

    return self._CurrentSkills
end

function XTheatre6SubSkillModel:SyncSkillsToModelData()
    local modelData = self._MainModel:GetCurPlayModeData()
    if not modelData then
        return
    end

    local currentSkills = self:GetCharacterSkills()
    local syncSkills = {}
    local index = 1
    for _, slotType in ipairs(SyncSlotTypes) do
        local slotSkillGroup = currentSkills[slotType] or {}
        for pos = 1, self:GetSlotMaxLimit(slotType) do
            local skillData = slotSkillGroup[pos]
            if skillData then
                syncSkills[index] = skillData
                index = index + 1
            end
        end
    end

    modelData.Skills = syncSkills
end

---收集自动获取技能场景下需要的 toast 标志，必须在 UpdateSkills 修改缓存前调用
---@param skillUpdateData table 后端单条 SkillUpdate 数据
---@return boolean hasUpgradeReplace 是否存在同 key 高等级替换装备槽位
---@return boolean hasLowLevelToBag 是否存在同 key 低等级技能进入背包
function XTheatre6SubSkillModel:CollectAddSkillToastFlags(skillUpdateData)
    if not skillUpdateData then
        return false, false
    end

    local currentSkills = self:GetCharacterSkills()
    local addSkill = skillUpdateData.AddSkill
    if not (addSkill and XTool.IsNumberValid(addSkill.SkillId)) then
        --无 AddSkill 字段说明后端是合成升级类逻辑,不属于"新获得技能"场景
        return false, false
    end

    local addSkillKey = self:GetSkillKey(addSkill.SkillId)
    local addSkillLevel = self:GetSkillLevel(addSkill.SkillId)

    --本次 ReplaceSkills 在装备槽上的覆盖表,代表"更新后"的装备视图,供两个 flag 共用
    local replaceLookup
    if skillUpdateData.ReplaceSkills then
        replaceLookup = {}
        for _, skillData in pairs(skillUpdateData.ReplaceSkills) do
            if skillData and XTool.IsNumberValid(skillData.SkillId) and skillData.SlotType ~= SlotType.Bag then
                replaceLookup[skillData.SlotType] = replaceLookup[skillData.SlotType] or {}
                replaceLookup[skillData.SlotType][skillData.Position] = skillData
            end
        end
    end

    local hasUpgradeReplace = false
    if replaceLookup then
        for slotType, slotReplace in pairs(replaceLookup) do
            local slotGroup = currentSkills[slotType]
            for pos, skillData in pairs(slotReplace) do
                if self:GetSkillKey(skillData.SkillId) == addSkillKey then
                    local oldData = slotGroup and slotGroup[pos]
                    if oldData and XTool.IsNumberValid(oldData.SkillId)
                        and self:GetSkillKey(oldData.SkillId) == addSkillKey
                        and self:GetSkillLevel(skillData.SkillId) > self:GetSkillLevel(oldData.SkillId) then
                        hasUpgradeReplace = true
                        break
                    end
                end
            end
            if hasUpgradeReplace then
                break
            end
        end
    end

    local hasLowLevelToBag = false
    if addSkill.SlotType == SlotType.Bag then
        for slotType, slotGroup in pairs(currentSkills) do
            if slotType ~= SlotType.Bag then
                local replaceSlot = replaceLookup and replaceLookup[slotType]
                local positions = {}
                for pos in pairs(slotGroup) do
                    positions[pos] = true
                end
                if replaceSlot then
                    for pos in pairs(replaceSlot) do
                        positions[pos] = true
                    end
                end
                for pos in pairs(positions) do
                    local equipData = (replaceSlot and replaceSlot[pos]) or slotGroup[pos]
                    if equipData and XTool.IsNumberValid(equipData.SkillId)
                        and self:GetSkillKey(equipData.SkillId) == addSkillKey
                        and self:GetSkillLevel(equipData.SkillId) > addSkillLevel then
                        hasLowLevelToBag = true
                        break
                    end
                end
                if hasLowLevelToBag then
                    break
                end
            end
        end
    end

    return hasUpgradeReplace, hasLowLevelToBag
end

function XTheatre6SubSkillModel:UpdateSkills(skillUpdateData, ignoreNewSkill)
    if not skillUpdateData then
        XLog.Error("后端同步技能移动或交换时，返回数据中缺少技能更新数据")
        return
    end

    local currentSkills = self:GetCharacterSkills()

    local addSkillIdSetBySlot = {
        [SlotType.Active] = {},
        [SlotType.Insert] = {},
        [SlotType.Special] = {},
    }
    local upgradeSkillIdSet = {}
    if skillUpdateData.ReplaceSkills then
        for _, skillData in pairs(skillUpdateData.ReplaceSkills) do
            if skillData and XTool.IsNumberValid(skillData.SkillId) then
                local bucket = addSkillIdSetBySlot[skillData.SlotType]
                if bucket then
                    bucket[skillData.SkillId] = true
                end
                local slotGroup = currentSkills[skillData.SlotType]
                local oldData = slotGroup and slotGroup[skillData.Position]
                if oldData and XTool.IsNumberValid(oldData.SkillId)
                    and self:GetSkillKey(oldData.SkillId) == self:GetSkillKey(skillData.SkillId)
                    and self:GetSkillLevel(skillData.SkillId) > self:GetSkillLevel(oldData.SkillId) then
                    upgradeSkillIdSet[skillData.SkillId] = true
                end
            end
        end
    end
    if skillUpdateData.AddSkill and XTool.IsNumberValid(skillUpdateData.AddSkill.SkillId) then
        local bucket = addSkillIdSetBySlot[skillUpdateData.AddSkill.SlotType]
        if bucket then
            bucket[skillUpdateData.AddSkill.SkillId] = true
        end
        if not ignoreNewSkill and skillUpdateData.AddSkill.SlotType == SlotType.Bag then
            self:MarkSkillAsNew(skillUpdateData.AddSkill.SkillId)
        end
    end

    local isUpdated = false
    if skillUpdateData.ReplaceSkills and self:ReplaceSkills(skillUpdateData.ReplaceSkills) then
        isUpdated = true
    end
    if skillUpdateData.RemovesSkills and self:RemovesSkills(skillUpdateData.RemovesSkills) then
        isUpdated = true
    end
    if skillUpdateData.AddSkill and self:AddSkill(skillUpdateData.AddSkill) then
        isUpdated = true
    end

    if not isUpdated then
        return
    end

    self:SyncSkillsToModelData()
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_UPDATE_SKILL, addSkillIdSetBySlot, upgradeSkillIdSet)
end

function XTheatre6SubSkillModel:UpdateSkillsWithOverQueue(skillUpdateData, playModeId, ignoreNewSkill)
    self:UpdateSkills(skillUpdateData, ignoreNewSkill)
    if not skillUpdateData then
        return
    end

    if XTool.IsNumberValid(skillUpdateData.FullEnQueueSkill) then
        self:AddSkillOverQueue(skillUpdateData.FullEnQueueSkill, playModeId)
    end

    if not XTool.IsTableEmpty(skillUpdateData.DequeueSkills) then
        self:RemoveSkillOverQueueBySkillIds(skillUpdateData.DequeueSkills, playModeId)
    end
end

function XTheatre6SubSkillModel:UpdateSkillListWithOverQueue(skillUpdates, playModeId, ignoreNewSkill)
    playModeId = playModeId or self._MainModel:GetCurPlayMode()
    for _, skillUpdateData in ipairs(skillUpdates or {}) do
        self:UpdateSkillsWithOverQueue(skillUpdateData, playModeId, ignoreNewSkill)
    end
end

---实际上后端会类似2048，先卖掉原技能，再添加新技能，所以前端只要覆盖更新原技能就行
function XTheatre6SubSkillModel:ReplaceSkills(replaceSkills)
    local currentSkills = self:GetCharacterSkills()
    local isUpdated = false

    for key, skillData in pairs(replaceSkills or {}) do
        local slotSkillGroup = currentSkills[skillData.SlotType]
        local pos = skillData.Position
        if not slotSkillGroup or not slotSkillGroup[pos] then
            XLog.Error("后端同步技能替换时，原技能位置不存在，无法替换， skillId:" .. skillData.SkillId .. " position:" .. key.. " slotType:" .. skillData.SlotType)
        else
            slotSkillGroup[pos] = skillData
            isUpdated = true
        end
    end

    return isUpdated
end

function XTheatre6SubSkillModel:RemovesSkills(removesSkills)
    local currentSkills = self:GetCharacterSkills()
    local isUpdated = false

    for key, skillUpdateData in pairs(removesSkills or {}) do
        local slotSkillGroup = currentSkills[skillUpdateData.SlotType]
        if not slotSkillGroup then
            XLog.Error("后端同步技能移除时，槽位类型不存在， skillId:" .. skillUpdateData.SkillId .. " position:" .. key.. " slotType:" .. skillUpdateData.SlotType)
        else
            local pos = skillUpdateData.Position
            local targetSkillData = slotSkillGroup[pos]
            if targetSkillData and targetSkillData.SkillId == skillUpdateData.SkillId then
                slotSkillGroup[pos] = nil
                isUpdated = true
            else
                local skillData = nil
                local realPos = nil
                for position, cacheSkillData in pairs(slotSkillGroup) do
                    if cacheSkillData.SkillId == skillUpdateData.SkillId then
                        skillData = cacheSkillData
                        realPos = position
                        break
                    end
                end
                if not skillData then
                    XLog.Error("后端同步技能移除时，技能不存在当前前端缓存中， skillId:" .. skillUpdateData.SkillId .. " position:" .. key.. " slotType:" .. skillUpdateData.SlotType)
                else
                    slotSkillGroup[realPos] = nil
                    isUpdated = true
                end
            end
        end
    end

    return isUpdated
end

function XTheatre6SubSkillModel:AddSkill(addSkill)
    local slotSkillGroup = self:GetCharacterSkills(addSkill.SlotType)
    if not slotSkillGroup then
        XLog.Error("后端同步技能添加时，技能槽位类型错误， skillId:" .. addSkill.SkillId .. " slotType:" .. addSkill.SlotType .. " position:" .. addSkill.Position)
        return false
    end

    if slotSkillGroup[addSkill.Position] then
        XLog.Error("后端同步技能添加时，技能位置已存在，无法添加， skillId:" .. addSkill.SkillId .. " position:" .. addSkill.Position .. " slotType:" .. addSkill.SlotType)
        return false
    end

    slotSkillGroup[addSkill.Position] = addSkill
    return true
end

---根据技能id获取技能数据
---@param skillId number 技能id
---@return XTheatre6Skill skillId slotType position 技能数据
function XTheatre6SubSkillModel:GetSkillData(slotType, skillId)
    local slotSkillGroup = self:GetCharacterSkills(slotType)
    if not slotSkillGroup then
        return nil
    end

    for _, skillData in pairs(slotSkillGroup) do
        if skillData.SkillId == skillId then
            return skillData
        end
    end

    return nil
end

---设置溢出技能强制处理技能Id,缓存当前玩法的溢出技能列表
function XTheatre6SubSkillModel:SetForceSellSkillFlag(overQueue, playModeId)
    playModeId = playModeId or self._MainModel:GetCurPlayMode()
    if not playModeId then
        return
    end

    if not self._ForceSellSkillFlagByMode then
        self._ForceSellSkillFlagByMode = {}
    end

    local playModeData = self._MainModel:GetPlayModeData(playModeId)
    if not playModeData then
        return
    end

    playModeData.SkillOverQueue = overQueue or playModeData.SkillOverQueue
    overQueue = playModeData.SkillOverQueue
    if XTool.IsTableEmpty(overQueue) or not XTool.IsNumberValid(overQueue[1]) then
        self:ClearSkillOverQueue(playModeId)
        return
    end
    self._ForceSellSkillFlagByMode[playModeId] = overQueue[1]
end

---清除溢出技能强制处理技能Id
function XTheatre6SubSkillModel:ClearForceSellSkillFlag(playModeId)
    playModeId = playModeId or self._MainModel:GetCurPlayMode()
    if self._ForceSellSkillFlagByMode and playModeId then
        self._ForceSellSkillFlagByMode[playModeId] = nil
    end
end

function XTheatre6SubSkillModel:GetForceSellSkillOverQueue(playModeId)
    playModeId = playModeId or self._MainModel:GetCurPlayMode()
    local playModeData = playModeId and self._MainModel:GetPlayModeData(playModeId)
    return playModeData and playModeData.SkillOverQueue
end

function XTheatre6SubSkillModel:AddSkillOverQueue(skillId, playModeId)
    if not XTool.IsNumberValid(skillId) then
        return
    end

    playModeId = playModeId or self._MainModel:GetCurPlayMode()
    local playModeData = playModeId and self._MainModel:GetPlayModeData(playModeId)
    if not playModeData then
        return
    end

    if not playModeData.SkillOverQueue then
        playModeData.SkillOverQueue = {}
    end
    table.insert(playModeData.SkillOverQueue, skillId)
    self:SetForceSellSkillFlag(playModeData.SkillOverQueue, playModeId)
end

function XTheatre6SubSkillModel:PopSkillOverQueue(playModeId)
    local overQueue = self:GetForceSellSkillOverQueue(playModeId)
    if XTool.IsTableEmpty(overQueue) then
        self:ClearSkillOverQueue(playModeId)
        return nil
    end

    local skillId = table.remove(overQueue, 1)
    if XTool.IsTableEmpty(overQueue) then
        self:ClearSkillOverQueue(playModeId)
    else
        self:SetForceSellSkillFlag(overQueue, playModeId)
    end
    return skillId
end

function XTheatre6SubSkillModel:RemoveSkillOverQueueBySkillIds(skillIds, playModeId)
    local overQueue = self:GetForceSellSkillOverQueue(playModeId)
    if XTool.IsTableEmpty(overQueue) then
        self:ClearSkillOverQueue(playModeId)
        return
    end

    for _, skillId in ipairs(skillIds or {}) do
        for index = #overQueue, 1, -1 do
            if overQueue[index] == skillId then
                table.remove(overQueue, index)
                break
            end
        end
    end

    if XTool.IsTableEmpty(overQueue) then
        self:ClearSkillOverQueue(playModeId)
    else
        self:SetForceSellSkillFlag(overQueue, playModeId)
    end
end

function XTheatre6SubSkillModel:IsForceSellSkillBlock(playModeId)
    playModeId = playModeId or self._MainModel:GetCurPlayMode()
    local overQueue = self:GetForceSellSkillOverQueue(playModeId)
    if XTool.IsTableEmpty(overQueue) then
        self:ClearSkillOverQueue(playModeId)
        return false
    end

    local skillId = self._ForceSellSkillFlagByMode and self._ForceSellSkillFlagByMode[playModeId]
    local overQueueSkillId = overQueue[1]
    if not XTool.IsNumberValid(overQueueSkillId) then
        self:ClearSkillOverQueue(playModeId)
        return false
    end
    if not XTool.IsNumberValid(skillId) or skillId ~= overQueueSkillId then
        self:SetForceSellSkillFlag(overQueue, playModeId)
    end
    return true
end

function XTheatre6SubSkillModel:OnNotifySkillData(playModeData)
    if playModeData then
        self:SetCharacterSkills(playModeData.ModeId, playModeData.Skills)
        if not XTool.IsTableEmpty(playModeData.SkillOverQueue) then
            self:SetForceSellSkillFlag(playModeData.SkillOverQueue, playModeData.ModeId)
        end
    end

    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_UPDATE_SKILL)
end

function XTheatre6SubSkillModel:OpenSellSkillPanel(overQueue)
    if XTool.IsTableEmpty(overQueue) then
        self:ClearSkillOverQueue()
        return
    end
    self:SetForceSellSkillFlag(overQueue)
    if XLuaUiManager.IsUiShow("UiFightDLC") or XLuaUiManager.IsUiShow("UiTheatre6RoundSettlement") then
        return
    end
    local curOverQueue = self:GetForceSellSkillOverQueue(self._MainModel:GetCurPlayMode())
    if self.PopupSellSkillTimer then
        XScheduleManager.UnSchedule(self.PopupSellSkillTimer)
        self.PopupSellSkillTimer = nil
    end
    self.PopupSellSkillTimer = XScheduleManager.ScheduleNextFrame(function()
        if XLuaUiManager.IsUiLoad("UiTheatre6PopupSellSkill") or XLuaUiManager.IsUiPushing("UiTheatre6PopupSellSkill") then
            XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_OVER_SKILL_REFRESH, curOverQueue)
            self.PopupSellSkillTimer = nil
            return
        end
   
        XLuaUiManager.Open("UiTheatre6PopupSellSkill", curOverQueue)
    end)
 
end

---清理后端推送的溢出队列缓存（售卖完成后调用）
function XTheatre6SubSkillModel:ClearSkillOverQueue(playModeId)
    playModeId = playModeId or self._MainModel:GetCurPlayMode()
    local playModeData = playModeId and self._MainModel:GetPlayModeData(playModeId)
    if playModeData then
        playModeData.SkillOverQueue = nil
    end
    self:ClearForceSellSkillFlag(playModeId)
end

--endregion

--region Bag / Slot Queries

---角色穿戴的所有技能
---@param slotType number 槽位类型，不传表示获取所有槽位上的技能
---@return number[] 技能id列表
function XTheatre6SubSkillModel:GetCharacterDressSkillIds(roleId, slotType)
    local skillIds = {}
    local currentSkills = self:GetCharacterSkills()

    if slotType then
        for pos, skillData in pairs(currentSkills[slotType] or {}) do
            skillIds[pos] = skillData.SkillId
        end
        return skillIds
    end

    local index = 1
    for _, slotSkillGroup in pairs(currentSkills) do
        for _, skillData in pairs(slotSkillGroup) do
            skillIds[index] = skillData.SkillId
            index = index + 1
        end
    end

    return skillIds
end

---角色技能背包里所有技能
---@return number[]
function XTheatre6SubSkillModel:GetCharacterSkillBagIds(roleId)
    local bagSkillIds = {}
    for pos, skillData in pairs(self:GetCharacterSkills(SlotType.Bag)) do
        if XTool.IsNumberValid(skillData.SkillId) then
            bagSkillIds[pos] = skillData.SkillId
        end
    end
    return bagSkillIds
end

---槽位上已装备的技能数量
function XTheatre6SubSkillModel:GetCharacterDressSkillCount(roleId, slotType)
    local count = 0
    for _ in pairs(self:GetCharacterDressSkillIds(roleId, slotType)) do
        count = count + 1
    end
    return count
end

---技能背包是否已满
function XTheatre6SubSkillModel:IsSkillBagFull(roleId)
    local count = 0
    for _ in pairs(self:GetCharacterSkillBagIds(roleId)) do
        count = count + 1
    end
    return count >= self:GetSkillBagCapacity()
end

---槽位是否已满
function XTheatre6SubSkillModel:IsSlotFull(roleId, slotType)
    return self:GetCharacterDressSkillCount(roleId, slotType) >= self:GetSlotCapacity(slotType)
end

---装备槽空位位置
---@return number[] 空位位置
function XTheatre6SubSkillModel:GetEmptySlotPositions(roleId, slotType)
    local skillIds
    if slotType == SlotType.Bag then
        skillIds = self:GetCharacterSkillBagIds(roleId)
    else
        skillIds = self:GetCharacterDressSkillIds(roleId, slotType)
    end

    local emptyPositions = {}
    for index = 1, self:GetSlotMaxLimit(slotType) do
        if not skillIds[index] then
            table.insert(emptyPositions, index)
        end
    end

    return emptyPositions
end

function XTheatre6SubSkillModel:CheckSkillHad(skillId)
    for _, slotSkillGroup in pairs(self:GetCharacterSkills()) do
        for _, skillData in pairs(slotSkillGroup) do
            if skillData.SkillId == skillId then
                return true
            end
        end
    end

    return false
end

---是否背包存在同技能key且等级更高的技能
function XTheatre6SubSkillModel:ExistsHighLevelSkill(skillId)
    local targetSkillKey = self:GetSkillKey(skillId)
    local targetSkillLevel = self:GetSkillLevel(skillId)
    for _, skillData in pairs(self:GetCharacterSkills(SlotType.Bag)) do
        local bagSkillId = skillData.SkillId
        if self:GetSkillKey(bagSkillId) == targetSkillKey and self:GetSkillLevel(bagSkillId) > targetSkillLevel then
            return true
        end
    end

    return false
end

---仓库存在不同key的技能,且可装配到指定槽位
function XTheatre6SubSkillModel:CheckAnotherSkill(skillId, slotType)
    local bagSkills = self:GetCharacterSkills(SlotType.Bag)
    if not bagSkills or #bagSkills == 0 then
        return false
    end

    local targetSkillKey = self:GetSkillKey(skillId)
    for _, skillData in pairs(bagSkills) do
        if self:GetSkillKey(skillData.SkillId) ~= targetSkillKey then
            local installSlots = self:GetSkillInstallSlots(skillData.SkillId)
            if installSlots then
                for _, installSlot in pairs(installSlots) do
                    if installSlot == slotType then
                        return true
                    end
                end
            end
        end
    end

    return false
end

--endregion

--region Config / Rules

---技能背包槽位数量（v4.5暂无扩容逻辑）
function XTheatre6SubSkillModel:GetSkillBagCapacity()
    return self._MainModel:GetIntConfigValue("SkillBagSlotLimit")
end

function XTheatre6SubSkillModel:GetSlotMaxLimit(slotType)
    if not self._SlotLimitDict then
        self._SlotLimitDict = {
            [SlotType.Active] = self._MainModel:GetIntConfigValue("ActiveSkillSlotLimit"),
            [SlotType.Insert] = self._MainModel:GetIntConfigValue("InsertSkillSlotLimit"),
            [SlotType.Special] = 1,
            [SlotType.Bag] = self:GetSkillBagCapacity(),
        }
    end

    return self._SlotLimitDict[slotType] or 0
end

---槽位容量
function XTheatre6SubSkillModel:GetSlotCapacity(slotType)
    if not self._SlotCapacityDict then
        self._SlotCapacityDict = {
            [SlotType.Active] = self._MainModel:GetIntConfigValue("ActiveSkillSlotInitCount"),
            [SlotType.Insert] = self._MainModel:GetIntConfigValue("InsertSkillSlotInitCount"),
            [SlotType.Special] = 1,
        }
    end

    return self._SlotCapacityDict[slotType] or 0
end

---当前玩法技能id即配置id，保留该接口兼容旧调用
function XTheatre6SubSkillModel:GetSkillConfigId(id)
    return id
end

---技能类型
function XTheatre6SubSkillModel:GetSkillType(id)
    return self._MainModel:GetSkillCfgById(id).Type
end

---技能key
function XTheatre6SubSkillModel:GetSkillKey(id)
    return self._MainModel:GetSkillCfgById(id).SkillKey
end

---技能可安装槽位
---@param skillId number 技能ID
---@return number[] 可安装槽位类型
function XTheatre6SubSkillModel:GetSkillInstallSlots(skillId)
    local skillType = self:GetSkillType(skillId)
    return self._SkillSlotDict[skillType]
end

---查找技能当前装备的槽位位置;不在装备槽(在背包或不存在)时返回 nil
---@param skillId number 技能ID
---@return number|nil slotType 槽位类型
---@return number|nil position 槽位位置
function XTheatre6SubSkillModel:GetSkillEquippedPosition(skillId)
    if not XTool.IsNumberValid(skillId) then return nil end
    for _, slotType in ipairs({ SlotType.Active, SlotType.Insert, SlotType.Special }) do
        local group = self:GetCharacterSkills(slotType)
        if group then
            for pos, data in pairs(group) do
                if data and data.SkillId == skillId then
                    return slotType, pos
                end
            end
        end
    end
    return nil
end

---技能等级
function XTheatre6SubSkillModel:GetSkillLevel(skillId)
    return self._MainModel:GetSkillCfgById(skillId).Level
end

---技能是否满级
function XTheatre6SubSkillModel:IsSkillLevelMax(skillId)
    return self:GetSkillLevel(skillId) >= self._SkillMaxLevel
end

function XTheatre6SubSkillModel:IsSkillType(id, skillType)
    return self:GetSkillType(id) == skillType
end

function XTheatre6SubSkillModel:CanUpGradeSkill(skillId, inShop)
    local count = 0
    for _, slotSkillGroup in pairs(self:GetCharacterSkills()) do
        for _, skillData in pairs(slotSkillGroup) do
            if skillData.SkillId == skillId then
                if inShop then
                    return true
                end

                count = count + 1
                if count > 1 then
                    return true
                end
            end
        end
    end

    return false
end

---槽位上技能的最高等级
function XTheatre6SubSkillModel:GetSlotSkillMaxLevel(roleId, skillKey, slotType)
    local maxLevel = 0
    local skillIds = self:GetCharacterDressSkillIds(roleId, slotType)
    for _, id in ipairs(skillIds) do
        if self:GetSkillKey(id) == skillKey then
            maxLevel = math.max(maxLevel, self:GetSkillLevel(id))
        end
    end

    return maxLevel
end

---技能是否能装备到该槽位上
function XTheatre6SubSkillModel:CanSkillDressToSlot(roleId, skillId, slotType)
    local slots = self:GetSkillInstallSlots(skillId)
    if not slots or not table.contains(slots, slotType) then
        return false
    end

    if self:IsSlotFull(roleId, slotType) then
        return false
    end

    local lv = self:GetSkillLevel(skillId)
    local skillKey = self:GetSkillKey(skillId)
    if lv <= self:GetSlotSkillMaxLevel(roleId, skillKey, slotType) then
        return false
    end

    return true
end

---Buff能否升级该技能
function XTheatre6SubSkillModel:CanSkillLevelUpByBuff(skillId, buffId)
    if self:IsSkillLevelMax(skillId) then
        return false
    end

    if buffId then

    end

    return true
end

---是否两个相同等级技能合并升级
function XTheatre6SubSkillModel:CanSkillLevelUpByMerge(skillId, skillLevel)
    if self:IsSkillLevelMax(skillId) then
        return false
    end

    if self:GetSkillLevel(skillId) ~= skillLevel then
        return false
    end

    return true
end

function XTheatre6SubSkillModel:GetEmptyPositionsByCfg(skillId)
    local cfgSlotType = self:GetSkillType(skillId)
    self._SortSlotTypes = self._SortSlotTypes or {
        [SkillType.Active] = self._MainModel:GetConfigValues("ActiveSkillSlotSort"),
        [SkillType.Parry] = self._MainModel:GetConfigValues("ClashSkillSlotSort"),
        [SkillType.OverClock] = self._MainModel:GetConfigValues("UltraCalcSkillSlotSort"),
        [SkillType.Insert] = self._MainModel:GetConfigValues("InsertSkillSlotSort"),
    }

    local sortSlotTypes = self._SortSlotTypes[cfgSlotType]
    if not sortSlotTypes then
        return
    end

    for _, slotTypeStr in ipairs(sortSlotTypes) do
        local slotType = tonumber(slotTypeStr)
        local positions = self:GetEmptySlotPositions(nil, slotType)
        if positions and #positions > 0 then
            return slotType, positions
        end
    end
end

---获取下一级技能id
function XTheatre6SubSkillModel:GetNextLevelSkillId(tagetskillId)
    local targetSkillKey = self:GetSkillKey(tagetskillId)
    local targetLevel = self:GetSkillLevel(tagetskillId) + 1
    for skillId, skillCfg in pairs(self._MainModel:GetSkillConfigs()) do
        if skillCfg.SkillKey == targetSkillKey and skillCfg.Level == targetLevel then
            return skillId
        end
    end

    return nil
end

--endregion

--region Base Skill / Score / Flags

---获取指定槽位和位置的初始技能（BaseSkill）
---@param slotType number 槽位类型
---@param pos number 槽位位置（1-indexed）
---@return number|nil baseSkillId
function XTheatre6SubSkillModel:GetBaseSkillForSlot(slotType, pos, characterId)
    local modelData = self._MainModel:GetCurPlayModeData()
    characterId = characterId or (modelData and modelData.CharacterId)
    if not XTool.IsNumberValid(characterId) then
        return nil
    end

    local characterConfig = self._MainModel:GetCharacterConfig(characterId)
    for i, baseSkillId in ipairs(characterConfig.BaseSkill) do
        if XTool.IsNumberValid(baseSkillId) then
            local slots = self:GetSkillInstallSlots(baseSkillId)
            if slots and table.contains(slots, slotType) and i == pos then
                return baseSkillId
            end
        end
    end

    return nil
end

---获取所有穿戴中的基础技能
---@return number[]
function XTheatre6SubSkillModel:GetAllBaseSkill()
    local modelData = self._MainModel:GetCurPlayModeData()
    if not modelData then
        return {}
    end

    local characterId = modelData.CharacterId
    local slotType = SlotType.Active
    local baseSkillIds = {}
    local characterConfig = self._MainModel:GetCharacterConfig(characterId)
    local skillSlots = self:GetCharacterSkills(slotType)

    for i, baseSkillId in ipairs(characterConfig.BaseSkill) do
        if XTool.IsNumberValid(baseSkillId) and skillSlots[i] == nil then
            table.insert(baseSkillIds, baseSkillId)
        end
    end

    return baseSkillIds
end

---计算角色当前技能战力
---@return number
function XTheatre6SubSkillModel:CalcEquippedSkillScore()
    local score = 0

    for _, baseSkillId in ipairs(self:GetAllBaseSkill()) do
        local skillConfig = self._MainModel:GetSkillCfgById(baseSkillId)
        if skillConfig then
            score = score + (skillConfig.SaveScore or 0)
        end
    end

    for slotType, slotSkillGroup in pairs(self:GetCharacterSkills()) do
        if slotType ~= SlotType.Bag then
            for _, skillData in pairs(slotSkillGroup) do
                if XTool.IsNumberValid(skillData.SkillId) then
                    local skillConfig = self._MainModel:GetSkillCfgById(skillData.SkillId)
                    if skillConfig then
                        score = score + (skillConfig.SaveScore or 0)
                    end
                end
            end
        end
    end

    return score
end

function XTheatre6SubSkillModel:MarkSkillAsNew(skillId)
    if not XTool.IsNumberValid(skillId) then
        return
    end
    self._NewSkillIdSet[skillId] = true
end

function XTheatre6SubSkillModel:SetNewSkillViewed(skillId)
    self._NewSkillIdSet[skillId] = nil
end

function XTheatre6SubSkillModel:HasNewSkill(skillId)
    return self._NewSkillIdSet[skillId] == true
end

function XTheatre6SubSkillModel:ClearBagNewSkillFlags()
    if not next(self._NewSkillIdSet) then
        return false
    end
    self._NewSkillIdSet = {}
    return true
end

--endregion

return XTheatre6SubSkillModel
