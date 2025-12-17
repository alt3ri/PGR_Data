local XUiPlotExhibitionDetailCharacterGrid = require("XUi/XUiPlotExhibition/XUiPlotExhibitionDetailCharacterGrid")
local XUiPlotExhibitionDetailStoryGrid = require("XUi/XUiPlotExhibition/XUiPlotExhibitionDetailStoryGrid")

---@class XUiPlotExhibitionDetail : XLuaUi
---@field _Control XPlotExhibitionControl
local XUiPlotExhibitionDetail = XLuaUiManager.Register(XLuaUi, "UiPlotExhibitionDetail")

function XUiPlotExhibitionDetail:OnAwake()
    self._IsScrolling = false
    self._TimerNextSetScrollingFalse = false

    self.GridMember.gameObject:SetActiveEx(false)
    self.GridChapter.gameObject:SetActiveEx(false)
    self:BindExitBtns()
    ---@type XUiPlotExhibitionDetailStoryGrid[]
    self._GridStory = {}

    ---@type XDynamicTableNormal
    self.DynamicTableNormal = XUiHelper.DynamicTableNormal(self, self.ListMember, XUiPlotExhibitionDetailCharacterGrid)

    ---@type UnityEngine.UI.ScrollRect
    local listChapter = self.ListChapter
    local gridHeight = self.GridChapter.rect.height
    local autoLayoutGroup = listChapter.content:GetComponent("XAutoLayoutGroup")
    local spacing = 0
    if autoLayoutGroup then
        spacing = autoLayoutGroup.Spacing.y
    else
        spacing = 36
        XLog.Error("[XUiPlotExhibitionDetail] 根据剧情滚动选中角色可能出错。ui结构发生了改变？找不到XAutoLayoutGroup")
    end
    gridHeight = gridHeight + spacing

    listChapter.onValueChanged:AddListener(function()
        if self._IsScrolling then
            return
        end
        local y = listChapter.content.transform.anchoredPosition.y
        local index = math.ceil(y / gridHeight - 0.5) + 1
        local storyList = self._Control:GetUiData().StoryDetail.StoryList
        index = XMath.Clamp(index, 1, #storyList)
        ---@type XPlotExhibitionControlStory
        local data = storyList[index]
        if data then
            local characterId = data.CharacterId
            ---@type XPlotExhibitionControlCharacter[]
            local characterDatas = self.DynamicTableNormal.DataSource
            for i = 1, #characterDatas do
                if characterDatas[i].Id == characterId then
                    self:SetCharacterSelected(i)
                    break
                end
            end
        end
    end)
end

function XUiPlotExhibitionDetail:OnDestroy()
    if self._TimerNextSetScrollingFalse then
        XScheduleManager.UnSchedule(self._TimerNextSetScrollingFalse)
        self._TimerNextSetScrollingFalse = false
    end
end

function XUiPlotExhibitionDetail:OnStart(characterId)
    -- 从角色详情直接打开剧情线界面
    if characterId then
        local roleId = self._Control:GetRoleIdByCharacterId(characterId)
        local role = self._Control:GetRole(roleId)
        self._Control:SetRole4UiDetail(role)
    end
end

function XUiPlotExhibitionDetail:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_PLOT_EXHIBITION_UPDATE_DETAIL, self.Update, self)
end

function XUiPlotExhibitionDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLOT_EXHIBITION_UPDATE_DETAIL, self.Update, self)
end

function XUiPlotExhibitionDetail:Update(characterId)
    self._Control:UpdateDetail(true)
    local data = self._Control:GetUiData().Detail
    local characterList = data.CharacterList
    self.DynamicTableNormal:SetDataSource(characterList)
    if characterId then
        local scrollTo = self:GetScrollToIndex(characterId)
        self.DynamicTableNormal:ReloadDataSync(scrollTo)
    else
        self.DynamicTableNormal:ReloadDataSync()
    end
    self.TxtTitle01.text = data.Name
    self:UpdateStory()
end

---@param grid XUiPlotExhibitionDetailCharacterGrid
function XUiPlotExhibitionDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTableNormal:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        --self._Control:OpenUiDetail(self.DynamicTableNormal:GetData(index))
        ---@type XPlotExhibitionControlCharacter
        local data = self.DynamicTableNormal:GetData(index)
        self:ScrollToCharacterId(data.Id)

        ---@type XUiPlotExhibitionDetailCharacterGrid[]
        local girds = self.DynamicTableNormal:GetGrids()
        for i, otherGrid in pairs(girds) do
            if index ~= i then
                otherGrid:Deselected()
            end
        end
    end
end

function XUiPlotExhibitionDetail:SetCharacterSelected(index)
    ---@type XUiPlotExhibitionDetailCharacterGrid[]
    local girds = self.DynamicTableNormal:GetGrids()
    for i, grid in pairs(girds) do
        if index == i then
            grid:Select()
        else
            grid:Deselected()
        end
    end
end

function XUiPlotExhibitionDetail:GetScrollToIndex(characterId)
    local storyList = self._Control:GetUiData().StoryDetail.StoryList
    local scrollTo
    for i = 1, #storyList do
        local story = storyList[i]
        if story.CharacterId == characterId then
            scrollTo = i
            break
        end
    end
    return scrollTo
end

function XUiPlotExhibitionDetail:ScrollToCharacterId(characterId)
    local scrollTo = self:GetScrollToIndex(characterId)
    if scrollTo then
        print("[XUiPlotExhibitionDetail] 找到该角色对应的故事位置:" .. tostring(scrollTo))
        self:ScrollToStory(scrollTo)
    else
        XLog.Error("[XUiPlotExhibitionDetail] 找不到该角色对应的故事所在的位置")
    end
end

function XUiPlotExhibitionDetail:UpdateStory()
    self._Control:UpdateStoryDetail(true)
    XTool.UpdateDynamicItem(self._GridStory, self._Control:GetUiData().StoryDetail.StoryList, self.GridChapter, XUiPlotExhibitionDetailStoryGrid, self)
end

function XUiPlotExhibitionDetail:ScrollToStory(index)
    local childUi = self._GridStory[index]
    if childUi then
        local gameObject = childUi.GameObject
        ---@type UnityEngine.UI.ScrollRect
        local scrollRect = self.ListChapter
        self:ScrollTo(scrollRect, gameObject.transform, 0.3)
    else
        XLog.Error("[XUiPlotExhibitionDetail] 找不到该故事所在位置:" .. tostring(index))
    end
end

-- scrollRect滚动到child对应的位置
---@param scrollRect UnityEngine.UI.ScrollRect
---@param childTransform UnityEngine.RectTransform
---@param time number
function XUiPlotExhibitionDetail:ScrollTo(scrollRect, childTransform, time)
    if not scrollRect or not childTransform then
        return
    end

    -- 强制更新Canvas以确保布局正确
    CS.UnityEngine.Canvas.ForceUpdateCanvases()

    -- 计算content和viewport
    local content = scrollRect.content
    local viewport = scrollRect.viewport

    if not content or not viewport then
        return
    end

    -- 计算child在content中的位置
    local childWorldPos = childTransform.position
    local viewportRect = viewport:GetComponent(typeof(CS.UnityEngine.RectTransform))

    -- 计算相对位置
    local localPos = content:InverseTransformPoint(childWorldPos)
    local contentRect = content:GetComponent(typeof(CS.UnityEngine.RectTransform))

    -- 计算归一化滚动位置
    local contentHeight = math.abs(contentRect.rect.height)
    local viewportHeight = math.abs(viewportRect.rect.height)
    local targetY = localPos.y

    -- 归一化位置计算 (0 = 顶部, 1 = 底部)
    local childHeight = childTransform.sizeDelta.y
    local pivot = childTransform.pivot
    local targetPosition = 1 - (math.abs(targetY) - childHeight * pivot.y) / (contentHeight - viewportHeight)
    targetPosition = math.max(0, math.min(1, targetPosition)) -- 限制在0-1之间

    -- 如果有时间参数，则使用插值滚动
    if time and time > 0 then
        self._IsScrolling = true
        local startPosition = scrollRect.verticalNormalizedPosition
        XUiHelper.Tween(time, function(value)
            scrollRect.verticalNormalizedPosition = startPosition * (1 - value) + targetPosition * value
        end, function()
            self._TimerNextSetScrollingFalse = XScheduleManager.ScheduleNextFrame(function()
                self._IsScrolling = false
                self._TimerNextSetScrollingFalse = false
            end)
        end)
    else
        -- 直接设置位置
        scrollRect.verticalNormalizedPosition = targetPosition
    end
end

function XUiPlotExhibitionDetail:UpdateCover()
    for i = 1, #self._GridStory do
        local grid = self._GridStory[i]
        grid:UpdateCover(self._Control:GetUiData().StoryDetail.StoryList[i])
    end
end

return XUiPlotExhibitionDetail