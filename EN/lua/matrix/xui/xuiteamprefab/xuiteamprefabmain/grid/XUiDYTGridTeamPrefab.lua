local XUiDYTGridTeamPrefab = XClass(XUiNode, "XUiDYTGridTeamPrefab")

--- func desc
---@param curTeamPrefabEntity XTeamPrefab
function XUiDYTGridTeamPrefab:Refresh(curTeamPrefabEntity)
    if not curTeamPrefabEntity then return end
    
    self.Btn:SetNameByGroup(0, curTeamPrefabEntity:GetName())
    local capatinCharacterId = curTeamPrefabEntity:GetCaptainPosEntityId()
    if XTool.IsNumberValid(capatinCharacterId) then
        self.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(capatinCharacterId))
    end
    self.Normal:GetObject("PanelHave").gameObject:SetActiveEx(XTool.IsNumberValid(capatinCharacterId))
    self.Normal:GetObject("PanelEmpty").gameObject:SetActiveEx(not XTool.IsNumberValid(capatinCharacterId))
    self.Press:GetObject("PanelHave").gameObject:SetActiveEx(XTool.IsNumberValid(capatinCharacterId))
    self.Press:GetObject("PanelEmpty").gameObject:SetActiveEx(not XTool.IsNumberValid(capatinCharacterId))
    self.Select:GetObject("PanelHave").gameObject:SetActiveEx(XTool.IsNumberValid(capatinCharacterId))
    self.Select:GetObject("PanelEmpty").gameObject:SetActiveEx(not XTool.IsNumberValid(capatinCharacterId))
    self.RImgHead.gameObject:SetActiveEx(XTool.IsNumberValid(capatinCharacterId))
end

function XUiDYTGridTeamPrefab:SetSelect(isSelect)
    if isSelect == self.IsSelect then
        return
    end

    self.IsSelect = isSelect
    if isSelect then
        self.Btn:SetButtonState(CS.UiButtonState.Select)
    else
        self.Btn:SetButtonState(CS.UiButtonState.Normal)
    end
end

return XUiDYTGridTeamPrefab