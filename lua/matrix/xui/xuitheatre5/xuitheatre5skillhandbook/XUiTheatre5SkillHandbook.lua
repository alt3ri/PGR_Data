local XUiTheatre5SkillHandbookTabGrid = require("XUi/XUiTheatre5/XUiTheatre5SkillHandbook/XUiTheatre5SkillHandbookTabGrid")
local XUiTheatre5SkillHandbookTag = require("XUi/XUiTheatre5/XUiTheatre5SkillHandbook/XUiTheatre5SkillHandbookTag")
local XUiGridTheatre5Item = require("XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Item")
local XUiGridTheatre5MissionInBook = require('XUi/XUiTheatre5/XUiTheatre5SkillHandbook/XUiGridTheatre5MissionInBook')

local Tab = {
    Skill = 1,
    Rune = 2,
    Relic = 3,
    Mission = 4,
}

---@class XUiTheatre5SkillHandbook : XLuaUi
---@field _Control XTheatre5Control
local XUiTheatre5SkillHandbook = XLuaUiManager.Register(XLuaUi, "UiTheatre5SkillHandbook")

function XUiTheatre5SkillHandbook:OnAwake()
    ---@type XUiTheatre5SkillHandbookTabGrid[]
    self._Tabs = {}
    ---@type XUiTheatre5SkillHandbookTag[]
    self._Tags = { XUiTheatre5SkillHandbookTag.New(self.GridTag, self) }
    self:BindExitBtns()

    self._TimerDelayInit = false
    self._LastCheckVisibleTime = 0
    self._CheckVisibleInterval = 0.1 -- 0.1秒间隔

    ---@type UnityEngine.UI.ScrollRect
    self.PanelItemList = self.PanelItemList or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelItemList", "ScrollRect")
    self.PanelItemList.onValueChanged:AddListener(function()
        self:CheckGridVisible()
    end)

    self._Index = 0

    ---@type XUiGridTheatre5Item
    self._GridGem = XUiGridTheatre5Item.New(self.UiTheatre5GridGem, self)
    self._GridGem:SetHideTag(true)
    ---@type XUiGridTheatre5Item
    self._GridSkill = XUiGridTheatre5Item.New(self.UiTheatre5GridSkill, self)
    self._GridSkill:SetHideTag(true)
    ---@type XUiGridTheatre5Item
    self._GridRelic = XUiGridTheatre5Item.New(self.UiTheatre5GridRelic, self)
    self._GridRelic:SetHideTag(true)
    ---@type XUiGridTheatre5MissionInBook
    self._GridMission = XUiGridTheatre5MissionInBook.New(self.UiTheatre5GridMission, self)
    self._GridMission:SetHideTag(true)
end

function XUiTheatre5SkillHandbook:OnStart()
    self.PanelBtnTab:Init({
        self.BtnTab1,
        self.BtnTab2,
        self.BtnTab3,
        self.BtnTab4,
    }, function(index)
        if self._TimerDelaySelectTab then
            XScheduleManager.UnSchedule(self._TimerDelaySelectTab)
            self._TimerDelaySelectTab = nil
        end
        self:OnSelectTab(index)
    end)

    -- 延迟一秒播放, 让玩家看到动画
    self._TimerDelaySelectTab = XScheduleManager.ScheduleOnce(function()
        self._TimerDelaySelectTab = nil
        self.PanelBtnTab:SelectIndex(1)
    end, 500)
end

function XUiTheatre5SkillHandbook:OnEnable()
    self:Update()
end

function XUiTheatre5SkillHandbook:OnDisable()
end

function XUiTheatre5SkillHandbook:OnDestroy()
    if self._TimerDelayInit then
        XScheduleManager.UnSchedule(self._TimerDelayInit)
        self:_RemoveTimerIdAndDoCallback(self._TimerDelayInit)
        self._TimerDelayInit = nil
    end
    if self._TimerDelaySelectTab then
        XScheduleManager.UnSchedule(self._TimerDelaySelectTab)
        self._TimerDelaySelectTab = nil
    end
    -- 重置检查可见性的时间记录
    self._LastCheckVisibleTime = 0
end

function XUiTheatre5SkillHandbook:Update()
end

function XUiTheatre5SkillHandbook:OnSelectTab(index)
    if index == self._Index then
        return
    end

    -- 第一次不播放切换动画，相同的index不播放切换动画
    if self._Index > 0 then
        self:PlayAnimation("QieHuan")
    end
    self._Index = index

    -- 切换页签后，滚到0的位置
    self.PanelItemList.verticalNormalizedPosition = 1

    -- 根据索引确定类型和数据
    local type
    if index == Tab.Skill then
        type = XMVCA.XTheatre5.EnumConst.ItemType.Skill
    elseif index == Tab.Rune then
        type = XMVCA.XTheatre5.EnumConst.ItemType.Equip
    elseif index == Tab.Relic then
        type = XMVCA.XTheatre5.EnumConst.ItemType.Relic
    elseif index == Tab.Mission then
        type = XMVCA.XTheatre5.EnumConst.ItemType.Mission  
    else
        XLog.Error("[XUiTheatre5SkillHandbook] invalid tab index: " .. tostring(index))
        return
    end

    local datas = self._Control:GetDataHandBook(type)

    -- 前面12格播放动画
    local firstPage = datas[1]
    ---@type XUiTheatre5SkillHandbookItemGridData[]
    local items = firstPage.Items
    for i = 1, 12 do
        local item = items[i]
        if item then
            item.PlayAnimation = true
        end
    end

    XTool.UpdateDynamicItemLazy(self._Tabs, datas, self.Panel, XUiTheatre5SkillHandbookTabGrid, self, 1, 24)
    self:CheckGridVisible(true)

    -- 默认选中第一个
    if datas and #datas > 0 and datas[1].Items and #datas[1].Items > 0 then
        self:OnSelectItem(datas[1].Items[1])
    else
        XLog.Error("[XUiTheatre5SkillHandbook] default select fail")
    end
end

---@param data XUiTheatre5SkillHandbookItemGridData
function XUiTheatre5SkillHandbook:OnSelectItem(data)
    -- 先关闭所有面板
    self._GridSkill:Close()
    self._GridGem:Close()
    self._GridRelic:Close()
    self._GridMission:Close()

    if self.PanelConsume then
        self.PanelConsume.gameObject:SetActiveEx(false)
    end

    -- 根据索引打开对应面板并刷新显示
    local showStoryParent = false
    if self._Index == Tab.Skill then
        self._GridSkill:Open()
        self._GridSkill:RefreshShow(data)
        showStoryParent = false
    elseif self._Index == Tab.Rune then
        self._GridGem:Open()
        self._GridGem:RefreshShow(data)
        --"相同效果，仅最高稀有度生效" 只在符文页签提示
        showStoryParent = true
    elseif self._Index == Tab.Relic then
        self._GridRelic:Open()
        self._GridRelic:RefreshShow(data)
        showStoryParent = false
    elseif self._Index == Tab.Mission then
        self._GridMission:Open()
        self._GridMission:RefreshShow(data)
        showStoryParent = false
    end

    self.TxtStory.transform.parent.gameObject:SetActiveEx(showStoryParent)

    --if self.TxtStory then
    --    self.TxtStory.text = data.Desc
    --end
    if self.TxtDes then
        if self._Index == Tab.Mission then
            if data.IsUnlock then
                self.TxtDes.text = self._Control.MissionControl:GetMissionRewardDesc(data.Bounty)
            else
                self.TxtDes.text = self._Control.MissionControl:GetClientConfigMissonIsLockInBook()
            end
        else
            local config = XMVCA.XTheatre5:GetTheatre5ItemCfgById(data.Id)
            self.TxtDes.text = self._Control:GetItemDesc(config)
        end
        
    end
    --self.RImgIcon:SetRawImage(data.Icon)
    self.TxtTitle.text = data.Name
    --if data.Quality == 0 then
    --    self.ImgQuality.gameObject:SetActiveEx(false)
    --else
    --    self.ImgQuality.gameObject:SetAxctiveEx(true)
    --    XUiHelper.SetQualityIcon(self, self.ImgQuality, data.Quality)
    --end

    -- tag
    if self._Index == Tab.Mission then
        XTool.UpdateDynamicItem(self._Tags, nil, self.GridTag, XUiTheatre5SkillHandbookTag, self)
        self.ListItemTag.gameObject:SetActiveEx(false)

        if data.IsUnlock then
            if self.PanelConsume then
                self.PanelConsume.gameObject:SetActiveEx(true)
            end

            if self.TxtConsume then
                self.TxtConsume.text = self._Control.MissionControl:GetMissionLevelUpCostDesc(data.Bounty)
            end
        end
        
    else
        self.ListItemTag.gameObject:SetActiveEx(true)
        XTool.UpdateDynamicItem(self._Tags, data.Tags, self.GridTag, XUiTheatre5SkillHandbookTag, self)
    end

    for i, tags in pairs(self._Tabs) do
        tags:UpdateSelectState(data)
    end
end

-- 检测格子是否可见, 把不可见的格子隐藏, 因为会卡顿
function XUiTheatre5SkillHandbook:CheckGridVisible(force)
    -- 添加更新间隔，避免过于频繁的检查
    local currentTime = CS.UnityEngine.Time.time
    if force or (currentTime - self._LastCheckVisibleTime < self._CheckVisibleInterval) then
        return
    end
    self._LastCheckVisibleTime = currentTime

    local viewport = self.PanelItemList.viewport
    local content = self.PanelItemList.content

    -- 获取viewport在content坐标系中的矩形范围
    ---@type System.Array
    local Array = CS.System.Array
    local worldCorners = Array.CreateInstance(typeof(CS.UnityEngine.Vector3), 4)
    viewport:GetWorldCorners(worldCorners)
    local viewportRectMin = content:InverseTransformPoint(worldCorners[0])
    local viewportRectMax = content:InverseTransformPoint(worldCorners[2])

    -- 增加一个格子高度的范围，防止格子在边界处完全消失
    local gridHeightBuffer = 0
    if #self._Tabs > 0 and self._Tabs[1]:IsNodeShow() then
        local grids = self._Tabs[1]:GetGrids()
        if #grids > 0 and grids[1].Transform then
            gridHeightBuffer = grids[1].Transform.rect.height
        end
    end

    for i = 1, #self._Tabs do
        local tab = self._Tabs[i]
        if tab:IsNodeShow() then
            local grids = tab:GetGrids()
            for j = 1, #grids do
                ---@type XUiTheatre5SkillHandbookItemGrid
                local grid = grids[j]
                if grid:IsNodeShow() then
                    local transform = grid.Transform

                    -- 将grid的位置转换为content坐标系中的位置
                    local gridWorldPos = transform:TransformPoint(CS.UnityEngine.Vector3.zero)
                    local gridLocalPos = content:InverseTransformPoint(gridWorldPos)

                    -- 检查grid是否在viewport可见区域内（增加缓冲区）
                    local isVisible = gridLocalPos.y >= viewportRectMin.y - gridHeightBuffer and
                            gridLocalPos.y <= viewportRectMax.y + gridHeightBuffer

                    grid:SetVisibleInScrollView(isVisible)
                end
            end
        end
    end
end

return XUiTheatre5SkillHandbook