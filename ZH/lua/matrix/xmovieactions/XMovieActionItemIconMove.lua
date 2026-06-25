---@class XMovieActionItemIconMove
---@field UiRoot XUiMovie
local XMovieActionItemIconMove = XClass(XMovieActionBase, "XMovieActionItemIconMove")

function XMovieActionItemIconMove:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.Index = paramToNumber(params[1])
    self.Duration = paramToNumber(params[2])
    if self.Duration <= 0 then
        self.Duration = XMovieConfigs.ITEM_MOVIE_DURATION
    end
    self.PosX = paramToNumber(params[3])
    self.PosY = paramToNumber(params[4])
    self.PosZ = paramToNumber(params[5])
end

function XMovieActionItemIconMove:OnRunning()
    local panel = self.UiRoot.PanelItem
    if not panel then
        return
    end
    panel:Move(self.Index, self.Duration, self.PosX, self.PosY, self.PosZ)
end

function XMovieActionItemIconMove:GetIndex()
    return self.Index
end

function XMovieActionItemIconMove:GetEndDelay()
    local endDelay = XMovieActionBase.GetEndDelay(self)
    if endDelay and endDelay > 0 then
        return endDelay
    end
    return self.Duration
end

function XMovieActionItemIconMove:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

---@param action XMovieActionBase
function XMovieActionItemIconMove:IsPassedActionCovered(action)
    local actionType = action:GetType()
    local enum = XMVCA.XMovie.EnumConst.ACTION_TYPE
    if actionType == enum.ITEM_ICON_SET
        or actionType == enum.ITEM_ICON_MOVE
        or actionType == enum.ITEM_ICON_REMOVE then
        return action:GetIndex() == self.Index
    end
    return false
end

function XMovieActionItemIconMove:OnPassedActionRun()
    local panel = self.UiRoot.PanelItem
    if not panel then
        return
    end
    panel:Move(self.Index, 0, self.PosX, self.PosY, self.PosZ)
end

return XMovieActionItemIconMove
