---@class XAprilFoolDayAgency : XAgency
---@field private _Model XAprilFoolDayModel
local XAprilFoolDayAgency = XClass(XAgency, "XAprilFoolDayAgency")
function XAprilFoolDayAgency:OnInit()
    --初始化一些变量
end

function XAprilFoolDayAgency:InitRpc()
    XRpc.NotifyFoolsDayClearOutData = handler(self, self.OnNotifyFoolsDayClearOutData)
end

function XAprilFoolDayAgency:InitEvent()
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_ENABLE, self.OnUiMainEnableEventCheckTips, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_DISABLE, self.OnUiMainDisableEventCloseTip, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UICHAT_ENABLE, self.OnUiChatEnableEventCheckTip, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UICHAT_DISABLE, self.OnUiChatDisableEventCloseTip, self)
end

function XAprilFoolDayAgency:RemoveEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_ENABLE, self.OnUiMainEnableEventCheckTips, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_DISABLE, self.OnUiMainDisableEventCloseTip, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UICHAT_ENABLE, self.OnUiChatEnableEventCheckTip, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UICHAT_DISABLE, self.OnUiChatDisableEventCloseTip, self)
end

function XAprilFoolDayAgency:ResetAll()
    self:StopBroadcastTipsTimer()
    self._CandidateTipIds = nil
end
----------public start----------

-- 活动时间
function XAprilFoolDayAgency:IsInTime()
    local TITLE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayStartTime"))
    local TITLE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayEndTime"))

    local curTime = os.time()
    return curTime >= TITLE_START_TIME and curTime < TITLE_END_TIME
end

-- 标题时间
function XAprilFoolDayAgency:IsInTitleTime()
    local TITLE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayTitleStartTime"))
    local TITLE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayTitleEndTime"))

    local curTime = os.time()
    return curTime >= TITLE_START_TIME and curTime < TITLE_END_TIME
end

-- 标题特效时间
function XAprilFoolDayAgency:IsInTitleSpecialEffectShowTime()
    local TITLE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayLoginStartTime2026"))
    local TITLE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayLoginEndTime2026"))

    local curTime = os.time()
    return curTime >= TITLE_START_TIME and curTime < TITLE_END_TIME
end

-- Q版模型时间
function XAprilFoolDayAgency:IsInCuteModelTime()
    local CUTE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayCuteModeltartTime"))
    local CUTE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayCuteModelEndTime"))

    local curTime = os.time()
    return curTime >= CUTE_START_TIME and curTime < CUTE_END_TIME
end

-- Q版头像时间
function XAprilFoolDayAgency:IsInCuteHeadIconTime()
    local CUTE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayCuteHeadStartTime2025"))
    local CUTE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayCuteHeadEndTime2025"))

    local curTime = os.time()
    return curTime >= CUTE_START_TIME and curTime < CUTE_END_TIME
end

-- 随机爪痕时间
function XAprilFoolDayAgency:IsInRandomClawTime()
    local CUTE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayClawStartTime2025"))
    local CUTE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayClawEndTime2025"))

    local curTime = os.time()
    return curTime >= CUTE_START_TIME and curTime < CUTE_END_TIME
end

-- Ui界面随机角色模型时间
function XAprilFoolDayAgency:IsInRandomCharacterUiModelTime()
    return false
end

function XAprilFoolDayAgency:IsMainCharacter(characterId)
    local mainCharacterId = tonumber(CS.XGame.ClientConfig:GetInt("AprilFoolsDayMainCharacter"))
    return characterId == mainCharacterId
end

function XAprilFoolDayAgency:IsSubCharacter(characterId)
    local subCharalist = CS.XGame.ClientConfig:GetString("AprilFoolsDaySubCharacter")
    subCharalist = string.ToIntArray(subCharalist, '|')
    local isCharIn = table.contains(subCharalist, characterId)

    return isCharIn
end

--- 返回false表示不显示猫或狼
function XAprilFoolDayAgency:IsShowCatOrWolf()
    if not self:IsInRandomClawTime() then
        return false
    end

    local randomNum = math.random()
    local showProbability = tonumber(CS.XGame.ClientConfig:GetInt("AprilFoolsDayClawProShow2025")) * 0.001
    if randomNum < showProbability then
        return false
    end

    randomNum = math.random()
    if randomNum < 0.5 then
        return XEnumConst.AprilFool.Random2025Type.Cat
    else
        return XEnumConst.AprilFool.Random2025Type.Wolf
    end
end

-- 隐藏角色模型
function XAprilFoolDayAgency:IsMainCharacterHide(characterId)
    if not self:IsInRandomCharacterUiModelTime() then
        return false
    end

    if not self:IsMainCharacter(characterId) then
        return false
    end

    local hideProbability = tonumber(CS.XGame.ClientConfig:GetInt("AprilFoolsDayMainCharacterMiss")) * 0.01
    local randomNum = math.random()
    local isLastHide = randomNum <= hideProbability
    if isLastHide then
        self._Model.TempWholeDic.IsLastHideChar = characterId
    else
        self._Model.TempWholeDic.IsLastHideChar = nil
    end

    return isLastHide
end

-- 显示愚人节专用第二角色模型
function XAprilFoolDayAgency:GetCharIsSubCharacterShow(characterId)
    if not self:IsInRandomCharacterUiModelTime() then
        return false
    end

    if not self:IsSubCharacter(characterId) then
        return false
    end

    return self._Model.TempWholeDic.IsLastHideChar
end

function XAprilFoolDayAgency:CheckCanEnterFailureMain()
    if self._Model:Check2026ActivityIsOpen() then
        local condition = CS.XGame.ClientConfig:GetInt('AprilFoolsDayCondition2026')

        if XTool.IsNumberValidEx(condition) and XConditionManager.CheckCondition(condition) then
            return true
        end
    end

    return false
end

function XAprilFoolDayAgency:CheckAndEnterFailureMain()
    if self._Model:Check2026ActivityIsOpen() then
        local condition = CS.XGame.ClientConfig:GetInt('AprilFoolsDayCondition2026')

        if XTool.IsNumberValidEx(condition) and XConditionManager.CheckCondition(condition) then
            self:RunAprilFoolMain()
            return true
        end
    end
    
    return false
end

function XAprilFoolDayAgency:RunAprilFoolMain()
    local needClearUiName = {
        "UiFubenMainLineChapter",
        "UiFubenMainLineChapterFw",
        "UiFubenMainLineChapterDP",
        "UiPrequel",
        "UiTheatre5PVEClueBoard",
        "XUiSoloReformChapterDetail",
    }
    for _, uiName in pairs(needClearUiName) do
        XLuaUiManager.RemoveUiData(uiName)
    end

    if XDataCenter.RoomManager.RoomData then
        XDataCenter.RoomManager.Quit(
                function()
                    XLuaUiManager.PopAllThenOpen('UiMainAprilFoolsV403')
                end
        )
    elseif XDataCenter.RoomManager.Matching then
        XDataCenter.RoomManager.CancelMatch(
                function()
                    XLuaUiManager.PopAllThenOpen('UiMainAprilFoolsV403')
                end
        )
    elseif XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.DialogTipQuitRoom(function()
            XLuaUiManager.PopAllThenOpen('UiMainAprilFoolsV403')
        end)
    elseif XMVCA.XDlcRoom:IsInRoom() then
        XMVCA.XDlcRoom:Quit(function()
            XLuaUiManager.PopAllThenOpen('UiMainAprilFoolsV403')
        end)
    elseif XMVCA.XDlcRoom:IsMatching() then
        XMVCA.XDlcRoom:CancelMatch(function()
            XLuaUiManager.PopAllThenOpen('UiMainAprilFoolsV403')
        end)
    elseif XMVCA.XBigWorldGamePlay:IsInGame() then
        XMVCA.XBigWorldGamePlay:ExitGame()
        XLuaUiManager.PopAllThenOpen('UiMainAprilFoolsV403')
    else
        if XLoginManager.IsFirstOpenMainUi() then
            CS.XCustomUi.Instance:GetData()
        end
        XLuaUiManager.PopAllThenOpen('UiMainAprilFoolsV403')
    end

    XMVCA.XFunction:ExitCurrentFunction()
end

-- 清理返回主界面
function XAprilFoolDayAgency:BackToAprilFoolMain()
    XLoginManager.ClearGame()
    XLoginManager.CheckWaterMask()
    self:RunAprilFoolMain()
end

function XAprilFoolDayAgency:RequestFoolsDayClearOutComplete(cb)
    if self._Model:Check2026ActivityIsOpen() then
        self._Model:SetIsComplete(true)
        
        XNetwork.Call("FoolsDayClearOutCompleteRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                self._Model:SetIsComplete(false)
                
                if cb then
                    cb(false)
                end
                
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb(true)
            end
        end)
    end
end

--region 2026愚人节飘窗播报

function XAprilFoolDayAgency:StartBroadcastTipsTimer()
    self:StopBroadcastTipsTimer()
    
    -- 检查总控
    local timeId = self._Model:GetClientConfigActivityBroadcastEnableTimeId()

    if not XTool.IsNumberValidEx(timeId) or not XFunctionManager.CheckInTimeByTimeId(timeId, false) then
        return
    end
    
    -- 初始化队列
    if not self._TipsQueue then
        ---@type XQueue
        self._TipsQueue = XQueue.New()
    end
    
    -- 检查列表（通过遍历配置表获取那些在时间上有可能被显示部分的Id）
    -- 只在每次登录后收集一次
    if self._CandidateTipIds == nil then
        self._CandidateTipIds = {}
        self:_CheckAllAndFindHopefulIds()
    end

    self:_UpdateBroadcastTipsCheckTimer()
    
    local interval = math.floor(self._Model:GetClientConfigActivityBroadcastCheckIntervalTime() * XScheduleManager.SECOND)
    
    self._TipsTimer = XScheduleManager.ScheduleForever(handler(self, self._UpdateBroadcastTipsCheckTimer), interval)
end

function XAprilFoolDayAgency:StopBroadcastTipsTimer()
    if self._TipsTimer then
        XScheduleManager.UnSchedule(self._TipsTimer)
        self._TipsTimer = nil
    end

    if self._TipsQueue and self._TipsQueue:Count() > 0 then
        self._TipsQueue:Clear()
    end
end

function XAprilFoolDayAgency:_AddCandidateTipIdList(id)
    if self._CandidateTipIds then
        if not table.contains(self._CandidateTipIds, id) then
            table.insert(self._CandidateTipIds, id)
        end
    end
end

function XAprilFoolDayAgency:_AddTipsIdToWaittingPop(id)
    if self._TipsQueue then
        self._TipsQueue:Enqueue(id)
    end
end

function XAprilFoolDayAgency:_GetOneBroadcastTipsId()
    if self._TipsQueue then
        return self._TipsQueue:Dequeue()
    end
end

--- 遍历配置表，找出那些在时间配置上有机会被展示的部分
--- 用于定时器轮询之初
function XAprilFoolDayAgency:_CheckAllAndFindHopefulIds()
    local configs = self._Model:GetFoolsDayActivityBroadcastCfgs()

    if XTool.IsTableEmpty(configs) then
        return
    end

    local now = XTime.GetServerNowTimestamp()

    for i, v in ipairs(configs) do
        local hopefulId = nil
        
        -- 首先判断是否满足时间
        if XTool.IsNumberValidEx(v.TimeId) and not XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
            local endTime = XFunctionManager.GetEndTimeByTimeId(v.TimeId)

            -- 当前不在时间范围内，但不限制结束时间或者尚未到达结束时间，则说明未来有机会满足时间条件
            local willStart = not XTool.IsNumberValidEx(endTime) or now < endTime

            if willStart then
                hopefulId = v.Id
            end
        else
            -- 没有时间约束或在时间内，都有机会显示
            hopefulId = v.Id
        end
        
        if hopefulId then
            self:_AddCandidateTipIdList(hopefulId)
        end
    end
end

function XAprilFoolDayAgency:_UpdateBroadcastTipsCheckTimer()
    -- 从候选中遍历而不是遍历配置表
    if XTool.IsTableEmpty(self._CandidateTipIds) then
        self:StopBroadcastTipsTimer()
        return
    end

    local now = XTime.GetServerNowTimestamp()

    for i, id in pairs(self._CandidateTipIds) do
        local cfg = self._Model:GetFoolsDayActivityBroadcastCfgById(id)

        if cfg then
            -- 首先判断是否满足时间
            if XTool.IsNumberValidEx(cfg.TimeId) and not XFunctionManager.CheckInTimeByTimeId(cfg.TimeId) then
                goto CONTINUE
            end

            -- 判断条件
            if XTool.IsNumberValidEx(cfg.Condition) and not XConditionManager.CheckCondition(cfg.Condition) then
                goto CONTINUE
            end

            -- 判断距离上一次播报的时间间隔
            local lastTime = self._Model:GetBroadcastLastShowTime(cfg.Id)
            
            if XTool.IsNumberValidEx(cfg.IntervalTime) then
                if XTool.IsNumberValidEx(lastTime) and (now - lastTime) < cfg.IntervalTime then
                    goto CONTINUE
                end
            else
                -- 没有时间的，只播一次，客户端缓存
                if XTool.IsNumberValidEx(lastTime) then
                    goto CONTINUE
                end
            end

            -- 加入显示队列
            self:_AddTipsIdToWaittingPop(cfg.Id)

            :: CONTINUE ::
        end
    end
    
    self:TryPopTips()
end

--- 检查当前打开的界面是否能够弹窗
function XAprilFoolDayAgency:_CheckCurrentTopUiIsValid()
    local inRealMainUi =  XLuaUiManager.IsUiShow("UiMain") and XLuaUiManager.GetTopUiName() == "UiMain"
    local inFoolsDayMainUi = XLuaUiManager.IsUiShow("UiMainAprilFoolsV403") and XLuaUiManager.GetTopUiName() == "UiMainAprilFoolsV403"
    local inMainChat = XLuaUiManager.IsUiShow("UiChatServeMain") and XLuaUiManager.GetTopUiName() == "UiChatServeMain"
    
    local inMainUi = inRealMainUi or inFoolsDayMainUi or inMainChat
    
    return inMainUi
end

-- UiMain的OnEnable时机可能比协议下发快
function XAprilFoolDayAgency:OnUiMainEnableEventCheckTips()
    local inRealMainUi =  XLuaUiManager.IsUiShow("UiMain") and XLuaUiManager.GetTopUiName() == "UiMain"
    local inFoolsDayMainUi = XLuaUiManager.IsUiShow("UiMainAprilFoolsV403") and XLuaUiManager.GetTopUiName() == "UiMainAprilFoolsV403"
    
    local inMainUi = inRealMainUi or inFoolsDayMainUi
    
    if not inMainUi then
        return
    end
    if XLuaUiManager.IsUiLoad("UiChatServeMain") then
        -- 避免从聊天横幅跳转活动主界面，然后点返回按钮时，同时出现2个横幅导致层级出问题
        return
    end
    self:StartBroadcastTipsTimer()
end

function XAprilFoolDayAgency:OnUiChatEnableEventCheckTip()
    local inMainUi = XLuaUiManager.IsUiShow("UiChatServeMain") and XLuaUiManager.GetTopUiName() == "UiChatServeMain"
    if not inMainUi then
        return
    end
    self:StartBroadcastTipsTimer()
end

function XAprilFoolDayAgency:OnUiMainDisableEventCloseTip()
    self:CloseTip()
    XLuaUiManager.SafeClose('UiMainAprilFoolsToastHall')
end

function XAprilFoolDayAgency:OnUiChatDisableEventCloseTip()
    --self:CloseTip()
end

function XAprilFoolDayAgency:CloseTip()
    self:StopBroadcastTipsTimer()
end

function XAprilFoolDayAgency:TryPopTips()
    if XLuaUiManager.IsUiShow('UiMainAprilFoolsToastHall') or not self:_CheckCurrentTopUiIsValid() then
        return
    end

    if XLuaUiManager.IsUiLoad('UiMainAprilFoolsToastHall') then
        XLuaUiManager.Remove('UiMainAprilFoolsToastHall')
    end
    
    local id = self:_GetOneBroadcastTipsId()

    if XTool.IsNumberValidEx(id) then
        XLuaUiManager.OpenWithCallback('UiMainAprilFoolsToastHall', function()
            self._Model:SetBroadcastShowTime(id, XTime.GetServerNowTimestamp())
        end, id)
    end
end
--endregion

----------public end----------


function XAprilFoolDayAgency:OnNotifyFoolsDayClearOutData(data)
    self._Model:UpdateClearOutData(data)
end

return XAprilFoolDayAgency