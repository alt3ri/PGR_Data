local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XGoldenMinerAgency : XFubenActivityAgency
---@field private _Model XGoldenMinerModel
local XGoldenMinerAgency = XClass(XFubenActivityAgency, "XGoldenMinerAgency")
local METHOD_NAME = {
    GoldenMinerEnterGameRequest = "GoldenMinerEnterGameRequest",
    GoldenMinerExitGameRequest = "GoldenMinerExitGameRequest",
    GoldenMinerEnterStageRequest = "GoldenMinerEnterStageRequest",
}
local CSTimeManager = CS.XTimerManager
local TicksPerSecond = 10000000
local CDTime = 0.2

function XGoldenMinerAgency:OnInit()
    if XMain.IsEditorDebug then
        self.IsDebug = XSaveTool.GetData('GoldenMinerDebug')
        self.LogEnableDict = {}
    end
    self._ReqCdDir = {}
    self:RegisterActivityAgency()
    self.EnumConst = require('XModule/XGoldenMiner/XGoldenMinerEnumConst')
    self.EventId = require('XModule/XGoldenMiner/XGoldenMinerEventId')
end

function XGoldenMinerAgency:InitRpc()
    --实现服务器事件注册
    XRpc.NotifyGoldenMinerGameInfo = handler(self, self.NotifyGoldenMinerGameInfo)
    XRpc.NotifyGoldenMinerItemData = handler(self, self.NotifyGoldenMinerItemData)
    XRpc.NotifyGoldenMinerCharacterProgress = handler(self, self.NotifyGoldenMinerCharacterProgress)
end

function XGoldenMinerAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region Debug
function XGoldenMinerAgency:_CheckLogTypeEnable(logType)
    return self.LogEnableDict and self.LogEnableDict[logType]
end

function XGoldenMinerAgency:SetLogTypeEnable(logType, enable)
    if self.LogEnableDict then
        self.LogEnableDict[logType] = enable
    end
end

function XGoldenMinerAgency:_CheckIsDebug()
    return self.IsDebug and XMain.IsWindowsEditor
end

function XGoldenMinerAgency:DebugWarning(content, ...)
    if not self:_CheckIsDebug() then
        return
    end
    if string.IsNilOrEmpty(content) then
        XLog.Warning("黄金矿工Debug:", ...)
        return
    end
    XLog.Warning("黄金矿工Debug:" .. content, ...)
end

function XGoldenMinerAgency:DebugLog(content, ...)
    if not self:_CheckIsDebug() then
        return
    end
    if string.IsNilOrEmpty(content) then
        XLog.Debug("黄金矿工Debug:", ...)
        return
    end
    XLog.Debug("黄金矿工Debug:" .. content, ...)
end

function XGoldenMinerAgency:DebugLogWithType(type, content, ...)
    if not self:_CheckIsDebug() then
        return
    end

    if not self:_CheckLogTypeEnable(type) then
        return
    end
    
    if string.IsNilOrEmpty(content) then
        XLog.Debug("黄金矿工Debug:", ...)
        return
    end
    XLog.Debug("黄金矿工Debug:" .. content, ...)
end

function XGoldenMinerAgency:DebugAddScore(value)
    if not self:_CheckIsDebug() then
        return
    end
    XLog.Warning("黄金矿工Debug: 添加分数 score = ", value)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_SCORE, value)
end

function XGoldenMinerAgency:DebugAddTime(value)
    if not self:_CheckIsDebug() then
        return
    end
    XLog.Warning("黄金矿工Debug: 添加事件 time = ", value)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_TIME, value)
end

function XGoldenMinerAgency:DebugAddItem(value)
    if not self:_CheckIsDebug() then
        return
    end
    XLog.Warning("黄金矿工Debug:添加道具 Id = ", value)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_ITEM, value)
end

function XGoldenMinerAgency:DebugAddBuff(value)
    if not self:_CheckIsDebug() then
        return
    end
    XLog.Warning("黄金矿工Debug:添加buff(部分buff得初始化才会生效) Id = ", value)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_BUFF, value)
end

function XGoldenMinerAgency:DebugInitBuff(buffList)
    if not self:_CheckIsDebug() then
        return
    end
    XLog.Warning("黄金矿工Debug:添加初始化buffList", buffList)
    if type(buffList) ~= "table" then
        XLog.Error("黄金矿工Debug:添加初始化buffList参数错误，例子:{1,2}")
        return
    end
    self._Model.DebugInitBuffList = buffList
end
--endregion

--region Rpc
---通知当前游戏流程数据
function XGoldenMinerAgency:NotifyGoldenMinerGameInfo(data)
    local dataDb = self._Model:GetMineDb()
    dataDb:UpdateData(data.StageDataDb)
    dataDb:BackupsItemColumns()
end

---更新新解锁的角色卡
function XGoldenMinerAgency:NotifyGoldenMinerCharacterProgress(data)
    local dataDb = self._Model:GetMineDb()
    dataDb:UpdateNewCharacter(data.UnlockCharacter)
    dataDb:UpdateRedEnvelopeProgress(data.RedEnvelopeProgress)
    dataDb:UpdateTotalPlayCount(data.TotalPlayCount)
end

---进图同步道具
function XGoldenMinerAgency:NotifyGoldenMinerItemData(data)
    local dataDb = self._Model:GetMineDb()
    dataDb:UpdateItemColumns(data.ItemColumns)
    dataDb:BackupsItemColumns()
end
--endregion

--region FubenEx
function XGoldenMinerAgency:ExOpenMainUi()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.GoldenMiner) then
        return false
    end
    if not self:CheckIsOpen() then
        XUiManager.TipText("RougeLikeNotInActivityTime")
        return false
    end
    XLuaUiManager.Open("UiGoldenMinerMain")
    
    return true
end

function XGoldenMinerAgency:ExCheckInTime()
    -- 保持FubenActivity表TimeId清空功能有效
    if not self.Super.ExCheckInTime(self) then
        return false
    end
    return self:CheckIsOpen()
end

function XGoldenMinerAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.GoldenMiner
end
--endregion

--region Activity
function XGoldenMinerAgency:GetCurActivityHexMapStages(index)
    return self._Model:GetCurActivityHexMapStages(index)
end

function XGoldenMinerAgency:CheckIsOpen()
    return self._Model:CheckIsOpen()
end

function XGoldenMinerAgency:_CheckIsRecordRequestCD(request, time)
    time = time or CDTime
    if self._ReqCdDir[request] then
        if CSTimeManager.Ticks - self._ReqCdDir[request] < (time * TicksPerSecond) then
            return true
        end
    end
    self._ReqCdDir[request] = CSTimeManager.Ticks
    return false
end

function XGoldenMinerAgency:GetUseCharacterId()
    local characterId = self._Model:GetMineDb():GetCurPlayCharacterId()
    if XTool.IsNumberValid(characterId) and self:IsCharacterUnLock(characterId) then
        return characterId
    end

    characterId = self._Model:GetCacheData("_CurCharacterId")
    if XTool.IsNumberValid(characterId) and self:IsCharacterUnLock(characterId) then
        return characterId
    end

    local characterConfig = self._Model:GetCharacterCfgList()
    for _, cfg in pairs(characterConfig) do
        if self:IsCharacterUnLock(cfg.Id) then
            characterId = cfg.Id
            break
        end
    end

    self:CatchCurCharacterId(characterId)
    return characterId
end

function XGoldenMinerAgency:RequestGoldenMinerEnterGame(useCharacter, cb)
    if self:_CheckIsRecordRequestCD(METHOD_NAME.GoldenMinerEnterGameRequest) then
        return
    end

    XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.GoldenMinerEnterGameRequest, {
        UseCharacter = useCharacter,
    }, function(res)
        self:_SetCharacterUsed(useCharacter)
        self._Model:GetMineDb():UpdateData(res.MinerDataDb)
        if cb then
            cb()
        end
    end)
end

function XGoldenMinerAgency:OpenGameUi()
    local dataDb = self:GetMainDb()
    local curStageId = dataDb:GetCurStageId()
    local curState = dataDb:GetCurrentState()

    if curState == self.EnumConst.GameState.CommonHexSelect or curState == self.EnumConst.GameState.CoreHexSelect then
        XLuaUiManager.PopThenOpen("UiGoldenMinerHexSelect")
        return
    end

    self:RequestGoldenMinerEnterStage(curStageId, function()
        XLuaUiManager.PopThenOpen("UiGoldenMinerBattle")
    end)
end

function XGoldenMinerAgency:ContinueGame()
    local dataDb = self:GetMainDb()

    dataDb:CoverItemColumns()
    if XTool.IsNumberValid(dataDb:GetCurrentPlayStage()) then
        XLuaUiManager.PopThenOpen("UiGoldenMinerBattle")
        return
    end

    self:OpenGameUi()
end

function XGoldenMinerAgency:RequestGoldenMinerExitGame(stageId, cb, settlementInfo, curMapScore, beforeScore)
    if self:_CheckIsRecordRequestCD(METHOD_NAME.GoldenMinerExitGameRequest) then
        return
    end

    local settlementInfoReq
    if not settlementInfo then
        settlementInfoReq = {
            Scores = curMapScore,
            LaunchingClawCount = 0,
            CostTime = 0,
            MoveCount = 0,
            SettlementItems = {},
            GrabDataInfos = {},
            UpdateTaskInfo = {},
            SlotMachineCount = 0,
        }
    else
        settlementInfoReq = settlementInfo:GetReqServerData()
    end

    local score = curMapScore
    XNetwork.Call(METHOD_NAME.GoldenMinerExitGameRequest, {
        StageId = stageId,
        SettlementInfo = settlementInfoReq,
    }, function(res)
        if res.Code ~= XCode.Success and res.Code ~= XCode.GoldenMinerSaveRankError then
            XUiManager.TipCode(res.Code)
            score = beforeScore
        end

        if res.Code == XCode.GoldenMinerSaveRankError then
            XUiManager.TipCode(res.Code)
        end

        local dataDb = self._Model:GetMineDb()
        dataDb:UpdateCurClearData(score)
        dataDb:ResetData()
        dataDb:UpdateTotalMaxScores(res.TotalMaxScores)
        dataDb:UpdateTotalMaxScoresHexes(res.TotalMaxScoresHexes)
        dataDb:UpdateTotalMaxScoresCharacter(res.CharacterId)
        if cb then
            cb()
        end
    end)
end

function XGoldenMinerAgency:RequestGoldenMinerEnterStage(stageId, cb)
    if self:_CheckIsRecordRequestCD(METHOD_NAME.GoldenMinerEnterStageRequest) then
        return
    end

    XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.GoldenMinerEnterStageRequest, {
        StageId = stageId,
    }, function()
        self._Model:GetMineDb():BackupsItemColumns()
        if cb then
            cb()
        end
    end)
end

function XGoldenMinerAgency:CheckIsHaveGameStage()
    local dataDb = self._Model:GetMineDb()
    return dataDb and dataDb:CheckIsInStage() or false
end

function XGoldenMinerAgency:GetStageScores()
    local dataDb = self._Model:GetMineDb()
    return dataDb and dataDb:GetStageScores() or 0
end

function XGoldenMinerAgency:GetMainDb()
    return self._Model:GetMineDb()
end

function XGoldenMinerAgency:CatchCurCharacterId(characterId)
    self._Model:SetCacheData("_CurCharacterId", characterId)
end

function XGoldenMinerAgency:IsCharacterUsed(characterId)
    if not self:IsCharacterUnLock(characterId) then
        return true
    end

    return self._Model:GetCacheData("IsCharacterUsed" .. characterId)
end

function XGoldenMinerAgency:_SetCharacterUsed(characterId)
    if self:IsCharacterUsed(characterId) then
        return
    end

    self._Model:SetCacheData("IsCharacterUsed" .. characterId, true)
end
--endregion

--region RedPoint
function XGoldenMinerAgency:CheckHaveTaskCanRecv()
    return self._Model:CheckHaveTaskCanRecv()
end

---角色是否解锁
function XGoldenMinerAgency:IsCharacterUnLock(characterId)
    local condition = self._Model:GetCharacterCfgCondition(characterId)
    if not XTool.IsNumberValid(condition) then
        return true
    end
    return self._Model:GetMineDb():IsCharacterUnlock(characterId)
end

---是否使用X角色
function XGoldenMinerAgency:CheckIsUseCharacter(characterId)
    if not self:CheckIsOpen() then
        return false
    end
    if not self._Model:GetMineDb():CheckIsInStage() then
        return false
    end
    local dataDb = self._Model:GetMineDb()
    return dataDb:GetCurPlayCharacterId() == characterId
end
--endregion

--region Condition

--- 当前已经通过了几关
function XGoldenMinerAgency:GetCurrentPassedStageCount()
    local dataDb = self._Model:GetMineDb()
    
    return dataDb and dataDb:GetFinishStageCount() or 0
end

--- 当前所处商店状态
function XGoldenMinerAgency:GetCurrentState()
    local dataDb = self._Model:GetMineDb()
    
    return dataDb and dataDb:GetCurrentState() or 0
end

--endregion

--region Cfg - ClientConfig

function XGoldenMinerAgency:GetCurActivityMaxItemColumnCount()
    local id = self._Model:GetCurActivityId()
    if XTool.IsNumberValid(id) then
        return self:GetCfgActivityMaxItemColumnCount(id)
    end
    return 0
end

function XGoldenMinerAgency:GetCfgActivityMaxItemColumnCount(id)
    local cfg = self._Model:GetActivityCfg(id)
    return cfg and cfg.MaxItemColumnCount
end
--endregion

--region Cfg - Buff
function XGoldenMinerAgency:GetShopGridLockCount()
    return self._Model:GetShopGridLockCount()
end
--endregion

--region Cfg - Item
function XGoldenMinerAgency:GetCfgItemType(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.ItemType
end

function XGoldenMinerAgency:GetCfgItemBuffId(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.BuffId
end
--endregion

--region Cfg - Stage
function XGoldenMinerAgency:GetCfgStageShopGridCount(id)
    local cfg = self._Model:GetStageCfg(id)
    return cfg and cfg.ShopGridCount
end

function XGoldenMinerAgency:GetCfgStageTargetScore(id)
    local cfg = self._Model:GetStageCfg(id)
    return cfg and cfg.TargetScore
end

function XGoldenMinerAgency:GetCfgStageFixTargetScore(id)
    local cfg = self._Model:GetStageCfg(id)
    return cfg and cfg.FixTargetScore
end
--endregion

--region Cfg - Upgrade
function XGoldenMinerAgency:GetCfgUpgradeCfgCosts(id, index)
    return self._Model:GetUpgradeCfgCosts(id, index)
end

function XGoldenMinerAgency:GetCfgUpgradeCfgBuffId(id, index)
    return self._Model:GetUpgradeCfgBuffId(id, index)
end

function XGoldenMinerAgency:GetCfgUpgradeLvMaxShipKey(id)
    local cfg = self._Model:GetUpgradeCfg(id)
    return cfg and cfg.LvMaxShipKey
end
--endregion

--region Cfg - HideTask
function XGoldenMinerAgency:GetCfgHideTask(id)
    return self._Model:GetHideTaskCfg(id)
end
--endregion

--region Cfg - Hex
function XGoldenMinerAgency:GetCfgHexMapId(hexId)
    local cfg = self._Model:GetGoldenMinerHexCfg(hexId)
    return cfg and cfg.Map
end
--endregion

return XGoldenMinerAgency
