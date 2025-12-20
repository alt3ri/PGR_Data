---@class XUiGridMainLineExhibitionChapter
---@field UiGridModule XUiGridMainLineExhibitionModule
---@field UiPanelExhibition XUiPanelMainLineExhibition
local XUiGridMainLineExhibitionChapter = XClass(nil, "XUiGridMainLineExhibitionChapter")

function XUiGridMainLineExhibitionChapter:Ctor(uiGridModule, uiPanelExhibition, linkGo, chapterId, index)
    self.UiGridModule = uiGridModule
    self.UiPanelExhibition = uiPanelExhibition
    self.LinkGo = linkGo -- 挂点
    self.LinkGoRectTransform = linkGo:GetComponent("RectTransform")
    self.ChapterId = chapterId
    self.Index = index
end

function XUiGridMainLineExhibitionChapter:OnEnable()
    if self:IsLoaded() then
        self:RefreshUi()
    end
end

function XUiGridMainLineExhibitionChapter:OnDisable()
    
end

function XUiGridMainLineExhibitionChapter:OnRelease()
    self.ViewModel = nil
    CS.UnityEngine.Object.Destroy(self.GameObject)
    self.GameObject = nil
    
    self.UiPanelExhibition = nil
    self.LinkGo = nil
    self.Transform = nil
end

function XUiGridMainLineExhibitionChapter:GetLocalPosition()
    return self.LinkGoRectTransform.localPosition
end

function XUiGridMainLineExhibitionChapter:GetWidth()
    return self.LinkGoRectTransform.rect.width
end

-- 是否已经加载完成
function XUiGridMainLineExhibitionChapter:IsLoaded()
    return self._IsLoaded
end

-- 加载格子预制体
function XUiGridMainLineExhibitionChapter:LoadPrefab()
    if self:IsLoaded() then return end
    
    local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(self.ChapterId)
    local grid = self.UiPanelExhibition:GetObject(chapterCfg.UiName)
    local go = XUiHelper.Instantiate(grid, self.LinkGo).gameObject
    go.transform.localPosition = XLuaVector3.New(0, 0, 0)
    go:SetActiveEx(true)
    XUiHelper.InitUiClass(self, go)
    self._IsLoaded = true
    self:OnLoadCompleted()
end

-- 加载完成
function XUiGridMainLineExhibitionChapter:OnLoadCompleted()
    self:RegisterUiEvents()
    self:RefreshNoChangeUi()
    self:RefreshUi()
    
    if not self.UiPanelExhibition.IsShowDetailUi then
        self:SwitchBriefUi()
    end
end

-- 显示预制体
function XUiGridMainLineExhibitionChapter:ShowPrefab()
    self:LoadPrefab()
    self.LinkGo.gameObject:SetActiveEx(true)
end

-- 隐藏预制体
function XUiGridMainLineExhibitionChapter:HidePrefab()
    if self:IsLoaded() then
        self.LinkGo.gameObject:SetActiveEx(false)
    end
end

function XUiGridMainLineExhibitionChapter:RegisterUiEvents()
    self.UiBriefButton = self.UiBrief:GetComponent("XUiButton")
    XUiHelper.RegisterClickEvent(self, self.UiBriefButton, self.OnButtonClick, nil)
    self.UiDetailButton = self.UiDetail:GetComponent("XUiButton")
    XUiHelper.RegisterClickEvent(self, self.UiDetailButton, self.OnButtonClick, nil)
end

function XUiGridMainLineExhibitionChapter:OnButtonClick()
    if self.UiPanelExhibition:IsDragOperation() then return end
    
    -- 播放音效
    if self.AudioObject then
        self.AudioObject:PlayByKeyName("BtnClick")
    end

    -- 上锁提示
    local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(self.ChapterId)
    if chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.CHALLENGE then
        local challengeBannerConfig = XMVCA.XFuben:GetNewChallengeConfigById(chapterCfg.ExhibitionFubenConfigId)
        local functionId = challengeBannerConfig.FunctionId
        if not XFunctionManager.JudgeCanOpen(functionId) then
            XUiManager.TipError(XFunctionManager.GetFunctionOpenCondition(functionId))
            return
        end
    end
    
    local isIgnorePopup = XMVCA.XMainLine2:GetIsIgnoreUiExhibitionPopupChapter()
    if not isIgnorePopup then
        -- 新手动态漫跳转观看提示
        local params = XMVCA.XMainLine2:GetClientConfigParams("NewbiePreChapterSkipCondition")
        local chapterId = tonumber(params[1])
        if chapterId == self.ChapterId then
            local conditionId = tonumber(params[2])
            local ret, desc = XConditionManager.CheckCondition(conditionId)
            if ret then
                XLuaUiManager.Open("UiMainLineExhibitionPopupCG", self.ChapterId, function()
                    self.UiPanelExhibition:SetAreaScaleDragEnable(false)
                end, function()
                    self.UiPanelExhibition:SetAreaScaleDragEnable(true)
                end)
                return
            end
        end
        
        -- 前置章节未完成提示
        local isPreCompleted = XMVCA.XMainLine2:IsExhibitionChapterPreCompleted(self.ChapterId)
        if not isPreCompleted then
            XLuaUiManager.Open("UiMainLineExhibitionPopupChapter", self.ChapterId, function()
                self.UiPanelExhibition:SetAreaScaleDragEnable(false)
            end, function()
                self.UiPanelExhibition:SetAreaScaleDragEnable(true)
            end)
            return
        end
    end

    XMVCA.XMainLine2:RecordEnterChapterWay(XEnumConst.MAINLINE2.ENTER_CHAPTER_WAY_TYPE.EXHIBITION)
    XMVCA.XMainLine2:OpenExhibitionChapter(self.ChapterId)
end

-- 刷新不会变化的UI
function XUiGridMainLineExhibitionChapter:RefreshNoChangeUi()
    local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(self.ChapterId)
    ---@type XChapterViewModel
    local viewModel = self:GetViewModel()
    if viewModel then
        -- 标题
        local name = string.format("%s %s", viewModel:GetExtralName(), chapterCfg.TitleName)
        self:RefreshTitle(name, chapterCfg.SubTitleName)
        -- 背景图
        local iconBg = viewModel:GetIcon()
        self:RefreshRImgBg(chapterCfg, iconBg)
    elseif chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.CHALLENGE then
        -- 多维演绎
        -- 标题
        self:RefreshTitle(chapterCfg.TitleName, chapterCfg.SubTitleName)
        -- 背景图
        local challengeBannerConfig = XMVCA.XFuben:GetNewChallengeConfigById(chapterCfg.ExhibitionFubenConfigId)
        self:RefreshRImgBg(chapterCfg, challengeBannerConfig.Icon)
        -- 隐藏成就
        self:HidePanelAchievement()
        -- 隐藏页签
        self:HidePanelTag()
        -- 隐藏进度
        self:HidePanelProgress()
    end
end

-- 刷新UI
function XUiGridMainLineExhibitionChapter:RefreshUi()
    -- 条件显示
    local isShow = self:IsConditionShow()
    self:SetGridChapterShow(isShow)
    
    local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(self.ChapterId)
    ---@type XChapterViewModel
    local viewModel = self:GetViewModel()
    if viewModel then
        -- 成就
        self:RefreshPanelAchievement(viewModel)
        -- 页签 
        self:RefreshPanelTag(viewModel)
        -- 进度
        self:RefreshPanelProgress(viewModel)
        self:RefreshLockByViewModel(viewModel)
    elseif chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.CHALLENGE then
        -- 上锁
        self:RefreshLock()
    end
    
    -- 蓝点
    local isRed = self:IsShowRed()
    self:RefreshRedPoint(isRed)
    -- 最后通关章节
    local chapterId = XMVCA.XMainLine2:GetLastExhibitionChapterId()
    local isLastEnter = chapterId == self.ChapterId
    self.UiBrief:GetObject("PanelLastPassed").gameObject:SetActiveEx(isLastEnter)
    self.UiDetail:GetObject("PanelLastPassed").gameObject:SetActiveEx(isLastEnter)
end

-- 切换章节详情UI
function XUiGridMainLineExhibitionChapter:SwitchDetailUi()
    if self:IsLoaded() then
        self.UiBrief.gameObject:SetActiveEx(false)
        self.UiDetail.gameObject:SetActiveEx(true)
        XUiHelper.PlayUiNodeAnimation(self.Transform, "QieHuan")
    end
end

-- 切换章节简略UI
function XUiGridMainLineExhibitionChapter:SwitchBriefUi()
    if self:IsLoaded() then
        self.UiBrief.gameObject:SetActiveEx(true)
        self.UiDetail.gameObject:SetActiveEx(false)
        XUiHelper.PlayUiNodeAnimation(self.Transform, "QieHuan")
    end
end

-- 刷新标题
function XUiGridMainLineExhibitionChapter:RefreshTitle(titleName, subTitleName)
    -- 标题
    self.UiDetail:GetObject("TxtName").text = titleName
    -- 副标题
    local panelBranchLine = self.UiDetail:GetObject("PanelBranchLine", false)
    if panelBranchLine then
        local isShowSubTitle = not string.IsNilOrEmpty(subTitleName)
        panelBranchLine.gameObject:SetActiveEx(isShowSubTitle)
        if isShowSubTitle then
            self.UiDetail:GetObject("TxtBranchLineName").text = subTitleName
        end
    end
end

-- 刷新背景图
function XUiGridMainLineExhibitionChapter:RefreshRImgBg(chapterCfg, originBgPath)
    local bgPath = string.IsNilOrEmpty(chapterCfg.BgPath) and originBgPath or chapterCfg.BgPath
    local rImgBgBrief = self.UiBrief:GetObject("RImgBg")
    rImgBgBrief:SetRawImage(bgPath)
    local rImgBgDetail = self.UiDetail:GetObject("RImgBg")
    rImgBgDetail:SetRawImage(bgPath)

    if chapterCfg.BgPosX ~= 0 and chapterCfg.BgPosY ~= 0 then
        local pos = XLuaVector3.New(chapterCfg.BgPosX / 1000, chapterCfg.BgPosY / 1000, 0)
        rImgBgBrief.transform.anchoredPosition = pos
        rImgBgDetail.transform.anchoredPosition = pos
    end
end

function XUiGridMainLineExhibitionChapter:RefreshLockByViewModel(viewModel)
    local isLock = viewModel:GetIsLocked()
    local lockText = viewModel:GetLockTip()
    self.UiBriefButton:SetDisable(isLock)
    self.UiDetailButton:SetDisable(isLock)
    self.UiDetailButton:SetNameByGroup(0, lockText)
end

-- 刷新上锁状态
function XUiGridMainLineExhibitionChapter:RefreshLock()
    local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(self.ChapterId)
    local challengeBannerConfig = XMVCA.XFuben:GetNewChallengeConfigById(chapterCfg.ExhibitionFubenConfigId)
    local lockFun = not XFunctionManager.JudgeCanOpen(challengeBannerConfig.FunctionId)
    local lockSubPackage = not XMVCA.XSubPackage:CheckSubpackageDownloadByFunctionType(challengeBannerConfig.FunctionId)
    local isLock = lockFun or lockSubPackage
    local lockText = XUiHelper.GetText("NecessaryResourcesNotDownloaded")
    if lockFun then
        lockText = XUiHelper.GetText("CommonLockedTip")
    end
    self.UiBriefButton:SetDisable(isLock)
    self.UiDetailButton:SetDisable(isLock)
    self.UiDetailButton:SetNameByGroup(0, lockText)
end

-- 刷新成就
function XUiGridMainLineExhibitionChapter:RefreshPanelAchievement(viewModel)
    local achievementIcon = viewModel:GetAchievementIcon()
    local achievementIconLock = viewModel:GetAchievementIconLock()
    local isShowAchieve = achievementIcon ~= nil
    self.UiDetail:GetObject("PanelAchievement").gameObject:SetActiveEx(isShowAchieve)
    if isShowAchieve then
        local isUnlock = viewModel:IsAchievementUnlock()
        local rImgAchievementGrey = self.UiDetail:GetObject("RImgAchievementGrey")
        local rImgAchievementColor = self.UiDetail:GetObject("RImgAchievementColor")
        rImgAchievementGrey.gameObject:SetActiveEx(not isUnlock)
        rImgAchievementColor.gameObject:SetActiveEx(isUnlock)
        if isUnlock then
            rImgAchievementColor:SetRawImage(achievementIcon)
        else
            rImgAchievementGrey:SetRawImage(achievementIconLock)
        end
    end
end

-- 隐藏成就
function XUiGridMainLineExhibitionChapter:HidePanelAchievement()
    local panelAchievement = self.UiDetail:GetObject("PanelAchievement", false)
    if panelAchievement then
        panelAchievement.gameObject:SetActiveEx(false)
    end
end

-- 刷新页签
function XUiGridMainLineExhibitionChapter:RefreshPanelTag(viewModel)
    local panelTag = self.UiDetail:GetObject("PanelTag", false)
    if not panelTag then return end
    
    local tagImage = self.UiDetail:GetObject("TagImage")
    local tagText = self.UiDetail:GetObject("TagText")
    
    -- 特殊标签
    if viewModel:CheckHasSpecialTag() then
        panelTag.gameObject:SetActiveEx(true)
        tagImage.color = XUiHelper.Hexcolor2Color(XEnumConst.MAINLINE2.MAIN_TAG_COLOR.SPECIAL)
        tagText.text = currentChapter:GetSpecialTagName()

    -- 限时开放页签
    elseif viewModel:CheckHasTimeLimitTag() then
        panelTag.gameObject:SetActiveEx(true)
        tagImage.color = XUiHelper.Hexcolor2Color(XEnumConst.MAINLINE2.MAIN_TAG_COLOR.LIMIT_TIME)
        tagText.text = XUiHelper.GetText("MainLineChapterTimeLimitTag")

    -- 新章节页签，只显示第一个新章节页签
    elseif self.UiPanelExhibition:GetFirstNewTagExhibitionChapterId() == self.ChapterId and viewModel:CheckHasNewTag() then
        panelTag.gameObject:SetActiveEx(true)
        tagImage.color = XUiHelper.Hexcolor2Color(XEnumConst.MAINLINE2.MAIN_TAG_COLOR.NEW)
        tagText.text = XUiHelper.GetText("MainLineChapterNewTag")
    else
        panelTag.gameObject:SetActiveEx(false)
    end
end

-- 隐藏页签
function XUiGridMainLineExhibitionChapter:HidePanelTag()
    local panelTag = self.UiDetail:GetObject("PanelTag", false)
    if panelTag then
        panelTag.gameObject:SetActiveEx(false)
    end
end

-- 刷新完成进度
function XUiGridMainLineExhibitionChapter:RefreshPanelProgress(viewModel)
    local currentProgress, maxProgress = XMVCA.XMainLine2:GetViewModelCurrentAndMaxProgress(viewModel)
    local progress = math.ceil(currentProgress / maxProgress * 100) .. "%"
    
    local isCompleted = currentProgress >= maxProgress
    local uiObjs = { self.UiBrief, self.UiDetail }
    local stateNames = { "Normal", "Press"}
    for _, uiObj in pairs(uiObjs) do
        for _, stateName in pairs(stateNames) do
            local stateUiObj = uiObj:GetObject(stateName)
            stateUiObj:GetObject("ProgressCompleted").gameObject:SetActiveEx(isCompleted)
            stateUiObj:GetObject("ProgressDefault").gameObject:SetActiveEx(not isCompleted)
            if not isCompleted then
                stateUiObj:GetObject("TxtProgressDefault").text = progress
            end
        end
    end
end

-- 刷新红点
function XUiGridMainLineExhibitionChapter:RefreshRedPoint(isRed)
    self.UiBriefButton:ShowReddot(isRed)
    self.UiDetailButton:ShowReddot(isRed)
end

-- 隐藏完成进度
function XUiGridMainLineExhibitionChapter:HidePanelProgress()
    local uiObjs = { self.UiBrief, self.UiDetail }
    local stateNames = { "Normal", "Press"}
    for _, uiObj in pairs(uiObjs) do
        for _, stateName in pairs(stateNames) do
            local stateUiObj = uiObj:GetObject(stateName, false)
            stateUiObj:GetObject("PanelProgress").gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridMainLineExhibitionChapter:GetChapterId()
    return self.ChapterId
end

function XUiGridMainLineExhibitionChapter:GetViewModel()
    if self.ViewModel then
        return self.ViewModel
    end
    
    local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(self.ChapterId)
    local difficult = XDataCenter.FubenManager.DifficultNormal
    
    -- 主线 + 浮点纪实
    if chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.MAINLINE then
        self.ViewModel = XMVCA.XMainLine2:GetExhibitionViewModel(chapterCfg.ExhibitionFubenConfigId)

    -- 外篇旧闻
    elseif chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.EXTRA then
        self.ViewModel = XDataCenter.ExtraChapterManager:ExGetChapterViewModelById(chapterCfg.ExhibitionFubenConfigId, difficult)
    end
    return self.ViewModel
end

function XUiGridMainLineExhibitionChapter:GetProgress()
    local viewModel = self:GetViewModel()
    if viewModel then
        local currentProgress, maxProgress = viewModel:GetCurrentAndMaxProgress()
        return currentProgress, maxProgress
    else
        return 0, 0
    end
end

function XUiGridMainLineExhibitionChapter:IsPassed()
    local currentProgress, maxProgress = self:GetProgress()
    return currentProgress >= maxProgress
end

-- 是否满足显示条件
function XUiGridMainLineExhibitionChapter:IsConditionShow()
    local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(self.ChapterId)
    local conditionId = chapterCfg.ShowConditionId
    if XTool.IsNumberValidEx(conditionId) then
        local isShow, desc = XConditionManager.CheckCondition(conditionId)
        return isShow
    end
    return true
end

-- 设置章节显示
function XUiGridMainLineExhibitionChapter:SetGridChapterShow(isShow)
    self.GameObject:SetActiveEx(isShow)
    local line = self.UiGridModule:GetLine(self.Index - 1)
    if line then
        line.gameObject:SetActiveEx(isShow)
    end
end

-- 是否有新章节标签
function XUiGridMainLineExhibitionChapter:HasNewTag()
    local viewModel = self:GetViewModel()
    return viewModel and viewModel:CheckHasNewTag()
end

-- 是否显示蓝点
function XUiGridMainLineExhibitionChapter:IsShowRed()
    local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(self.ChapterId)
    ---@type XChapterViewModel
    local viewModel = self:GetViewModel()
    if viewModel then
        return viewModel:CheckHasRedPoint()
    elseif chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.CHALLENGE then
        local challengeBannerConfig = XMVCA.XFuben:GetNewChallengeConfigById(chapterCfg.ExhibitionFubenConfigId)
        local managers = XDataCenter.FubenManagerEx.GetManagers(challengeBannerConfig.Type)
        return managers[1]:ExCheckIsShowRedPoint()
    end
    return false
end

return XUiGridMainLineExhibitionChapter