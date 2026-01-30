---@class XUiMainLineLuosaitaPopupFileDetail : XLuaUi
---@field _Control XMainLineLuosaitaControl
local XUiMainLineLuosaitaPopupFileDetail = XLuaUiManager.Register(XLuaUi, "UiMainLineLuosaitaPopupFileDetail")

function XUiMainLineLuosaitaPopupFileDetail:OnAwake()
    self:RegisterUiEvents()
end

function XUiMainLineLuosaitaPopupFileDetail:OnStart(sectionId, docId, closeCb)
    self.SectionId = sectionId
    self.DocId = docId
    self.CloseCb = closeCb
end

function XUiMainLineLuosaitaPopupFileDetail:OnEnable()
    self:Refresh()
end

function XUiMainLineLuosaitaPopupFileDetail:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnYes, self.OnBtnCloseClick)
end

function XUiMainLineLuosaitaPopupFileDetail:OnBtnCloseClick()
    local sectionInfo = self._Control:GetSectionInfo(self.SectionId)
    local docId = sectionInfo:GetUnUseDocId()
    if docId and self.DocId ~= docId then
        self.DocId = docId
        self:Refresh()
        -- TODO 切换下一个文件动画
        return
    end

    local cb = self.CloseCb
    XLuaUiManager.CloseWithCallback("UiMainLineLuosaitaPopupFileDetail", function()
        if cb then cb() end
    end)
end

-- 刷新界面
function XUiMainLineLuosaitaPopupFileDetail:Refresh()
    local docConfig = self._Control:GetConfig():GetConfigDocument(self.DocId)
    self.RImgIcon:SetRawImage(docConfig.Icon)
    self.TxtTitle.text = docConfig.PopUpTitle
    self.TxtName.text = docConfig.PopUpName
    self.TxtStory.text = docConfig.PopUpDesc
    
    -- 请求使用
    local sectionInfo = self._Control:GetSectionInfo(self.SectionId)
    if not sectionInfo:IsDocUse(self.DocId) then
        XMVCA.XMainLineLuosaita:RequestMainLineLuosaitaUseDoc(self.SectionId, self.DocId)
    end

    -- 增加文件回顾蓝点
    local docType = self._Control:GetConfig():GetDocumentType(self.DocId)
    if docType == XMVCA.XMainLineLuosaita.EnumConst.DOCUMENT_TYPE.STORY then
        self._Control:SetDocumentReviewRed(true)
    end
end

return XUiMainLineLuosaitaPopupFileDetail