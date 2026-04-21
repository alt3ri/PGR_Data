local pairs = pairs
local type = type

local table = table
local tableInsert = table.insert

XAttribManager = XAttribManager or {}

-- 属性id获取接口
local AddNumericIdInterfaces = {}
local AddPromotedIdInterfaces = {}
local AddGrowRateIdInterfaces = {}

local FPS = CS.XFightConfig.FPS
local FPS_FIX = fix(FPS)
local FPS_RECIPROCAL_FIX = CS.XFightConfig.FpsReciprocal
local RADIAN_PER_ANGLE_FIX = fix.deg2rad

local AttribCount = XNpcAttribType.End
local RunSpeedIndex = XNpcAttribType.RunSpeed
local WalkSpeedIndex = XNpcAttribType.WalkSpeed
local SquatSpeedIndex = XNpcAttribType.SquatSpeed
local SprintSpeedIndex = XNpcAttribType.SprintSpeed
local TurnRoundSpeedIndex = XNpcAttribType.TurnRoundSpeed
local BallIntervalIndex = XNpcAttribType.BallInterval
local DodgeEnergyAutoRecoveryIndex = XNpcAttribType.DodgeEnergyAutoRecovery

local DEFAULT_VALUE = 0
local AttribTemplates = {}
local AttribPromotedTemplates = {}
local AttribGrowRateTemplates = {}
local AttribReviseTemplates = {}
local AttribGroupTemplates = {}
local AttribAbilityTemplate = {}

--属性名字配置表
local AttribDescTemplates = {}
-- local NpcTemplates = {}
--属性值table对象池
local AttriValueArrayPool = {}

---属性id接口注册
---@param inter function
function XAttribManager.RegisterGrowRateIdInterface(inter)
    tableInsert(AddGrowRateIdInterfaces, inter)
end

---@param inter function
function XAttribManager.RegisterNumericIdInterface(inter)
    tableInsert(AddNumericIdInterfaces, inter)
end

---@param inter function
function XAttribManager.RegisterPromotedIdInterface(inter)
    tableInsert(AddPromotedIdInterfaces, inter)
end

---属性计算
local function CreateAttribValueArray()
    if not XTool.IsTableEmpty(AttriValueArrayPool) then
       return table.remove(AttriValueArrayPool)
    end
    return {}  
end

--回收属性table
local function RecycleAttribArray(attriArray)
   for k, _ in pairs(attriArray) do 
        attriArray[k] = 0  --这里占个坑，防止自动缩容
   end
    tableInsert(AttriValueArrayPool, attriArray)
end

local function ClearAttribArrayPool()
    AttriValueArrayPool = {}
end 

---将配置转换成fix.RawValue
---@param template table 属性配置
---@return long[] fix.RawValue
local function GetAttribValueArray(template)
    local attribValues = CreateAttribValueArray()
    for k, v in pairs(XNpcAttribType) do
        if template[k] and template[k] ~= DEFAULT_VALUE then
            attribValues[v] = template[k].RawValue
        end
    end
    return attribValues
end

--全部计算完后再转成fix
local function RawValueToFixList(rawValueList)
    if not rawValueList then
        return
    end
    local fixAttribs = {}
    for k, v in pairs(rawValueList) do
        fixAttribs[k] = fix.FromRaw(v)
    end
    RecycleAttribArray(rawValueList)
    return fixAttribs
end 

---加载属性配置
local function LoadAttribConfig()
    AttribGroupTemplates = XAttribConfigs.GetAttribGroupTemplates()
    AttribReviseTemplates = XAttribConfigs.GetAttribReviseTemplates()
    -- NpcTemplates = XAttribConfigs.GetNpcTemplates()
    AttribDescTemplates = XAttribConfigs.GetAttribDescTemplates()
    AttribAbilityTemplate = XAttribConfigs.GetAttribAbilityTemplate()

    AttribTemplates = XAttribConfigs.GetAttribTemplates()--InitAttribTemplates(XAttribConfigs.GetAttribTemplates())
    AttribPromotedTemplates = XAttribConfigs.GetAttribPromotedTemplates()
    AttribGrowRateTemplates = XAttribConfigs.GetAttribGrowRateTemplates()
end

local function GetAttribValueTemplate(attribId)
    local attribs = AttribTemplates[attribId]
    if not attribs then
        XLog.Error("Share/Attrib/Attrib 未找到配置，Id:" .. attribId)
        return XCode.AttribManagerGetAttribTemplateNotFound, nil
    end

    local attribValues = GetAttribValueArray(attribs)

    return XCode.Success, attribValues
end

local function GetAttribValuePromotedTemplate(attribId)
    local attribs = AttribPromotedTemplates[attribId]
    if not attribs then
        XLog.Error("XAttribManager GetAttribPromotedTemplate Error: can not found attrib template, Id is " .. attribId)
        return XCode.AttribManagerGetPromotedAttribTemplateNotFound, nil
    end

    local attribValues = GetAttribValueArray(attribs)

    return XCode.Success, attribValues
end

local function GetAttribValueGrowRateTemplate(attribId)
    local attribs = AttribGrowRateTemplates[attribId]
    if not attribs then
        XLog.Error("XAttribManager GetAttribGrowRateTemplate Error: can not found attrib template, Id is " .. attribId)
        return XCode.AttribManagerGetGrowRateAttribTemplateNotFound, nil
    end

    local attribValues = GetAttribValueArray(attribs)

    return XCode.Success, attribValues
end

local function GetAttribGroupTemplate(id)
    local attribGroup = AttribGroupTemplates[id]
    if not attribGroup then
        XLog.Error("XAttribManager GetAttribGroupTemplate Error: can not found attrib group template, Id is " .. id)
        return XCode.AttribGroupNotFound, nil
    end

    return XCode.Success, attribGroup
end

---属性计算
---属性加法
---@param attribs1 fix[] 原属性数组
---@param attribs2 fix[] 增加属性数组
local function DoAddAttribs(attribs1, attribs2)
    for k, v in pairs(attribs2) do
        if attribs1[k] then
            attribs1[k] = attribs1[k] + attribs2[k]
        else
            attribs1[k] = attribs2[k]
        end
    end
end


---属性计算
---属性加法
---@param attribsValue1 long[] 原属性数组
---@param attribsValue2 long[] 增加属性数组
local function DoAddAttribValues(attribsValue1, attribsValue2)
     for k, v in pairs(attribsValue2) do
        if attribsValue1[k] then
            attribsValue1[k] = AddFixEx(attribsValue1[k] , attribsValue2[k]) 
        else
            attribsValue1[k] = attribsValue2[k]
        end
    end
    RecycleAttribArray(attribsValue2)
end

---属性成长(原属性 + 成长属性 * 培养等级)
---@param attribsValue1 long[] 原属性数组
---@param attribsValue2 long[] 成长属性数组
---@param trainedLevel number 培养等级
local function DoPromotedAttribValues(attribsValue1, attribsValue2, trainedLevel)
   if trainedLevel <= 0 then
        return
    end
    trainedLevel = fix(trainedLevel)
    for k, v in pairs(attribsValue2) do
        if attribsValue1[k] then
            attribsValue1[k] = AddFixEx(attribsValue1[k], MultFixEx(attribsValue2[k] , trainedLevel.RawValue))
        else
            attribsValue1[k] = MultFixEx(attribsValue2[k] , trainedLevel.RawValue)
        end
    end
    RecycleAttribArray(attribsValue2)
end

---属性加成(原属性 + 原属性 * 加成属性)
---@param attribsValue1 long[] 原属性数组
---@param attribsValue2 long[] 加成属性数组
local function DoGrowRateAttribValues(attribsValue1, attribsValue2)
    for k, v in pairs(attribsValue2) do
        if attribsValue1[k] then
            attribsValue1[k] = AddFixEx(attribsValue1[k], MultFixEx(attribsValue1[k] , attribsValue2[k]))
        else
            attribsValue1[k] = MultFixEx(attribsValue1[k] , attribsValue2[k])
        end
    end
    RecycleAttribArray(attribsValue2)
end

---属性修正(原属性 * (1 + 修正系数))
---@param attribValue long 原属性
---@param factorValue long 修正系数
---@return long 修正后属性
local function DoReviseAttrib(attribValue, factorValue)
    if not attribValue then
        attribValue = DEFAULT_VALUE
    end
    return MultFixEx(attribValue, AddFixEx(fix.one.RawValue, factorValue))
end

---获取总加成属性
---@param attribIds table 属性加成id列表
---@return XCode,long[] 状态码和属性数组
local function GetTotalGrowRateAttribValues(attribIds)
    local attribValues = CreateAttribValueArray()

    for _, id in pairs(attribIds) do
        local code, readAttribValues = GetAttribValueGrowRateTemplate(id)
        if code ~= XCode.Success then
            return code, nil
        end

        DoAddAttribValues(attribValues, readAttribValues)
    end
    return XCode.Success, attribValues
end

---获取总属性数值叠加
---@param attribIds table 叠加属性id列表
---@return XCode,long[] 状态码和属性数组
local function GetTotalNumericAttribValues(attribIds)
    local attribValues = CreateAttribValueArray()

    for _, id in pairs(attribIds) do
        local code, readAttribValues = GetAttribValueTemplate(id)
        if code ~= XCode.Success then
            return code, nil
        end

        DoAddAttribValues(attribValues, readAttribValues)
    end
    return XCode.Success, attribValues
end

---获取总成长属性
---@param attribIds table 成长属性id列表
---@param trainedLevels table 培养等级列表
---@return XCode, long[] 状态码和属性数组
local function GetTotalPromotedAttribValues(attribIds, trainedLevels)
    local attribValues = CreateAttribValueArray()
    if #trainedLevels ~= #attribIds then
        XLog.Error("XAttribManager GetTotalPromotedAttribs Error: trainedLevels array length is not equal to template id array length")
        return XCode.AttribManagerGetTotalPromotedAttribsParamArrayError, nil
    end

    local length = #trainedLevels
    for i = 1, length do
        local level = trainedLevels[i]
        if level <= 0 then
            XLog.Error("XAttribManager GetTotalPromotedAttribs Error: level is smaller than 1, level is " .. level)
            return XCode.AttribManagerGetTotalPromotedAttribsLevelError, nil
        end

        local code, readAttribValues = GetAttribValuePromotedTemplate(attribIds[i])
        if code ~= XCode.Success then
            return code, nil
        end

        DoPromotedAttribValues(attribValues, readAttribValues, level)
    end

    return XCode.Success, attribValues
end

---属性数组修正
---@param attribValues long[] 属性数组
---@param reviseId number 修正id
---@return XCode 状态码
local function ReviseAttribs(attribValues, reviseId)
    local template = AttribReviseTemplates[reviseId]
    if not template then
        XLog.Error("XAttribManager.ReviseAttribs error: can not found template, reviseId is " .. reviseId);
        return XCode.AttribReviseTemplateNotFound
    end

    for i = 1, #template.AttribTypes do
        local attribIndex = template.AttribTypes[i]
        attribValues[attribIndex] = DoReviseAttrib(attribValues[attribIndex], template.Values[i].RawValue);
    end

    return XCode.Success
end

---将属性数组从RawValue转换成XAttrib，减少rawValue转fix传回lua的装箱操作
---@param attribs long[] RawValue数组
---@return XAttrib[] XAttrib属性数组
local function RawValue2XAttrib(attribs)
    local xAttribs = CS.XAttrib.CreateArray(AttribCount)
    for attribIndex = 1, AttribCount - 1 do
        if attribs[attribIndex] then
            CS.XAttrib.CtorToArray(xAttribs, attribIndex, FixToIntEx(attribs[attribIndex]))
        end
    end

    --- 提取常量
    local thousandRaw = fix.thousand.RawValue
    local fpsFixRaw = FPS_FIX.RawValue
    local fpsReciprocalRaw = FPS_RECIPROCAL_FIX.RawValue
    local radianPerAngleRaw = RADIAN_PER_ANGLE_FIX.RawValue

    --- 特殊处理
    CS.XAttrib.SetBaseInArray(xAttribs, RunSpeedIndex,
            FixToIntEx(DivisionFixEx(MultFixEx(attribs[RunSpeedIndex], thousandRaw), fpsFixRaw)))

    CS.XAttrib.SetBaseInArray(xAttribs, WalkSpeedIndex,
            FixToIntEx(DivisionFixEx(MultFixEx(attribs[WalkSpeedIndex], thousandRaw), fpsFixRaw)))

    CS.XAttrib.SetBaseInArray(xAttribs, SquatSpeedIndex,
            FixToIntEx(DivisionFixEx(MultFixEx(attribs[SquatSpeedIndex], thousandRaw), fpsFixRaw)))

    CS.XAttrib.SetBaseInArray(xAttribs, SprintSpeedIndex,
            FixToIntEx(DivisionFixEx(MultFixEx(attribs[SprintSpeedIndex], thousandRaw), fpsFixRaw)))

    CS.XAttrib.SetBaseInArray(xAttribs, TurnRoundSpeedIndex,
            FixToIntEx(MultFixEx(MultFixEx(MultFixEx(attribs[TurnRoundSpeedIndex],
                    fpsReciprocalRaw), radianPerAngleRaw), thousandRaw)))

    CS.XAttrib.SetBaseInArray(xAttribs, BallIntervalIndex,
            FixToIntEx(MultFixEx(attribs[BallIntervalIndex], fpsFixRaw)))

    CS.XAttrib.SetBaseInArray(xAttribs, DodgeEnergyAutoRecoveryIndex,
            FixToIntEx(MultFixEx(attribs[DodgeEnergyAutoRecoveryIndex], fpsReciprocalRaw)))

    return xAttribs
end

---将属性数组从fix转换成XAttrib
---@param attribs fix[] fix属性数组
---@return XAttrib[] XAttrib属性数组
local function Fix2XAttrib(attribs)
    local xAttribs = CS.XAttrib.CreateArray(AttribCount)
    for attribIndex = 1, AttribCount - 1 do
        if attribs[attribIndex] then
            CS.XAttrib.CtorToArray(xAttribs, attribIndex, FixToInt(attribs[attribIndex]))
        end
    end

    --- 特殊处理
    CS.XAttrib.SetBaseInArray(xAttribs, RunSpeedIndex, FixToInt(attribs[RunSpeedIndex] * fix.thousand / FPS_FIX))
    CS.XAttrib.SetBaseInArray(xAttribs, WalkSpeedIndex, FixToInt(attribs[WalkSpeedIndex] * fix.thousand / FPS_FIX))
    CS.XAttrib.SetBaseInArray(xAttribs, SquatSpeedIndex, FixToInt(attribs[SquatSpeedIndex] * fix.thousand / FPS_FIX))
    CS.XAttrib.SetBaseInArray(xAttribs, SprintSpeedIndex, FixToInt(attribs[SprintSpeedIndex] * fix.thousand / FPS_FIX))
    CS.XAttrib.SetBaseInArray(xAttribs, TurnRoundSpeedIndex, FixToInt(attribs[TurnRoundSpeedIndex] * FPS_RECIPROCAL_FIX * RADIAN_PER_ANGLE_FIX * fix.thousand))
    CS.XAttrib.SetBaseInArray(xAttribs, BallIntervalIndex, FixToInt(attribs[BallIntervalIndex] * FPS_FIX))
    CS.XAttrib.SetBaseInArray(xAttribs, DodgeEnergyAutoRecoveryIndex, FixToInt(attribs[DodgeEnergyAutoRecoveryIndex] * FPS_RECIPROCAL_FIX))

    return xAttribs
end

---获取npc基础属性
---@param npcTemplate table npc配置
---@param level number 等级
---@return XCode,long[] 状态码和属性数组
local function GetNpcBaseAttribValues(npcTemplate, level)
    local code, baseAttribValues = GetAttribValueTemplate(npcTemplate.AttribId)
    if code ~= XCode.Success then
        return code, nil
    end

    local attribValues = CreateAttribValueArray()
    DoAddAttribValues(attribValues, baseAttribValues)

    --- 出生等级为1，培养等级=等级 - 1
    local trainedLevel = level - 1

    if npcTemplate.PromotedId and npcTemplate.PromotedId > 0 and trainedLevel > 0 then
        local promotedAttribValues
        code, promotedAttribValues = GetAttribValuePromotedTemplate(npcTemplate.PromotedId)
        if code ~= XCode.Success then
            return code, nil
        end

        DoPromotedAttribValues(attribValues, promotedAttribValues, trainedLevel)
    end

    return XCode.Success, attribValues
end

---获取npc基础属性
---@param npcTemplate table npc配置
---@param level number 等级
---@param reviseId number 修正系数id
---@param isReturnRawValue boolean 是否返回RawValue数据
---@return XCode,fix[] 状态码和属性数组
local function GetNpcBaseAttribsWithReviseId(npcTemplate, level, reviseId, isReturnRawValue)
    local code, attribValues = GetNpcBaseAttribValues(npcTemplate, level)
    if code ~= XCode.Success then
        return code, nil
    end

    if reviseId and reviseId > 0 then
        code = ReviseAttribs(attribValues, reviseId)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    if isReturnRawValue then
        return XCode.Success, attribValues
    else
        local attribs = RawValueToFixList(attribValues)
        return XCode.Success, attribs
    end
end

---获取npc基础属性
---@param npcTemplateId number npc配置id
---@param level number 等级
---@return XCode,long[] 状态码和属性数组
local function GetNpcBaseAttribValuesByNpcId(npcTemplateId, level)
    local npcTemplate = CS.XNpcManager.GetNpcTemplate(npcTemplateId)
    if not npcTemplate then
        XLog.Error("XAttribManager GetNpcBaseAttribsByNpcId Error: can not found npc template, npc Id is " .. npcTemplateId)
        return XCode.AttribManagerGetNpcAttribNpcNotFound, nil
    end

    return GetNpcBaseAttribValues(npcTemplate, level)
end

---获取npc基础属性
---@param npcTemplateId number npc配置id
---@param level number 等级
---@param reviseId number 修正系数id
---@param isReturnRawValue boolean 是否返回RawValue[]数据
---@return XCode,fix[] 状态码和属性数组
local function GetNpcBaseAttribsByNpcIdWithReviseId(npcTemplateId, level, reviseId, isReturnRawValue)
    local npcTemplate = CS.XNpcManager.GetNpcTemplate(npcTemplateId)
    if not npcTemplate then
        XLog.Error("XAttribManager GetNpcBaseAttribsByNpcIdWithReviseId Error: can not found npc template, npc Id is " .. npcTemplateId)
        return XCode.AttribManagerGetNpcAttribNpcNotFound, nil
    end

    return GetNpcBaseAttribsWithReviseId(npcTemplate, level, reviseId, isReturnRawValue)
end

---获取属性加成id列表
---@param npcData userdata npc数据
---@return XCode,table 状态码和属性id列表
local function GetGrowRateAttribIds(npcData)
    local attribIds = {}
    for _, inter in pairs(AddGrowRateIdInterfaces) do
        local code = inter(npcData, attribIds)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    if npcData.AttribGroupList then
        local attribGroupList = npcData.AttribGroupList
        if type(attribGroupList) == "userdata" then
            attribGroupList = XTool.CsList2LuaTable(attribGroupList)
        end

        if #attribGroupList > 0 then
            for _, id in pairs(attribGroupList) do
                local code, group = GetAttribGroupTemplate(id)
                if code ~= XCode.Success then
                    return code, nil
                end

                if group.AttribGrowRateId > 0 then
                    tableInsert(attribIds, group.AttribGrowRateId)
                end
            end
        end
    end

    return XCode.Success, attribIds
end

---获取属性叠加id列表
---@param npcData userdata npc数据
---@return XCode,table 状态码和属性id列表
local function GetNumericAttribIds(npcData)
    local attribIds = {}
    for _, inter in pairs(AddNumericIdInterfaces) do
        local code = inter(npcData, attribIds)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    if npcData.AttribGroupList then
        local attribGroupList = npcData.AttribGroupList
        if type(attribGroupList) == "userdata" then
            attribGroupList = XTool.CsList2LuaTable(attribGroupList)
        end

        if #attribGroupList > 0 then
            for _, id in pairs(attribGroupList) do
                local code, group = GetAttribGroupTemplate(id)
                if code ~= XCode.Success then
                    return code, nil
                end

                if group.AttribId > 0 then
                    tableInsert(attribIds, group.AttribId)
                end
            end
        end
    end

    return XCode.Success, attribIds
end

---获取属性成长id列表和培养等级列表
---@param npcData userdata npc数据
---@return XCode,table,table 状态码和属性id列表、培养等级列表
local function GetPromotedAttribIds(npcData)
    local attribIds = {}
    local levels = {}

    for _, inter in pairs(AddPromotedIdInterfaces) do
        local code = inter(npcData, attribIds, levels)
        if code ~= XCode.Success then
            return code, nil, nil
        end
    end

    return XCode.Success, attribIds, levels
end

---属性加成计算
---@param npcData userdata npc数据
---@param attribValues long[] 属性数组
---@return XCode 状态码
local function DoAddGrowRateAttribValues(npcData, attribValues)
    local code, attribIds = GetGrowRateAttribIds(npcData)
    if code ~= XCode.Success then
        return code
    end

    local growRateAttribValues
    code, growRateAttribValues = GetTotalGrowRateAttribValues(attribIds)
    if code ~= XCode.Success then
        return code
    end

    DoGrowRateAttribValues(attribValues, growRateAttribValues)

    return XCode.Success
end

---属性叠加计算
---@param npcData userdata npc数据
---@param attribValues long[] 属性数组
---@return XCode 状态码
local function DoAddNumericAttribValues(npcData, attribValues)
    local code, attribIds = GetNumericAttribIds(npcData)
    if code ~= XCode.Success then
        return code
    end

    local numericAttribValues
    code, numericAttribValues = GetTotalNumericAttribValues(attribIds)
    if code ~= XCode.Success then
        return code
    end

    DoAddAttribValues(attribValues, numericAttribValues)

    return XCode.Success
end

---属性成长计算
---@param npcData userdata npc数据
---@param attribValues long[] 属性数组
---@return XCode 状态码
local function DoAddPromotedAttribValues(npcData, attribValues)
    local code, attribIds, levels = GetPromotedAttribIds(npcData)
    if code ~= XCode.Success then
        return code
    end

    local promotedAttribValues
    code, promotedAttribValues = GetTotalPromotedAttribValues(attribIds, levels)
    if code ~= XCode.Success then
        return code
    end

    DoAddAttribValues(attribValues, promotedAttribValues)

    return XCode.Success
end

---获取npc属性
---@param npcData userdata npc数据
---@param isReturnRawValue boolean 是否返回RawValue数据
---@return XCode,fix[] 状态码和属性数组
local function GetNpcAttribs(npcData, isReturnRawValue)
    local attribValues
    local characterData = npcData.Character

    local code, npcId = XFightCharacterManager.GetNpcId(characterData)
    if code ~= XCode.Success then
        return code, nil
    end

    code, attribValues = GetNpcBaseAttribValuesByNpcId(npcId, characterData.Level)
    if code ~= XCode.Success then
        return code, nil
    end

    --- 属性加成只针对基础属性，需要第一个计算
    code = DoAddGrowRateAttribValues(npcData, attribValues)
    if code ~= XCode.Success then
        return code, nil
    end

    code = DoAddNumericAttribValues(npcData, attribValues)
    if code ~= XCode.Success then
        return code, nil
    end

    code = DoAddPromotedAttribValues(npcData, attribValues)
    if code ~= XCode.Success then
        return code, nil
    end

    if npcData.AttribReviseId and npcData.AttribReviseId > 0 then
        code = ReviseAttribs(attribValues, npcData.AttribReviseId)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    if isReturnRawValue then
        return XCode.Success, attribValues
    else
        local attribs = RawValueToFixList(attribValues)
        return XCode.Success, attribs
    end
end

local function TryGetNpcBaseAttribs(npcTemplateId, level, reviseId)
    local code, attribs = GetNpcBaseAttribsByNpcIdWithReviseId(npcTemplateId, level, reviseId, true)
    if code ~= XCode.Success then
        XLog.Error("TryGetNpcBaseAttribs error: code is ", code)
        return nil
    end

    return RawValue2XAttrib(attribs)
end

local function TryGetNpcAttribs(npcData)
    local code, attribs = GetNpcAttribs(npcData, true)
    if code ~= XCode.Success then
        XLog.Error("TryGetNpcAttribs error: code is ", code)
        return nil
    end

    return RawValue2XAttrib(attribs)
end

-------------------------------------------------------------------------------------------
XAttribManager.GetAttribAbility = function(attribs)
    if not attribs then
        return
    end

    local ability = fix.zero
    for k, attr in pairs(attribs) do
        local attribKey = XAttribManager.GetAttribKeyByIndex(k)
        local template = AttribAbilityTemplate[attribKey]
        if template and template.Ability > fix.zero then
            ability = ability + attr * template.Ability
        end
    end

    return FixToInt(ability)
end

XAttribManager.GetPartnerAttribAbility = function(attribs)
    if not attribs then
        return
    end

    local ability = fix.zero
    for k, attr in pairs(attribs) do
        local attribKey = XAttribManager.GetAttribKeyByIndex(k)
        local template = AttribAbilityTemplate[attribKey]
        if template and template.PartnerAbility > fix.zero then
            ability = ability + attr * template.PartnerAbility
        end
    end

    return FixToInt(ability)
end

XAttribManager.GetAttribGroupTemplate = GetAttribGroupTemplate

---------------------------------------客户端特有方法---------------------------------------
---获取合并属性数组(fix结构)
---@param numericIds table 数值加成id列表
---@param promotedIds table 等级提升id列表
---@param trainedLevels table 等级列表
---@return fix[] fix数组
function XAttribManager.GetMergeAttribs(numericIds, promotedIds, trainedLevels)
    local attribValues = CreateAttribValueArray()
    if #numericIds > 0 then
        local code, numericAttribValues = GetTotalNumericAttribValues(numericIds)
        if code ~= XCode.Success then
            return
        end

        DoAddAttribValues(attribValues, numericAttribValues)
    end

    if (trainedLevels and promotedIds) and (#promotedIds > 0 and #trainedLevels > 0) then
        local code, promotedAttribValues = GetTotalPromotedAttribValues(promotedIds, trainedLevels)
        if code ~= XCode.Success then
            return
        end

        DoAddAttribValues(attribValues, promotedAttribValues)
    end
    local attribs = RawValueToFixList(attribValues)
    return attribs
end

---获取基础属性数组
---@param attribId number|table 属性id或者属性id列表
---@return fix[] 属性fix数组
function XAttribManager.GetBaseAttribs(attribId)
    local attribIdList = {}

    if type(attribId) ~= "table" then
        tableInsert(attribIdList, attribId)
    else
        attribIdList = attribId
    end

    local code, attribValues = GetTotalNumericAttribValues(attribIdList)
    if code ~= XCode.Success then
        return nil
    end
    local attribs = RawValueToFixList(attribValues)
    return attribs
end

---获取等级提升属性数组
---@param attribId number|table 属性id或者属性id列表
---@param level number|table 等级或者等级列表
---@return fix[] 属性fix数组
function XAttribManager.GetPromotedAttribs(attribId, level)
    local attribIds = {}
    local levels = {}

    if type(attribId) ~= "table" then
        tableInsert(attribIds, attribId)
    else
        attribIds = attribId
    end

    if not level then
        for _ = 1, #attribIds do
            tableInsert(levels, 1)
        end
    elseif type(level) ~= "table" then
        tableInsert(levels, level)
    else
        levels = level
    end

    local code, attribValues = GetTotalPromotedAttribValues(attribIds, levels)
    if code ~= XCode.Success then
        return nil
    end
    local attribs = RawValueToFixList(attribValues)
    return attribs
end

---获取提升比例属性数组
---@param attribId number|table 属性id或者属性id列表
---@return fix[] 属性fix数组
function XAttribManager.GetGrowRateAttribs(attribId)
    local attribIdList = {}

    if type(attribId) ~= "table" then
        tableInsert(attribIdList, attribId)
    else
        attribIdList = attribId
    end

    local code, attribValues = GetTotalGrowRateAttribValues(attribIdList)
    if code ~= XCode.Success then
        return nil
    end
    local attribs = RawValueToFixList(attribValues)
    return attribs
end

function XAttribManager.GetAttribNameByIndex(index)
    local template = AttribDescTemplates[index]
    if not template then
        return
    end
    return template.Name
end

function XAttribManager.GetAttribKeyByIndex(index)
    local template = AttribDescTemplates[index]
    if not template then
        return
    end
    return template.Attrib
end

---获取npc属性
---@param npcData table npc数据
---@return table fix属性数组
XAttribManager.GetNpcAttribs = function(npcData)
    local code, attribs = GetNpcAttribs(npcData)
    if code ~= XCode.Success then
        return nil
    end

    return attribs
end

--============
--属性加值
--============
XAttribManager.DoAddAttribsByAttrAndAddId = function(attr, attrId)
    local attr1 = XAttribManager.GetAttribByAttribId(attrId)
    DoAddAttribs(attr, attr1)
end

XAttribManager.GetAttribByAttribId = function(attribId)
    local code, baseAttribValues = GetAttribValueTemplate(attribId)
    if code then 
        local baseAttribs = RawValueToFixList(baseAttribValues)
        return baseAttribs 
    end
    return nil
end

XAttribManager.TryGetAttribGroupTemplate = function(id)
    local code, template = GetAttribGroupTemplate(id)
    if code ~= XCode.Success then
        XLog.Error("XAttribManager.GetAttribGroupTemplate error: code is ", code)
        return nil
    end

    return template
end

---获取npc基础属性
XAttribManager.GetNpcBaseAttribsByNpcIdWithReviseId = function(npcTemplateId, level, reviseId)
    local code, attribs = GetNpcBaseAttribsByNpcIdWithReviseId(npcTemplateId, level, reviseId)
    if code ~= XCode.Success then
        return nil
    end

    return attribs
end

-------------------------------------Partner相关----------------------------------------------------
-- 伙伴属性id获取接口
local AddPartnerNumericIdInterfaces = {}
local AddPartnerPromotedIdInterfaces = {}

function XAttribManager.RegisterPartnerNumericIdInterface(inter)
    tableInsert(AddPartnerNumericIdInterfaces, inter)
end

function XAttribManager.RegisterPartnerPromotedIdInterface(inter)
    tableInsert(AddPartnerPromotedIdInterfaces, inter)
end

---获取Partner基础属性
-- local function GetPartnerBaseAttribs(partnerData, attribs)
--     local partnerEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData)

--     if partnerEntity then
--         return XCode.PartnerTemplateNotFound
--     end
--     local code, baseAttribs = GetAttribTemplate(partnerEntity:GetBaseAttribId())
--     if code ~= XCode.Success then
--         return code, nil
--     end
--     DoAddAttribs(attribs, baseAttribs)
--     return XCode.Success
-- end

---获取属性叠加id列表
local function GetPartnerNumericAttribIds(partnerData)
    local attribIds = {}
    for _, inter in pairs(AddPartnerNumericIdInterfaces) do
        local code = inter(partnerData, attribIds)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    return XCode.Success, attribIds
end

---获取属性成长id列表和培养等级列表
local function GetPartnerPromotedAttribIds(partnerData)
    local attribIds = {}
    local levels = {}

    for _, inter in pairs(AddPartnerPromotedIdInterfaces) do
        local code = inter(partnerData, attribIds, levels)
        if code ~= XCode.Success then
            return code, nil, nil
        end
    end

    return XCode.Success, attribIds, levels
end

---属性叠加计算
local function DoAddPartnerNumericAttribValues(partnerData, attribValues)
    local code, attribIds = GetPartnerNumericAttribIds(partnerData)
    if code ~= XCode.Success then
        return code
    end

    local numericAttribValues
    code, numericAttribValues = GetTotalNumericAttribValues(attribIds)
    if code ~= XCode.Success then
        return code
    end

    DoAddAttribValues(attribValues, numericAttribValues)

    return XCode.Success
end

---属性成长计算
local function DoAddPartnerPromotedAttribValues(partnerData, attribValues)
    local code, attribIds, levels = GetPartnerPromotedAttribIds(partnerData)
    if code ~= XCode.Success then
        return code
    end

    local promotedAttribs
    code, promotedAttribs = GetTotalPromotedAttribValues(attribIds, levels)
    if code ~= XCode.Success then
        return code
    end

    DoAddAttribValues(attribValues, promotedAttribs)
    return XCode.Success
end

---获取Partner属性
---@param isReturnRawValue boolean 是否返回RawValue数
local function GetPartnerAttribs(partnerData, isReturnRawValue)
    local attribValues = CreateAttribValueArray()

    local code = DoAddPartnerNumericAttribValues(partnerData, attribValues)
    if code ~= XCode.Success then
        return code, nil
    end

    code = DoAddPartnerPromotedAttribValues(partnerData, attribValues)
    if code ~= XCode.Success then
        return code, nil
    end

    if isReturnRawValue then
        return XCode.Success, attribValues
    else
        local attribs = RawValueToFixList(attribValues)
        return XCode.Success, attribs
    end
end

local function TryGetPartnerAttribs(partnerData)
    local code, attribs = GetPartnerAttribs(partnerData, true)
    if code ~= XCode.Success then
        XLog.Error("TryGetPartnerAttribs error: code is ", code)
        return nil
    end

    return RawValue2XAttrib(attribs)
end

------------------------------------------------------------------------------------------
---------------------------------------客户端特有方法---------------------------------------
local _IsInited

function XAttribManager.Init()
    CS.XFightDelegate.GetNpcBaseAttrib = TryGetNpcBaseAttribs
    CS.XFightDelegate.GetNpcAttrib = TryGetNpcAttribs
    CS.XFightDelegate.GetPartnerAttrib = TryGetPartnerAttribs
    LoadAttribConfig()

    _IsInited = true
    XEventManager.DispatchEvent(XEventId.EVENT_ATTRIBUTE_MANAGER_INIT)
end

function XAttribManager.IsInited()
    return _IsInited
end