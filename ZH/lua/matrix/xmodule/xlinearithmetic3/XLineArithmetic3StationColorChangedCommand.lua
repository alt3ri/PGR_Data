--- 车站颜色变更命令
local XLineArithmetic3Command = require("XModule/XLineArithmetic3/XLineArithmetic3Command")
local XLineArithmetic3StationColorChangedCommand = XClass(XLineArithmetic3Command, "XLineArithmetic3StationColorChangedCommand")

--- 构造函数
function XLineArithmetic3StationColorChangedCommand:Ctor(uiGame, gridX, gridY, color, stationColorBefore)
    self._GridX = gridX
    self._GridY = gridY
    self._Color = color
    self._StationColorBefore = stationColorBefore
end

--- 执行命令（用指令携带的颜色刷新车站显示，不从 Game 层读取）
function XLineArithmetic3StationColorChangedCommand:Execute(game, onComplete)
    local uiGame = self._UiGame
    local key = string.format("%d_%d", self._GridX, self._GridY)
    local stationGo = uiGame:GetGridElement(key)
    if stationGo then
        uiGame:UpdateStationColor(self._GridX, self._GridY, stationGo, self._Color)
    end
    if onComplete then onComplete() end
end

--- 撤销命令（恢复车站颜色）
function XLineArithmetic3StationColorChangedCommand:Undo(game, onComplete)
    local uiGame = self._UiGame

    -- 恢复 Game 层状态
    local grid = game:GetGrid({ x = self._GridX, y = self._GridY })
    if grid then
        grid.StationColor = self._StationColorBefore
    end

    -- 用旧颜色刷新 UI 层显示
    local key = string.format("%d_%d", self._GridX, self._GridY)
    local stationGo = uiGame:GetGridElement(key)
    if stationGo then
        uiGame:UpdateStationColor(self._GridX, self._GridY, stationGo, self._StationColorBefore)
    end
    if onComplete then onComplete() end
end

return XLineArithmetic3StationColorChangedCommand
