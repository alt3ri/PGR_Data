local XQuestBaseAction = require("XUi/XUiBigWorld/XHud/Action/XQuestBaseAction")

---@class XQuestFuncAction : XQuestBaseAction
local XQuestFuncAction = XClass(XQuestBaseAction, "XQuestFuncAction")

function XQuestFuncAction:OnInit(func, caller, ...)
    self._Func = func
    self._Caller = caller
    local n = select("#", ...)
    if n > 0 then
        self._Args = {...}
    else
        self._Args = nil
    end
    self._IsPause = false
end

function XQuestFuncAction:Execute()
    if not self._Func then
        return self:Finish()
    end
    if self._Args then
        self._Func(self._Caller, table.unpack(self._Args))
    else
        self._Func(self._Caller)
    end
    
    self:Finish()
end

function XQuestFuncAction:OnDestroy()
    self:OnFinish()
end

function XQuestFuncAction:Finish()
    --结束时被暂停了，则不执行完成逻辑
    if self._IsPause then
        return
    end
    XQuestBaseAction.Finish(self)
end

function XQuestFuncAction:OnFinish()
    self._Func = nil
    self._Caller = nil
    self._Args = nil
end

function XQuestFuncAction:OnPause()
    self._IsPause = true
end

function XQuestFuncAction:GetActionType()
    return XMVCA.XBigWorldQuest.ActionType.Func
end

return XQuestFuncAction