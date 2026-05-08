local pairs = pairs
local tableInsert = table.insert
local SPINE_INDEX_OFFSET = 100 -- spine位置的偏移值
local ALL_BG_INDEX = 999
local START_INDEX = 2
local END_INDEX = 7

---@class XMovieActionSetGray
---@field UiRoot XUiMovie
local XMovieActionSetGray = XClass(XMovieActionBase, "XMovieActionSetGray")

function XMovieActionSetGray:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.Value = XMath.Clamp(paramToNumber(params[1]), 0, 1)
    self.IndexList = {}

    -- params[2]-params[7]
    for i = START_INDEX, END_INDEX do
        local id = paramToNumber(params[i])
        if id ~= 0 then
            tableInsert(self.IndexList, id)
        end
    end

    -- 灰度值变化时间
    self.Time = paramToNumber(params[8])
end

function XMovieActionSetGray:OnRunning()
    local value = self.Value
    local maxActorNum = XMovieConfigs.MAX_ACTOR_NUM
    local indexList = self.IndexList
    local setValue = false

    for _, index in pairs(indexList) do
        if index > 0 and index <= maxActorNum then
            ---@type XUiGridMovieActor
            local actor = self.UiRoot:GetActor(index)
            actor:SetGrayScale(value, self.Time)
            setValue = true
        elseif index > SPINE_INDEX_OFFSET and index <= SPINE_INDEX_OFFSET + maxActorNum then
            ---@type XUiGridMovieSpineActor
            local actor = self.UiRoot:GetSpineActor(index - SPINE_INDEX_OFFSET)
            actor:SetGrayScale(value, self.Time)
            setValue = true
        else
            self:SetBgGray(index, value, self.Time)
            self:SetLeftTitleGray(value, self.Time)
            setValue = true
        end
    end

    if not setValue then
        self:SetAllBgGray(value, self.Time)
        self:SetLeftTitleGray(value, self.Time)
        for index = 1, maxActorNum do
            ---@type XUiGridMovieActor
            local actor = self.UiRoot:GetActor(index)
            actor:SetGrayScale(value, self.Time)
        end

        for index = 1, XMovieConfigs.MAX_SPINE_ACTOR_NUM do
            ---@type XUiGridMovieSpineActor
            local actor = self.UiRoot:GetSpineActor(index)
            actor:SetGrayScale(value, self.Time)
        end
    end
end

-- 设置左边标题的灰度
function XMovieActionSetGray:SetLeftTitleGray(value, time)
    local controllerComponents = self.UiRoot.PanelLeftTitle:GetComponentsInChildren(typeof(CS.XUiMaterialController))
    for i = 0, controllerComponents.Length - 1 do
        local controller = controllerComponents[i]
        controller:SetGrayScale(value, time)
    end
end

-- 设置背景的灰度值
function XMovieActionSetGray:SetBgGray(index, value, time)
    if index == ALL_BG_INDEX then
        self:SetAllBgGray(value, time)
    else
        local bgIndex = index % 1000
        local rImgBg = self.UiRoot.UiMovieBg:GetBg(bgIndex)
        rImgBg:SetGrayScale(value, time)
    end
end

-- 设置所有背景的灰度值
function XMovieActionSetGray:SetAllBgGray(value, time)
    local bgDic = self.UiRoot.UiMovieBg:GetBgDic()
    for _, bg in pairs(bgDic) do
        bg:SetGrayScale(value, time)
    end
end

function XMovieActionSetGray:IsPassedActionRun(index)
    if self.Value == 0 then
        return false
    end

    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionSetGray:IsPassedActionCovered(action)
    return action:GetType() == self:GetType()
end

function XMovieActionSetGray:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionSetGray