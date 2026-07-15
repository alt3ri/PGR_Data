local XUiMainLine2PanelEntranceList = require("XUi/XUiMainLine2/XUiMainLine2PanelEntranceList")

---@class XUiMainLine2PanelChapter4P6: XUiMainLine2PanelEntranceList
---@field protected _Control XMainLine2Control
local XUiMainLine2PanelChapter4P6 = XClass(XUiMainLine2PanelEntranceList, "XUiMainLine2PanelChapter4P6")

function XUiMainLine2PanelChapter4P6:OnStart(...)
    XUiMainLine2PanelEntranceList.OnStart(self, ...)
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
    self._AnimTransCache = {}
end

-- 递归按 GameObject 名查找
function XUiMainLine2PanelChapter4P6:_FindChildByName(parent, name)
    if not parent then return nil end
    if parent.name == name then return parent end
    local count = parent.childCount
    for i = 0, count - 1 do
        local child = parent:GetChild(i)
        local found = self:_FindChildByName(child, name)
        if found then return found end
    end
    return nil
end

function XUiMainLine2PanelChapter4P6:_GetAnimTrans(name)
    if not name or name == "" then return nil end
    local cached = self._AnimTransCache[name]
    if cached ~= nil then
        return cached or nil
    end
    local trans = self:_FindChildByName(self.Transform, name)
    if not trans then
        XLog.Debug(string.format("[Chapter4P6] 未找到动画节点 name=%s", name))
        self._AnimTransCache[name] = false
        return nil
    end
    self._AnimTransCache[name] = trans
    return trans
end

function XUiMainLine2PanelChapter4P6:_PlayAnimByPath(name)
    if not name or name == "" then return end
    local trans = self:_GetAnimTrans(name)
    if not trans then return end
    XLog.Debug(string.format("[Chapter4P6] 播放动画 name=%s", name))
    trans:PlayTimelineAnimation()
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
