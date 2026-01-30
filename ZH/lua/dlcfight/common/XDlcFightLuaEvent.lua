EFightLuaEvent = {
    --- 设置棋子AI是否启用 参数详看: XLuaEventArgsAutoChessSetAIEnable
    AutoChessSetAIEnable = 1000,
    --- 触发道具技能 参数详看: XLuaEventArgsAutoChessTriggerItemSkill
    AutoChessTriggerItemSkill = 1001,
    --- 触发道具技能连招 参数详看: XLuaEventArgsAutoChessItemSkillComboStart
    AutoChessItemSkillComboStart = 1002,
    --- 触发道具技能连招 参数详看: XLuaEventArgsAutoChessItemSkillComboEnd
    AutoChessItemSkillComboEnd = 1003,
    --- 设置RelinkAI是否激活 参数详看：XLuaEventArgsRelinkSetAIActivate
    RelinkSetAIActivate = 1004,
    --- RelinkAI出生 参数详看：XLuaEventArgsRelinkAIBorn
    RelinkAIBorn = 1005,
    --- Relink弹刀事件
    RelinkCounterSuccess = 1006,
    --- Relink发起弹刀技能
    RelinkCastCounterSkill = 1007,
    --- Relink怪物释放强力技能
    RelinkMonsterCastPowerfulSkill = 1008
}

--region Define - GetEventArgs
---@class XLuaEventArgsAutoChessSetAIEnable
---@field Enable boolean

---@class XLuaEventArgsAutoChessTriggerItemSkill
---@field NpcUUid number
---@field ItemSkillId number

---@class XLuaEventArgsAutoChessItemSkillComboStart
---@field NpcUUid number
---@field StartItemSkillId number

---@class XLuaEventArgsAutoChessItemSkillComboEnd
---@field NpcUUid number
---@field ItemSkillId number

---@class XLuaEventArgsRelinkSetAIActivate
---@field NpcUUid number
---@field IsActivated boolean

---@class XLuaEventArgsRelinkAIBorn
---@field NpcUUid number

---@class XLuaEventArgsRelinkCounterSuccess
---@field TriggerNpcUUid number
---@field NpcUUid number

---@class XLuaEventArgsRelinkCastCounterSkill
---@field SourceNpcUUID int
---@field TargetNpcUUID int

---@class XLuaEventArgsRelinkMonsterCastPowerfulSkill
---@field NpcUUid int
--endregion

--------------------------------------------

local EventNamesById = {}

for name, id in pairs(EFightLuaEvent) do
    EventNamesById[id] = name
end

local function InitEventArgsAccessHook(proto)
    proto.__index = function(argsTable, key)
        return proto[key] --argsTable里找不到对应key的value时，拿原型里的默认值
    end

    proto.__newindex = function(argsTable, key, value)
        local protoValue = proto[key]
        if protoValue == nil then
            XLog.Error(string.format(
                "[战斗Lua自定义事件.字段赋值] 不允许赋值事件参数定义外的字段！[事件:%s][字段:%s]",
                proto.__name or "", key))
            return
        end

        local valueType = type(value)
        local defValueType = type(protoValue)
        if valueType ~= defValueType then
            XLog.Error(string.format(
                "[战斗Lua自定义事件.字段赋值] 所给值的类型与事件参数定义的类型不匹配！[事件:%s][字段:%s][所给类型:%s][定义类型:%s]",
                proto.__name or "", key, valueType, defValueType))
            return
        end

        rawset(argsTable, key, value) --通过了限制判断，才允许修改
    end
end

--region 战斗Lua自定义事件定义

---@class LuaEventArgs
local LuaEventArgs = {
    __type = 0,
    __name = "None",
}
function LuaEventArgs:Clear()
end

---@class AutoChessTriggerItemSkillEventArgs : LuaEventArgs
local AutoChessTriggerItemSkillEventArgs = {
    __type = EFightLuaEvent.AutoChessTriggerItemSkill,
    __name = EventNamesById[EFightLuaEvent.AutoChessTriggerItemSkill],
    NpcUUid = 0,
    ItemSkillId = 0,
}
function AutoChessTriggerItemSkillEventArgs:Clear()
    self.NpcUUid = 0
    self.ItemSkillId = 0
end

local EventArgsPrototypes = {
    [EFightLuaEvent.AutoChessTriggerItemSkill] = AutoChessTriggerItemSkillEventArgs,
    --TODO：增加新的事件参数原型映射
}

--endregion 战斗Lua自定义事件定义

for _, proto in pairs(EventArgsPrototypes) do
    InitEventArgsAccessHook(proto)
end

XEventManager = {
    _pool = {}
}
---获取给定lua自定义事件类型的事件参数对象
---@param eventType number @使用EFightLuaEvent填写
---@return table
function XEventManager.GetEventArgs(eventType)
    if eventType == nil then
        XLog.Error("[XEventManager.GetEventArgs] 参数eventType为空")
        return nil
    end

    local proto = EventArgsPrototypes[eventType]
    if proto == nil then
        XLog.Error(string.format("[XEventManager.GetEventArgs] 找不到对应事件类型的事件参数原型 [事件:%s]",
            EventNamesById[eventType] or ""))
        return nil
    end

    local obj
    local list = XEventManager._GetListInPool(eventType)
    local count = #list
    if count > 0 then
        obj = table.remove(list, count)
    else
        obj = {}
        setmetatable(obj, proto)
    end

    return obj
end

---回收lua自定义事件参数对象
---@param args LuaEventArgs @事件参数对象
---@return bool 是否成功回收事件参数对象
function XEventManager.ReleaseEvenArgs(args)
    if args == nil then
        XLog.Error("[XEventManager.ReleaseEvenArgs] args为空")
        return false
    end

    if type(args) ~= "table" then
        XLog.Error("[XEventManager.ReleaseEvenArgs] args不是table")
        return false
    end

    if args.__type == nil then
        XLog.Error("[XEventManager.ReleaseEvenArgs] args没有__type字段，不是从原型生成的事件参数对象")
        return false
    end

    local list = XEventManager._GetListInPool(args.__type)
    args:Clear()
    list[#list + 1] = args
    return true
end

function XEventManager._GetListInPool(eventType)
    local list = XEventManager._pool[eventType]
    if list == nil then
        list = {}
        XEventManager._pool[eventType] = list
    end
    return list
end

--测试
---@type AutoChessTriggerItemSkillEventArgs
--local args = XEventManager.GetEventArgs(EFightLuaEvent.AutoChessTriggerItemSkill)
--args.Name = "v" --会报错，原型没有这个key，不允许设值
--args.NpcUUid = "123" --会报错，值的类型不匹配
--args.ItemSkillId = 1001 --会正常修改
--print("args.NpcUUid", args.NpcUUid) --会获取到默认值
--print("args.ItemSkillId", args.ItemSkillId) --会获取到前面修改后的值

--XEventManager.ReleaseEvenArgs(args)
--XLog.Debug("lua事件对象池 回收后", XEventManager._pool)
--args = XEventManager.GetEventArgs(EFightLuaEvent.AutoChessTriggerItemSkill)
--XLog.Debug("lua事件对象池 重新取出后", XEventManager._pool)
--print("args.NpcUUid", args.NpcUUid)
--print("args.ItemSkillId", args.ItemSkillId)

--XEventManager.ReleaseEvenArgs(args)
--XLog.Debug("lua事件对象池 再次回收后", XEventManager._pool)