---线索板标签
---@class XUiTheatre5PVEClueBoardTag: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVEClueBoardTag = XClass(XUiNode, 'XUiTheatre5PVEClueBoardTag')

function XUiTheatre5PVEClueBoardTag:OnStart()
    self._ClueBoardId = nil
    self._unlock = nil
    self._Index = nil
    XUiHelper.RegisterClickEvent(self, self.GridButton, self.OnClickTag, true)
end

function XUiTheatre5PVEClueBoardTag:Update(clueBoardCfg, index)
    self._ClueBoardId = clueBoardCfg.Id
    self._Index = index
    local isCondition = XConditionManager.CheckConditionAndDefaultPass(clueBoardCfg.ConditionId)
    local title = ""
    self._unlock = true
    if not XTool.IsNumberValid(clueBoardCfg.IsOpen) then
        title = clueBoardCfg.CloseDesc
        self._unlock = false
    elseif not isCondition then
        title = clueBoardCfg.LockDesc
        self._unlock = false
    end    
    local imgCondition = XConditionManager.CheckConditionAndDefaultPass(clueBoardCfg.ImgConditionId)
    self.RImgHeadIcon.gameObject:SetActiveEx(imgCondition)
    if imgCondition then
        self.RImgHeadIcon:SetRawImage(clueBoardCfg.Img)
    end
    self.DescTag.gameObject:SetActiveEx(not self._unlock)
    self.PanelLock.gameObject:SetActiveEx(not self._unlock)          
    self.Desc.text = title
    local soundComp = self.GridButton.transform:GetComponent("XUguiPlaySoundWithSource")
    if soundComp then
        soundComp.enabled = self._unlock
    end       
end

function XUiTheatre5PVEClueBoardTag:SetSelect(clueBoardId)
    if not self._unlock then
        return
    end
    self.PanelSelected.gameObject:SetActiveEx(self._ClueBoardId == clueBoardId)      
end

function XUiTheatre5PVEClueBoardTag:OnClickTag()
    if not self._unlock then
        return
    end    
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_CLICK_CLUE_BOARD_TAG, self._Index)
end

return XUiTheatre5PVEClueBoardTag