local UiNoticeTipsPC = XLuaUiManager.Register(XLuaUi, "UiNoticeTipsPC")

local MoveSpeed = 100
local TextReservedWidth = 60
local HideIntervalTime = 3
local WaitTime = 3

function UiNoticeTipsPC:OnAwake()
    self:InitAutoScript()

    local noticePC = XDataCenter.NoticeManager.GetKRPCNotice()
    self.EndTime = noticePC.EndTime

    if not self.behaviour then
        self.behaviour = self.Transform.gameObject:AddComponent(typeof(CS.XLuaBehaviour))
        self.behaviour.LuaUpdate = function()
            if self.Update then
                self:Update()
            end
        end
    end
end

function UiNoticeTipsPC:OnStart()
    self:RefreshNoticeContent()

    self.TxtNoticeWidth = XUiHelper.CalcTextWidth(self.TxtNotice)
    self.PanelNoticeRect = self.PanelNotice.gameObject:GetComponent("RectTransform")
    self.PauseTime = 0
end

function UiNoticeTipsPC:RefreshNoticeContent()
    local noticePC = XDataCenter.NoticeManager.GetKRPCNotice()
    if not noticePC then
        return
    end
    self.EndTime = noticePC.EndTime
    local noticeContent = CS.XTextManager.GetText("PCplaytimeTip",noticePC.OnlineHour)
    if not noticeContent then
        return
    end
    self.TxtNotice.text = noticeContent
end

function UiNoticeTipsPC:OnNotify(evt)
    if evt == XEventId.EVENT_USER_LOGOUT then
        self:Close()
    end
end

function UiNoticeTipsPC:OnGetEvents()
    return {XEventId.EVENT_NOTICE_CLOSE_TEXT_NOTICE, XEventId.EVENT_USER_LOGOUT}
end

function UiNoticeTipsPC:GetEndPos()
    if self.EndPos then
        return self.EndPos
    end

    self.EndPos = CS.UnityEngine.Vector3((-self.PanelNoticeRect.sizeDelta.x / 2 - self.TxtNoticeWidth / 2), 0, 0)

    return self.EndPos
end

function UiNoticeTipsPC:GetBeginPos()
    local BeginPos
    if self.TxtNoticeWidth > self.PanelNoticeRect.sizeDelta.x then
        BeginPos = CS.UnityEngine.Vector3((self.TxtNoticeWidth - self.PanelNoticeRect.sizeDelta.x) / 2 + TextReservedWidth, 0, 0)
    else
        BeginPos = CS.UnityEngine.Vector3(0, 0, 0)
    end
    return BeginPos
end

function UiNoticeTipsPC:ResetTxtNoticePos()
    if not self.NeedReset then
        return false
    end

    local nowTime = XTime.GetServerNowTimestamp()
    if nowTime >= self.EndTime then
        return true
    end

    self:SetBgActive(true)

    self.TxtNotice.transform.localPosition = self:GetBeginPos()
    self.WaitTime = 0
    self.NeedReset = false

    self:RefreshNoticeContent()

    return false
end

function UiNoticeTipsPC:OnEnable()
    self.NeedReset = true
    self.IsInit = true

    if self:ResetTxtNoticePos() then
        self:Close()
    end
end

function UiNoticeTipsPC:Update()
    if not self.IsInit then
        return
    end

    if self:ResetTxtNoticePos() then
        self:Close()
        return
    end

    if XTool.UObjIsNil(self.TxtNotice) then
        self:Close()
        return
    end

    local timeInterval = CS.UnityEngine.Time.deltaTime
    if self.TxtNotice.transform.localPosition.x <= self:GetEndPos().x then
        if HideIntervalTime <= 1 then
            self:SetBgActive(false)
        end
        if self.PauseTime < 1 then
            self.PauseTime = self.PauseTime + timeInterval
            return
        end

        self.NeedReset = true
        self.PauseTime = 0
    end

    -- 公告刚出来静止一定时间再开始滚动
    if self.WaitTime < WaitTime then
        self.WaitTime = self.WaitTime + timeInterval
        return
    end

    self.TxtNotice.transform.localPosition = self.TxtNotice.transform.localPosition - CS.UnityEngine.Vector3(timeInterval * MoveSpeed, 0, 0)
end

function UiNoticeTipsPC:SetBgActive(flag)
    self.ImgBg.gameObject:SetActive(flag)
    self.BtnClose.gameObject:SetActive(flag)
end

-- auto
-- Automatic generation of code, forbid to edit
function UiNoticeTipsPC:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function UiNoticeTipsPC:AutoInitUi()
    self.PanelNotice = self.Transform:Find("SafeAreaContentPane/PanelNotice")
    self.TxtNotice = self.Transform:Find("SafeAreaContentPane/PanelNotice/TxtNotice"):GetComponent("Text")
    self.ImgBg = self.Transform:Find("SafeAreaContentPane/ImgBg"):GetComponent("Image")
    self.BtnClose = self.Transform:Find("SafeAreaContentPane/BtnClose"):GetComponent("XUiButton")
end

function UiNoticeTipsPC:AutoAddListener()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
end
-- auto

function UiNoticeTipsPC:OnBtnCloseClick()
    self:Close()
end

function UiNoticeTipsPC:OnDestroy()
    if not XTool.UObjIsNil(self.behaviour) then
        CS.UnityEngine.GameObject.Destroy(self.behaviour)
    end

    self.behaviour = nil
end
