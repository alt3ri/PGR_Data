---@class XUiGridGuideBubble: XUiNode
local XUiGridGuideBubble = XClass(XUiNode, 'XUiGridGuideBubble')

function XUiGridGuideBubble:OnStart()
    self.BubbleTxt.text = ''
end

function XUiGridGuideBubble:OnEnable()
    -- 每次重新激活后坐标根据父节点自适应改变，所以需要同步记录改变后的值，再用来给后续的偏移使用
    self._DefaultPosX, self._DefaultPosY, self._DefaultPosZ = self.Transform:GetLocalPosition()
    self._DefaultRotateX, self._DefaultRotateY, self._DefaultRotateZ = self.Transform:GetLocalRotation()
    
    -- 修正上一次的偏移（如果有）
    if self._CurOffset then
        self._DefaultPosX = self._DefaultPosX - self._CurOffset.X
        self._DefaultPosY = self._DefaultPosY - self._CurOffset.Y
        self._DefaultPosZ = self._DefaultPosZ - self._CurOffset.Z

        self._CurOffset = nil
    end
end

function XUiGridGuideBubble:SetRotateZ(rotateZ)
    self.Transform:SetLocalRotation(self._DefaultRotateX, self._DefaultRotateY, rotateZ)
end

function XUiGridGuideBubble:SetLoccalPosOffset(offset)
    self._CurOffset = offset
    self.Transform:SetLocalPosition(self._DefaultPosX + offset.X, self._DefaultPosY + offset.Y, self._DefaultPosZ + offset.Z)
end

function XUiGridGuideBubble:SetContent(content)
    self.BubbleTxt.text = XUiHelper.ReplaceTextNewLine(content)
end

return XUiGridGuideBubble