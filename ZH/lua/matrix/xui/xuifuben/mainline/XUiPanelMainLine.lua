-- local XUiGridFubenChapter = require("XUi/XUiFuben/UiDynamicList/XUiGridFubenChapter")
-- local XUiGridFubenSideTab = require("XUi/XUiFuben/UiDynamicList/XUiGridFubenSideTab")
local XUiGridMainLineChapter = require("XUi/XUiFuben/MainLine/XUiGridMainLineChapter")
local XUiGridMainLineTab = require("XUi/XUiFuben/MainLine/XUiGridMainLineTab")
local XUiFubenChapterDynamicTable = require("XUi/XUiFuben/UiDynamicList/XUiFubenChapterDynamicTable")
local XUiFubenSideDynamicTable = require("XUi/XUiFuben/UiDynamicList/XUiFubenSideDynamicTable")

local XUiPanelMainLine = XClass(XSignalData, "XUiPanelMainLine")

function XUiPanelMainLine:Ctor(ui, root)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = root
    self.MainLineManager = XDataCenter.FubenManagerEx.GetMainLineManager()
    -- 动态列表
    self.GridChapterContent.gameObject:SetActiveEx(false)
    self.UiFubenChapterDynamicTableCurrent = XUiFubenChapterDynamicTable.New(self, self.PanelChapterListCurrent, XUiGridMainLineChapter
        , handler(self, self.OnBtnChapterClicked))
    self.CurrentChapterListControl = self.UiFubenChapterDynamicTableCurrent
    self.PanelChapterListNext.gameObject:SetActiveEx(false)
    -- 侧边列表
    self.UiFubenSideDynamicTable = XUiFubenSideDynamicTable.New(self.PanelSideList, XUiGridMainLineTab
        , handler(self, self.OnBtnTabClicked))
    self.UiFubenSideDynamicTable:ConnectSignal("DYNAMIC_TWEEN_OVER", self, self.OnSideDynamicTableTweenOver)
    -- 当前章节组id
    self.CurrentGroupId = 1
    self.CurrentChapterIndex = 1
    -- 当前章节限时难度
    self.CurrentFubenDifficulty = XDataCenter.FubenManager.DifficultNormal
    self.FirstTagIndex = nil
    
    self.BtnBookmark.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self.BtnCharacterStory.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
    self:RegisterUiEvents()
end

function XUiPanelMainLine:SetData(firstTagId, groupIndex, chapterIndex)
    self.FirstTagIndex = firstTagId
    if groupIndex == nil then
        local g, i = self.MainLineManager:ExGetCurrentGroupIndexAndChapterIndex()
        groupIndex = g
    end
    self.CurrentGroupId = groupIndex
    self.CurrentChapterIndex = chapterIndex
    -- 背景底图刷新
    self.RootUi:ChangeBgBySecondTag(self.MainLineManager:ExGetChapterGroupConfigs()[self.CurrentGroupId].Bg)
    -- 侧边栏卷刷新
    self:RefreshTabList(self.CurrentGroupId)
    -- -- 章节列表刷新
    -- self:RefreshChapterList(self.CurrentChapterIndex)
    self._SetDataRun = true
end

function XUiPanelMainLine:OnEnable()
    -- 防止多次触发OnEnable时，动画异常。
    -- XUiNewFuben在OnBtnBottomTabClicked切换加载旧主线时触发了一次OnEnable
    -- 随后XUiNewFuben在OnChildPanelEnable主动触发了一次OnEnable
    if self.IsEnable then return end
    self.IsEnable = true
    local gridDic = self.CurrentChapterListControl:GetGridDic()
    for _, grid in pairs(gridDic) do
        grid:RefreshRedPoint()
    end
    gridDic = self.UiFubenSideDynamicTable:GetGridDic()
    for _, grid in pairs(gridDic) do
        grid:RefreshRedPoint()
    end
    -- 章节列表刷新
    self:RefreshChapterList(self.CurrentGroupId, self.CurrentChapterIndex, true)

    if self._SetDataRun then
        self._SetDataRun = false
    else
        -- 侧边栏卷刷新
        self:RefreshTabList(self.CurrentGroupId)
    end
    
    self:RefreshNewbieLockConditionShow()
    self:RefreshBtnBookmark()
end

function XUiPanelMainLine:OnDisable()
    self.IsEnable = false
    self.CurrentChapterListControl:SetCurrGridOpen() -- 退出时要强设一遍展开样式，防止在滑动侧边栏过程中，快速切换底部标签再切回来导致open动画播放错误

    -- 临时 BGM 功能本期暂不启用
    -- self.RootUi.BgmMusicPlayer:ClearTempMusic()
end

function XUiPanelMainLine:RefreshBgm(groupConfig)
    if not self or not groupConfig then
        return
    end

    -- 临时 BGM 功能本期暂不启用
    -- local bgmCueId = groupConfig.BgmCueId
    -- if bgmCueId ~= 0 then
    --     self.RootUi.BgmMusicPlayer:SetTempMusic(bgmCueId)
    -- else
    --     self.RootUi.BgmMusicPlayer:ClearTempMusic()
    -- end
end

function XUiPanelMainLine:RefreshChapterList(groupId, index, isFirstChange)
    if index == nil then
        local _, i = self.MainLineManager:ExGetCurrentGroupIndexAndChapterIndex(self.CurrentGroupId)
        index = i
    end
    local chapterViewModels = self.MainLineManager:ExGetChapterViewModels(self.CurrentGroupId, self.CurrentFubenDifficulty)
    self.CurrentChapterListControl:RefreshList(chapterViewModels, index - 1, isFirstChange)

    self:RefreshBgm(self.MainLineManager:ExGetChapterGroupConfigs()[groupId])
end

function XUiPanelMainLine:RefreshTabList(index)
    local groupConfigs = self.MainLineManager:ExGetChapterGroupConfigs()
    self.UiFubenSideDynamicTable:RefreshList(groupConfigs, index - 1)
end

--- 刷新新手锁定提示文本的显示
function XUiPanelMainLine:RefreshNewbieLockConditionShow()
    local conditionId = XMVCA.XMainLine2:GetClientNewbieMainLineLockCondition()

    if XTool.IsNumberValidEx(conditionId) then
        if self.LockTips then
            local isShow = XConditionManager.CheckCondition(conditionId)
            self.LockTips.gameObject:SetActiveEx(isShow)

            if isShow then
                if self.LockText then
                    self.LockText.text = XConditionManager.GetConditionDescById(conditionId)
                end
            end
        end
    else
        if self.LockTips then
            self.LockTips.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelMainLine:OnBtnTabClicked(index, groupConfig)
    if self.UiFubenSideDynamicTable:GetCurrentSelectedIndex() == index then
        return
    end
    local isUp = groupConfig.Id > self.CurrentGroupId
    self.UiFubenSideDynamicTable:TweenToIndex(index)
    self.CurrentGroupId = groupConfig.Id
    self:EmitSignal("SetMainUiFirstIndexArgs", self.FirstTagIndex, self.CurrentGroupId, self:GetHistoryChapterIndex(self.CurrentGroupId)) -- 点击侧边栏不记录chapter，只记录2级标签
    self:RefreshChapterList(self.CurrentGroupId, self:GetHistoryChapterIndex(self.CurrentGroupId))
end

function XUiPanelMainLine:OnBtnChapterClicked(index, viewModel)
    self.CurrentChapterIndex = index + 1 
    self:EmitSignal("SetMainUiFirstIndexArgs", self.FirstTagIndex, self.CurrentGroupId, self.CurrentChapterIndex)
    self:SetHistoryChapterIndex(self.CurrentGroupId, self.CurrentChapterIndex)
    -- 只有是选中的，才直接打开界面
    if self.CurrentChapterListControl:GetCurrentSelectedIndex() == index then
        XMVCA.XMainLine2:RecordEnterChapterWay(XEnumConst.MAINLINE2.ENTER_CHAPTER_WAY_TYPE.MAINLINE)
        self.MainLineManager:ExOpenChapterUi(viewModel, self.CurrentFubenDifficulty)
        return
    end
    self.Mask.gameObject:SetActiveEx(true)
    -- 未选中要先跳过去播动画
    self.CurrentChapterListControl:TweenToIndex(index, XFubenConfigs.MainLineWaitTime, function ()
        self.Mask.gameObject:SetActiveEx(false)
    end)
end

function XUiPanelMainLine:OnSideDynamicTableTweenOver(index)
    self.Mask.gameObject:SetActiveEx(false)
    local groupConfig = self.MainLineManager:ExGetChapterGroupConfigs()[index + 1]
    -- 背景底图刷新
    self.Transform:Find("Animation/QieHuan"):PlayTimelineAnimation()
    self.RootUi:ChangeBgBySecondTag(groupConfig.Bg) 
    if self.CurrentGroupId == groupConfig.Id then return end
    local isUp = groupConfig.Id > self.CurrentGroupId
    self.CurrentGroupId = groupConfig.Id
    self:RefreshChapterList(self.CurrentGroupId, self:GetHistoryChapterIndex(self.CurrentGroupId))
end

function XUiPanelMainLine:SetHistoryChapterIndex(groupId, chapterIndex)
    if self.__HistoryChapterIndexDic == nil then
        self.__HistoryChapterIndexDic = {}
    end
    self.__HistoryChapterIndexDic[groupId] = chapterIndex
end

function XUiPanelMainLine:GetHistoryChapterIndex(groupId)
    if self.__HistoryChapterIndexDic == nil then return nil end
    return self.__HistoryChapterIndexDic[groupId]
end

function XUiPanelMainLine:OnDestroy()
    if self.CurrentChapterListControl and self.CurrentChapterListControl.OnDestroy then
        self.CurrentChapterListControl:OnDestroy()
    end
    if self.UiFubenSideDynamicTable and self.UiFubenSideDynamicTable.OnDestroy then
        self.UiFubenSideDynamicTable:OnDestroy()
    end
end

function XUiPanelMainLine:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBookmark, self.OnBtnBookmarkClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnCharacterStory, self.OnBtnCharacterStoryClick, nil, true)
end

function XUiPanelMainLine:OnBtnBookmarkClick()
    -- 没有书签时，弹提示
    local bookmarkData = XMVCA.XMovie:GetBookmarkData()
    if not bookmarkData then
        local tips = XMVCA.XMainLine2:GetClientConfigParams("NoBookmarkTips", 1)
        XUiManager.TipError(tips)
        return
    end

    -- 二次确认是否播放书签剧情
    local bookmarkName = XMVCA.XMovie:GetBookmarkName()
    local params = XMVCA.XMovie:GetClientConfigParams("BookmarkEnterTips")
    local tipTitle = params[1]
    local contentFormat = params[2]
    local content = string.format(contentFormat, bookmarkName)
    content = XUiHelper.ConvertLineBreakSymbol(content)
    local confirmCb = function()
        XMVCA.XMovie:PlayBookmarkMovie()
    end
    XLuaUiManager.Open("UiDialog", tipTitle, content, XUiManager.DialogType.Normal, nil, confirmCb)
end

function XUiPanelMainLine:OnBtnCharacterStoryClick()
    XMVCA.XPlotExhibition:OpenMain()
end

--region 剧情书签
-- 刷新剧情书签按钮
function XUiPanelMainLine:RefreshBtnBookmark()
    XMVCA.XMovie:RequestGetStageBookmark(function(bookmarkData)
        local isExit = bookmarkData ~= nil
        self.BookmarkBubble.gameObject:SetActiveEx(isExit)
        if isExit then
            local name = XMVCA.XMovie:GetBookmarkName()
            self.BtnBookmark:SetName(name)
        end
    end)
end
--endregion

return XUiPanelMainLine