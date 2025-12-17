local XLevelScript90002 = XDlcScriptManager.RegLevelLogicScript(90002, "XLevel90002") --注册脚本类到管理器（逻辑脚本注册

---@param proxy XDlcCSharpFuncs
function XLevelScript90002:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end

function XLevelScript90002:Init() --初始化逻辑
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)                                       --事件注册：NPC死亡

    self._localPlayerNpcUUID = self._proxy:GetLocalPlayerNpcId()                         -- 获取本端玩家npcUUID
    self._localPlayerDeathTimes = 0                                                      -- 初始化本端玩家死亡次数
   
    self._levelTime = 0 
    self._isReadyToEnd = false                                                                 --关卡时间初始化
    self._isPlayerWin = false                                                                   --结算结果
    self._hasSettleLevel = false                                                                --是否已经上传过服务器结果了
    --拿到玩家列表
    self._playerNpcList = self._proxy:GetPlayerNpcList() --获取玩家列表
    
    -- --创建怪物配置
    local monsterId = 8005   --白龙
    local monsterCamp= ENpcCampType.Camp2
    local monsterBornPos = {x = 86, y = 1.9, z = 65}
    local monsterBornRota = {x = 0, y = 180, z = 0}

        -- --创建公共NPC
    local commonNpcId = 1200 --公共NPC
    local commonNpcCamp = ENpcCampType.Camp1
    local commonNpcBornPos = {x = 86, y = 1.9, z = 65}
    local commonNpcBornRota = {x = 0, y = 180, z = 0}
    
    self.isLeveEnd = false --关卡是否结束
    self._delayToEnd = 1.5                --延迟退出时间
    self._levelEndTime = 99999               --临时记录游戏结束的时间(初始化一个超级大的时间)
    -----------------创建怪物--------------------------------------------------------------------------------------------
    self.monster_UUID = self._proxy:GenerateNpc(monsterId, monsterCamp, monsterBornPos, monsterBornRota)
    -----------------创建公共NPC--------------------------------------------------------------------------------------------
    self.commonNpc_UUID = self._proxy:GenerateNpc(commonNpcId, commonNpcCamp, commonNpcBornPos, commonNpcBornRota)
    self._proxy:SetTeamWorkSkillActive(true,300,5)
    --XLog.Warning("开启团队协作系统")
end

---@param dt number @ delta time
function XLevelScript90002:Update(dt) --每帧更新逻辑
    self._levelTime = self._levelTime + dt       --记录关卡已进行时间
    if  self.isLeveEnd then
        return
    end
    self:CheckLevelEnd()
    self:LevelEnd(self._isPlayerWin)
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript90002:HandleEvent(eventType, eventArgs) --事件响应逻辑
    if eventType == EWorldEvent.NpcDie then 
        self:CheckLevelEnd()
        ----失败结算检测-----------------
        if self:CheckAllPlayerDead() then
            if self._isReadyToEnd ~= true then                      
                self._levelEndTime = self._levelTime                --死完了，确定游戏结算时间
                self._isReadyToEnd = true
            end
            self._isPlayerWin = false                               --玩家失败传参修改
        end
    end
end

function XLevelScript90002:CheckAllPlayerDead() --检查是否所有玩家都死亡了
    self._playerNpcList = self._proxy:GetPlayerNpcList() --获取玩家列表
    for i = 1,#self._playerNpcList do                                           --还没死完
        if not 
            (self._proxy:CheckNpcAction(self._playerNpcList[i],ENpcAction.Dying) 
                or self._proxy:CheckNpcAction(self._playerNpcList[i],ENpcAction.Death)) then          --其余两个队友都还没在倒地或者死亡状态的话就返回（09.03临时做法，具体做法需要等死亡流程功能做完先）
            return false
        end

        -- if not self._proxy:CheckBuffByKind(self._playerNpcList[i],1000480) then --不存在buff也不算死亡
        --     return false
        -- end
        -- if self._proxy:GetBuffStacks(self._playerNpcList[i],1000480)<=3 then
        --     return false
        -- end    
    end
    return true
end

function XLevelScript90002:CheckLevelEnd() --检查关卡结束
    ----胜利结算检测-----------------
    if self.monster_UUID ~= 0 then
        if self._proxy:CheckNpc(self.monster_UUID) == false or self._proxy:CheckActorExist(self.monster_UUID) == false then
            if self._isReadyToEnd ~= true then 
                self._levelEndTime = self._levelTime
                self._isReadyToEnd = true
            end
            self._isPlayerWin = true            --玩家胜利传参修改
            return
        end
    end
end

function XLevelScript90002:LevelEnd(isPlayerWin)
   if self._levelTime >= self._levelEndTime then
        if not self._hasSettleLevel then
            self._proxy:SettleFight(isPlayerWin)  --后端结算通知API
            self._hasSettleLevel = true
        end
    end

    if self._levelTime - self._delayToEnd >= self._levelEndTime then
        self.isLeveEnd = true
        self._proxy:FinishFight() --仅客户端完成战斗
    end
end

function XLevelScript90002:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

return XLevelScript90002