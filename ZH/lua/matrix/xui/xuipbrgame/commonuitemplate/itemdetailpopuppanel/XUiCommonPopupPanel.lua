--- 通用浮窗基类，特点在于是个小界面，需要定位悬浮在指定UI旁边，且需要修正位置防止超框
---@class XUiCommonPopupPanel: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
local XUiCommonPopupPanel = XClass(XUiNode, "XUiCommonPopupPanel")

local Vector3ForCal = Vector3.zero

---@param width number
---@param height number
function XUiCommonPopupPanel:SetViewArea(width, height)
    self._ViewWidth = width
    self._ViewHeight = height
end

---@param rectTrans UnityEngine.RectTransform
function XUiCommonPopupPanel:SetPopupPanelRectTrans(rectTrans)
    self._PanelRectTrans = rectTrans
end

---@param worldPos UnityEngine.Vector3|XLuaVector3 @世界坐标
---@param pivot UnityEngine.Vector2|XLuaVector2 @轴心, 用于控制面板以哪个地方为准与坐标重合，同时也控制了布局方向
function XUiCommonPopupPanel:SetPosition(worldPos, pivot)
    if pivot then
        self._PanelRectTrans:SetPivot(pivot.x, pivot.y)
    end
    
    self._PanelRectTrans:SetPosition(worldPos.x, worldPos.y, worldPos.z)
    
    self:PositionBoundsFix()
end

function XUiCommonPopupPanel:PositionBoundsFix()
    local pivotX, pivotY = self._PanelRectTrans:GetPivot()
    local panelWidth, panelHeight = self._PanelRectTrans:GetUIRectWidthHeight()
    
    local panelLocPos = self._PanelRectTrans.localPosition
    
    -- 边界修正
    -- 计算左下角
    Vector3ForCal.x = pivotX * panelWidth
    Vector3ForCal.y = pivotY * panelHeight
    local leftDownPos = panelLocPos - Vector3ForCal

    -- 计算右上角
    Vector3ForCal.x = (1 - pivotX) * panelWidth
    Vector3ForCal.y = (1 - pivotY) * panelHeight
    local rightUpPos = panelLocPos + Vector3ForCal

    Vector3ForCal.x = self._ViewWidth / 2
    Vector3ForCal.y = self._ViewHeight / 2

    local rightUpDiff = Vector3ForCal - rightUpPos
    local leftDownDiff = leftDownPos + Vector3ForCal

    if rightUpDiff.x < 0 or rightUpDiff.y < 0 then
        Vector3ForCal.x = rightUpDiff.x < 0 and rightUpDiff.x or 0
        Vector3ForCal.y = rightUpDiff.y < 0 and rightUpDiff.y or 0

        panelLocPos = panelLocPos + Vector3ForCal

        if XMain.IsEditorDebug then
            XLog.Warning(self.__cname .. ' 浮窗触发右上位置越界修正')
        end
    end

    if leftDownDiff.x < 0 or leftDownDiff.y < 0 then
        Vector3ForCal.x = leftDownDiff.x < 0 and leftDownDiff.x or 0
        Vector3ForCal.y = leftDownDiff.y < 0 and leftDownDiff.y or 0

        panelLocPos = panelLocPos - Vector3ForCal

        if XMain.IsEditorDebug then
            XLog.Warning(self.__cname .. ' 浮窗触发左下位置越界修正')
        end
    end
end

return XUiCommonPopupPanel