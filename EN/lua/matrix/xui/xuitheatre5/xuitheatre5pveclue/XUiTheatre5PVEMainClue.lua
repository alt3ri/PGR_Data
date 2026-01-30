--- 主要线索
---@class XUiTheatre5PVEMainClue: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVEMainClue = XClass(XUiNode, 'XUiTheatre5PVEMainClue')

function XUiTheatre5PVEMainClue:OnStart()
    self._AvgId = nil
    self._DeduceId = nil
    self._ClueId = nil
    XUiHelper.RegisterClickEvent(self, self.BtnVideo, self.OnClickVideo, true)
    XUiHelper.RegisterClickEvent(self, self.DeduceBtn, self.OnClickDeduce, true)
end

function XUiTheatre5PVEMainClue:Update(clueId)
    self._ClueId = clueId
    local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueId)
    if not clueCfg then
        return
    end
    self._AvgId = clueCfg.StoryId
    self._DeduceId = clueCfg.ScriptId
    local clueState = self._Control.PVEControl:GetClueState(clueId)
    if clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.NoShow then
        return
    end
    local desc = clueCfg.UnlockDesc
    if clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.Completed then
        desc = clueCfg.CompleteDesc  
    end      
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(desc)   
    self.TxtTitle.text = clueCfg.Title
    self.BtnVideo:SetRawImage(clueCfg.Img)   
    self.BtnVideo.gameObject:SetActiveEx(clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.Completed and not string.IsNilOrEmpty(clueCfg.StoryId))
    self.DeduceBtn.gameObject:SetActiveEx(clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.Deduce)
end

function XUiTheatre5PVEMainClue:UpdateCuleBoard(localPosition, visible, playAnim)
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

--region 外部做定制化
function XUiTheatre5PVEMainClue:UpdateDesc(desc)
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(desc)   
end

function XUiTheatre5PVEMainClue:HideDeduceBtn()
    self.DeduceBtn.gameObject:SetActiveEx(false)
end

function XUiTheatre5PVEMainClue:HideVideoBtn()
    self.BtnVideo.gameObject:SetActiveEx(false)
end

--endregion

function XUiTheatre5PVEMainClue:OnClickVideo()
    if not string.IsNilOrEmpty(self._AvgId) then
        XDataCenter.MovieManager.PlayMovie(self._AvgId, nil, nil, nil, false)
    end    
end

function XUiTheatre5PVEMainClue:OnClickDeduce()
    local storyLineId = self._Control.PVEControl:GetStoryLineIdByScriptId(self._DeduceId)
    if not XTool.IsNumberValid(storyLineId) then
        XUiManager.TipMsg(self._Control.PVEControl:GetPveVersionError())
        return
    end
    self._Control.FlowControl:EnterStroryLineContent(storyLineId)    
end

function XUiTheatre5PVEMainClue:OnDestroy()
    self._AvgId = nil
    self._DeduceId = nil
    self._ClueId = nil
end

return XUiTheatre5PVEMainClue