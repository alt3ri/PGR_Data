local XUiSGGridItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiBigWorldMapDetail : XBigWorldUi
---@field BtnClose XUiComponent.XUiButton
---@field PanelIcon UnityEngine.UI.Image
---@field TxtTitle UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field PanelName UnityEngine.RectTransform
---@field TxtStoryDes UnityEngine.UI.Text
---@field PanelProgress XUiComponent.XUiTextGroup
---@field PanelReward UnityEngine.RectTransform
---@field PanelItem UnityEngine.RectTransform
---@field ItemGrid UnityEngine.RectTransform
---@field ProgressList UnityEngine.RectTransform
---@field PanelBottom UnityEngine.RectTransform
---@field BtnTracking XUiComponent.XUiButton
---@field BtnCancelTracking XUiComponent.XUiButton
---@field BtnTransmit XUiComponent.XUiButton
---@field BtnGo XUiComponent.XUiButton
---@field _Control XBigWorldMapControl
---@field Parent XUiBigWorldMap
local XUiBigWorldMapDetail = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldMapDetail")

local OperatorType = {
    Track = 0,
    Teleport = 1,
    CancelTrack = 2,
}

-- region 生命周期

function XUiBigWorldMapDetail:OnAwake()
    ---@type XBWMapPinData
    self._PinData = nil
    ---@type XBWMapPinData
    self._QuickGoingData = nil
    ---@type XUiGridBWItem[]
    self._RewardGrids = {}

    if self.CharacterEcologyTitle then
        self.CharacterEcologyTitle.text = XMVCA.XBigWorldService:GetText("MapAiMemoryTitle")
    end
    self:_RegisterButtonClicks()
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_DETAIL_CHANGE, self.Refresh, self)
end

function XUiBigWorldMapDetail:OnStart(levelId, pinData)
    self._LevelId = levelId
    self._PinData = pinData
    self._QuickGoingData = self._Control:GetQuickGoingPinData(pinData)
end

function XUiBigWorldMapDetail:OnEnable()
    self:_Refresh()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMapDetail:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldMapDetail:OnDestroy()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_DETAIL_CHANGE, self.Refresh, self)
end

-- endregion

---@param pinData XBWMapPinData
function XUiBigWorldMapDetail:Refresh(levelId, pinData)
    self._LevelId = levelId
    self._PinData = pinData
    self._QuickGoingData = self._Control:GetQuickGoingPinData(pinData)

    self:_Refresh()
end

-- region 按钮事件

function XUiBigWorldMapDetail:OnBtnCloseClick()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_DETAIL_CLOSE)
end

function XUiBigWorldMapDetail:OnBtnTrackingClick()
    local pinData = self._PinData

    if pinData then
        if not pinData:IsTracking() then
            local isCanTele = false
            local currentLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
            if pinData.LevelId ~= currentLevelId then
                local quickGoingData = self._Control:GetQuickGoingPinData(self._PinData, true)
                isCanTele = quickGoingData ~= nil
                self:_QuickTeleport(quickGoingData, true, self.Name .. "OnBtnTrackingClick", XMVCA.XBigWorldService:GetText("MapQuickGoingTeleportDesc"), true, function()
                    if pinData:IsVirtual() then
                        self._Control:TrackPin(pinData.LevelId, pinData.ReferPinId)
                    else
                        self._Control:TrackPin(pinData.LevelId, pinData.PinId)
                    end
                end)
            end
            if not isCanTele then
                if pinData:IsVirtual() then
                    self._Control:TrackPin(pinData.LevelId, pinData.ReferPinId)
                else
                    self._Control:TrackPin(pinData.LevelId, pinData.PinId)
                end
            end
        end
    end
end

function XUiBigWorldMapDetail:OnBtnCancelTrackingClick()
    local pinData = self._PinData

    if pinData then
        if pinData:IsTracking() then
            if pinData:IsVirtual() then
                self._Control:CancelTrackPin(pinData.LevelId, pinData.ReferPinId)
            else
                self._Control:CancelTrackPin(pinData.LevelId, pinData.PinId)
            end
        end
    end
end

function XUiBigWorldMapDetail:OnBtnTransmitClick()
    local pinData = self._PinData

    if pinData and pinData:IsActive() then
        if pinData.TeleportEnable then
            self:_Teleport(pinData)
        elseif pinData:IsNearbyPin() then
            local nearbyPinId = pinData.NearbyPinId
            local nearbyPinData = self._Control:GetPinDataByLevelIdAndPinId(pinData:GetValidLevelId(), nearbyPinId)

            self:_Teleport(nearbyPinData)
        end
    end
end

function XUiBigWorldMapDetail:OnBtnGoClick()
    local pinData = self._PinData
    local quickPinData = self._QuickGoingData

    if quickPinData and pinData then
        local playerGroupId = self._Control:GetCurrentAreaGroupId()

        if playerGroupId ~= pinData.MapAreaGroupId then
            local tips = XMVCA.XBigWorldService:GetText("MapQuickGoingTeleportDesc")

            self:_QuickTeleport(quickPinData, true, self.Name .. "QuickTeleport", tips, true)
        else
            local playerTransform = CS.StatusSyncFight.XFightClient.GetCurrentNpcTransform(false)
            local playerPosition = playerTransform.position
            local targetPosition = pinData.WorldPosition
            local quickPosition = quickPinData.WorldPosition
            local playerDistance = math.pow((targetPosition.x - playerPosition.x), 2) +
                                       math.pow((targetPosition.y - playerPosition.y), 2)
            local quickDistance = math.pow((quickPosition.x - targetPosition.x), 2) +
                                      math.pow((quickPosition.y - targetPosition.y), 2)
            local baseline = math.pow(150, 2)

            if playerDistance > quickDistance and quickDistance > baseline then
                local tips = XMVCA.XBigWorldService:GetText("MapQuickGoingFarTeleportDesc")

                self:_QuickTeleport(quickPinData, true, self.Name .. "QuickFarTeleport", tips)
            elseif playerDistance >= quickDistance and quickDistance <= baseline then
                local tips = XMVCA.XBigWorldService:GetText("MapQuickGoingTeleportDesc")

                self:_QuickTeleport(quickPinData, true, self.Name .. "QuickTeleport", tips, true)
            elseif playerDistance < quickDistance then
                local tips = XMVCA.XBigWorldService:GetText("MapQuickGoingNearTeleportDesc")

                self:_QuickTeleport(quickPinData, true, self.Name .. "QuickNearTeleport", tips, true)
            else
                self:_QuickTeleport(quickPinData)
            end
        end
    end
end

function XUiBigWorldMapDetail:OnPinTrackClick(pinId, levelId)
    if self._Control:CheckCurrentTrackPin(levelId, pinId) then
        self._Control:CancelTrackPin(levelId, pinId)
    else
        self._Control:TrackPin(levelId, pinId)
    end
end

function XUiBigWorldMapDetail:OnRefresh()
    self._QuickGoingData = self._Control:GetQuickGoingPinData(self._PinData)

    self:_Refresh()
end

-- endregion

-- region 私有方法

function XUiBigWorldMapDetail:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self:RegisterClickEvent(self.BtnTracking, self.OnBtnTrackingClick, true)
    self:RegisterClickEvent(self.BtnCancelTracking, self.OnBtnCancelTrackingClick, true)
    self:RegisterClickEvent(self.BtnTransmit, self.OnBtnTransmitClick, true)
    self:RegisterClickEvent(self.BtnGo, self.OnBtnGoClick, true)
end

function XUiBigWorldMapDetail:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMapDetail:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMapDetail:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, self.OnRefresh, self)
end

function XUiBigWorldMapDetail:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, self.OnRefresh, self)
end

function XUiBigWorldMapDetail:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldMapDetail:_Refresh()
    if not self._PinData then
        return
    end

    if self._PinData:IsAiMemoryGroup() then
        self:_RefreshCharacterEcology()
    else
        self:_RefreshNormalPin()
    end
end

function XUiBigWorldMapDetail:_RefreshCharacterEcology()
    local pinData = self._PinData
    local isActive = self._PinData:IsActive()
    local aiMemoryGroupId = pinData:GetAiMemoryGroupId()
    local isShowAiMemory = aiMemoryGroupId > 0

    self.PanelCharacterEcology.gameObject:SetActive(isShowAiMemory)
    self.PanelName.gameObject:SetActive(not isShowAiMemory)
    self.ProgressList.gameObject:SetActive(not isShowAiMemory)
    self.TxtStoryDes.gameObject:SetActive(not isShowAiMemory)
    self.PanelReward.gameObject:SetActive(not isShowAiMemory)

    self:_RefreshPinIcon(self._PinData)
    self:_RefreshTrackOperator(not (isActive and self._PinData.TeleportEnable))
    self:_RefreshTeleportOperator(isActive and self._PinData.TeleportEnable)
    self:_RefreshQuickGoingOperator()

    self.TxtTitle.text = pinData.Name or ""

    if isShowAiMemory then
        if not self._AiMemoryGrids then
            self._AiMemoryGrids = {}
        end
        local configs = self._Control:GetBigworldAIMemorysByGroupId(aiMemoryGroupId)
        XTool.UpdateDynamicItemByUiCache(self._AiMemoryGrids, configs, self.GroupCharacterEcology.transform.parent, nil, self)
        for i = 1, #configs do
            local config = configs[i]
            local cell = self._AiMemoryGrids[i]
            local isUnlock = config.Condition == 0 or XMVCA.XBigWorldService:CheckCondition(config.Condition)
            cell.UnLock.gameObject:SetActive(isUnlock)
            cell.Lock.gameObject:SetActive(not isUnlock)
            if isUnlock then
                cell.TxtNameUnLock.text = config.UnlockedTitle
                cell.CharacterEcologyTaskTxtStoryUnLock.text = XUiHelper.ConvertLineBreakSymbol(config.UnlockedDesc)
            else
                cell.TxtNameLock.text = config.LockedTitle
                cell.CharacterEcologyTaskTxtStoryLock.text = XUiHelper.ConvertLineBreakSymbol(config.LockedDesc)
            end
        end
    end
end

function XUiBigWorldMapDetail:_RefreshNormalPin()
    if self._AiMemoryGrids then
        XTool.UpdateDynamicItemByUiCache(self._AiMemoryGrids, nil, self.GroupCharacterEcology.transform.parent, nil, self)
    end
    self.PanelCharacterEcology.gameObject:SetActive(false)
    self.PanelName.gameObject:SetActive(false)
    self.ProgressList.gameObject:SetActive(true)
    self.TxtStoryDes.gameObject:SetActive(true)
    self.PanelReward.gameObject:SetActive(true)

    if self._PinData:IsQuest() then
        self:_RefreshQuest(self._PinData.QuestId, self._PinData.QuestObjectiveId)
    elseif self._PinData:IsActivity() then
        self:_RefreshActivity(self._PinData.ActivityId)
    else
        self:_RefreshPin()
    end
end

function XUiBigWorldMapDetail:_RefreshPin()
    local isActive = self._PinData:IsActive()

    self.TxtTitle.text = self._PinData.Name or ""
    self.TxtStoryDes.text = XUiHelper.ReplaceTextNewLine(self._PinData.Desc or "")
    self.TxtName.text = XMVCA.XBigWorldService:GetText("MapPinDesc")
    self:_RefreshPinIcon(self._PinData)
    self:_RefreshTrackOperator(not (isActive and self._PinData.TeleportEnable))
    self:_RefreshTeleportOperator(isActive and self._PinData.TeleportEnable)
    self:_RefreshQuickGoingOperator()
    self:_RefreshProgress()
    self:_RefreshReward()
end

function XUiBigWorldMapDetail:_RefreshQuest(questId, objectiveId)
    local rewardId = XMVCA.XBigWorldQuest:GetQuestRewardId(questId)
    local progressText = XMVCA.XBigWorldQuest:GetObjectiveProgressDescByObjectiveId(questId, objectiveId)

    self.TxtTitle.text = XMVCA.XBigWorldQuest:GetQuestText(questId)
    if XTool.IsNumberValid(objectiveId) then
        self.TxtStoryDes.text = XUiHelper.ReplaceTextNewLine(XMVCA.XBigWorldQuest:GetObjectiveDesc(objectiveId) or "")
    else
        self.TxtStoryDes.text = ""
    end
    self.TxtName.text = XMVCA.XBigWorldService:GetText("MapPinQuestDesc")
    self:_RefreshPinIcon(self._PinData)
    self:_RefreshTrackOperator(true)
    self:_RefreshTeleportOperator(false)
    self:_RefreshQuickGoingOperator()
    self:_RefreshProgress(progressText)
    self:_RefreshReward(rewardId)
end

function XUiBigWorldMapDetail:_RefreshActivity(activityId)
    local rewards = XMVCA.XBigWorldGamePlay:GetBigWorldActivityGoodsByActivityId(activityId)

    self:_RefreshPin()
    self:_RefreshRewardList(rewards)
end

function XUiBigWorldMapDetail:_RefreshTeleportOperator(isActive)
    if not self._PinData:IsNearbyPin() then
        self.BtnTransmit.gameObject:SetActiveEx(isActive)

        if isActive then
            if self._PinData:IsTeleportLevel() then
                self:_RefreshTeleportLevelText(self._PinData:GetTeleportLevelId())
            else
                self:_RefreshTeleportLevelText()
            end
        end
    else
        local nearbyPinId = self._PinData.NearbyPinId
        local nearbyPinData = self._Control:GetPinDataByLevelIdAndPinId(self._PinData:GetValidLevelId(), nearbyPinId)

        if nearbyPinData then
            if nearbyPinData:IsTeleportLevel() then
                self.BtnTransmit.gameObject:SetActiveEx(true)
                self:_RefreshTeleportLevelText(nearbyPinData:GetTeleportLevelId())
            else
                self.BtnTransmit.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiBigWorldMapDetail:_RefreshTrackOperator(isActive)
    local isTrack = self._PinData:IsTracking()

    self.BtnTracking.gameObject:SetActiveEx(isActive and not isTrack)
    self.BtnCancelTracking.gameObject:SetActiveEx(isActive and isTrack)
end

function XUiBigWorldMapDetail:_RefreshQuickGoingOperator()
    if self._PinData then
        --- 任务在宿舍内绑定宿舍节点特殊处理
        local isNearBy = self._PinData:IsNearbyPin()
        local isNearByTeleportLevel = false

        if isNearBy then
            local nearbyPinId = self._PinData.NearbyPinId
            local nearbyPinData =
                self._Control:GetPinDataByLevelIdAndPinId(self._PinData:GetValidLevelId(), nearbyPinId)

            if nearbyPinData then
                isNearByTeleportLevel = nearbyPinData:IsTeleportLevel()
            end
        end

        if isNearByTeleportLevel or self._PinData:IsCouldTeleport() or not self._PinData:IsTracking() then
            self.BtnGo.gameObject:SetActiveEx(false)
        else
            self.BtnGo.gameObject:SetActiveEx(true)

            if self._QuickGoingData then
                self.BtnGo:SetButtonState(CS.UiButtonState.Normal)
            else
                self.BtnGo:SetDisable(true, false)
            end
        end
    else
        self.BtnGo.gameObject:SetActiveEx(false)
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMapDetail:_RefreshPinIcon(pinData)
    if pinData then
        local isActive = pinData:IsActive()

        self:_RefreshPinStyle(pinData.StyleId, isActive)
    end
end

function XUiBigWorldMapDetail:_RefreshPinStyle(styleId, isActive)
    if XTool.IsNumberValid(styleId) then
        self.PanelIcon:SetSprite(self._Control:GetPinIconByStyleId(styleId, isActive))
    end
end

function XUiBigWorldMapDetail:_RefreshTeleportLevelText(teleportLevelId)
    if XTool.IsNumberValid(teleportLevelId) then
        self.BtnTransmit:SetNameByGroup(0, self._Control:GetTeleportLevelText(teleportLevelId))
    else
        self.BtnTransmit:SetNameByGroup(0, XMVCA.XBigWorldService:GetText("MapTeleportDesc"))
    end
end

function XUiBigWorldMapDetail:_RefreshTeleportText(text)
    self.BtnTransmit:SetNameByGroup(0, text or XMVCA.XBigWorldService:GetText("MapTeleportDesc"))
end

function XUiBigWorldMapDetail:_RefreshReward(rewardId)
    if XTool.IsNumberValid(rewardId) then
        local rewardList = XMVCA.XBigWorldService:GetRewardDataList(rewardId)

        self:_RefreshRewardList(rewardList)
    else
        self:_RefreshRewardList()
    end
end

function XUiBigWorldMapDetail:_RefreshRewardList(rewardList)
    if not XTool.IsTableEmpty(rewardList) then
        self.PanelReward.gameObject:SetActiveEx(true)
        for i, reward in pairs(rewardList) do
            local grid = self._RewardGrids[i]

            if not grid then
                local ui = i == 1 and self.ItemGrid or XUiHelper.Instantiate(self.ItemGrid, self.PanelItem)

                grid = XUiSGGridItem.New(ui, self)
                self._RewardGrids[i] = grid
            end

            grid:Open()
            grid:Refresh(reward)
            grid:RefreshName()
        end
        for i = #rewardList + 1, #self._RewardGrids do
            self._RewardGrids[i]:Close()
        end
    else
        for _, grid in pairs(self._RewardGrids) do
            grid:Close()
        end
        self.PanelReward.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldMapDetail:_RefreshProgress(progressText)
    if not string.IsNilOrEmpty(progressText) then
        self.ProgressList.gameObject:SetActiveEx(true)
        self.PanelProgress:SetName(progressText)
    else
        self.ProgressList.gameObject:SetActiveEx(false)
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMapDetail:_Teleport(pinData)
    if pinData and pinData.TeleportEnable then
        local teleportLevelId = pinData:GetTeleportLevelId()
        local currentLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()

        if pinData:IsTeleportLevel() or teleportLevelId ~= currentLevelId then
            local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

            confirmData:InitInfo(nil, self._Control:GetTeleportLevelTips(teleportLevelId))
            confirmData:InitToggleActive(true):InitKey(self.Name)
            confirmData:InitSureClick(nil, function()
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT,
                    teleportLevelId, pinData.LevelId, pinData.PinId)
            end)
            confirmData:InitCancelAndCloseClick(nil, function()
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_CLOSE)
            end)

            if not XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData) then
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT,
                    teleportLevelId, pinData.LevelId, pinData.PinId)
            else
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_OPEN)
            end
        else
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT, teleportLevelId,
                pinData.LevelId, pinData.PinId)
        end
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMapDetail:_QuickTeleport(pinData, isPopConfirm, key, tips, isToggleActive, cb)
    if pinData and pinData:IsCouldTeleport() then
        local teleportLevelId = pinData:GetTeleportLevelId()
        local currentLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
        local pinId = pinData.PinId
        local mapPinLevelId = pinData.LevelId

        if isPopConfirm then
            local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

            confirmData:InitInfo(nil, tips)
            confirmData:InitToggleActive(isToggleActive or false):InitKey(key)
            confirmData:InitSureClick(nil, function()
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT,
                    teleportLevelId, mapPinLevelId, pinId)
                if cb then cb() end
            end)
            confirmData:InitCancelAndCloseClick(nil, function()
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_CLOSE)
            end)

            if not XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData) then
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT,
                    teleportLevelId, mapPinLevelId, pinId)
            else
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_OPEN)
            end
        else
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT, teleportLevelId,
                mapPinLevelId, pinId)
            if cb then cb() end
        end
    end
end

-- endregion

return XUiBigWorldMapDetail
