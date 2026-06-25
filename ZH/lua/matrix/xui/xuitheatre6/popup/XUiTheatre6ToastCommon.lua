--- Theatre6模块内部使用的通用Toast提示窗口
---@class XUiTheatre6ToastCommon: XLuaUi
local XUiTheatre6ToastCommon = XLuaUiManager.Register(XLuaUi, 'UiTheatre6ToastCommon')

local TIP_MSG_SHOW_TIME = 2000

function XUiTheatre6ToastCommon:OnAwake()
    self:InitAutoScript()
end

function XUiTheatre6ToastCommon:OnStart(msg, cb, hideCloseMark)
    self.Cb = cb
    self.closeState = false
    self.BtnClose.interactable = true
    self.BtnClose.gameObject:SetActive(not hideCloseMark)

    XUiHelper.StopAnimation()
    self.PanelTip.gameObject:SetActive(true)
    self:PlayAnimation("PanelTip")
    self.TxtInfo.text = msg

    local pop = function()
        self:Close()
    end

    local closeFunc = function()
        if not XTool.UObjIsNil(self.GameObject) then
            self:PlayAnimation("PanelTipEnd", pop)
        end
    end

    self.CloseFunc = closeFunc
    self.Timer = XScheduleManager.ScheduleOnce(function()
        if not self.closeState then
            self.closeState = true
            closeFunc()
        end
    end, TIP_MSG_SHOW_TIME)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiTheatre6ToastCommon:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiTheatre6ToastCommon:AutoInitUi()
    self.BtnClose = self.Transform:Find("SafeAreaContentPane/BtnClose"):GetComponent(typeof(CS.UnityEngine.UI.Button))
    self.PanelTip = self.Transform:Find("SafeAreaContentPane/PanelTip")
    self.TxtInfo = self.Transform:Find("SafeAreaContentPane/PanelTip/TxtInfo"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    self.PanelError = self.Transform:Find("SafeAreaContentPane/PanelError")
    self.PanelSuccess = self.Transform:Find("SafeAreaContentPane/PanelSuccess")
    self.PanelError.gameObject:SetActiveEx(false)
    self.PanelSuccess.gameObject:SetActiveEx(false)
end

function XUiTheatre6ToastCommon:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiTheatre6ToastCommon:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiTheatre6ToastCommon:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiTheatre6ToastCommon:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterListener(self.BtnClose, "onClick", self.OnBtnCloseClick)
end
-- auto

function XUiTheatre6ToastCommon:OnBtnCloseClick()
    if self.closeState then
        return
    end

    self.closeState = true
    XScheduleManager.UnSchedule(self.Timer)
    self.BtnClose.interactable = false
    if self.CloseFunc then
        self:CloseFunc()
    else
        self:Close()
    end
end

function XUiTheatre6ToastCommon:OnDestroy()
    local key = self:GetAutoKey(self.BtnClose, "onClick")
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        self.BtnClose["onClick"]:RemoveListener(listener)
    end
    if self.Cb then
        self.Cb()
    end
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiTheatre6ToastCommon
