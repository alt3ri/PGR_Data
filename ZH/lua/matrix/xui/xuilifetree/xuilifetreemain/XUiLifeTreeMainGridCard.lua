local CSRectTransformUtility = CS.UnityEngine.RectTransformUtility

---@class XUiLifeTreeMainGridCard : XUiNode
---@field _Control XLifeTreeControl
local XUiLifeTreeMainGridCard = XClass(XUiNode, "XUiLifeTreeMainGridCard")

-- 更新位置
function XUiLifeTreeMainGridCard:UpdatePosition()
    self._UiCamera = self._UiCamera or CS.XUiManager.Instance.UiCamera
    local screenPos3D  = self.Parent.UiFarCamera:WorldToScreenPoint(self.Follow3DGo.position)
    local screenPos2D = XLuaVector2.New(screenPos3D.x, screenPos3D.y)
    local success, localPoint = CSRectTransformUtility.ScreenPointToLocalPointInRectangle(self.Transform.parent, screenPos2D, self._UiCamera)
    if success then
        self.Transform.localPosition = XLuaVector3.New(localPoint.x, localPoint.y, 0)
    end
end

return XUiLifeTreeMainGridCard
