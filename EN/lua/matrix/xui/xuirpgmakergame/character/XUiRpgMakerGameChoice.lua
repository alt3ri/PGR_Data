local CSXTextManagerGetText = CS.XTextManager.GetText

---@class XUiRpgMakerGameChoice
---@field _Control XRpgMakerGameControl
local XUiRpgMakerGameChoice = XLuaUiManager.Register(XLuaUi, "UiRpgMakerGameChoice")

function XUiRpgMakerGameChoice:OnAwake()
    self.PanelDrag.gameObject:SetActiveEx(false)
    self.PanelDragLock.gameObject:SetActiveEx(false)
    self:AutoAddListener()
    self:InitSceneRoot()
end

function XUiRpgMakerGameChoice:OnStart(stageId)
    self.StageId = stageId
    self._Control:SetCurrentStageId(stageId)
    --限定使用的角色Id
    self.CharacterId = self._Control:GetConfig():GetStageUseRoleId(stageId)
    if not self.CharacterId then
        self.CharacterId = XDataCenter.RpgMakerGameManager.GetOnceUnLockRoleId()
    end
end

function XUiRpgMakerGameChoice:OnEnable()
    self:Refresh()
end

function XUiRpgMakerGameChoice:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:RegisterClickEvent(self.BtnEnterFight, self.OnBtnEnterFightClick)

    local curChapterGroupId = XDataCenter.RpgMakerGameManager.GetCurChapterGroupId()
    self:BindHelpBtn(self.BtnHelp, XMVCA.XRpgMakerGame:GetConfig():GetChapterGroupHelpKey(curChapterGroupId))
end

function XUiRpgMakerGameChoice:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
end

function XUiRpgMakerGameChoice:UpdateModel()
    if not self.RoleModelPanel then
        local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
        self.RoleModelPanel =  XUiPanelRoleModel.New(self.PanelRoleModel, self.Name)
    end
    
    local modelName = XMVCA.XRpgMakerGame:GetConfig():GetRoleModelAssetPath(self.CharacterId)
    self.RoleModelPanel:UpdateRoleModelWithAutoConfig(modelName, XModelManager.MODEL_UINAME.XUiCharacter, function(model)
        -- self.PanelDrag.Target = model.transform
    end)
    self.RoleModelPanel:ShowRoleModel()
end

function XUiRpgMakerGameChoice:OnBtnEnterFightClick()
    local stageId = self:GetStageId()
    local characterId = self:GetCharacterId()
    local cb = function()
        self._Control:LoadScene()
    end
    XMVCA.XRpgMakerGame:RequestRpgMakerGameEnterStage(stageId, characterId, cb)
end

function XUiRpgMakerGameChoice:GetCharacterId()
    return self.CharacterId
end

function XUiRpgMakerGameChoice:GetStageId()
    return self.StageId
end

function XUiRpgMakerGameChoice:Refresh()
    -- 更新角色模型
    self:UpdateModel()
    
    -- 刷新角色信息
    self:RefreshCharacterInfo()
end

-- 刷新角色信息
function XUiRpgMakerGameChoice:RefreshCharacterInfo()
    local skillTypes = self._Control:GetConfig():GetRoleSkillTypes(self.CharacterId)
    local skillType1 = skillTypes[1]
    local skillType2 = skillTypes[2]
    if skillType1 and skillType2 then
        self.PanelOneAttr.gameObject:SetActiveEx(false)
        self.PanelTwoAttr.gameObject:SetActiveEx(true)
        self:RefreshSkillType(self.PanelLeftAttr, skillType1, 1)
        self:RefreshSkillType(self.PanelRightAttr, skillType2, 2)
    elseif skillType1 then
        self.PanelOneAttr.gameObject:SetActiveEx(true)
        self.PanelTwoAttr.gameObject:SetActiveEx(false)
        self:RefreshSkillType(self.PanelAttr, skillType1, 1)
    end
end

function XUiRpgMakerGameChoice:RefreshSkillType(uiObj, skillType, index)
    -- 角色名称
    local textName = uiObj:GetObject("TextName", false)
    if textName then
        textName.text = self._Control:GetConfig():GetRoleName(self.CharacterId)
    end

    -- 属性
    local textAttribute = uiObj:GetObject("TextAttribute")
    local imgAttribute = uiObj:GetObject("ImgAttribute") 
    local skillTypeIcon = self._Control:GetConfig():GetSkillTypeIcon(skillType)
    textAttribute.text = self._Control:GetConfig():GetSkillTypeName(skillType)
    imgAttribute:SetRawImage(skillTypeIcon)
    
    -- 属性描述
    local txtEnergy = uiObj:GetObject("TxtEnergy")
    local imgBefore = uiObj:GetObject("ImgBefore")
    local imgAfter = uiObj:GetObject("ImgAfter")
    local beforeIcon = self._Control:GetConfig():GetRoleSkillTypeIconBefore(self.CharacterId, index)
    local afterIcon = self._Control:GetConfig():GetRoleSkillTypeIconAfter(self.CharacterId, index)
    txtEnergy.text = self._Control:GetConfig():GetRoleSkillTypeDesc(self.CharacterId, index)
    imgBefore:SetSprite(beforeIcon)
    imgAfter:SetSprite(afterIcon)
end

return XUiRpgMakerGameChoice