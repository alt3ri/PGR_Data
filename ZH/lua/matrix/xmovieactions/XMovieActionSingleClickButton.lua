---@class XMovieActionSingleClickButton
---@field UiRoot XUiMovie
local XMovieActionSingleClickButton = XClass(XMovieActionBase, "XMovieActionSingleClickButton")

local OPTION_INDEX = 1

function XMovieActionSingleClickButton:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.ButtonId = params[1]
    if string.IsNilOrEmpty(self.ButtonId) then
        self.ButtonId = tostring(self.ActionId)
    end

    self.ImagePath = params[2]
    local pos = XMVCA.XMovie:SplitParam(params[3], "|", true)
    self.PosX = pos[1] or 0
    self.PosY = pos[2] or 0
    self.TargetActionId = paramToNumber(params[4])
end

function XMovieActionSingleClickButton:CanContinue()
    return false
end

function XMovieActionSingleClickButton:OnRunning()
    self.SelectedActionId = 0
    self.RepeatClick = nil

    if not self.UiRoot or not self.UiRoot.AddSingleClickButton then
        XLog.Error("XMovieActionSingleClickButton:OnRunning error: UiRoot does not support single click button, actionId is " .. self.ActionId)
        return
    end

    self.UiRoot:AddSingleClickButton(self.ButtonId, self.ImagePath, self.PosX, self.PosY, self:GetClickActionId(), function()
        self:OnClickButton()
    end)

    if self:IsBlock() then
        self.UiRoot:SetBtnNextCallback(function() end)
    end
end

function XMovieActionSingleClickButton:OnClickButton()
    if self.RepeatClick then
        return
    end
    self.RepeatClick = true
    self.SelectedActionId = self:GetClickActionId()

    local movieId = XDataCenter.MovieManager.GetCurPlayingMovieId()
    XMVCA.XMovie:RequestRecordOption(movieId, self.ActionId, OPTION_INDEX)
    XDataCenter.MovieManager.CacheSelectionData(self.ActionId, OPTION_INDEX)

    local isMoviePause = XDataCenter.MovieManager.IsMoviePause()
    if isMoviePause then
        self.UiRoot:OnClickBtnPause()
    end

    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
end

function XMovieActionSingleClickButton:OnDestroy()
    if self:IsBlock() and self.UiRoot and self.UiRoot.RemoveBtnNextCallback then
        self.UiRoot:RemoveBtnNextCallback()
    end
    self.RepeatClick = nil
end

function XMovieActionSingleClickButton:OnUiRootDestroy()
    self.RepeatClick = nil
end

function XMovieActionSingleClickButton:OnUndo()
    if self.UiRoot and self.UiRoot.ClearSingleClickButtons then
        self.UiRoot:ClearSingleClickButtons()
    end
end

function XMovieActionSingleClickButton:GetSelectedActionId()
    local selectedActionId = self.SelectedActionId or 0
    if selectedActionId == 0 and self.UiRoot and self.UiRoot.GetSingleClickButtonSelectedActionId then
        selectedActionId = self.UiRoot:GetSingleClickButtonSelectedActionId()
    end

    if selectedActionId ~= 0 and self.UiRoot and self.UiRoot.ClearSingleClickButtons then
        self.UiRoot:ClearSingleClickButtons()
    end
    return selectedActionId
end

function XMovieActionSingleClickButton:GetClickActionId()
    if self.TargetActionId ~= 0 then
        return self.TargetActionId
    end
    return XDataCenter.MovieManager.GetNextActionId(self.ActionId)
end

function XMovieActionSingleClickButton:GetClickButtonOptionIndex()
    return OPTION_INDEX
end

return XMovieActionSingleClickButton
