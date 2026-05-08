---@class XUiBigWorldMapTitle : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field CanvasGroup UnityEngine.CanvasGroup
---@field Parent XUiBigWorldMap
---@field _Control XBigWorldMapControl
local XUiBigWorldMapTitle = XClass(XUiNode, "XUiBigWorldMapTitle")

function XUiBigWorldMapTitle:OnDisable()
    self:_RemoveTimer()
    self.CanvasGroup.alpha = self._IsShow and 1 or 0
end

function XUiBigWorldMapTitle:Refresh(text)
    self.TxtTitle.text = text
end

function XUiBigWorldMapTitle:Init()
    self._Target = false
    self._MinScale = 0
    self._MaxScale = 1
    self._Group = table.empty
    self._IsShow = true
    self._Timer = false
end

function XUiBigWorldMapTitle:SetTarget(target)
    if not XTool.UObjIsNil(target) then
        local binder = self.GameObject:AddComponent(typeof(CS.XTransformBind))

        binder:SetTarget(target)
        self._Target = target
    end
end

function XUiBigWorldMapTitle:SetScaleRange(min, max)
    self._MinScale = min or 0
    self._MaxScale = max or 1
end

function XUiBigWorldMapTitle:SetGroup(groupIds)
    self._Group = {}
    if not XTool.IsTableEmpty(groupIds) then
        for _, groupId in pairs(groupIds) do
            self._Group[groupId] = true
        end
    end
end

function XUiBigWorldMapTitle:SetShow(scale)
    if self._IsActive then
        local isShow = scale >= self._MinScale and scale <= self._MaxScale

        self._IsShow = isShow
        self.CanvasGroup.alpha = isShow and 1 or 0
    end
end

function XUiBigWorldMapTitle:SetActive(isActive, scale)
    self._IsActive = isActive
    self:_RemoveTimer()
    self:SetShow(scale)

    if not isActive then
        self.CanvasGroup.alpha = 0
    end
end

function XUiBigWorldMapTitle:ChangeActive(groupId, scale)
    self:SetActive(self._Group[groupId], scale)
end

function XUiBigWorldMapTitle:ChangeScale(scale)
    if not self._IsActive then
        return
    end

    if scale >= self._MinScale and scale <= self._MaxScale then
        self:_TryChangeShow(true)
    else
        self:_TryChangeShow(false)
    end
end

function XUiBigWorldMapTitle:_TryChangeShow(isShow)
    if self._IsShow ~= isShow then
        self._IsShow = isShow
        self:_RegisterTimer()
    end
end

function XUiBigWorldMapTitle:_RegisterTimer()
    local aplha = self._IsShow and 0 or 1
    local targetAlpha = self._IsShow and 1 or 0
    local delta = (targetAlpha - aplha) / (0.01 * XScheduleManager.SECOND)

    self:_RemoveTimer()
    self.CanvasGroup.alpha = aplha
    self._Timer = XScheduleManager.ScheduleForever(function()
        aplha = aplha + delta
        self.CanvasGroup.alpha = aplha

        if (self._IsShow and aplha >= 1) or (not self._IsShow and aplha <= 0) then
            self.CanvasGroup.alpha = targetAlpha
            self:_RemoveTimer()
        end
    end, 1)
end

function XUiBigWorldMapTitle:_RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

return XUiBigWorldMapTitle
