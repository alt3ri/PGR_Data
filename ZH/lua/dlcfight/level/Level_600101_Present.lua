local XLevel6001Present = XDlcScriptManager.RegLevelPresentScript(600101)
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local Timer = require("Level/Common/XTaskScheduler")

--局部变量需要最上层定义
local ETrafficHubElevatorState = { --电梯状态初始化
    Moving = 0, --运行中
    Up = 1, --在上层
    Down = 2, --在下层
    forbidden = 3, --被禁用
}


---@param proxy XDlcCSharpFuncs
function XLevel6001Present:Ctor(proxy)
    --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy
    self._timer = Timer.New()
end

function XLevel6001Present:Init()
    --初始化逻辑
    --region 响应事件注册
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectMoveStop)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectActionFinish)
    self._proxy:RegisterEvent(EWorldEvent.DramaCaptionBegin)
    self._proxy:RegisterEvent(EWorldEvent.DramaCaptionEnd)
    self._proxy:RegisterEvent(EWorldEvent.DramaFinish)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractComplete)
    --endregion

    --region 交互事件参数初始化
    self:InitWishingPond() --许愿池打捞
    self:InitOfferFlowers() --献花
    self:InitTrafficHubElevator()--电梯
    self:InitGacha()--扭蛋机
    self:InitMirror()--理发店镜子
    self:InitInformation()--情报社
    self:InitDanceRobot()--跳舞机器人
    self:InitSqureRunner()--纪念广场跑步的人
    self:Weapon()--武器架

    --endregion

    self._DanceTime = 15 --跳舞持续的总时间
    self._DancingTimer = 0 --跳舞当前持续的时间

end

---@param dt number @ delta time
function XLevel6001Present:Update(dt)
    --每帧更新逻辑,暂时没有需要tick的内容，需要的话去抄5001
    self:StopDancing(dt)
end


--region 响应事件
---@param eventType number
---@param eventArgs userdata
function XLevel6001Present:HandleEvent(eventType, eventArgs)
    ---交互事件
    if eventType == EWorldEvent.NpcInteractStart and self._proxy:IsPlayerNpc(eventArgs.LauncherId) then
        if eventArgs.TargetPlaceId == self._WishPondPlaceID then
            self:OnWishingPondNpcInteractStart(eventType, eventArgs) --许愿池打捞交互
        elseif eventArgs.TargetPlaceId == self._OfferFlowerPlaceID01 then
            self:OnOfferFlowerInteractStart01(eventType, eventArgs) --献花交互01
        elseif eventArgs.TargetPlaceId == self._OfferFlowerPlaceID02 then
            self:OnOfferFlowerInteractStart02(eventType, eventArgs) --献花交互02
        elseif eventArgs.TargetPlaceId == self._TrafficHubElevator.PlaceId then
            self:OnTrafficHubElevatorInteractStart(eventType, eventArgs) --交互电梯
        elseif eventArgs.TargetPlaceId == self._TrafficHubElevator.NPC02 then
            self:SwitchTrafficHubElevatorAD(eventType, eventArgs) --交互npc切换电梯广告
        elseif eventArgs.TargetPlaceId == self._GachaPlaceID01 or eventArgs.TargetPlaceId == self._GachaPlaceID02 then
            self:OnGachaInteractStart(eventType, eventArgs)--交互扭蛋机
        elseif eventArgs.TargetPlaceId == self._MirrorPlaceID then
            self:OnMirrorInteractStart(eventType, eventArgs) --交互理发店镜子
        elseif eventArgs.TargetPlaceId == self._WeaponPlaceID then
        --交互理发店镜子
            self:WeaponStart(eventType, eventArgs)
        end

    end
    ---监听Drama播放结束
    if eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama302003" then
            --战斗支线对话跳转
            local dramaOptions = self._proxy:GetDramaDialogFirstDecisionId(2)
            if dramaOptions == 1 then
                --选择了对话选项1
                self._proxy:RequestEnterInstLevel(6002, { x =26.91, y = 0, z = 8.3740 }, { x = 0, y = -268.832, z = 0 })
            end
        elseif eventArgs.DramaName == "Drama302002" then
            local dramaOptions = self._proxy:GetDramaDialogFirstDecisionId(3)
            if dramaOptions == 1 then
                --选择了对话选项1
                self._proxy:RequestEnterInstLevel(6003, { x = 33.35, y = 0, z = 21.53 }, { x = 0, y = -268.832, z = 0 })
            end
        elseif eventArgs.DramaName == "Drama60010110" then  --跳舞机器人的对话，先随便抓个DramaID凑合一下后面记得改
            local dramaOptions = self._proxy:GetDramaDialogFirstDecisionId(11)
            if dramaOptions == 2 then   --选择了对话选项1，那就让机器人开始跳舞
                self:OnRobotDancing(eventType, eventArgs) --播放动作与特效
            end
        elseif eventArgs.DramaName == "Drama60010130" then--如果播放完了机器人Drama且过完了选项
            self._proxy:LoadLevelNpc(4000047) --那就吧机器人给显示出来
            self.RobotUUid = self._proxy:GetNpcUUID(4000047)
            self._proxy:SetNpcAnimationLayer(self.RobotUUid, 1)
        elseif eventArgs.DramaName == "Drama60010109" then --抓到的Drama是外卖柜任务，标志外卖柜任务结束，加载外卖柜相关的后续逻辑
            -- 读取分期选项数据
            local selectOptionIdList = eventArgs.HistoryDecisionDict[2]
            if not selectOptionIdList then -- 剧情跳过走默认
                self._proxy:UnloadLevelNpc(self._InformationParam.WaitressStartID) --卸载初始的NPC
                self._proxy:LoadLevelNpc(self._InformationParam.Waitress01Underway) --加载选项1NPC
                self._proxy:LoadLevelNpc(self._InformationParam.Student01After) --加载选项1的学生
            elseif table.contains(selectOptionIdList, 1) then -- 分支1
                self._proxy:UnloadLevelNpc(self._InformationParam.WaitressStartID) --卸载初始的NPC
                self._proxy:LoadLevelNpc(self._InformationParam.Waitress01Underway) --加载选项1NPC
                self._proxy:LoadLevelNpc(self._InformationParam.Student01After) --加载选项1的学生
            elseif table.contains(selectOptionIdList, 2) then -- 分支2
                self._proxy:LoadLevelNpc(self._InformationParam.Waitress02After) --加载后续2的服务生
                self._proxy:LoadLevelNpc(self._InformationParam.Student02After)--加载后续2的学生
            end
        elseif self:IsInclude(eventArgs.DramaName, self._WishPondTimelinePool) then
            --许愿池 随机对话，执行随机对话的逻辑
            self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._WishPondPlaceID, true)
        elseif eventArgs.DramaName == "Drama60010111" then
            self._proxy:UnloadLevelNpc(4000059)--卸载饮料机NPC
        elseif eventArgs.DramaName == "Drama60010112" then
            self._proxy:LoadSceneObject(4000001) --完成饮料机任务，获得小卡片
            self._proxy:LoadLevelNpc(4000059)--加载饮料机NPC
        end
    end
    ---Trigger事件
    if eventType == EWorldEvent.ActorTrigger then
        if self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then--如果触发事件的NPC是玩家的话，可触发如下逻辑
            if eventArgs.TriggerState == ETriggerState.Enter then--事件是进入触发器
                if eventArgs.HostSceneObjectPlaceId == self._TrafficHubElevator.UpTrigger then--如果是玩家进入上层电梯的触发器
                    self:OnTrafficHubElevatorEnterUP(eventType, eventArgs)--电梯移至上层，并设置状态
                end
                if eventArgs.HostSceneObjectPlaceId == self._TrafficHubElevator.DownTrigger then--进入下层电梯的触发器
                    self:OnTrafficHubElevatorEnterDOWN(eventType, eventArgs)--电梯移至下层，并设置状态
                end
            end
        elseif eventArgs.EnteredActorUUID == self.Runner01UUID then--如果是跑步者进入了触发器
            if eventArgs.TriggerState == ETriggerState.Enter then
                if eventArgs.HostSceneObjectPlaceId == self._RunnerParam.RunnerStartTriggerPlaceID then--进入的触发器是起步用触发器
                    self._proxy:NpcMoveByRoute(self.Runner01UUID, self._RunnerParam.Line1ID, ENpcMoveType.Run)--让他沿着路径1移动
                    self._proxy:NpcMoveByRoute(self.Runner02UUID, self._RunnerParam.Line2ID, ENpcMoveType.Run)
                elseif eventArgs.HostSceneObjectPlaceId == self._RunnerParam.TriggerPlaceID then
                    self:OnRunnerBubbleTrigger(eventType, eventArgs) --触发一次随机对话
                end
            end
        end
    end
    ---监听底端字幕（简易台词）播放完成后，恢复对应物件交互
    if eventType == EWorldEvent.DramaCaptionEnd then
        local caption = eventArgs.CaptionName
        if caption == "Caption600112" then--许愿池 最后一句话
            self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._WishPondPlaceID, true)
        elseif caption == "Caption600104" then--献花后
            self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._OfferFlowerPlaceID02, true)
        elseif caption == "Caption600127" or caption == "Caption600128" or caption == "Caption600129" then--扭蛋机 任意一个扭蛋扭出来了之后就重置所有
            self._proxy:SetSceneObjectInteractOneOptionActive(self._GachaPlaceID01, 1)--设置场景物件仅显示某个交互选项
            self._proxy:SetSceneObjectInteractOneOptionActive(self._GachaPlaceID02, 1)
        elseif caption == "Caption600133" or caption == "Caption600134" then
            self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.Npc, self._TrafficHubElevator.NPC02, true) --电梯npc
        end

    end
    ---监听场景物件停止移动
    if eventType == EWorldEvent.SceneObjectMoveStop then
        if eventArgs.SceneObjectId == self._TrafficHubElevator.PlaceId then--如果物件是电梯，则根据目标点设置状态
            self:SetTrafficHubElevatorState(eventArgs.ToNodeId)
            self._proxy:PlaySound(5500139,ETargetActorType.Npc,self.TrafficHubElevatorUUid,-1,-1,-1,-1,-1,-1,-1)--播放电梯停止音效
            if self._TrafficHubElevator.ADstate == 1 then--如果有广告，那就停止播放广告特效
                self._proxy:UnBindSceneObjectEffect(self._TrafficHubElevator.PlaceId, "FxSkyGardenDtilang")
            elseif self._TrafficHubElevator.ADstate == 0 then--如果没有广告那就停止播放无广告特效
                self._proxy:UnBindSceneObjectEffect(self._TrafficHubElevator.PlaceId, "FxSkyGardenDtilangLoop")
            end
            self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId, "FxSkyGardenDtiTouping", { x = 1, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }, { x = 0.9, y = 1, z = 1 })--播放投屏特效来提示玩家
        end

    end
    ---监听交互结束
    if eventType == EWorldEvent.NpcInteractComplete then
        if eventArgs.TargetPlaceId == self._TrafficHubElevator.NPC01 then --如果交互结束的NPC是电梯修理工（修理电梯ver）
            self._TrafficHubElevator.State = ETrafficHubElevatorState.Up --把电梯状态设置为在上层
            self._proxy:UnBindSceneObjectEffect(self._TrafficHubElevator.PlaceId, "FxSkyGardenDtihuangLoop") --删除掉电梯原有的特效
            self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId, "FxSkyGardenDtihuangBianse", { x = 1, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }, { x = 0.9, y = 1, z = 1 })
            self._proxy:AddTimerTask(1.5,function()
                self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId, "FxSkyGardenDtiTouping", { x = 1, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }, { x = 0.9, y = 1, z = 1 })--延迟1.5s播放投屏特效
                self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._TrafficHubElevator.PlaceId, true) --设置电梯为可交互状态
            end)
        elseif self._proxy:IsQuestObjectiveFinished(60040101) and eventArgs.TargetPlaceId == self._TrafficHubElevator.NPC01 then
            self._proxy:LoadLevelNpc(self._TrafficHubElevator.NPC02)--加载NPC02
        elseif eventArgs.TargetPlaceId == self._TrafficHubElevator.PlaceId then --如果交互结束的NPC是电梯本身（使用电梯点击完后）
            self._proxy:PlaySound(5500140,ETargetActorType.Npc,self.TrafficHubElevatorUUid,-1,-1,-1,-1,-1,-1,-1)--播放电梯开闸音效
            self._proxy:UnBindSceneObjectEffect(self._TrafficHubElevator.PlaceId, "FxSkyGardenDtiTouping")--暂时删除投屏特效
            if self._TrafficHubElevator.ADstate == 1 then--如果有广告，那就播放广告特效
                self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId, "FxSkyGardenDtilang", { x = 1, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }, { x = 0.9, y = 1, z = 1 })
            elseif self._TrafficHubElevator.ADstate == 0 then--如果没有广告那就播放无广告特效
                self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId, "FxSkyGardenDtilangLoop", { x = 1, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }, { x = 0.9, y = 1, z = 1 })
            end
        end
    end
end

--------------事件本体---------------

--region 许愿池打捞
--初始化参数
function XLevel6001Present:InitWishingPond()
    self._WishPondPlaceID = 3900004
    self._WishPondCaptionPool = {
        "Caption600106",
        "Caption600107",
        "Caption600108",
        "Caption600109",
        "Caption600110",
        "Caption600111",
    }
    self._WishPondTimelinePool = { --替换成播timeline
        "Drama60010137",
        "Drama60010138",
        "Drama60010139",
        "Drama60010140",
        "Drama60010141",
        "Drama60010142",
        "Drama60010143",
    }
    self._WishPondPlayedCaptions = {}
    self._WishPondCurrentCaptionIndex = 1
    self._WishPondFinalCaption = "Caption600112"
    for i = #self._WishPondTimelinePool, 2, -1 do
        local j = math.random(i)
        self._WishPondTimelinePool[i], self._WishPondTimelinePool[j] = self._WishPondTimelinePool[j], self._WishPondTimelinePool[i]
    end

end
    --许愿池随机台词
function XLevel6001Present:OnWishingPondNpcInteractStart(eventType, eventArgs)
    if eventArgs.TargetPlaceId == self._WishPondPlaceID then
        if #self._WishPondPlayedCaptions >= #self._WishPondTimelinePool then--如果播完了，就播最后一句，最后一句是caption
            self._proxy:PlayDramaCaption(self._WishPondFinalCaption)
        else
            local dialog = self._WishPondTimelinePool[self._WishPondCurrentCaptionIndex]
            self._proxy:PlayDrama(dialog)
            table.insert(self._WishPondPlayedCaptions, dialog)
            self._WishPondCurrentCaptionIndex = self._WishPondCurrentCaptionIndex + 1
        end

        ---暂时关闭交互
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._WishPondPlaceID, false)
    end
end
--重新开启交互在响应事件里
--endregion

--region 献花
--ps：献花事件重进场景后刷新，故无需做存档处理。
--初始化参数
function XLevel6001Present:InitOfferFlowers()
    self._OfferFlowerPlaceID01 = 3900002 --献花前
    self._OfferFlowerPlaceID02 = 3900009 --献花后
    self._FlowerPlaceID = 3900010 --花束模型
end
--交互01 献花前 完成献花 （黑屏字幕）
function XLevel6001Present:OnOfferFlowerInteractStart01(eventType, eventArgs)
    self:OfferedFlower()
end
function XLevel6001Present:OfferedFlower(eventType, eventArgs)
    self._proxy:LoadSceneObject(self._FlowerPlaceID) --加载花束模型
    self._proxy:LoadSceneObject(self._OfferFlowerPlaceID02)--加载献花后交互点
    self._proxy:UnloadSceneObject(self._OfferFlowerPlaceID01) --卸载献花前交互点
end

--交互02 献花后 重复旁白对话
function XLevel6001Present:OnOfferFlowerInteractStart02(eventType, eventArgs)
    ---暂时关闭交互
    self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._OfferFlowerPlaceID02, false)
end
--endregion

--region 电梯
--初始化参数
function XLevel6001Present:InitTrafficHubElevator()
    self._TrafficHubElevator = {
        PlaceId = 4000016, --自己的place id
        UpTrigger = 4000017, --上层触发器
        DownTrigger = 4000018, --下层触发器
        State = ETrafficHubElevatorState.forbidden, --初始电梯在上层且被禁用
        CD = 3, --没用上 现在直接走的监听移动
        NPC01 = 4000005, --修好前npc
        NPC02 = 4000060, --修好后npc
        ADstate = 1, --电梯广告状态，0-无广告；1-有广告
    }
    self.TrafficHubElevatorUUid = self._proxy:GetNpcUUID(self._TrafficHubElevator.PlaceId)
    if self._proxy:IsQuestObjectiveFinished(60040101) then
        --如果剧情播放完了，就隐藏NPC1显示NPC2并设置对应的状态
        self._TrafficHubElevator.State = ETrafficHubElevatorState.Up --把电梯状态设置为在上层
        self._proxy:LoadLevelNpc(self._TrafficHubElevator.NPC02) --加载好哥们
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._TrafficHubElevator.PlaceId, true) --设置电梯为可交互状态
        self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId, "FxSkyGardenDtiTouping", { x = 1, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }, { x = 1, y = 1, z = 1 })

    elseif (not self._proxy:IsQuestObjectiveFinished(60040101)) then
        --剧情没有播放过的话
        self._TrafficHubElevator.State = ETrafficHubElevatorState.forbidden --把电梯状态设置为被禁用
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._TrafficHubElevator.PlaceId, false) --设置电梯为不可交互状态
        self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId, "FxSkyGardenDtihuangLoop", { x = 1, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }, { x = 1, y = 1, z = 1 })

    end
    -- 移动组件节点：上 1 ；下 2
    --维修工程师对话选项：广告开启时 交互关-1；广告关闭时 交互开-2
end

--当玩家靠近电梯时，自动移动到玩家所在层
function XLevel6001Present:OnTrafficHubElevatorEnterUP() --电梯上升行为，触发逻辑在监听进入触发器中
    if self._TrafficHubElevator.State == ETrafficHubElevatorState.Down then
        --只有电梯在下层时，才会往上走
        self._proxy:MoveSceneObjectToNode(self._TrafficHubElevator.PlaceId, 1)
        self._proxy:PlaySound(5500141,ETargetActorType.Npc,self.TrafficHubElevatorUUid,-1,-1,-1,-1,-1,-1,-1)
        self._TrafficHubElevator.State = ETrafficHubElevatorState.Moving
    end
end

function XLevel6001Present:OnTrafficHubElevatorEnterDOWN()--电梯下降行为，触发逻辑在监听进入触发器中
    if self._TrafficHubElevator.State == ETrafficHubElevatorState.Up then
        self._proxy:MoveSceneObjectToNode(self._TrafficHubElevator.PlaceId, 2)
        self._proxy:PlaySound(5500141,ETargetActorType.Npc,self.TrafficHubElevatorUUid,-1,-1,-1,-1,-1,-1,-1)
        self._TrafficHubElevator.State = ETrafficHubElevatorState.Moving
    end
end

--如果是moving的话就先不动 后面再看会不会出现边界情况
--电梯停稳后，设置电梯状态并重设对应交互开关
function XLevel6001Present:SetTrafficHubElevatorState(state)
    self._TrafficHubElevator.State = state

end

--玩家交互电梯
function XLevel6001Present:OnTrafficHubElevatorInteractStart()
    ---根据所在层移动到另一层

    self._proxy:AddTimerTask(1,function() --延迟1s之后播放后续
        self._proxy:PlaySound(5500141,ETargetActorType.Npc,self.TrafficHubElevatorUUid,-1,-1,-1,-1,-1,-1,-1)--播放电梯运行音效
        if self._TrafficHubElevator.State == ETrafficHubElevatorState.Up then --电梯在上层时，往下走
            self._proxy:MoveSceneObjectToNode(self._TrafficHubElevator.PlaceId, 2)
            self._TrafficHubElevator.State = ETrafficHubElevatorState.Moving --变成moving 以免移动期间误触
        elseif self._TrafficHubElevator.State == ETrafficHubElevatorState.Down then --电梯在下层时，往上走
            self._proxy:MoveSceneObjectToNode(self._TrafficHubElevator.PlaceId, 1)
            self._TrafficHubElevator.State = ETrafficHubElevatorState.Moving --变成moving 以免移动期间误触
        end
        ---根据广告状态播广告
        if self._TrafficHubElevator.ADstate == 1 then
            self._proxy:PlayDramaCaption("Caption600145")
        elseif self._TrafficHubElevator.ADstate == 0 then
            self._proxy:PlayDramaCaption("Caption600146")
        end
    end)

end

--玩家交互常驻npc时，切换广告开关 这一段好像除了广告没被加载出来以外都正常
function XLevel6001Present:SwitchTrafficHubElevatorAD() --电梯NPC交互后切换为无广告状态
    if self._TrafficHubElevator.ADstate == 1 then
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.Npc, self._TrafficHubElevator.NPC02, false) --暂时关闭交互ui
        self._proxy:SetNpcInteractOneOptionActive(self._TrafficHubElevator.NPC02, 2)
        self._TrafficHubElevator.ADstate = 0
    else  --电梯NPC交互后切换为有广告状态
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.Npc, self._TrafficHubElevator.NPC02, false)
        self._proxy:SetNpcInteractOneOptionActive(self._TrafficHubElevator.NPC02, 1)
        self._TrafficHubElevator.ADstate = 1
    end
end
--endregion

--region 扭蛋机
--初始化参数
function XLevel6001Present:InitGacha()
    self._GachaPlaceID01 = 4000004
    self._GachaPlaceID02 = 4000021


    self._GachaCaptionPool = {
        "Caption600127",
        "Caption600128",
        "Caption600129",
    }
    self._GachaUUid01 = self._proxy:GetNpcUUID(self._GachaPlaceID01)
    self._GachaUUid02 = self._proxy:GetNpcUUID(self._GachaPlaceID02)
    self._proxy:SetSceneObjectInteractOneOptionActive(self._GachaPlaceID01, 1) --初始化 只显示第一个选项
    self._proxy:SetSceneObjectInteractOneOptionActive(self._GachaPlaceID02, 1)
end
--交互事件
function XLevel6001Present:OnGachaInteractStart(eventType, eventArgs)
    if eventArgs.OptionId == 1 then
        --投入硬币
        if eventArgs.TargetPlaceId == self._GachaPlaceID01 then --如果交互的是01就给01播放音效，交互02给02播放
            self._proxy:PlaySound(5500148,ETargetActorType.Npc,self._GachaUUid01,-1,-1,-1,-1,-1,-1,-1)
        elseif eventArgs.TargetPlaceId == self._GachaPlaceID02 then
            self._proxy:PlaySound(5500148,ETargetActorType.Npc,self._GachaUUid02,-1,-1,-1,-1,-1,-1,-1)
        end
        self._proxy:SetSceneObjectInteractOneOptionActive(eventArgs.TargetPlaceId, 2)
    elseif eventArgs.OptionId == 2 then
        --旋转按钮
        if eventArgs.TargetPlaceId == self._GachaPlaceID01 then --如果交互的是01就给01播放音效，交互02给02播放
            self._proxy:PlaySound(5500149,ETargetActorType.Npc,self._GachaUUid01,-1,-1,-1,-1,-1,-1,-1)
        elseif eventArgs.TargetPlaceId == self._GachaPlaceID02 then
            self._proxy:PlaySound(5500149,ETargetActorType.Npc,self._GachaUUid02,-1,-1,-1,-1,-1,-1,-1)
        end
        self._proxy:SetSceneObjectInteractOptionActive(eventArgs.TargetPlaceId, 2, false)
        self._proxy:AddTimerTask(2,function() --延迟2s播放交互成功音效
            self._proxy:PlayDramaCaption(self._GachaCaptionPool[math.random(1, 3)]) --随机播一句
            if eventArgs.TargetPlaceId == self._GachaPlaceID01 then --如果交互的是01就给01播放音效，交互02给02播放
                self._proxy:PlaySound(5500150,ETargetActorType.Npc,self._GachaUUid01,-1,-1,-1,-1,-1,-1,-1)
            elseif eventArgs.TargetPlaceId == self._GachaPlaceID02 then
                self._proxy:PlaySound(5500150,ETargetActorType.Npc,self._GachaUUid02,-1,-1,-1,-1,-1,-1,-1)
            end
        end)

    end
end
--endregion

--region 理发店镜子
--初始化参数
function XLevel6001Present:InitMirror()
    self._MirrorPlaceID = 4000012
    self._MirrorInteractedTimes = 0 --交互次数
    self._MirrorMaxTime = 3 --最大交互次数
end
--交互事件
function XLevel6001Present:OnMirrorInteractStart()
    if self._MirrorInteractedTimes < self._MirrorMaxTime then
        self._proxy:PlayDrama("Drama60010146") --前三次播放描述
    elseif self._MirrorInteractedTimes == self._MirrorMaxTime then
        --self._proxy:PlayDrama()
        self._proxy:PlayDrama("Drama60010133")--最后播放正牌的
        self._proxy:UnloadSceneObject(self._MirrorPlaceID) --卸载交互点
    elseif self._MirrorInteractedTimes > self._MirrorMaxTime then
        --大于就什么也不做 理论上不会大于，因为等于的时候就已经关交互了
    end
    self._MirrorInteractedTimes = self._MirrorInteractedTimes + 1
end
--endregion

--region 情报社相关
local EInformationEventState = {
    Before = 0, --未开始
    Underway = 1, --进行中
    After = 2, --已结束
}

--初始化参数
function XLevel6001Present:InitInformation()
    self._InformationParam = {
        WaitressStartID = 4000003, --女服务生初始ID
        Waitress01Underway = 4000056, --选择选项1后，女服务生ID
        Waitress01After = 4000057, --选择选项1后，女服务生常驻ID
        Waitress02After = 4000058, --选择选项2后女服务升常驻ID
        Student01After = 4000001, --选择选项1后，刷新的女学生ID
        Student02After = 4000002, --选择选项2后，刷新的女学生ID

    }
    if self._proxy:IsQuestObjectiveFinished(60020201) then --检测到玩家选完了选项1
        self._proxy:LoadLevelNpc(self._InformationParam.Waitress01After) --加载后续1的服务生
        self._proxy:LoadLevelNpc(self._InformationParam.Student01After) --加载后续1的学生
    elseif self._proxy:IsQuestObjectiveFinished(60020301) then --检测到玩家选了选项2
        self._proxy:LoadLevelNpc(self._InformationParam.Waitress02After) --加载后续2的服务生
        self._proxy:LoadLevelNpc(self._InformationParam.Student02After)--加载后续2的学生
    elseif self._proxy:IsQuestObjectiveFinished(60020102) and (not self._proxy:IsQuestObjectiveFinished(60020201)) and (not self._proxy:IsQuestObjectiveFinished(60020301)) then--如果玩家直接跳过了，那就按照选项1来
        self._proxy:UnloadLevelNpc(self._InformationParam.WaitressStartID) --卸载初始的NPC
        self._proxy:LoadLevelNpc(self._InformationParam.Waitress01Underway) --加载选项1NPC
        self._proxy:LoadLevelNpc(self._InformationParam.Student01After) --加载选项1的学生
    elseif (not self._proxy:IsQuestObjectiveFinished(60020201)) and (not self._proxy:IsQuestObjectiveFinished(60020301)) and (not self._proxy:IsQuestObjectiveFinished(60020102)) then--如果什么都没做，那就直接加载初始的
        self._proxy:LoadLevelNpc(self._InformationParam.WaitressStartID) --加载初始服务生
    end
end

--endregion

--region 纪念广场跑步者相关
--初始化参数
function XLevel6001Present:InitSqureRunner()
    self._RunnerParam = {
        Line1ID = 3900005, --第一条路线ID
        Line2ID = 3900006, --第二条路线ID
        Runner01PlaceID = 3900023, --训人的哥们ID
        Runner02PlaceID = 3900024, --被训的哥们ID
        TriggerPlaceID = 3900011, --触发盒ID
        RunnerStartTriggerPlaceID = 3900012, --起步用触发器ID
    }
    self._RunnerBubblePool = { --随机对话池
        "1289",
        "1290",
        "1291",
        "1292",
    }
    self._proxy:LoadLevelNpc(self._RunnerParam.Runner01PlaceID) --加载两哥们
    self._proxy:LoadLevelNpc(self._RunnerParam.Runner02PlaceID)
    self.Runner01UUID = self._proxy:GetNpcUUID(self._RunnerParam.Runner01PlaceID)--抓一下两哥们的UUID
    self.Runner02UUID = self._proxy:GetNpcUUID(self._RunnerParam.Runner02PlaceID)
    self._proxy:NpcMoveByRoute(self.Runner01UUID, self._RunnerParam.Line1ID, ENpcMoveType.Run)
    self._proxy:NpcMoveByRoute(self.Runner02UUID, self._RunnerParam.Line2ID, ENpcMoveType.Run)
end
--进入触发器时随机播放气泡对话
function XLevel6001Present:OnRunnerBubbleTrigger(eventType, eventArgs)
    self.RandomRunnerBubble = self._RunnerBubblePool[self._proxy:Random(1, 4)] --随机一个数出来
    if self.RandomRunnerBubble == "1292" then
        --如果随机到了唯一一句学生说的，那就让一号播放，否则让二号播放
        self._proxy:PlayDramaBubble(ETargetActorType.Npc, self.Runner01UUID, self.RandomRunnerBubble)
    elseif self.RandomRunnerBubble ~= "1292" then
        --如果不是学生说的
        self._proxy:PlayDramaBubble(ETargetActorType.Npc, self.Runner02UUID, self.RandomRunnerBubble)
    end
end

--endregion

--region 跳舞机器人相关
local ETrafficDanceRobotState = {
    Prepare = 0,
    Dancing = 1,
    Done = 2,
}
function XLevel6001Present:InitDanceRobot()
    self._DanceRobotParam = {
        RobotPlaceID = 4000047, --小机器人的ID
        BoxPlaceID = 4000010,
        Audience01PlaceID = 4000048,
        Audience02PlaceID = 4000050,
        Audience03PlaceID = 4000054,
    }
    self.RobotUUid = self._proxy:GetNpcUUID(self._DanceRobotParam.RobotPlaceID) --小机器人uuid
    self.Audience01UUid = self._proxy:GetNpcUUID(self._DanceRobotParam.Audience01PlaceID) --观众1uuid
    self.Audience02UUid = self._proxy:GetNpcUUID(self._DanceRobotParam.Audience02PlaceID) --观众2uuid
    self.Audience03UUid = self._proxy:GetNpcUUID(self._DanceRobotParam.Audience03PlaceID)--观众3uuid
    --self.Audience01Rot = self._proxy:GetNpcRotation(self.Audience01UUid) --获取一下观众01的初始朝向
    --self.Audience02Rot = self._proxy:GetNpcRotation(self.Audience02UUid) --观众02的朝向
    --self.Audience03Rot = self._proxy:GetNpcRotation(self.Audience03UUid)--观众03的朝向

    self._DanceRobotState = ETrafficDanceRobotState.Prepare
    if self._proxy:IsQuestObjectiveFinished(60050101) then
        self._proxy:LoadLevelNpc(self._DanceRobotParam.RobotPlaceID) --如果完成了的话那就加载机器人
        self.RobotUUid = self._proxy:GetNpcUUID(4000047)
        self._proxy:SetNpcAnimationLayer(self.RobotUUid, 1)
    end
end

--跳舞事件
function XLevel6001Present:OnRobotDancing(eventType, eventArgs) --开始跳舞逻辑

    self._proxy:SetNpcAnimationLayer(self.RobotUUid, 1)
    self._proxy:PlayNpcCustomPerformAnim(self.RobotUUid, "Dance_Loop", 0, 0, false, {}, true)
    self._proxy:BindNpcEffect(self._DanceRobotParam.RobotPlaceID, "FxSkyGardenJqrTiaowuJgd", { x=0, y=1.8, z=0 }, { x=0, y=0, z=0 }, { x = 1, y = 1, z = 1 })
    self._proxy:BindNpcEffect(self._DanceRobotParam.RobotPlaceID, "FxSkyGardenJqrTiaowuWutai", { x=0, y=0, z=0 }, { x=0, y=0, z=0 }, { x = 1, y = 1, z = 1 })
    self._proxy:PlaySound(5500164,ETargetActorType.Npc,self.RobotUUid,-1,-1,-1,-1,self._DanceTime,-1,-1)
    self.RobotDanceStartTime = self._proxy:GetNpcTime(self.RobotUUid)--记录一下当前的时间
    self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.Npc, self._DanceRobotParam.RobotPlaceID,false)
    self._proxy:TurnNpc(self.Audience01UUid,self.RobotUUid,"Drama_NPC_Claps",false)
    self._proxy:PlayDramaBubble(ETargetActorType.Npc,self.Audience01UUid,"1252")
    self._proxy:TurnNpc(self.Audience02UUid,self.RobotUUid,"Drama_NPC_Claps",false)
    self._proxy:PlayDramaBubble(ETargetActorType.Npc,self.Audience02UUid,"1304")
    self._proxy:TurnNpc(self.Audience03UUid,self.RobotUUid,"Drama_Stand_06",false)
    self._proxy:PlayDramaBubble(ETargetActorType.Npc,self.Audience03UUid,"1305")
    self._DanceRobotState = ETrafficDanceRobotState.Dancing --设置状态为1
    self._DancingTimer = 0
end

function XLevel6001Present:StopDancing(dt) --跳舞停止逻辑，开始跳舞后等待一定时间结束
    if self._DanceRobotState == ETrafficDanceRobotState.Dancing then
        self._DancingTimer = self._DancingTimer + dt
        if self._DancingTimer >= self._DanceTime then --动作时间超过之后
            self._proxy:StopNpcPerformAnim(self.RobotUUid) --停止播放跳舞动作
            self._proxy:SetNpcAnimationLayer(self.RobotUUid, 0)--设置回正常层级
            self._proxy:PlayNpcCustomPerformAnim(self.RobotUUid, "Drama_Stand_01", 0, 0, false, {}, true) --播放战立动作
            self._proxy:UnBindNpcEffect(self._DanceRobotParam.RobotPlaceID, "FxSkyGardenJqrTiaowuJgd") --删除两个特效
            self._proxy:UnBindNpcEffect(self._DanceRobotParam.RobotPlaceID, "FxSkyGardenJqrTiaowuWutai")
            self._DanceRobotState = ETrafficDanceRobotState.Done
            self._proxy:TurnPos(self.Audience01UUid,{x=313.72,y=126.82,z=180.02},"Drama_NPC_Claps",false)
            self._proxy:TurnPos(self.Audience02UUid,{x=305.13,y=126.82,z=174.89},"StandPhone",false)
            self._proxy:TurnPos(self.Audience03UUid,{x=304.7,y=126.82,z=174.97},"Drama_NPC_Dance_01",true)
            self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.Npc,self._DanceRobotParam.RobotPlaceID,true)
            self._DancingTimer = 0
        end
    end
end
--endregion

--region （通用函数）查找table中是否包含某元素
local EWeaponState = {
    A = 1,
    B = 2
}

function XLevel6001Present:IsInclude(value, tab)
    for k, v in ipairs(tab) do
        if v == value then
            return true
        end
    end
    return false
end

function XLevel6001Present:Weapon()
    self._WeaponPlaceID = 3200019
    self._proxy:SetSceneObjectInteractOneOptionActive(self._WeaponPlaceID, 1)
    self._WeaponState = EWeaponState.A
end

function XLevel6001Present:WeaponStart()
    if self._WeaponState == EWeaponState.A then
        self._proxy:SetSceneObjectInteractOneOptionActive(self._WeaponPlaceID, 2)
        self._WeaponState = EWeaponState.B
    elseif self._WeaponState == EWeaponState.B then
        self._proxy:SetSceneObjectInteractOneOptionActive(self._WeaponPlaceID, 1)
        self._WeaponState = EWeaponState.A
    end
end

--endregion


return XLevel6001Present