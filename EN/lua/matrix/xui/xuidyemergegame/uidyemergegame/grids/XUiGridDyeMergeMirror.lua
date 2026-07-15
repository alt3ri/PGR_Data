local XUiGridDyeMerge = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMerge")

--- 镜子方块
---@class XUiGridDyeMergeMirror: XUiGridDyeMerge
---@field protected _Control
---@field Parent
---@field RImgObject1 @水平方向的镜子显示
---@field RImgObject2 @竖直方向的镜子显示
--- 可移动镜子的相关UI节点
---@field ImgSelect|nil 选中时显示
---@field BtnMove|nil 可移动点击按钮
--- 可旋转镜子的相关UI节点
---@field BtnRotate|nil 旋转点击按钮
local XUiGridDyeMergeMirror = XClass(XUiGridDyeMerge, "XUiGridDyeMergeMirror")

function XUiGridDyeMergeMirror:OnStart()
    if self.BtnMove then
        self.BtnMove:AddEventListener(handler(self, self._OnBtnMoveClick))
    end

    if self.BtnRotate then
        self.BtnRotate:AddEventListener(handler(self, self._OnBtnRotateClick))
    end
end

---@overload
function XUiGridDyeMergeMirror:Refresh(uid)
    self.Uid = uid
    local block = self._Control.GamingControl.BlocksControl:GetBlockByUid(uid)
    if not block then return end

    -- RotateIndex: 0,2 = 同一朝向(Object1)；1,3 = 另一朝向(Object2)
    local rotateIndex = block:GetRotateIndex()
    local showFirst = (rotateIndex % 2 == 0)
    if self.RImgObject2 then
        self.RImgObject2.gameObject:SetActiveEx(showFirst)
    end
    if self.RImgObject1 then
        self.RImgObject1.gameObject:SetActiveEx(not showFirst)
    end
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(false)
    end
end

function XUiGridDyeMergeMirror:_OnBtnMoveClick()
    if self._SendGridClickSignal then
        self._SendGridClickSignal(self.Uid)
    end
end

function XUiGridDyeMergeMirror:_OnBtnRotateClick()
    if self._SendGridClickSignal then
        self._SendGridClickSignal(self.Uid)
    end
end

return XUiGridDyeMergeMirror