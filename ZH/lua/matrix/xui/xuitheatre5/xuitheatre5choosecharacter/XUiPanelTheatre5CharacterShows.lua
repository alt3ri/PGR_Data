--- 角色选择界面最开始的界面，展示所有角色
---@class XUiPanelTheatre5CharacterShows: XUiNode
---@field private _Control XTheatre5Control
---@field Parent UiTheatre5ChooseCharacter
local XUiPanelTheatre5CharacterShows = XClass(XUiNode, 'XUiPanelTheatre5CharacterShows')

function XUiPanelTheatre5CharacterShows:OnStart()
    self:InitCharacterList()
end

function XUiPanelTheatre5CharacterShows:InitCharacterList()
    local characterCfgs = self._Control:GetTheatre5CharacterCfgs()
    
    for i = 1, 100 do
        local btn = self['Character'..i]

        if btn then
            if characterCfgs[i] ~= nil then
                btn.gameObject:SetActiveEx(true)
                
                local index = i
                
                btn.CallBack = function()
                    self.Parent:OnSelectCharacter(index)
                    self:Close()
                end
            else
                btn.gameObject:SetActiveEx(false)
            end
        else
            break
        end
    end
end

return XUiPanelTheatre5CharacterShows