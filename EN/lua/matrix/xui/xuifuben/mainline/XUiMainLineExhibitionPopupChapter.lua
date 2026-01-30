---@class XUiMainLineExhibitionPopupChapter:XLuaUi
local XUiMainLineExhibitionPopupChapter = XLuaUiManager.Register(XLuaUi, "UiMainLineExhibitionPopupChapter")

function XUiMainLineExhibitionPopupChapter:OnAwake()
    self.IndexToCharacterGos = {}
    self.IndexToCharacterIds = {}
    self.GridChapter.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiMainLineExhibitionPopupChapter:OnStart(chapterId, enableCb, disableCb)
    self.ChapterId = chapterId
    self.EnableCb = enableCb -- 激活界面的回调
    self.DisableCb = disableCb -- 关闭界面的回调
end

function XUiMainLineExhibitionPopupChapter:OnEnable()
    self:Refresh()

    if self.EnableCb then
        self.EnableCb()
    end
end

function XUiMainLineExhibitionPopupChapter:OnDisable()
    if self.DisableCb then
        self.DisableCb()
    end
end

function XUiMainLineExhibitionPopupChapter:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBgClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnGo, self.OnBtnGoClick)
    self:RegisterClickEvent(self.BtnIgnore, self.OnBtnIgnoreClick)
end

function XUiMainLineExhibitionPopupChapter:OnBtnCloseClick()
    self:Close()
end

function XUiMainLineExhibitionPopupChapter:OnBtnGoClick()
    local chapterId = self.ChapterId
    self:Close()
    XMVCA.XMainLine2:OpenExhibitionChapter(chapterId)
end

function XUiMainLineExhibitionPopupChapter:OnBtnIgnoreClick()
    local isIgnore = XMVCA.XMainLine2:GetIsIgnoreUiExhibitionPopupChapter()
    XMVCA.XMainLine2:SetIgnoreUiExhibitionPopupChapter(not isIgnore)
    self:RefreshBtnIgnore()
end

function XUiMainLineExhibitionPopupChapter:OnPreChapterClick(index)
    local chapterId = self.ShowPreChapterIds[index]
    self:Close()
    XMVCA.XMainLine2:OpenExhibitionChapter(chapterId)
end

function XUiMainLineExhibitionPopupChapter:Refresh()
    self:RefreshPreChapterList()
    self:RefreshBtnIgnore()
end

-- 刷新前置关卡列表
function XUiMainLineExhibitionPopupChapter:RefreshPreChapterList()
    local chapterConfig = XMVCA.XMainLine2:GetConfigExhibitionChapter(self.ChapterId)
    self.ShowPreChapterIds = {}
    for _, preId in pairs(chapterConfig.PreIds) do
        local isCompleted = XMVCA.XMainLine2:IsExhibitionChapterCompleted(preId)
        if not isCompleted then
            table.insert(self.ShowPreChapterIds, preId)
        end
    end
    
    self.GridChapterGoList = self.GridChapterGoList or {}
    for _, go in pairs(self.GridChapterGoList) do
        go.gameObject:SetActiveEx(false)
    end

    for i, cId in ipairs(self.ShowPreChapterIds) do
        local index = i
        local go = self.GridChapterGoList[i]
        if not go then
            go = XUiHelper.Instantiate(self.GridChapter, self.Content)
            table.insert(self.GridChapterGoList, go)
            local button = go:GetComponent("UiObject"):GetObject("Button")
            XUiHelper.RegisterClickEvent(self, button, function()
                self:OnPreChapterClick(index)
            end, nil, true)
        end
        go.gameObject:SetActiveEx(true)
        self:RefreshPreChapter(i, go, cId)
    end
end

-- 刷新单个前置关卡
function XUiMainLineExhibitionPopupChapter:RefreshPreChapter(index, go, chapterId)
    local uiObj = go:GetComponent("UiObject")
    local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(chapterId)

    local mainId = chapterCfg.ExhibitionFubenConfigId
    local difficult = XDataCenter.FubenManager.DifficultNormal
    local viewModel
    -- 主线/浮点纪实
    if chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.MAINLINE then
        viewModel = XMVCA.XMainLine2:GetExhibitionViewModel(mainId)
    -- 外篇旧闻
    elseif chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.EXTRA then
        viewModel = XDataCenter.ExtraChapterManager:ExGetChapterViewModelById(mainId, difficult)
    end
    
    -- 标题
    uiObj:GetObject("TxtName").text = chapterCfg.TitleName
    -- 副标题
    local panelBranchLine = uiObj:GetObject("PanelBranchLine", false)
    if panelBranchLine then
        local isShowSubTitle = not string.IsNilOrEmpty(chapterCfg.SubTitleName)
        panelBranchLine.gameObject:SetActiveEx(isShowSubTitle)
        if isShowSubTitle then
            uiObj:GetObject("TxtBranchLineName").text = chapterCfg.SubTitleName
        end
    end
    
    -- 背景图
    uiObj:GetObject("RImgBg"):SetRawImage(viewModel:GetIcon())
    
    -- 成就
    local achievementIcon = viewModel:GetAchievementIcon()
    local isShowAchieve = achievementIcon ~= nil
    uiObj:GetObject("PanelAchievement").gameObject:SetActiveEx(isShowAchieve)
    if isShowAchieve then
        local isUnlock = viewModel:IsAchievementUnlock()
        local rImgAchievementGrey = uiObj:GetObject("RImgAchievementGrey")
        local rImgAchievementColor = uiObj:GetObject("RImgAchievementColor")
        rImgAchievementGrey.gameObject:SetActiveEx(not isUnlock)
        rImgAchievementColor.gameObject:SetActiveEx(isUnlock)
        if isUnlock then
            rImgAchievementColor:SetRawImage(achievementIcon)
        else
            rImgAchievementGrey:SetRawImage(achievementIcon)
        end
    end
    
    -- 页签
    local panelTag = uiObj:GetObject("PanelTag", false)
    local tagImage = uiObj:GetObject("TagImage")
    local tagText = uiObj:GetObject("TagText")
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
    -- 新章节页签
    elseif viewModel:CheckHasNewTag() then
        panelTag.gameObject:SetActiveEx(true)
        tagImage.color = XUiHelper.Hexcolor2Color(XEnumConst.MAINLINE2.MAIN_TAG_COLOR.NEW)
        tagText.text = XUiHelper.GetText("MainLineChapterNewTag")
    else
        panelTag.gameObject:SetActiveEx(false)
    end

    -- 进度
    local currentProgress, maxProgress = viewModel:GetCurrentAndMaxProgress()
    local stateNames = { "Normal", "Press"}
    local txtProgress = math.ceil(currentProgress / maxProgress * 100) .. "%"
    for _, stateName in pairs(stateNames) do
        local stateUiObj = uiObj:GetObject(stateName)
        stateUiObj:GetObject("TxtProgress").text = txtProgress
    end
    
    -- 关联角色
    self:RefreshChapterCharacters(index, uiObj, chapterCfg)
end

function XUiMainLineExhibitionPopupChapter:RefreshBtnIgnore()
    local isIgnore = XMVCA.XMainLine2:GetIsIgnoreUiExhibitionPopupChapter()
    local btnState = isIgnore and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.BtnIgnore:SetButtonState(btnState)
end

-- 刷新章节的关联角色
---@param chapterCfg XTableMainLine2ExhibitionChapter
function XUiMainLineExhibitionPopupChapter:RefreshChapterCharacters(index, uiObj, chapterCfg)
    local characterIds = {}
    local configs = XMVCA.XPlotExhibition:GetStoryLineConfigs()
    for _, config in pairs(configs) do
        if config.StoryChapter == chapterCfg.ExhibitionFubenConfigId then
            table.insert(characterIds, config.CharacterId)
        end
    end
    self.IndexToCharacterIds[index] = characterIds

    local isShow = #characterIds > 0
    local panelCharacter = uiObj:GetObject("PanelCharacter")
    panelCharacter.gameObject:SetActiveEx(isShow)
    if not isShow then return end

    local gridHead = uiObj:GetObject("GridHead")
    gridHead.gameObject:SetActiveEx(false)
    local contentCharacter = uiObj:GetObject("ContentCharacter")

    local characterGos = self.IndexToCharacterGos[index]
    if not characterGos then
        characterGos = {}
        self.IndexToCharacterGos[index] = characterGos
    end
    for _, go in pairs(characterGos) do
        go.gameObject:SetActiveEx(false)
    end

    for i, charId in ipairs(characterIds) do
        local charIndex = i
        local go = characterGos[i]
        if not go then
            go = XUiHelper.Instantiate(gridHead, contentCharacter)
            table.insert(characterGos, go)
            local button = go:GetComponent("XUiButton")
            XUiHelper.RegisterClickEvent(self, button, function()
                self:OnCharacterClick(index, charIndex)
            end, nil, true)
        end
        go.gameObject:SetActiveEx(true)
        local charUiObj = go:GetComponent("UiObject")
        local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(charId)
        charUiObj:GetObject("RImgHead"):SetRawImage(icon)
    end
end

function XUiMainLineExhibitionPopupChapter:OnCharacterClick(index, charIndex)
    local characterIds = self.IndexToCharacterIds[index]
    local character = characterIds[charIndex]
    self:Close()
    XMVCA.XPlotExhibition:OpenRoleDetail(character)
end

return XUiMainLineExhibitionPopupChapter