local CSInstantiate = CS.UnityEngine.Object.Instantiate
local stringFormat = string.format
local tableInsert = table.insert
local ipairs = ipairs

---@class XUiMainLineLuosaitaPopupReview : XLuaUi
---@field _Control XMainLineLuosaitaControl
local XUiMainLineLuosaitaPopupReview = XLuaUiManager.Register(XLuaUi, "UiMainLineLuosaitaPopupReview")

function XUiMainLineLuosaitaPopupReview:OnAwake()
	self.ContentLocalPosition = self.Content.localPosition
	self.GridFile.gameObject:SetActiveEx(false)
	self:RegisterUiEvents()
end

function XUiMainLineLuosaitaPopupReview:OnStart(sectionId)
	self.SectionId = sectionId
	self.UnlockSectionIds = self._Control:GetUnlockSectionIds()
	self.Index = self:GetSectionIndex(self.UnlockSectionIds, self.SectionId)
	self.DocUiObjs = {}
	self.OpenTimestamp = XTime.GetServerNowTimestamp()
	self:Refresh()
end

function XUiMainLineLuosaitaPopupReview:OnDestroy()
	local closeTimestamp = XTime.GetServerNowTimestamp()
	local dict = {}
	dict["time"] = closeTimestamp - self.OpenTimestamp
	CS.XRecord.Record(dict, "900015", "LuosaitaReview")
end

function XUiMainLineLuosaitaPopupReview:RegisterUiEvents()
	self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
	self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
	self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick)
end

function XUiMainLineLuosaitaPopupReview:OnBtnCloseClick()
	self:Close()
end

function XUiMainLineLuosaitaPopupReview:OnBtnLeftClick()
	if self.Index <= 1 then return end
	
	self.Index = self.Index - 1
	self.SectionId = self.UnlockSectionIds[self.Index]
	self:Refresh()
end

function XUiMainLineLuosaitaPopupReview:OnBtnRightClick()
	if self.Index >= #self.UnlockSectionIds then return end

	self.Index = self.Index + 1
	self.SectionId = self.UnlockSectionIds[self.Index]
	self:Refresh()
end

function XUiMainLineLuosaitaPopupReview:Refresh()
	self.BtnLeft.gameObject:SetActiveEx(self.Index > 1)
	self.BtnRight.gameObject:SetActiveEx(self.Index < #self.UnlockSectionIds)
	
	self.TxtSection.text = self._Control:GetConfig():GetSectionName(self.SectionId)
	self:RefreshDocList()
end

function XUiMainLineLuosaitaPopupReview:RefreshDocList()
	local sectionInfo = self._Control:GetSectionInfo(self.SectionId)
	local docIds = {}
	if sectionInfo and sectionInfo:IsFinish() then
		docIds = self._Control:GetSectionDocIds(self.SectionId)
	elseif sectionInfo then
		docIds = sectionInfo:GetUnlockDocIds()
	end
	
	-- 筛选文件类型
	local newDocIds = {}
	for _, docId in ipairs(docIds) do
		local docType = self._Control:GetConfig():GetDocumentType(docId)
		if docType == XMVCA.XMainLineLuosaita.EnumConst.DOCUMENT_TYPE.STORY then
			tableInsert(newDocIds, docId)
		end
	end
	docIds = newDocIds
	
	-- 刷新
	for _, uiObj in ipairs(self.DocUiObjs) do
		uiObj.gameObject:SetActiveEx(false)
	end
	for i, docId in ipairs(docIds) do
		local uiObj = self.DocUiObjs[i]
		if not uiObj then
			local go = CSInstantiate(self.GridFile.gameObject, self.GridFile.transform.parent)
			uiObj = go:GetComponent("UiObject")
			tableInsert(self.DocUiObjs, uiObj)
		end
		uiObj.gameObject:SetActiveEx(true)
		
		local docConfig = self._Control:GetConfig():GetConfigDocument(docId)
		uiObj:GetObject("RImgIcon"):SetRawImage(docConfig.Icon)
		uiObj:GetObject("TxtName").text = docConfig.Name
		uiObj:GetObject("TxtDesc").text = XUiHelper.ReplaceTextNewLine(docConfig.Desc)
		local isUnlock = sectionInfo:IsDocUnlock(docId)
		uiObj:GetObject("PanelLock").gameObject:SetActiveEx(not isUnlock)
		local numberOrderString = self._Control:GetConfig():GetConfigString("NumberOrder", 1)
		uiObj:GetObject("TxtTag").text = stringFormat(numberOrderString, tostring(i))
	end
	self.Content.localPosition = self.ContentLocalPosition
	
	-- 没有文件提示
	self.PanelNone.gameObject:SetActiveEx(#docIds == 0)
end

function XUiMainLineLuosaitaPopupReview:GetSectionIndex(unlockSectionIds, sectionId)
	for i, id in ipairs(unlockSectionIds) do
		if id == sectionId then
			return i
		end
	end
end

return XUiMainLineLuosaitaPopupReview