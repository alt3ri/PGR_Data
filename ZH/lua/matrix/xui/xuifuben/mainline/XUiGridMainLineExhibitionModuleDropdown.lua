local XUiGridMainLineExhibitionModuleDropdown = XClass(nil, "XUiGridMainLineExhibitionModuleDropdown")

function XUiGridMainLineExhibitionModuleDropdown:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
end

function XUiGridMainLineExhibitionModuleDropdown:Refresh(moduleConfig, isSelect)
    local state = isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.UiButton:SetButtonState(state)
    self.UiButton.TempState = state
    
    -- 名称
    self.TxtName.text = moduleConfig.Name
    -- 进度
    local currentProgress, maxProgress = XMVCA.XMainLine2:GetExhibitionModuleProgress(moduleConfig.Id)
    self.TxtProgress.text = math.floor(currentProgress / maxProgress * 100) .. "%"
    
    -- 页签
    self:RefreshPanelTag(moduleConfig)
    
    -- 蓝点
    local module = self.Parent.UiPanelExhibition:GetModuleByModuleId(moduleConfig.Id)
    local isRed = module:IsShowRed()
    self.UiButton:ShowReddot(isRed)
end

-- 刷新页签
function XUiGridMainLineExhibitionModuleDropdown:RefreshPanelTag(moduleConfig)
    for _, chapterId in ipairs(moduleConfig.ChapterIds) do
        local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(chapterId)
        if chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.MAINLINE then
            local viewModel = XMVCA.XMainLine2:GetExhibitionViewModel(chapterCfg.ExhibitionFubenConfigId)
            
            if viewModel:CheckHasSpecialTag() then
                -- 特殊标签
                self.PanelTag.gameObject:SetActiveEx(true)
                self.TagImage.color = XUiHelper.Hexcolor2Color(XEnumConst.MAINLINE2.MAIN_TAG_COLOR.SPECIAL)
                self.TagText.text = currentChapter:GetSpecialTagName()
                return
                
            elseif viewModel:CheckHasTimeLimitTag() then
                -- 限时开放页签
                self.PanelTag.gameObject:SetActiveEx(true)
                self.TagImage.color = XUiHelper.Hexcolor2Color(XEnumConst.MAINLINE2.MAIN_TAG_COLOR.LIMIT_TIME)
                self.TagText.text = XUiHelper.GetText("MainLineChapterTimeLimitTag")
                return

            elseif self.Parent.UiPanelExhibition:GetFirstNewTagExhibitionChapterId() == chapterId and viewModel:CheckHasNewTag() then
                -- 新章节页签
                self.PanelTag.gameObject:SetActiveEx(true)
                self.TagImage.color = XUiHelper.Hexcolor2Color(XEnumConst.MAINLINE2.MAIN_TAG_COLOR.NEW)
                self.TagText.text = XUiHelper.GetText("MainLineChapterNewTag")
                return
            end
        end
    end
    self.PanelTag.gameObject:SetActiveEx(false)
end

return XUiGridMainLineExhibitionModuleDropdown
