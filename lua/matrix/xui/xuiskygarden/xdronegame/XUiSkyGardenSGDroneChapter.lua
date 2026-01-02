local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")
local XUiBWPanelAsset = require("XUi/XUiBigWorld/XCommon/XPanelAsset/XUiBWPanelAsset")

---@class XUiSkyGardenSGDroneChapter : XBigWorldUi
---@field PanelSpecialTool UnityEngine.RectTransform
---@field BtnStore XUiComponent.XUiButtonExt
---@field BtnBack XUiComponent.XUiButtonExt
---@field BtnMainUi XUiComponent.XUiButtonExt
---@field BtnHelp XUiComponent.XUiButtonExt
---@field PanelChapter UnityEngine.RectTransform
---@field BtnChapterNormal XUiComponent.XUiButtonExt
---@field BtnChapterDifficult XUiComponent.XUiButtonExt
---@field ListPreviewReward UnityEngine.RectTransform
---@field RewardGrid UnityEngine.RectTransform
---@field ScrollRect UnityEngine.RectTransform
---@field PointLocation1 UnityEngine.RectTransform
---@field PointLocation2 UnityEngine.RectTransform
---@field PointLocation3 UnityEngine.RectTransform
---@field PointLocation4 UnityEngine.RectTransform
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenSGDroneChapter = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenSGDroneChapter")

function XUiSkyGardenSGDroneChapter:OnAwake()
    ---@type XSGDroneChapterEntity[]
    self._Chapters = self._Control:GetChapterEntities()

    ---@type XUiGridBWItem[]
    self._RewardGrids = {}

    ---@type XUiBWPanelAsset
    self._PanelAsset = XUiBWPanelAsset.New(self.PanelSpecialTool, self, self._Control:GetShopItemIds())
    self._PanelAsset:Open()

    self._ChapterButtons = {}

    self:_InitUi()
    self:_InitChapters()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDroneChapter:OnStart()
end

function XUiSkyGardenSGDroneChapter:OnEnable()
    self._Control:SendSwitchChapterSelectViewCmd()
    self:_RefreshChapter()
    self:_RefreshShopRewards()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneChapter:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneChapter:OnDestroy()
end

function XUiSkyGardenSGDroneChapter:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnBack:AddEventListener(Handler(self, self.OnBtnBackClick))
    self.BtnStore:AddEventListener(Handler(self, self.OnBtnStoreClick))
end

function XUiSkyGardenSGDroneChapter:OnBtnStoreClick()
    self._Control:OpenShopUi()
end

function XUiSkyGardenSGDroneChapter:OnBtnBackClick()
    self:Close()
end

function XUiSkyGardenSGDroneChapter:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDroneChapter:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDroneChapter:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneChapter:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDroneChapter:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenSGDroneChapter:_InitUi()
    self.RewardGrid.gameObject:SetActiveEx(false)
    self.BtnChapterNormal.gameObject:SetActiveEx(false)
    self.BtnChapterDifficult.gameObject:SetActiveEx(false)
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.BtnStore:ShowReddot(false)
end

function XUiSkyGardenSGDroneChapter:_InitChapters()
    for index, chapter in pairs(self._Chapters) do
        local pointLocation = self["PointLocation" .. tostring(index)]
        local button = false

        if chapter:GetType() == XMVCA.XSkyGardenDroneGame.ChapterType.Normal then
            button = XUiHelper.Instantiate(self.BtnChapterNormal, self.PanelChapter)

            button.gameObject:SetActiveEx(true)
            self._ChapterButtons[index] = button
        elseif chapter:GetType() == XMVCA.XSkyGardenDroneGame.ChapterType.Difficult then
            button = XUiHelper.Instantiate(self.BtnChapterDifficult, self.PanelChapter)
            
            button.gameObject:SetActiveEx(true)
            self._ChapterButtons[index] = button
        end

        if pointLocation then
            button.transform:SetParent(pointLocation)
            button.transform:Reset()
        end
    end
end

function XUiSkyGardenSGDroneChapter:_RefreshChapter()
    for index, button in pairs(self._ChapterButtons) do
        local chapter = self._Chapters[index]

        if chapter then
            button:SetNameByGroup(0, chapter:GetName())
            button:SetNameByGroup(1, chapter:GetStarProgressText())
            button:ShowTag(chapter:IsComplete())
            button:ShowReddot(chapter:IsNew())
            button:SetSprite(chapter:GetIcon())

            if not chapter:IsUnlock() then
                button:SetDisable(true, false)
            else
                button:SetDisable(false)
            end

            button.CallBack = function()
                XMVCA.XBigWorldUI:Open("UiSkyGardenSGDroneStage", chapter)
            end
        end
    end
end

function XUiSkyGardenSGDroneChapter:_RefreshShopRewards()
    local goodId = self._Control:GetShopRewardGoodId()
    
    if XTool.IsNumberValid(goodId) then
        local rewardGoods = XMVCA.XBigWorldGamePlay:GetBigWorldGoodsByGroupId(goodId)

        if not XTool.IsTableEmpty(rewardGoods) then
            local index = 1
            
            self.ScrollRect.gameObject:SetActiveEx(true)
            for _, rewardGood in pairs(rewardGoods) do
                local grid = self._RewardGrids[index]

                if not grid then
                    local gridUi = XUiHelper.Instantiate(self.RewardGrid, self.ListPreviewReward)

                    grid = XUiGridBWItem.New(gridUi, self)
                    self._RewardGrids[index] = grid
                end

                grid:Open()
                grid:Refresh(rewardGood)

                index = index + 1
            end

            for i = index, #self._RewardGrids do
                self._RewardGrids[i]:Close()
            end

            return
        end
    end

    for _, grid in pairs(self._RewardGrids) do
        grid:Close()
    end

    self.ScrollRect.gameObject:SetActiveEx(false)
end

return XUiSkyGardenSGDroneChapter
