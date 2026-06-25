---@class XMovieActionChannelOffsetEnable
---@field UiRoot XUiMovie
local XMovieActionChannelOffsetEnable = XClass(XMovieActionBase, "XMovieActionChannelOffsetEnable")

local TARGET_NORMAL = 1
local TARGET_FULLSCREEN = 2
local TARGET_CENTERTIPS = 3
local TARGET_PANELTEXT = 4
local TARGET_3D = 5

local function ClampChannel(value, channelName)
    if value == nil then
        return nil
    end
    if value < -1 or value > 1 then
        XLog.Error(string.format("ChannelOffset %s 值 %s 超出 [-1, 1] 范围，已重置为 0", channelName, tostring(value)))
        return 0
    end
    return value
end

function XMovieActionChannelOffsetEnable:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.Target = paramToNumber(params[1])
    self.ExpansionScale = string.IsNilOrEmpty(params[2]) and nil or tonumber(params[2])
    self.OffsetMultiplier = string.IsNilOrEmpty(params[3]) and nil or tonumber(params[3])
    if not string.IsNilOrEmpty(params[4]) then
        local rgb = string.Split(params[4], "|")
        self.R = ClampChannel(rgb[1] and tonumber(rgb[1]) or nil, "R")
        self.G = ClampChannel(rgb[2] and tonumber(rgb[2]) or nil, "G")
        self.B = ClampChannel(rgb[3] and tonumber(rgb[3]) or nil, "B")
    end
end

function XMovieActionChannelOffsetEnable:_GetAddons()
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

function XMovieActionChannelOffsetEnable:_ApplyTo(addon)
    if self.ExpansionScale ~= nil then
        addon.ExpansionScale = self.ExpansionScale
    end
    if self.OffsetMultiplier ~= nil then
        addon.ChannelOffsetMultiplier = self.OffsetMultiplier
    end
    if self.R ~= nil then
        addon.ChannelOffsetR = self.R
    end
    if self.G ~= nil then
        addon.ChannelOffsetG = self.G
    end
    if self.B ~= nil then
        addon.ChannelOffsetB = self.B
    end
    addon:Apply()
end

function XMovieActionChannelOffsetEnable:OnRunning()
    if self.Target == TARGET_FULLSCREEN then
        if self.UiRoot then
            self.UiRoot:SetFullScreenChannelOffset(self.ExpansionScale, self.OffsetMultiplier, self.R, self.G, self.B)
        end
        return
    end

    if self.Target == TARGET_PANELTEXT then
        local panel = self.UiRoot and self.UiRoot:GetUiPanelText()
        if panel then
            panel:SetChannelOffset(self.ExpansionScale, self.OffsetMultiplier, self.R, self.G, self.B)
        end
        return
    end

    local addons = self:_GetAddons()
    if not addons then
        return
    end
    for _, addon in ipairs(addons) do
        self:_ApplyTo(addon)
    end
end

function XMovieActionChannelOffsetEnable:GetTarget()
    return self.Target
end

function XMovieActionChannelOffsetEnable:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

---@param action XMovieActionBase
function XMovieActionChannelOffsetEnable:IsPassedActionCovered(action)
    local actionType = action:GetType()
    local enum = XMVCA.XMovie.EnumConst.ACTION_TYPE
    if actionType == enum.CHANNEL_OFFSET_ENABLE or actionType == enum.CHANNEL_OFFSET_DISABLE then
        return action:GetTarget() == self.Target
    end
    return false
end

function XMovieActionChannelOffsetEnable:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionChannelOffsetEnable
