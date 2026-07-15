---Control部分类，此处用于处理角色相关逻辑
---@type XTheatre6Control
local XTheatre6Control = XClassPartial('XTheatre6Control')
local ReqMethodName = {
    SkillMoveOrSwap = "Theatre6SkillMoveOrSwapRequest",
    OverQueueSell = "Theatre6SkillOverQueueSellRequest",
    BuffLevelUpSkill = "Theatre6BuffLevelUpSkillRequest"
}
local MoveSkillMaskKey = "XTheatre6Control:SkillMoveOrSwapRequest"
XTheatre6Control.ImgHighlightKey = 2

local SkillTypeBgConfigName = {
    [XEnumConst.Theatre6.SlotType.Special] = "SkillType4Bg",
    [XEnumConst.Theatre6.SlotType.Insert] = "SkillType2a3Bg",
    [XEnumConst.Theatre6.SlotType.Active] = "SkillType1Bg"
}

function XTheatre6Control:OnInitCharacter()

end

---当前模式是否已收到后端结算下发(只读态)
function XTheatre6Control:IsCurModeSettle()
    local modelData = self._Model:GetCurPlayModeData()
    return modelData ~= nil and modelData.IsSettle == true
end

---是否使用肉鸽涂装
---@param roleId number 角色Id
function XTheatre6Control:IsUseRogueFashion(roleId)
    return self._Model:IsUseRogueFashion(roleId)
end

function XTheatre6Control:SetUseRogueFashion(roleId, bo)
    self._Model:SetUseRogueFashion(roleId, bo)
end

function XTheatre6Control:GetSelectRoleId(mode)
    return self._Model:GetSelectRoleId(mode)
end

function XTheatre6Control:SetSelectRoleId(mode, roleId)
    self._Model:SetSelectRoleId(mode, roleId)
end

---技能槽位容量
function XTheatre6Control:GetSlotCapacity(slotType)
    return self._Model.Skill:GetSlotCapacity(slotType)
end

---技能槽位上限
function XTheatre6Control:GetSlotMaxLimit(slotType)
    return self._Model.Skill:GetSlotMaxLimit(slotType)
end

---根据玩家选择的涂装，获取角色头像
function XTheatre6Control:GetHeadIcon()
    local modelData = self:GetCurPlayModeData()
    local fashionId = modelData.FashionId
    return self:GetFashionConfig(fashionId).Portrait
end

function XTheatre6Control:GetHeadIconByMode(mode)
    local modelData = self._Model:GetPlayModeData(mode)
    local fashionId = modelData.FashionId
    return self:GetFashionConfig(fashionId).Portrait
end

function XTheatre6Control:GetBigHeadIconByMode(mode)
    local modelData = self._Model:GetPlayModeData(mode)
    local fashionId = modelData.FashionId
    return self:GetFashionConfig(fashionId).BigPortrait
end

---Buff是否已被销毁
function XTheatre6Control:IsBuffDestory(buffUid)
    return self._Model:IsBuffDestory(buffUid)
end

---@param data XTheatre6BuffProtocol
function XTheatre6Control:GetActiveBuffInfo(data)
    ---@type XTheatre6BuffData
    local info = {}
    info.Uid = data.Uid
    info.StackCount = 0
    info.RemainCount = data.RemainCount
    info.TriggerCount = data.TriggerCount

    local modeData = self:GetCurPlayModeData()
    for _, buff in pairs(modeData.Buffs) do
        if buff.BuffId == data.BuffId then
            info.StackCount = info.StackCount + 1
            info.RemainCount = math.min(info.RemainCount, buff.RemainCount)
        end
    end

    return info
end

---获取需要展示的角色Buff
---@return XTheatre6BuffData[]
function XTheatre6Control:GetSortCharacterShowBuffs()
    local modeData = self:GetCurPlayModeData()
    local buffs = self:FilterCharacterShowBuffs(modeData.Buffs)
    local destoryBuffs = self:FilterCharacterShowBuffs(modeData.DestroyedBuffs)
    local sortBuffs = {}

    if buffs then
        for _, data in ipairs(buffs) do
            table.insert(sortBuffs, data)
        end
    end

    if destoryBuffs then
        for _, data in ipairs(destoryBuffs) do
            table.insert(sortBuffs, data)
        end
    end

    return sortBuffs
end

function XTheatre6Control:FilterCharacterShowBuffs(buffDatas)
    if XTool.IsTableEmpty(buffDatas) then
        return nil
    end
    ---@type XTheatre6BuffData[]
    local buffs = {}
    local buffIdDict = {}
    for _, data in pairs(buffDatas) do
        local config = self:GetBuffConfig(data.BuffId)
        if not XTool.IsNumberValid(config.IsNotShow) then
            local idx = buffIdDict[data.BuffId]
            if config.CanStack and idx then
                local buff = buffs[idx]
                buff.StackCount = buff.StackCount + 1
                buff.RemainCount = math.min(buff.RemainCount, data.RemainCount)
            else
                ---@type XTheatre6BuffData
                local buff = {}
                buff.Uid = data.Uid
                buff.StackCount = 1
                buff.RemainCount = data.RemainCount
                buff.isLimitTime = config.DurationType ~= 1
                buff.TriggerCount = data.TriggerCount
                table.insert(buffs, buff)
                buffIdDict[data.BuffId] = #buffs
            end
        end
    end
    --是否销毁＞是否限时＞获取顺序
    table.sort(buffs, function(a, b)
        if a.isLimitTime ~= b.isLimitTime then
            return a.isLimitTime == true
        end
        return a.Uid < b.Uid
    end)
    return buffs
end

---@param buffDatas XTheatre6BuffSaveDataProtocol[]
function XTheatre6Control:FilterFileSaveBuffs(buffDatas)
    if XTool.IsTableEmpty(buffDatas) then
        return nil
    end
    ---@type XTheatre6BuffSaveDataProtocol[]
    local buffs = {}
    for _, buff in pairs(buffDatas) do
        local config = self:GetBuffConfig(buff.BuffId)
        if not XTool.IsNumberValid(config.IsNotShow) then
            table.insert(buffs, buff)
        end
    end
    table.sort(buffs, function(a, b)
        local aCfg = self:GetBuffConfig(a.BuffId)
        local bCfg = self:GetBuffConfig(b.BuffId)
        local isALimitTime = aCfg.DurationType ~= 1
        local isBLimitTime = bCfg.DurationType ~= 1
        if isALimitTime ~= isBLimitTime then
            return isALimitTime == true
        end
        return a.BuffId < b.BuffId
    end)
    return buffs
end

---获取存档标签（遗物+技能），不使用服务器数据
---@param fileData Theatre6FileData|Theatre6FileDataProtocol
---@return XTableTheatre6BuildTag[]
function XTheatre6Control:GetSortFileDataBuildTags(fileData)
    --组内使用权重排序（从大到小）
    local buildTagDict = {}
    local groupDict = {}
    for _, attrPack in ipairs(fileData.AttrPacks) do
        local cfg = self:GetAttrPackCfgById(attrPack.PackId)
        self:_SortMergaBuildTag(buildTagDict, groupDict, cfg.BuildTags)
    end
    for _, skill in ipairs(fileData.Skills) do
        local cfg = self:GetSkillCfgById(skill.SkillId)
        self:_SortMergaBuildTag(buildTagDict, groupDict, cfg.BuildTags)
    end
    local sortBuildTagIds = {}
    for _, id in pairs(groupDict) do
        table.insert(sortBuildTagIds, id)
    end
    --组外使用组Id排序（从小到大）
    table.sort(sortBuildTagIds, function(a, b)
        return self:GetBuildTagConfig(a).GroupId < self:GetBuildTagConfig(b).GroupId
    end)
    return sortBuildTagIds
end

function XTheatre6Control:_SortMergaBuildTag(buildTagDict, groupDict, buildTags)
    for _, curId in ipairs(buildTags) do
        local curCfg = self:GetBuildTagConfig(curId)
        if not curCfg.IsHide and XTool.IsNumberValid(curCfg.GroupId) then
            local curWeight = buildTagDict[curId] or 0
            curWeight = curWeight + curCfg.SaveWeight
            buildTagDict[curId] = curWeight
            
            local groupId = curCfg.GroupId
            local oldId = groupDict[groupId]
            if oldId and oldId ~= curId then
                local oldWeight = buildTagDict[oldId]
                local oldCfg = self:GetBuildTagConfig(oldId)
                local isHightWeight = curWeight > oldWeight
                local isHightPirority = curWeight == oldWeight and curCfg.Pirority > oldCfg.Pirority
                local isLowId = curWeight == oldWeight and curCfg.Pirority == oldCfg.Pirority and curCfg.Id < oldCfg.Id
                if isHightWeight or isHightPirority or isLowId then
                    groupDict[groupId] = curId
                end
            elseif not oldId then
                groupDict[groupId] = curId
            end
        end
    end
end

---获取任务免费刷新次数
function XTheatre6Control:GetTaskFreeRefreshTimes(taskGroupId)
    return self._Model:GetTaskFreeRefreshTimes(taskGroupId)
end

---获得卡槽位空位
function XTheatre6Control:GetEmptySlotPositions(slotType)
    return self._Model.Skill:GetEmptySlotPositions(nil, slotType)
end

---根据技能ID获取技能安装的槽位类型
function XTheatre6Control:GetCanExchangePos(skillId,slotType)
    local skillModel = self._Model.Skill
    local skillKey = skillModel:GetSkillKey(skillId)
    local skillLevel = skillModel:GetSkillLevel(skillId)
    local slotGroup = self._Model.Skill:GetCharacterSkills(slotType)
    if not slotGroup then
        return nil
    end
    for _, dstSkillData in pairs(slotGroup) do
        if dstSkillData and XTool.IsNumberValid(dstSkillData.SkillId) then
            if skillModel:GetSkillKey(dstSkillData.SkillId) == skillKey
                and skillLevel >= skillModel:GetSkillLevel(dstSkillData.SkillId) then
                return dstSkillData.Position
            end
        end
    end
    return nil
end

---根据技能ID获取可安装卡槽槽位的空位
function XTheatre6Control:GetEmptyPositionsByCfg(skillId)
    return self._Model.Skill:GetEmptyPositionsByCfg(skillId)
end

---根据技能ID获取可安装卡槽槽位类型
---@param skillId number 技能ID
---@return number[] 可安装卡槽槽位类型
function XTheatre6Control:GetSkillInstallSlots(skillId)
    return self._Model.Skill:GetSkillInstallSlots(skillId)
end

---技能移动或交换请求
---@param skillId number 技能ID
---@param dstSlotType number 目标槽位类型
---@param dstPosition number 目标位置
---@param cb function 回调函数
function XTheatre6Control:SkillMoveOrSwapRequest(skillId, dstSlotType, dstPosition, cb)
    local SlotType = XEnumConst.Theatre6.SlotType
    local skillModel = self._Model.Skill
    local slotSkillGroup = skillModel:GetCharacterSkills(dstSlotType)
    local dstSkillData = slotSkillGroup and slotSkillGroup[dstPosition]
    if dstSkillData and dstSkillData.SkillId == skillId then
        if cb then
            cb()
        end
        return
    end
    --槽位类型校验:1.拖入技能能否装到目标槽 2.替换时被挤走的技能能否装回源装备槽
    if dstSlotType ~= SlotType.Bag then
        local srcSlots = self:GetSkillInstallSlots(skillId)
        if not srcSlots or not table.contains(srcSlots, dstSlotType) then
            XUiManager.TipText("Theatre6SkillMoveError")
            if cb then cb() end
            return
        end
    end
    if dstSkillData and XTool.IsNumberValid(dstSkillData.SkillId) and dstSkillData.SkillId ~= skillId then
        local srcSlotType = skillModel:GetSkillEquippedPosition(skillId)
        if srcSlotType and srcSlotType ~= SlotType.Bag then
            local dstSlots = self:GetSkillInstallSlots(dstSkillData.SkillId)
            if not dstSlots or not table.contains(dstSlots, srcSlotType) then
                XUiManager.TipText("Theatre6SkillMoveError")
                if cb then cb() end
                return
            end
        end
    end
    --装入装备槽时校验:1.目标位置低不能换高;2.其他装备位不允许出现同名技能
    if dstSlotType ~= SlotType.Bag then
        local skillKey = skillModel:GetSkillKey(skillId)
        local skillLevel = skillModel:GetSkillLevel(skillId)
        --1.目标位置:同 key 但等级更低,不允许覆盖
        if dstSkillData and XTool.IsNumberValid(dstSkillData.SkillId)
            and skillModel:GetSkillKey(dstSkillData.SkillId) == skillKey
            and skillLevel < skillModel:GetSkillLevel(dstSkillData.SkillId) then
            XUiManager.TipMsg(XUiHelper.GetText("Theatre6SkillChangeError1"))
            if cb then
                cb()
            end
            return
        end
        --2.其他装备位:任意同 key 都不允许并存
        for _, equipSlotType in pairs(SlotType) do
            if equipSlotType ~= SlotType.Bag then
                local equipGroup = skillModel:GetCharacterSkills(equipSlotType)
                if equipGroup then
                    for pos, equipData in pairs(equipGroup) do
                        if equipData and XTool.IsNumberValid(equipData.SkillId)
                            and not (equipSlotType == dstSlotType and pos == dstPosition)
                            and equipData.SkillId ~= skillId
                            and skillModel:GetSkillKey(equipData.SkillId) == skillKey then
                            XUiManager.TipMsg(XUiHelper.GetText("Theatre6SkillChangeError2"))
                            if cb then
                                cb()
                            end
                            return
                        end
                    end
                end
            end
        end
    end
    local req = {
        SrcSkillId = skillId,
        DstSlotType = dstSlotType,
        DstPosition = dstPosition
    }
    XLuaUiManager.SetMask(true, MoveSkillMaskKey)
    XNetwork.Call(ReqMethodName.SkillMoveOrSwap, req, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
        end
        if response.SkillUpdates then
            for index, SkillUpdate in pairs(response.SkillUpdates) do
                self._Model.Skill:UpdateSkills(SkillUpdate, true)
            end
        end
            if cb then
                cb()
        end
    end)
    XScheduleManager.ScheduleOnce(function()
        if XLuaUiManager.IsMaskShow(MoveSkillMaskKey) then
            XLuaUiManager.SetMask(false, MoveSkillMaskKey)
        end
    end, 200)
end

---溢出技能出售请求
function XTheatre6Control:OverQueueSellRequest(cb)
    XNetwork.Call(ReqMethodName.OverQueueSell, nil, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        self._Model.Skill:ClearSkillOverQueue()
        if cb then
            cb()
        end
    end)
end

function XTheatre6Control:BuffLevelUpSkillRequest(buffId,skillId, cb)
    local req = {
        BuffId = buffId,
        SkillId = skillId
    }
    XNetwork.Call(ReqMethodName.BuffLevelUpSkill, req, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        if XTool.IsNumberValid(skillId) and skillId ~= 0 then
            for i,skillUpdateData in ipairs(response.SkillUpdates) do
            local targetSkillId = nil
                
            if skillUpdateData and skillUpdateData.ReplaceSkills then 
                for index, skillData in pairs(skillUpdateData.ReplaceSkills) do
                    local replaceCfg = self:GetSkillCfgById(skillData.SkillId)
                    local skillCfg = self:GetSkillCfgById(skillId)
                    if replaceCfg and skillCfg
                        and replaceCfg.SkillKey == skillCfg.SkillKey and replaceCfg.Level > skillCfg.Level then
                        targetSkillId = skillData.SkillId
                        break
                    end
                end
            end
            if targetSkillId then
                XLuaUiManager.Open("UiTheatre6GainTips", 1, targetSkillId, true)
            end
        end 
        
        end
        if response.SkillUpdates then
            self._Model.Skill:UpdateSkillListWithOverQueue(response.SkillUpdates)
        end
        if cb then
            cb()
        end
 
    end)
end

---对应Theatre6SkillUpdate数据结构
function XTheatre6Control:OnNotifySkillUpdate(skillUpdateData)
    self._Model.Skill:UpdateSkillData(skillUpdateData.ReplaceSkills)
end

function XTheatre6Control:IsSkillBagFull()
    return self._Model.Skill:IsSkillBagFull()
end

---各界面拦截入口:当前玩法溢出队列未处理时重新弹出 SellSkill 弹窗并返回 true
function XTheatre6Control:CheckForceSellSkillBlock()
    if not self._Model.Skill:IsForceSellSkillBlock() then
        return false
    end
    if self:IsCurModeSettle() then
        return false
    end
    self._Model.Skill:OpenSellSkillPanel(self._Model.Skill:GetForceSellSkillOverQueue())
    return true
end

--#region 技能相关
function XTheatre6Control:GetCharacterSkillBagIds()
    return self._Model.Skill:GetCharacterSkillBagIds()
end

function XTheatre6Control:GetActiveSkillIds()
    return self._Model.Skill:GetCharacterDressSkillIds(nil, XEnumConst.Theatre6.SlotType.Active)
end

function XTheatre6Control:GetInsertSkillIds()
    return self._Model.Skill:GetCharacterDressSkillIds(nil, XEnumConst.Theatre6.SlotType.Insert)
end

function XTheatre6Control:GetSpecialSkillIds()
    return self._Model.Skill:GetCharacterDressSkillIds(nil, XEnumConst.Theatre6.SlotType.Special)
end

function XTheatre6Control:GetCharacterDressSkillIds(slotType)
    return self._Model.Skill:GetCharacterDressSkillIds(nil, slotType)
end

function XTheatre6Control:GetSkillData(slotType, skillId)
    return self._Model.Skill:GetSkillData(slotType, skillId)
end

function XTheatre6Control:CanUpGradeSkill(skillId, inShop)
    return self._Model.Skill:CanUpGradeSkill(skillId, inShop)
end

function XTheatre6Control:ExistsHighLevelSkill()
    local SlotType = XEnumConst.Theatre6.SlotType
    for _, slotType in pairs(SlotType) do
        if slotType ~= SlotType.Bag then
            local skillIds = self._Model.Skill:GetCharacterDressSkillIds(nil, slotType)
            for _, skillId in pairs(skillIds) do
                if XTool.IsNumberValid(skillId) then
                    if self._Model.Skill:ExistsHighLevelSkill(skillId) then
                        return true
                    end
                else
                    XLog.Error(string.format("角色技能槽位存在无效技能，槽位类型：%d，技能ID：%s", slotType, tostring(skillId))) --异常情况排查
                end
            end
        end
    end
    return false
end

function XTheatre6Control:CheckSkillCanEquipSkill(skillId, slotType)
    local skillModel = self._Model.Skill
    local pos = self:GetCanExchangePos(skillId,slotType)
    if pos ~= nil then
        return true,pos
    end
    
    return false
end

--背包是否存在可装备到任一装备槽位的技能
function XTheatre6Control:CheckCanEquipSkill()
    local SlotType = XEnumConst.Theatre6.SlotType
    local skillModel = self._Model.Skill
    local bagSkills = skillModel:GetCharacterSkills(SlotType.Bag)
    if not bagSkills then
        return false
    end
    for _, skillData in pairs(bagSkills) do
        local bagSkillId = skillData.SkillId
        if XTool.IsNumberValid(bagSkillId) then
            local installSlots = skillModel:GetSkillInstallSlots(bagSkillId)
            if installSlots then
                for _, installSlot in pairs(installSlots) do
                    if self:CheckSkillCanEquipSkill(bagSkillId, installSlot) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

---获取指定槽位和位置的初始技能
---@param slotType number
---@param pos number
---@return number|nil
function XTheatre6Control:GetBaseSkillForSlot(slotType, pos, characterId)
    return self._Model.Skill:GetBaseSkillForSlot(slotType, pos, characterId)
end

function XTheatre6Control:GetNextLevelSkillId(skillId)
    return self._Model.Skill:GetNextLevelSkillId(skillId)
end

function XTheatre6Control:GetDefaultSkill(slotType)
    return self._Model.Skill:GetCharacterSkills(slotType)[1]
end

function XTheatre6Control:BagHasNewSkill()
    for _, skillId in pairs(self:GetCharacterSkillBagIds()) do
        if self._Model.Skill:HasNewSkill(skillId) then
            return true
        end
    end
    return false
end

function XTheatre6Control:GetSkillTypeBgConfigName(skillId)
    local slotTypes = self:GetSkillInstallSlots(skillId)
    local skillConfig = self:GetSkillCfgById(skillId)
    if not slotTypes or #slotTypes < 1 then
        return self:GetQualityIcon(skillConfig.Quality)
    end
    return self:GetClientConfigValue(SkillTypeBgConfigName[slotTypes[1]], skillConfig.Quality)
end

function XTheatre6Control:SetNewSkillViewed(skillId)
    self._Model.Skill:SetNewSkillViewed(skillId)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_SKILL_NOT_NEW)
end

---清空当前背包的新技能标记并刷新红点
function XTheatre6Control:ClearBagNewSkillViewed()
    if self._Model.Skill:ClearBagNewSkillFlags() then
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_SKILL_NOT_NEW)
    end
end

--region 遗物

function XTheatre6Control:IsOwnRelic(relicId)
    local modelData = self:GetCurPlayModeData()
    return modelData.AttrPacks[relicId] ~= nil
end

--endregion

---@param mode number 玩法模式
---@param roleConfigs XTableTheatre6Character[]
function XTheatre6Control:GetModeSelectRoleIndex(mode, roleConfigs)
    if not roleConfigs then
        roleConfigs = {}
        for k, v in pairs(self:GetCharacterConfigs()) do
            if XTool.IsNumberValid(v.Priority) then
                table.insert(roleConfigs, v)
            end
        end
        table.sort(roleConfigs, function(a, b)
            return a.Priority > b.Priority
        end)
    end

    local historyId = self:GetSelectRoleId(mode)
    local hasHistory = XTool.IsNumberValid(historyId)

    for i, config in ipairs(roleConfigs) do
        if hasHistory then
            if config.Id == historyId then
                return i
            end
        elseif not XTool.IsNumberValid(config.ConditionId) or XConditionManager.CheckCondition(config.ConditionId) then
            return i
        end
    end
    return 1
end

function XTheatre6Control:GetNewCharacterShowTimeId()
    local values = self._Model:GetClientConfigValues("NewCharacterTagShowTime")
    local timeId = 0

    if #values ~= 0 then
        timeId = tonumber(values[#values])
    end

    return timeId
end

function XTheatre6Control:GetNewCharacterShowTagMap()
    local result = {}
    local timeId = self:GetNewCharacterShowTimeId()
    local tags = self._Model:GetNewCharacterShowTags()

    if XFunctionManager.CheckInTimeByTimeId(timeId, false) then
        local values = self._Model:GetClientConfigValues("NewCharacterTagShowId")

        for _, value in pairs(values) do
            local showId = tonumber(value)

            if XTool.IsNumberValid(showId) and (not tags or not tags[showId]) then
                result[showId] = true
            end
        end
    end

    return result
end

function XTheatre6Control:CheckHasNewCharacter()
    return not XTool.IsTableEmpty(self:GetNewCharacterShowTagMap())
end

function XTheatre6Control:AddNewCharacterShowTag(id)
    self._Model:AddNewCharacterShowTag(id)
end

function XTheatre6Control:SaveBuffChooseIndex(mode, characterId, index)
    self._Model:SaveBuffChooseIndex(mode, characterId, index)
end

function XTheatre6Control:GetBuffChooseIndex(mode, characterId)
    return self._Model:GetBuffChooseIndex(mode, characterId)
end

function XTheatre6Control:SaveDifficultyChooseIndex(characterId, index)
    self._Model:SaveDifficultyChooseIndex(characterId, index)
end

function XTheatre6Control:GetDifficultyChooseIndex(characterId)
    return self._Model:GetDifficultyChooseIndex(characterId)
end

--#endregion
return XTheatre6Control

---@class XTheatre6BuffData
---@field Uid number 唯一Id
---@field StackCount number 堆叠数量（为0时不显示）
---@field RemainCount number 剩余生效次数（堆叠时以最小为准）
---@field isLimitTime boolean 是否限时（仅排序用）
---@field TriggerCount number 触发次数
