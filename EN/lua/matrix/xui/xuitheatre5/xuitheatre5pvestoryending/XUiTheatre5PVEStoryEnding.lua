---@class XUiTheatre5PVEStoryEnding: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PVEStoryEnding = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVEStoryEnding')

function XUiTheatre5PVEStoryEnding:OnAwake()
    self:AddUIListener()
end

function XUiTheatre5PVEStoryEnding:OnStart(storyLineId, contentId)
    self._StoryLineId = storyLineId
    self._StoryLineContentId = contentId
    self:RefreshAll(contentId)
end

function XUiTheatre5PVEStoryEnding:AddUIListener()
    self:RegisterClickEvent(self.BtnClick, self.Close, true)
end

function XUiTheatre5PVEStoryEnding:RefreshAll(contentId)
    local contentCfg = self._Control.PVEControl:GetStoryLineContentCfg(contentId)
    local endingCfg = self._Control.PVEControl:GetPVEEndingCfg(contentCfg.ContentId)
    self.TxtEndTitle.text = endingCfg.Name
    self.TxtEndInfo.text = endingCfg.Desc
    self.BgCommonBai:SetRawImage(endingCfg.Bg)
    self.Icon:SetRawImage(endingCfg.Icon)

end

function XUiTheatre5PVEStoryEnding:OnEnable()
    
end

function XUiTheatre5PVEStoryEnding:OnDisable()

end

function XUiTheatre5PVEStoryEnding:OnDestroy()
    self._StoryLineId = nil
    self._StoryLineContentId = nil
end

return XUiTheatre5PVEStoryEnding