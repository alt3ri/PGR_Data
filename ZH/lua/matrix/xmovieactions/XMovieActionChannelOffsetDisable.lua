---@class XMovieActionChannelOffsetDisable
---@field UiRoot XUiMovie
local XMovieActionChannelOffsetDisable = XClass(XMovieActionBase, "XMovieActionChannelOffsetDisable")

local TARGET_NORMAL = 1
local TARGET_FULLSCREEN = 2
local TARGET_CENTERTIPS = 3
local TARGET_PANELTEXT = 4
local TARGET_3D = 5

function XMovieActionChannelOffsetDisable:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.Target = paramToNumber(params[1])
end

function XMovieActionChannelOffsetDisable:_GetAddons()
    local txtList
    if self.Target == TARGET_NORMAL then
        txtList = { self.UiRoot and self.UiRoot.TxtWords }
    elseif self.Target == TARGET_3D then
        txtList = { self.UiRoot and self.UiRoot.Panel3D and self.UiRoot.Panel3D.TxtWords }
    elseif self.Target == TARGET_CENTERTIPS then
        txtList = {
            self.UiRoot and self.UiRoot.TxtCenterTipDescMid,
            self.UiRoot and self.UiRoot.TxtCenterTipDescLeft,
        }
    else
        XLog.Error(string.format("ChannelOffset 非法 Target=%s", tostring(self.Target)))
        return nil
    end

    local addons = {}
    for _, txt in ipairs(txtList) do
        if not XTool.UObjIsNil(txt) then
            local addon = txt:GetComponent("XChannelOffsetTextAddon")
            if not XTool.UObjIsNil(addon) then
                addons[#addons + 1] = addon
            end
        end
    end
    return addons
end

function XMovieActionChannelOffsetDisable:OnRunning()
    if self.Target == TARGET_FULLSCREEN then
        if self.UiRoot then
            self.UiRoot:ClearFullScreenChannelOffset()
        end
        return
    end

    if self.Target == TARGET_PANELTEXT then
        local panel = self.UiRoot and self.UiRoot:GetUiPanelText()
        if panel then
            panel:ClearChannelOffset()
        end
        return
    end

    local addons = self:_GetAddons()
    if not addons then
        return
    end
    for _, addon in ipairs(addons) do
        addon:Revert()
    end
end

function XMovieActionChannelOffsetDisable:GetTarget()
    return self.Target
end

function XMovieActionChannelOffsetDisable:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

---@param action XMovieActionBase
function XMovieActionChannelOffsetDisable:IsPassedActionCovered(action)
    local actionType = action:GetType()
    local enum = XMVCA.XMovie.EnumConst.ACTION_TYPE
    if actionType == enum.CHANNEL_OFFSET_ENABLE or actionType == enum.CHANNEL_OFFSET_DISABLE then
        return action:GetTarget() == self.Target
    end
    return false
end

function XMovieActionChannelOffsetDisable:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionChannelOffsetDisable
