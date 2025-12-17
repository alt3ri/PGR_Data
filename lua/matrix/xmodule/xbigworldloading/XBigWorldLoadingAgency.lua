---@class XBigWorldLoadingAgency : XAgency
---@field private _Model XBigWorldLoadingModel
local XBigWorldLoadingAgency = XClass(XAgency, "XBigWorldLoadingAgency")

function XBigWorldLoadingAgency:OnInit()
    -- 初始化一些变量

    self.LoadingType = {
        ImageMask = 1, -- 图片加载
        BlackTransition = 2, -- 带动画黑幕
        BlackMask = 3, -- 纯黑幕
    }

    self._CurrentOpenType = false
end

function XBigWorldLoadingAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
end

function XBigWorldLoadingAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XBigWorldLoadingAgency:OnRelease()
    self._CurrentOpenType = false
end

function XBigWorldLoadingAgency:OpenBlackTransitionLoading()
    if self._CurrentOpenType then
        XLog.Error("Loading Has Been Turned On! Current Type = " .. tostring(self._CurrentOpenType))
        return
    end

    self._CurrentOpenType = self.LoadingType.BlackTransition
    XMVCA.XBigWorldUI:Open("UiBigWorldShowLoading")
end

function XBigWorldLoadingAgency:CloseBlackTransitionLoading(callback)
    XMVCA.XBigWorldUI:Close("UiBigWorldShowLoading", callback)
    self._CurrentOpenType = false
end

function XBigWorldLoadingAgency:OpenImageMaskLoading(groupId)
    if self._CurrentOpenType then
        XLog.Error("Loading Has Been Turned On! Current Type = " .. tostring(self._CurrentOpenType))
        return
    end

    if XTool.IsNumberValid(groupId) then
        local groupType = self._Model:GetLoadingTypeByGroupId(groupId)

        if groupType == self.LoadingType.ImageMask then
            local config = self._Model:GetRandomLoadingByGroupId(groupId)

            self._CurrentOpenType = self.LoadingType.ImageMask
            XMVCA.XBigWorldUI:Open("UiBigWorldLoading", config)
        else
            XLog.Error("Open LoadingType Error!")
        end
    else
        XLog.Error("Open ImageMask Loading worldId or levelId is invalid!")
    end
end

function XBigWorldLoadingAgency:CloseImageMaskLoading(callback)
    XMVCA.XBigWorldUI:Close("UiBigWorldLoading", callback)
    self._CurrentOpenType = false
end

function XBigWorldLoadingAgency:OpenBlackMaskLoading(enableFinishCb, disableFinishCb)
    if self._CurrentOpenType then
        XLog.Error("Loading Has Been Turned On! Current Type = " .. tostring(self._CurrentOpenType))
        return
    end

    self._CurrentOpenType = self.LoadingType.BlackMask
    XMVCA.XBigWorldUI:Open("UiBigWorldBlackMaskLoading", enableFinishCb, disableFinishCb)
end

function XBigWorldLoadingAgency:CloseBlackMaskLoading()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BLACK_MASK_LOADING_CLOSE)
    self._CurrentOpenType = false
end

function XBigWorldLoadingAgency:OpenLoadingByType(loadingType, ...)
    if loadingType == self.LoadingType.ImageMask then
        self:OpenImageMaskLoading(...)
    elseif loadingType == self.LoadingType.BlackTransition then
        self:OpenBlackTransitionLoading()
    elseif loadingType == self.LoadingType.BlackMask then
        self:OpenBlackMaskLoading(...)
    end
end

function XBigWorldLoadingAgency:CloseLoadingByType(loadingType, callback)
    if loadingType == self.LoadingType.ImageMask then
        self:CloseImageMaskLoading(callback)
    elseif loadingType == self.LoadingType.BlackTransition then
        self:CloseBlackTransitionLoading(callback)
    elseif loadingType == self.LoadingType.BlackMask then
        self:CloseBlackMaskLoading(callback)
    end
end

function XBigWorldLoadingAgency:OpenLoadingByGroupId(groupId)
    local loadingType = self._Model:GetLoadingTypeByGroupId(groupId)

    if XTool.IsNumberValid(loadingType) then
        self:OpenLoadingByType(loadingType, groupId)
    else
        XLog.Error("Open Loading Error! Can Not Find LoadingType, GroupId = " .. tostring(groupId))
    end
end

function XBigWorldLoadingAgency:CloseLoadingByGroupId(groupId, callback)
    local loadingType = self._Model:GetLoadingTypeByGroupId(groupId)

    if XTool.IsNumberValid(loadingType) then
        self:CloseLoadingByType(loadingType, callback)
    else
        XLog.Error("Close Loading Error! Can Not Find LoadingType, GroupId = " .. tostring(groupId))
    end
end

function XBigWorldLoadingAgency:CloseCurrentLoading(callback)
    if self._CurrentOpenType then
        self:CloseLoadingByType(self._CurrentOpenType, callback)
        self._CurrentOpenType = false
    end
end

function XBigWorldLoadingAgency:OnCmdOpenLoading(data)
    if data then
        local loadingType = data.LoadingType
        local args = data.Args
        
        if XTool.IsNumberValid(loadingType) then
            if not XTool.IsTableEmpty(args) then
                self:OpenLoadingByType(loadingType, table.unpack(args))
            else
                self:OpenLoadingByType(loadingType)
            end
        end
    end
end

function XBigWorldLoadingAgency:OnCmdCloseLoading(data)
    if data then
        local loadingType = data.LoadingType
        local callback = data.Callback
        
        if XTool.IsNumberValid(loadingType) then
            self:CloseLoadingByType(loadingType, callback)
        else
            self:CloseCurrentLoading(callback)
        end
    else
        self:CloseCurrentLoading()
    end
end

return XBigWorldLoadingAgency
