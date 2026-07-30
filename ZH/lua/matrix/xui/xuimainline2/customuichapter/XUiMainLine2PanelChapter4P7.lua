local XUiMainLine2PanelEntranceList = require("XUi/XUiMainLine2/XUiMainLine2PanelEntranceList")

---@class XUiMainLine2PanelChapter4P7: XUiMainLine2PanelEntranceList
---@field protected _Control XMainLine2Control
local XUiMainLine2PanelChapter4P7 = XClass(XUiMainLine2PanelEntranceList, "XUiMainLine2PanelChapter4P7")

function XUiMainLine2PanelChapter4P7:OnStart(...)
    XUiMainLine2PanelEntranceList.OnStart(self, ...)
    self._IdleStageIndexs = self._Control:GetChapterIdleSpineStageIndexs(self.ChapterId) or {}
    self._IdleAnimPaths = self._Control:GetChapterIdleSpineName(self.ChapterId) or {}
    self:_CollectSpineComponents()
    -- P7 的 Spine 全部自驱 Idle 循环，不参与基类进度驱动
    self.SpineTrackEntryDrags = {}
    self.SpineTrackEntryBgs = {}
    self.SpineTrackEntries = {}
end

function XUiMainLine2PanelChapter4P7:OnEnable()
    XUiMainLine2PanelEntranceList.OnEnable(self)
    self._LastEntranceIndex = self:_GetCurrentEntranceIndex()
    self:_PlayIdleAnim(self._LastEntranceIndex)
end

function XUiMainLine2PanelChapter4P7:OnDisable()
    XUiMainLine2PanelEntranceList.OnDisable(self)
    self:_StopAllSpineAnim()
end

function XUiMainLine2PanelChapter4P7:OnScrollRectValueChanged(normalizedPos)
    XUiMainLine2PanelEntranceList.OnScrollRectValueChanged(self, normalizedPos)
    self:_CheckIdleAnimSwitch()
end

function XUiMainLine2PanelChapter4P7:_CollectSpineComponents()
    self._SpineComponents = {}
    local spineLink = self.Transform:Find("Spine")
    if not spineLink then return end

    local skeletonGraphics = spineLink:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonGraphic))
    for i = 0, skeletonGraphics.Length - 1 do
        table.insert(self._SpineComponents, skeletonGraphics[i])
    end
    local skeletonAnimations = spineLink:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
    for i = 0, skeletonAnimations.Length - 1 do
        table.insert(self._SpineComponents, skeletonAnimations[i])
    end
end

-- 取当前居中的关卡下标
function XUiMainLine2PanelChapter4P7:_GetCurrentEntranceIndex()
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

-- 左开右闭：取第一个满足 curIndex <= stageIdx 的段，落入该段
-- 当前关卡超出配置范围或对应段动画名为空时，回退到上一个有动画名的段
function XUiMainLine2PanelChapter4P7:_PickIdleAnimPath(curIndex)
    local fallback
    for i, stageIdx in ipairs(self._IdleStageIndexs) do
        local path = self._IdleAnimPaths[i]
        if path and path ~= "" then
            fallback = path
        end
        if curIndex <= stageIdx then
            return path and path ~= "" and path or fallback
        end
    end
    return fallback
end

function XUiMainLine2PanelChapter4P7:_PlayIdleAnim(curIndex, path)
    if not curIndex then return end
    path = path or self:_PickIdleAnimPath(curIndex)
    if not path or path == "" then
        XLog.Error(string.format("[Chapter4P7] Idle 未匹配到动画 curIndex=%d", curIndex))
        return
    end
    if #self._SpineComponents == 0 then return end
    self:_PlayAnimByPath(path, true)
    self._CurrentIdlePath = path
end

-- 跨段才切换；同段不重播，避免滚动抖动
function XUiMainLine2PanelChapter4P7:_CheckIdleAnimSwitch()
    local cur = self:_GetCurrentEntranceIndex()
    local last = self._LastEntranceIndex
    self._LastEntranceIndex = cur
    if cur == nil or cur == last then return end

    local newPath = self:_PickIdleAnimPath(cur)
    if newPath ~= self._CurrentIdlePath then
        self:_PlayIdleAnim(cur, newPath)
    end
end

function XUiMainLine2PanelChapter4P7:_PlayAnimByPath(animName, loop)
    if not animName or animName == "" then return end
    if #self._SpineComponents == 0 then return end
    for _, skeleton in ipairs(self._SpineComponents) do
        local animationState = skeleton.AnimationState
        if animationState then
            animationState:SetAnimation(0, animName, loop)
        end
    end
end

function XUiMainLine2PanelChapter4P7:_StopAllSpineAnim()
    if not self._SpineComponents then return end
    for _, skeleton in ipairs(self._SpineComponents) do
        local animationState = skeleton.AnimationState
        if animationState then
            animationState:SetEmptyAnimation(0, 0)
        end
    end
    self._CurrentIdlePath = nil
end

return XUiMainLine2PanelChapter4P7
