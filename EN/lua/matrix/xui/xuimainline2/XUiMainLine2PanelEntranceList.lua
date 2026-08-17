local tableInsert = table.insert
local stringSub = string.sub
local stringIsNilOrEmpty = string.IsNilOrEmpty
local stringLen = string.len

---@class XUiMainLine2PanelEntranceList : XUiNode
---@field private _Control XMainLine2Control
---@field GridEntrances XUiMainLine2GridEntrance[]
local XUiMainLine2PanelEntranceList = XClass(XUiNode, "XUiMainLine2PanelEntranceList")

function XUiMainLine2PanelEntranceList:OnStart(chapterId, mainId, skipStageId, lastClickStageId, isOpenStageDetail)
    self.ChapterId = chapterId
    self.MainId = mainId
    self.SkipStageId = skipStageId
    self.LastClickStageId = lastClickStageId
    self.IsOpenStageDetail = isOpenStageDetail
    self.EntranceDatas = self._Control:GetChapterEntranceDatas(chapterId)
    self.GridEntrances = {}
    self.BgIndex = 0
    self.StagePosXs = {}

    self:InitUi()
    self:InitEntrances()
    self:InitBgChange()
    self:InitPaneBgList()
    self:InitSpineAndTimeline()
    self:RegisterUiEvents()
    
    self:InitComponents()
end

function XUiMainLine2PanelEntranceList:OnEnable()
    self._Control:AddEventListener(self._Control.EventIds.FOCUS_STAGE_WITH_AREA_GROUP, self.FocusStageByStageId, self)
    self:RefreshEntrances()
    self:RefreshBgs()

    -- 跳转定位到关卡
    if self.SkipStageId then
        self:SkipToStage(self.SkipStageId, self.IsOpenStageDetail)
    else
        local isPass = self._Control:IsChapterPassed(self.ChapterId)
        if isPass then
            -- 章节通关，跳转到服务器记录打的最后一关，考虑老玩家重打主线
            local stageId = self.LastClickStageId or self._Control:GetLastPassStage(self.ChapterId)
            self:SkipToStage(stageId)
        else
            -- 章节未通关，跳转到最新的关卡
            local index = self._Control:GetChapterNextEntrance(self.ChapterId)
            self:LocateToEntrance(index)
        end
    end
    
    self.SkipStageId = nil
    self.LastClickStageId = nil
    self.IsOpenStageDetail = nil
end

function XUiMainLine2PanelEntranceList:OnDisable()
    self._Control:RemoveEventListener(self._Control.EventIds.FOCUS_STAGE_WITH_AREA_GROUP, self.FocusStageByStageId, self)
end

function XUiMainLine2PanelEntranceList:OnDestroy()
    self.ChapterId = nil
    self.MainId = nil
    self.EntranceDatas = nil
    self.GridEntrances = nil
    self.BgIndex = nil
    self.StagePosXs = nil
end

-- 初始化UI引用
function XUiMainLine2PanelEntranceList:InitUi()
    self.ScrollRect = self.ScrollRect or XUiHelper.TryGetComponent(self.Transform, "PaneStageList", "ScrollRect")
    self.ViewPort = self.ViewPort or XUiHelper.TryGetComponent(self.Transform, "PaneStageList/ViewPort", "RectTransform")
    self.PanelStageContent = self.PanelStageContent or XUiHelper.TryGetComponent(self.Transform, "PaneStageList/ViewPort/PanelStageContent", "RectTransform")
    self.LocateOffsetX = self.ScrollRect.viewport.rect.width * 0.5
end

--- 初始化扩展的组件
function XUiMainLine2PanelEntranceList:InitComponents()
    -- Message
    if self._Control.MessageControl:CheckChapterHasMessage(self.ChapterId) then
        self._MessageCom = require("XUi/XUiMainLine2/Component/UiMainLine2PanelMessageCom/XUiMainLine2PanelMessageCom").New(self.GameObject, self, self.ChapterId, self.MainId)
    end
    
    -- Area
    if self._Control.UiStageAreaControl:CheckChapterHasAreaGroup(self.ChapterId) then
        self._StageAreaCom = require("XUi/XUiMainLine2/Component/UiMainLine2StageAreaCom/XUiMainLine2StageAreaCom").New(self.GameObject, self, self.ChapterId, self.MainId)

        if self.PaneStageList then
            CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PaneStageList.content)

            ---@type XUiCommonScrollView
            self._ScrollView = require("XUi/XUiCommon/XUiCommonScrollView").New(self.PaneStageList, self, self.PaneStageList)
            self._ScrollView:Init()
            self._ScrollView:RegisterCallBack(nil, nil, nil, handler(self, self._OnScrollEndDrag), handler(self, self._OnScrollBeginDrag))
        end

        self:_InjectAreaClickInterceptor()
    end
end

function XUiMainLine2PanelEntranceList:_InjectAreaClickInterceptor()
    for _, entrance in ipairs(self.GridEntrances) do
        entrance:SetAreaClickInterceptor(function(stageId)
            return self._StageAreaCom:TryInterceptStageClick(stageId)
        end)
    end
end

function XUiMainLine2PanelEntranceList:_OnScrollBeginDrag()
    if not self._StageAreaCom then return end
    self._StageAreaCom:RecordBeginDragAreaIndex()
end

function XUiMainLine2PanelEntranceList:_OnScrollEndDrag(dragDeltaX)
    if not self._StageAreaCom then return end
    self._StageAreaCom:CheckAutoFocusOnEndDrag(dragDeltaX)
end

function XUiMainLine2PanelEntranceList:RegisterUiEvents()
    self.ScrollRect.onValueChanged:AddListener(function(value)
        self:OnScrollRectValueChanged(value)
    end)
end

function XUiMainLine2PanelEntranceList:OnScrollRectValueChanged(normalizedPos)
    -- 检测切换背景图
    self:CheckChangeBg()
    -- 刷新Spine和Timeline进度
    self:RefreshSpineAndTimelineProgress()
    -- 刷新视野中心入口特效
    self:RefreshViewCenterEntranceEffect()
end

-- 初始化入口
function XUiMainLine2PanelEntranceList:InitEntrances()
    local XUiMainLine2GridEntrance =  require("XUi/XUiMainLine2/XUiMainLine2GridEntrance")
    for i, data in pairs(self.EntranceDatas) do
        local parentGo = self:GetStageGo(i)
        local lineGo = self.PanelStageContent:Find("Line"..(i-1))
        if not parentGo then
            XLog.Error(string.format("章节预制体%s缺少Stage%s", self.Parent.ChapterPrefabName, i))
            goto CONTINUE
        end

        local stageId = data.StageIds[1]
        local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(stageId)
        local uiName = stageCfg.StageGridStyle
        local prefabName = CS.XGame.ClientConfig:GetString(uiName)
        local prefab = parentGo:LoadPrefab(prefabName)

        parentGo.gameObject:SetActiveEx(true)
        local stage = XUiMainLine2GridEntrance.New(prefab, self, data, self.ChapterId, self.MainId, parentGo, lineGo, uiName)
        stage:Open()
        tableInsert(self.GridEntrances, stage)

        :: CONTINUE ::
    end
end

-- 刷新入口列表
function XUiMainLine2PanelEntranceList:RefreshEntrances()
    for _, entrance in ipairs(self.GridEntrances) do
        entrance:Refresh()
    end
end

-- 初始化背景切换
function XUiMainLine2PanelEntranceList:InitBgChange()
    local stageIndexs = self._Control:GetChapterBgStageIndexs(self.ChapterId)
    if #stageIndexs == 0 then
        return
    end

    -- 记录切换背景入口相的anchoredPosition.x
    for _, index in ipairs(stageIndexs) do
        local stageGo = self:GetStageGo(index)
        local posX = stageGo.anchoredPosition.x
        tableInsert(self.StagePosXs, posX)
    end
end

-- 检测切换背景
function XUiMainLine2PanelEntranceList:CheckChangeBg(ignoreAnim)
    local curIndex = self:CalcuBgIndex()
    if self.BgIndex == curIndex then return end
    
    -- 背景图
    local bgStageIndexs = self._Control:GetChapterBgStageIndexs(self.ChapterId)
    for i = 1, #bgStageIndexs do
        local bg = self:GetRImgChapterBg(i)
        bg.alpha = i == curIndex and 1 or 0
    end

    -- 动画
    if not ignoreAnim then
        local animIndex = curIndex > self.BgIndex and curIndex or -curIndex
        local anim = self:GetBgQieHuanAnim(animIndex)
        if anim then
            anim:PlayTimelineAnimation()
        end
    end

    self.Parent:RefreshChapterUiColor(curIndex)
    self.BgIndex = curIndex
end

-- 计算背景下标
function XUiMainLine2PanelEntranceList:CalcuBgIndex()
    local moveLength = -self.PanelStageContent.anchoredPosition.x -- 滚动容器移动距离
    for i = #self.StagePosXs, 1, -1 do
        local posX = self.StagePosXs[i]
        -- 不需要关卡贴到屏幕左边才切换背景图，在滑动区域中心点就切换
        if moveLength > posX - self.LocateOffsetX then  
            return i
        end
    end

    return 1
end

-- 获取章节背景图
function XUiMainLine2PanelEntranceList:GetRImgChapterBg(index)
    local bgName = "RImgChapterBg" .. tostring(index)
    local rImgBg = self[bgName]
    if not rImgBg then
        rImgBg = self.Transform:Find(bgName):GetComponent(typeof(CS.UnityEngine.CanvasGroup))
        self[bgName] = rImgBg
    end
    return rImgBg
end

-- 获取背景图切换动画
function XUiMainLine2PanelEntranceList:GetBgQieHuanAnim(index)
    local animName = "BgQieHuan" .. tostring(index)
    local bgAnim = self[animName]
    if not bgAnim then
        bgAnim = self.Transform:Find("Animation/" .. animName)
        self[animName] = bgAnim
    end
    return bgAnim
end

-- 根据关卡Id获取入口下标
function XUiMainLine2PanelEntranceList:GetEntranceIndexByStageId(stageId)
    for i, data in pairs(self.EntranceDatas) do
        for _, sId in ipairs(data.StageIds) do
            if sId == stageId then
                return i
            end
        end
    end

    XLog.Error(string.format("关卡%s不属于章节%s", stageId, self.ChapterId))
    return nil
end

-- 跳转到关卡
function XUiMainLine2PanelEntranceList:SkipToStage(stageId, isOpenDetail)
    if stageId == 0 then
        return
    end

    local index = self:GetEntranceIndexByStageId(stageId)
    if not index then
        return
    end

    self:LocateToEntrance(index)
    if isOpenDetail then
        local entrance = self.GridEntrances[index]
        entrance:OnBtnStageClick()
    end
end

-- 定位到入口
function XUiMainLine2PanelEntranceList:LocateToEntrance(index)
    local stageGo = self:GetStageGo(index)
    local posX = -stageGo.anchoredPosition.x + self.LocateOffsetX
    self.PanelStageContent.anchoredPosition = CS.UnityEngine.Vector2(posX, self.PanelStageContent.anchoredPosition.y)

    self:CheckChangeBg(true)
end

-- 获取关卡挂点GameObject
function XUiMainLine2PanelEntranceList:GetStageGo(index)
    self.StageGos = self.StageGos or {}
    local stageGo = self.StageGos[index]
    if not stageGo then
        stageGo = self.PanelStageContent:Find("Stage" .. tostring(index))
        self.StageGos[index] = stageGo
    end
    return stageGo
end

-- 获取最大解锁的入口对象
function XUiMainLine2PanelEntranceList:GetMaxUnlockEntrance()
    local maxUnlockIndex = 1
    for i, entrance in ipairs(self.GridEntrances) do
        if entrance:IsPass() or entrance:IsShow() then
            maxUnlockIndex = i
        end
    end
    return maxUnlockIndex
end

-- 获取最大解锁的入口对象对应的MaxPosX
function XUiMainLine2PanelEntranceList:GetMaxUnlockEntranceMaxPosX()
    local maxUnlockIndex = self:GetMaxUnlockEntrance()
    local lastStageGo = self:GetStageGo(maxUnlockIndex)
    local maxPosX = lastStageGo.anchoredPosition.x - self.LocateOffsetX -- 关卡拖动到中间视为结束
    if maxPosX < 0 then maxPosX = 0 end
    return maxPosX
end

function XUiMainLine2PanelEntranceList:FocusStageByStageId(stageId)
    if not self._ScrollView then
        -- 没有处理聚焦的组件，不处理
        return
    end
    
    if XTool.IsTableEmpty(self.GridEntrances) then
        return
    end
    
    local stageGrid = nil

    -- 查找对应的关卡UI
    for _, grid in pairs(self.GridEntrances) do
        if grid.StageId == stageId then
            stageGrid = grid
            break
        elseif not XTool.IsTableEmpty(grid.StageIds) then
            for i, id in pairs(grid.StageIds) do
                if id == stageId then
                    stageGrid = grid
                    break
                end
            end

            if stageGrid ~= nil then
                break
            end
        end
    end

    if stageGrid == nil then
        return
    end

    -- 聚焦到中间
    -- Conetnt锚点在最左侧， 希望聚焦关卡UI在屏幕中心（不强制）
    local contentToCenter = 0

    local targetPosX = contentToCenter - stageGrid.Transform.parent.localPosition.x
    -- 越界检查，Content锚点在左侧时，即坐标为0时为起始，不可大于0，也不可小于自身长度的负数 - 屏幕宽度
    targetPosX = XMath.Clamp(targetPosX, - self.PaneStageList.content.transform.sizeDelta.x + self._ScrollView.HalfViewPortWidth , - self._ScrollView.HalfViewPortWidth)

    -- 按照当前布局计算聚焦位置
    
    self._ScrollView:PlayScrollViewMove(targetPosX, nil, true)
end

--region 背景列表 ------------------------------------------------------------------------------------------------------

-- MainLine2ClientConfig.tab的key
function XUiMainLine2PanelEntranceList:GetBgPathsKey()
    return "BgPaths" .. tostring(self.ChapterId)
end

-- MainLine2ClientConfig.tab的key
function XUiMainLine2PanelEntranceList:GetBgUnlockIndexsKey()
    return "BgUnlockIndexs" .. tostring(self.ChapterId)
end

-- MainLine2ClientConfig.tab的key
function XUiMainLine2PanelEntranceList:GetBgUnlockCueIdKey()
    return "BgUnlockCueId" .. tostring(self.ChapterId)
end

function XUiMainLine2PanelEntranceList:IsShowPaneBgList()
    local key = self:GetBgPathsKey()
    return self._Control:IsClientConfigExit(key)
end

-- 初始化背景列表
function XUiMainLine2PanelEntranceList:InitPaneBgList()
    if not self:IsShowPaneBgList() then return end
    
    -- 初始化动态滑动列表
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    local XUiMainLine2GridBg = require("XUi/XUiMainLine2/XUiMainLine2GridBg")
    self.DynamicTable = XDynamicTableNormal.New(self.PaneBgList)
    self.DynamicTable:SetProxy(XUiMainLine2GridBg, self)
    self.DynamicTable:SetDelegate(self)
    self.GridBg.gameObject:SetActiveEx(false)

    -- 与关卡滑动列表拖拽同步
    self.PaneStageList.onValueChanged:AddListener(function(v)
        local posY = self.PaneBgList.normalizedPosition.y
        self.PaneBgList.normalizedPosition = XLuaVector2.New(v.x, posY)
    end)
end

function XUiMainLine2PanelEntranceList:RefreshBgs()
    if not self:IsShowPaneBgList() then return end

    -- content的尺寸<=Viewport的尺寸时，不给拖动
    local viewport = self.PanelStageContent.parent:GetComponent(typeof(CS.UnityEngine.RectTransform))
    local canDrag = self.PanelStageContent.sizeDelta.x <= viewport.sizeDelta.x
    local CSMovementType = CS.UnityEngine.UI.ScrollRect.MovementType
    self.PaneStageList.movementType = canDrag and CSMovementType.Elastic or CSMovementType.Clamped

    local key = self:GetBgPathsKey()
    self.BgPaths = self._Control:GetClientConfigParams(key)
    self.DynamicTable:SetDataSource(self.BgPaths)
    self.DynamicTable:ReloadDataASync()
    
    -- 需要播放解锁动画的背景图
    self.PlayUnlockAnimBgs = self:GetPlayUnlockAnimBgs()
end

function XUiMainLine2PanelEntranceList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local empty4Raycast = grid.Transform:GetComponent(typeof(CS.UnityEngine.UI.XEmpty4Raycast))
        empty4Raycast.raycastTarget = false
        local isStart = index == 1
        local isEnd = index == #self.BgPaths
        local bgPath = self.BgPaths[index]
        local isUnlock = self:IsBgUnlock(index)
        grid:Refresh(bgPath, isUnlock, isStart, isEnd)
        
        -- 播放解锁动画
        if self.PlayUnlockAnimBgs and self.PlayUnlockAnimBgs[index] then
            local key = self:GetBgUnlockCueIdKey()
            local cueId = self._Control:GetClientConfigParams(key, 1)
            local cueDelay = self._Control:GetClientConfigParams(key, 2)
            grid:PlayUnlockAnim(cueId, cueDelay)
            self.PlayUnlockAnimBgs[index] = nil
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        -- 更新Content的宽度
        local sizeX = self.PanelStageContent.sizeDelta.x
        local sizeY = self.PaneBgContent.sizeDelta.y
        self.PaneBgContent.sizeDelta = XLuaVector2.New(sizeX, sizeY)
        local posX = self.PanelStageContent.localPosition.x
        local posY = self.PaneBgContent.localPosition.y
        local posZ = self.PaneBgContent.localPosition.z
        self.PaneBgContent.localPosition = XLuaVector3.New(posX, posY, posZ)
    end
end

-- 背景图是否解锁
function XUiMainLine2PanelEntranceList:IsBgUnlock(bgIndex)
    local key = self:GetBgUnlockIndexsKey()
    local entranceIndexs = self._Control:GetClientConfigParams(key)
    local entranceIndex = tonumber(entranceIndexs[bgIndex])
    ---@type XUiMainLine2GridEntrance
    local entrance = self.GridEntrances[entranceIndex]
    
    -- 没有这个下标的入口视为解锁
    if not entrance then return true end
    
    local isPass, tips = entrance:IsPass()
    return isPass
end

-- 需要播放解锁动画的背景图
function XUiMainLine2PanelEntranceList:GetPlayUnlockAnimBgs()
    if not self:IsShowPaneBgList() then return end

    -- 获取最后解锁的入口下标
    local passEntranceIdx = 0
    for i, entrance in ipairs(self.GridEntrances) do
        if entrance:IsPass() then
            passEntranceIdx = i
        end
    end
    
    -- 未解锁/本地解锁过
    local lastIdx = self._Control:GetChapterLastUnlockEntranceIndex(self.ChapterId)
    if passEntranceIdx == 0 or passEntranceIdx == lastIdx then 
        return
    end
    self._Control:SetChapterLastUnlockEntranceIndex(self.ChapterId, passEntranceIdx)
    
    -- 入口下标对应解锁背景图
    local palyAnimBgs = {}
    local key = self:GetBgUnlockIndexsKey()
    local entranceIndexs = self._Control:GetClientConfigParams(key)
    for bgIdx, entranceIdx in ipairs(entranceIndexs) do
        if tonumber(entranceIdx) == passEntranceIdx then
            palyAnimBgs[bgIdx] = true
        end
    end
    return palyAnimBgs
end

-- 获取已解锁的背景图下标
function XUiMainLine2PanelEntranceList:GetUnLockBgIndex()
    if not self:IsShowPaneBgList() then return end

    local unlockIndex = 1
    for i, _ in ipairs(self.BgPaths) do
        if self:IsBgUnlock(i) then
            unlockIndex = i
        else
            break
        end
    end
    return unlockIndex
end
--endregion -----------------------------------------------------------------------------------------------------------

--region Spine/Timeline
-- 初始化Spine和Timeline动画
function XUiMainLine2PanelEntranceList:InitSpineAndTimeline()
    self:InitSpine()
    self:InitTimeline()
    
    -- 拖拽进度的最大X坐标
    if (self.SpineTrackEntryDrags and #self.SpineTrackEntryDrags > 0) or (self.TimelineDirectorDrags and #self.TimelineDirectorDrags > 0) then
        local lastStageGo = self:GetStageGo(#self.EntranceDatas)
        self.DragMaxPosX = lastStageGo.anchoredPosition.x - self.LocateOffsetX -- 最后一个关卡拖动到中间视为结束
    end
    
    -- 关卡对应Bg进度
    if (self.SpineTrackEntryBgs and #self.SpineTrackEntryBgs > 0) or (self.TimelineDirectorBgs and #self.TimelineDirectorBgs > 0) then
        local bgStageIndexs = self._Control:GetChapterBgSpineStageIndexs(self.ChapterId)
        local bgProgressWans = self._Control:GetChapterBgSpineProgressWans(self.ChapterId)
        self.StagePosXToBgProgress = self:GenStagePosXToProgress(bgStageIndexs, bgProgressWans)
    end
    
    -- 关卡对应进度
    if (self.SpineTrackEntries and #self.SpineTrackEntries > 0) or (self.TimelineDirectors and #self.TimelineDirectors > 0) then
        local stageIndexs = self._Control:GetChapterSpineStageIndexs(self.ChapterId)
        local progressWans = self._Control:GetChapterSpineProgressWans(self.ChapterId)
        self.StagePosXToProgress = self:GenStagePosXToProgress(stageIndexs, progressWans)
    end
end

-- 初始化Spine
function XUiMainLine2PanelEntranceList:InitSpine()
    local spineLink = self.Transform:Find("Spine")
    if not spineLink or not spineLink.gameObject.activeSelf then return end

    ---@type table<number, CS.Spine.Unity.ISkeletonAnimation> 统一接口
    local spineComponents = {}
    -- 获取所有 SkeletonGraphic 组件
    local skeletonGraphics = spineLink.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonGraphic))
    for i = 0, skeletonGraphics.Length - 1 do
        tableInsert(spineComponents, skeletonGraphics[i])
    end
    -- 获取所有 SkeletonAnimation 组件
    local skeletonAnimations = spineLink.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
    for i = 0, skeletonAnimations.Length - 1 do
        tableInsert(spineComponents, skeletonAnimations[i])
    end
    if #spineComponents == 0 then return end

    local dragKey = "Drag"
    local dragKeyLength = stringLen(dragKey)
    ---@type Spine.TrackEntry 由拖拽进度控制
    self.SpineTrackEntryDrags = {}

    local bgKey = "Bg"
    local bgKeyLength = stringLen(bgKey)
    ---@type Spine.TrackEntry 由配置关卡进度控制的背景Spine
    self.SpineTrackEntryBgs = {}

    ---@type Spine.TrackEntry 由配置关卡进度控制的主Spine
    self.SpineTrackEntries = {}

    for i = 1, #spineComponents do
        local skeleton = spineComponents[i]
        -- 两者都有 AnimationState 属性，可以统一调用
        local animationState = skeleton.AnimationState
        local trackEntry = animationState and animationState:GetTrack(0) -- StartingAnimation设置默认播放动画
        -- 没有默认动画的 Spine 不参与进度驱动
        if trackEntry then
            trackEntry.TrackTime = 0 -- 设置为第0秒的状态
            trackEntry.TimeScale = 0 -- 暂停播放

            local goName = skeleton.gameObject.name
            if stringSub(goName, 1, dragKeyLength) == dragKey then
                tableInsert(self.SpineTrackEntryDrags, trackEntry)
            elseif stringSub(goName, 1, bgKeyLength) == bgKey then
                tableInsert(self.SpineTrackEntryBgs, trackEntry)
            else
                tableInsert(self.SpineTrackEntries, trackEntry)
            end
        end
    end
end

-- 初始化Timeline
function XUiMainLine2PanelEntranceList:InitTimeline()
    local timelineLink = self.Transform:Find("Timeline")
    if not timelineLink or not timelineLink.gameObject.activeSelf then return end

    ---@type table<number, CS.UnityEngine.Playables.PlayableDirector>
    local directorComponents = {}
    -- 获取所有 PlayableDirector 组件
    local directors = timelineLink.transform:GetComponentsInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
    for i = 0, directors.Length - 1 do
        tableInsert(directorComponents, directors[i])
    end
    if #directorComponents == 0 then return end

    local dragKey = "Drag"
    local dragKeyLength = stringLen(dragKey)
    ---@type CS.UnityEngine.Playables.PlayableDirector 由拖拽进度控制
    self.TimelineDirectorDrags = {}

    local bgKey = "Bg"
    local bgKeyLength = stringLen(bgKey)
    ---@type CS.UnityEngine.Playables.PlayableDirector 由配置关卡进度控制的背景Timeline
    self.TimelineDirectorBgs = {}

    ---@type CS.UnityEngine.Playables.PlayableDirector 由配置关卡进度控制的主Timeline
    self.TimelineDirectors = {}

    for i = 1, #directorComponents do
        local director = directorComponents[i]
        director:Pause()
        director.playOnAwake = false
        director.time = 0
        director:Evaluate() -- 刷新到第一帧

        local goName = director.gameObject.name
        if stringSub(goName, 1, dragKeyLength) == dragKey then
            tableInsert(self.TimelineDirectorDrags, director)
        elseif stringSub(goName, 1, bgKeyLength) == bgKey then
            tableInsert(self.TimelineDirectorBgs, director)
        else
            tableInsert(self.TimelineDirectors, director)
        end
    end
end

-- 生成关卡X位置对应进度
function XUiMainLine2PanelEntranceList:GenStagePosXToProgress(stageIndexs, progressWans)
    local result = {}
    for i, index in ipairs(stageIndexs) do
        local stageGo = self:GetStageGo(index)
        local data = {
            PosX = stageGo.anchoredPosition.x - self.LocateOffsetX, -- 不需要关卡贴到屏幕左边才切换背景图，在滑动区域中心点就切换
            Progress = progressWans[i] / 10000
        }
        tableInsert(result, data)
    end
    local maxDragLength = self.PanelStageContent.rect.width - self.ViewPort.rect.width
    tableInsert(result, 1,{ PosX = 0, Progress = 0 })
    tableInsert(result, { PosX = maxDragLength, Progress = 1 })
    return result
end

-- 获取当前进度
function XUiMainLine2PanelEntranceList:GetCurProgress(stagePosXToProgressList)
    local moveLength = -self.PanelStageContent.anchoredPosition.x -- 滚动容器移动距离
    
    -- 根据解锁关卡，限制拖拽最大距离
    local unlockMaxPosX = self:GetMaxUnlockEntranceMaxPosX()
    if moveLength > unlockMaxPosX then moveLength = unlockMaxPosX end
    
    -- 处理边界情况
    local firstData = stagePosXToProgressList[1]
    if moveLength <= firstData.PosX then return firstData.Progress end
    local lastData = stagePosXToProgressList[#stagePosXToProgressList]
    if moveLength >= lastData.PosX then return lastData.Progress end

    for i, data in ipairs(stagePosXToProgressList) do
        local nextData = stagePosXToProgressList[i + 1]
        if moveLength >= data.PosX and nextData and  moveLength <= nextData.PosX then
            local progress = data.Progress + (nextData.Progress - data.Progress) * (moveLength - data.PosX) / (nextData.PosX - data.PosX)
            return progress
        end
    end
end

-- 更新Spine和Timeline动画进度
function XUiMainLine2PanelEntranceList:RefreshSpineAndTimelineProgress()
    -- 拖拽进度
    if (self.SpineTrackEntryDrags and #self.SpineTrackEntryDrags > 0) or (self.TimelineDirectorDrags and #self.TimelineDirectorDrags > 0) then
        local moveLength = -self.PanelStageContent.anchoredPosition.x -- 滚动容器移动距离
        
        -- 根据解锁关卡，限制拖拽最大距离
        local unlockMaxPosX = self:GetMaxUnlockEntranceMaxPosX()
        if moveLength > unlockMaxPosX then moveLength = unlockMaxPosX end
        -- 处理边界情况
        if moveLength < 0 then moveLength = 0 end
        if moveLength > self.DragMaxPosX then moveLength = self.DragMaxPosX end
        local progress = moveLength / self.DragMaxPosX
        self:RefreshSpineProgress(self.SpineTrackEntryDrags, progress)
        self:RefreshTimelineProgress(self.TimelineDirectorDrags, progress)
    end

    -- 配置关卡进度控制的背景进度
    if (self.SpineTrackEntryBgs and #self.SpineTrackEntryBgs > 0) or (self.TimelineDirectorBgs and #self.TimelineDirectorBgs > 0) then
        local progress = self:GetCurProgress(self.StagePosXToBgProgress)
        self:RefreshSpineProgress(self.SpineTrackEntryBgs, progress)
        self:RefreshTimelineProgress(self.TimelineDirectorBgs, progress)
    end
    
    -- 配置关卡进度控制的主Spine
    if (self.SpineTrackEntries and #self.SpineTrackEntries > 0) or (self.TimelineDirectors and #self.TimelineDirectors > 0) then
        local progress = self:GetCurProgress(self.StagePosXToProgress)
        self:RefreshSpineProgress(self.SpineTrackEntries, progress)
        self:RefreshTimelineProgress(self.TimelineDirectors, progress)
    end
end

-- 刷新Spine trackEntry 进度
function XUiMainLine2PanelEntranceList:RefreshSpineProgress(trackEntries, progress)
    if trackEntries and #trackEntries > 0 then
        for _, trackEntry in pairs(trackEntries) do
            local animation = trackEntry and trackEntry.Animation
            if animation then
                trackEntry.TrackTime = animation.Duration * progress
            end
        end
    end
end

-- 刷新Timeline director 进度
function XUiMainLine2PanelEntranceList:RefreshTimelineProgress(directors, progress)
    if directors and #directors > 0 then
        for _, director in pairs(directors) do
            director.time = director.duration * progress
            director:Evaluate()
        end 
    end
end
--endregion

--region 视野中心Entrance特效
-- 刷新视野中心Entrance特效
function XUiMainLine2PanelEntranceList:RefreshViewCenterEntranceEffect()
    -- 视野中间关卡入口
    local midLength = -self.PanelStageContent.anchoredPosition.x + self.LocateOffsetX -- 滚动容器移动距离
    ---@type XUiMainLine2GridEntrance
    local viewCenterEntrance = nil
    for _, entrance in pairs(self.GridEntrances) do
        if not viewCenterEntrance then
            viewCenterEntrance = entrance
        else
            local distance = math.abs(midLength - entrance.ParentGo.anchoredPosition.x)
            local lastDistance = math.abs(midLength - viewCenterEntrance.ParentGo.anchoredPosition.x)
            if distance < lastDistance then
                viewCenterEntrance = entrance
            end
        end
    end
    
    -- 刷新特效显示
    local effectPath = viewCenterEntrance:GetViewCenterEffectPath()
    local isShowEffect = not stringIsNilOrEmpty(effectPath)
    if self.ViewCenterEffectLink then
        self.ViewCenterEffectLink.gameObject:SetActiveEx(isShowEffect)
    end
    if isShowEffect then
        if not self.ViewCenterEffectLink then
            local linkGo = CS.UnityEngine.GameObject("ViewCenterEffectLink")
            linkGo.transform:SetParent(self.Transform)
            linkGo:AddComponent(typeof(CS.UnityEngine.RectTransform))
            linkGo.transform.localPosition = XLuaVector3.New(0, 0, 0)
            linkGo.transform.localScale = XLuaVector3.New(1, 1, 1)
            XUiHelper.SetCanvasesSortingOrder(linkGo.transform)
            self.ViewCenterEffectLink = linkGo
        end
        self.ViewCenterEffectLink:LoadPrefab(effectPath)
    end
end

--endregion

return XUiMainLine2PanelEntranceList