local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiPanelDlcRelinkCharacterRightOther = require("XUi/XUiDlcRelink/Room/Panel/XUiPanelDlcRelinkCharacterRightOther")
---@class XUiDlcRelinkCharacterOther : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PanelDrag XDrag
local XUiDlcRelinkCharacterOther = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkCharacterOther")

function XUiDlcRelinkCharacterOther:OnAwake()
    self:RegisterUiEvents()
end

---@param member XDlcMember 克隆后的成员数据
function XUiDlcRelinkCharacterOther:OnStart(member)
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self._Control.OtherMemberControl:SetMemberData(member)
    self.Member = member

    self:InitSceneModel()
end

function XUiDlcRelinkCharacterOther:OnEnable()
    self.Super.OnEnable(self)
    if not self.Member then
        XLog.Error("XUiDlcRelinkCharacterOther:OnEnable() self.Member is nil")
        return
    end

    self:RefreshPlayer()
    self:RefreshModel()
    self:RefreshPanelRight()
end

function XUiDlcRelinkCharacterOther:OnDisable()
    self.Super.OnDisable(self)
end

function XUiDlcRelinkCharacterOther:OnDestroy()
    self._Control.OtherMemberControl:ClearMemberData()
    self.Member = nil
end

function XUiDlcRelinkCharacterOther:InitSceneModel()
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

function XUiDlcRelinkCharacterOther:RefreshPlayer()
    XUiPlayerHead.InitPortrait(self.Member:GetHeadPortraitId(), self.Member:GetHeadFrameId(), self.Head)
    self.TxtPlayer.text = self.Member:GetName()
end

function XUiDlcRelinkCharacterOther:RefreshModel()
    if not self.RoleModel then
        ---@type XUiPanelRoleModel
        self.RoleModel = XUiPanelRoleModel.New(self.PanelRoleModel1, self.Name, nil, true)
    end
    self.RoleModel:ShowRoleModel()
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(self.Member:GetCharacterId()).DefaultNpcFashtionId
    self.RoleModel:UpdateCharacterModel(self.Member:GetCharacterId(), self.PanelRoleModel1, self.Name, function(model)
        self.PanelDrag.Target = model.transform
    end, nil, fashionId, nil, nil, true)
end

function XUiDlcRelinkCharacterOther:RefreshPanelRight()
    if not self.PanelRightNode then
        ---@type XUiPanelDlcRelinkCharacterRightOther
        self.PanelRightNode = XUiPanelDlcRelinkCharacterRightOther.New(self.PanelRight, self)
    end
    self.PanelRightNode:Open()
    self.PanelRightNode:Refresh(self.Member)
end

function XUiDlcRelinkCharacterOther:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnPlayer, self.OnBtnPlayerClick)
end

function XUiDlcRelinkCharacterOther:OnBtnBackClick()
    self:Close()
end

-- 查看个人信息
function XUiDlcRelinkCharacterOther:OnBtnPlayerClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.Member:GetPlayerId())
end

return XUiDlcRelinkCharacterOther
