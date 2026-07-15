local XLevel4001Present = XDlcScriptManager.RegLevelPresentScript(4001)

---@param proxy XDlcCSharpFuncs
function XLevel4001Present:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy

    self._assistMachineId = 6030               --辅助机npc单位表Id

    self._streetMall2F_ElevatorCallerPlaceId = 100066
    self._streetMall3F_ElevatorCallerPlaceId = 100067
    self._streetMall1F_ElevatorCallerPlaceId = 100068
    self._streetMall4F_ElevatorCallerPlaceId = 100123
    self._streetMall2F_ElevatorPortSpotId = 100002
    self._streetMall3F_ElevatorPortSpotId = 100001
    self._streetMall1F_ElevatorPortSpotId = 100014
    self._streetMall4F_ElevatorPortSpotId = 100015
    self._streetCE_ElevatorPortSpotId = 100010
    self._CoffeeNpcUUID = 100093
    self._WeComeBackID = 100010
    self._KuroNPCId = 100318
    self._count = 0

    self._deathZoneId = 100009                 --死区的triggerID
    self._reviveRotation = { 0, 0, 0 }         --复活时的旋转
    self._transportNPCPlazaId = 100020
    self._cafeObj = 100076
    -- 隐藏跳跳乐相关
    self._jumperTouchObj = 100043
    self._jumperLightObj = {100044,100045,100046}
    
    self:InitSpaceAudioParams()
end

function XLevel4001Present:Init() --初始化逻辑
    self._streetMall2F_ElevatorCallerUUID = self._proxy:GetSceneObjectUUID(self._streetMall2F_ElevatorCallerPlaceId)
    self._streetMall3F_ElevatorCallerUUID = self._proxy:GetSceneObjectUUID(self._streetMall3F_ElevatorCallerPlaceId)
    self._streetMall1F_ElevatorCallerUUID = self._proxy:GetSceneObjectUUID(self._streetMall1F_ElevatorCallerPlaceId)
    self._streetMall4F_ElevatorCallerUUID = self._proxy:GetSceneObjectUUID(self._streetMall4F_ElevatorCallerPlaceId)
    self._streetMall3F_ElevatorPortPos = self._proxy:GetSpot(self._streetMall3F_ElevatorPortSpotId)
    self._streetMall2F_ElevatorPortPos = self._proxy:GetSpot(self._streetMall2F_ElevatorPortSpotId)
    self._streetMall1F_ElevatorPortPos = self._proxy:GetSpot(self._streetMall1F_ElevatorPortSpotId)
    self._streetMall4F_ElevatorPortPos = self._proxy:GetSpot(self._streetMall4F_ElevatorPortSpotId)
    self._tempLevelSwitcherBackUUID = self._proxy:GetSceneObjectUUID(self._WeComeBackID)
    self._questNpcUUID = self._proxy:GetNpcUUID(self._CoffeeNpcUUID)
    self._PlazaLevelSwitchUUID = self._proxy:GetNpcUUID(self._transportNPCPlazaId)         --传送去商业街玩法
    self._storyInstLevelEntranceNpcPID = 100234            --测试版剧情副本入口NPC
    self._storyInstLevelEntranceNpc2PID = 600003
    self._storyInstLevelEntranceNpc3PID = 600021
    self._storyInstLevelEntranceNpc4PID = 600022
    self._storyInstLevelEntranceNpc5PID = 500026           --支线D跳跳乐备用入口
    self._cafeObjSwitchUUID = self._proxy:GetSceneObjectUUID(self._cafeObj)                        --切换去咖啡厅玩法
    self._lxyObjSwitchUUID = 900001                   --进入剧情副本入口1
    self._lxyObjSwitch1UUID = 900002                   --进入剧情副本入口1
    self._revivePoint = self._proxy:GetSpot(100003)                                --复活点坐标
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.DramaFinish)
    self:InitDeathZoneParams()
end

---@param dt number @ delta time
function XLevel4001Present:Update(dt) --每帧更新逻辑
    self:UpdateSpaceAudio(dt)
    self:UpdateDeathZoneCheck(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevel4001Present:HandleEvent(eventType, eventArgs) --事件响应逻辑
    if eventType == EWorldEvent.NpcInteractStart then
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) then --是玩家发起的交互
            --if eventArgs.TargetId == self._streetMall2F_ElevatorCallerUUID then
            --    --传送到露天广场
            --    self._proxy:TeleportWithBlackUi(eventArgs.LauncherId, self._streetMall3F_ElevatorPortPos, { x = 0, y = 90, z = 0 })
            --elseif eventArgs.TargetId == self._streetMall3F_ElevatorCallerUUID then
            --    --传送到时序广场
            --    self._proxy:TeleportWithBlackUi(eventArgs.LauncherId, self._streetMall2F_ElevatorPortPos, { x = 0, y = 16.935, z = 0 })
            --elseif eventArgs.TargetId == self._streetMall1F_ElevatorCallerUUID then
            --    --从商业街传送回时序广场
            --    self._proxy:TeleportWithBlackUi(eventArgs.LauncherId, self._streetMall1F_ElevatorPortPos, { x = 0, y = 158, z = 0 })
            --elseif eventArgs.TargetId == self._streetMall4F_ElevatorCallerUUID then
            --    --从时序广场传送到商业街
            --    self._proxy:TeleportWithBlackUi(eventArgs.LauncherId, self._streetMall4F_ElevatorPortPos, { x = 0, y = -50.33, z = 0 })
            --elseif eventArgs.TargetId == self._tempLevelSwitcherBackUUID then
            --    local pos = { x = 18.43, y = 1.14, z = 17.55 }
            --    self._proxy:SwitchLevelWitchRot(4003, pos, { x = 0, y = -95, z = 0 })
            --elseif eventArgs.TargetId == self._cafeObjSwitchUUID then
            --    self._proxy:OpenGameplayMainEntrance(1, { 555.03, 169.44, 1174.21 })
            --elseif eventArgs.TargetPlaceId == self._storyInstLevelEntranceNpc2PID then
            --    local pos = { x = 76.383, y = 7.865, z = 55.2803 }
            --    self._proxy:RequestEnterInstLevel(4013, pos)
            --elseif eventArgs.TargetPlaceId == self._lxyObjSwitch1UUID then
            --    local pos = { x = 20.9339, y = 56.59, z = 40.44 }
            --    self._proxy:RequestEnterInstLevel(4023, pos)
            --elseif eventArgs.TargetPlaceId == self._storyInstLevelEntranceNpc3PID then
            --    local pos = { x = 605.746094, y = 189.338181, z = 1146.83838 }
            --    self._proxy:RequestEnterInstLevel(4021, pos)
            --elseif eventArgs.TargetPlaceId == self._storyInstLevelEntranceNpc4PID then
            --    local pos = { x = 605.746094, y = 189.338181, z = 1146.83838 }
            --    self._proxy:RequestEnterInstLevel(4022, pos)
            --elseif eventArgs.TargetPlaceId == self._storyInstLevelEntranceNpc5PID then
            --    local pos = { x = 243.7, y = 36.6, z = 322.7 }
            --    self._proxy:RequestEnterInstLevel(4025, pos)
            if eventArgs.TargetPlaceId == self._jumperTouchObj then                     --随机生成场景物件特殊物件生成跳跳乐
                for _, HideObj in pairs(self._jumperLightObj ) do                       --隐藏所有场景物件并随机加载一个
                    self._proxy:UnloadSceneObject(HideObj)
                end
                self._proxy:LoadSceneObject(self._jumperLightObj[self._proxy:Random(1, #self._jumperLightObj)])
            end

            --记录库洛洛的交互，每次交互播放不同的Drama
            if eventArgs.TargetPlaceId == self._KuroNPCId then
                self._count = self._count+1
                if self._count == 3 then
                    self._proxy:PlayDrama("DramaNPC9000027")
                elseif self._count == 2 then
                    self._proxy:PlayDrama("DramaNPC9000026")
                elseif self._count == 1 then
                    self._proxy:PlayDrama("DramaNPC9000026")
                end
            end
        end
    elseif eventType == EWorldEvent.ActorTrigger then
        --XLog.Error("有npc触发器触发")
        if (eventArgs.HostSceneObjectPlaceId == self._deathZoneId and eventArgs.TriggerState == ETriggerState.Enter) then
            self._proxy:SetNpcPosAndRot(eventArgs.EnteredActorUUID, self._revivePoint,
                self._reviveRotation, true)
        end
    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama_5001_001" then                               --跳跳乐对话跳转
            local dramaOptions = self._proxy:GetDramaDialogFirstDecisionId(1)
            if dramaOptions == 1001 then --选择了对话选项1
                self._proxy:RequestEnterInstLevel(4008, { x = 243.7, y = 37, z = 322.7 }, self._reviveRotation)
            elseif dramaOptions == 1002 then --选择了对话选项2
                self._proxy:RequestEnterInstLevel(4009,  { x = 252.58, y = 38.92, z = 241.96 }, self._reviveRotation)
            elseif dramaOptions == 1003 then --选择了对话选项3
                self._proxy:RequestEnterInstLevel(4010,{ x = 250.82, y = 55.46, z = 270.79 }, self._reviveRotation)
            end
        elseif eventArgs.DramaName == "Drama_5002_001" then                               --跳跳乐对话跳转
            local dramaOptions = self._proxy:GetDramaDialogFirstDecisionId(2)
            if dramaOptions == 1001 then                --选择了对话选项1
                self._proxy:RequestEnterInstLevel(4018, { x = 266.72, y = 52.77, z = 327.83 }, self._reviveRotation)
            elseif dramaOptions == 1002 then            --选择了对话选项2
                self._proxy:RequestEnterInstLevel(4019, { x = 378.57, y = 54.64, z = 290.85 }, self._reviveRotation)
            elseif dramaOptions == 1003 then            --选择了对话选项3
                self._proxy:RequestEnterInstLevel(4020, { x = 271, y = 54.11, z = 237.4 }, self._reviveRotation)
            end
        end

        if eventArgs.DramaName == "DramaNPC9000027" then
            self._proxy:NpcNavigateTo(self._proxy:GetNpcUUID(100318), {x = 644.2914, y = 193.8959, z = 1290.067}, ENpcMoveType.Walk)
            self._proxy:SetActorInteractableComponentEnable(self._proxy:GetNpcUUID(100318), false)
        end
    end
    self:HandleSpaceAudioEvent(eventType, eventArgs)
end

function XLevel4001Present:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）
    self:TerminateSpaceAudioParams()
end

--region SpaceAudio 
---@class SpaceAudioInfo
---@field PlaceId number 对应PlaceId
---@field ActorType number ActorType 参考ETargetActorType
---@field CurPlayIndex number 当前播放空间音频序列索引, 为-1时表示当前没有播放
---@field MaxPlayIndex number 最大播放空间音频序列索引
---@field CurPlayTime number 当前播放时长
---@field TriggerCD number 触发播放CD
---@field CurTriggerCD number 当前CD
---@field EnterPlayerUID boolean 在区域的玩家ID, 处理切人重复触发
---@field IsPlayerIn boolean 玩家是否在区域内
---@field IsTrigger boolean 是否触发播放
---@field DurationDict table<number, number> 时长字典 Key:空间音频序列索引, value:音频时长（秒）

function XLevel4001Present:InitSpaceAudioParams()
    ---阿迪拉音频触发Trigger字典
    self._spaceAudioAdilaTriggerDict = {
        [100055] = true,
    }
    self._spaceAudioAdilaTrigger2Dict = {
        [100056] = true,
    }
    self._spaceAudioAdilaInfo = self:GetSpaceAudioInfo(100055, false, 10, {
        [0] = 10,
        [1] = 10,
    })
    self._spaceAudioAdilaInfo1 = self:GetSpaceAudioInfo(100056, false, 10, {
        [0] = 10,
        [1] = 10,
    })
end

---@param placeId number 关卡配置CD
---@param isNpc boolean 是否是Npc, 为true是Npc, 为false是SceneObj
---@param triggerCd number 触发播放CD
---@param DurationDict table<number, number> 时长字典 Key:空间音频序列索引, value:音频时长（秒）
---@return SpaceAudioInfo
function XLevel4001Present:GetSpaceAudioInfo(placeId, isNpc, triggerCd, DurationDict)
    ---@type SpaceAudioInfo
    local info = {}
    info.PlaceId = placeId
    if isNpc then
        info.ActorType = ETargetActorType.Npc
    else
        info.ActorType = ETargetActorType.SceneObject
    end
    info.CurPlayIndex = -1
    info.MaxPlayIndex = 1
    info.CurPlayTime = -1
    info.TriggerCD = triggerCd
    info.CurTriggerCD = 0
    info.EnterPlayerUID = 0
    info.IsPlayerIn = false
    info.IsTrigger = false
    if triggerCd then
        info.TriggerCD = triggerCd
    else
        info.TriggerCD = 5
    end
    if DurationDict then
        info.DurationDict = DurationDict
    else
        info.DurationDict = { }
    end
    return info
end

function XLevel4001Present:UpdateSpaceAudio(dt)
    self:UpdateSpaceAudioInfo(self._spaceAudioAdilaInfo, dt)
    self:UpdateSpaceAudioInfo(self._spaceAudioAdilaInfo1, dt)
end

function XLevel4001Present:HandleSpaceAudioEvent(eventType, eventArgs)
    -- 不是玩家不触发
    if eventArgs.EnteredActorUUID ~= self._proxy:GetLocalPlayerNpcId() then
        return
    end
    if eventType == EWorldEvent.ActorTrigger and eventArgs.TriggerState == ETriggerState.Enter then
        if self._spaceAudioAdilaTriggerDict[eventArgs.HostSceneObjectPlaceId] then
            self:TriggerSpaceAudio(self._spaceAudioAdilaInfo, true)
        end
        if self._spaceAudioAdilaTrigger2Dict[eventArgs.HostSceneObjectPlaceId] then
            self:TriggerSpaceAudio(self._spaceAudioAdilaInfo1, true)
        end
    elseif eventType == EWorldEvent.ActorTrigger and eventArgs.TriggerState == ETriggerState.Exit then
        if self._spaceAudioAdilaTriggerDict[eventArgs.HostSceneObjectPlaceId] then
            self:TriggerSpaceAudio(self._spaceAudioAdilaInfo, false)
        end
        if self._spaceAudioAdilaTrigger2Dict[eventArgs.HostSceneObjectPlaceId] then
            self:TriggerSpaceAudio(self._spaceAudioAdilaInfo1, false)
        end
    end
end

function XLevel4001Present:TerminateSpaceAudioParams()
    self._spaceAudioAdilaTriggerDict = nil
    self._spaceAudioAdilaTrigger2Dict = nil
    self._spaceAudioAdilaInfo = nil
    self._spaceAudioAdilaInfo1 = nil
end
---更新空间音频播放情况
---@param spaceAudioInfo SpaceAudioInfo
function XLevel4001Present:UpdateSpaceAudioInfo(spaceAudioInfo, dt)
    if spaceAudioInfo.CurTriggerCD > 0 then
        spaceAudioInfo.CurTriggerCD = spaceAudioInfo.CurTriggerCD - dt
        return
    end
    if not spaceAudioInfo.IsPlayerIn then
        return
    end
    if spaceAudioInfo.IsTrigger then
        self._proxy:SetActorAllSpaceAudioActive(spaceAudioInfo.ActorType, spaceAudioInfo.PlaceId, false)
        self._proxy:SetActorOneSpaceAudioActive(spaceAudioInfo.ActorType, spaceAudioInfo.PlaceId, spaceAudioInfo.CurPlayIndex, true)
        -- 关闭触发
        spaceAudioInfo.IsTrigger = false
        --XLog.Warning("空间音频播放"..spaceAudioInfo.CurPlayIndex)
    end
    -- 记录时长
    spaceAudioInfo.CurPlayTime = spaceAudioInfo.CurPlayTime + dt
    -- 判断是否到时间, 到时间播放下一个
    if spaceAudioInfo.CurPlayTime >= spaceAudioInfo.DurationDict[spaceAudioInfo.CurPlayIndex] then
        -- 防止数组过界
        spaceAudioInfo.CurPlayIndex = spaceAudioInfo.CurPlayIndex + 1
        if spaceAudioInfo.CurPlayIndex > spaceAudioInfo.MaxPlayIndex then
            spaceAudioInfo.CurPlayIndex = 0
        end
        spaceAudioInfo.CurPlayTime = 0
        -- 下一帧重新触发
        spaceAudioInfo.IsTrigger = true
        --XLog.Warning("空间音频播放下一个"..spaceAudioInfo.CurPlayIndex)
    end
end

---设置空间音频触发
---@param spaceAudioInfo SpaceAudioInfo
function XLevel4001Present:TriggerSpaceAudio(spaceAudioInfo, isEnter)
    local isTrigger = true
    local curPlayerNpcId = self._proxy:GetLocalPlayerNpcId()
    if isEnter and spaceAudioInfo.EnterPlayerUID > 0 and spaceAudioInfo.EnterPlayerUID ~= curPlayerNpcId then
        isTrigger = false
    end
    spaceAudioInfo.EnterPlayerUID = curPlayerNpcId
    spaceAudioInfo.IsPlayerIn = isEnter
    if not isEnter then
        self._proxy:SetActorAllSpaceAudioActive(spaceAudioInfo.ActorType, spaceAudioInfo.PlaceId, false)
        spaceAudioInfo.CurTriggerCD = spaceAudioInfo.TriggerCD
        return
    end
    if not isTrigger then
        return
    end
    -- 开始触发第一个播放
    if spaceAudioInfo.CurPlayIndex < 0 then
        spaceAudioInfo.CurPlayIndex = 0
    else
        spaceAudioInfo.CurPlayIndex = self._proxy:Random(0, spaceAudioInfo.MaxPlayIndex)
    end
    -- 重置时长
    spaceAudioInfo.CurPlayTime = 0
    spaceAudioInfo.IsTrigger = isTrigger
end
--endregion

--region 究极死区保底
function XLevel4001Present:InitDeathZoneParams()
    self._deathZoneCheckTime = 5
end

function XLevel4001Present:UpdateDeathZoneCheck(dt)
    if self._deathZoneCheckTime <= 0 then
        local playerId = self._proxy:GetLocalPlayerNpcId()
        local npcPosition = self._proxy:GetNpcPosition(playerId)
        if npcPosition.y <= 90 then
            self._proxy:SetNpcPosAndRot(self._proxy:GetLocalPlayerNpcId(), self._revivePoint, self._reviveRotation, true)
        end
        self._deathZoneCheckTime = 5
    end
    self._deathZoneCheckTime = self._deathZoneCheckTime - dt
end
--endregion

return XLevel4001Present