--- 方块基类
---@class XDyeMergeBlock
local XDyeMergeBlock = XClass(nil, 'XDyeMergeBlock')

-- DirColors 元表锁定（参考 XGameCommand.LockMeta）
local DirColorsLockMeta = {
    __newindex = function()
        XLog.Error("[DyeMerge]DirColors 数据锁定中，禁止修改")
    end
}

function XDyeMergeBlock:Ctor()
    
end

---@param id @配置表Id
---@param uid @实例唯一Id
---@param blockType @配置方块类型
function XDyeMergeBlock:Init(id, uid, blockType, initRotateIndex, canMove, ...)
    self._Id = id
    self._Uid = uid
    self._Type = blockType
    self._RotateIndex = initRotateIndex
    self._CanMove = canMove
end

--- 设置方块本体的中心坐标
--- 本体：即原始部分，不包括方块特性延伸部分
--- 中心坐标：方块形状的中心
function XDyeMergeBlock:SetCenter(x, y)
    self._X = x
    self._Y = y
end

--- 设置放置状态
--- 方块处于某个位置时，可能只是预放置，不参与、不接受棋盘状态的改变
function XDyeMergeBlock:SetPlacedState(isPlaced)
    self._IsPlaced = isPlaced
end

--- 设置方块的旋转角度
--- 这里采用的是离散角度索引
function XDyeMergeBlock:SetRotateIndex(rotateIndex)
    self._RotateIndex = rotateIndex
end

--- 设置可变方块的当前颜色索引
function XDyeMergeBlock:SetChangeableColorIndex(colorIndex)
    self._ColorIndex = colorIndex
end

--- 设置延伸块的初始长度及方向
function XDyeMergeBlock:SetVariableLength(len, isExpand)
    self._Length = len
    self._IsExpand = isExpand
end

--- 设置目标块当前接收到的混合颜色（由 UpdateBlocksState 命令写入）
function XDyeMergeBlock:SetReceivedColor(colorId)
    self._ReceivedColor = colorId
end

--- 获取目标块当前接收到的混合颜色，未受色时返回 nil
function XDyeMergeBlock:GetReceivedColor()
    return self._ReceivedColor
end

--- 设置目标块每个方向接收到的原始颜色（由 UpdateTargetReceivedColors 写入）
--- 值拷贝语义：将 source 的内容拷贝进内部持久表，拷贝完成后冻结防止外部误写
---@param source table|nil {[adjDir]=colorId}，adjDir: 1=上 2=右 3=下 4=左
function XDyeMergeBlock:SetReceivedDirColors(source)
    local t = self._ReceivedDirColors
    if not t then
        t = {}
        self._ReceivedDirColors = t
    end
    -- 解冻
    setmetatable(t, nil)
    -- 清空旧值
    for k in pairs(t) do t[k] = nil end
    -- 值拷贝
    if source then
        for k, v in pairs(source) do t[k] = v end
    end
    -- 冻结
    setmetatable(t, DirColorsLockMeta)
end

--- 获取目标块每个方向接收到的原始颜色，未受色时返回 nil
---@return table|nil {[adjDir]=colorId}
function XDyeMergeBlock:GetReceivedDirColors()
    return self._ReceivedDirColors
end

function XDyeMergeBlock:GetId()
    return self._Id
end

function XDyeMergeBlock:GetUid()
    return self._Uid
end

function XDyeMergeBlock:GetType()
    return self._Type
end

function XDyeMergeBlock:GetX()
    return self._X
end

function XDyeMergeBlock:GetY()
    return self._Y
end

function XDyeMergeBlock:GetRotateIndex()
    return self._RotateIndex or 0
end

function XDyeMergeBlock:GetChangeableColorIndex()
    return self._ColorIndex
end

function XDyeMergeBlock:GetVariableLength()
    return self._Length
end

function XDyeMergeBlock:GetVariableIsExpand()
    return self._IsExpand
end

function XDyeMergeBlock:GetCanMove()
    return self._CanMove
end

function XDyeMergeBlock:Reset()
    self._Id = nil
    self._Uid = nil
    self._Type = nil
    self._RotateIndex = nil
    self._X = nil
    self._Y = nil
    self._IsPlaced = nil
    self._ColorIndex = nil
    self._Length = nil
    self._IsExpand = nil
    self._ReceivedColor = nil
    -- 解冻并清空，保留表实例供池复用
    if self._ReceivedDirColors then
        setmetatable(self._ReceivedDirColors, nil)
        for k in pairs(self._ReceivedDirColors) do
            self._ReceivedDirColors[k] = nil
        end
    end
end

return XDyeMergeBlock