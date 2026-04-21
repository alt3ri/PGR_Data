--- 乘客上车命令
local XLineArithmetic3Command = require("XModule/XLineArithmetic3/XLineArithmetic3Command")
local XLineArithmetic3Enum = require("XModule/XLineArithmetic3/XLineArithmetic3Enum")
local XLineArithmetic3BoardCommand = XClass(XLineArithmetic3Command, "XLineArithmetic3BoardCommand")

--- 构造函数
---@param uiGame XUiLineArithmetic3Game UI游戏对象
---@param gridX number 格子X坐标
---@param gridY number 格子Y坐标
---@param carriageIndex number 车厢索引
---@param color number 乘客颜色
---@param gridPassengerBefore table 上车前格子上的乘客
function XLineArithmetic3BoardCommand:Ctor(uiGame, gridX, gridY, carriageIndex, color, gridPassengerBefore, isInfected)
    self._GridX = gridX
    self._GridY = gridY
    self._CarriageIndex = carriageIndex
    self._Color = color
    -- Game 层状态（从指令获取）
    self._GridPassengerBefore = gridPassengerBefore
    self._IsInfected = isInfected
    -- UI 层状态（使用UID而不是GameObject引用）
    self._PassengerUid = nil
    self._PassengerStartPos = nil
end

--- 执行命令（乘客上车动画）
---@param game XLineArithmetic3Game
function XLineArithmetic3BoardCommand:Execute(game, onComplete)
    local uiGame = self._UiGame

    -- 通过坐标获取乘客UID
    self._PassengerUid = uiGame:GetPassengerUidByPos(self._GridX, self._GridY)
    if not self._PassengerUid then
        if onComplete then onComplete() end
        return
    end

    local passengerGrid = uiGame:GetPassengerByUid(self._PassengerUid)
    if not passengerGrid then
        if onComplete then onComplete() end
        return
    end
    -- 更新乘客颜色（染色后的颜色）
    uiGame:UpdatePassengerColor(passengerGrid, self._Color)

    local carriageGo = uiGame:GetCarriageGo(self._CarriageIndex)
    if not carriageGo then
        if onComplete then onComplete() end
        return
    end

    -- 清除坐标到UID的映射（乘客离开原位置）
    uiGame:SetPassengerUidByPos(self._GridX, self._GridY, nil)

    self._PassengerStartPos = passengerGrid.Transform.position
    local targetPos = carriageGo.transform.position

    -- 播放乘客跳跃动画，等待完成后回调
    local jumpTarget = uiGame:GetPassengerByUid(self._PassengerUid)
    if jumpTarget then
        uiGame:PlayPassengerJumpAnim(jumpTarget)
    end
    
    uiGame:CreateDelayCall(function()
        uiGame:CreateTween(game.BoardMoveDuration, function(progress)
            local gridItem = uiGame:GetPassengerByUid(self._PassengerUid)
            if gridItem then
                local pos = CS.UnityEngine.Vector3.Lerp(self._PassengerStartPos, targetPos, progress)
                gridItem.Transform:SetPosition(pos.x, pos.y, pos.z)
            end
        end, function()
            local gridItem = uiGame:GetPassengerByUid(self._PassengerUid)
            if gridItem then
                gridItem.Transform:SetParent(carriageGo.transform)
                -- 记录车厢索引到乘客UID的映射
                uiGame:SetPassengerUidByCarriage(self._CarriageIndex, self._PassengerUid)
            end
            -- 播放上车音效
            self:_PlayBoardSound()
            
            --播放上车动效
            uiGame:PlayBoardEffect(targetPos, nil)
            
            -- 延时让动效播放一会再标记完成
            uiGame:CreateDelayCall(onComplete, game.BoardWaitFxTime)
        end)
    end, game.BoardJumpAnimDelay)
end

--- 播放上车音效
function XLineArithmetic3BoardCommand:_PlayBoardSound()
    local cueId = XMVCA.XLineArithmetic3:GetClientConfigNumberByKey("ToBoardCueId") or 0
    XLog.Debug("[BoardCommand] _PlayBoardSound called, cueId=" .. tostring(cueId))
    if cueId > 0 then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
    end
end

--- 撤销命令（乘客下车回到原位）
function XLineArithmetic3BoardCommand:Undo(game, onComplete)
    local uiGame = self._UiGame

    -- 恢复 Game 层状态
    local grid = game:GetGrid({ x = self._GridX, y = self._GridY })
    if grid then
        grid.Passenger = self._GridPassengerBefore
    end
    local carriages = game:GetCarriages()
    local carriage = carriages[self._CarriageIndex]
    if carriage then
        carriage.Passenger = nil  -- 上车前车厢是空的
    end

    -- 恢复表情状态：将车厢的表情状态转移到格子
    local carriageEmojKey = game:_GetCarriageEmojKey(self._CarriageIndex)
    local gridEmojKey = game:_GetGridEmojKey(self._GridX, self._GridY)
    local carriageEmoj = game:GetEmojState(carriageEmojKey)
    game:SetEmojState(gridEmojKey, carriageEmoj)

    -- UI 层逻辑
    if not self._PassengerUid or not self._PassengerStartPos then
        if onComplete then onComplete() end
        return
    end

    local passengerGrid = uiGame:GetPassengerByUid(self._PassengerUid)
    if not passengerGrid then
        if onComplete then onComplete() end
        return
    end

    passengerGrid.Transform:SetParent(uiGame.PanelCharacter)

    local currentPos = passengerGrid.Transform.position
    local duration = XLineArithmetic3Enum.UndoDuration
    uiGame:CreateTween(duration, function(progress)
        local gridItem = uiGame:GetPassengerByUid(self._PassengerUid)
        if gridItem then
            local pos = CS.UnityEngine.Vector3.Lerp(currentPos, self._PassengerStartPos, progress)
            gridItem.Transform:SetPosition(pos.x, pos.y, pos.z)
        end
    end, function()
        -- 恢复坐标到UID的映射
        uiGame:SetPassengerUidByPos(self._GridX, self._GridY, self._PassengerUid)
        -- 清除车厢索引到乘客UID的映射
        uiGame:SetPassengerUidByCarriage(self._CarriageIndex, nil)
        if onComplete then onComplete() end
    end)
end

return XLineArithmetic3BoardCommand
