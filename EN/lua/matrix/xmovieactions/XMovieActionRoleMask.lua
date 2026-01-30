local XMovieActionRoleMask = XClass(XMovieActionBase,"XMovieActionRoleMask")

function XMovieActionRoleMask:OnInit(actionData)
    self.IsEnable = XDataCenter.MovieManager.ParamToNumber(actionData.Params[1]) == 1
end

function XMovieActionRoleMask:OnRunning()
    if self.IsEnable then
        self.UiRoot:PlayAnimation("UiMaskEnable",nil,function() 
            self.UiRoot.UiMask02.gameObject:SetActiveEx(true)
        end)
    else
        self.UiRoot:PlayAnimation("UiMaskDisable",function()
            self.UiRoot.UiMask02.gameObject:SetActiveEx(false)
        end)
    end
end

function XMovieActionRoleMask:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index, function(action)
        return self:IsActionCover(action)
    end)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionRoleMask:IsActionCover(action)
    return action:GetType() == self:GetType()
end

function XMovieActionRoleMask:OnPassedActionRun()
    self.UiRoot.UiMask02.gameObject:SetActiveEx(self.IsEnable)
end

return XMovieActionRoleMask