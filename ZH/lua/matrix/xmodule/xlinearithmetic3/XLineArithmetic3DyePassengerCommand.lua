--- 乘客染色命令
local XLineArithmetic3Command = require("XModule/XLineArithmetic3/XLineArithmetic3Command")
---@class XLineArithmetic3DyePassengerCommand: XLineArithmetic3Command
local XLineArithmetic3DyePassengerCommand = XClass(XLineArithmetic3Command, "XLineArithmetic3DyePassengerCommand")

--- 构造函数
function XLineArithmetic3DyePassengerCommand:Ctor(uiGame, carriageIndex, color, passengerColorBefore)
    self._CarriageIndex = carriageIndex
    self._Color = color
    -- Game 层状态（从指令获取）
    self._PassengerColorBefore = passengerColorBefore
    -- UI 层状态（使用UID而不是GameObject引用）
    self._NewColorUid = nil
end

--- 执行命令（染色动画）
---@param game XLineArithmetic3Game
function XLineArithmetic3DyePassengerCommand:Execute(game, onComplete)
    local uiGame = self._UiGame

    -- 通过车厢索引获取乘客UID
    local passengerUid = uiGame:GetPassengerUidByCarriage(self._CarriageIndex)
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

--- 撤销命令（移除染色）
function XLineArithmetic3DyePassengerCommand:Undo(game, onComplete)
    local uiGame = self._UiGame

    -- 恢复 Game 层状态
    local carriages = game:GetCarriages()
    local carriage = carriages[self._CarriageIndex]
    if carriage and carriage.Passenger and self._PassengerColorBefore then
        carriage.Passenger.Color = self._PassengerColorBefore
    end

    -- UI 层逻辑：通过UID销毁颜色节点
    if self._NewColorUid then
        uiGame:DestroyGameObjectByUid(self._NewColorUid)
        self._NewColorUid = nil
    end
    if onComplete then onComplete() end
end

return XLineArithmetic3DyePassengerCommand
