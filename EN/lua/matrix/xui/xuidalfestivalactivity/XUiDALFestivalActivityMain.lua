--- 狂三(DAL)联动剧情关，复用 FestivalActivity 配置与圣诞外层容器，内层使用 UiDALStage 预制
---@class XUiDALFestivalActivityMain: XLuaUi
---@field PanelStageList UnityEngine.UI.ScrollRect
local XUiDALFestivalActivityMain = XLuaUiManager.Register(XLuaUi, 'UiDALFestivalActivityMain')

local XUiGridDALFestivalActivityStage = require("XUi/XUiDALFestivalActivity/XUiGridDALFestivalActivityStage")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")

-- 关卡聚焦定位：目标关卡图标中心落在屏幕水平方向的比例位置。
-- 0.5=屏幕正中；0.25=左1/4；0.75=右1/4。改此值即可稳定调整定位点，无需重测。
local FOCUS_RATIO = 0.6


--region --------- 生命周期 ---------->>>
function XUiDALFestivalActivityMain:OnAwake()
    self:InitUiView()
    self.LastOpenStage = nil
    self.StageGroup = {}
    XEventManager.AddEventListener(XEventId.EVENT_ON_FESTIVAL_CHANGED, self.RefreshFestivalNodes, self)
end

function XUiDALFestivalActivityMain:OnStart(chapterId, defaultStageId)
    self.ChapterId = chapterId
    self.Chapter = XDataCenter.FubenFestivalActivityManager.GetFestivalChapterById(chapterId)
    if not self.Chapter then
        XLog.Error(string.format("XUiDALFestivalActivityMain:OnStart() 函数错误: chapterId=%s 找不到对应的章节配置", tostring(chapterId)))
        self:Close()
        return
    end
    XMVCA.XDailyReset:MarkDateALiveEnteredToday(chapterId)
    self.ChapterTemplate = XFestivalActivityConfig.GetFestivalById(self.ChapterId)
    self:InitProxy()
    self:SetUiData(self.ChapterTemplate)
    self.NeedReset = false

    if defaultStageId then
        self:OpenDefaultStage(defaultStageId)
    end
    -- 保存点击
    XDataCenter.FubenFestivalActivityManager.SaveFestivalActivityIsOpen(chapterId)
end

function XUiDALFestivalActivityMain:OnEnable()
    self.Super.OnEnable(self)
    if self.PanelStageList and self.NeedReset then
        self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
        self:ReopenAssetPanel()
    else
        self.NeedReset = true
    end

    if not XDataCenter.MovieManager.IsPlayingMovie() then
        local festivalConfig = XFestivalActivityConfig.GetFestivalById(self.ChapterId)
        if festivalConfig and festivalConfig.ChapterBgm > 0 then
            XLuaAudioManager.PlaySoundDoNotInterrupt(festivalConfig.ChapterBgm)
        end
    end

    if self.LastOpenStage then
        self:MoveIntoStage(self.LastOpenStage)
    end

    if self.RedPointId then
        XRedPointManager.Check(self.RedPointId)
    end

    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
end

function XUiDALFestivalActivityMain:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ON_FESTIVAL_CHANGED, self.RefreshFestivalNodes, self)
end

--endregion <<<--------------------

--region ---------- 初始化 ---------->>>
function XUiDALFestivalActivityMain:InitUiView()
    self.SceneBtnBack:AddEventListener(function() self:OnBtnBackClick() end)
    self.SceneBtnMainUi:AddEventListener(function() self:OnBtnMainUiClick() end)
end

function XUiDALFestivalActivityMain:InitProxy()
    self._Proxy = require("XUi/XUiFestivalActivity/XUiFestivalActivityProxyDefault").New()
end

function XUiDALFestivalActivityMain:SetUiData(chapterTemplate)
    -- 初始化prefab组件
    local chapterGameObject = self.PanelChapter:LoadPrefab(chapterTemplate.FubenPrefab)
    local uiObj = chapterGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    -- 初始化动态生成节点的层级
    XUiHelper.SetCanvasesSortingOrder(self.PanelChapter.transform)

    -- 顶部返回/主界面由外壳的 SceneTopControl 负责（chapter 预制内的 TopControl 为遗留，已废弃）
    self.SceneTopControl.gameObject:SetActiveEx(true)
    if self.PanelStageList then
        local listCanvas = self.PanelStageList.gameObject:GetComponent(typeof(CS.UnityEngine.Canvas))
        local rootCanvas = self.GameObject:GetComponent(typeof(CS.UnityEngine.Canvas))
        if not XTool.UObjIsNil(listCanvas) and not XTool.UObjIsNil(rootCanvas) then
            listCanvas.sortingOrder = rootCanvas.sortingOrder + listCanvas.sortingOrder
        end
    end
    self.FestivalStageIds = self:GetFakeStages(chapterTemplate)
    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
    -- 界面信息
    self:SwitchFestivalBg()
    -- 加载特效
    self:LoadEffect(chapterTemplate.EffectUrl)
    local now = XTime.GetServerNowTimestamp()
    local _, endTimeSecond = XFunctionManager.GetTimeByTimeId(self.Chapter:GetTimeId())
    local isShowTime = endTimeSecond and endTimeSecond ~= 0
    self.TxtTime.gameObject:SetActiveEx(isShowTime)
    if isShowTime then
        self.TxtTime.text = XUiHelper.GetTime(endTimeSecond - now, self._Proxy:GetTimeFormatType())
        -- 走基类自动关闭：定时器由框架 OnEnable/OnDisable/OnRelease 自动启停
        self:SetAutoCloseInfo(endTimeSecond, function(isClose)
            if isClose then
                self:Close()
                XUiManager.TipErrorWithKey("ActivityMainLineEnd")
                return
            end
            self.TxtTime.text = XUiHelper.GetTime(endTimeSecond - XTime.GetServerNowTimestamp(), self._Proxy:GetTimeFormatType())
        end)
    end
    self.TxtChapterName.text = self.Chapter:GetName()
    self.TxtChapter.text = string.format("%02d", self.ChapterId)
    local itemId = XDataCenter.ItemManager.ItemId
    if self.PanelAsset then
        if not self.AssetPanel then
            self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, itemId.FreeGem, itemId.ActionPoint, itemId.Coin)
        end
    end
end

-- 背景:按当前通关进度取图,无命中回退 MainBackgound
function XUiDALFestivalActivityMain:SwitchFestivalBg()
    local bg = self.Chapter and self.Chapter:GetProgressBackgound()
    if not bg or bg == "" then
        self.RImgFestivalBg.gameObject:SetActiveEx(false)
        return
    end
    self.RImgFestivalBg.gameObject:SetActiveEx(true)
    self.RImgFestivalBg:SetRawImage(bg)
end

-- 加载特效
function XUiDALFestivalActivityMain:LoadEffect(effectUrl)
    if not effectUrl or effectUrl == "" then
        self.PanelEffect.gameObject:SetActiveEx(false)
        return
    end

    self.PanelEffect.gameObject:LoadUiEffect(effectUrl)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

--endregion <<<----------------------

--region ---------- 事件回调 ---------->>>

function XUiDALFestivalActivityMain:OnBtnBackClick()
    self:Close()
end

function XUiDALFestivalActivityMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiDALFestivalActivityMain:Close()
    self.Super.Close(self)
end

--endregion <<<----------------------

--region ---------- 界面刷新 ---------->>>


function XUiDALFestivalActivityMain:HandleStages()
    if self.FestivalStages == nil then
        self.FestivalStages = {}
    end

    for i = 1, #self.FestivalStageIds do
        local grid = self.FestivalStages[i]

        if not grid then
            local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
            if not itemStage then
                XLog.Error("XUiDALFestivalActivityMain:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
                break
            end
            -- 组件初始化
            self.StageGroup[i] = itemStage
            self.FestivalStages[i] = XUiGridDALFestivalActivityStage.New(itemStage, self)
            grid = self.FestivalStages[i]
        end

        grid:Open()
        grid:UpdateNode(self.Chapter:GetChapterId(), self.FestivalStageIds[i])
    end
    self:UpdateNodeLines()
    -- 隐藏多余组件
    local indexStage = #self.FestivalStageIds + 1
    local extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    while extraStage do
        if self.FestivalStages[indexStage] then
            self.FestivalStages[indexStage]:Close()
        else
            extraStage.gameObject:SetActiveEx(false)
        end
        indexStage = indexStage + 1
        extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    end
end

function XUiDALFestivalActivityMain:HandleStageLines()
    self.FestivalStageLine = {}
    for i = 1, #self.FestivalStageIds - 1 do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i))
        if not itemLine then
            XLog.Error("XUiDALFestivalActivityMain:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
            break
        end
        itemLine.gameObject:SetActiveEx(false)
        self.FestivalStageLine[i] = itemLine
    end

    -- 隐藏多余组件
    local indexLine = #self.FestivalStageLine + 1
    local extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    while extraLine do
        extraLine.gameObject:SetActiveEx(false)
        indexLine = indexLine + 1
        extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    end
end

-- 更新刷新
function XUiDALFestivalActivityMain:RefreshFestivalNodes()
    if not self.Chapter or not self.FestivalStageIds then return end
    for i = 1, #self.FestivalStageIds do
        if self.FestivalStages[i] then
            self.FestivalStages[i]:UpdateNode(self.Chapter:GetChapterId(), self.FestivalStageIds[i])
        end
    end
    self:UpdateNodeLines()
    -- 通关进度变化时刷新背景图
    self:SwitchFestivalBg()
    if self.PanelStageContentSizeFitter then
        self.PanelStageContentSizeFitter:SetLayoutHorizontal()
    end
end

-- 更新节点线条
function XUiDALFestivalActivityMain:UpdateNodeLines()
    if not self.Chapter or not self.FestivalStageIds then return end
    local stageLength = #self.FestivalStageIds
    for i = 2, stageLength do
        local stage = self.Chapter:GetStageByStageId(self.FestivalStageIds[i])
        local isOpen = stage and stage:GetIsShow()
        self:SetStageLineActive(i - 1, isOpen)
        if isOpen then
            self.LastOpenStage = i
        end
    end
    self:SetStageLineActive(stageLength, false)
end

function XUiDALFestivalActivityMain:SetStageLineActive(index, isActive)
    if self.FestivalStageLine[index] then
        self.FestivalStageLine[index].gameObject:SetActiveEx(isActive)
    end
end
--endregion <<<-----------------------

function XUiDALFestivalActivityMain:OpenDefaultStage(stageId)
    if not self.FestivalStageIds or not self.FestivalStages then return end
    for i = 1, #self.FestivalStageIds do
        if self.FestivalStageIds[i] == stageId and self.FestivalStages[i] then
            self.FestivalStages[i]:OnBtnStageClick()
            return
        end
    end
end

-- 选中关卡
function XUiDALFestivalActivityMain:UpdateNodesSelect(stageId)
    local stageIds = self.FestivalStageIds
    for i = 1, #stageIds do
        if self.FestivalStages[i] then
            self.FestivalStages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

-- 取消选中
function XUiDALFestivalActivityMain:ClearNodesSelect()
    for i = 1, #self.FestivalStageIds do
        if self.FestivalStages[i] then
            self.FestivalStages[i]:SetNodeSelect(false)
        end
    end
end

function XUiDALFestivalActivityMain:GetFakeStages()
    local stageIds = {}
    local stageIdList = self.Chapter:GetStageIdList()
    for i = 1, #stageIdList do
        stageIds[i] = stageIdList[i]
    end

    return stageIds
end

-- 打开剧情/战斗详情
-- 剧情关：UiDALDetailStory；战斗关：UiDALDetailBattle。
-- 均为独立弹窗（复用 UiDALStage 下预制，自带关闭按钮），关闭时回调 ClearNodesSelect。
function XUiDALFestivalActivityMain:OpenStageDetails(stageId, festivalId)
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    if not fStage then return end
    self.FStage = fStage

    local closeCb = function() self:ClearNodesSelect() end
    local stageType = fStage:GetStageType()
    if stageType == XFubenConfigs.STAGETYPE_STORY or stageType == XFubenConfigs.STAGETYPE_STORYEGG then
        XLuaUiManager.Open("UiDALDetailStory", stageId, festivalId, closeCb)
    else
        XLuaUiManager.Open("UiDALDetailBattle", stageId, festivalId, closeCb)
    end
end

--region ---------- 关卡滑动 ---------->>>
-- 把目标关卡图标中心平移到屏幕 FOCUS_RATIO 比例处，并钳制内容边界防止露白。
-- 图标屏幕中心用 WorldToScreenPoint 实测，自动吸收容器偏移与相机投影。
function XUiDALFestivalActivityMain:MoveIntoStage(stageIndex)
    local grid = self.FestivalStages[stageIndex]
    local curCenterX
    if grid and grid.GetFocusScreenCenterX then
        curCenterX = grid:GetFocusScreenCenterX()
    end
    local contentRT = self.PanelStageContent:GetComponent(typeof(CS.UnityEngine.RectTransform))
    local vpRT = self.PanelStageList:GetComponent(typeof(CS.UnityEngine.RectTransform))
    local originW = CS.XResolutionManager.OriginWidth
    local pixelPerLocal = (originW ~= 0) and (CS.UnityEngine.Screen.width / originW) or 1
    local curContentX = self.PanelStageContent.localPosition.x
    local rawTarPosX = curContentX
    if curCenterX and pixelPerLocal ~= 0 then
        local targetScreenX = CS.UnityEngine.Screen.width * FOCUS_RATIO
        rawTarPosX = curContentX + (targetScreenX - curCenterX) / pixelPerLocal
    end
    -- 边界钳制：不露白约束 c ∈ [vpW/2 - xMax, -vpW/2 - xMin]（content 与 viewport 同局部坐标系）
    local vpW = vpRT.rect.width
    local xMin = contentRT.rect.xMin
    local xMax = contentRT.rect.xMax
    local maxC = -vpW / 2 - xMin
    local minC = vpW / 2 - xMax
    local tarPosX = math.min(rawTarPosX, maxC)
    if minC < maxC then   -- 内容比视口宽时才钳右边界
        tarPosX = math.max(tarPosX, minC)
    end
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = tarPosX
    XLuaUiManager.SetMask(true)
    self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
    self._FocusScrollMoving = true
    XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        XLuaUiManager.SetMask(false)
        self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
        self.PanelStageList.velocity = Vector2.zero
        self._FocusScrollMoving = false
    end)
end

function XUiDALFestivalActivityMain:SetPanelStageListMovementType(moveMentType)
    if not self.PanelStageList then return end
    self.PanelStageList.movementType = moveMentType
end

--endregion <<<-----------------------

function XUiDALFestivalActivityMain:ReopenAssetPanel()
    if self.AssetPanel and self.AssetPanel.GameObject and self.AssetPanel.GameObject:Exist() then
        self.AssetPanel.GameObject:SetActiveEx(true)
    end
end

return XUiDALFestivalActivityMain
