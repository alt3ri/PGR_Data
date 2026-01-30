---@class XUiPanelTheatre5PVECharacterDetail: XUiNode
---@field private _Control XTheatre5Control
---@field Parent UiTheatre5ChooseCharacter
local XUiPanelTheatre5PVECharacterDetail = XClass(XUiNode, 'XUiPanelTheatre5PVECharacterDetail')

function XUiPanelTheatre5PVECharacterDetail:OnStart()
    self.TxtName2 = self.TxtName2 or XUiHelper.TryGetComponent(self.Transform, "PanelName/TxtName (1)", "Text")
end

function XUiPanelTheatre5PVECharacterDetail:RefreshShow(cfg)
    self.TxtName.text = cfg.Name
    if self.TxtName2 then
        self.TxtName2.text = cfg.Name
    end
    self.TxtStory.text = XUiHelper.ReplaceTextNewLine(cfg.Info)
    local entranceName = self.Parent:GetEntranceName()
    local entranceCfg = self._Control.PVEControl:GetPveStoryEntranceCfg(entranceName)
    if not entranceCfg then
        return
    end
    local isCharacterCanSelect, tips = self._Control:IsCharacterCanSelect(cfg.Id)
    if not isCharacterCanSelect then
        self.TxtStoryDesc.text = tips
    else
        local characterStoryDesc = self._Control.PVEControl:GetChacterStoryDesc(entranceName)
        self.CharacterStoryDescNode.gameObject:SetActiveEx(not string.IsNilOrEmpty(characterStoryDesc))
        if not string.IsNilOrEmpty(characterStoryDesc) then
            self.TxtStoryDesc.text = XUiHelper.ReplaceTextNewLine(characterStoryDesc)
        end
    end
    
    --线索
    local curContentId = self._Control.PVEControl:GetStoryLineContentId(entranceCfg.StoryLine)
    if not XTool.IsNumberValid(curContentId) then --复刷章节
        self.PanelClue.gameObject:SetActiveEx(false)
        return
    end    
    local storyLineContentCfg = self._Control.PVEControl:GetStoryLineContentCfg(curContentId)
    local isDeduce = storyLineContentCfg and storyLineContentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.DeduceBattle 
        and XTool.IsNumberValid(storyLineContentCfg.NextScript)
    self.PanelClue.gameObject:SetActiveEx(isDeduce)
    if not isDeduce then
        return
    end

    local scriptCfg = self._Control.PVEControl:GetDeduceScriptCfg(storyLineContentCfg.NextScript)
    local clueCfgs = self._Control.PVEControl:GetDeduceClueGroupCfgs(scriptCfg.PreClueGroupId)
    local unLockCount = self._Control.PVEControl:GetUnlockDeduceScriptCount(storyLineContentCfg.NextScript)
    self.TxtClueNum.text = string.format("%d/%d", unLockCount, #clueCfgs)  

end    

return XUiPanelTheatre5PVECharacterDetail