---@class XUiMainLine2PanelEntranceList : XUiNode
---@field private _Control XMainLine2Control
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
    self:InitChangeBgTimer()
    self:InitPaneBgList()
end

function XUiMainLine2PanelEntranceList:OnEnable()
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
    
end

function XUiMainLine2PanelEntranceList:OnDestroy()
    self:ClearChangeBgTimer()

    self.ChapterId = nil
    self.MainId = nil
    self.EntranceDatas = nil
    self.GridEntrances = nil
    self.BgIndex = nil
    self.StagePosXs = nil
end

-- 初始化UI引用
function XUiMainLine2PanelEntranceList:InitUi()
    self.PanelStageContent = self.PanelStageContent or self.Transform:Find("PaneStageList/ViewPort/PanelStageContent")
    self.ScrollRect = self.ScrollRect or XUiHelper.TryGetComponent(self.Transform, "PaneStageList", "ScrollRect")
    self.LocateOffsetX = self.ScrollRect.viewport.rect.width * 0.5
end

-- 初始化入口
function XUiMainLine2PanelEntranceList:InitEntrances()
    local XUiMainLine2GridEntrance =  require("XUi/XUiMainLine2/XUiMainLine2GridEntrance")
    for i, data in pairs(self.EntranceDatas) do
        local parentGo = self.PanelStageContent:Find("Stage"..i)
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
        table.insert(self.GridEntrances, stage)

        :: CONTINUE ::
    end
end

-- 刷新入口列表
function XUiMainLine2PanelEntranceList:RefreshEntrances()
    for _, entrance in ipairs(self.GridEntrances) do
        entrance:Refresh()
    end
end

-- 初始化切换背景定时器
function XUiMainLine2PanelEntranceList:InitChangeBgTimer()
    local stageIndexs = self._Control:GetChapterBgStageIndexs(self.ChapterId)
    if #stageIndexs == 0 then
        return
    end

    -- 记录切换背景入口相的anchoredPosition.x
    for _, index in ipairs(stageIndexs) do
        local stageGo = self.PanelStageContent:Find("Stage" .. tostring(index))
        local posX = stageGo.anchoredPosition.x
        table.insert(self.StagePosXs, posX)
    end

    self:ClearChangeBgTimer()
    self.ChangeBgTimer = XScheduleManager.ScheduleForever(function()
        self:CheckChangeBg()
    end, 100)
end

-- 检测切换背景
function XUiMainLine2PanelEntranceList:CheckChangeBg(ignoreAnim)
    local curIndex = self:CalcuBgIndex()
    if self.BgIndex ~= curIndex then
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

-- 清除切换背景定时器
function XUiMainLine2PanelEntranceList:ClearChangeBgTimer()
    if self.ChangeBgTimer then
        XScheduleManager.UnSchedule(self.ChangeBgTimer)
        self.ChangeBgTimer = nil
    end
end

-- 获取章节背景图
function XUiMainLine2PanelEntranceList:GetRImgChapterBg(index)
    local bgName = "RImgChapterBg" .. tostring(index)
    local rImgBg = self[bgName]
    if not rImgBg then
        rImgBg = self.Transform:Find(bgName):GetComponent("CanvasGroup")
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
    local stageGo = self.PanelStageContent:Find("Stage" .. tostring(index))
    local posX = -stageGo.anchoredPosition.x + self.LocateOffsetX
    self.PanelStageContent.anchoredPosition = CS.UnityEngine.Vector2(posX, self.PanelStageContent.anchoredPosition.y)

    self:CheckChangeBg(true)
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

return XUiMainLine2PanelEntranceList