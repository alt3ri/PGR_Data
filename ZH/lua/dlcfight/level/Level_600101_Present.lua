local XLevel6001Present = XDlcScriptManager.RegLevelPresentScript(600101)
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local Timer = require("Level/Common/XTaskScheduler")


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
    --endregion
    self._QuestObj3020 = 3200035
end

---@param dt number @ delta time
function XLevel6001Present:Update(dt)
    --每帧更新逻辑,暂时没有需要tick的内容，需要的话去抄5001
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
            XLog.Debug("触发响应事件 献花交互01")
        elseif eventArgs.TargetPlaceId == self._OfferFlowerPlaceID02 then
            self:OnOfferFlowerInteractStart02(eventType, eventArgs) --献花交互02
            XLog.Debug("触发响应事件 献花交互02")
        elseif eventArgs.TargetPlaceId == self._TrafficHubElevator.PlaceId then
            self:OnTrafficHubElevatorInteractStart(eventType, eventArgs) --交互电梯
            XLog.Debug("交互电梯-交互类型"..eventArgs.Type) -- 这个交互类型是指ui类型，，，，，，，
        elseif eventArgs.TargetPlaceId == self._TrafficHubElevator.NPC02 then
            self:SwitchTrafficHubElevatorAD(eventType, eventArgs) --交互npc切换电梯广告
            XLog.Debug("交互电梯npc-交互类型"..eventArgs.Type)
        elseif eventArgs.TargetPlaceId == self._GachaPlaceID01 or eventArgs.TargetPlaceId == self._GachaPlaceID02 then
            self:OnGachaInteractStart(eventType, eventArgs)--交互扭蛋机
        elseif eventArgs.TargetPlaceId == self._MirrorPlaceID then
            self:OnMirrorInteractStart(eventType, eventArgs) --交互理发店镜子
        end

    end

    ---监听Drama播放结束
    if eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama302003" then --战斗支线对话跳转
            local dramaOptions = self._proxy:GetDramaDialogFirstDecisionId(2)
            if dramaOptions == 1 then        --选择了对话选项1
                self._proxy:RequestEnterInstLevel(6002, { x = 33.35, y = 0, z = 21.53  }, { x = 0, y = 0, z = 0 })
            end
        elseif eventArgs.DramaName == "Drama302002" then
            local dramaOptions = self._proxy:GetDramaDialogFirstDecisionId(3)
            if dramaOptions == 1 then --选择了对话选项1
                self._proxy:RequestEnterInstLevel(6003, { x = 33.35, y = 0, z = 21.53 }, { x = 0, y = 0, z = 0 })
            end
        elseif eventArgs.DramaName == "Drama60010110" then --跳舞机器人的对话，先随便抓个DramaID凑合一下后面记得改
            XLog.Debug("抓到了机器人Drama结束")
            local dramaOptions = self._proxy:GetDramaDialogFirstDecisionId(11)
            XLog.Debug("抓一下玩家选择的选项ID"..dramaOptions)
            if dramaOptions == 2 then        --选择了对话选项1
                self:OnRobotDancing(eventType,eventArgs) --播放动作与特效
                XLog.Debug("成功让机器人跳舞")
            end
        elseif self:IsInclude(eventArgs.DramaName,self._WishPondTimelinePool) then --许愿池 随机对话
            self._proxy:SetActorInteractableComponentEnableByPlaceId(2,self._WishPondPlaceID,true)

        end

    end

    ---Trigger事件
    if eventType == EWorldEvent.ActorTrigger then
        if self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then --如果触发事件的NPC是玩家的话，可触发如下逻辑
            if eventArgs.TriggerState == ETriggerState.Enter then --事件是进入触发器
                if eventArgs.HostSceneObjectPlaceId == self._TrafficHubElevator.UpTrigger then --如果是玩家进入上层电梯的触发器
                    self:OnTrafficHubElevatorEnterUP(eventType, eventArgs)--电梯移至上层，并设置状态
                    if self._TrafficHubElevator.ADstate == 1 then --如果有广告，那就播放广告特效
                        self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId,"FxSkyGardenDtihuangTPtongxing",{x = 0, y = 0, z = 0},{x = 0, y = 0, z = 0},{x = 1, y = 1, z = 1})
                    elseif self._TrafficHubElevator.ADstate == 0 then --如果没有广告那就播放无广告特效
                        self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId,"FxSkyGardenDtihuangtongxing",{x = 0, y = 0, z = 0},{x = 0, y = 0, z = 0},{x = 1, y = 1, z = 1})
                    end
                end
                if eventArgs.HostSceneObjectPlaceId == self._TrafficHubElevator.DownTrigger then  --进入下层电梯的触发器
                    self:OnTrafficHubElevatorEnterDOWN(eventType, eventArgs)--电梯移至下层，并设置状态
                    if self._TrafficHubElevator.ADstate == 1 then --如果有广告，那就播放广告特效
                        self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId,"FxSkyGardenDtihuangTPtongxing",{x = 0, y = 0, z = 0},{x = 0, y = 0, z = 0},{x = 1, y = 1, z = 1})
                    elseif self._TrafficHubElevator.ADstate == 0 then --如果没有广告那就播放无广告特效
                        self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId,"FxSkyGardenDtihuangtongxing",{x = 0, y = 0, z = 0},{x = 0, y = 0, z = 0},{x = 1, y = 1, z = 1})
                    end
                end
            end
        end
        if eventArgs.EnteredActorUUID == self.Runner01UUID or eventArgs.EnteredActorUUID == self.Runner02UUID then --如果是跑步者进入了触发器
            if  eventArgs.TriggerState == ETriggerState.Enter then
                if eventArgs.HostSceneObjectPlaceId == self._RunnerParam.RunnerStartTriggerPlaceID then --进入的触发器是起步用触发器
                    self._proxy:NpcMoveByRoute(self.Runner01UUID,self._RunnerParam.Line1ID,2) --让他沿着路径1移动
                    self._proxy:NpcMoveByRoute(self.Runner02UUID,self._RunnerParam.Line2ID,2)
                    XLog.Debug("成功使NPC沿路径移动")
                elseif eventArgs.HostSceneObjectPlaceId == self._RunnerParam.TriggerPlaceID then
                    self:OnRunnerBubbleTrigger(eventType,eventArgs) --触发一次随机对话
                    XLog.Debug("播放随机对话")
                end
            end

        end
    end


    ---监听底端字幕（简易台词）播放完成后，恢复对应物件交互
    if eventType == EWorldEvent.DramaCaptionEnd then
        local caption = eventArgs.CaptionName
        if caption =="Caption600112" then --许愿池 最后一句话
            self._proxy:SetActorInteractableComponentEnableByPlaceId(2,self._WishPondPlaceID,true)
        elseif caption =="Caption600104" then --献花后
            self._proxy:SetActorInteractableComponentEnableByPlaceId(2,self._OfferFlowerPlaceID02,true)
        elseif caption =="Caption600127" or caption == "Caption600128" or caption == "Caption600129" then --扭蛋机 任意一个扭蛋扭出来了之后就重置所有
            self._proxy:SetSceneObjectInteractOneOptionActive(self._GachaPlaceID01,1)--设置场景物件仅显示某个交互选项
            self._proxy:SetSceneObjectInteractOneOptionActive(self._GachaPlaceID02,1)
        elseif caption =="Caption600133" or caption == "Caption600134" then
            self._proxy:SetActorInteractableComponentEnableByPlaceId(1,self._TrafficHubElevator.NPC02,true) --电梯npc
        end
    end

    ---监听场景物件停止移动
    if eventType == EWorldEvent.SceneObjectMoveStop then
        XLog.Debug("监听到场景物件停止移动")
        if eventArgs.SceneObjectId == self._TrafficHubElevator.PlaceId then --如果物件是电梯，则根据目标点设置状态
            XLog.Debug("停止移动的物件为电梯")
            self:SetTrafficHubElevatorState(eventArgs.ToNodeId)
            if self._TrafficHubElevator.ADstate == 1 then --如果有广告，那就停止播放广告特效
                self._proxy:UnBindSceneObjectEffect(self._TrafficHubElevator.PlaceId,"FxSkyGardenDtihuangTPtongxing")
            elseif self._TrafficHubElevator.ADstate == 0 then --如果没有广告那就停止播放无广告特效
                self._proxy:UnBindSceneObjectEffect(self._TrafficHubElevator.PlaceId,"FxSkyGardenDtihuangtongxing")
            end
        end
    end

    ---监听交互结束
    if eventType == EWorldEvent.NpcInteractComplete then
        XLog.Debug("监听到NPC交互结束")
        if eventArgs.TargetPlaceId == self._TrafficHubElevator.NPC01 then
            XLog.Debug("监听到开启电梯的任务已经完毕")
            self._proxy:SetActorInteractableComponentEnableByPlaceId(1,self._TrafficHubElevator.NPC01,false) --禁止NPC01交互
            self._proxy:UnloadLevelNpc(self._TrafficHubElevator.NPC01) --卸载NPC1
            self._proxy:LoadLevelNpc(self._TrafficHubElevator.NPC02) --加载NPC2，
            self._proxy:SetNpcInteractOneOptionActive(self._TrafficHubElevator.NPC02,1)--设置npc仅显示某个交互选项
            self._TrafficHubElevator.State = 1 --把电梯状态设置为在上层
            self._proxy:UnBindSceneObjectEffect(self._TrafficHubElevator.PlaceId,"FxSkyGardenDtihuangLoop") --删除掉电梯原有的特效
            self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId,"FxSkyGardenDtihuangBianse",{x = 0, y = 0, z = 0},{x = 0, y = 0, z = 0},{x = 1, y = 1, z = 1})
            self._proxy:SetActorInteractableComponentEnableByPlaceId(2,self._TrafficHubElevator.PlaceId,true) --设置电梯为可交互状态
            XLog.Debug("电梯任务结束，状态更改完成 电梯状态："..self._TrafficHubElevator.State.."广告状态："..self._TrafficHubElevator.ADstate)
        end
    end

    ---监听NPC动作状态改变
    if eventArgs == EWorldEvent.NpcActionStateChange then
        if
        end

    end
    --endregion


    --------------事件本体---------------

    --region 许愿池打捞
    --初始化参数
    function XLevel6001Present:InitWishingPond()
        self._WishPondPlaceID = 3900004
        self._WishPondCaptionPool= {
            "Caption600106",
            "Caption600107",
            "Caption600108",
            "Caption600109",
            "Caption600110",
            "Caption600111",
        }
        self._WishPondTimelinePool={ --替换成播timeline
            "Drama60010137",
            "Drama60010138",
            "Drama60010139",
            "Drama60010140",
            "Drama60010141",
            "Drama60010142",
            "Drama60010143",
        }
        self._WishPondPlayedCaptions={}
        self._WishPondCurrentCaptionIndex= 1
        self._WishPondFinalCaption="Caption600112"
        for i = #self._WishPondTimelinePool, 2, -1 do
            local j = math.random(i)
            self._WishPondTimelinePool[i], self._WishPondTimelinePool[j] = self._WishPondTimelinePool[j], self._WishPondTimelinePool[i]
        end
        ---DS写的 #应该是代表元素数量。这一整段是通过洗牌算法预先随机好，打乱原pool的排序（因此没有创建一个新的数组来存新顺序）。
        XLog.Debug("许愿池随机对话初始化完成")
        XLog.Debug(self._WishPondTimelinePool[1],self._WishPondTimelinePool[2],self._WishPondTimelinePool[3],self._WishPondTimelinePool[4],self._WishPondTimelinePool[5],self._WishPondTimelinePool[6])
    end
    --许愿池随机台词
    function XLevel6001Present:OnWishingPondNpcInteractStart(eventType, eventArgs)
        if eventArgs.TargetPlaceId == self._WishPondPlaceID then
            --self._proxy:PlayDramaCaption(self._WishPondTimelinePool[self._proxy:Random(1, 6)]) --纯随机，会随到重复的

            if #self._WishPondPlayedCaptions >= #self._WishPondTimelinePool then --如果播完了，就播最后一句，最后一句是caption
                self._proxy:PlayDramaCaption(self._WishPondFinalCaption)
                XLog.Debug("许愿池-播放最后一句对话".."已播对话"..#self._WishPondPlayedCaptions.."总对话数"..#self._WishPondTimelinePool)
            else
                local dialog = self._WishPondTimelinePool[self._WishPondCurrentCaptionIndex]
                self._proxy:PlayDrama(dialog)
                table.insert(self._WishPondPlayedCaptions, dialog)
                self._WishPondCurrentCaptionIndex = self._WishPondCurrentCaptionIndex + 1
                ---DS写的，按顺序播
                XLog.Debug("许愿池-播放已随机好的对话"..dialog)
            end

            ---暂时关闭交互
            self._proxy:SetActorInteractableComponentEnableByPlaceId(2,self._WishPondPlaceID,false)
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
        self._proxy:SetActorInteractableComponentEnableByPlaceId(2,self._OfferFlowerPlaceID02,false)
    end
    --endregion

    --region 电梯
    local ETrafficHubElevatorState = { --局部变量好像没法在上面的响应事件里用
        Moving = 0,    --运行中
        Up = 1,        --在上层
        Down = 2,      --在下层
        forbidden = 3, --被禁用
    }
    --初始化参数
    function XLevel6001Present:InitTrafficHubElevator()
        self._TrafficHubElevator = {
            PlaceId = 4000016, --自己的place id
            UpTrigger = 4000017,        --上层触发器
            DownTrigger = 4000018,      --下层触发器
            State = 3, --初始电梯在上层且被禁用
            CD = 3,--没用上 现在直接走的监听移动
            NPC01 = 4000005, --修好前npc
            NPC02 = 4000060, --修好后npc
            ADstate = 1, --电梯广告状态，0-无广告；1-有广告
        }
        XLog.Debug("电梯状态："..self._TrafficHubElevator.State.."广告状态："..self._TrafficHubElevator.ADstate)
        if self._proxy:IsQuestObjectiveFinished(60040101) then --如果剧情播放完了，就隐藏NPC1显示NPC2并设置对应的状态
            XLog.Debug("准备开始设置剧情完成的状态")
            self._proxy:LoadLevelNpc(self._TrafficHubElevator.NPC02) --加载NPC2，
            self._proxy:SetNpcInteractOneOptionActive(self._TrafficHubElevator.NPC02,1)--设置npc仅显示某个交互选项
            self._TrafficHubElevator.State = ETrafficHubElevatorState.Up --把电梯状态设置为在上层
            self._proxy:SetActorInteractableComponentEnableByPlaceId(2,self._TrafficHubElevator.PlaceId,true) --设置电梯为可交互状态
            self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId,"FxSkyGardenDtihuangTPtongxing",{x = 0, y = 0, z = 0},{x = 0, y = 0, z = 0},{x = 1, y = 1, z = 1})
            XLog.Debug("电梯初始化完成 剧情已完成 电梯状态："..self._TrafficHubElevator.State.."广告状态："..self._TrafficHubElevator.ADstate)
        elseif (not self._proxy:IsQuestObjectiveFinished(60040101)) then   --剧情没有播放过的话
            self._proxy:LoadLevelNpc(self._TrafficHubElevator.NPC01) --加载NPC1，
            self._proxy:SetNpcInteractOneOptionActive(self._TrafficHubElevator.NPC01,1)--设置npc仅显示某个交互选项
            self._TrafficHubElevator.State = 3 --把电梯状态设置为被禁用
            self._proxy:SetActorInteractableComponentEnableByPlaceId(2,self._TrafficHubElevator.PlaceId,false) --设置电梯为不可交互状态
            self._proxy:BindSceneObjectEffect(self._TrafficHubElevator.PlaceId,"FxSkyGardenDtihuangLoop",{x = 0, y = 0, z = 0},{x = 0, y = 0, z = 0},{x = 1, y = 1, z = 1})
            XLog.Debug("电梯初始化完成 剧情未完成 电梯状态："..self._TrafficHubElevator.State.."广告状态："..self._TrafficHubElevator.ADstate)
        end

        -- 移动组件节点：上 1 ；下 2
        --维修工程师对话选项：广告开启时 交互关-1；广告关闭时 交互开-2
    end
    --当玩家靠近电梯时，自动移动到玩家所在层
    function XLevel6001Present:OnTrafficHubElevatorEnterUP()
        XLog.Debug("触发响应事件 进入电梯 上层触发器")
        if self._TrafficHubElevator.State == 2 then --只有电梯在下层时，才会往上走
            self._proxy:MoveSceneObjectToNode(self._TrafficHubElevator.PlaceId,1)
            self._TrafficHubElevator.State = 0
        end
    end
    function XLevel6001Present:OnTrafficHubElevatorEnterDOWN()
        XLog.Debug("触发响应事件 进入电梯 下层触发器")
        if self._TrafficHubElevator.State == 1 then
            self._proxy:MoveSceneObjectToNode(self._TrafficHubElevator.PlaceId,2)
            self._TrafficHubElevator.State = 0
        end
    end --如果是moving的话就先不动 后面再看会不会出现边界情况
    --电梯停稳后，设置电梯状态并重设对应交互开关
    function XLevel6001Present:SetTrafficHubElevatorState(state)
        self._TrafficHubElevator.State = state
        XLog.Debug("电梯状态为 "..self._TrafficHubElevator.State)
    end
    --玩家交互电梯
    function XLevel6001Present:OnTrafficHubElevatorInteractStart()
        XLog.Debug("玩家进入电梯自身trigger")
        ---根据所在层移动到另一层
        if self._TrafficHubElevator.State == 1 then --电梯在上层时，往下走
            self._proxy:MoveSceneObjectToNode(self._TrafficHubElevator.PlaceId,2)
            self._TrafficHubElevator.State = 0 --变成moving 以免移动期间误触
        elseif self._TrafficHubElevator.State == 2 then --电梯在下层时，往上走
            self._proxy:MoveSceneObjectToNode(self._TrafficHubElevator.PlaceId,1)
            self._TrafficHubElevator.State = 0 --变成moving 以免移动期间误触
        end
        ---根据广告状态播广告
        if self._TrafficHubElevator.ADstate == 1 then
            self._proxy:PlayDramaCaption("Caption600145")
        elseif self._TrafficHubElevator.ADstate == 0 then
            self._proxy:PlayDramaCaption("Caption600146")
        end
    end
    --玩家交互常驻npc时，切换广告开关 这一段好像除了广告没被加载出来以外都正常
    function XLevel6001Present:SwitchTrafficHubElevatorAD()
        if self._TrafficHubElevator.ADstate == 1 then
            self._proxy:SetActorInteractableComponentEnableByPlaceId(1,self._TrafficHubElevator.NPC02,false) --暂时关闭交互ui
            self._proxy:SetNpcInteractOneOptionActive(self._TrafficHubElevator.NPC02,2)
            self._TrafficHubElevator.ADstate = 0
            XLog.Debug("切换为无广告")
        else
            self._proxy:SetActorInteractableComponentEnableByPlaceId(1,self._TrafficHubElevator.NPC02,false)
            self._proxy:SetNpcInteractOneOptionActive(self._TrafficHubElevator.NPC02,1)
            self._TrafficHubElevator.ADstate = 1
            XLog.Debug("切换为有广告")
        end
    end
    --endregion

    --region 扭蛋机
    --初始化参数
    function XLevel6001Present:InitGacha()
        self._GachaPlaceID01 = 4000004
        self._GachaPlaceID02 = 4000021
        self._GachaCaptionPool= {
            "Caption600127",
            "Caption600128",
            "Caption600129",
        }
        self._proxy:SetSceneObjectInteractOneOptionActive(self._GachaPlaceID01,1) --初始化 只显示第一个选项
        self._proxy:SetSceneObjectInteractOneOptionActive(self._GachaPlaceID02,1)
        XLog.Debug("扭蛋机初始化完成 ")
    end
    --交互事件
    function XLevel6001Present:OnGachaInteractStart(eventType, eventArgs)
        if eventArgs.OptionId == 1 then --投入硬币
            self._proxy:SetSceneObjectInteractOneOptionActive(eventArgs.TargetPlaceId,2)
        elseif eventArgs.OptionId == 2 then --旋转按钮
            self._proxy:SetSceneObjectInteractOptionActive(eventArgs.TargetPlaceId,2,false)
            self._proxy:PlayDramaCaption(self._GachaCaptionPool[math.random(1,3)]) --随机播一句
        end
    end
    --endregion

    --region 理发店镜子
    --初始化参数
    function XLevel6001Present:InitMirror()
        self._MirrorPlaceID = 4000012
        self._MirrorInteractedTimes = 0 --交互次数
        self._MirrorMaxTime = 3 --最大交互次数
        XLog.Debug("理发店镜子初始化完成 ")
    end
    --交互事件
    function XLevel6001Present:OnMirrorInteractStart()
        if self._MirrorInteractedTimes < self._MirrorMaxTime then
            self._proxy:PlayDrama("Drama60010132") --后续要替换为drama
        elseif self._MirrorInteractedTimes == self._MirrorMaxTime then
            --self._proxy:PlayDrama()
            self._proxy:PlayDrama("Drama60010133")--后续要替换为drama
            self._proxy:UnloadSceneObject(self._MirrorPlaceID) --卸载交互点
        elseif self._MirrorInteractedTimes > self._MirrorMaxTime then --大于就什么也不做 理论上不会大于，因为等于的时候就已经关交互了
        end
        self._MirrorInteractedTimes = self._MirrorInteractedTimes + 1
    end
    --endregion

    --region 情报社相关
    local EInformationEventState = {
        Before = 0,  --未开始
        Underway = 1, --进行中
        After = 2, --已结束
    }

    --初始化参数
    function XLevel6001Present:InitInformation()
        self._InformationParam = {
            WaitressStartID = 4000003, --女服务生初始ID
            Waitress01Underway = 4000056, --选择选项1后，女服务生ID
            Waitress01After = 4000057,  --选择选项1后，女服务生常驻ID
            Waitress02After = 4000057,  --选择选项2后女服务升常驻ID
            Student01After = 4000001, --选择选项1后，刷新的女学生ID
            Student02After = 4000002, --选择选项2后，刷新的女学生ID

        }
        XLog.Debug("情报社相关参数初始化完成，准备进行状态设置") --等待任务老师给到反馈确认后续逻辑是否需要Lua接入，我先写个参数初始化备用嘻嘻
    end

    --endregion

    --region 纪念广场跑步者相关
    --初始化参数
    function XLevel6001Present:InitSqureRunner()
        self._RunnerParam = {
            Line1ID = 3900005,--第一条路线ID
            Line2ID = 3900006, --第二条路线ID
            Runner01PlaceID = 3900023, --训人的哥们ID
            Runner02PlaceID = 3900024, --被训的哥们ID
            BubbleTip1ID = 1289,--气泡对话1ID
            BubbleTip2ID = 1290,--气泡对话2ID
            BubbleTip3ID = 1291,--气泡对话3ID
            BubbleTip4ID = 1292,--气泡对话4ID
            TriggerPlaceID = 3900011,--触发盒ID
            RunnerStartTriggerPlaceID = 3900012, --起步用触发器ID
        }
        self._RunnerBubblePool = { --随机对话池
            Bubble01 = 1289,
            Bubble02 = 1290,
            Bubble03 = 1291,
            Bubble04 = 1292,
        }
        self._proxy:LoadLevelNpc(self._RunnerParam.Runner01PlaceID) --加载两哥们
        self._proxy:LoadLevelNpc(self._RunnerParam.Runner02PlaceID)
        self.Runner01UUID = self._proxy:GetNpcUUID(self._RunnerParam.Runner01PlaceID)--抓一下两哥们的UUID
        self.Runner02UUID = self._proxy:GetNpcUUID(self._RunnerParam.Runner02PlaceID)
        self._proxy:NpcMoveByRoute(self.Runner01UUID,self._RunnerParam.Line1ID,2)
        XLog.Debug("成功让01跑起来")
        self._proxy:NpcMoveByRoute(self.Runner02UUID,self._RunnerParam.Line2ID,2)
        XLog.Debug("成功让02跑起来")
        XLog.Debug("成功加载完毕".."NPC1UUID"..self.Runner01UUID,"NPC02UUID"..self.Runner02UUID)
    end
    --进入触发器时随机播放气泡对话
    function XLevel6001Present:OnRunnerBubbleTrigger(eventType,eventArgs)
        self.RandomRunnerBubble = self._RunnerBubblePool[self._proxy:Random(1, 4)] --随机一个数出来
        if self.RandomRunnerBubble == 1292 then --如果随机到了唯一一句学生说的，那就让一号播放，否则让二号播放
            self._proxy:PlayDramaBubble(1,self.Runner01UUID,Self.RandomRunnerBubble)
            XLog.Debug("播放了学生说的话")
        elseif self.RandomRunnerBubble ~= 1292 then --如果不是学生说的
            self._proxy:PlayDramaBubble(1,self.Runner02UUID,Self.RandomRunnerBubble)
            XLog.Debug("播放了教官说的话")
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
        }
        if self._proxy:IsQuestObjectiveFinished(60050101) then
            self._proxy:LoadLevelNpc(self._DanceRobotParam.RobotPlaceID) --如果完成了的话那就加载机器人
        else
            self._proxy:LoadSceneObject(self._DanceRobotParam.BoxPlaceID) --没有完成就加载宝箱
        end

    end

    --跳舞事件
    function XLevel6001Present:OnRobotDancing(eventType , eventArgs)
        self.RobotUUid = self._proxy:GetNpcUUID(4000047)
        self._proxy:SetNpcAnimationLayer(self.RobotUUid,1)
        self._proxy:PlayNpcCustomPerformAnim(self.RobotUUid,"Dance_Loop",0,0,false,{},true)
        self._proxy:BindNpcEffect(4000047,"FxSkyGardenJqrTiaowuJgd",{0,0,0},{0,0,0},{1,1,1})
        self._proxy:BindNpcEffect(4000047,"FxSkyGardenJqrTiaowuWutai",{0,0,0},{0,0,0},{1,1,1})
        self.RobotDanceStartTime = self._proxy:GetNpcTime(self.RobotUUid)--记录一下当前的时间
    end
    function XLevel6001Present:StopDancing()
        if self._proxy:CheckNpcTime(self.RobotUUid,self.RobotDanceStartTime,6.84) then --动作时间超过之后
            self._proxy:SetNpcAnimationLayer(self.RobotUUid,0)--设置回正常层级
            self._proxy:PlayNpcCustomPerformAnim(self.RobotUUid,"Drama_Stand_01",0,0,false,{},true) --播放战立动作
            self._proxy:UnBindNpcEffect(4000047,"FxSkyGardenJqrTiaowuJgd") --删除两个特效
            self._proxy:UnBindNpcEffect(4000047,"FxSkyGardenJqrTiaowuWutai")
        end
    end


    ---endregion
end


--endregion
--region （通用函数）查找table中是否包含某元素
function XLevel6001Present:IsInclude(value,tab)
    for k,v in  ipairs(tab)do
        if v == value then
            XLog.Debug("该表中包含对应元素")
            return true
        end
    end
    XLog.Debug("该表中不包含对应元素")
    return false
end
--endregion


return XLevel6001Present
