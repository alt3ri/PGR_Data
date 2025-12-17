---@class InputParamBtnHold
local InputParamBtnHold = XClass(nil, "InputParamBtnHold")

local EnumHoldState = {}
EnumHoldState.Awake = 0 --等待触发
EnumHoldState.HasBegan = 1 --已经触发长按

---@desc 传入技能输入事件里 OnInputEvent(eventArgs).InputTemplate参数列表 返回解析后的呼入参数
---@return InputParamBtnHold
function InputParamBtnHold:Ctor(eventArgs)
    self.InputType = eventArgs.InputType
    self.OperateTime = eventArgs.OperateTime --操作存在时间
    self.CurrentFightTime = eventArgs.CurrentFightTime --该操作的战斗时间
    self.InputParam = {}
    self.InputParam.BtnKey = eventArgs.BtnKey --按键Key
    self.InputParam.BtnState = eventArgs.BtnState --按键状态
    self.InputParam.HoldState = EnumHoldState.Awake
    self.InputParam.HoldStartTime = 0 --长按开始时间
    self.InputParam.HoldTriggerTime = 0.15 --长按触发时间
    
    local list = XTool.CsList2LuaTable(eventArgs.InputTemplate)
    --长按触发时间
    if (not list[1] == nil) then
        self.InputParam.HoldTriggerTime = list[1]
    else
        self.InputParam.HoldTriggerTime = 0.15 --默认0.15
    end
end

--检查是否处于 可触发动作开始 状态
function InputParamBtnHold:CheckCanAwake()
    local result = self.InputParam.HoldState == EnumHoldState.Awake and self.OperateTime > self.InputParam.HoldTriggerTime
    return result
end

--检查 动作开始是否已经被触发
function InputParamBtnHold:CheckHasBegan()
    return self.InputParam.HoldState == EnumHoldState.HasBegan
end

--触发动作开始
function InputParamBtnHold:SetHasBegan()
    self.InputParam.HoldState = EnumHoldState.HasBegan
    self.InputParam.HoldStartTime = self.OperateTime
end

--获取该技能长按时间
function InputParamBtnHold:GetHoldTime()
    if self.InputParam.HoldStartTime == 0 then
        return 0
    end
    return self.OperateTime - self.InputParam.HoldStartTime
end

return InputParamBtnHold

