---@class XUiGridAnnouncementBtn
local XUiGridAnnouncementBtn = XClass(nil, "XUiGridAnnouncementBtn")

---@desc 公告标签
---@field Activity 活动
---@field Supply 补给
---@field Important 重要
local NoticeTag = {
    Activity = 1,
    Supply = 2,
    Important = 3
}

--- 公告没有子页签，下标默认为 1
local HtmlIndex = 1
local TITLE_MAX_LENGTH = 22 --标题最大容纳字符窜长度


function XUiGridAnnouncementBtn:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridAnnouncementBtn:GetClickBtn()
    return self.BtnTab
end

function XUiGridAnnouncementBtn:Refresh(info)
    if not info then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.Info = info
    self.GameObject:SetActiveEx(true)
    local tag = info.Tag
    self.ImgActivity.gameObject:SetActiveEx(tag == NoticeTag.Activity)
    self.ImgFedd.gameObject:SetActiveEx(tag == NoticeTag.Supply)
    self.ImgImportant.gameObject:SetActiveEx(tag == NoticeTag.Important)
    local title = info.Title
    if XOverseaManager.IsJP_KRRegion() or XOverseaManager.IsENRegion() and string.Utf8LenCustom(title) > TITLE_MAX_LENGTH then
        title = string.Utf8SubCustom(title, 1, TITLE_MAX_LENGTH) .. "..."
    end
    self.BtnTab:SetNameByGroup(0, title)
    self.BtnTab:ShowReddot(XDataCenter.NoticeManager.CheckInGameNoticeRedPointIndividual(info, HtmlIndex))
end

function XUiGridAnnouncementBtn:SetSelect(select)
    self.BtnTab:SetButtonState(select and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

--- 这个方法由动态列表的Touch事件来调用
--- 组件上的XUiButton不激活响应，仅保留它的显示相关的功能
function XUiGridAnnouncementBtn:OnBtnClick()
    local htmlKey = XDataCenter.NoticeManager.GetGameNoticeReadDataKey(self.Info, HtmlIndex)
    XDataCenter.NoticeManager.ChangeInGameNoticeReadStatus(htmlKey, true)
    self.BtnTab:ShowReddot(false)
    
    self:SetSelect(true)
end

return XUiGridAnnouncementBtn