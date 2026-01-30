---@class XBigWorldTeachAgency : XAgency
---@field private _Model XBigWorldTeachModel
local XBigWorldTeachAgency = XClass(XAgency, "XBigWorldTeachAgency")

function XBigWorldTeachAgency:OnInit()
    -- 初始化一些变量
    self._IsIgnoreNotify = false

    self._IsTipsShow = false
end

function XBigWorldTeachAgency:InitRpc()
    self:AddRpc("NotifyBigWorldHelpCourseUnlock", handler(self, self.OnNotifyBigWorldHelpCourseUnlock))
end

function XBigWorldTeachAgency:InitEvent()
    --给新手引导用的事件
    XEventManager.AddEventListener("EVENT_OPEN_BIG_WORLD_TEACH", self.OpenTeachTipUi, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_TIP_CLOSE, self.OnTeachTipClose, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_HELP_COURSE_UNLOCK_TRIGGER, self.OnUnlockTrigger, self)
end

function XBigWorldTeachAgency:RemoveEvent()
    --给新手引导用的事件
    XEventManager.RemoveEventListener("EVENT_OPEN_BIG_WORLD_TEACH", self.OpenTeachTipUi, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_TIP_CLOSE, self.OnTeachTipClose, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_HELP_COURSE_UNLOCK_TRIGGER, self.OnUnlockTrigger, self)
end

function XBigWorldTeachAgency:OnNotifyBigWorldHelpCourseUnlock(data)
    self._Model:AddTeachUnlockServerData(data.Data)

    if not self._IsIgnoreNotify then
        self._Model:AddTeachQueue(data.Data)
        self:TryShowTeach()
    end
end

function XBigWorldTeachAgency:TryShowTeach()
    if XMVCA.XBigWorldGamePlay:IsInGame() and not self._IsTipsShow then
        local data = self._Model:GetTeachFromQueue()

        if data then
            local teachId = data.Id

            if self:CheckTeachIsForce(teachId) then
                return XMVCA.XBigWorldUI:Open("UiBigWorldPopupTeach", teachId)
            else
                self._IsTipsShow = true
                XMVCA.XBigWorldUI:Open("UiBigWorldTeachTips", teachId)
            end
        end
    end
    return false
end

function XBigWorldTeachAgency:UpdateTeachUnlockServerData(teachDatas)
    self._Model:UpdateTeachUnlockServerData(teachDatas)
end

function XBigWorldTeachAgency:RequestBigWorldHelpCourseUnlock(teachId, isRead, isIgnoreNotify)
    local isMask = self:CheckTeachIsForce(teachId)

    self._IsIgnoreNotify = isIgnoreNotify or false
    XNetwork.Call("BigWorldHelpCourseUnlockRequest", {
        CourseId = teachId,
        IsRead = isRead or false,
    }, function(res)
        self._IsIgnoreNotify = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end, nil, nil, nil, not isMask)
end

function XBigWorldTeachAgency:OnUnlockTrigger(type, targetId)
    local dict = self._Model:GetUnlockTriggerDict()
    local typeDict = dict[type]
    if XTool.IsTableEmpty(typeDict) then
        return
    end
    local teachId = typeDict[targetId]
    if not teachId or teachId <= 0 then
        return
    end
    if self:CheckTeachUnlock(teachId) then
        return
    end
    self:RequestBigWorldHelpCourseUnlock(teachId, false, true)
end

function XBigWorldTeachAgency:OnShowTeach(data)
    local teachId = data.TeachId

    if not self._Model:CheckTeachIsUnlock(teachId) then
        self:RequestBigWorldHelpCourseUnlock(teachId)
    end
end

function XBigWorldTeachAgency:OnTeachTipClose()
    self._IsTipsShow = false
end

function XBigWorldTeachAgency:OnOpenTeachPopup(data)
    self:OpenTeachTipUi(data.TeachId)
end

function XBigWorldTeachAgency:CheckTeachIsForce(teachId)
    return self._Model:GetBigWorldHelpCourseIsForceById(teachId)
end

function XBigWorldTeachAgency:CheckHasUnReadTeach()
    local unlockTeach = self._Model:GetTeachUnlockServerDatas()

    if not XTool.IsTableEmpty(unlockTeach) then
        for _, data in ipairs(unlockTeach) do
            if not data.IsRead and not self._Model:GetBigWorldHelpCourseIsHideById(data.Id) then
                return true
            end
        end
    end

    return false
end

function XBigWorldTeachAgency:CheckTeachUnlock(teachId)
    return self._Model:CheckTeachIsUnlock(teachId)
end

function XBigWorldTeachAgency:OpenTeachMainUi()
    XMVCA.XBigWorldUI:Open("UiBigWorldTeachMain")
end

function XBigWorldTeachAgency:OpenTeachTipUi(teachId)
    if not teachId then
        return
    end
    teachId = tonumber(teachId)
    if XTool.IsNumberValid(teachId) then
        if not self:CheckTeachUnlock(teachId) then
            self:RequestBigWorldHelpCourseUnlock(teachId, false, true)
        end

        XMVCA.XBigWorldUI:Open("UiBigWorldPopupTeach", teachId)
    end
end

return XBigWorldTeachAgency
