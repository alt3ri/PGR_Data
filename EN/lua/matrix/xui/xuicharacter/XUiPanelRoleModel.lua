---@class XUiPanelRoleModel
local XUiPanelRoleModel = XClass(nil, "XUiPanelRoleModel")
local AnimeLayer = {
    Body = 0,
    Face = 1
}

local KeepGraphicLayer = {
    Distortion = "Distortion",
}

local DefaultRoleAnimaName = "StandAct0101"
--==============================--
--- RoleModelPool = {["model"] = model, ["weaponList"] = list, ["characterId"] = characterId}
--==============================--
function XUiPanelRoleModel:Ctor(
ui,
refName,
hideWeapon,
showShadow,
loadClip,
setFocus,
fixLight,
playEffectFunc,
clearUiChildren,
useMultiModel)
    self.Ui = ui
    self.RefName = refName or "DefaultName"
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    if clearUiChildren then -- 初始化时是否清空model挂点下所有物体
        XTool.DestroyChildren(ui.gameObject)
    end
    self.NodeEffectMappingPrefabPool = {}
    self.HideWeapon = hideWeapon and true or false
    self.ShowShadow = showShadow
    self.SetFocus = setFocus
    self.FixLight = fixLight
    self.PlayEffectFunc = playEffectFunc
    if loadClip == nil then
        self.InitLoadClip = true
    else
        self.InitLoadClip = loadClip and true
    end
    self.LoadClip = self.InitLoadClip
    self.IsStandAnimaShowWeapon = false
    self.StandAnimaShowWeaponList = {}
    self.StandAnimaShowWeaponAnimatorList = {}
    -- 模型音频状态：只记录RoleModel通过Lua主动托管的声音，不记录Animator事件声音
    self._FashionUiStandConfigCueId = nil -- 配置给涂装UiStand展示音的cueId，来自FashionVoice.tab
    self._PartnerSToCVoiceConfigCueId = nil -- 配置给辅助机待机转战斗音效的cueId，来自PartnerModel.SToCVoice
    self._PartnerSToCVoicePlayedCueIdSet = {} -- 辅助机SToCVoice播放记录，避免同一面板重复播放同一个cueId
    self._PartnerSToCVoiceActiveCueId = nil -- 当前PartnerSToCVoice链路的停止目标cueId
    self._PartnerSToCVoiceFallbackAudioInfo = nil -- 辅助机缺少XAnimationSound时，SToCVoice的历史兼容播放句柄
    self.UiStandCallBack = {}
    self.NowFashionId = nil
    self.PlayUiStandCallBackList = {}
    self.AnimaPlayedCallBackList = {}
    self.IsStandAnimaHideNode = false
    self._MySkinMeshFace = nil
    self._MyXAnimationSound = nil
    if useMultiModel == nil then
        self.UseMultiModel = true
    end
    self.CurCharacterId = nil

    -- 初始化模型缓存池（默认使用普通策略）
    local isHarwareLowMemory = XHardwareManager.GetIsLowMemoryDevice()
    local isInSkyGarden = CS.XBigWorldHelper.IsInsideSkyGarden()
    
    -- 设备是低内存的情况下，处于空花环境，或者未约束仅空花环境，则启用
    local isEnableLowMemoryMode = isHarwareLowMemory and (isInSkyGarden or not XTool.IsNumberValidEx(CS.XGame.ClientConfig:GetInt("UiRoleLowMemoryOnlyInSG")))
    
    
    self:_InitCachePool(isEnableLowMemoryMode)

    self._AnimationEvent = nil

    -- 融合动画播放计数，用于定时器区分是否动画变更
    self._AnimaCrossTimes = 0
end

--- 初始化缓存池，根据 isLowMemory 选择淘汰策略
---@param isLowMemory boolean
function XUiPanelRoleModel:_InitCachePool(isLowMemory)
    local XModelCachePool    = require("XCommon/XModelCache/XModelCachePool")
    local EvictionPolicy     = require("XCommon/XModelCache/XCacheEvictionPolicy")

    local cacheTTL = isLowMemory and CS.XGame.ClientConfig:GetFloat("UiRoleCacheMaxTimeLowMemory") or CS.XGame.ClientConfig:GetFloat("UiRoleCacheMaxTime")
    local cacheMaxCount = isLowMemory and CS.XGame.ClientConfig:GetInt("UiRoleCacheMaxCountLowMemory") or CS.XGame.ClientConfig:GetInt("MainMaxCacheModelNumber")
    
    local policy

    -- 最大缓存数为0、缓存时长为0，都将在没有引用后立刻释放，此时使用无缓存策略
    if not XTool.IsNumberValidEx(cacheTTL) or not XTool.IsNumberValidEx(cacheMaxCount) then
        policy = EvictionPolicy.XLowMemoryEvictionPolicy.New()
    else
        policy = EvictionPolicy.XCompositeEvictionPolicy.New(cacheTTL, cacheMaxCount)
    end
    
    self._CachePool = XModelCachePool.New(
        policy,
        function(key, entry) self:_OnCacheEntryDestroy(key, entry) end
    )
    -- 兼容层：保持 self.RoleModelPool[key] 的外部引用有效
    -- 因 Lua table 是引用类型，_Pool 的增删会同步反映到此引用上
    -- 注意：_CachePool:Clear() 内部不替换整个 table，只逐一置 nil，兼容层始终有效
    self.RoleModelPool = self._CachePool._Pool
end

--- 运行时切换低内存模式（热切换策略，不影响已有缓存条目）
--- 由外部调用方根据设备内存状态主动调用
---@param isLowMemory boolean
function XUiPanelRoleModel:SetLowMemoryMode(isLowMemory)
    local EvictionPolicy = require("XCommon/XModelCache/XCacheEvictionPolicy")
    if isLowMemory then
        self._CachePool:SetPolicy(EvictionPolicy.XLowMemoryEvictionPolicy.New())
    else
        local maxCount = XUiHelper.GetClientConfig("MainMaxCacheModelNumber", XUiHelper.ClientConfigType.Int)
        self._CachePool:SetPolicy(EvictionPolicy.XCompositeEvictionPolicy.New(5, maxCount))
    end
end

--- 获取有效的涂装ID（分包检查）
--- 若指定涂装未下载，返回角色默认涂装ID
---@param fashionId number 原始涂装ID
---@param characterId number 角色ID（可选，用于获取默认涂装）
---@return number 有效的涂装ID
function XUiPanelRoleModel:_GetValidFashionId(fashionId, characterId)
    -- 无效fashionId直接返回
    if not XTool.IsNumberValid(fashionId) then
        return fashionId
    end

    -- 检查分包是否开启
    if not XMVCA.XSubPackage:IsOpen() then
        return fashionId
    end

    -- 检查涂装资源是否已下载
    if XMVCA.XSubPackage:CheckFashionDownloaded(fashionId) then
        return fashionId
    end

    -- 未下载，获取角色默认涂装
    local targetCharacterId = characterId
    if not XTool.IsNumberValid(targetCharacterId) then
        -- 从Fashion表获取CharacterId
        local fashionTemplate = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
        if fashionTemplate then
            targetCharacterId = fashionTemplate.CharacterId
        end
    end

    if XTool.IsNumberValid(targetCharacterId) then
        local charTemplate = XMVCA.XCharacter:GetCharacterTemplate(targetCharacterId)
        if charTemplate then
            return charTemplate.DefaultNpcFashtionId
        end
    end

    return fashionId
end

--设置默认动画
function XUiPanelRoleModel:SetDefaultAnimation(animationName)
    self.DefaultAnimation = animationName
end

--[[    根据roleName从UiModel获取配置
    如果没有Display控制器，直接加载默认动画，否则加载控制器并播控制器默认动画
    PS:如果配置了Fasion控制层，直接以Fasion控制器为主
]]
function XUiPanelRoleModel:UpdateRoleModelWithAutoConfig(
roleName,
targetUiName,
cb,
isReLoadController,
needFightController)
    local displayController = XModelManager.GetUiDisplayControllerPath(roleName)
    local defaultAnimation = XModelManager.GetUiDefaultAnimationPath(roleName)
    self:UpdateRoleModel(
    roleName,
    nil,
    targetUiName,
    cb,
    defaultAnimation ~= nil,
    displayController ~= nil,
    isReLoadController,
    needFightController
    )
end

function XUiPanelRoleModel:UpdateRoleModel(
roleName,
targetPanelRole,
targetUiName,
cb,
IsReLoadAnime,
needDisplayController,
IsReLoadController,
needFightController)
    if not roleName then
        XLog.Error("XUiPanelCharRole:UpdateRoleModel 函数错误: 参数roleName不能为空")
        return
    end
    local isSpecialModel, isMultiModel = XModelManager.CheckModelIsSpecial(roleName, targetUiName)
    if self.UseMultiModel and isMultiModel then
        if not self.NewPanel then
            self.UseMultiModel = false
            self.NewPanel = XUiPanelRoleModel.New(
                    self.Ui,
                    self.RefName,
                    self.HideWeapon,
                    self.ShowShadow,nil,nil,nil,nil,nil,self.UseMultiModel)
        end
    end

    if self.NewPanel and isMultiModel then
        local minorModelId = XModelManager.GetMinorModelId(roleName, targetUiName)
        if not minorModelId then
            self.NewPanel = nil
        else
            self.NewPanel:UpdateRoleModel(
                    minorModelId,
                    targetPanelRole,
                    targetUiName,
                    cb,
                    IsReLoadAnime,
                    needDisplayController,
                    IsReLoadController,
                    needFightController)
        end

    end
    --特殊模型 && 单模型
    if isSpecialModel and not isMultiModel then
        roleName = XModelManager.GetSpecialModelId(roleName, targetUiName)
    end
    local defaultAnimation = self.DefaultAnimation or XModelManager.GetUiDefaultAnimationPath(roleName)
    self.DefaultAnimation = nil

    -- 隐藏当前激活模型的特效（BeginSwitch 内会打时间戳，此处只需处理特效）
    local curEntry = self._CachePool:Get(self.CurRoleName)
    if curEntry then
        if XTool.UObjIsNil(curEntry.Model) then
            XLog.Error("[UpdateRoleModel] NullReferenceException: Object reference not set to an instance of an object")
            -- _CachePool:Get 内部已通过悬空检测清除该条目，此处直接返回
            return
        end
        curEntry.Model.gameObject:SetActiveEx(false)
        self:SetCurrentUiEffectActive(curEntry.UiEffect, false)
    end
    if self.CurRoleName ~= roleName then
        self.CurRoleName = roleName
    end

    local runtimeControllerName
    --特殊时装只加载配置的动画状态机Controller
    runtimeControllerName = (not needFightController) and XModelManager.GetUiFashionControllerPath(roleName)
    if not runtimeControllerName then
        --如果没有配置，再加载配置展示用的动画状态机Controller
        if needDisplayController then
            runtimeControllerName = XModelManager.GetUiDisplayControllerPath(roleName)
        end

        if needFightController then
            runtimeControllerName = XModelManager.GetUiControllerPath(roleName)
        end
    end

    --如果用状态机就不需要手动加载animclip了
    if runtimeControllerName then
        self.LoadClip = nil
    else
        self.LoadClip = self.InitLoadClip --复原成一开始传入的参数
    end

    -- 触发淘汰策略，并取得异步令牌和是否需要串行等待
    -- 低内存策略下 needWaitDestroy=true，须等下一帧 Unity 完成 Destroy 后再加载
    local token, needWaitDestroy = self._CachePool:BeginSwitch(roleName)

    -- 同步通知副面板切换（低内存下副模型也同步淘汰）
    if self.NewPanel and isMultiModel then
        local minorModelId = XModelManager.GetMinorModelId(roleName, targetUiName)
        if minorModelId then
            self.NewPanel._CachePool:BeginSwitch(minorModelId)
        end
    end

    local fashionUiStandConfigCueId = self._FashionUiStandConfigCueId
    local partnerSToCVoiceConfigCueId = self._PartnerSToCVoiceConfigCueId
    local partnerSToCVoicePlayedCueIdSet = self._PartnerSToCVoicePlayedCueIdSet
    local onRoleModelLoaded = function(roleModel)
        self:_TryPlayFashionUiStandAudio(roleModel, fashionUiStandConfigCueId)
        self:_TryPlayPartnerSToCVoice(partnerSToCVoiceConfigCueId, partnerSToCVoicePlayedCueIdSet)

        if cb then
            cb(roleModel)
        end
    end

    -- 检查缓存是否命中（BeginSwitch 之后再 Get，此时旧条目已完成淘汰）
    local cachedEntry = self._CachePool:Get(roleName)

    if IsReLoadAnime then
        self:_DoLoadModel(cachedEntry, roleName, targetUiName, defaultAnimation,
            onRoleModelLoaded, runtimeControllerName, IsReLoadController,
            token, needWaitDestroy, true)
    else
        self:_DoLoadModel(cachedEntry, roleName, targetUiName, defaultAnimation,
            onRoleModelLoaded, runtimeControllerName, IsReLoadController,
            token, needWaitDestroy, false)
    end
end

--- 统一的模型加载/复用入口
--- 根据缓存命中与否、串行/并行模式三路分发
---@param cachedEntry      table|nil   缓存命中时的 entry，nil 表示未命中
---@param roleName         string
---@param targetUiName     string|nil
---@param defaultAnimation string|nil
---@param cb               function
---@param runtimeControllerName string|nil
---@param IsReLoadController    boolean
---@param token            number   BeginSwitch 返回的令牌
---@param needWaitDestroy  boolean  低内存串行模式标志
---@param isReLoadAnime    boolean
function XUiPanelRoleModel:_DoLoadModel(cachedEntry, roleName, targetUiName, defaultAnimation,
    cb, runtimeControllerName, IsReLoadController, token, needWaitDestroy, isReLoadAnime)

    if cachedEntry then
        -- ── 命中缓存：直接复用，无需异步加载 ──
        if isReLoadAnime then
            self:_LoadModelAndReLoadAnime(cachedEntry, targetUiName, roleName,
                defaultAnimation, cb, runtimeControllerName, IsReLoadController)
        else
            self:_LoadModelAndNotReLoadAnime(cachedEntry, targetUiName, roleName,
                defaultAnimation, cb, runtimeControllerName, IsReLoadController)
        end
        return
    end

    -- ── 未命中：需要异步加载 ──
    local doLoad = function()
        -- 串行模式等待后，须二次校验令牌（等待期间可能再次切换）
        if token ~= self._CachePool._TokenCounter then
            return
        end
        if isReLoadAnime then
            self:_LoadModelAndReLoadAnime(nil, targetUiName, roleName,
                defaultAnimation, cb, runtimeControllerName, IsReLoadController, token)
        else
            self:_LoadModelAndNotReLoadAnime(nil, targetUiName, roleName,
                defaultAnimation, cb, runtimeControllerName, IsReLoadController, token)
        end
    end

    if needWaitDestroy then
        -- 低内存串行模式：等下一帧 Unity Destroy 完成后再发起加载
        --XScheduleManager.ScheduleNextFrame(doLoad)
        --todo 因为很多地方是同步逻辑，这里暂时先不隔帧加载
        doLoad()
    else
        doLoad()
    end
end

--region 模型音频

--region Set

---设置涂装UiStand展示音。音频来自Client/Fashion/FashionVoice.tab。
function XUiPanelRoleModel:SetFashionUiStandCueIdByFashionId(fashionId)
    if not fashionId then
        return
    end
    self.UiStandCallBack = {}
    self._FashionUiStandConfigCueId = XDataCenter.FashionManager.GetCueIdByFashionId(fashionId)
end

---设置辅助机待机转战斗音效。音频来自Client/Partner/PartnerModel.tab的SToCVoice。
function XUiPanelRoleModel:SetPartnerSToCVoiceCueId(cueId)
    if not XTool.IsNumberValid(cueId) then
        return
    end
    self.UiStandCallBack = {}
    self._PartnerSToCVoiceConfigCueId = cueId
end

--endregion

--region Play

---注册并尝试播放涂装UiStand展示音。SetUiStandAnimaFinishCallback会立即执行一次播放回调，后续动画结束时也会回调。
function XUiPanelRoleModel:_TryPlayFashionUiStandAudio(model, cueId)
    if not cueId then
        return
    end

    if CS.XAudioManager.IsOpenFashionVoice ~= 1 then
        return
    end

    self:SetUiStandAnimaFinishCallback(model, function()
        self:StopFashionUiStandAudio()
        if not self:_TryPlaySfxWithXAnimationSound(cueId) then
            XLog.Warning("PlayFashionCue xAnimationSound is nil, skip audio ", cueId)
        end
    end, function()
        self:StopFashionUiStandAudio()
    end, false, true)
end

---尝试播放辅助机SToCVoice。同一cueId在同一面板内只播放一次；缺少XAnimationSound时走局部历史兼容。
function XUiPanelRoleModel:_TryPlayPartnerSToCVoice(cueId, playedCueIdSet)
    if not cueId or playedCueIdSet[cueId] then
        return
    end

    playedCueIdSet[cueId] = true
    self:StopPartnerSToCVoice()
    self._PartnerSToCVoiceActiveCueId = cueId

    if not self:_TryPlaySfxWithXAnimationSound(cueId) then
        self._PartnerSToCVoiceFallbackAudioInfo = self:_PlayPartnerSToCVoiceFallback(cueId)
    end
end

---辅助机模型暂未配置XAnimationSound时，保留SToCVoice的历史兼容播放。
function XUiPanelRoleModel:_PlayPartnerSToCVoiceFallback(cueId)
    local audioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
    if audioInfo then
        audioInfo.UpdateCb = function()
            local curModel = self:GetCurRoleModel()
            if XTool.UObjIsNil(curModel) or not curModel.activeSelf then
                self:StopPartnerSToCVoice()
            end
        end
    end
    return audioInfo
end

---内部尝试通过XAnimationSound播放SFX，只表达正常主链路。
function XUiPanelRoleModel:_TryPlaySfxWithXAnimationSound(cueId)
    if not cueId then
        return false
    end

    local xAnimationSound = self:GetXAnimationSound()
    if not xAnimationSound then
        return false
    end

    xAnimationSound:PlaySoundByCueId(cueId)
    return true
end

--endregion

--region Stop

---停止涂装UiStand展示音。保留为独立public语义入口，供消费侧按需单独停止。
function XUiPanelRoleModel:StopFashionUiStandAudio()
    if self._FashionUiStandConfigCueId then
        XLuaAudioManager.StopAudioByCueId(self._FashionUiStandConfigCueId)
    end
end

---停止辅助机SToCVoice。保留为独立public语义入口，供消费侧按需单独停止。
function XUiPanelRoleModel:StopPartnerSToCVoice()
    local cueId = self._PartnerSToCVoiceActiveCueId or self._PartnerSToCVoiceConfigCueId
    if cueId then
        XLuaAudioManager.StopAudioByCueId(cueId)
    end

    if self._PartnerSToCVoiceFallbackAudioInfo then
        self._PartnerSToCVoiceFallbackAudioInfo.UpdateCb = nil
    end
    self._PartnerSToCVoiceActiveCueId = nil
    self._PartnerSToCVoiceFallbackAudioInfo = nil
end

---内部停止RoleModel当前托管的Lua主动播放音频；不包含动画事件SFX。
function XUiPanelRoleModel:_StopRoleModelManagedAudio()
    self:StopFashionUiStandAudio()
    self:StopPartnerSToCVoice()
end

---停止当前模型动画事件触发的SFX。播放侧由Animator事件/XAnimationSound触发，不在Lua显式成对调用。
function XUiPanelRoleModel:StopCurrentAnimationSfx()
    local xAnimationSound = self:GetXAnimationSound()
    if xAnimationSound then
        xAnimationSound:StopSFXByAudioInfoUIdSet()
    end
end

---停止当前RoleModel托管的全部展示音频。供看板/拍照等消费侧在展示动作结束时调用。
function XUiPanelRoleModel:StopAllManagedAudio()
    self:StopFashionUiStandAudio()
    self:StopPartnerSToCVoice()
    self:StopCurrentAnimationSfx()
end

--endregion

---获取当前模型上的XAnimationSound组件。
function XUiPanelRoleModel:GetXAnimationSound()
    -- 如果已经获取过组件，直接返回缓存的结果
    if not XTool.UObjIsNil(self._MyXAnimationSound) then
        return self._MyXAnimationSound
    end

    -- 获取所有子物体中的XAnimationSound组件
    local transform = self:GetTransform()
    if not transform then
        return
    end
    local animationSound = transform:GetComponent(typeof(CS.XAnimationSound))

    -- 缓存结果并返回
    self._MyXAnimationSound = animationSound
    return animationSound
end

--endregion

function XUiPanelRoleModel:_LoadModelAndNotReLoadAnime(
modelInfo,
targetUiName,
roleName,
defaultAnimation,
cb,
runtimeControllerName,
IsReLoadController,
token) --更新加载同一个模型时不重新加载动画
    if modelInfo then
        -- 命中缓存：直接激活
        modelInfo.Model.gameObject:SetActiveEx(true)
        if IsReLoadController then
            self:RoleModelLoaded(roleName, targetUiName, cb, runtimeControllerName)
        else
            self:RoleModelLoaded(roleName, targetUiName, cb)
        end
    else
        -- 未命中：发起异步加载
        XModelManager.LoadRoleModel(
        self.CurRoleName,
        self.Transform,
        function(model)
            -- 写入缓存，令牌校验在 Put 内部完成；过期则 Put 自动销毁多余 GO 并返回 false
            local payload = {}
            payload.RenderingProxy = CS.XNPCRendingUIProxy.GetNPCRendingUIProxy(model)
            local ok = self._CachePool:Put(roleName, model, token, payload)
            if not ok then return end

            if self.LoadClip then
                self:LoadAnimationClips(
                model.gameObject,
                defaultAnimation,
                function()
                    self:RoleModelLoaded(roleName, targetUiName, cb, runtimeControllerName)
                end
                )
            else
                self:RoleModelLoaded(roleName, targetUiName, cb, runtimeControllerName)
            end

            self:_AttachMinorModelIfNeeded(model, targetUiName)
        end)
    end
end

function XUiPanelRoleModel:_LoadModelAndReLoadAnime(
modelInfo,
targetUiName,
roleName,
defaultAnimation,
cb,
runtimeControllerName,
IsReLoadController,
token) --更新加载同一个模型时重新加载动画
    if modelInfo then
        -- 命中缓存：激活并重新加载动画片段
        modelInfo.Model.gameObject:SetActiveEx(true)
        self:LoadSingleAnimationClip(
        modelInfo.Model.gameObject,
        defaultAnimation,
        function()
            self:RoleModelLoaded(roleName, targetUiName, cb)
        end
        )
    else
        -- 未命中：发起异步加载
        XModelManager.LoadRoleModel(
        self.CurRoleName,
        self.Transform,
        function(model)
            local payload = {}
            payload.RenderingProxy = CS.XNPCRendingUIProxy.GetNPCRendingUIProxy(model)
            local ok = self._CachePool:Put(roleName, model, token, payload)
            if not ok then return end

            self:LoadSingleAnimationClip(
            model.gameObject,
            defaultAnimation,
            function()
                self:RoleModelLoaded(roleName, targetUiName, cb)
            end
            )

            self:_AttachMinorModelIfNeeded(model, targetUiName)
        end)
    end
end

--- 新加载的主模型就绪后，将已加载的副模型挂到主模型下（多重模型场景）
---@param mainModel userdata  Unity Component
---@param targetUiName string|nil
function XUiPanelRoleModel:_AttachMinorModelIfNeeded(mainModel, targetUiName)
    local isSpecialModel, isMultiModel = XModelManager.CheckModelIsSpecial(self.CurRoleName, targetUiName)
    if not (self.NewPanel and isMultiModel) then
        return
    end
    local newModelName = XModelManager.GetMinorModelId(self.CurRoleName, targetUiName)
    local minorEntry = newModelName and self.NewPanel._CachePool:Get(newModelName)
    if minorEntry then
        minorEntry.Model.transform:SetParent(mainModel.transform, false)
        self:SetEffectLayerRecursively(
            minorEntry.Model.gameObject,
            mainModel.gameObject.layer,
            CS.UnityEngine.LayerMask.NameToLayer(KeepGraphicLayer.Distortion)
        )
    end
end

local function GetDefaultAnimaName(loadAnimationClip)
    if not XTool.UObjIsNil(loadAnimationClip) and loadAnimationClip.Clips.Length > 0 then
        return loadAnimationClip.Clips[0].name
    end
    
    return ""
end

function XUiPanelRoleModel:SetPlayRoleAnimationCallback(model)
    local playRoleAnimation = model.gameObject:GetComponent(typeof(CS.XPlayRoleAnimation))

    if XTool.UObjIsNil(playRoleAnimation) then
        return
    end
    playRoleAnimation:SetPlayCallback(function(animaName, leftTime)
        for i = 1, #self.PlayUiStandCallBackList do
            self.PlayUiStandCallBackList[i](animaName, leftTime)
        end
    end)
end

local function RestoreModelNode(model, modelName, actionName)
    XModelManager.HandleUiModelNodeActive(actionName, modelName, model, true)
end

---设置播放UiStand时根据动画名隐藏或显示躯干的回调
function XUiPanelRoleModel:InitPlayUiStandCallBackList(model, defaultAnimaName)
    local curRoleName = self.CurRoleName
    local preAnimaName = ""
    
    self.PlayUiStandCallBackList = {}
    if curRoleName then
        if defaultAnimaName then
            XModelManager.HandleUiModelNodeActive(defaultAnimaName, curRoleName, model, false)
            preAnimaName = defaultAnimaName
        end
        
        self:AddUiStandPlayCallback(function(animaName, leftTime)
            if not string.IsNilOrEmpty(animaName) then
                if preAnimaName == animaName then
                    return
                end
                
                self:UnBindWeaponBone(animaName)
                RestoreModelNode(model, curRoleName, preAnimaName)
                XModelManager.HandleUiModelNodeActive(animaName, curRoleName, model, false)
                preAnimaName = animaName
            end
        end)
    end
end

function XUiPanelRoleModel:LoadAnimationClips(model, defaultAnimation, cb)
    if model == nil or not model:Exist() then
        XLog.Error("XUiPanelRoleModel.LoadAnimation 函数错误，参数model不能为空")
        return
    end
    
    
    local loadAnimationClip = model.gameObject:GetComponent(typeof(CS.XLoadAnimationClip))
    if loadAnimationClip == nil or not loadAnimationClip:Exist() then
        loadAnimationClip = model.gameObject:AddComponent(typeof(CS.XLoadAnimationClip))
        if not loadAnimationClip:Exist() then
            XLog.Error("XUiPanelRoleModel.LoadAnimation XLoadAnimationClip不存在")
            return
        end

        local clips = { defaultAnimation }
        if XTool.IsTableEmpty(clips) then
            XLog.Error("XUiPanelRoleModel.LoadAnimation error: defaultAnimation为空")
            return
        end

        local activeState = model.gameObject.activeSelf
        model.gameObject:SetActiveEx(false)
        loadAnimationClip:LoadAnimationClips(
        clips,
        function()
            model.gameObject:SetActiveEx(activeState)
            if cb then
                cb()
            end
        end
        )
    else
        if cb then
            cb()
        end
    end
end

function XUiPanelRoleModel:LoadSingleAnimationClip(model, defaultAnimation, cb)
    if model == nil or not model:Exist() then
        local modelPool = self.RoleModelPool
        local curRoleName = self.CurRoleName
        local curModelInfo = modelPool[curRoleName]
        if curModelInfo then
            model = curModelInfo.Model.gameObject
        else
            XLog.Error("XUiPanelRoleModel.LoadAnimation model = nil ")
            return
        end
    end

    local loadAnimationClip = model.gameObject:GetComponent(typeof(CS.XLoadAnimationClip))

    if loadAnimationClip == nil or not loadAnimationClip:Exist() then
        loadAnimationClip = model.gameObject:AddComponent(typeof(CS.XLoadAnimationClip))
    end

    local activeState = model.gameObject.activeSelf
    model.gameObject:SetActiveEx(false)
    loadAnimationClip:LoadSingleAnimationClip(
    defaultAnimation,
    function()
        model.gameObject:SetActiveEx(activeState)
        if cb then
            cb()
        end
    end
    )
end

function XUiPanelRoleModel:RoleModelLoaded(name, uiName, cb, runtimeControllerName)
    if not self.CurRoleName then
        return
    end
    local modelInfo = self.RoleModelPool[self.CurRoleName]
    if not modelInfo then
        return
    end
    local model = modelInfo.Model

    XModelManager.SetRoleTransform(name, model, uiName)
    XModelManager.SetRoleCamera(name, model.transform.parent.parent.parent, uiName, self.CurCharacterId)

    if runtimeControllerName then
        local animator = model:GetComponent("Animator")
        animator.runtimeAnimatorController = CS.LoadHelper.LoadUiController(runtimeControllerName, animator.gameObject)
    end

    if self.SetFocus then
        CS.XGraphicManager.Focus = model.transform
    end

    -- UiStand通过动作控制节点显隐回调注册
    if self.LoadClip then
        local loadAnimationClip = model.gameObject:GetComponent(typeof(CS.XLoadAnimationClip))

        -- 在Callback前初始化回调列表
        if not XTool.UObjIsNil(loadAnimationClip) then
            self:SetPlayRoleAnimationCallback(model)
            self:InitPlayUiStandCallBackList(model, GetDefaultAnimaName(loadAnimationClip))
        end
    end

    if cb then
        cb(model)
    end
    uiName = uiName or self.RefName

    -- 在武器加载完成后进行第一次UiStand的判断
    if self.LoadClip then
        local loadAnimationClip = model.gameObject:GetComponent(typeof(CS.XLoadAnimationClip))

        if not XTool.UObjIsNil(loadAnimationClip) then
            self:UnBindWeaponBone(GetDefaultAnimaName(loadAnimationClip))
        end
    end
    if not self.InitLoadClip then
        self.IsStandAnimaHideNode = XModelManager.HandleUiModelNodeActive(DefaultRoleAnimaName, name, model, false)
    end

    -- 阴影要放在武器模型加载完之后
    if self.ShowShadow then
        CS.XShadowHelper.AddShadow(self.GameObject, true)
    end

    -- 只有不是三个模型同时出现的界面调用此接口
    if not self.FixLight then
        CS.XShadowHelper.SetCharRealtimeShadow(self.GameObject, true)
    end

    -- 在最后设置材质球，避免加载模式过程中将模型隐藏后还原材质球设置
    XModelManager.LoadModelScriptPart(name, model)
end

function XUiPanelRoleModel:SetRoleTransform(uiName)
    local modelInfo = self.RoleModelPool[self.CurRoleName]
    if not modelInfo then
        return
    end
    local model = modelInfo.Model
    local name = self.CurRoleName
    XModelManager.SetRoleTransform(name, model, uiName)
    XModelManager.SetRoleCamera(name, model.transform.parent.parent.parent, uiName, self.CurCharacterId)
end

function XUiPanelRoleModel:GetModelName(characterId)
    local quality
    local character = XMVCA.XCharacter:GetCharacter(characterId)
    if character then
        quality = character.Quality
    end

    return XMVCA.XCharacter:GetCharModel(characterId, quality)
end
--region---------------------------------加载Ui角色动作特效start---------------------------
--==============================--
--desc: (外部接口)加载当前Ui角色动作特效
--@characterId: 角色id
--@actionId: 动作Id
--==============================--
function XUiPanelRoleModel:LoadCharacterUiEffect(characterId, actionId, isNotSelf, weaponFashionId, isShowDefaultWeapon)
    if not characterId then
        return
    end
    
    local fashionId = nil

    if not self.NowFashionId then
        fashionId = XMVCA.XCharacter:GetShowFashionId(characterId, isNotSelf)
    else
        fashionId = self.NowFashionId    
    end
    local equipModelIdList = XMVCA.XEquip:GetWeaponEquipModelIdListByTemplateId(0, weaponFashionId)
    local id, rootName, effectPath = XCharacterUiEffectConfig.GetEffectInfo(characterId, fashionId, actionId, equipModelIdList)
    local model = self.RoleModelPool[self.CurRoleName]
    if not model then return end
    if not model.CharacterId then
        model.CharacterId = characterId
    end

    self:SetCurrentUiEffectActive(model.UiEffect, false)
    self:SetCurrentUiEffectActive(model.UiEquipEffect, false)

    if not model.NotUiStand1 then
        local playRoleAnimation = model.Model.gameObject:GetComponent("XPlayRoleAnimation")
        if playRoleAnimation then
            local defaultAnimeName = playRoleAnimation.DefaultClip
            model.NotUiStand1 = defaultAnimeName ~= "UiStand1"
        else
            model.NotUiStand1 = true
            return
        end
    end
    if not actionId and model.NotUiStand1 then
        return
    end
    if not actionId then
        model.UiDefaultId = id
    end
    self:LoadCharacterUiEquipEffect(model, characterId, fashionId, actionId, isShowDefaultWeapon, weaponFashionId)
    self:PlayCharacterUiEffect(model, id, rootName, effectPath)
end
--==============================--
--desc: (外部接口)加载时装展示Ui角色动作特效
--@characterId: 角色id
--@fashionId: 时装Id
--==============================--
function XUiPanelRoleModel:LoadResCharacterUiEffect(characterId, fashionId, weaponFashionId, isShowDefaultWeapon, equipTemplateId)
    if not characterId then
        return
    end
    local equipModelIdList = XMVCA.XEquip:GetWeaponEquipModelIdListByTemplateId(equipTemplateId, weaponFashionId)
    local id, rootName, effectPath = XCharacterUiEffectConfig.GetEffectInfo(characterId, fashionId, nil, equipModelIdList)
    if not id or not effectPath then
        return
    end
    local model = self.RoleModelPool[self.CurRoleName]
    if not model then return end
    if not model.CharacterId then
        model.CharacterId = characterId
    end
    self:SetCurrentUiEffectActive(model.UiEffect, false)
    self:SetCurrentUiEffectActive(model.UiEquipEffect, false)
    local playRoleAnimation = model.Model.gameObject:GetComponent("XPlayRoleAnimation")
    if playRoleAnimation then
        local defaultAnimeName = playRoleAnimation.DefaultClip
        model.NotUiStand1 = defaultAnimeName ~= "UiStand1"
        if model.NotUiStand1 then
            return
        end
    else
        model.NotUiStand1 = true
        return
    end
    self:LoadCharacterUiEquipEffect(model, characterId, fashionId, nil, isShowDefaultWeapon, weaponFashionId, equipTemplateId)
    self:PlayCharacterUiEffect(model, id, rootName, effectPath)
end
--==============================--
--desc: 加载当前Q版角色动作特效
--@characterId: 角色id
--==============================--
function XUiPanelRoleModel:LoadCharacterCuteUiEffect(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    local model = self.RoleModelPool[self.CurRoleName]
    if not model then
        return
    end
    if not model.CharacterId then
        model.CharacterId = characterId
    end
    if XTool.UObjIsNil(model.Model) then
        return
    end
    local playRoleAnimation = model.Model.gameObject:GetComponent("XPlayRoleAnimation")
    if not playRoleAnimation then
        return
    end
    -- Q版角色特殊处理 直接取默认动作id
    local actionId = playRoleAnimation.DefaultClip
    local id, rootName, effectPath = XCharacterCuteConfig.GetEffectInfo(characterId, actionId)
    self:SetCurrentUiEffectActive(model.UiEffect, false)
    self:PlayCharacterUiEffect(model, id, rootName, effectPath)
end
--==============================--
--desc: (外部接口)加载Ui角色默认动作特效
--==============================--
function XUiPanelRoleModel:LoadCurrentCharacterDefaultUiEffect()
    local model = self.RoleModelPool[self.CurRoleName]
    if not model then return end
    if model.NotUiStand1 or not model.UiDefaultId then
        return
    end
    self:SetCurrentUiEffectActive(model.UiEffect, false)
    self:SetCurrentUiEffectActive(model.UiEquipEffect, false)
    local fashionId = XMVCA.XCharacter:GetShowFashionId(model.CharacterId)
    -- 分包检查：若涂装未下载则使用默认涂装
    fashionId = self:_GetValidFashionId(fashionId, model.CharacterId)
    local _, rootName, effectPath = XCharacterUiEffectConfig.GetEffectInfo(model.CharacterId, fashionId)
    self:LoadCharacterUiEquipEffect(model, model.CharacterId, fashionId)
    self:PlayCharacterUiEffect(model, model.UiDefaultId, rootName, effectPath)
end
--==============================--
--desc: 播放Ui角色动作特效
--==============================--
function XUiPanelRoleModel:PlayCharacterUiEffect(model, id, rootName, effectPath)
    if not id or not effectPath then
        return
    end
    if self._EffectTimer then
        XScheduleManager.UnSchedule(self._EffectTimer)
        self._EffectTimer = nil
    end
    --- 临时处理21号森息涂装模型动画和特效动画对齐问题
    if self.CurRoleName == XEnumConst.SpecialHandling.CoatingModelId then
        self._EffectTimer = XScheduleManager.ScheduleNextFrame(function()
            self:GetModelUiEffect(model, id, rootName, effectPath)
            self:SetCurrentUiEffectActive(model.UiEffect, true)
            self:BindEffectByModel(model)
            self:RePlayUiStand(model)
            self:SetReActiveUiEffect(model)
        end)
    else
        self:GetModelUiEffect(model, id, rootName, effectPath)
        self:SetCurrentUiEffectActive(model.UiEffect, true)
        self:BindEffectByModel(model)
        self:SetReActiveUiEffect(model)
    end
end

function XUiPanelRoleModel:RePlayUiStand(model)
    local playAnima = model.Model.gameObject:GetComponent(typeof(CS.XPlayRoleAnimation))

    if not playAnima then
        return
    end

    local clips = playAnima.Clips
    local defaultClip = playAnima.DefaultClip

    playAnima:Stop()
    playAnima:SetAnimationClips(clips);
    playAnima:SetDefaultAnimation(defaultClip);
    playAnima:PlayDefault()

    self:SetPlayRoleAnimationCallback(model.Model)
end

function XUiPanelRoleModel:LoadCharacterUiEquipEffect(model, characterId, fashionId, actionId, isShowDefaultWeapon, weaponFashionId, equipTemplateId)
    local equipModelIdList
    if equipTemplateId then
        local equip = { TemplateId = equipTemplateId }
        equipModelIdList = XMVCA.XEquip:GetWeaponEquipModelIdListByEquip(equip, weaponFashionId)
    else
        equipModelIdList = XMVCA.XEquip:GetEquipModelIdListByCharacterId(characterId, isShowDefaultWeapon, weaponFashionId)
    end
    local idList, rootName2EffectPath = {}, {}
    for _, equipModelId in ipairs(equipModelIdList or {}) do
        if equipModelId and equipModelId ~= 0 then
            local effectId, name2EffectMap = XCharacterUiEffectConfig.GetEquipEffectInfo(equipModelId, fashionId, actionId)
            if effectId then
                table.insert(idList, effectId)
                for rootName, effectList in pairs(name2EffectMap or {}) do
                    rootName2EffectPath[rootName] = effectList
                end
            end
        end
    end
    if not XTool.IsTableEmpty(idList) then
        self:GetModelUiEquipEffect(model, table.concat(idList, "-"), rootName2EffectPath)
    end
end

function XUiPanelRoleModel:LoadCharacterUiEquipEffectOther(model, equip, fashionId, actionId, weaponFashionId)
    local idList, rootName2EffectPath = {}, {}
    local equipModelIdList = XMVCA.XEquip:GetWeaponEquipModelIdListByEquip(equip, weaponFashionId)
    for _, equipModelId in ipairs(equipModelIdList or {}) do
        if equipModelId ~= 0 then
            local effectId, name2EffectMap = XCharacterUiEffectConfig.GetEquipEffectInfo(equipModelId, fashionId, actionId)
            if effectId then
                table.insert(idList, effectId)
                for rootName, effectList in pairs(name2EffectMap or {}) do
                    rootName2EffectPath[rootName] = effectList
                end
            end
        end
    end
    if not XTool.IsTableEmpty(idList) then
        self:GetModelUiEquipEffect(model, table.concat(idList, "-"), rootName2EffectPath)
    end
end
--==============================--
--desc: 获取Ui角色动作特效
--==============================--
function XUiPanelRoleModel:GetModelUiEffect(model, id, rootNameArray, effectPathArray)
    -- 判断是否需要更新特效显示
    local isUpdateShow = false
    if XTool.IsTableEmpty(model.UiEffectRecord) then
        isUpdateShow = true
    else
        for index, effectPathList in pairs(effectPathArray) do
            if not model.UiEffectRecord[index] then
                isUpdateShow = true
                break
            end
            for i, effectPath in pairs(effectPathList) do
                if not model.UiEffectRecord[index][i] or effectPath ~= model.UiEffectRecord[index][i] then
                    isUpdateShow = true
                    break
                end
            end
        end
    end
    
    if model.UiEffect and model.CurrentUiEffectId == id and not isUpdateShow then
        local isHaveValue = true
        for _, v in ipairs(model.UiEffect) do
            if XTool.UObjIsNil(v) then
                isHaveValue = false
            end
        end
        if isHaveValue then
            self:PlayDelayEffects(model)
            return model.UiEffect
        end
    end
    model.CurrentUiEffectId = id
    model.UiEffectRecord = effectPathArray
    -- 不管上次的特效，因为XUiLoadPrefab已经处理了重复加载问题（XUiLoadPrefab组件同一个挂点只会生成一个Prefab，旧的会自动销毁）
    model.UiEffect = self:ClearUiEffectList(model.UiEffect)
    model.EffectDelayTimes = {}
    local uiEffectArray = model.UiEffect
    local isRotates = XCharacterUiEffectConfig.IsRotateWithCharacter(model)
    local displayDelayTimes = XCharacterUiEffectConfig.GetDisplayDelayTime(model)
    for idx, rootName in pairs(rootNameArray) do
        local displayDelayTime = displayDelayTimes and displayDelayTimes[idx] or nil
        for i, effectPath in ipairs(effectPathArray[idx] or {}) do
            local isRotate = true
            if isRotates then
                isRotate = isRotates[idx]
            end
            local time = 0
            if not XTool.IsTableEmpty(displayDelayTime) then
                time = displayDelayTime[i] or 0
            end
            local uiEffect = self:CreateUiEffect(model, id, rootName, effectPath, XEnumConst.Fashion.EffectType.UiEffect, isRotate, time)
            uiEffectArray[#uiEffectArray + 1] = uiEffect
            model.EffectDelayTimes[uiEffect.transform.parent.gameObject.name] = time
        end
    end
    return uiEffectArray
end

function XUiPanelRoleModel:SetEffectLayerRecursively(gameObject,targetLayer, keepLayer , force)
    gameObject.transform:SetLayerRecursively(targetLayer,keepLayer)    
end 

--- 获取Ui角色武器特效
--------------------------
function XUiPanelRoleModel:GetModelUiEquipEffect(model, id, rootName2EffectPath)
    self:SetCurrentUiEffectActive(model.UiEquipEffect, true)
    if model.UiEquipEffect and model.CurrentUiEquipEffectId == id then
        return model.UiEquipEffect
    end
    model.CurrentUiEquipEffectId = id
    model.UiEquipEffect = self:ClearUiEffectList(model.UiEquipEffect)
    local list = {}
    for rootName, effectPathList in pairs(rootName2EffectPath or {}) do
        for _, effectPath in ipairs(effectPathList or {}) do
            table.insert(list, self:CreateUiEffect(model, id, rootName, effectPath, XEnumConst.Fashion.EffectType.WeaponEffect))
        end
    end
    model.UiEquipEffect = list
    
    return list
end
--==============================--
--desc: 生成Ui角色动作特效
--==============================--
function XUiPanelRoleModel:CreateUiEffect(model, id, rootName, effectPath, effectType, isRotate, displayDelayTime)
    local parent = self:GetUiEffectRoot(model, rootName, effectPath, effectType, isRotate, displayDelayTime)
    local obj = CS.LoadHelper.InstantiateGameObject(effectPath)
    obj.transform:SetParent(parent.transform, false)
    self:SetEffectLayerRecursively(obj,parent.gameObject.layer,CS.UnityEngine.LayerMask.NameToLayer(KeepGraphicLayer.Distortion))
    -- obj:SetLayerRecursively(parent.gameObject.layer,CS.UnityEngine.LayerMask.NameToLayer(KeepGraphicLayer.Distortion))
    --local fx = parent:LoadPrefab(effectPath, false)
    -- 由于预制是在模型加载之后，需要再次添加阴影
    if self.ShowShadow then
        CS.XShadowHelper.AddShadow(obj.gameObject, true)
    end
    -- 只有不是三个模型同时出现的界面调用此接口 由于预制是在模型加载之后，需要再次添加阴影
    if not self.FixLight then
        CS.XShadowHelper.SetCharRealtimeShadow(self.GameObject, true)
    end
    -- v3.1 延迟播放特效
    self:PlayDelayEffect(parent, displayDelayTime)
    return obj
end

function XUiPanelRoleModel:GetUiEffectRoot(model, rootName, effectPath, effectType, isRotate, displayDelayTime)
    ---@type UnityEngine.GameObject
    local parent  -- 搜挂点
    if not rootName or rootName == XCharacterUiEffectConfig.GetDefaultRootName() then
        parent = model.Model.gameObject
    else
        parent = model.Model.gameObject:FindGameObject(rootName)
        if not parent then
            parent = model.Model.gameObject
        end
    end
    if effectType == XEnumConst.Fashion.EffectType.WeaponEffect or (isRotate and not XTool.IsNumberValid(displayDelayTime)) then
        return parent
    else
        local filename = effectPath:match("^.+/(.+)%..+$")
        local modelParent = model.Model.transform.parent
        ---@type UnityEngine.GameObject
        local root = CS.UnityEngine.GameObject(filename)
        root.transform:SetParent(modelParent, false)
        self:SetEffectLayerRecursively(root,modelParent.gameObject.layer,CS.UnityEngine.LayerMask.NameToLayer(KeepGraphicLayer.Distortion))
        -- root:SetLayerRecursively(modelParent.gameObject.layer,CS.UnityEngine.LayerMask.NameToLayer(KeepGraphicLayer.Distortion))
        root.transform.position = parent.transform.position
        root.transform.localScale.x = parent.transform.lossyScale.x / modelParent.lossyScale.x
        root.transform.localScale.y = parent.transform.lossyScale.y / modelParent.lossyScale.y
        root.transform.localScale.z = parent.transform.lossyScale.z / modelParent.lossyScale.z
        root.transform.rotation = parent.transform.rotation
        return root
    end
end

--动作播放完重新播放特效
-- 角色动作播放完后重新激活特效，因角色是循环播放，特效每次都是重新播放（从0开始播）。
-- 这会导致特效的播放时间和角色动作的播放时间不一致，角色比特效慢了大约一帧时间（范围是 0到一帧）
function XUiPanelRoleModel:SetReActiveUiEffect(model)
    --local playRoleAnimation = model.Model.gameObject:GetComponent("XPlayRoleAnimation")
    if XTool.IsTableEmpty(model.UiEffect)
            and XTool.IsTableEmpty(model.UiEquipEffect) --[[or not playRoleAnimation]] then
        return
    end

    self:SetUiStandAnimaFinishCallback(model.Model, function()
        for _, effect in ipairs(model.UiEffect or {}) do
            if not XTool.UObjIsNil(effect) and effect.gameObject.activeSelf then
                effect.gameObject:SetActiveEx(false)
                effect.gameObject:SetActiveEx(true)
            end
        end

        for _, effect in ipairs(model.UiEquipEffect or {}) do
            if not XTool.UObjIsNil(effect) and effect.gameObject.activeSelf then
                effect.gameObject:SetActiveEx(false)
                effect.gameObject:SetActiveEx(true)
            end
        end
    end, nil, false, false)
    --playRoleAnimation:SetIsNotRemoveFinishCallback(true)
    --playRoleAnimation:SetFinishedCallback(function()
    --    for _, effect in ipairs(effectList or {}) do
    --        if not XTool.UObjIsNil(effect) and effect.gameObject.activeSelf then
    --            effect.gameObject:SetActiveEx(false)
    --            effect.gameObject:SetActiveEx(true)
    --        end
    --    end
    --end)
end

function XUiPanelRoleModel:SetCurrentUiEffectActive(effectList, isActive)
    if XTool.IsTableEmpty(effectList) then
        return
    end
    for _, effect in ipairs(effectList or {}) do
        if not XTool.UObjIsNil(effect) then
            effect.gameObject:SetActiveEx(isActive)
        end
    end
end

function XUiPanelRoleModel:ClearUiEffectList(effectList)
    for _, effect in ipairs(effectList or {}) do
        if not XTool.UObjIsNil(effect) then
            XUiHelper.Destroy(effect)
        end
    end
    return {}
end

function XUiPanelRoleModel:GetValidEffect(effectList)
    local list = {}
    for _, effect in ipairs(effectList or {}) do
        if not XTool.UObjIsNil(effect) then
            table.insert(list, effect)
        end
    end
    return list
end

--endregion------------------------------------加载Ui角色动作特效end---------------------------
--==============================--
--desc: 更新角色模型
--@characterId: 角色id
--@targetPanelRole: 目标面板
--@targetUiName: 目标ui名
--==============================--
function XUiPanelRoleModel:UpdateCharacterModel(
characterId,
targetPanelRole,
targetUiName,
cb,
weaponCb,
fashionId,
growUpLevel,
hideEffect,
isShowDefaultWeapon,
isNotSelf,
weaponId,
colorId)
    self.StandAnimaShowWeaponList = {}
    self.StandAnimaShowWeaponAnimatorList = {}
    
    local weaponFashionId = weaponId

    if XRobotManager.CheckIsRobotId(characterId) then
        local robotId = characterId
        characterId = XRobotManager.GetRobotTemplate(characterId).CharacterId
        weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    end

    local resourcesId
    if XTool.IsNumberValid(fashionId) then
         -- 分包检查：若涂装未下载则使用默认涂装
        local validFashionId = self:_GetValidFashionId(fashionId, characterId)
        self.NowFashionId = validFashionId
        resourcesId = XMVCA.XFashion:GetOwnFashionColorResourcesId(validFashionId, colorId)
    else
        resourcesId = XDataCenter.FashionManager.GetFashionResourceIdByCharId(characterId, isNotSelf)
        self.NowFashionId = XDataCenter.FashionManager.GetFashionIdByResId(resourcesId)
        -- 分包检查：若涂装未下载则使用默认涂装
        local validFashionId = self:_GetValidFashionId(self.NowFashionId, characterId)
        if validFashionId ~= self.NowFashionId then
            resourcesId = XDataCenter.FashionManager.GetResourcesId(validFashionId)
            self.NowFashionId = validFashionId
        end
    end

    local modelName
    if resourcesId then
        modelName = XMVCA.XCharacter:GetCharResModel(resourcesId)
    else
        modelName = self:GetModelName(characterId)
    end
    if not modelName then
        return
    end
    
    self.IsStandAnimaShowWeapon = XMVCA.XEquip:CheckHasLoadEquipBySignboard(characterId, self.NowFashionId)
    self:SetFashionUiStandCueIdByFashionId(self.NowFashionId)
    -- 设置当前加载的角色Id（设置相机参数时使用）
    self.CurCharacterId = characterId
    
    self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, 
            function(model)
                if not self.HideWeapon then
                    self:UpdateCharacterWeaponModels(characterId, modelName, weaponCb, hideEffect, nil, weaponFashionId, isShowDefaultWeapon) --- todo  cur equip
                end

                if self.IsStandAnimaShowWeapon and self.HideWeapon then
                    local equipUsage = XMVCA.XEquip:GetEquipAnimControllerBySignboard(characterId, self.NowFashionId)
                    local newCb = function(model)
                        self.StandAnimaShowWeaponList[#self.StandAnimaShowWeaponList + 1] = model
                        local weaponAnimator = model:GetComponent("Animator")
                        if weaponAnimator then
                            self.StandAnimaShowWeaponAnimatorList[#self.StandAnimaShowWeaponAnimatorList + 1] = weaponAnimator
                        end
                        
                        if weaponCb then
                            weaponCb(model)
                        end
                    end
                    
                    self:UpdateCharacterWeaponModels(characterId, modelName, newCb, hideEffect, nil, weaponFashionId, isShowDefaultWeapon, equipUsage)
                end
                
                if not hideEffect then
                    self:UpdateCharacterLiberationLevelEffect(modelName, characterId, growUpLevel, fashionId)
                end

                if cb then
                    cb(model)
                end
                
                if self.FixLight then
                    CS.XGraphicManager.FixUICharacterLightDir(model.gameObject)
                end
    end)
    local actionId = self:GetPlayingStateName(AnimeLayer.Body)
    self:LoadCharacterUiEffect(tonumber(characterId), actionId, isNotSelf, weaponFashionId, isShowDefaultWeapon)
end

---将callback保存在列表中，在执行回调时遍历callback列表
---@param model UnityEngine.GameObject 角色模型
---@param callback function 回调函数
---@param disableCallback function 模型销毁的回调
---@param isOnce boolean 是否只执行一次
---@param isInstantExecute boolean 是否立即执行
function XUiPanelRoleModel:SetUiStandAnimaFinishCallback(model, callback, disableCallback, isOnce, isInstantExecute)
    isOnce = isOnce or false
    isInstantExecute = isInstantExecute or false
    self.UiStandCallBack[#self.UiStandCallBack + 1] = { Callback = callback, IsOnce = isOnce }

    local playAnima = model.gameObject:GetComponent(typeof(CS.XPlayRoleAnimation))

    if not playAnima then
        return
    end

    if isInstantExecute then
        callback()
    end
    
    playAnima:SetIsNotRemoveFinishCallback(true)
    playAnima:SetFinishedCallback(function()
        for i = #self.UiStandCallBack, 1, -1  do
            local funcData = self.UiStandCallBack[i]
            local callbackFunc = funcData.Callback
            local isOnlyOnce = funcData.IsOnce

            callbackFunc()

            if isOnlyOnce then
                table.remove(self.UiStandCallBack, i)
            end
        end 
    end)
    if disableCallback ~= nil then
        playAnima:SetDisableCallback(disableCallback)
    end
end

-- 设置当前角色Id（设置相机参数时使用）
function XUiPanelRoleModel:SetCurCharacterId(id)
    self.CurCharacterId = id
end

--==============================--
--desc: 在查看其他玩家信息时，更新角色模型
--==============================--
---@param weapon XEquip
function XUiPanelRoleModel:UpdateCharacterModelOther(
character,
weapon,
weaponFashionId,
targetPanelRole,
targetUiName,
cb)
    local characterId = character.Id
    if XRobotManager.CheckIsRobotId(characterId) then
        local robotId = characterId
        characterId = XRobotManager.GetRobotTemplate(characterId).CharacterId
        weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    end

    local template = XDataCenter.FashionManager.GetFashionTemplate(character.FashionId)
    local resourcesId = template.ResourcesId

    local modelName
    if resourcesId then
        modelName = XMVCA.XCharacter:GetCharResModel(resourcesId)
    else
        local quality
        if character then
            quality = character.Quality
        end

        modelName = XMVCA.XCharacter:GetCharModel(characterId, quality)
    end
    if not modelName then
        return
    end
    self:UpdateRoleModel(
    modelName,
    targetPanelRole,
    targetUiName,
    function(model)
        if not self.HideWeapon then
            self:UpdateCharacterWeaponModelsOther(character, weapon, weaponFashionId, modelName)
        end

        local fashionId = character.FashionId or XMVCA.XCharacter:GetCharacterTemplate(character.Id).DefaultNpcFashtionId
        self:UpdateCharacterLiberationLevelEffect(modelName, characterId, character.LiberateLv, fashionId)

        if cb then
            cb(model)
        end

        if self.FixLight then
            CS.XGraphicManager.FixUICharacterLightDir(model.gameObject)
        end
    end
    )
    self:LoadCharacterUiEffectOther(character, nil, weapon, weaponFashionId)
end

---@param weapon XEquip
function XUiPanelRoleModel:LoadCharacterUiEffectOther(character, actionId, weapon, weaponFashionId)
    if not character then
        return
    end
    local fashionId = character.FashionId or XMVCA.XCharacter:GetCharacterTemplate(character.Id).DefaultNpcFashtionId
    -- 分包检查：若涂装未下载则使用默认涂装
    fashionId = self:_GetValidFashionId(fashionId, character.Id)
    local equipModelIdList = XMVCA.XEquip:GetWeaponEquipModelIdListByTemplateId(weapon.TemplateId, weaponFashionId)
    local id, rootName, effectPath = XCharacterUiEffectConfig.GetEffectInfo(character.Id, fashionId, actionId, equipModelIdList)
    local model = self.RoleModelPool[self.CurRoleName]
    if not model then return end
    if not model.CharacterId then
        model.CharacterId = character.Id
    end
    self:SetCurrentUiEffectActive(model.UiEffect, false)
    self:SetCurrentUiEffectActive(model.UiEquipEffect, false)
    if not model.NotUiStand1 then
        local playRoleAnimation = model.Model.gameObject:GetComponent("XPlayRoleAnimation")
        if playRoleAnimation then
            local defaultAnimeName = playRoleAnimation.DefaultClip
            model.NotUiStand1 = defaultAnimeName ~= "UiStand1"
        else
            model.NotUiStand1 = true
            return
        end
    end
    if not actionId and model.NotUiStand1 then
        return
    end
    if not actionId then
        model.UiDefaultId = id
    end
    self:LoadCharacterUiEquipEffectOther(model, weapon, fashionId, actionId, weaponFashionId)
    self:PlayCharacterUiEffect(model, id, rootName, effectPath)
end

--==============================--
--desc: 更新机器人角色模型
--==============================--
function XUiPanelRoleModel:UpdateRobotModel(robotId, characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController
    , targetPanelRole, targetUiName)
    local resourcesId
    local nowFashionId
    if fashionId then
         -- 分包检查：若涂装未下载则使用默认涂装
        local validFashionId = self:_GetValidFashionId(fashionId, characterId)
        nowFashionId = validFashionId
        resourcesId = XMVCA.XFashion:GetOwnFashionColorResourcesId(validFashionId)
    else
        resourcesId = XDataCenter.FashionManager.GetFashionResourceIdByCharId(characterId)
        nowFashionId = XDataCenter.FashionManager.GetFashionIdByResId(resourcesId)
    end

    local modelName
    if resourcesId then
        modelName = XMVCA.XCharacter:GetCharResModel(resourcesId)
    else
        modelName = self:GetModelName(characterId)
    end
    if not modelName then
        return
    end
    targetUiName = targetUiName or self.RefName
    local weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    
    self:SetFashionUiStandCueIdByFashionId(nowFashionId)
    self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
        if not self.HideWeapon then
            self:UpdateCharacterWeaponModels(characterId, modelName, weaponCb, true, equipTemplateId, weaponFashionId)
        end
        if modelCb then
            modelCb(model)
        end
        if self.FixLight then
            CS.XGraphicManager.FixUICharacterLightDir(model.gameObject)
        end
    end, nil, needDisplayController)
    
    self:LoadResCharacterUiEffect(characterId, nowFashionId, weaponFashionId, nil, equipTemplateId)
end

--==============================--
--desc: 更新机器人角色模型 可以根据UseFashion使用角色涂装和角色武器涂装
--==============================--
function XUiPanelRoleModel:UpdateRobotModelNew(robotId, characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController, targetPanelRole, targetUiName)
    local weaponFashionId
    local isOwn = XMVCA.XCharacter:IsOwnCharacter(characterId)
    if XRobotManager.CheckUseFashion(robotId) and isOwn then
        local character = XMVCA.XCharacter:GetCharacter(characterId)
        local robot2CharViewModel = character:GetCharacterViewModel()
        local rawFashionId = robot2CharViewModel:GetFashionId()
        -- 分包检查：若涂装未下载则使用默认涂装
        fashionId = self:_GetValidFashionId(rawFashionId, characterId)
        weaponFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    else
        weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    end

    self:UpdateRobotModelPublicNew(weaponFashionId,characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController, targetPanelRole, targetUiName)
end

--==============================--
--desc: 更新机器人角色模型 可以手动设置角色武器。武器涂装以机器人优先
--==============================--
function XUiPanelRoleModel:UpdateRobotModelWithWeapon(robotId, characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController, targetPanelRole, targetUiName)
    local weaponFashionId
    local isOwn = XMVCA.XCharacter:IsOwnCharacter(characterId)
    if XRobotManager.CheckUseFashion(robotId) and isOwn then
        local character = XMVCA.XCharacter:GetCharacter(characterId)
        local robot2CharViewModel = character:GetCharacterViewModel()
        local rawFashionId = robot2CharViewModel:GetFashionId()
        -- 分包检查：若涂装未下载则使用默认涂装
        fashionId = self:_GetValidFashionId(rawFashionId, characterId)
        weaponFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    else
        weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    end

    if not XTool.IsNumberValid(weaponFashionId) then
        weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    end
    
    self:UpdateRobotModelPublicNew(weaponFashionId,characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController, targetPanelRole, targetUiName)
end

--==============================--
--desc: 更新机器人角色模型 模型新显示逻辑的公共部分
--==============================--
function XUiPanelRoleModel:UpdateRobotModelPublicNew(weaponFashionId,characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController, targetPanelRole, targetUiName)
    local resourcesId
    if fashionId then
        -- 分包检查：若涂装未下载则使用默认涂装
        local validFashionId = self:_GetValidFashionId(fashionId, characterId)
        resourcesId = XDataCenter.FashionManager.GetResourcesId(validFashionId)
        fashionId = validFashionId  -- 更新fashionId供后续使用
    else
        resourcesId = XDataCenter.FashionManager.GetFashionResourceIdByCharId(characterId)
    end

    local modelName
    if resourcesId then
        modelName = XMVCA.XCharacter:GetCharResModel(resourcesId)
    else
        modelName = self:GetModelName(characterId)
    end
    if not modelName then
        return
    end
    self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
        if not self.HideWeapon then
            self:UpdateCharacterWeaponModels(characterId, modelName, weaponCb, true, equipTemplateId, weaponFashionId)
        end
        if modelCb then
            modelCb(model)
        end
        if self.FixLight then
            CS.XGraphicManager.FixUICharacterLightDir(model.gameObject)
        end
    end, nil, needDisplayController)

    self:LoadResCharacterUiEffect(characterId, fashionId, weaponFashionId, nil, equipTemplateId)
end

function XUiPanelRoleModel:UpdateCharacterResModel(resId, characterId, targetUiName, cb, growUpLevel, weaponFashionId)
    local fashionId = XDataCenter.FashionManager.GetFashionIdByResId(resId)

    -- 分包检查：若涂装未下载则使用默认涂装
    local validFashionId = self:_GetValidFashionId(fashionId, characterId)
    local validResId = resId
    if validFashionId ~= fashionId then
        -- 涂装未下载，使用默认涂装的resId
        validResId = XDataCenter.FashionManager.GetResourcesId(validFashionId)
        fashionId = validFashionId
    end

    local modelName = XMVCA.XCharacter:GetCharResModel(validResId)
    
    if modelName then
        self:SetFashionUiStandCueIdByFashionId(fashionId)
        self:UpdateRoleModel(modelName, nil, targetUiName, function(model)
            if not self.HideWeapon then
                self:UpdateCharacterWeaponModels(characterId, modelName, nil, nil, nil, weaponFashionId)
            end
            
            self:UpdateCharacterLiberationLevelEffect(modelName, characterId, growUpLevel, fashionId)

            if cb then
                cb(model)
            end
        end
        )
    end
    if fashionId then
        self:LoadResCharacterUiEffect(characterId, fashionId, weaponFashionId)
    end
end

function XUiPanelRoleModel:UpdateCharacterModelByModelId(
modelId,
characterId,
targetPanelRole,
targetUiName,
cb,
growUpLevel,
showDefaultFx)
    if not modelId then
        return
    end
    
    self:UpdateRoleModel(modelId, targetPanelRole, targetUiName, function(model)
        if not self.HideWeapon and XTool.IsNumberValid(characterId) then
            self:UpdateCharacterWeaponModels(characterId, modelId)
        end

        if XTool.IsNumberValid(characterId) then
            self:UpdateCharacterLiberationLevelEffect(modelId, characterId, growUpLevel, nil, showDefaultFx)
        end

        if cb then
            cb(model)
        end
    end)
    
    if XTool.IsNumberValid(characterId) then
        local defaultFashionId = XMVCA.XCharacter:GetCharacterTemplate(characterId).DefaultNpcFashtionId
        local fashionId
        if growUpLevel == 2 then --growUpLevel 2为第一套解放衣服 3，4为第二套解放衣服，解放的时装Id跟默认时装Id紧挨且按顺序+1
            fashionId = defaultFashionId + 1
        elseif growUpLevel >= 3 then
            fashionId = defaultFashionId + 2
        end

        local allFashionConfig = XFashionConfigs.GetFashionTemplates()
        if not fashionId or not allFashionConfig[fashionId] then
            fashionId = defaultFashionId
        end
        if fashionId then
            self:LoadResCharacterUiEffect(characterId, fashionId)
        end
    end
end

function XUiPanelRoleModel:UpdateBossModel(modelName, targetUiName, targetPanelRole, cb, isReLoad)
    if modelName then
        self:UpdateRoleModel(
        modelName,
        targetPanelRole,
        targetUiName,
        function(model)
            if cb then
                cb(model)
            end
        end,
        true
        )
    end
end

function XUiPanelRoleModel:UpdateArchiveMonsterModel(modelName, targetUiName, targetPanelRole, cb)
    if modelName then
        self:UpdateRoleModel(
        modelName,
        targetPanelRole,
        targetUiName,
        function(model)
            if cb then
                cb(model)
            end
        end,
        true
        )
    end
end

local DoPartnerModelControl = function(modelName, model) -- 加载伙伴模型时同时加载“模型节点控制”配置
    local modelControlList = XPartnerConfigs.GetPartnerModelControlsByModel(modelName)
    if modelControlList then
        for nodeName, modelControl in pairs(modelControlList) do
            local parts
            if nodeName == XPartnerConfigs.DefaultNodeName then
                parts = model.transform
            else
                parts = model.gameObject:FindTransform(nodeName)
            end
            if not XTool.UObjIsNil(parts) then
                if modelControl.IsHide and modelControl.IsHide == 1 then
                    parts.gameObject:SetActiveEx(false)
                end
                if modelControl.Effect and not string.IsNilOrEmpty(modelControl.Effect) then
                    local effect = parts.gameObject:LoadPrefab(modelControl.Effect, false)
                    if effect then
                        effect.gameObject:SetActiveEx(true)
                    end
                end
            else
                XLog.Error("NodeName Is Wrong :" .. nodeName)
            end
        end
    end
end

function XUiPanelRoleModel:UpdatePartnerModel(
modelName,
targetUiName,
targetPanelRole,
cb,
isReLoad,
needController,
IsReLoadController)
    if modelName then
        self:UpdateRoleModel(
        modelName,
        targetPanelRole,
        targetUiName,
        function(model)
            if cb then
                cb(model)
            end
            self:LoadPartnerUiEffect(modelName, XPartnerConfigs.EffectParentName.ModelLoopEffect, false, false)
            self:LoadPartnerUiEffect(modelName, XPartnerConfigs.EffectParentName.ControlByAnimationEvent, false, false)
            --DoPartnerModelControl(modelName, model)
        end,
        isReLoad,
        needController,
        IsReLoadController
        )
    end
end

function XUiPanelRoleModel:UpdateSCBattleShowModel(
modelName,
weaponIdList,
targetUiName,
targetPanelRole,
cb,
isReLoad,
needController,
IsReLoadController)
    if modelName then
        self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model) 
            if cb then
                cb(model)
            end
            XModelManager.LoadRoleWeaponModel(model, weaponIdList, 
                    self.RefName, nil, false, self.GameObject, modelName)
        end, isReLoad, false, IsReLoadController, needController)
    end
end

function XUiPanelRoleModel:UpdateCharacterModelByFightNpcData(fightNpcData, cb, isCute, needDisplayController, customizeWeaponData, isSelfPlayer)
    local char = fightNpcData.Character
    if char then
        if isSelfPlayer then
            local charId = char.Id
            local tempChar = XMVCA.XCharacter:GetCharacter(charId)
            if tempChar then
                char = tempChar
            end
        end

        local modelName
        -- 分包检查：若涂装未下载则使用默认涂装
        local fashionId = self:_GetValidFashionId(char.FashionId, char.Id)
        if isCute then
            modelName = XCharacterCuteConfig.GetCuteModelModelName(char.Id)
        elseif fashionId then
            local fashion = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
            modelName = XMVCA.XCharacter:GetCharResModel(fashion.ResourcesId)
        else
            -- modelName = XMVCA.XCharacter:GetCharModel(char.Id, char.Quality)
            modelName = self:GetModelName(char.Id)
        end

        if modelName then
            self:SetFashionUiStandCueIdByFashionId(fashionId)
            self:UpdateRoleModel(modelName, nil, nil, function(model)
                self:UpdateEquipsModelsByFightNpcData(model, fightNpcData, modelName)
                self:UpdateCharacterLiberationLevelEffect(modelName, char.Id, char.LiberateLv, fashionId)
                if cb then
                    cb(model)
                end
                if isCute then
                    self:CloseRootMotion(model)
                end
            end,nil, needDisplayController)
        end
        
        if isCute then
            self:LoadCharacterCuteUiEffect(char.Id)
        elseif customizeWeaponData then
            self:LoadResCharacterUiEffect(char.Id, fashionId, fightNpcData.WeaponFashionId, nil, fightNpcData.Equips[1].TemplateId)
        else
            self:LoadResCharacterUiEffect(char.Id, fashionId, fightNpcData.WeaponFashionId, nil, fightNpcData.Equips[1].TemplateId)
        end
    end
end

function XUiPanelRoleModel:UpdateEquipsModelsByFightNpcData(charModel, fightNpcData, modelName)
    local weaponModelList = {}
    local tempWeaponCb = function(weaponModel)
        weaponModelList[#weaponModelList + 1] = weaponModel
    end
    XModelManager.LoadRoleWeaponModelByFight(charModel, fightNpcData, self.RefName, self.GameObject, modelName, tempWeaponCb)
    self:WeaponAnimationSync(weaponModelList, modelName)
end

--==============================--
--desc: 更新角色武器模型
--@characterId: 角色id
--==============================--
function XUiPanelRoleModel:UpdateCharacterWeaponModels(
characterId,
modelName,
weaponCb,
hideEffect,
equipTemplateId,
weaponFashionId,
isShowDefaultWeapon,
equipUsage)
    local equipModelIdList = {}
    
    if equipTemplateId then
        local equip = { TemplateId = equipTemplateId }
        equipModelIdList = XMVCA.XEquip:GetWeaponEquipModelIdListByEquip(equip, weaponFashionId)
    else
        equipModelIdList = XMVCA.XEquip:GetEquipModelIdListByCharacterId(characterId, isShowDefaultWeapon, weaponFashionId)
    end

    if not equipModelIdList or not next(equipModelIdList) then
        return
    end

    if not modelName then
        modelName = self:GetModelName(characterId)
    end

    local roleModel = self.RoleModelPool[modelName]
    if not roleModel then
        return
    end

    local weaponModelList = {}
    local tempWeaponCb = function(weaponModel)
        weaponModelList[#weaponModelList + 1] = weaponModel
        if weaponCb then
            weaponCb(weaponModel)
        end
    end

    XModelManager.LoadRoleWeaponModel(
    roleModel.Model,
    equipModelIdList,
    self.RefName,
    tempWeaponCb,
    hideEffect,
    self.GameObject,
    modelName,
    equipUsage        
    )

    self:WeaponAnimationSync(weaponModelList, modelName)
end

--==============================--
--desc: 查看其他玩家角色信息时，更新角色武器模型
--==============================--
function XUiPanelRoleModel:UpdateCharacterWeaponModelsOther(
characterId,
equip,
weaponFashionId,
modelName,
weaponCb,
hideEffect)
    local equipModelIdList = {}
    if weaponFashionId and weaponFashionId ~= 0 then
        equipModelIdList = XMVCA.XEquip:GetWeaponEquipModelIdListByEquip(equip, weaponFashionId)
    else
        equipModelIdList = XMVCA.XEquip:GetWeaponEquipModelIdListByEquip(equip)
    end

    if not equipModelIdList or not next(equipModelIdList) then
        return
    end

    if not modelName then
        modelName = self:GetModelName(characterId)
    end

    local roleModel = self.RoleModelPool[modelName]
    if not roleModel then
        return
    end
    XModelManager.LoadRoleWeaponModel(
    roleModel.Model,
    equipModelIdList,
    self.RefName,
    weaponCb,
    hideEffect,
    self.GameObject,
    modelName
    )
end

---=================================================
--- 在当前播放中的动画播放完后执行回调
--- 如果动画被打断或是停止都会调用回调
---@overload fun(callBack:function)
---@param callBack function
---=================================================
local CheckAnimeFinish = function(animator, behaviour, animaName, callBack, layer)
    if XTool.UObjIsNil(animator) then
        return
    end
    local animatorInfo = animator:GetCurrentAnimatorStateInfo(layer)
    if (animatorInfo:IsName(animaName) and animatorInfo.normalizedTime >= 1) or not animatorInfo:IsName(animaName) then --normalizedTime的值为0~1，0为开始，1为结束。
        if callBack then
            callBack()
        end
        behaviour.enabled = false
        behaviour.LuaUpdate = nil
    end
end

--- 针对动画融合的版本
---@param roleModel XUiPanelRoleModel
local CheckAnimeCrossFinish = function(animator, behaviour, animaName, roleModel, layer)
    if XTool.UObjIsNil(animator) then
        return false
    end

    -- 当前的动画
    local curStateInfo = animator:GetCurrentAnimatorStateInfo(layer)
    -- 切换的动画
    local nextStateInfo = animator:GetNextAnimatorStateInfo(layer)
    
    local isFinish = false
    
    -- 先判断是否在切换动画
    if animator:IsInTransition(layer) then
        -- 正在切换动画的情况
        -- 情况1：相同动画重新播时，不当做结束（因为回调相同冲突，使用最新的回调即可）
        -- 情况2：当前动画不是目标动画，下一个动画是目标动画时，不算结束（动画才刚开始，且处于动画融合阶段，“当前”信息未及时切换）
        -- 情况3：当前动画是目标动画，下一个动画不是目标动画时，算结束
        if curStateInfo:IsName(animaName) and not nextStateInfo:IsName(animaName) then
            isFinish = true
        end
    else
        -- 未切换动画时，当前动画已不是目标动画，或已完成一轮播放，则结束  
        if (curStateInfo:IsName(animaName) and curStateInfo.normalizedTime >= 1) or not curStateInfo:IsName(animaName) then
            isFinish = true
        end
    end
    
    if isFinish then --normalizedTime的值为0~1，0为开始，1为结束。
        roleModel:DoAnimaCrossFinishCallBack(true, true)
        behaviour.enabled = false
        behaviour.LuaUpdate = nil
        
        return true
    end
    
    return false
end

local AddPlayingAnimCallBack = function(obj, animator, animaName, callBack, layer)
    if XTool.UObjIsNil(animator) then   -- 防止定时器GameObject丢失
        return
    end
    local animatorInfo = animator:GetCurrentAnimatorStateInfo(layer)

    if not animatorInfo:IsName(animaName) or animatorInfo.normalizedTime >= 1 then --normalizedTime的值，0为开始，大于1为结束。
        return
    end

    local behaviour = obj.Transform:GetComponent(typeof(CS.XLuaBehaviour))
    if not behaviour then
        behaviour = obj.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    else
        behaviour.enabled = true
    end

    behaviour.LuaUpdate = function()
        CheckAnimeFinish(animator, behaviour, animaName, callBack, layer)
    end
end

--- 动画融合需要特殊判断
---@param roleModel XUiPanelRoleModel
local AddPlayingAnimCrossCallBack = function(roleModel, animator, animaName, layer)
    if XTool.UObjIsNil(animator) then   -- 防止定时器GameObject丢失
        return
    end
    
    -- 当前的动画
    local curStateInfo = animator:GetCurrentAnimatorStateInfo(layer)

    -- 切换的动画
    local nextStateInfo = animator:GetNextAnimatorStateInfo(layer)
    
    -- 可以通过并注册监听的条件
    -- 情况1：当前动画就是目标动画，且未播放完，且未发生动画切换
    -- 情况2：下一个动画是目标动画，且正在发生动画切换
    local isValid = false
    
    if curStateInfo:IsName(animaName) then
        if curStateInfo.normalizedTime < 1 and not animator:IsInTransition(layer) then
            isValid = true
        end
    end

    if not isValid then
        if nextStateInfo and nextStateInfo:IsName(animaName) and animator:IsInTransition(layer) then
            isValid = true
        end
    end
    
    if not isValid then --normalizedTime的值，0为开始，大于1为结束。
        return
    end

    local behaviour = roleModel.Transform:GetComponent(typeof(CS.XLuaBehaviour))
    if not behaviour then
        behaviour = roleModel.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    else
        behaviour.enabled = true
    end
    
    behaviour.LuaUpdate = function()
        CheckAnimeCrossFinish(animator, behaviour, animaName, roleModel, layer)
    end
end

--- 立刻清除状态机检查回调
local ClearPlayingAnimCrossCallBack = function(roleModel)
    local behaviour = roleModel.Transform:GetComponent(typeof(CS.XLuaBehaviour))
    if not behaviour then
        behaviour = roleModel.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    end

    behaviour.LuaUpdate = nil
end

---根据模型名和动作名解除武器绑定角色同名骨骼
function XUiPanelRoleModel:UnBindWeaponBone(actionId)
    if string.IsNilOrEmpty(actionId) then
        return
    end

    if self.CurRoleName then
        local model = self:GetModelInfoByName(self.CurRoleName)

        if model and model.Model then
            XModelManager.WaeponUnBindModelBone(self.CurRoleName, model.Model, actionId)
        end
    end
end

---=================================================
--- 播放'AnimaName'动画，‘fromBegin’决定动画是否需要调整到从0开始播放，默认值为false
---@overload fun(AnimaName:string)
---@param AnimaName string
---@param fromBegin boolean
---@param callBack function 成功之后的回调
---@param errorCb function 失败之后的回调
---@param layer number 状态机层级
---=================================================
function XUiPanelRoleModel:PlayAnima(AnimaName, fromBegin, callBack, errorCb, layer)
    local animatorlaye = layer or 0
    local IsCanPlay, animator = self:CheckAnimaCanPlay(AnimaName)
    local delay = 1

    if IsCanPlay and animator then
        if fromBegin then
            animator:Play(AnimaName, animatorlaye, 0)
        else
            animator:Play(AnimaName, animatorlaye)
        end

        self.AnimaPlayedCallBackList = {}
        --根据当前角色动画判断躯干显隐
        local hideNodeFunc = self:HideOrShowModelWithAction(AnimaName)
        local loadWeaponFunc = self:PlayWeaponAnima(AnimaName)
        if callBack then
            self:AddPlayedAnimCallBack(callBack)
        end

        local callBackList = self.AnimaPlayedCallBackList
        self:UnBindWeaponBone(AnimaName)
        XScheduleManager.ScheduleOnce(function()
            if loadWeaponFunc then
                loadWeaponFunc()
            end
            if hideNodeFunc then
                hideNodeFunc()
            end
            if callBackList and #callBackList ~= 0 then
                AddPlayingAnimCallBack(self, animator, AnimaName, function()
                    for i = 1, #callBackList do
                        if callBackList[i] then
                            callBackList[i]()
                        end
                    end
                end, animatorlaye)
            end
        end, delay)
        
        if self._AnimationEvent then
            self._AnimationEvent:StopEffectThisAction(self)
        end
    else
        if errorCb then
            errorCb()
        end
    end
    return IsCanPlay
end

---=================================================
--- 播放'AnimaName'动画，‘fromBegin’决定动画是否需要调整到从0开始播放，默认值为false
---@overload fun(AnimaName:string)
---@param AnimaName string
---@param fromBegin boolean
---@param callBack function 成功之后的回调
---@param errorCb function 失败之后的回调
---@param layer number 状态机层级
---=================================================
function XUiPanelRoleModel:PlayAnimaCross(AnimaName, fromBegin, callBack, errorCb, layer)
    local animatorlaye = layer or 0
    local IsCanPlay, animator = self:CheckAnimaCanPlay(AnimaName)
    
    if IsCanPlay and animator then
        -- 如果是直接切动画，需要立刻结束上一个动画的回调
        self:DoAnimaCrossFinishCallBack()

        self._AnimaCrossTimes = self._AnimaCrossTimes + 1
        
        local delay = 0.25
        
        if fromBegin then
            animator:CrossFadeInFixedTime(AnimaName, delay, animatorlaye, 0)
        else
            animator:CrossFadeInFixedTime(AnimaName, delay, animatorlaye)
        end

        if not XTool.IsTableEmpty(self.StandAnimaShowWeaponAnimatorList) then
            local signBoradConfigId = XMVCA.XUiMain:GetLastPlaySignBoardCfgId()
            if XTool.IsNumberValid(signBoradConfigId) then
                for k, weaponAnimator in pairs(self.StandAnimaShowWeaponAnimatorList) do
                    if not XTool.UObjIsNil(weaponAnimator.runtimeAnimatorController) then
                        weaponAnimator:SetInteger("UiSignBoardConfigId", signBoradConfigId)
                    end
                end
            end
        end
        
        self.AnimaPlayedCallBackList = {}
        
        --根据当前角色动画判断躯干显隐
        local hideNodeFunc = self:HideOrShowModelWithAction(AnimaName)
        local loadWeaponFunc = self:PlayWeaponAnima(AnimaName)
        if callBack then
            self:AddPlayedAnimCallBack(callBack)
        end

        self._AnimaCrossFinishCbList = self.AnimaPlayedCallBackList
        self._CurAnimaName = AnimaName
        
        self:UnBindWeaponBone(AnimaName)
        
        -- 动画切换状态下一帧就会刷新，回调注册需尽快执行
        if self._AnimaCbAddTimeId then
            XScheduleManager.UnSchedule(self._AnimaCbAddTimeId)
            self._AnimaCbAddTimeId = nil
        end
        
        if self._AnimaCrossFinishCbList and #self._AnimaCrossFinishCbList ~= 0 then
            self._AnimaCbAddTimeId = XScheduleManager.ScheduleNextFrame(function()
                self._AnimaCbAddTimeId = nil
                AddPlayingAnimCrossCallBack(self, animator, AnimaName, animatorlaye)
            end)
        end
        
        -- 加载相关回调照旧延时执行，但追加打断检查
        self:DoAnimaCrossCallBackTimer()
        
        local animaCrossTimes = self._AnimaCrossTimes
        
        self._AnimaCrossCbTimeId =  XScheduleManager.ScheduleOnce(function()
            self._AnimaCrossCbTimeId = nil

            if animaCrossTimes == self._AnimaCrossTimes then
                if loadWeaponFunc then
                    loadWeaponFunc()
                end
                if hideNodeFunc then
                    hideNodeFunc()
                end
            end
        end, delay * XScheduleManager.SECOND + 1)
        
    else
        if errorCb then
            errorCb()
        end
    end
    return IsCanPlay
end

-- 处理融合动画的回调，目前逻辑仅针对融合动画调整，因此单独方法及字段
function XUiPanelRoleModel:DoAnimaCrossFinishCallBack(sync, ignoreBehaviorClear)
    if not XTool.IsTableEmpty(self._AnimaCrossFinishCbList) then
        if sync or XCharacterUiEffectConfig.CheckCharaAnimaIsSyncCallBack(self.CurRoleName, self._CurAnimaName) then
            for i, cb in pairs(self._AnimaCrossFinishCbList) do
                cb()
            end

            self._AnimaCrossFinishCbList = nil
            self._CurAnimaName = nil

            if not ignoreBehaviorClear then
                ClearPlayingAnimCrossCallBack(self)
            end
        end
    end

    self:DoAnimaCrossCallBackTimer()
end

-- 处理融合动画播放的延迟回调
function XUiPanelRoleModel:DoAnimaCrossCallBackTimer()
    if self._AnimaCrossCbTimeId then
        XScheduleManager.UnSchedule(self._AnimaCrossCbTimeId)
        self._AnimaCrossCbTimeId = nil
    end
end

function XUiPanelRoleModel:HideOrShowModelWithAction(animaName)
    if not self.CurRoleName then
        return
    end
    
    local modelInfo = self.RoleModelPool[self.CurRoleName]
    if not modelInfo then
        return
    end
    
    local model = modelInfo.Model
    local modelName = self.CurRoleName
    if not model or not modelName then
        return 
    end

    local isStandAnimaHide = self.IsStandAnimaHideNode
    local isHide = XModelManager.CheckUiModelNodeActive(animaName, modelName, model)
    local playCallback = nil
    local hideNodeFunc = function()
        if isStandAnimaHide then
            XModelManager.HandleUiModelNodeActive(DefaultRoleAnimaName, modelName, model, true)
        end
        XModelManager.HandleUiModelNodeActive(animaName, modelName, model, false)
    end
    
    if isHide then
        if isStandAnimaHide then
            playCallback = function()
                RestoreModelNode(model, modelName, animaName)
                XModelManager.HandleUiModelNodeActive(DefaultRoleAnimaName, modelName, model, false)
            end
        else
            playCallback = function()
                RestoreModelNode(model, modelName, animaName)
            end
        end
    else
        if isStandAnimaHide then
            playCallback = function()
                XModelManager.HandleUiModelNodeActive(DefaultRoleAnimaName, modelName, model, false)
            end
        end
    end

    if playCallback then
        self:AddPlayedAnimCallBack(playCallback)
    end
    
    return hideNodeFunc
end

function XUiPanelRoleModel:AddPlayedAnimCallBack(callback)
    if callback then
        self.AnimaPlayedCallBackList[#self.AnimaPlayedCallBackList + 1] = callback
    end
end

function XUiPanelRoleModel:PlayWeaponAnima(actionId)
    local weaponModelList = self.StandAnimaShowWeaponList
    local isStandAnimaShowWeapon = self.IsStandAnimaShowWeapon
    local animaCallback = function()
        if weaponModelList then
            for i = 1, #weaponModelList do
                weaponModelList[i].gameObject:SetActiveEx(isStandAnimaShowWeapon)
            end
        end
    end

    if not isStandAnimaShowWeapon then
        local weaponAnimatorList = nil
        weaponModelList, weaponAnimatorList = self:LoadWeaponModelWhenPlayAnima(actionId)

        if weaponModelList then
            local needActiveControl = false
            local isShow = false

            -- 判断是否要强制控制资源的默认状态
            if XCharacterUiEffectConfig.CheckCharaAnimaWeaponLoadDefaultShow(self.CurRoleName, actionId) then
                needActiveControl = true
                isShow = true
            elseif XCharacterUiEffectConfig.CheckCharaAnimaWeaponLoadDefaultHide(self.CurRoleName, actionId) then
                needActiveControl = true
                isShow = false
            end
            
            if needActiveControl then
                for i = 1, #weaponModelList do
                    weaponModelList[i].gameObject:SetActiveEx(isShow)
                end
            end
            
            
            local callback = function()
                for i = 1, #weaponModelList do
                    weaponModelList[i].gameObject:SetActiveEx(true)
                end
            end

            self:AddPlayedAnimCallBack(animaCallback)
            return callback
        end

        if weaponAnimatorList then
            self.StandAnimaShowWeaponAnimatorList = weaponAnimatorList
        end
    end
    
    if not self:CheckHasLoadEquipWhenPlayAnima(actionId) and isStandAnimaShowWeapon then
        local callback = function()
            for i = 1, #self.StandAnimaShowWeaponList do
                self.StandAnimaShowWeaponList[i].gameObject:SetActiveEx(false)
            end
        end

        self:AddPlayedAnimCallBack(animaCallback)
        return callback
    end
end

function XUiPanelRoleModel:CheckHasLoadEquipWhenPlayAnima(actionId)
    local modelName = self.CurRoleName

    if not modelName then
        return false
    end
    
    local characterId = self.RoleModelPool[modelName].CharacterId

    if not characterId then
        return false
    end

    local fashionId = self.NowFashionId or XMVCA.XCharacter:GetShowFashionId(characterId)

    if not fashionId then
        return false
    end
    
    return XMVCA.XEquip:CheckHasLoadEquipBySignboard(characterId, fashionId, actionId)
end

function XUiPanelRoleModel:LoadWeaponModelWhenPlayAnima(actionId)
    local modelName = self.CurRoleName

    if not modelName then
        return
    end
    
    local characterId = self.RoleModelPool[modelName].CharacterId
    
    if not characterId then
        return 
    end
    
    local weaponFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    local roleModel = self.RoleModelPool[modelName].Model
    local equipModelIdList = {}
    local equipUsage = nil
    local weaponModelList = {}
    local weaponAnimatorList = {}
    local weaponCb = function(model)
        weaponModelList[#weaponModelList + 1] = model
        local weaponAnimator = model:GetComponent("Animator")
        if weaponAnimator then
            weaponAnimatorList[#weaponAnimatorList + 1] = weaponAnimator
        end
    end

    equipModelIdList = XMVCA.XEquip:GetEquipModelIdListByCharacterId(characterId, false, weaponFashionId)
    equipUsage = XMVCA.XEquip:GetEquipAnimControllerBySignboard(characterId, self.NowFashionId, actionId)
    --equipUsage = 1

    if not equipModelIdList or not next(equipModelIdList) or not roleModel or not equipUsage then
        return
    end
    
    XModelManager.LoadRoleWeaponModel(roleModel, equipModelIdList, self.RefName, weaponCb, false, self.GameObject, modelName, equipUsage)
    
    return weaponModelList, weaponAnimatorList
end

---=================================================
--- 播放身体动画（状态机层级0）
---@overload fun(AnimaName:string)
---@param AnimaName string
---@param fromBegin boolean
---@param callBack function 成功之后的回调
---@param errorCb function 失败之后的回调
---=================================================
function XUiPanelRoleModel:PlayBodyAnima(AnimaName, fromBegin, callBack, errorCb)
    self:PlayAnima(AnimaName, fromBegin, callBack, errorCb, AnimeLayer.Body)
end

---=================================================
--- 播放表情动画（状态机层级1）
---@overload fun(AnimaName:string)
---@param AnimaName string
---@param fromBegin boolean
---@param callBack function 成功之后的回调
---@param errorCb function 失败之后的回调
---=================================================
function XUiPanelRoleModel:PlayFaceAnima(AnimaName, fromBegin, callBack, errorCb)
    self:PlayAnima(AnimaName, fromBegin, callBack, errorCb, AnimeLayer.Face)
end
---=================================================
--- 检查'AnimaName'动画，是否能够播放
---@overload fun(AnimaName:string)
---@param AnimaName string
---=================================================
function XUiPanelRoleModel:CheckAnimaCanPlay(AnimaName)
    local IsCanPlay = false
    local animator
    if self.CurRoleName and self.RoleModelPool[self.CurRoleName] and self.RoleModelPool[self.CurRoleName].Model then
        animator = self.RoleModelPool[self.CurRoleName].Model:GetComponent("Animator")
        if XModelManager.CheckAnimatorAction(animator, AnimaName) then
            IsCanPlay = true
        end
    end
    return IsCanPlay, animator
end

local time
---=================================================
--- 无参数时，结束播放当前动画，恢复成站立动画
---
--- 有参数时，只有当前动画为'oriAnima'，才结束播放动画
---@overload fun()
---@param oriAnima string
---=================================================
function XUiPanelRoleModel:StopAnima(oriAnima, force)
    -- 低内存模式下模型可能已被淘汰销毁，entry 为 nil 时安全跳过
    local curEntry = self._CachePool:Get(self.CurRoleName)
    if not curEntry then
        return
    end
    if XTool.UObjIsNil(curEntry.Model) then
        local topUiName = XLuaUiManager.GetTopUiName() or ""
        XLog.Error("模型丢失：" .. self.CurRoleName .. ",栈顶UI是：" .. topUiName)
        return
    end
    ---@type UnityEngine.Animator
    local animator = curEntry.Model:GetComponent("Animator")
    local clips = animator:GetCurrentAnimatorClipInfo(0)
    local clip
    if clips and clips.Length > 0 then
        clip = clips[0].clip
    end

    -- 是否需要播放动作打断特效
    if self.PlayEffectFunc then
        self.PlayEffectFunc()
    end

    if force and clip or oriAnima == nil or (clip and clip.name == oriAnima) then
        -- 停止UI特效
        self.CurrentAnimationName = nil
        -- 立刻执行上一次动画的结束回调
        self:DoAnimaCrossFinishCallBack()
        self:SetCurrentUiEffectActive(curEntry.UiEffect, false)
        self:SetCurrentUiEffectActive(curEntry.UiEquipEffect, false)
        animator:Play(clip.name, 0, 0.999)
    end

    if not XTool.IsTableEmpty(self.StandAnimaShowWeaponAnimatorList) then
        for k, weaponAnimator in pairs(self.StandAnimaShowWeaponAnimatorList) do
            if not XTool.UObjIsNil(weaponAnimator.runtimeAnimatorController) then
                weaponAnimator:SetInteger("UiSignBoardConfigId", 0)
                weaponAnimator:SetTrigger("Interput")
            end
        end
    end
end

---@return UnityEngine.Animator
function XUiPanelRoleModel:GetAnimator()
    local model = self.RoleModelPool[self.CurRoleName]
    if not model then
        return nil
    end
    if not XTool.UObjIsNil(model.Model) then
        return model.Model:GetComponent("Animator")
    else
        return nil
    end
end

---@return UnityEngine.Animator[]
function XUiPanelRoleModel:GetUiEffectAnimators()
    local model = self.RoleModelPool[self.CurRoleName]
    if not model then
        return nil
    end
    if XTool.IsTableEmpty(model.UiEffect) then
        return nil
    end
    local animators = {}
    for _, effect in pairs(model.UiEffect) do
        if not XTool.UObjIsNil(effect) then
            local list = effect.transform:GetComponentsInChildren(typeof(CS.UnityEngine.Animator))
            for i = 0, list.Length - 1 do
                table.insert(animators, list[i])
            end
        end
    end
    return animators
end

function XUiPanelRoleModel:GetComponent(componentType)
    if self.RoleModelPool[self.CurRoleName] then
        return self.RoleModelPool[self.CurRoleName].Model:GetComponent(componentType)
    else
        return nil
    end
end

function XUiPanelRoleModel:ShowRoleModel()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(true)
    end
end

function XUiPanelRoleModel:HideRoleModel()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(false)
    end
end

function XUiPanelRoleModel:SetModelZeroPos()
    local entry = self._CachePool:Get(self.CurRoleName)
    if not entry then return end
    entry.Model.transform.localPosition = CS.UnityEngine.Vector3.zero
end

--- 获取正在播放动画名
---@param layerIndex number 状态机层级
---@return string
--------------------------
function XUiPanelRoleModel:GetPlayingStateName(layerIndex)
    local animator = self:GetAnimator()
    if XTool.UObjIsNil(animator) then
        return
    end

    if XTool.UObjIsNil(animator.runtimeAnimatorController) then
        return
    end
    
    local actionId
    local clips = animator.runtimeAnimatorController.animationClips
    local info = animator:GetCurrentAnimatorStateInfo(layerIndex)
    for i = 0, clips.Length - 1 do
        local clip = clips[i]
        if info:IsName(clip.name) then
            actionId = clip.name
            break
        end
    end
    return actionId
end

--==============================--
--desc: 更新角色解放特效
--@characterId: 角色id
--==============================--
function XUiPanelRoleModel:UpdateCharacterLiberationLevelEffect(
modelName,
characterId,
growUpLevel,
fashionId,
showDefaultFx)
    local modelInfo
    local isSpecialModel, _ = XModelManager.CheckModelIsSpecial(modelName)
    if isSpecialModel then
        if self.NewPanel then
            modelName = XModelManager.GetMinorModelId(modelName)
            modelInfo = modelName and self.NewPanel.RoleModelPool[modelName]
        else
            modelName = XModelManager.GetSpecialModelId(modelName)
            modelInfo = self.RoleModelPool[modelName]
        end
    else
        modelInfo = self.RoleModelPool[modelName]
    end
    local model = modelInfo and modelInfo.Model
    if not model then
        return
    end

    local liberationFx = modelInfo.LiberationFx

    local character = XMVCA.XCharacter:GetCharacter(characterId)
    local rootName, fxPath, aureoleId
    if showDefaultFx then
        --通过解放等级获取默认解放特效配置
        rootName, fxPath =        XMVCA.XCharacter:GetCharLiberationLevelEffectRootAndPath(characterId, growUpLevel)
    else
        -- 1.如果没有通过超解自定义手环
        --通过角色Id获取时装对应解放特效配置
        rootName, fxPath =        XMVCA.XCharacter:GetCharFashionLiberationEffectRootAndPath(characterId, growUpLevel, fashionId)
        aureoleId = character and XFashionConfigs.GetFashionCfgById(fashionId or character.FashionId).AureoleId
        fxPath = XFashionConfigs.GetAureoleEffectPathById(aureoleId)
        -- 2.如果有自定义手环
        local currLiberateAureoleId = character and character.LiberateAureoleId
        if XTool.IsNumberValid(currLiberateAureoleId) then
            fxPath = XFashionConfigs.GetAureoleEffectPathById(currLiberateAureoleId)
            liberationFx = nil -- 销毁替换之前的 刷新终解环
        end 
    end
    if not rootName or not fxPath then
        if liberationFx then
            liberationFx:SetActiveEx(false)
        end
        return
    end

    if not liberationFx then

        local rootTransform = nil
        if string.find(rootName, "/", 1, true) then
            -- 多层路径 → 使用结构匹配抽象方法
            rootTransform = XUiHelper.FindTransformByStructure(model.transform, rootName)
        else
            -- 单个点名 → 保留原 FindTransform 行为
            rootTransform = model.transform:FindTransform(rootName)
        end

        if XTool.UObjIsNil(rootTransform) then
            XLog.Error(
            "XUiPanelRoleModel:UpdateCharacterLiberationLevelEffect Error:can Not find rootTransform in this model, rootName is:" ..
            rootName
            )
            return
        end
        modelInfo.LiberationFx = rootTransform.gameObject:LoadPrefab(fxPath, false)
        modelInfo.AureoleId = aureoleId

        local proxy = self:GetRenderingProxy()
        if proxy then
            proxy:ReplaceWeaponPart(rootTransform.name, modelInfo.LiberationFx)
        end
        -- self:FixAurolePos(modelInfo.LiberationFx, characterId, modelInfo)
    else
        liberationFx:SetActiveEx(true)
    end
end

-- 给外部切换终解特效的接口
function XUiPanelRoleModel:SetLiberationEffect(modelName, rootName, aureoleId, characterId)
    if not aureoleId then
        return
    end

    local modelInfo
    local isSpecialModel, _ = XModelManager.CheckModelIsSpecial(modelName)
    if isSpecialModel then
        if self.NewPanel then
            modelName = XModelManager.GetMinorModelId(modelName)
            modelInfo = modelName and self.NewPanel.RoleModelPool[modelName]
        else
            modelName = XModelManager.GetSpecialModelId(modelName)
            modelInfo = self.RoleModelPool[modelName]
        end
    else
        modelInfo = self.RoleModelPool[modelName]
    end
    local model = modelInfo and modelInfo.Model
    local rootTransform = model.transform:FindTransform(rootName)

    local effectPath = XFashionConfigs.GetAureoleEffectPathById(aureoleId)
    modelInfo.LiberationFx = rootTransform.gameObject:LoadPrefab(effectPath, false)
    if modelInfo.LiberationFx then
        modelInfo.LiberationFx:SetActiveEx(true)
        modelInfo.AureoleId = aureoleId
        -- self:FixAurolePos(modelInfo.LiberationFx, characterId, modelInfo)
    end
end

-- 由于2.0版本 新增同一角色可佩戴不同角色的手环，需要进行位置修正
function XUiPanelRoleModel:FixAurolePos(auroeTrans, characterId, modelInfo)
    local defaultFashionId = XMVCA.XCharacter:GetCharacterTemplate(characterId).DefaultNpcFashtionId
    local aureoleId = XFashionConfigs.GetAllConfigs(XFashionConfigs.TableKey.Fashion)[defaultFashionId].AureoleId
    local aureoleConfig = aureoleId and XFashionConfigs.GetAllConfigs(XFashionConfigs.TableKey.FashionAureole)[aureoleId]

    local tempEffectGo = nil
    if modelInfo.TempEffectGo then
        tempEffectGo = modelInfo.TempEffectGo
    else
        self.aureoleConfigEffectPath = aureoleConfig.EffectPath
        tempEffectGo = auroeTrans.transform.parent:LoadPrefabEx(aureoleConfig.EffectPath)
    end
    local tempTrans = tempEffectGo.transform:GetChild(0)
    
    -- 第一子物体同步
    local targetFixTrans = auroeTrans.transform:GetChild(0)
    local tempGoPostition = tempTrans.localPosition
    local tempGoRotation = tempTrans.localEulerAngles
    local targetPos = CS.UnityEngine.Vector3(tempGoPostition.x, tempGoPostition.y, 0)
    local targetRotation = CS.UnityEngine.Vector3(tempGoRotation.x, tempGoRotation.y, tempGoRotation.z)
    targetFixTrans.localPosition = targetPos
    targetFixTrans.localEulerAngles = targetRotation

    tempEffectGo:SetActiveEx(false)
    tempEffectGo.name = "TempAuroe"
    modelInfo.TempEffectGo = tempEffectGo
end

--- func 给外部生成基于 CharacterModelNodeEffectMapping.tab 检测的特效prefab
---@param config XTableCharacterModelNodeEffectMapping
function XUiPanelRoleModel:SetCharacterModelNodeEffectMappingPrefab(config)
    local characterModel = self.RoleModelPool[self.CurRoleName]
    if not characterModel then
        return
    end
    local characerModelTransform = characterModel.Model.transform
    local targerParentNode = characerModelTransform:FindTransform(config.PrefabRootName)
    for i = 1, #config.PrefabName do
        local prefabName = config.PrefabName[i]
        local effectParentName = string.format("EffectParent{0}", i)
        if not self.NodeEffectMappingPrefabPool[effectParentName] then
            local effectParent = CS.UnityEngine.GameObject(effectParentName)
            self.NodeEffectMappingPrefabPool[effectParentName] = effectParent
            effectParent.transform:SetParent(targerParentNode)
            effectParent.transform.localPosition = CS.UnityEngine.Vector3.zero
            effectParent.transform.localRotation = CS.UnityEngine.Quaternion.identity
            effectParent.transform.localScale = CS.UnityEngine.Vector3.one
            local effectGo = effectParent:LoadPrefab(prefabName)
            if config.IsDontRotate then
                effectGo.transform:SetParent(characerModelTransform)
            end
    
            local animator = effectGo:GetComponent(typeof(CS.UnityEngine.Animator))
            if animator and config.AnimController[i] then
                animator.runtimeAnimatorController = CS.LoadHelper.LoadUiController(config.AnimController[i], animator.gameObject)
            end
        end
    end
end

function XUiPanelRoleModel:DisposeCharacterModelNodeEffectMappingPrefab()
    if not self.NodeEffectMappingPrefabPool then
        return
    end

    for k, go in pairs(self.NodeEffectMappingPrefabPool) do
        XUiHelper.Destroy(go)
        self.NodeEffectMappingPrefabPool[k] = nil
    end
end

---=================================================
--- 材质控制器相关特效需要跟模型绑定
---@param effect UnityEngine.GameObject
---=================================================
function XUiPanelRoleModel:BindEffect(effect)
    if XTool.UObjIsNil(effect) then
        return
    end

    local renderingProxy = self:GetRenderingProxy()
    if renderingProxy then
        renderingProxy:BindEffect(effect)
        effect.gameObject:SetActiveEx(false)
        effect.gameObject:SetActiveEx(true)
    end
end

function XUiPanelRoleModel:GetRenderingProxy()
    if not self.CurRoleName then
        return nil
    end

    local entry = self._CachePool:Get(self.CurRoleName)
    if not entry then
        return nil
    end

    -- RenderingProxy 存放在 entry.Payload（新结构）
    return entry.Payload and entry.Payload.RenderingProxy
end

function XUiPanelRoleModel:BindEffectByModel(model)
    if model.UiEffect then
        for i = 1, #model.UiEffect do
            self:BindEffect(model.UiEffect[i])
        end
    end
    
    if model.UiEquipEffect then
        for i = 1, #model.UiEquipEffect do
            self:BindEffect(model.UiEquipEffect[i])
        end
    end
    
end

---=================================================
--- 设置LoadEffect接口最大加载特效数量，默认最大是1
---=================================================
function XUiPanelRoleModel:SetEffectMaxCount(value)
    self.EffectMaxCount = value
end

---=================================================
--- 加载特效，可支持多次加载特效，需要提前设置EffectMaxCount
---@param effectPath string 特效路径
---@param isBindEffect boolean 材质控制器相关特效和模型绑定
---=================================================
function XUiPanelRoleModel:LoopLoadEffect(effectPath, isBindEffect)
    if not effectPath then
        return
    end
    if isBindEffect == nil then
        isBindEffect = false
    end
    if self.EffectMaxCount == nil then
        self.EffectMaxCount = 1
    end
    if self.EffectingIndex == nil then
        self.EffectingIndex = 0
    end

    local effectParentKey = self.EffectingIndex % self.EffectMaxCount
    self:LoadEffect(effectPath, effectParentKey, isBindEffect, false)
    self.EffectingIndex = self.EffectingIndex + 1
end

local CreateEffectParentName = function(name)
    return name and string.format("Customize_%s", name) or "Default_EffectParent"
end

---=================================================
---根据PartnerUiEffect加载辅助机特效
---@param modelName string 辅助机模型名字(来自【PartnerModel.tab】StandbyModel/CombatModel字段)
---@param effectParentName string 生成一个前缀Customize_+ effectParentName的节点,特效将挂载在其下。(XPartnerConfigs.EffectParentName枚举)
---@param isBindEffect boolean|nil 材质控制器相关特效和模型绑定
---@param isDisableOldEffect boolean|nil 为true时UnActive指定节点名下挂载的特效
---@param isUseModelParent boolean|nil 为true时该特效节点挂载在模型下
---=================================================
function XUiPanelRoleModel:LoadPartnerUiEffect(modelName, effectParentName, isBindEffect, isDisableOldEffect, isUseModelParent)
    if isDisableOldEffect then
        self:HideEffectByParentName(effectParentName)
    end

    if not modelName then
        return
    end

    if isBindEffect == nil then
        isBindEffect = false
    end
    
    -- 隐藏之前加载的特效
    if self.EffectDic then
        local parentName = CreateEffectParentName(effectParentName)
        local effectDict = self.EffectDic[parentName]
        if effectDict then
            for _, effect in pairs(effectDict) do
                if not XTool.UObjIsNil(effect) then
                    effect.gameObject:SetActiveEx(false)
                end
            end
        end
    end
    

    self.EffectParentDic = self.EffectParentDic or {}
    self.EffectDic = self.EffectDic or {}
    
    local effectInfos = XDataCenter.PartnerManager.GetPartnerUiEffect(modelName, effectParentName)
    local curModelInfo = self:GetModelInfoByName(self.CurRoleName)

    if not effectInfos then
        return 
    end
    if not curModelInfo or XTool.UObjIsNil(curModelInfo.Model) then
        XLog.Error("获取模型失败!请检查模型是否加载成功!")
        return
    end

    local parentNamePrefix = CreateEffectParentName(effectParentName)
    local index = 1

    if isUseModelParent or effectParentName == XPartnerConfigs.EffectParentName.ModelLoopEffect then
        parentNamePrefix = modelName .. parentNamePrefix
    end
    
    for _, effectInfo in pairs(effectInfos) do
        ---@type UnityEngine.GameObject
        local effectParent = nil
        local parentName = parentNamePrefix

        effectParent = self.EffectParentDic[parentName]
        if not effectParent or XTool.UObjIsNil(effectParent) then
            local parentTransform = nil
            
            if isUseModelParent or effectParentName == XPartnerConfigs.EffectParentName.ModelLoopEffect then
                parentTransform = curModelInfo.Model.transform
            else
                parentTransform = self.Transform
            end
    
            effectParent = CS.UnityEngine.GameObject(tostring(parentName))
            effectParent.transform:SetParent(parentTransform, false)
            effectParent.layer = parentTransform.gameObject.layer
        end
        
        self.EffectParentDic[parentName] = effectParent
        for i, effectPath in pairs(effectInfo.EffectPath) do
            local effectNode = effectParent.transform:FindTransform(effectParentName .. index)
            local effect = nil
    
            if not effectNode or XTool.UObjIsNil(effectNode) then
                effectNode = CS.UnityEngine.GameObject(effectParentName .. index)
                effectNode.transform:SetParent(effectParent.transform, false)
                effectNode.layer = effectParent.layer
            end
            
            if not string.IsNilOrEmpty(effectInfo.BoneRootName) then
                local bindComponent = effectNode:GetComponent(typeof(CS.XEffectBindBone))
                local node = curModelInfo.Model.transform:FindTransform(effectInfo.BoneRootName)

                if not bindComponent then
                    bindComponent = effectNode.gameObject:AddComponent(typeof(CS.XEffectBindBone))
                end

                bindComponent:UnBind()
                bindComponent:BindBone(node, effectNode.transform)
            else
                local bindComponent = effectNode:GetComponent(typeof(CS.XEffectBindBone))

                if bindComponent then
                    bindComponent:UnBind()
                end
            end

            index = index + 1
            -- 为了修复薇拉辅助机FxPet3RedwolfoffChange02，它的拖尾特效layer错误为Default，导致不可见，于是这里强制设置所有特效的层级都为其父节点的layer
            effect = effectNode:LoadPrefab(effectPath, false)
            self.EffectDic[parentName] = self.EffectDic[parentName] or {}
            self.EffectDic[parentName][effectPath] = effect
    
            if effect == nil or XTool.UObjIsNil(effect) then
                XLog.Error("加载的特效为空! 路径：" .. effectPath)
                return
            end
    
            if isBindEffect then
                self:BindEffect(effect)
            end

            effect.gameObject:SetActiveEx(true)
    
            -- 使用动画事件控制的特效, 默认隐藏
            if effectParentName == XPartnerConfigs.EffectParentName.ControlByAnimationEvent then
                self:AddAnimationEventListener()
                self:SetEffectForAnimationEvent(effectInfo.Id, effectParentName, effectPath)
                effect.gameObject:SetActiveEx(false)
                -- 因为modelTransform表, 会根据所在ui设置不同的坐标等, 所以需要同步修正一下
                effectNode.transform.localPosition = curModelInfo.Model.transform.localPosition
                effectNode.transform.localEulerAngles = curModelInfo.Model.transform.localEulerAngles
            else
                effectNode.gameObject:SetActiveEx(false)
                effectNode.gameObject:SetActiveEx(true)
            end
        end
    end
end

---=================================================
---生成指定名称的父节点并在其下加载特效
---@param effectPath string 特效路径
---@param effectParentName any 生成一个前缀Customize_+ effectParentName的节点,特效将挂载在其下。不指定时默认生成一个Default_EffectParent节点供挂载
---@param isBindEffect boolean|nil 材质控制器相关特效和模型绑定
---@param isDisableOldEffect boolean|nil 为true时UnActive指定节点名下挂载的特效
---@param isUseModelParent boolean|nil 为true时该特效节点挂载在模型下
---=================================================
function XUiPanelRoleModel:LoadEffect(effectPath, effectParentName, isBindEffect, isDisableOldEffect, isUseModelParent)
    if isDisableOldEffect then
        self:HideEffectByParentName(effectParentName)
    end

    if not effectPath then
        return
    end
    if isBindEffect == nil then
        isBindEffect = false
    end

    self.EffectParentDic = self.EffectParentDic or {}
    self.EffectDic = self.EffectDic or {}

    local parentName = CreateEffectParentName(effectParentName)
    local effectParent = self.EffectParentDic[parentName]

    if effectParent == nil then
        local curModelInfo = self:GetModelInfoByName(self.CurRoleName)
        local model
        if curModelInfo then
            model = curModelInfo.Model.transform
        end
        local parentTransform = isUseModelParent and model or self.Transform
        effectParent = CS.UnityEngine.GameObject(tostring(parentName))
        effectParent.transform:SetParent(parentTransform, false)
        self.EffectParentDic[parentName] = effectParent
    end
    local effect = effectParent:LoadPrefab(effectPath)

    self.EffectDic[parentName] = self.EffectDic[parentName] or {}
    self.EffectDic[parentName][effectPath] = effect

    if effect == nil or XTool.UObjIsNil(effect) then
        XLog.Error(string.format("特效路径%s加载的特效为空", effectPath))
        return
    end

    if isBindEffect then
        self:BindEffect(effect)
    end

    effect.gameObject:SetActiveEx(false)
    effect.gameObject:SetActiveEx(true)
end

---读取特效节点
function XUiPanelRoleModel:GetEffectObj(effectParentName, effectPath)
    local parentName = CreateEffectParentName(effectParentName)
    if XTool.IsTableEmpty(self.EffectDic) or XTool.IsTableEmpty(self.EffectDic[parentName]) then return end
    return self.EffectDic[parentName][effectPath]
end

function XUiPanelRoleModel:HideEffectByParentName(effectParentName)
    if self.EffectDic == nil then
        return
    end
    local parentName = CreateEffectParentName(effectParentName)
    for _, effect in pairs(self.EffectDic[parentName] or {}) do
        if effect and not XTool.UObjIsNil(effect) then
            effect.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelRoleModel:HideAllEffects()
    for _, effectGroup in pairs(self.EffectDic or {}) do
        for _, effect in pairs(effectGroup or {}) do
            if effect and not XTool.UObjIsNil(effect) then
                effect.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiPanelRoleModel:GetModelInfoByName(name)
    return self.RoleModelPool[name]
end

function XUiPanelRoleModel:RemoveRoleModelPool()
    -- 委托缓存池统一清理：业务回调 + Object.Destroy + 清空 _Pool
    self._CachePool:Clear()
    -- 兼容层引用 self.RoleModelPool 指向 _Pool 内部 table，Clear 是逐一 nil 而非替换 table，引用仍有效
    self.CurRoleName = nil
end

--- 释放当前激活模型，使其回归缓存并触发通用淘汰检查
--- 模型 GO 立即隐藏；是否立刻 Destroy 由缓存淘汰策略决定：
---   普通策略：打上 HideTime 时间戳，超时后销毁，下次加载同角色可命中缓存
---   低内存/无缓存策略：立刻触发 Destroy（activeKey=nil，所有条目均满足淘汰条件）
--- 调用后面板处于"无激活模型"状态，与 RemoveRoleModelPool 的区别在于不强制清空全部缓存
function XUiPanelRoleModel:ReleaseCurrentModel()
    if not self.CurRoleName then return end

    -- 1. 隐藏当前模型 GO 及其特效
    local curEntry = self._CachePool:Get(self.CurRoleName)
    if curEntry then
        curEntry.Model.gameObject:SetActiveEx(false)
        self:SetCurrentUiEffectActive(curEntry.UiEffect, false)
    end

    -- 2. 停止音效
    self:_StopRoleModelManagedAudio()

    -- 3. 通知缓存池：无激活模型
    --    内部执行：给旧条目打 HideTime、清空 ActiveKey、令牌递增、触发淘汰检查
    --    activeKey=nil 时所有条目均满足淘汰条件，低内存/无缓存策略下立刻 Destroy
    self._CachePool:BeginSwitch(nil)

    -- 4. 同步处理副面板（如有）
    if self.NewPanel and self.NewPanel.CurRoleName then
        local newPanelEntry = self.NewPanel._CachePool:Get(self.NewPanel.CurRoleName)
        if newPanelEntry then
            newPanelEntry.Model.gameObject:SetActiveEx(false)
        end
        self.NewPanel._CachePool:BeginSwitch(nil)
        self.NewPanel.CurRoleName = nil
    end

    -- 5. 清空面板激活状态
    self.CurRoleName = nil
end

--- 缓存条目被淘汰/销毁前的业务清理回调（由 XModelCachePool._DestroyEntry 调用）
--- 负责清理角色模型的所有附属资源：UI 特效、武器特效、解放特效等
---@param key   string  模型 roleName
---@param entry table   缓存条目
function XUiPanelRoleModel:_OnCacheEntryDestroy(key, entry)
    -- UiEffect / UiEquipEffect 存在 entry 本身（历史兼容，由业务代码直接写入 entry）
    self:ClearUiEffectList(entry.UiEffect)
    self:ClearUiEffectList(entry.UiEquipEffect)

    -- LiberationFx 同上
    if entry.LiberationFx and not XTool.UObjIsNil(entry.LiberationFx) then
        XUiHelper.Destroy(entry.LiberationFx)
    end

    -- TempEffectGo（手环位置修正用的临时 GO）
    if entry.TempEffectGo and not XTool.UObjIsNil(entry.TempEffectGo) then
        XUiHelper.Destroy(entry.TempEffectGo)
    end
end

function XUiPanelRoleModel:UpdateCuteModelWithoutUiEffect(robotId, isNotCuteUiEffect)
    self:UpdateCuteModel(robotId, nil, nil, nil, nil, nil,
            nil, nil, nil, isNotCuteUiEffect)
end

---=================================================
---更新Q版角色模型 参数都是复制自UpdateRobotModel
---希望以后统一通用接口,所以进行了二次封装并加上一定注解
---期待一个有缘人统一模型加载参数对象 by ljb
---@param robotId number|nil Robot.tab的robotId
---@param characterId number|nil Character.tab的characterId
---@param equipTemplateId number|nil Equip.tab的equipId
---@param weaponCb function|nil 武器模型加载后回调
---@param fashionId number|nil 模型皮肤id
---@param modelCb function|nil 武器模型加载后回调
---@param needDisplayController boolean
---@param targetPanelRole
---@param targetUiName
---=================================================
function XUiPanelRoleModel:UpdateCuteModel(robotId, characterId, weaponCb, fashionId, equipTemplateId, modelCb, needDisplayController
    , targetPanelRole, targetUiName, isNotCuteUiEffect)
    if not characterId then
        characterId = XRobotManager.GetCharacterId(robotId)
    end
    local modelName = XCharacterCuteConfig.GetCuteModelModelName(characterId)
    local weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
    -- 分包检查：若涂装未下载则使用默认涂装
    local validFashionId = self:_GetValidFashionId(fashionId, characterId)
    self:UpdateCuteModelByModelName(characterId, validFashionId, equipTemplateId, weaponFashionId, weaponCb, modelName,
            modelCb, needDisplayController, targetPanelRole, targetUiName, isNotCuteUiEffect)
end

---=================================================
---更新Q版角色模型 UpdateCuteModel()的二次封装
---@param characterId number|nil
---@param fashionId number|nil
---@param equipTemplateId number|nil
---@param weaponFashionId number|nil
---@param weaponCb function|nil
---@param modelName string
---@param modelCb function|nil
---@param needDisplayController boolean
---@param targetPanelRole
---@param targetUiName
---=================================================
function XUiPanelRoleModel:UpdateCuteModelByModelName(characterId, fashionId, equipTemplateId, weaponFashionId, weaponCb, modelName
, modelCb, needDisplayController, targetPanelRole, targetUiName, isNotCuteUiEffect)
    if not modelName or modelName == "" then
        return
    end
    -- 分包检查：若涂装未下载则使用默认涂装
    fashionId = self:_GetValidFashionId(fashionId, characterId)
    self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
        if not self.HideWeapon and XTool.IsNumberValid(equipTemplateId) then
            self:UpdateCharacterWeaponModels(
                    characterId,
                    modelName,
                    weaponCb,
                    true,
                    equipTemplateId,
                    weaponFashionId
            )
        end

        if modelCb then
            modelCb(model)
        end
        if self.FixLight then
            CS.XGraphicManager.FixUICharacterLightDir(model.gameObject)
        end
        -- Q版模型禁止动画移动
        self:CloseRootMotion(model)
    end, nil, needDisplayController)

    if isNotCuteUiEffect then
        return
    end
    self:LoadCharacterCuteUiEffect(characterId)
end

-- 禁止动画根节点移动
function XUiPanelRoleModel:CloseRootMotion(model)
    local animator = model:GetComponent("Animator")
    animator.applyRootMotion = false                        
end

---=================================================
--- 播放'AnimaName'动画，融合过渡
---@overload fun(animaName:string)
---@param animaName string
---@param crossDuration number@两个动作的融合时长
---@param animatorLayer number@动画层
---=================================================
function XUiPanelRoleModel:CrossFadeAnim(animaName, crossDuration, animatorLayer)
    local IsCanPlay, animator = self:CheckAnimaCanPlay(animaName)
    if IsCanPlay and animator then
        animator:CrossFade(animaName, crossDuration or 0.2, animatorLayer or 0)
    end
    return IsCanPlay
end

function XUiPanelRoleModel:GetCurRoleName()
    return self.CurRoleName
end

function XUiPanelRoleModel:GetCurRoleModel()
    local entry = self._CachePool:Get(self.CurRoleName)
    return entry and entry.Model
end

---@param dataModel XDlcHuntModel
function XUiPanelRoleModel:UpdateDlcModel(dataModel, targetUiName, callback)
    local characterId = nil
    local weaponFashionId = nil
    local weaponId = dataModel:GetWeaponId()
    local modelName = dataModel:GetModelId()
    local fashionId = nil
    local targetPanelRole = nil
    self:UpdateRoleModel(modelName, targetPanelRole, targetUiName, function(model)
                if not weaponId then
                    if callback then callback() end
                    return
                end
                self:UpdateCharacterWeaponModels(characterId, modelName, callback, true, weaponId, weaponFashionId)
            end, nil, nil)
    self:LoadResCharacterUiEffect(characterId, fashionId, weaponFashionId)
end

-- 开启/关闭头部跟随
function XUiPanelRoleModel:SetXPostFaicalControllerActive(flag)
    if not self.CurRoleName then
        return
    end
    
    local curModelInfo = self:GetModelInfoByName(self.CurRoleName)
    local model
    if curModelInfo then
        if XTool.UObjIsNil(curModelInfo.Model) then
            local topUiName = XLuaUiManager.GetTopUiName() or ""
            XLog.Error("模型丢失：" .. self.CurRoleName .. ",栈顶UI是：" .. topUiName)
        end
        model = curModelInfo.Model.transform
    end
    
    if not model then
        return
    end
    
    local targetComponent = model:GetComponent(typeof(CS.XPostFaicalController))
    if not targetComponent then
        return
    end

    targetComponent.enabled = true
    targetComponent:ActiveInput(flag)
end

function XUiPanelRoleModel:SetLocalPosition(v3)
    if not self.CurRoleName then
        return
    end
    
    local curModelInfo = self.RoleModelPool[self.CurRoleName]
    curModelInfo.Model.transform.localPosition = v3
end

function XUiPanelRoleModel:SetLocalRotation(v3)
    if not self.CurRoleName then
        return
    end

    local curModelInfo = self.RoleModelPool[self.CurRoleName]
    curModelInfo.Model.transform.localEulerAngles = v3
end

function XUiPanelRoleModel:SetWorldPosition(v3)
    if not self.CurRoleName then
        return
    end

    local curModelInfo = self.RoleModelPool[self.CurRoleName]
    curModelInfo.Model.transform.position = v3
end

function XUiPanelRoleModel:GetTransform()
    if not self.CurRoleName then
        return
    end

    local curModelInfo = self.RoleModelPool[self.CurRoleName]
    return curModelInfo.Model.transform
end

-- 同步武器动画
function XUiPanelRoleModel:WeaponAnimationSync(weaponModelList, modelName)
    if XTool.IsTableEmpty(weaponModelList) then
        return
    end
    local isAnimReset = XMVCA.XEquip:GetEquipAnimIsReset(modelName)
    if not isAnimReset then
        return
    end
    local roleModel = self.RoleModelPool[modelName]
    if not roleModel or XTool.UObjIsNil(roleModel.Model) then
        return
    end
    local playRoleAnimation = roleModel.Model.gameObject:GetComponent("XPlayRoleAnimation")
    if not playRoleAnimation then
        return
    end
    local defaultAnimeName = playRoleAnimation.DefaultClip
    if defaultAnimeName ~= "UiStand1" then
        return
    end
    local defaultAnimeLength = 0
    for i = 0, playRoleAnimation.Clips.Length - 1 do
        local clip = playRoleAnimation.Clips[i]
        if clip and clip.name == defaultAnimeName then
            defaultAnimeLength = clip.length
            break
        end
    end
    self:AddUiStandPlayCallback(function(animaName, leftTime)
        local layerIndex = 0
        for _, weaponModel in pairs(weaponModelList or {}) do
            if XTool.UObjIsNil(weaponModel) then
                goto CONTINUE
            end
            ---@type UnityEngine.Animator
            local weaponAnim = weaponModel:GetComponent("Animator")
            if XTool.UObjIsNil(weaponAnim) or XTool.UObjIsNil(weaponAnim.runtimeAnimatorController) then
                goto CONTINUE
            end

            local stateInfo = weaponAnim:GetCurrentAnimatorStateInfo(layerIndex)
            local length = stateInfo.length
            -- 角色动作时长和武器动作时长不一致时跳过武器动作重置
            if length <= 0 or math.abs(defaultAnimeLength - length) > 0.05 then
                goto CONTINUE
            end
            local time = leftTime / length
            weaponAnim:Play(stateInfo.shortNameHash, layerIndex, time)
            :: CONTINUE ::
        end
    end)
end

---将添加UiStand完成时的回调队列
function XUiPanelRoleModel:AddUiStandPlayCallback(callback)
    self.PlayUiStandCallBackList[#self.PlayUiStandCallBackList + 1] = callback
end

--region 特效延迟播放

function XUiPanelRoleModel:PlayDelayEffects(model)
    if XTool.IsTableEmpty(model.UiEffect) then
        return
    end
    for _, obj in pairs(model.UiEffect) do
        local root = obj.transform.parent.gameObject
        local time = model.EffectDelayTimes[root.name]
        self:PlayDelayEffect(root, time)
    end
end

function XUiPanelRoleModel:PlayDelayEffect(root, displayDelayTime)
    self:RemoveEffectTimer(root.name)
    if XTool.IsNumberValid(displayDelayTime) then
        if string.IsNilOrEmpty(self.RefName) or self.RefName == "DefaultName" then
            XLog.Error("没有传入UiName 无法延迟播放特效 和程序说说.\n" .. root.name)
        else
            root:SetActiveEx(false)
            local timer = XScheduleManager.ScheduleOnce(function()
                root:SetActiveEx(true)
            end, displayDelayTime)
            self:AddEffectTimer(timer, root.name)
        end
    end
end

function XUiPanelRoleModel:AddEffectTimer(timer, effectName)
    XModelManager.AddEffectTimer(timer, self.RefName, effectName, XEnumConst.ModelDisplayDelay.Character)
end

function XUiPanelRoleModel:RemoveEffectTimer(effectName)
    XModelManager.RemoveEffectTimer(self.RefName, effectName, XEnumConst.ModelDisplayDelay.Character)
end

--endregion

--region 添加动画事件监听
function XUiPanelRoleModel:AddAnimationEventListener()
    if not self._AnimationEvent then
        local XUiPanelRoleModelAnimationEvent = require("XUi/XUiCharacter/XUiPanelRoleModelAnimationEvent")
        ---@type XUiPanelRoleModelAnimationEvent
        self._AnimationEvent = XUiPanelRoleModelAnimationEvent.New(self)
    end
    self._AnimationEvent:AddAnimationEventListener(self)
end

function XUiPanelRoleModel:SetEffectForAnimationEvent(key, effectParent, EffectPath)
    if not self._EffectKey2ParentAndPath then
        self._EffectKey2ParentAndPath = {}
    end
    self._EffectKey2ParentAndPath[key] = {
        Parent = effectParent,
        Path = EffectPath
    }
end

function XUiPanelRoleModel:GetEffectByKey(key)
    local effectInfo = self._EffectKey2ParentAndPath[key]
    if effectInfo then
        local parent = effectInfo.Parent
        local path = effectInfo.Path
        local effect = self:GetEffectObj(parent, path)
        if effect then
            return effect
        end
    end
    XLog.Warning("[XUiPanelRoleModel] 根据key找不到要获取的特效", tostring(key))
end
--endregion

function XUiPanelRoleModel:AddRoleShadow()
    CS.XShadowHelper.SetCharRealtimeShadow(self.GameObject, true)
end

function XUiPanelRoleModel:RemoveRoleShadow()
    CS.XShadowHelper.SetCharRealtimeShadow(self.GameObject, false)
end

function XUiPanelRoleModel:GetSkinMeshFace()
    if not XTool.UObjIsNil(self._MySkinMeshFace) then
        return self._MySkinMeshFace
    end
    local transform = self:GetTransform()
    if not transform then
        return
    end
    local skinMeshFaceList = transform.gameObject:GetComponentsInChildren(typeof(CS.UnityEngine.SkinnedMeshRenderer), true)
    if not skinMeshFaceList then
        return
    end
    local targetSkinMeshFace = nil
    for i = 0, skinMeshFaceList.Length - 1 do
        local tempMesh = skinMeshFaceList[i]
        if string.find(tempMesh.name, "Face") then
            targetSkinMeshFace = tempMesh
            break
        end
    end
    self._MySkinMeshFace = targetSkinMeshFace
    return targetSkinMeshFace
end

-- 手动重置特效，修复播放其他动作后，loop特效周期与特效不一致的问题
function XUiPanelRoleModel:ReplayUiLoopEffect()
    if self.RoleModelPool then
        local model = self.RoleModelPool[self.CurRoleName]
        if model then
            if model.UiEffect then
                self:SetCurrentUiEffectActive(model.UiEffect, false)
                self:SetCurrentUiEffectActive(model.UiEffect, true)
            end
            if model.UiEquipEffect then
                self:SetCurrentUiEffectActive(model.UiEquipEffect, false)
                self:SetCurrentUiEffectActive(model.UiEquipEffect, true)
            end
        end
    end

    if self.EffectDic then
        local effectList = self.EffectDic["Customize_ModelLoopEffect"]
        if effectList then
            for _, effect in pairs(effectList) do
                -- 强制刷新
                effect.gameObject:SetActiveEx(false)
                effect.gameObject:SetActiveEx(true)
            end
        end
    end
end

function XUiPanelRoleModel:StopUiLoopEffect()
    if self.RoleModelPool then
        local model = self.RoleModelPool[self.CurRoleName]
        if model then
            if model.UiEffect then
                self:SetCurrentUiEffectActive(model.UiEffect, false)
            end
            if model.UiEquipEffect then
                self:SetCurrentUiEffectActive(model.UiEquipEffect, false)
            end
        end
    end
    if self.EffectDic then
        local effectList = self.EffectDic["Customize_ModelLoopEffect"]
        if effectList then
            for _, effect in pairs(effectList) do
                if effect.gameObject.activeSelf then
                    effect.gameObject:SetActiveEx(false)
                end
            end
        end
    end
end

return XUiPanelRoleModel
