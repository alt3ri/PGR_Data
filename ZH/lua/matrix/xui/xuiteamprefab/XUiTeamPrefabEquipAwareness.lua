local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiTeamPrefabEquipAwareness = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabEquipAwareness")

function XUiTeamPrefabEquipAwareness:OnAwake()
    -- 模型初始化
    self.PanelRoleModelGo = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = self.UiModelGo.transform:FindTransform("ImgEffectHuanren1")
    self.ImgEffectHuanren.gameObject:SetActive(false)
    self.ImgEffectHuanren1.gameObject:SetActive(false)
    self.UiPanelRoleModel = XUiPanelRoleModel.New(self.PanelRoleModelGo, self.Name, nil, true)

    -- 装备面板初始化（替换为预设专用面板）
    self.PanelEquip = XMVCA.XEquip:InitPanelEquipTeamPrefab(self.PanelEquip, self, self)
    self.PanelEquip:InitData()

    self:SetButtonCallBack()
    self:InitPanelAsset()
end

function XUiTeamPrefabEquipAwareness:OnStart(teamPrefab, pos, closeCallback)
    -- 存储预设数据（核心差异点）
    self.TeamPrefab = teamPrefab
    self.CurrentPos = pos
    self.CloseCallback = closeCallback
    self.CharacterId = self.TeamPrefab:GetEntityIdByTeamPos(pos)

    -- 由动画展开意识面板（完全复用原版）
    local anim = self.PanelEquip.PanelEquipEnable:GetComponent("PlayableDirector")
    anim.time = anim.duration
    anim:Play()
    self.PanelEquip.PanelAwareness.gameObject:SetActiveEx(true)

    -- 切换按钮不显示，不可点击（保持原版）
    local canvasGroup = self.PanelEquip.BtnFold:GetComponent("CanvasGroup")
    canvasGroup.alpha = 0
    canvasGroup.blocksRaycasts = false

    -- 预设面板额外初始化
    self.PanelEquip:InitTeamPrefabData(teamPrefab, pos)

    -- 刷新装备面板（适配预设）
    self.PanelEquip:Open()
    self.PanelEquip.IsShowPanelAwareness = true
    self.PanelEquip:UpdateCharacter(self.CharacterId)
    self.PanelEquip:InitUnFoldButton()
end

function XUiTeamPrefabEquipAwareness:OnEnable()
    self.PanelEquip:UpdateAwarenessView()
    self:RefreshModel(self.CharacterId)
end

function XUiTeamPrefabEquipAwareness:OnDisable()
    self:ReleasePlayEffectTimer()
end

function XUiTeamPrefabEquipAwareness:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiTeamPrefabEquipAwareness:OnBtnBackClick()
    self:Close()
end

function XUiTeamPrefabEquipAwareness:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTeamPrefabEquipAwareness:InitPanelAsset()
    self.AssetPanel = XUiPanelAsset.New(
        self,
        self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin
    )
end

-- 初始化角色模型（完全复用原版）
function XUiTeamPrefabEquipAwareness:RefreshModel(entityId)
    local finishedCallback = function(model)
        self.PanelDrag.Target = model.transform
        self:PlaySwitchEffect()
    end

    local entity = XMVCA.XCharacter:GetCharacter(entityId)
    local characterViewModel = entity:GetCharacterViewModel()
    local sourceEntityId = characterViewModel:GetSourceEntityId()
    
    if XRobotManager.CheckIsRobotId(sourceEntityId) then
        local robot2CharEntityId = XRobotManager.GetCharacterId(sourceEntityId)
        local isOwen = XMVCA.XCharacter:IsOwnCharacter(robot2CharEntityId)
        if XRobotManager.CheckUseFashion(sourceEntityId) and isOwen then
            local character = XMVCA.XCharacter:GetCharacter(robot2CharEntityId)
            local robot2CharViewModel = character:GetCharacterViewModel()
            self.UiPanelRoleModel:UpdateCharacterModel(robot2CharEntityId
            , self.PanelRoleModelGo
            , self.Name
            , finishedCallback
            , nil
            , robot2CharViewModel:GetFashionId())
        else
            local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
            self.UiPanelRoleModel:UpdateRobotModel(sourceEntityId
            , robotConfig.CharacterId
            , nil
            , robotConfig.FashionId
            , robotConfig.WeaponId
            , finishedCallback
            , nil
            , self.PanelRoleModelGo
            , self.Name)
        end
    else
        self.UiPanelRoleModel:UpdateCharacterModel(
        sourceEntityId,
        self.PanelRoleModelGo,
        self.Name,
        finishedCallback,
        nil,
        characterViewModel:GetFashionId()
        )
    end
end

-- 播放切换特效（完全复用原版）
function XUiTeamPrefabEquipAwareness:PlaySwitchEffect()
    -- 第一次打开界面延迟播特效
    local isFirst = not self.IsPlayed
    if isFirst then
        self:ReleasePlayEffectTimer()
        self.PlayEffectTimer = XScheduleManager.ScheduleOnce(function() 
            self.PlayEffectTimer = nil
            self:PlaySwitchEffect()
        end, 500)
        self.IsPlayed = true
        return
    end

    local characterType = XMVCA.XCharacter:GetCharacterType(self.CharacterId)
    if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
        self.ImgEffectHuanren.gameObject:SetActive(true)
    else
        self.ImgEffectHuanren.gameObject:SetActive(false)
    end
end

function XUiTeamPrefabEquipAwareness:ReleasePlayEffectTimer()
    if self.PlayEffectTimer then
        XScheduleManager.UnSchedule(self.PlayEffectTimer)
        self.PlayEffectTimer = nil
    end
end

function XUiTeamPrefabEquipAwareness:OnDestroy()
    if self.CloseCallback then
        self.CloseCallback(self.ChangeEquipSuccess)
    end
end

return XUiTeamPrefabEquipAwareness
