---@class XUiPanelMainLineExhibition
---@field ModuleList XUiGridMainLineExhibitionModule[]
---@field IsShowDetailUi boolean 是否显示章节详情Ui
---@field UiPanelModuleDropdown XUiPanelMainLineExhibitionModuleDropdown 模块下拉列表
local XUiPanelMainLineExhibition = XClass(nil, "XUiPanelMainLineExhibition")

function XUiPanelMainLineExhibition:Ctor(ui, root)
    self.RootUi = root
    XUiHelper.InitUiClass(self, ui)

    self.CurModuleIndex = nil   -- 当前模块下标
    self.CurChapterIndex = nil  -- 当前模块章节下标
    self.GridChapterMainLine.gameObject:SetActiveEx(false)
    self.GridChapterBranchLine.gameObject:SetActiveEx(false)
    self.GridChapterFubenChallenge.gameObject:SetActiveEx(false)
    self.BtnGoRight.gameObject:SetActiveEx(false)
    self.BtnGoLeft.gameObject:SetActiveEx(false)
    -- 滚动条总是显示，显隐交给动画控制
    self.ScrollBar.gameObject:SetActiveEx(true)
    self:RegisterUiEvents()
    self:InitDragArea()
    self:InitModuleList()
    self:InitModuleDropdown()
end

function XUiPanelMainLineExhibition:SetData(firstTagId, groupIndex, chapterIndex)

end

function XUiPanelMainLineExhibition:OnEnable()
    if self.IsEnable then
        return
    end

    self.IsEnable = true
    
    -- 子界面OnEnable
    for _, module in pairs(self.ModuleList) do
        module:OnEnable()
    end

    -- 强制刷新BG和BGM
    self._OldModuleId = -1
    -- 刷新书签
    self:RefreshBtnBookmark()
    -- 新手期间增加提示，禁用拖拽和缩放
    local isNewable, tips = self:IsNewbie()
    self.LockTips.gameObject:SetActiveEx(isNewable)
    self:SetAreaScaleDragEnable(not isNewable)
    
    -- 新手期间保持默认位置，隐藏下拉列表和滑动条，增加上锁提示
    if isNewable then
        self:Refresh()
        self.UiPanelModuleDropdown:Close()
        self:HideScrollBar()
        self.LockText.text = tips
        
    -- 默认的定位规则
    elseif not self.CurModuleIndex then
        local curModuleIndex, curChapterIndex = XMVCA.XMainLine2:GetExhibitionCurrentModuleIndexAndChapterIndex()
        self:LocateByIndex(curModuleIndex, curChapterIndex)
        
    -- 返回界面重新刷新
    else
        self:Refresh()    
    end
end

function XUiPanelMainLineExhibition:OnDisable()
    self.IsEnable = false

    -- 子界面OnDisable
    for _, module in pairs(self.ModuleList) do
        module:OnDisable()
    end

    self.UiPanelModuleDropdown:CloseDropdown()
    self.firstNewTagExhibitionChapterId = nil
    self.RootUi.BgmMusicPlayer:ClearTempMusic()
end

function XUiPanelMainLineExhibition:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINLINE_EXHIBITION_LOCATE, self.OnEventLocate, self)
    self:StopLocateTimer()
end

function XUiPanelMainLineExhibition:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBookmark, self.OnBtnBookmarkClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnCharacterStory, self.OnBtnCharacterStoryClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnGoRight, self.OnBtnGoLastPassedChapter, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnGoLeft, self.OnBtnGoLastPassedChapter, nil, true)
    self.BtnLifeTree:AddEventListener(function() self:OnBtnLifeTreeClick() end)
    XEventManager.AddEventListener(XEventId.EVENT_MAINLINE_EXHIBITION_LOCATE, self.OnEventLocate, self)

    -- 滑动条
    self.ScrollBar.onValueChanged:AddListener(function(v)
        self:OnScrollBarValueChanged(v)
    end)
end

function XUiPanelMainLineExhibition:OnBtnBookmarkClick()
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

function XUiPanelMainLineExhibition:OnBtnCharacterStoryClick()
    XMVCA.XPlotExhibition:OpenMain()
end

function XUiPanelMainLineExhibition:OnBtnGoLastPassedChapter()
    local exhibitionChapterId = XMVCA.XMainLine2:GetLastExhibitionChapterId()
    local moduleIndex, chapterIndex = self:GetExhibitionChapterIndex(exhibitionChapterId)
    if moduleIndex then
        self:LocateByIndex(moduleIndex, chapterIndex)
    end
end

-- 位置发生变化
function XUiPanelMainLineExhibition:OnTranslateValueChanged(pos)
    local posX = self.PanelModule.anchoredPosition.x
    local pivotX = self.PanelModule.pivot.x
    local allWidth = self:GetAllDragAreaWidth()
    local width = math.abs(posX + pivotX * allWidth)  -- 计算pivotX为0时的位置
    local progress = width / allWidth
    if progress > 1 then
        progress = 1
    end
    if progress < 0 then
        progress = 0
    end
    self.IsUpdateScrollBarProgress = true -- 仅更新进度不触发回调
    self.ScrollBar.value = progress
    self.IsUpdateScrollBarProgress = false

    self:Refresh()
end

function XUiPanelMainLineExhibition:IsDragOperation()
    return self.PanelAreaScaleDrag.DragTranslate.IsFingerDrag
end

-- 缩放发生变化
function XUiPanelMainLineExhibition:OnScrollValueChanged()
    self:Refresh()
end

function XUiPanelMainLineExhibition:Refresh()
    -- 检测显示章节预制体
    self:CheckShowChapterPrefab()
    -- 更新简略/详细信息显示
    self:RefreshBriefAndDetailUiShow()
    -- 更新背景图
    self:RefreshBgByPos()
    -- 更新跳转按钮
    self:RefreshBtnGoLastPassedChapter()
    -- 刷新生命树跳转按钮状态
    self:RefreshBtnLifeTreeState()
end

-- 事件触发定位
function XUiPanelMainLineExhibition:OnEventLocate(...)
    local args = { ... }
    local exhibitionModuleId = tonumber(args[1])
    local exhibitionChapterId = tonumber(args[2])

    if exhibitionChapterId then
        local moduleIndex, chapterIndex = self:GetExhibitionChapterIndex(exhibitionChapterId)
        if moduleIndex then
            self:LocateByIndex(moduleIndex, chapterIndex)
        else
            XLog.Error(string.format("定位到 ExhibitionChapterId:%s 失败！", exhibitionChapterId))
        end
        return
    end

    if exhibitionModuleId then
        local moduleCfgs = XMVCA.XMainLine2:GetConfigExhibitionModule()
        for i, moduleCfg in ipairs(moduleCfgs) do
            if moduleCfg.Id == exhibitionModuleId then
                self:LocateByIndex(i)
                return
            end
        end
        XLog.Error(string.format("定位到 ExhibitionModuleId:%s 失败！", exhibitionModuleId))
        return
    end

    local curModuleIndex, curChapterIndex = XMVCA.XMainLine2:GetExhibitionCurrentModuleIndexAndChapterIndex()
    self:LocateByIndex(curModuleIndex, curChapterIndex)
end

-- 切换章节详情UI
function XUiPanelMainLineExhibition:SwitchDetailUi()
    self.IsShowDetailUi = true
    for _, module in pairs(self.ModuleList) do
        module:SwitchDetailUi()
    end

    -- 改为常驻显现，不需要动画和切换
    --[[
    self.UiPanelModuleDropdown:Open()
    self:HideScrollBar()
    XUiHelper.PlayUiNodeAnimation(self.Transform, "BtnCurModuleEnable")
    ]]
end

-- 切换章节简略UI
function XUiPanelMainLineExhibition:SwitchBriefUi()
    self.IsShowDetailUi = false
    for _, module in pairs(self.ModuleList) do
        module:SwitchBriefUi()
    end

    -- 改为常驻显现，不需要动画和切换
    --[[
    XUiHelper.PlayUiNodeAnimation(self.Transform, "BtnCurModuleDisable", function()
        if self.IsShowDetailUi == false then
            self.UiPanelModuleDropdown:Close()
            self:ShowScrollBar()
        end
    end)
    ]]
end

function XUiPanelMainLineExhibition:InitDragArea()
    self.DragAreaRectTransform = self.DragArea:GetComponent("RectTransform")
    self.PanelAreaScaleDrag.MaxScale = XEnumConst.MAINLINE2.EXHIBITION_MAX_SCALE
    self.PanelAreaScaleDrag.MinScale = XEnumConst.MAINLINE2.EXHIBITION_MIN_SCALE
    local scale = XEnumConst.MAINLINE2.EXHIBITION_SHOW_INIT_SCALE
    self.PanelModule.localScale = XLuaVector3.New(scale, scale, scale)
    self.PanelModule.pivot = XLuaVector2.New(0, 0.5)
    self.IsShowDetailUi = false

    -- 拖拽和缩放区域
    self.PanelAreaScaleDrag:AddTranslateValueChangedListener(function(pos)
        self:OnTranslateValueChanged(pos)
    end)
    self.PanelAreaScaleDrag:AddScaleValueChangedListener(function()
        self:OnScrollValueChanged()
    end)
end

-- 初始化ModuleList
function XUiPanelMainLineExhibition:InitModuleList()
    self.ModuleList = {}
    local XUiGridMainLineExhibitionModule = require("XUi/XUiFuben/MainLine/XUiGridMainLineExhibitionModule")
    local moduleCfgs = XMVCA.XMainLine2:GetConfigExhibitionModule()
    for i, moduleCfg in ipairs(moduleCfgs) do
        local moduleGo = self.PanelModule.transform:Find("Module" .. i)
        if moduleGo then
            local gridModule = XUiGridMainLineExhibitionModule.New(self, moduleGo, moduleCfg.Id, i)
            table.insert(self.ModuleList, gridModule)
        else
            XLog.Error(string.format("预制体UiMainLineExhibitionMain，缺少节点PanelModule/Module%s!", i))
        end
    end
end

function XUiPanelMainLineExhibition:GetModuleByModuleIndex(index)
    return self.ModuleList[index]
end

function XUiPanelMainLineExhibition:GetModuleByModuleId(moduleId)
    for _, module in pairs(self.ModuleList) do
        if module.ModuleId == moduleId then
            return module
        end
    end
end

-- 通过下标定位
function XUiPanelMainLineExhibition:LocateByIndex(moduleIndex, chapterIndex, finishCb)
    -- 设置锚点和缩放
    local scale = self:GetCurrentScale()
    local moduleId = self.ModuleList[moduleIndex]:GetModuleId()
    if not chapterIndex then
        chapterIndex = XMVCA.XMainLine2:GetExhibitionCurrentChapterIndex(moduleId)
    end
    self.CurModuleIndex = moduleIndex
    self.CurChapterIndex = chapterIndex
    local halfShowAreaWidth = self:GetHalfShowAreaWidth()

    -- 以模块的左边确定位置
    local moveWidth = self:GetMoveToModuleStartWidth(moduleIndex)
    moveWidth = moveWidth * scale

    -- 配置chapterIndex时，对应章节在屏幕中心显示
    if chapterIndex then
        local gridModule = self.ModuleList[moduleIndex]
        local moduleWidth = gridModule:GetWidth()
        local gridChapter = gridModule:GetGridChapter(chapterIndex)
        local chapterPosX = gridChapter:GetLocalPosition().x
        local offsetWidth = (moduleWidth / 2 + chapterPosX) * scale - halfShowAreaWidth

        -- 超出模块范围
        local maxOffsetWidth = moduleWidth * scale - self:GetShowAreaWidth() -- 最大的移动距离，模块右边贴着屏幕右边
        if offsetWidth < 0 then
            offsetWidth = 0
        end
        if offsetWidth > maxOffsetWidth then
            offsetWidth = maxOffsetWidth
        end

        moveWidth = moveWidth + offsetWidth
    end

    -- 定位
    self.PanelModule.anchoredPosition = XLuaVector2.New(-moveWidth, 0)

    -- 更新背景
    self:RefreshBgAndBgm(moduleId)
    -- 更新下拉列表
    self:SetDropdownModuleId(moduleId)

    -- 定位完成回调
    if finishCb then
        self:Refresh() -- 禁用拖拽组件会导致不触发OnTranslateValueChanged，手动刷新一次
        XLuaUiManager.SetMask(true)
        self:SetAreaScaleDragEnable(false)
        self.LocateTimer = XScheduleManager.ScheduleOnce(function()
            self.LocateTimer = nil
            XLuaUiManager.SetMask(false)
            self:SetAreaScaleDragEnable(true)
            finishCb()
        end, 400)
    end
end

-- 停止定位定时器
function XUiPanelMainLineExhibition:StopLocateTimer()
    if self.LocateTimer then
        XScheduleManager.UnSchedule(self.LocateTimer)
        self.LocateTimer = nil
    end
end

function XUiPanelMainLineExhibition:GetObject(name)
    return self[name]
end

function XUiPanelMainLineExhibition:RefreshBriefAndDetailUiShow()
    local scale = self:GetCurrentScale()
    if scale <= XEnumConst.MAINLINE2.EXHIBITION_SHOW_BRIEF_SCALE and self.IsShowDetailUi then
        self:SwitchBriefUi()
    elseif scale >= XEnumConst.MAINLINE2.EXHIBITION_SHOW_DETAIL_SCALE and not self.IsShowDetailUi then
        self:SwitchDetailUi()
    end
end

-- 刷新背景图
function XUiPanelMainLineExhibition:RefreshBgAndBgm(moduleId)
    if self._OldModuleId == moduleId then
        return
    end
    if self._OldModuleId then
        XUiHelper.PlayUiNodeAnimation(self.Transform, "BgQieHuan")
    end
    self._OldModuleId = moduleId
    local moduleConfig = XMVCA.XMainLine2:GetConfigExhibitionModule(moduleId)
    self.BgImage:SetRawImage(moduleConfig.BgImage)
    self:SetDropdownModuleId(moduleId)

    local bgmCueId = moduleConfig.BgmCueId
    if bgmCueId ~= 0 then
        self.RootUi.BgmMusicPlayer:SetTempMusic(bgmCueId)
    else
        self.RootUi.BgmMusicPlayer:ClearTempMusic()
    end
end

-- 刷新背景图
function XUiPanelMainLineExhibition:RefreshBgByPos()
    local scale = self:GetCurrentScale()
    local moveWidth = math.abs(self.PanelModule.anchoredPosition.x)
    local halfShowAreaWidth = self:GetHalfShowAreaWidth()
    local paddingLeft = self.PanelModuleLayoutGroup.padding.left * scale
    local spacing = self.PanelModuleLayoutGroup.spacing * scale
    moveWidth = moveWidth + halfShowAreaWidth - paddingLeft -- 屏幕中心点位置

    for _, module in ipairs(self.ModuleList) do
        local moduleWidth = module:GetWidth() * scale
        if moveWidth >= 0 and moveWidth - moduleWidth <= 0 then
            local moduleId = module:GetModuleId()
            self:RefreshBgAndBgm(moduleId)
            return
        end
        moveWidth = moveWidth - moduleWidth - spacing
    end
end

-- 刷新跳转上次通关章节按钮
function XUiPanelMainLineExhibition:RefreshBtnGoLastPassedChapter()
    local exhibitionChapterId = XMVCA.XMainLine2:GetLastExhibitionChapterId()
    if not XTool.IsNumberValidEx(exhibitionChapterId) then
        self.BtnGoLeft.gameObject:SetActiveEx(false)
        self.BtnGoRight.gameObject:SetActiveEx(false)
        return
    end

    local moduleIndex, chapterIndex = self:GetExhibitionChapterIndex(exhibitionChapterId)
    local isInArea, isInAreaLeft = self:IsExhibitionChapterInShowArea(moduleIndex, chapterIndex)
    --if isInArea then
    --    self.BtnGoLeft.gameObject:SetActiveEx(false)
    --    self.BtnGoRight.gameObject:SetActiveEx(false)
    --else
    --    self.BtnGoLeft.gameObject:SetActiveEx(isInAreaLeft)
    --    self.BtnGoRight.gameObject:SetActiveEx(not isInAreaLeft)
    --end
    local isLeft = not isInArea and isInAreaLeft
    local isRight = not isInArea and not isInAreaLeft
    if self._IsLeft ~= isLeft then
        self._IsLeft = isLeft
        if isLeft then
            self.BtnGoLeft.gameObject:SetActiveEx(true)
            XUiHelper.PlayUiNodeAnimation(self.Transform, "BtnGoLeftEnable")
        else
            XUiHelper.PlayUiNodeAnimation(self.Transform, "BtnGoLeftDisable",function()
                if not self._IsLeft then
                    self.BtnGoLeft.gameObject:SetActiveEx(false)
                end
            end)
        end
    end
    if self._IsRight ~= isRight then
        self._IsRight = isRight
        if isRight then
            self.BtnGoRight.gameObject:SetActiveEx(true)
            XUiHelper.PlayUiNodeAnimation(self.Transform, "BtnGoRightEnable")
        else
            XUiHelper.PlayUiNodeAnimation(self.Transform, "BtnGoRightDisable",function()
                if not self._IsRight then
                    self.BtnGoRight.gameObject:SetActiveEx(false)
                end
            end)
        end
    end
end

-- 检测显示章节预制体
function XUiPanelMainLineExhibition:CheckShowChapterPrefab()
    local showAreaWidth = self:GetShowAreaWidth()
    for moduleIndex, module in ipairs(self.ModuleList) do
        local chapterList = module:GetChapterList()
        for chapterIndex, chapter in ipairs(chapterList) do
            local isInArea, isInAreaLeft = self:IsExhibitionChapterInShowArea(moduleIndex, chapterIndex, showAreaWidth)
            if isInArea then
                chapter:ShowPrefab()
            else
                chapter:HidePrefab()
            end
        end
    end
end

-- 设置拖拽和缩放组件是否启用
function XUiPanelMainLineExhibition:SetAreaScaleDragEnable(isEnable)
    self.PanelAreaScaleDrag.enabled = isEnable
end

-- 获取时间轴章节的模块下标和章节下标
---@return number moduleIndex
---@return number chapterIndex
function XUiPanelMainLineExhibition:GetExhibitionChapterIndex(exhibitionChapterId)
    local moduleCfgs = XMVCA.XMainLine2:GetConfigExhibitionModule()
    for i, moduleCfg in ipairs(moduleCfgs) do
        for j, chapterId in ipairs(moduleCfg.ChapterIds) do
            if chapterId == exhibitionChapterId then
                return i, j
            end
        end
    end
end

-- 时间轴是否在显示区域内
---@param offset number 判断是否在区域内的左右偏移值
---@return boolean 是否在显示区域内
---@return boolean 是否在显示区域左边
function XUiPanelMainLineExhibition:IsExhibitionChapterInShowArea(moduleIndex, chapterIndex, offset)
    offset = offset or 0

    -- 左边到模块开始的长度
    local scale = self:GetCurrentScale()
    local moduleStartWidth = self:GetMoveToModuleStartWidth(moduleIndex)

    -- 计算章节所在长度
    local gridModule = self.ModuleList[moduleIndex]
    local moduleWidth = gridModule:GetWidth()
    local gridChapter = gridModule:GetGridChapter(chapterIndex)
    local chapterPosX = gridChapter:GetLocalPosition().x
    local chapterMoveWidth = (moduleStartWidth + moduleWidth / 2 + chapterPosX) * scale

    -- 拖拽列表的移动长度，一开始贴着左边的时候是0，拖拽Width对应anchoredPosition.x
    local showAreaWidthLeft = math.abs(self.PanelModule.anchoredPosition.x)
    local showAreaWidthRight = showAreaWidthLeft + self:GetShowAreaWidth()

    local isInAreaLeft = chapterMoveWidth < (showAreaWidthLeft - offset)
    local isInAreaRight = chapterMoveWidth > (showAreaWidthRight + offset)
    local isInArea = not isInAreaLeft and not isInAreaRight
    return isInArea, isInAreaLeft
end

-- 获取移动到模块开始位置的长度
function XUiPanelMainLineExhibition:GetMoveToModuleStartWidth(moduleIndex)
    self.ModuleStartWidthDic = self.ModuleStartWidthDic or {}
    local width = self.ModuleStartWidthDic[moduleIndex]
    if width then
        return width
    end

    width = self.PanelModuleLayoutGroup.padding.left
    local spacing = self.PanelModuleLayoutGroup.spacing
    for i, gridModule in ipairs(self.ModuleList) do
        local moduleWidth = gridModule:GetWidth()
        if i < moduleIndex then
            width = width + moduleWidth + spacing
        end
    end
    self.ModuleStartWidthDic[moduleIndex] = width
    return width
end

-- 获取可拖拽区域的长度
function XUiPanelMainLineExhibition:GetAllDragAreaWidth()
    local scale = self:GetCurrentScale()
    --CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelModule)
    return self.PanelModule.rect.width * scale - self:GetShowAreaWidth()
end

-- 获取当前的缩放值
function XUiPanelMainLineExhibition:GetCurrentScale()
    return self.PanelModule.localScale.x
end

-- 获取显示区域的长度（不进行缓存，界面打开的下一帧会刷新布局，width发生变化）
function XUiPanelMainLineExhibition:GetShowAreaWidth()
    local width = self.DragAreaRectTransform.rect.width
    return width
end

-- 获取显示区域的一半（不进行缓存，界面打开的下一帧会刷新布局，width发生变化）
function XUiPanelMainLineExhibition:GetHalfShowAreaWidth()
    return self:GetShowAreaWidth() / 2
end

--region 模块下拉列表
-- 初始化模块下拉列表
function XUiPanelMainLineExhibition:InitModuleDropdown()
    local XUiPanelMainLineExhibitionModuleDropdown = require("XUi/XUiFuben/MainLine/XUiPanelMainLineExhibitionModuleDropdown")
    self.UiPanelModuleDropdown = XUiPanelMainLineExhibitionModuleDropdown.New(self, self.PanelModuleDropdown)
end

function XUiPanelMainLineExhibition:SetDropdownModuleId(moduleId)
    self.UiPanelModuleDropdown:SetCurrentModuleId(moduleId)
end
--endregion

--region 滚动条
-- 滚动条的值发生变化
function XUiPanelMainLineExhibition:OnScrollBarValueChanged(v)
    -- 仅更新进度不触发回调
    if self.IsUpdateScrollBarProgress then
        return
    end

    local allWidth = self:GetAllDragAreaWidth()
    local curPosX = allWidth * v
    self.PanelModule.anchoredPosition = XLuaVector2.New(-curPosX, 0)
end

-- 显示滑动条
function XUiPanelMainLineExhibition:ShowScrollBar()
    self.IsShowScrollBar = true
    --self.ScrollBar.gameObject:SetActiveEx(true)
    XUiHelper.PlayUiNodeAnimation(self.Transform, "ScrollBarEnable")
end

-- 隐藏滑动条
function XUiPanelMainLineExhibition:HideScrollBar()
    self.IsShowScrollBar = false
    --self.ScrollBar.gameObject:SetActiveEx(false)
    XUiHelper.PlayUiNodeAnimation(self.Transform, "ScrollBarDisable")
end
--endregion

--region 新手阶段只显示部分章节，未通关1-12只显示序章和第一章
-- 是否是新手
function XUiPanelMainLineExhibition:IsNewbie()
    local params = XMVCA.XMainLine2:GetClientConfigParams("NewbieMainLineLockCondition")
    local conditionId = tonumber(params[1])
    local isReach, tips = XConditionManager.CheckCondition(conditionId)
    return isReach, tips
end

--endregion

--region 剧情书签
-- 刷新剧情书签按钮
function XUiPanelMainLineExhibition:RefreshBtnBookmark()
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

--region 生命树
-- 刷新生命树按钮
function XUiPanelMainLineExhibition:RefreshBtnLifeTree()
    local isOpen = XMVCA.XLifeTree:IsOpen()
    self.BtnLifeTree.gameObject:SetActiveEx(isOpen)

    if isOpen then
        local isRed = XMVCA.XLifeTree:IsRed()
        self.BtnLifeTree:ShowReddot(isRed)
    end
end

-- 刷新生命树按钮状态
function XUiPanelMainLineExhibition:RefreshBtnLifeTreeState()
    -- 获取生命树按钮跳转的章节Id
    if not self.IsInitLifeTreeSkipData then
        self.IsInitLifeTreeSkipData = true
        local config = XMVCA.XLifeTree:GetLifeTreeClientConfigConfigById("MainLineExhibitionSkipChapterId")
        local chapterId = tonumber(config.Values[1])
        if XTool.IsNumberValidEx(chapterId) then
            self.LifeTreeSkipModuleIndex, self.LifeTreeSkipChapterIndex = self:GetExhibitionChapterIndex(chapterId)
        end
    end

    -- 未配置跳转章节，不需要刷新按钮状态
    if not self.LifeTreeSkipModuleIndex and not self.LifeTreeSkipChapterIndex then
        return
    end

    -- 根据是否在显示区域内刷新状态
    local isInShowArea, isInShowAreaLeft = self:IsExhibitionChapterInShowArea(self.LifeTreeSkipModuleIndex, self.LifeTreeSkipChapterIndex)
    local isHighlight = isInShowArea or isInShowAreaLeft
    self.BtnLifeTree:SetDisable(not isHighlight)
end

function XUiPanelMainLineExhibition:OnBtnLifeTreeClick()
    -- 运营埋点
    local dict = {}
    dict["way"] = 1
    CS.XRecord.Record(dict, "1000041", "LifeTreeEnterWay")

    -- 配置了跳转章节，跳转章节不在显示范围内时，先跳转章节
    if self.LifeTreeSkipModuleIndex and self.LifeTreeSkipChapterIndex then
        local isInShowArea, isInShowAreaLeft = self:IsExhibitionChapterInShowArea(self.LifeTreeSkipModuleIndex, self.LifeTreeSkipChapterIndex)
        local isHighlight = isInShowArea or isInShowAreaLeft
        if not isHighlight then
            -- 定位到生命树开始的章节，然后打开生命树图鉴功能
            self:LocateByIndex(self.LifeTreeSkipModuleIndex, self.LifeTreeSkipChapterIndex, function()
                XMVCA.XLifeTree:ExOpenMainUi()
            end)
            return
        end
    end
    
    -- 打开生命树图鉴功能
    XMVCA.XLifeTree:ExOpenMainUi()
end
--endregion

-- 获取第一个显示新章节的
function XUiPanelMainLineExhibition:GetFirstNewTagExhibitionChapterId()
    if self.firstNewTagExhibitionChapterId then
        return self.firstNewTagExhibitionChapterId
    end

    if not self.firstNewTagExhibitionChapterId then
        for _, module in ipairs(self.ModuleList) do
            local chapterList = module:GetChapterList()
            for _, chapter in ipairs(chapterList) do
                if chapter:HasNewTag() then
                    self.firstNewTagExhibitionChapterId = chapter:GetChapterId()
                    return self.firstNewTagExhibitionChapterId
                end
            end
        end
    end
end

return XUiPanelMainLineExhibition