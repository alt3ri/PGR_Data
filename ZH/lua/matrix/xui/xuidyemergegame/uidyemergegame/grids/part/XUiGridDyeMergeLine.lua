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

    self._WidthAnimScheduleId = nil
    self._WidthAnimHandler = handler(self, self._OnWidthAnimFrame)

    UV_SCROLL_SPEED = XMVCA.XDyeMergeGame:GetClientDyeMergeNumberByKey("GridLineScrollSpeed")
end

function XUiGridDyeMergeLine:OnDisable()
    self:_StopUVScroll()
    self:_StopWidthAnimation()
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

--region 宽度动画
--- 线条的视觉长度由 RectTransform.sizeDelta.x 控制（pivot在起点，x轴朝终点方向旋转）。
--- 宽度动画通过逐帧线性插值 sizeDelta.x 实现射线"伸出/缩回"的视觉效果。
--- 同时需要同步更新 _TileX（UV 横向平铺次数 = 当前宽度 / 预制原始宽度），
--- 否则纹理会在动画过程中拉伸变形。

function XUiGridDyeMergeLine:GetCurrentWidth()
    local w = self.Transform:GetUISizeDelta()
    return w
end

--- 直接设置线条宽度（跳过动画），同步更新 UV 平铺
--- _TileX = width / _OriginalWidth 保证每 _OriginalWidth 像素重复一次纹理
function XUiGridDyeMergeLine:SetCurrentWidth(width)
    local _, h = self.Transform:GetUISizeDelta()
    self.Transform:SetUISizeDelta(width, h)
    self._TileX = width / self._OriginalWidth
    if self.RImgLine then
        self.RImgLine.uvRect = CS.UnityEngine.Rect(self._UVOffset or 0, 0, self._TileX, 1)
    end
end

--- 启动从当前宽度到 targetWidth 的线性插值动画
--- 使用 ScheduleForever(handler, 0, 0) 实现逐帧驱动（间隔0 = 每帧回调）
--- handler 在 OnStart 中预创建，避免每次动画产生新闭包的 GC 开销
function XUiGridDyeMergeLine:AnimateWidth(targetWidth, duration, onComplete)
    self:_StopWidthAnimation()
    local startWidth = self:GetCurrentWidth()
    if math.abs(startWidth - targetWidth) < 0.1 then
        if onComplete then onComplete() end
        return
    end
    self._WidthAnimElapsed = 0
    self._WidthAnimDuration = duration
    self._WidthAnimStartWidth = startWidth
    self._WidthAnimTargetWidth = targetWidth
    self._WidthAnimOnComplete = onComplete
    self._WidthAnimScheduleId = XScheduleManager.ScheduleForever(self._WidthAnimHandler, 0, 0)
end

--- 逐帧回调：线性插值 t = elapsed / duration，width = lerp(start, target, t)
function XUiGridDyeMergeLine:_OnWidthAnimFrame()
    self._WidthAnimElapsed = self._WidthAnimElapsed + CS.UnityEngine.Time.deltaTime
    local t = self._WidthAnimElapsed / self._WidthAnimDuration
    if t >= 1 then
        self:SetCurrentWidth(self._WidthAnimTargetWidth)
        -- 先取回调引用再停止动画，避免 _StopWidthAnimation 清空后丢失回调
        local cb = self._WidthAnimOnComplete
        self:_StopWidthAnimation()
        if cb then cb() end
        return
    end
    local width = self._WidthAnimStartWidth + (self._WidthAnimTargetWidth - self._WidthAnimStartWidth) * t
    self:SetCurrentWidth(width)
end

function XUiGridDyeMergeLine:_StopWidthAnimation()
    if self._WidthAnimScheduleId then
        XScheduleManager.UnSchedule(self._WidthAnimScheduleId)
        self._WidthAnimScheduleId = nil
    end
    self._WidthAnimOnComplete = nil
end

--endregion

return XUiGridDyeMergeLine
