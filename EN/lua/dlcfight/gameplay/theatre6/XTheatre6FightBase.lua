local XFightBase = require("Common/XFightBase")

---肉鸽6战斗相关脚本通用基类
---负责事件的自动监听
---负责通知的调用
---@class XTheatre6FightBase:XFightBase
---@field _name string 对象名, 用于打印调试信息
local XTheatre6FightBase = XClass(XFightBase, "XTheatre6FightBase")

local LuaEvent = EFightLuaEvent

local LuaEventType2Func = {
    [LuaEvent.Theatre6SkillStart] = "OnLuaSkillStart",
    [LuaEvent.Theatre6SkillEnd] = "OnLuaSkillEnd",
    [LuaEvent.Theatre6AttakerChange] = "OnLuaAttackerChange",
    [LuaEvent.Theatre6AffixCritDamage] = "OnLuaAffixCritDamage",
    [LuaEvent.Theatre6AffixHitFly] = "OnLuaAffixHitFly",
    [LuaEvent.Theatre6AffixHitDown] = "OnLuaAffixHitDown",
    [LuaEvent.Theatre6SpecialHit] = "OnLuaSpecialHit",
    [LuaEvent.Theatre6AffixBlock] = "OnLuaAffixBlock",
    [LuaEvent.Theatre6AffixBlockBreak] = "OnLuaAffixBlockBreak",
}

function XTheatre6FightBase:_BaseInit()
    XFightBase._BaseInit(self)
    self:InitDefaultEventCallBackRegister()
end

function XTheatre6FightBase:InitEnemyUUID()
    local proxy = self._proxy
    local uuid1, uuid2 = proxy:Theatre6GetNpc(true), proxy:Theatre6GetNpc(false)
    if uuid1 == self._uuid then
        self._enemyUUID = uuid2
    else
        self._enemyUUID = uuid1
    end
end

---@return XTheatre6CharBase
function XTheatre6FightBase:GetEnemyNpc()
    if not self._enemy then
        local uuid = self._enemyUUID
        self._enemy = self._proxy:GetActorScriptObject(EScriptType.Npc, uuid,
            self._proxy:GetNpcTemplate(uuid).ScriptId) --[[@as XTheatre6CharBase]]
    end
    return self._enemy
end

function XTheatre6FightBase:InitLuaEvent()
    XFightBase.InitLuaEvent(self)

    --这里的自动化监听本来想通过__newIndex给每个子类生成一张静态的监听范围表, 但涉及XClass结构, 暂且作罢
    for eventType, funcName in pairs(LuaEventType2Func) do
        if self[funcName] then
            self:RegisterLuaEvent(eventType)
        end
    end
end

function XTheatre6FightBase:InitDefaultEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.EnterLevel)
end

function XTheatre6FightBase:HandleEvent(eventType, eventArgs)
    XFightBase.HandleEvent(self, eventType, eventArgs)
    if eventType == EWorldEvent.EnterLevel then
        return self:OnEnterLevel(eventArgs.LevelId)
    end
end

---@param eventType EFightLuaEvent lua事件类型
---@param eventArgs LuaEventArgs lua事件参数表
function XTheatre6FightBase:HandleLuaEvent(eventType, eventArgs)
    local fun = LuaEventType2Func[eventType]
    fun = fun and self[fun]
    return fun and fun(self, eventArgs)
end

---发送lua事件通知并释放事件参数表
---@param eventType EFightLuaEvent lua事件类型
---@param eventArgs LuaEventArgs lua事件参数表, 需要通过 XEventManager.GetEventArgs() 获取
---@param targetType ELuaEventTarget|nil lua事件通知范围类型, 为空时全域广播
function XTheatre6FightBase:DispatchLuaEvent(eventType, eventArgs, targetType)
    -- ※※※ 注意这里立刻释放事件参数表的逻辑强依赖于_proxy:DispatchLuaEvent()的时效性,
    -- ※※※ 如果_proxy:DispatchLuaEvent()修改为异步逻辑, 则这里必炸.

    -- if not (eventArgs.IsLuaEventArgs and eventArgs:IsLuaEventArgs()) then
    --     self:LogError("XTheatre6FightBase:DispatchLuaEvent Error: Illegal EventArgs")
    -- end

    targetType = targetType or ELuaEventTarget.All
    XFightBase.DispatchLuaEvent(self, targetType, eventType, eventArgs)
    XEventManager.ReleaseEvenArgs(eventArgs)
end

---@param logStr string
function XTheatre6FightBase:LogError(logStr)
    if type(logStr) ~= "string" then
        return XLog.Error("XTheatre6FightBase:LogError Error: Illegal Log Format")
    end
    return XLog.Error(self._name .. ": " .. logStr)
end

---@param logStr string
function XTheatre6FightBase:LogInfo(logStr)
    if type(logStr) ~= "string" then
        return XLog.Error("XTheatre6FightBase:LogInfo Error: Illegal Log Format")
    end
    return XLog.Debug(self._name .. ": " .. logStr)
end

local AddAttribMagics = {
    [ENpcAttrib.Attack] = 1025904,
    [ENpcAttrib.Life] = 1025905,
}

---增加通用属性值
---@param Type ENpcAttrib
---@param Value number
---@param launcherUUID integer
---@param targetUUID integer
function XTheatre6FightBase:AddAttrib(Type, Value, launcherUUID, targetUUID)
    local magicId = AddAttribMagics[Type]
    self._proxy:ApplyMagic(launcherUUID, targetUUID, magicId, 1, 0, Value)
end

local Theatre6AddAttribMagics = {
    [ETheatre6AttribType.WrestlePoint] = 1025901,
    [ETheatre6AttribType.OverClock] = 1025902,
    [ETheatre6AttribType.Stamina] = 1025903,
}

---增加肉鸽6专属属性值
---@param Type ETheatre6AttribType
---@param Value number
---@param launcherUUID integer
---@param targetUUID integer
function XTheatre6FightBase:AddTheatre6Attrib(Type, Value, launcherUUID, targetUUID)
    local magicId = Theatre6AddAttribMagics[Type]
    self._proxy:ApplyMagic(launcherUUID, targetUUID, magicId, 1, 0, Value)
end

---关卡初始化完成的通知, 在这里进行部分指针的初始化
---@param levelId integer
function XTheatre6FightBase:OnEnterLevel(levelId)
    self._level = self._proxy:GetLevelScriptObject(EScriptType.LevelLogic, levelId) --[[@as XLevelScript.1081]]
    self:InitEnemyUUID()
    self:GetEnemyNpc()
    -- self:LogError("OnEnterLevel is called")
end

do return XTheatre6FightBase end

---肉鸽6技能启动的通知
---@param eventArgs Theatre6SkillEventArgs
function XTheatre6FightBase:OnLuaSkillStart(eventArgs)
end

---肉鸽6技能结束的通知
---@param eventArgs Theatre6SkillEventArgs
function XTheatre6FightBase:OnLuaSkillEnd(eventArgs)
end

---肉鸽6出手权/出手方交换的通知
---@param eventArgs Theatre6AttackerChangeEventArgs
function XTheatre6FightBase:OnLuaAttackerChange(eventArgs)
end

---肉鸽6触发暴击的通知
---@param eventArgs Theatre6HitAffixArgs
function XTheatre6FightBase:OnLuaAffixCritDamage(eventArgs)
end

---肉鸽6触发击飞的通知
---@param eventArgs Theatre6HitAffixArgs
function XTheatre6FightBase:OnLuaAffixHitFly(eventArgs)
end

---肉鸽6触发击倒的通知
---@param eventArgs Theatre6HitAffixArgs
function XTheatre6FightBase:OnLuaAffixHitDown(eventArgs)
end

---肉鸽6触发格挡的通知
---@param eventArgs Theatre6HitAffixArgs
function XTheatre6FightBase:OnLuaAffixBlock(eventArgs)
end

---肉鸽6触发破防的通知
---@param eventArgs Theatre6HitAffixArgs
function XTheatre6FightBase:OnLuaAffixBlockBreak(eventArgs)
end

---肉鸽6触发特殊命中的通知(即被标记activate的子弹命中)
---@param eventArgs Theatre6HitAffixArgs
function XTheatre6FightBase:OnLuaSpecialHit(eventArgs)
end