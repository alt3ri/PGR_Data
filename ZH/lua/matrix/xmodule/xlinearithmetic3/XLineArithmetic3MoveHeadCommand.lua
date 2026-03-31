--- 移动车头命令
local XLineArithmetic3Command = require("XModule/XLineArithmetic3/XLineArithmetic3Command")
local XLineArithmetic3Enum = require("XModule/XLineArithmetic3/XLineArithmetic3Enum")
local XLineArithmetic3MoveHeadCommand = XClass(XLineArithmetic3Command, "XLineArithmetic3MoveHeadCommand")

--- 构造函数
---@param uiGame XUiLineArithmetic3Game UI游戏对象
---@param targetX number 目标X坐标
---@param targetY number 目标Y坐标
---@param headPosBefore table 移动前的车头位置
function XLineArithmetic3MoveHeadCommand:Ctor(uiGame, targetX, targetY, headPosBefore)
    self._TargetX = targetX
    self._TargetY = targetY
    -- Game 层状态（从指令获取）
    self._GameHeadPosBefore = headPosBefore
    -- 是否真的添加了 TraveledPath
    self._DidAddTraveledPath = false
    -- UI 层状态（在 Execute 时填充）
    self._StartHeadPos = nil
    self._StartCarriagePositions = {}
    self._TargetPos = nil
end

--- 执行命令（正向动画）
function XLineArithmetic3MoveHeadCommand:Execute(game, onComplete)
    local uiGame = self._UiGame

    -- 保存 UI 层状态
    local headGo = uiGame:GetHeadGo()
    if not headGo then
        if onComplete then onComplete() end
        return
    end
    self._StartHeadPos = headGo.transform.position
    self._TargetPos = uiGame:GetGridWorldPosition(self._TargetX, self._TargetY)

    for i = 1, uiGame:GetCarriageCount() do
        local carriageGo = uiGame:GetCarriageGo(i)
        if carriageGo then
            self._StartCarriagePositions[i] = carriageGo.transform.position
        end
    end

    -- 执行正向动画
    self:_PlayTween(self._StartHeadPos, self._TargetPos, self._StartCarriagePositions, self._StartHeadPos, function()
        -- 动画完成后，更新 Game 层状态，记录是否真的添加了
        self._DidAddTraveledPath = game:AddTraveledPath({ x = self._TargetX, y = self._TargetY })
        if onComplete then onComplete() end
    end)
end

--- 撤销命令（反向动画）
function XLineArithmetic3MoveHeadCommand:Undo(game, onComplete)
    local uiGame = self._UiGame
    local headGo = uiGame:GetHeadGo()
    if not headGo or not self._StartHeadPos then
        if onComplete then onComplete() end
        return
    end

    -- 恢复 Game 层状态
    if self._GameHeadPosBefore then
        game:SetHeadPos(self._GameHeadPosBefore)
    end
    -- 只有 Execute 时真的添加了，才移除
    if self._DidAddTraveledPath then
        game:RemoveLastTraveledPath()
    end

    -- 当前 UI 位置作为起点，回到之前的位置
    local currentHeadPos = headGo.transform.position
    local currentCarriagePositions = {}
    for i = 1, uiGame:GetCarriageCount() do
        local carriageGo = uiGame:GetCarriageGo(i)
        if carriageGo then
            currentCarriagePositions[i] = carriageGo.transform.position
        end
    end

    -- 执行反向动画（使用全局 undo 时长）
    self:_PlayTween(currentHeadPos, self._StartHeadPos, currentCarriagePositions, self._StartCarriagePositions, onComplete, XLineArithmetic3Enum.UndoDuration)
end

--- 播放移动动画
---@param durationOverride number|nil 可选的时长覆盖（用于 undo 加速）
function XLineArithmetic3MoveHeadCommand:_PlayTween(headFrom, headTo, carriagesFrom, carriagesTo, onComplete, durationOverride)
    local uiGame = self._UiGame
    local duration = durationOverride or 0.3

    uiGame:CreateTween(duration, function(progress)
        -- 车头移动
        local headGo = uiGame:GetHeadGo()
        if headGo then
            local headPos = CS.UnityEngine.Vector3.Lerp(headFrom, headTo, progress)
            headGo.transform.position = headPos
        end

        -- 车厢移动
        for i = 1, uiGame:GetCarriageCount() do
            local carriageGo = uiGame:GetCarriageGo(i)
            if carriageGo and carriagesFrom[i] then
                local targetPos = type(carriagesTo) == "table" and carriagesTo[i] or carriagesTo
                if targetPos then
                    local carriagePos = CS.UnityEngine.Vector3.Lerp(carriagesFrom[i], targetPos, progress)
                    carriageGo.transform.position = carriagePos
                end
            end
        end
    end, onComplete)
end

return XLineArithmetic3MoveHeadCommand
