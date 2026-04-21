--- 上车冲突命令：乘客尝试移向车厢但被弹回
local XLineArithmetic3Command = require("XModule/XLineArithmetic3/XLineArithmetic3Command")
local XLineArithmetic3ConflictCommand = XClass(XLineArithmetic3Command, "XLineArithmetic3ConflictCommand")

local MOVE_RATIO = 0.35  -- 向车厢方向移动的比例（格距的1/4）
local MOVE_DURATION = 0.15  -- 单段移动时长（秒）

--- 构造函数
---@param uiGame XUiLineArithmetic3Game
---@param carriageIndex number 车厢索引
---@param conflictPassengers table[] 冲突乘客坐标列表 { {x, y}, ... }
function XLineArithmetic3ConflictCommand:Ctor(uiGame, carriageIndex, conflictPassengers)
    self._CarriageIndex = carriageIndex
    self._ConflictPassengers = conflictPassengers
end

--- 执行命令
function XLineArithmetic3ConflictCommand:Execute(game, onComplete)
    local uiGame = self._UiGame
    local carriageGo = uiGame:GetCarriageGo(self._CarriageIndex)
    if not carriageGo or not self._ConflictPassengers or #self._ConflictPassengers == 0 then
        if onComplete then onComplete() end
        return
    end

    local carriagePos = carriageGo.transform.position

    -- 收集每个冲突乘客的 UID 和起始位置
    local passengerInfos = {}
    for _, pos in ipairs(self._ConflictPassengers) do
        local uid = uiGame:GetPassengerUidByPos(pos.x, pos.y)
        if uid then
            local passengerGrid = uiGame:GetPassengerByUid(uid)
            if passengerGrid then
                local startPos = passengerGrid.Transform.position
                -- 向车厢方向移动 MOVE_RATIO 的距离作为目标位置
                local targetPos = CS.UnityEngine.Vector3.Lerp(startPos, carriagePos, game.ConflictMoveRatio)
                passengerInfos[#passengerInfos + 1] = {
                    uid = uid,
                    startPos = startPos,
                    targetPos = targetPos,
                }
            end
        end
    end

    if #passengerInfos == 0 then
        if onComplete then onComplete() end
        return
    end

    -- 阶段1：所有乘客同时向车厢方向移动
    local phase1Done = 0
    local function onPhase1Complete()
        phase1Done = phase1Done + 1
        if phase1Done < #passengerInfos then return end

        -- 所有乘客到位，播放冲突特效，等待完成
        uiGame:PlayConflictEffect(carriagePos)

        -- 阶段2：所有乘客同时弹回原位
        local phase2Done = 0
        local function onPhase2Complete()
            phase2Done = phase2Done + 1
            if phase2Done < #passengerInfos then return end
            if onComplete then onComplete() end
        end

        for _, info in ipairs(passengerInfos) do
            local uid = info.uid
            local currentPos = info.targetPos
            local returnPos = info.startPos
            uiGame:CreateTween(MOVE_DURATION, function(progress)
                local passengerGrid = uiGame:GetPassengerByUid(uid)
                if passengerGrid then
                    local pos = CS.UnityEngine.Vector3.Lerp(currentPos, returnPos, progress)
                    passengerGrid.Transform:SetPosition(pos.x, pos.y, pos.z)
                end
            end, onPhase2Complete)
        end
    end

    for _, info in ipairs(passengerInfos) do
        local uid = info.uid
        local startPos = info.startPos
        local targetPos = info.targetPos
        uiGame:CreateTween(game.ConflictMoveDuration, function(progress)
            local passengerGrid = uiGame:GetPassengerByUid(uid)
            if passengerGrid then
                local pos = CS.UnityEngine.Vector3.Lerp(startPos, targetPos, progress)
                passengerGrid.Transform:SetPosition(pos.x, pos.y, pos.z)
            end
        end, onPhase1Complete)

        uiGame:CreateTween(game.ConflictJumpAnimDelay, nil, function()
            -- 播放乘客跳跃动画，等待完成后回调
            local jumpTarget = uiGame:GetPassengerByUid(uid)
            if jumpTarget then
                uiGame:PlayPassengerJumpAnim(jumpTarget)
            end
        end)
    end
end

--- 撤销命令（冲突动画无需撤销，乘客位置未发生实际变化）
function XLineArithmetic3ConflictCommand:Undo(game, onComplete)
    if onComplete then onComplete() end
end

return XLineArithmetic3ConflictCommand
