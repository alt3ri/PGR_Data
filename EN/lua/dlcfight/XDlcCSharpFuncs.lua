---@alias float number
---@alias int number
---@alias Action function
---@alias bool boolean
---@alias Vector4 UnityEngine.Vector4
---@alias Vector3 UnityEngine.Vector3
---@alias Vector2 UnityEngine.Vector2
---@class XDlcCSharpFuncs
local XDlcCSharpFuncs = {}

---@desc 结束战斗并通知所有客户端退出战斗
---@return void 
function XDlcCSharpFuncs:FinishFight()
end

---@desc 统一结算所有玩家（相当于用相同的参数批量对所有玩家调用SettlePlayer）
---@param win bool 默认值:
---@return void 
function XDlcCSharpFuncs:SettleFight(win)
end

---@desc 单独结算某个玩家
---@param npcUUID int 默认值:
---@param win bool 默认值:
---@return void 
function XDlcCSharpFuncs:SettlePlayer(npcUUID, win)
end

---@desc 获取进入本场战斗的玩家数量
---@return int 玩家数量
function XDlcCSharpFuncs:GetPlayerCount()
end

---@desc 根据玩家NpcUUID获取玩家ID
---@param npcId int 默认值: 
---@return int 玩家ID
function XDlcCSharpFuncs:GetPlayerIdByNpc(npcId)
end

---@desc 获取战斗当前时间
---@return float 时间
function XDlcCSharpFuncs:GetFightTime()
end

---@desc 判断玩家是否离线
---@param npcUUID int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckNpcIsDisconnect(npcUUID)
end

---@desc 设置战斗配置float
---@param key string 默认值: 
---@param value float 默认值: 
---@return void 
function XDlcCSharpFuncs:SetFloatConfig(key, value)
end

---@desc 添加定时器任务
---@param delayTimeSeconds float 默认值:
---@param callback Action 默认值:
---@return int 计时器任务ID，成功时返回大于0的ID，失败时返回0
function XDlcCSharpFuncs:AddTimerTask(delayTimeSeconds, callback)
end

---@desc 移除定时器任务
---@param taskId int 默认值:
---@return void 
function XDlcCSharpFuncs:RemoveTimerTask(taskId)
end

---@desc 获取NpcPlaceId, 不为零为LevelNpc
---@return int LevelNpc PlaceId
function XDlcCSharpFuncs:GetNpcPlaceId()
end

---@desc 注册事件
---@param eventType int 默认值:
---@return bool 返回是否监听成功
function XDlcCSharpFuncs:RegisterEvent(eventType)
end

---@desc 注销事件
---@param eventType int 默认值:
---@return void 
function XDlcCSharpFuncs:UnregisterEvent(eventType)
end

---@desc 注册Npc个人事件
---@param eventType int 默认值:
---@param targetUUID int 默认值:
---@return void 返回是否监听成功
function XDlcCSharpFuncs:RegisterEventByTarget(eventType, targetUUID)
end

---@desc 注销Npc个人事件
---@param eventType int 默认值:
---@param targetUUID int 默认值:
---@return void 
function XDlcCSharpFuncs:UnregisterEventByTarget(eventType, targetUUID)
end

---@desc 注册Lua玩法事件
---@param eventType int 默认值:
---@return void 
function XDlcCSharpFuncs:RegisterLuaEvent(eventType)
end

---@desc 注销Lua玩法事件
---@param eventType int 默认值:
---@return void 
function XDlcCSharpFuncs:UnregisterLuaEvent(eventType)
end

---@desc 广播Lua玩法事件
---@param targetType int 默认值:
---@param eventType int 默认值:
---@param luaTable LuaTable 默认值:
---@return void 
function XDlcCSharpFuncs:DispatchLuaEvent(targetType, eventType, luaTable)
end

---@desc 将某个Actor的局部坐标转换为世界坐标
---@param uuid int 默认值: 
---@param point Vector3 默认值: 
---@return Vector3 
function XDlcCSharpFuncs:TransformPointByActor(uuid, point)
end

---@desc 将世界坐标转换为某个Actor的局部坐标
---@param uuid int 默认值: 
---@param point Vector3 默认值: 
---@return Vector3 
function XDlcCSharpFuncs:InverseTransformPointByActor(uuid, point)
end

---@desc 获取一定范围内的随机数(int)
---@param min int 默认值:
---@param max int 默认值:
---@return int 
function XDlcCSharpFuncs:Random(min, max)
end

---@desc 获取一定范围内的随机数(float)
---@param minInclude float 默认值:
---@param maxExclude float 默认值:
---@return float 
function XDlcCSharpFuncs:RandomFloat(minInclude, maxExclude)
end

---@desc 记录自定义结算数据
---@param playerId int 默认值:
---@param key int 默认值: 
---@param value int 默认值: 
---@return void 
function XDlcCSharpFuncs:SetFightResultCustomData(playerId, key, value)
end

---@desc 发送副本结算数据
---@desc 详情:https://kurogame.feishu.cn/wiki/Fvqsw1u6pi6vzzkpPzlcMsQjnLb
---@param settleType int 默认值:
---@param settleDataLuaTable LuaTable 默认值:
---@return void 
function XDlcCSharpFuncs:OpenInstLevelSettleUi(settleType, settleDataLuaTable)
end

---@desc 记录副本结算数据(通常是埋点)
---@desc 详情:https://kurogame.feishu.cn/wiki/Fvqsw1u6pi6vzzkpPzlcMsQjnLb
---@param settleType int 默认值:
---@param settleDataLuaTable LuaTable 默认值:
---@return void 
function XDlcCSharpFuncs:RecordInstLevelSettleData(settleType, settleDataLuaTable)
end

---@desc 获取指定类型指定Id的关卡脚本对象
---@param scriptType EScriptType 默认值:
---@param levelId int 默认值:
---@return ILuaFightScript 
function XDlcCSharpFuncs:GetLevelScriptObject(scriptType, levelId)
end

---@desc 获取指定Actor的指定Id的脚本对象
---@param scriptType EScriptType 默认值:
---@param actorId int 默认值:
---@param scriptId int 默认值:
---@return ILuaFightScript 
function XDlcCSharpFuncs:GetActorScriptObject(scriptType, actorId, scriptId)
end

---@desc 给Npc添加角色脚本
---@param npcUUID int 默认值:
---@param scriptId int 默认值:
---@return void 
function XDlcCSharpFuncs:AddNpcCharScript(npcUUID, scriptId)
end

---@desc 给Npc移除角色脚本
---@param npcUUID int 默认值:
---@param scriptId int 默认值:
---@return void 
function XDlcCSharpFuncs:RemoveNpcCharScript(npcUUID, scriptId)
end

---@desc 加载关卡NPC
---@param placeId int 默认值:
---@return bool true成功，false失败
function XDlcCSharpFuncs:LoadLevelNpc(placeId)
end

---@desc 通过PlaceId获取Npc的UUID
---@param placeId int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetNpcUUID(placeId)
end

---@desc 生成Npc，并返回其对象Id。
---@param templateId int 默认值: 
---@param camp int 默认值: 
---@param position Vector3 默认值: 
---@param rotation Vector3 默认值: 
---@param canLaunchInteraction bool 
---@param skipBornState bool 
---@return int 
function XDlcCSharpFuncs:GenerateNpc(templateId, camp, position, rotation, canLaunchInteraction, skipBornState)
end

---@desc 获取辅助机对象UUID
---@return int 
function XDlcCSharpFuncs:GetAssistNpcUUID()
end

---@desc 设置Npc显隐，会将角色控制器、角色碰撞一同显隐
---@param uuid int 默认值: 
---@param active bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcActive(uuid, active)
end

---@desc 读取Npc的显隐状态
---@param uuid int 默认值: 
---@return bool 
function XDlcCSharpFuncs:GetNpcActive(uuid)
end

---@desc 移除Npc
---@param uuid int 默认值: 
---@return void 
function XDlcCSharpFuncs:DestroyNpc(uuid)
end

---@desc 卸载关卡NPC
---@param placeId int 默认值:
---@return void 
function XDlcCSharpFuncs:UnloadLevelNpc(placeId)
end

---@desc 使Npc死亡
---@param npcId int 默认值: 
---@param magicId int 默认值: 
---@return void 
function XDlcCSharpFuncs:NpcDie(npcId, magicId)
end

---@desc 使Npc开始移动并看向lookPosition
---@param npcId int 默认值: 
---@param lookPosition Vector3 默认值: 
---@return void 
function XDlcCSharpFuncs:NpcStartMove(npcId, lookPosition)
end

---@desc 使Npc开始移动并看向lookPosition
---@param npcUUID int 默认值: 
---@param destination Vector3 默认值: 
---@param moveType ENpcMoveType 默认值: 
---@return void 
function XDlcCSharpFuncs:NpcMoveTo(npcUUID, destination, moveType)
end

---@desc 使Npc开始沿着给定的路线移动
---@param npcUUID int 默认值: 
---@param routeId int 默认值: 
---@param moveType ENpcMoveType 默认值: 
---@return void 
function XDlcCSharpFuncs:NpcMoveByRoute(npcUUID, routeId, moveType)
end

---@desc 使Npc停止移动
---@param npcId int 默认值: 
---@return void 
function XDlcCSharpFuncs:NpcStopMove(npcId)
end

---@desc 【注意】要求存在寻路数据配置，
---@desc 文档:https://kurogame.feishu.cn/docx/JHIfd7qInosGvpxkgvwcDa0UnGc
---@desc 令Npc寻路到达某处
---@param npcUUID int 默认值:
---@param position Vector3 默认值:
---@param moveType int
---@return void 
function XDlcCSharpFuncs:NpcNavigateTo(npcUUID, position, moveType)
end

---@desc 禁止频繁调用（会发送同步消息
---@desc 设置Npc坐标
---@param npcId int 默认值: 
---@param position Vector3 默认值: 
---@param resetNpcState bool 
---@return void 
function XDlcCSharpFuncs:SetNpcPosition(npcId, position, resetNpcState)
end

---@desc 禁止频繁调用（会发送同步消息
---@desc 设置Npc朝向（rotation为各轴旋转角度
---@param npcId int 默认值: 
---@param rotation Vector3 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcRotation(npcId, rotation)
end

---@desc 禁止频繁调用（会发送同步消息
---@desc 设置Npc坐标与朝向
---@desc rotation：各轴的旋转角度（单位：°，非弧度）
---@desc resetNpcState：是否重置Npc状态为待机状态
---@param npcId int 默认值: 
---@param position Vector3 默认值: 
---@param rotation Vector3 默认值: 
---@param resetNpcState bool 
---@return void 
function XDlcCSharpFuncs:SetNpcPosAndRot(npcId, position, rotation, resetNpcState)
end

---@desc 设置Npc移动方向
---@param npcId int 默认值: 
---@param direction int 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcMoveDirection(npcId, direction)
end

---@desc 设置Npc移动类型
---@param npcId int 默认值: 
---@param type int 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcMoveType(npcId, type)
end

---@desc 获取Npc移动类型
---@param npcId int 默认值: 
---@return int 参考枚举ENpcMoveType
function XDlcCSharpFuncs:GetNpcMoveType(npcId)
end

---@desc Npc是否正在移动
---@param npcUUID int 默认值: 
---@return bool 
function XDlcCSharpFuncs:IsNpcMoving(npcUUID)
end

---@desc 设置Npc看向坐标
---@param npcId int 默认值: 
---@param position Vector3 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcFaceToPosition(npcId, position)
end

---@desc 设置Npc看向索敌/锁定目标
---@param npcId int 默认值:
---@param searchTargetUID long 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcFaceToSearchTarget(npcId, searchTargetUID)
end

---@desc 设置Npc看向目标
---@param npcId int 默认值: 
---@param targetNpcId int 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcFaceToNpc(npcId, targetNpcId)
end

---@desc 设置玩家Npc相机锁定目标
---@param npcId int 默认值:
---@param targetId int 默认值:
---@return bool 
function XDlcCSharpFuncs:SetNpcFocusTarget(npcId, targetId)
end

---@desc 移除玩家Npc相机锁定目标
---@param npcId int 默认值:
---@return void 
function XDlcCSharpFuncs:RemoveNpcFocusTarget(npcId)
end

---@desc 获取玩家Npc相机锁定目标UUID
---@param npcId int 默认值:
---@return int 玩家相机锁定的目标的UUID
function XDlcCSharpFuncs:GetNpcFocusTarget(npcId)
end

---@desc 获取本端玩家角色的Npc的UUID
---@return int 
function XDlcCSharpFuncs:GetLocalPlayerNpcId()
end

---@desc 获取本段玩家指挥官NPC的UUID
---@return int 
function XDlcCSharpFuncs:GetLocalPlayerSelfNpcId()
end

---@desc 检查是否存在对应npcUUID的Npc
---@param npcId int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckNpc(npcId)
end

---@desc 检查Npc动作状态机是否处于action
---@param npcId int 默认值: 
---@param action int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckNpcAction(npcId, action)
end

---@desc 检查Npc能否释放动作
---@desc --C#该接口判断了
---@desc --1 Npc是否死亡
---@desc --2 Npc是否拥有 Npc状态:无法释放动作
---@desc --3 Npc是否在受击
---@desc --4 空中组件判断是否能在空中放动作
---@param npcId int 默认值: 
---@return bool Bool:能否释放动作
function XDlcCSharpFuncs:CheckCanCastSkill(npcId)
end

---@desc 检查Npc动作Condition是否满足 (Condition表格)
---@desc 表格位置："Share\StatusSyncFight\Skill\Condition"
---@param npcId int 默认值: 
---@param actionId int 默认值:
---@return bool Bool:是否满足
function XDlcCSharpFuncs:CheckNpcActionCondition(npcId, actionId)
end

---@desc 检查下一个动作是否能打断当前动作
---@desc 1 若当前没有在播放的动作，则返回True。
---@desc 2 先判断打断优先级，若优先级高于当前动作，返回True。
---@desc 3 再判断时间轴，若处于打断时间内，返回True。(填写了TimingID则以时间轴做判断，否则用当前动作的CastTime做通用后摇区间判断)
---@param npcId int 默认值: 
---@param nextActionId int 默认值: 
---@param timingId int 
---@return bool Bool:能否打断
function XDlcCSharpFuncs:CheckNpcCanAbortCurrentAction(npcId, nextActionId, timingId)
end

---@desc 检查Npc当前技能已经释放完或到后摇阶段（当前没有正在释放技能也算完成)
---@param npcId int 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckNpcCurActionIsDone(npcId)
end

---@desc 检测Npc与目标距离是否在指定值内
---@param npc int 默认值: 
---@param target int 默认值: 
---@param distance float 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckNpcDistance(npc, target, distance)
end

---@desc 计算Npc与目标的距离
---@param npc int 默认值: 
---@param target int 默认值: 
---@return float 
function XDlcCSharpFuncs:CalcNpcDistance(npc, target)
end

---@desc 检测target和Npc的连线与Npc朝向的夹角是否在给定的agnle角度内，angle单位为度。
---@param npc int 默认值: 
---@param target int 默认值: 
---@param angle float 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckNpcInAngle(npc, target, angle)
end

---@desc 检测target和Npc的连线与Npc朝向的夹角是否在from和to的角度范围内，from和to单位为度。
---@param npc int 默认值:
---@param target int 默认值:
---@param from float 默认值:
---@param to float 默认值:
---@return bool 是否在from和to构成的角度区间内
function XDlcCSharpFuncs:CheckNpcInAngleRangeHorizontal(npc, target, from, to)
end

---@desc 检测Npc是否在空中
---@param npcId int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckNpcOnAir(npcId)
end

---@desc 获取Npc坐标
---@param npcId int 默认值: 
---@return Vector3 
function XDlcCSharpFuncs:GetNpcPosition(npcId)
end

---@desc 获取Npc朝向（返回各轴角度
---@param npcId int 默认值: 
---@return Vector3 
function XDlcCSharpFuncs:GetNpcRotation(npcId)
end

---@desc attrib参考枚举ENpcAttrib
---@param npcId int 默认值: 
---@param attrib int 默认值: 
---@return float 
function XDlcCSharpFuncs:GetNpcAttribRate(npcId, attrib)
end

---@desc 获取Npc阵营（返回值参考ENpcCamp
---@param npcId int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetNpcCamp(npcId)
end

---@desc 比较两个Npc的阵营是否相同
---@param npcA int 默认值: 
---@param npcB int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CompareNpcCamp(npcA, npcB)
end

---@desc 返回值参考枚举ENpcKind
---@param npc int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetNpcKind(npc)
end

---@desc 获取关卡内所有Npc组成的列表
---@return LuaTable 
function XDlcCSharpFuncs:GetNpcList()
end

---@desc 获取玩家Npc对象列表
---@return LuaTable 
function XDlcCSharpFuncs:GetPlayerNpcList()
end

---@desc 是否为玩家NPC
---@param npcId int 默认值: 
---@return bool 
function XDlcCSharpFuncs:IsPlayerNpc(npcId)
end

---@desc NPC是否死亡
---@param uuid int 默认值: 
---@return bool 
function XDlcCSharpFuncs:IsNpcDead(uuid)
end

---@desc 判断Actor是否还存在
---@param uuid int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckActorExist(uuid)
end

---@desc 复活Npc
---@param launcherId int 默认值: 
---@param targetId int 默认值: 
---@return void 
function XDlcCSharpFuncs:RebornNpc(launcherId, targetId)
end

---@desc 执行Magic
---@param launcherId int 默认值: 
---@param targetId int 默认值: 
---@param magicId int 默认值: 
---@param level int 默认值: 
---@param contextId int 默认值: 
---@param count int 默认值: 
---@return void 
function XDlcCSharpFuncs:ApplyMagic(launcherId, targetId, magicId, level, contextId, count)
end

---@desc 检查Npc是否有指定buff
---@param npcId int 默认值: 
---@param kind int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckBuffByKind(npcId, kind)
end

---@desc 重置Npc到安全点（系统自动计算的安全点
---@param npcId int 默认值: 
---@return void 
function XDlcCSharpFuncs:ResetNpcToSafePoint(npcId)
end

---@desc 重置Npc到已记录的检查点（自动选择检查点配置点位之一
---@param npcId int 默认值: 
---@return void 
function XDlcCSharpFuncs:ResetNpcToCheckPoint(npcId)
end

---@desc 重置Npc到指定检查点（自动选择检查点配置点位之一
---@param npcId int 默认值: 
---@param checkPointPlaceId int 默认值: 
---@return void 
function XDlcCSharpFuncs:ResetNpcToSpecificCheckPoint(npcId, checkPointPlaceId)
end

---@desc 设置Npc的检查点（本质是设置重生坐标
---@param npcId int 默认值: 
---@param checkPointPlaceId int 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcCheckPoint(npcId, checkPointPlaceId)
end

---@desc 获取Npc记录的检查点
---@param npcId int 默认值: 
---@return void , float x:, float y:, float z:
function XDlcCSharpFuncs:GetNpcLastCheckPoint(npcId)
end

---@desc 添加技能球
---@param npcId int 默认值:
---@param key int 默认值:
---@param count int 默认值:
---@return void 
function XDlcCSharpFuncs:AddSkillBall(npcId, key, count)
end

---@desc 清除所有技能球
---@param npcId int 默认值:
---@return int 清除的球数量
function XDlcCSharpFuncs:ClearAllSkillBalls(npcId)
end

---@desc 获取所有球的类型列表
---@param npcId int 默认值:
---@return LuaTable int数组Table，包含了每个球的类型
function XDlcCSharpFuncs:GetBallKindsList(npcId)
end

---@desc 获取Npc技能球数量
---@param npcId int 默认值: 
---@param countBackend bool 默认值:
---@return int 
function XDlcCSharpFuncs:GetSkillBallCount(npcId, countBackend)
end

---@desc 设置Npc作为交互发起者进行交互时是否转身面向交互目标
---@param uuid int 默认值:
---@param enable bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcInteractTurnEnable(uuid, enable)
end

---@desc 设置Npc重力
---@param uuid int 默认值:
---@param jumpGravity float 默认值:
---@param freeFallGravity float 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcGravity(uuid, jumpGravity, freeFallGravity)
end

---@desc 移动Npc（暂定）
---@param uuid int 默认值:
---@param vector Vector3 默认值:
---@return bool 是否未受阻挡地移动（true表示没有受到阻挡）
function XDlcCSharpFuncs:MoveNpc(uuid, vector)
end

---@desc 转向Npc
---@param npcUUID1 int 默认值:
---@param npcUUID2 int 默认值:
---@return void 
function XDlcCSharpFuncs:TurnNpc(npcUUID1, npcUUID2)
end

---@desc Npc 的水平方向上的角度差是否抵达视线角度最大值
---@param fstNpcUUID int 默认值: 
---@param sndNpcUUID int 默认值: 
---@return bool 
function XDlcCSharpFuncs:IsNpcAngleReachMaxLookAtAngleOnHorizontal(fstNpcUUID, sndNpcUUID)
end

---@desc 向目标 Npc 位置旋转一次
---@param fstNpcUUID int 默认值:
---@param sndNpcUUID int 默认值:
---@return void 
function XDlcCSharpFuncs:TurnNpcOnce(fstNpcUUID, sndNpcUUID)
end

---@desc 开启注视（仅客户端使用）
---@param fstNpcUUID int 默认值:
---@param sndNpcUUID int 默认值:
---@return void 
function XDlcCSharpFuncs:EnableNpcLookAt(fstNpcUUID, sndNpcUUID)
end

---@desc 关闭注视（仅客户端使用）
---@param fstNpcUUID int 默认值:
---@return void 
function XDlcCSharpFuncs:DisableNpcLookAt(fstNpcUUID)
end

---@desc 获取目标Actor的交互发起者点位 （每个可以交互的Actor，如果要响应库洛洛这种“助理NPC”的交互，则需要配置相应的坐标点位供他们使用）
---@param targetUUID int 默认值:
---@return Vector3 
function XDlcCSharpFuncs:GetActorInteractionLauncherSpot(targetUUID)
end

---@desc 使NPC向指定目标发起交互
---@param launcherUUID int 默认值:
---@param targetUUID int 默认值:
---@param optionId int 默认值:
---@return bool 
function XDlcCSharpFuncs:NpcStartInteractWith(launcherUUID, targetUUID, optionId)
end

---@desc 设置Actor的交互响应回调 （可交互Actor一般有默认的交互响应逻辑，当你不希望它们执行时，使用此函数进行“重写”以替换响应逻辑）
---@param uuid int 默认值:
---@param callback Action<int, int, int> 默认值:
---@return bool 
function XDlcCSharpFuncs:SetActorInteractionReactCallback(uuid, callback)
end

---@desc 设置Npc忽略其他Npc的所有碰撞
---@desc 已包含同步和断线重连逻辑
---@param uuid int 默认值:
---@param ignore bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcIgnoreOtherNpcAllCollisions(uuid, ignore)
end

---@desc 检查Npc完整状态
---@desc 子状态填写-1 或 者当前主状态没有子状态时 子状态参数无效
---@desc 子状态ID请查阅“g工具表“的”NPC状态类型”子表
---@param uuid int 默认值: 
---@param mainState int 默认值:
---@param subState int 默认值:
---@return bool Npc状态和参数一致则返回true
function XDlcCSharpFuncs:CheckNpcFullActionState(uuid, mainState, subState)
end

---@desc 判断Npc的受击状态
---@param uuid int 默认值:
---@param state int 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckNpcBeHitState(uuid, state)
end

---@desc 判断Npc是否处于后台
---@param uuid int 默认值: 
---@return bool 
function XDlcCSharpFuncs:IsNpcBackState(uuid)
end

---@desc 切换玩家Npc
---@param uuid int 默认值:
---@param operationKey int 默认值:
---@return void 
function XDlcCSharpFuncs:SwitchPlayerNpc(uuid, operationKey)
end

---@desc 本地控制角色跳跃
---@desc TODO 目前仅用于本地控制角色使用, 待优化
---@param uuid int 默认值:
---@param isMoving bool 默认值:
---@return void 
function XDlcCSharpFuncs:Jump(uuid, isMoving)
end

---@desc 判断Npc的跳跃状态
---@param uuid int 默认值:
---@param state int 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckNpcJumpState(uuid, state)
end

---@desc 请找程序 ，没注释
---@param uuid int 默认值: 
---@param speed float 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcJumpLookAtSpeed(uuid, speed)
end

---@desc 用于传送后设置Npc为在地面(防止空中状态动量残留)
---@param uuid int 默认值: 
---@return void 
function XDlcCSharpFuncs:TeleportResetNpcOnGround(uuid)
end

---@desc 带黑幕传送NPC(仅客户端使用)
---@param npcId int 默认值:
---@param position Vector3 默认值:
---@param rotation Vector3 默认值:
---@param cb Action 默认值:
---@return void 
function XDlcCSharpFuncs:TeleportWithBlackUi(npcId, position, rotation, cb)
end

---@desc 设置Npc动画控制器层
---@param uuid int 默认值:
---@param layerIndex int 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcAnimationLayer(uuid, layerIndex)
end

---@desc 设置Actor是否可交互，目前支持NPC和SceneObject
---@param uuid int 默认值:
---@param enable bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetActorInteractableComponentEnable(uuid, enable)
end

---@desc 通过PlaceId设置Actor是否可交互，目前支持NPC和SceneObject
---@param actorType int 默认值:
---@param placeId int 默认值:
---@param enable bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetActorInteractableComponentEnableByPlaceId(actorType, placeId, enable)
end

---@desc 设置Npc FightTarget
---@param uuid int 默认值:
---@param targetUuid int 默认值:
---@return void 
function XDlcCSharpFuncs:SetFightTarget(uuid, targetUuid)
end

---@desc 获取Npc的 FightTarget的 uuid
---@param uuid int 默认值:
---@return int FightTarget的UUID
function XDlcCSharpFuncs:GetFightTargetId(uuid)
end

---@desc 检查Npc是否存在FightTarget
---@param uuid int 默认值:
---@return bool 存在返回true
function XDlcCSharpFuncs:CheckFightTarget(uuid)
end

---@desc 移出Npc的FightTarget
---@param uuid int 默认值:
---@return void 
function XDlcCSharpFuncs:RemoveFightTarget(uuid)
end

---@desc 获取相对于Npc的偏移坐标位置
---@param uuid int 默认值:
---@param position Vector3 默认值:
---@param euler Vector3 默认值:
---@param distance float 默认值:
---@return Vector3 最终偏移的世界坐标
function XDlcCSharpFuncs:GetNpcOffsetPosition(uuid, position, euler, distance)
end

---@desc 获取Npc朝向目标位置世界坐标系的旋转
---@param uuid int 默认值:
---@param position Vector3 默认值:
---@param eulerOffset Vector3 默认值:
---@param isOnlyY bool 默认值:
---@return Vector3 世界坐标下旋转的欧拉角
function XDlcCSharpFuncs:GetNpcOffsetRotation(uuid, position, eulerOffset, isOnlyY)
end

---@desc 获取相对于Npc的偏移向量（忽略npc自身旋转）
---@param uuid int 默认值:
---@param position Vector3 默认值:
---@param euler Vector3 默认值:
---@param distance float 默认值:
---@return Vector3 最终偏移向量
function XDlcCSharpFuncs:GetNpcOffset(uuid, position, euler, distance)
end

---@desc 获取相对于Npc朝向的偏移坐标
---@param uuid int 默认值:
---@param euler Vector3 默认值:
---@param distance float 默认值:
---@return Vector3 最终偏移的世界坐标
function XDlcCSharpFuncs:GetNpcOffsetPositionByFacing(uuid, euler, distance)
end

---@desc 获得世界坐标系中的点在目标角色本地坐标系中的本地坐标
---@param pointInWorldSpace Vector3 默认值:
---@param targetNpcUUID int 默认值:
---@return Vector3 
function XDlcCSharpFuncs:GetLocalPosInNpcLocalSpace(pointInWorldSpace, targetNpcUUID)
end

---@desc 移动Npc到指定位置
---@param uuid int 默认值:
---@param position Vector3 默认值:
---@return void 
function XDlcCSharpFuncs:MoveToPosition(uuid, position)
end

---@desc Npc朝向指定位置
---@param uuid int 默认值:
---@param position Vector3 默认值:
---@return void 
function XDlcCSharpFuncs:LookAtPositionImmediately(uuid, position)
end

---@desc 获取与目标的距离
---@param uuid int 默认值:
---@param targetUuid int 默认值:
---@param ignoreY bool 默认值:
---@return float 距离
function XDlcCSharpFuncs:GetNpcDistance(uuid, targetUuid, ignoreY)
end

---@desc 获取Npc的时间
---@param uuid int 默认值:
---@return float 
function XDlcCSharpFuncs:GetNpcTime(uuid)
end

---@desc 检查Npc的时间是否大于指定时间加上额外时间的总和
---@param uuid int 默认值:
---@param time float 默认值:
---@param extraTime float 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckNpcTime(uuid, time, extraTime)
end

---@desc 设置Npc输入行为组
---@param uuid int 默认值:
---@param id int 默认值:
---@return bool 是否设置成功
function XDlcCSharpFuncs:SetNpcInputActionGroup(uuid, id)
end

---@desc 添加连线特效
---@param launcherNpcUUID int 默认值:
---@param uuidA int 默认值:
---@param uuidB int 默认值:
---@param jointA string 默认值:
---@param jointB string 默认值:
---@param effectName string 默认值:
---@param updateAlways bool 默认值:
---@return int 返回链接的Id
function XDlcCSharpFuncs:AddLink(launcherNpcUUID, uuidA, uuidB, jointA, jointB, effectName, updateAlways)
end

---@desc 根据位置添加连线特效
---@param pos1 Vector3 默认值:
---@param pos2 Vector3 默认值:
---@param effectName string 默认值:
---@param launcherNpcUUID int 默认值:
---@param updateAlways bool 默认值:
---@return int 返回链接的Id
function XDlcCSharpFuncs:AddPosLink(pos1, pos2, effectName, launcherNpcUUID, updateAlways)
end

---@desc 检查连线特效是否存在
---@param linkId int 默认值:
---@return bool 是否存在该链接
function XDlcCSharpFuncs:CheckLink(linkId)
end

---@desc 查询连线特效的ActorA和B的UUID
---@param linkId int 默认值:
---@return int ActorA的Id, int actorBUUID:ActorB的Id
function XDlcCSharpFuncs:QueryLinkActor(linkId)
end

---@desc 移除指定的连线特效
---@param launcherNpcUUID int 默认值:
---@param linkId int 默认值:
---@return void 
function XDlcCSharpFuncs:RemoveLink(launcherNpcUUID, linkId)
end

---@desc 移除指定Actor的所有连线特效
---@param launcherNpcUUID int 默认值:
---@param actorUUID int 默认值:
---@return void 
function XDlcCSharpFuncs:RemoveAllActorLink(launcherNpcUUID, actorUUID)
end

---@desc 移除指定Npc创造的所有PosLink
---@param launcherNpcUUID int 默认值:
---@return void 
function XDlcCSharpFuncs:RemoveAllNpcPosLink(launcherNpcUUID)
end

---@desc 获取Npc的属性值
---@param uuid int 默认值:
---@param attribType ENpcAttrib 默认值:
---@return int 
function XDlcCSharpFuncs:GetNpcAttribValue(uuid, attribType)
end

---@desc 获取Npc的属性最大值
---@param uuid int 默认值:
---@param attribType ENpcAttrib 默认值:
---@return int 
function XDlcCSharpFuncs:GetNpcAttribMaxValue(uuid, attribType)
end

---@desc 增加Npc属性的加成值
---@param uuid int 默认值:
---@param attribType ENpcAttrib 默认值:
---@param value int 默认值:
---@param percent int 默认值:
---@return void 
function XDlcCSharpFuncs:AddNpcAttribAdditive(uuid, attribType, value, percent)
end

---@desc 检查Npc与位置的距离是否小于指定距离
---@param uuid int 默认值:
---@param position Vector3 默认值:
---@param distance float 默认值:
---@param ignoreY bool 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckNpcPositionDistance(uuid, position, distance, ignoreY)
end

---@desc 获取Npc与位置的距离
---@param uuid int 默认值:
---@param position Vector3 默认值:
---@param ignoreY bool 默认值:
---@return float 
function XDlcCSharpFuncs:GetNpcToPositionDistance(uuid, position, ignoreY)
end

---@desc 3.6自走棋造成伤害（仅单机使用）
---@param launcherUUID int 默认值:
---@param targetUUID int 默认值:
---@param partId int 默认值:
---@param magicId int 默认值:
---@param kind int 默认值:
---@param permyriad int 默认值:
---@param elementType int 默认值:
---@param hackValue int 默认值:
---@param hackPermyriad int 默认值:
---@param skillCap int 默认值:
---@return void 
function XDlcCSharpFuncs:DamageRelinkStandalone(launcherUUID, targetUUID, partId, magicId, kind, permyriad, elementType, hackValue, hackPermyriad, skillCap)
end

---@desc 3.6自走棋造成治疗（仅单机使用）
---@param launcherUUID int 默认值:
---@param targetUUID int 默认值:
---@param magicId int 默认值:
---@param attribType int 默认值:
---@param type int 默认值:
---@param value int 默认值:
---@param permyriad int 默认值:
---@param useTargetAttrib bool 默认值:
---@param useHealAmpP bool 默认值:
---@return void 
function XDlcCSharpFuncs:CureRelinkStandalone(launcherUUID, targetUUID, magicId, attribType, type, value, permyriad, useTargetAttrib, useHealAmpP)
end

---@desc 获取Npc护盾总值
---@param uuid int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetNpcProtector(uuid)
end

---@desc 根据类型获取Npc护盾值
---@param uuid int 默认值: 
---@param type int 默认值:
---@return int 
function XDlcCSharpFuncs:GetNpcProtectorByType(uuid, type)
end

---@desc 添加护盾 (Buff脚本限定)
---@param value int 默认值:
---@param type EDamageType 默认值:
---@param priority int 默认值:
---@return void 
function XDlcCSharpFuncs:AddProtector(value, type, priority)
end

---@desc 移除护盾 (Buff脚本限定)
---@return void 
function XDlcCSharpFuncs:RemoveProtector()
end

---@desc 检测基于Npc计算出的射线是否命中静态碰撞体（地形 & 场景物体 & 关卡障碍）
---@param npcUUID int 默认值:
---@param posOffset Vector3 默认值:
---@param rotOffset Vector3 默认值:
---@param distance float 默认值:
---@return bool 是否命中碰撞体, Vector3 hitPos:(第二个返回值)命中的障碍位置
function XDlcCSharpFuncs:CheckNpcRayCastStaticCollider(npcUUID, posOffset, rotOffset, distance)
end

---@desc 检测基于Npc计算出的射线是否命中关卡障碍
---@param npcUUID int 默认值:
---@param posOffset Vector3 默认值:
---@param rotOffset Vector3 默认值:
---@param distance float 默认值:
---@return bool 是否命中障碍, Vector3 hitPos:(第二个返回值)命中的障碍位置
function XDlcCSharpFuncs:CheckNpcRayCastObstacle(npcUUID, posOffset, rotOffset, distance)
end

---@desc 检测基于Npc计算出的球体是否碰撞到关卡障碍
---@param npcUUID int 默认值:
---@param posOffset Vector3 默认值:
---@param rotOffset Vector3 默认值:
---@param distance float 默认值:
---@param radius float 默认值:
---@return bool 是否碰撞到关卡障碍
function XDlcCSharpFuncs:CheckNpcSphereObstacle(npcUUID, posOffset, rotOffset, distance, radius)
end

---@desc 检测世界坐标系下的射线是否命中关卡障碍
---@param npcUUID int 默认值:
---@param pos Vector3 默认值:
---@param rot Vector3 默认值:
---@param distance float 默认值:
---@return bool 是否命中障碍, Vector3 hitPos:(第二个返回值)命中的障碍位置
function XDlcCSharpFuncs:CheckRayCastObstacle(npcUUID, pos, rot, distance)
end

---@desc 检测世界坐标系下的球体是否碰撞到关卡障碍
---@param npcUUID int 默认值:
---@param pos Vector3 默认值:
---@param radius float 默认值:
---@return bool 球体是否碰到障碍
function XDlcCSharpFuncs:CheckSphereObstacle(npcUUID, pos, radius)
end

---@desc 获取Npc最大仇恨的目标NPC的UUID
---@param uuid int 默认值:
---@return int 最大仇恨的NpcUUID（返回0没有）
function XDlcCSharpFuncs:GetMaxThreatNpc(uuid)
end

---@desc 获取Npc最小仇恨的目标NPC的UUID
---@param uuid int 默认值:
---@return int 最小仇恨的NpcUUID（返回0没有）
function XDlcCSharpFuncs:GetMinThreatNpc(uuid)
end

---@desc 检查Npc仇恨列表是否为空（不为空返回true）
---@param uuid int 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckThreatList(uuid)
end

---@desc 检查Npc仇恨值列表是否为空（不为空返回true）
---@param uuid int 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckThreatValueList(uuid)
end

---@desc 检查Npc强仇恨列表是否为空（不为空返回true）
---@param uuid int 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckForceThreatList(uuid)
end

---@desc 检查目标Npc是否在当前Npc的仇恨列表中
---@param uuid int 默认值:
---@param targetUUID int 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckNpcInThreatList(uuid, targetUUID)
end

---@desc 获取当前Npc对目标NPC的仇恨值
---@desc 如果目标不在仇恨列表返回 0
---@param uuid int 默认值:
---@param targetUUID int 默认值:
---@return int 
function XDlcCSharpFuncs:GetThreatValue(uuid, targetUUID)
end

---@desc 检查目标Npc是不是最高仇恨目标
---@param uuid int 默认值:
---@param targetUUID int 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckNpcIsIsFirstThreat(uuid, targetUUID)
end

---@desc 获取最高仇恨值的Npc
---@param uuid int 默认值:
---@return int 最高仇恨值的Npc的UUID
function XDlcCSharpFuncs:GetMaxThreatValueNpc(uuid)
end

---@desc 获取最低仇恨值的Npc
---@param uuid int 默认值:
---@return int 最低仇恨值的Npc的UUID
function XDlcCSharpFuncs:GetMinThreatValueNpc(uuid)
end

---@desc 添加仇恨值
---@param uuid int 默认值:
---@param targetUUID int 默认值:
---@param ratioValue int 默认值:
---@param value int 默认值:
---@return void 
function XDlcCSharpFuncs:AddThreat(uuid, targetUUID, ratioValue, value)
end

---@desc 设置目标Npc为最高仇恨值Npc
---@param uuid int 默认值:
---@param targetNpcUUID int 默认值:
---@return void 
function XDlcCSharpFuncs:SetMaxThreatValueNpc(uuid, targetNpcUUID)
end

---@desc 检查目标Npc是否在仇恨值列表中
---@param uuid int 默认值:
---@param targetUUID int 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckNpcInThreatValueList(uuid, targetUUID)
end

---@desc 检查目标Npc是否在强仇列表中
---@param uuid int 默认值:
---@param targetUUID int 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckNpcInThreatForceList(uuid, targetUUID)
end

---@desc 带有过渡的进入自定义表演流程
---@param uuid int 默认值:
---@param animName string 默认值:
---@param inTransitionDuration float 默认值:
---@param outTransitionDuration float 默认值:
---@param needTurn bool
---@param interactFacePos Vector3
---@return void 
function XDlcCSharpFuncs:PlayNpcCustomPerformAnim(uuid, animName, inTransitionDuration, outTransitionDuration, needTurn, interactFacePos)
end

---@desc 中止当前表演状态
---@param uuid int 默认值: 
---@return void 
function XDlcCSharpFuncs:StopNpcPerformAnim(uuid)
end

---@desc 设置Npc部位忽略所有Npc碰撞
---@param uuid int 默认值:
---@param partId int 默认值:
---@param ignore bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcPartCollidersIgnoreAllOtherNpc(uuid, partId, ignore)
end

---@desc 设置Npc骨骼抖动时间缩放
---@param uuid int 默认值:
---@param isGetFromNpc bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcBoneShakeTimeScale(uuid, isGetFromNpc)
end

---@desc 设置Npc透视
---@param npcUUID int 默认值:
---@param enable bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcDither(npcUUID, enable)
end

---@desc 设置计算伤害前上下文
---@param contextId int 默认值:
---@param physicalPermyraid int 默认值:
---@param elementPermyraid int 默认值:
---@param hackDamage int 默认值:
---@param hackPermyraid int 默认值:
---@param isCrit bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetBeforeDamageMagicContext(contextId, physicalPermyraid, elementPermyraid, hackDamage, hackPermyraid, isCrit)
end

---@desc 设置计算伤害前上下文 韧性倍率
---@param contextId int 默认值:
---@param breakPermyraid int 默认值:
---@return void 
function XDlcCSharpFuncs:SetBeforeDamageMagicContextBreak(contextId, breakPermyraid)
end

---@desc 设置计算伤害后上下文
---@param contextId int 默认值:
---@param physicalDamage int 默认值:
---@param elementDamage int 默认值:
---@param finalHackDamage int 默认值:
---@return void 
function XDlcCSharpFuncs:SetAfterDamageMagicContext(contextId, physicalDamage, elementDamage, finalHackDamage)
end

---@desc 设置计算伤害后上下文 韧性倍率
---@param contextId int 默认值:
---@param finalBreakDamage int 默认值:
---@return void 
function XDlcCSharpFuncs:SetAfterDamageMagicContextBreak(contextId, finalBreakDamage)
end

---@desc 设置计算治疗前上下文
---@param contextId int 默认值:
---@param value int 默认值:
---@param permyraid int 默认值:
---@return void 
function XDlcCSharpFuncs:SetBeforeCureMagicContext(contextId, value, permyraid)
end

---@desc 设置计算治疗后上下文
---@param contextId int 默认值:
---@param finalValue int 默认值:
---@return void 
function XDlcCSharpFuncs:SetAfterCureMagicContext(contextId, finalValue)
end

---@desc 添加伤害上下文附加值
---@param contextId int 默认值:
---@param attrType int 默认值:
---@param v int 默认值:
---@param p int 默认值:
---@return void 
function XDlcCSharpFuncs:AddDamageMagicContextValue(contextId, attrType, v, p)
end

---@desc 设置伤害上下文附加值
---@param contextId int 默认值:
---@param attrType int 默认值:
---@param v int 默认值:
---@param p int 默认值:
---@return void 
function XDlcCSharpFuncs:SetDamageMagicContextValue(contextId, attrType, v, p)
end

---@desc 添加治疗上下文附加值
---@param contextId int 默认值:
---@param attrType int 默认值:
---@param v int 默认值:
---@param p int 默认值:
---@return void 
function XDlcCSharpFuncs:AddCureMagicContextValue(contextId, attrType, v, p)
end

---@desc 设置治疗上下文附加值
---@param contextId int 默认值:
---@param attrType int 默认值:
---@param v int 默认值:
---@param p int 默认值:
---@return void 
function XDlcCSharpFuncs:SetCureMagicContextValue(contextId, attrType, v, p)
end

---@desc 修改技能预输入上下文
---@param contextId int 默认值:
---@param targetType int 默认值:
---@param targetUUID int 默认值:
---@param targetPos Vector3 默认值:
---@param searchTargetUID long 默认值:
---@return void 
function XDlcCSharpFuncs:SetCastSkillByInputActionBeforeValue(contextId, targetType, targetUUID, targetPos, searchTargetUID)
end

---@desc 修改弹刀上下文
---@param contextId int 默认值:
---@param success bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetTriggerCounterContextValue(contextId, success)
end

---@desc 以Npc为半径搜索符合条件的Npc
---@param centerNpcUuid int 默认值:
---@param campValue int 默认值:
---@param typeValue int 默认值:
---@param range float 默认值:
---@param rangeCoe int 默认值:
---@return int Npc对象的UUID
function XDlcCSharpFuncs:SearchNpc(centerNpcUuid, campValue, typeValue, range, rangeCoe)
end

---@desc 【使用了相机方向，仅限玩家npc调用】搜索npc
---@param selfNpcUuid int 默认值:
---@param campValue int 默认值:
---@param typeValue int 默认值:
---@param range float 默认值:
---@param rangeCoe int 默认值:
---@param angleCoe int 默认值:
---@return int Npc对象的UUID
function XDlcCSharpFuncs:SearchNpcForRole(selfNpcUuid, campValue, typeValue, range, rangeCoe, angleCoe)
end

---@desc 【使用了相机方向，仅限玩家npc调用】搜索npc部位
---@param selfNpcUuid int 默认值:
---@param campValue int 默认值:
---@param typeValue int 默认值:
---@param range float 默认值:
---@param rangeCoe int 默认值:
---@param angleCoe int 默认值:
---@return LuaTable { NpcUUID:目标NpcId PartId:部位Id PartBoneUID:部位骨骼id}
function XDlcCSharpFuncs:SearchNpcPartForRole(selfNpcUuid, campValue, typeValue, range, rangeCoe, angleCoe)
end

---@desc 获取首个搜索目标的UID，若无则返回0。
---@param uuid int 默认值:
---@param npcTargetType int 默认值:
---@return long 
function XDlcCSharpFuncs:GetFirstSearchTarget(uuid, npcTargetType)
end

---@desc 获取搜索目标列表，若无则返回null。
---@param uuid int 默认值:
---@param npcTargetType int 默认值:
---@return LuaTable 
function XDlcCSharpFuncs:GetSearchTargetList(uuid, npcTargetType)
end

---@desc 获取索敌/锁定目标的位置
---@param searchTargetUID long 默认值:
---@return Vector3 
function XDlcCSharpFuncs:GetSearchTargetPosition(searchTargetUID)
end

---@desc 获取当前锁定的目标（优先级 强制>硬锁>软锁）
---@return long 返回锁定目标的UID, int actorUUID:返回锁定目标所属的ActorUUID
function XDlcCSharpFuncs:GetLockTarget()
end

---@desc 获取当前锁定的目标类型
---@return int 锁定目标类型 ELockTargetType
function XDlcCSharpFuncs:GetCurLockTargetType()
end

---@desc 设置软锁基础配置
---@param configId int 默认值:
---@return void 
function XDlcCSharpFuncs:SetBaseSoftLockTargetConfig(configId)
end

---@desc 设置指定NPC软锁配置
---@param npcUUID int 默认值:
---@param configId int 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcSoftLockTargetConfig(npcUUID, configId)
end

---@desc 设置软锁目标
---@param targetUID long 默认值:
---@return void 
function XDlcCSharpFuncs:SetSoftLock(targetUID)
end

---@desc 设置软锁目标到指定部位
---@param npcUUID int 默认值:
---@param partId int 默认值:
---@return void 
function XDlcCSharpFuncs:SetSoftLockToPart(npcUUID, partId)
end

---@desc 取消软锁目标
---@return void 
function XDlcCSharpFuncs:CancelSoftLockTarget()
end

---@desc 设置硬锁锁目标
---@param targetUID long 默认值:
---@return void 
function XDlcCSharpFuncs:SetHardLock(targetUID)
end

---@desc 设置硬锁锁目标到指定部位
---@param npcUUID int 默认值:
---@param partId int 默认值:
---@return void 
function XDlcCSharpFuncs:SetHardLockToPart(npcUUID, partId)
end

---@desc 取消硬锁目标
---@return void 
function XDlcCSharpFuncs:CancelHardLockTarget()
end

---@desc 设置强制锁定到指定Npc的部位
---@param npcUUID int 默认值:
---@param partId int 默认值:
---@return void 
function XDlcCSharpFuncs:SetAllPlayerForceLockToPart(npcUUID, partId)
end

---@desc 检查Npc对应key的Int类型字典值是否存在
---@param npcId int 默认值: 
---@param key int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckNpcNoteInt(npcId, key)
end

---@desc 检查Npc对应key的float类型字典值是否存在
---@param npcId int 默认值: 
---@param key int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckNpcNoteFloat(npcId, key)
end

---@desc 检查Npc对应key的bool类型字典值是否存在
---@param npcId int 默认值: 
---@param key int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckNpcNoteBool(npcId, key)
end

---@desc 检查Npc对应key的float3类型字典值是否存在
---@param npcId int 默认值: 
---@param key int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckNpcNoteFloat3(npcId, key)
end

---@desc 获取Npc对应key的Int类型字典值
---@param npcId int 默认值: 
---@param key int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetNpcNoteInt(npcId, key)
end

---@desc 获取Npc对应key的float类型字典值
---@param npcId int 默认值: 
---@param key int 默认值: 
---@return float 
function XDlcCSharpFuncs:GetNpcNoteFloat(npcId, key)
end

---@desc 获取Npc对应key的float3类型字典值
---@param npcId int 默认值: 
---@param key int 默认值: 
---@return Vector3 
function XDlcCSharpFuncs:GetNpcNoteFloat3(npcId, key)
end

---@desc 修改Npc对应key的Int类型字典值
---@param npcId int 默认值: 
---@param key int 默认值: 
---@param value int 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcNoteInt(npcId, key, value)
end

---@desc 修改Npc对应key的float类型字典值
---@param npcId int 默认值: 
---@param key int 默认值: 
---@param value float 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcNoteFloat(npcId, key, value)
end

---@desc 修改Npc对应key的float2类型字典值
---@param npcId int 默认值: 
---@param key int 默认值: 
---@param v1 float 默认值: 
---@param v2 float 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcNoteFloat2(npcId, key, v1, v2)
end

---@desc 修改Npc对应key的float3类型字典值
---@param npcId int 默认值: 
---@param key int 默认值: 
---@param v1 float 默认值: 
---@param v2 float 默认值: 
---@param v3 float 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcNoteFloat3(npcId, key, v1, v2, v3)
end

---@desc 注册黑板同步值
---@param domain int 默认值: 
---@param id int 默认值: 
---@param key int 默认值: 
---@return void 
function XDlcCSharpFuncs:RegisterBBSync(domain, id, key)
end

---@desc 取消黑板同步值
---@param domain int 默认值: 
---@param id int 默认值: 
---@param key int 默认值: 
---@return void 
function XDlcCSharpFuncs:UnregisterBBSync(domain, id, key)
end

---@desc 设置黑板值Bool
---@param domain int 默认值: 
---@param id int 默认值: 
---@param key int 默认值: 
---@param value bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetBBBoolean(domain, id, key, value)
end

---@desc 获取黑板值Bool
---@param domain int 默认值: 
---@param id int 默认值: 
---@param key int 默认值: 
---@return bool , bool result:
function XDlcCSharpFuncs:TryGetBBBoolean(domain, id, key)
end

---@desc 设置黑板值Int
---@param domain int 默认值: 
---@param id int 默认值: 
---@param key int 默认值: 
---@param value int 默认值: 
---@return void 
function XDlcCSharpFuncs:SetBBInt(domain, id, key, value)
end

---@desc 获取黑板值Int
---@param domain int 默认值: 
---@param id int 默认值: 
---@param key int 默认值: 
---@return bool , int result:
function XDlcCSharpFuncs:TryGetBBInt(domain, id, key)
end

---@desc 设置黑板值Float
---@param domain int 默认值: 
---@param id int 默认值: 
---@param key int 默认值: 
---@param value float 默认值: 
---@return void 
function XDlcCSharpFuncs:SetBBFloat(domain, id, key, value)
end

---@desc 获取黑板值Float
---@param domain int 默认值: 
---@param id int 默认值: 
---@param key int 默认值: 
---@return bool , float result:
function XDlcCSharpFuncs:TryGetBBFloat(domain, id, key)
end

---@desc 设置黑板值Vector2
---@param domain int 默认值: 
---@param id int 默认值: 
---@param key int 默认值: 
---@param value Vector2 默认值: 
---@return void 
function XDlcCSharpFuncs:SetBBVector2(domain, id, key, value)
end

---@desc 获取黑板值Vector2
---@param domain int 默认值: 
---@param id int 默认值: 
---@param key int 默认值: 
---@return bool , Vector2 result:
function XDlcCSharpFuncs:TryGetBBVector2(domain, id, key)
end

---@desc 设置黑板值Vector3
---@param domain int 默认值: 
---@param id int 默认值: 
---@param key int 默认值: 
---@param value Vector3 默认值: 
---@return void 
function XDlcCSharpFuncs:SetBBVector3(domain, id, key, value)
end

---@desc 获取黑板值Vector3
---@param domain int 默认值: 
---@param id int 默认值: 
---@param key int 默认值: 
---@return bool , Vector3 result:
function XDlcCSharpFuncs:TryGetBBVector3(domain, id, key)
end

---@desc 使一Npc向另一Npc发射子弹
---@param launcherId int 默认值:
---@param targetId int 默认值:
---@param launchId int 默认值:
---@param missileId int 默认值:
---@param level int 默认值:
---@return bool 发射是否成功
function XDlcCSharpFuncs:LaunchMissile(launcherId, targetId, launchId, missileId, level)
end

---@desc 从指定坐标向另一指定坐标发射线性子弹
---@param launcherId int 默认值:
---@param launchId int 默认值:
---@param missileId int 默认值:
---@param launchPos Vector3 默认值:
---@param targetPos Vector3 默认值:
---@param level int 默认值:
---@return bool 发射是否成功
function XDlcCSharpFuncs:LaunchMissileFromPosToPos(launcherId, launchId, missileId, launchPos, targetPos, level)
end

---@desc 移除所有指定发射者的子弹
---@param launcherId int 默认值:
---@return bool 移除是否执行成功
function XDlcCSharpFuncs:DestroyAllMissileDependOnLauncher(launcherId)
end

---@desc 激活虚拟相机
---@desc （激活指定玩家npc对应端的虚拟相机
---@desc （priority为优先级，一般取100，上限9999
---@desc 激活一个固定的虚拟相机的方式，referenceId填0、followId填0、lookAtId填0
---@param playerNpcId int 默认值: 
---@param vCam string 默认值: 
---@param blendIn float 默认值: 
---@param blendOut float 默认值: 
---@param referenceId int 默认值: 
---@param x float 默认值: 
---@param y float 默认值: 
---@param z float 默认值: 
---@param eulerX float 默认值: 
---@param eulerY float 默认值: 
---@param eulerZ float 默认值: 
---@param followId int 默认值: 
---@param lookAtId int 默认值: 
---@param priority int 默认值: 
---@param allClients bool 默认值: 
---@return void 
function XDlcCSharpFuncs:ActivateVCam(playerNpcId, vCam, blendIn, blendOut, referenceId, x, y, z, eulerX, eulerY, eulerZ, followId, lookAtId, priority, allClients)
end

---@desc 关闭虚拟相机 （关闭指定玩家npc对应端的虚拟相机
---@param playerNpcId int 默认值: 
---@param vCam string 默认值: 
---@param allClients bool 默认值: 
---@return void 
function XDlcCSharpFuncs:DeactivateVCam(playerNpcId, vCam, allClients)
end

---@desc 获取目标点和相机坐标连线到相机朝向的夹角
---@param position Vector3 默认值: 
---@param ignoreY bool 默认值: 
---@return float 
function XDlcCSharpFuncs:GetCameraAngleFromPos(position, ignoreY)
end

---@desc 添加自定义相机旋转
---@param id int 默认值: 
---@param x float 默认值: 
---@param y float 默认值: 
---@param z float 默认值: 
---@param blendIn float 默认值: 
---@param blendOut float 默认值: 
---@param relative bool 默认值: 
---@param bind bool 默认值: 
---@return void 
function XDlcCSharpFuncs:AddCustomCameraRotation(id, x, y, z, blendIn, blendOut, relative, bind)
end

---@desc 移除自定义相机旋转
---@param id int 默认值: 
---@return void 
function XDlcCSharpFuncs:RemoveCustomCameraRotation(id)
end

---@desc 开关低饱和度屏幕效果（黑白滤镜
---@param target XNpc 默认值: 
---@param enabled bool 默认值: 
---@param allClients bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetLowSaturation(target, enabled, allClients)
end

---@desc 让程序补注释！
---@param ignoreHeightLerpOnAir bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetCameraIgnoreHeightLerpOnAir(ignoreHeightLerpOnAir)
end

---@desc 重置相机位置
---@param resetAngleX bool 默认值:
---@param rotYEulerOffset float 默认值:
---@param isEndRotationOverride bool 默认值:
---@return void 
function XDlcCSharpFuncs:ResetCamera(resetAngleX, rotYEulerOffset, isEndRotationOverride)
end

---@desc 获取相机位置信息（相对于npc1和npc2构成的坐标系）
---@param npc1UUID int 默认值:
---@param npc2UUID int 默认值:
---@return Vector2 相对于新坐标系的位置, float angleOffset:第二返回值（角度偏移）
function XDlcCSharpFuncs:GetCameraPosInfo(npc1UUID, npc2UUID)
end

---@desc 设置相机操作是否可用（仅客户端）
---@param enable bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetCameraOpEnable(enable)
end

---@desc 获取当前世界ID
---@return int 
function XDlcCSharpFuncs:GetWorldId()
end

---@desc 获取当前关卡ID
---@return int 
function XDlcCSharpFuncs:GetCurrentLevelId()
end

---@desc 切换Level
---@param nextLevelId int 默认值:
---@param position Vector3 默认值:
---@return void 
function XDlcCSharpFuncs:SwitchLevel(nextLevelId, position)
end

---@desc 切换Level
---@param nextLevelId int 默认值:
---@param position Vector3 默认值:
---@param rotation Vector3 默认值:
---@return void 
function XDlcCSharpFuncs:SwitchLevelWitchRot(nextLevelId, position, rotation)
end

---@desc 进入副本Level，要和RequestLeaveInstanceLevel()成对使用
---@param nextLevelId int 默认值:
---@param position Vector3 默认值:
---@param rotation Vector3 默认值:
---@return void 
function XDlcCSharpFuncs:RequestEnterInstLevel(nextLevelId, position, rotation)
end

---@desc 退出副本Level，要和RequestEnterInstLevel()成对使用
---@param resetSaveDataExit bool 默认值:
---@return void 
function XDlcCSharpFuncs:RequestLeaveInstanceLevel(resetSaveDataExit)
end

---@desc 设置关卡存储值Int
---@param key int 默认值: 
---@param value int 默认值: 
---@return void 
function XDlcCSharpFuncs:SetLevelMemoryInt(key, value)
end

---@desc 设置关卡存储值Float
---@param key int 默认值: 
---@param value float 默认值: 
---@return void 
function XDlcCSharpFuncs:SetLevelMemoryFloat(key, value)
end

---@desc 移除关卡存储值Int
---@param key int 默认值: 
---@return void 
function XDlcCSharpFuncs:RemoveLevelMemoryInt(key)
end

---@desc 移除关卡存储值Float
---@param key int 默认值: 
---@return void 
function XDlcCSharpFuncs:RemoveLevelMemoryFloat(key)
end

---@desc 获取关卡存储值Int
---@param key int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetLevelMemoryInt(key)
end

---@desc 获取关卡存储值Float
---@param key int 默认值: 
---@return float 
function XDlcCSharpFuncs:GetLevelMemoryFloat(key)
end

---@desc 检查关卡Int存储值是否存在
---@param key int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckLevelMemoryInt(key)
end

---@desc 检查关卡Float存储值是否存在
---@param key int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckLevelMemoryFloat(key)
end

---@desc 获取关卡点位
---@param id int 默认值: 
---@return Vector3 
function XDlcCSharpFuncs:GetSpot(id)
end

---@desc 创建一个挂载到指定Actor的触发器（Npc或SceneObject）
---@param uuid int 默认值: 
---@param touchType int 默认值:
---@param shapeType int 默认值:
---@param triggerName string 默认值:
---@param localPosition Vector3 默认值:
---@param eulerAngles Vector3 默认值:
---@param size Vector3 默认值:
---@param radius float 默认值:
---@param height float 默认值:
---@param direction int 默认值:
---@return int 返回TriggerId（成功时大于0，失败为0）
function XDlcCSharpFuncs:CreateActorTrigger(uuid, touchType, shapeType, triggerName, localPosition, eulerAngles, size, radius, height, direction)
end

---@desc 启动关卡玩法计时器
---@param time float 默认值:
---@param isCountDown bool
---@param imminentEndTimeS float
---@return bool 
function XDlcCSharpFuncs:StartLevelPlayTimer(time, isCountDown, imminentEndTimeS)
end

---@desc 获取关卡玩法计时器当前时间（单位：秒）
---@return float 
function XDlcCSharpFuncs:GetLevelPlayTimerCurTime()
end

---@desc 暂停关卡玩法计时器
---@return bool 
function XDlcCSharpFuncs:PauseLevelPlayTimer()
end

---@desc 恢复关卡玩法计时器
---@return bool 
function XDlcCSharpFuncs:ResumeLevelPlayTimer()
end

---@desc 终止关卡玩法计时器
---@return bool 
function XDlcCSharpFuncs:StopLevelPlayTimer()
end

---@desc 设置BGM的AISAC控制参数
---@param controlName string 默认值: 
---@param value float 默认值: 
---@return void 
function XDlcCSharpFuncs:SetBgmAisacControl(controlName, value)
end

---@desc 创建关卡特效
---@param effectRefId int 默认值: 
---@param effectName string 默认值: 
---@param posX float 默认值: 
---@param posY float 默认值: 
---@param posZ float 默认值: 
---@param rotX float 默认值: 
---@param rotY float 默认值: 
---@param rotZ float 默认值: 
---@param offsetX float 默认值: 
---@param offsetY float 默认值: 
---@param offsetZ float 默认值: 
---@return void 
function XDlcCSharpFuncs:CreateLevelEffect(effectRefId, effectName, posX, posY, posZ, rotX, rotY, rotZ, offsetX, offsetY, offsetZ)
end

---@desc 移除关卡特效
---@param effectRefId int 默认值: 
---@return void 
function XDlcCSharpFuncs:RemoveLevelEffect(effectRefId)
end

---@desc 检查关卡特效是否存在
---@param effectRefId int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckLevelEffectExist(effectRefId)
end

---@desc 播放相机Timeline
---@param name string 默认值: 
---@param targetId int 默认值: 
---@param blendIn float 默认值: 
---@param blendOut float 默认值: 
---@param locationType int 默认值:
---@return void 
function XDlcCSharpFuncs:PlayCameraTimeline(name, targetId, blendIn, blendOut, locationType)
end

---@desc 停止相机Timeline
---@param name string 默认值: 
---@param targetId int 默认值: 
---@return void 
function XDlcCSharpFuncs:StopCameraTimeline(name, targetId)
end

---@desc 播放场景动画（场景美术事先在场景里编辑好的动画
---@param id int 默认值: 
---@return void 
function XDlcCSharpFuncs:PlaySceneAnimation(id)
end

---@desc 开关场景Timeline
---@param id int 默认值:
---@param state bool 默认值:
---@return void 
function XDlcCSharpFuncs:SwitchSceneTimeline(id, state)
end

---@desc 禁止反复开关（会发送同步消息
---@desc 开关动态障碍
---@param obstacleId int 默认值:
---@param active bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetObstacleActive(obstacleId, active)
end

---@desc 禁止频繁调用（会发送同步消息
---@desc 设置Npc忽略障碍
---@param npcId int 默认值:
---@param obstacleId int 默认值:
---@param ignore bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcIgnoreObstacle(npcId, obstacleId, ignore)
end

---@desc 该功能已弃用，不要再调用
---@param npcId int 默认值: 
---@param groupName string 默认值: 
---@param colliderIndex int 默认值: 
---@param ignore bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetSceneColliderIgnoreCollision(npcId, groupName, colliderIndex, ignore)
end

---@desc 设置两个Actor间互相忽略碰撞
---@param actorUUIDA int 默认值:
---@param actorUUIDB int 默认值:
---@param ignore bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetActorIgnoreCollision(actorUUIDA, actorUUIDB, ignore)
end

---@desc 检查技能时间
---@param npcId int 默认值:
---@param type int 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckActionTiming(npcId, type)
end

---@desc 使Npc释放指定技能
---@param npcId int 默认值: 
---@param skillActionId int 默认值: 
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastAction(npcId, skillActionId)
end

---@desc 使Npc释放指定技能(部分技能)
---@param npcId int 默认值: 
---@param skillActionId int 默认值: 
---@param startTime float 默认值:
---@param endTime float 默认值:
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastActionEx(npcId, skillActionId, startTime, endTime)
end

---@desc 使Npc释放指定技能Action(不检查)
---@param npcId int 默认值: 
---@param skillActionId int 默认值: 
---@param startTime float 默认值:
---@param endTime float 默认值:
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillActionNotCheck(npcId, skillActionId, startTime, endTime)
end

---@desc 向指定坐标放技能
---@param npcId int 默认值: 
---@param skillActionId int 默认值: 
---@param position Vector3 默认值:
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastActionToPosition(npcId, skillActionId, position)
end

---@desc 向指定坐标放技能(部分技能)
---@param npcId int 默认值: 
---@param skillActionId int 默认值: 
---@param position Vector3 默认值:
---@param startTime float 默认值:
---@param endTime float 默认值:
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastActionToPositionEx(npcId, skillActionId, position, startTime, endTime)
end

---@desc 向指定坐标放技能(不检查)
---@param npcId int 默认值: 
---@param skillActionId int 默认值: 
---@param position Vector3 默认值:
---@param startTime float 默认值:
---@param endTime float 默认值:
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillActionToPositionNotCheck(npcId, skillActionId, position, startTime, endTime)
end

---@desc 向指定Npc放技能
---@param npcId int 默认值:
---@param skillActionId int 默认值:
---@param targetNpcId int 默认值:
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastActionToTarget(npcId, skillActionId, targetNpcId)
end

---@desc 向指定Npc放技能(部分技能)
---@param npcId int 默认值:
---@param skillActionId int 默认值:
---@param targetNpcId int 默认值:
---@param startTime float 默认值:
---@param endTime float 默认值:
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastActionToTargetEx(npcId, skillActionId, targetNpcId, startTime, endTime)
end

---@desc 向指定Npc放技能(不检查)
---@param npcId int 默认值:
---@param skillActionId int 默认值:
---@param targetNpcId int 默认值:
---@param startTime float 默认值:
---@param endTime float 默认值:
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillActionToNpcNotCheck(npcId, skillActionId, targetNpcId, startTime, endTime)
end

---@desc 向指定搜索or锁定目标放技能
---@param npcId int 默认值:
---@param skillActionId int 默认值:
---@param targetUID long 默认值:
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastActionToSearchTarget(npcId, skillActionId, targetUID)
end

---@desc 向指定搜索or锁定目标放技能(不检查条件)
---@param npcId int 默认值:
---@param skillActionId int 默认值:
---@param searchTargetId long 默认值:
---@param startTime float 默认值:
---@param endTime float 默认值:
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillActionToSearchTargetNotCheck(npcId, skillActionId, searchTargetId, startTime, endTime)
end

---@desc 打断Npc当前技能
---@param npcId int 默认值: 
---@param force bool 
---@return void 
function XDlcCSharpFuncs:AbortAction(npcId, force)
end

---@desc 检查Npc当前技能是否为指定技能
---@param npcId int 默认值: 
---@param skillActionId int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckNpcCurrentAction(npcId, skillActionId)
end

---@desc 获取当前技能的配置ID以及类型
---@param npcId int 默认值: 
---@return bool , int skillActionId:, int skillType:
function XDlcCSharpFuncs:TryGetCurrentAction(npcId)
end

---@desc 获取当前技能的运行时间
---@param npcId int 默认值: 
---@return bool , float elapsedTime:
function XDlcCSharpFuncs:TryGetNpcCurrentActionElapsedTime(npcId)
end

---@desc 获取技能类型
---@param skillId int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetActionType(skillId)
end

---@desc 获取Npc动作的动作类型(技能Id传0时，使用上一个动作Id作为动作Id)
---@param uuid int 默认值:
---@param actionId int 默认值:
---@return int 
function XDlcCSharpFuncs:GetNpcActionType(uuid, actionId)
end

---@desc 设置动作优先级(动作Id传0时，使用上一个动作Id作为动作Id)
---@param npcUUID int 默认值:
---@param actionId int 默认值:
---@param priority int 默认值:
---@return void 
function XDlcCSharpFuncs:SetActionPriority(npcUUID, actionId, priority)
end

---@desc 获取动作优先级(动作Id传0时，使用上一个动作Id作为动作Id)
---@param npcUUID int 默认值:
---@param actionId int 默认值:
---@return bool , int priority:优先级(第二个返回值)
function XDlcCSharpFuncs:TryGetActionPriority(npcUUID, actionId)
end

---@desc 获取技能特征标签(技能Id传0时，使用上一个技能Id作为技能Id)
---@param npcUUID int 默认值:
---@param skillId int 默认值:
---@return LuaTable 
function XDlcCSharpFuncs:GetActionFeatureTag(npcUUID, skillId)
end

---@desc 检查技能特征标签(技能Id传0时，使用上一个技能Id作为技能Id)
---@param npcUUID int 默认值:
---@param skillId int 默认值:
---@param featureTag int 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckActionFeatureTag(npcUUID, skillId, featureTag)
end

---@desc 获取Npc的技能Id列表
---@param npcUUID int 默认值:
---@return LuaTable 技能ID列表
function XDlcCSharpFuncs:GetActionIdList(npcUUID)
end

---@desc 尝试使用技能
---@param npcUUID int 默认值:
---@param key int 默认值:
---@param type int 默认值:
---@param operateTime float 默认值:
---@return void 
function XDlcCSharpFuncs:TryCastAction(npcUUID, key, type, operateTime)
end

---@desc 获取技能脚本 SkillID
---@return int 
function XDlcCSharpFuncs:GetSelfSkillUUID()
end

---@desc 获取技能的NpcUUID
---@return int 
function XDlcCSharpFuncs:GetSelfSkillNpcUUID()
end

---@desc 获取技能配置
---@return XTableSkill 
function XDlcCSharpFuncs:GetSkillTemplate()
end

---@desc 让技能的Lua脚本每次接受事件时能拿到Input配置
---@param active bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetUseInputTemplate(active)
end

---@desc 尝试获取当前SkillAction所依赖的SkillId
---@param npcId int 默认值: 
---@return bool , int subscribeSkill:
function XDlcCSharpFuncs:TryGetCurrentActionSubscribeSkill(npcId)
end

---@desc 获取技能默认CD
---@return float 
function XDlcCSharpFuncs:GetSkillCoolDown()
end

---@desc 让技能进入默认CD
---@return void 
function XDlcCSharpFuncs:EnterSkillDefaultCD()
end

---@desc 让技能进入固定CD
---@param value float 默认值: 
---@return void 
function XDlcCSharpFuncs:EnterSkillCD(value)
end

---@desc 减少技能CD固定值
---@param value float 默认值: 
---@return void 
function XDlcCSharpFuncs:DecreaseSkillCD(value)
end

---@desc 减少技能CD万分比
---@param value int 默认值: 
---@return void 
function XDlcCSharpFuncs:DecreaseSkillCDPercent(value)
end

---@desc 设置技能当前CD
---@param value int 默认值: 
---@return void 
function XDlcCSharpFuncs:SetSkillCD(value)
end

---@desc 获取技能当前CD
---@return float 
function XDlcCSharpFuncs:GetSkillDefaultCD()
end

---@desc 判断技能是否在CD中
---@return bool 
function XDlcCSharpFuncs:IsSkillInCD()
end

---@desc 获取Buff脚本的配置Id
---@return int 
function XDlcCSharpFuncs:GetSelfBuffId()
end

---@desc 获取Buff脚本所属的BUff的UUID
---@return int 
function XDlcCSharpFuncs:GetSelfBuffUUID()
end

---@desc 获取Buff脚本所属的BUff的CasterNpcUUID
---@return int 
function XDlcCSharpFuncs:GetSelfBuffCasterNpcUUID()
end

---@desc 获取Buff脚本所属的BUff的NpcUUID
---@return int 
function XDlcCSharpFuncs:GetSelfBuffNpcUUID()
end

---@desc 获取Buff层数
---@param npcUUID int 默认值: 
---@param buffTempId int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetBuffStacks(npcUUID, buffTempId)
end

---@desc 根据Kind获取Buff数量
---@param npcUUID int 默认值: 
---@param kind int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetBuffCountByKind(npcUUID, kind)
end

---@desc 检查Buff是否属于传入的类型
---@param buffTempId int 默认值:
---@param kinds List<int> 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckBuffKinds(buffTempId, kinds)
end

---@desc 检查Buff列表是否属于传入类型列表
---@param buffTempIds List<int> 默认值:
---@param kinds List<int> 默认值:
---@return bool 
function XDlcCSharpFuncs:CheckBuffListKinds(buffTempIds, kinds)
end

---@desc 加载场景物件
---@param placeId int 默认值:
---@return bool true成功，false失败
function XDlcCSharpFuncs:LoadSceneObject(placeId)
end

---@desc 卸载SceneObj
---@param placeId int 默认值: 
---@return void 
function XDlcCSharpFuncs:UnloadSceneObject(placeId)
end

---@desc 获取场景物件对象id
---@param placeId int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetSceneObjectUUID(placeId)
end

---@desc 获取场景物件坐标
---@param placeId int 默认值: 
---@return Vector3 
function XDlcCSharpFuncs:GetSceneObjectPositionByPlaceId(placeId)
end

---@desc 获取场景物件朝向
---@param placeId int 默认值: 
---@return Vector3 
function XDlcCSharpFuncs:GetSceneObjectRotationByPlaceId(placeId)
end

---@desc 获取场景物件坐标
---@param uuid int 默认值: 
---@return Vector3 
function XDlcCSharpFuncs:GetSceneObjectPosition(uuid)
end

---@desc 获取场景物件朝向
---@param uuid int 默认值: 
---@return Vector3 
function XDlcCSharpFuncs:GetSceneObjectRotation(uuid)
end

---@desc 开关场景物件
---@param sceneObjectPlaceId int 默认值: 
---@param active bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetSceneObjectActive(sceneObjectPlaceId, active)
end

---@desc 场景物件是否开启
---@param sceneObjectPlaceId int 默认值: 
---@return bool 
function XDlcCSharpFuncs:IsSceneObjectActive(sceneObjectPlaceId)
end

---@desc 开关场景物件阴影（仅在客户端生效）
---@param sceneObjectPlaceId int 默认值: 
---@param enable bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetSceneObjectShadowEnable(sceneObjectPlaceId, enable)
end

---@desc 移动场景物体到MoveComponent的第几个点
---@param sceneObjectPlaceId int 默认值: 
---@param nodeId int 默认值: 
---@return void 
function XDlcCSharpFuncs:MoveSceneObjectToNode(sceneObjectPlaceId, nodeId)
end

---@desc 开启SceneObj的自动旋转
---@param sceneObjectPlaceId int 默认值: 
---@param isRotate bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetSceneObjectAutoRotate(sceneObjectPlaceId, isRotate)
end

---@desc 旋转SceneObject，仅在SceneObject不会自动旋转时生效
---@param sceneObjectPlaceId int 默认值:
---@param rotateTime float 默认值:
---@param rotateAngle float 默认值:
---@param rotateAxis byte 默认值:
---@param isQueue bool
---@return void 
function XDlcCSharpFuncs:RotateSceneObject(sceneObjectPlaceId, rotateTime, rotateAngle, rotateAxis, isQueue)
end

---@desc 设置SceneObject的特效字文本（仅客户端使用）
---@param sceneObjectPlaceId int 默认值:
---@param isEnabled bool 默认值:
---@param textKey string 默认值:
---@return void 
function XDlcCSharpFuncs:SetSceneObjectTextMeshText(sceneObjectPlaceId, isEnabled, textKey)
end

---@desc 开关场景物件钩点组件
---@param soPlaceId int 默认值: 
---@param enable bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetHookableSceneObjectEnable(soPlaceId, enable)
end

---@desc 使场景物件执行指定动作
---@param soPlaceId int 默认值: 
---@param actionId int 默认值: 
---@return bool 
function XDlcCSharpFuncs:DoSceneObjectAction(soPlaceId, actionId)
end

---@desc 检查场景物件是否在执行指定动作
---@param soPlaceId int 默认值: 
---@param actionId int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckSceneObjectAction(soPlaceId, actionId)
end

---@desc 请联系程序补充注释
---@param soPlaceId int 默认值: 
---@param scriptId int 默认值: 
---@return void 
function XDlcCSharpFuncs:AddSceneObjectScript(soPlaceId, scriptId)
end

---@desc 请联系程序补充注释
---@param soPlaceId int 默认值: 
---@param scriptId int 默认值: 
---@return void 
function XDlcCSharpFuncs:RemoveSceneObjectScript(soPlaceId, scriptId)
end

---@desc 生成SceneObject
---@param sceneObjId int 默认值: 
---@param position Vector3 默认值: 
---@param rotation Vector3 默认值: 
---@return int 
function XDlcCSharpFuncs:CreateSceneObject(sceneObjId, position, rotation)
end

---@desc 移除SceneObject
---@param sceneObjUUID int 默认值: 
---@return void 
function XDlcCSharpFuncs:DestroySceneObject(sceneObjUUID)
end

---@desc 设置SceneObject锁定状态（仅限控制端调用）
---@param soPlaceId int 默认值: 
---@param locked bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetSceneObjectLocked(soPlaceId, locked)
end

---@desc 播放任务剧情
---@param questId int 默认值:
---@param dramaName string 默认值:
---@param referencePos Vector3
---@param referenceRot Vector3
---@param combineKey int
---@return void 
function XDlcCSharpFuncs:PlayQuestDrama(questId, dramaName, referencePos, referenceRot, combineKey)
end

---@desc 直接播放剧情
---@param dramaName string 默认值:
---@param referencePos Vector3
---@param referenceRot Vector3
---@param combineKey int
---@return void 
function XDlcCSharpFuncs:PlayDrama(dramaName, referencePos, referenceRot, combineKey)
end

---@desc 播放简易台词
---@desc 枚举文档:https://kurogame.feishu.cn/sheets/JLxYs1gwShWf25tBScrc9xqqngd?sheet=3zVYsP
---@param captionName string 默认值:
---@param isSequential bool
---@return void 
function XDlcCSharpFuncs:PlayDramaCaption(captionName, isSequential)
end

---@desc 播放气泡
---@param actorType int 默认值:
---@param uuid int 默认值: 
---@param bubbleName string 默认值: 
---@return void 
function XDlcCSharpFuncs:PlayDramaBubble(actorType, uuid, bubbleName)
end

---@desc 停止气泡
---@param actorType int 默认值:
---@param uuid int 默认值: 
---@return void 
function XDlcCSharpFuncs:StopDramaBubble(actorType, uuid)
end

---@desc 设置任务剧情选项显示列表
---@param questId int 默认值: 
---@param dramaName string 默认值: 
---@param decisionNodeId int 默认值: 
---@param optionShowList List<int> 默认值: 
---@return void 
function XDlcCSharpFuncs:SetQuestDecisionDialogShowList(questId, dramaName, decisionNodeId, optionShowList)
end

---@desc 设置npc剧情选项显示列表
---@param npcUUID int 默认值: 
---@param decisionNodeId int 默认值: 
---@param optionShowList List<int> 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcDecisionDialogShowList(npcUUID, decisionNodeId, optionShowList)
end

---@desc 获取某个节点第一次选的选项Id
---@param nodeId int 默认值:
---@return int 
function XDlcCSharpFuncs:GetDramaDialogFirstDecisionId(nodeId)
end

---@desc 获取某个节点所有选择过的选项Id（有循环跳转的时候，一个分歧会被选择多次）
---@param nodeId int 默认值: 
---@return LuaTable 
function XDlcCSharpFuncs:GetDramaDialogDecisionIdList(nodeId)
end

---@desc 开关锚点UI
---@param soPlaceId int 默认值: 
---@param active bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetSpearPointUiActive(soPlaceId, active)
end

---@desc 设置锚点UI进度
---@param soPlaceId int 默认值: 
---@param progress float 默认值: 
---@return void 
function XDlcCSharpFuncs:SetSpearPointUiProgress(soPlaceId, progress)
end

---@desc 显示提示
---@param id int 默认值: 
---@param var int 默认值: 
---@return void 
function XDlcCSharpFuncs:ShowTip(id, var)
end

---@desc 关闭提示
---@param id int 默认值: 
---@return void 
function XDlcCSharpFuncs:CloseTip(id)
end

---@desc 显示战斗引导
---@param id int 默认值:
---@return void 
function XDlcCSharpFuncs:ShowGuide(id)
end

---@desc 关闭战斗引导
---@return void 
function XDlcCSharpFuncs:HideGuide()
end

---@desc 手动触发系统引导开启检查
---@return void 
function XDlcCSharpFuncs:TryActiveSystemGuide()
end

---@desc 显隐指定UI界面
---@param uiIndex int 默认值:
---@param active bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetUiActive(uiIndex, active)
end

---@desc 显隐指定UI界面下某个部件
---@param uiIndex int 默认值:
---@param widgetKey int 默认值:
---@param active bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetUiWidgetActive(uiIndex, widgetKey, active)
end

---@desc 设置是否允许Npc使用顶部血条
---@param npcId int 默认值: 
---@param enable bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcTopHpEnable(npcId, enable)
end

---@desc 开关动态血条
---@param npcId int 默认值:
---@param show bool 默认值:
---@return void 
function XDlcCSharpFuncs:ShowDynamicHpBar(npcId, show)
end

---@desc 开关Npc头顶标识信息
---@param npcId int 默认值: 
---@param active bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcTopInfoActive(npcId, active)
end

---@desc 开关假结算（黑白龙转场演出用
---@param active bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetFakeSettleActive(active)
end

---@desc 打开通用黑幕特效
---@param enterDuration float 默认值:
---@param exitDuration float 默认值:
---@return void 
function XDlcCSharpFuncs:PlayBlackScreenEffect(enterDuration, exitDuration)
end

---@desc 播放屏幕特效(控制时长)【注】引用的屏幕特效需要添加脚本资源依赖表
---@param screenEffectId int 默认值:
---@param enterDuration float 默认值:
---@param exitDuration float 默认值:
---@return void 
function XDlcCSharpFuncs:PlayScreenEffectById(screenEffectId, enterDuration, exitDuration)
end

---@desc 播放持续屏幕特效(不控制时长), 需要使用KillStayScreenEffectById关闭【注】引用的屏幕特效需要添加脚本资源依赖表
---@param screenEffectId int 默认值:
---@return void 
function XDlcCSharpFuncs:PlayStayScreenEffectById(screenEffectId)
end

---@desc 卸载屏幕特效(不控制时长)
---@param screenEffectId int 默认值:
---@return void 
function XDlcCSharpFuncs:KillStayScreenEffectById(screenEffectId)
end

---@desc 为指定关卡物体播放特效
---@param sceneObjectPlaceId int 默认值:
---@param effectName string 默认值:
---@param posOffset Vector3 默认值:
---@param rotOffset Vector3 默认值:
---@param scale Vector3 默认值:
---@param partNames string[]
---@return void 
function XDlcCSharpFuncs:BindSceneObjectEffect(sceneObjectPlaceId, effectName, posOffset, rotOffset, scale, partNames)
end

---@desc 设置关卡实体所有空间音效开关
---@param actorType int 默认值:
---@param placeId int 默认值:
---@param active bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetActorAllSpaceAudioActive(actorType, placeId, active)
end

---@desc 设置关卡实体一个空间音效开关
---@param actorType int 默认值:
---@param placeId int 默认值:
---@param index int 默认值: 
---@param active bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetActorOneSpaceAudioActive(actorType, placeId, index, active)
end

---@desc 播放背景音乐
---@desc 参考文档：【需求】V2.13 音频需求对接-音频战斗控制逻辑相关(2024.02.29) -【2.3 BGM相关】
---@param cueId int 默认值:
---@param stopDuration float
---@param startTime float
---@param endTime float
---@param lastFor float
---@param fadeIn float
---@param fadeOut float
---@return void 
function XDlcCSharpFuncs:PlayMusicInOut(cueId, stopDuration, startTime, endTime, lastFor, fadeIn, fadeOut)
end

---@desc 以平滑过渡形式修改BGM的aisac参数
---@param controlName string 默认值:
---@param targetValue float 默认值:
---@param startValue float
---@param curveTime float
---@return void 
function XDlcCSharpFuncs:ChangeMusicAisacTween(controlName, targetValue, startValue, curveTime)
end

---@desc 设置音频音量控制模式（默认乘法合并）
---@param mode int 默认值:
---@return void 
function XDlcCSharpFuncs:SetAudioVolumeControlMode(mode)
end

---@desc 音频音量调整
---@param volumeController int 默认值:
---@param audioType int 默认值:
---@param volume float 默认值:
---@param curveTime float 默认值:
---@return void 
function XDlcCSharpFuncs:ChangeAudioVolume(volumeController, audioType, volume, curveTime)
end

---@desc 设置音频开关控制模式（默认与逻辑,指多方权限分配: 关卡控制、角色控制、怪物控制, 详细参考主线音频控制行为树节点）
---@param mode int 默认值:
---@return void 
function XDlcCSharpFuncs:SetAudioSwitchControlMode(mode)
end

---@desc 设置音频是否开启
---@param volumeController int 默认值:
---@param audioType int 默认值:
---@param isOpen bool 默认值:
---@return void 
function XDlcCSharpFuncs:ChangeAudioEnable(volumeController, audioType, isOpen)
end

---@desc 播放Bgm
---@param controllerType int 默认值:
---@param cueId int 默认值:
---@param startTime float 默认值:
---@param endTime float 默认值:
---@param stopDuration float 默认值:
---@param lastFor float 默认值:
---@param fadeInDuration float 默认值:
---@param fadeOutDuration float 默认值:
---@param isCrossFade bool 默认值:
---@return void 
function XDlcCSharpFuncs:PlayFightAudioBgm(controllerType, cueId, startTime, endTime, stopDuration, lastFor, fadeInDuration, fadeOutDuration, isCrossFade)
end

---@desc 播放音效
---@param cueId int 默认值: 
---@param actorType int
---@param actorId int
---@param duration float
---@param stopDuration float
---@param startTime float
---@param endTime float
---@param lastFor float
---@param attack float
---@param release float
---@return int AudioId, 用以进行暂停、恢复、停止、调节音量
function XDlcCSharpFuncs:PlaySound(cueId, actorType, actorId, duration, stopDuration, startTime, endTime, lastFor, attack, release)
end

---@desc 通过AudioUid设置音频音量
---@param audioId int 默认值: 
---@param volume float 默认值: 
---@return void 
function XDlcCSharpFuncs:ChangeAudioVolumeByUid(audioId, volume)
end

---@desc 通过AudioUid暂停音频
---@param audioUid int 默认值: 
---@return void 
function XDlcCSharpFuncs:PauseAudioByUid(audioUid)
end

---@desc 通过AudioUid恢复音频
---@param audioId int 默认值: 
---@return void 
function XDlcCSharpFuncs:ResumeAudioByUid(audioId)
end

---@desc 通过AudioUid停止音频
---@param audioUid int 默认值: 
---@return void 
function XDlcCSharpFuncs:StopAudioByUid(audioUid)
end

---@desc 停止Bgm
---@param controllerType int 默认值:
---@param cueId int 默认值:
---@return void 
function XDlcCSharpFuncs:StopFightAudioBgm(controllerType, cueId)
end

---@desc 暂停当前播放的BGM
---@param controllerType int 默认值:
---@return void 
function XDlcCSharpFuncs:PauseFightAudioBgm(controllerType)
end

---@desc 恢复当前暂停的BGM
---@param controllerType int 默认值:
---@return void 
function XDlcCSharpFuncs:ResumeFightAudioBgm(controllerType)
end

---@desc BGM Block功能开关
---@param isOpen bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetFightAudioBlockOperationEnable(isOpen)
end

---@desc 初始化BGM Block
---@param blockIndex int 默认值: 
---@return void 
function XDlcCSharpFuncs:InitAudioBlock(blockIndex)
end

---@desc 战斗用切换BGM Block 使用前先调用InitAudioBlock接口
---@param blockIndex int 默认值: 
---@return void 
function XDlcCSharpFuncs:SwitchFightAudioBlockByFight(blockIndex)
end

---@desc 关卡用切换BGM Block 使用前先调用InitAudioBlock接口
---@param blockIndex int 默认值: 
---@return void 
function XDlcCSharpFuncs:SwitchFightAudioBlockByLevel(blockIndex)
end

---@desc 切换BGM Selector
---@param selectorName string 默认值:
---@param labelName string 默认值:
---@return void 
function XDlcCSharpFuncs:ChangeMusicSelector(selectorName, labelName)
end

---@desc 切换所有音频选择器
---@param selectorName string 默认值:
---@param labelName string 默认值:
---@return void 
function XDlcCSharpFuncs:SetAllAudioSelector(selectorName, labelName)
end

---@desc 增加QTE时间
---@param time float 默认值: 
---@return void 
function XDlcCSharpFuncs:AddQTETime(time)
end

---@desc 设置在场玩家进入QTE时间（黯角boss战专用） 参数分别是第几位成员进入QTE增加的时间
---@param time1 float 默认值: 
---@param time2 float 默认值: 
---@param time3 float 默认值: 
---@return void 
function XDlcCSharpFuncs:UpdateRoleCountQTETime(time1, time2, time3)
end

---@desc 玩家摇杆用力量化长度
---@return float 
function XDlcCSharpFuncs:GetMoveNormalizedDist()
end

---@desc 【仅限玩家npc调用】查询摇杆值
---@desc 接口使用示例：
---@desc local success, axis = self._proxy:TryGetQueryStickAxis()
---@return bool , Vector2 xyAxis:
function XDlcCSharpFuncs:TryGetQueryStickAxis()
end

---@desc 检测按键是否按下
---@param opKey int 默认值:
---@return bool 
function XDlcCSharpFuncs:IsKeyDown(opKey)
end

---@desc 检测按键是否长按
---@param opKey int 默认值: 
---@return bool , float time:长按时间
function XDlcCSharpFuncs:IsKeyHold(opKey)
end

---@desc 检测按键是否抬起
---@param opKey int 默认值: 
---@return bool 
function XDlcCSharpFuncs:IsKeyUp(opKey)
end

---@desc 请提示程序补充注释
---@return bool 
function XDlcCSharpFuncs:HasMoveInput()
end

---@desc 请提示程序补充注释
---@return Vector3 
function XDlcCSharpFuncs:GetMoveInputOperation()
end

---@desc 修改团队分数
---@param delta int 默认值:
---@return void 
function XDlcCSharpFuncs:ChangeRubikTeamScore(delta)
end

---@desc 获取当前团队分数
---@return int 
function XDlcCSharpFuncs:GetRubikTeamScore()
end

---@desc 修改玩家分数
---@param playerNpcId int 默认值:
---@param delta int 默认值:
---@return void 
function XDlcCSharpFuncs:ChangeRubikPlayerScore(playerNpcId, delta)
end

---@desc 获取玩家分数
---@param playerNpcId int 默认值:
---@return int 
function XDlcCSharpFuncs:GetRubikPlayerScore(playerNpcId)
end

---@desc 设置玩家猫鼠阵营
---@param npcId int 默认值:
---@param isCat bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetMouseHunterPlayerCamp(npcId, isCat)
end

---@desc 设置玩家积分
---@param npcId int 默认值: 
---@param score int 默认值: 
---@return void 
function XDlcCSharpFuncs:SetMouseHunterPlayerScore(npcId, score)
end

---@desc 设置猫的捕鼠数量
---@param npcId int 默认值: 
---@param huntCount int 默认值: 
---@return void 
function XDlcCSharpFuncs:SetCatHuntCount(npcId, huntCount)
end

---@desc 设置老鼠存活时间
---@param npcId int 默认值: 
---@param liveTime int 默认值:
---@return void 
function XDlcCSharpFuncs:SetMouseAliveTime(npcId, liveTime)
end

---@desc 设置老鼠数量
---@param liveCount int 默认值:
---@param totalCount int 默认值:
---@return void 
function XDlcCSharpFuncs:SetPlayerMouseCount(liveCount, totalCount)
end

---@desc 创建老鼠变身选项列表
---@param npcId int 默认值: 
---@param reserveOptionsTable LuaTable 默认值:
---@return void 
function XDlcCSharpFuncs:CreateMouseTransformOptionList(npcId, reserveOptionsTable)
end

---@desc 开关猫鼠阵营提示
---@desc 该方法会自动判断调用的客户端玩家阵营，显示对应的阵营图标。
---@param tipId int 默认值:
---@return void 
function XDlcCSharpFuncs:ShowMouseHunterCampTip(tipId)
end

---@desc 生成道具
---@param key int 默认值: 
---@param position Vector3 默认值: 
---@return void 
function XDlcCSharpFuncs:GenerateMouseHunterItem(key, position)
end

---@desc 根据子弹UUID获取对应的道具key
---@param missileUUID int 默认值: 
---@return int 
function XDlcCSharpFuncs:MouseHunterGetItemKey(missileUUID)
end

---@desc 获取玩家的阵营。[玩家ID] = 阵营  1为猫2为鼠
---@return LuaTable 
function XDlcCSharpFuncs:MouseHunterGetCatCampIndex()
end

---@desc 设置技能CD
---@param skillId int 默认值: 
---@param skillCD float 默认值: 
---@return void 
function XDlcCSharpFuncs:MouseHunterSetSkillCD(skillId, skillCD)
end

---@desc 标记关卡玩法完成
---@param isFullyCleared bool 默认值:
---@return void 
function XDlcCSharpFuncs:CompleteLevelPlay(isFullyCleared)
end

---@desc 通知任务系统，任务目标脚本enter执行结束
---@return void 
function XDlcCSharpFuncs:FinishQuestObjectiveScriptEnter()
end

---@desc 通知任务系统，任务目标脚本exit执行结束
---@return void 
function XDlcCSharpFuncs:FinishQuestObjectiveScriptExit()
end

---@desc 设置任务步骤进度完成类型
---@param questId int 默认值: 
---@param stepId int 默认值: 
---@param objectiveId int 默认值: 
---@param type int 默认值: 
---@return void 
function XDlcCSharpFuncs:SetQuestObjectiveFinishType(questId, stepId, objectiveId, type)
end

---@desc 获取任务步骤进度完成类型
---@param objectiveId int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetQuestObjectiveFinishType(objectiveId)
end

---@desc 检查任务目标进度是否完成
---@param objectiveId int 默认值: 
---@return bool 
function XDlcCSharpFuncs:IsQuestObjectiveFinished(objectiveId)
end

---@desc 检查任务目标是否未激活
---@param objectiveId int 默认值: 
---@return bool 
function XDlcCSharpFuncs:IsQuestObjectiveInActive(objectiveId)
end

---@desc 检查是否在任务内
---@param questId int 默认值: 
---@return bool 
function XDlcCSharpFuncs:IsInQuest(questId)
end

---@desc 设置Actor任务占用
---@desc 如果Actor设置了任务占用并且在任务完成期间未再设设置回未占用状态，则会在任务结束后自动将占用Actor设 置为未占用
---@param questId int 默认值:
---@param uuid int 默认值:
---@param isIn bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetActorInQuest(questId, uuid, isIn)
end

---@desc 联系程序补充注释
---@param uuid int 默认值: 
---@return bool 
function XDlcCSharpFuncs:IsActorInQuest(uuid)
end

---@desc 打开任务道具交付UI
---@param objectiveId int 默认值:
---@return void 
function XDlcCSharpFuncs:OpenQuestItemDeliveryUI(objectiveId)
end

---@desc 试用角色加入队伍
---@param trialNpcIds List<int> 默认值:
---@param addMode ETrialNpcAddMode 默认值:
---@param curNpcPos int 默认值:
---@return void 
function XDlcCSharpFuncs:AddTrialNpcToTeam(trialNpcIds, addMode, curNpcPos)
end

---@desc 试用角色离开队伍
---@return void 
function XDlcCSharpFuncs:RemoveTrialNpcFromTeam()
end

---@desc 提醒程序补充注释
---@return void 
function XDlcCSharpFuncs:FinishInstLevel()
end

---@desc 手动接取任务 仅限任务Objective脚本使用，使用时quest不配AutoUndertake字段
---@return void 
function XDlcCSharpFuncs:UnderTakeSelfQuest()
end

---@desc 添加任务自动卸载Npc白名单
---@param levelId int 默认值: 
---@param placeIdList List<int> 默认值:
---@return void 
function XDlcCSharpFuncs:AddUnloadNpcWhiteList(levelId, placeIdList)
end

---@desc 添加任务自动卸载SceneObj白名单
---@param levelId int 默认值: 
---@param placeIdList List<int> 默认值:
---@return void 
function XDlcCSharpFuncs:AddUnloadSceneObjWhiteList(levelId, placeIdList)
end

---@desc 检查系统条件是否达成
---@param conditionId int 默认值: 
---@return bool 
function XDlcCSharpFuncs:CheckSystemCondition(conditionId)
end

---@desc 设置系统功能开放或屏蔽
---@param systemFunctionType ESystemFunctionType 默认值:
---@param enable bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetSystemFuncEntryEnable(systemFunctionType, enable)
end

---@desc 设置一批系统功能开放或屏蔽
---@param enableList List<int> 默认值:
---@param disableList List<int> 默认值:
---@return void 
function XDlcCSharpFuncs:SetSystemFuncEntryEnableBatch(enableList, disableList)
end

---@desc 控制具体的系统功能状态
---@param systemFunctionType ESystemFunctionType 默认值:
---@param args List<object> 默认值:
---@return void 
function XDlcCSharpFuncs:ControlSystemFunction(systemFunctionType, args)
end

---@desc 设置玩家第一人称模式
---@param isFirstPersonMode bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetPlayerFirstPersonMode(isFirstPersonMode)
end

---@desc 弹出第一人称设置UI
---@param isShowClose bool 默认值:
---@param titleTextKey string 默认值:
---@return void 
function XDlcCSharpFuncs:OpenSetPersonModeUI(isShowClose, titleTextKey)
end

---@desc 获取当前第一人称模式和状态
---@return bool 第一人称模式, bool state:(第二返回值)第一人称状态
function XDlcCSharpFuncs:GetPlayerFirstPersonModeAndState()
end

---@desc 获取玩家在指定关卡中保存的人称模式数据
---@param levelId int 默认值:
---@return bool , bool mode:是否是第一人称模式
function XDlcCSharpFuncs:GetSavedPlayerFirstPersonState(levelId)
end

---@desc 打开【玩家自定义外观】的UI
---@return void 
function XDlcCSharpFuncs:ShowPlayerDIYUI()
end

---@desc 发送短信
---@param messageId int 默认值: 
---@return void 
function XDlcCSharpFuncs:SendChatMessage(messageId)
end

---@desc 显示大世界图文教学
---@param teachId int 默认值: 
---@return void 
function XDlcCSharpFuncs:ShowBigWorldTeach(teachId)
end

---@desc 在空花下打开玩法入口并推进相机到指定位置
---@param bigWorldActivityId int 默认值: 
---@param args object[] 默认值: 
---@return void 
function XDlcCSharpFuncs:OpenGameplayMainEntrance(bigWorldActivityId, args)
end

---@desc OperateDormitoryPhotoWall
---@return void 
function XDlcCSharpFuncs:OperateDormitoryPhotoWall()
end

---@desc 宿舍玩法-与摆件架交互
---@return void 
function XDlcCSharpFuncs:OperateDormitoryFrameWall()
end

---@desc 宿舍玩法-修改宿舍涂装
---@return void 
function XDlcCSharpFuncs:ChangeDormitorySkin()
end

---@desc 打开拍照玩法
---@param camParamId int 默认值: 
---@param npcPlaceIdList List<int> 默认值: 
---@param sceneObjectPlaceIdList List<int> 默认值: 
---@return void 
function XDlcCSharpFuncs:OpenGameplayPhotograph(camParamId, npcPlaceIdList, sceneObjectPlaceIdList)
end

---@desc 获取自走棋Npc自动模式
---@param uuid int 默认值:
---@return bool 
function XDlcCSharpFuncs:GetAutoChessNpcAutoMode(uuid)
end

---@desc 设置自走棋技能冷却显示
---@param uuid int 默认值:
---@param id int 默认值:
---@param current float 默认值:
---@param max float 默认值:
---@return void 
function XDlcCSharpFuncs:SetAutoChessSkillData(uuid, id, current, max)
end

---@desc 设置自走棋技能队列状态
---@param uuid int 默认值:
---@param id int 默认值:
---@return void 
function XDlcCSharpFuncs:SetAutoChessSkillTriggerState(uuid, id)
end

---@desc 设置自走棋技能释放状态
---@param uuid int 默认值:
---@param id int 默认值:
---@return void 
function XDlcCSharpFuncs:SetAutoChessSkillActiveState(uuid, id)
end

---@desc 设置自走棋宝石冷却显示
---@param uuid int 默认值:
---@param id int 默认值:
---@param current float 默认值:
---@param max float 默认值:
---@return void 
function XDlcCSharpFuncs:SetAutoChessGemData(uuid, id, current, max)
end

---@desc 设置自走棋宝珠触发状态
---@param uuid int 默认值:
---@param id int 默认值:
---@return void 
function XDlcCSharpFuncs:SetAutoChessGemTriggerState(uuid, id)
end

---@desc 设置自走棋宝珠持续生效状态
---@param uuid int 默认值:
---@param id int 默认值:
---@return void 
function XDlcCSharpFuncs:SetAutoChessGemActiveState(uuid, id)
end

---@desc 打开自走棋疲劳UI
---@return void 
function XDlcCSharpFuncs:ShowAutoChessTriedMessageTip()
end

---@desc 打开自走棋倒计时UI
---@param seconds int 默认值: 
---@return void 
function XDlcCSharpFuncs:ShowAutoChessCountDownMessageTip(seconds)
end

---@desc 获取自走棋Npc
---@param self bool 默认值:
---@return int 
function XDlcCSharpFuncs:GetAutoChessNpc(self)
end

---@desc 添加自走棋宝珠触发次数
---@param npcId int 默认值: 
---@param gemId int 默认值: 
---@param value int 默认值: 
---@return void 
function XDlcCSharpFuncs:AddAutoChessGemTriggerRecord(npcId, gemId, value)
end

---@desc TODO 自走棋调试用 绑定UI
---@param uuid int 默认值:
---@param self bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetAutoChessNpcUi(uuid, self)
end

---@desc 获取自走棋角色配置ID
---@param uuid int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetAutoChessCharacterId(uuid)
end

---@desc 设置自走棋UI显隐动画
---@param active bool 默认值: 
---@param animName string 默认值: 
---@return void 
function XDlcCSharpFuncs:SetAutoChessUiActive(active, animName)
end

---@desc 设置自走棋计时器UI显隐
---@param active bool 默认值: 
---@param offset int 默认值: 
---@return void 
function XDlcCSharpFuncs:SetAutoChessTimerTipsActive(active, offset)
end

---@desc 根据SkillId获取技能配置
---@param id int 默认值: 
---@return XTable.XTableTheatre5ItemSkill 
function XDlcCSharpFuncs:GetAutoChessSkillConfig(id)
end

---@desc 根据MagicId获取技能配置
---@param id int 默认值: 
---@return XTable.XTableTheatre5ItemSkill 
function XDlcCSharpFuncs:GetAutoChessSkillConfigByMagicId(id)
end

---@desc 获取角色配置
---@param id int 默认值: 
---@return XTable.XTableTheatre5Character 
function XDlcCSharpFuncs:GetAutoChessCharacterConfig(id)
end

---@desc 获取宝珠配置
---@param id int 默认值: 
---@return XTable.XTableTheatre5ItemRune 
function XDlcCSharpFuncs:GetAutoChessRuneConfig(id)
end

---@desc 赛后结算MagicId映射到SkillId
---@param magicId int 默认值: 
---@param skillId int 默认值: 
---@return void 
function XDlcCSharpFuncs:MagicIdToSkillIdMapping(magicId, skillId)
end

---@desc 设置连携玩法激活
---@param active bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetGameplayFullChainActive(active)
end

---@desc 获取连携技能上下文数据
---@return LuaTable 
function XDlcCSharpFuncs:GetFullChainContext()
end

---@desc 获取锁定破韧状态
---@param uuid int 默认值: 
---@return bool 
function XDlcCSharpFuncs:GetNpcInBrokenState(uuid)
end

---@desc 获取锁定削韧状态
---@param uuid int 默认值: 
---@return bool 
function XDlcCSharpFuncs:GetNpcInBreakState(uuid)
end

---@desc 获取韧性状态
---@param uuid int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetNpcBreakState(uuid)
end

---@desc 获取韧性值
---@param uuid int 默认值: 
---@return int , int max:最大值
function XDlcCSharpFuncs:GetNpcBreakGauge(uuid)
end

---@desc 设置韧性值
---@param uuid int 默认值: 
---@param value int 默认值: 
---@param condition ENpcBreakStateCondition 默认值: 
---@return bool 
function XDlcCSharpFuncs:SetNpcBreakGauge(uuid, value, condition)
end

---@desc 设置击破/韧性条激活状态
---@param uuid int 默认值: 
---@param active bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcBreakGaugeActive(uuid, active)
end

---@desc 设置OverDrive激活状态
---@param uuid int 默认值: 
---@param active bool 默认值: 
---@return void 
function XDlcCSharpFuncs:SetNpcOverDriveActive(uuid, active)
end

---@desc 开关团队极限技玩法
---@param enable bool 默认值: 
---@param maxEnergy int 默认值:
---@param chainLimitTime float 默认值:
---@return void 
function XDlcCSharpFuncs:SetTeamWorkSkillActive(enable, maxEnergy, chainLimitTime)
end

---@desc 消耗团队极限技能量
---@param npcUUID int 默认值: 
---@param energy int 默认值: 
---@param skillId int 默认值: 
---@return void 
function XDlcCSharpFuncs:CastTeamWorkEnergy(npcUUID, energy, skillId)
end

---@desc 添加团队极限技能量
---@param npcUUID int 默认值: 
---@param energy int 默认值: 
---@return void 
function XDlcCSharpFuncs:AddTeamWorkEnergy(npcUUID, energy)
end

---@desc 设置团队极限技能量
---@param npcUUID int 默认值: 
---@param energy int 默认值: 
---@return void 
function XDlcCSharpFuncs:SetTeamWorkEnergy(npcUUID, energy)
end

---@desc 清除团队极限技能量
---@param npcUUID int 默认值: 
---@return void 
function XDlcCSharpFuncs:CleanTeamWorkEnergy(npcUUID)
end

---@desc 获取团队极限机能量
---@param npcUUID int 默认值: 
---@return int 
function XDlcCSharpFuncs:GetTeamWorkEnergy(npcUUID)
end

---@desc 获取团队极限机最大能量
---@return int 
function XDlcCSharpFuncs:GetTeamWorkMaxEnergy()
end

---@desc 开启角力
---@param launcherUUID int 默认值:
---@param targetUUID int 默认值:
---@param wrestleId int 默认值:
---@return void 
function XDlcCSharpFuncs:CastWrestle(launcherUUID, targetUUID, wrestleId)
end

---@desc 开启多人弹刀
---@param launcherUUID int 默认值:
---@param targetUUID int 默认值:
---@param id int 默认值:
---@return void 
function XDlcCSharpFuncs:CastMultiParry(launcherUUID, targetUUID, id)
end

---@desc 关卡专用操作按键开关
---@param operationKey int 默认值:
---@param npcId int 默认值:
---@param state bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetLevelButtonOpEnabled(operationKey, npcId, state)
end

---@desc 怪物专用操作按键开关
---@param operationKey int 默认值:
---@param npcId int 默认值:
---@param state bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetMonsterButtonOpEnabled(operationKey, npcId, state)
end

---@desc 玩家专用操作按键开关
---@param operationKey int 默认值:
---@param npcId int 默认值:
---@param state bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetPlayerButtonOpEnabled(operationKey, npcId, state)
end

---@desc Npc专用操作按键开关
---@param operationKey int 默认值:
---@param npcId int 默认值:
---@param state bool 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcButtonOpEnabled(operationKey, npcId, state)
end

---@desc 关卡专用操作按键显隐
---@param uiType int 默认值:
---@param operationKey int 默认值:
---@param npcId int 默认值:
---@param uiState int 默认值:
---@return void 
function XDlcCSharpFuncs:SetLevelOperationUiState(uiType, operationKey, npcId, uiState)
end

---@desc 怪物专用操作按键显隐
---@param uiType int 默认值:
---@param operationKey int 默认值:
---@param npcId int 默认值:
---@param uiState int 默认值:
---@return void 
function XDlcCSharpFuncs:SetMonsterOperationUiState(uiType, operationKey, npcId, uiState)
end

---@desc 玩家专用操作按键显隐
---@param uiType int 默认值:
---@param operationKey int 默认值:
---@param npcId int 默认值:
---@param uiState int 默认值:
---@return void 
function XDlcCSharpFuncs:SetPlayerOperationUiState(uiType, operationKey, npcId, uiState)
end

---@desc Npc专用操作按键显隐
---@param uiType int 默认值:
---@param operationKey int 默认值:
---@param npcId int 默认值:
---@param uiState int 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcOperationUiState(uiType, operationKey, npcId, uiState)
end

---@desc 关卡专用Ui显隐
---@param uiType int 默认值:
---@param npcId int 默认值:
---@param uiState int 默认值:
---@return void 
function XDlcCSharpFuncs:SetLevelUiState(uiType, npcId, uiState)
end

---@desc 怪物专用Ui显隐
---@param uiType int 默认值:
---@param npcId int 默认值:
---@param uiState int 默认值:
---@return void 
function XDlcCSharpFuncs:SetBossUiState(uiType, npcId, uiState)
end

---@desc 玩家专用Ui显隐
---@param uiType int 默认值:
---@param npcId int 默认值:
---@param uiState int 默认值:
---@return void 
function XDlcCSharpFuncs:SetPlayerUiState(uiType, npcId, uiState)
end

---@desc Npc专用操作按键显隐
---@param uiType int 默认值:
---@param npcId int 默认值:
---@param uiState int 默认值:
---@return void 
function XDlcCSharpFuncs:SetNpcUiState(uiType, npcId, uiState)
end

---@desc 在矩形区域内生成泊松盘采样点
---@param width float 默认值:
---@param height float 默认值:
---@param radius float 默认值:
---@return LuaTable 长度为2的倍数的LuaTable [x1, y1, x2, y2....]
function XDlcCSharpFuncs:PoissonDiscPoints(width, height, radius)
end

return XDlcCSharpFuncs;
