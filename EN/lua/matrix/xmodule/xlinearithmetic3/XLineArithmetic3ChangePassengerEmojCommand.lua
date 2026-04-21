--- 修改角色表情命令（支持乘客、车头）
local XLineArithmetic3Command = require("XModule/XLineArithmetic3/XLineArithmetic3Command")
local XLineArithmetic3Enum = require("XModule/XLineArithmetic3/XLineArithmetic3Enum")
---@class XLineArithmetic3ChangePassengerEmojCommand: XLineArithmetic3Command
local XLineArithmetic3ChangePassengerEmojCommand = XClass(XLineArithmetic3Command, "XLineArithmetic3ChangePassengerEmojCommand")

-- 目标类型
local TargetType = {
    Passenger = 1,  -- 乘客（格子坐标或车厢索引）
    Head = 2,       -- 车头
}

--- 构造函数
---@param uiGame XUiLineArithmetic3Game UI游戏对象
---@param gridX number|nil 格子X坐标（乘客在格子上的位置）
---@param gridY number|nil 格子Y坐标
---@param carriageIndex number|nil 车厢索引（乘客已上车时使用）
---@param emoj number 表情枚举值 (XLineArithmetic3Enum.Emoj)
---@param emojBefore number 之前的表情（用于Undo）
---@param isHead boolean|nil 是否为车头（true时忽略其他参数）
function XLineArithmetic3ChangePassengerEmojCommand:Ctor(uiGame, gridX, gridY, carriageIndex, emoj, emojBefore, isHead)
    self._GridX = gridX
    self._GridY = gridY
    self._CarriageIndex = carriageIndex
    self._Emoj = emoj
    self._EmojBefore = emojBefore
    self._IsHead = isHead or false
    self._PassengerUid = nil
end

--- 执行命令
---@param game XLineArithmetic3Game
---@param onComplete function
function XLineArithmetic3ChangePassengerEmojCommand:Execute(game, onComplete)
    local uiGame = self._UiGame

    -- 车头表情切换
    if self._IsHead then
        local headGrid = uiGame:GetHeadGrid()
        if headGrid then
            uiGame:UpdatePassengerEmoj(headGrid, self._Emoj)
        end
        if onComplete then onComplete() end
        return
    end

    -- 乘客表情切换
    -- 优先使用格子坐标获取乘客UID（格子上的乘客）
    if self._GridX and self._GridY then
        self._PassengerUid = uiGame:GetPassengerUidByPos(self._GridX, self._GridY)
    -- 否则使用车厢索引获取乘客UID（已上车的乘客）
    elseif self._CarriageIndex then
        self._PassengerUid = uiGame:GetPassengerUidByCarriage(self._CarriageIndex)
    end

    if not self._PassengerUid then
        if onComplete then onComplete() end
        return
    end

    local passengerGrid = uiGame:GetPassengerByUid(self._PassengerUid)
    if not passengerGrid then
        if onComplete then onComplete() end
        return
    end

    -- 更新乘客表情
    uiGame:UpdatePassengerEmoj(passengerGrid, self._Emoj)

    if onComplete then onComplete() end
end

--- 撤销命令
---@param game XLineArithmetic3Game
---@param onComplete function
function XLineArithmetic3ChangePassengerEmojCommand:Undo(game, onComplete)
    -- 车头表情撤销
    if self._IsHead then
        local headGrid = self._UiGame:GetHeadGrid()
        if headGrid then
            self._UiGame:UpdatePassengerEmoj(headGrid, self._EmojBefore)
        end
        -- 恢复表情状态字典
        game:SetEmojState(game:_GetHeadEmojKey(), self._EmojBefore)
        if onComplete then onComplete() end
        return
    end

    -- 乘客表情撤销
    if not self._PassengerUid then
        if onComplete then onComplete() end
        return
    end

    local passengerGrid = self._UiGame:GetPassengerByUid(self._PassengerUid)
    if passengerGrid then
        self._UiGame:UpdatePassengerEmoj(passengerGrid, self._EmojBefore)
    end

    -- 恢复表情状态字典
    if self._GridX and self._GridY then
        game:SetEmojState(game:_GetGridEmojKey(self._GridX, self._GridY), self._EmojBefore)
    elseif self._CarriageIndex then
        game:SetEmojState(game:_GetCarriageEmojKey(self._CarriageIndex), self._EmojBefore)
    end

    if onComplete then onComplete() end
end

return XLineArithmetic3ChangePassengerEmojCommand