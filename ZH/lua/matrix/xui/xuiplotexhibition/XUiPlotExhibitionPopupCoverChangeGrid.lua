---@class XUiPlotExhibitionPopupCoverChangeGrid : XUiNode
---@field _Control XPlotExhibitionControl
---@field Parent XUiPlotExhibitionPopupCoverChange
local XUiPlotExhibitionPopupCoverChangeGrid = XClass(XUiNode, "XUiPlotExhibitionPopupCoverChangeGrid")

function XUiPlotExhibitionPopupCoverChangeGrid:OnStart()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
end

---@param data XPlotExhibitionControlCharacter
function XUiPlotExhibitionPopupCoverChangeGrid:Update(data)
    self._Data = data
    
    local characterCg = self._Control:GetCharacterCg(data.Id)
    
    -- 显示封面图片（两个RImgHead显示相同内容）
    if self.RImgHead1 and characterCg then
        self.RImgHead1:SetRawImage(characterCg)
    end
    if self.RImgHead2 and characterCg then
        self.RImgHead2:SetRawImage(characterCg)
    end
    
    -- 判断当前封面是否是该Character
    local isCover = self._Control:IsCharacterCover(data.RoleId, data.Id)
    
    -- 显示当前标记
    if self.PanelTagCurrent then
        self.PanelTagCurrent.gameObject:SetActiveEx(isCover)
    end
end

function XUiPlotExhibitionPopupCoverChangeGrid:OnClick()
    if not self._Data then
        return
    end
    
    -- 设置封面（直接使用Character）
    self._Control:SetRoleCover(self._Data)
    
    -- 关闭界面
    if self.Parent then
        self.Parent:Close()
    end
end

return XUiPlotExhibitionPopupCoverChangeGrid

