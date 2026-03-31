--- 车站乘客染色命令
local XLineArithmetic3Command = require("XModule/XLineArithmetic3/XLineArithmetic3Command")
local XLineArithmetic3DyeStationPassengerCommand = XClass(XLineArithmetic3Command, "XLineArithmetic3DyeStationPassengerCommand")

--- 构造函数
function XLineArithmetic3DyeStationPassengerCommand:Ctor(uiGame, gridX, gridY, color, passengerColorBefore)
    self._GridX = gridX
    self._GridY = gridY
    self._Color = color
    self._PassengerColorBefore = passengerColorBefore
    self._NewColorUid = nil
end

--- 执行命令（车站上的乘客染色动画）
function XLineArithmetic3DyeStationPassengerCommand:Execute(game, onComplete)
    local uiGame = self._UiGame

    -- 通过坐标获取乘客UID
    local passengerUid = uiGame:GetPassengerUidByPos(self._GridX, self._GridY)
    if not passengerUid then
        if onComplete then onComplete() end
        return
    end

    -- 通过UID获取乘客GameObject
    local passengerGo = uiGame:GetPassengerByUid(passengerUid)
    if not passengerGo then
        if onComplete then onComplete() end
        return
    end

    local colorPrefab = uiGame:GetColorPrefab(self._Color)
    if not colorPrefab then
        if onComplete then onComplete() end
        return
    end

    -- 实例化颜色节点并添加到乘客GameObject下
    local colorGo = CS.UnityEngine.Object.Instantiate(colorPrefab, passengerGo.transform)
    colorGo.transform.localPosition = CS.UnityEngine.Vector3.zero
    self._NewColorUid = uiGame:RegisterGameObject(colorGo)

    if onComplete then onComplete() end
end

--- 撤销命令（恢复车站乘客颜色）
function XLineArithmetic3DyeStationPassengerCommand:Undo(game, onComplete)
    local uiGame = self._UiGame

    -- 恢复 Game 层状态
    local grid = game:GetGrid({ x = self._GridX, y = self._GridY })
    if grid and grid.Passenger then
        grid.Passenger.Color = self._PassengerColorBefore
    end

    -- UI 层逻辑：通过UID销毁颜色节点
    if self._NewColorUid then
        uiGame:DestroyGameObjectByUid(self._NewColorUid)
        self._NewColorUid = nil
    end

    -- 刷新乘客 UI 颜色显示为旧颜色
    local passengerUid = uiGame:GetPassengerUidByPos(self._GridX, self._GridY)
    if passengerUid then
        local passengerGo = uiGame:GetPassengerByUid(passengerUid)
        if passengerGo then
            uiGame:UpdatePassengerColor(passengerGo, self._PassengerColorBefore)
        end
    end

    if onComplete then onComplete() end
end

return XLineArithmetic3DyeStationPassengerCommand
