---@class XRaceScene : XLuaScene
local XRaceScene = XMVCA.XScene:Register(nil, "XRaceScene")

function XRaceScene:Ctor(sceneId, roundId, mapId, ids, sceneType, reportName)
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._sceneId = sceneId
    self._RoundId = roundId or self._Control:GetCurRound() or 1
    self._Ids = ids or { 1, 2, 3, 4, 5, 6, }
    self._MapId = mapId or 2
    self._SceneType = sceneType or XEnumConst.Race.GameMode.Local -- Playback -- LiveStream -- XEnumConst.Race.GameMode.Local
    self._ReportName = reportName or ""
    -- XLog.Warning("XRaceScene:ids", self._Ids)
end

----------public start----------

function XRaceScene:GetActorUiCamera(actor)
    if XTool.UObjIsNil(self._XRaceViewManager) then return end
    return self._XRaceViewManager:GetActorUiCamera(actor - 1)
end

function XRaceScene:SetAutoCamera()
    if XTool.UObjIsNil(self._XRaceViewManager) then return end
    self._XRaceViewManager:SetAutoCamera()
end

function XRaceScene:GetRankFinishCount()
    if XTool.UObjIsNil(self._XRaceViewManager) then return end
    return self._XRaceViewManager.RankFinishCount
end

function XRaceScene:GetRankData()
    if XTool.UObjIsNil(self._XRaceViewManager) then return end
    return self._XRaceViewManager:GetRankData()
end

function XRaceScene:PlayMatch()
    if XTool.UObjIsNil(self._XRaceViewManager) then return end
    self._XRaceViewManager:Play()
end

function XRaceScene:MoveCamera2Index(index)
    if XTool.UObjIsNil(self._XRaceViewManager) then return end
    self._XRaceViewManager:MoveCamera2Index(index - 1)
end

function XRaceScene:InitMapHead(mapHeads, mapAreaGrid)
    if XTool.UObjIsNil(self._XRaceViewManager) then return end
    local mapHeadsTrans = {}
    for _, mapHead in ipairs(mapHeads) do
        table.insert(mapHeadsTrans, mapHead.Transform)
    end
    self._XRaceViewManager:InitMapHead(mapHeadsTrans, mapAreaGrid)
end

function XRaceScene:InitActor(raceIds, powerUpdateCb, skillUpdateCb)
    if XTool.UObjIsNil(self._XRaceViewManager) then return end
    self._XRaceViewManager:InitActorView(raceIds, powerUpdateCb, skillUpdateCb)
end

function XRaceScene:InitMatch(uiCallback)
    if XTool.UObjIsNil(self._XRaceViewManager) then return end
    self._XRaceViewManager:SetLuaCallback(uiCallback)
    self._XRaceViewManager:InitCamera(self._MapCfg.CameraConfigPath)
    self._XRaceViewManager:Init(false)
    self._XRaceViewManager:Enter(self._SceneType, self._RoundId, self._ReportName)
end

function XRaceScene:PlayTrackAnim(isPlay)
    if not self._CamTrack then return end
    self._CamTrack.gameObject:SetActive(isPlay)
end

function XRaceScene:CheckMapEffect()
    if not self._MapEffect then return end

    local actor = self._XRaceViewManager:GetRankActor(1)
    if actor.Distance >= self._MapCfg.EffectDistance then
        self._MapEffect.gameObject:SetActive(true)
        self._MapEffect = nil
    end
end

function XRaceScene:Stop()
    if XTool.UObjIsNil(self._XRaceViewManager) then return end
    self._XRaceViewManager.IsLockTime = true
end

----------public end----------

----------private start----------

function XRaceScene:OnEnter()
    self._MapCfg = self._Control:GetRaceMapById(self._MapId)
    self:LoadChildAsync(nil, self._MapCfg.ScenePath, function(loadId, obj)
        self._PrefabRoot = obj
        self:LoadChildAsync(obj, self._MapCfg.SceneRoadPath, function(loadId, obj2)
            if not XTool.UObjIsNil(obj2) then
                self._Road = obj2
                self._SceneRaceGameRoot = self._Road.transform:Find("RaceGame")
                self._CamTrack = self._Road.transform:Find("CamTrack")
                if self._CamTrack then
                    self._CamTrack.gameObject:SetActive(false)
                end
                self._MapEffect = self._Road.transform:Find("MapEffect")
                if self._MapEffect then
                    self._MapEffect.gameObject:SetActive(false)
                end
                self._XRaceViewManager = self._SceneRaceGameRoot:GetComponent(typeof(CS.XRace.XRaceViewManager))

                local brain = self._Road.transform:Find("MainCamera"):GetComponent(typeof(CS.Cinemachine.CinemachineBrain))
                brain.m_VcamUpdateMethod = CS.Cinemachine.CinemachineBrain.VcamUpdateMethod.LateUpdate
            end
            XLuaUiManager.Open("UiRaceFightMain", self._RoundId, self._Ids, self._SceneType)
        end)
    end)
end

function XRaceScene:OnExit()
    if not XTool.UObjIsNil(self._XRaceViewManager) then
        if XLoginManager.IsLogin() then
            self._XRaceViewManager:Exit()
        end
    end
end

function XRaceScene:OnDestroy()
end

----------private end----------

----------config start----------


----------config end----------


return XRaceScene