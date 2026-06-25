---@class XMovieActionItemIconRemove
---@field UiRoot XUiMovie
local XMovieActionItemIconRemove = XClass(XMovieActionBase, "XMovieActionItemIconRemove")

function XMovieActionItemIconRemove:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.Index = paramToNumber(params[1])
    self.Duration = paramToNumber(params[2])
    if self.Duration <= 0 then
        self.Duration = XMovieConfigs.ITEM_DISAPPEAR_DURATION
    end
end

function XMovieActionItemIconRemove:OnRunning()
    local panel = self.UiRoot.PanelItem
    if not panel then
        return
    end
    panel:Remove(self.Index, self.Duration)
end

function XMovieActionItemIconRemove:GetIndex()
    return self.Index
end

function XMovieActionItemIconRemove:GetEndDelay()
    local endDelay = XMovieActionBase.GetEndDelay(self)
    if endDelay and endDelay > 0 then
        return endDelay
    end
    return self.Duration
end

function XMovieActionItemIconRemove:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

---@param action XMovieActionBase
function XMovieActionItemIconRemove:IsPassedActionCovered(action)
    local actionType = action:GetType()
    local enum = XMVCA.XMovie.EnumConst.ACTION_TYPE
    if actionType == enum.ITEM_ICON_SET or actionType == enum.ITEM_ICON_REMOVE then
        return action:GetIndex() == self.Index
    end
    return false
end

function XMovieActionItemIconRemove:OnPassedActionRun()
    local panel = self.UiRoot.PanelItem
    if not panel then
        return
    end
    panel:Remove(self.Index, 0)
end

return XMovieActionItemIconRemove
