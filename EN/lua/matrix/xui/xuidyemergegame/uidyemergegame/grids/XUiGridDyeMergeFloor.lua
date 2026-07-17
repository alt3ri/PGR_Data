local XUiGridDyeMerge = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMerge")

---@class XUiGridDyeMergeFloor: XUiGridDyeMerge
---@field protected _Control
---@field Parent
local XUiGridDyeMergeFloor = XClass(XUiGridDyeMerge, "XUiGridDyeMergeFloor")

function XUiGridDyeMergeFloor:OnStart()
    XUiGridDyeMerge.OnStart(self)
    if self.BtnMove then
        self.BtnMove:AddEventListener(handler(self, self._OnBtnMoveClick))
    end
end

function XUiGridDyeMergeFloor:SetFloorCoord(x, y)
    self._FloorX = x
    self._FloorY = y
end

--- 设置地板背景样式：isAlt=false 显示 Bg 隐藏 Bg2，isAlt=true 显示 Bg2 隐藏 Bg
--- isAlt=true 同时标记为仅展示地板，屏蔽点击和选中高亮
function XUiGridDyeMergeFloor:SetBgStyle(isAlt)
    self._IsDisplayOnly = isAlt
    if self.Bg then
        self.Bg.gameObject:SetActiveEx(not isAlt)
    end
    if self.Bg2 then
        self.Bg2.gameObject:SetActiveEx(isAlt)
    end
end

--- 当展示可选择的地块时显示，用于选中其他可移动方块时同步显示
function XUiGridDyeMergeFloor:SetShowSelectable(isShow)
    if self._IsDisplayOnly then return end
    self.ImgSelect.gameObject:SetActiveEx(isShow)
end

function XUiGridDyeMergeFloor:_OnBtnMoveClick()
    if self._IsDisplayOnly then return end
    if self._SendGridClickSignal then
        self._SendGridClickSignal(self._FloorX, self._FloorY)
    end
end


function XUiGridDyeMergeFloor:OnRecycle()
    XUiGridDyeMerge.OnRecycle(self)
    self._FloorX = nil
    self._FloorY = nil
    self:SetBgStyle(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
end


return XUiGridDyeMergeFloor