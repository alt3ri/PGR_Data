---@class XUiPanelTheatre5CharacterList: XUiNode
---@field private _Control XTheatre5Control
---@field Parent UiTheatre5ChooseCharacter
---@field ButtonGroup XUiButtonGroup
local XUiPanelTheatre5CharacterList = XClass(XUiNode, 'XUiPanelTheatre5CharacterList')
local XUiGridTheatre5Character = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/XUiGridTheatre5Character')
local XUiGridTheatre5PVECharacter = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/PVE/XUiGridTheatre5PVECharacter')

function XUiPanelTheatre5CharacterList:OnStart()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_CLICK_SCENE_OBJECT, self.UpdateCharacterList, self)
    local curTheatre5Model = XMVCA.XTheatre5:GetCurPlayingMode()
    self._GridClass = curTheatre5Model == XMVCA.XTheatre5.EnumConst.GameMode.PVP and XUiGridTheatre5Character or XUiGridTheatre5PVECharacter
    self:InitCharacterList()
end

function XUiPanelTheatre5CharacterList:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CHARACTER_FASHION_CHANGED, self.UpdateCharacterList, self)
end

function XUiPanelTheatre5CharacterList:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CHARACTER_FASHION_CHANGED, self.UpdateCharacterList, self)
end

function XUiPanelTheatre5CharacterList:InitCharacterList()

    ---@type XUiGridTheatre5Character[]
    self.GridCharacters = {}
    
    self:UpdateCharacterList()
end

function XUiPanelTheatre5CharacterList:UpdateCharacterList()
    local characterCfgs = self._Control:GetTheatre5CharacterCfgs()
    XTool.UpdateDynamicItem(self.GridCharacters, characterCfgs, self.GridCharacter, self._GridClass, self)
end

function XUiPanelTheatre5CharacterList:OnBtnSelect(index, force)
    if self._CurIndex == index and not force then
        return
    end

    if XTool.IsNumberValid(self._CurIndex) then
        self.GridCharacters[self._CurIndex]:OnUnselectShow()
    end
    
    self._CurIndex = index

    if XTool.IsNumberValid(self._CurIndex) then
        self.GridCharacters[self._CurIndex]:OnSelectedShow()

        self.Parent:RefreshDetailShow(self._CurIndex, self.GridCharacters[self._CurIndex].Config)
    end
end

function XUiPanelTheatre5CharacterList:GetCurSelectCharacterConfigId()
    if XTool.IsNumberValid(self._CurIndex) then
        return self.GridCharacters[self._CurIndex].Config.Id
    end
end

function XUiPanelTheatre5CharacterList:OnDestroy()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_CLICK_SCENE_OBJECT, self.UpdateCharacterList, self)
end

return XUiPanelTheatre5CharacterList