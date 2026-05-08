local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiPanelRace3DCamera : XUiNode 主界面场景相机
---@field Parent XUiRaceMain
---@field _Control XRaceControl
local XUiPanelRace3DCamera = XClass(XUiNode, "XUiPanelRace3DCamera")

local NodeCount = 8
local NameToLayer = CS.UnityEngine.LayerMask.NameToLayer
local SceneType = XEnumConst.Race.SceneType
local MainCam = 1
local GuessRoleCam = 2
local GuessOptionCam = 3
local SettlementCam = 4

function XUiPanelRace3DCamera:OnStart(sceneType)
    self._SceneType = sceneType
    ---@type XUiPanelRoleModel[]
    self._RoleModels = {}
    self._StateNameArray = self._Control:GetClientConfigs("RaceMainRoleStateName")
    self._EffectPath = self._Control:GetClientConfig("FxHuangguan")
    self._EffectOffsetY = self._Control:GetIntClientConfig("FxHuangguanOffsetY")
    local randTimeConfig = self._Control:GetClientConfigs("RaceMainRoleRandomTime")
    self._RandMinTime = tonumber(randTimeConfig[1]) or 100
    self._RandMaxTime = tonumber(randTimeConfig[2]) or 1000

    self._Offset = CS.UnityEngine.Vector3(0, self._Control:GetIntClientConfig("HUDOffsetY"), 0)
    self._Pivot = CS.UnityEngine.Vector2(0.5, 0.5)
    self._RoleIds = {}

    self._TimerList = {}
    self._TimerCountList = {}
    self._AnimList = {}
    self._AnimStandStateList = {}
    self._AnimStateNameList = {}

    self.UiChangeCamFarMatch = self.Transform:FindTransform("UiChangeCamFarMatch")
    self.UiChangeCamFarOption = self.Transform:FindTransform("UiChangeCamFarOption")
end

function XUiPanelRace3DCamera:PlayRoleEffect()
    self.Effect01.gameObject:SetActiveEx(false)
    self.Effect01.gameObject:SetActiveEx(true)
end

function XUiPanelRace3DCamera:PlayOptionEffect()
    self.Effect02.gameObject:SetActiveEx(false)
    self.Effect02.gameObject:SetActiveEx(true)
end

function XUiPanelRace3DCamera:PlaySettleEffect()
    self.Effect03.gameObject:SetActiveEx(false)
    self.Effect03.gameObject:SetActiveEx(true)
end

---注册角色点击事件
function XUiPanelRace3DCamera:RegisterRoleClick()
    for i = 1, NodeCount do
        local input = self[string.format("Input%s", i)]
        if not XTool.UObjIsNil(input) then
            input:AddPointerClickListener(function()
                self:OnClickRole(i)
            end)
        end
    end
end

function XUiPanelRace3DCamera:ShowRoundRole()
    self._RoleIds = self._Control:GetRoleRandomSite()
    if not XTool.IsTableEmpty(self._RoleIds) then
        return
    end
    self._ChampionId = nil
    if self._Control:IsAllMatchFinish() then
        local roundId = self._Control:GetFinalRoundId()
        local data = self._Control:GetEliminatorData(roundId)
        local upIds = data and data:GetUpRoleIds()
        if not XTool.IsTableEmpty(upIds) then
            self._ChampionId = upIds[1]
        end
    end
    self:RemoveTimer()
    self:RandomRoleSite()
    self:InitRole()
    self:ShowCamera(MainCam)
end

function XUiPanelRace3DCamera:RandomRoleSite()
    local roundId
    local championRoleId --总冠军角色有特殊显示
    if self._Control:IsAllMatchFinish() then
        roundId = self._Control:GetFinalRoundId()
        local data = self._Control:GetEliminatorData(roundId)
        championRoleId = data:GetShowRoleId(1)
    else
        roundId = self._Control:GetCurRound()
    end

    self._RoleIds = XTool.Clone(self._Control:GetRoleIdsByRoundId(roundId))
    XTool.Shuffle(self._RoleIds) --随机角色位置
    self._Control:SetRoleRandomSite(self._RoleIds)
end

function XUiPanelRace3DCamera:InitRole()
    for i = 1, NodeCount do
        local roleId = self._RoleIds[i]
        local node = self[string.format("Role%s", i)]
        if XTool.UObjIsNil(node) then
            XLog.Error(string.format("节点%s不存在", i))
            goto continue
        end
        
        local effect = self[string.format("EffectRole%s", i)]
        if not XTool.UObjIsNil(effect) then
            effect.gameObject:SetActiveEx(roleId)
        end

        if roleId then
            self:LoadRole(node, roleId, true)
        else
            node.gameObject:SetActiveEx(false)
        end
        :: continue ::
    end
end

function XUiPanelRace3DCamera:LoadRole(node, roleId, isHideSelfCollider)
    local characterCfg = self._Control:GetRaceCharacterById(roleId)
    local model = node:LoadPrefab(characterCfg.CharacterModel)
    model:SetLayerRecursively(NameToLayer("UiNear"))
    CS.XShadowHelper.AddShadow(model.gameObject, true)
    ---@type UnityEngine.Animator
    local anim = model:GetComponent("Animator")
    anim.applyRootMotion = false
    if self._SceneType == SceneType.Predict then
        anim:Play("Greet01", 0, 0)
        self:RemoveAnimTimer()
        self._AnimTimer = XScheduleManager.ScheduleForever(function()
            if self:UpdatePredictRoleActor(anim) then
                self:RemoveAnimTimer()
            end
        end, 10, 0)
        self.Parent:_AddTimerId(self._AnimTimer)
    else
        if not XTool.UObjIsNil(anim) then
            self:RemoveRoleTimer(roleId)
            self:AddRoleTimer(roleId)
            self._AnimList[roleId] = anim
        end
        if self._SceneType == SceneType.Main and roleId == self._ChampionId then
            self:LoadChampionEffect(model)
        end
    end
    if isHideSelfCollider then
        --不隐藏会影响Input的点击
        local bip001 = model:FindTransform("Bip001")
        if not XTool.UObjIsNil(bip001) then
            local collider = bip001:GetComponent("CapsuleCollider")
            if not XTool.UObjIsNil(collider) then
                collider.enabled = false
            end
        end
    end
end

--皇冠特效
function XUiPanelRace3DCamera:LoadChampionEffect(model)
    local effectRoot = CS.UnityEngine.GameObject("ChamptionEffect")
    effectRoot.transform:SetParent(model.transform, false)
    effectRoot:SetLayerRecursively(NameToLayer("UiNear"))
    local effect = effectRoot:LoadPrefab(self._EffectPath)
    effect:SetLayerRecursively(NameToLayer("UiNear"))
    effect.transform.localPosition = Vector3(0, self._EffectOffsetY, 0)
end

function XUiPanelRace3DCamera:LoadCar(node, roleId)
    local characterCfg = self._Control:GetRaceCharacterById(roleId)
    local carGo = node:LoadPrefab(characterCfg.CarModel)
    carGo:SetLayerRecursively(NameToLayer("UiNear"))
    CS.XShadowHelper.AddShadow(carGo.gameObject, true)
    ---@type UnityEngine.Animator
    local carAnim = carGo:GetComponent("Animator")
    carAnim.applyRootMotion = false
    local charRoot = carGo.transform:Find("Root")
    local charGo = charRoot:LoadPrefab(characterCfg.CharacterModel)
    charGo:SetLayerRecursively(NameToLayer("UiNear"))
    CS.XShadowHelper.AddShadow(charGo.gameObject, true)
    charGo.transform.localEulerAngles = Vector3(90, 0, 0)
    ---@type UnityEngine.Animator
    local charAnim = charGo:GetComponent("Animator")
    local charControllerAsset = CS.LoadHelper.LoadUiController(characterCfg.AnimPath, charAnim.gameObject)
    charAnim.runtimeAnimatorController = charControllerAsset
    charAnim.applyRootMotion = false
end

function XUiPanelRace3DCamera:LoadOption()
    local path = self._Control:GetClientConfig("GuessOptionModel")
    local model = self.Option:LoadPrefab(path)
    model:SetLayerRecursively(NameToLayer("UiNear"))
    ---@type UnityEngine.Animator
    local anim = model:GetComponent("Animator")
    anim:Play("RaceCarIdle", 0, 0)
end

function XUiPanelRace3DCamera:LookAt(roleId)
    if not roleId then
        return
    end
    
    self.Option.gameObject:SetActiveEx(false)
    self.RoleMatch.gameObject:SetActiveEx(self._SceneType ~= SceneType.Settlement)
    self.PanelSettleRoleModel.gameObject:SetActiveEx(self._SceneType == SceneType.Settlement)
    
    if self._SceneType == SceneType.Predict then
        self:LoadRole(self.RoleMatch, roleId) --直接替换角色
        self:ShowCamera(GuessRoleCam)
    elseif self._SceneType == SceneType.Settlement then
        self:LoadCar(self.PanelSettleRoleModel, roleId)
        self:ShowCamera(SettlementCam)
    end
end

function XUiPanelRace3DCamera:ShowOption()
    self.Option.gameObject:SetActiveEx(true)
    self.RoleMatch.gameObject:SetActiveEx(false)
    for i = 1, NodeCount do
        local node = self[string.format("Role%s", i)]
        if not XTool.UObjIsNil(node) then
            node.gameObject:SetActiveEx(false)
        end
    end
    self:ShowCamera(GuessOptionCam)
end

function XUiPanelRace3DCamera:ShowCamera(cameraType, camIndex)
    self.UiMainCamFar.gameObject:SetActiveEx(cameraType == MainCam)
    self.UiMainCamNear.gameObject:SetActiveEx(cameraType == MainCam)
    self.UiChangeCamNearMatch.gameObject:SetActiveEx(cameraType == GuessRoleCam)
    self.UiChangeCamFarMatch.gameObject:SetActiveEx(cameraType == GuessRoleCam)
    self.UiChangeCamNearOption.gameObject:SetActiveEx(cameraType == GuessOptionCam)
    self.UiChangeCamFarOption.gameObject:SetActiveEx(cameraType == GuessOptionCam)
    self.UiChangeCamFarFightSettlement.gameObject:SetActiveEx(cameraType == SettlementCam)
    self.UiChangeCamNearFightSettlement.gameObject:SetActiveEx(cameraType == SettlementCam)

    --已废弃
    for i = 1, NodeCount do
        local farCam = self[string.format("UiChangeCamFar%s", i)]
        if not XTool.UObjIsNil(farCam) then
            farCam.gameObject:SetActiveEx(false)
        end

        local nearCam = self[string.format("UiChangeCamNear%s", i)]
        if not XTool.UObjIsNil(nearCam) then
            nearCam.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelRace3DCamera:OnClickRole(index)
    local roleId = self._RoleIds[index]
    if not roleId then
        return
    end
    local info = self._Control:GetCurRoundInfo()
    if info.State ~= XEnumConst.Race.RoundState.Guess then
        return
    end
    local dontGainRoundId = self._Control:GetDontViewedRoundId()
    if dontGainRoundId then
        --有预测奖励没领取
        return
    end
    XLuaUiManager.Open("UiRacePredict", roleId)
end

function XUiPanelRace3DCamera:SetViewPosToTransformLocalPosition(uiTransform, roleId)
    if XTool.UObjIsNil(self.UiNearCamera) then
        return
    end
    if self._SceneType == SceneType.Predict then
        if not XTool.UObjIsNil(self.RoleMatch) then
            CS.XUiHelper.SetViewPosToTransformLocalPosition(self.UiNearCamera, uiTransform, self.RoleMatch, self._Offset, self._Pivot)
        end
        return
    end
    if XTool.IsTableEmpty(self._RoleIds) then
        return
    end
    local site = table.indexof(self._RoleIds, roleId)
    if site == -1 then
        return
    end
    local node = self[string.format("Role%s", site)]
    if XTool.UObjIsNil(node) then
        return
    end
    CS.XUiHelper.SetViewPosToTransformLocalPosition(self.UiNearCamera, uiTransform, node, self._Offset, self._Pivot)
end

function XUiPanelRace3DCamera:UpdatePredictRoleActor(anim)
    if XTool.UObjIsNil(anim) then
        return true
    end

    local info = anim:GetCurrentAnimatorStateInfo(0)
    if (info:IsName("Greet01") and info.normalizedTime >= 1) or not info:IsName("Greet01") then
        --播放下一个动作
        anim:CrossFade("Stand02", 0.2, 0)
        return true
    end
    
    return false
end

function XUiPanelRace3DCamera:RemoveAnimTimer()
    if self._AnimTimer then
        XScheduleManager.UnSchedule(self._AnimTimer)
        self.Parent:_RemoveTimerIdAndDoCallback(self._AnimTimer)
        self._AnimTimer = nil
    end
end

function XUiPanelRace3DCamera:RemoveRoleTimer(roleId)
    if not roleId or not self._TimerList[roleId] then return end
    XScheduleManager.UnSchedule(self._TimerList[roleId])
    self._TimerList[roleId] = nil
end

function XUiPanelRace3DCamera:AddRoleTimerCallback(roleId)
    local updateCnt = 123
    self._TimerList[roleId] = XScheduleManager.ScheduleForever(function()
        local anim = self._AnimList[roleId]
        if not anim.gameObject.activeInHierarchy then
            return
        end
        local cnt = self._TimerCountList[roleId]
        cnt = cnt - updateCnt
        if cnt <= 0 then
            local info = anim:GetCurrentAnimatorStateInfo(0)
            local stateName = self._AnimStateNameList[roleId] or "Stand02"
            if (info:IsName(stateName) and info.normalizedTime >= 1) or not info:IsName(stateName) then
                --播放下一个动作
                if not self._AnimStandStateList[roleId] then
                    self._AnimStandStateList[roleId] = true
                    
                    local maxNameCnt = #self._StateNameArray
                    local randIndex = math.random(1, maxNameCnt)
                    stateName = self._StateNameArray[randIndex]
                    anim:CrossFade(stateName, 0.2, 0)
                    cnt = updateCnt * 4
                else
                    self._AnimStandStateList[roleId] = false
                    stateName = "Stand02"
                    anim:CrossFade(stateName, 0.2, 0)
                    cnt = math.random(self._RandMinTime, self._RandMaxTime)
                end
                self._AnimStateNameList[roleId] = stateName
            end
        end
        self._TimerCountList[roleId] = cnt
    end, updateCnt)
end

function XUiPanelRace3DCamera:AddRoleTimer(roleId)
    if self._TimerList[roleId] then return end

    self._TimerCountList[roleId] = math.random(self._RandMinTime, self._RandMaxTime)
    self:AddRoleTimerCallback(roleId)
end

function XUiPanelRace3DCamera:OnEnable()
    for roleId, timerId in pairs(self._TimerList) do
        self:AddRoleTimerCallback(roleId)
    end
end

function XUiPanelRace3DCamera:OnDisable()
    for roleId, timerId in pairs(self._TimerList) do
        XScheduleManager.UnSchedule(timerId)
    end
end

function XUiPanelRace3DCamera:RemoveTimer()
    self:RemoveAnimTimer()
    for _, timerId in pairs(self._TimerList) do
        XScheduleManager.UnSchedule(timerId)
    end
    self._TimerList = {}
end

function XUiPanelRace3DCamera:OnDestroy()
    self:RemoveTimer()
    self._TimerCountList = nil
    self._AnimList = nil
    self._AnimStateNameList = nil
end

return XUiPanelRace3DCamera
