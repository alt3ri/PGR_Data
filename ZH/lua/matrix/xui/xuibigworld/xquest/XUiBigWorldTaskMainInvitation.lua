---@class XUiBigWorldTaskMainInvitation : XBigWorldUi
---@field _Control XBigWorldQuestControl
---@field PanelTabBtnGroup XUiButtonGroup
---@field _TabList XUiComponent.XUiButton[]
---@field _ComponentList XUiComponent.XUiComponentGroup[]
---@field _GridCommon XUiGridBWItem
---@field _GridCache table<number, XUiGridBWBranchResult>
---@field _DynamicTable XDynamicTableCurve
---@field _DisplayController XUiModelDisplayController
local XUiBigWorldTaskMainInvitation = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldTaskMainInvitation")

local XDynamicTableCurve = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableCurve")
local XUiGridBWBranchResult = require("XUi/XUiBigWorld/XQuest/Grid/XUiGridBWBranchResult")
local XUiModelDisplayController = require("XUi/XUiCommon/XUiModelDisplay/XUiModelDisplayController")

function XUiBigWorldTaskMainInvitation:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldTaskMainInvitation:OnStart(questId)
    self._DefaultIndex = self:CalIndexByQuestId(questId)
    self:InitView()
end

function XUiBigWorldTaskMainInvitation:OnEnable()
    self.PanelTabBtnGroup:SelectIndex(self._DefaultIndex)
end

function XUiBigWorldTaskMainInvitation:OnDisable()
    self._DefaultIndex = self._TabIndex
    self._TabIndex = nil
    self:StopAutoSwitch()
end

function XUiBigWorldTaskMainInvitation:OnDestroy()
end

function XUiBigWorldTaskMainInvitation:InitUi()
    self:InitDisplay()
    self._Tab2SelectIndex = {}
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
    
    self._ConditionId = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("BranchCondition")
    
    self._ConditionPass, self._ConditionDesc = XMVCA.XBigWorldService:CheckCondition(self._ConditionId)

    local tabList = {}
    local componentGroupList = {}
    self._TabConditions = {}
    self._BranchIds = self:SortBranchIds()
    for index, id in ipairs(self._BranchIds) do
        local btn = index == 1 and self.BtnTab or XUiHelper.Instantiate(self.BtnTab, self.PanelTabBtnGroup.transform)
        btn.gameObject:SetActiveEx(false)
        ---@type XUiComponent.XUiComponentGroup
        local componentGroup = btn.gameObject:GetComponent(typeof(CS.XUiComponent.XUiComponentGroup))
        componentGroupList[#componentGroupList + 1] = componentGroup
        tabList[#tabList + 1] = btn
        componentGroup:SetRawImageWithGroup(0, XMVCA.XBigWorldQuest:GetInviteQuestRoleIcon(id))
        local conditionId = self._Control:GetInviteQuestCondition(id)
        if conditionId and conditionId > 0 then
            local isPass, desc = XMVCA.XBigWorldService:CheckCondition(conditionId)
            btn:SetDisable(not isPass)
            self._TabConditions[index] = {
                Pass = isPass,
                Desc = desc
            }
        else
            self._TabConditions[index] = {
                Pass = true,
                Desc = ""
            }
        end
        local timerId = XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(btn) then
                return
            end
            btn.gameObject:SetActiveEx(true)
        end, (index - 1) * 120)
        self._Tab2SelectIndex[index] = 0
    end
    self._TabList = tabList
    self._ComponentList = componentGroupList
    self.PanelTabBtnGroup:Init(tabList, function(index) self:OnSelectTab(index) end)

    self.BtnStart:SetDisable(not self._ConditionPass)
    self._GridCommon = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem").New(self.UiBigWorldItemGrid, self, handler(self, self.OnClickCommon))

    self:InitDynamicTable()
end

function XUiBigWorldTaskMainInvitation:InitDynamicTable()
    self._DynamicTable = XDynamicTableCurve.New(self.ScrollRect)
    self._DynamicTable:SetProxy(XUiGridBWBranchResult, self)
    self._DynamicTable:SetDelegate(self)
    self.GridEnding.gameObject:SetActiveEx(false)

    -- 初始化拖拽状态管理
    self._IsDragging = false
    self._GridCache = {}  -- 缓存grid，index -> grid
end

function XUiBigWorldTaskMainInvitation:InitDisplay()
    local uiModelRoot = self.UiModelGo.transform
    local panelRoleModel = uiModelRoot and uiModelRoot:FindTransform("PanelRoleModel") or uiModelRoot:FindTransform("RoleCameraPoint")
    
    self._DisplayController = XUiModelDisplayController.New(uiModelRoot, true)
    
    self.PanelRoleModel = panelRoleModel
    self.NearCamera = uiModelRoot:FindTransform("UiNearCamera"):GetComponent("Camera")
    self.EffectChangeRole = uiModelRoot and uiModelRoot:FindTransform("FxUiBigWorldRoleRoom3DShenqi")
end

function XUiBigWorldTaskMainInvitation:InitCb()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnStart:AddEventListener(handler(self, self.OnBtnStartClick))
    self.BtnContinue:AddEventListener(handler(self, self.OnBtnContinueClick))
    if self.BtnDIY then
        self.BtnDIY:AddEventListener(handler(self, self.OnBtnDIYClick))
    end
end

function XUiBigWorldTaskMainInvitation:InitView()
end

function XUiBigWorldTaskMainInvitation:OnSelectTab(tabIndex)
    local condition = self._TabConditions[tabIndex]
    if condition and not condition.Pass then
        XUiManager.TipError(condition.Desc)
        return
    end

    if tabIndex == self._TabIndex then
        return
    end
    self._IsDragging = false
    self._IsManualSwitch = false
    self:StartAutoSwitch()
    
    self._TabIndex = tabIndex
    self:RefreshDetail(tabIndex)
    self:RefreshRole(tabIndex)
    self:RefreshRedPoint()
end

function XUiBigWorldTaskMainInvitation:RefreshDetail(tabIndex)
    local questId = self._BranchIds[tabIndex]
    self:RefreshTotalReward(self._Control:GetInviteQuestTotalRewardId(questId))
    self:RefreshResult(tabIndex)

    local name = XMVCA.XBigWorldQuest:GetInviteQuestName(questId)
    self.TxtName.text = name
    self.TxtDetail.text = XMVCA.XBigWorldQuest:GetQuestText(questId)
    self.TxtInfo.text = self._Control:GetInviteQuestTipText(questId)

    local questData = XMVCA.XBigWorldQuest:GetQuestData(questId)
    local isOpened = questData:IsInProgress()

    self.BtnStart.gameObject:SetActiveEx(not isOpened)
    self.BtnContinue.gameObject:SetActiveEx(isOpened)
    self:RefreshNumber()
end

function XUiBigWorldTaskMainInvitation:RefreshNumber()
    local questId = self._BranchIds[self._TabIndex]
    local resultIds = self._Control:GetInviteQuestResultIds(questId)
    local total = XTool.IsTableEmpty(resultIds) and 0 or #resultIds
    local finished = 0
    if not XTool.IsTableEmpty(resultIds) then
        for _, resultId in ipairs(resultIds) do
            if XMVCA.XBigWorldQuest:CheckInviteResultFinish(resultId) then
                finished = finished + 1
            end
        end
    end
    self.TxtNember.text = finished .. "/" .. total
end

function XUiBigWorldTaskMainInvitation:RefreshRole(tabIndex)
    if self._DisplayModelId then
        self._DisplayController:SetModelActive(self._DisplayModelId, false)
    end
    local id = self._BranchIds[tabIndex]
    local modelId = self._Control:GetInviteQuestModelId(id)
    
    local modelUrl = XMVCA.XBigWorldResource:GetModelUrl(modelId)
    local controllerUrl = XMVCA.XBigWorldResource:GetModelControllerUrl(modelId)
    
    self._DisplayController:AddOrUpdateModel(self._DisplayController:GetDisplayHelper().CreateBWModelDisplayInfo(
            modelId, modelUrl, controllerUrl, self.NearCamera, self.PanelRoleModel, 0))

    self.EffectChangeRole.gameObject:SetActiveEx(false)
    self.EffectChangeRole.gameObject:SetActiveEx(true)
    
    local animName = XMVCA.XBigWorldResource:GetDlcUiDefaultAnimationName(modelId)
    if not string.IsNilOrEmpty(animName) then
        self._DisplayController:PlayAnimation(modelId, animName)
    end
    self._DisplayModelId = modelId
end

function XUiBigWorldTaskMainInvitation:RefreshTotalReward(rewardId)
    if rewardId and rewardId > 0 then
        local rewardList = XRewardManager.GetRewardList(rewardId)
        if not XTool.IsTableEmpty(rewardList) then
            local questId = self._BranchIds[self._TabIndex]
            self._GridCommon:Update(rewardList[1])
            self._GridCommon:RefreshReceive(XMVCA.XBigWorldQuest:CheckInviteFinish(questId) and XMVCA.XBigWorldQuest:CheckInviteRewardReceived(questId))
        else
            self._GridCommon:Close()
        end
    else
        self._GridCommon:Close()
    end
end

function XUiBigWorldTaskMainInvitation:RefreshResult(tabIndex)
    local questId = self._BranchIds[tabIndex]
    local resultIds = self._Control:GetInviteQuestResultIds(questId)
    local dataSource = {}
    if not XTool.IsTableEmpty(resultIds) then
        for _, resultId in ipairs(resultIds) do
            table.insert(dataSource, {
                QuestId = questId,
                ResultId = resultId,
            })
        end
    end

    self._DynamicTable:SetDataSource(dataSource)
    self._DynamicTable:ReloadData(self._Tab2SelectIndex[self._TabIndex])
end

---@param grid XUiGridBWBranchResult
function XUiBigWorldTaskMainInvitation:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then

        local data = self._DynamicTable:GetData(index + 1)
        if data then
            grid:Refresh(data)
        end
        self._GridCache[index] = grid
        if self._IsDragging then
            grid:PlayCollapseAnim(false)
        else
            local centerIndex = self._Tab2SelectIndex[self._TabIndex]
            if centerIndex == index then
                grid:PlayExpandAnim(false)
            else
                grid:PlayCollapseAnim(false)
            end
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local selectIndex = self._Tab2SelectIndex[self._TabIndex]
        if selectIndex == index then
            grid:OnBtnClick()
        else
            self._IsManualSwitch = true
            self._DynamicTable.Imp:TweenToIndex(index)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_BEGIN_DRAG then
        if self._DynamicTable.Imp.TotalCount <= 1 then
            return
        end
        self:StopAutoSwitch()
        local selectIndex = self._Tab2SelectIndex[self._TabIndex]
        for i, v in pairs(self._GridCache) do
            v:PlayCollapseAnim(selectIndex == i)
        end
        self._IsManualSwitch = true
        self._IsDragging = true
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        self:UpdateSelectIndex()
    end
end

function XUiBigWorldTaskMainInvitation:UpdateSelectIndex()
    local index = self._DynamicTable:GetTweenIndex()
    if XTool.IsTableEmpty(self._GridCache) or not self._GridCache[index] then
        return
    end
    if self._IsDragging then
        self._GridCache[index]:PlayExpandAnim(true)
        self._IsDragging = false
    else
        local selectIndex = self._Tab2SelectIndex[self._TabIndex]
        if selectIndex ~= index then
            local lastGrid = self._GridCache[selectIndex]
            lastGrid:PlayCollapseAnim(true)
            self._GridCache[index]:PlayExpandAnim(true)
        end
    end
    if self._IsManualSwitch then
        self._IsManualSwitch = false
        self:StartAutoSwitch()
    end
    self._Tab2SelectIndex[self._TabIndex] = index
end

function XUiBigWorldTaskMainInvitation:CheckInviteRedPoint(id)
    return XMVCA.XBigWorldQuest:CheckInviteRedPoint(id)
end

function XUiBigWorldTaskMainInvitation:RefreshRedPoint()
    local currentReward = false
    for index, questId in pairs(self._BranchIds) do
        local btn = self._TabList[index]
        local showRed = self:CheckInviteRedPoint(questId)
        if btn then
            btn:ShowReddot(showRed)
        end
        if index == self._TabIndex then
            currentReward = showRed
        end
    end
    if self.PanelActive then
        self.PanelActive.gameObject:SetActiveEx(currentReward)
    end
end

function XUiBigWorldTaskMainInvitation:SortBranchIds()
    local ids = self._Control:GetInviteIds()
    if XTool.IsTableEmpty(ids) then
        return ids
    end
    local control = self._Control
    table.sort(ids, function(a, b)
        local completeA = XMVCA.XBigWorldQuest:CheckInviteFinish(a)
        local completeB = XMVCA.XBigWorldQuest:CheckInviteFinish(b)
        if completeA ~= completeB then
            return completeB
        end
        local pA = control and control:GetInviteQuestPriority(a) or 0
        local pB = control and control:GetInviteQuestPriority(b) or 0
        if pA ~= pB then
            return pA > pB
        end
        return a < b
    end)
    
    return ids
end

function XUiBigWorldTaskMainInvitation:OnClickCommon(itemParms, goodsParams)
    local questId = self._BranchIds[self._TabIndex]
    local tabIndex = self._TabIndex
    --已经完成 && 未领取
    if XMVCA.XBigWorldQuest:CheckInviteFinish(questId) and not XMVCA.XBigWorldQuest:CheckInviteRewardReceived(questId) then
        self._Control:RequestReceiveInviteReward(questId, function()
            self:RefreshDetail(tabIndex)
            self:RefreshRedPoint()
        end)
    else
        local rewardId = self._Control:GetInviteQuestTotalRewardId(questId)
        XMVCA.XBigWorldUI:OpenBigWorldObtain(XMVCA.XBigWorldService:GetRewardDataList(rewardId), XMVCA.XBigWorldService:GetText("TipReward"), nil, true, false)
    end
end

function XUiBigWorldTaskMainInvitation:CalIndexByQuestId(questId)
    if not questId or questId <= 0 then
        return self:GetFirstUnlockedIndex()
    end
    for index, id in ipairs(self._BranchIds) do
        if questId == id then
            return index
        end
    end
    return self:GetFirstUnlockedIndex()
end

function XUiBigWorldTaskMainInvitation:GetFirstUnlockedIndex()
    for index, _ in ipairs(self._BranchIds) do
        local condition = self._TabConditions[index]
        if condition and condition.Pass then
            return index
        end
    end
    return 1
end

function XUiBigWorldTaskMainInvitation:OnBtnStartClick()
    if not self._ConditionPass then
        XUiManager.TipMsg(self._ConditionDesc)
        return
    end
    local questId = self._BranchIds[self._TabIndex]
    if not XMVCA.XBigWorldQuest:IsInvitePopped(questId) then
        local popTip = self._Control:GetInviteQuestPopTipText(questId)
        if not string.IsNilOrEmpty(popTip) then
            local commonData = XMVCA.XBigWorldCommon:GetPopupConfirmData()
            local markFunc = function()
                XMVCA.XBigWorldQuest:SetInvitePopup(questId)
            end
            commonData:InitSureClick(nil,
                    function() self:DoAcceptInviteQuest() end):InitInfo(nil, popTip
            ):InitToggle(
                    XMVCA.XBigWorldService:GetText("LoginWillNoLongerPrompt"), markFunc)

            XMVCA.XBigWorldUI:OpenConfirmPopup(commonData)
        else
            self:DoAcceptInviteQuest()
        end
    else
        self:DoAcceptInviteQuest()
    end
end

function XUiBigWorldTaskMainInvitation:DoAcceptInviteQuest()
    local questId =  self._BranchIds[self._TabIndex]
    self._Control:RequestAcceptInviteQuest(questId, function()
        XMVCA.XBigWorldUI:CloseAllUpperUiWithCallback("UiFightDLC")
    end)
end

function XUiBigWorldTaskMainInvitation:OnBtnContinueClick()
    local questId = self._BranchIds[self._TabIndex]
    if XMVCA.XBigWorldUI:IsUiLoad("UiBigWorldTaskMain") then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_REFRESH_MAIN_SELECT, questId)
        XMVCA.XBigWorldUI:SafeClose("UiBigWorldProcess")
        self:Close()
    else
        XMVCA.XBigWorldUI:CloseAllUpperUiWithCallback("UiFightDLC", function() 
            XMVCA.XBigWorldQuest:OpenQuestMainByType(XMVCA.XBigWorldQuest.QuestType.Invitation)
        end)
    end
end

function XUiBigWorldTaskMainInvitation:OnBtnDIYClick()
    XMVCA.XBigWorldCommanderDIY:OpenMainUi()
end

function XUiBigWorldTaskMainInvitation:StartAutoSwitch()
    self:StopAutoSwitch()

    self._AutoSwitchScheduleId = XScheduleManager.ScheduleForever(function()
        self:SwitchToNextGrid()
    end, 5000, 0)  
end

function XUiBigWorldTaskMainInvitation:StopAutoSwitch()
    if self._AutoSwitchScheduleId then
        XScheduleManager.UnSchedule(self._AutoSwitchScheduleId)
        self._AutoSwitchScheduleId = nil
    end
end

function XUiBigWorldTaskMainInvitation:SwitchToNextGrid()
    if not self._DynamicTable or not self._DynamicTable.Imp then
        return
    end

    local currentIndex = self._DynamicTable.Imp.StartIndex
    local totalCount = self._DynamicTable.Imp.TotalCount

    if totalCount <= 1 then
        return
    end

    local nextIndex = (currentIndex + 1) % totalCount
    self._DynamicTable:TweenToIndex(nextIndex)
end