local XUiMainLine2PanelEntranceList = require("XUi/XUiMainLine2/XUiMainLine2PanelEntranceList")
---支持循环动画中间插入切换动画，进入->循环->进入下一个
---@class XUiMainLine2PanelChapter4P7: XUiMainLine2PanelEntranceList
---@field protected _Control XMainLine2Control
local XUiMainLine2PanelChapter4P7 = XClass(XUiMainLine2PanelEntranceList, "XUiMainLine2PanelChapter4P7")

function XUiMainLine2PanelChapter4P7:OnStart(...)
    XUiMainLine2PanelEntranceList.OnStart(self, ...)
    self._IdleStageIndexs = self._Control:GetChapterIdleSpineStageIndexs(self.ChapterId) or {}
    self._IdleAnimPaths = self._Control:GetChapterIdleSpineName(self.ChapterId) or {}
    self._SwitchStageIndexs = self._Control:GetChapterSwitchSpineStageIndex(self.ChapterId) or {}
    self._SwitchAheadPaths = self._Control:GetChapterSwitchAheadSpineName(self.ChapterId) or {}
    self._SwitchBackwardPaths = self._Control:GetChapterSwitchBackwardSpineName(self.ChapterId) or {}
    self._IdleSoundNames = self._Control:GetChapterIdleSoundName(self.ChapterId) or {}
    self._SwitchAheadSounds = self._Control:GetChapterSwitchAheadSoundName(self.ChapterId) or {}
    self._SwitchBackwardSounds = self._Control:GetChapterSwitchBackwardSoundName(self.ChapterId) or {}
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
    self:_StopIdleSound()
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
    self:_PlayIdleSound(curIndex)
end

function XUiMainLine2PanelChapter4P7:_PickSwitchAnimPath(last, cur)
    for i, sIdx in ipairs(self._SwitchStageIndexs) do
        if last <= sIdx and cur > sIdx then
            return self._SwitchAheadPaths[i]
        elseif last > sIdx and cur <= sIdx then
            return self._SwitchBackwardPaths[i]
        end
    end
    return nil
end

-- 跨段才切换；同段不重播，避免滚动抖动
function XUiMainLine2PanelChapter4P7:_CheckIdleAnimSwitch()
    local cur = self:_GetCurrentEntranceIndex()
    local last = self._LastEntranceIndex
    self._LastEntranceIndex = cur
    if cur == nil or cur == last then return end

    local newPath = self:_PickIdleAnimPath(cur)
    local switchPath = last and self:_PickSwitchAnimPath(last, cur)
    if switchPath and switchPath ~= "" then
        local switchSound = self:_PickSwitchSoundKey(last, cur)
        self:_PlaySwitchThenIdle(switchPath, switchSound, cur, newPath)
        return
    end

    if newPath ~= self._CurrentIdlePath then
        self:_PlayIdleAnim(cur, newPath)
    end
end

-- 跨边界时按方向取切换音效 key；无边界返回 nil
function XUiMainLine2PanelChapter4P7:_PickSwitchSoundKey(last, cur)
    for i, sIdx in ipairs(self._SwitchStageIndexs) do
        if last <= sIdx and cur > sIdx then
            return self._SwitchAheadSounds[i]
        elseif last > sIdx and cur <= sIdx then
            return self._SwitchBackwardSounds[i]
        end
    end
    return nil
end

-- 播一次切换动效，并在其后排队循环动画；同时播音效
function XUiMainLine2PanelChapter4P7:_PlaySwitchThenIdle(switchPath, switchSound, curIndex, idlePath)
    idlePath = idlePath or self:_PickIdleAnimPath(curIndex)
    if not idlePath or idlePath == "" then
        XLog.Error(string.format("[Chapter4P7] Idle 未匹配到动画 curIndex=%d", curIndex))
        return
    end
    if #self._SpineComponents == 0 then return end

    for _, skeleton in ipairs(self._SpineComponents) do
        local animationState = skeleton.AnimationState
        if animationState then
            animationState:SetAnimation(0, switchPath, false)
            animationState:AddAnimation(0, idlePath, true, 0)
        end
    end
    self._CurrentIdlePath = idlePath
    self:_PlayIdleSound(curIndex)
    if switchSound and switchSound ~= "" then
        self.AudioPlayer:PlayByKeyName(switchSound)
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

function XUiMainLine2PanelChapter4P7:_PlaySound(name)
    self.AudioPlayer:PlayByKeyName(name)
end

-- 切换循环音效
function XUiMainLine2PanelChapter4P7:_PlayIdleSound(curIndex)
    if not curIndex then return end
    local idx
    for i, stageIdx in ipairs(self._IdleStageIndexs) do
        if curIndex <= stageIdx then
            idx = i
            break
        end
    end
    if not idx then
        idx = #self._IdleStageIndexs
    end
    local key = idx and self._IdleSoundNames[idx]
    if key == self._CurrentIdleSound then return end
    if self._CurrentIdleSound then
        self.AudioPlayer:StopByKeyName(self._CurrentIdleSound)
        self._CurrentIdleSound = nil
    end
    if not key or key == "" then
        return
    end
    self.AudioPlayer:PlayByKeyName(key)
    self._CurrentIdleSound = key
end

function XUiMainLine2PanelChapter4P7:_StopIdleSound()
    if self._CurrentIdleSound then
        self.AudioPlayer:StopByKeyName(self._CurrentIdleSound)
        self._CurrentIdleSound = nil
    end
end

return XUiMainLine2PanelChapter4P7
