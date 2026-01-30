
---@class InputParamBtnPress
local InputParamBtnPress = XClass(nil, "InputParamBtnPress")


function InputParamBtnPress:Ctor(eventArgs)
    self.InputType = eventArgs.InputType
    self.OperateTime = eventArgs.OperateTime --操作存在时间
    self.CurrentFightTime = eventArgs.CurrentFightTime --该操作的战斗时间
    self.InputParam = {}
    self.InputParam.BtnKey = eventArgs.BtnKey --按键Key
    self.InputParam.BtnState = eventArgs.BtnState --按键状态
    self.InputParam.InputCache = 0.15 --输入缓存 默认0.15秒

    local list = XTool.CsList2LuaTable(eventArgs.InputTemplate)
    --输入缓存
    if (not list[1] == nil) then
        self.InputParam.InputCache = list[1]
    else
        self.InputParam.InputCache = 0.15 --默认0.15
    end
end

--检查输入缓存，判断该输入还是否有效
function InputParamBtnPress:CheckInputValid()
    return self.OperateTime <= self.InputParam.InputCache
end


return InputParamBtnPress

