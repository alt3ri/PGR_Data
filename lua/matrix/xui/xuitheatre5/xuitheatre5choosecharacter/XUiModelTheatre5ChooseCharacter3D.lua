--- 专门管理场景模型的类
---@class XUiModelTheatre5ChooseCharacter3D: XUiNode
---@field private _Control XTheatre5Control
local XUiModelTheatre5ChooseCharacter3D = XClass(XUiNode, 'XUiModelTheatre5ChooseCharacter3D')
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XTheatre5CharacterAnimatorFSM = require('XModule/XTheatre5/XTheatre5CharacterAnimatorFSM')

local DefaultRoleAnimaName = "StandAct0101"
function XUiModelTheatre5ChooseCharacter3D:OnStart()
    -- 莉莉丝特调，只有莉莉丝模型有Ui特效，其他角色都不播放
    local IndexLilith = 4
    self._CharacterIndexPlayUiEffect = {
        [IndexLilith] = true
    }
end

function XUiModelTheatre5ChooseCharacter3D:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CHARACTER_FASHION_CHANGED, self.RefreshCharacterShow, self)
    self:ResetAllActionAndUiEffect()
end

function XUiModelTheatre5ChooseCharacter3D:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CHARACTER_FASHION_CHANGED, self.RefreshCharacterShow, self)
    if self._TimerResetAllActionAndUiEffect then
        XScheduleManager.UnSchedule(self._TimerResetAllActionAndUiEffect)
        self._TimerResetAllActionAndUiEffect = false
    end
end

function XUiModelTheatre5ChooseCharacter3D:OnDestroy()
    self.CharacterCfgs = nil
end

function XUiModelTheatre5ChooseCharacter3D:LoadCharacters(characterCfgs)
    ---@type XUiPanelRoleModel[]
    self.UiPanelRoleModels = {}
    ---@type XTableTheatre5Character[]
    self.CharacterCfgs = characterCfgs
    ---@type XTheatre5CharacterAnimatorFSM[]
    self.CharacterAnimFSM = {}

    self.CharaId2UiModelMap = {}
    self.CharaId2AnimFSMMap = {}

    for i = 1, #characterCfgs do
        local root = self['PanelRoleModel' .. i]

        if root then
            local cfg = self.CharacterCfgs[i]
            local mainlineFashionId = self._Control.CharacterControl:GetMainlineFashionIdByCharacterIdCurMode(cfg.Id)
            local animatorController = self._Control.CharacterControl:GetAnimatorControllerByCharacterIdCurMode(cfg.Id)

            self.UiPanelRoleModels[i] = XUiPanelRoleModel.New(root, 'UiTheatre5ChooseCharacter', true, true)
            self:UpdateRoleModelByHand(self.UiPanelRoleModels[i], cfg.CharacterId, mainlineFashionId, animatorController)
            self.UiPanelRoleModels[i]:ShowRoleModel()

            self.CharacterAnimFSM[i] = XTheatre5CharacterAnimatorFSM.New(i, self, XMVCA.XTheatre5.EnumConst.CharacterAnimaState.FullView)

            self.CharaId2UiModelMap[cfg.Id] = self.UiPanelRoleModels[i]
            self.CharaId2AnimFSMMap[cfg.Id] = self.CharacterAnimFSM[i]
        else
            break
        end
    end

    -- 从新手战斗退出之后，从ui栈恢复ui时，出现动作和模型不一致问题，需要重置
    self._TimerResetAllActionAndUiEffect = XScheduleManager.ScheduleNextFrame(function()
        self:ResetAllActionAndUiEffect()
        self._TimerResetAllActionAndUiEffect = false
    end)
end

function XUiModelTheatre5ChooseCharacter3D:RefreshCharacterShow(charaCfg)
    if not charaCfg then
        return
    end

    local uiModel = self.CharaId2UiModelMap[charaCfg.Id]

    if uiModel then
        local mainlineFashionId = self._Control.CharacterControl:GetMainlineFashionIdByCharacterIdCurMode(charaCfg.Id)
        local animatorController = self._Control.CharacterControl:GetAnimatorControllerByCharacterIdCurMode(charaCfg.Id)

        self:UpdateRoleModelByHand(uiModel, charaCfg.CharacterId, mainlineFashionId, animatorController)

        -- 显示刷新特效
        local posPoint = self['ModelChangedEffectRoot' .. self._CurFocusIndex]

        if posPoint then
            if self.FxUiHuanRen then
                self.FxUiHuanRen.transform.position = posPoint.transform.position
                self.FxUiHuanRen:PlayWithEnable()
            end
        end
    end

    local fsm = self.CharaId2AnimFSMMap[charaCfg.Id]

    if fsm then
        fsm:RefreshState()
    end
end

function XUiModelTheatre5ChooseCharacter3D:RefreshAllCharacterAnimation()
    if not XTool.IsTableEmpty(self.CharaId2AnimFSMMap) then
        for i, fsm in pairs(self.CharaId2AnimFSMMap) do
            fsm:RefreshState()
        end
    end
end

function XUiModelTheatre5ChooseCharacter3D:SetCharactersVisible(characters, enable)
    if XTool.IsTableEmpty(characters) then
        return
    end
    for _, characterId in pairs(characters) do
        local root = self['PanelRoleModel' .. characterId]
        if root then
            root.gameObject:SetActiveEx(enable)
        end
    end
end

---@param panelRoleModel XUiPanelRoleModel
function XUiModelTheatre5ChooseCharacter3D:UpdateRoleModelByHand(panelRoleModel, characterId, fashionId, runtimeControllerName)
    --获取时装ModelName
    local resourcesId
    if fashionId then
        resourcesId = XDataCenter.FashionManager.GetResourcesId(fashionId)
    else
        resourcesId = XDataCenter.FashionManager.GetFashionResourceIdByCharId(characterId)
    end

    local fashionModelName

    if resourcesId then
        fashionModelName = XMVCA.XCharacter:GetCharResModel(resourcesId)
    else
        fashionModelName = XDisplayManager.GetModelName(characterId)
    end

    local isSpecialModel, isMultiModel = XModelManager.CheckModelIsSpecial(fashionModelName, panelRoleModel.RefName)
    -- 特殊模型 && 非多重模型
    if isSpecialModel and not isMultiModel then
        fashionModelName = XModelManager.GetSpecialModelId(fashionModelName, panelRoleModel.RefName)
    end

    panelRoleModel:UpdateCharacterModel(characterId, nil, panelRoleModel.RefName, nil, nil, fashionId, nil, nil, nil, true)
    -- 加载animationController
    local runtimeController = CS.LoadHelper.LoadUiController(runtimeControllerName, panelRoleModel.RefName)

    if runtimeController == nil or not runtimeController:Exist() then
        XLog.Error("XUiPanelDisplay RefreshSelf 错误: 展示角色的动画状态机加载失败: 状态机名称 " .. runtimeControllerName .. " Ui名称：" .. panelRoleModel.RefName)
        return
    end

    local animator = panelRoleModel:GetAnimator()

    if animator then
        XModelManager.HandleUiModelNodeActive(DefaultRoleAnimaName, panelRoleModel.CurRoleName, panelRoleModel:GetCurRoleModel(), false)
        animator.runtimeAnimatorController = runtimeController
        ---@type UnityEngine.GameObject
        local loadAnimatioClip = animator.gameObject:GetComponent(typeof(CS.XLoadAnimationClip))

        if loadAnimatioClip then
            CS.UnityEngine.Component.Destroy(loadAnimatioClip)
        end

        -- 重新加载特效
        local actionId = panelRoleModel:GetPlayingStateName(0) -- 0:只展示身体

        local weaponFashionId
        if XRobotManager.CheckIsRobotId(characterId) then
            local robotId = characterId
            characterId = XRobotManager.GetCharacterId(robotId)
            weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
        end
        panelRoleModel:LoadCharacterUiEffect(characterId, actionId, nil, weaponFashionId, nil)
    end
end

function XUiModelTheatre5ChooseCharacter3D:SetCharacterFocus(index)
    if self._CurFocusIndex == index then
        return
    end

    if XTool.IsNumberValid(self._CurFocusIndex) then
        -- 取消动画
        local animaFsm = self.CharacterAnimFSM[self._CurFocusIndex]

        if animaFsm then
            animaFsm:SetState(XMVCA.XTheatre5.EnumConst.CharacterAnimaState.FullView)
        end
    end

    self._CurFocusIndex = index

    -- 切换相机
    for i = 1, 100 do
        local farCam = self['UiCamFarCharacter' .. i]
        local nearCam = self['UiCamNearCharacter' .. i]

        if not farCam and not nearCam then
            break
        end

        farCam.gameObject:SetActiveEx(i == index)
        nearCam.gameObject:SetActiveEx(i == index)
    end

    -- 播放选中动画
    local animaFsm = self.CharacterAnimFSM[index]

    if animaFsm then
        animaFsm:SetState(XMVCA.XTheatre5.EnumConst.CharacterAnimaState.Choose)
    end

    -- 返回全局视角时,需要重新播放动画和特效
    if index == nil then
        self:ResetAllActionAndUiEffect()
        
    else
        -- 莉莉丝特调:需要停止播放纸牌特效, 否则纸牌特效会在桌面上播放, 会穿帮
        if index and index > 0 then
            for indexToStopEffect, _ in pairs(self._CharacterIndexPlayUiEffect) do
                local roleModel = self.UiPanelRoleModels[indexToStopEffect]
                if roleModel then
                    roleModel:StopUiLoopEffect()
                end
            end
        end
    end
end

--- 由状态机内部传参调用
function XUiModelTheatre5ChooseCharacter3D:PlayAnimaCross(index, type, noCross)
    local roleModel = self.UiPanelRoleModels[index]
    local charaCfg = self.CharacterCfgs[index]

    if roleModel and charaCfg then
        local anima = nil

        ---@type XTableTheatre5CharacterFashion
        local curFashionCfg = self._Control.CharacterControl:GetFashionCfgByCharacterIdInCurMode(charaCfg.Id)

        if type == XMVCA.XTheatre5.EnumConst.CharacterAnimaType.FullView then
            anima = curFashionCfg.NoChooseAnima
        elseif type == XMVCA.XTheatre5.EnumConst.CharacterAnimaType.FullViewSwitch then
            anima = curFashionCfg.NoChooseSwitchAnima
        elseif type == XMVCA.XTheatre5.EnumConst.CharacterAnimaType.Choose then
            anima = curFashionCfg.ChooseAnima
        elseif type == XMVCA.XTheatre5.EnumConst.CharacterAnimaType.ChooseSwitch then
            anima = curFashionCfg.ChooseSwitchAnima
        elseif type == XMVCA.XTheatre5.EnumConst.CharacterAnimaType.Detail then
            anima = curFashionCfg.DetailIdleAnima
        end

        if not string.IsNilOrEmpty(anima) then
            if noCross then
                roleModel:PlayAnima(anima, 0)
                if self._CharacterIndexPlayUiEffect[index] then
                    if self._CurFocusIndex == nil or self._CurFocusIndex == 0 then
                        roleModel:ReplayUiLoopEffect()
                    else
                        roleModel:StopUiLoopEffect()    
                    end
                end
            else
                roleModel:PlayAnimaCross(anima)
                -- 其他角色的特效是一次性的，不loop，不能replay，否则在切换镜头的时候会重复播放特效
                if self._CharacterIndexPlayUiEffect[index] then
                    if self._CurFocusIndex == nil or self._CurFocusIndex == 0 then
                        roleModel:PlayCharacterUiEffect()
                        roleModel:ReplayUiLoopEffect()
                    else
                        roleModel:StopUiLoopEffect()
                    end
                end
            end
        end
    end
end

function XUiModelTheatre5ChooseCharacter3D:ResetAllActionAndUiEffect()
    if self.CharacterCfgs then
        for i = 1, #self.CharacterCfgs do
            if self._CharacterIndexPlayUiEffect[i] then
                -- 只处理莉莉丝，因为其他角色的模型是一次性的，不loop的，不会出现这个问题
                if self.CharacterCfgs[i] then
                    if self._CurFocusIndex == nil or self._CurFocusIndex == 0 then
                        self:PlayAnimaCross(i, XMVCA.XTheatre5.EnumConst.CharacterAnimaType.FullViewSwitch, true)
                    else
                        self:PlayAnimaCross(i, XMVCA.XTheatre5.EnumConst.CharacterAnimaType.Choose, true)
                    end
                end
            end
        end
    end
end

return XUiModelTheatre5ChooseCharacter3D