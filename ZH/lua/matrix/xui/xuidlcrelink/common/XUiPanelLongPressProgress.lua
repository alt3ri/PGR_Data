-- 长按进度条面板
---@class XUiPanelLongPressProgress : XUiNode
---@field private _Control XDlcRelinkControl
local XUiPanelLongPressProgress = XClass(XUiNode, "XUiPanelLongPressProgress")

function XUiPanelLongPressProgress:OnStart(order)
    self.AnimaTimer = nil
    self.TargetTransform = nil

    if self.Canvas and XTool.IsNumberValid(order) then
        self.Canvas.sortingOrder = order
    end

    self._hidePos = CS.UnityEngine.Vector2(-99999, -99999)
    self._tempPos = CS.UnityEngine.Vector2(0, 0)
    self._tempVec3 = CS.UnityEngine.Vector3(0, 0, 0)

    self.ShowTime = tonumber(self._Control:GetClientConfig("LongPressProgressBarShowTime") or 0)
end

function XUiPanelLongPressProgress:Refresh(targetTransform, onComplete)
    self.TargetTransform = targetTransform
    self:SetPositionToTarget()
    self:PlayAnima(self.ShowTime, onComplete)
end

-- 将进度条定位到目标格子的右上角
function XUiPanelLongPressProgress:SetPositionToTarget()
    if not self.TargetTransform or XTool.UObjIsNil(self.TargetTransform) then
        self.Transform.anchoredPosition = self._hidePos
        return
    end
    -- 计算目标格子右上角的世界坐标
    local rect = self.TargetTransform.rect
    self._tempVec3.x = rect.xMax
    self._tempVec3.y = rect.yMax
    self._tempVec3.z = 0
    local topRightWorld = self.TargetTransform:TransformPoint(self._tempVec3)
    -- 转换为进度条父节点的本地坐标
    local localPos = self.Transform.parent:InverseTransformPoint(topRightWorld)
    self._tempPos.x = localPos.x
    self._tempPos.y = localPos.y
    self.Transform.anchoredPosition = self._tempPos
end

-- 播放进度动画
function XUiPanelLongPressProgress:PlayAnima(duration, onComplete)
    self:StopAnima()
    self.OnComplete = onComplete
    self.ImgPrecess.fillAmount = 0
    self.AnimaTimer = XUiHelper.Tween(duration, function(f)
        if XTool.UObjIsNil(self.GameObject) or not self.GameObject.activeSelf then
            self.OnComplete = nil
            return true
        end
        self.ImgPrecess.fillAmount = f
    end, function()
        if self.OnComplete then
            self.OnComplete()
            self.OnComplete = nil
        end
    end)
end

-- 停止动画
function XUiPanelLongPressProgress:StopAnima()
    if self.AnimaTimer then
        XScheduleManager.UnSchedule(self.AnimaTimer)
        self.AnimaTimer = nil
    end
    self.OnComplete = nil
end

function XUiPanelLongPressProgress:OnDisable()
    self:StopAnima()
    self.TargetTransform = nil
end

return XUiPanelLongPressProgress
