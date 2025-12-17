--- 主要简版线索
---@class XUiTheatre5PVESimpleMainClue: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVESimpleMainClue = XClass(XUiNode, 'XUiTheatre5PVESimpleMainClue')

function XUiTheatre5PVESimpleMainClue:OnStart()
    self._ClueId = nil
    XUiHelper.RegisterClickEvent(self, self.BtnMainClue, self.OnClickClue, true)
    XUiHelper.RegisterClickEvent(self, self.DeduceBtn, self.OnClickDeduce, true)
end

function XUiTheatre5PVESimpleMainClue:Update(clueId)
    self._ClueId = clueId
    local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueId)
    if not clueCfg then
        return
    end
    self._deduceId = clueCfg.ScriptId
    local clueState = self._Control.PVEControl:GetClueState(clueId)
    if clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.NoShow then
        return
    end
    self.TxtTitle.text = clueCfg.Title
    self.RImgClue:SetRawImage(clueCfg.Img)
    self.DeduceBtn.gameObject:SetActiveEx(clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.Deduce)
    local desc = clueCfg.UnlockDesc
    if clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.Completed then
        desc = clueCfg.CompleteDesc  
    end      
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(desc)    
end

function XUiTheatre5PVESimpleMainClue:UpdateCuleBoard(localPosition, visible, playAnim)
    local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(self._ClueId)
    if not clueCfg then
        return
    end
    self.GameObject.name = string.format("%s_%s", self.__cname, clueCfg.Index)
    self.Transform.localPosition = localPosition 
    self:SetVisible(visible)
    if visible and playAnim then
        self:PlayAnimation("Storage")
    end     
end

function XUiTheatre5PVESimpleMainClue:OnClickClue()
      self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_CLICK_SIMPLE_CLUE, self._ClueId)
end

function XUiTheatre5PVESimpleMainClue:OnClickDeduce()
    local storyLineId = self._Control.PVEControl:GetStoryLineIdByScriptId(self._deduceId)
    if not XTool.IsNumberValid(storyLineId) then
        XUiManager.TipMsg(self._Control.PVEControl:GetPveVersionError())
        return
    end
    self._Control.FlowControl:EnterStroryLineContent(storyLineId)    
end

function XUiTheatre5PVESimpleMainClue:OnDestroy()
    self._ClueId = nil
end

return XUiTheatre5PVESimpleMainClue