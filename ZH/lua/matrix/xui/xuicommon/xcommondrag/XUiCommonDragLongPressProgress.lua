-- 长按进度条面板：进度由外部（手势）按统一时钟每帧驱动 SetProgress，本组件不自跑定时器。
---@class XUiCommonDragLongPressProgress : XUiNode
local XUiCommonDragLongPressProgress = XClass(XUiNode, "XUiCommonDragLongPressProgress")

---@param order number 进度条 Canvas 排序层级
function XUiCommonDragLongPressProgress:OnStart(order)
    self.TargetTransform = nil
    self.AnchorMode = XEnumConst.CommonDrag.AnchorType.TopRight

    if self.Canvas and XTool.IsNumberValid(order) then
        self.Canvas.sortingOrder = self.Canvas.sortingOrder + order
    end

    self._hidePos = CS.UnityEngine.Vector2(-99999, -99999)
    self._tempPos = CS.UnityEngine.Vector2(0, 0)
    self._tempVec3 = CS.UnityEngine.Vector3(0, 0, 0)
end

function XUiCommonDragLongPressProgress:SetAnchorMode(anchorMode)
    self.AnchorMode = anchorMode or XEnumConst.CommonDrag.AnchorType.TopRight
end

-- 显示并定位到目标格子，进度清零
function XUiCommonDragLongPressProgress:Refresh(targetTransform)
    self.TargetTransform = targetTransform
    self:SetPositionToTarget()
    self.ImgPrecess.fillAmount = 0
end

-- 设置进度填充 [0,1]（外部每帧驱动）
function XUiCommonDragLongPressProgress:SetProgress(f)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.ImgPrecess.fillAmount = f or 0
end

-- 定位到目标格子顶部角落（按 AnchorMode 取右上 / 左上）
function XUiCommonDragLongPressProgress:SetPositionToTarget()
    if XTool.UObjIsNil(self.TargetTransform) then
        self.Transform.anchoredPosition = self._hidePos
        return
    end
    -- 计算目标格子顶部角落的世界坐标
    local rect = self.TargetTransform.rect
    local isTopLeft = self.AnchorMode == XEnumConst.CommonDrag.AnchorType.TopLeft
    self._tempVec3.x = isTopLeft and rect.xMin or rect.xMax
    self._tempVec3.y = rect.yMax
    self._tempVec3.z = 0
    local topCornerWorld = self.TargetTransform:TransformPoint(self._tempVec3)
    -- 转换为进度条父节点的本地坐标
    local localPos = self.Transform.parent:InverseTransformPoint(topCornerWorld)
    self._tempPos.x = localPos.x
    self._tempPos.y = localPos.y
    self.Transform.anchoredPosition = self._tempPos
end

function XUiCommonDragLongPressProgress:OnDisable()
    self.TargetTransform = nil
end

return XUiCommonDragLongPressProgress
