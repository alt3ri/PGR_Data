local tableInsert = table.insert

---@class XRpgMakerGameScene : XControl
---@field private _MainControl XRpgMakerGameControl
---@field private _Model XRpgMakerGameModel
---@field PlayerObj XRpgMakerGamePlayer
---@field EndPointObj XRpgMakerGameEndPoint
---@field TorchObjs XRpgMakerGameTorch[]
local XRpgMakerGameScene = XClass(XControl, "XRpgMakerGameScene")

function XRpgMakerGameScene:LoadScene()
    self.MapId = self._Model.MapId
    self.SelectRoleId = self._Model.SelectRoleId
    self.StageId = self._Model.StageId
    self.PlayerObj = nil
    self.EndPointObj = nil
    self.BlockObjs = {}
    self.GapObjs = {}
    self.CubeObjs = {}
    self.TrapObjs = {}
    self.NewGrowObjs = {}   --非配置生成的草圃对象字典
    self.SwitchSkillPointObjs = {} -- 换属性阵
    self.TorchObjs = {} -- 火炬

    self:GenerateSceneMap()
end

-- 生成场景地图
function XRpgMakerGameScene:GenerateSceneMap()
    -- 打开Loading界面
    XLuaUiManager.Open("UiFubenRpgMakerGameMovie", self._Model.StageId)
    
    -- 加载场景预制体
    local mapId = self.MapId
    local sceneUrl = self:GetConfig():GetMapPrefab(mapId)
    self.Root = CS.UnityEngine.GameObject("RpgMakerGameScene")
    local link = CS.UnityEngine.GameObject(sceneUrl)
    link.transform:SetParent(self.Root.transform)
    self.GameObject = link:LoadPrefab(sceneUrl)
    self.SceneObjRoot = XUiHelper.TryGetComponent(self.GameObject.transform, "GroupBase/Objects")
    
    -- 初始化
    XDataCenter.RpgMakerGameManager.InitStageMap(mapId)
    self:InitCamera()
    self:InitCube(mapId)
    self:InitBlock(mapId)
    self:InitEntity(mapId)
    self:InitGap(mapId)
    self:InitEndPoint(mapId)
    self:InitTriggerPoint(mapId)
    self:InitElectricFence(mapId)
    self:InitTrap(mapId)
    self:InitPlayer(mapId)
    self:InitMonster(mapId)
    self:InitShadow(mapId)
    self:InitTransferPoint(mapId)
    self:InitBubble(mapId)
    self:InitDrop(mapId)
    self:InitMagic(mapId)
    self:InitSwitchSkillPoint(mapId)
    self:InitTorch(mapId)
    
    -- 场景加载完成回调
    self:OnSceneLoadComplete()
end

-- 场景加载完成
function XRpgMakerGameScene:OnSceneLoadComplete()
    XLuaUiManager.Remove("UiRpgMakerGameDetail")
    XLuaUiManager.Remove("UiRpgMakerGameChoice")

    -- 延迟Loading界面关闭的时间
    local delay = CS.XGame.ClientConfig:GetInt("RpgMakerGameLoadingDelayClose")
    self.DelayTimer = XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.Close("UiFubenRpgMakerGameMovie")
        if not XLuaUiManager.IsUiLoad("UiRpgMakerGamePlayMain") then
            XLuaUiManager.Open("UiRpgMakerGamePlayMain")
        end
        self:SetSceneActive(false) --处理光照异常
        self:SetSceneActive(true)
        self.DelayTimer = nil
    end, delay)

    -- 注册事件
    self:RegisterEvents()
end

function XRpgMakerGameScene:RegisterEvents()
    local beijing = XUiHelper.TryGetComponent(self.GameObject.transform, "GroupBase/Beijing")
    local childCnt = beijing.transform.childCount
    for i = 1, childCnt do
        local childGo = beijing:GetChild(i - 1)
        if childGo.gameObject.name == "Plane" and childGo.gameObject.activeSelf then -- 场景还有一个隐藏的Plane，代码处理获取显示的Plane
            self.Plane = childGo
            break
        end
    end
    
    self.GoInputHandler = self.Plane:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler = self.Plane.gameObject:AddComponent(typeof(CS.XGoInputHandler))
    end

    self.GoInputHandler:AddPointerDownListener(function(eventData) self:OnPointerDown(eventData) end)
    self.GoInputHandler:AddPointerUpListener(function(eventData) self:OnPointerUp(eventData) end)
end

function XRpgMakerGameScene:OnPointerDown()
    XDataCenter.RpgMakerGameManager.FirePointerDownObjectCallback()
end

function XRpgMakerGameScene:OnPointerUp()
    XDataCenter.RpgMakerGameManager.FirePointerUpObjectCallback()
end

function XRpgMakerGameScene:GetConfig()
    return self._Model:GetConfig()
end

function XRpgMakerGameScene:GetMapId()
    return self.MapId    
end

-- 释放场景
function XRpgMakerGameScene:OnRelease()
    if self.Root then
        CS.UnityEngine.GameObject.Destroy(self.Root)
        self.Root = nil
        self.GameObject = nil
    end

    if self.DelayTimer then
        XScheduleManager.UnSchedule(self.DelayTimer)
        self.DelayTimer = nil
    end
    self.ActionClass = nil
    
    -- 释放对象
    if self.PlayerObj then
        self.PlayerObj:Release()
        self.PlayerObj = nil
    end
    
    if self.PlayerObj then
        self.PlayerObj:Release()
        self.PlayerObj = nil
    end
    
    if self.EndPointObj then
        self.EndPointObj:Release()
        self.EndPointObj = nil
    end

    if self.BlockObjs then
        for _, rawObjs in pairs(self.BlockObjs) do
            for _, obj in pairs(rawObjs) do
                obj:Release()
            end
        end
        self.BlockObjs = nil
    end

    if self.GapObjs then
        for _, obj in pairs(self.GapObjs) do
            obj:Release()
        end
        self.GapObjs = nil
    end

    if self.CubeObjs then
        for _, rawObjs in pairs(self.CubeObjs) do
            for _, obj in pairs(rawObjs) do
                obj:Release()
            end
        end
        self.CubeObjs = nil
    end

    if self.TrapObjs then
        for _, obj in pairs(self.TrapObjs) do
            obj:Release()
        end
        self.TrapObjs = nil
    end

    if self.NewGrowObjs then
        for _, rawObjs in pairs(self.NewGrowObjs) do
            for _, obj in pairs(rawObjs) do
                obj:Release()
            end
        end
        self.NewGrowObjs = nil
    end

    if self.SwitchSkillPointObjs then
        for _, obj in pairs(self.SwitchSkillPointObjs) do
            obj:Release()
        end
        self.SwitchSkillPointObjs = nil
    end

    if self.TorchObjs then
        for _, obj in pairs(self.TorchObjs) do
            obj:Release()
        end
        self.TorchObjs = nil
    end

    local shadowObjDic = XDataCenter.RpgMakerGameManager.GetShadowObjDic()
    if shadowObjDic then
        for _, obj in pairs(shadowObjDic) do
            obj:Release()
        end
    end
    
    local electricFenceObjDic = XDataCenter.RpgMakerGameManager.GetElectricFenceObjDic()
    if electricFenceObjDic then
        for _, obj in pairs(electricFenceObjDic) do
            obj:Release()
        end
    end
    
    local grassObjDic = XDataCenter.RpgMakerGameManager.GetGrassObjDic()
    if grassObjDic then
        for _, obj in pairs(grassObjDic) do
            obj:Release()
        end
    end
    
    local transferPointObjDic = XDataCenter.RpgMakerGameManager.GetTransferPointObjDic()
    if transferPointObjDic then
        for _, obj in pairs(transferPointObjDic) do
            obj:Release()
        end
    end
    
    local steelObjDic = XDataCenter.RpgMakerGameManager.GetSteelObjDic()
    if steelObjDic then
        for _, obj in pairs(steelObjDic) do
            obj:Release()
        end
    end
    
    local waterObjDic = XDataCenter.RpgMakerGameManager.GetWaterObjDic()
    if waterObjDic then
        for _, obj in pairs(waterObjDic) do
            obj:Release()
        end
    end
    
    local bubbleObjDic = XDataCenter.RpgMakerGameManager.GetBubbleObjDic()
    if bubbleObjDic then
        for _, obj in pairs(bubbleObjDic) do
            obj:Release()
        end
    end
    
    local dropObjDic = XDataCenter.RpgMakerGameManager.GetDropObjDic()
    if dropObjDic then
        for _, obj in pairs(dropObjDic) do
            obj:Release()
        end
    end
    
    local magicObjDic = XDataCenter.RpgMakerGameManager.GetMagicObjDic()
    if magicObjDic then
        for _, obj in pairs(magicObjDic) do
            obj:Release()
        end
    end

    local monsterObjDic = XDataCenter.RpgMakerGameManager.GetGameMonsterObjDic()
    if monsterObjDic then
        for _, obj in pairs(monsterObjDic) do
            obj:Release()
        end
    end
end

---设置场景对象的位置，和二维坐标
---@param cubeX number 二维X坐标
---@param cubeY number 二维Y坐标
---@param obj any
function XRpgMakerGameScene:SetObjPosition(cubeX, cubeY, obj)
    local cube = self:GetCubeObj(cubeY, cubeX)
    if not cube then
        XLog.Error("设置场景对象的位置错误：", cubeY, cubeX, obj)
        return
    end
    local cubePosition = cube:GetGameObjUpCenterPosition()
    obj:UpdatePosition({PositionX = cubeX, PositionY = cubeY})
    obj:SetGameObjectPosition(cubePosition)
end

---初始化实体
function XRpgMakerGameScene:InitEntity(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local obj
    local modelPath
    local entityType
    local modelKey
    local x, y
    local entityData

    local trapModelPath = self:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Trap)
    local mapEntityDataList = XRpgMakerGameConfigs.GetMixBlockEntityList(mapId)
    local XRpgMakerGameTrap = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameTrap")

    for index, data in ipairs(mapEntityDataList) do
        --加载模型
        obj = XDataCenter.RpgMakerGameManager.GetEntityObj(index)
        entityData = obj:GetMapObjData()
        entityType = entityData:GetType()
        modelKey = XRpgMakerGameConfigs.GetMixBlockModelEntityKey(entityType)
        modelPath = self:GetConfig():GetModelPath(modelKey)
        obj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)

        --设置位置
        x = entityData:GetX()
        y = entityData:GetY()
        self:SetObjPosition(x, y, obj)

        --额外加载陷阱
        if entityData:GetParams()[2] == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameSteelBrokenType.Trap then
            local trapObj = XRpgMakerGameTrap.New()
            trapObj:LoadModel(trapModelPath, sceneObjRoot, nil, XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Trap)
            self:SetObjPosition(x, y, trapObj)
        end
    end
end

--region 草圃相关
--非配置的草圃生长
function XRpgMakerGameScene:GrowGrass(x, y)
    local curRoundCount = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    local obj = self.NewGrowObjs[x] and self.NewGrowObjs[x][y]
    if obj then
        obj:SetRoundState(curRoundCount, true)
        obj:SetActive(true)
        return
    end

    if not self.NewGrowObjs[x] then
        self.NewGrowObjs[x] = {}
    end

    local modelKey = XRpgMakerGameConfigs.GetModelEntityKey(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Grass)
    local modelPath = self:GetConfig():GetModelPath(modelKey)
    local XRpgMakerGameGrassData = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameGrassData")
    obj = XRpgMakerGameGrassData.New()
    obj:LoadModel(modelPath, self:GetSceneObjRoot(), nil, modelKey)
    obj:SetRoundState(curRoundCount, true)
    obj:PlayGrowSound()
    self:SetObjPosition(x, y, obj)
    self.NewGrowObjs[x][y] = obj
end

--非配置的草圃燃烧
function XRpgMakerGameScene:BurnGrass(x, y)
    local curRoundCount = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    local obj = self.NewGrowObjs[x] and self.NewGrowObjs[x][y]
    if not obj then
        return
    end
    obj:SetRoundState(curRoundCount, false)
    obj:Burn()
end

--根据回合数检查非配置的草圃是否显示，并删除指定回合数以上的数据
function XRpgMakerGameScene:CheckGrowActive(currRound)
    for _, growObjs in pairs(self.NewGrowObjs) do
        for _, growObj in pairs(growObjs) do
            growObj:CheckRoundState(currRound)
        end
    end
end

--重置所有非配置的草圃
function XRpgMakerGameScene:ResetGrow()
    for _, growObjs in pairs(self.NewGrowObjs) do
        for _, growObj in pairs(growObjs) do
            XUiHelper.Destroy(growObj:GetGameObject())
        end
    end
    self.NewGrowObjs = {}
end

--获得草圃
function XRpgMakerGameScene:GetGrass(x, y)
    -- 非配置草圃
    if self.NewGrowObjs[x] and self.NewGrowObjs[x][y] then
        return self.NewGrowObjs[x][y]
    end
    -- 配置草圃
    return XDataCenter.RpgMakerGameManager.GetEntityObjByPosition(x, y, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Grass)
end
--endregion



--region 地图初始化
function XRpgMakerGameScene:InitCamera()
    --镜头角度与地图适配
    local row = self:GetConfig():GetMapRow(self:GetMapId())
    local cameras = {}
    for i = 8, 10, 1 do
        local cameraName = "Camera" .. i
        local camera = self.GameObject.transform:Find(cameraName)
        if not XTool.UObjIsNil(camera) then
            tableInsert(cameras, camera)
            if i == row then
                self.Camera = camera:GetComponent("Camera")
            end
            camera.gameObject:SetActiveEx(false)
        end
    end
    if XTool.UObjIsNil(self.Camera) then
        self.Camera = self.GameObject.transform:Find("Camera"):GetComponent("Camera")
    end
    self.Camera.gameObject:SetActiveEx(true)
    self.PhysicsRaycaster = self.Camera.gameObject:AddComponent(typeof(CS.UnityEngine.EventSystems.PhysicsRaycaster))
end

--初始化传送
function XRpgMakerGameScene:InitTransferPoint(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local obj
    local modelPath
    local modelKey
    local color
    local x, y

    local mapTransferPointDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.TransferPoint)
    for index, data in ipairs(mapTransferPointDataList) do
        --加载模型
        obj = XDataCenter.RpgMakerGameManager.GetTransferPointObj(index)
        color = data:GetParams()[1]
        modelKey = XRpgMakerGameConfigs.GetTransferPointLoopColorKey(color)
        modelPath = self:GetConfig():GetModelPath(modelKey)
        obj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
        --设置位置
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, obj)
    end
end

--初始化机关
function XRpgMakerGameScene:InitTriggerPoint(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local triggerObj
    local modelPath
    local triggerType
    local modelKey
    local isElectricOpen
    local x, y

    local mapTriggerDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Trigger)
    for _, data in ipairs(mapTriggerDataList) do
        local triggerId = data:GetParams()[1]
        --加载模型
        triggerObj = XDataCenter.RpgMakerGameManager.GetTriggerObj(triggerId)
        isElectricOpen = triggerObj:IsElectricOpen()
        triggerType = self:GetConfig():GetTriggerType(triggerId)
        modelKey = XRpgMakerGameConfigs.GetRpgMakerGameTriggerKey(triggerType, isElectricOpen)
        modelPath = self:GetConfig():GetModelPath(modelKey)
        triggerObj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
        --设置位置
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, triggerObj)

        triggerObj:UpdateObjTriggerStatus(true)
    end
end

--初始化缝隙
function XRpgMakerGameScene:InitGap(mapId)
    local sceneGameRoot = self:GetSceneObjRoot()
    local x, y
    local direction
    local gameObj
    local modelKey = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Gap
    local modelPath = self:GetConfig():GetModelPath(modelKey)
    local XRpgMakerGameGap = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameGap")

    local mapGapDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Gap)
    for index, gapData in ipairs(mapGapDataList) do
        --加载模型
        gameObj = XRpgMakerGameGap.New(index)
        gameObj:InitDataByMapObjData(gapData)
        gameObj:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        --设置位置和方向
        x = gapData:GetX()
        y = gapData:GetY()
        self:SetObjPosition(x, y, gameObj)
        direction = gapData:GetParams()[1]
        gameObj:ChangeDirectionAction({ Direction = direction })

        self.GapObjs[index] = gameObj
    end
end

--初始化电网
function XRpgMakerGameScene:InitElectricFence(mapId)
    local sceneGameRoot = self:GetSceneObjRoot()
    local x, y
    local direction
    local gameObj
    local modelKey = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.ElectricFence
    local modelPath = self:GetConfig():GetModelPath(modelKey)

    local mapElectricFenceDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.ElectricFence)
    for index, data in ipairs(mapElectricFenceDataList) do
        --加载模型
        gameObj = XDataCenter.RpgMakerGameManager.GetElectricFenceObj(index)
        gameObj:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        --设置位置和方向
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, gameObj)
        direction = data:GetParams()[1]
        gameObj:ChangeDirectionAction({ Direction = direction })
    end
end

--初始化影子
function XRpgMakerGameScene:InitShadow(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local shadowObj
    local x, y
    local direction
    -- 影子特效key 根据roleId读取
    local stageId = XDataCenter.RpgMakerGameManager.GetRpgMakerGameEnterStageDb():GetStageId()
    local roleId = self:GetConfig():GetStageShadowId(stageId)
    if not XTool.IsNumberValid(roleId) then
        return
    end
    local modelName = self:GetConfig():GetRoleModelAssetPath(roleId)
    local modelKey = XRpgMakerGameConfigs.GetModelSkillShadowEffctKey(self:GetConfig():GetRoleSkillType(roleId))

    local mapShadowDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Shadow)
    for _, data in ipairs(mapShadowDataList) do
        local shadowId = data:GetParams()[1]
        --加载模型
        shadowObj = XDataCenter.RpgMakerGameManager.GetShadowObj(shadowId)
        shadowObj:LoadModel(nil, sceneObjRoot, modelName, modelKey)
        --设置位置和方向
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, shadowObj)
        direction = data:GetParams()[2]
        shadowObj:ChangeDirectionAction({ Direction = direction })
    end
end

--初始化陷阱
function XRpgMakerGameScene:InitTrap(mapId)
    local x, y
    local obj
    local sceneObjRoot = self:GetSceneObjRoot()
    local modelKey = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Trap
    local modelPath = self:GetConfig():GetModelPath(modelKey)

    local XRpgMakerGameTrap = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameTrap")
    local mapTrapDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Trap)
    for index, data in ipairs(mapTrapDataList) do
        --加载模型
        obj = XRpgMakerGameTrap.New(index)
        obj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
        self.TrapObjs[index] = obj
        --设置位置
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, obj)
    end
end

--初始化终点
function XRpgMakerGameScene:InitEndPoint(mapId)
    local endPointDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.EndPoint)
    local endPointData = endPointDataList[1]
    if not endPointData then
        XLog.Error(string.format("Map %s 未配置终点坐标!"))
        return
    end

    local XRpgMakerGameEndPoint = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameEndPoint")
    self.EndPointObj = XRpgMakerGameEndPoint.New()
    self.EndPointObj:InitData(endPointData)

    --加载模型
    local sceneObjRoot = self:GetSceneObjRoot()
    local modelKey = self.EndPointObj:IsOpen() and XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.GoldOpen or XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.GoldClose
    local modelPath = self:GetConfig():GetModelPath(modelKey)
    self.EndPointObj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
    --设置位置
    local x = endPointData:GetX()
    local y = endPointData:GetY()
    self:SetObjPosition(x, y, self.EndPointObj)
end

function XRpgMakerGameScene:GetEndPointObj()
    return self.EndPointObj
end

function XRpgMakerGameScene:InitMonster(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local monsterObj
    local modelName
    local x, y
    local direction
    local skillType

    local mapMonsterDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Monster)
    for _, data in ipairs(mapMonsterDataList) do
        local monsterId = data:GetParams()[1]
        local modelKey = self:GetConfig():GetMonsterModelKey(monsterId)
        --加载模型
        monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
        modelName = self:GetConfig():GetMonsterPrefab(monsterId)
        monsterObj:LoadModel(nil, sceneObjRoot, modelName, modelKey)
        monsterObj:CheckLoadTriggerEndEffect()
        --设置位置和方向
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, monsterObj)
        direction = self:GetConfig():GetMonsterDirection(monsterId)
        monsterObj:ChangeDirectionAction({ Direction = direction })
        --设置怪物模型初始视野范围
        monsterObj:SetViewAreaAndLine()
        --设置技能特效
        skillType = self:GetConfig():GetMonsterSkillType(monsterId)
        monsterObj:LoadSkillEffect(skillType)
    end
end

function XRpgMakerGameScene:InitPlayer(mapId)
    local startPointDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.StartPoint)
    local startPointData = startPointDataList[1]
    if not startPointData then
        XLog.Error(string.format("Map %s 未配置开始坐标!"))
        return
    end
    local XRpgMakerGamePlayer = require("XEntity/XRpgMakerGame/Object/XRpgMakerGamePlayer")
    self.PlayerObj = XRpgMakerGamePlayer.New()
    self.PlayerObj:InitData(startPointData, self.SelectRoleId)

    --加载玩家角色模型
    local roleId = self.PlayerObj:GetId()
    local modelName = self:GetConfig():GetRoleModelAssetPath(roleId)
    local sceneObjRoot = self:GetSceneObjRoot()
    self.PlayerObj:LoadModel(nil, sceneObjRoot, modelName)
    --设置位置
    local x = startPointData:GetX()
    local y = startPointData:GetY()
    self:SetObjPosition(x, y, self.PlayerObj)
    --设置方向
    local direction = startPointData:GetParams()[1]
    self.PlayerObj:ChangeDirectionAction({ Direction = direction })
    --初始化箭头特效
    self.PlayerObj:LoadMoveDirectionEffect()
    self.PlayerObj:SetMoveDirectionEffectActive(false)
end

function XRpgMakerGameScene:GetPlayerObj()
    return self.PlayerObj
end

--初始化地面
function XRpgMakerGameScene:InitCube(mapId)
    local sceneObjRoot = self:GetSceneObjRoot()
    local cube = XUiHelper.TryGetComponent(sceneObjRoot.transform, "ScenePuzzle01_03Hezi01") or
            XUiHelper.TryGetComponent(sceneObjRoot.transform, "ScenePuzzle02_02Box") or
            XUiHelper.TryGetComponent(sceneObjRoot.transform, "ScenePuzzle03_01Box") or
            XUiHelper.TryGetComponent(sceneObjRoot.transform, "ScenePuzzle04_02Box")
    if not cube then
        XLog.Error(string.format("XRpgMakerGameScene:InitCube没找到ScenePuzzle01_03Hezi01对象 mapId：%s，sceneObjRoot：%s", mapId, sceneObjRoot))
        return
    end

    local cubeMeshFilter = cube:GetComponent("MeshFilter")
    local cubeSize = cubeMeshFilter.mesh.bounds.size

    local row = self:GetConfig():GetMapRow(mapId)
    local col = self:GetConfig():GetMapCol(mapId)
    local modelPath
    local gameObjPositionX
    local gameObjPositionY
    local gameObj
    local firstModelPath
    local secondModelPath
    local curChapterGroupId = XDataCenter.RpgMakerGameManager.GetCurChapterGroupId()
    local prefabs = self:GetConfig():GetChapterGroupGroundPrefab(curChapterGroupId)
    local cubeModelPath1 = prefabs[1]
    local cubeModelPath2 = prefabs[2]
    local poolModelPath = self:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Pool)
    local modelKey
    local XRpgMakerGameCube = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameCube")

    for i = 1, row do
        self.CubeObjs[i] = {}
        firstModelPath = i % 2 ~= 0 and cubeModelPath1 or cubeModelPath2
        secondModelPath = i % 2 == 0 and cubeModelPath1 or cubeModelPath2
        for j = 1, col do
            modelKey = nil
            if XRpgMakerGameConfigs.IsSameMixBlock(mapId, j, i, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Water) or
                    XRpgMakerGameConfigs.IsSameMixBlock(mapId, j, i, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Ice) then
                modelPath = poolModelPath
                modelKey = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Pool
            else
                modelPath = j % 2 ~= 0 and firstModelPath or secondModelPath
            end
            gameObjPositionX = cube.position.x + cubeSize.x * (j - 1)
            gameObjPositionY = cube.position.z + cubeSize.z * (i - 1)
            gameObj = XRpgMakerGameCube.New()
            gameObj:LoadModel(modelPath, sceneObjRoot, nil, modelKey)
            gameObj:SetGameObjectPosition(XLuaVector3.New(gameObjPositionX, cube.position.y, gameObjPositionY))
            self.CubeObjs[i][j] = gameObj
        end
    end

    cube.gameObject:SetActiveEx(false)
end

--初始化阻挡物
function XRpgMakerGameScene:InitBlock(mapId)
    local blockRow
    local colNum
    local blockObjTemp
    local sceneObjRoot = self:GetSceneObjRoot()
    local modelPath = self:GetConfig():GetChapterGroupBlockPrefab(XDataCenter.RpgMakerGameManager.GetCurChapterGroupId())
    local mapBlockDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.BlockType)

    local XRpgMakerGameBlock = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameBlock")
    for _, data in ipairs(mapBlockDataList) do
        colNum = data:GetX()
        blockRow = data:GetY()
        blockObjTemp = XRpgMakerGameBlock.New()
        blockObjTemp:LoadModel(modelPath, sceneObjRoot)
        self:SetObjPosition(colNum, blockRow, blockObjTemp)

        if not self.BlockObjs[blockRow] then
            self.BlockObjs[blockRow] = {}
        end
        self.BlockObjs[blockRow][colNum] = blockObjTemp
    end
end

---初始化泡泡
---@param mapId number
function XRpgMakerGameScene:InitBubble(mapId)
    local sceneGameRoot = self:GetSceneObjRoot()
    local x, y
    local gameObj
    local bubbleId
    local modelKey = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Bubble
    local modelPath = self:GetConfig():GetModelPath(modelKey)

    local mapBubbleDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Bubble)
    for _, data in ipairs(mapBubbleDataList) do
        bubbleId = data:GetParams()[1]
        --加载模型
        gameObj = XDataCenter.RpgMakerGameManager.GetBubbleObj(bubbleId)
        gameObj:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        --设置位置和方向
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, gameObj)
    end
end

---初始化掉落物
---@param mapId number
function XRpgMakerGameScene:InitDrop(mapId)
    local sceneGameRoot = self:GetSceneObjRoot()
    local x, y
    local gameObj
    local dropId, dropType, modelKey, modelPath

    local mapBubbleDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Drop)
    for _, data in ipairs(mapBubbleDataList) do
        dropId = data:GetParams()[1]
        dropType = data:GetParams()[2]
        modelKey = XRpgMakerGameConfigs.GetMixBlockModelDropKey(dropType)
        modelPath = self:GetConfig():GetModelPath(modelKey)
        --加载模型
        gameObj = XDataCenter.RpgMakerGameManager.GetDropObj(dropId)
        gameObj:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        --设置位置和方向
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, gameObj)
    end
end

---初始化魔法阵
---@param mapId number
function XRpgMakerGameScene:InitMagic(mapId)
    local sceneGameRoot = self:GetSceneObjRoot()
    local x, y
    local gameObj
    local modelKey = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Magic
    local modelPath = self:GetConfig():GetModelPath(modelKey)

    local mapMagicDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Magic)
    for index, data in ipairs(mapMagicDataList) do
        --加载模型
        gameObj = XDataCenter.RpgMakerGameManager.GetMagicObj(index)
        gameObj:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        --设置位置和方向
        x = data:GetX()
        y = data:GetY()
        self:SetObjPosition(x, y, gameObj)
    end
end

---初始化换属性阵
function XRpgMakerGameScene:InitSwitchSkillPoint(mapId)
    local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")
    local modelKey = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.SwitchSkillPoint
    local sceneGameRoot = self:GetSceneObjRoot()
    
    self.SwitchSkillPointObjs = {}
    local mapBubbleDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.SwitchSkillType)
    for index, data in ipairs(mapBubbleDataList) do
        ---@type XRpgMakerGameObject
        local go = XRpgMakerGameObject.New()
        self.SwitchSkillPointObjs[index] = go
        local modelPath = self:GetConfig():GetModelPath(modelKey)
        go:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        local x = data:GetX()
        local y = data:GetY()
        self:SetObjPosition(x, y, go)
    end
end

---初始化火炬
function XRpgMakerGameScene:InitTorch(mapId)
    local XRpgMakerGameTorch = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameTorch")
    local modelKey = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Torch
    local sceneGameRoot = self:GetSceneObjRoot()
    
    self.TorchObjs = {}
    local mapBubbleDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Torch)
    for _, data in ipairs(mapBubbleDataList) do
        ---@type XRpgMakerGameTorch
        local go = XRpgMakerGameTorch.New()
        tableInsert(self.TorchObjs, go)
        local modelPath = self:GetConfig():GetModelPath(modelKey)
        go:LoadModel(modelPath, sceneGameRoot, nil, modelKey)
        local x = data:GetX()
        local y = data:GetY()
        self:SetObjPosition(x, y, go)
        go:SetPosition(x, y)
        
        -- 设置状态
        local state = data:GetParams()[1] or 0
        go:SetState(state)
    end
end

-- 获取火炬
function XRpgMakerGameScene:GetTorchObj(posX, posY)
    for _, torch in pairs(self.TorchObjs) do
        if posX == torch:GetPosX() and posY == torch:GetPosY() then
            return torch
        end
    end
end

-- 重置火炬
function XRpgMakerGameScene:StageResetTorchObj()
    for _, torchObj in pairs(self.TorchObjs) do
        torchObj:OnStageReset()
    end
end
--endregion



function XRpgMakerGameScene:GetGapObjs()
    return self.GapObjs
end

function XRpgMakerGameScene:GetBlockObj(row, col)
    return self.BlockObjs[row] and self.BlockObjs[row][col]
end

function XRpgMakerGameScene:GetCubeObj(row, col)
    return self.CubeObjs[row] and self.CubeObjs[row][col]
end

function XRpgMakerGameScene:GetCubeObjs()
    return self.CubeObjs
end

function XRpgMakerGameScene:GetSceneObjRoot()
    return self.SceneObjRoot
end

function XRpgMakerGameScene:IsSceneNil()
    return XTool.UObjIsNil(self.GameObject)
end

function XRpgMakerGameScene:SetSceneActive(isActive)
    if not self:IsSceneNil() then
        self.GameObject.gameObject:SetActiveEx(isActive)
    end
end

--重置
function XRpgMakerGameScene:Reset()
    self:BackUp()
    self:ResetGrow()
end

--后退
function XRpgMakerGameScene:BackUp()
    local mapId = self:GetMapId()
    self:UpdatePlayerObj()
    self:UpdateEntity(mapId)
    self:UpdateMonsterObjs(mapId)
    self:UpdateEndPointObjStatus()
    self:UpdateTriggeObjStatus(mapId)
    self:UpdateShadowObjs(mapId)
    self:UpdateElectricFenceObjStatus(mapId)
    self:UpdateBubbleObjs(mapId)
    self:UpdateDropObjs(mapId)
end

function XRpgMakerGameScene:UpdateEntity(mapId)
    local entityList = XRpgMakerGameConfigs.GetMixBlockEntityList(mapId)
    local obj
    for index, _ in ipairs(entityList) do
        obj = XDataCenter.RpgMakerGameManager.GetEntityObj(index)
        if obj and obj.CheckPlayFlat then
            obj:CheckPlayFlat()
        end
    end
end

function XRpgMakerGameScene:UpdateElectricFenceObjStatus(mapId)
    local electricFenceIdList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.ElectricFence)
    local obj
    for index, _ in ipairs(electricFenceIdList) do
        obj = XDataCenter.RpgMakerGameManager.GetElectricFenceObj(index)
        if obj then
            obj:PlayElectricFenceStatusChangeAction()
        end
    end
end

function XRpgMakerGameScene:UpdateShadowObjs(mapId)
    local shadowIdList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Shadow)
    local shadowObj
    local shadowId
    for _, data in ipairs(shadowIdList) do
        shadowId = data:GetParams()[1]
        shadowObj = XDataCenter.RpgMakerGameManager.GetShadowObj(shadowId)
        if shadowObj then
            shadowObj:UpdateObjPosAndDirection()
            shadowObj:CheckIsDeath()
        end
    end
end

function XRpgMakerGameScene:UpdatePlayerObj()
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    playerObj:UpdateObjPosAndDirection()
    playerObj:CheckIsDeath()
end

function XRpgMakerGameScene:UpdateMonsterObjs(mapId)
    local monsterIdList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Monster)
    local monsterObj
    local monsterId
    for _, data in ipairs(monsterIdList) do
        monsterId = data:GetParams()[1]
        monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
        if monsterObj then
            monsterObj:UpdateObjPosAndDirection()
            monsterObj:CheckIsDeath()
            monsterObj:RemovePatrolLineObjs()
            monsterObj:SetViewAreaAndLine()
            monsterObj:LoadSentrySign()
        end
    end
end

function XRpgMakerGameScene:UpdateEndPointObjStatus()
    local endPointObj = XDataCenter.RpgMakerGameManager.GetEndPointObj()
    endPointObj:UpdateObjStatus()
end

function XRpgMakerGameScene:UpdateTriggeObjStatus(mapId)
    local triggerIdList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Trigger)
    local triggerObj
    local triggerId
    for _, data in ipairs(triggerIdList) do
        triggerId = data:GetParams()[1]
        triggerObj = XDataCenter.RpgMakerGameManager.GetTriggerObj(triggerId)
        triggerObj:UpdateObjTriggerStatus()
    end
end

function XRpgMakerGameScene:UpdateBubbleObjs(mapId)
    local objDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Bubble)
    local obj
    local bubbleId
    for _, data in ipairs(objDataList) do
        bubbleId = data:GetParams()[1]
        obj = XDataCenter.RpgMakerGameManager.GetBubbleObj(bubbleId)
        if obj then
            obj:UpdateObjPosAndDirection()
        end
    end
end

function XRpgMakerGameScene:UpdateDropObjs(mapId)
    local objDataList = self:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Drop)
    local obj
    local bubbleId
    for _, data in ipairs(objDataList) do
        bubbleId = data:GetParams()[1]
        obj = XDataCenter.RpgMakerGameManager.GetDropObj(bubbleId)
        if obj then
            obj:UpdateObjPosAndDirection()
        end
    end
end

function XRpgMakerGameScene:PlayAnimation()
    if not self:IsSceneNil() then
        self.PlayableDirector = XUiHelper.TryGetComponent(self.GameObject.transform, "Animation/AnimEnable", "PlayableDirector")
        if self.PlayableDirector then
            self.PlayableDirector.gameObject:SetActiveEx(true)
            self.PlayableDirector:Play()
        end
    end
end

function XRpgMakerGameScene:GetSceneCamera()
    return self.Camera
end

--region 执行Action
-- 获取Action对应Class
function XRpgMakerGameScene:GetActionClass(actionType)
    if not self.ActionClass then
        local ACTION_TYPE_ENUM = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameActionType
        self.ActionClass = {
            [ACTION_TYPE_ENUM.ActionSkillTypeChange] = require("XModule/XRpgMakerGame/XAction/XRpgMakerGameActionSkillTypeChange"), -- 属性变化
            [ACTION_TYPE_ENUM.ActionMonsterKnocked] = require("XModule/XRpgMakerGame/XAction/XRpgMakerGameActionMonsterKnocked"), -- 怪物被击飞
            [ACTION_TYPE_ENUM.ActionWaterStatusChange] = require("XModule/XRpgMakerGame/XAction/XRpgMakerGameActionWaterStatusChange"), -- 水池状态改变
            [ACTION_TYPE_ENUM.ActionTorchStatusChange] = require("XModule/XRpgMakerGame/XAction/XRpgMakerGameActionTorchStatusChange"), -- 火炬状态改变
            [ACTION_TYPE_ENUM.ActionMonsterDieByFlame] = require("XModule/XRpgMakerGame/XAction/XRpgMakerGameActionMonsterDieByFlame"), -- 怪物被烧死
            [ACTION_TYPE_ENUM.ActionMonsterDieByKnocked] = require("XModule/XRpgMakerGame/XAction/XRpgMakerGameActionMonsterDieByKnocked"), -- 怪物被物理撞死
        }
    end
    
    local class = self.ActionClass[actionType]
    if not class then
        XLog.Error(string.format("XRpgMakerGameScene:GetActionClass报错，未定义ActionType%s对应的ActionClass!", action.ActionType))
    end
    return class
end

-- 执行一个Action
function XRpgMakerGameScene:PlayAction(action, actionEndCb)
    ---@type XRpgMakerGameActionBase
    local class = self:GetActionClass(action.ActionType)
    if not class then
        if actionEndCb then actionEndCb() end
        return
    end

    local instance = class.New(self, action, actionEndCb)
    instance:Execute()
end
--endregion

--region 地形判断
-- 根据位置、方向、距离，获取位置
function XRpgMakerGameScene:GetDirectionPos(originPos, direction, distance)
    local aimPos = { PositionX = originPos.PositionX, PositionY = originPos.PositionY }
    local DIRECTION = XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection
    if direction == DIRECTION.MoveLeft then
        aimPos.PositionX = aimPos.PositionX - distance
    elseif direction == DIRECTION.MoveRight then
        aimPos.PositionX = aimPos.PositionX + distance
    elseif direction == DIRECTION.MoveUp then
        aimPos.PositionY = aimPos.PositionY + distance
    elseif direction == DIRECTION.MoveDown then
        aimPos.PositionY = aimPos.PositionY - distance
    end
    return aimPos
end

-- 目标位置是否有草
function XRpgMakerGameScene:IsPosGrass(pos)
    local posX = pos.PositionX
    local posY = pos.PositionY
    local grassDic = XDataCenter.RpgMakerGameManager.GetGrassObjDic()
    for _, grass in pairs(grassDic) do
        if grass:IsSamePoint(posX, posY) and not grass:IsEmpty() then
            return true
        end
    end

    if self:GetGrass(posX, posY) then
        return true
    end
    return false
end

-- 物理属性单位是否可通过
function XRpgMakerGameScene:IsPhysics2CanPass(pos)
    local posX = pos.PositionX
    local posY = pos.PositionY
    -- 玩家
    if self.PlayerObj and self.PlayerObj:IsSamePoint(posX, posY) and not self.PlayerObj:IsEmpty() then
        return false
    end
    -- 终点
    if self.EndPointObj and self.EndPointObj:IsSamePoint(posX, posY) and not self.EndPointObj:IsEmpty() then
        return false
    end
    -- 火炬
    if self.TorchObjs then
        for _, torch in pairs(self.TorchObjs) do
            if torch:IsSamePoint(posX, posY) and not torch:IsEmpty() then
                return false
            end
        end
    end
    -- 影子
    local shadowObjDic = XDataCenter.RpgMakerGameManager.GetShadowObjDic()
    for _, shadow in pairs(shadowObjDic) do
        if shadow:IsSamePoint(posX, posY) and shadow:IsAlive() then
            return false
        end
    end
    -- 魔法阵
    local magicObjDic = XDataCenter.RpgMakerGameManager.GetMagicObjDic()
    for _, magic in pairs(magicObjDic) do
        if magic:IsSamePoint(posX, posY) then
            return false
        end
    end
    -- 换属性阵
    for _, switchPoint in pairs(self.SwitchSkillPointObjs) do
        if switchPoint:IsSamePoint(posX, posY) then
            return false
        end
    end
    -- 传送点
    local transferPointObjDic = XDataCenter.RpgMakerGameManager.GetTransferPointObjDic()
    for _, transferPoint in pairs(transferPointObjDic) do
        if transferPoint:IsSamePoint(posX, posY) then
            return false
        end
    end
    -- 怪物
    local monsterObjDic = XDataCenter.RpgMakerGameManager.GetGameMonsterObjDic()
    for _, monster in pairs(monsterObjDic) do
        if monster:IsSamePoint(posX, posY) and not monster:IsDeath() then
            return false
        end
    end
    -- 水
    local waterDic = XDataCenter.RpgMakerGameManager.GetWaterObjDic()
    for _, water in pairs(waterDic) do
        if water:IsSamePoint(posX, posY) then
            local status = water:GetStatus()
            if status ~= XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Ice and status ~= XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Disappear then
                return false
            end
        end
    end
    -- 草
    local grassDic = XDataCenter.RpgMakerGameManager.GetGrassObjDic()
    for _, grass in pairs(grassDic) do
        if grass:IsSamePoint(posX, posY) and not grass:IsEmpty() then
            return false
        end
    end
    -- 阻挡物
    if self:GetBlockObj(posY, posX) then
        return false
    end
    return true
end


-- 物理属性单位是否可飞过
function XRpgMakerGameScene:IsPhysics2CanFly(pos)
    local posX = pos.PositionX
    local posY = pos.PositionY
    -- 玩家
    if self.PlayerObj and self.PlayerObj:IsSamePoint(posX, posY) and not self.PlayerObj:IsEmpty() then
        return false
    end
    -- 终点
    if self.EndPointObj and self.EndPointObj:IsSamePoint(posX, posY) and not self.EndPointObj:IsEmpty() then
        return false
    end
    -- 火炬
    if self.TorchObjs then
        for _, torch in pairs(self.TorchObjs) do
            if torch:IsSamePoint(posX, posY) and not torch:IsEmpty() then
                return false
            end
        end
    end
    -- 影子
    local shadowObjDic = XDataCenter.RpgMakerGameManager.GetShadowObjDic()
    for _, shadow in pairs(shadowObjDic) do
        if shadow:IsSamePoint(posX, posY) and shadow:IsAlive() then
            return false
        end
    end
    -- 魔法阵
    local magicObjDic = XDataCenter.RpgMakerGameManager.GetMagicObjDic()
    for _, magic in pairs(magicObjDic) do
        if magic:IsSamePoint(posX, posY) then
            return false
        end
    end
    -- 传送点
    local transferPointObjDic = XDataCenter.RpgMakerGameManager.GetTransferPointObjDic()
    for _, transferPoint in pairs(transferPointObjDic) do
        if transferPoint:IsSamePoint(posX, posY) then
            return false
        end
    end
    -- 怪物
    local monsterObjDic = XDataCenter.RpgMakerGameManager.GetGameMonsterObjDic()
    for _, monster in pairs(monsterObjDic) do
        if monster:IsSamePoint(posX, posY) and not monster:IsDeath() then
            return false
        end
    end
    -- 水格子都可通过
    -- 草
    local grassDic = XDataCenter.RpgMakerGameManager.GetGrassObjDic()
    for _, grass in pairs(grassDic) do
        if grass:IsSamePoint(posX, posY) and not torch:IsEmpty() then
            return false
        end
    end
    -- 阻挡物
    if self:GetBlockObj(posY, posX) then
        return false
    end
    return true
end

-- 该位置是否会停止玩家移动
function XRpgMakerGameScene:IsPosStopMove(pos)
    local posX = pos.PositionX
    local posY = pos.PositionY
    -- 魔法阵
    local magicObjDic = XDataCenter.RpgMakerGameManager.GetMagicObjDic()
    for _, magic in pairs(magicObjDic) do
        if magic:IsSamePoint(posX, posY) then
            return true
        end
    end
    -- 换属性阵
    for _, switchPoint in pairs(self.SwitchSkillPointObjs) do
        if switchPoint:IsSamePoint(posX, posY) then
            return true
        end
    end
    return false
end

--endregion

return XRpgMakerGameScene