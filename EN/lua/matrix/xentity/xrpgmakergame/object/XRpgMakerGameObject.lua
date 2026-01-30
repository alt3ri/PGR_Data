local XRpgMakerGamePosition = require("XEntity/XRpgMakerGame/XRpgMakerGamePosition")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule
local LookRotation = CS.UnityEngine.Quaternion.LookRotation

local Default = {
    _Id = 0,
}

local MoveSpeed = CS.XGame.ClientConfig:GetInt("RpgMakeGameMoveSpeed")
local DieByTrapTime = CS.XGame.ClientConfig:GetInt("RpgMakerGameDieByTrapTime") / 1000  --掉入陷阱动画时长


---推箱子物体对象
---@class XRpgMakerGameObject : XRpgMakerGamePosition
local XRpgMakerGameObject = XClass(XRpgMakerGamePosition, "XRpgMakerGameObject")

function XRpgMakerGameObject:Ctor(id, gameObject)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Id = id
    self.ModelPath = nil    --模型路径
    self.ModelRoot = nil    --模型根节点
    self.ModelName = nil    --模型名，作为key检索其他配置表用，可为nil
    self.ModelKey = ""      --RpgMakerGameModel表的Key
    self.RoleModelPanel = nil   --模型控制
    self.ResourcePool = {}  --已加载的资源池
    self:Init()

    if not XTool.UObjIsNil(gameObject) then
        self:SetModel(gameObject)
    end
end

function XRpgMakerGameObject:Init()
    self:ClearDrown()
    self._IsPlayAdsorb = false  --是否播放钢板吸附动作
    self:SetIsTranser(false)
end

function XRpgMakerGameObject:Dispose()
    self:RemoveResourcePool()

    if not XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler:RemoveAllListeners()
    end
    self.GoInputHandler = nil

    self:DisposeModel()
    self:StopPlayMoveActionTimer()

    self.ModelPath = nil
    self.RoleModelPanel = nil
    self:Init()
    self:SetIsTranser(false)
end

function XRpgMakerGameObject:DisposeModel()
    if not XTool.UObjIsNil(self.GameObject) then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
        self.GameObject = nil
        self.Transform = nil
    end
end

function XRpgMakerGameObject:SetId(id)
    self._Id = id
end

function XRpgMakerGameObject:GetId()
    return self._Id
end

function XRpgMakerGameObject:Release()
    self:RemoveResourcePool()
    self:RemoveDieEffectTimer()
    self:RemoveTweenTimer()
    self:OnRelease()
end

-- 提供给继承类重写
function XRpgMakerGameObject:OnRelease()
    
end

--------------场景对象相关 begin----------------
--获得两点间的传送点列表
local GetTransferPointDistanceList = function(data)
    local mapId = data.MapId
    local startPosX = data.StartPosX
    local startPosY = data.StartPosY
    local endPosX = data.EndPosX 
    local endPosY = data.EndPosY
    local cubeDistance = data.CubeDistance

    local distanceList = {}
    local distance = math.sqrt(XTool.MathPow((endPosY - startPosY), 2) + XTool.MathPow((endPosX - startPosX), 2))
    local oneCubeDistance = cubeDistance / distance

    local UpdateDistanceList = function(posX, posY, index)
        -- local transferPointId = XRpgMakerGameConfigs.GetRpgMakerGameTransferPointId(mapId, posX, posY)
        local transferPointId = XRpgMakerGameConfigs.GetMixTransferPointIndexByPosition(mapId, posX, posY)
        local obj = XDataCenter.RpgMakerGameManager.GetTransferPointObj(transferPointId)
        if obj then
            table.insert(distanceList, {
                Distance = oneCubeDistance * index,
                Obj = obj
            })
        end
    end

    
    local nextPosX, nextPosY = startPosX, startPosY
    for i = 1, math.ceil(distance) do
        if startPosX ~= endPosX then
            nextPosX = startPosX > endPosX and startPosX - i or startPosX + i
        end
        if startPosY ~= endPosY then
            nextPosY = startPosY > endPosY and startPosY - i or startPosY + i
        end
        UpdateDistanceList(nextPosX, nextPosY, i)
    end

    return distanceList
end

--获得两点间的实例列表
local GetEntityDistanceList = function(data)
    local mapId = data.MapId
    local startPosX = data.StartPosX
    local startPosY = data.StartPosY
    local endPosX = data.EndPosX 
    local endPosY = data.EndPosY
    local cubeDistance = data.CubeDistance

    local entityDistanceList = {}
    local distance = math.sqrt(XTool.MathPow((endPosY - startPosY), 2) + XTool.MathPow((endPosX - startPosX), 2))
    local oneCubeDistance = cubeDistance / distance

    local UpdateEntityDistanceList = function(posX, posY, index)
        local entityDataList = XRpgMakerGameConfigs.GetMixBlockEntityListByPosition(mapId, posX, posY)
        for _, data in ipairs(entityDataList) do
            local entityId = XRpgMakerGameConfigs.GetEntityIndex(mapId, data)
            local entityObj = XTool.IsNumberValid(entityId) and XDataCenter.RpgMakerGameManager.GetEntityObj(entityId)
            if entityObj and entityObj:IsActive() then
                table.insert(entityDistanceList, {
                    Distance = oneCubeDistance * index,
                    EntityObj = entityObj
                })
            end
        end
    end

    local nextPosX, nextPosY = startPosX, startPosY
    for i = 1, math.ceil(distance) do
        if startPosX ~= endPosX then
            nextPosX = startPosX > endPosX and startPosX - i or startPosX + i
        end
        if startPosY ~= endPosY then
            nextPosY = startPosY > endPosY and startPosY - i or startPosY + i
        end
        UpdateEntityDistanceList(nextPosX, nextPosY, i)
    end

    return entityDistanceList
end

-- 播放移动Action
function XRpgMakerGameObject:PlayMoveAction(action, cb, skillType)
    -- 反弹前提：自身携带物理2属性 + 朝向的第一格子可以走 + 朝向的第二个格子是草
    local physics2 = XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Physics2
    local scene = XDataCenter.RpgMakerGameManager.GetCurrentScene()
    local nextPos1 = scene:GetDirectionPos(action.EndPosition, action.Direction, 1)
    local nextPos2 = scene:GetDirectionPos(action.EndPosition, action.Direction, 2)
    local isStartAndEndSamePos = action.StartPosition.PositionX == action.EndPosition.PositionX and action.StartPosition.PositionY == action.EndPosition.PositionY
    self._IsRebound = self:IsOwnSkillType(physics2) and scene:IsPosGrass(nextPos2) and scene:IsPhysics2CanPass(nextPos1) and (isStartAndEndSamePos or not scene:IsPosStopMove(action.EndPosition))
    if self._IsRebound then
        local action1 = { StartPosition = action.StartPosition, EndPosition = nextPos1, Direction = action.Direction }
        local action2 = { StartPosition = nextPos1, EndPosition = action.EndPosition, Direction = action.Direction }
        self:PlayMove(action1, function()
            self:PlayMove(action2, cb, skillType, true, true)
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Rebound)
        end, skillType)
    else
        self:PlayMove(action, cb, skillType, true)
    end
end

--执行一次移动
---@param isLastMove boolean 是否是最后一段位移
---@param isRebound boolean 是否是反弹
function XRpgMakerGameObject:PlayMove(action, cb, skillType, isLastMove, isRebound)
    local transform = self:GetTransform()
    local startPosX = action.StartPosition.PositionX
    local startPosY = action.StartPosition.PositionY
    local endPosX = action.EndPosition.PositionX
    local endPosY = action.EndPosition.PositionY
    local direction = action.Direction
    if startPosX == endPosX and startPosY == endPosY then
        -- 移动结束
        if isLastMove then
            self:MoveComplete(endPosX, endPosY, direction, true)
        end
        self:ChangeDirectionAction(action)
        if cb then cb() end
        return
    end
    
    -- 怪物的警戒特效
    if self.RemoveViewAreaAndLine then
        self:RemoveViewAreaAndLine()
    end

    local startCube = self:GetCubeObj(startPosY, startPosX)
    local endCube = self:GetCubeObj(endPosY, endPosX)
    local startCubePosition = startCube:GetGameObjUpCenterPosition()
    local endCubePosition = endCube:GetGameObjUpCenterPosition()
    local cubeDistance = CS.UnityEngine.Vector3.Distance(startCubePosition, endCubePosition)
    local playActionTime = cubeDistance / MoveSpeed

    --计算播放音效的位置
    local distance = math.sqrt(XTool.MathPow((endPosY - startPosY), 2) + XTool.MathPow((endPosX - startPosX), 2))
    local playMoveSoundSpacePosition = distance > 0 and (endCubePosition - startCubePosition) / distance or Vector3(0, 0, 0)
    local currPlayMoveSoundPosition = startCubePosition + playMoveSoundSpacePosition

    self:SetGameObjectPosition(startCubePosition)

    --计算移动到目标位置的距离
    local gameObjPosition = self:GetGameObjPosition()
    local enterStageDb = XDataCenter.RpgMakerGameManager:GetRpgMakerGameEnterStageDb()
    local mapId = enterStageDb:GetMapId()
    local trapId = nil --XRpgMakerGameConfigs.GetRpgMakerGameTrapId(mapId, endPosX, endPosY)  --移动到的坐标有陷阱时，不偏移模型的位置
    local moveX = endCubePosition.x - gameObjPosition.x
    local moveZ = endCubePosition.z - gameObjPosition.z

    --在格子边缘停止移动
    if (self:IsDieByDrown() and not self:IsNotPlayDrownAnima()) or self:IsTranser() then
        local cubeSize = endCube:GetGameObjSize()
        local moveTempX = endCubePosition.x - startCubePosition.x
        if moveTempX < 0 then
            moveX = moveX + cubeSize.x / 2
        elseif moveTempX > 0 then
            moveX = moveX - cubeSize.x / 2
        end

        local moveTempZ = endCubePosition.z - startCubePosition.z
        if moveTempZ < 0 then
            moveZ = moveZ + cubeSize.z / 2
        elseif moveTempZ > 0 then
            moveZ = moveZ - cubeSize.z / 2
        end
    end

    self:ChangeDirectionAction(action)

    if isRebound then
        self:PlayPushBubbleAnim()
    else
        local modelName = self:GetModelName()
        local runAnima = XMVCA.XRpgMakerGame:GetConfig():GetAnimationRunAnimaName(modelName, direction)
        self.RoleModelPanel:PlayAnima(runAnima)
    end

    local getDistanceData = {
        MapId = mapId,
        StartPosX = startPosX,
        StartPosY = startPosY,
        EndPosX = endPosX,
        EndPosY = endPosY,
        CubeDistance = cubeDistance
    }

    --获得移动路径中的实例
    local entityDistanceList
    if skillType then
        entityDistanceList = GetEntityDistanceList(getDistanceData)
    end

    --获得移动路径中的传送点
    local transPointList
    if skillType and skillType ~= XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Dark then
        transPointList = GetTransferPointDistanceList(getDistanceData)
    end
    
    -- 加载移动特效特效
    self:CheckLoadMoveEffect()

    local movePositionX
    local movePositionZ
    local currPlayMoveSoundPositionX
    local currPlayMoveSoundPositionZ
    local curMoveDistance   --当前距离起点移动了多少
    self.PlayMoveActionTimer = XUiHelper.Tween(playActionTime, function(f)
        if XTool.UObjIsNil(transform) then
            return
        end

        curMoveDistance = playActionTime * f * MoveSpeed

        movePositionX = gameObjPosition.x + moveX * f
        movePositionZ = gameObjPosition.z + moveZ * f

        self:SetGameObjectPosition(Vector3(movePositionX, startCubePosition.y, movePositionZ), trapId)

        --保留2位小数
        movePositionX = movePositionX - movePositionX % 0.01
        movePositionZ = movePositionZ - movePositionZ % 0.01
        currPlayMoveSoundPositionX = currPlayMoveSoundPosition.x - currPlayMoveSoundPosition.x % 0.01
        currPlayMoveSoundPositionZ = currPlayMoveSoundPosition.z - currPlayMoveSoundPosition.z % 0.01

        --每移动一个格子播放一次音效
        if (playMoveSoundSpacePosition.x > 0 and movePositionX >= currPlayMoveSoundPositionX) or
        (playMoveSoundSpacePosition.z > 0 and movePositionZ >= currPlayMoveSoundPositionZ) or
        (playMoveSoundSpacePosition.x < 0 and movePositionX <= currPlayMoveSoundPositionX) or
        (playMoveSoundSpacePosition.z < 0 and movePositionZ <= currPlayMoveSoundPositionZ) then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Move)
            currPlayMoveSoundPosition = currPlayMoveSoundPosition + playMoveSoundSpacePosition
        end

        
        --检查实体对象是否需要播放状态变化的特效
        if not XTool.IsTableEmpty(entityDistanceList) and curMoveDistance >= entityDistanceList[1].Distance then
            self:CheckEntityDistanceList(entityDistanceList, skillType)
        end

        --检查移动到传送点是否需要播放传送失败的特效
        if not XTool.IsTableEmpty(transPointList) and curMoveDistance >= transPointList[1].Distance then
            local obj = transPointList[1].Obj
            obj:PlayTransFailEffect()
            table.remove(transPointList, 1)
        end
    end, function()
        self:UpdatePosition(action.EndPosition)
        -- 防止残余
        self:CheckEntityDistanceList(entityDistanceList, skillType)
        self:StopMove(cb)
        -- 移动结束
        if isLastMove then
            self:MoveComplete(endPosX, endPosY, direction)
        end
    end)
end

---@param isSamePos boolean 开始位置和结束位置是否相同
function XRpgMakerGameObject:MoveComplete(endPosX, endPosY, direction, isSamePos)
    local scene = XDataCenter.RpgMakerGameManager.GetCurrentScene()
    local isCurPosPlayed = false
    if not isSamePos then
        -- 当前格子是魔法阵
        local magicObjDic = XDataCenter.RpgMakerGameManager.GetMagicObjDic()
        for _, magic in pairs(magicObjDic) do
            if magic:IsSamePoint(endPosX, endPosY) then
                self:PlayAdsorbAnima()
                isCurPosPlayed = true
            end
        end
        -- 当前格子是换属性阵
        for _, switchPoint in pairs(scene.SwitchSkillPointObjs) do
            if switchPoint:IsSamePoint(endPosX, endPosY) then
                self:PlayAdsorbAnima()
                isCurPosPlayed = true
            end
        end
    end

    if not isCurPosPlayed then
        local nextPosX = endPosX
        local nextPosY = endPosY
        if direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft then
            nextPosX = nextPosX - 1
        elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight then
            nextPosX = nextPosX + 1
        elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp then
            nextPosY = nextPosY + 1
        elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown then
            nextPosY = nextPosY - 1
        end

        -- 下一格子是水
        ---@type XRpgMakerGameWaterData
        local waterObj = XDataCenter.RpgMakerGameManager.GetEntityObjByPosition(nextPosX, nextPosY, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Water)
        if waterObj and waterObj:IsStatusWater() then
            self:PlayAdsorbAnima()
        end
        ---@type XRpgMakerGameWaterData
        local iceObj = XDataCenter.RpgMakerGameManager.GetEntityObjByPosition(nextPosX, nextPosY, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Ice)
        if iceObj and iceObj:IsStatusWater() then
            self:PlayAdsorbAnima()
        end

        local isFlame = self:IsOwnSkillType(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Flame2) -- 是否是火属性
        local isPhysics = self:IsOwnSkillType(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Physics2) -- 是否是物理属性
        
        -- 下一格子是藤球
        local monsterObjDic = XDataCenter.RpgMakerGameManager.GetGameMonsterObjDic()
        for _, monster in pairs(monsterObjDic) do
            if monster:IsSamePoint(nextPosX, nextPosY) and not monster:IsDeath() and monster:IsSepaktakraw() then
                if isPhysics then
                    self:PlayAtkAction()
                elseif isFlame then
                    self:PlayPushBubbleAnim()
                end
            end
        end

        -- 本身火属性，下一格子是草
        ---@type XRpgMakerGameGrassData
        local grassObj = scene:GetGrass(nextPosX, nextPosY)
        if grassObj and grassObj:IsActive() and isFlame then
            self:PlayAtkAction()
        end
    end
    
    if self.OnMoveComplete then
        self:OnMoveComplete()
    end
end

-- 播放击飞Action
function XRpgMakerGameObject:PlayFlyAwayAction(action, cb)
    local modelName = self:GetModelName()
    local flyAnima = XMVCA.XRpgMakerGame:GetConfig():GetAnimationFlyAnimaName(modelName, action.Direction)
    if flyAnima and flyAnima ~= "" then
        self.RoleModelPanel:PlayAnima(flyAnima)
    end
    self:LoadFlyEffect(action.Direction)
    
    -- 反弹前提：自身携带物理2属性 + 朝向的第一格子无阻挡 + 朝向的第二个格子是草
    local physics2 = XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Physics2
    local scene = XDataCenter.RpgMakerGameManager.GetCurrentScene()
    local nextPos1 = scene:GetDirectionPos(action.EndPosition, action.Direction, 1)
    local nextPos2 = scene:GetDirectionPos(action.EndPosition, action.Direction, 2)
    local isRebound = self:IsOwnSkillType(physics2) and scene:IsPosGrass(nextPos2) and scene:IsPhysics2CanFly(nextPos1)
    if isRebound then
        local action1 = { StartPosition = action.StartPosition, EndPosition = nextPos1, Direction = action.Direction }
        local action2 = { StartPosition = nextPos1, EndPosition = action.EndPosition, Direction = action.Direction }
        self:PlayFlyAway(action1, function()
            self:PlayMove(action2, cb)
        end)
    else
        self:PlayFlyAway(action, cb)
    end
end

function XRpgMakerGameObject:PlayFlyAway(action, cb)
    local transform = self:GetTransform()
    local startCube = self:GetCubeObj(action.StartPosition.PositionY, action.StartPosition.PositionX)
    local endCube = self:GetCubeObj(action.EndPosition.PositionY, action.EndPosition.PositionX)
    local startCubePosition = startCube:GetGameObjUpCenterPosition()
    local endCubePosition = endCube:GetGameObjUpCenterPosition()
    local cubeDistance = CS.UnityEngine.Vector3.Distance(startCubePosition, endCubePosition)
    local playActionTime = cubeDistance / MoveSpeed

    self:SetGameObjectPosition(startCubePosition)

    local moveX = endCubePosition.x - startCubePosition.x
    local moveZ = endCubePosition.z - startCubePosition.z
    local moveY = 0.6 -- 移动的高度
    
    local easeType = XUiHelper.EaseType.Sin
    self.PlayMoveActionTimer = XUiHelper.Tween(playActionTime, function(f)
        if XTool.UObjIsNil(transform) then return end

        local movePositionX = startCubePosition.x + moveX * f
        local movePositionZ = startCubePosition.z + moveZ * f
        local movePositionY = startCubePosition.y
        if f < 0.5 then
            movePositionY = startCubePosition.y + f * 2 * moveY
        else
            movePositionY = startCubePosition.y + moveY - (f - 0.5) * 2 * moveY
        end

        self:SetGameObjectPosition(Vector3(movePositionX, movePositionY, movePositionZ))

    end, function()
        self:PlayStandAnima()
        self:StopPlayMoveActionTimer()
        self:SetGameObjectPosition(endCubePosition)
        self:UpdatePosition(action.EndPosition)
        self:RemoveFlyEffect()
        if cb then cb() end
    end, function(t)
        return XUiHelper.Evaluate(easeType, t)
    end)
end

-- 加载飞行特效
function XRpgMakerGameObject:LoadFlyEffect(direction)
    local effectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Physics2Effect)
    local resource = self:ResourceManagerLoad(effectPath)
    self:LoadEffect(resource.Asset, nil, nil, direction)
end

-- 移除飞行特效
function XRpgMakerGameObject:RemoveFlyEffect()
    local effectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Physics2Effect)
    self:RemoveResource(effectPath)
end

---检查移动过程中冰火对象转换
function XRpgMakerGameObject:CheckEntityDistanceList(entityDistanceList, skillType)
    if not XTool.IsTableEmpty(entityDistanceList) then
        local entityObj = entityDistanceList[1].EntityObj
        local mapObjData = entityObj:GetMapObjData()
        local type = mapObjData:GetType()
        if type == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Water or type == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Ice then
            if entityObj:GetStatus() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Water and skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Crystal then
                --冰属性角色触发水结冰
                entityObj:SetStatus(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Ice)
                entityObj:CheckPlayFlat()
            elseif entityObj:GetStatus() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Ice and skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Flame then
                --火属性对象触发冰融化
                entityObj:SetStatus(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Water)
                entityObj:CheckPlayFlat()
            end
        end
        table.remove(entityDistanceList, 1)
    end
end

function XRpgMakerGameObject:StopMove(cb)
    self:RemoveMoveEffect()
    self:StopPlayMoveActionTimer()

    if self:IsPlayAdsorbAnima() then
        self:SetIsPlayAdsorbAnima(false)
        self:PlayAdsorbAnima(function()
            self:StopMove(cb)
        end)
        return
    end

    self:PlayStandAnima()
    if cb then
        cb()
    end
end

--isEnforceSetObjPos：是否强制设置场景对象的位置
function XRpgMakerGameObject:StopPlayMoveActionTimer(isEnforceSetObjPos)
    if isEnforceSetObjPos and self.PlayMoveActionTimer then
        CSXScheduleManagerUnSchedule(self.PlayMoveActionTimer)
        self.PlayMoveActionTimer = nil
    end

    if isEnforceSetObjPos then
        local cubePosition = self:GetCurPosByCubeUpCenterPosition()
        self:SetGameObjectPosition(Vector3(cubePosition))
    end
end

-- 加载移动特效
function XRpgMakerGameObject:CheckLoadMoveEffect()
    if self:IsOwnSkillType(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Physics2) then
        self.MoveEffectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Physics2Effect)
        local resource = self:ResourceManagerLoad(self.MoveEffectPath)
        self:LoadEffect(resource.Asset)
    end
end

-- 移除移动特效
function XRpgMakerGameObject:RemoveMoveEffect()
    if self.MoveEffectPath then
        self:RemoveResource(self.MoveEffectPath)
        self.MoveEffectPath = nil
    end
end

--改变方向
function XRpgMakerGameObject:ChangeDirectionAction(action, cb)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    self:SetGameObjectLookRotation(action.Direction)

    if cb then
        cb()
    end
end

--获得对应方向的坐标
function XRpgMakerGameObject:GetDirectionPos(direction)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local objPosition = transform.position
    local directionPos
    if direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft then
        directionPos = objPosition + Vector3.left
    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight then
        directionPos = objPosition + Vector3.right
    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp then
        directionPos = objPosition + Vector3.forward
    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown then
        directionPos = objPosition + Vector3.back
    end
    return directionPos
end

--加载模型（只能存在一个）
function XRpgMakerGameObject:LoadModel(modelPath, root, modelName, modelKey)
    --记录旧模型位置
    local oldPos = self:GetGameObjPosition()

    self:Dispose()

    self.ModelPath = modelPath
    self.ModelRoot = root or self.ModelRoot
    self.ModelName = modelName
    self.ModelKey = modelKey or self.ModelKey

    if modelName and self.ModelRoot then
        local modelLink = CS.UnityEngine.GameObject("Model")
        self:BindToRoot(modelLink, self.ModelRoot)
        local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
        self.RoleModelPanel = XUiPanelRoleModel.New(modelLink, modelName, nil, nil, false)
        self.RoleModelPanel:UpdateRoleModel(modelName, nil, nil, function()
            self:SetModel(modelLink)
        end, nil, true, true)
    else
        if not modelPath then
            return
        end
        local resource = self:ResourceManagerLoad(modelPath)
        if not resource then
            return
        end
        local model = resource.Asset
        local scale = not string.IsNilOrEmpty(modelKey) and XMVCA.XRpgMakerGame:GetConfig():GetModelScale(modelKey)
        self:BindToRoot(model, self.ModelRoot, scale)
        self:SetModel(model)
    end

    if oldPos then
        self:SetGameObjectPosition(oldPos)
    end
    
    self:RefreshSkillTypeEffect()
end

---加载技能特效
function XRpgMakerGameObject:LoadSkillEffect(skillType)
    if not self.RoleModelPanel then
        return
    end

    local skillModelKey = XRpgMakerGameConfigs.GetModelSkillEffctKey(skillType)
    if not skillModelKey then
        return
    end

    local effectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(skillModelKey)
    self.RoleModelPanel:LoadEffect(effectPath, nil, true, true, true)
end

function XRpgMakerGameObject:GetEffectTransform()
    local modelName = self:GetModelName()
    local transform = self:GetTransform()
    if string.IsNilOrEmpty(modelName) then
        return transform
    end
    
    local effectRootName = XMVCA.XRpgMakerGame:GetConfig():GetAnimationEffectRoot(modelName)
    if string.IsNilOrEmpty(effectRootName) then
        return transform
    end

    local effectRoot = transform:FindTransform(effectRootName)
    return XTool.UObjIsNil(effectRoot) and transform or effectRoot
end

--加载特效（可加载多个不同的预制）
function XRpgMakerGameObject:LoadEffect(model, position, rootTransform, direction)
    local transform = rootTransform or self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    self:BindToRoot(model, transform)

    if position then
        model.transform.position = position
    end

    if direction then
        local rotation = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameDirectionRotation[direction]
        model.transform.eulerAngles = XLuaVector3.New(0, rotation, 0)
    end

    model.gameObject:SetActiveEx(false)
    model.gameObject:SetActiveEx(true)

    return model
end

function XRpgMakerGameObject:BindToRoot(model, root, scale)
    if XTool.UObjIsNil(model) then
        XLog.Error("绑定根节点失败，model不存在")
        return
    end
    model.transform:SetParent(root)
    model.transform.localPosition = CS.UnityEngine.Vector3.zero
    model.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    model.transform.localScale = scale or CS.UnityEngine.Vector3.one
end

function XRpgMakerGameObject:ResetModel()
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    transform.localScale = CS.UnityEngine.Vector3.one

    local position = self:GetCurPosByCubeUpCenterPosition()
    self:SetGameObjectPosition(position)
end

function XRpgMakerGameObject:SetModel(go)
    self.GameObject = go
    self.Transform = go.transform

    self:OnLoadComplete()
end

function XRpgMakerGameObject:GetGameObject()
    return self.GameObject
end

function XRpgMakerGameObject:GetTransform()
    return self.Transform
end

-- 获取资源Transform
function XRpgMakerGameObject:GetAssetTransform()
    return self.Transform:GetChild(0)
end

function XRpgMakerGameObject:GetModelName()
    return self.ModelName or ""
end

function XRpgMakerGameObject:GetModelKey()
    return self.ModelKey
end

--设置场景对象位置
function XRpgMakerGameObject:SetGameObjectPosition(position, isNotOffset)
    if XTool.UObjIsNil(self.Transform) then
        return
    end

    if not position then
        XLog.Error("XRpgMakerGameObject:SetGameObjectPosition设置场景对象位置错误，position为nil")
        return
    end

    local xOffset, yOffset, zOffset = 0, 0, 0
    local modelName = self:GetModelName()
    if not string.IsNilOrEmpty(modelName) and not isNotOffset then
        xOffset = XMVCA.XRpgMakerGame:GetConfig():GetAnimationXOffSet(modelName)
        yOffset = XMVCA.XRpgMakerGame:GetConfig():GetAnimationYOffSet(modelName)
        zOffset = XMVCA.XRpgMakerGame:GetConfig():GetAnimationZOffSet(modelName)
    end

    self.LastPosition = Vector3(position.x + xOffset, position.y + yOffset, position.z + zOffset)
    self.Transform.position = self.LastPosition
end

function XRpgMakerGameObject:GetGameObjPosition()
    return self.LastPosition
    --[[
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return self.TransformPosition
    end

    return transform.position
    ]]
end

--获得模型所在的根节点
function XRpgMakerGameObject:GetGameObjModelRoot()
    return self.ModelRoot
end

--设置场景对象朝向
function XRpgMakerGameObject:SetGameObjectLookRotation(direction)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local objPos = self:GetGameObjPosition()
    local directionPos = self:GetDirectionPos(direction)
    if not objPos or not directionPos then
        return
    end

    if self.Direction and self.Direction ~= direction and self.MonsterType ~= XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.Sepaktakraw then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_ChangeDirection)
    end
    self.Direction = direction

    local lookRotation = LookRotation(directionPos - objPos)
    self:SetGameObjectRotation(lookRotation)
end

--设置场景对象角度
function XRpgMakerGameObject:SetGameObjectRotation(rotation)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end
    transform.rotation = rotation
end

--获得场景对象大小
function XRpgMakerGameObject:GetGameObjSize()
    local gameObject = self:GetGameObject()
    if XTool.UObjIsNil(gameObject) then
        return {}
    end

    local meshFilter = gameObject:GetComponent("MeshFilter")
    if not XTool.UObjIsNil(meshFilter) then
        return meshFilter.mesh.bounds.size
    end

    local modelKey = self:GetModelKey()
    return XMVCA.XRpgMakerGame:GetConfig():GetModelSize(modelKey)
end

function XRpgMakerGameObject:OnLoadComplete()
    self.GoInputHandler = self.Transform:GetComponentInChildren(typeof(CS.XGoInputHandler)) -- 部分模型已经挂了XGoInputHandler组件
    if XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler = self.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    end

    self.GoInputHandler:AddPointerClickListener(function(eventData) self:OnClick(eventData) end)
    self.GoInputHandler:AddPointerDownListener(function(eventData) self:OnPointerDown(eventData) end)
    self.GoInputHandler:AddPointerUpListener(function(eventData) self:OnPointerUp(eventData) end)
end

function XRpgMakerGameObject:OnClick(eventData)
    local modelKey = self:GetModelKey()
    local modelName = self:GetModelName()
    XDataCenter.RpgMakerGameManager.FireClickObjectCallback(modelKey, modelName)
end

function XRpgMakerGameObject:OnPointerDown()
    XDataCenter.RpgMakerGameManager.FirePointerDownObjectCallback()
end

function XRpgMakerGameObject:OnPointerUp()
    XDataCenter.RpgMakerGameManager.FirePointerUpObjectCallback()
end

--播放攻击动画
function XRpgMakerGameObject:PlayAtkAction(cb)
    local modelName = self:GetModelName()
    local atkAnima = XMVCA.XRpgMakerGame:GetConfig():GetAnimationAtkAnimaName(modelName)
    local callBack = function()
        self:PlayStandAnima()
        if cb then
            cb()
        end
    end
    self.RoleModelPanel:PlayAnima(atkAnima, true, callBack, callBack)
end

function XRpgMakerGameObject:Death(cb)
    self:SetActive(false)
    if cb then
        cb()
    end
end

--播放站立动画
function XRpgMakerGameObject:PlayStandAnima()
    local modelName = self:GetModelName()
    local standAnima = XMVCA.XRpgMakerGame:GetConfig():GetAnimationStandAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(standAnima)
end

--播放进入陷阱死亡动画
function XRpgMakerGameObject:PlayDieByTrapAnima(cb)
    -- 怪物的警戒特效
    if self.RemoveViewAreaAndLine then
        self:RemoveViewAreaAndLine()
    end
    
    local easeMethod = function(f)
        return XUiHelper.Evaluate(XUiHelper.EaseType.Increase, f)
    end

    local objPos = self:GetGameObjPosition()
    local scale
    XUiHelper.Tween(DieByTrapTime, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        self:SetGameObjectPosition(Vector3(objPos.x, objPos.y - f * objPos.y, objPos.z), true)

        scale = 1 - f
        self:SetGameObjScale(Vector3(scale, scale, scale))
    end, function()
        self:ResetModel()
        self:Death(cb)
    end, easeMethod)

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_DieByTrap)
end

--播放被电死亡动画
function XRpgMakerGameObject:PlayKillByElectricFenceAnima(cb)
    local callback = function()
        self:Death(cb)
    end
    local modelName = self:GetModelName()
    local electricFenceAnima = XMVCA.XRpgMakerGame:GetConfig():GetAnimationElectricFenceAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(electricFenceAnima, true, callback, callback)

    --被电的材质动画和特效
    local effectName = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.KillByElectricFenceEffect
    local killByElectricFenceEffectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(effectName)
    self.RoleModelPanel:LoadEffect(killByElectricFenceEffectPath, effectName, true, true, true)

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Elecboom)
end

--播放惊吓动画
function XRpgMakerGameObject:PlayAlarmAnima(cb)
    local modelName = self:GetModelName()
    local alarmAnima = XMVCA.XRpgMakerGame:GetConfig():GetAnimationAlarmAnimaName(modelName)
    if alarmAnima and alarmAnima ~= "" then
        self.RoleModelPanel:PlayAnima(alarmAnima, true, cb, cb)
    else
        if cb then cb() end
    end
end

---------溺死相关 begin----------
--设置溺死，判断播放哪种动画
--x, y：二维坐标
function XRpgMakerGameObject:DieByDrown(mapId, x, y)
    local isDieByDrown = true
    local entityMapDataList = XRpgMakerGameConfigs.GetMixBlockEntityListByPosition(mapId, x, y)
    if XTool.IsTableEmpty(entityMapDataList) then
        return
    end

    for _, entityMapData in pairs(entityMapDataList) do
        local entityType = entityMapData:GetType()
        if entityType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Water or entityType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Ice then
            local entityId = XRpgMakerGameConfigs.GetEntityIndex(mapId, entityMapData)
            --目的地是冰面，会死说明站在冰面融化了，不播放模型动作
            local entityObj = XDataCenter.RpgMakerGameManager.GetEntityObj(entityId)
            local isNotPlayDrownAnima = (entityObj) and (entityObj:GetStatus() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Ice)
            self:SetDieByDrownAction(isDieByDrown, isNotPlayDrownAnima, entityObj)
            return
        end
    end
end

function XRpgMakerGameObject:SetDieByDrownAction(isDieByDrown, isNotPlayDrownAnima, entityObj)
    if isDieByDrown ~= nil then
        self._IsDieByDrown = isDieByDrown
    end
    if isNotPlayDrownAnima ~= nil then
        self._IsNotPlayDrownAnima = isNotPlayDrownAnima
    end
    if entityObj ~= nil then
        self._PlayDrownEffectObj = entityObj
    end
end

function XRpgMakerGameObject:ClearDrown()
    self._IsNotPlayDrownAnima = false   --是否不播放溺死的动作，为true时改播渐渐变小并落下的动画
    self._IsDieByDrown = false  --是否溺死
    self._PlayDrownEffectObj = nil  --播放落水特效的对象
end

function XRpgMakerGameObject:IsDieByDrown()
    return self._IsDieByDrown
end

function XRpgMakerGameObject:IsNotPlayDrownAnima()
    return self._IsNotPlayDrownAnima
end

--播放溺死动画
--isNotPlayAnima：是否不播放溺死的动作；为true时改播渐渐变小并落下的动画
function XRpgMakerGameObject:PlayDrownAnima(cb, isNotPlayAnima)
    isNotPlayAnima = isNotPlayAnima ~= nil and isNotPlayAnima or self:IsNotPlayDrownAnima()

    local callback = function()
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_DieByDrown)
        self:PlayDrownEffect()
        self:ClearDrown()
        self:Death(cb)
    end

    if isNotPlayAnima then
        local easeMethod = function(f)
            return XUiHelper.Evaluate(XUiHelper.EaseType.Increase, f)
        end

        local objPos = self:GetGameObjPosition()
        local scale
        self:RemoveTweenTimer()
        self.TweenTimer = XUiHelper.Tween(DieByTrapTime, function(f)
            if XTool.UObjIsNil(self.Transform) then
                return
            end

            self:SetGameObjectPosition(Vector3(objPos.x, objPos.y - f * objPos.y, objPos.z), true)

            scale = 1 - f
            self:SetGameObjScale(Vector3(scale, scale, scale))
        end, function()
            self:ResetModel()
            callback()
        end, easeMethod)
        return
    end

    -- 反弹后落水，需要调整朝向
    if self._IsRebound then
        local endCube = self:GetCubeObj(self._PositionY, self._PositionX)
        local endCubePosition = endCube:GetGameObjUpCenterPosition()
        local curPosition = self.Transform.position
        local direction = XLuaVector3.New(endCubePosition.x - curPosition.x, 0, endCubePosition.z - curPosition.z)
        self.Transform.rotation = LookRotation(direction)
    end
    
    local modelName = self:GetModelName()
    local drownAnima = XMVCA.XRpgMakerGame:GetConfig():GetAnimationDrownAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(drownAnima, true, callback, callback)
end

function XRpgMakerGameObject:RemoveTweenTimer()
    if self.TweenTimer then
        XScheduleManager.UnSchedule(self.TweenTimer)
        self.TweenTimer = nil
    end
end

--播放落水特效
function XRpgMakerGameObject:PlayDrownEffect()
    local obj = self._PlayDrownEffectObj
    if not obj then
        return
    end
    local effectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Drown)
    local resource = obj:ResourceManagerLoad(effectPath)
    local drownEffect = obj:LoadEffect(resource.Asset)
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(drownEffect) then
            drownEffect.gameObject:SetActiveEx(false)
        end
    end, XScheduleManager.SECOND)
end
---------溺死相关 end----------

---------钢板相关 begin----------
--检查是否需要播放钢板吸附动作
function XRpgMakerGameObject:CheckIsSteelAdsorb(mapId, x, y, skillType)
    if skillType ~= XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Thunder then
        return
    end
    local isPlay = XRpgMakerGameConfigs.IsSameMixBlock(mapId, x, y, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Steel)
    self:SetIsPlayAdsorbAnima(isPlay)
end

function XRpgMakerGameObject:SetIsPlayAdsorbAnima(isPlay)
    self._IsPlayAdsorb = isPlay
end

function XRpgMakerGameObject:IsPlayAdsorbAnima()
    return self._IsPlayAdsorb and true or false
end

--播放吸附动作
function XRpgMakerGameObject:PlayAdsorbAnima(cb)
    local modelName = self:GetModelName()
    local adsorbAnima = XMVCA.XRpgMakerGame:GetConfig():GetAnimationAdsorbAnimaName(modelName)
    if string.IsNilOrEmpty(adsorbAnima) then
        if cb then cb() end
    else
        self.RoleModelPanel:PlayAnima(adsorbAnima, true, cb, cb)
        --XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Adsorb)
    end
end
---------钢板相关 end----------

---------传送相关 begin----------
local _IsTranser --是否传送
function XRpgMakerGameObject:SetIsTranser(isTranser)
    _IsTranser = isTranser
end

function XRpgMakerGameObject:IsTranser()
    return _IsTranser
end

--传送
--startPosX, startPosZ：开始传送的位置（地面的二维坐标）
--endPosX, endPosY：结束传送的位置（地面的二维坐标）
function XRpgMakerGameObject:PlayTransfer(startPosX, startPosY, endPosX, endPosY, cb)
    self:SetIsTranser(false)
    local gameObjPosition = self:GetGameObjPosition()
    local startCubePosition = self:GetCubeUpCenterPosition(startPosY, startPosX)
    local cubeDistance = CS.UnityEngine.Vector3.Distance(gameObjPosition, startCubePosition)
    local playActionTime = cubeDistance / MoveSpeed
    local transform = self:GetTransform()
    local moveX = startCubePosition.x - gameObjPosition.x
    local moveZ = startCubePosition.z - gameObjPosition.z

    --当前位置到传送点的位移
    local movePositionX, movePositionZ
    local moveToTransPointFunc = XUiHelper.Tween(0.5, function(f)
        if XTool.UObjIsNil(transform) then
            return
        end
        movePositionX = gameObjPosition.x + moveX * f
        movePositionZ = gameObjPosition.z + moveZ * f
        self:SetGameObjectPosition(Vector3(movePositionX, gameObjPosition.y, movePositionZ))
    end)

    self:PlayTransferDisAnima(function()
        if moveToTransPointFunc then
            CSXScheduleManagerUnSchedule(moveToTransPointFunc)
            moveToTransPointFunc = nil
        end
        local endCubePosition = self:GetCubeUpCenterPosition(endPosY, endPosX)
        self:SetGameObjectPosition(Vector3(endCubePosition.x, gameObjPosition.y, endCubePosition.z))
        self:PlayTransferAnima(cb)
    end)
end

--播放传送消失动作
function XRpgMakerGameObject:PlayTransferDisAnima(cb)
    local modelName = self:GetModelName()
    local transferDis = XMVCA.XRpgMakerGame:GetConfig():GetAnimationTransferDisAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(transferDis, true, cb, cb)
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_TransferDis)
end

--播放传送出现动作
function XRpgMakerGameObject:PlayTransferAnima(cb)
    local modelName = self:GetModelName()
    local transferAnima = XMVCA.XRpgMakerGame:GetConfig():GetAnimationTransferAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(transferAnima, true, cb, cb)
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Transfer)
end
---------传送相关 end----------

--#region 掉落物相关

---角色捡起掉落物动画
---@param cb function
function XRpgMakerGameObject:PlayPickUpAnim(cb)
    local modelName = self:GetModelName()
    local transferAnima = XMVCA.XRpgMakerGame:GetConfig():GetAnimationDropPickAnimaName(modelName)
    local callBack = function()
        self:PlayStandAnima()
        if cb then
            cb()
        end
    end
    self.RoleModelPanel:PlayAnima(transferAnima, true, callBack, callBack)
    -- XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Sound, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Transfer)
end

--#endregion


--#region 魔法阵相关

---角色魔法阵传送特效
---@param cb function
function XRpgMakerGameObject:PlayMagicTransferAnim(endPosX, endPosY, cb)
    local gameObjPosition = self:GetGameObjPosition()
    --当前位置到传送点的位移
    self:PlayMagicTransferDisEffect(function()
        local endCubePosition = self:GetCubeUpCenterPosition(endPosY, endPosX)
        self:SetGameObjectPosition(Vector3(endCubePosition.x, gameObjPosition.y, endCubePosition.z))
        self:PlayMagicTransferEffect(cb)
    end)
end

--播放传送阵消失特效
function XRpgMakerGameObject:PlayMagicTransferDisEffect(cb)
    if XTool.UObjIsNil(self._MagicDisEffect) then
        local effectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.MagicDisEffect)
        local resource = self:ResourceManagerLoad(effectPath)
        local position = self:GetTransform().position
        if not position then
            return
        end
        self._MagicDisEffect = self:LoadEffect(resource.Asset, position)
    end
    self._MagicDisEffect.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(self._MagicDisEffect) then
            self._MagicDisEffect.gameObject:SetActiveEx(false)
        end
        if cb then cb() end
    end, XScheduleManager.SECOND)
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_TransferDis)
end

--播放传送阵出现特效
function XRpgMakerGameObject:PlayMagicTransferEffect(cb)
    if XTool.UObjIsNil(self._MagicShowEffect) then
        local effectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.MagicShowEffect)
        local resource = self:ResourceManagerLoad(effectPath)
        local position = self:GetTransform().position
        if not position then
            return
        end
        self._MagicShowEffect = self:LoadEffect(resource.Asset, position)
    end
    self._MagicShowEffect.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(self._MagicDisEffect) then
            self._MagicShowEffect.gameObject:SetActiveEx(false)
        end
        if cb then cb() end
    end, XScheduleManager.SECOND)
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Transfer)
end

--#endregion


--#region 泡泡相关

---推动泡泡动画
---@param cb function
function XRpgMakerGameObject:PlayPushBubbleAnim(cb)
    local modelName = self:GetModelName()
    local pushAnima = XMVCA.XRpgMakerGame:GetConfig():GetAnimationBubblePushAnimaName(modelName)
    local callBack = function()
        self:PlayStandAnima()
        if cb then
            cb()
        end
    end
    self.RoleModelPanel:PlayAnima(pushAnima, true, callBack, callBack)
    -- XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Sound, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Transfer)
end

--#endregion

function XRpgMakerGameObject:SetActive(isActive)
    local gameObject = self:GetGameObject()
    if XTool.UObjIsNil(gameObject) then
        return
    end
    gameObject:SetActiveEx(isActive)

    if self.RoleModelPanel then
        local effectName = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.KillByElectricFenceEffect
        self.RoleModelPanel:HideEffectByParentName(effectName)
    end
end

function XRpgMakerGameObject:IsActive()
    local gameObject = self:GetGameObject()
    if XTool.UObjIsNil(gameObject) then
        return false
    end
    return gameObject.activeSelf
end

function XRpgMakerGameObject:SetGameObjScale(scale)
    if XTool.UObjIsNil(self.Transform) then
        return
    end

    self.Transform.localScale = scale
end

function XRpgMakerGameObject:GetCubeObj(row, col)
    return XDataCenter.RpgMakerGameManager.GetSceneCubeObj(row, col)
end

function XRpgMakerGameObject:GetCubeUpCenterPosition(row, col)
    return XDataCenter.RpgMakerGameManager.GetSceneCubeUpCenterPosition(row, col)
end

function XRpgMakerGameObject:GetCubeTransform(row, col)
    return XDataCenter.RpgMakerGameManager.GetSceneCubeTransform(row, col)
end

--获得当前模型所在的3D场景坐标
function XRpgMakerGameObject:GetCurPosByCubeUpCenterPosition()
    local x = self:GetPositionX()
    local y = self:GetPositionY()
    return self:GetCubeUpCenterPosition(y, x)
end

---@param noReuse boolean 不复用资源
function XRpgMakerGameObject:ResourceManagerLoad(path, noReuse)
    local isReuse = not noReuse -- 是否复用资源
    if isReuse then
        for _, res in pairs(self.ResourcePool) do
            if res.Path == path then
                return res
            end
        end
    end

    local go = CS.UnityEngine.GameObject(path)
    local prefab = go:LoadPrefab(path)
    local res = { Path = path, Asset = go, Prefab = prefab }
    table.insert(self.ResourcePool, res)
    return res
end

function XRpgMakerGameObject:RemoveResource(path)
    for i = #self.ResourcePool, 1, -1 do
        local res = self.ResourcePool[i]
        if res.Path == path then
            table.remove(self.ResourcePool, i)
            CS.UnityEngine.GameObject.Destroy(res.Asset)
        end
    end
end

function XRpgMakerGameObject:RemoveResourcePool()
    for _, resource in pairs(self.ResourcePool) do
        CS.UnityEngine.GameObject.Destroy(resource.Asset)
    end
    self.ResourcePool = {}
    self.EffectPathDic = {}
    self.MoveEffectPath = {}
end

function XRpgMakerGameObject:GetStatus()
end
--------------场景对象相关 end------------------

-- 当前格子是否为空，默认false，可在继承类重写
function XRpgMakerGameObject:IsEmpty()
    return false
end

-- 加载死亡特效
function XRpgMakerGameObject:LoadDieEffect(cb)
    local dieEffectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.DieEffect)
    local resource = self:ResourceManagerLoad(dieEffectPath)
    self:LoadEffect(resource.Asset)
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Death)

    local EFFECT_TIME = 500
    self:RemoveDieEffectTimer()
    self.DieEffectTimer = XScheduleManager.ScheduleOnce(function()
        self:RemoveResource(dieEffectPath)
        self:Die()
        if cb then cb() end
    end, EFFECT_TIME)
end

function XRpgMakerGameObject:RemoveDieEffectTimer()
    if self.DieEffectTimer then
        XScheduleManager.UnSchedule(self.DieEffectTimer)
        self.DieEffectTimer = nil
    end
end

function XRpgMakerGameObject:Die()
    if self.SetCurrentHp then
        self:SetCurrentHp(0)
    end
    self:SetActive(false)
    self:OnDie()
end

-- 继承类重写
function XRpgMakerGameObject:OnDie()
    
end

--region 属性
-- 初始化属性类型
function XRpgMakerGameObject:InitSkillTypes(skillTypes)
    self.SkillTypes = skillTypes
    self:RefreshSkillTypeEffect()
end

-- 切换属性类型
function XRpgMakerGameObject:ChangeSkillTypes(skillTypes)
    local oldSkillTypes = self.SkillTypes
    self.SkillTypes = skillTypes
    self:RefreshSkillTypeEffect()
    self:OnSkillTypesChange(oldSkillTypes, skillTypes)
end

-- 属性类型变化
function XRpgMakerGameObject:OnSkillTypesChange(oldSkillTypes, skillTypes)
    
end

-- 获取属性类型
function XRpgMakerGameObject:GetSkillTypes()
    return self.SkillTypes
end

-- 是否拥有某个属性
function XRpgMakerGameObject:IsOwnSkillType(skillType)
    if not self.SkillTypes then return false end
    
    for _, v in pairs(self.SkillTypes) do
        if v == skillType then
            return true
        end
    end
    return false
end

-- 刷新属性类型特效
function XRpgMakerGameObject:RefreshSkillTypeEffect()
    local effectPathDic = {}
    if self.SkillTypes and #self.SkillTypes > 0 then
        for _, skillType in pairs(self.SkillTypes) do
            local effectKey = XMVCA.XRpgMakerGame.EnumConst:GetSkillTypePermanentEffectKey(skillType, self.MonsterType)
            if effectKey then
                local effectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(effectKey)
                effectPathDic[effectPath] = true
            end
        end
    end

    -- 移除不需要的特效
    if self.EffectPathDic then
        for path, _  in pairs(self.EffectPathDic) do
            if not effectPathDic[path] then
                self:RemoveResource(path)
            end
        end
    end
    
    -- 加载新特效
    for path, _  in pairs(effectPathDic) do
        if not self.EffectPathDic or not self.EffectPathDic[path] then
            local resource = self:ResourceManagerLoad(path)
            self:LoadEffect(resource.Asset)
        end
    end
    self.EffectPathDic = effectPathDic
end
--endregion
return XRpgMakerGameObject