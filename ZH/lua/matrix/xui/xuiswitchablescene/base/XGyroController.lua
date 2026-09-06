---@class XGyroController 陀螺仪控制器组件（纯陀螺仪逻辑，通过组合方式使用）
---@field private _Enabled boolean 是否启用
---@field private _ForceDisable boolean 强制禁用
---@field private _GyroFrequency number 陀螺仪检测频率
---@field private _EulerXLimit number X轴角度限制阈值
---@field private _EulerZKeep number Z轴保持角度
---@field private _MoveXKeep number 鼠标移动保持距离
---@field private _CheckGyroTime number 上次检测时间
---@field private _OnDirectionChanged function 方向变化回调
---@field private _OnSpeedChanged function 速度变化回调
---@field private _OnInputEnd function 输入结束回调（PC模式松开按键时）
---@field private _CloudMotionHandler function 云游戏姿态回调（缓存复用，Add/Remove 必须传同一函数对象）
---@field private _SpeedCalculatorByAngle function 根据角度计算速度（外部注入）
---@field private _SpeedCalculatorByDistance function 根据距离计算速度（外部注入）
---@field private _InputChecker function 输入检测器（外部注入，用于PC模式）
local XGyroController = XClass(nil, "XGyroController")

local Reference = CS.UnityEngine.Quaternion.Euler(90, 0, 0)
local Time = CS.UnityEngine.Time
local Input = CS.UnityEngine.Input
local XUiPcMode = XDataCenter.UiPcManager.XUiPcMode

---方向常量
XGyroController.Direction = {
    Sequential = 1, -- 正序
    Reverse = 2     -- 倒序
}

---创建陀螺仪控制器
---@param gyroFrequency number 陀螺仪检测频率
---@param eulerXLimit number X轴角度限制阈值
---@param eulerZKeep number Z轴保持角度
---@param moveXKeep number 鼠标移动保持距离
function XGyroController:Ctor(gyroFrequency, eulerXLimit, eulerZKeep, moveXKeep)
    self._Enabled = false
    self._ForceDisable = false
    self._CheckGyroTime = 0

    -- 配置
    self._GyroFrequency = gyroFrequency or 0.1
    self._EulerXLimit = eulerXLimit or 45
    self._EulerZKeep = eulerZKeep or 5
    self._MoveXKeep = moveXKeep or 10

    -- 回调
    self._OnDirectionChanged = nil
    self._OnSpeedChanged = nil
    self._OnInputEnd = nil

    -- 云游戏姿态回调（Add/Remove 依赖委托相等性，必须全程复用同一个函数对象）
    self._CloudMotionHandler = handler(self, self._OnCloudMotion)

    -- 速度计算器（外部注入）
    self._SpeedCalculatorByAngle = nil
    self._SpeedCalculatorByDistance = nil

    -- 输入检测器（外部注入，用于PC模式）
    self._InputChecker = nil

    -- PC模式状态
    self._PcState = {
        active = false,
        startPos = 0
    }
end

--region 生命周期

---启用陀螺仪
function XGyroController:Enable()
    if self._Enabled then return end
    self._Enabled = true

    if XDataCenter.UiPcManager.GetUiPcMode() == XUiPcMode.CloudGame then
        XDataCenter.CloudGameManager.AddMotionListener(self._CloudMotionHandler)
    else
        CS.UnityEngine.Input.gyro.enabled = true
    end
end

---禁用陀螺仪
function XGyroController:Disable()
    if not self._Enabled then return end
    self._Enabled = false

    if XDataCenter.UiPcManager.GetUiPcMode() == XUiPcMode.CloudGame then
        XDataCenter.CloudGameManager.RemoveMotionListener(self._CloudMotionHandler)
    end
end

---销毁
function XGyroController:OnDestroy()
    self:Disable()
    self._CloudMotionHandler = nil
    self._OnDirectionChanged = nil
    self._OnSpeedChanged = nil
    self._OnInputEnd = nil
    self._SpeedCalculatorByAngle = nil
    self._SpeedCalculatorByDistance = nil
    self._InputChecker = nil
end

---是否启用中
function XGyroController:IsEnabled()
    return self._Enabled and not self._ForceDisable
end

--endregion

--region 配置与回调

---设置强制禁用
---@param disable boolean
function XGyroController:SetForceDisable(disable)
    self._ForceDisable = disable
end

---设置方向变化回调
---@param callback function(direction: number)
function XGyroController:SetOnDirectionChanged(callback)
    self._OnDirectionChanged = callback
end

---设置速度变化回调
---@param callback function(speedValue: number, angleOrDistance: number)
function XGyroController:SetOnSpeedChanged(callback)
    self._OnSpeedChanged = callback
end

---设置输入结束回调（PC模式松开按键时调用，用于恢复默认速度但保持当前方向）
---@param callback function()
function XGyroController:SetOnInputEnd(callback)
    self._OnInputEnd = callback
end

---设置根据角度计算速度的函数
---@param calculator function(angle: number): number
function XGyroController:SetSpeedCalculatorByAngle(calculator)
    self._SpeedCalculatorByAngle = calculator
end

---设置根据距离计算速度的函数（PC模式）
---@param calculator function(distance: number): number
function XGyroController:SetSpeedCalculatorByDistance(calculator)
    self._SpeedCalculatorByDistance = calculator
end

---设置输入检测器（PC模式自定义输入检测）
---输入检测器返回值：isInputActive: boolean, inputValue: number 或 nil
---当 isInputActive 为 true 时，inputValue 表示输入值（如鼠标移动距离）
---当 isInputActive 为 false 时，表示输入结束，需要重置
---@param checker function(): isInputActive, inputValue
function XGyroController:SetInputChecker(checker)
    self._InputChecker = checker
end

---更新配置
---@param gyroFrequency number
---@param eulerXLimit number
---@param eulerZKeep number
---@param moveXKeep number
function XGyroController:UpdateConfig(gyroFrequency, eulerXLimit, eulerZKeep, moveXKeep)
    if gyroFrequency then
        self._GyroFrequency = gyroFrequency
    end
    if eulerXLimit then
        self._EulerXLimit = eulerXLimit
    end
    if eulerZKeep then
        self._EulerZKeep = eulerZKeep
    end
    if moveXKeep then
        self._MoveXKeep = moveXKeep
    end
end

--endregion

--region 更新（每帧调用）

---更新陀螺仪输入
function XGyroController:Update()
    if not self:IsEnabled() then return end

    local mode = XDataCenter.UiPcManager.GetUiPcMode()
    if mode == XUiPcMode.Pc then
        self:_UpdatePc()
    elseif mode == XUiPcMode.Default then
        local nowTime = Time.time
        if nowTime - self._CheckGyroTime >= self._GyroFrequency then
            self._CheckGyroTime = nowTime
            self:_UpdateGyro()
        end
    end
end

--endregion

--region 内部：输入处理

---处理陀螺仪输入
function XGyroController:_UpdateGyro()
    local q = Input.gyro.attitude
    local deviceRotation = CS.UnityEngine.Quaternion(q.x, q.y, -q.z, -q.w)
    local adjusted = Reference * deviceRotation
    local euler = adjusted.eulerAngles

    if euler.x <= self._EulerXLimit or euler.x >= (360 - self._EulerXLimit) then
        local pitch = euler.z > 180 and euler.z - 360 or euler.z
        self:_ProcessAngle(math.abs(pitch), pitch >= 0)
    else
        -- 输入结束，通知业务层（业务层决定是否保持方向）
        if self._OnInputEnd then
            self._OnInputEnd()
        end
    end
end

---处理PC模式输入
function XGyroController:_UpdatePc()
    if self._InputChecker then
        -- 使用外部注入的输入检测器
        local isActive, value = self._InputChecker()
        if isActive then
            local absValue = math.abs(value)

            -- 计算速度
            local speedValue = self:_CalculateSpeedByDistance(absValue)
            if self._OnSpeedChanged then
                self._OnSpeedChanged(speedValue, absValue)
            end

            -- 判断方向
            if absValue > self._MoveXKeep then
                local direction = value >= 0 and XGyroController.Direction.Reverse or XGyroController.Direction.Sequential
                if self._OnDirectionChanged then
                    self._OnDirectionChanged(direction)
                end
            end
        elseif isActive == false then
            -- 输入结束，通知业务层（业务层决定是否保持方向）
            if self._OnInputEnd then
                self._OnInputEnd()
            end
        end
    end
end

---处理云游戏姿态
---@param attitude table { pitch: number, roll: number }
function XGyroController:_OnCloudMotion(attitude)
    if not self:IsEnabled() or not attitude then
        return
    end

    local pitch = attitude.pitch / 100
    local roll = attitude.roll / 100

    if math.abs(roll) >= 90 - self._EulerXLimit then
        self:_ProcessAngle(math.abs(pitch), pitch >= 0)
    else
        -- 输入结束，通知业务层（业务层决定是否保持方向）
        if self._OnInputEnd then
            self._OnInputEnd()
        end
    end
end

--endregion

--region 内部：结果处理

---处理角度（通用）
---@param absAngle number 角度绝对值
---@param isPositive boolean 是否正向
function XGyroController:_ProcessAngle(absAngle, isPositive)
    local speedValue = self:_CalculateSpeedByAngle(absAngle)
    if self._OnSpeedChanged then
        self._OnSpeedChanged(speedValue, absAngle)
    end

    if absAngle > self._EulerZKeep then
        local direction = isPositive and XGyroController.Direction.Sequential or XGyroController.Direction.Reverse
        if self._OnDirectionChanged then
            self._OnDirectionChanged(direction)
        end
    end
end

---根据角度计算速度
---@param angle number
---@return number
function XGyroController:_CalculateSpeedByAngle(angle)
    if self._SpeedCalculatorByAngle then
        return self._SpeedCalculatorByAngle(angle)
    end
    return 1
end

---根据距离计算速度
---@param distance number
---@return number
function XGyroController:_CalculateSpeedByDistance(distance)
    if self._SpeedCalculatorByDistance then
        return self._SpeedCalculatorByDistance(distance)
    end
    return 1
end

---重置为默认状态
function XGyroController:_ResetToDefault()
    if self._OnDirectionChanged then
        self._OnDirectionChanged(XGyroController.Direction.Sequential)
    end
    if self._OnSpeedChanged then
        self._OnSpeedChanged(1, 0)
    end
end

--endregion

return XGyroController