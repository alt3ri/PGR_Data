---@class XUiGridGuideBubble: XUiNode
local XUiGridGuideBubble = XClass(XUiNode, 'XUiGridGuideBubble')

function XUiGridGuideBubble:OnStart()
    self.BubbleTxt.text = ''
    
    self._DefaultPosX, self._DefaultPosY, self._DefaultPosZ = self.Transform:GetLocalPosition()
    self._DefaultRotateX, self._DefaultRotateY, self._DefaultRotateZ = self.Transform:GetLocalRotation()
end

function XUiGridGuideBubble:SetRotateZ(rotateZ)
    self.Transform:SetLocalRotation(self._DefaultRotateX, self._DefaultRotateY, rotateZ)
end

function XUiGridGuideBubble:SetLoccalPosOffset(offset)
    self.Transform:SetLocalPosition(self._DefaultPosX + offset.X, self._DefaultPosY + offset.Y, self._DefaultPosZ + offset.Z)
end

function XUiGridGuideBubble:SetContent(content)
    self.BubbleTxt.text = XUiHelper.ReplaceTextNewLine(content)
end

return XUiGridGuideBubble