--- 激活终点命令
local XLineArithmetic3Command = require("XModule/XLineArithmetic3/XLineArithmetic3Command")
local XLineArithmetic3ActivateEndCommand = XClass(XLineArithmetic3Command, "XLineArithmetic3ActivateEndCommand")

--- 构造函数
function XLineArithmetic3ActivateEndCommand:Ctor(uiGame, gridX, gridY)
    self._GridX = gridX
    self._GridY = gridY
    -- UI 层状态（保存key而不是GameObject引用）
    self._EndKey = "End_" .. gridX .. "_" .. gridY
end

--- 执行命令（激活终点动画）
function XLineArithmetic3ActivateEndCommand:Execute(game, onComplete)
    local uiGame = self._UiGame
    local endGrid = uiGame:GetGridElement(self._EndKey)

    if endGrid then
        local duration = 0.2
        uiGame:CreateTween(duration, function(progress)
            local gridItem = uiGame:GetGridElement(self._EndKey)
            if gridItem then
                local scale = 1 + 0.2 * math.sin(progress * math.pi)
                gridItem.Transform:SetLocalScale(scale, scale, 1)
            end
        end, onComplete)
    else
        if onComplete then onComplete() end
    end
end

--- 撤销命令（取消激活）
function XLineArithmetic3ActivateEndCommand:Undo(game, onComplete)
    local uiGame = self._UiGame

    -- UI 层逻辑：通过key获取GameObject
    local endGrid = uiGame:GetGridElement(self._EndKey)
    if endGrid then
        endGrid.Transform:SetLocalScale(1, 1, 1)
    end
    if onComplete then onComplete() end
end

return XLineArithmetic3ActivateEndCommand
