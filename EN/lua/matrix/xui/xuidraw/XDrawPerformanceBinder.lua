---@class XDrawPerformanceBinder
local XDrawPerformanceBinder = XClass(nil, "XDrawPerformanceBinder")

local TRACK_CHARACTER_ANIM = "CharacterAnim"
local TRACK_WEAPON_ANIM = "WeaponAnim"
local TRACK_CAMERA_CONTROL = "CameraControl"
local TRACK_NPC_MATERIAL_PREFIX = "UiNpcMaterial"

local EFFECT_ROOT_SENTINEL = "EffectRoot"
local MAIN_CAMERA_SENTINEL = "MainCamera"

local PlayableDirectorType = typeof(CS.UnityEngine.Playables.PlayableDirector)
local AnimatorType = typeof(CS.UnityEngine.Animator)
local CinemachineBrainType = typeof(CS.Cinemachine.CinemachineBrain)
local BoneTransformSyncType = typeof(CS.XBoneTransformSync)
local CameraType = typeof(CS.UnityEngine.Camera)
local XTrackConfigType = typeof(CS.XTrackConfig)
local XEffectScalerType = typeof(CS.XEffectScaler)
local Vector3 = CS.UnityEngine.Vector3

---@param rootUi XUiNewDrawMainV4P5Performance
function XDrawPerformanceBinder:Ctor(rootUi)
    self._rootUi = rootUi
    self._director = nil
    self._trackMap = nil
    local characterId = rootUi and rootUi.CharacterId or "?"
    self._logPrefix = string.format("[PerfBind][CharacterId=%s] ", tostring(characterId))
end

--region 绑定方法

-- 将 Animator 绑定到 AnimationTrack
function XDrawPerformanceBinder:_BindAnimation(trackName, animator)
    local track = self._trackMap[trackName]
    if track then
        self._director:SetGenericBinding(track, animator)
    end
end

-- 通过 SetReferenceValue 绑定 ExposedReference（CameraControl ControlTrack）
function XDrawPerformanceBinder:_BindReference(trackName, target)
    local track = self._trackMap[trackName]
    if not track then
        return
    end
    CS.XUnityEx.SetReferenceValue(self._director, trackName, target)
end

-- 通过 SetReferenceValue 绑定 ExposedReference（XUiEffectClip.effectObject）
-- 同时通过 SetGenericBinding 绑定 XNPCRendingUIProxy
function XDrawPerformanceBinder:_BindEffect(trackName, target, renderingProxy)
    local track = self._trackMap[trackName]
    if not track then
        return
    end
    CS.XUnityEx.SetReferenceValue(self._director, trackName, target)
    if not XTool.UObjIsNil(renderingProxy) then
        self._director:SetGenericBinding(track, renderingProxy)
    end
end

--endregion

--region 工具函数

-- 构建 trackName → TrackAsset 映射表
function XDrawPerformanceBinder:_BuildTrackMap(timelineAsset)
    local map = {}
    local tracks = timelineAsset:GetOutputTracks()
    for i = 0, tracks.Length - 1 do
        local track = tracks[i]
        local name = track.name
        if not string.IsNilOrEmpty(name) then
            if not map[name] then
                map[name] = track
            else
                XLog.Error(self._logPrefix .. "重复的轨道名: " .. name .. "，仅首条生效")
            end
        end
    end
    return map
end

-- 根据骨骼名确定特效的父节点：nil→EffectRoot，"MainCamera"→主相机，其他→角色骨骼
function XDrawPerformanceBinder:_ResolveEffectParent(boneName, charGo, mainCamGo, effectRoot, trackName)
    if not boneName then
        return effectRoot
    end
    if boneName == MAIN_CAMERA_SENTINEL then
        if not XTool.UObjIsNil(mainCamGo) then
            return mainCamGo.transform
        end
        XLog.Error(self._logPrefix .. "特效轨道 " .. trackName .. " 挂点为 MainCamera 但主相机不存在，fallback 到 EffectRoot")
        return effectRoot
    end
    if not XTool.UObjIsNil(charGo) then
        local bone = charGo.transform:FindTransformEx(boneName)
        if bone then
            return bone
        end
        XLog.Error(self._logPrefix .. "特效轨道 " .. trackName .. " 挂点骨骼 " .. boneName .. " 在角色模型中找不到，fallback 到 EffectRoot")
    end
    return effectRoot
end

-- 预计算特效绑定信息和已知轨道名集合
function XDrawPerformanceBinder:_BuildEffectBindInfos(config)
    local infos = {}
    local knownSet = {}
    local effectPaths = config.EffectPrefabPaths
    if not effectPaths then
        return infos, knownSet
    end
    local effectBones = config.EffectBoneNames
    if effectBones and #effectPaths ~= #effectBones then
        XLog.Error(self._logPrefix .. "EffectPrefabPaths 长度 (" .. #effectPaths .. ") 与 EffectBoneNames 长度 (" .. #effectBones .. ") 不一致，" .. "可能导致骨骼错位绑定")
    end

    local function addInfo(trackName, path, bone)
        if knownSet[trackName] then
            XLog.Error(self._logPrefix .. "存在重复的特效轨道名: " .. trackName .. "，可能导致绑定冲突")
        end
        knownSet[trackName] = true
        infos[#infos + 1] = { trackName = trackName, path = path, bone = bone }
    end

    for i, fxPath in pairs(effectPaths) do
        if not string.IsNilOrEmpty(fxPath) then
            local boneName = effectBones and effectBones[i] or nil
            if string.IsNilOrEmpty(boneName) then
                boneName = EFFECT_ROOT_SENTINEL
            end
            local fxName = XTool.GetFileNameWithoutExtension(fxPath)
            if boneName == EFFECT_ROOT_SENTINEL then
                -- 无挂点：轨道名 = 特效名
                addInfo(fxName, fxPath, nil)
            elseif not string.find(boneName, "|", 1, true) then
                -- 单骨骼：轨道名 = 特效名_骨骼名
                addInfo(fxName .. "_" .. boneName, fxPath, boneName)
            else
                -- 多骨骼（"|" 分隔）：每个骨骼独立一条轨道
                local bones = string.Split(boneName, "|")
                for _, bone in ipairs(bones) do
                    addInfo(fxName .. "_" .. bone, fxPath, bone)
                end
            end
        end
    end
    return infos, knownSet
end

--endregion

--region 各元素绑定

-- 绑定角色 → CharacterAnim AnimationTrack
function XDrawPerformanceBinder:_BindCharacter(config, npcRoot)
    if string.IsNilOrEmpty(config.CharacterPrefabPath) then
        return nil
    end
    local charGo = npcRoot:LoadPrefabEx(config.CharacterPrefabPath)
    if XTool.UObjIsNil(charGo) then
        return nil
    end
    local animator = charGo:GetComponent(AnimatorType)
    if XTool.UObjIsNil(animator) then
        animator = charGo:AddComponent(AnimatorType)
    end
    self:_BindAnimation(TRACK_CHARACTER_ANIM, animator)
    return charGo
end

-- 绑定武器 → 骨骼挂载 + WeaponAnim AnimationTrack
function XDrawPerformanceBinder:_BindWeapon(config, charGo, npcRoot)
    if config.HasWeapon ~= 1 or string.IsNilOrEmpty(config.WeaponPrefabPath) or XTool.UObjIsNil(charGo) then
        return
    end
    local mountBone = npcRoot
    if not string.IsNilOrEmpty(config.WeaponMountBoneName) then
        local bone = charGo.transform:FindTransformEx(config.WeaponMountBoneName)
        if bone then
            mountBone = bone
        else
            XLog.Error(self._logPrefix .. "武器挂点骨骼 " .. config.WeaponMountBoneName .. " 在角色模型中找不到，fallback 到 NpcRoot")
        end
    end
    local weaponGo = mountBone:LoadPrefabEx(config.WeaponPrefabPath)
    if XTool.UObjIsNil(weaponGo) then
        return
    end
    weaponGo.transform.localScale = Vector3.one
    local sync = weaponGo:GetComponent(BoneTransformSyncType)
    if sync then
        sync:SetTarget(charGo.transform)
    end
    if self._trackMap[TRACK_WEAPON_ANIM] then
        local animator = weaponGo:GetComponent(AnimatorType)
        if XTool.UObjIsNil(animator) then
            animator = weaponGo:AddComponent(AnimatorType)
        end
        self:_BindAnimation(TRACK_WEAPON_ANIM, animator)
    end
end

-- 加载主相机并添加 CinemachineBrain
function XDrawPerformanceBinder:_BindMainCamera(config, cameraRoot)
    if string.IsNilOrEmpty(config.MainCameraPrefabPath) then
        return nil
    end
    local camGo = cameraRoot:LoadPrefabEx(config.MainCameraPrefabPath)
    if XTool.UObjIsNil(camGo) then
        return nil
    end
    if XTool.UObjIsNil(camGo:GetComponent(CinemachineBrainType)) then
        camGo:AddComponent(CinemachineBrainType)
    end
    local camera = camGo:GetComponent(CameraType)
    if not XTool.UObjIsNil(camera) then
        CS.XGraphicManager.BindCamera(camera)
    end
    return camGo
end

-- 绑定镜头轨道 → CameraControl ControlTrack（通过 ExposedReference）
function XDrawPerformanceBinder:_BindCameraTrack(config, cameraRoot)
    if string.IsNilOrEmpty(config.CameraPrefabPath) then
        return
    end
    local camGo = cameraRoot:LoadPrefabEx(config.CameraPrefabPath)
    if XTool.UObjIsNil(camGo) then
        return
    end
    local trackConfig = camGo:GetComponent(XTrackConfigType)
    if XTool.UObjIsNil(trackConfig) then
        trackConfig = camGo:AddComponent(XTrackConfigType)
        trackConfig.LocationType = CS.XTrackConfig.XTrackLocationType.World
    end
    self:_BindReference(TRACK_CAMERA_CONTROL, camGo)
end

-- 绑定特效 → 各 XUiEffectTrack（ExposedReference 绑定特效 GO + GenericBinding 绑定 renderingProxy）
function XDrawPerformanceBinder:_BindEffects(effectInfos, charGo, mainCamGo, effectRoot, renderingProxy)
    -- 获取主相机 Camera 组件，用于 XEffectScaler
    local mainCamera
    if not XTool.UObjIsNil(mainCamGo) then
        mainCamera = mainCamGo:GetComponent(CameraType)
    end
    for i = 1, #effectInfos do
        local info = effectInfos[i]
        local parent = self:_ResolveEffectParent(info.bone, charGo, mainCamGo, effectRoot, info.trackName)
        local fxGo = parent:LoadPrefabEx(info.path)
        if not XTool.UObjIsNil(fxGo) then
            -- 配置 XEffectScaler 使用自定义相机
            if not XTool.UObjIsNil(mainCamera) then
                local effectScaler = fxGo:GetComponentInChildren(XEffectScalerType, true)
                if not XTool.UObjIsNil(effectScaler) then
                    effectScaler.CameraSearchRule = CS.XEffectScaler.XCameraSearchRule.CustomCamera
                    effectScaler.CustomCamera = mainCamera
                end
            end
            -- 特效初始不可见，由 XUiEffectTrack 在 Timeline 播放时控制激活
            fxGo.gameObject:SetActiveEx(false)
            self:_BindEffect(info.trackName, fxGo, renderingProxy)
        end
    end
end

-- 绑定材质替换轨道（UiNpcMaterial_{MatId}）→ GenericBinding 绑定 renderingProxy
function XDrawPerformanceBinder:_BindMaterialTracks(knownTracks, renderingProxy)
    local hasProxy = not XTool.UObjIsNil(renderingProxy)
    for trackName, track in pairs(self._trackMap) do
        if string.StartsWith(trackName, TRACK_NPC_MATERIAL_PREFIX) then
            knownTracks[trackName] = true
            if hasProxy then
                self._director:SetGenericBinding(track, renderingProxy)
            end
        end
    end
end

-- 遍历所有未知轨道（节点组 + 延迟事件产生的 ActivationTrack），
-- 按轨道名匹配角色骨骼节点，并通过 SetGenericBinding 绑定 GameObject。
function XDrawPerformanceBinder:_BindNodeGroups(knownTracks, charGo)
    if XTool.UObjIsNil(charGo) then
        return
    end
    for trackName, track in pairs(self._trackMap) do
        if not knownTracks[trackName] then
            local node = charGo.transform:FindTransformEx(trackName)
            if node then
                self._director:SetGenericBinding(track, node.gameObject)
            else
                XLog.Error(self._logPrefix .. "存在未知轨道但无匹配骨骼节点: " .. trackName)
            end
        end
    end
end

--endregion

--region 公开接口

-- 加载资源并绑定到 Timeline 轨道
function XDrawPerformanceBinder:Bind()
    local rootUi = self._rootUi
    local loader = rootUi.Loader
    if not loader then
        XLog.Error(self._logPrefix .. "Loader 为 nil，无法加载 Timeline")
        return
    end
    local config = rootUi.RolePerformanceConfig
    local timelineAsset = loader:Load(config.TimelinePath)
    if not timelineAsset then
        XLog.Error(self._logPrefix .. "Timeline 加载失败: " .. tostring(config.TimelinePath))
        return
    end

    local director = rootUi.PerformancePlayable:GetComponent(PlayableDirectorType)
    if XTool.UObjIsNil(director) then
        XLog.Error(self._logPrefix .. "PerformancePlayable 缺少 PlayableDirector 组件")
        return
    end
    director.playableAsset = timelineAsset

    self._director = director
    self._trackMap = self:_BuildTrackMap(timelineAsset)

    local effectInfos, knownTracks = self:_BuildEffectBindInfos(config)
    knownTracks[TRACK_CHARACTER_ANIM] = true
    knownTracks[TRACK_WEAPON_ANIM] = true
    knownTracks[TRACK_CAMERA_CONTROL] = true

    -- 1. 绑定角色和武器
    local characterGo = self:_BindCharacter(config, rootUi.NpcRoot)
    self:_BindWeapon(config, characterGo, rootUi.NpcRoot)

    -- 获取 renderingProxy（运行时 XUiEffectTrack / XUiNpcMaterialTrack 需要）
    ---@type XNPCRendingUIProxy
    local renderingProxy
    if not XTool.UObjIsNil(characterGo) then
        renderingProxy = CS.XNPCRendingUIProxy.GetNPCRendingUIProxy(characterGo)
    end

    -- 2. 绑定相机
    local mainCameraGo = self:_BindMainCamera(config, rootUi.CameraRoot)
    self:_BindCameraTrack(config, rootUi.CameraRoot)

    -- 3. 绑定特效（ExposedReference + GenericBinding renderingProxy）
    self:_BindEffects(effectInfos, characterGo, mainCameraGo, rootUi.EffectRoot, renderingProxy)

    -- 4. 绑定材质替换轨道（GenericBinding renderingProxy）
    self:_BindMaterialTracks(knownTracks, renderingProxy)

    -- 5. 绑定节点组和延迟事件（ActivationTrack → 角色骨骼）
    self:_BindNodeGroups(knownTracks, characterGo)

    self._director.time = 0
    self._director:Evaluate()

    self._trackMap = nil
end

-- 播放 Timeline，并在播放结束后调用回调
---@param callback function|nil
---@return number|nil scheduleId
function XDrawPerformanceBinder:Play(callback)
    if XTool.UObjIsNil(self._director) then
        XLog.Error(self._logPrefix .. "Play 被调用但 Director 不可用，可能是 Bind 失败，跳过演出直接回调")
        if callback then
            callback()
        end
        return nil
    end
    self._director.time = 0
    self._director:Stop()
    self._director:Evaluate()
    self._director:Play()
    if not callback then
        return nil
    end
    local duration = self._director.duration
    if duration and duration > 0 then
        local delay = math.ceil(duration * XScheduleManager.SECOND)
        return XScheduleManager.ScheduleOnce(callback, delay)
    end
    callback()
    return nil
end

-- 停止播放
function XDrawPerformanceBinder:Stop()
    if not XTool.UObjIsNil(self._director) then
        self._director:Stop()
    end
    self._director = nil
end

-- 是否已成功绑定 Director
function XDrawPerformanceBinder:HasDirector()
    return not XTool.UObjIsNil(self._director)
end

--endregion

return XDrawPerformanceBinder
