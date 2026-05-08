-- 本脚本主要起到对部分【常用多逻辑接口组合】与【常见的复数参数判断】进行二次封装以便调用, 功能作用类似于组合行为树
-- 策划写逻辑时可以先在各自脚本集合成一个方法，然后再可以联系TD/程序看有没有迁移到这里的实际必要 

-- 基础逻辑块分类
-- 以Check为前缀：   做条件判断 return boolean
-- 以Do为前缀：      做逻辑执行 以doData响应具体执行逻辑, 视情况return数据 
-- 以Process为前缀： 对象的一个具体行为, 包含了Check、SelectTodo、Do逻辑, 视情况return数据, 参考Char_3005.lua的ProcessChangeMoveState

XScriptTool = {}

local Vector3 = XMain.IsClient and CS.UnityEngine.Vector3 or CS.HaruMath.Vector3

--region Checker
---检查是否是Npc交互对象
---@param proxy XDlcCSharpFuncs
---@param eventArgs
function XScriptTool.CheckNpcInteractStart(proxy, eventArgs, targetNpcId)
    if proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == targetNpcId and eventArgs.Type == 1 then
        return true
    end
    return false
end
--endregion

--region DoTeleport
---Npc传送(不带转向)
---@param proxy XDlcCSharpFuncs
---@param npcId number
---@param position UnityEngine.Vector3 参考{x=0, y=0, z=0}
---@param isNotEffect boolean 是否不带传送特效
function XScriptTool.DoTeleportNpcPos(proxy, npcId, position, isNotEffect)
    proxy:SetNpcPosition(npcId, position, true) --不转向传送
    if isNotEffect then
        return
    end
    proxy:ApplyMagic(npcId, npcId, 200037, 1) --传送特效
end

---Npc传送(不带转向、带特效、带屏幕特效)
---@param proxy XDlcCSharpFuncs
---@param npcId number
---@param position UnityEngine.Vector3 参考{x=0, y=0, z=0}
---@param blackEnterDuration number 特效渐入时间
---@param blackExitDuration number 特效渐出时间
---@param screenEffectId number 屏幕特效Id, 不配则默认播放黑幕
---@param callBack function 传送回调
function XScriptTool.DoTeleportNpcPosWithBlackScreen(proxy, npcId, position, blackEnterDuration, blackExitDuration, screenEffectId, callBack)
    if not blackEnterDuration then
        blackEnterDuration = 0.5
    end
    if not blackExitDuration then
        blackExitDuration = 0.5
    end
    local teleportFunc = function()
        proxy:SetNpcPosition(npcId, position, true)
        proxy:TeleportResetNpcOnGround(npcId)   -- 重置NPC空中状态为地面, 避免动量保留
        proxy:ApplyMagic(npcId, npcId, 200037, 1)
        if callBack then
            callBack()
        end
    end
    if not screenEffectId then
        screenEffectId = 300011
    end
    proxy:PlayScreenEffectById(screenEffectId, blackEnterDuration, blackExitDuration)
    proxy:AddTimerTask(blackEnterDuration, teleportFunc)
end

---Npc传送(带转向、带特效、带黑幕)
---@param proxy XDlcCSharpFuncs
---@param npcId number
---@param position UnityEngine.Vector3 参考{x=0, y=0, z=0}
---@param rotation UnityEngine.Vector3 参考{x=0, y=0, z=0}
---@param blackEnterDuration number 特效渐入时间
---@param blackExitDuration number 特效渐出时间
---@param screenEffectId number 屏幕特效Id, 不配则默认播放黑幕
---@param callBack function 传送回调
function XScriptTool.DoTeleportNpcPosAndRotWithBlackScreen(proxy, npcId, position, rotation, blackEnterDuration, blackExitDuration, screenEffectId, callBack)
    if blackEnterDuration == nil  then
        blackEnterDuration = 0.5
    end
    if blackExitDuration == nil  then
        blackExitDuration = 0.5
    end
    local teleportFunc = function()
        proxy:SetNpcPosAndRot(npcId, position, rotation, true)
        proxy:TeleportResetNpcOnGround(npcId)   -- 重置NPC空中状态为地面, 避免动量保留
        proxy:ApplyMagic(npcId, npcId, 200037, 1)
        if callBack then
            callBack()
        end
    end
    if not screenEffectId then
        screenEffectId = 300011
    end
    proxy:PlayScreenEffectById(screenEffectId, blackEnterDuration, blackExitDuration)
    proxy:AddTimerTask(blackEnterDuration, teleportFunc)
end
--endregion

--region Quest
---@param proxy StatusSyncFight.XFightScriptProxy
---@param key string
---@param addValue int
---@return int 当前数值
function XScriptTool.AddQuestIntValue(proxy, key, addValue, notCheckLessZero)
    local success, value = proxy:TryGetVarInt(key)
    if success then
        value = value + addValue
        if not notCheckLessZero then
            value = math.max(value, 0)
        end
        proxy:SetVarInt(key, value)
    else
        XLog.Error("[ScriptId:"..proxy.Id.."]任务脚本 添加Int参数失败! Key"..key)
    end
    return value
end
--endregion

--region Quest 跳跳乐
---@param proxy StatusSyncFight.XFightScriptProxy
function XScriptTool.InitJumperVarBlock(proxy)
    -- 分数从零开始
    proxy:SetVarInt(EJumperLevelVarKey.Score, 0)
    -- 死亡次数从零开始
    proxy:SetVarInt(EJumperLevelVarKey.DeathCount, 0)
    -- 吃金币数从零开始
    proxy:SetVarInt(EJumperLevelVarKey.GoldCount, 0)
    -- 星级数量从零开始
    proxy:SetVarInt(EJumperLevelVarKey.StarCount, 0)
    -- 触发保底默认为false
    proxy:SetVarBool(EJumperLevelVarKey.IsTriggerJudge, false)
    -- 触发隐藏路线默认为false
    proxy:SetVarBool(EJumperLevelVarKey.IsTriggerHideRoad, false)
end

---@param proxy StatusSyncFight.XFightScriptProxy
---@return table
function XScriptTool.GetJumperSettleData(proxy, timeRewordScore, questId, objectiveIds, isWin)
    local _, score = proxy:TryGetVarInt(EJumperLevelVarKey.Score)
    local _, deathCount = proxy:TryGetVarInt(EJumperLevelVarKey.DeathCount)
    local _, goldCount = proxy:TryGetVarInt(EJumperLevelVarKey.GoldCount)
    local _, starCount = proxy:TryGetVarInt(EJumperLevelVarKey.StarCount)
    local _, isTriggerJudge = proxy:TryGetVarBool(EJumperLevelVarKey.IsTriggerJudge)
    local _, isTriggerHideRoad = proxy:TryGetVarBool(EJumperLevelVarKey.IsTriggerHideRoad)
    local time = proxy:GetLevelPlayTimerCurTime()
    -- 时间奖励分
    if timeRewordScore ~= nil and timeRewordScore > 0 then
        score = math.floor(score + timeRewordScore - time  * 10)    --最终结算时加上倒计时奖励时间
        proxy:SetVarInt(EJumperLevelVarKey.Score, score)
        XLog.Debug("跳跳乐：结算，分:"..score.." 时间:"..time)
    end
    -- 三星
    for i, objectiveId in ipairs(objectiveIds) do
        if proxy:IsQuestObjectiveFinished(objectiveId) then
            starCount = starCount + 1
        end
    end
    proxy:SetVarInt(EJumperLevelVarKey.StarCount, starCount)
    return {
        SettleType = EInstLevelSettleType.Jumper,
        Theme = 1,
        QuestId = questId,
        ObjectiveIds = objectiveIds,
        Score = score,
        PlayTime = time,
        IsWin = isWin,
        DeathCount = deathCount,
        GoldCount = goldCount,
        StarCount = starCount,
        IsTriggerJudge = isTriggerJudge,
        IsTriggerHideRoad = isTriggerHideRoad
    }
end

function XScriptTool.JumperLevelSettle(proxy, timeRewordScore, questId, objectiveIds, isWin, isNotLevelPlay)
    local settleData = XScriptTool.GetJumperSettleData(proxy, timeRewordScore, questId, objectiveIds, isWin)
    proxy:OpenInstLevelSettleUi(EInstLevelSettleType.Jumper, settleData)
    proxy:RecordInstLevelSettleData(EInstLevelSettleType.Jumper, settleData)
    if isWin then
        -- 暂停倒计时
        proxy:PauseLevelPlayTimer()
        if not isNotLevelPlay then
            proxy:CompleteLevelPlay(settleData.StarCount >= 3)
        end
        proxy:FinishInstLevel()
    end
end
--endregion

--region Math
---计算两点距离
---@param posA UnityEngine.Vector3
---@param posB UnityEngine.Vector3
---@return number
function XScriptTool.Distance(posA, posB)
    local num1 = posA.x - posB.x;
    local num2 = posA.y - posB.y;
    local num3 = posA.z - posB.z;
    return math.sqrt(num1 * num1 + num2 * num2 + num3 * num3);
end

---判断向量是否相等
---@param vector1 table {x, y, z}
---@param vector2 table {x, y, z}
---@return boolean
function XScriptTool.EqualVector3(vector1, vector2)
    return vector1.x == vector2.x and vector1.y == vector2.y and vector1.z == vector2.z
end
--endregion

--region 生态AI 日志
---@param script XEcologyCharAIBaseState
function XScriptTool.EcologyError(script, str, ...)
    local placeId = script._proxy:GetNpcPlaceId() or 0
    XLog.Error("[生态构造体AI][PlaceId:"..placeId.."][脚本:"..script._proxy.Id.."]"..tostring(str), ...)
end

---@param script XEcologyCharAIBaseState
function XScriptTool.EcologyWarning(script, str, ...)
    local placeId = script._proxy:GetNpcPlaceId() or 0
    XLog.Warning("[生态构造体AI][PlaceId:"..placeId.."][脚本:"..script._proxy.Id.."]"..tostring(str), ...)
end

---@param script XEcologyCharAIBaseState
function XScriptTool.EcologyDebug(script, str, ...)
    local placeId = script._proxy:GetNpcPlaceId() or 0
    XLog.Debug("[生态构造体AI][PlaceId:"..placeId.."][脚本:"..script._proxy.Id.."]"..tostring(str), ...)
end
--endregion