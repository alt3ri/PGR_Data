local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiFubenBossSingleTrial : XLuaUi
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleTrial = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleTrial")

local XUiGridBossEXSection = require("XUi/XUiFubenBossSingleTrial/XUiGridBossTrialSection")
local ACHIEVEMENT_FIGHT = 1
local FUBEN_BOSS_SINGLE_TAG = 2
-- 体验版囚笼
function XUiFubenBossSingleTrial:OnAwake()
    self:_RegisterButtonClicks()
    self:_InitDynamicTable()
    self:_InitTabGroup()
    self:_HideEffect()
end

function XUiFubenBossSingleTrial:OnStart()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiFubenBossSingleTrial:OnEnable()
    self:PlayAnimation("AnimEnable")
    self.BtnTrial:ShowReddot(XDataCenter.AchievementManager.CheckHasRewardByType(FUBEN_BOSS_SINGLE_TAG))
end

function XUiFubenBossSingleTrial:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiFubenBossSingleTrial:OnActivityEnd()
    self._Control:OnActivityEnd()
end

function XUiFubenBossSingleTrial:_HideEffect()
    local root = self.UiModelGo.transform
    local imgEffect = root:FindTransform("ImgEffectHuanren")
    local imgEffectHide = root:FindTransform("ImgEffectHuanren1")

    if imgEffect then
        imgEffect.gameObject:SetActiveEx(false)
    end
    if imgEffectHide then
        imgEffectHide.gameObject:SetActiveEx(false)
    end
end

function XUiFubenBossSingleTrial:_RegisterButtonClicks()
    self:RegisterClickEvent(self.BtnTrial, self.OnBtnTrialClick, true)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick, true)
    self:BindHelpBtn(self.BtnHelp, "BossSingle")
end

--初始化关卡入口动态列表
function XUiFubenBossSingleTrial:_InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewStage)
    self.DynamicTable:SetProxy(XUiGridBossEXSection, self)
    self.DynamicTable:SetDelegate(self)
    self.GridSectionBoss.gameObject:SetActive(false)
end

--初始化难度区域选择按钮
function XUiFubenBossSingleTrial:_InitTabGroup()
    self._BtnTabList = {
        self.BtnTog1,
        self.BtnTog2,
        self.BtnTog3,
        self.BtnTog4,
        self.BtnTogCur
    }

    -- 检查是否有配置该区域 并隐藏按钮
    for index = 1, #self._BtnTabList - 1 do
        local isHide = self._Control:CheckHasTrialGradeConfigByType(index)
        if not isHide then
            self._BtnTabList[index].gameObject:SetActive(false)
        end
    end

    -- 现有威胁页签始终打开
    self.BtnTogCur.gameObject:SetActive(true)

    --设置Togge按钮
    local defaultSelectIndex = #self._BtnTabList

    self.GroupTab:Init(self._BtnTabList, Handler(self, self.OnClickTabCallBack))
    self.GroupTab:SelectIndex(defaultSelectIndex)
end

function XUiFubenBossSingleTrial:_ShowBossDetail(bossId)
    if self.IsBestiraryMode then
        XLuaUiManager.Open("UiFubenBossSingleBestiaryDetailV4P5", bossId)
    else
        XLuaUiManager.Open("UiFubenBossSingleTrialDetailV4P5", bossId)
        -- XLuaUiManager.Open("UiFubenBossSingleTrialDetail", bossId)
    end
end

function XUiFubenBossSingleTrial:OnBtnTrialClick()
    XLuaUiManager.Open("UiAchievement", ACHIEVEMENT_FIGHT)
    XEventManager.DispatchEvent(XEventId.EVENT_ACHIEVEMENT_CHANGE_INDEX, FUBEN_BOSS_SINGLE_TAG)
end

function XUiFubenBossSingleTrial:OnClickTabCallBack(index)
    if self._CurrSelectIndex == index then
        return
    end

    if index == #self._BtnTabList then
        self:RefreshPageAsBestiary()
    else
        self:RefreshPageAsTrail(index)
    end

    self._CurrSelectIndex = index
end

-- 【不可修复的历史遗留问题，和策划、服务端协商一致提出解决方案】
-- Boss图鉴分为离群点和现有威胁两部分
-- BossSingleTrailGrade.tab中的LevelType已失去原有语义，纯粹作为表主键使用
-- 4固定为终极区难度离群点
-- 新定义5/6/7/8为分别四个难度区的现有威胁
-- 另外使用IsBestiaryCfg列来明确区分离群点和现有威胁的配置
-- 原有代码逻辑比较奇怪，停留在原LevelType=1/2/3/4的语义上，目前只有4具有严格定义的语义
-- UI逻辑凑巧可以在LevelType = 4的情况下正确运行，尽管它的逻辑实际上是错误的，但它最终的行为是符合定义的
-- 2026.3.30 许兴逸

-- 该函数提取LevelType = tableIndexLevelType（无实际语义）主键的配置以呈现到页面上
function XUiFubenBossSingleTrial:RefreshPageByTableLevelType(tableIndexLevelType)
    local currSingeExGradeConfig = self._Control:GetBossSingleTrialGradeConfigByType(tableIndexLevelType)

    if currSingeExGradeConfig.IsBestiaryCfg ~= self.IsBestiraryMode then
        XLog.Error("XUiFubenBossSingleTrial:RefreshPageByTableLevelType currSingeExGradeConfig is not match IsBestiraryMode")
        return
    end

    local currSectionConfig = currSingeExGradeConfig.SectionId
    self._CurrSelectAreaSectionData = {}
    -- 排序
    -- 这里是不光要根据Order值排序，还要根据AchievementTasks完成度完成排序
    for i = 1, #currSectionConfig do
        local sectionConf = self._Control:GetBossSectionConfigByBossId(
            currSectionConfig[i])

        local order = currSingeExGradeConfig.Order[i]
        local achievementTasks = sectionConf.AchievementTasks

        if #achievementTasks > 0 then
            local finishedTasks = 0

            for _, achievementTask in pairs(achievementTasks) do
                if XDataCenter.TaskManager.IsTaskFinished(achievementTask) then
                    finishedTasks = finishedTasks + 1
                end
            end

            local achievementTaskProgress = (tonumber(finishedTasks) / tonumber(#achievementTasks))
            order = order + achievementTaskProgress * 1000.0
        end

        table.insert(self._CurrSelectAreaSectionData,
            { SectionId = currSectionConfig[i] , Order = order })
    end

    table.sort(self._CurrSelectAreaSectionData, function(a, b)
        return a.Order < b.Order
    end)

    -- 刷新列表
    self.DynamicTable:SetDataSource(self._CurrSelectAreaSectionData)
    self.DynamicTable:ReloadDataSync()
end

-- 刷新页面为离群点
function XUiFubenBossSingleTrial:RefreshPageAsTrail(index)
    self.IsBestiraryMode = false

    if index ~= 4 then
        self.DynamicTable:SetDataSource({})
        self.DynamicTable:ReloadDataSync()
        XLog.Error("XUiFubenBossSingleTrial:RefreshPageAsTrail index is not 4, that's invalid argument.")
        return
    end

    self:RefreshPageByTableLevelType(index)
end

-- 刷新页面为现有威胁
function XUiFubenBossSingleTrial:RefreshPageAsBestiary()
    self.IsBestiraryMode = true

    local bossSingleData = self._Control:GetBossSingleData()
    local levelType = bossSingleData:GetBossSingleLevelType()
    self:RefreshPageByTableLevelType(levelType)
end

--动态列表事件
function XUiFubenBossSingleTrial:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local sectionId = self._CurrSelectAreaSectionData[index].SectionId
        grid:Refresh(sectionId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local sectionId = self._CurrSelectAreaSectionData[index].SectionId
        self:_ShowBossDetail(sectionId)
    end
end

function XUiFubenBossSingleTrial:OnBtnBackClick()
    self:Close()
end

function XUiFubenBossSingleTrial:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiFubenBossSingleTrial
