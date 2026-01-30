--- 次要线索
---@class XUiTheatre5PVEMinorClue: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVEMinorClue = XClass(XUiNode, 'XUiTheatre5PVEMinorClue')

function XUiTheatre5PVEMinorClue:OnEnable()

end

function XUiTheatre5PVEMinorClue:OnDisable()

end

function XUiTheatre5PVEMinorClue:Update(clueId)
    self._ClueId = clueId
    local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueId)
    if not clueCfg then
        return
    end
    local clueState = self._Control.PVEControl:GetClueState(clueId)
    if clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.NoShow then
        return
    end    
    self.RImgNormalBg.gameObject:SetActiveEx(clueCfg.ShowType == XMVCA.XTheatre5.EnumConst.PVEClueShowType.Normal)
    self.RImgSpecialBg.gameObject:SetActiveEx(clueCfg.ShowType == XMVCA.XTheatre5.EnumConst.PVEClueShowType.RImgSpecialBg)
    self.RImgClue:SetRawImage(clueCfg.Img)
    self.TxtTitle.text = clueCfg.Title
    self.Lock.gameObject:SetActiveEx(clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.Lock)
    local desc = ""
    if clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.Lock then
        desc = clueCfg.LockDesc
    elseif clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.Unlock then
        desc = clueCfg.UnlockDesc
    elseif clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.Completed then
        desc = clueCfg.CompleteDesc
    end      
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(desc)        
end

function XUiTheatre5PVEMinorClue:UpdateCuleBoard(localPosition, visible, playAnim)
    local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(self._ClueId)
    if not clueCfg then
        return
    end
    self.GameObject.name = string.format("%s_%s", self.__cname, clueCfg.Index)
    self.Transform.localPosition = localPosition 
    self:SetVisible(visible)
    if visible and playAnim then
        self:PlayAnimation("Expand")
    end     
end

return XUiTheatre5PVEMinorClue