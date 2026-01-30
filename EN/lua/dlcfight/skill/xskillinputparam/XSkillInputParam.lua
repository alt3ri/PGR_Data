local InputParamBtnPress = require("Skill/XSkillInputParam/InputParamBtnPress")
local InputParamBtnHold = require("Skill/XSkillInputParam/InputParamBtnHold")

local XSkillInputParam = {}

function XSkillInputParam.InitInputEvent(eventArgs)
    --输入类型:按键点按
    if eventArgs.InputType == ESkillInputType.BtnPress then
        return InputParamBtnPress.New(eventArgs) 
    --输入类型:按键长按
    elseif eventArgs.InputType == ESkillInputType.BtnHold then
        return InputParamBtnHold.New(eventArgs)
    else
        XLog.Error("未知输入事件:" .. tostring(eventArgs.InputType) .. "！ " .. eventArgs)
        return eventArgs
    end
end

return XSkillInputParam