---@class XUiPlotExhibitionDetailStoryGrid : XUiNode
---@field _Control XPlotExhibitionControl
---@field Parent XUiPlotExhibitionDetail
local XUiPlotExhibitionDetailStoryGrid = XClass(XUiNode, "XUiPlotExhibitionDetailStoryGrid")

function XUiPlotExhibitionDetailStoryGrid:OnStart()
    self.BtnPower.gameObject:SetActiveEx(false)
    ---@type XUiComponent.XUiButton
    self._BtnForces = {}
    -- XUiHelper.RegisterClickEvent(self, self.BtnSetFace, self.OnClickSetCover)
    XUiHelper.RegisterClickEvent(self, self.PanelChapter, self.OnClickSkip)
    self.ImgPercentNormal = self.ImgPercentNormal or
    XUiHelper.TryGetComponent(self.Transform, "PanelChapter/Jindutiao/ImgPercentNormal", "Image")
    self.TagNew.gameObject:SetActiveEx(false)
    self.TagLimited.gameObject:SetActiveEx(false)
    self.ImgNew = self.ImgNew or XUiHelper.TryGetComponent(self.Transform, "PanelChapter/ImgNew", "RectTransform")
end

---@param data XPlotExhibitionControlStory
function XUiPlotExhibitionDetailStoryGrid:Update(data)
    self._Data = data
    --self.PanelMemberTitle
    --self.PanelChapter
    self.TxtName.text = data.CharacterName
    --self.ListPower
    self.RimgChapter:SetRawImage(data.StoryBg)
    --self.PanelTag
    self.TxtStoryName1.text = data.StoryName
    --self.TxtStoryName2.text = data.StoryDesc
    self.ImgPercentNormal.fillAmount = data.Progress / 100
    if self.ImgNew then
        self.ImgNew.gameObject:SetActiveEx(data.IsNew)
    end
    -- 成就徽章
    if data.AchievementIcon then
        self.PanelCollection.gameObject:SetActiveEx(true)
        if data.IsAchievementIconUnlock then
            self.RimgCollectionGrey.gameObject:SetActiveEx(false)
            self.RimgCollectionColor.gameObject:SetActiveEx(true)
            self.RimgCollectionColor:SetRawImage(data.AchievementIcon)
        else
            self.RimgCollectionGrey.gameObject:SetActiveEx(true)
            self.RimgCollectionColor.gameObject:SetActiveEx(false)
            self.RimgCollectionGrey:SetRawImage(data.AchievementIcon)
        end
    else
        self.PanelCollection.gameObject:SetActiveEx(false)
    end

    -- 势力
    for i = 1, #data.Force do
        local button = self._BtnForces[i]
        if not button then
            button = XUiHelper.Instantiate(self.BtnPower, self.BtnPower.transform.parent)
            button.gameObject:SetActiveEx(true)
            self._BtnForces[i] = button
            XUiHelper.RegisterClickEvent(self, button, function()
                local force = self._Data.Force[i]
                self._Control:OpenUiForceDetail(force)
            end)
        end
        button.gameObject:SetActiveEx(true)
        local component = button:GetComponent("XUiButton")
        if component then
            --component:SetNameByGroup(0, data.Force[i].Name)
            component:SetSprite(data.Force[i].Logo)
        end
    end
    for i = #data.Force + 1, #self._BtnForces do
        self._BtnForces[i].gameObject:SetActiveEx(false)
    end

    --if data.Progress == 100 then
    --    self.ImgBgGrey1.gameObject:SetActiveEx(false)
    --    self.ImgBgGrey2.gameObject:SetActiveEx(false)
    --    self.ImgBgGreen1.gameObject:SetActiveEx(true)
    --    self.ImgBgGreen2.gameObject:SetActiveEx(true)
    --else
    --    self.ImgBgGrey1.gameObject:SetActiveEx(true)
    --    self.ImgBgGrey2.gameObject:SetActiveEx(true)
    --    self.ImgBgGreen1.gameObject:SetActiveEx(false)
    --    self.ImgBgGreen2.gameObject:SetActiveEx(false)
    --end

    -- 对于肉鸽123456类型，progress显示为空字符串
    local progressText = ""
    if data.StoryType == XEnumConst.FuBen.ChapterType.Theatre
        or data.StoryType == XEnumConst.FuBen.ChapterType.BiancaTheatre
        or data.StoryType == XEnumConst.FuBen.ChapterType.Theatre3
        or data.StoryType == XEnumConst.FuBen.ChapterType.Theatre4
        or data.StoryType == XEnumConst.FuBen.ChapterType.Theatre5
        or data.StoryType == XEnumConst.FuBen.ChapterType.Theatre6 then
        progressText = ""
    else
        progressText = data.Progress .. "%"
    end
    self.PanelChapter:SetNameByGroup(0, progressText)
    self:UpdateCover(data)
end

---@param data XPlotExhibitionControlStory
function XUiPlotExhibitionDetailStoryGrid:UpdateCover(data)
    if data.IsCover then
        self.BtnSetFace:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnSetFace:SetButtonState(CS.UiButtonState.Normal)
    end
end

-- function XUiPlotExhibitionDetailStoryGrid:OnClickSetCover()
-- v4.2 选中cover的逻辑改为在XUiPlotExhibitionPopupCoverChangeGrid中实现
-- self.Parent:UpdateCover()
-- end

function XUiPlotExhibitionDetailStoryGrid:OnClickSkip()
    XMVCA.XMainLine2:RecordEnterChapterWay(XEnumConst.MAINLINE2.ENTER_CHAPTER_WAY_TYPE.PLOT)
    self._Control:SkipToChapter(self._Data)
end

return XUiPlotExhibitionDetailStoryGrid
