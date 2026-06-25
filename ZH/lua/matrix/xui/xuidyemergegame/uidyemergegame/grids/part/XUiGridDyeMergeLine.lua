--- 线条节点，不是方块类型，而是多色旋转方块的延伸表现节点
---@class XUiGridDyeMergeLine: XUiNode
---@field protected _Control XDyeMergeGameControl
---@field Parent
---@field RImgLine UnityEngine.UI.RawImage
local XUiGridDyeMergeLine = XClass(XUiNode, "XUiGridDyeMergeLine")

local UV_SCROLL_SPEED = 0
local UV_SCROLL_INTERVAL = 100

function XUiGridDyeMergeLine:OnStart()
    self._OriginalWidth = self.Transform:GetUISizeDelta()

    if self._OriginalWidth <= 0 then
        self._OriginalWidth = 1
    end

    UV_SCROLL_SPEED = XMVCA.XDyeMergeGame:GetClientDyeMergeNumberByKey("GridLineScrollSpeed")
end

function XUiGridDyeMergeLine:OnDisable()
    self:_StopUVScroll()
end

--- 刷新线条显示
---@param colorId number 颜色配置 Id
---@param startX number 起始屏幕局部坐标 X
---@param startY number 起始屏幕局部坐标 Y
---@param endX number 终点屏幕局部坐标 X
---@param endY number 终点屏幕局部坐标 Y
function XUiGridDyeMergeLine:Refresh(colorId, startX, startY, endX, endY)
    if not self.RImgLine then return end
    local color = self._Control.GamingControl:GetCfgDyeMergeBlocksColor(colorId, true)
    self.RImgLine.color = color
    self:_SetTransform(startX, startY, endX, endY)
    self:_StartUVScroll()
end

--- 设置线条变换：pivot 在起点，向终点方向延伸
function XUiGridDyeMergeLine:_SetTransform(startX, startY, endX, endY)
    self.Transform:SetLocalPosition(startX, startY, 0)
    local dx = endX - startX
    local dy = endY - startY
    local angle = math.deg(math.atan(dy, dx))
    self.Transform:SetLocalRotation(0, 0, angle)
    local width = math.sqrt(dx * dx + dy * dy)
    local scaleX = self.Transform.localScale.x
    if scaleX ~= 0 and scaleX ~= 1 then
        width = width / scaleX
    end
    local _, oriY = self.Transform:GetUISizeDelta()
    self.Transform:SetUISizeDelta(width, oriY)
    self._TileX = width / self._OriginalWidth
end

--- 启动 UV 滚动动画
function XUiGridDyeMergeLine:_StartUVScroll()
    if self._UVTimerId then return end
    self._UVOffset = 0
    self.RImgLine.uvRect = CS.UnityEngine.Rect(0, 0, self._TileX, 1)
    self._UVTimerId = XScheduleManager.ScheduleForever(function()
        self._UVOffset = (self._UVOffset + UV_SCROLL_SPEED) % 256
        self.RImgLine.uvRect = CS.UnityEngine.Rect(self._UVOffset, 0, self._TileX, 1)
    end, UV_SCROLL_INTERVAL)
end

--- 停止 UV 滚动动画并重置
function XUiGridDyeMergeLine:_StopUVScroll()
    if self._UVTimerId then
        XScheduleManager.UnSchedule(self._UVTimerId)
        self._UVTimerId = nil
    end
    self._UVOffset = 0
    if self.RImgLine then
        self.RImgLine.uvRect = CS.UnityEngine.Rect(0, 0, 1, 1)
    end
end

return XUiGridDyeMergeLine
