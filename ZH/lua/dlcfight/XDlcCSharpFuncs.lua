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
---@param win bool 是否胜利
---@return void 
function XDlcCSharpFuncs:SettleFight(win)
end

---@desc 单独结算某个玩家
---@param npcUUID int 玩家npc的UUID
---@param win bool 是否胜利
---@return void 
function XDlcCSharpFuncs:SettlePlayer(npcUUID, win)
end

---@desc 获取进入本场战斗的玩家数量
---@return int 玩家数量
function XDlcCSharpFuncs:GetPlayerCount()
end

---@desc 根据玩家NpcUUID获取玩家ID
---@param npcId int
---@return int 玩家ID
function XDlcCSharpFuncs:GetPlayerIdByNpc(npcId)
end

---@desc 获取战斗当前时间
---@return float 时间
function XDlcCSharpFuncs:GetFightTime()
end

---@desc 判断玩家是否离线
---@param npcUUID int
---@return bool 
function XDlcCSharpFuncs:CheckNpcIsDisconnect(npcUUID)
end

---@desc 设置战斗配置float
---@param key string
---@param value float
---@return void 
function XDlcCSharpFuncs:SetFloatConfig(key, value)
end

---@desc 添加定时器任务
---@param delayTimeSeconds float 延迟时间，单位：秒
---@param callback Action 回调函数
---@return int 计时器任务ID，成功时返回大于0的ID，失败时返回0
function XDlcCSharpFuncs:AddTimerTask(delayTimeSeconds, callback)
end

---@desc 移除定时器任务
---@param taskId int 计时器任务ID
---@return void 
function XDlcCSharpFuncs:RemoveTimerTask(taskId)
end

---@desc 获取NpcPlaceId, 不为零为LevelNpc
---@return int LevelNpc PlaceId
function XDlcCSharpFuncs:GetNpcPlaceId()
end

---@desc 获取Npc配置
---@param npcUUID int 可以留空,留空时根据proxy自动获取npc
---@return XTableNpc 单位属性表中的一行
function XDlcCSharpFuncs:GetNpcTemplate(npcUUID)
end

---@desc 注册事件
---@param eventType int  事件类型 C#XWorldEventManager.EWorldEvent LuaXDlcFightEnum.EWorldEvent 
---@return bool 返回是否监听成功
function XDlcCSharpFuncs:RegisterEvent(eventType)
end

---@desc 注销事件
---@param eventType int  事件类型 C#XWorldEventManager.EWorldEvent LuaXDlcFightEnum.EWorldEvent 
---@return void 
function XDlcCSharpFuncs:UnregisterEvent(eventType)
end

---@desc 注册Npc个人事件
---@param eventType int  事件类型 C#XWorldEventManager.EWorldEvent LuaXDlcFightEnum.EWorldEvent 
---@param targetUUID int Npc的UUID
---@return void 返回是否监听成功
function XDlcCSharpFuncs:RegisterEventByTarget(eventType, targetUUID)
end

---@desc 注销Npc个人事件
---@param eventType int  事件类型 C#XWorldEventManager.EWorldEvent LuaXDlcFightEnum.EWorldEvent 
---@param targetUUID int Npc的UUID
---@return void 
function XDlcCSharpFuncs:UnregisterEventByTarget(eventType, targetUUID)
end

---@desc 注册Lua玩法事件
---@param eventType int  事件类型 LuaXDlcFightLuaEvent.EFightLuaEvent 
---@return void 
function XDlcCSharpFuncs:RegisterLuaEvent(eventType)
end

---@desc 注销Lua玩法事件
---@param eventType int  事件类型 LuaXDlcFightLuaEvent.EFightLuaEvent 
---@return void 
function XDlcCSharpFuncs:UnregisterLuaEvent(eventType)
end

---@desc 广播Lua玩法事件
---@param targetType int  目标类型 1=Level 2=Npc, 4=Buff, 8=Skill, 14=NpcAllScript=Npc+Buff+Skill, 15=All=Level+Npc+Buff+Skill, 
---@param eventType int  事件类型 LuaXDlcFightLuaEvent.EFightLuaEvent 
---@param luaTable LuaTable  自定义事件参数 
---@return void 
function XDlcCSharpFuncs:DispatchLuaEvent(targetType, eventType, luaTable)
end

---@desc 将某个Actor的局部坐标转换为世界坐标
---@param uuid int
---@param point Vector3
---@return Vector3 
function XDlcCSharpFuncs:TransformPointByActor(uuid, point)
end

---@desc 将世界坐标转换为某个Actor的局部坐标
---@param uuid int
---@param point Vector3
---@return Vector3 
function XDlcCSharpFuncs:InverseTransformPointByActor(uuid, point)
end

---@desc 获取一定范围内的随机数(int)
---@param min int 随机范围下限
---@param max int 随机范围上限
---@return int 
function XDlcCSharpFuncs:Random(min, max)
end

---@desc 获取一定范围内的随机数(float)
---@param minInclude float 随机范围下限
---@param maxExclude float 随机范围上限
---@return float 
function XDlcCSharpFuncs:RandomFloat(minInclude, maxExclude)
end

---@desc 记录自定义结算数据
---@param playerId int 玩家ID（可通过GetPlayerIdByNpc提前获取）
---@param key int
---@param value int
---@return void 
function XDlcCSharpFuncs:SetFightResultCustomData(playerId, key, value)
end

---@desc 获取指定类型指定Id的关卡脚本对象
---@param scriptType EScriptType 脚本类型（参考EScriptType枚举）
---@param levelId int 关卡ID
---@return ILuaFightScript 
function XDlcCSharpFuncs:GetLevelScriptObject(scriptType, levelId)
end

---@desc 获取指定Actor的指定Id的脚本对象
---@param scriptType EScriptType 脚本类型（参考EScriptType枚举）
---@param actorId int Npc或SceneObject的UUID
---@param scriptId int 脚本ID（例如4001就是Q版露西亚）
---@return ILuaFightScript 
function XDlcCSharpFuncs:GetActorScriptObject(scriptType, actorId, scriptId)
end

---@desc 给Npc添加角色脚本
---@param npcUUID int npc对象UUID
---@param scriptId int 角色脚本Id
---@return void 
function XDlcCSharpFuncs:AddNpcCharScript(npcUUID, scriptId)
end

---@desc 给Npc移除角色脚本
---@param npcUUID int npc对象UUID
---@param scriptId int 角色脚本Id
---@return void 
function XDlcCSharpFuncs:RemoveNpcCharScript(npcUUID, scriptId)
end

---@desc 加载关卡NPC
---@param placeId int 关卡NPC的PlaceId
---@return bool true成功，false失败
function XDlcCSharpFuncs:LoadLevelNpc(placeId)
end

---@desc 通过PlaceId获取Npc的UUID
---@param placeId int
---@return int 
function XDlcCSharpFuncs:GetNpcUUID(placeId)
end

---@desc 生成Npc，并返回其对象Id。
---@param templateId int
---@param camp int
---@param position Vector3
---@param rotation Vector3
---@param skipBornState bool 默认值:false
---@return int 
function XDlcCSharpFuncs:GenerateNpc(templateId, camp, position, rotation, skipBornState)
end

---@desc 设置Npc显隐，会将角色控制器、角色碰撞一同显隐
---@param uuid int
---@param active bool
---@return void 
function XDlcCSharpFuncs:SetNpcActive(uuid, active)
end

---@desc 读取Npc的显隐状态
---@param uuid int
---@return bool 
function XDlcCSharpFuncs:GetNpcActive(uuid)
end

---@desc 移除Npc
---@param uuid int
---@return void 
function XDlcCSharpFuncs:DestroyNpc(uuid)
end

---@desc 延迟性移除 Npc
---@param uuid int
---@return void 
function XDlcCSharpFuncs:DestroyNpcDelay(uuid)
end

---@desc 卸载关卡NPC
---@param placeId int 关卡NPC的PlaceId
---@return void 
function XDlcCSharpFuncs:UnloadLevelNpc(placeId)
end

---@desc 使Npc死亡
---@param npcId int
---@param magicId int
---@return void 
function XDlcCSharpFuncs:NpcDie(npcId, magicId)
end

---@desc 使Npc开始移动并看向lookPosition
---@param npcId int
---@param lookPosition Vector3
---@return void 
function XDlcCSharpFuncs:NpcStartMove(npcId, lookPosition)
end

---@desc 使Npc开始移动并看向lookPosition
---@param npcUUID int
---@param destination Vector3
---@param moveType ENpcMoveType
---@return void 
function XDlcCSharpFuncs:NpcMoveTo(npcUUID, destination, moveType)
end

---@desc 使Npc开始沿着给定的路线移动
---@param npcUUID int
---@param routeId int
---@param moveType ENpcMoveType
---@return void 
function XDlcCSharpFuncs:NpcMoveByRoute(npcUUID, routeId, moveType)
end

---@desc 使Npc停止移动
---@param npcId int
---@return void 
function XDlcCSharpFuncs:NpcStopMove(npcId)
end

---@desc 【注意】要求存在寻路数据配置，
---@desc 文档:https://kurogame.feishu.cn/docx/JHIfd7qInosGvpxkgvwcDa0UnGc
---@desc 令Npc寻路到达某处
---@param npcUUID int 要寻路的NpcId
---@param position Vector3 目标地点
---@param moveType int 默认值:1 npc的移动方式(走、跑、疾跑)
---@return void 
function XDlcCSharpFuncs:NpcNavigateTo(npcUUID, position, moveType)
end

---@desc 禁止频繁调用（会发送同步消息
---@desc 设置Npc坐标
---@param npcId int
---@param position Vector3
---@param resetNpcState bool 默认值:false
---@return void 
function XDlcCSharpFuncs:SetNpcPosition(npcId, position, resetNpcState)
end

---@desc 禁止频繁调用（会发送同步消息
---@desc 设置Npc朝向（rotation为各轴旋转角度
---@param npcId int
---@param rotation Vector3
---@return void 
function XDlcCSharpFuncs:SetNpcRotation(npcId, rotation)
end

---@desc 禁止频繁调用（会发送同步消息
---@desc 设置Npc坐标与朝向
---@desc rotation：各轴的旋转角度（单位：°，非弧度）
---@desc resetNpcState：是否重置Npc状态为待机状态
---@param npcId int
---@param position Vector3
---@param rotation Vector3
---@param resetNpcState bool 默认值:false
---@return void 
function XDlcCSharpFuncs:SetNpcPosAndRot(npcId, position, rotation, resetNpcState)
end

---@desc 设置Npc移动方向
---@param npcId int
---@param direction int 参考枚举ENpcMoveDirection
---@return void 
function XDlcCSharpFuncs:SetNpcMoveDirection(npcId, direction)
end

---@desc 设置Npc移动类型
---@param npcId int
---@param type int 参考枚举ENpcMoveType
---@return void 
function XDlcCSharpFuncs:SetNpcMoveType(npcId, type)
end

---@desc 获取Npc移动类型
---@param npcId int
---@return int 参考枚举ENpcMoveType
function XDlcCSharpFuncs:GetNpcMoveType(npcId)
end

---@desc Npc是否正在移动
---@param npcUUID int
---@return bool 
function XDlcCSharpFuncs:IsNpcMoving(npcUUID)
end

---@desc 设置Npc看向坐标
---@param npcId int
---@param position Vector3
---@return void 
function XDlcCSharpFuncs:SetNpcFaceToPosition(npcId, position)
end

---@desc 设置Npc看向索敌/锁定目标
---@param npcId int 要设置的npcUUID
---@param searchTargetUID long 索敌/锁定目标UID
---@return void 
function XDlcCSharpFuncs:SetNpcFaceToSearchTarget(npcId, searchTargetUID)
end

---@desc 设置Npc看向目标。Npc会逐渐转向目标，直至角度差小于1度时停止。
---@desc 转向速度由IdleSpinningSpeed、RunSpinningSpeed等属性控制。
---@desc 如果控制的是玩家角色，则在此期间玩家角色不会使用摇杆输入的移动方向。
---@param npcId int
---@param targetNpcId int
---@return void 
function XDlcCSharpFuncs:SetNpcFaceToNpc(npcId, targetNpcId)
end

---@desc 设置玩家Npc相机锁定目标
---@param npcId int 玩家NpcUUID
---@param targetId int 目标UUID
---@return bool 
function XDlcCSharpFuncs:SetNpcFocusTarget(npcId, targetId)
end

---@desc 移除玩家Npc相机锁定目标
---@param npcId int 玩家NpcUUID
---@return void 
function XDlcCSharpFuncs:RemoveNpcFocusTarget(npcId)
end

---@desc 获取玩家Npc相机锁定目标UUID
---@param npcId int 玩家NpcUUID
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
---@param npcId int
---@return bool 
function XDlcCSharpFuncs:CheckNpc(npcId)
end

---@desc 检查Npc动作状态机是否处于action
---@param npcId int
---@param action int
---@return bool 
function XDlcCSharpFuncs:CheckNpcAction(npcId, action)
end

---@desc 检查Npc能否释放动作
---@desc --C#该接口判断了
---@desc --1 Npc是否死亡
---@desc --2 Npc是否拥有 Npc状态:无法释放动作
---@desc --3 Npc是否在受击
---@desc --4 空中组件判断是否能在空中放动作
---@param npcId int
---@return bool Bool:能否释放动作
function XDlcCSharpFuncs:CheckCanCastSkill(npcId)
end

---@desc 检查Npc动作Condition是否满足 (Condition表格)
---@desc 表格位置："Share\StatusSyncFight\Skill\Condition"
---@param npcId int
---@param actionId int 要判断的动作Id
---@return bool Bool:是否满足
function XDlcCSharpFuncs:CheckNpcActionCondition(npcId, actionId)
end

---@desc 检查下一个动作是否能打断当前动作
---@desc 1 若当前没有在播放的动作，则返回True。
---@desc 2 先判断打断优先级，若优先级高于当前动作，返回True。
---@desc 3 再判断时间轴，若处于打断时间内，返回True。(填写了TimingID则以时间轴做判断，否则用当前动作的CastTime做通用后摇区间判断)
---@param npcId int
---@param nextActionId int
---@param timingId int 默认值:0
---@return bool Bool:能否打断
function XDlcCSharpFuncs:CheckNpcCanAbortCurrentAction(npcId, nextActionId, timingId)
end

---@desc 根据 ReplaceParams 检查下一个技能是否能打断当前技能
---@param npcUUID int
---@param nextSkillId int
---@return bool Bool:能否打断
function XDlcCSharpFuncs:CheckNpcCanAbortCurrentSkill(npcUUID, nextSkillId)
end

---@desc 检查Npc当前技能已经释放完或到后摇阶段（当前没有正在释放技能也算完成)
---@param npcId int 要检查的NpcUUID
---@return bool 
function XDlcCSharpFuncs:CheckNpcCurActionIsDone(npcId)
end

---@desc 检测Npc与目标距离是否在指定值内
---@param npc int
---@param target int
---@param distance float
---@return bool 
function XDlcCSharpFuncs:CheckNpcDistance(npc, target, distance)
end

---@desc 检测Npc与目标坐标是否在指定值内
---@param npc int
---@param targetPosX float
---@param targetPosY float
---@param targetPosZ float
---@param distance float
---@return bool 
function XDlcCSharpFuncs:CheckNpcDistanceWithPos(npc, targetPosX, targetPosY, targetPosZ, distance)
end

---@desc 计算Npc与目标坐标的距离
---@param npc int
---@param target int
---@return float 
function XDlcCSharpFuncs:CalcNpcDistance(npc, target)
end

---@desc 计算Npc与目标的距离
---@param npc int
---@param targetPosX float
---@param targetPosY float
---@param targetPosZ float
---@return float 
function XDlcCSharpFuncs:CalcNpcDistanceWitchPos(npc, targetPosX, targetPosY, targetPosZ)
end

---@desc 检测pos和Npc的连线与Npc朝向的夹角是否在给定的angle角度内，angle单位为度。
---@param npcUUID int 指定NpcUUID
---@param pos Vector3 目标位置
---@param angle float 角度限制
---@return bool 
function XDlcCSharpFuncs:CheckNpcToPosInAngle(npcUUID, pos, angle)
end

---@desc 检测target和Npc的连线与Npc朝向的夹角是否在给定的angle角度内，angle单位为度。
---@param npc int
---@param target int
---@param angle float
---@return bool 
function XDlcCSharpFuncs:CheckNpcInAngle(npc, target, angle)
end

---@desc 检测target和Npc的连线与Npc朝向的夹角是否在from和to的角度范围内，from和to单位为度。
---@param npc int 主体角色UUID
---@param target int 目标角色UUID
---@param from float 区间起始角度
---@param to float 区间结束角度，不能小于from
---@return bool 是否在from和to构成的角度区间内
function XDlcCSharpFuncs:CheckNpcInAngleRangeHorizontal(npc, target, from, to)
end

---@desc 检测Npc是否在空中
---@param npcId int
---@return bool 
function XDlcCSharpFuncs:CheckNpcOnAir(npcId)
end

---@desc 获取Npc坐标
---@param npcId int
---@return Vector3 
function XDlcCSharpFuncs:GetNpcPosition(npcId)
end

---@desc 获取Npc朝向（返回各轴角度
---@param npcId int
---@return Vector3 
function XDlcCSharpFuncs:GetNpcRotation(npcId)
end

---@desc attrib参考枚举ENpcAttrib
---@param npcId int
---@param attrib int
---@return float 
function XDlcCSharpFuncs:GetNpcAttribRate(npcId, attrib)
end

---@desc 设置 Npc 装备隐藏
---@param npcUUID int
---@param equipUUID int
---@param isHide bool
---@return void 
function XDlcCSharpFuncs:SetNpcEquipHide(npcUUID, equipUUID, isHide)
end

---@desc 获取 Npc 装备 UUID
---@param npcUUID int
---@param equipType int
---@param equipIndex int
---@return int 
function XDlcCSharpFuncs:GetNpcEquipUUID(npcUUID, equipType, equipIndex)
end

---@desc 获取Npc阵营（返回值参考ENpcCamp
---@param npcId int
---@return int 
function XDlcCSharpFuncs:GetNpcCamp(npcId)
end

---@desc 设置Npc阵营
---@param npcId int
---@param camp ENpcCampType 目标阵营
---@return void 
function XDlcCSharpFuncs:SetNpcCamp(npcId, camp)
end

---@desc 比较两个Npc的阵营是否相同
---@param npcA int
---@param npcB int
---@return bool 
function XDlcCSharpFuncs:CompareNpcCamp(npcA, npcB)
end

---@desc 返回值参考枚举ENpcKind
---@param npc int
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
---@param npcId int
---@return bool 
function XDlcCSharpFuncs:IsPlayerNpc(npcId)
end

---@desc NPC是否死亡
---@param uuid int
---@return bool 
function XDlcCSharpFuncs:IsNpcDead(uuid)
end

---@desc 判断Actor是否还存在
---@param uuid int
---@return bool 
function XDlcCSharpFuncs:CheckActorExist(uuid)
end

---@desc 复活Npc
---@param launcherId int
---@param targetId int
---@return void 
function XDlcCSharpFuncs:RebornNpc(launcherId, targetId)
end

---@desc 执行Magic
---@param launcherNpcUUID int
---@param targetNpcUUID int
---@param magicId int
---@param level int
---@param contextId int
---@param count int
---@return void 
function XDlcCSharpFuncs:ApplyMagic(launcherNpcUUID, targetNpcUUID, magicId, level, contextId, count)
end

---@desc Npc给自己添加Buff
---@param npcId int NpcUUID
---@param buffId int Buff的配置Id
---@return void 
function XDlcCSharpFuncs:AddBuff(npcId, buffId)
end

---@desc Npc根据类型移除全部Buff
---@param npcId int NpcUUID
---@param kind int Buff的KindId
---@return void 
function XDlcCSharpFuncs:RemoveBuff(npcId, kind)
end

---@desc Npc根据类型和数量移除Buff
---@param npcUUID int NpcUUID
---@param buffKind int Buff的KindId
---@param count int 移除的数量
---@return void 
function XDlcCSharpFuncs:RemoveBuffByKindAndCount(npcUUID, buffKind, count)
end

---@desc 检查Npc是否有指定buff
---@param npcId int
---@param kind int
---@return bool 
function XDlcCSharpFuncs:CheckBuffByKind(npcId, kind)
end

---@desc 查询Buff等级
---@param npcUUID int 要查询的npcUUID
---@param buffTemplateId int buff配置Id
---@return bool 是否成功返回, int level:第二返回值等级
function XDlcCSharpFuncs:TryQueryBuffLevel(npcUUID, buffTemplateId)
end

---@desc 重置Npc到安全点（系统自动计算的安全点
---@param npcId int
---@return void 
function XDlcCSharpFuncs:ResetNpcToSafePoint(npcId)
end

---@desc 重置Npc到已记录的检查点（自动选择检查点配置点位之一
---@param npcId int
---@return void 
function XDlcCSharpFuncs:ResetNpcToCheckPoint(npcId)
end

---@desc 重置Npc到指定检查点（自动选择检查点配置点位之一
---@param npcId int
---@param checkPointPlaceId int
---@return void 
function XDlcCSharpFuncs:ResetNpcToSpecificCheckPoint(npcId, checkPointPlaceId)
end

---@desc 设置Npc的检查点（本质是设置重生坐标
---@param npcId int
---@param checkPointPlaceId int
---@return void 
function XDlcCSharpFuncs:SetNpcCheckPoint(npcId, checkPointPlaceId)
end

---@desc 获取Npc记录的检查点
---@param npcId int
---@return void , float x:, float y:, float z:
function XDlcCSharpFuncs:GetNpcLastCheckPoint(npcId)
end

---@desc 添加技能球
---@param npcId int 目标NPC的UUID
---@param key int 三色球的ID
---@param count int 要添加的数量
---@return void 
function XDlcCSharpFuncs:AddSkillBall(npcId, key, count)
end

---@desc 清除所有技能球
---@param npcId int 目标Npc的UUID
---@return int 清除的球数量
function XDlcCSharpFuncs:ClearAllSkillBalls(npcId)
end

---@desc 获取所有球的类型列表
---@param npcId int 目标Npc的UUID
---@return LuaTable int数组Table，包含了每个球的类型
function XDlcCSharpFuncs:GetBallKindsList(npcId)
end

---@desc 获取Npc技能球数量
---@param npcId int
---@param countBackend bool 是否将后台球也计算在内
---@return int 
function XDlcCSharpFuncs:GetSkillBallCount(npcId, countBackend)
end

---@desc 设置玩家交互时是否可以转身面向交互目标
---@param enable bool 是否允许
---@return void 
function XDlcCSharpFuncs:SetPlayerInteractTurnEnable(enable)
end

---@desc 设置Npc重力
---@param uuid int Npc对象的UUID
---@param jumpGravity float 跳跃重力
---@param freeFallGravity float 自由落体重力
---@return void 
function XDlcCSharpFuncs:SetNpcGravity(uuid, jumpGravity, freeFallGravity)
end

---@desc 移动Npc（暂定）
---@param uuid int Npc对象的UUID
---@param vector Vector3 移动向量
---@return bool 是否未受阻挡地移动（true表示没有受到阻挡）
function XDlcCSharpFuncs:MoveNpc(uuid, vector)
end

---@desc 转向Npc
---@param npcUUID1 int 要转向的Npc对象的UUID
---@param npcUUID2 int 要朝向的Npc对象的UUID
---@param animName string 默认值:null 朝向后要播的动画
---@param onlyOnceAnim bool 默认值:false 非三段式动画
---@return void 
function XDlcCSharpFuncs:TurnNpc(npcUUID1, npcUUID2, animName, onlyOnceAnim)
end

---@desc 转向SceneObj
---@param npcUUID int 要转向的Npc对象的UUID
---@param sceneObjectUUID int 要朝向的SceneObj对象的UUID
---@param animName string 默认值:null 朝向后要播的动画
---@param onlyOnceAnim bool 默认值:false 非三段式动画
---@return void 
function XDlcCSharpFuncs:TurnSceneObject(npcUUID, sceneObjectUUID, animName, onlyOnceAnim)
end

---@desc 转向坐标
---@param npcUUID int 要转向的Npc对象的UUID
---@param pos Vector3 朝向坐标
---@param animName string 默认值:null 朝向后要播的动画
---@param onlyOnceAnim bool 默认值:false 非三段式动画
---@return void 
function XDlcCSharpFuncs:TurnPos(npcUUID, pos, animName, onlyOnceAnim)
end

---@desc 按角度转向
---@param npcUUID int 要转向的Npc对象的UUID
---@param angle float 要旋转的角度
---@param animName string 默认值:null 朝向后要播的动画
---@param onlyOnceAnim bool 默认值:false 非三段式动画
---@return void 
function XDlcCSharpFuncs:TurnAngle(npcUUID, angle, animName, onlyOnceAnim)
end

---@desc Npc 的水平方向上的角度差是否抵达视线角度最大值
---@param fstNpcUUID int
---@param sndNpcUUID int
---@return bool 
function XDlcCSharpFuncs:IsNpcAngleReachMaxLookAtAngleOnHorizontal(fstNpcUUID, sndNpcUUID)
end

---@desc 向目标 Npc 位置旋转一次
---@param fstNpcUUID int 要转向的Npc对象的UUID
---@param sndNpcUUID int 要朝向的Npc对象的UUID
---@return void 
function XDlcCSharpFuncs:TurnNpcOnce(fstNpcUUID, sndNpcUUID)
end

---@desc 开启注视
---@param fstNpcUUID int 要注视其它人的Npc对象的UUID
---@param sndNpcUUID int 被注视的Npc对象的UUID
---@param targetBoneName string 默认值:"LookAtNode" 目标骨骼名称
---@return void 
function XDlcCSharpFuncs:EnableNpcLookAt(fstNpcUUID, sndNpcUUID, targetBoneName)
end

---@desc 关闭注视
---@param fstNpcUUID int 要注视其它人的Npc对象的UUID
---@return void 
function XDlcCSharpFuncs:DisableNpcLookAt(fstNpcUUID)
end

---@desc 设置Npc忽略其他Npc的所有碰撞
---@desc 已包含同步和断线重连逻辑
---@param uuid int 设置的目标NpcUUID
---@param ignore bool true忽略，false取消忽略
---@return void 
function XDlcCSharpFuncs:SetNpcIgnoreOtherNpcAllCollisions(uuid, ignore)
end

---@desc 检查Npc完整状态
---@desc 子状态填写-1 或 者当前主状态没有子状态时 子状态参数无效
---@desc 子状态ID请查阅“g工具表“的”NPC状态类型”子表
---@param uuid int
---@param mainState int 主状态0待机1移动2跳跃3技能4受击5濒死6出生7死亡8被抓9瘫痪10乘骑
---@param subState int 子状态
---@return bool Npc状态和参数一致则返回true
function XDlcCSharpFuncs:CheckNpcFullActionState(uuid, mainState, subState)
end

---@desc 判断Npc的受击状态
---@param uuid int Npc对象的UUID
---@param state int 受击状态枚举，详见EHitType
---@return bool 
function XDlcCSharpFuncs:CheckNpcBeHitState(uuid, state)
end

---@desc 判断Npc是否处于后台
---@param uuid int
---@return bool 
function XDlcCSharpFuncs:IsNpcBackState(uuid)
end

---@desc 切换玩家Npc
---@param uuid int 当前玩家NpcUuid
---@param operationKey int 切换的按键，参考ENpcOperationKey.SwitchNpc1
---@return void 
function XDlcCSharpFuncs:SwitchPlayerNpc(uuid, operationKey)
end

---@desc 本地控制角色跳跃
---@desc TODO 目前仅用于本地控制角色使用, 待优化
---@param uuid int Npc对象的UUID
---@param isMoving bool 是否为跑跳
---@return void 
function XDlcCSharpFuncs:Jump(uuid, isMoving)
end

---@desc 判断Npc的跳跃状态
---@param uuid int Npc对象的UUID
---@param state int 跳跃状态枚举，详见ENpcJumpState
---@return bool 
function XDlcCSharpFuncs:CheckNpcJumpState(uuid, state)
end

---@desc 请找程序 ，没注释
---@param uuid int
---@param speed float
---@return void 
function XDlcCSharpFuncs:SetNpcJumpLookAtSpeed(uuid, speed)
end

---@desc 用于传送后设置Npc为在地面(防止空中状态动量残留)
---@param uuid int
---@return void 
function XDlcCSharpFuncs:TeleportResetNpcOnGround(uuid)
end

---@desc 带黑幕传送NPC(仅客户端使用)
---@param npcId int NpcUUID
---@param position Vector3 目标地点
---@param rotation Vector3 传送后朝向
---@param cb Action 传送后回调
---@return void 
function XDlcCSharpFuncs:TeleportWithBlackUi(npcId, position, rotation, cb)
end

---@desc 设置Npc动画控制器层
---@param uuid int npc对象的UUID
---@param layerIndex int 动画层级
---@return void 
function XDlcCSharpFuncs:SetNpcAnimationLayer(uuid, layerIndex)
end

---@desc 设置Actor是否可交互，目前支持NPC和SceneObject
---@param uuid int Actor对象的UUID
---@param enable bool 是否可交互
---@return void 
function XDlcCSharpFuncs:SetActorInteractableComponentEnable(uuid, enable)
end

---@desc 通过PlaceId设置Actor是否可交互，目前支持NPC和SceneObject
---@param actorType int Actor对象类型枚举，参考ETargetActorType
---@param placeId int Actor对象的PlaceId
---@param enable bool 是否可交互
---@return void 
function XDlcCSharpFuncs:SetActorInteractableComponentEnableByPlaceId(actorType, placeId, enable)
end

---@desc Actor是否可交互，目前支持NPC和SceneObject
---@param actorType int Actor对象类型枚举，参考ETargetActorType
---@param placeId int Actor对象的PlaceId
---@return bool 
function XDlcCSharpFuncs:IsActorInteractableComponentByPlaceId(actorType, placeId)
end

---@desc 设置Npc FightTarget
---@param uuid int 要锁定npc的npc对象Uuid
---@param targetUuid int 被锁定的npc对象UUid
---@return void 
function XDlcCSharpFuncs:SetFightTarget(uuid, targetUuid)
end

---@desc 获取Npc的 FightTarget的 uuid
---@param uuid int Npc对象的UUID
---@return int FightTarget的UUID
function XDlcCSharpFuncs:GetFightTargetId(uuid)
end

---@desc 检查Npc是否存在FightTarget
---@param uuid int Npc对象的UUID
---@return bool 存在返回true
function XDlcCSharpFuncs:CheckFightTarget(uuid)
end

---@desc 移出Npc的FightTarget
---@param uuid int Npc对象的UUID
---@return void 
function XDlcCSharpFuncs:RemoveFightTarget(uuid)
end

---@desc 获取相对于Npc的偏移坐标位置
---@param uuid int Npc对象的UUID
---@param position Vector3 计算方向的位置坐标
---@param euler Vector3 偏移的角度
---@param distance float 偏移的长度
---@return Vector3 最终偏移的世界坐标
function XDlcCSharpFuncs:GetNpcOffsetPosition(uuid, position, euler, distance)
end

---@desc 获取Npc朝向目标位置世界坐标系的旋转
---@param uuid int Npc对象的UUID
---@param position Vector3 计算方向的位置坐标
---@param eulerOffset Vector3 偏移的角度
---@param isOnlyY bool 是否只是Y轴旋转
---@return Vector3 世界坐标下旋转的欧拉角
function XDlcCSharpFuncs:GetNpcOffsetRotation(uuid, position, eulerOffset, isOnlyY)
end

---@desc 获取相对于Npc的偏移向量（忽略npc自身旋转）
---@param uuid int Npc对象的UUID
---@param position Vector3 偏移的位置坐标
---@param euler Vector3 偏移的角度
---@param distance float 偏移的长度
---@return Vector3 最终偏移向量
function XDlcCSharpFuncs:GetNpcOffset(uuid, position, euler, distance)
end

---@desc 获取相对于Npc朝向的偏移坐标
---@param uuid int Npc对象的UUID
---@param euler Vector3 偏移的角度
---@param distance float 偏移的长度
---@return Vector3 最终偏移的世界坐标
function XDlcCSharpFuncs:GetNpcOffsetPositionByFacing(uuid, euler, distance)
end

---@desc 获得世界坐标系中的点在目标角色本地坐标系中的本地坐标
---@param pointInWorldSpace Vector3 世界坐标系中的点
---@param targetNpcUUID int 目标Npc的UUID
---@return Vector3 
function XDlcCSharpFuncs:GetLocalPosInNpcLocalSpace(pointInWorldSpace, targetNpcUUID)
end

---@desc 移动Npc到指定位置
---@param uuid int Npc对象的UUID
---@param position Vector3 移动到的位置
---@return void 
function XDlcCSharpFuncs:MoveToPosition(uuid, position)
end

---@desc Npc朝向指定位置
---@param uuid int Npc对象的UUID
---@param position Vector3 朝向的位置
---@return void 
function XDlcCSharpFuncs:LookAtPositionImmediately(uuid, position)
end

---@desc 获取与目标的距离
---@param uuid int Npc对象的UUID
---@param targetUuid int 目标对象的UUID
---@param ignoreY bool 是否忽略Y轴
---@return float 距离
function XDlcCSharpFuncs:GetNpcDistance(uuid, targetUuid, ignoreY)
end

---@desc 获取Npc的时间
---@param uuid int Npc对象的UUID
---@return float 
function XDlcCSharpFuncs:GetNpcTime(uuid)
end

---@desc 检查Npc的时间是否大于指定时间加上额外时间的总和
---@param uuid int Npc对象的UUID
---@param time float 时间
---@param extraTime float 额外时间
---@return bool 
function XDlcCSharpFuncs:CheckNpcTime(uuid, time, extraTime)
end

---@desc 设置Npc输入行为组
---@param uuid int Npc对象的UUID
---@param id int 输入行为组Id
---@return bool 是否设置成功
function XDlcCSharpFuncs:SetNpcInputActionGroup(uuid, id)
end

---@desc 添加连线特效
---@param launcherNpcUUID int 释放者UUID
---@param fromUUID int 被连接的ActorA的UUID
---@param toUUID int 被连接的ActorB的UUID
---@param fromJoint string ActorA被连接的部位
---@param toJoint string ActorB被连接的部位
---@param effectName string 特效名
---@param updateAlways bool 是否一直更新(否则隐藏不更新)
---@return int 返回链接的Id
function XDlcCSharpFuncs:AddLink(launcherNpcUUID, fromUUID, toUUID, fromJoint, toJoint, effectName, updateAlways)
end

---@desc 根据位置添加连线特效
---@param from Vector3 链接的起始位置
---@param to Vector3 链接的终点位置
---@param effectName string 特效名
---@param launcherNpcUUID int 释放者UUID
---@param updateAlways bool 是否一直更新(否则隐藏不更新)
---@return int 返回链接的Id
function XDlcCSharpFuncs:AddPosLink(from, to, effectName, launcherNpcUUID, updateAlways)
end

---@desc 检查连线特效是否存在
---@param linkId int 连接的Id
---@return bool 是否存在该链接
function XDlcCSharpFuncs:CheckLink(linkId)
end

---@desc 查询连线特效的ActorA和B的UUID
---@param linkId int 连接的Id
---@return int ActorA的Id, int actorBUUID:ActorB的Id
function XDlcCSharpFuncs:QueryLinkActor(linkId)
end

---@desc 移除指定的连线特效
---@param launcherNpcUUID int 施放者的UUID
---@param linkId int 链接的Id
---@return void 
function XDlcCSharpFuncs:RemoveLink(launcherNpcUUID, linkId)
end

---@desc 移除指定Actor的所有连线特效
---@param launcherNpcUUID int 施放者的UUID
---@param actorUUID int Actor的UUID
---@return void 
function XDlcCSharpFuncs:RemoveAllActorLink(launcherNpcUUID, actorUUID)
end

---@desc 移除指定Npc创造的所有PosLink
---@param launcherNpcUUID int 施放者的UUID
---@return void 
function XDlcCSharpFuncs:RemoveAllNpcPosLink(launcherNpcUUID)
end

---@desc 获取Npc的属性值
---@param uuid int Npc的UUID
---@param attribType ENpcAttrib Npc属性类型枚举
---@return int 
function XDlcCSharpFuncs:GetNpcAttribValue(uuid, attribType)
end

---@desc 获取Npc的属性最大值
---@param uuid int Npc的UUID
---@param attribType ENpcAttrib Npc属性类型枚举
---@return int 
function XDlcCSharpFuncs:GetNpcAttribMaxValue(uuid, attribType)
end

---@desc 增加Npc属性的加成值
---@param uuid int npcid
---@param attribType ENpcAttrib 属性类型
---@param value int 基础值
---@param percent int 万分比加成
---@return void 
function XDlcCSharpFuncs:AddNpcAttribAdditive(uuid, attribType, value, percent)
end

---@desc 检查Npc与位置的距离是否小于指定距离
---@param uuid int Npc的UUID
---@param position Vector3 指定位置
---@param distance float 指定距离
---@param ignoreY bool 是否忽略Y轴
---@return bool 
function XDlcCSharpFuncs:CheckNpcPositionDistance(uuid, position, distance, ignoreY)
end

---@desc 获取Npc与位置的距离
---@param uuid int Npc的UUID
---@param position Vector3 指定位置
---@param ignoreY bool 是否忽略Y轴
---@return float 
function XDlcCSharpFuncs:GetNpcToPositionDistance(uuid, position, ignoreY)
end

---@desc 3.6自走棋造成伤害（仅单机使用）
---@param launcherNpcUUID int 施放者NpcUUID
---@param targetNpcUUID int 目标NpcUUID
---@param partId int 受击部位Id
---@param magicId int MagicId
---@param kind int 伤害类型(由策划配表定义）
---@param permyriad int 伤害万分比
---@param elementType int 元素类型
---@param hackValue int 骇破伤害
---@param hackPermyriad int 骇破伤害万分比
---@param skillCap int 技能伤害上限
---@return void 
function XDlcCSharpFuncs:DamageRelinkStandalone(launcherNpcUUID, targetNpcUUID, partId, magicId, kind, permyriad, elementType, hackValue, hackPermyriad, skillCap)
end

---@desc 3.6自走棋造成治疗（仅单机使用）
---@param launcherNpcUUID int 施放者NpcUUID
---@param targetNpcUUID int 目标NpcUUID
---@param magicId int MagicId
---@param attribType int 属性类型
---@param type int 治疗类型
---@param value int 治疗量
---@param permyriad int 技能恢复倍率万分比
---@param useTargetAttrib bool 是否使用目标属性
---@param useHealAmpP bool 使用恢复强度
---@return void 
function XDlcCSharpFuncs:CureRelinkStandalone(launcherNpcUUID, targetNpcUUID, magicId, attribType, type, value, permyriad, useTargetAttrib, useHealAmpP)
end

---@desc 获取Npc护盾总值
---@param uuid int
---@return int 
function XDlcCSharpFuncs:GetNpcProtector(uuid)
end

---@desc 根据类型获取Npc护盾值
---@param uuid int
---@param type int 护盾类型
---@return int 
function XDlcCSharpFuncs:GetNpcProtectorByType(uuid, type)
end

---@desc 添加护盾 (Buff脚本限定)
---@param value int 值
---@param type EDamageType 护盾类型
---@param priority int 优先级
---@return void 
function XDlcCSharpFuncs:AddProtector(value, type, priority)
end

---@desc 移除护盾 (Buff脚本限定)
---@return void 
function XDlcCSharpFuncs:RemoveProtector()
end

---@desc 检测基于Npc计算出的射线是否命中静态碰撞体（地形 & 场景物体 & 关卡障碍）
---@param npcUUID int NPC的UUID
---@param posOffset Vector3 射线原点基于NPC位置的偏移
---@param rotOffset Vector3 射线方向基于NPC朝向的旋转偏移
---@param distance float 射线长度
---@return bool 是否命中碰撞体, Vector3 hitPos:(第二个返回值)命中的障碍位置
function XDlcCSharpFuncs:CheckNpcRayCastStaticCollider(npcUUID, posOffset, rotOffset, distance)
end

---@desc 检测基于Npc计算出的射线是否命中关卡障碍
---@param npcUUID int NPC的UUID
---@param posOffset Vector3 射线原点基于NPC位置的偏移
---@param rotOffset Vector3 射线方向基于NPC朝向的旋转偏移
---@param distance float 射线长度
---@return bool 是否命中障碍, Vector3 hitPos:(第二个返回值)命中的障碍位置
function XDlcCSharpFuncs:CheckNpcRayCastObstacle(npcUUID, posOffset, rotOffset, distance)
end

---@desc 检测基于Npc计算出的球体是否碰撞到关卡障碍
---@param npcUUID int NPC的UUID
---@param posOffset Vector3 计算球体最终位置的射线原点基于NPC位置的偏移
---@param rotOffset Vector3 计算球体最终位置的射线方向基于NPC朝向的旋转偏移
---@param distance float 计算球体最终位置的射线长度
---@param radius float 球体半径
---@return bool 是否碰撞到关卡障碍
function XDlcCSharpFuncs:CheckNpcSphereObstacle(npcUUID, posOffset, rotOffset, distance, radius)
end

---@desc 检测世界坐标系下的射线是否命中关卡障碍
---@param npcUUID int NPC的UUID
---@param pos Vector3 射线原点世界坐标系位置
---@param rot Vector3 射线世界坐标系旋转
---@param distance float 射线距离
---@return bool 是否命中障碍, Vector3 hitPos:(第二个返回值)命中的障碍位置
function XDlcCSharpFuncs:CheckRayCastObstacle(npcUUID, pos, rot, distance)
end

---@desc 检测世界坐标系下的球体是否碰撞到关卡障碍
---@param npcUUID int NPC的UUID
---@param pos Vector3 球体世界坐标系位置
---@param radius float 球体半径
---@return bool 球体是否碰到障碍
function XDlcCSharpFuncs:CheckSphereObstacle(npcUUID, pos, radius)
end

---@desc 获取Npc最大仇恨的目标NPC的UUID
---@param uuid int 当前Npc的UUID
---@return int 最大仇恨的NpcUUID（返回0没有）
function XDlcCSharpFuncs:GetMaxThreatNpc(uuid)
end

---@desc 获取Npc最小仇恨的目标NPC的UUID
---@param uuid int 当前Npc的UUID
---@return int 最小仇恨的NpcUUID（返回0没有）
function XDlcCSharpFuncs:GetMinThreatNpc(uuid)
end

---@desc 检查Npc仇恨列表是否为空（不为空返回true）
---@param uuid int 当前Npc的UUID
---@return bool 
function XDlcCSharpFuncs:CheckThreatList(uuid)
end

---@desc 检查Npc仇恨值列表是否为空（不为空返回true）
---@param uuid int 当前Npc的UUID
---@return bool 
function XDlcCSharpFuncs:CheckThreatValueList(uuid)
end

---@desc 检查Npc强仇恨列表是否为空（不为空返回true）
---@param uuid int 当前Npc的UUID
---@return bool 
function XDlcCSharpFuncs:CheckForceThreatList(uuid)
end

---@desc 检查目标Npc是否在当前Npc的仇恨列表中
---@param uuid int 当前Npc的UUID
---@param targetUUID int 目标Npc的UUID
---@return bool 
function XDlcCSharpFuncs:CheckNpcInThreatList(uuid, targetUUID)
end

---@desc 获取当前Npc对目标NPC的仇恨值
---@desc 如果目标不在仇恨列表返回 0
---@param uuid int 当前Npc的UUID
---@param targetUUID int 目标Npc的UUID
---@return int 
function XDlcCSharpFuncs:GetThreatValue(uuid, targetUUID)
end

---@desc 检查目标Npc是不是最高仇恨目标
---@param uuid int 要检查的NpcUUID
---@param targetUUID int 目标NpcUUID
---@return bool 
function XDlcCSharpFuncs:CheckNpcIsIsFirstThreat(uuid, targetUUID)
end

---@desc 获取最高仇恨值的Npc
---@param uuid int 要查询的NpcUUID
---@return int 最高仇恨值的Npc的UUID
function XDlcCSharpFuncs:GetMaxThreatValueNpc(uuid)
end

---@desc 获取最低仇恨值的Npc
---@param uuid int 要查询的NpcUUID
---@return int 最低仇恨值的Npc的UUID
function XDlcCSharpFuncs:GetMinThreatValueNpc(uuid)
end

---@desc 添加仇恨值
---@param uuid int 要添加仇恨的NpcUUID
---@param targetUUID int 目标的Npc的UUID
---@param ratioValue int 仇恨值比例
---@param value int 仇恨值
---@return void 
function XDlcCSharpFuncs:AddThreat(uuid, targetUUID, ratioValue, value)
end

---@desc 设置目标Npc为最高仇恨值Npc
---@param uuid int Npc的UUID
---@param targetNpcUUID int 目标NpcUUID
---@return void 
function XDlcCSharpFuncs:SetMaxThreatValueNpc(uuid, targetNpcUUID)
end

---@desc 检查目标Npc是否在仇恨值列表中
---@param uuid int NpcUUID
---@param targetUUID int 目标NpcUUID
---@return bool 
function XDlcCSharpFuncs:CheckNpcInThreatValueList(uuid, targetUUID)
end

---@desc 检查目标Npc是否在强仇列表中
---@param uuid int NpcUUID
---@param targetUUID int 目标NpcUUID
---@return bool 
function XDlcCSharpFuncs:CheckNpcInThreatForceList(uuid, targetUUID)
end

---@desc 带有过渡的进入自定义表演流程
---@param uuid int npcUUid
---@param animName string 自定义表演动画
---@param inTransitionDuration float 进入表演前的过渡时间
---@param outTransitionDuration float 离开表演后的过渡时间
---@param needTurn bool 默认值:false 是否需要旋转
---@param interactFacePos Vector3 默认值:default 旋转后面向的目标位置
---@param onlyOnceAnim bool 默认值:false 非三段式
---@return void 
function XDlcCSharpFuncs:PlayNpcCustomPerformAnim(uuid, animName, inTransitionDuration, outTransitionDuration, needTurn, interactFacePos, onlyOnceAnim)
end

---@desc 中止当前表演状态
---@param uuid int
---@return void 
function XDlcCSharpFuncs:StopNpcPerformAnim(uuid)
end

---@desc 设置Npc部位忽略所有Npc碰撞
---@param uuid int 要设置的NpcUUID
---@param partId int 部位Id
---@param ignore bool 是否忽略
---@return void 
function XDlcCSharpFuncs:SetNpcPartCollidersIgnoreAllOtherNpc(uuid, partId, ignore)
end

---@desc 设置Npc骨骼抖动时间缩放
---@param uuid int 要设置的NpcUUID
---@param isGetFromNpc bool 时间缩放是否依赖Npc的时间缩放
---@return void 
function XDlcCSharpFuncs:SetNpcBoneShakeTimeScale(uuid, isGetFromNpc)
end

---@desc 设置Npc透视
---@param npcUUID int 要设置的NpcUUID
---@param enable bool 是否开启透视效果
---@return void 
function XDlcCSharpFuncs:SetNpcDither(npcUUID, enable)
end

---@desc 设置Npc模型节点显隐(不同步)
---@param npcUUID int 要设置的NpcUUID
---@param jointName string 节点名（为空时为根节点）
---@param active bool 是否显示模型
---@return void 
function XDlcCSharpFuncs:SetNpcJointActive(npcUUID, jointName, active)
end

---@desc 设置 Npc 锁定骨骼点跟随目标 Npc，仅客户端使用
---@param npcPlaceId int 要进行跟随的NpcPlaceId
---@param lockJointName string 锁定的骨骼名
---@param posOffset Vector3 坐标偏移量
---@param isFollowMasterPlayer bool 跟随目标是否是主玩家
---@param followTargetNpcPlaceId int 默认值:0
---@return void 
function XDlcCSharpFuncs:SetNpcNodeLockFollow(npcPlaceId, lockJointName, posOffset, isFollowMasterPlayer, followTargetNpcPlaceId)
end

---@desc 设置 Npc 直接跟随目标 Npc，仅客户端使用
---@param npcUUID int 要进行跟随的NpcUUID
---@param maxIdleRange float 最大闲置半径
---@param startFollowRange float 开始跟随半径
---@param useNavMesh bool 是否使用网格寻路
---@param idleLookAtTarget bool 闲置时注视玩家
---@param enableForceTeleport bool 是否开启范围外传送
---@param teleportRange float 触发传送的距离
---@param isFollowMasterPlayer bool 跟随目标是否是主玩家
---@param followTargetNpcUUID int 默认值:0 若不跟随主玩家，要跟随的NpcUUID
---@param expectedMovingRotateAngularSpeed float 默认值:0 预期移动旋转速度（仅在不使用寻路时生效）
---@return void 
function XDlcCSharpFuncs:SetNpcDirectlyFollow(npcUUID, maxIdleRange, startFollowRange, useNavMesh, idleLookAtTarget, enableForceTeleport, teleportRange, isFollowMasterPlayer, followTargetNpcUUID, expectedMovingRotateAngularSpeed)
end

---@desc 设置 Npc 停止跟随
---@param npcUUID int 要进行跟随的NpcUUID
---@return void 
function XDlcCSharpFuncs:SetNpcStopFollow(npcUUID)
end

---@desc 使Npc从坐下
---@param npcUUID int npcUUID
---@param position Vector3 座位坐标
---@param rotation Vector3 坐下朝向
---@return void 
function XDlcCSharpFuncs:DoNpcSitDown(npcUUID, position, rotation)
end

---@desc 通过PlaceId使得LevelNpc从坐下
---@param npcPlaceId int level配置组的NpcplaceId
---@param position Vector3 座位坐标
---@param rotation Vector3 坐下朝向
---@return void 
function XDlcCSharpFuncs:DoNpcSitDownByPlaceId(npcPlaceId, position, rotation)
end

---@desc 令Npc从坐下状态转为站起，需要先让NpcSitDown
---@param npcUUID int
---@return void 
function XDlcCSharpFuncs:DoNpcSitUp(npcUUID)
end

---@desc 通过PlaceId使得LevelNpc从坐下状态转为站起，需要先让NpcSitDown
---@param npcPlaceId int level配置组的NpcplaceId
---@return void 
function XDlcCSharpFuncs:DoNpcSitUpByPlaceId(npcPlaceId)
end

---@desc 通过PlaceId设置npc的交互选项开启状态
---@param placeId int
---@param optionId int
---@param active bool
---@return bool 
function XDlcCSharpFuncs:SetNpcInteractOptionActive(placeId, optionId, active)
end

---@desc 通过PlaceId设置npc的交互选项仅有OptionId显示
---@param placeId int
---@param optionId int
---@return bool 
function XDlcCSharpFuncs:SetNpcInteractOneOptionActive(placeId, optionId)
end

---@desc 判断npc是否在与玩家交互中
---@param placeId int
---@return bool 
function XDlcCSharpFuncs:CheckNpcIsInInteract(placeId)
end

---@desc 通过PlaceId设置场景物件的交互选项开启状态
---@param placeId int
---@param optionId int
---@param active bool
---@return bool 
function XDlcCSharpFuncs:SetSceneObjectInteractOptionActive(placeId, optionId, active)
end

---@desc 通过PlaceId设置sceneObject的交互选项仅有OptionId显示
---@param placeId int
---@param optionId int
---@return bool 
function XDlcCSharpFuncs:SetSceneObjectInteractOneOptionActive(placeId, optionId)
end

---@desc 判断sceneObject是否在交互中
---@param placeId int
---@return bool 
function XDlcCSharpFuncs:CheckSceneObjectIsInInteract(placeId)
end

---@desc 设置计算伤害前上下文
---@param contextId int 上下文Id
---@param physicalPermyraid double 物理倍率
---@param elementPermyraid double 元素倍率
---@param hackDamage int hack伤害
---@param hackPermyraid int hack倍率
---@param isCrit bool 是否暴击
---@return void 
function XDlcCSharpFuncs:SetBeforeDamageMagicContext(contextId, physicalPermyraid, elementPermyraid, hackDamage, hackPermyraid, isCrit)
end

---@desc 设置计算伤害前上下文 韧性倍率
---@param contextId int 上下文Id
---@param breakPermyraid int 韧性倍率
---@return void 
function XDlcCSharpFuncs:SetBeforeDamageMagicContextBreak(contextId, breakPermyraid)
end

---@desc 设置计算伤害后上下文
---@param contextId int 上下文Id
---@param physicalDamage double 最终物理伤害
---@param elementDamage double 最终元素伤害
---@param finalHackDamage double 最终Hack伤害
---@return void 
function XDlcCSharpFuncs:SetAfterDamageMagicContext(contextId, physicalDamage, elementDamage, finalHackDamage)
end

---@desc 设置计算伤害后上下文 韧性倍率
---@param contextId int 上下文Id
---@param finalBreakDamage int 最终韧性倍率
---@return void 
function XDlcCSharpFuncs:SetAfterDamageMagicContextBreak(contextId, finalBreakDamage)
end

---@desc 设置计算治疗前上下文
---@param contextId int 上下文Id
---@param value double 基础值
---@param permyraid double 万分比
---@return void 
function XDlcCSharpFuncs:SetBeforeCureMagicContext(contextId, value, permyraid)
end

---@desc 设置计算治疗后上下文
---@param contextId int 上下文Id
---@param finalValue double 最终值
---@return void 
function XDlcCSharpFuncs:SetAfterCureMagicContext(contextId, finalValue)
end

---@desc 添加伤害上下文附加值
---@param contextId int contextId
---@param attrType int 属性枚举
---@param v int 固定值
---@param p int 万分比
---@return void 
function XDlcCSharpFuncs:AddDamageMagicContextValue(contextId, attrType, v, p)
end

---@desc 设置伤害上下文附加值
---@param contextId int contextId
---@param attrType int 属性枚举
---@param v int 固定值
---@param p int 万分比
---@return void 
function XDlcCSharpFuncs:SetDamageMagicContextValue(contextId, attrType, v, p)
end

---@desc 添加治疗上下文附加值
---@param contextId int contextId
---@param attrType int 属性枚举
---@param v int 固定值
---@param p int 万分比
---@return void 
function XDlcCSharpFuncs:AddCureMagicContextValue(contextId, attrType, v, p)
end

---@desc 设置治疗上下文附加值
---@param contextId int contextId
---@param attrType int 属性枚举
---@param v int 固定值
---@param p int 万分比
---@return void 
function XDlcCSharpFuncs:SetCureMagicContextValue(contextId, attrType, v, p)
end

---@desc 修改技能预输入上下文
---@param contextId int 上下文Id
---@param targetType int 目标类型
---@param targetUUID int 目标UUID
---@param targetPos Vector3 目标位置
---@param searchTargetUID long 索敌目标UID
---@return void 
function XDlcCSharpFuncs:SetCastSkillByInputActionBeforeValue(contextId, targetType, targetUUID, targetPos, searchTargetUID)
end

---@desc 修改弹刀上下文
---@param contextId int 上下文Id
---@param success bool 弹刀是否成功
---@return void 
function XDlcCSharpFuncs:SetTriggerCounterContextValue(contextId, success)
end

---@desc 以Npc为半径搜索符合条件的Npc
---@param centerNpcUuid int Npc对象的UUID
---@param campValue int 阵营，详细见枚举ENpcCampType
---@param typeValue int npc类型，详细见枚举ENpcTargetType
---@param range float 半径范围
---@param rangeCoe int 范围系数
---@return int Npc对象的UUID
function XDlcCSharpFuncs:SearchNpc(centerNpcUuid, campValue, typeValue, range, rangeCoe)
end

---@desc 【使用了相机方向，仅限玩家npc调用】搜索npc
---@param selfNpcUuid int 玩家操控的Npc对象UUID
---@param campValue int 阵营，详细见枚举ENpcCampType
---@param typeValue int npc类型，详细见枚举ENpcTargetType
---@param range float 半径范围
---@param rangeCoe int 范围系数
---@param angleCoe int 范围系数
---@return int Npc对象的UUID
function XDlcCSharpFuncs:SearchNpcForRole(selfNpcUuid, campValue, typeValue, range, rangeCoe, angleCoe)
end

---@desc 【使用了相机方向，仅限玩家npc调用】搜索npc部位
---@param selfNpcUuid int 玩家操控的Npc对象UUID
---@param campValue int 阵营，详细见枚举ENpcCampType
---@param typeValue int npc类型，详细见枚举ENpcTargetType
---@param range float 半径范围
---@param rangeCoe int 范围系数
---@param angleCoe int 范围系数
---@return LuaTable { NpcUUID:目标NpcId PartId:部位Id PartBoneUID:部位骨骼id}
function XDlcCSharpFuncs:SearchNpcPartForRole(selfNpcUuid, campValue, typeValue, range, rangeCoe, angleCoe)
end

---@desc 获取首个搜索目标的UID，若无则返回0。
---@param uuid int 当前Npc的uuid
---@param npcTargetType int Npc目标类型(ENpcTargetType)
---@return long 
function XDlcCSharpFuncs:GetFirstSearchTarget(uuid, npcTargetType)
end

---@desc 获取搜索目标列表，若无则返回null。
---@param uuid int 当前Npc的uuid
---@param npcTargetType int Npc目标类型(ENpcTargetType)
---@return LuaTable 
function XDlcCSharpFuncs:GetSearchTargetList(uuid, npcTargetType)
end

---@desc 获取索敌/锁定目标的位置
---@param searchTargetUID long 索敌/锁定目标的UID
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
---@param configId int 软锁配置Id
---@return void 
function XDlcCSharpFuncs:SetBaseSoftLockTargetConfig(configId)
end

---@desc 设置指定NPC软锁配置
---@param npcUUID int NpcUUID
---@param configId int 软锁配置Id
---@return void 
function XDlcCSharpFuncs:SetNpcSoftLockTargetConfig(npcUUID, configId)
end

---@desc 设置软锁目标
---@param npcUUID int 要锁定的NpcUUID
---@param targetUID long 锁定目标的UID
---@return void 
function XDlcCSharpFuncs:SetSoftLock(npcUUID, targetUID)
end

---@desc 设置软锁目标到指定部位
---@param npcUUID int 要锁的NpcUUID
---@param targetNpcUUID int 要锁的NpcUUID
---@param partId int 部位Id
---@return void 
function XDlcCSharpFuncs:SetSoftLockToPart(npcUUID, targetNpcUUID, partId)
end

---@desc 取消软锁目标
---@param npcUUID int 要解锁的NpcUUID
---@return void 
function XDlcCSharpFuncs:CancelSoftLockTarget(npcUUID)
end

---@desc 设置硬锁锁目标
---@param npcUUID int 要锁的NpcUUID
---@param targetUID long 锁定目标的UID
---@return void 
function XDlcCSharpFuncs:SetHardLock(npcUUID, targetUID)
end

---@desc 设置硬锁锁目标到指定部位
---@param npcUUID int 执行锁定的NpcUUID
---@param targetNpcUUID int 被锁的NpcUUID
---@param partId int 部位Id
---@return void 
function XDlcCSharpFuncs:SetHardLockToPart(npcUUID, targetNpcUUID, partId)
end

---@desc 取消硬锁目标
---@param npcUUID int 要锁的NpcUUID
---@return void 
function XDlcCSharpFuncs:CancelHardLockTarget(npcUUID)
end

---@desc 设置强制锁定到指定Npc的部位
---@param npcUUID int 要锁定的NpcUUID
---@param partId int 部位Id
---@return void 
function XDlcCSharpFuncs:SetAllPlayerForceLockToPart(npcUUID, partId)
end

---@desc 取消强制锁定
---@return void 
function XDlcCSharpFuncs:CanceAllPlayerForceLockTarget()
end

---@desc 设置破韧锁(强制锁)定到指定Npc的部位
---@param npcUUID int 要锁定的NpcUUID
---@param partId int 部位Id
---@return void 
function XDlcCSharpFuncs:SetAllPlayerBreakResilienceLockToPart(npcUUID, partId)
end

---@desc 取消破韧锁(强制锁)
---@return void 
function XDlcCSharpFuncs:CanceAllPlayerBreakResilienceLockTarget()
end

---@desc 检查Npc对应key的Int类型字典值是否存在
---@param npcId int
---@param key int
---@return bool 
function XDlcCSharpFuncs:CheckNpcNoteInt(npcId, key)
end

---@desc 检查Npc对应key的float类型字典值是否存在
---@param npcId int
---@param key int
---@return bool 
function XDlcCSharpFuncs:CheckNpcNoteFloat(npcId, key)
end

---@desc 检查Npc对应key的bool类型字典值是否存在
---@param npcId int
---@param key int
---@return bool 
function XDlcCSharpFuncs:CheckNpcNoteBool(npcId, key)
end

---@desc 检查Npc对应key的float3类型字典值是否存在
---@param npcId int
---@param key int
---@return bool 
function XDlcCSharpFuncs:CheckNpcNoteFloat3(npcId, key)
end

---@desc 获取Npc对应key的Int类型字典值
---@param npcId int
---@param key int
---@return int 
function XDlcCSharpFuncs:GetNpcNoteInt(npcId, key)
end

---@desc 获取Npc对应key的float类型字典值
---@param npcId int
---@param key int
---@return float 
function XDlcCSharpFuncs:GetNpcNoteFloat(npcId, key)
end

---@desc 获取Npc对应key的float3类型字典值
---@param npcId int
---@param key int
---@return Vector3 
function XDlcCSharpFuncs:GetNpcNoteFloat3(npcId, key)
end

---@desc 修改Npc对应key的Int类型字典值
---@param npcId int
---@param key int
---@param value int
---@return void 
function XDlcCSharpFuncs:SetNpcNoteInt(npcId, key, value)
end

---@desc 修改Npc对应key的float类型字典值
---@param npcId int
---@param key int
---@param value float
---@return void 
function XDlcCSharpFuncs:SetNpcNoteFloat(npcId, key, value)
end

---@desc 修改Npc对应key的float2类型字典值
---@param npcId int
---@param key int
---@param v1 float
---@param v2 float
---@return void 
function XDlcCSharpFuncs:SetNpcNoteFloat2(npcId, key, v1, v2)
end

---@desc 修改Npc对应key的float3类型字典值
---@param npcId int
---@param key int
---@param v1 float
---@param v2 float
---@param v3 float
---@return void 
function XDlcCSharpFuncs:SetNpcNoteFloat3(npcId, key, v1, v2, v3)
end

---@desc 注册黑板同步值
---@param domain int
---@param id int
---@param key int
---@return void 
function XDlcCSharpFuncs:RegisterBBSync(domain, id, key)
end

---@desc 取消黑板同步值
---@param domain int
---@param id int
---@param key int
---@return void 
function XDlcCSharpFuncs:UnregisterBBSync(domain, id, key)
end

---@desc 设置黑板值Bool
---@param domain int
---@param id int
---@param key int
---@param value bool
---@return void 
function XDlcCSharpFuncs:SetBBBoolean(domain, id, key, value)
end

---@desc 获取黑板值Bool
---@param domain int
---@param id int
---@param key int
---@return bool , bool result:
function XDlcCSharpFuncs:TryGetBBBoolean(domain, id, key)
end

---@desc 设置黑板值Int
---@param domain int
---@param id int
---@param key int
---@param value int
---@return void 
function XDlcCSharpFuncs:SetBBInt(domain, id, key, value)
end

---@desc 获取黑板值Int
---@param domain int
---@param id int
---@param key int
---@return bool , int result:
function XDlcCSharpFuncs:TryGetBBInt(domain, id, key)
end

---@desc 设置黑板值Float
---@param domain int
---@param id int
---@param key int
---@param value float
---@return void 
function XDlcCSharpFuncs:SetBBFloat(domain, id, key, value)
end

---@desc 获取黑板值Float
---@param domain int
---@param id int
---@param key int
---@return bool , float result:
function XDlcCSharpFuncs:TryGetBBFloat(domain, id, key)
end

---@desc 设置黑板值Vector2
---@param domain int
---@param id int
---@param key int
---@param value Vector2
---@return void 
function XDlcCSharpFuncs:SetBBVector2(domain, id, key, value)
end

---@desc 获取黑板值Vector2
---@param domain int
---@param id int
---@param key int
---@return bool , Vector2 result:
function XDlcCSharpFuncs:TryGetBBVector2(domain, id, key)
end

---@desc 设置黑板值Vector3
---@param domain int
---@param id int
---@param key int
---@param value Vector3
---@return void 
function XDlcCSharpFuncs:SetBBVector3(domain, id, key, value)
end

---@desc 获取黑板值Vector3
---@param domain int
---@param id int
---@param key int
---@return bool , Vector3 result:
function XDlcCSharpFuncs:TryGetBBVector3(domain, id, key)
end

---@desc 通过子弹 UUID 查找其配置 Id
---@param uuid int UUID
---@return bool , int templateId:返回出的配置Id
function XDlcCSharpFuncs:MissileUUIDToTemplateId(uuid)
end

---@desc 使一Npc向另一Npc发射子弹
---@param launcherNpcUUID int 发射Npc的uuid
---@param targetNpcUUID int 目标Npc的uuid
---@param launchId int 子弹发射参数id，与子弹帧事件id相同
---@param missileId int 子弹配置id
---@param level int 子弹等级，作为子弹击中目标时执行的magic的等级，一般默认为1
---@return bool 发射是否成功, int missileUUID:(第二返回值)子弹ActorUUID
function XDlcCSharpFuncs:LaunchMissile(launcherNpcUUID, targetNpcUUID, launchId, missileId, level)
end

---@desc 从指定坐标向另一指定坐标发射线性子弹
---@param launcherNpcUUID int 发射Npc的uuid
---@param launchId int 子弹发射参数id，与子弹帧事件id相同
---@param missileId int 子弹配置id
---@param launchPos Vector3 发射坐标
---@param targetPos Vector3 目标坐标
---@param level int 子弹等级，作为子弹击中目标时执行的magic的等级，一般默认为1
---@return bool 发射是否成功, int missileUUID:(第二返回值)子弹ActorUUID
function XDlcCSharpFuncs:LaunchMissileFromPosToPos(launcherNpcUUID, launchId, missileId, launchPos, targetPos, level)
end

---@desc 从指定Npc向另一指定坐标发射线性子弹
---@param launcherNpcUUID int 发射Npc的uuid
---@param targetPos Vector3 目标坐标
---@param launchId int 子弹发射参数id，与子弹帧事件id相同
---@param missileId int 子弹配置id
---@param level int 子弹等级，作为子弹击中目标时执行的magic的等级，一般默认为1
---@return bool 发射是否成功, int missileUUID:(第二返回值)子弹ActorUUID
function XDlcCSharpFuncs:LaunchMissileFromNpcToPos(launcherNpcUUID, targetPos, launchId, missileId, level)
end

---@desc 移除所有指定发射者的子弹
---@param launcherId int 发射Npc的uuid
---@return bool 移除是否执行成功
function XDlcCSharpFuncs:DestroyAllMissileDependOnLauncher(launcherId)
end

---@desc 移除指定UUID的子弹
---@param missileUUID int 发射Npc的uuid
---@return bool 移除是否执行成功
function XDlcCSharpFuncs:DestroyMissileByUUID(missileUUID)
end

---@desc 根据子弹UUID获取子弹当前位置
---@param missileUUID int 子弹UUID
---@return bool 是否获取成功, Vector3 pos:子弹位置
function XDlcCSharpFuncs:TryGetMissilePositionByUUID(missileUUID)
end

---@desc 根据子弹配置移除当前Npc子弹
---@param templateId int 子弹配置ID
---@return bool 
function XDlcCSharpFuncs:RemoveCurrentNpcMissileByTemplateId(templateId)
end

---@desc 激活虚拟相机
---@desc （激活指定玩家npc对应端的虚拟相机
---@desc （priority为优先级，一般取100，上限9999
---@desc 激活一个固定的虚拟相机的方式，referenceId填0、followId填0、lookAtId填0
---@param playerNpcId int
---@param vCam string
---@param blendIn float
---@param blendOut float
---@param referenceId int
---@param x float
---@param y float
---@param z float
---@param eulerX float
---@param eulerY float
---@param eulerZ float
---@param followId int
---@param lookAtId int
---@param priority int
---@param allClients bool
---@return void 
function XDlcCSharpFuncs:ActivateVCam(playerNpcId, vCam, blendIn, blendOut, referenceId, x, y, z, eulerX, eulerY, eulerZ, followId, lookAtId, priority, allClients)
end

---@desc 关闭虚拟相机 （关闭指定玩家npc对应端的虚拟相机
---@param playerNpcId int
---@param vCam string
---@param allClients bool
---@return void 
function XDlcCSharpFuncs:DeactivateVCam(playerNpcId, vCam, allClients)
end

---@desc 获取相机当前朝向
---@return Vector3 
function XDlcCSharpFuncs:GetCameraForwardDir()
end

---@desc 获取目标点和相机坐标连线到相机朝向的夹角
---@param position Vector3
---@param ignoreY bool
---@return float 
function XDlcCSharpFuncs:GetCameraAngleFromPos(position, ignoreY)
end

---@desc 添加自定义相机旋转
---@param id int
---@param x float
---@param y float
---@param z float
---@param blendIn float
---@param blendOut float
---@param relative bool
---@param bind bool
---@return void 
function XDlcCSharpFuncs:AddCustomCameraRotation(id, x, y, z, blendIn, blendOut, relative, bind)
end

---@desc 移除自定义相机旋转
---@param id int
---@return void 
function XDlcCSharpFuncs:RemoveCustomCameraRotation(id)
end

---@desc 开关低饱和度屏幕效果（黑白滤镜
---@param target XNpc
---@param enabled bool
---@param allClients bool
---@return void 
function XDlcCSharpFuncs:SetLowSaturation(target, enabled, allClients)
end

---@desc 让程序补注释！
---@param ignoreHeightLerpOnAir bool
---@return void 
function XDlcCSharpFuncs:SetCameraIgnoreHeightLerpOnAir(ignoreHeightLerpOnAir)
end

---@desc 重置相机位置
---@param resetAngleX bool 是否重置相机X轴
---@param rotYEulerOffset float 重置Y轴后的偏移
---@param isEndRotationOverride bool 是否强制重置（忽略玩家正在操作相机）
---@return void 
function XDlcCSharpFuncs:ResetCamera(resetAngleX, rotYEulerOffset, isEndRotationOverride)
end

---@desc 获取相机位置信息（相对于npc1和npc2构成的坐标系）
---@param npc1UUID int Npc1的UUID
---@param npc2UUID int Npc2的UUID
---@return Vector2 相对于新坐标系的位置, float angleOffset:第二返回值（角度偏移）
function XDlcCSharpFuncs:GetCameraPosInfo(npc1UUID, npc2UUID)
end

---@desc 检测基于相机计算出的射线是否命中碰撞体（地形 & 场景物体 & Npc & 关卡障碍），仅客户端使用
---@param length float 射线长度
---@return bool 是否命中碰撞体, Vector3 hitPos:(第二个返回值)命中的障碍位置
function XDlcCSharpFuncs:CheckCameraRayCastCollider(length)
end

---@desc 设置相机操作是否可用（仅客户端）
---@param enable bool 是否可用
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
---@param nextLevelId int 下一个进入的LevelId
---@param position Vector3 目标坐标
---@return void 
function XDlcCSharpFuncs:SwitchLevel(nextLevelId, position)
end

---@desc 切换Level
---@param nextLevelId int 下一个进入的LevelId
---@param position Vector3 目标坐标
---@param rotation Vector3 目标旋转度
---@return void 
function XDlcCSharpFuncs:SwitchLevelWitchRot(nextLevelId, position, rotation)
end

---@desc 进入副本Level，要和RequestLeaveInstanceLevel()成对使用
---@param nextLevelId int 要进入的副本LevelId
---@param position Vector3 目标坐标
---@param rotation Vector3 目标旋转度
---@return void 
function XDlcCSharpFuncs:RequestEnterInstLevel(nextLevelId, position, rotation)
end

---@desc 退出副本Level，要和RequestEnterInstLevel()成对使用
---@param resetSaveDataExit bool 是否保存数据退出
---@return void 
function XDlcCSharpFuncs:RequestLeaveInstanceLevel(resetSaveDataExit)
end

---@desc 设置关卡存储值Int
---@param key int
---@param value int
---@return void 
function XDlcCSharpFuncs:SetLevelMemoryInt(key, value)
end

---@desc 设置关卡存储值Float
---@param key int
---@param value float
---@return void 
function XDlcCSharpFuncs:SetLevelMemoryFloat(key, value)
end

---@desc 移除关卡存储值Int
---@param key int
---@return void 
function XDlcCSharpFuncs:RemoveLevelMemoryInt(key)
end

---@desc 移除关卡存储值Float
---@param key int
---@return void 
function XDlcCSharpFuncs:RemoveLevelMemoryFloat(key)
end

---@desc 获取关卡存储值Int
---@param key int
---@return int 
function XDlcCSharpFuncs:GetLevelMemoryInt(key)
end

---@desc 获取关卡存储值Float
---@param key int
---@return float 
function XDlcCSharpFuncs:GetLevelMemoryFloat(key)
end

---@desc 检查关卡Int存储值是否存在
---@param key int
---@return bool 
function XDlcCSharpFuncs:CheckLevelMemoryInt(key)
end

---@desc 检查关卡Float存储值是否存在
---@param key int
---@return bool 
function XDlcCSharpFuncs:CheckLevelMemoryFloat(key)
end

---@desc 获取关卡点位
---@param id int
---@return Vector3 
function XDlcCSharpFuncs:GetSpot(id)
end

---@desc 创建一个挂载到指定Actor的触发器（Npc或SceneObject）
---@param uuid int
---@param touchType int 触发器接触类型，参考ESceneObjectTouchType
---@param shapeType int 触发器的形状，参考EShapeType
---@param triggerName string 触发器的内部名称
---@param localPosition Vector3 trigger在Actor局部坐标系下的坐标
---@param eulerAngles Vector3 trigger的朝向（欧拉角，单位：度）
---@param size Vector3 尺寸/大小，仅当类型为Box时有效
---@param radius float 半径，仅当类型为Sphere或Capsule时有效
---@param height float 高度，仅当类型为Capsule时有效
---@param direction int 胶囊体延展轴向，仅当类型为Capsule时有效
---@return int 返回TriggerId（成功时大于0，失败为0）
function XDlcCSharpFuncs:CreateActorTrigger(uuid, touchType, shapeType, triggerName, localPosition, eulerAngles, size, radius, height, direction)
end

---@desc 启动关卡玩法计时器
---@param time float 需计时间（单位：秒）
---@param isCountDown bool 默认值:false 是否为倒计时
---@param imminentEndTimeS float 默认值:10f 倒计时完毕前提醒的时间
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
---@param controlName string
---@param value float
---@return void 
function XDlcCSharpFuncs:SetBgmAisacControl(controlName, value)
end

---@desc 创建关卡特效
---@param effectRefId int
---@param effectName string
---@param posX float
---@param posY float
---@param posZ float
---@param rotX float
---@param rotY float
---@param rotZ float
---@param offsetX float
---@param offsetY float
---@param offsetZ float
---@return void 
function XDlcCSharpFuncs:CreateLevelEffect(effectRefId, effectName, posX, posY, posZ, rotX, rotY, rotZ, offsetX, offsetY, offsetZ)
end

---@desc 移除关卡特效
---@param effectRefId int
---@return void 
function XDlcCSharpFuncs:RemoveLevelEffect(effectRefId)
end

---@desc 检查关卡特效是否存在
---@param effectRefId int
---@return bool 
function XDlcCSharpFuncs:CheckLevelEffectExist(effectRefId)
end

---@desc 播放相机Timeline
---@param name string
---@param targetId int
---@param blendIn float
---@param blendOut float
---@param locationType int 0-世界坐标系起始为目标坐标，1-目标局部坐标系
---@return void 
function XDlcCSharpFuncs:PlayCameraTimeline(name, targetId, blendIn, blendOut, locationType)
end

---@desc 停止相机Timeline
---@param name string
---@param targetId int
---@return void 
function XDlcCSharpFuncs:StopCameraTimeline(name, targetId)
end

---@desc 播放场景动画（场景美术事先在场景里编辑好的动画
---@param id int
---@return void 
function XDlcCSharpFuncs:PlaySceneAnimation(id)
end

---@desc 开关场景Timeline
---@param id int timeline序号，从1开始
---@param state bool true播放，false停止
---@return void 
function XDlcCSharpFuncs:SwitchSceneTimeline(id, state)
end

---@desc 切换场景子预制体（当关卡场景的预制体是多个场景预制体合成而来时）。
---@desc 举例：boss转二阶段时，播了个CG把原本的场景周围一圈东西破坏掉了，
---@desc 那这前后就会做成两个场景预制体，然后合并为一个场景预制体，通过该方法在需要的时候切换。
---@desc 这种是受限于不好做动态破坏等效果，另一种是受限于主线的渲染模式、光照烘焙等，
---@desc 无法将两个相邻的场景做成无缝衔接的一个场景。
---@desc 策划使用时，要注意，如果前后两个场景重叠，而玩家所在位置的地形高度又不一样，则需要传送一下并且重置状态。
---@param index int 要切换到的场景子预制体索引
---@return bool 
function XDlcCSharpFuncs:SwitchSceneSubPrefab(index)
end

---@desc 禁止反复开关（会发送同步消息
---@desc 开关动态障碍
---@param obstacleId int 障碍ID（必须是动态障碍的ID）
---@param active bool true开，false关
---@return void 
function XDlcCSharpFuncs:SetObstacleActive(obstacleId, active)
end

---@desc 禁止反复开关（会发送同步消息
---@desc 开关动态障碍组
---@param obstacleGroupId int 障碍组ID（必须是动态障碍的ID）
---@param active bool true开，false关
---@return void 
function XDlcCSharpFuncs:SetObstacleGroupActive(obstacleGroupId, active)
end

---@desc 禁止频繁调用（会发送同步消息
---@desc 设置Npc忽略障碍
---@param npcId int Npc对象的UUID
---@param obstacleId int 障碍ID（静态/动态障碍都可以）
---@param ignore bool true忽略，false取消忽略
---@return void 
function XDlcCSharpFuncs:SetNpcIgnoreObstacle(npcId, obstacleId, ignore)
end

---@desc 该功能已弃用，不要再调用
---@param npcId int
---@param groupName string
---@param colliderIndex int
---@param ignore bool
---@return void 
function XDlcCSharpFuncs:SetSceneColliderIgnoreCollision(npcId, groupName, colliderIndex, ignore)
end

---@desc 设置两个Actor间互相忽略碰撞
---@param actorUUIDA int 对象A的UUID
---@param actorUUIDB int 对象B的UUID
---@param ignore bool true忽略，false取消忽略
---@return void 
function XDlcCSharpFuncs:SetActorIgnoreCollision(actorUUIDA, actorUUIDB, ignore)
end

---@desc 检查技能时间
---@param npcId int Npc对象的UUID
---@param type int 技能时间类型：Jump=1,Move=2,Skill=3,UseAnimationY=4
---@return bool 
function XDlcCSharpFuncs:CheckActionTiming(npcId, type)
end

---@desc 使Npc释放指定技能
---@param npcId int
---@param skillActionId int
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastAction(npcId, skillActionId)
end

---@desc 使Npc释放指定技能(部分技能)
---@param npcId int
---@param skillActionId int
---@param startTime float 开始时间
---@param endTime float 结束时间
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastActionEx(npcId, skillActionId, startTime, endTime)
end

---@desc 使Npc释放指定技能Action(不检查)
---@param npcId int
---@param skillActionId int
---@param startTime float 开始时间
---@param endTime float 结束时间
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillActionNotCheck(npcId, skillActionId, startTime, endTime)
end

---@desc 向指定坐标放技能
---@param npcId int
---@param skillActionId int
---@param position Vector3 位置
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastActionToPosition(npcId, skillActionId, position)
end

---@desc 向指定坐标放技能(部分技能)
---@param npcId int
---@param skillActionId int
---@param position Vector3 位置
---@param startTime float 开始时间
---@param endTime float 结束时间
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastActionToPositionEx(npcId, skillActionId, position, startTime, endTime)
end

---@desc 向指定坐标放技能(不检查)
---@param npcId int
---@param skillActionId int
---@param position Vector3 位置
---@param startTime float 开始时间
---@param endTime float 结束时间
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillActionToPositionNotCheck(npcId, skillActionId, position, startTime, endTime)
end

---@desc 向指定Npc放技能
---@param npcId int 要释放技能的Npc对象的UUID
---@param skillActionId int 技能Id
---@param targetNpcId int 目标Npc对象的UUID
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastActionToTarget(npcId, skillActionId, targetNpcId)
end

---@desc 向指定Npc放技能(部分技能)
---@param npcId int 要释放技能的Npc对象的UUID
---@param skillActionId int 技能Id
---@param targetNpcId int 目标Npc对象的UUID
---@param startTime float 开始时间
---@param endTime float 结束时间
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastActionToTargetEx(npcId, skillActionId, targetNpcId, startTime, endTime)
end

---@desc 向指定Npc放技能(不检查)
---@param npcId int 要释放技能的Npc对象的UUID
---@param skillActionId int 技能Id
---@param targetNpcId int 目标Npc对象的UUID
---@param startTime float 开始时间
---@param endTime float 结束时间
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillActionToNpcNotCheck(npcId, skillActionId, targetNpcId, startTime, endTime)
end

---@desc 向指定搜索or锁定目标放技能
---@param npcId int 要释放技能的Npc对象的UUID
---@param skillActionId int 技能Id
---@param targetUID long 搜索or锁定目标的UID
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastActionToSearchTarget(npcId, skillActionId, targetUID)
end

---@desc 向指定搜索or锁定目标放技能(不检查条件)
---@param npcId int 要释放技能的Npc对象的UUID
---@param skillActionId int 技能Id
---@param searchTargetId long 搜索or锁定目标的UID
---@param startTime float 开始时间
---@param endTime float 结束时间
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillActionToSearchTargetNotCheck(npcId, skillActionId, searchTargetId, startTime, endTime)
end

---@desc 打断Npc当前技能
---@param npcId int
---@param force bool 默认值:false
---@return void 
function XDlcCSharpFuncs:AbortAction(npcId, force)
end

---@desc 检查Npc当前技能是否为指定技能
---@param npcId int
---@param skillActionId int
---@return bool 
function XDlcCSharpFuncs:CheckNpcCurrentAction(npcId, skillActionId)
end

---@desc 获取当前技能的配置ID以及类型
---@param npcId int
---@return bool , int skillActionId:, int skillType:
function XDlcCSharpFuncs:TryGetCurrentAction(npcId)
end

---@desc 获取当前技能的运行时间
---@param npcId int
---@return bool , float elapsedTime:
function XDlcCSharpFuncs:TryGetNpcCurrentActionElapsedTime(npcId)
end

---@desc 获取技能类型
---@param skillId int
---@return int 
function XDlcCSharpFuncs:GetActionType(skillId)
end

---@desc 获取Npc动作的动作类型(技能Id传0时，使用上一个动作Id作为动作Id)
---@param uuid int Npc的UUID
---@param actionId int 动作Id
---@return int 
function XDlcCSharpFuncs:GetNpcActionType(uuid, actionId)
end

---@desc 设置动作优先级(动作Id传0时，使用上一个动作Id作为动作Id)
---@param npcUUID int Npc的UUID
---@param actionId int 动作Id
---@param priority int 优先级
---@return void 
function XDlcCSharpFuncs:SetActionPriority(npcUUID, actionId, priority)
end

---@desc 获取动作优先级(动作Id传0时，使用上一个动作Id作为动作Id)
---@param npcUUID int Npc的UUID
---@param actionId int 动作Id
---@return bool , int priority:优先级(第二个返回值)
function XDlcCSharpFuncs:TryGetActionPriority(npcUUID, actionId)
end

---@desc 获取技能特征标签(技能Id传0时，使用上一个技能Id作为技能Id)
---@param npcUUID int Npc的UUID
---@param skillId int 技能Id
---@return LuaTable 
function XDlcCSharpFuncs:GetActionFeatureTag(npcUUID, skillId)
end

---@desc 检查技能特征标签(技能Id传0时，使用上一个技能Id作为技能Id)
---@param npcUUID int Npc的UUID
---@param skillId int 技能Id
---@param featureTag int 要检查的标签值
---@return bool 
function XDlcCSharpFuncs:CheckActionFeatureTag(npcUUID, skillId, featureTag)
end

---@desc 获取Npc的技能Id列表
---@param npcUUID int NpcUUID
---@return LuaTable 技能ID列表
function XDlcCSharpFuncs:GetActionIdList(npcUUID)
end

---@desc 尝试使用技能
---@param npcUUID int NPCUUID
---@param key int ENpcOperationKey
---@param type int EOperationType
---@param operateTime float 长按时间
---@return void 
function XDlcCSharpFuncs:TryCastAction(npcUUID, key, type, operateTime)
end

---@desc 获取动作配置
---@param actionId int
---@return XTableSkillAction 
function XDlcCSharpFuncs:GetSkillActionTemplate(actionId)
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
---@param active bool
---@return void 
function XDlcCSharpFuncs:SetUseInputTemplate(active)
end

---@desc 尝试获取当前SkillAction所依赖的SkillId
---@param npcId int
---@return bool , int subscribeSkill:
function XDlcCSharpFuncs:TryGetCurrentActionSubscribeSkill(npcId)
end

---@desc 将按键上的技能组替换为指定技能组(指定技能组未挂载时会报错)
---@param npcId int Npc对象的UUID
---@param opKeyId int 要替换技能组的操作键id,参考ENpcOperationKey
---@param skillGroupId int 默认值:0 要替换的目标技能组ID,留空或为0时将换下当前技能组并按照优先级队列进行回退,小于0时将替换为key的默认技能组
---@return void 
function XDlcCSharpFuncs:SetSkillGroup(npcId, opKeyId, skillGroupId)
end

---@desc 获取指定技能组的按压计数器
---@param npcUUID int Npc对象的UUID
---@param skillGroupId int 目标技能组id
---@return int 技能组获取失败时返回 -1
function XDlcCSharpFuncs:GetSkillGroupLastHitId(npcUUID, skillGroupId)
end

---@desc [触发输入缓存](http://redmine.haru.com/redmine/issues/217546)
---@param npcUUID int Npc对象的UUID
---@return void 
function XDlcCSharpFuncs:PopInputCache(npcUUID)
end

---@desc [在按钮上启动倒计时进度条](http://redmine.haru.com:8081/redmine/issues/223498)
---@param npcUUID int Npc对象的UUID
---@param opKeyId int 目标操作键id,参考ENpcOperationKey
---@param time float 倒计时时长,受npc时停倍率影响
---@return void 
function XDlcCSharpFuncs:StartButtonCountDown(npcUUID, opKeyId, time)
end

---@desc [清空按钮上的倒计时进度条](http://redmine.haru.com:8081/redmine/issues/223498)
---@param npcUUID int Npc对象的UUID
---@param opKeyId int 目标操作键id,参考ENpcOperationKey
---@param time float
---@return void 
function XDlcCSharpFuncs:ClearButtonCountDown(npcUUID, opKeyId, time)
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
---@param value float
---@return void 
function XDlcCSharpFuncs:EnterSkillCD(value)
end

---@desc 减少技能CD固定值
---@param value float
---@return void 
function XDlcCSharpFuncs:DecreaseSkillCD(value)
end

---@desc 减少技能CD万分比
---@param value int
---@return void 
function XDlcCSharpFuncs:DecreaseSkillCDPercent(value)
end

---@desc 设置技能当前CD
---@param value int
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
---@param npcUUID int
---@param buffTempId int
---@return int 
function XDlcCSharpFuncs:GetBuffStacks(npcUUID, buffTempId)
end

---@desc 根据Kind获取Buff数量
---@param npcUUID int
---@param kind int
---@return int 
function XDlcCSharpFuncs:GetBuffCountByKind(npcUUID, kind)
end

---@desc 检查Buff是否属于传入的类型
---@param buffTempId int Buff的配置Id
---@param kinds List<int> 要检查的类型列表
---@return bool 
function XDlcCSharpFuncs:CheckBuffKinds(buffTempId, kinds)
end

---@desc 检查Buff列表是否属于传入类型列表
---@param buffTempIds List<int> Buff的配置Id列表
---@param kinds List<int> 要检查的类型列表
---@return bool 
function XDlcCSharpFuncs:CheckBuffListKinds(buffTempIds, kinds)
end

---@desc 修改该脚本挂载的Npc所持有的所有配置为BuffTempId的Buff的持续时间
---@param buffTemplateId int BuffTempIdbuff配置ID
---@param value float Value增加值正数为增加负数为减少
---@param valueType EBuffModifyType ValueType值类型|默认0数值|1万分比
---@param valueRef EBuffValueRefType 值参照|默认0Buff出生时的持续时间|1当前剩余时间(参数3为万分比时生效)
---@return void 
function XDlcCSharpFuncs:ChangeBuffTimeByTemplateId(buffTemplateId, value, valueType, valueRef)
end

---@desc 设置该脚本挂在的Npc所持有的所有配置为BuffTempId的Buff的持续时间
---@param buffTemplateId int BuffTempIdbuff配置ID
---@param value float 设置值
---@param valueType EBuffModifyType 值类型|默认0数值|1万分比
---@param valueRef EBuffValueRefType 值参照|默认0Buff出生时的持续时间|1当前剩余时间(参数3为万分比时生效)
---@return void 
function XDlcCSharpFuncs:SetBuffTimeByTemplateId(buffTemplateId, value, valueType, valueRef)
end

---@desc 获取magic的tag列表
---@param magicId int magic配置Id
---@return IReadOnlyList<int> 
function XDlcCSharpFuncs:GetMagicTags(magicId)
end

---@desc 加载场景物件
---@param placeId int 场景物件的PlaceId
---@return bool true成功，false失败
function XDlcCSharpFuncs:LoadSceneObject(placeId)
end

---@desc 卸载SceneObj
---@param placeId int
---@return void 
function XDlcCSharpFuncs:UnloadSceneObject(placeId)
end

---@desc 获取场景物件对象id
---@param placeId int
---@return int 
function XDlcCSharpFuncs:GetSceneObjectUUID(placeId)
end

---@desc 获取场景物件坐标
---@param placeId int
---@return Vector3 
function XDlcCSharpFuncs:GetSceneObjectPositionByPlaceId(placeId)
end

---@desc 获取场景物件朝向
---@param placeId int
---@return Vector3 
function XDlcCSharpFuncs:GetSceneObjectRotationByPlaceId(placeId)
end

---@desc 获取场景物件坐标
---@param uuid int
---@return Vector3 
function XDlcCSharpFuncs:GetSceneObjectPosition(uuid)
end

---@desc 获取场景物件朝向
---@param uuid int
---@return Vector3 
function XDlcCSharpFuncs:GetSceneObjectRotation(uuid)
end

---@desc 开关场景物件
---@param sceneObjectPlaceId int
---@param active bool
---@return void 
function XDlcCSharpFuncs:SetSceneObjectActive(sceneObjectPlaceId, active)
end

---@desc 场景物件是否开启
---@param sceneObjectPlaceId int
---@return bool 
function XDlcCSharpFuncs:IsSceneObjectActive(sceneObjectPlaceId)
end

---@desc 开关场景物件阴影（仅在客户端生效）
---@param sceneObjectPlaceId int
---@param enable bool
---@return void 
function XDlcCSharpFuncs:SetSceneObjectShadowEnable(sceneObjectPlaceId, enable)
end

---@desc 移动场景物体到MoveComponent的第几个点
---@param sceneObjectPlaceId int
---@param nodeId int
---@param moveSpeed float 默认值:-1 重调移动速度
---@return void 
function XDlcCSharpFuncs:MoveSceneObjectToNode(sceneObjectPlaceId, nodeId, moveSpeed)
end

---@desc 判断场景物体是否移动到第几个点（不建议每帧调用）
---@param sceneObjectPlaceId int
---@param nodeId int
---@return bool 
function XDlcCSharpFuncs:CheckSceneObjectInNode(sceneObjectPlaceId, nodeId)
end

---@desc 开启SceneObj的自动旋转
---@param sceneObjectPlaceId int
---@param isRotate bool
---@return void 
function XDlcCSharpFuncs:SetSceneObjectAutoRotate(sceneObjectPlaceId, isRotate)
end

---@desc 旋转SceneObject，仅在SceneObject不会自动旋转时生效
---@param sceneObjectPlaceId int SceneObject的PlaceId
---@param rotateTime float 旋转时间
---@param rotateAngle float 旋转角度
---@param rotateAxis byte 旋转轴，参考ESceneObjectRotateAxis
---@param isQueue bool 默认值:false 是否加入旋转指令队列（可选，默认值为false）
---@return void 
function XDlcCSharpFuncs:RotateSceneObject(sceneObjectPlaceId, rotateTime, rotateAngle, rotateAxis, isQueue)
end

---@desc 设置SceneObject的特效字文本（仅客户端使用）
---@param sceneObjectPlaceId int SceneObject的PlaceId
---@param isEnabled bool 是否开启特效字组件，若组件已经开启则状态不变
---@param textKey string 要使用的文本配置Key，配置位于Client\BigWorld\Common\Text\BigWorldText
---@return void 
function XDlcCSharpFuncs:SetSceneObjectTextMeshText(sceneObjectPlaceId, isEnabled, textKey)
end

---@desc 开关场景物件钩点组件
---@param soPlaceId int
---@param enable bool
---@return void 
function XDlcCSharpFuncs:SetHookableSceneObjectEnable(soPlaceId, enable)
end

---@desc 使场景物件执行指定动作
---@param soPlaceId int
---@param actionId int
---@return bool 
function XDlcCSharpFuncs:DoSceneObjectAction(soPlaceId, actionId)
end

---@desc 检查场景物件是否在执行指定动作
---@param soPlaceId int
---@param actionId int
---@return bool 
function XDlcCSharpFuncs:CheckSceneObjectAction(soPlaceId, actionId)
end

---@desc 请联系程序补充注释
---@param soPlaceId int
---@param scriptId int
---@return void 
function XDlcCSharpFuncs:AddSceneObjectScript(soPlaceId, scriptId)
end

---@desc 请联系程序补充注释
---@param soPlaceId int
---@param scriptId int
---@return void 
function XDlcCSharpFuncs:RemoveSceneObjectScript(soPlaceId, scriptId)
end

---@desc 动态创建SceneObject
---@param sceneObjId int SceneObjectBaseID
---@param position Vector3 坐标
---@param rotation Vector3 朝向（欧拉角）
---@return int 
function XDlcCSharpFuncs:CreateSceneObject(sceneObjId, position, rotation)
end

---@desc 移除SceneObject
---@param sceneObjUUID int
---@return void 
function XDlcCSharpFuncs:DestroySceneObject(sceneObjUUID)
end

---@desc 设置SceneObject锁定状态（仅限控制端调用）
---@param soPlaceId int
---@param locked bool
---@return void 
function XDlcCSharpFuncs:SetSceneObjectLocked(soPlaceId, locked)
end

---@desc 设置SceneObject模型节点显隐（仅限客户端调用）
---@param soPlaceId int
---@param tag string
---@param active bool
---@return void 
function XDlcCSharpFuncs:SetSceneObjectNodesActive(soPlaceId, tag, active)
end

---@desc 播放任务剧情
---@param questId int 任务Id
---@param dramaName string 剧情名
---@param referencePos Vector3 默认值:default 相对位置（可选，默认为原点）
---@param referenceRot Vector3 默认值:default 相对旋转（可选，默认为原点）
---@param combineKey int 默认值:0 连贯播放组合ID（可选，默认为0）
---@return void 
function XDlcCSharpFuncs:PlayQuestDrama(questId, dramaName, referencePos, referenceRot, combineKey)
end

---@desc 直接播放剧情
---@param dramaName string 剧情名
---@param referencePos Vector3 默认值:default 相对位置（可选，默认为原点）
---@param referenceRot Vector3 默认值:default 相对旋转（可选，默认为原点）
---@param combineKey int 默认值:0 连贯播放组合ID（可选，默认为0）
---@return void 
function XDlcCSharpFuncs:PlayDrama(dramaName, referencePos, referenceRot, combineKey)
end

---@desc 播放简易台词
---@desc 枚举文档:https://kurogame.feishu.cn/sheets/JLxYs1gwShWf25tBScrc9xqqngd?sheet=3zVYsP
---@param captionName string 简易台词名字
---@param isSequential bool 默认值:false 是否采用流水线播放模式
---@return void 
function XDlcCSharpFuncs:PlayDramaCaption(captionName, isSequential)
end

---@desc 播放插卡字幕
---@param actorType int ETargetActorType
---@param uuid int
---@param bubbleName string
---@return void 
function XDlcCSharpFuncs:PlayDramaBubble(actorType, uuid, bubbleName)
end

---@desc 停止气泡
---@param actorType int ETargetActorType
---@param uuid int
---@return void 
function XDlcCSharpFuncs:StopDramaBubble(actorType, uuid)
end

---@desc 设置任务剧情选项显示列表
---@param questId int
---@param dramaName string
---@param decisionNodeId int
---@param optionShowList List<int>
---@return void 
function XDlcCSharpFuncs:SetQuestDecisionDialogShowList(questId, dramaName, decisionNodeId, optionShowList)
end

---@desc 设置npc剧情选项显示列表
---@param npcUUID int
---@param decisionNodeId int
---@param optionShowList List<int> 填选项Id的列表
---@return void 
function XDlcCSharpFuncs:SetNpcDecisionDialogShowList(npcUUID, decisionNodeId, optionShowList)
end

---@desc 获取某个节点第一次选的选项Id
---@param nodeId int ClipId
---@return int 
function XDlcCSharpFuncs:GetDramaDialogFirstDecisionId(nodeId)
end

---@desc 获取某个节点所有选择过的选项Id（有循环跳转的时候，一个分歧会被选择多次）
---@param nodeId int
---@return LuaTable 
function XDlcCSharpFuncs:GetDramaDialogDecisionIdList(nodeId)
end

---@desc 是否有正在播放的Drama
---@return bool 
function XDlcCSharpFuncs:HasRunningDrama()
end

---@desc 开关锚点UI
---@param soPlaceId int
---@param active bool
---@return void 
function XDlcCSharpFuncs:SetSpearPointUiActive(soPlaceId, active)
end

---@desc 设置锚点UI进度
---@param soPlaceId int
---@param progress float
---@return void 
function XDlcCSharpFuncs:SetSpearPointUiProgress(soPlaceId, progress)
end

---@desc 显示提示
---@param id int
---@param var int
---@return void 
function XDlcCSharpFuncs:ShowTip(id, var)
end

---@desc 关闭提示
---@param id int
---@return void 
function XDlcCSharpFuncs:CloseTip(id)
end

---@desc 显示战斗引导
---@param id int 引自Table\Client\StatusSyncFight\FightGuideStepDLC.tab
---@return void 
function XDlcCSharpFuncs:ShowGuide(id)
end

---@desc 关闭战斗引导,包括Relink
---@return void 
function XDlcCSharpFuncs:HideGuide()
end

---@desc 显示Relink引导
---@param id int
---@param type int
---@return void 
function XDlcCSharpFuncs:ShowDlcGuide(id, type)
end

---@desc 手动触发系统引导开启检查
---@return void 
function XDlcCSharpFuncs:TryActiveSystemGuide()
end

---@desc 显隐指定UI界面
---@param uiIndex int UI界面索引
---@param active bool 是否显示
---@return void 
function XDlcCSharpFuncs:SetUiActive(uiIndex, active)
end

---@desc 显隐指定UI界面下某个部件
---@param uiIndex int UI界面索引
---@param widgetKey int UI界面内部件编号
---@param active bool 是否显示
---@return void 
function XDlcCSharpFuncs:SetUiWidgetActive(uiIndex, widgetKey, active)
end

---@desc 设置是否允许Npc使用顶部血条
---@param npcId int
---@param enable bool
---@return void 
function XDlcCSharpFuncs:SetNpcTopHpEnable(npcId, enable)
end

---@desc 开关动态血条
---@param npcId int npc对象唯一ID
---@param show bool true开，false关
---@return void 
function XDlcCSharpFuncs:ShowDynamicHpBar(npcId, show)
end

---@desc 开关Npc头顶标识信息
---@param npcId int
---@param active bool
---@return void 
function XDlcCSharpFuncs:SetNpcTopInfoActive(npcId, active)
end

---@desc 开关假结算（黑白龙转场演出用
---@param active bool
---@return void 
function XDlcCSharpFuncs:SetFakeSettleActive(active)
end

---@desc 显示CV提示
---@param npcId int
---@param npcUUId int
---@param actionId int
---@return void 
function XDlcCSharpFuncs:ShowCvTips(npcId, npcUUId, actionId)
end

---@desc 显示关卡信息
---@param textId int 信息对应的string的ID
---@param processId int 进度对应的string的ID
---@param sortPosition int 放置位置
---@param isComplete bool 是否完成
---@param textArgs LuaTable 默认值:null
---@param processArgs LuaTable 默认值:null
---@return void 
function XDlcCSharpFuncs:ShowStageInfo(textId, processId, sortPosition, isComplete, textArgs, processArgs)
end

---@desc 打开通用黑幕特效
---@param enterDuration float 进入黑幕时长(单位/s)
---@param exitDuration float 退出黑幕时长(单位/s)
---@return void 
function XDlcCSharpFuncs:PlayBlackScreenEffect(enterDuration, exitDuration)
end

---@desc 播放屏幕特效(控制时长)【注】引用的屏幕特效需要添加脚本资源依赖表
---@param screenEffectId int 屏幕特效Id，引自Product\Table\Client\StatusSyncFight\ScreenEffect.tab
---@param enterDuration float 特效渐入时长(单位/s)
---@param exitDuration float 特效渐出时长(单位/s)
---@return void 
function XDlcCSharpFuncs:PlayScreenEffectById(screenEffectId, enterDuration, exitDuration)
end

---@desc 播放持续屏幕特效(不控制时长), 需要使用KillStayScreenEffectById关闭【注】引用的屏幕特效需要添加脚本资源依赖表
---@param screenEffectId int 屏幕特效Id，引自Product\Table\Client\StatusSyncFight\ScreenEffect.tab
---@return void 
function XDlcCSharpFuncs:PlayStayScreenEffectById(screenEffectId)
end

---@desc 卸载屏幕特效(不控制时长)
---@param screenEffectId int 屏幕特效Id，引自Product\Table\Client\StatusSyncFight\ScreenEffect.tab
---@return void 
function XDlcCSharpFuncs:KillStayScreenEffectById(screenEffectId)
end

---@desc 为指定关卡物体播放特效
---@param sceneObjectPlaceId int 关卡物体的PlaceId
---@param effectName string 特效名
---@param posOffset Vector3 特效位置偏移
---@param rotOffset Vector3 特效旋转偏移
---@param scale Vector3 特效缩放
---@param partNames string[] 默认值:null 在指定部位播放的部位列表
---@return void 
function XDlcCSharpFuncs:BindSceneObjectEffect(sceneObjectPlaceId, effectName, posOffset, rotOffset, scale, partNames)
end

---@desc 为指定关卡物体移除特效
---@param sceneObjectPlaceId int 关卡物体的PlaceId
---@param effectName string 特效名
---@return void 
function XDlcCSharpFuncs:UnBindSceneObjectEffect(sceneObjectPlaceId, effectName)
end

---@desc 为指定关卡Npc播放特效
---@param npcPlaceId int 关卡Npc的PlaceId
---@param effectName string 特效名
---@param posOffset Vector3 特效位置偏移
---@param rotOffset Vector3 特效旋转偏移
---@param scale Vector3 特效缩放
---@param partNames string[] 默认值:null 在指定部位播放的部位列表
---@return void 
function XDlcCSharpFuncs:BindNpcEffect(npcPlaceId, effectName, posOffset, rotOffset, scale, partNames)
end

---@desc 为指定关卡Npc移除特效
---@param npcPlaceId int 关卡Npc的PlaceId
---@param effectName string 特效名
---@return void 
function XDlcCSharpFuncs:UnBindNpcEffect(npcPlaceId, effectName)
end

---@desc 设置关卡实体所有空间音效开关
---@param actorType int 枚举,参考ETargetActorType,默认为空不起效
---@param placeId int 关卡实体PlaceId
---@param active bool
---@return void 
function XDlcCSharpFuncs:SetActorAllSpaceAudioActive(actorType, placeId, active)
end

---@desc 设置关卡实体一个空间音效开关
---@param actorType int 枚举,参考ETargetActorType,默认为空不起效
---@param placeId int 关卡实体PlaceId
---@param index int
---@param active bool
---@return void 
function XDlcCSharpFuncs:SetActorOneSpaceAudioActive(actorType, placeId, index, active)
end

---@desc 播放背景音乐
---@desc 参考文档：【需求】V2.13 音频需求对接-音频战斗控制逻辑相关(2024.02.29) -【2.3 BGM相关】
---@param cueId int 音频文件id
---@param stopDuration float 默认值:-1 本次播放的BGM停止时其声音降低所需时间
---@param startTime float 默认值:-1 本次播放的起始时刻（相对于音频时间长度）
---@param endTime float 默认值:-1 本次播放的截止时刻（相对于音频时间长度）
---@param lastFor float 默认值:-1 本次播放持续多久时间
---@param fadeIn float 默认值:0 即将播放的BGM淡入的时间
---@param fadeOut float 默认值:0 :当前BGM淡出的时间
---@return void 
function XDlcCSharpFuncs:PlayMusicInOut(cueId, stopDuration, startTime, endTime, lastFor, fadeIn, fadeOut)
end

---@desc 以平滑过渡形式修改BGM的aisac参数
---@param controlName string aisac参数名
---@param targetValue float 目标值
---@param startValue float 默认值:-1 起始值
---@param curveTime float 默认值:-1 过渡时间
---@return void 
function XDlcCSharpFuncs:ChangeMusicAisacTween(controlName, targetValue, startValue, curveTime)
end

---@desc 设置音频音量控制模式（默认乘法合并）
---@param mode int 0:不控制1:乘法合并2:取最高值3:取最低值4:取优先级
---@return void 
function XDlcCSharpFuncs:SetAudioVolumeControlMode(mode)
end

---@desc 音频音量调整
---@param volumeController int 发起来源,参考FightAudio.FightAudioControllerType
---@param audioType int 音频类型引自XAudioManager.PlayType,1:音乐2:音效4:CV
---@param volume float 音量
---@param curveTime float 过渡时长
---@return void 
function XDlcCSharpFuncs:ChangeAudioVolume(volumeController, audioType, volume, curveTime)
end

---@desc 设置音频开关控制模式（默认与逻辑,指多方权限分配: 关卡控制、角色控制、怪物控制, 详细参考主线音频控制行为树节点）
---@param mode int 0:不控制1:与逻辑2:或逻辑3:优先级
---@return void 
function XDlcCSharpFuncs:SetAudioSwitchControlMode(mode)
end

---@desc 设置音频是否开启
---@param volumeController int 发起来源,参考FightAudio.FightAudioControllerType
---@param audioType int 音频类型引自XAudioManager.PlayType,1:音乐2:音效4:CV
---@param isOpen bool 是否开启
---@return void 
function XDlcCSharpFuncs:ChangeAudioEnable(volumeController, audioType, isOpen)
end

---@desc 播放Bgm
---@param controllerType int 发起来源,参考FightAudio.FightAudioOperationControllerType
---@param cueId int BgmcueId
---@param startTime float 将播放Bgm的起始时间
---@param endTime float 音频截止功能：将播放Bgm的截止时间
---@param stopDuration float 音频截止功能：将播放Bgm停止时声音淡出时间
---@param lastFor float 音频截止功能：将播放Bgm的的累计播放时间,设置此BGM循环播放时长,若填写startTime和endTime,循环以填入时间戳为准,若均为0则默认整首循环
---@param fadeInDuration float 将播放Bgm淡入时长
---@param fadeOutDuration float 被切换Bgm淡出时长
---@param isCrossFade bool 是否是交叉淡入淡出,交叉淡入淡出是CriWare的功能和fade不同,开启后表示使用CriWare的交叉淡出功能，否则是普通的淡入淡出
---@return void 
function XDlcCSharpFuncs:PlayFightAudioBgm(controllerType, cueId, startTime, endTime, stopDuration, lastFor, fadeInDuration, fadeOutDuration, isCrossFade)
end

---@desc 播放音效
---@param cueId int
---@param actorType int 默认值:0 枚举,参考ETargetActorType,默认为空不起效,3D音效效果需要选定一个物体
---@param actorId int 默认值:0 npc或SceneObj的uuid,默认为0不起效
---@param duration float 默认值:-1 基于tween渐入,默认为-1不起效
---@param stopDuration float 默认值:-1 基于自动stop(一定要配合endtime和lastFor)的渐出,默认为-1不起效
---@param startTime float 默认值:-1 【Cri参数】从cue的指定ms开始播放,默认为-1不起效
---@param endTime float 默认值:-1 【Cri参数】在cue的指定ms结束播放,默认为-1不起效
---@param lastFor float 默认值:-1 在累计播放该ms时间后自动stop,默认为-1不起效
---@param attack float 默认值:-1 【Cri参数】,默认为-1不起效
---@param release float 默认值:-1 【Cri参数】,默认为-1不起效
---@return int AudioId, 用以进行暂停、恢复、停止、调节音量
function XDlcCSharpFuncs:PlaySound(cueId, actorType, actorId, duration, stopDuration, startTime, endTime, lastFor, attack, release)
end

---@desc 通过AudioUid设置音频音量
---@param audioId int
---@param volume float
---@return void 
function XDlcCSharpFuncs:ChangeAudioVolumeByUid(audioId, volume)
end

---@desc 通过AudioUid暂停音频
---@param audioUid int
---@return void 
function XDlcCSharpFuncs:PauseAudioByUid(audioUid)
end

---@desc 通过AudioUid恢复音频
---@param audioId int
---@return void 
function XDlcCSharpFuncs:ResumeAudioByUid(audioId)
end

---@desc 通过AudioUid停止音频
---@param audioUid int
---@return void 
function XDlcCSharpFuncs:StopAudioByUid(audioUid)
end

---@desc 停止Bgm
---@param controllerType int 发起来源,参考FightAudio.FightAudioOperationControllerType
---@param cueId int BgmcueId
---@return void 
function XDlcCSharpFuncs:StopFightAudioBgm(controllerType, cueId)
end

---@desc 暂停当前播放的BGM
---@param controllerType int 发起来源,参考FightAudio.FightAudioOperationControllerType
---@return void 
function XDlcCSharpFuncs:PauseFightAudioBgm(controllerType)
end

---@desc 恢复当前暂停的BGM
---@param controllerType int 发起来源,参考FightAudio.FightAudioOperationControllerType
---@return void 
function XDlcCSharpFuncs:ResumeFightAudioBgm(controllerType)
end

---@desc BGM Block功能开关
---@param isOpen bool
---@return void 
function XDlcCSharpFuncs:SetFightAudioBlockOperationEnable(isOpen)
end

---@desc 初始化BGM Block
---@param blockIndex int
---@return void 
function XDlcCSharpFuncs:InitAudioBlock(blockIndex)
end

---@desc 战斗用切换BGM Block 使用前先调用InitAudioBlock接口
---@param blockIndex int
---@return void 
function XDlcCSharpFuncs:SwitchFightAudioBlockByFight(blockIndex)
end

---@desc 关卡用切换BGM Block 使用前先调用InitAudioBlock接口
---@param blockIndex int
---@return void 
function XDlcCSharpFuncs:SwitchFightAudioBlockByLevel(blockIndex)
end

---@desc 切换BGM Selector
---@param selectorName string 选择器名称
---@param labelName string 标签名称
---@return void 
function XDlcCSharpFuncs:ChangeMusicSelector(selectorName, labelName)
end

---@desc 切换所有音频选择器
---@param selectorName string 选择器名称
---@param labelName string 标签名称
---@return void 
function XDlcCSharpFuncs:SetAllAudioSelector(selectorName, labelName)
end

---@desc 增加QTE时间
---@param time float
---@return void 
function XDlcCSharpFuncs:AddQTETime(time)
end

---@desc 设置在场玩家进入QTE时间（黯角boss战专用） 参数分别是第几位成员进入QTE增加的时间
---@param time1 float
---@param time2 float
---@param time3 float
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
---@param opKey int 参考枚举ENpcOperationKey
---@return bool 
function XDlcCSharpFuncs:IsKeyDown(opKey)
end

---@desc 检测按键是否长按
---@param opKey int
---@return bool , float time:长按时间
function XDlcCSharpFuncs:IsKeyHold(opKey)
end

---@desc 检测按键是否抬起
---@param opKey int
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
---@param delta int 分数变化量
---@return void 
function XDlcCSharpFuncs:ChangeRubikTeamScore(delta)
end

---@desc 获取当前团队分数
---@return int 
function XDlcCSharpFuncs:GetRubikTeamScore()
end

---@desc 修改玩家分数
---@param playerNpcId int 玩家Npc的UUID
---@param delta int 分数变化量
---@return void 
function XDlcCSharpFuncs:ChangeRubikPlayerScore(playerNpcId, delta)
end

---@desc 获取玩家分数
---@param playerNpcId int 玩家Npc的UUID
---@return int 
function XDlcCSharpFuncs:GetRubikPlayerScore(playerNpcId)
end

---@desc 设置玩家猫鼠阵营
---@param npcId int true为猫
---@param isCat bool false为鼠
---@return void 
function XDlcCSharpFuncs:SetMouseHunterPlayerCamp(npcId, isCat)
end

---@desc 设置玩家积分
---@param npcId int
---@param score int
---@return void 
function XDlcCSharpFuncs:SetMouseHunterPlayerScore(npcId, score)
end

---@desc 设置猫的捕鼠数量
---@param npcId int
---@param huntCount int
---@return void 
function XDlcCSharpFuncs:SetCatHuntCount(npcId, huntCount)
end

---@desc 设置老鼠存活时间
---@param npcId int
---@param liveTime int 秒
---@return void 
function XDlcCSharpFuncs:SetMouseAliveTime(npcId, liveTime)
end

---@desc 设置老鼠数量
---@param liveCount int 当前存活老鼠数量
---@param totalCount int 总共的老鼠数量（不论死活）
---@return void 
function XDlcCSharpFuncs:SetPlayerMouseCount(liveCount, totalCount)
end

---@desc 创建老鼠变身选项列表
---@param npcId int
---@param reserveOptionsTable LuaTable 关卡预定的变身选项列表（包含与出生地关联的几个变身选项）
---@return void 
function XDlcCSharpFuncs:CreateMouseTransformOptionList(npcId, reserveOptionsTable)
end

---@desc 开关猫鼠阵营提示
---@desc 该方法会自动判断调用的客户端玩家阵营，显示对应的阵营图标。
---@param tipId int FightTips表中配置的ID
---@return void 
function XDlcCSharpFuncs:ShowMouseHunterCampTip(tipId)
end

---@desc 生成道具
---@param key int
---@param position Vector3
---@return void 
function XDlcCSharpFuncs:GenerateMouseHunterItem(key, position)
end

---@desc 根据子弹UUID获取对应的道具key
---@param missileUUID int
---@return int 
function XDlcCSharpFuncs:MouseHunterGetItemKey(missileUUID)
end

---@desc 获取玩家的阵营。[玩家ID] = 阵营  1为猫2为鼠
---@return LuaTable 
function XDlcCSharpFuncs:MouseHunterGetCatCampIndex()
end

---@desc 设置技能CD
---@param skillId int
---@param skillCD float
---@return void 
function XDlcCSharpFuncs:MouseHunterSetSkillCD(skillId, skillCD)
end

---@desc 躲猫猫设置技能最大使用次数
---@param skillId int 要设置的技能Id
---@param value int 最大使用次数
---@return void 
function XDlcCSharpFuncs:MouseHunterSetSkillMaxAvailableTimes(skillId, value)
end

---@desc 躲猫猫设置技能单次充能次数（仅关卡主控端调用）
---@param skillId int 要设置的技能Id
---@param chargeTimesValue int 单次充能补充的使用次数
---@return void 
function XDlcCSharpFuncs:MouseHunterSetSkillChargeTimes(skillId, chargeTimesValue)
end

---@desc 躲猫猫增加技能可用次数（仅关卡主控端调用）
---@param npcUUID int
---@return void 
function XDlcCSharpFuncs:MouseHunterChargeSkillAvailableTimes(npcUUID)
end

---@desc 躲猫猫完全恢复指定 Npc 的技能可用次数（仅关卡主控端初始化调用）
---@param npcUUID int
---@return void 
function XDlcCSharpFuncs:MouseHunterFullRecoverySkillCurAvailableTimes(npcUUID)
end

---@desc 躲猫猫设置猫的奶酪数量
---@param curCount int 当前已收集数量
---@param targetCount int 目标收集数量
---@return void 
function XDlcCSharpFuncs:MouseHunterSetCatCheeseCount(curCount, targetCount)
end

---@desc 躲猫猫设置猫奶酪效果状态
---@param state int 目标状态：1-累积中2-激活中3-冷却中
---@param duration float 持续时间
---@return void 
function XDlcCSharpFuncs:MouseHunterSetCatCheeseEffectState(state, duration)
end

---@desc 躲猫猫设置鼠奶酪信息
---@param npcUUID int 鼠UUID
---@param curBringCount int 当前携带数量
---@param maxBringCount int 最大携带数量
---@param scoreFactor float 分数倍率
---@param moveSpeedAddPercent float 移速加成百分比
---@return void 
function XDlcCSharpFuncs:MouseHunterSetMouseCheeseData(npcUUID, curBringCount, maxBringCount, scoreFactor, moveSpeedAddPercent)
end

---@desc 躲猫猫设置拾取状态
---@param npcUUID int UUID
---@param isTaking bool 是否正在拾取
---@param duration float 默认值:0 拾取时间
---@return void 
function XDlcCSharpFuncs:MouseHunterSetTakingStatus(npcUUID, isTaking, duration)
end

---@desc 躲猫猫添加道具箱拾取状态
---@param itemBoxPlaceId int 道具箱PlaceId
---@param npcUUID int 拾取NpcUUID
---@param takingDuration float 拾取时间
---@return void 
function XDlcCSharpFuncs:MouseHunterAddItemBoxTakingState(itemBoxPlaceId, npcUUID, takingDuration)
end

---@desc 躲猫猫移除道具箱拾取状态
---@param itemBoxPlaceId int 道具箱PlaceId
---@param npcUUID int 拾取NpcUUID
---@return void 
function XDlcCSharpFuncs:MouseHunterRemoveItemBoxTakingState(itemBoxPlaceId, npcUUID)
end

---@desc 躲猫猫通知目标玩家创建不需要参数的提示
---@param uuid int
---@param tipId int
---@return void 
function XDlcCSharpFuncs:MouseHunterShowTipWithoutArg(uuid, tipId)
end

---@desc 躲猫猫通知玩家创建需要一个整形参数的提示
---@param uuid int
---@param tipId int
---@param arg0 int
---@return void 
function XDlcCSharpFuncs:MouseHunterShowTipWithoutOneArg(uuid, tipId, arg0)
end

---@desc 躲猫猫通知对局结束
---@return void 
function XDlcCSharpFuncs:MouseHunterNotifyEndMatch()
end

---@desc 检查任务目标进度是否完成
---@param objectiveId int
---@return bool 
function XDlcCSharpFuncs:IsQuestObjectiveFinished(objectiveId)
end

---@desc 检查任务目标是否未激活
---@param objectiveId int
---@return bool 
function XDlcCSharpFuncs:IsQuestObjectiveInActive(objectiveId)
end

---@desc 检查是否在任务内
---@param questId int
---@return bool 
function XDlcCSharpFuncs:IsInQuest(questId)
end

---@desc 检查系统条件是否达成
---@param conditionId int
---@return bool 
function XDlcCSharpFuncs:CheckSystemCondition(conditionId)
end

---@desc 设置系统功能开放或屏蔽
---@param systemFunctionType ESystemFunctionType 系统功能类型枚举
---@param enable bool 是否开放
---@return void 
function XDlcCSharpFuncs:SetSystemFuncEntryEnable(systemFunctionType, enable)
end

---@desc 设置一批系统功能开放或屏蔽
---@param enableList List<int> 开放的系统功能类型枚举数组
---@param disableList List<int> 屏蔽的系统功能类型枚举数组
---@return void 
function XDlcCSharpFuncs:SetSystemFuncEntryEnableBatch(enableList, disableList)
end

---@desc 控制具体的系统功能状态
---@param systemFunctionType ESystemFunctionType 系统功能类型枚举
---@param args List<object> 控制参数（参数由关卡和系统共同协商，系统定制化解析）例如：关卡要控制小地图是否可以点击打开大地图，控制是否可以进行地图传送等。
---@return void 
function XDlcCSharpFuncs:ControlSystemFunction(systemFunctionType, args)
end

---@desc 设置玩家第一人称模式
---@param isFirstPersonMode bool 第一人称模式
---@return void 
function XDlcCSharpFuncs:SetPlayerFirstPersonMode(isFirstPersonMode)
end

---@desc 弹出第一人称设置UI
---@param isShowClose bool 是否显示关闭按钮
---@param titleTextKey string 标题文本TextKey
---@return void 
function XDlcCSharpFuncs:OpenSetPersonModeUI(isShowClose, titleTextKey)
end

---@desc 获取当前第一人称模式和状态
---@return bool 第一人称模式, bool state:(第二返回值)第一人称状态
function XDlcCSharpFuncs:GetPlayerFirstPersonModeAndState()
end

---@desc 获取玩家在指定关卡中保存的人称模式数据
---@param levelId int 关卡Id
---@return bool , bool mode:是否是第一人称模式
function XDlcCSharpFuncs:GetSavedPlayerFirstPersonState(levelId)
end

---@desc 打开【玩家自定义外观】的UI
---@return void 
function XDlcCSharpFuncs:ShowPlayerDIYUI()
end

---@desc 发送短信
---@param messageId int
---@return void 
function XDlcCSharpFuncs:SendChatMessage(messageId)
end

---@desc 显示大世界图文教学
---@param teachId int
---@return void 
function XDlcCSharpFuncs:ShowBigWorldTeach(teachId)
end

---@desc 在空花下打开玩法入口并推进相机到指定位置
---@param bigWorldActivityId int
---@param args object[]
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
---@param camParamId int
---@param npcPlaceIdList List<int>
---@param sceneObjectPlaceIdList List<int>
---@return void 
function XDlcCSharpFuncs:OpenGameplayPhotograph(camParamId, npcPlaceIdList, sceneObjectPlaceIdList)
end

---@desc 获取自走棋Npc自动模式
---@param uuid int npcId
---@return bool 
function XDlcCSharpFuncs:GetAutoChessNpcAutoMode(uuid)
end

---@desc 设置自走棋技能冷却显示
---@param uuid int npcId
---@param id int 技能ID
---@param current float 当前进度
---@param max float 最大进度
---@return void 
function XDlcCSharpFuncs:SetAutoChessSkillData(uuid, id, current, max)
end

---@desc 设置自走棋技能队列状态
---@param uuid int npcId
---@param id int 技能ID
---@return void 
function XDlcCSharpFuncs:SetAutoChessSkillTriggerState(uuid, id)
end

---@desc 设置自走棋技能释放状态
---@param uuid int npcId
---@param id int 技能ID
---@return void 
function XDlcCSharpFuncs:SetAutoChessSkillActiveState(uuid, id)
end

---@desc 设置自走棋宝石冷却显示
---@param uuid int npcId
---@param id int 宝石ID
---@param current float 当前进度
---@param max float 最大进度
---@return void 
function XDlcCSharpFuncs:SetAutoChessGemData(uuid, id, current, max)
end

---@desc 设置自走棋宝珠触发状态
---@param uuid int npcId
---@param id int 技能ID
---@return void 
function XDlcCSharpFuncs:SetAutoChessGemTriggerState(uuid, id)
end

---@desc 设置自走棋宝珠持续生效状态
---@param uuid int npcId
---@param id int 技能ID
---@return void 
function XDlcCSharpFuncs:SetAutoChessGemActiveState(uuid, id)
end

---@desc 打开自走棋疲劳UI
---@return void 
function XDlcCSharpFuncs:ShowAutoChessTriedMessageTip()
end

---@desc 打开自走棋倒计时UI
---@param seconds int
---@return void 
function XDlcCSharpFuncs:ShowAutoChessCountDownMessageTip(seconds)
end

---@desc 获取自走棋Npc
---@param self bool 是否自身
---@return int 
function XDlcCSharpFuncs:GetAutoChessNpc(self)
end

---@desc 添加自走棋宝珠触发次数
---@param npcId int
---@param gemId int
---@param value int
---@return void 
function XDlcCSharpFuncs:AddAutoChessGemTriggerRecord(npcId, gemId, value)
end

---@desc TODO 自走棋调试用 绑定UI
---@param uuid int npcId
---@param self bool 是否自身
---@return void 
function XDlcCSharpFuncs:SetAutoChessNpcUi(uuid, self)
end

---@desc 获取自走棋角色配置ID
---@param uuid int
---@return int 
function XDlcCSharpFuncs:GetAutoChessCharacterId(uuid)
end

---@desc 设置自走棋UI显隐动画
---@param active bool
---@param animName string
---@return void 
function XDlcCSharpFuncs:SetAutoChessUiActive(active, animName)
end

---@desc 设置自走棋计时器UI显隐
---@param active bool
---@param offset int
---@return void 
function XDlcCSharpFuncs:SetAutoChessTimerTipsActive(active, offset)
end

---@desc 根据SkillId获取技能配置
---@param id int
---@return XTable.XTableTheatre5ItemSkill 
function XDlcCSharpFuncs:GetAutoChessSkillConfig(id)
end

---@desc 根据MagicId获取技能配置
---@param id int
---@return XTable.XTableTheatre5ItemSkill 
function XDlcCSharpFuncs:GetAutoChessSkillConfigByMagicId(id)
end

---@desc 获取角色配置
---@param id int
---@return XTable.XTableTheatre5Character 
function XDlcCSharpFuncs:GetAutoChessCharacterConfig(id)
end

---@desc 获取宝珠配置
---@param id int
---@return XTable.XTableTheatre5ItemRune 
function XDlcCSharpFuncs:GetAutoChessRuneConfig(id)
end

---@desc 赛后结算MagicId映射到SkillId
---@param magicId int
---@param skillId int
---@return void 
function XDlcCSharpFuncs:MagicIdToSkillIdMapping(magicId, skillId)
end

---@desc 设置连携玩法激活
---@param active bool 是否激活
---@return void 
function XDlcCSharpFuncs:SetGameplayFullChainActive(active)
end

---@desc 获取连携技能上下文数据
---@return LuaTable 
function XDlcCSharpFuncs:GetFullChainContext()
end

---@desc 获取锁定破韧状态
---@param uuid int
---@return bool 
function XDlcCSharpFuncs:GetNpcInBrokenState(uuid)
end

---@desc 获取锁定削韧状态
---@param uuid int
---@return bool 
function XDlcCSharpFuncs:GetNpcInBreakState(uuid)
end

---@desc 获取韧性状态
---@param uuid int
---@return int 
function XDlcCSharpFuncs:GetNpcBreakState(uuid)
end

---@desc 获取韧性值
---@param uuid int
---@return int , int max:最大值
function XDlcCSharpFuncs:GetNpcBreakGauge(uuid)
end

---@desc 设置韧性值
---@param uuid int
---@param value int
---@param condition ENpcBreakStateCondition
---@return bool 
function XDlcCSharpFuncs:SetNpcBreakGauge(uuid, value, condition)
end

---@desc 设置击破/韧性条激活状态
---@param uuid int
---@param active bool
---@return void 
function XDlcCSharpFuncs:SetNpcBreakGaugeActive(uuid, active)
end

---@desc 设置OverDrive激活状态
---@param uuid int
---@param active bool
---@return void 
function XDlcCSharpFuncs:SetNpcOverDriveActive(uuid, active)
end

---@desc 获取Npc OverDrive 状态
---@param uuid int
---@return ENpcOverDriveState 
function XDlcCSharpFuncs:GetNpcOverDriveState(uuid)
end

---@desc 开关团队极限技玩法
---@param enable bool
---@param maxEnergy int 能量上限
---@param chainLimitTime float 连续释放判定最大时间间隔
---@return void 
function XDlcCSharpFuncs:SetTeamWorkSkillActive(enable, maxEnergy, chainLimitTime)
end

---@desc 消耗团队极限技能量
---@param npcUUID int
---@param energy int
---@param skillId int
---@return void 
function XDlcCSharpFuncs:CastTeamWorkEnergy(npcUUID, energy, skillId)
end

---@desc 添加团队极限技能量
---@param npcUUID int
---@param energy int
---@return void 
function XDlcCSharpFuncs:AddTeamWorkEnergy(npcUUID, energy)
end

---@desc 设置团队极限技能量
---@param npcUUID int
---@param energy int
---@return void 
function XDlcCSharpFuncs:SetTeamWorkEnergy(npcUUID, energy)
end

---@desc 清除团队极限技能量
---@param npcUUID int
---@return void 
function XDlcCSharpFuncs:CleanTeamWorkEnergy(npcUUID)
end

---@desc 获取团队极限机能量
---@param npcUUID int
---@return int 
function XDlcCSharpFuncs:GetTeamWorkEnergy(npcUUID)
end

---@desc 获取团队极限机最大能量
---@return int 
function XDlcCSharpFuncs:GetTeamWorkMaxEnergy()
end

---@desc 设置Npc团队极限技可用次数
---@param npcUUID int
---@param count int
---@return void 
function XDlcCSharpFuncs:SetTeamWorkSkillNpcRemainUseCount(npcUUID, count)
end

---@desc 获取Npc团队极限技可用次数
---@param npcUUID int
---@return int 
function XDlcCSharpFuncs:GetTeamWorkSkillNpcRemainUseCount(npcUUID)
end

---@desc 开启角力
---@param launcherNpcUUID int 发起者UUID
---@param targetNpcUUID int 目标UUID
---@param wrestleId int 角力配置ID
---@return void 
function XDlcCSharpFuncs:CastWrestle(launcherNpcUUID, targetNpcUUID, wrestleId)
end

---@desc 开启多人弹刀
---@param launcherNpcUUID int 发起者UUID
---@param targetNpcUUID int 目标UUID
---@param id int 多人弹刀配置ID
---@return void 
function XDlcCSharpFuncs:CastMultiParry(launcherNpcUUID, targetNpcUUID, id)
end

---@desc 关卡专用操作按键开关
---@param operationKey int 操作Id
---@param npcId int npcId
---@param state bool 开关状态
---@return void 
function XDlcCSharpFuncs:SetLevelButtonOpEnabled(operationKey, npcId, state)
end

---@desc 怪物专用操作按键开关
---@param operationKey int 操作Id
---@param npcId int npcId
---@param state bool 开关状态
---@return void 
function XDlcCSharpFuncs:SetMonsterButtonOpEnabled(operationKey, npcId, state)
end

---@desc 玩家专用操作按键开关
---@param operationKey int 操作Id
---@param npcId int npcId
---@param state bool 开关状态
---@return void 
function XDlcCSharpFuncs:SetPlayerButtonOpEnabled(operationKey, npcId, state)
end

---@desc Npc专用操作按键开关
---@param operationKey int 操作Id
---@param npcId int npcId
---@param state bool 开关状态
---@return void 
function XDlcCSharpFuncs:SetNpcButtonOpEnabled(operationKey, npcId, state)
end

---@desc 关卡专用操作按键显隐
---@param uiType int ui类型
---@param operationKey int 操作按键
---@param npcId int npcId
---@param uiState int ui状态(1:显示，2：隐藏但可以点击，3：未启用)
---@return void 
function XDlcCSharpFuncs:SetLevelOperationUiState(uiType, operationKey, npcId, uiState)
end

---@desc 怪物专用操作按键显隐
---@param uiType int ui类型
---@param operationKey int 操作按键
---@param npcId int npcId
---@param uiState int ui状态(1:显示，2：隐藏但可以点击，3：未启用)
---@return void 
function XDlcCSharpFuncs:SetMonsterOperationUiState(uiType, operationKey, npcId, uiState)
end

---@desc 玩家专用操作按键显隐
---@param uiType int ui类型
---@param operationKey int 操作按键
---@param npcId int npcId
---@param uiState int ui状态(1:显示，2：隐藏但可以点击，3：未启用)
---@return void 
function XDlcCSharpFuncs:SetPlayerOperationUiState(uiType, operationKey, npcId, uiState)
end

---@desc Npc专用操作按键显隐
---@param uiType int ui类型
---@param operationKey int 操作按键
---@param npcId int npcId
---@param uiState int ui状态(1:显示，2：隐藏但可以点击，3：未启用)
---@return void 
function XDlcCSharpFuncs:SetNpcOperationUiState(uiType, operationKey, npcId, uiState)
end

---@desc 关卡专用Ui显隐
---@param uiType int ui类型
---@param npcId int npcId
---@param uiState int ui状态(1:显示，2：隐藏但可以点击，3：未启用)
---@return void 
function XDlcCSharpFuncs:SetLevelUiState(uiType, npcId, uiState)
end

---@desc 怪物专用Ui显隐
---@param uiType int ui类型
---@param npcId int npcId
---@param uiState int ui状态(1:显示，2：隐藏但可以点击，3：未启用)
---@return void 
function XDlcCSharpFuncs:SetBossUiState(uiType, npcId, uiState)
end

---@desc 玩家专用Ui显隐
---@param uiType int ui类型
---@param npcId int npcId
---@param uiState int ui状态(1:显示，2：隐藏但可以点击，3：未启用)
---@return void 
function XDlcCSharpFuncs:SetPlayerUiState(uiType, npcId, uiState)
end

---@desc Npc专用操作按键显隐
---@param uiType int ui类型
---@param npcId int npcId
---@param uiState int ui状态(1:显示，2：隐藏但可以点击，3：未启用)
---@return void 
function XDlcCSharpFuncs:SetNpcUiState(uiType, npcId, uiState)
end

---@desc 显示快速信息
---@param emojiId int QuickEmoji表中的Id
---@return void 
function XDlcCSharpFuncs:ShowQuickMessage(emojiId)
end

---@desc 发送UI事件
---@param eventId int RelinkSkillTips表中ID
---@param eventType int SendUiEventType枚举中的类型
---@param uuId int 所需的uuId，后可以换成自定义的int
---@return void 
function XDlcCSharpFuncs:SendUIEvent(eventId, eventType, uuId)
end

---@desc 显示机制条
---@param id int 机制ID
---@param currentValue float 当前值
---@param attributeTargetValue float 属性目标值
---@param priority int 默认值:0 优先级
---@param npcUUID int 默认值:0 NpcUUID（用于Npc属性和护盾机制条）
---@param attributeType int 默认值:0 属性类型
---@param isReverseDirection bool 默认值:false 是否为反方向（true为反方向，false为正方向）
---@param autoDestroy bool 默认值:true 是否自动销毁（根据机制条方向和目标值条件自动销毁/关闭机制条）
---@param isSendToOneNpcUUId int 默认值:0 是否向指定UUID单独发送
---@return void 
function XDlcCSharpFuncs:ShowMechanismBar(id, currentValue, attributeTargetValue, priority, npcUUID, attributeType, isReverseDirection, autoDestroy, isSendToOneNpcUUId)
end

---@desc 隐藏机制条
---@param id int 机制ID
---@return void 
function XDlcCSharpFuncs:HideMechanismBar(id)
end

---@desc 清除所有机制条
---@return void 
function XDlcCSharpFuncs:ClearAllMechanismBars()
end

---@desc 在矩形区域内生成泊松盘采样点
---@param width float 区域宽度（X方向）
---@param height float 区域高度（Y方向）
---@param radius float 最小间距r
---@return LuaTable 长度为2的倍数的LuaTable [x1, y1, x2, y2....]
function XDlcCSharpFuncs:PoissonDiscPoints(width, height, radius)
end

---@desc 开始掉落物流程
---@return void 
function XDlcCSharpFuncs:PlayDropEffect()
end

---@desc 播放NpcCV
---@param npcUUID int
---@param npcCvKind int 配置ID
---@param actionId int 行为ID
---@param syncType EAudioLuaFuncSyncType 同步类型
---@return void 
function XDlcCSharpFuncs:PlayNpcCV(npcUUID, npcCvKind, actionId, syncType)
end

---@desc 播放关卡CV
---@param npcCvKind int 配置ID
---@param actionId int 行为ID
---@param syncType EAudioLuaFuncSyncType 同步类型
---@return void 
function XDlcCSharpFuncs:PlayLevelCV(npcCvKind, actionId, syncType)
end

---@desc 设置Npc发声音量
---@param npcUUID int
---@param volume float 音量
---@return void 
function XDlcCSharpFuncs:SetNpcVolume(npcUUID, volume)
end

---@desc 设置关卡发声音量
---@param volume float 音量
---@return void 
function XDlcCSharpFuncs:SetLevelVolume(volume)
end

---@desc 查询Npc是否处于救援状态
---@param npcUUID int
---@return bool 
function XDlcCSharpFuncs:GetNpcIsAid(npcUUID)
end

---@desc 查询所有救援中的Npc
---@param npcUUID int
---@return List<int> 
function XDlcCSharpFuncs:GetNpcAidsList(npcUUID)
end

return XDlcCSharpFuncs;
