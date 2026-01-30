local XUiGridRelinkPopupChooseCharacter = require("XUi/XUiDlcRelink/Room/XUiGridRelinkPopupChooseCharacter")
---@class XUiRelinkPopupChooseCharacter : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiRelinkPopupChooseCharacter = XLuaUiManager.Register(XLuaUi, "UiRelinkPopupChooseCharacter")

function XUiRelinkPopupChooseCharacter:OnAwake()
    XMVCA.XDlcRoom:BeginSelectCharacter()
    self.GridCharacterNew.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self:InitDynamicTable()
end

function XUiRelinkPopupChooseCharacter:OnStart(characterId)
    self.OriginalCharacterId = characterId
    self.SelectCharacterId = 0
    self.SelectCharacterGrid = nil
end

function XUiRelinkPopupChooseCharacter:OnEnable()
    self.SelectCharacterId = 0
    self:SetupDynamicTable()
end

function XUiRelinkPopupChooseCharacter:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_ROOM_SELECT_CHARACTER,
        XEventId.EVENT_DLC_MULTIPLAYER_MATCHING_BACK
    }
end

function XUiRelinkPopupChooseCharacter:OnNotify(event, ...)
    self:EndSelectingAndClose()
end

function XUiRelinkPopupChooseCharacter:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self.DynamicTable:SetProxy(XUiGridRelinkPopupChooseCharacter, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRelinkPopupChooseCharacter:SetupDynamicTable()
    self.CharacterIdList = self._Control:GetCharacterIdList()
    if XTool.IsTableEmpty(self.CharacterIdList) then
        return
    end
    local selectIndex = 1
    for index, characterId in ipairs(self.CharacterIdList) do
        if characterId == self.OriginalCharacterId then
            self.SelectCharacterId = characterId
            selectIndex = index
            break
        end
    end
    self.DynamicTable:SetDataSource(self.CharacterIdList)
    self.DynamicTable:ReloadDataASync(selectIndex)
end

---@param grid XUiGridRelinkPopupChooseCharacter
function XUiRelinkPopupChooseCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local characterId = self.CharacterIdList[index]
        grid:Refresh(characterId)
        if self.SelectCharacterId == characterId then
            self.SelectCharacterGrid = grid
            grid:OnSelected(true)
        else
            grid:OnSelected(false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:ChangeSelectCharacter(grid)
    end
end

---@param grid XUiGridRelinkPopupChooseCharacter
function XUiRelinkPopupChooseCharacter:ChangeSelectCharacter(grid)
    if self.SelectCharacterGrid then
        self.SelectCharacterGrid:OnSelected(false)
    end
    self.SelectCharacterGrid = grid
    self.SelectCharacterId = grid:GetCharacterId()
    grid:OnSelected(true)
end

function XUiRelinkPopupChooseCharacter:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnYes, self.OnBtnYesClick)
end

function XUiRelinkPopupChooseCharacter:EndSelectingAndClose()
    XMVCA.XDlcRoom:EndSelectCharacter()
    self:Close()
end

function XUiRelinkPopupChooseCharacter:OnBtnCancelClick()
    self:EndSelectingAndClose()
end

function XUiRelinkPopupChooseCharacter:OnBtnYesClick()
    if XTool.IsNumberValid(self.SelectCharacterId) and self.SelectCharacterId ~= self.OriginalCharacterId then
        XMVCA.XDlcRoom:SelectCharacter(self.SelectCharacterId)
    else
        self:EndSelectingAndClose()
    end
end

return XUiRelinkPopupChooseCharacter
