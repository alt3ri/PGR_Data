--- XLineArithmetic3 指令命令基类
--- 使用 Command 模式实现 Do/Undo，支持动画倒放
local XLineArithmetic3Command = XClass(nil, "XLineArithmetic3Command")

--- 构造函数
---@param uiGame XUiLineArithmetic3Game UI游戏对象
function XLineArithmetic3Command:Ctor(uiGame)
    ---@type XUiLineArithmetic3Game
    self._UiGame = uiGame
end

--- 执行命令（正向动画）
---@param game XLineArithmetic3Game 游戏逻辑对象
---@param onComplete function 完成回调
function XLineArithmetic3Command:Execute(game, onComplete)
    if onComplete then onComplete() end
end

--- 撤销命令（反向动画）
---@param game XLineArithmetic3Game 游戏逻辑对象
---@param onComplete function 完成回调
function XLineArithmetic3Command:Undo(game, onComplete)
    if onComplete then onComplete() end
end

--- 销毁命令，清理引用
function XLineArithmetic3Command:Destroy()
    self._UiGame = nil
end

return XLineArithmetic3Command
