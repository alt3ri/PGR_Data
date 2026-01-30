local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")
local XRpgMakerGameMonsterPatrolLine = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameMonsterPatrolLine")
local XRpgMakerGameMonsterSentry = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameMonsterSentry")

local type = type
local pairs = pairs
local tableInsert = table.insert
local IsNumberValid = XTool.IsNumberValid
local Vector3 = CS.UnityEngine.Vector3

local DefaultHp = 100

local Default = {
    _CurrentHp = 100,       --当前血量
    _FaceDirection = 0,     --朝向
}

--往某个方向设置移动路线特效
local MoveLineEffectType = {
    Horizontal = 1,    --往水平方向设置特效
    Vertical = 2,      --往垂直方向设置特效
}

--怪物对象
---@class XRpgMakerGameMonsterData
local XRpgMakerGameMonsterData = XClass(XRpgMakerGameObject, "XRpgMakerGameMonsterData")

function XRpgMakerGameMonsterData:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self.PatrolLineObjs = {}    --场景中生成的下回合移动路线
    self.ViewAreaModels = {}    --场景中生成的视野范围
    self.SentryLineModels = {}  --场景中生成的探测视野
    self.Sentry = XRpgMakerGameMonsterSentry.New(id)           --场景中生成的哨戒指示物
    self.HeadRoot = nil         --模型的头部挂点
    self.MonsterType = XMVCA.XRpgMakerGame:GetConfig():GetMonsterType(self._Id)
    self:InitData()
end

function XRpgMakerGameMonsterData:Dispose()
    self:RemoveViewAreaAndLine()
    self:RemoveSentry()
    self:RemoveTriggerEffectResource()
    self:RemoveViewAreaResource()
    XRpgMakerGameMonsterData.Super.Dispose(self)
end

function XRpgMakerGameMonsterData:RemoveTriggerEffectResource()
    if self.TriggerEffectResource then
        CS.UnityEngine.GameObject.Destroy(self.TriggerEffectResource.Asset)
        self.TriggerEffectResource = nil
    end
end

function XRpgMakerGameMonsterData:RemoveViewAreaResource()
    if self.ViewAreaResourcePath then
        self:RemoveResource(self.ViewAreaResourcePath)
        self.ViewAreaResourcePath = nil
    end
end

function XRpgMakerGameMonsterData:RemoveSentry()
    if self.Sentry then
        self.Sentry:Dispose()
    end
end

function XRpgMakerGameMonsterData:RemovePatrolLineObjs()
    for _, v in pairs(self.PatrolLineObjs) do
        v:Dispose()
    end
    self.PatrolLineObjs = {}
end

function XRpgMakerGameMonsterData:RemoveViewAreaModels()
    for _, v in pairs(self.ViewAreaModels) do
        if not XTool.UObjIsNil(v) then
            XUiHelper.Destroy(v)
        end
    end
    self.ViewAreaModels = {}
end

function XRpgMakerGameMonsterData:RemoveSentryLineModels()
    for _, v in pairs(self.SentryLineModels) do
        v:Dispose()
    end
    self.SentryLineModels = {}
end

function XRpgMakerGameMonsterData:InitData()
    local monsterId = self:GetId()
    --设置初始SkillTypes
    local skillTypes = XMVCA.XRpgMakerGame:GetConfig():GetMonsterInitSkillTypes(monsterId)
    self:InitSkillTypes(skillTypes)
    -- local pointX = XMVCA.XRpgMakerGame:GetConfig():GetMonsterX(monsterId)
    -- local pointY = XMVCA.XRpgMakerGame:GetConfig():GetMonsterY(monsterId)
    -- self:UpdatePosition({PositionX = pointX, PositionY = pointY})
    local direction = XMVCA.XRpgMakerGame:GetConfig():GetMonsterDirection(monsterId)
    self:SetFaceDirection(direction)
    self:SetCurrentHp(DefaultHp)

    self:RemoveViewAreaAndLine()
    self:RemoveBurnedEffect()
    self:InitSentryData()
    if not XTool.IsTableEmpty(self.MapObjData) then
        self:InitDataByMapObjData(self.MapObjData)
    end
end

---@param mapObjData XMapObjectData
function XRpgMakerGameMonsterData:InitDataByMapObjData(mapObjData)
    self.MapObjData = mapObjData
    self:UpdatePosition({PositionX = mapObjData:GetX(), PositionY = mapObjData:GetY()})
end

function XRpgMakerGameMonsterData:UpdateData(data)
    self._CurrentHp = data.CurrentHp
    self._FaceDirection = data.FaceDirection
    self.Sentry:UpdateData(data)
    self:UpdatePosition(data)
    self:ChangeSkillTypes(data.SkillTypes)
end

function XRpgMakerGameMonsterData:SetCurrentHp(hp)
    self._CurrentHp = hp
end

function XRpgMakerGameMonsterData:SetFaceDirection(faceDirection)
    self._FaceDirection = faceDirection
end

function XRpgMakerGameMonsterData:GetFaceDirection()
    return self._FaceDirection
end

function XRpgMakerGameMonsterData:GetCurrentHp()
    return self._CurrentHp
end

function XRpgMakerGameMonsterData:Death(cb)
    self:Die()
    XRpgMakerGameMonsterData.Super.Death(self, cb)
end

function XRpgMakerGameMonsterData:IsDeath()
    local currentHp = self:GetCurrentHp()
    return currentHp <= 0
end

function XRpgMakerGameMonsterData:OnDie()
    self:SetCurrentHp(0)
    self:RemoveViewAreaModels()
    self:RemoveResourcePool()
end

--朝向转方向
function XRpgMakerGameMonsterData:FaceToDirection(faceDirection)
    local curDirection = self:GetFaceDirection()
    local direction
    if faceDirection == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterViewAreaType.ViewBack then
        if curDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown then
            direction = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp
        elseif curDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp then
            direction = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown
        elseif curDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft then
            direction = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight
        elseif curDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight then
            direction = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft
        end

    elseif faceDirection == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterViewAreaType.ViewLeft then
        if curDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown then
            direction = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight
        elseif curDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp then
            direction = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft
        elseif curDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft then
            direction = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown
        elseif curDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight then
            direction = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp
        end

    elseif faceDirection == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterViewAreaType.ViewRight then
        if curDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown then
            direction = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft
        elseif curDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp then
            direction = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight
        elseif curDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft then
            direction = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp
        elseif curDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight then
            direction = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown
        end
    end
    return direction or curDirection
end

--设置视野范围
function XRpgMakerGameMonsterData:SetGameObjectViewArea()
    self:RemoveViewAreaModels()
    self:RemoveViewAreaResource()

    if self:IsDeath() then
        return
    end

    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end
    
    local monsterId = self:GetId()
    local viewFront = XMVCA.XRpgMakerGame:GetConfig():GetMonsterViewFront(monsterId)
    local viewBack = XMVCA.XRpgMakerGame:GetConfig():GetMonsterViewBack(monsterId)
    local viewLeft = XMVCA.XRpgMakerGame:GetConfig():GetMonsterViewLeft(monsterId)
    local viewRight = XMVCA.XRpgMakerGame:GetConfig():GetMonsterViewRight(monsterId)
    if not IsNumberValid(viewFront) and not IsNumberValid(viewBack) and not IsNumberValid(viewLeft) and not IsNumberValid(viewRight) then
        return
    end
    
    local modelKey = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.ViewArea
    local effectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(modelKey)
    self.ViewAreaResourcePath = effectPath
    
    
    local viewAreaEffectPos = self:GetViewAreaEffectPos()
    local row, col
    local monsterPosX = self:GetPositionX()
    local monsterPosY = self:GetPositionY()

    local isNotUsePool = true
    local InsertModel = function(row, col, models, faceDirection)
        local cubeTransform = self:GetCubeTransform(row, col)
        if not cubeTransform then
            return
        end

        local direction = self:FaceToDirection(faceDirection)
        local isNextSet = XDataCenter.RpgMakerGameManager.IsCurGapSet(monsterPosX, monsterPosY, direction)
        if not isNextSet then
            return
        end

        local resource = self:ResourceManagerLoad(effectPath)
        local asset = resource.Asset
        local cubeUpCenterPosition = self:GetCubeUpCenterPosition(row, col)
        local model = self:LoadEffect(asset, cubeUpCenterPosition, cubeTransform, isNotUsePool)
        tableInsert(models, model)
    end

    local viewType = XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterViewAreaType
    if IsNumberValid(viewFront) then
        row, col = viewAreaEffectPos[viewType.ViewFront].row, viewAreaEffectPos[viewType.ViewFront].col
        InsertModel(row, col, self.ViewAreaModels, viewType.ViewFront)
    end

    if IsNumberValid(viewBack) then
        row, col = viewAreaEffectPos[viewType.ViewBack].row, viewAreaEffectPos[viewType.ViewBack].col
        InsertModel(row, col, self.ViewAreaModels, viewType.ViewBack)
    end

    if IsNumberValid(viewLeft) then
        row, col = viewAreaEffectPos[viewType.ViewLeft].row, viewAreaEffectPos[viewType.ViewLeft].col
        InsertModel(row, col, self.ViewAreaModels, viewType.ViewLeft)
    end

    if IsNumberValid(viewRight) then
        row, col = viewAreaEffectPos[viewType.ViewRight].row, viewAreaEffectPos[viewType.ViewRight].col
        InsertModel(row, col, self.ViewAreaModels, viewType.ViewRight)
    end
end

function XRpgMakerGameMonsterData:GetViewAreaEffectPos()
    local direction = self:GetFaceDirection()
    local positionX = self:GetPositionX()
    local positionY = self:GetPositionY()
    local intervalPos = 1   --间隔多少位置设置

    local viewType = XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterViewAreaType
    local viewAreaPos = {}
    if direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft then
        viewAreaPos[viewType.ViewFront] = {row = positionY, col = positionX - intervalPos}
        viewAreaPos[viewType.ViewBack] = {row = positionY, col = positionX + intervalPos}
        viewAreaPos[viewType.ViewLeft] = {row = positionY - intervalPos, col = positionX}
        viewAreaPos[viewType.ViewRight] = {row = positionY + intervalPos, col = positionX}

    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight then
        viewAreaPos[viewType.ViewFront] = {row = positionY, col = positionX + intervalPos}
        viewAreaPos[viewType.ViewBack] = {row = positionY, col = positionX - intervalPos}
        viewAreaPos[viewType.ViewLeft] = {row = positionY + intervalPos, col = positionX}
        viewAreaPos[viewType.ViewRight] = {row = positionY - intervalPos, col = positionX}

    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp then
        viewAreaPos[viewType.ViewFront] = {row = positionY + intervalPos, col = positionX}
        viewAreaPos[viewType.ViewBack] = {row = positionY - intervalPos, col = positionX}
        viewAreaPos[viewType.ViewLeft] = {row = positionY, col = positionX - intervalPos}
        viewAreaPos[viewType.ViewRight] = {row = positionY, col = positionX + intervalPos}

    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown then
        viewAreaPos[viewType.ViewFront] = {row = positionY - intervalPos, col = positionX}
        viewAreaPos[viewType.ViewBack] = {row = positionY + intervalPos, col = positionX}
        viewAreaPos[viewType.ViewLeft] = {row = positionY, col = positionX - intervalPos}
        viewAreaPos[viewType.ViewRight] = {row = positionY, col = positionX + intervalPos}
    end
    return viewAreaPos
end

function XRpgMakerGameMonsterData:UpdateObjPosAndDirection()
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local x = self:GetPositionX()
    local y = self:GetPositionY()
    local direction = self:GetFaceDirection()
    local cubePosition = self:GetCubeUpCenterPosition(y, x)
    cubePosition.y = transform.position.y
    self:SetGameObjectPosition(cubePosition)
    self:ChangeDirectionAction({Direction = direction})
end

--设置下一回合的移动路线
function XRpgMakerGameMonsterData:SetMoveLine(action)
    self:RemovePatrolLineObjs()

    local direction = action.Direction
    local startPosition = action.StartPosition
    local endPosition = action.EndPosition

    local horizontal = 0    --往水平方向设置特效
    local vertical = 0      --往垂直方向设置特效
    local intervalPos = 1   --间隔多少位置设置

    if direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft then
        horizontal = -intervalPos
    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight then
        horizontal = intervalPos
    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp then
        vertical = intervalPos
    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown then
        vertical = -intervalPos
    end

    if XTool.IsNumberValid(horizontal) then
        self:LoadMoveLineEffect(horizontal, MoveLineEffectType.Horizontal, startPosition, endPosition, direction)
    elseif XTool.IsNumberValid(vertical) then
        self:LoadMoveLineEffect(vertical, MoveLineEffectType.Vertical, startPosition, endPosition, direction)
    end
end

function XRpgMakerGameMonsterData:LoadMoveLineEffect(num, moveLineEffectType, startPosition, endPosition, direction)
    local moveLinePath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.MoveLine)
    local startPosX = startPosition.PositionX
    local startPosY = startPosition.PositionY
    local endPosX = endPosition.PositionX
    local endPosY = endPosition.PositionY
    local cubeUpCenterPos
    local patrolLineObj

    while true do
        if startPosX == endPosX and startPosY == endPosY then
            return
        end

        if moveLineEffectType == MoveLineEffectType.Horizontal then
            startPosX = startPosX + num
        elseif moveLineEffectType == MoveLineEffectType.Vertical then
            startPosY = startPosY + num
        else
            return
        end

        cubeUpCenterPos = self:GetCubeUpCenterPosition(startPosY, startPosX)
        if not cubeUpCenterPos then
            return
        end

        patrolLineObj = XRpgMakerGameMonsterPatrolLine.New()
        patrolLineObj:LoadPatrolLine(moveLinePath, startPosX, startPosY, direction)
        tableInsert(self.PatrolLineObjs, patrolLineObj) 
    end
end

function XRpgMakerGameMonsterData:CheckLoadTriggerEndEffect()
    local monsterId = self:GetId()
    if not XMVCA.XRpgMakerGame:GetConfig():IsMonsterTriggerEnd(monsterId) then
        return
    end

    local effectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.MonsterTriggerEffect)
    local resource = self.TriggerEffectResource
    if not resource then
        local link = self.Transform:FindTransform("Dummy001") -- 目前只有库洛洛模型会挂特效，挂在Dummy001节点随模型上下抖动
        local root = CS.UnityEngine.GameObject(effectPath)
        root.transform:SetParent(link)
        self.TriggerEffectResource = {Asset = root:LoadPrefab(effectPath)}
        root.transform.localPosition = XLuaVector3.New(0, 0, 0)
        return
    end
    if resource == nil or not resource.Asset then
        XLog.Error(string.format("XRpgMakerGameMonsterData加载开启终点的指示特效:%s失败", effectPath))
        return
    end

    local modelName = self:GetModelName()
    local effectRootName = XMVCA.XRpgMakerGame:GetConfig():GetAnimationEffectRoot(modelName)
    local transform = self:GetTransform()
    local effectRoot = transform:FindTransform(effectRootName)
    if XTool.UObjIsNil(effectRoot) then
        XLog.Error(string.format("XRpgMakerGameObject:CheckLoadTriggerEndEffect error: 终点指示特效父节点找不到, effectRootName: %s，modelName：%s", effectRootName, modelName))
        return
    end

    local asset = resource.Asset
    self:LoadEffect(asset, effectRoot.transform.position, effectRoot)
end

--杀死玩家
function XRpgMakerGameMonsterData:PlayKillPlayerAction(action, cb)
    self:PlayAtkAction(function()
        local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
        playerObj:LoadDieEffect(cb)
    end)
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_MonsterAttack)
end

--杀死影子
function XRpgMakerGameMonsterData:PlayKillShadowAction(action, cb)
    self:PlayAtkAction(function()
        local shadowObj = XDataCenter.RpgMakerGameManager.GetShadowObj(action.ShadowId)
        shadowObj:LoadDieEffect(cb)
    end)
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_MonsterAttack)
end

--检查是否死亡并设置模型显示状态
function XRpgMakerGameMonsterData:CheckIsDeath()
    local isDeath = self:IsDeath()
    self:SetActive(not isDeath)
end

--小怪或人类移动前先播放惊动的动作再移动
function XRpgMakerGameMonsterData:PlayMoveAction(action, cb, mapId)
    local id = self:GetId()
    local skillType = XMVCA.XRpgMakerGame:GetConfig():GetMonsterSkillType(self:GetId())
    self:CheckIsSteelAdsorb(mapId, action.EndPosition.PositionX, action.EndPosition.PositionY, skillType)

    --检查下一个动作
    local nextAction = XDataCenter.RpgMakerGameManager.GetNextAction(true)
    if nextAction then
        if nextAction.ActionType == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameActionType.ActionMonsterTransfer then
            self:SetIsTranser(true)
        end
    end

    local monsterType = XMVCA.XRpgMakerGame:GetConfig():GetMonsterType(id)
    if monsterType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.Normal or monsterType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.Human then
        self:PlayAlarmAnima(function()
            XRpgMakerGameMonsterData.Super.PlayMoveAction(self, action, cb, skillType)
        end)
        return
    end
    XRpgMakerGameMonsterData.Super.PlayMoveAction(self, action, cb, skillType)

    local isSamePos = action.StartPosition.PositionX == action.EndPosition.PositionX and action.StartPosition.PositionY == action.EndPosition.PositionY
    if not isSamePos then
        if self.MonsterType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.Sepaktakraw then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_SepaktakrawRun)
        else
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_MonsterRun)
        end
    end
end

------------哨戒 begin--------------
function XRpgMakerGameMonsterData:InitSentryData()
    self.Sentry:UpdateData({})
end

--哨戒指示物位置数据
function XRpgMakerGameMonsterData:UpdateSentrySignAction(action)
    local startPosition = action.StartPosition
    local startPosX = self:GetPositionX()
    local startPosY = self:GetPositionY()
    local endPosX = startPosition and startPosition.PositionX or 0
    local endPosY = startPosition and startPosition.PositionY or 0
    local curRount = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    curRount = curRount and curRount + 1 or 0       --创建指示物的回合数同步服务端+1
    self.Sentry:UpdatePosition({PositionX = startPosX, PositionY = startPosY})
    self.Sentry:UpdateData({SentryStartPositionX = startPosX,
        SentryStartPositionY = startPosY,
        SentryEndPositionX = endPosX,
        SentryEndPositionY = endPosY,
        SentryStartRound = curRount})
end

function XRpgMakerGameMonsterData:CheckRemoveSentry()
    if not self.Sentry:IsCreateSentry() then
        self:RemoveSentry()
    end
end

--加载哨戒指示物
function XRpgMakerGameMonsterData:LoadSentrySign()
    self:RemoveSentry()
    if not self.Sentry:IsCreateSentry() or self:IsDeath() then
        return
    end

    local position = self:GetGameObjPosition()
    local modelName = self:GetModelName()
    local yOffset = XMVCA.XRpgMakerGame:GetConfig():GetAnimationSentrySignYOffset(modelName)
    self.Sentry:Load(position + Vector3(0, yOffset, 0))

    if self.Sentry:IsShowNextRoundSentry() then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_SentrySign)
    end
end

--设置哨戒警戒线
function XRpgMakerGameMonsterData:SetSentryLine()
    self:RemoveSentryLineModels()

    if self:IsDeath() then
        return
    end

    --生成指示物的第一回合会生成警戒线，之后直到指示物消失才会重新生成警戒线
    if not self.Sentry:InFirstRoundCreate() and self.Sentry:IsCreateSentry() then
        return
    end

    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    --哨戒路线
    local modelKey = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.SentryLine
    local effectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(modelKey)
    local monsterId = self:GetId()
    local sentryFront = XMVCA.XRpgMakerGame:GetConfig():GetMonsterSentryFront(monsterId)
    local sentryBack = XMVCA.XRpgMakerGame:GetConfig():GetMonsterSentryBack(monsterId)
    local sentryLeft = XMVCA.XRpgMakerGame:GetConfig():GetMonsterSentryLeft(monsterId)
    local sentryRight = XMVCA.XRpgMakerGame:GetConfig():GetMonsterSentryRight(monsterId)
    local faceDirection = self:GetFaceDirection()
    local direction

    local InsertModel = function(direction)
        local intervalPos = 1   --间隔多少位置设置
        --往水平方向设置特效
        local horizontal = (direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft and -intervalPos) or (direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight and intervalPos) or 0
        --往垂直方向设置特效
        local vertical = (direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown and -intervalPos) or (direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp and intervalPos) or 0

        local posX, posY = self:GetPositionX(), self:GetPositionY()
        local cubeUpCenterPos
        local obj
        local isCurSet       --是否能在当前的坐标中设置
        local isNextSet = XDataCenter.RpgMakerGameManager.IsCurGapSet(posX, posY, direction)      --是否能继续在下一个坐标中设置

        while isNextSet do
            posX = posX + horizontal
            posY = posY + vertical
            cubeUpCenterPos = self:GetCubeUpCenterPosition(posX, posY)
            if not cubeUpCenterPos then
                return
            end

            isCurSet, isNextSet = XDataCenter.RpgMakerGameManager.IsCurPositionSet(posX, posY, direction)

            if isCurSet then
                obj = XRpgMakerGameMonsterPatrolLine.New()
                obj:LoadPatrolLine(effectPath, posX, posY, direction)
                tableInsert(self.SentryLineModels, obj) 
            end
        end
    end

    if IsNumberValid(sentryFront) then
        InsertModel(faceDirection)
    end

    if IsNumberValid(sentryBack) then
        direction = self:FaceToDirection(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterViewAreaType.ViewBack)
        InsertModel(direction)
    end

    if IsNumberValid(sentryLeft) then
        direction = self:FaceToDirection(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterViewAreaType.ViewLeft)
        InsertModel(direction)
    end

    if IsNumberValid(sentryRight) then
        direction = self:FaceToDirection(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterViewAreaType.ViewRight)
        InsertModel(direction)
    end
end

function XRpgMakerGameMonsterData:IsSentryShowLastStopRound()
    return self.Sentry:IsShowLastStopRound()
end

function XRpgMakerGameMonsterData:GetSentryLastStopRound()
    return self.Sentry:GetLastStopRound()
end

function XRpgMakerGameMonsterData:GetSentryRoandGameObjPosition()
    return self.Sentry:GetSentryRoandGameObjPosition()
end
------------哨戒 end----------------

function XRpgMakerGameMonsterData:SetViewAreaAndLine()
    if self:IsDeath() then
        return
    end
    self:SetGameObjectViewArea()
    self:SetSentryLine()
end

function XRpgMakerGameMonsterData:RemoveViewAreaAndLine()
    self:RemovePatrolLineObjs()
    self:RemoveViewAreaModels()
    self:RemoveSentryLineModels()
end

function XRpgMakerGameMonsterData:LoadBurnedEffect()
    self.BurnedEffect = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.BurnedEffect)
    local resource = self:ResourceManagerLoad(self.BurnedEffect)
    self:LoadEffect(resource.Asset)
end

function XRpgMakerGameMonsterData:RemoveBurnedEffect()
    if self.BurnedEffect then
        self:RemoveResource(self.BurnedEffect)
        self.BurnedEffect = nil
    end
end

-- 是否是藤球
function XRpgMakerGameMonsterData:IsSepaktakraw()
    return self.MonsterType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.Sepaktakraw
end

-- 属性类型变化
function XRpgMakerGameMonsterData:OnSkillTypesChange(oldSkillTypes, skillTypes)
    local skillTypeDic = {}
    for _, skillType in pairs(oldSkillTypes) do
        skillTypeDic[skillType] = true
    end
    
    -- 新增属性
    for _, skillType in pairs(skillTypes) do
        if not skillTypeDic[skillType] then
            -- 被点燃
            if skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Flame2 then
                XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_FireUp)
                self:PlayAlarmAnima()
            end
        end
    end
end

return XRpgMakerGameMonsterData