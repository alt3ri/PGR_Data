---@class XUiTheatre5Movie: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5Movie = XLuaUiManager.Register(XLuaUi, 'UiTheatre5Movie')
function XUiTheatre5Movie:OnAwake()
    self:AddUIListener()
    self._CurIndex = 1
    self._SceneChatCfgs = nil
    self._IsTyping = false
    self._CompletedCb = nil
end

function XUiTheatre5Movie:OnStart(chatGroupId, characters, completedCb)
    self._CompletedCb = completedCb
    self._WriterTime = self._Control.PVEControl:GetPVEChatWriteTime()
    if not self._WriterTime then
        self._WriterTime = 1000
    end  
    self._SceneChatCfgs = self._Control.PVEControl:GetPveSceneChatCfgs(chatGroupId)
    self:RefreshChatCharacters(characters)
    self:RefreshChatText(self._SceneChatCfgs[self._CurIndex])
end

function XUiTheatre5Movie:OnEnable()

end

function XUiTheatre5Movie:OnDisable()

end

function XUiTheatre5Movie:AddUIListener()
    self:RegisterClickEvent(self.BtnSkip, self.OnClickSkip, true)
    self:RegisterClickEvent(self.BtnNext, self.OnClickNext, true)
end

function XUiTheatre5Movie:RefreshChatCharacters(characterIds)
    if XTool.IsTableEmpty(characterIds) then
        return
    end
    --todo 隐藏角色    
end

function XUiTheatre5Movie:RefreshChatText(sceneChatCfg)
    self:PlayChatText(sceneChatCfg)
end

function XUiTheatre5Movie:PlayChatText(sceneChatCfg)
    self._IsTyping = true
    self._CurIndex = self._CurIndex + 1
    local content = XMVCA.XMovie:ExtractGenderContent(sceneChatCfg.ChatText)
    self.TxtWords.text = XUiHelper.ConvertLineBreakSymbol(content)
    self.TxtName.text = sceneChatCfg.RoleName
    local duration = self._WriterTime /1000
    self.DialogTypeWriter.Duration = duration
    self.DialogTypeWriter.CompletedHandle = function() self:OnTypeWriterComplete() end
    self.DialogTypeWriter:Play()
end

function XUiTheatre5Movie:OnTypeWriterComplete()
    self._IsTyping = false
end

function XUiTheatre5Movie:OnClickSkip()
    if self._CompletedCb then
        self._CompletedCb()
    end  
    self:Close()  
end

function XUiTheatre5Movie:OnClickNext()
    if XTool.IsTableEmpty(self._SceneChatCfgs) or self._CurIndex > #self._SceneChatCfgs then
        if self._CompletedCb then
            self._CompletedCb()
        end  
        self:Close()  
        return
    end    
    if self._IsTyping then
        self.DialogTypeWriter:Stop()
        self:OnTypeWriterComplete()
    else
        self:RefreshChatText(self._SceneChatCfgs[self._CurIndex])
    end
end

function XUiTheatre5Movie:OnDestroy()
    self._CurIndex = nil
    self._SceneChatCfgs = nil
    self._IsTyping = nil
    self._CompletedCb = nil
    self._WriterTime = nil
end

return XUiTheatre5Movie