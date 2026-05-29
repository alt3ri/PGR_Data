---@class XUiGirdBigWorldEnvironmentalStory: XUiNode
local XUiGirdBigWorldEnvironmentalStory = XClass(XUiNode, "XUiGirdBigWorldEnvironmentalStory")

function XUiGirdBigWorldEnvironmentalStory:OnStart()
    self.BtnReward:AddEventListener(handler(self, self.OnBtnRewardClick))
    self.BtnGo:AddEventListener(handler(self, self.OnBtnGoClick))
end

function XUiGirdBigWorldEnvironmentalStory:Refresh(id)
    self.RImgCharacter:SetRawImage(XMVCA.XBigWorldQuest:GetEnvironmentQuestRoleIcon(id))
    self.TxtName.text = XMVCA.XBigWorldQuest:GetEnvironmentQuestName(id)
    local reward = XMVCA.XBigWorldQuest:GetEnvironmentQuestShowReward(id)

    self:RefreshReward(reward)
    local cur, sum = XMVCA.XBigWorldQuest:GetEnvironmentProgress(id)
    self.BtnGo:SetNameByGroup(0, string.format("%s/%s", cur, sum))
    local complete = XMVCA.XBigWorldQuest:CheckEnvironmentFinish(id)
    self.BtnReward:SetDisable(complete, not complete)
    self._SkipId = XMVCA.XBigWorldQuest:GetEnvironmentQuestSkipId(id)
end

function XUiGirdBigWorldEnvironmentalStory:RefreshReward(rewardId)
    self._GoodsParams = nil
    local rewardList
    if rewardId and rewardId > 0 then
        rewardList = XMVCA.XBigWorldGamePlay:GetBigWorldGoodsByGroupId(rewardId)
        -- local reward = rewardList[1]
        -- if reward then
        -- local id = reward.TemplateId or reward.Id
        -- self._GoodsParams = XMVCA.XBigWorldService:GetGoodsShowParamsByTemplateId(id)
        -- self.BtnReward:SetRawImage(self._GoodsParams.Icon)
        -- end
    end
    self._RewardList = rewardList
    self.BtnReward.gameObject:SetActiveEx(rewardList ~= nil)
end

function XUiGirdBigWorldEnvironmentalStory:OnBtnRewardClick()
    if not self._RewardList then
        return
    end
    XMVCA.XBigWorldUI:OpenBigWorldObtain(self._RewardList, XMVCA.XBigWorldService:GetText("TipReward"), nil, true)
end

function XUiGirdBigWorldEnvironmentalStory:OnBtnGoClick()
    if not self._SkipId or self._SkipId <= 0 then
        XLog.Warning("无法跳转，跳转Id为空")
        return
    end

    if not self.Parent:TryChangeOnDuty() then
        XMVCA.XBigWorldSkipFunction:SkipTo(self._SkipId)
    end
end

---@class XUiGirdBigWorldEnvironmentalGroup: XUiNode
local XUiGirdBigWorldEnvironmentalGroup = XClass(XUiNode, "XUiGirdBigWorldEnvironmentalGroup")

function XUiGirdBigWorldEnvironmentalGroup:OnStart()
    self._Tabs = {}
    self._Configs = table.empty
    self._LevelId = 0

    self.BtnTab.gameObject:SetActiveEx(false)
end

function XUiGirdBigWorldEnvironmentalGroup:OnTabClick(index)
    local config = self._Configs[index]

    self.Parent:Refresh(config)
end

function XUiGirdBigWorldEnvironmentalGroup:OnDestroy()
    if XTool.IsNumberValid(self._LevelId) then
        XMVCA.XBigWorldQuest:SetRecordEnvironmentalGroup(self._LevelId)
        XMVCA.XBigWorldQuest:SaveEnvironmentalGroupNews(self._LevelId)
    end
end

---@param config XTableDlcEnvironmentQuestLevel
function XUiGirdBigWorldEnvironmentalGroup:Refresh(config, isRealSelect, selectTarget)
    local name = config.Name

    if string.IsNilOrEmpty(name) then
        name = XMVCA.XBigWorldMap:GetLevelName(config.LevelId)
    end

    self._LevelId = config.LevelId
    self.TexTital.text = name
    self.GroupRed.gameObject:SetActiveEx(not XMVCA.XBigWorldQuest:GetRecordEnvironmentalGroup(config.LevelId))
    self:RefreshTabs(config, isRealSelect, selectTarget)
end

---@param config XTableDlcEnvironmentQuestLevel
function XUiGirdBigWorldEnvironmentalGroup:RefreshTabs(config, isRealSelect, selectTarget)
    local groupIds = config.GroupIds

    self._Configs = {}
    if not XTool.IsTableEmpty(groupIds) then
        local index = 1
        local seleceIndex = 1
        local defaultOnDuty = XMVCA.XBigWorldQuest:GetEnvironmentQuestGroupOnDuty(config.LevelId)
        local tabs = {}

        self.TabGroup.gameObject:SetActiveEx(true)
        for _, groupId in pairs(groupIds) do
            local groupConfig = XMVCA.XBigWorldQuest:GetEnvironmentQuestGroupTemplate(groupId)
            local isOnDuty = false

            if groupConfig then
                local tab = self._Tabs[index]

                if not tab then
                    tab = XUiHelper.Instantiate(self.BtnTab, self.TabGroup.transform)

                    self._Tabs[index] = tab
                end

                if XTool.IsNumberValid(defaultOnDuty) then
                    isOnDuty = defaultOnDuty == groupConfig.Id
                else
                    isOnDuty = groupConfig.IsDefaultGroup
                end
                if XTool.IsNumberValid(selectTarget) then
                    if selectTarget == groupConfig.Id then
                        seleceIndex = index
                    end
                elseif isOnDuty then
                    seleceIndex = index
                end
                
                tab:ShowTag(isOnDuty)
                tab:ShowReddot(XMVCA.XBigWorldQuest:CheckEnvironmentGroupFinish(groupId))
                self._Configs[index] = groupConfig
                tabs[index] = tab
                index = index + 1
                tab.gameObject:SetActiveEx(true)
                tab:SetNameByGroup(0, groupConfig.Name)
            end
        end
        for i = index, #self._Tabs do
            self._Tabs[i].gameObject:SetActiveEx(false)
        end

        self.TabGroup:Init(tabs, Handler(self, self.OnTabClick))
        self.TabGroup:SelectIndex(seleceIndex, isRealSelect)
    else
        self.TabGroup.gameObject:SetActiveEx(false)

        for _, tab in pairs(self._Tabs) do
            tab.gameObject:SetActiveEx(false)
        end
    end
end

---@class XUiBigWorldPopupEnvironmentalStory: XBigWorldUi
local XUiBigWorldPopupEnvironmentalStory = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupEnvironmentalStory")

function XUiBigWorldPopupEnvironmentalStory:OnAwake()
    ---@type XUiGirdBigWorldEnvironmentalGroup[]
    self._Groups = {}
    self._GroupLevelConfigs = XMVCA.XBigWorldQuest:GetEnvironmentQuestGroupLevelConfigs()
    self._IsOnDuty = false

    self:InitUi()
    self:InitCb()

    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_ECOLOGY_LOAD_COMPLETE,
        self.OnEnvironmentGroupChangeComplete, self)
end

function XUiBigWorldPopupEnvironmentalStory:OnStart(id)
    self:InitGroups(id)
end

function XUiBigWorldPopupEnvironmentalStory:OnDestroy()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_ECOLOGY_LOAD_COMPLETE,
        self.OnEnvironmentGroupChangeComplete, self)
    self:RemoveTimer()
end

function XUiBigWorldPopupEnvironmentalStory:InitUi()
    self.GridStory.gameObject:SetActiveEx(false)
    self.GridGroup.gameObject:SetActiveEx(false)
    self._DynamicTable = XUiHelper.DynamicTableNormal(self, self.ListStory, XUiGirdBigWorldEnvironmentalStory)

    self.TxtTips.text = XMVCA.XBigWorldService:GetText("EnvironmentalStoryTip")
end

function XUiBigWorldPopupEnvironmentalStory:InitCb()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.Close))
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
    self.BtnTimeDetail:AddEventListener(handler(self, self.OnBtnTimeDetailClick))
end

function XUiBigWorldPopupEnvironmentalStory:InitGroups(id)
    if not XTool.IsTableEmpty(self._GroupLevelConfigs) then
        local levelId = self._GroupLevelConfigs[1].LevelId

        if XTool.IsNumberValid(id) then
            local groupId = XMVCA.XBigWorldQuest:GetEnvironmentQuestGroupId(id)

            levelId = XMVCA.XBigWorldQuest:GetEnvironmentQuestGroupLevelId(groupId)
        end

        for index, config in pairs(self._GroupLevelConfigs) do
            local group = self._Groups[index]
            local groupId = nil

            if not group then
                local groupUi = XUiHelper.Instantiate(self.GridGroup, self.GroupContent)

                group = XUiGirdBigWorldEnvironmentalGroup.New(groupUi, self)

                self._Groups[index] = group
            end

            if XTool.IsNumberValid(id) then
                groupId = XMVCA.XBigWorldQuest:GetEnvironmentQuestGroupId(id)
            end

            group:Open()
            group:Refresh(config, levelId == config.LevelId, groupId)

            if XTool.IsNumberValid(id) and levelId == config.LevelId then
                XScheduleManager.ScheduleNextFrame(function()
                    XUiHelper.ScrollTo(self.ListGroup, group.Transform)
                end)
            end
        end
        for i = #self._GroupLevelConfigs + 1, #self._Groups do
            self._Groups[i]:Close()
        end
    else
        for i = 1, #self._Groups do
            self._Groups[i]:Close()
        end
    end
end

---@param grid XUiGirdBigWorldEnvironmentalStory
function XUiBigWorldPopupEnvironmentalStory:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._DataList[index])
    end
end

function XUiBigWorldPopupEnvironmentalStory:TryChangeOnDuty()
    if not self._IsOnDuty then
        self:ConfirmChangeEnvironmentQuestGroup()
    end

    return not self._IsOnDuty
end

function XUiBigWorldPopupEnvironmentalStory:ConfirmChangeEnvironmentQuestGroup()
    local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

    confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText("EnvironmentalStoryTryOnDuty"))
    confirmData:InitToggleActive(false)
    confirmData:InitSureClick(nil, function()
        self:ChangeEnvironmentQuestGroup()
    end, true)

    XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
end

function XUiBigWorldPopupEnvironmentalStory:ChangeEnvironmentQuestGroup()
    XMVCA.XBigWorldQuest:RequestEnvironmentQuestGroupChange(self._LevelId, self._GroupId, function()
        self._IsReload = true
        self:RemoveTimer()
        XMVCA.XBigWorldLoading:OpenLoadingByType(XMVCA.XBigWorldLoading.LoadingType.BlackMask, nil, function()
            XMVCA.XBigWorldUI:TipText("EnvironmentalStoryChangeTip")
        end)
        self._Timer = XScheduleManager.ScheduleOnce(function()
            self._Timer = nil
            self:OnEnvironmentGroupChangeComplete()
        end, XScheduleManager.SECOND)
    end)
end

function XUiBigWorldPopupEnvironmentalStory:OnBtnConfirmClick()
    if not self._IsOnDuty then
        self:ConfirmChangeEnvironmentQuestGroup()
    else
        XMVCA.XBigWorldUI:TipText("EnvironmentalStoryOnDuty")
    end
end

function XUiBigWorldPopupEnvironmentalStory:OnBtnTimeDetailClick()
    local dialogId = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("BigWorldEnvironmentalStoryDialogId")

    if XTool.IsNumberValid(dialogId) then
        XMVCA.XBigWorldUI:OpenTextDialog(dialogId)
    end
end

function XUiBigWorldPopupEnvironmentalStory:OnEnvironmentGroupChangeComplete()
    if self._IsReload then
        self._IsReload = false
        self:RemoveTimer()
        XMVCA.XBigWorldUI:RunMain()
        XMVCA.XBigWorldLoading:CloseCurrentLoading()
    end
end

function XUiBigWorldPopupEnvironmentalStory:RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiBigWorldPopupEnvironmentalStory:SortEnvironmentIds(ids)
    if XTool.IsTableEmpty(ids) then
        return
    end

    table.sort(ids, function(a, b)
        local finishA = XMVCA.XBigWorldQuest:CheckEnvironmentFinish(a)
        local finishB = XMVCA.XBigWorldQuest:CheckEnvironmentFinish(b)
        if finishA ~= finishB then
            return finishB
        end

        local pA = XMVCA.XBigWorldQuest:GetEnvironmentQuestPriority(a)
        local pB = XMVCA.XBigWorldQuest:GetEnvironmentQuestPriority(b)
        if pA ~= pB then
            return pA > pB
        end
        return a < b
    end)
    return ids
end

function XUiBigWorldPopupEnvironmentalStory:CalIndexByEnvironmentId(id)
    if not id or id <= 0 then
        return 1
    end
    for index, environmentId in pairs(self._DataList) do
        if environmentId == id then
            return index
        end
    end
    return 1
end

---@param groupConfig XTableDlcEnvironmentQuestGroup
function XUiBigWorldPopupEnvironmentalStory:Refresh(groupConfig, targetId)
    if groupConfig.Id == self._GroupId then
        return
    end

    self._IsOnDuty = false
    self._LevelId = groupConfig.LevelId
    self._GroupId = groupConfig.Id
    self._DataList = self:SortEnvironmentIds(XMVCA.XBigWorldQuest:GetEnvironmentIdsByGroup(self._GroupId))

    local index = XTool.IsNumberValid(targetId) and self:CalIndexByEnvironmentId(targetId) or 1
    local defaultOnDuty = XMVCA.XBigWorldQuest:GetEnvironmentQuestGroupOnDuty(groupConfig.LevelId)

    if XTool.IsNumberValid(defaultOnDuty) then
        self._IsOnDuty = defaultOnDuty == groupConfig.Id
    else
        self._IsOnDuty = groupConfig.IsDefaultGroup
    end

    self.BtnConfirm:SetDisable(self._IsOnDuty, true)
    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync(index)
end
