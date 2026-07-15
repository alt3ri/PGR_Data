-- 拖拽输入工具：统一屏幕坐标 / 按压状态读取
local XUiCommonDragInput = {}

local CSInput = CS.UnityEngine.Input

-- 是否有鼠标按压输入（含按下/持续/抬起那一帧）
local function HasMouseInput()
    return CSInput.GetMouseButton(0) or CSInput.GetMouseButtonDown(0) or CSInput.GetMouseButtonUp(0)
end

-- 按 pointerId 匹配触点；pointerId 为 nil 时取第 0 个触点。返回 touch 或 nil。
local function FindTouch(pointerId)
    local count = CSInput.touchCount
    if count <= 0 then
        return nil
    end
    if pointerId then
        for i = 0, count - 1 do
            local touch = CSInput.GetTouch(i)
            if touch.fingerId == pointerId then
                return touch
            end
        end
        -- 有记录触点却匹配不到：视为该触点已抬起
        return nil
    end
    return CSInput.GetTouch(0)
end

-- 是否仍有按压输入。有触摸则只认匹配 pointerId 的触点；无触摸再看鼠标。
---@param pointerId number|nil 拖拽起始记录的触点 id
---@return boolean
function XUiCommonDragInput.HasPressInput(pointerId)
    if CSInput.touchCount > 0 then
        return FindTouch(pointerId) ~= nil
    end
    return HasMouseInput()
end

-- 取当前指针屏幕坐标 (x, y)；无有效输入返回 nil。有触摸走触摸、无触摸走鼠标。
---@param pointerId number|nil 拖拽起始记录的触点 id
---@return number|nil, number|nil
function XUiCommonDragInput.GetScreenXY(pointerId)
    if CSInput.touchCount > 0 then
        local touch = FindTouch(pointerId)
        if touch then
            local pos = touch.position
            return pos.x, pos.y
        end
        return nil
    end
    if HasMouseInput() then
        local mp = CSInput.mousePosition
        return mp.x, mp.y
    end
    return nil
end

return XUiCommonDragInput
