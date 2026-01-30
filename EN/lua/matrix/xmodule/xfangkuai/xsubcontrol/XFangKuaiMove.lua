---@class XFangKuaiMove : XControl 方块移动
---@field _MainControl XFangKuaiControl
---@field _Model XFangKuaiModel
local XFangKuaiMove = XClass(XControl, "XFangKuaiMove")

function XFangKuaiMove:OnInit()
    self._SpeedX = tonumber(self._MainControl:GetClientConfig("BlockMoveXSpeed"))
    self._SpeedY = tonumber(self._MainControl:GetClientConfig("BlockMoveYSpeed"))
    self._BlockWidth = tonumber(self._MainControl:GetClientConfig("BlockWidth"))
    self._BlockHeight = tonumber(self._MainControl:GetClientConfig("BlockHeight"))
    self._FevLineMoveUp = tonumber(self._MainControl:GetClientConfig("FevLineMoveUp"))
    self._FevLineMoveDown = tonumber(self._MainControl:GetClientConfig("FevLineMoveDown"))
    self._FevLineMoveUpMin = tonumber(self._MainControl:GetClientConfig("FevLineMoveUp", 2))
    self._FevLineMoveDownMin = tonumber(self._MainControl:GetClientConfig("FevLineMoveDown", 2))
end

function XFangKuaiMove:AddAgencyEvent()

end

function XFangKuaiMove:RemoveAgencyEvent()

end

function XFangKuaiMove:OnRelease()

end

function XFangKuaiMove:GetPosByGridX(index)
    return (index - 1) * self._BlockWidth
end

function XFangKuaiMove:GetPosByGridY(index)
    return (index - 1) * self._BlockHeight
end

function XFangKuaiMove:GetGridYByPos(posY)
    return posY / self._BlockHeight + 1
end

---@param block XFangKuaiBlock
---@return number,number
function XFangKuaiMove:GetPosByBlock(block)
    local gird = block:GetHeadGrid()
    return self:GetPosByGridX(gird.x), self:GetPosByGridY(gird.y)
end

---水平移动
---@param block XUiGridFangKuaiBlock
function XFangKuaiMove:MoveX(block, gridX, updateCb, completeCb, moveTime)
    if block then
        local time = moveTime or self:GetMoveXTime(block.BlockData, gridX)
        return block.Transform:DOLocalMoveX(self:GetPosByGridX(gridX), time):OnUpdate(updateCb):OnComplete(completeCb)
    end
    return nil
end

---垂直移动
---@param block XUiGridFangKuaiBlock
function XFangKuaiMove:MoveY(block, gridY)
    if block then
        local time = self:GetMoveYTime()
        block.Transform:DOLocalMoveY(self:GetPosByGridY(gridY), time):SetEase(CS.DG.Tweening.Ease.OutQuad)
    end
end

function XFangKuaiMove:FevMoveY(tran, gridY, isMoveUp, addLine, finishCallBack)
    if XTool.UObjIsNil(tran) then
        return
    end
    local time = isMoveUp and self:GetFevMoveUpTime(addLine) or self:GetFevMoveDownTime(addLine)
    tran:DOLocalMoveY(self:GetPosByGridY(gridY), time):SetEase(CS.DG.Tweening.Ease.Linear):OnComplete(function()
        if finishCallBack then
            finishCallBack()
        end
    end)
end

---@param block XUiGridFangKuaiBlock
function XFangKuaiMove:AutoMoveUp(block)
    if block and block.BlockData:CheckMoveUp() then
        self:MoveY(block, block.BlockData:GetNextUpGrid())
    end
end

---将点击坐标转换为格子索引
---@param block XUiGridFangKuaiBlock
function XFangKuaiMove:GetMouseClickGrid(block)
    local offsetX = XUiHelper.GetScreenClickPosition(block.Transform.parent, CS.XUiManager.Instance.UiCamera).x
    offsetX = offsetX + self._BlockWidth / 2
    local gridIndex = math.floor(offsetX / self._BlockWidth) + 1
    return math.max(1, math.min(block.BlockData:GetMaxWidth(), gridIndex))
end

---@param blockData XFangKuaiBlock
function XFangKuaiMove:GetMoveXTime(blockData, dimGridX)
    return self._SpeedX
end

function XFangKuaiMove:GetMoveYTime()
    if self._MainControl:IsFever() then
        -- 进入狂热状态时 加速方块上升和掉落
        -- 这里有可能是无限循环小数 如果不确定精度 会导致异步等待和缓动不同步
        local fevSpeed = string.format("%.2f", self._SpeedY / self._MainControl:GetFevSpeed())
        return tonumber(fevSpeed)
    end
    return self._SpeedY
end

function XFangKuaiMove:GetFevMoveUpWaitTime(lineCount)
    if not lineCount or lineCount <= 0 then
        return 0
    end
    local time = string.format("%.1f", self._FevLineMoveUp * lineCount)
    return tonumber(time)
end

function XFangKuaiMove:GetFevMoveUpTime(lineCount)
    return math.max(self._FevLineMoveUpMin, self:GetFevMoveUpWaitTime(lineCount))
end

function XFangKuaiMove:GetFevMoveDownWaitTime(lineCount)
    if not lineCount or lineCount <= 0 then
        return 0
    end
    local time = string.format("%.1f", self._FevLineMoveDown * lineCount)
    return tonumber(time)
end

function XFangKuaiMove:GetFevMoveDownTime(lineCount)
    return math.max(self._FevLineMoveDownMin, self:GetFevMoveDownWaitTime(lineCount))
end

return XFangKuaiMove