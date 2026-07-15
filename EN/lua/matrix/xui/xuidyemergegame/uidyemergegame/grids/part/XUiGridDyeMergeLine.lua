--- 线条节点，不是方块类型，而是多色旋转方块的延伸表现节点
---@class XUiGridDyeMergeLine: XUiNode
---@field protected _Control
---@field Parent
---@field RImgLine UnityEngine.UI.Image
local XUiGridDyeMergeLine = XClass(XUiNode, "XUiGridDyeMergeLine")

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
    -- 定位到起终点中点，使线条居中
    local midX = (startX + endX) / 2
    local midY = (startY + endY) / 2
    self.Transform:SetLocalPosition(midX, midY, 0)
    -- atan2(dy, dx) 求起点到终点的方向角，转为度数给旋转
    local dx = endX - startX
    local dy = endY - startY
    local angle = math.deg(math.atan(dy, dx))
    self.Transform:SetLocalRotation(0, 0, angle)
    -- sizeDelta.x 控制线段视觉宽度；实际渲染长度 = sizeDelta.x × localScale.x
    -- 因此需除以 scale 将父空间距离转为 sizeDelta 的本地空间值
    local width = math.sqrt(dx * dx + dy * dy)
    local scaleX = self.Transform.localScale.x
    if scaleX ~= 0 and scaleX ~= 1 then
        width = width / scaleX
    end
    local _, oriY = self.Transform:GetUISizeDelta()
    self.Transform:SetUISizeDelta(width, oriY)
end

return XUiGridDyeMergeLine