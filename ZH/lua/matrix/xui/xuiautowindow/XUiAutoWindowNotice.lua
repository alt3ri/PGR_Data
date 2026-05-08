---拍脸图公告界面
---@class XUiAutoWindowNotice : XLuaUi
local XUiAutoWindowNotice = XLuaUiManager.Register(XLuaUi, "UiAutoWindowNotice")

local JumpType = {
    Web = 1,
    Game = 2,
}

function XUiAutoWindowNotice:OnAwake()
    self:RegisterUiEvents()
end

---@param contentData XPopUpPicNoticeContent 单条拍脸图公告内容
function XUiAutoWindowNotice:OnStart(contentData)
    self.ContentData = contentData
    self:RefreshView()
    self.IsSkip = false
end

function XUiAutoWindowNotice:OnDestroy()
    if self.IsSkip then
        return
    end
    XDataCenter.NoticeManager.ShowNextPopUpPicNotice()
end

function XUiAutoWindowNotice:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self.BtnBigSkin:AddEventListener(handler(self, self.OnBtnSkipClick))
end

---加载并展示拍脸图
function XUiAutoWindowNotice:RefreshView()
    if not self.ContentData then
        return
    end

    self.PanelBigSkin.gameObject:SetActiveEx(false)
    self.PanelBarSkin.gameObject:SetActiveEx(false)
    self.PanelSpineSkin.gameObject:SetActiveEx(false)
    self.PanelNotOpen.gameObject:SetActive(false)
    self.PanelOpen.gameObject:SetActive(false)

    -- 加载拍脸图图片
    local picAddr = self.ContentData.PicAddr
    if not string.IsNilOrEmpty(picAddr) then
        XDataCenter.NoticeManager.LoadPicFromLocal(picAddr, function(texture)
            if XTool.UObjIsNil(self.GameObject) or not texture then
                return
            end
            self.PanelBigSkin.gameObject:SetActiveEx(true)
            self.RImgBgNormal:SetRawImageTexture(texture)
            self.RImgBgPress:SetRawImageTexture(texture)
        end)
    end
end

function XUiAutoWindowNotice:OnBtnBackClick()
    self:Close()
end

-- 根据 JumpType 进行不同的跳转
function XUiAutoWindowNotice:OnBtnSkipClick()
    if not self.ContentData then
        return
    end

    local jumpAddr = self.ContentData.JumpAddr
    if string.IsNilOrEmpty(jumpAddr) then
        return
    end

    local jumpType = tonumber(self.ContentData.JumpType)
    if jumpType == JumpType.Web then
        CS.UnityEngine.Application.OpenURL(jumpAddr)
    elseif jumpType == JumpType.Game then
        local skipId = tonumber(jumpAddr)
        if XTool.IsNumberValid(skipId) then
            XFunctionManager.SkipInterface(skipId)
        end
    end

    self.IsSkip = true
    XDataCenter.NoticeManager.StopPopUpPicNotice()
    self:Close()
end

return XUiAutoWindowNotice
