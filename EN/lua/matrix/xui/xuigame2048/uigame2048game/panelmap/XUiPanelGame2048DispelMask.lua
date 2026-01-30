---@class XUiPanelGame2048DispelMask: XUiNode
---@field Parent XUiPanelGame2048Map
local XUiPanelGame2048DispelMask = XClass(XUiNode, 'XUiPanelGame2048DispelMask')

function XUiPanelGame2048DispelMask:OnStart()
    self:InitBlock()

    if self.EffectEliminate then
        self.EffectEliminate.gameObject:SetActiveEx(false)
    end

    if self.EffectEliminateMask then
        self.EffectEliminateMask.gameObject:SetActiveEx(false)
    end

    if self.EffectEliminate then
        self.EffectEliminate.gameObject:SetActiveEx(false)
    end

    ---@type XGame2048GameControl
    self._GameControl = self._Control:GetGameControl()
end

function XUiPanelGame2048DispelMask:InitBlock()
    self._MaskGrids ={}

    for i = 1, 16 do
        local mask = self['ImgMask' .. tostring(i)]
        
        self._MaskGrids[i] = mask

        mask.gameObject:SetActiveEx(false)
    end
end

--- 水火方块选择中，显示无效的区域
function XUiPanelGame2048DispelMask:ShowInvalidMask()
    -- 获取无效区域的左下角和右上角
    local hasInValidArea, leftDownX, leftDownY, rightUpX, rightUpY = self._GameControl.GridsControl:GetDispelGridCleanUpInvalidRange()

    if hasInValidArea then
        for i, v in pairs(self._MaskGrids) do
            local x = (i - 1) % 4 + 1
            local y = math.floor((i - 1) / 4) + 1
            
            local isShow = x >= leftDownX and x <= rightUpX and y >= leftDownY and y <= rightUpY
            
            v.gameObject:SetActiveEx(isShow)
        end
    else
        self:HideInvalidMask()
    end
end

function XUiPanelGame2048DispelMask:HideInvalidMask()
    for i, v in pairs(self._MaskGrids) do
        v.gameObject:SetActiveEx(false)
    end
end

--- 显示消除范围特效
function XUiPanelGame2048DispelMask:ShowDispelRangeEffect()
    if self.EffectEliminateMask then
        self.EffectEliminateMask.gameObject:SetActiveEx(true)
    end
    
    if self.EffectEliminateMask then
        -- 获取有效区域的左下角和右上角
        local leftDownX, rightUpX, leftDownY, rightUpY = self._GameControl.GridsControl:GetDispelGridCleanUpRange()

        self.EffectEliminateMask.gameObject:SetActiveEx(true)

        local leftDownGrid = self.Parent:GetBgUiGridByNormalizePos(leftDownX, leftDownY)
        local rightUpGrid = self.Parent:GetBgUiGridByNormalizePos(rightUpX, rightUpY)

        self.EffectEliminateMask.transform.position = (leftDownGrid.Transform.position + rightUpGrid.Transform.position) / 2

        local fixCellWidth = self.Parent.BgLayout.cellSize.x
        local fixCellHeight = self.Parent.BgLayout.cellSize.y

        local width = fixCellWidth * (rightUpX - leftDownX + 1) + self.Parent.BgLayout.spacing.x * (rightUpX - leftDownX)
        local height = fixCellHeight * (rightUpY - leftDownY + 1) + self.Parent.BgLayout.spacing.y * (rightUpY - leftDownY)

        self.EffectEliminateMask.transform:SetUISizeDelta(width, height)
    end
    
    -- 获取消除方块的标准坐标
    local x, y = self._GameControl.GridsControl:GetDispelGridNormalizePos()

    if XTool.IsNumberValidEx(x) and XTool.IsNumberValidEx(y) then
        local blockUi = self.Parent:GetBgUiGridByNormalizePos(x, y)

        if blockUi then
            if self.EffectEliminate then
                self.EffectEliminate.transform.position = blockUi.Transform.position

                self.EffectEliminate.gameObject:SetActiveEx(true)
            end
        end
    else
        if self.EffectEliminate then
            self.EffectEliminate.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelGame2048DispelMask:HideDispelRangeEffect()
    if self.EffectEliminateMask then
        self.EffectEliminateMask.gameObject:SetActiveEx(false)
    end

    if self.EffectEliminate then
        self.EffectEliminate.gameObject:SetActiveEx(false)
    end
end

return XUiPanelGame2048DispelMask