local XLevelScript90004 = XDlcScriptManager.RegLevelLogicScript(90004, "XLevel90004") --注册脚本类到管理器（逻辑脚本注册

---@param proxy XDlcCSharpFuncs
function XLevelScript90004:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
    --变量初始化
    self.isEndBattle = false
    self._spawnPoint = {}                                            --获取点位序号，初始化中获取
end

function XLevelScript90004:Init() --初始化逻辑
     ----------------地图初始化----------------------------------------------------------------------
    self._levelId = self._proxy:GetCurrentLevelId() -- 关卡ID,获取本关ID
    for i = 1, 3 do
        self._spawnPoint[i] = self._proxy:GetSpot(i)    --获取关卡编辑器中配置好的点，100001是战场中心点，100002是玩家1(本机)，100003是玩家2
    end

    -- --创建怪物配置
    local monsterId = 8052   --小灰灰
    local monsterCamp= ENpcCampType.Camp2
    local monsterBornPos = {x = 86, y = 1.9, z = 65}
    local monsterBornRota = {x = 0, y = 180, z = 0}

        -- --创建公共NPC
    local commonNpcId = 1200 --公共NPC
    local commonNpcCamp = ENpcCampType.Camp1
    local commonNpcBornPos = {x = 86, y = 1.9, z = 65}
    local commonNpcBornRota = {x = 0, y = 180, z = 0}
    
    self.isLeveEnd = false --关卡是否结束
    -----------------创建怪物--------------------------------------------------------------------------------------------
    self.monster_UUID = self._proxy:GenerateNpc(monsterId, monsterCamp, self._spawnPoint[2], monsterBornRota)
    -----------------创建公共NPC--------------------------------------------------------------------------------------------
    self.commonNpc_UUID = self._proxy:GenerateNpc(commonNpcId, commonNpcCamp, self._spawnPoint[1], commonNpcBornRota)
    
end

---@param dt number @ delta time
function XLevelScript90004:Update(dt) --每帧更新逻辑
    if  self.isLeveEnd then
        return
    end
    self:CheckLevelEnd()
end
---@param eventType number
---@param eventArgs userdata
function XLevelScript90004:HandleEvent(eventType, eventArgs) --事件响应逻辑
end

function XLevelScript90004:CheckLevelEnd() --检查关卡结束
    ----胜利结算检测-----------------
    if self.monster_UUID ~= 0 then
        if self._proxy:CheckNpc(self.monster_UUID) == false or self._proxy:CheckActorExist(self.monster_UUID) == false then
            self._proxy:FinishFight() --仅客户端完成战斗
            self:LevelEnd(true)
            return
        end
    end
end
    ---关卡失败检测------------------

function XLevelScript90004:LevelEnd(isPlayerWin)
    self.isLeveEnd = true
    self._proxy:SettleFight(isPlayerWin)                   --后端结算通知API
    if isPlayerWin then
        XLog.Warning("玩家胜利")
    else
        XLog.Warning("玩家失败")
    end
end

function XLevelScript90004:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

return XLevelScript90004