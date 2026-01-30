---@class XUiTheatre5PopupHandBook : XLuaUi
---@field _Control XTheatre5Control
local XUiTheatre5PopupHandBook = XLuaUiManager.Register(XLuaUi, "UiTheatre5PopupHandBook")

function XUiTheatre5PopupHandBook:OnAwake()
    self:BindExitBtns()
    XUiHelper.RegisterClickEvent(self, self.BtnSure, self.PlayMovie)
end

---@param config XTableTheatre5Story
function XUiTheatre5PopupHandBook:OnStart(config)
    self._Config = config
    self.TxtDescription.text = config.StoryDesc
    self.TxtName.text = config.StoryTitle
end

function XUiTheatre5PopupHandBook:PlayMovie()
    self:Close()
    XDataCenter.MovieManager.PlayMovie(self._Config.StoryId, nil, nil ,nil, false)
end

return XUiTheatre5PopupHandBook