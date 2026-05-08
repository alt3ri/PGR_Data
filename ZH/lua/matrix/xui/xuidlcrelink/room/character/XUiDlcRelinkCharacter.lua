local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiGridDlcRelinkCharacter = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkCharacter")
local XUiPanelDlcRelinkCharacterRight = require("XUi/XUiDlcRelink/Room/Panel/XUiPanelDlcRelinkCharacterRight")
---@class XUiDlcRelinkCharacter : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PanelDrag XDrag
local XUiDlcRelinkCharacter = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkCharacter")

function XUiDlcRelinkCharacter:OnAwake()
    self.PanelEmptyList.gameObject:SetActiveEx(false)
    self.PanelRight.gameObject:SetActiveEx(false)
    self.GridCharacter.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()

    -- 进入角色选择界面，设置玩家状态为准备中
    XMVCA.XDlcRoom:ReqSetShowState(XEnumConst.DlcRoom.PlayerShowState.Preparing)
end

function XUiDlcRelinkCharacter:OnStart(characterId)
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self.OriginalCharacterId = characterId

    ---@type XUiGridDlcRelinkCharacter[]
    self.CharacterGridList = {}
    self.CurSelectCharacterId = self.OriginalCharacterId
    self.CurSelectGrid = nil

    self:InitSceneModel()
end

function XUiDlcRelinkCharacter:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshCharacterList()
end

function XUiDlcRelinkCharacter:OnDisable()
    self.Super.OnDisable(self)
    self.CurSelectGrid = nil
end

function XUiDlcRelinkCharacter:OnDestroy()
    XMVCA.XDlcRoom:ReqSetShowState(XEnumConst.DlcRoom.PlayerShowState.Normal)
end

function XUiDlcRelinkCharacter:InitSceneModel()
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    self.PanelRoleModel1 = XUiHelper.TryGetComponent(root, "UiNearRoot/PanelRoleModel1")
    self.UiCamFarCharacter = XUiHelper.TryGetComponent(root, "UiFarRoot/UiCamFarCharacter")
    self.UiCamNearCharacter = XUiHelper.TryGetComponent(root, "UiNearRoot/UiCamNearCharacter")
    if self.UiCamFarCharacter then
        self.UiCamFarCharacter.gameObject:SetActiveEx(true)
    end
    if self.UiCamNearCharacter then
        self.UiCamNearCharacter.gameObject:SetActiveEx(true)
    end
end

function XUiDlcRelinkCharacter:RefreshCharacterList()
    self.CharacterIds = self._Control:GetCharacterIdList()
    local isEmpty = XTool.IsTableEmpty(self.CharacterIds)
    self.PanelEmptyList.gameObject:SetActiveEx(isEmpty)
    self.PanelCharacter.gameObject:SetActiveEx(not isEmpty)
    if isEmpty then
        return
    end

    if not XTool.IsNumberValid(self.CurSelectCharacterId) then
        -- 默认选择第一个角色
        self.CurSelectCharacterId = self.CharacterIds[1]
    end

    for index, characterId in ipairs(self.CharacterIds) do
        local grid = self.CharacterGridList[index]
        if not grid then
            local parent = self[string.format("Character%s", index)]
            if not parent then
                XLog.Error(string.format("XUiDlcRelinkCharacter:RefreshPanelCharacter error: not find Character%s", index))
                return
            end
            local go = XUiHelper.Instantiate(self.GridCharacter, parent)
            grid = XUiGridDlcRelinkCharacter.New(go, self, handler(self, self.OnCharacterGridClick))
            self.CharacterGridList[index] = grid
        end
        grid:Open()
        grid:Refresh(characterId)
        local isSelected = characterId == self.CurSelectCharacterId
        grid:SetSelect(isSelected)
        grid:SetNow(self.OriginalCharacterId == characterId)
        if isSelected and not self.CurSelectGrid then
            self.CurSelectGrid = grid
            self:RefreshModel()
            self:RefreshPanelRight()
        end
    end
end

---@param grid XUiGridDlcRelinkCharacter
function XUiDlcRelinkCharacter:OnCharacterGridClick(grid)
    local characterId = grid:GetCharacterId()
    if characterId == self.CurSelectCharacterId then
        return
    end
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    grid:SetSelect(true)
    self.CurSelectCharacterId = characterId
    self.CurSelectGrid = grid
    self:RefreshModel()
    self:RefreshPanelRight()
end

function XUiDlcRelinkCharacter:RefreshModel()
    if not self.RoleModel then
        ---@type XUiPanelRoleModel
        self.RoleModel = XUiPanelRoleModel.New(self.PanelRoleModel1, self.Name, nil, true)
    end
    self.RoleModel:ShowRoleModel()
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(self.CurSelectCharacterId).DefaultNpcFashtionId
    self.RoleModel:UpdateCharacterModel(self.CurSelectCharacterId, self.PanelRoleModel1, self.Name, function(model)
        self.PanelDrag.Target = model.transform
    end, nil, fashionId, nil, nil, true)
end

function XUiDlcRelinkCharacter:RefreshPanelRight()
    if not self.PanelRightNode then
        ---@type XUiPanelDlcRelinkCharacterRight
        self.PanelRightNode = XUiPanelDlcRelinkCharacterRight.New(self.PanelRight, self)
    end
    self.PanelRightNode:Open()
    self.PanelRightNode:Refresh(self.CurSelectCharacterId)
end

function XUiDlcRelinkCharacter:RegisterUiEvents()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
end

function XUiDlcRelinkCharacter:OnBtnBackClick()
    self:Close()
end

return XUiDlcRelinkCharacter
