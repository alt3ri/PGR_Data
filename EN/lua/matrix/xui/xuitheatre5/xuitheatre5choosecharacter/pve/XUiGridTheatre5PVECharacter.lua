local XUiGridTheatre5Character = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/XUiGridTheatre5Character')
---@class XUiGridTheatre5PVECharacter: XUiGridTheatre5Character
---@field private _Control XTheatre5Control
local XUiGridTheatre5PVECharacter = XClass(XUiGridTheatre5Character, 'XUiGridTheatre5PVECharacter')


---@param cfg XTableTheatre5Character
---@overload
function XUiGridTheatre5PVECharacter:Update(cfg, index)
    self.Config = cfg
    self.Index = index
    self._EntranceName = nil
    if self.Parent and self.Parent.Parent and self.Parent.Parent.GetEntranceName then
        self._EntranceName = self.Parent.Parent:GetEntranceName()
    end 
    if not self._EntranceName then
        return
    end       
    local storyEntranceCfg = self._Control.PVEControl:GetPveStoryEntranceCfg(self._EntranceName)
    local storyLineCfg = self._Control.PVEControl:GetStoryLineCfg(storyEntranceCfg.StoryLine)
    --共通线走角色逻辑，否则走角色各自的故事线逻辑
    if storyLineCfg.StoryLineType ~= XMVCA.XTheatre5.EnumConst.PVEStoryLineType.Together then
        local entranceCfg = self._Control.PVEControl:GetCharacterPveStoryEntranceCfg(cfg.Id)
        if entranceCfg then   
            self._EntranceName = entranceCfg.SceneObject
        else
            self._EntranceName = nil   --有的故事线没有配角色
        end         
    end    
    self._IsUnlock = self._Control.PVEControl:IsCharacterAndStoryLineUnlock(cfg.Id,self._EntranceName)       

    self.PanelLock.gameObject:SetActiveEx(not self._IsUnlock)
    if self._IsUnlock then
        self.PanelSelected.gameObject:SetActiveEx(false)
    end    
    
    local portrait = self._Control.CharacterControl:GetPortraitByCharacterIdCurMode(cfg.Id)
    if not string.IsNilOrEmpty(portrait) then
        self.RImgHeadIcon:SetRawImage(portrait)
    end
end

---@overload
function XUiGridTheatre5PVECharacter:OnBtnClickEvent()
    if not self._IsUnlock then
        return
    end    
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_CLICK_CHARACTER_HEAD, self._EntranceName, self.Config.Id)
    XUiGridTheatre5PVECharacter.Super.OnBtnClickEvent(self)
end

return XUiGridTheatre5PVECharacter