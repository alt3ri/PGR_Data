local Base = require("Common/XFightBase")
local XSkillInputParam = require("Skill/XSkillInputParam/XSkillInputParam")

---所有Skill脚本的基类
---@class XSkillBase : XFightBase
---@field _uuid number NpcUUID
---@field _skillId number skill配置Id
local XSkillBase = XDlcScriptManager.RegSkillScript(1, "XSkillBase", Base)

--region 脚本生命周期
---@desc 初始化所有成员参数和注册所有事件
function XSkillBase:Init() --初始化
    --NpcId
    self._uuid = self._proxy:GetSelfSkillNpcUUID()
    --技能Id
    self._skillUUID = self._proxy:GetSelfSkillUUID()
    --初始化技能配置
    self.Template = self:InitSkillTemplate()
    self.SkillId = self.Template.SkillId
    --初始化脚本名
    self.ScriptName = "XSkillScript:" .. tostring(self.Template.SkillId)
    --设置主输入事件增加传递输入配置数据
    self._proxy:SetUseInputTemplate(true)
    --主输入事件数据缓存
    self.MainInputCache = nil
    --输入启用状态
    self.InputActive = true
    --初始化事件注册
    self:InitLuaEvent()
    self:InitEventCallBackRegister()
end

---@desc 初始化配置
function XSkillBase:InitSkillTemplate()
    local template = self._proxy:GetSkillTemplate()
    local Template = {}
    Template.SkillId = template.Id
    Template.NpcId = template.NpcId
    Template.ScriptType = template.ScriptType
    Template.ScriptId = template.ScriptId
    Template.CoolDown = template.CoolDown
    Template.CDGroup = template.CDGroup
    Template.MaxCharge = template.MaxCharge
    Template.OriginCharge = template.OriginCharge
    Template.ActionList1 = XTool.CsList2LuaTable(template.ActionList1);
    Template.ActionList2 = XTool.CsList2LuaTable(template.ActionList2);
    Template.ActionList3 = XTool.CsList2LuaTable(template.ActionList3);
    Template.CustomActionList = XTool.CsList2LuaTable(template.CustomActionList);
    Template.CustomParamList = XTool.CsList2LuaTable(template.CustomParamList);
    Template.SearchConfigId = template.SearchConfigId
    self.Template = Template
    return self.Template
end

---@desc Update基函数
---@param dt number @ delta time
function XSkillBase:Update(dt)
    Base.Update(self, dt)
    self:CheckInputCacheValid()
    if self:CheckInputCacheAndTryCastAction() then
        self.MainInputCache = nil
    end
    if not (self.MainInputCache == nil) then
        self.MainInputCache.OperateTime = self.MainInputCache.OperateTime + dt
    end
end

---@desc 输入启用时
function XSkillBase:OnInputEnable()
    self.MainInputCache = nil
    self.InputActive = true
end

---@desc 输入禁用时
function XSkillBase:OnInputDisable()
    self.MainInputCache = nil
    self.InputActive = false
end

---@desc 不允许策划复写
---@desc 脚本生命周期结束时调用
function XSkillBase:Terminate()
    Base.Terminate(self)
end

--endregion

--region 输入相关
---@desc 主输入事件(同一帧内时机比Update要早)
---@param eventArgs userdata
---eventArgs = {
---
---}
function XSkillBase:OnInputEvent(eventArgs)
    --缓存输入
    local inputCache = XSkillInputParam.InitInputEvent(eventArgs)
    --输入类型:按键按下
    if inputCache.InputType == ESkillInputType.BtnPress then
        if inputCache.InputParam.BtnState == EOperationType.Hold then
            return
        end
    end
    --输入类型:按键长按
    if inputCache.InputType == ESkillInputType.BtnHold then
        --长按有个可以预见的问题，当一个长按技能注册了两个长按按钮，但玩家长按按钮1的同时，移除了按钮1的注册。那该技能就会一直处在Loop状态。
        --如果已经存在长按输入缓存，则保留长按缓存数据。
        if inputCache.InputParam.BtnState == EOperationType.Down and not self.MainInputCache == nil then
            self.MainInputCache.InputParam.BtnState = EOperationType.Down
            return
        elseif inputCache.InputParam.BtnState == EOperationType.Hold then
            return
        elseif inputCache.InputParam.BtnState == EOperationType.Up and not self.MainInputCache == nil then
            self.MainInputCache.InputParam.BtnState = EOperationType.Up
            return
        end
    end
    self.MainInputCache = inputCache
    self.MainInputCache.OperateTime = 0
end

---@desc 检查缓存是否有效 若已经失效，则移除缓存
function XSkillBase:CheckInputCacheValid()
    if self.MainInputCache == nil then
        return
    end
    --输入类型:按键按下
    if self.MainInputCache.InputType == ESkillInputType.BtnPress then
        --判断按键缓存
        if not self.MainInputCache:CheckInputValid() then
            self.MainInputCache = nil
            return
        end
    end
    --输入类型:按键长按
    if self.MainInputCache.InputType == ESkillInputType.BtnHold then
        return
    end
end

---@desc 检查缓存并尝试释放动作
---@return bool 是否清理缓存
function XSkillBase:CheckInputCacheAndTryCastAction()
    if self.MainInputCache == nil then
        return false
    end
    --输入类型:按键按下
    if self.MainInputCache.InputType == ESkillInputType.BtnPress then
        if self.MainInputCache.InputParam.BtnState == EOperationType.Down then
            return self:CastStartAction()
        elseif self.MainInputCache.InputParam.BtnState == EOperationType.Up then
            return self:CastEndAction()
        end
    end
    --输入类型:按键长按
    if self.MainInputCache.InputType == ESkillInputType.BtnHold then
        if self.MainInputCache.InputParam.BtnState == EOperationType.Down and self.MainInputCache:CheckCanAwake() then
            if self:CastStartAction() then
                self.MainInputCache:SetHasBegan()
            end
            return false
        elseif self.MainInputCache.InputParam.BtnState == EOperationType.Down and self.MainInputCache:CheckHasBegan() then
            self:CastLoopAction()
            return false
        elseif self.MainInputCache.InputParam.BtnState == EOperationType.Up then
            self:CastEndAction()
            return true
        end
    end
end

--endregion

--region 事件入口
---@desc 不允许策划复写
---@desc 处理并分发C#事件
---@param eventType number
---@param eventArgs userdata
function XSkillBase:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

---@desc 不允许策划复写
---@desc 处理并分发Lua事件
---@param eventType number
---@param eventArgs userdata
function XSkillBase:HandleLuaEvent(eventType, eventArgs)
    Base.HandleLuaEvent(self, eventType, eventArgs)
end

--endregion

--region 动作触发逻辑
---@desc 禁止继承复写
function XSkillBase:CastStartAction()
    local CastContext = {}
    CastContext.Result = self:TryCastStartAction(CastContext)
    self.OnCastStartAction(CastContext)
    return CastContext.Result
end

---@desc 禁止继承复写
function XSkillBase:CastLoopAction()
    local CastContext = {}
    CastContext.Result = self:TryLoopEndAction(CastContext)
    self.OnCastLoopAction(CastContext)
    return CastContext.Result
end

---@desc 禁止继承复写
function XSkillBase:CastEndAction()
    local CastContext = {}
    CastContext.Result = self:TryCastEndAction(CastContext)
    self.OnCastEndAction(CastContext)
    return CastContext.Result
end

---@尝试释放开始动作
function XSkillBase:TryCastStartAction(CastContext)
    return false
end

---@尝试释放循环动作
function XSkillBase:TryLoopEndAction(CastContext)
    return false
end

---@尝试释放结束动作
function XSkillBase:TryCastEndAction(CastContext)
    return false
end

---@释放开始动作后(无论成不成功)
function XSkillBase:OnCastStartAction(CastContext)
end

---@释放循环动作后(无论成不成功)
function XSkillBase:OnCastLoopAction(CastContext)
end

---@释放结束动作后(无论成不成功)
function XSkillBase:OnCastEndAction(CastContext)
end

--endregion

--region 其他基础逻辑

---@desc 检查主输入事件是否通过
function XSkillBase:CheckMainEvent(eventArgs)
    if eventArgs.InputType == ESkillInputType.BtnPress then
        if eventArgs.BtnState == EOperationType.Down then
            return true
        end
        return false
    elseif eventArgs.InputType == ESkillInputType.BtnHold then
        if eventArgs.BtnState == EOperationType.Hold then
            return true
        end
        return false
    end
    return true
end

---@desc 检查释放动作的条件
---@param actionId number 动作ID
---@return boolean 是否通过
function XSkillBase:CheckCastCondition(actionId, timingId)
    --默认TimingId为0
    timingId = timingId or 0

    --判断输入是否通过
    if not self:CheckInputValid(actionId) then
        --XLog.Error("输入不通过")
        return false
    end

    --判断动作条件
    if not self._proxy:CheckNpcActionCondition(self._uuid, actionId) then
        --XLog.Error("动作条件不通过")
        return false
    end

    --判断打断关系
    if not self._proxy:CheckNpcCanAbortCurrentAction(self._uuid, actionId, timingId) then
        local _, curtime = self._proxy:TryGetNpcCurrentActionElapsedTime(self._uuid)
        --XLog.Error("打断不通过:" .. tostring(actionId) .. "  "  .. tostring(timingId) .. "   " .. tostring(curtime))
        return false
    end

    --C#该接口判断了
    --1 Npc是否死亡
    --2 Npc是否拥有 Npc状态:无法释放动作
    --3 Npc是否在受击
    --4 空中组件判断是否能在空中放动作
    if not self._proxy:CheckCanCastSkill(self._uuid) then
        --XLog.Error("Npc状态不用过")
        return false
    end

    return true
end

---@desc 刷新索敌并对索敌目标(敌人)释放技能，若无索敌目标，则对Npc面前10米处释放
function XSkillBase:CastActionBySearchEnemy(actionId, startTime, endTime)
    local LauncherId = self._uuid
    local searchConfigId = self.Template.SearchConfigId
    self._proxy:SwitchSearchMode(LauncherId, searchConfigId)
    local searchId = self._proxy:GetFirstSearchTarget(self._uuid, ENpcTargetType.Enemy)
    local curTarId = self._proxy:GetLockTarget(LauncherId)

    if searchId ~= curTarId then
        curTarId = searchId
        if searchId ~= 0 then
            local locktargettype = self._proxy:GetCurLockTargetType()
            if locktargettype == ELockTargetType.HardLock then
                self._proxy:SetHardLock(self._uuid, searchId)
            else
                self._proxy:SetSoftLock(self._uuid, searchId) --直接使用新索敌获得目标设置为软锁目标，新索敌获得的id不可读，为组合生成内容
            end

            local _, targetId = self._proxy:GetLockTarget()     --转换新索敌目标为搜索目标id，npcuuid
            self._proxy:SetNpcFocusTarget(LauncherId, targetId) --镜头锁定
        end
    end

    local actionTemplate = self._proxy:GetSkillActionTemplate(actionId)
    startTime = startTime or (actionTemplate and actionTemplate.StartTime)
    endTime = endTime or (actionTemplate and actionTemplate.EndTime)

    if curTarId ~= 0 then
        return self._proxy:CastSkillActionToSearchTargetNotCheck(self._uuid, actionId, curTarId, startTime, endTime)
    else
        return self:CastActionToFront(actionId, startTime, endTime);
    end
end

---@desc 对已有目标释放技能,若无目标,则对Npc面前10米处释放
function XSkillBase:CastActionToOldTarget(actionId, startTime, endTime)
    local LauncherId = self._uuid
    local curTarId = self._proxy:GetLockTarget(LauncherId)

    local actionTemplate = self._proxy:GetSkillActionTemplate(actionId)
    startTime = startTime or (actionTemplate and actionTemplate.StartTime)
    endTime = endTime or (actionTemplate and actionTemplate.EndTime)

    if curTarId ~= 0 then
        return self._proxy:CastSkillActionToSearchTargetNotCheck(self._uuid, actionId, curTarId, startTime, endTime)
    else
        return  self:CastActionToFront(actionId, startTime, endTime)
    end
end

---@desc 对Npc面前10米处释放
function XSkillBase:CastActionToFront(actionId, startTime, endTime)
    local actionTemplate = self._proxy:GetSkillActionTemplate(actionId)
    startTime = startTime or (actionTemplate and actionTemplate.StartTime)
    endTime = endTime or (actionTemplate and actionTemplate.EndTime)


    local pos = self._proxy:GetNpcPosition(self._uuid)
    local facing = self._proxy:GetNpcRotation(self._uuid)
    local tarPos = pos + facing * 10
    return self._proxy:CastSkillActionToPositionNotCheck(self._uuid, actionId, tarPos, startTime, endTime)
end

---@desc 检查输入是否通过
---@param actionId number 动作ID
---@return boolean 是否通过
function XSkillBase:CheckInputValid(actionId)
    return true
end

--endregion

function XSkillBase:IsReady()
    if not self._proxy:CheckNpcCanAbortCurrentSkill(self._uuid, self.SkillId) then return false end
    for _, actionId in ipairs(self.Template.ActionList1) do
        if self:CheckCastCondition(actionId) then return true end
    end
    return false;
end

function XSkillBase:Exec()
    for _, actionId in ipairs(self.Template.ActionList1) do
        if self:CheckCastCondition(actionId) then
            self:CastActionBySearchEnemy(actionId)
        end
    end
end

return XSkillBase
