--- 乘客下车命令
local XLineArithmetic3Command = require("XModule/XLineArithmetic3/XLineArithmetic3Command")
local XLineArithmetic3Enum = require("XModule/XLineArithmetic3/XLineArithmetic3Enum")
local XLineArithmetic3DisembarkCommand = XClass(XLineArithmetic3Command, "XLineArithmetic3DisembarkCommand")

--- 构造函数
function XLineArithmetic3DisembarkCommand:Ctor(uiGame, gridX, gridY, carriageIndex, color, carriagePassengerBefore)
    self._GridX = gridX
    self._GridY = gridY
    self._CarriageIndex = carriageIndex
    self._Color = color
    -- Game 层状态（从指令获取）
    self._CarriagePassengerBefore = carriagePassengerBefore
    -- UI 层状态（使用UID而不是GameObject引用）
    self._PassengerUid = nil
    self._TargetPos = nil
end

--- 执行命令（乘客下车动画）
function XLineArithmetic3DisembarkCommand:Execute(game, onComplete)
    local uiGame = self._UiGame

    local carriageGo = uiGame:GetCarriageGo(self._CarriageIndex)
    if not carriageGo then
        if onComplete then onComplete() end
        return
    end

    -- 通过车厢索引获取乘客UID
    self._PassengerUid = uiGame:GetPassengerUidByCarriage(self._CarriageIndex)
    if not self._PassengerUid then
        XLog.Warning("[XLineArithmetic3DisembarkCommand] 车厢上没有乘客UID: " .. self._CarriageIndex)
        if onComplete then onComplete() end
        return
    end

    -- 通过UID获取乘客GameObject
    local passengerGrid = uiGame:GetPassengerByUid(self._PassengerUid)
    if not passengerGrid then
        XLog.Warning("[XLineArithmetic3DisembarkCommand] 找不到乘客GameObject, UID: " .. self._PassengerUid)
        if onComplete then onComplete() end
        return
    end

    -- 设置父节点为PanelCharacter，保持世界坐标不变
    passengerGrid.Transform:SetParent(uiGame.PanelCharacter, true)

    local startPos = carriageGo.transform.position
    self._TargetPos = uiGame:GetGridWorldPosition(self._GridX, self._GridY)
    passengerGrid.Transform.position = startPos

    local duration = 0.2
    uiGame:CreateTween(duration, function(progress)
        -- 直接使用passengerGo变量，不通过UID获取
        if passengerGrid then
            local pos = CS.UnityEngine.Vector3.Lerp(startPos, self._TargetPos, progress)
            passengerGrid.Transform:SetPosition(pos.x, pos.y, pos.z)
        end
    end, function()
        -- 更新乘客颜色（染色后的颜色）
        uiGame:UpdatePassengerColor(passengerGrid, self._Color)
        -- 设置坐标到UID的映射
        uiGame:SetPassengerUidByPos(self._GridX, self._GridY, self._PassengerUid)
        -- 清除车厢索引到乘客UID的映射
        uiGame:SetPassengerUidByCarriage(self._CarriageIndex, nil)
        if onComplete then onComplete() end
    end)
end

--- 撤销命令（乘客回到车厢）
function XLineArithmetic3DisembarkCommand:Undo(game, onComplete)
    local uiGame = self._UiGame

    -- 恢复 Game 层状态
    local grid = game:GetGrid({ x = self._GridX, y = self._GridY })
    if grid then
        grid.Passenger = nil  -- 下车前格子是空的
    end
    local carriages = game:GetCarriages()
    local carriage = carriages[self._CarriageIndex]
    if carriage then
        carriage.Passenger = self._CarriagePassengerBefore
    end

    -- UI 层逻辑
    if not self._PassengerUid then
        if onComplete then onComplete() end
        return
    end

    local passengerGrid = uiGame:GetPassengerByUid(self._PassengerUid)
    if not passengerGrid then
        if onComplete then onComplete() end
        return
    end

    -- 还原乘客颜色（下车前在车上的颜色）
    if self._CarriagePassengerBefore and self._CarriagePassengerBefore.Color then
        uiGame:UpdatePassengerColor(passengerGrid, self._CarriagePassengerBefore.Color)
    end

    local carriageGo = uiGame:GetCarriageGo(self._CarriageIndex)
    local targetPos = carriageGo and carriageGo.transform.position or self._TargetPos
    local startPos = passengerGrid.Transform.position

    local duration = XLineArithmetic3Enum.UndoDuration
    uiGame:CreateTween(duration, function(progress)
        local gridItem = uiGame:GetPassengerByUid(self._PassengerUid)
        if gridItem then
            local pos = CS.UnityEngine.Vector3.Lerp(startPos, targetPos, progress)
            gridItem.Transform:SetPosition(pos.x, pos.y, pos.z)
        end
    end, function()
        -- 设置父节点为车厢
        local gridItem = uiGame:GetPassengerByUid(self._PassengerUid)
        if gridItem then
            local carriageGo = uiGame:GetCarriageGo(self._CarriageIndex)
            if carriageGo then
                gridItem.Transform:SetParent(carriageGo.transform)
            end
        end
        -- 清除坐标到UID的映射
        uiGame:SetPassengerUidByPos(self._GridX, self._GridY, nil)
        -- 恢复车厢索引到乘客UID的映射
        uiGame:SetPassengerUidByCarriage(self._CarriageIndex, self._PassengerUid)
        if onComplete then onComplete() end
    end)
end

return XLineArithmetic3DisembarkCommand
