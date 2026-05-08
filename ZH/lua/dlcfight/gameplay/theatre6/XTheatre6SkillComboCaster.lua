local function GetListCount(list)
    if not list then
        return 0
    end

    if list.Count then
        return list.Count
    end

    if list.Length then
        return list.Length
    end

    return #list
end

---@class XTheatre6SkillComboCaster
local XTheatre6SkillComboCaster = {}
XTheatre6SkillComboCaster.__index = XTheatre6SkillComboCaster

local SkillGetterByType = {
    [ETheatre6SkillType.Main] = function(proxy, npcUUID)
        return proxy:Theatre6GetMainSkill(npcUUID)
    end,
    [ETheatre6SkillType.Wrestle] = function(proxy, npcUUID)
        return proxy:Theatre6GetWrestleDeriveSkill(npcUUID)
    end,
    [ETheatre6SkillType.Dodge] = function(proxy, npcUUID)
        return proxy:Theatre6GetDodgeDeriveSkill(npcUUID)
    end,
}

local DebugSkillTypeName = {
    [ETheatre6SkillType.Main] = "[主动技能]",
    [ETheatre6SkillType.Wrestle] = "[拼刀技能]",
    [ETheatre6SkillType.Dodge] = "[超算技能]",
    [ETheatre6SkillType.Insert] = "[插入技能]",
}

--region 初始化
function XTheatre6SkillComboCaster.New(ownerOrProxy, npcUUID, targetNpcUUID)
    ---@class XTheatre6SkillComboCaster
    local obj = setmetatable({}, XTheatre6SkillComboCaster)
    obj._proxy = ownerOrProxy and ownerOrProxy._proxy or ownerOrProxy ---@type XDlcCSharpFuncs
    obj._npcUUID = npcUUID or 0
    obj._targetNpcUUID = targetNpcUUID or 0
    obj:Reset()
    return obj
end

function XTheatre6SkillComboCaster:Reset()
    self._lastSkillType = nil
    self._nextActionIndex = 0
    self._continueActionIndex = nil
    self._mainSkillIndex = 0
    self._activeActionList = nil
    self._activeSkillId = nil
end

--endregion


--region 获取技能配置

---获取主动技能配置
---@return XTable.XTableTheatre6Skill|nil skillTemplate #下一次要释放的主动技能的配置
---@return integer skillCount #当前持有主动技能的数量
function XTheatre6SkillComboCaster:GetMainSkillConfig()
    if not self._proxy or self._npcUUID == 0 then
        return nil, 0
    end

    local skillList = self._proxy:Theatre6GetMainSkill(self._npcUUID)
    local skillCount = GetListCount(skillList)
    if skillCount <= 0 then
        return nil, 0
    end

    if self._mainSkillIndex >= skillCount then
        self._mainSkillIndex = 0
    end

    local skillId = skillList and skillList[self._mainSkillIndex]
    if not skillId or skillId == 0 then
        return nil, skillCount
    end

    local skillConfig = self._proxy:Theatre6GetSkillConfig(skillId)
    return skillConfig, skillCount
end

---获取拼刀、超算技能配置
---@return XTable.XTableTheatre6Skill|nil skillTemplate #指定类型对应的追击技能的配置
function XTheatre6SkillComboCaster:GetSingleSkillConfig(skillType)
    local getter = SkillGetterByType[skillType]
    if not getter or not self._proxy or self._npcUUID == 0 then
        return nil
    end

    local skillId = getter(self._proxy, self._npcUUID)
    if not skillId or skillId == 0 then
        return nil
    end

    return self._proxy:Theatre6GetSkillConfig(skillId)
end

---获取插入式技能配置
---@return XTable.XTableTheatre6Skill|nil skillTemplate #指定id对应的插入式技能的配置
function XTheatre6SkillComboCaster:GetInsertSkillConfig(skillId)
    if not self._proxy or not skillId or skillId == 0 then
        return nil
    end

    return self._proxy:Theatre6GetSkillConfig(skillId)
end

---获取技能配置
---@param skillType ETheatre6SkillType
---@param skillId integer 目标技能的ID.此传参只对插入式技能生效.
---@return XTable.XTableTheatre6Skill|nil skillTemplate #目标技能的配置. 如果获取的是主动技能,则返回下一次要释放的主动技能的配置
---@return integer skillCount #当前持有主动技能的数量.只在获取主动技能配置时有值
function XTheatre6SkillComboCaster:GetSkillConfig(skillType, skillId)
    if skillType == ETheatre6SkillType.Main then
        return self:GetMainSkillConfig()
    end

    if skillType == ETheatre6SkillType.Insert then
        return self:GetInsertSkillConfig(skillId), 0
    end

    return self:GetSingleSkillConfig(skillType), 0
end

--endregion


--region 释放技能或动作

---启动一个技能(从第一个动作开始)
---@param skillType ETheatre6SkillType?
---@param skillId integer? 目标技能的ID.此传参只对插入式技能生效.
---@return integer? skillId 成功释放时返回技能id
---@return integer? actionId 成功释放时返回动作id, 即技能中的第一个动作
function XTheatre6SkillComboCaster:Cast(skillType, skillId)
    if not self._proxy or self._npcUUID == 0 or self._targetNpcUUID == 0 then
        return
    end

    local skillConfig, skillCount = self:GetSkillConfig(skillType, skillId)
    local skillId = skillConfig and skillConfig.Id
    local actionList = skillConfig and skillConfig.ComboList
    local actionCount = GetListCount(actionList)
    if actionCount <= 0 then return end

    --这里不对, 这里会导致每次释放技能的时候都从上次断掉的action继续
    -- local actionIndex = 0
    -- if self._lastSkillType == skillType then
    --     actionIndex = self._nextActionIndex or 0
    -- end


    local actionId = actionList and actionList[0]
    if not actionId or actionId == 0 then return end

    --体力值的检查可以在外面进行, 这里的检查是冗余的
    -- if skillConfig.CostTL > 0 and self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.Stamina) <= 0 then
    --     return false
    -- end

    -- XLog.Error("角色:" .. self._npcUUID ..
    --     ", 释放" .. DebugSkillTypeName[skillType] .. ": " .. skillId .. " ，消耗体力" .. skillConfig.CostTL)

    if skillType == ETheatre6SkillType.Main and skillCount > 0 then
        self._mainSkillIndex = (self._mainSkillIndex + 1) % skillCount
    end

    --ToDo:
    --关于数值和UI的部分迁移到角色基类里, 方便后续调整
    --另外这里的UI表现应该还涉及到守方的技能播报清理,以及连击数等内容
    local previewMainSkillId = self:GetPreviewMainSkillId()
    self._proxy:Theatre6UpdateSkillUI(self._npcUUID, skillConfig.Id, previewMainSkillId)
    self._proxy:Theatre6AddSkillCastCount(self._npcUUID, skillConfig.Id);
    self._proxy:ChangeNpcGameplayEnergy(self._npcUUID, ETheatre6AttribType.Stamina, -skillConfig.CostTL)
    self._proxy:CastSkillActionToNpcNotCheck(self._npcUUID, actionId, self._targetNpcUUID)
    self._lastSkillType = skillType
    self._activeActionList = actionList
    self._activeSkillId = skillId

    if actionCount < 2 then
        self._nextActionIndex = 0
        self._continueActionIndex = nil
    else
        self._nextActionIndex = 1
        self._continueActionIndex = 1
    end

    return skillId, actionId
end

---启动拼刀成功技能
---@return integer? actionId 成功释放时返回动作id, 即技能中的第一个动作
function XTheatre6SkillComboCaster:CastWrestleSucSkill()
    return self:Cast(ETheatre6SkillType.Wrestle)
end

---启动超算成功技能
---@return integer? actionId 成功释放时返回动作id, 即技能中的第一个动作
function XTheatre6SkillComboCaster:CastDodgeSucSkill()
    return self:Cast(ETheatre6SkillType.Dodge)
end

---启动队列中的下一个主动技能(从第一个动作开始)
---@return integer? skillId 成功释放时返回技能id
---@return integer? actionId 成功释放时返回动作id, 即技能中的第一个动作
function XTheatre6SkillComboCaster:CastMain()
    return self:Cast(ETheatre6SkillType.Main)
end

---启动指定的插入式技能(从第一个动作开始)
---@return integer? skillId 成功释放时返回技能id
---@return integer? actionId 成功释放时返回动作id, 即技能中的第一个动作
function XTheatre6SkillComboCaster:CastInsert(skillId)
    return self:Cast(ETheatre6SkillType.Insert, skillId)
end

--- 继续释放连招 当一个技能开始之后，每次调用会释放ComboList剩下的连招
function XTheatre6SkillComboCaster:Continue()
    if not self._proxy or self._npcUUID == 0 or self._targetNpcUUID == 0 then
        return
    end

    if not self._lastSkillType then return end

    local actionList = self._activeActionList
    local actionCount = GetListCount(actionList)
    local actionIndex = self._continueActionIndex
    if actionCount <= 0 or actionIndex == nil or actionIndex >= actionCount then
        self._nextActionIndex = 0
        self._continueActionIndex = nil
        self._activeActionList = nil
        self._activeSkillId = nil
        return
    end

    local actionId = actionList and actionList[actionIndex]
    if not actionId or actionId == 0 then
        self._nextActionIndex = 0
        self._continueActionIndex = nil
        self._activeActionList = nil
        self._activeSkillId = nil
        return
    end

    self._proxy:CastActionToTarget(self._npcUUID, actionId, self._targetNpcUUID)

    if actionIndex + 1 >= actionCount then
        local skillId = self._activeSkillId
        self._nextActionIndex = 0
        self._continueActionIndex = nil
        self._activeActionList = nil
        self._activeSkillId = nil
        return skillId, actionId
    end

    self._nextActionIndex = actionIndex + 1
    self._continueActionIndex = actionIndex + 1
    return self._activeSkillId, actionId
end

--endregion

function XTheatre6SkillComboCaster:GetActionTime(actionId)
    local actionConfig = self._proxy:GetSkillActionTemplate(actionId)
    if not actionConfig then
        XLog.Error("XTheatre6SkillComboCaster:GetActionTime Error: UnKnown ActionId " .. tostring(actionId))
        return 0
    end
    return actionConfig.BeforeTime + actionConfig.CastTime + actionConfig.AfterTime
end

function XTheatre6SkillComboCaster:GetSkillTime(skillId)
    local skillConfig = self._proxy:Theatre6GetSkillConfig(skillId)
    if not skillConfig then
        XLog.Error("XTheatre6SkillComboCaster:GetSkillTime Error: UnKnown SkillId " .. tostring(skillId))
        return 0
    end
    local actionList = skillConfig.ComboList
    local time = 0
    for i = 0, GetListCount(actionList) - 1 do
        time = time + self:GetActionTime(actionList[i])
    end
    -- for _, actionId in ipairs(actionList) do
    --     time = time + self:GetActionTime(actionId)
    -- end
    return time
end

function XTheatre6SkillComboCaster:GetPreviewMainSkillId()
    if not self._proxy or self._npcUUID == 0 then
        return 0
    end

    local skillList = self._proxy:Theatre6GetMainSkill(self._npcUUID)
    local mainSkillCount = GetListCount(skillList)
    if mainSkillCount <= 0 then
        return 0
    end

    local simulatedMainSkillIndex = self._mainSkillIndex
    if simulatedMainSkillIndex >= mainSkillCount then
        simulatedMainSkillIndex = 0
    end

    local previewSkillId = skillList and skillList[simulatedMainSkillIndex]
    if not previewSkillId or previewSkillId == 0 then
        return 0
    end

    return previewSkillId
end

--- 检查是否可以继续释放连招 Combo
function XTheatre6SkillComboCaster:CanContinue()
    return self._lastSkillType ~= nil and self._continueActionIndex ~= nil and self._activeActionList ~= nil
end

return XTheatre6SkillComboCaster


-- --- 绑定npc跟目标
-- function XTheatre6SkillComboCaster:Bind(npcUUID, targetNpcUUID)
--     self._npcUUID = npcUUID or 0
--     self._targetNpcUUID = targetNpcUUID or 0
-- end



-- --- 获取上次释放的技能类型
-- function XTheatre6SkillComboCaster:GetLastSkillType()
--     return self._lastSkillType
-- end
