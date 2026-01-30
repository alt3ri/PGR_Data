-- 邀请弹窗
---@class XUiDlcRelinkPopupInvitation : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupInvitation = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupInvitation")

local MenuType = {
    Main = 1,
    Second = 2,
    Calendar = 3,
}

local UI_NAMES = {
    MAIN = "UiMain",
    DLC_RELINK = { "UiDlcRelinkMain", "UiDlcRelinkRoom" },
}

function XUiDlcRelinkPopupInvitation:OnAwake()
    self:RegisterUiEvents()
end

---@param inviteData XChatData 邀请数据
function XUiDlcRelinkPopupInvitation:OnStart(inviteData)
    self.InviteData = inviteData
    self.IsStartTimer = false
end

function XUiDlcRelinkPopupInvitation:OnEnable()
    if not self.InviteData or not self.InviteData.Content then
        self:OnClose()
        return
    end

    self.TxtChpaterName.text = XMVCA.XDlcRelink:ExGetName()
    self.TxtName.text = self.InviteData.NickName

    -- 只显示头像，不用显示头像框
    if self.RImgHead and XTool.IsNumberValidEx(self.InviteData.Icon) then
        local info = XPlayerManager.GetHeadPortraitInfoById(self.InviteData.Icon)
        if info then
            self.RImgHead:SetRawImage(info.ImgSrc)
        end
    end

    self:CheckShowPanel()
end

function XUiDlcRelinkPopupInvitation:OnGetEvents()
    return {
        CS.XEventId.EVENT_UI_ENABLE,
        CS.XEventId.EVENT_UI_DISABLE,
        XEventId.EVENT_MOVIE_BEGIN,
        XEventId.EVENT_MOVIE_END,
        CS.XEventId.EVENT_VIDEO_ACTION_PLAY,
        CS.XEventId.EVENT_VIDEO_ACTION_STOP,
    }
end

function XUiDlcRelinkPopupInvitation:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_HIDE_INVITE,
        XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_BEGIN,
        XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_BREAK,
        XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_END,
        XEventId.EVENT_MAINUI_RIGHT_MENU_STATUS_CHANGE,
        XEventId.EVENT_FUNCTION_EVENT_END,
        XEventId.EVENT_DLC_CLEAR_INVITE,
    }
end

function XUiDlcRelinkPopupInvitation:OnNotify(event, ...)
    local args = { ... }
    -- 需要重新检查显示状态的事件
    if self:IsRefreshEvent(event) then
        self:CheckShowPanel()
        return
    end
    -- UI 启用/禁用事件
    if event == CS.XEventId.EVENT_UI_ENABLE or event == CS.XEventId.EVENT_UI_DISABLE then
        self:HandleUiStateChange(args[1])
        return
    end
    -- 强制隐藏事件
    if event == XEventId.EVENT_DLC_HIDE_INVITE or event == XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_BEGIN then
        self:SetPanelActive(false)
        return
    end
    -- 主界面菜单状态改变
    if event == XEventId.EVENT_MAINUI_RIGHT_MENU_STATUS_CHANGE then
        self:SetPanelActive(args[1] == MenuType.Main)
        return
    end
    -- 清除邀请事件
    if event == XEventId.EVENT_DLC_CLEAR_INVITE then
        self:OnClose()
    end
end

-- 判断是否为需要刷新显示状态的事件
function XUiDlcRelinkPopupInvitation:IsRefreshEvent(event)
    return event == XEventId.EVENT_MOVIE_BEGIN
        or event == XEventId.EVENT_MOVIE_END
        or event == CS.XEventId.EVENT_VIDEO_ACTION_PLAY
        or event == CS.XEventId.EVENT_VIDEO_ACTION_STOP
        or event == XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_BREAK
        or event == XEventId.EVENT_MAIN_SCENE_ANIM_PLAY_END
        or event == XEventId.EVENT_FUNCTION_EVENT_END
end

-- 处理 UI 状态变化
function XUiDlcRelinkPopupInvitation:HandleUiStateChange(uiObject)
    if not uiObject or not uiObject.UiData then
        return
    end
    local uiType = uiObject.UiData.UiType
    local uiName = uiObject.UiData.UiName
    -- 只处理 Normal 或 NormalPopup 类型的 UI
    if not (uiType == CS.XUiType.Normal or uiType == CS.XUiType.NormalPopup) then
        return
    end
    -- 忽略自身的 UI 状态变化
    if uiName == self.Name then
        return
    end
    self:CheckShowPanel()
end

-- 检查是否有特殊场景阻止显示
function XUiDlcRelinkPopupInvitation:ShouldHideInSpecialScenes()
    return CS.XFight.IsRunning
        or XDataCenter.MovieManager.IsPlayingMovie()
        or XHomeSceneManager.IsInHomeScene()
        or XMVCA.XFavorability:CheckCurSceneAnimIsPlaying()
        or XDataCenter.FunctionEventManager.IsPlaying()
end

-- 检查并更新邀请弹窗显示状态
function XUiDlcRelinkPopupInvitation:CheckShowPanel()
    -- 特殊场景下隐藏邀请弹窗
    if self:ShouldHideInSpecialScenes() then
        self:SetPanelActive(false)
        return
    end
    -- UiMain 需要特殊处理，检查是否显示主界面
    if XUiManager.CheckTopUi(CsXUiType.Normal, UI_NAMES.MAIN) then
        local luaUi = XLuaUiManager.GetTopLuaUi(UI_NAMES.MAIN)
        local show = luaUi and luaUi.IsShowMain and luaUi:IsShowMain() or false
        self:SetPanelActive(show)
        return
    end
    -- 其他界面：获取栈顶 Normal 类型的 UI 名称
    local topUiName = XLuaUiManager.GetUIStackTopUiName()
    if not topUiName then
        self:SetPanelActive(false)
        return
    end
    -- 如果栈顶 UI 是 DLC_RELINK 里的任意一个，则显示邀请弹窗
    local isInDlcRelinkUi = false
    for _, name in ipairs(UI_NAMES.DLC_RELINK) do
        if topUiName == name then
            isInDlcRelinkUi = true
            break
        end
    end
    self:SetPanelActive(isInDlcRelinkUi)
end

function XUiDlcRelinkPopupInvitation:SetPanelActive(isActive)
    self.PanelInvite.gameObject:SetActiveEx(isActive)
    if isActive and not self.IsStartTimer then
        self.IsStartTimer = true
        self:StartTimer()
    end
end

function XUiDlcRelinkPopupInvitation:StartTimer()
    if self.Timer then
        self:StopTimer()
    end

    local showTime = XMVCA.XDlcRoom:GetInviteShowTime()
    self.Timer = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:StopTimer()
            return
        end
        self:OnClose()
    end, XScheduleManager.SECOND * showTime)
end

function XUiDlcRelinkPopupInvitation:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiDlcRelinkPopupInvitation:OnClose()
    self:StopTimer()
    XLuaUiManager.CloseWithCallback(self.Name, function()
        XMVCA.XDlcRoom:CheckReceiveInvitation(true)
    end)
end

-- 关闭弹窗并标记消息已读
function XUiDlcRelinkPopupInvitation:CloseAndReadMessage()
    if self.InviteData then
        XDataCenter.ChatManager.SetPrivateChatReadByFriendIdAndMessageId(self.InviteData.SenderId, self.InviteData.MessageId)
    end
    self:OnClose()
end

function XUiDlcRelinkPopupInvitation:RegisterUiEvents()
    self.BtnSure:AddEventListener(handler(self, self.OnBtnSureClick))
    self.BtnCancel:AddEventListener(handler(self, self.OnBtnCancelClick))
end

-- 确认按钮点击事件
function XUiDlcRelinkPopupInvitation:OnBtnSureClick()
    if not self.InviteData or not self.InviteData.Content then
        self:CloseAndReadMessage()
        return
    end

    local params = XChatData.DecodeRoomMsg(self.InviteData.Content)
    if not params then
        self:CloseAndReadMessage()
        return
    end

    local worldId = tonumber(params[3])
    local roomId = params[4]
    local nodeId = params[7]
    local levelId = tonumber(params[8])
    XMVCA.XDlcRoom:ClickEnterRoomHref(roomId, nodeId, worldId, levelId, self.InviteData.CreateTime)
    self:CloseAndReadMessage()
end

-- 取消按钮点击事件
function XUiDlcRelinkPopupInvitation:OnBtnCancelClick()
    self:CloseAndReadMessage()
end

return XUiDlcRelinkPopupInvitation
