--- 玩法主界面
---@class XUiDyeMergeMain: XLuaUi
---@field protected _Control XDyeMergeGameControl
---@field PanelChapterTab XUiButtonGroup
local XUiDyeMergeMain = XLuaUiManager.Register(XLuaUi, "UiDyeMergeMain")

--region Ui生命周期

function XUiDyeMergeMain:OnAwake()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnMainUi:AddEventListener(XLuaUiManager.RunMain)
    self.BtnTask:AddEventListener(handler(self, self._OnBtnTaskClickEvent))
    self:BindHelpBtn(self.BtnHelp, XMVCA.XDyeMergeGame:GetCurActivityHelpKey())
end

function XUiDyeMergeMain:OnStart()
    self:InitStages()
    self:InitRewardPreviewShow()
    self:InitChapterTabs()
    self:InitReddots()
end

function XUiDyeMergeMain:OnEnable()
    self:RefreshChapterBgShow()
    self:RefreshTaskProgressShow()
    self:RefreshReddots()
    -- 刷新和显示章节解锁状态
    self:RefreshChapterUnlockShows()
    self:RefreshChapterFinishShows()
    
    self._Control:AddEventListener(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_ACTIVITY_TIMER_UPDATE, self._OnActivityTimeTickEvent, self)
    self._Control:UpdateActivityTimer()
    
    self:_RefreshMascot()
    self:_RefreshChapterDetailShow()
end

function XUiDyeMergeMain:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_ACTIVITY_TIMER_UPDATE, self._OnActivityTimeTickEvent, self)
end

--endregion

function XUiDyeMergeMain:InitStages()
    ---@type XUiPanelDyeMergeStages
    self.PanelStage = require("XUi/XUiDyeMergeGame/UiDyeMergeMain/XUiPanelDyeMergeStages").New(self.PanelChapter, self)
end

function XUiDyeMergeMain:InitRewardPreviewShow()
    self.Grid256New.gameObject:SetActiveEx(false)
    
    local rewardId = XMVCA.XDyeMergeGame:GetCurActivityPreviewRewardId()

    if not XTool.IsNumberValidEx(rewardId) then
        return
    end
    
    local rewardGoodsList = XRewardManager.GetRewardList(rewardId)
    
    XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, rewardGoodsList and #rewardGoodsList or 0, function(index, go)
        ---@type XUiGridCommon
        local grid = XUiHelper.XUiGridCommon(self, go)
        
        grid:Refresh(rewardGoodsList[index])
    end)
end

function XUiDyeMergeMain:RefreshChapterBgShow()
    local chapterId = XMVCA.XDyeMergeGame:GetLatestPassedChapterId()
    if not chapterId then return end
    local chapterCfg = XMVCA.XDyeMergeGame:GetTableDyeMergeChapterById(chapterId)
    if chapterCfg and not string.IsNilOrEmpty(chapterCfg.PassedBg) then
        self.RawImageBg:SetRawImage(chapterCfg.PassedBg)
    end
end

function XUiDyeMergeMain:InitChapterTabs()
    local chapterIds = XMVCA.XDyeMergeGame:GetCurActivityChapterIds()

    if XTool.IsTableEmpty(chapterIds) then
        return
    end
    
    local buttonList = {}

    for index = 1, #chapterIds do
        local btn = self["BtnChapterTab" .. index]

        if not btn then
            break
        end

        table.insert(buttonList, btn)

        btn:SetNameByGroup(0, XMVCA.XDyeMergeGame:GetCfgDyeMergeChapterNameById(chapterIds[index]))

        local icon = XMVCA.XDyeMergeGame:GetCfgDyeMergeChapterIconById(chapterIds[index])

        if not string.IsNilOrEmpty(icon) then
            btn:SetRawImage(icon)
        end
    end
    
    self.ChapterIds = chapterIds

    self.PanelChapterTab:Init(buttonList, handler(self, self._OnChapterTabGroupSelect), 1)
    self.PanelChapterTab:SelectIndex(self:_GetDefaultChapterIndex(chapterIds))
    
    -- 缓存章节Id和按钮列表，一一对应关系用于刷新红点
    self._ChapterBtnList = buttonList
    self._ChapterIds = chapterIds
end

function XUiDyeMergeMain:InitReddots()
    self._BtnTaskReddotId = self:AddRedPointEvent(self.BtnTask, self.OnBtnTaskReddotEvent, self, { XRedPointConditions.Types.CONDITION_DYEMERGE_TASK }, nil, false)
end

function XUiDyeMergeMain:RefreshReddots()
    XRedPointManager.Check(self._BtnTaskReddotId)

    if not XTool.IsTableEmpty(self._ChapterBtnList) and not XTool.IsTableEmpty(self._ChapterIds) then
        for i, v in pairs(self._ChapterBtnList) do
            v:ShowReddot(XMVCA.XDyeMergeGame:CheckChapterShowReddot(self._ChapterIds[i]))
        end
    end
end

function XUiDyeMergeMain:RefreshChapterUnlockShows()
    if not XTool.IsTableEmpty(self._ChapterBtnList) and not XTool.IsTableEmpty(self._ChapterIds) then
        if self._ChapterLockDescList == nil then
            self._ChapterLockDescList = {}
        end

        for i, v in ipairs(self._ChapterIds) do
            local isUnlock, lockTips = XMVCA.XDyeMergeGame:GetIsChapterUnlock(v)
            
            local btn = self._ChapterBtnList[i]

            if btn then
                if isUnlock then
                    -- 因为按钮组和自动选中的特点，不能直接全设置成Normal，只有之前状态是Disable的节点才设置Normal，其他按钮维持状态
                    if btn.ButtonState == CS.UiButtonState.Disable then
                        btn:SetDisable(false)
                    end
                else
                    btn:SetDisable(true)
                end
            end

            if not isUnlock then
                self._ChapterLockDescList[i] = lockTips
            else
                self._ChapterLockDescList[i] = nil
            end
        end
    end
end

function XUiDyeMergeMain:RefreshChapterFinishShows()
    if not XTool.IsTableEmpty(self._ChapterBtnList) and not XTool.IsTableEmpty(self._ChapterIds) then
        if self._ChapterLockDescList == nil then
            self._ChapterLockDescList = {}
        end

        for i, v in ipairs(self._ChapterIds) do
            local isAllPass = XMVCA.XDyeMergeGame:IsChapterAllPassed(v)
            local isUnlock, lockTips = XMVCA.XDyeMergeGame:GetIsChapterUnlock(v)

            local btn = self._ChapterBtnList[i]

            if btn then
                btn:ShowTag(isAllPass and isUnlock)
            end
        end
    end
end

function XUiDyeMergeMain:_RefreshChapterBtnByIndex(index)
    if not self._ChapterBtnList or not self._ChapterIds then
        return
    end
    
    local btn = self._ChapterBtnList[index]
    local chapterId = self._ChapterIds[index]

    if btn then
        btn:ShowReddot(XMVCA.XDyeMergeGame:CheckChapterShowReddot(chapterId))
    end
end

function XUiDyeMergeMain:RefreshTaskProgressShow()
    local format = XMVCA.XDyeMergeGame:GetClientDyeMergeTextByKey("TaskProgressShowLabel")
    
    local passedCount, totalCount = XMVCA.XDyeMergeGame:GetCurTaskProgress()
    
    self.BtnTask:SetNameByGroup(0, XUiHelper.FormatTextEx(format, passedCount, totalCount))
end

function XUiDyeMergeMain:_OnChapterTabGroupSelect(index)
    if self._CurChapterIndex == index then
        return
    end
    
    -- 解锁判断：初始化时就固定了各章节解锁情况即描述
    local lockTips = self._ChapterLockDescList and self._ChapterLockDescList[index] or nil

    if lockTips then
        -- 只要锁定提示不为空，则说明未解锁
        -- 判断是否解锁时，只有未解锁才会缓存锁定提示
        XUiManager.TipMsg(lockTips)
        -- 直接返回，不执行切换逻辑
        return
    end

    self._CurChapterIndex = index

    local chapterId = self.ChapterIds[index]
    
    -- 更新章节列表
    self.PanelStage:RefreshStagesByChapterId(chapterId)
    
    self:_RefreshChapterDetailShow(chapterId)

    self:_RefreshMascot()
    
    -- 记录点击
    self._Control:MarkNewChapter(chapterId)
    self:_RefreshChapterBtnByIndex(index)
end

function XUiDyeMergeMain:_RefreshChapterDetailShow(chapterId)
    if chapterId == nil then
        if XTool.IsNumberValidEx(self._CurChapterIndex) then
            chapterId = self.ChapterIds[self._CurChapterIndex]
        end
    end

    if chapterId == nil then
        return
    end
    
    local chapterCfg = XMVCA.XDyeMergeGame:GetTableDyeMergeChapterById(chapterId)

    if chapterCfg then
        --self.TxtTitle.text = chapterCfg.Name
        local allPassed = XMVCA.XDyeMergeGame:IsChapterAllPassed(chapterId)
        local desc = allPassed and chapterCfg.PassedDesc or chapterCfg.NotPassedDesc
        if not string.IsNilOrEmpty(desc) then
            self.TxtDesc.text = XUiHelper.ReplaceTextNewLine(desc)
        end
    end
end

--- 返回进度章节在 chapterIds 中的下标（1-based）
--- 规则：进度关卡所在章节；找不到或全通时返回最后一章
function XUiDyeMergeMain:_GetDefaultChapterIndex(chapterIds)
    local progressStageId = XMVCA.XDyeMergeGame:GetLatestProgressStageId()
    if progressStageId then
        for i, chapterId in ipairs(chapterIds) do
            local chapterCfg = XMVCA.XDyeMergeGame:GetTableDyeMergeChapterById(chapterId)
            if chapterCfg and not XTool.IsTableEmpty(chapterCfg.StageIds) then
                for _, stageId in ipairs(chapterCfg.StageIds) do
                    if stageId == progressStageId then
                        return i
                    end
                end
            end
        end
    end
    return #chapterIds
end

--- 刷新吉祥物到进度关卡格位置（若当前章节无进度关卡则隐藏）
function XUiDyeMergeMain:_RefreshMascot()
    local progressStageId = XMVCA.XDyeMergeGame:GetLatestProgressStageId()

    if not progressStageId or XMVCA.XDyeMergeGame:CheckPassedByStageId(progressStageId) then
        self.RImgMascot.gameObject:SetActiveEx(false)
        return
    end

    local grid = self.PanelStage:GetStageGridByStageId(progressStageId)
    if grid then
        local worldPos = grid.Transform.position
        local localPos = self.RImgMascot.transform.parent:InverseTransformPoint(worldPos)
        self.RImgMascot.transform:SetLocalPosition(localPos.x, localPos.y, 0)
        self.RImgMascot.gameObject:SetActiveEx(true)
    else
        self.RImgMascot.gameObject:SetActiveEx(false)
    end
end

function XUiDyeMergeMain:_OnBtnTaskClickEvent()
    XLuaUiManager.Open("UiDyeMergeTask")
end

--- 活动剩余时间更新
function XUiDyeMergeMain:_OnActivityTimeTickEvent(timeId)
    local now = XTime.GetServerNowTimestamp()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    
    local leftTime = math.max(endTime - now, 0)

    if self.TxtTime then
        self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    end
end

--region 红点响应

function XUiDyeMergeMain:OnBtnTaskReddotEvent(count)
    self.BtnTask:ShowReddot(count >= 0)
end

--endregion

return XUiDyeMergeMain