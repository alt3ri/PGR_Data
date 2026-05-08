---@class XUiGridBwQuestTitle : XUiNode
---@field Parent XUiPanelBWTaskGroup
---@field _Control XBigWorldQuestControl
local XUiGridBwQuestTitle = XClass(XUiNode, "XUiGridBwQuestTitle")

function XUiGridBwQuestTitle:RefreshView(typeId)
    self:Open()
    self.Bg.color = XUiHelper.Hexcolor2Color(self._Control:GetQuestTypeColorStr(typeId))
    self.TxtTitle.text = self._Control:GetQuestTypeName(typeId)
    self.ImgIcon:SetSprite(self._Control:GetQuestTypeBriefIcon(typeId))
end

local IsDebugBuild = CS.XApplication.Debug

local CsNormal = CS.UiButtonState.Normal
local CsSelect = CS.UiButtonState.Select

---@class XUiPanelBWTaskGroup : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldTaskMain
---@field _Control XBigWorldQuestControl
---@field _TypeToGridTitle table<number, XUiGridBwQuestTitle>
---@field _TypeToTabData table<number, table<number, XUiGridBWQuestGroupTab>>
local XUiPanelBWTaskGroup = XClass(XUiNode, "XUiPanelBWTaskGroup")

function XUiPanelBWTaskGroup:OnStart(typeId)
    self._TypeId = typeId
    self:InitData()
    self:AddEventListener()
    self:InitView()
end

function XUiPanelBWTaskGroup:OnEnable()
    self:RefreshSelect()
end

function XUiPanelBWTaskGroup:OnDisable()
    self:CancelLastSelect()
    self:SetLastSelectData(0, 0, 0)
end

function XUiPanelBWTaskGroup:OnDestroy()
    self:RemoveEventListener()
end

function XUiPanelBWTaskGroup:AddEventListener()
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_RED_POINT_REFRESH, self.RefreshRedPoint, self)
end

function XUiPanelBWTaskGroup:RemoveEventListener()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_RED_POINT_REFRESH, self.RefreshRedPoint, self)
end

function XUiPanelBWTaskGroup:InitData()
    self._TypeToTabData = {}
    self._TypeToGridTitle = {}
    self._LastSelectData = {
        TypeId = 0,
        GroupId = 0,
        questId = 0,
        IsValid = false
    }
    self.PanelTitle.gameObject:SetActiveEx(false)
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
end

function XUiPanelBWTaskGroup:InitView()
    self._AllReceiveQuestIds = self._Control:GetReceiveQuestIds()
    local isAll = self._TypeId == XMVCA.XBigWorldQuest.QuestType.All
    if isAll then
        self:InitMultiTaskGroup()
    else
        self:InitTaskGroup(self._TypeId)
    end
    self._IsAllType = isAll
end

function XUiPanelBWTaskGroup:RefreshSelect()
    --记录上次点击的
    local questId = self.Parent:GetSelectData(self._TypeId)
    local result
    if not questId or questId <= 0 then
        questId = XMVCA.XBigWorldQuest:GetTrackQuestId()
    end
    if questId and questId > 0 then
        local questData = XMVCA.XBigWorldQuest:GetQuestData(questId)
        if questData:IsInProgress() then
            result = self:TryClickSecondButton(questId)
        end
    end
    if result then
        return
    end
    --再没有则用第一个
    questId = self:GetFirstQuestId()
    if not questId or questId <= 0 then
        -- 刷新空
        self.Parent:RefreshTaskContent(self._TypeId, 0, 0)
        return
    end
    result = self:TryClickSecondButton(questId)
    if result then
        return
    end
    -- 刷新空
    self.Parent:RefreshTaskContent(self._TypeId, 0, 0)
end

function XUiPanelBWTaskGroup:RefreshButton()
    for _, typeData in pairs(self._TypeToTabData) do
        for _, groupData in pairs(typeData) do
            local childData = groupData.ChildData
            if not XTool.IsTableEmpty(childData) then
                for questId, questData in pairs(childData) do
                    questData.Component:SetVisibleWithGroup(1, XMVCA.XBigWorldQuest:IsTrackQuest(questId))
                end
            end
        end
    end
end

function XUiPanelBWTaskGroup:RefreshRedPoint()
    for _, typeDict in pairs(self._TypeToTabData) do
        for groupId, groupData in pairs(typeDict) do
            groupData.Button:ShowReddot(self:CheckGroupRedPoint(groupId))
            if not XTool.IsTableEmpty(groupData.ChildData) then
                for questId, questData in pairs(groupData.ChildData) do
                    questData.Button:ShowReddot(self:CheckQuestRedPoint(questId))
                end
            end
        end
    end
end

function XUiPanelBWTaskGroup:CheckGroupRedPoint(groupId)
    for _, questId in pairs(self._AllReceiveQuestIds) do
        local gId = self._Control:GetGroupIdByQuestId(questId)
        if groupId == gId and XMVCA.XBigWorldQuest:CheckQuestRedWithQuestId(questId) then
            return true
        end
    end
    return false
end

function XUiPanelBWTaskGroup:CheckQuestRedPoint(questId)
    return XMVCA.XBigWorldQuest:CheckQuestRedWithQuestId(questId)
end

function XUiPanelBWTaskGroup:InitTaskGroup(typeId)
    local groupIds = self._Control:GetGroupIdsByTypeId(typeId)
    ---@type XUiGridBwQuestTitle
    local gridTitle
    for _, groupId in pairs(groupIds) do
        --获取当前类型下，已经领取的任务
        local questIds = self._Control:GetQuestIdsByGroupId(groupId, self._AllReceiveQuestIds)
        if XTool.IsTableEmpty(questIds) then
            goto continue
        end
        --刷新标题
        gridTitle = self:GetOrCreateGridTitle(typeId)
        gridTitle:RefreshView(typeId)
        self:CreateAndRefreshFirstBtn(typeId, groupId)

        --创建具体的任务类型
        for _, questId in pairs(questIds) do
            self:CreateAndRefreshSecondBtn(typeId, groupId, questId)
        end
        ::continue::
    end
end

function XUiPanelBWTaskGroup:InitMultiTaskGroup()
    local typeIds = self._Control:GetQuestTypeIds()
    for _, typeId in pairs(typeIds) do
        self:InitTaskGroup(typeId)
    end
end

---@return XUiGridBwQuestTitle
function XUiPanelBWTaskGroup:GetOrCreateGridTitle(typeId)
    local grid = self._TypeToGridTitle[typeId]
    if not grid then
        local ui = XUiHelper.Instantiate(self.PanelTitle, self.Transform)
        if IsDebugBuild then
            ui.gameObject.name = "Title_" .. typeId
        end
        grid = XUiGridBwQuestTitle.New(ui, self)
        self._TypeToGridTitle[typeId] = grid
    end
    return grid
end

---@return XUiComponent.XUiButton
function XUiPanelBWTaskGroup:CreateAndRefreshFirstBtn(typeId, groupId)
    local typeData = self._TypeToTabData[typeId]
    if not typeData then
        typeData = {}
        self._TypeToTabData[typeId] = typeData
    end
    local groupData = typeData[groupId]
    ---@type XUiComponent.XUiButton
    local btn
    ---@type XUiComponent.XUiComponentGroup
    local component
    if not groupData then
        groupData = {
            Button = false,
            Component = false
        }
        typeData[groupId] = groupData
        btn = XUiHelper.Instantiate(self.BtnFirst, self.Transform)
        component = btn.gameObject:GetComponent(typeof(CS.XUiComponent.XUiComponentGroup))
        if not component then
            component = btn.gameObject:AddComponent(typeof(CS.XUiComponent.XUiComponentGroup))
        end
        groupData.Button = btn
        groupData.Component = component
        btn:AddEventListener(function() 
            self:OnClickFirstOrSecondBtn(typeId, groupId, 0)
        end)
    else
        btn = groupData.Button
        component = groupData.Component
    end
    btn.gameObject:SetActiveEx(true)
    btn:SetNameByGroup(0, self._Control:GetGroupName(groupId))
    btn:ShowReddot(self:CheckGroupRedPoint(groupId))
    --策划需要全部展开
    btn.IsFold = true
    btn:SetButtonState(CsSelect)
    local icon = self._Control:GetGroupIcon(groupId)
    local valid = not string.IsNilOrEmpty(icon)
    component:SetVisibleWithGroup(0, valid)
    if valid then
        component:SetRawImageWithGroup(0, icon)
    end
    return btn
end

---@return XUiComponent.XUiButton
function XUiPanelBWTaskGroup:CreateAndRefreshSecondBtn(typeId, groupId, questId)
    local typeData = self._TypeToTabData[typeId]
    if not typeData then
        XLog.Error("未创建Type数据，无法创建Quest！！！", typeId, groupId, questId)
        return
    end
    local groupData = typeData[groupId]
    if not groupData then
        XLog.Error("未创建QuestGroup数据，无法创建Quest！！！", typeId, groupId, questId)
        return
    end
    local childData = groupData.ChildData
    if not childData then
        childData = {}
        groupData.ChildData = childData
    end
    
    local questData = childData[questId]

    ---@type XUiComponent.XUiButton
    local btn
    ---@type XUiComponent.XUiComponentGroup
    local component

    if not questData then
        questData = {
            Button = false,
            Component = false
        }
        childData[questId] = questData
        btn = XUiHelper.Instantiate(self.BtnSecond, self.Transform)
        component = btn.gameObject:GetComponent(typeof(CS.XUiComponent.XUiComponentGroup))
        if not component then
            component = btn.gameObject:AddComponent(typeof(CS.XUiComponent.XUiComponentGroup))
        end
        questData.Button = btn
        questData.Component = component
        btn:AddEventListener(function()
            self:OnClickFirstOrSecondBtn(typeId, groupId, questId)
        end)
    else
        btn = questData.Button
        component = questData.Component
    end
    btn.gameObject:SetActiveEx(true)
    btn:SetNameByGroup(0, self._Control:GetQuestName(questId))
    btn:SetSprite(self._Control:GetQuestTypeIcon(self._Control:GetQuestType(questId)))
    btn:ShowReddot(self:CheckQuestRedPoint(questId))
    component:SetVisibleWithGroup(1, XMVCA.XBigWorldQuest:IsTrackQuest(questId))
    local step = XMVCA.XBigWorldQuest:GetQuestData(questId):GetActiveStepData()
    local location
    if step then
        location = self._Control:GetStepLocation(step:GetId())
    end
    if string.IsNilOrEmpty(location) then
        component:SetVisibleWithGroup(0, false)
    else
        btn:SetNameByGroup(1, location)
        component:SetVisibleWithGroup(0, true)
    end
    return btn
end

function XUiPanelBWTaskGroup:TryClickSecondButton(questId)
    if not questId or questId <= 0 then
        return false
    end
    local typeId = self._Control:GetQuestType(questId)
    local typeData = self._TypeToTabData[typeId]
    if not typeData then
        return false
    end
    local groupId = self._Control:GetGroupIdByQuestId(questId)
    local groupData = typeData[groupId]
    if not groupData then
        return false
    end
    local childData = groupData.ChildData
    if XTool.IsTableEmpty(childData) then
        return false
    end
    self:OnClickFirstOrSecondBtn(typeId, groupId, questId)
    return true
end

function XUiPanelBWTaskGroup:OnClickFirstOrSecondBtn(typeId, groupId, questId)
    local typeData = self._TypeToTabData[typeId]
    if not typeData then
        return
    end
    local groupData = typeData[groupId]
    if not groupData then
        return
    end
    if questId <= 0 then --点击的是任务组
        self:DoClickFirstButton(typeId, groupId, questId)
    else
        self:DoClickSecondButton(typeId, groupId, questId)
    end
end

function XUiPanelBWTaskGroup:DoClickFirstButton(typeId, groupId, questId)
    local groupData = self._TypeToTabData[typeId][groupId]
    local btn = groupData.Button
    local isFold = not btn.IsFold
    btn.IsFold = isFold
    local childData = groupData.ChildData
    if childData then
        local isSelectFirst = false
        for qId, tabData in pairs(childData) do
            if isFold then
                tabData.Button.gameObject:SetActiveEx(true)
                if not isSelectFirst then
                    self:OnClickFirstOrSecondBtn(typeId, groupId, qId)
                    isSelectFirst = true
                end
            else
                tabData.Button.gameObject:SetActiveEx(false)
                tabData.Button:SetButtonState(CsNormal)
            end
        end
    end
    btn:SetButtonState(isFold and CsSelect or CsNormal)
end

function XUiPanelBWTaskGroup:DoClickSecondButton(typeId, groupId, questId)
    local groupData = self._TypeToTabData[typeId][groupId]
    local lastSelect = self:GetLastSelectData()
    local childData = groupData.ChildData[questId]
    if not childData then
        return
    end
    --选中当前
    local btn = childData.Button
    --重复点击
    if lastSelect.TypeId == typeId and lastSelect.GroupId == groupId and lastSelect.QuestId == questId then
        btn:SetButtonState(CsSelect)
        return
    end
    --取消上次选中
    self:CancelLastSelect()
    btn:SetButtonState(CsSelect)
    self.Parent:SetSelectData(self._TypeId, questId)
    self:SetLastSelectData(typeId, groupId, questId)
    --播放动画
    self.Parent:PlayAnimation("ContentQieHuan")
    --刷新右边
    self.Parent:RefreshTaskContent(typeId, groupId, questId)
    --标记已经被点击过
    XMVCA.XBigWorldQuest:MarkQuestRedPoint(questId)
    --刷新红点
    self:RefreshRedPoint()
end

function XUiPanelBWTaskGroup:GetLastSelectData()
    return self._LastSelectData
end

function XUiPanelBWTaskGroup:SetLastSelectData(typeId, groupId, questId)
    self._LastSelectData.TypeId = typeId
    self._LastSelectData.GroupId = groupId
    self._LastSelectData.QuestId = questId
    self._LastSelectData.IsValid = typeId > 0 and groupId > 0 and questId > 0
end

function XUiPanelBWTaskGroup:CancelLastSelect()
    local lastSelect = self:GetLastSelectData()
    if not lastSelect.IsValid then
        return
    end
    local typeData = self._TypeToTabData[lastSelect.TypeId]
    if not typeData then
        return
    end
    local groupData = typeData[lastSelect.GroupId]
    if not groupData then
        return
    end
    local childData = groupData.ChildData
    if not childData or lastSelect.QuestId <= 0 then
        return
    end
    local btn = childData[lastSelect.QuestId].Button
    btn:SetButtonState(CsNormal)
end

function XUiPanelBWTaskGroup:GetFirstQuestId()
    if self._IsAllType then
        local typeIds = self._Control:GetQuestTypeIds()
        for _, typeId in pairs(typeIds) do
            local result, questId = self:TryGetFirstQuestIdByTypeId(typeId)
            if result then
                return questId
            end
        end
    else
        local result, questId = self:TryGetFirstQuestIdByTypeId(self._TypeId)
        if result then
            return questId
        end
    end
    return 0
end

function XUiPanelBWTaskGroup:TryGetFirstQuestIdByTypeId(typeId)
    local groupIds = self._Control:GetGroupIdsByTypeId(typeId)
    for _, groupId in pairs(groupIds) do
        local questIds = self._Control:GetQuestIdsByGroupId(groupId, self._AllReceiveQuestIds)
        if not XTool.IsTableEmpty(questIds) then
            return true, questIds[1]
        end
    end
    return false, 0
end

---@class XUiGridBWQuestGroupTab
---@field public Button XUiComponent.XUiButton
---@field public Component XUiComponent.XUiComponentGroup
---@field public ChildData table<number, XUiGridBWQuestGroupTab>

return XUiPanelBWTaskGroup