local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XTheatre6Scene : XLuaScene
---@field _Control XTheatre6Control
local XTheatre6Scene = XMVCA.XScene:Register(nil, "XTheatre6Scene")

local AllRogue = 1
local CustomRogue = 2
local Normal = 3

function XTheatre6Scene:OnInit()
    ---@type XUiPanelRoleModel[]
    self._RoleModelPanels = {}
    ---@type table<number, XTableTheatre6CharacterFashion>
    self._FashionConfigDict = {}
    ---@type table<number, string> 记录每个位置上次加载的DlcModelId
    self._LoadedDlcModelIdDict = {}
    ---@type table<number, string> 记录每个位置上次加载的AnimatorController
    self._LoadedAnimControllerDict = {}
    ---@type table<number, UnityEngine.GameObject> 每个位置缓存的换人特效对象
    self._HuanRenFxDict = {}
    self._FxUiHuanRen = self._Control:GetClientConfigValue("FxUiHuanRen")
    self._NodeCount = self._Control:GetIntClientConfigValue("SceneRoleNodeCount")
    self.CurSelectIndex = nil
end

----------public start----------

function XTheatre6Scene:UpdateRogueModel(isHideLockRole)
    self:_UpdateRoleModel(AllRogue, isHideLockRole)
end

function XTheatre6Scene:UpdateNormalModel(isHideLockRole)
    self:_UpdateRoleModel(Normal, isHideLockRole)
end

function XTheatre6Scene:UpdateCustomRogueModel(isHideLockRole)
    self:_UpdateRoleModel(CustomRogue, isHideLockRole)
end

function XTheatre6Scene:_UpdateRoleModel(mode, isHideLockRole)
    local index = 0
    ---@type XTableTheatre6Character[]
    self._RoleConfigs = {}
    self._RoleIndexDict = {}
    for _, v in pairs(self._Control:GetCharacterConfigs()) do
        if XTool.IsNumberValid(v.Priority) then
            index = index + 1
            if isHideLockRole and XTool.IsNumberValid(v.ConditionId) and not XConditionManager.CheckCondition(v.ConditionId) then
                goto continue
            end
            table.insert(self._RoleConfigs, v)
            self._RoleIndexDict[v.Id] = index
        end
        :: continue ::
    end
    table.sort(self._RoleConfigs, function(a, b)
        return a.Priority > b.Priority
    end)

    for _, v in ipairs(self._RoleConfigs) do
        local index = self._RoleIndexDict[v.Id]
        local fashionId = v.FashionIds[1] --肉鸽涂装
        if #v.FashionIds >= 2 then
            if mode == AllRogue then
                fashionId = v.FashionIds[1]
            elseif mode == Normal then
                fashionId = v.FashionIds[2]
            elseif mode == CustomRogue then
                fashionId = self._Control:IsUseRogueFashion(v.Id) and v.FashionIds[1] or v.FashionIds[2]
            end
        end
        local fashionConfig = self._Control:GetFashionConfig(fashionId)
        self:_LoadRoleModel(index, fashionId, false, fashionConfig.ChooseAnim)
    end
end

---按角色刷新单个模型（涂装切换时使用，避免整排重载）
---@param roleId number
function XTheatre6Scene:UpdateSingleRougeRoleModel(roleId)
    if not self._RoleIndexDict then
        return
    end
    local index = self._RoleIndexDict[roleId]
    if not index then
        return
    end
    local config
    for _, v in ipairs(self._RoleConfigs) do
        if v.Id == roleId then
            config = v
            break
        end
    end
    if not config then
        return
    end
    local fashionId = self._Control:IsUseRogueFashion(roleId) and config.FashionIds[1] or config.FashionIds[2]
    local fashionConfig = self._Control:GetFashionConfig(fashionId)
    self:PlayHuanRenFx(index)
    self:_LoadRoleModel(index, fashionId, true, fashionConfig.DetailIdleAnim)
end

-- 切换角色（播放选中/取消选中动画）
function XTheatre6Scene:SetChangeByRoleBtn(index)
    if self.CurSelectIndex == index then
        return
    end

    -- 取消选中的角色播放NoChooseAnim
    if self.CurSelectIndex then
        local prevConfig = self._FashionConfigDict[self.CurSelectIndex]
        if prevConfig then
            self:_PlayAnimOnIndex(self.CurSelectIndex, prevConfig.NoChooseAnim)
        end
    end

    self:SetMainCamera(false)
    self:SetAllModelCamFalse()
    self:SetModelSelect(index)
    self.CurSelectIndex = index

    -- 选中的角色播放ChooseAnim
    local curConfig = self._FashionConfigDict[index]
    if curConfig then
        self:_PlayAnimOnIndex(index, curConfig.ChooseAnim)
    end
end

-- 切换角色存档
function XTheatre6Scene:SetChangeArchiveByRoleBtn(index)
    self:SetMainCamera(false)
    self:SetAllModelCamFalse()
    self:SetModelArchiveSelect(index)
    self.CurSelectIndex = index
end

-- 返回主页
function XTheatre6Scene:BackToMain()
    -- 当前选中的角色播放NoChooseAnim
    if self.CurSelectIndex then
        local prevConfig = self._FashionConfigDict[self.CurSelectIndex]
        if prevConfig then
            self:_PlayAnimOnIndex(self.CurSelectIndex, prevConfig.NoChooseAnim)
        end
    end
    self:SetAllModelCamFalse()
    self:SetMainCamera(true)
    self.CurSelectIndex = nil
end

-- 控制主相机
function XTheatre6Scene:SetMainCamera(isActive)
    if self.CamFarMain then
        self.CamFarMain.gameObject:SetActiveEx(isActive)
    end
    if self.CamNearMain then
        self.CamNearMain.gameObject:SetActiveEx(isActive)
    end
end

-- 激活指定角色的相机
function XTheatre6Scene:SetModelSelect(index)
    for modelIndex = 1, self._NodeCount do
        local isCurrent = modelIndex == index
        self._ModelTransform:FindTransform(string.format("UiCamFarCharacter%s", modelIndex)).gameObject:SetActiveEx(isCurrent)
        self._ModelTransform:FindTransform(string.format("UiCamNearCharacter%s", modelIndex)).gameObject:SetActiveEx(isCurrent)
    end
end

-- 激活指定角色存档的相机
function XTheatre6Scene:SetModelArchiveSelect(index)
    for modelIndex = 1, self._NodeCount do
        local isCurrent = modelIndex == index
        self._ModelTransform:FindTransform(string.format("UiCamFarCharacter%sArchive", modelIndex)).gameObject:SetActiveEx(isCurrent)
        self._ModelTransform:FindTransform(string.format("UiCamNearCharacter%sArchive", modelIndex)).gameObject:SetActiveEx(isCurrent)
    end
end

-- 关闭所有角色相机
function XTheatre6Scene:SetAllModelCamFalse()
    for modelIndex = 1, self._NodeCount do
        self._ModelTransform:FindTransform(string.format("UiCamFarCharacter%s", modelIndex)).gameObject:SetActiveEx(false)
        self._ModelTransform:FindTransform(string.format("UiCamNearCharacter%s", modelIndex)).gameObject:SetActiveEx(false)
        self._ModelTransform:FindTransform(string.format("UiCamFarCharacter%sArchive", modelIndex)).gameObject:SetActiveEx(false)
        self._ModelTransform:FindTransform(string.format("UiCamNearCharacter%sArchive", modelIndex)).gameObject:SetActiveEx(false)
    end
end

---已解锁且未通关则显示共通线引导特效，其他情况隐藏
function XTheatre6Scene:SetCommonFxVisible(fx, isVisible)
    if string.IsNilOrEmpty(fx) then
        return
    end
    local effect = self:Find(fx)
    if effect then
        effect.gameObject:SetActiveEx(isVisible)
    end
end

function XTheatre6Scene:HideScene()
    self._Transform.gameObject:SetActiveEx(false)
end

function XTheatre6Scene:ShowScene()
    self._Transform.gameObject:SetActiveEx(true)
end

---播放共通线相机动画，动画结束后执行回调
function XTheatre6Scene:PlayCommonCamAnim(index, cb)
    local nearPath = self._Control:GetClientConfigValue("CommonCameraNear", index)
    local farPath = self._Control:GetClientConfigValue("CommonCameraFar", index)

    self._CommonCameraNear = string.IsNilOrEmpty(nearPath) and nil or self:FindTransform(nearPath)
    self._CommonCameraFar = string.IsNilOrEmpty(farPath) and nil or self:FindTransform(farPath)

    if XTool.UObjIsNil(self._CommonCameraNear) or XTool.UObjIsNil(self._CommonCameraFar) then
        cb()
        return nil
    end

    self._CommonCameraNear.gameObject:SetActiveEx(true)
    self._CommonCameraFar.gameObject:SetActiveEx(true)
    XLuaUiManager.SetMask(true)

    local duration = self._Control:GetIntClientConfigValue("CommonCameraDuration", index) or 0
    local timerId = XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.SetMask(false)
        cb()
    end, duration)

    return timerId
end

---停止共通线相机动画
function XTheatre6Scene:StopCommonCamAnim()
    if not XTool.UObjIsNil(self._CommonCameraNear) then
        self._CommonCameraNear.gameObject:SetActiveEx(false)
    end
    if not XTool.UObjIsNil(self._CommonCameraFar) then
        self._CommonCameraFar.gameObject:SetActiveEx(false)
    end
    self._CommonCameraNear = nil
    self._CommonCameraFar = nil
end

----------public end----------

----------private start----------

function XTheatre6Scene:OnEnter()
    self._ModelTransform = self:FindTransform("UiTheatre6CamPVPChooseCharacter")
    self:_InitMainCamera()
    self:SetMainCamera(true)
end

function XTheatre6Scene:OnExit()
end

function XTheatre6Scene:OnDestroy()
    self._RoleModelPanels = {}
    self._FashionConfigDict = {}
    self._LoadedDlcModelIdDict = {}
    self._LoadedAnimControllerDict = {}
    self._HuanRenFxDict = {}
    self._RoleConfigs = nil
    self._RoleIndexDict = nil
end

function XTheatre6Scene:_InitMainCamera()
    local farRoot = self._ModelTransform:FindTransform("UiFarRoot")
    local nearRoot = self._ModelTransform:FindTransform("UiNearRoot")
    self.CamFarMain = farRoot:GetComponent("CinemachineVirtualCamera")
    self.CamNearMain = nearRoot:GetComponent("CinemachineVirtualCamera")
end

---加载指定位置的角色模型，设置状态机并播放默认待机动作
---@param index number 模型位置索引
---@param fashionId number Theatre6CharacterFashion表Id
---@param isChangeFashion boolean 是否切换涂装
function XTheatre6Scene:_LoadRoleModel(index, fashionId, isChangeFashion, playAnimName)
    local fashionConfig = self._Control:GetFashionConfig(fashionId)
    if not fashionConfig then
        return
    end

    local dlcModelId = fashionConfig.DlcModelId
    if string.IsNilOrEmpty(dlcModelId) then
        return
    end

    self._FashionConfigDict[index] = fashionConfig
    local roleModelPanel = self:_GetOrCreateRoleModelPanel(index)

    local lastDlcModelId = self._LoadedDlcModelIdDict[index]
    local isSameDlcModelId = lastDlcModelId == dlcModelId

    if isChangeFashion or not isSameDlcModelId then
        -- DlcModelId不一样，重新加载模型（异步，回调中执行_OnModelReady）
        -- 仅在选人界面切换涂装的单角色刷新时播放换人特效
        self:_ReloadFullModel(index, roleModelPanel, dlcModelId, fashionConfig, playAnimName)
        return
    end

    local isSameAnimController = self._LoadedAnimControllerDict[index] == fashionConfig.AnimatorController
    if not isSameAnimController then
        -- DlcModelId一样但AnimatorController不一样，只更新状态机
        self:_UpdateAnimatorOnly(index, roleModelPanel, fashionConfig, playAnimName)
        return
    end

    -- DlcModelId和AnimatorController都一样，仍需执行_OnModelReady
    local model = roleModelPanel:GetCurRoleModel()
    if model then
        self:_OnModelReady(model, index, fashionConfig, playAnimName)
    end
end

---获取或创建指定位置的RoleModelPanel
---@param index number 模型位置索引
---@return XUiPanelRoleModel
function XTheatre6Scene:_GetOrCreateRoleModelPanel(index)
    local roleModelPanel = self._RoleModelPanels[index]
    if not roleModelPanel then
        local node = self._ModelTransform:FindTransform(string.format("PanelRoleModel%s", index))
        roleModelPanel = XUiPanelRoleModel.New(node, self._Name, true, true, false)
        self._RoleModelPanels[index] = roleModelPanel
    end
    return roleModelPanel
end

---DlcModelId一样但AnimatorController不一样时，只更新状态机
---@param index number
---@param roleModelPanel XUiPanelRoleModel
---@param fashionConfig XTableTheatre6CharacterFashion
function XTheatre6Scene:_UpdateAnimatorOnly(index, roleModelPanel, fashionConfig, animName)
    self._LoadedAnimControllerDict[index] = fashionConfig.AnimatorController
    local model = roleModelPanel:GetCurRoleModel()
    if model then
        self:_OnModelReady(model, index, fashionConfig, animName)
    end
end

---DlcModelId不一样时，重新加载模型
---@param index number
---@param roleModelPanel XUiPanelRoleModel
---@param dlcModelId string
---@param fashionConfig XTableTheatre6CharacterFashion
function XTheatre6Scene:_ReloadFullModel(index, roleModelPanel, dlcModelId, fashionConfig, animName)
    self._LoadedDlcModelIdDict[index] = dlcModelId
    self._LoadedAnimControllerDict[index] = fashionConfig.AnimatorController
    roleModelPanel:UpdateRoleModel(dlcModelId, nil, self._Name, function(model)
        self:_OnModelReady(model, index, fashionConfig, animName)
    end)
end

---模型就绪后的共同处理：设置状态机并在需要时补播ChooseAnim
---@param model UnityEngine.GameObject
---@param index number
---@param fashionConfig XTableTheatre6CharacterFashion
function XTheatre6Scene:_OnModelReady(model, index, fashionConfig, animName)
    if self.CurSelectIndex == index then
        self:_PlayAnimOnIndex(index, animName)
    else
        self:_ApplyAnimatorAndIdle(model, fashionConfig)
    end
end

---为已加载的模型设置AnimatorController并播放NormalIdleAnim
---@param model UnityEngine.GameObject
---@param fashionConfig XTableTheatre6CharacterFashion
function XTheatre6Scene:_ApplyAnimatorAndIdle(model, fashionConfig)
    if XTool.UObjIsNil(model) then
        return
    end

    local animatorController = fashionConfig.AnimatorController
    if string.IsNilOrEmpty(animatorController) then
        return
    end

    ---@type UnityEngine.Animator
    local animator = model:GetComponent("Animator")
    if XTool.UObjIsNil(animator) then
        return
    end

    animator.runtimeAnimatorController = CS.LoadHelper.LoadUiController(animatorController, animator.gameObject)

    local normalIdleAnim = fashionConfig.NormalIdleAnim
    if not string.IsNilOrEmpty(normalIdleAnim) then
        animator:CrossFade(normalIdleAnim, 0.2, 0)
    end
end

---在指定位置的模型上播放动画（模型未加载完成时静默跳过）
---@param index number
---@param animName string
function XTheatre6Scene:_PlayAnimOnIndex(index, animName)
    if string.IsNilOrEmpty(animName) then
        return
    end
    local roleModelPanel = self._RoleModelPanels[index]
    if not roleModelPanel then
        return
    end
    roleModelPanel:PlayAnima(animName, true)
end

---在指定位置播放换人特效（同槽位切换角色模型时调用）
---@param index number
function XTheatre6Scene:PlayHuanRenFx(index)
    local roleModelPanel = self._RoleModelPanels[index]
    if not roleModelPanel or XTool.UObjIsNil(roleModelPanel.Transform) then
        return
    end

    local fxObj = self._HuanRenFxDict[index]
    if XTool.UObjIsNil(fxObj) then
        fxObj = roleModelPanel.Transform:LoadPrefab(self._FxUiHuanRen)
        if XTool.UObjIsNil(fxObj) then
            return
        end
        fxObj.gameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer("UiNear"))
        self._HuanRenFxDict[index] = fxObj
    end

    fxObj:SetActiveEx(false)
    fxObj:SetActiveEx(true)
end

---销毁所有缓存的换人特效（离开选人界面时调用，避免特效残留导致下次进入误触发）
function XTheatre6Scene:DestroyHuanRenFx()
    for index, fxObj in pairs(self._HuanRenFxDict) do
        if not XTool.UObjIsNil(fxObj) then
            CS.UnityEngine.Object.Destroy(fxObj.gameObject)
        end
        self._HuanRenFxDict[index] = nil
    end
end

----------private end----------

return XTheatre6Scene
