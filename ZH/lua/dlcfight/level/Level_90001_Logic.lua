local XLevelScript90001 = XDlcScriptManager.RegLevelLogicScript(90001, "XLevel90001") --注册脚本类到管理器（逻辑脚本注册

---@param proxy XDlcCSharpFuncs
function XLevelScript90001:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
    self.endBattle = false
end

function XLevelScript90001:Init() --初始化逻辑
    -- 玩家的初始化, 正式应该由Gameplay的程序初始化处理, 此处为临时方案
    self.isFightAiOpen = false
    ----------------------------调试用的逻辑--------------------------------------

    self.isFighter1AiOpen = false
    self.isFighter2AiOpen = false
    self._isDiedByTired = false                                      --是否有npc因为疲劳伤害而死亡
    self._levelTime = 0
    ----------------------------调试用的逻辑--------------------------------------
    ----------------------------调试用的变量--------------------------------------
    

    
    self._tiredArgA = 100                                    --疲劳攻击力递增参数A      疲劳递增公式为 攻击力=A*int（T/3)^B   其中AB是可调参数，T是疲劳时间
    self._tiredArgB = 2                                     --疲劳攻击力递增参数B
    self._robotNextAttack = 0                              --用于计算机器人下一次攻击力的变量
    self._tiredDamageLevel = 3                                       --疲劳伤害等级（1秒提升1级）
    self._tiredDamageTarget = 2                                      --疲劳目标（1为自己，2为对手，每一轮疲劳优先对手扣血）
    self._isTiredTime = false                                        --是否进入了疲劳阶段 （一次性开关
    self._robotAttack = self._tiredArgA * ((self._tiredDamageLevel/3) ^ self._tiredArgB)                                   --空白机器人的初始疲劳攻击力
    ----------------Npc基础配置-------------------------------------------------------------------------- -------------

    --Fighter1配置
    local fighter1NpcId = 1010
    local fighter1Camp= ENpcCampType.Camp1
    local fighter1BornPos = {x = 44, y = 0.574, z = 50}
    local fighter1BornRota = {x = 0, y = -90, z = 0}

    --Fighter2配置
    local fighter2NpcId = 1011
    local fighter2Camp= ENpcCampType.Camp2
    local fighter2BornPos = {x = 38.92, y = 0.574, z = 50}
    local fighter2BornRota = {x = 0, y = 90, z = 0}
    
    -----------------创建Npc1--------------------------------------------------------------------------------------------

    self.fighter1UUID = self._proxy:GetAutoChessNpc(true)

    if self.fighter1UUID == 0 then
        self.fighter1UUID = self._proxy:GenerateNpc(fighter1NpcId, fighter1Camp, fighter1BornPos, fighter1BornRota)
        self._proxy:SetAutoChessNpcUi(self.fighter1UUID, true) -- Debug暂时给绑定角色血量
    else
        self._proxy:SetNpcPosition(self.fighter1UUID, fighter1BornPos)
    end

    self._proxy:SetNpcFaceToPosition(self.fighter1UUID,fighter2BornPos)  --设置看向2的位置

    self._proxy:ActivateVCam(self.fighter1UUID, "DlcAutoChess", 0, 0, 0, 41.725, 9.11, 60.74, 44.3, 180, 0, 0, 0, 101, false)

    -----------------创建Npc2--------------------------------------------------------------------------------------------

    self.fighter2UUID = self._proxy:GetAutoChessNpc(false)

    if self.fighter2UUID == 0 then
        self.fighter2UUID = self._proxy:GenerateNpc(fighter2NpcId, fighter2Camp, fighter2BornPos, fighter2BornRota)
        self._proxy:SetAutoChessNpcUi(self.fighter2UUID, false) -- Debug暂时给绑定角色血量
    else
        self._proxy:SetNpcPosition(self.fighter2UUID, fighter2BornPos)
    end

    self._proxy:SetNpcFaceToPosition(self.fighter2UUID,fighter1BornPos)  --设置看向1的位置
    -----------------创建空NPC-------------------------------------------------------------------------------------------
    self._robotUUID = self._proxy:GenerateNpc(1016, fighter2Camp, fighter2BornPos, fighter2BornRota)           --空NPCUUID赋值，生成机器人                                                                                                                        
    XLog.Debug("Robot的UUID是"..self._robotUUID)
    self._proxy:SetNpcActive(self._robotUUID, false)                                                                   --设置隐藏空NPC
    self._proxy:ApplyMagic(self._robotUUID, self._robotUUID, 1010028, 1)                                              --关闭AI

    ----------Level配置-------------------------------------------------------------------------------------------
    self.FightBeginCountDown = 3      ------游戏开局倒计时
    self.isLevelBegin = false  --关卡开始了
    self.isLevelEnd   =  false --关卡结束
    self._proxy:SetLevelMemoryInt(4001,1)  --设置游戏开始的局

    --疲劳伤害npc攻击力重置
    self._robotAttackTmeple = self._proxy:GetNpcAttribMaxValue(self._robotUUID,ENpcAttrib.Attack)                                                     
    self._proxy:AddNpcAttribAdditive(self._robotUUID,ENpcAttrib.Attack,-self._robotAttackTmeple,0)                                  --归零攻击力
    self._proxy:AddNpcAttribAdditive(self._robotUUID,ENpcAttrib.Attack,self._robotAttack,0)                                         --重置NPC攻击力为初始值

    self._robotAttackTmeple = self._proxy:GetNpcAttribMaxValue(self._robotUUID,ENpcAttrib.Attack) 
    XLog.Debug("Robot的攻击力是"..self._robotAttackTmeple)

    -------LevelState管理-------------------------------------------------------------------------------------------
    
end

---@param dt number @ delta time
function XLevelScript90001:Update(dt) --每帧更新逻辑
    self._levelTime = self._levelTime + dt       --记录关卡已进行时间
    ----------------------------调试用的逻辑--------------------------------------
    if self._proxy:IsKeyDown(ENpcOperationKey.Dodge) then   --同时战斗AI
        self.isFighter1AiOpen=true
        self.isFighter1AiOpen=true
        self.isFightAiOpen = not self.isFightAiOpen
        ---@type XLuaEventArgsAutoChessSetAIEnable
        local eventArgs = {
            Enable = self.isFightAiOpen
        }
        self._proxy:DispatchLuaEvent(ELuaEventTarget.All, EFightLuaEvent.AutoChessSetAIEnable, eventArgs)
        self.isFighter1AiOpen=true
        self.isFighter2AiOpen=true
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball1) then   --设置阵营1的AI
        if self.isFighter1AiOpen then
            self._proxy:ApplyMagic(self.fighter1UUID,self.fighter1UUID,1010028,1)--关闭AI
            self.isFighter1AiOpen =false
        else
            self._proxy:ApplyMagic(self.fighter1UUID,self.fighter1UUID,1010027,1)--开启AI
            self.isFighter1AiOpen =true
        end
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball2) then   --设置阵营2的AI
        if self.isFighter2AiOpen then
            self._proxy:ApplyMagic(self.fighter2UUID,self.fighter2UUID,1010028,1)--关闭AI
            self.isFighter2AiOpen=false
        else
            self._proxy:ApplyMagic(self.fighter2UUID,self.fighter2UUID,1010027,1)--开启AI
            self.isFighter2AiOpen=true
        end
    end
    if self._proxy:IsKeyDown(ENpcOperationKey.Ball3) then   --开启疲劳模式！
        self._isTiredTime = true
        self._player1nextTiredDamageTime = self._levelTime                            --NPC1疲劳扣血的时间
        self._player2nextTiredDamageTime = self._levelTime                            --NPC1疲劳扣血的时间
        self._proxy:ShowAutoChessTriedMessageTip()                                                                          --疲劳播报
    end
    ----------------------------调试用的逻辑--------------------------------------
    
    self:CheckFightEnd()
    self:OnUpdatePhase(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript90001:HandleEvent(eventType, eventArgs) --事件响应逻辑
end

function XLevelScript90001:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

--region 关卡阶段管理
function XLevelScript90001:InitPhase() --初始化关卡各个阶段的相关变量
    self._currentPhase = 0
    self._lastPhase = 0
end

function XLevelScript90001:SetPhase(phase) --跳转关卡阶段
    if phase == self._currentPhase then
        return
    end

    self:OnExitPhase(self._currentPhase)
    self:OnEnterPhase(phase)
    self:OnPhaseChanged(self._currentPhase, self.phase)

    self._lastPhase = self._currentPhase
    self._currentPhase = phase
end

function XLevelScript90001:OnEnterPhase(phase) --进入一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
end
---@param dt number @ delta time
function XLevelScript90001:OnUpdatePhase(dt) --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
    if self._isTiredTime then
        if self._tiredDamageTarget == 2 then
            if self._levelTime >= self._player2nextTiredDamageTime then
                --扣NPC2的血的时间了
                self._proxy:DamageRelinkStandalone(self._robotUUID,self.fighter2UUID,0,1010050,1,10000,0,0,0,0)      --扣血的逻辑
                self._player1nextTiredDamageTime = self._player2nextTiredDamageTime + dt         --下一帧再扣玩家的
                self._tiredDamageTarget = 1                                                     --准备轮到玩家1扣血
            end
        elseif self._tiredDamageTarget == 1 then
            if self._levelTime >= self._player1nextTiredDamageTime then
                --扣NPC1的血的时间了
                self._proxy:DamageRelinkStandalone(self._robotUUID,self.fighter1UUID,0,1010050,1,10000,0,0,0,0)             --扣血的逻辑
                self._player2nextTiredDamageTime = self._player1nextTiredDamageTime + 1          --NPC2的扣血时间改到1秒后
                self._tiredDamageTarget = 2                                                      --准备轮到玩家2扣血
                self._tiredDamageLevel = self._tiredDamageLevel + 1                              --疲劳伤害等级+1
                self._robotNextAttack = self._tiredArgA * ((self._tiredDamageLevel/3) ^ self._tiredArgB)    -- 计算疲劳攻击力
                self._robotAttackTmeple = self._proxy:GetNpcAttribMaxValue(self._robotUUID,ENpcAttrib.Attack)                                                     
                self._proxy:AddNpcAttribAdditive(self._robotUUID,ENpcAttrib.Attack,(self._robotNextAttack - self._robotAttackTmeple) ,0)         --疲劳机器人攻击力改变
            end
        end
    end
end

function XLevelScript90001:OnExitPhase(phase) --退出一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
end

function XLevelScript90001:OnPhaseChanged(lastPhase, nextPhase)
    --关卡阶段改变时需要执行的逻辑，一般用于通知外部
end

function XLevelScript90001:HandlePhaseEvent(eventType, eventArgs) --处理阶段相关的事件响应，一般在这里跳转关卡阶段
end

function XLevelScript90001:CheckFightEnd()
    if self.endBattle then
        return
    end

    if self.fighter1UUID ~= 0 and self._proxy:CheckActorExist(self.fighter1UUID) ~= true then
        self.endBattle = true
        self._proxy:SettleFight(true)
        self._isTiredTime = false
    elseif self.fighter2UUID ~= 0 and self._proxy:CheckActorExist(self.fighter2UUID) ~= true then
        self.endBattle = true
        self._proxy:SettleFight(false)
        self._isTiredTime = false
    end
end

--endregion

return XLevelScript90001