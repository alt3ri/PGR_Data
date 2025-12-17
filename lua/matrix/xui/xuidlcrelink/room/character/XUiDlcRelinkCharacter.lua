local XUiGridDlcRelinkCharacter = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkCharacter")
local XUiPanelDlcRelinkCharacterRight = require("XUi/XUiDlcRelink/Room/Panel/XUiPanelDlcRelinkCharacterRight")
---@class XUiDlcRelinkCharacter : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PanelDrag XDrag
local XUiDlcRelinkCharacter = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkCharacter")

function XUiDlcRelinkCharacter:OnAwake()
    XMVCA.XDlcRoom:BeginSelectCharacter()
    self.PanelEmptyList.gameObject:SetActiveEx(false)
    self.PanelRight.gameObject:SetActiveEx(false)
    self.GridCharacter.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self.AssetPanel = XUiHelper.XUiPanelAsset(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.DlcRelinkCoin)
end

function XUiDlcRelinkCharacter:OnStart(characterId)
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self:InitDynamicTable()
    self.OriginalCharacterId = characterId

    self.CurSelectCharacterId = 0
    self.CurSelectGrid = nil
end

function XUiDlcRelinkCharacter:OnEnable()
    self.Super.OnEnable(self)
    self:SetupDynamicTable()
    self:RefreshPlayer()
end

function XUiDlcRelinkCharacter:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_ROOM_SELECT_CHARACTER,
        XEventId.EVENT_DLC_MULTIPLAYER_MATCHING_BACK
    }
end

function XUiDlcRelinkCharacter:OnNotify(event, ...)
    self:EndSelectingAndClose()
end

function XUiDlcRelinkCharacter:OnDisable()
    self.Super.OnDisable(self)
    self.CurSelectCharacterId = 0
    self.CurSelectGrid = nil
end

function XUiDlcRelinkCharacter:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.GridCharacterList)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkCharacter, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkCharacter:SetupDynamicTable()
    self.CharacterIds = self._Control:GetCharacterIdList()
    local isEmpty = XTool.IsTableEmpty(self.CharacterIds)
    self.PanelEmptyList.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        return
    end

    local index = 1
    for i, id in ipairs(self.CharacterIds) do
        if id == self.OriginalCharacterId then
            index = i
            break
        end
    end
    self.CurSelectCharacterId = self.CharacterIds[index]

    self.DynamicTable:SetDataSource(self.CharacterIds)
    self.DynamicTable:ReloadDataASync(index)
end

---@param grid XUiGridDlcRelinkCharacter
function XUiDlcRelinkCharacter:OnDynamicTableEvent(event, index, grid)
    local characterId = self.CharacterIds[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(characterId)
        local isSelected = characterId == self.CurSelectCharacterId
        grid:SetSelect(isSelected)
        grid:SetNow(self.OriginalCharacterId == characterId)
        if isSelected and not self.CurSelectGrid then
            self.CurSelectGrid = grid
            self:RefreshPanelRight()
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if characterId == self.CurSelectCharacterId then
            return
        end
        if self.CurSelectGrid then
            self.CurSelectGrid:SetSelect(false)
        end
        grid:SetSelect(true)
        self.CurSelectCharacterId = characterId
        self.CurSelectGrid = grid
        self:RefreshPanelRight()
    end
end

function XUiDlcRelinkCharacter:RefreshPlayer()
    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    self.TxtPlayer.text = XPlayer.Name
end

function XUiDlcRelinkCharacter:RefreshPanelRight()
    if not self.PanelRightNode then
        ---@type XUiPanelDlcRelinkCharacterRight
        self.PanelRightNode = XUiPanelDlcRelinkCharacterRight.New(self.PanelRight, self)
        self.PanelRightNode:Open()
    end
    self.PanelRightNode:Refresh(self.CurSelectCharacterId)
end

function XUiDlcRelinkCharacter:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
end

function XUiDlcRelinkCharacter:OnBtnBackClick()
    self:EndSelectingAndClose()
end

function XUiDlcRelinkCharacter:EndSelectingAndClose()
    XMVCA.XDlcRoom:EndSelectCharacter()
    self:Close()
end

return XUiDlcRelinkCharacter
