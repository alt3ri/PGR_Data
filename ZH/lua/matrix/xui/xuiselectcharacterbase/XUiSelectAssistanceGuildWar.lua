local XUiSelectCharacterBase = require("XUi/XUiSelectCharacterBase/XUiSelectCharacterBase")

---@class XUiSelectAssistanceGuildWar:XUiSelectCharacterBase
local XUiSelectAssistanceGuildWar = XLuaUiManager.Register(XUiSelectCharacterBase, "UiSelectAssistanceGuildWar")

function XUiSelectAssistanceGuildWar:RefreshMid()
    local character = self.CurCharacter
    if character then
        local characterId = character:GetId()
        if XDataCenter.GuildWarManager.GetAssistantCharacterId() == characterId then
            self.BtnJoin.gameObject:SetActiveEx(false)
            self.BtnQuit.gameObject:SetActiveEx(true)
            return
        end
    end
    self.BtnJoin.gameObject:SetActiveEx(true)
    self.BtnQuit.gameObject:SetActiveEx(false)
end

function XUiSelectAssistanceGuildWar:OnBtnJoinClick()
    local character = self.CurCharacter
    if character then
        local characterId = character:GetId()
        XDataCenter.GuildWarManager.SendAssistant(characterId)
        self.Super.Close(self)
    end
end

function XUiSelectAssistanceGuildWar:OnBtnQuitClick()
    local character = self.CurCharacter
    if character then
        local characterId = character:GetId()
        XDataCenter.GuildWarManager.CancelAssistant(characterId)
        self.Super.Close(self)
    end
end

function XUiSelectAssistanceGuildWar:OnEnableCb()
    local characterId = XDataCenter.GuildWarManager.GetAssistantCharacterId()
    if characterId and characterId > 0 then
        self.PanelFilter:DoSelectCharacter(characterId)
    end
end

function XUiSelectAssistanceGuildWar:GetGridProxy()
    local XGridCharacterGuildWarAssistantV2P6 = require("XUi/XUiCharacterV2P6/Grid/XGridCharacterGuildWarAssistantV2P6")
    return XGridCharacterGuildWarAssistantV2P6
end

return XUiSelectAssistanceGuildWar
