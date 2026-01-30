--- 公会战角色驻守玩法驻守选择界面角色选项
---@class XUiGridGuildWarStayChoose: XUiNode
---@field _Control XGuildWarControl
local XUiGridGuildWarStayChoose = XClass(XUiNode, 'XUiGridGuildWarStayChoose')

function XUiGridGuildWarStayChoose:Refresh(characterData)
    local charIconUrl = XMVCA.XCharacter:GetCharSmallHeadIcon(characterData.Id)

    if not string.IsNilOrEmpty(charIconUrl) then
        self.GridBtn:SetRawImage(charIconUrl)
    end
    
    self.GridBtn:SetNameByGroup(0, XMVCA.XCharacter:GetCharacterTradeName(characterData.Id))
    
    -- 判断是否驻扎
    local isStationed = self._Control.RoleStationControl:CheckCharacterIsStationedAnyNode(characterData.Id)
    
    self.GridBtn:ShowTag(isStationed)
end

function XUiGridGuildWarStayChoose:SetSelectState(isSelect)
    if self.SelectStateCache ~= isSelect then
        self.SelectStateCache = isSelect
        
        self.GridBtn:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
end

return XUiGridGuildWarStayChoose