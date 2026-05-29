---@class XDrawPerformanceBinder
local XDrawPerformanceBinder = XClass(nil, "XDrawPerformanceBinder")

local TRACK_CHARACTER_ANIM = "CharacterAnim"
local TRACK_WEAPON_ANIM_PREFIX = "WeaponAnim"
local TRACK_CAMERA_CONTROL = "CameraControl"
local TRACK_SOUND_EVENT = "SoundEvent"
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
local XEffectSettingType = typeof(CS.XEffectSetting)
local XTailType = typeof(CS.XTail)
local ParticleSystemType = typeof(CS.UnityEngine.ParticleSystem)
local Vector3 = CS.UnityEngine.Vector3

-- 用于在 Timeline Hold 末尾从 XUiEffectMixer 实例中读取 private EffectGroup 字段，
local XUiEffectMixerType = typeof(CS.XUiEffectMixer)
local XUiEffectTrackType = typeof(CS.XUiEffectTrack)
local PlayableStructType = typeof(CS.UnityEngine.Playables.Playable)
local SystemObjectType = typeof(CS.System.Object)
local SystemTypeType = typeof(CS.System.Type)
local BindingFlagsDefault = CS.System.Reflection.BindingFlags.Default
-- BindingFlags.NonPublic(32) | BindingFlags.Instance(4) = 36
local NonPublicInstanceFlags = 36

---@param rootUi XUiNewDrawMainV4P5Performance
function XDrawPerformanceBinder:Ctor(rootUi)
    self._rootUi = rootUi
    self._director = nil
    self._trackMap = nil
    self._effectGos = {}
    self._effectTracks = {}
    self._reflection = nil
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

-- 绑定武器列表 → 各骨骼挂载 + 各 WeaponAnim_{i} AnimationTrack（i 从 1 起）
function XDrawPerformanceBinder:_BindWeapon(config, charGo, npcRoot)
    if XTool.UObjIsNil(charGo) then
        return
    end
    local prefabPaths = config.WeaponPrefabPaths
    if not prefabPaths then
        return
    end
    local boneNames = config.WeaponMountBoneNames
    for index, prefabPath in pairs(prefabPaths) do
        if not string.IsNilOrEmpty(prefabPath) then
            local boneName = boneNames and boneNames[index] or nil
            local mountBone = npcRoot
            if not string.IsNilOrEmpty(boneName) then
                local bone = charGo.transform:FindTransformEx(boneName)
                if bone then
                    mountBone = bone
                else
                    XLog.Error(self._logPrefix .. "武器[" .. index .. "]挂点骨骼 " .. boneName .. " 在角色模型中找不到，fallback 到 NpcRoot")
                end
            end
            local weaponGo = mountBone:LoadPrefabEx(prefabPath)
            if not XTool.UObjIsNil(weaponGo) then
                weaponGo.transform.localScale = Vector3.one
                local sync = weaponGo:GetComponent(BoneTransformSyncType)
                if sync then
                    sync:SetTarget(charGo.transform)
                end
                local trackName = TRACK_WEAPON_ANIM_PREFIX .. "_" .. index
                if self._trackMap[trackName] then
                    local animator = weaponGo:GetComponent(AnimatorType)
                    if XTool.UObjIsNil(animator) then
                        animator = weaponGo:AddComponent(AnimatorType)
                    end
                    self:_BindAnimation(trackName, animator)
                end
            end
        end
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
                    -- 因为直接拿的战斗的特效使用，需要关闭这个选项才能在UI场景里正确缩放
                    effectScaler.IsFightSceneEffect = false
                end
            end
            -- 特效初始不可见，由 XUiEffectTrack 在 Timeline 播放时控制激活
            fxGo.gameObject:SetActiveEx(false)
            self:_BindEffect(info.trackName, fxGo, renderingProxy)
            self._effectGos[#self._effectGos + 1] = fxGo
        end
    end
end

-- 绑定声音事件轨道 (通过 AnimationTrack 派发 AnimationEvent，GenericBinding 绑定 Timeline GO 上的 Animator)
function XDrawPerformanceBinder:_BindSoundTrack(knownTracks)
    local track = self._trackMap[TRACK_SOUND_EVENT]
    if not track then
        return
    end
    knownTracks[TRACK_SOUND_EVENT] = true
    local timelineGo = self._director.gameObject
    -- AnimationTrack 必须绑定 Animator 才会派发其 AnimationClip 上的 AnimationEvent
    local animator = timelineGo:GetComponent(AnimatorType)
    if XTool.UObjIsNil(animator) then
        animator = timelineGo:AddComponent(AnimatorType)
    end
    self._director:SetGenericBinding(track, animator)
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
    knownTracks[TRACK_CAMERA_CONTROL] = true
    -- 武器动画轨道按 WeaponAnim_{i} 命名（i 从 1 起）
    for trackName, _ in pairs(self._trackMap) do
        if string.StartsWith(trackName, TRACK_WEAPON_ANIM_PREFIX) then
            knownTracks[trackName] = true
        end
    end

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

    -- 4. 绑定声音事件轨道
    self:_BindSoundTrack(knownTracks)

    -- 5. 绑定材质替换轨道（GenericBinding renderingProxy）
    self:_BindMaterialTracks(knownTracks, renderingProxy)

    -- 6. 绑定节点组和延迟事件（ActivationTrack → 角色骨骼）
    self:_BindNodeGroups(knownTracks, characterGo)

    -- 保存 XUiEffectTrack 列表，用于 Hold 模式下暂停特效
    if XUiEffectTrackType then
        for _, track in pairs(self._trackMap) do
            if XUiEffectTrackType:IsInstanceOfType(track) then
                self._effectTracks[#self._effectTracks + 1] = track
            end
        end
    end

    self._trackMap = nil
end

-- 播放 Timeline
function XDrawPerformanceBinder:Play()
    if XTool.UObjIsNil(self._director) then
        XLog.Error(self._logPrefix .. "Play 被调用但 Director 不可用，可能是 Bind 失败")
        return
    end
    self._director.time = 0
    self._director:Stop()
    self._director:Evaluate()
    self._director:Play()
end

-- 获取 Timeline 时长（秒）
---@return number
function XDrawPerformanceBinder:GetDuration()
    if XTool.UObjIsNil(self._director) then
        return 0
    end
    return self._director.duration or 0
end

-- Timeline 在 Hold 模式下播完后，把仍处于显示状态的特效定格
function XDrawPerformanceBinder:PauseActiveEffects()
    -- 暂停渲染特效组
    self:_FreezeMixerEffectGroups()

    -- 暂停特效预制下的 ParticleSystem / XEffectSetting / Animator / XTail
    if not self._effectGos then
        return
    end
    for i = 1, #self._effectGos do
        local fxGo = self._effectGos[i]
        if not XTool.UObjIsNil(fxGo) and fxGo.activeInHierarchy then
            local particles = fxGo:GetComponentsInChildren(ParticleSystemType, false)
            if particles then
                for j = 0, particles.Length - 1 do
                    local ps = particles[j]
                    if not XTool.UObjIsNil(ps) then
                        ps:Pause(true)
                    end
                end
            end

            local settings = fxGo:GetComponentsInChildren(XEffectSettingType, false)
            if settings then
                for j = 0, settings.Length - 1 do
                    local setting = settings[j]
                    if not XTool.UObjIsNil(setting) then
                        setting:SetSpeed(0)
                    end
                end
            end

            local tails = fxGo:GetComponentsInChildren(XTailType, false)
            if tails then
                for j = 0, tails.Length - 1 do
                    local tail = tails[j]
                    if not XTool.UObjIsNil(tail) then
                        tail:SetTimeScale(0)
                    end
                end
            end

            local animators = fxGo:GetComponentsInChildren(AnimatorType, false)
            if animators then
                for j = 0, animators.Length - 1 do
                    local animator = animators[j]
                    if not XTool.UObjIsNil(animator) then
                        animator.speed = 0
                    end
                end
            end
        end
    end
end

-- 停止播放
function XDrawPerformanceBinder:Stop()
    if not XTool.UObjIsNil(self._director) then
        self._director:Stop()
    end
    self._director = nil
    self._effectGos = nil
    self._effectTracks = nil
    self._reflection = nil
end

-- 是否已成功绑定 Director
function XDrawPerformanceBinder:HasDirector()
    return not XTool.UObjIsNil(self._director)
end

--endregion

--region 反射相关

-- 构建反射上下文
function XDrawPerformanceBinder:_GetReflection()
    local cached = self._reflection
    if cached ~= nil then
        return cached or nil
    end

    -- 给定 PlayableBehaviour 子类 T，取 ScriptPlayable<T> 上两个核心方法：
    --   op_Explicit(Playable) — 把通用 Playable 显式转回 ScriptPlayable<T>
    --   GetBehaviour()        — 从 ScriptPlayable<T> 拿到内部的 T 实例
    -- op_Explicit 有 Playable / PlayableOutput 两种重载，必须用参数类型数组消歧。
    local function GetScriptPlayableMethods(behaviourType, scriptPlayableOpen)
        local closed = scriptPlayableOpen:MakeGenericType(behaviourType)
        local castParamTypes = CS.System.Array.CreateInstance(SystemTypeType, 1)
        castParamTypes[0] = PlayableStructType
        return assert(closed:GetMethod("op_Explicit", castParamTypes), "ScriptPlayable.op_Explicit 缺失"), assert(closed:GetMethod("GetBehaviour"), "ScriptPlayable.GetBehaviour 缺失")
    end

    local built = {}
    local ok, err = pcall(function()
        local scriptPlayableOpen = assert(PlayableStructType.Assembly:GetType("UnityEngine.Playables.ScriptPlayable`1"), "找不到 UnityEngine.Playables.ScriptPlayable`1")
        local timelinePlayableType = assert(CS.System.Type.GetType("UnityEngine.Timeline.TimelinePlayable, Unity.Timeline"), "找不到 UnityEngine.Timeline.TimelinePlayable")

        built.timelineOpExplicit, built.timelineGetBehaviour = GetScriptPlayableMethods(timelinePlayableType, scriptPlayableOpen)
        built.mixerOpExplicit, built.mixerGetBehaviour = GetScriptPlayableMethods(XUiEffectMixerType, scriptPlayableOpen)

        -- TimelinePlayable.m_PlayableCache: Dictionary<TrackAsset, Playable>，存储 track→mixer 的映射
        built.playableCacheField = assert(timelinePlayableType:GetField("m_PlayableCache", NonPublicInstanceFlags), "TimelinePlayable.m_PlayableCache 缺失")
        -- XUiEffectMixer.EffectGroup: 渲染特效组（径向模糊/残影/Lut 等容器）
        built.effectGroupField = assert(XUiEffectMixerType:GetField("EffectGroup", NonPublicInstanceFlags), "XUiEffectMixer.EffectGroup 缺失")

        -- 泛型 Dictionary 的 ContainsKey / get_Item：xLua 从反射拿回 cache 时看到的是 object，
        -- 没法直接调实例方法，必须再走 MethodInfo:Invoke。
        local dictType = built.playableCacheField.FieldType
        built.dictContainsKey = assert(dictType:GetMethod("ContainsKey"), "Dictionary.ContainsKey 缺失")
        built.dictGetItem = assert(dictType:GetMethod("get_Item"), "Dictionary.get_Item 缺失")

        -- 复用的 object[1]，每次 MethodInfo:Invoke 时填入实参，避免每次分配新数组
        built.invokeArg1 = CS.System.Array.CreateInstance(SystemObjectType, 1)
    end)

    if not ok then
        XLog.Error(self._logPrefix .. "XUiEffectMixer 反射初始化失败，Hold 末尾将无法冻结渲染特效: " .. tostring(err))
        self._reflection = false
        return nil
    end

    self._reflection = built
    return built
end

-- 反射读取每条 XUiEffectMixer 的 private EffectGroup，调用 XSpecialEffectManager.ChangeSpeed(group, 0) 暂停渲染特效
function XDrawPerformanceBinder:_FreezeMixerEffectGroups()
    if XTool.UObjIsNil(self._director) then
        return
    end
    if XTool.IsTableEmpty(self._effectTracks) then
        return
    end
    local graph = self._director.playableGraph
    if not graph:IsValid() then
        return
    end
    local r = self:_GetReflection()
    if not r then
        return
    end

    local trackCount, hitCount, groupCount = #self._effectTracks, 0, 0
    local invokeArg1 = r.invokeArg1
    local ok, err = pcall(function()
        -- 第 1 步：根 Playable → TimelinePlayable
        local rootPlayable = graph:GetRootPlayable(0)
        invokeArg1[0] = rootPlayable
        local timelineSp = r.timelineOpExplicit:Invoke(nil, BindingFlagsDefault, nil, invokeArg1, nil)
        local timelineBehaviour = r.timelineGetBehaviour:Invoke(timelineSp, BindingFlagsDefault, nil, nil, nil)
        if timelineBehaviour == nil then
            return
        end

        -- 第 2 步：取 m_PlayableCache (Dictionary<TrackAsset, Playable>)
        local cache = r.playableCacheField:GetValue(timelineBehaviour)
        if cache == nil then
            return
        end

        -- 第 3 步：逐 track 查 cache，命中 → 拿到 mixer → 取 EffectGroup → ChangeSpeed(group, 0)
        for i = 1, trackCount do
            local track = self._effectTracks[i]
            if track then
                invokeArg1[0] = track
                local contains = r.dictContainsKey:Invoke(cache, BindingFlagsDefault, nil, invokeArg1, nil)
                if contains then
                    hitCount = hitCount + 1
                    local mixerPlayable = r.dictGetItem:Invoke(cache, BindingFlagsDefault, nil, invokeArg1, nil)
                    invokeArg1[0] = mixerPlayable
                    local mixerSp = r.mixerOpExplicit:Invoke(nil, BindingFlagsDefault, nil, invokeArg1, nil)
                    local mixer = r.mixerGetBehaviour:Invoke(mixerSp, BindingFlagsDefault, nil, nil, nil)
                    if mixer ~= nil then
                        local group = r.effectGroupField:GetValue(mixer)
                        if group ~= nil then
                            groupCount = groupCount + 1
                            CS.XSpecialEffectManager.ChangeSpeed(group, 0)
                        end
                    end
                end
            end
        end
    end)
    invokeArg1[0] = nil   -- 释放对装箱 Playable / track 的引用，避免长持有
    XLog.Debug(string.format("%s_FreezeMixerEffectGroups tracks=%d cacheHit=%d groupHit=%d", self._logPrefix, trackCount, hitCount, groupCount))
    if not ok then
        XLog.Error(self._logPrefix .. "暂停 EffectGroup 失败: " .. tostring(err))
    end
end

--endregion

return XDrawPerformanceBinder
