---@class XMovieActionItemIconSet
---@field UiRoot XUiMovie
local XMovieActionItemIconSet = XClass(XMovieActionBase, "XMovieActionItemIconSet")

function XMovieActionItemIconSet:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.Index = paramToNumber(params[1])
    self.IconPath = params[2]
    self.PosX = paramToNumber(params[3])
    self.PosY = paramToNumber(params[4])
    self.PosZ = paramToNumber(params[5])
    self.Duration = paramToNumber(params[6])
    if self.Duration <= 0 then
        self.Duration = XMovieConfigs.ITEM_APPEAR_DURATION
    end
end

function XMovieActionItemIconSet:OnRunning()
    local panel = self.UiRoot.PanelItem
    if not panel then
        return
    end
    panel:Set(self.Index, self.IconPath, self.Duration, self.PosX, self.PosY, self.PosZ)
end

function XMovieActionItemIconSet:GetIndex()
    return self.Index
end

function XMovieActionItemIconSet:GetEndDelay()
    local endDelay = XMovieActionBase.GetEndDelay(self)
    if endDelay and endDelay > 0 then
        return endDelay
    end
    return self.Duration
end

function XMovieActionItemIconSet:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

---@param action XMovieActionBase
function XMovieActionItemIconSet:IsPassedActionCovered(action)
    local actionType = action:GetType()
    local enum = XMVCA.XMovie.EnumConst.ACTION_TYPE
    if actionType == enum.ITEM_ICON_SET or actionType == enum.ITEM_ICON_REMOVE then
        return action:GetIndex() == self.Index
    end
    return false
end

function XMovieActionItemIconSet:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionItemIconSet
