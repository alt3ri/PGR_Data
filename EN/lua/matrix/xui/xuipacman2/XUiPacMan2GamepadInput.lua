--- PacMan2 手柄输入处理脚本
--- 用于响应手柄输入，控制游戏角色移动

---@class XUiPacMan2GamepadInput
local XUiPacMan2GamepadInput = XClass(nil, "XUiPacMan2GamepadInput")

local Input = CS.UnityEngine.Input
local KeyCode = CS.UnityEngine.KeyCode
local Cursor = CS.UnityEngine.Cursor
local CursorLockMode = CS.UnityEngine.CursorLockMode
local Time = CS.UnityEngine.Time

local Direction = {
    None = 0,
    Up = 1,
    Down = 2,
    Left = 3,
    Right = 4
}

function XUiPacMan2GamepadInput:Ctor(gameUi)
    ---@type XUiPacMan2Game
    self._GameUi = gameUi
    self._IsEnabled = false
    self._UpdateTimerId = nil

    -- 手柄输入相关
    self._LastDirection = Direction.None
    self._LastHasGamepadInput = false
    
    -- 鼠标控制相关
    self._IsUsingGamepad = false
    self._OriginalCursorLockState = CursorLockMode.None
    self._OriginalCursorVisible = true
    self._LastMousePosition = nil
    self._LockStartTime = nil
    self._UnlockDelay = 1  -- 解锁延迟时间（秒），避免鼠标闪烁
end

--- 启用手柄输入
function XUiPacMan2GamepadInput:Enable()
    if self._IsEnabled then
        return
    end

    if self._UpdateTimerId then
        XScheduleManager.UnSchedule(self._UpdateTimerId)
        self._UpdateTimerId = nil
    end

    self._OriginalCursorLockState = CursorLockMode.None
    self._OriginalCursorVisible = true
    self._IsEnabled = true

    self._UpdateTimerId = XScheduleManager.ScheduleForever(function()
        self:_UpdateInput()
    end, 0)
end

--- 禁用手柄输入
function XUiPacMan2GamepadInput:Disable()
    if not self._IsEnabled then
        return
    end

    self._IsEnabled = false

    if self._UpdateTimerId then
        XScheduleManager.UnSchedule(self._UpdateTimerId)
        self._UpdateTimerId = nil
    end

    self._LastDirection = Direction.None
    self._LockStartTime = nil

    if Cursor.lockState == CursorLockMode.Locked then
        Cursor.lockState = CursorLockMode.None
    end

    self:_RestoreCursor()
end

--- 销毁
function XUiPacMan2GamepadInput:Dispose()
    self:Disable()
    self._GameUi = nil
end

function XUiPacMan2GamepadInput:_UpdateInput()
    if not self._IsEnabled or not self._GameUi then
        return
    end

    -- 检测手柄摇杆输入
    local horizontal = Input.GetAxis("Horizontal")
    local vertical = Input.GetAxis("Vertical")
    local threshold = 0.3  -- 输入阈值，避免轻微触碰就触发
    local hasGamepadInput = math.abs(horizontal) > threshold or math.abs(vertical) > threshold
    
    if hasGamepadInput ~= (self._LastHasGamepadInput or false) then
        self._LastHasGamepadInput = hasGamepadInput
    end

    -- 手柄输入处理：锁定鼠标并隐藏
    if hasGamepadInput then
        if not self._IsUsingGamepad then
            self._IsUsingGamepad = true
        end
        if Cursor.lockState ~= CursorLockMode.Locked then
            Cursor.lockState = CursorLockMode.Locked
        end
        self._LockStartTime = Time.realtimeSinceStartup
        if Cursor.visible then
            Cursor.visible = false
        end
    else
        -- 无手柄输入时：延迟解锁，检测鼠标/键盘输入以恢复鼠标显示
        if self._IsUsingGamepad then
            if self._LockStartTime then
                local elapsedTime = Time.realtimeSinceStartup - self._LockStartTime
                if elapsedTime >= self._UnlockDelay then
                    -- 延迟时间已过，解锁鼠标但保持隐藏，等待输入
                    if Cursor.lockState == CursorLockMode.Locked then
                        Cursor.lockState = CursorLockMode.None
                        self._LastMousePosition = Input.mousePosition
                    end
                    if Cursor.visible then
                        Cursor.visible = false
                    end
                    self:_CheckMouseOrKeyboardInput()
                end
            end
        end
    end

    -- 根据输入确定方向（优先水平方向）
    local currentDirection = Direction.None
    if math.abs(horizontal) > threshold then
        if horizontal > 0 then
            currentDirection = Direction.Right
        else
            currentDirection = Direction.Left
        end
    elseif math.abs(vertical) > threshold then
        if vertical > 0 then
            currentDirection = Direction.Up
        else
            currentDirection = Direction.Down
        end
    end

    -- 方向变化时触发移动
    if currentDirection ~= self._LastDirection then
        if currentDirection == Direction.Up then
            self:_OnMoveUp()
        elseif currentDirection == Direction.Down then
            self:_OnMoveDown()
        elseif currentDirection == Direction.Left then
            self:_OnMoveLeft()
        elseif currentDirection == Direction.Right then
            self:_OnMoveRight()
        end
        self._LastDirection = currentDirection
    end
end

function XUiPacMan2GamepadInput:_OnMoveUp()
    if self._GameUi and self._GameUi.OnClickUp then
        self._GameUi:OnClickUp()
    end
end

function XUiPacMan2GamepadInput:_OnMoveDown()
    if self._GameUi and self._GameUi.OnClickDown then
        self._GameUi:OnClickDown()
    end
end

function XUiPacMan2GamepadInput:_OnMoveLeft()
    if self._GameUi and self._GameUi.OnClickLeft then
        self._GameUi:OnClickLeft()
    end
end

function XUiPacMan2GamepadInput:_OnMoveRight()
    if self._GameUi and self._GameUi.OnClickRight then
        self._GameUi:OnClickRight()
    end
end

--- 检测鼠标移动或键盘输入，用于恢复鼠标显示
function XUiPacMan2GamepadInput:_CheckMouseOrKeyboardInput()
    -- 检测鼠标移动
    local currentMousePosition = Input.mousePosition
    if self._LastMousePosition then
        local deltaX = math.abs(currentMousePosition.x - self._LastMousePosition.x)
        local deltaY = math.abs(currentMousePosition.y - self._LastMousePosition.y)
        local mouseMoveThreshold = 10  -- 鼠标移动阈值（像素）
        if deltaX > mouseMoveThreshold or deltaY > mouseMoveThreshold then
            self:_RestoreCursor()
            return
        end
    end
    self._LastMousePosition = currentMousePosition

    -- 检测键盘输入（方向键或WASD）
    local hasKeyInput = Input.GetKeyDown(KeyCode.UpArrow) or Input.GetKeyDown(KeyCode.DownArrow) or
        Input.GetKeyDown(KeyCode.LeftArrow) or Input.GetKeyDown(KeyCode.RightArrow) or
        Input.GetKeyDown(KeyCode.W) or Input.GetKeyDown(KeyCode.S) or
        Input.GetKeyDown(KeyCode.A) or Input.GetKeyDown(KeyCode.D)
    if hasKeyInput then
        self:_RestoreCursor()
        return
    end

    -- 检测鼠标点击
    local hasMouseClick = Input.GetMouseButtonDown(0) or Input.GetMouseButtonDown(1) or Input.GetMouseButtonDown(2)
    if hasMouseClick then
        self:_RestoreCursor()
    end
end

--- 恢复鼠标状态（公共方法，供外部调用）
function XUiPacMan2GamepadInput:RestoreCursor()
    self:_RestoreCursor()
end

--- 恢复鼠标状态（私有方法）
function XUiPacMan2GamepadInput:_RestoreCursor()
    if self._IsUsingGamepad then
        self._IsUsingGamepad = false
        self._LockStartTime = nil
        Cursor.lockState = self._OriginalCursorLockState
        Cursor.visible = self._OriginalCursorVisible
        self._LastMousePosition = nil
    end
end

return XUiPacMan2GamepadInput
