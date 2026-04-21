local stringIsNilOrEmpty = string.IsNilOrEmpty
local tableInsert = table.insert

---@class XMovieActionBgGroup
---@field UiRoot XUiMovie
local XMovieActionBgGroup = XClass(XMovieActionBase, "XMovieActionBgGroup")

---@param actionData XTableMovieNew
function XMovieActionBgGroup:OnInit(actionData)
    local params = actionData.Params
    self.Layer = XMVCA.XMovie:ParamToNumber(params[1])
    self.IsClose = params[2] == "1"
    self.LoopCount = XMVCA.XMovie:ParamToNumber(params[3]) -- 0为一直循环
    self.SwitchAnimTime = XMVCA.XMovie:ParamToNumber(params[4]) -- 背景切换的动画时间
    self.StayTime = XMVCA.XMovie:ParamToNumber(params[5]) -- 背景停留时间
    self.IsFadeOut = params[6] == "1" -- 是否淡出
    
    self.BgPaths = {}
    local BG_INDEX_START = 7
    local BG_INDEX_END = 11
    for i = BG_INDEX_START, BG_INDEX_END do
        local bgPath = params[i]
        if not stringIsNilOrEmpty(bgPath) then
            tableInsert(self.BgPaths, bgPath)
        end
    end
end

function XMovieActionBgGroup:OnRunning()
    local gridBgGroup = self.UiRoot:GetGridBgGroup(self.Layer)
    if self.IsClose then
        gridBgGroup:Close()
    else
        gridBgGroup:Open()
        gridBgGroup:Play(self.BgPaths, self.LoopCount, self.SwitchAnimTime, self.StayTime, self.IsFadeOut)
    end
end

function XMovieActionBgGroup:IsPassedActionRun(index)
    -- 关闭背景组/非循环的背景组，跳过都不执行
    if self.IsClose or self.LoopCount ~= 0 then return false end

    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionBgGroup:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then
        return action.Layer == self.Layer
    end
    return false
end

function XMovieActionBgGroup:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionBgGroup