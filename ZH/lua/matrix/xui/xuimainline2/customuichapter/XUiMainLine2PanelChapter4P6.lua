local XUiMainLine2PanelEntranceList = require("XUi/XUiMainLine2/XUiMainLine2PanelEntranceList")

---@class XUiMainLine2PanelChapter4P6: XUiMainLine2PanelEntranceList
---@field protected _Control XMainLine2Control
local XUiMainLine2PanelChapter4P6 = XClass(XUiMainLine2PanelEntranceList, "XUiMainLine2PanelChapter4P6")

function XUiMainLine2PanelChapter4P6:OnStart(...)
    XUiMainLine2PanelEntranceList.OnStart(self, ...)
    -- 4P6 自驱 Spine（SetAnimation），不参与基类按进度刷新
    self.SpineTrackEntries = {}
    self.SpineTrackEntryBgs = {}
    self.SpineTrackEntryDrags = {}
    self:_InitFlipBookAnim()
end

function XUiMainLine2PanelChapter4P6:OnEnable()
    XUiMainLine2PanelEntranceList.OnEnable(self)
    self._LastEntranceIndex = self:_GetCurrentEntranceIndex()
    self:_PlayEnterAnim(self._LastEntranceIndex)
end

function XUiMainLine2PanelChapter4P6:OnScrollRectValueChanged(normalizedPos)
    XUiMainLine2PanelEntranceList.OnScrollRectValueChanged(self, normalizedPos)
    self:_CheckSwitchAnimTrigger()
end

function XUiMainLine2PanelChapter4P6:_InitFlipBookAnim()
    local chapterId = self.ChapterId
    self._EnterStageIndex = self._Control:GetChapterEnterSpineStageIndex(chapterId) or {}
    self._EnterAnimPaths = self._Control:GetChapterEnterSpineName(chapterId) or {}
    self._SwitchStageIndex = self._Control:GetChapterSwitchSpineStageIndex(chapterId) or {}
    self._SwitchAheadPaths = self._Control:GetChapterSwitchAheadSpineName(chapterId) or {}
    self._SwitchBackwardPaths = self._Control:GetChapterSwitchBackwardSpineName(chapterId) or {}
    self:_CollectSpineComponents()
end

function XUiMainLine2PanelChapter4P6:_CollectSpineComponents()
    self._SpineComponents = {}
    local spineLink = self.Transform:Find("Spine")
    if not spineLink then return end

    local skeletonGraphics = spineLink.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonGraphic))
    for i = 0, skeletonGraphics.Length - 1 do
        table.insert(self._SpineComponents, skeletonGraphics[i])
    end
    local skeletonAnimations = spineLink.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
    for i = 0, skeletonAnimations.Length - 1 do
        table.insert(self._SpineComponents, skeletonAnimations[i])
    end
end

function XUiMainLine2PanelChapter4P6:_PlayAnimByPath(animName)
    if not animName or animName == "" then return end
    if not self._SpineComponents or #self._SpineComponents == 0 then return end
    for _, skeleton in ipairs(self._SpineComponents) do
        local animationState = skeleton.AnimationState
        if animationState then
            local trackEntry = animationState:SetAnimation(0, animName, false)
            if trackEntry then
                trackEntry.TimeScale = 1
            end
        end
    end
end

-- 取大于等于 curIndex 的最小一项作为该段的入场动画
function XUiMainLine2PanelChapter4P6:_PickEnterAnimPath(curIndex)
    for i, stageIdx in ipairs(self._EnterStageIndex) do
        if curIndex <= tonumber(stageIdx) then
            return self._EnterAnimPaths[i]
        end
    end
    return nil
end

function XUiMainLine2PanelChapter4P6:_PlayEnterAnim(curIndex)
    if not curIndex then return end
    local path = self:_PickEnterAnimPath(curIndex)
    if not path or path == "" then
        XLog.Debug(string.format("[Chapter4P6] 入场未匹配到动画 curIndex=%d", curIndex))
        return
    end
    self:_PlayAnimByPath(path)
end

function XUiMainLine2PanelChapter4P6:_GetCurrentEntranceIndex()
    if not self.GridEntrances or #self.GridEntrances == 0 then return nil end
    local midLength = -self.PanelStageContent.anchoredPosition.x + self.LocateOffsetX
    local nearestIdx, nearestDist
    for i, entrance in ipairs(self.GridEntrances) do
        local d = math.abs(midLength - entrance.ParentGo.anchoredPosition.x)
        if not nearestDist or d < nearestDist then
            nearestIdx = i
            nearestDist = d
        end
    end
    return nearestIdx
end

-- 跨越段边界时按方向播放对应动画
function XUiMainLine2PanelChapter4P6:_CheckSwitchAnimTrigger()
    local cur = self:_GetCurrentEntranceIndex()
    local last = self._LastEntranceIndex
    self._LastEntranceIndex = cur
    if cur == nil or last == nil or cur == last then return end

    for i, stageIdx in ipairs(self._SwitchStageIndex) do
        local sIdx = tonumber(stageIdx)
        if sIdx then
            if last <= sIdx and cur > sIdx then
                self:_PlayAnimByPath(self._SwitchAheadPaths[i])
            elseif last > sIdx and cur <= sIdx then
                self:_PlayAnimByPath(self._SwitchBackwardPaths[i])
            end
        end
    end
end

return XUiMainLine2PanelChapter4P6
