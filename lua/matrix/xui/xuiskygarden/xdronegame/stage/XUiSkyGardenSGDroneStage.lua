local XUiBWPanelAsset = require("XUi/XUiBigWorld/XCommon/XPanelAsset/XUiBWPanelAsset")
local XUiSkyGardenDroneStageGrid = require("XUi/XUiSkyGarden/XDroneGame/Stage/XUiSkyGardenDroneStageGrid")

---@class XUiSkyGardenSGDroneStage : XBigWorldUi
---@field PanelSpecialTool UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButtonExt
---@field BtnMainUi XUiComponent.XUiButtonExt
---@field BtnHelp XUiComponent.XUiButtonExt
---@field BtnTeach XUiComponent.XUiButtonExt
---@field TxtChapterTitle UnityEngine.UI.Text
---@field StageNormalUp UnityEngine.RectTransform
---@field StageNormalDown UnityEngine.RectTransform
---@field StageSpecial UnityEngine.RectTransform
---@field StageBranchLine UnityEngine.RectTransform
---@field StageMainLine UnityEngine.RectTransform
---@field PanelChapter UnityEngine.RectTransform
---@field PanelMainLine1 UnityEngine.RectTransform
---@field PanelMainLine2 UnityEngine.RectTransform
---@field PanelMainLine3 UnityEngine.RectTransform
---@field PanelMainLine4 UnityEngine.RectTransform
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenSGDroneStage = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenSGDroneStage")

function XUiSkyGardenSGDroneStage:OnAwake()
    ---@type XSGDroneChapterEntity
    self._ChapterEntity = false

    self._IsShow = false

    ---@type table<XSGDroneStageEntity, XUiSkyGardenDroneStageGrid>
    self._StageGridMap = false
    ---@type XUiSkyGardenDroneStageGrid[]
    self._NormalStageUpGrids = {}
    ---@type XUiSkyGardenDroneStageGrid[]
    self._NormalStageDownGrids = {}
    ---@type XUiSkyGardenDroneStageGrid[]
    self._SpecialStageGrids = {}
    ---@type XUiSkyGardenDroneStageGrid[]
    self._MainLineStageGrids = {}
    ---@type XUiSkyGardenDroneStageGrid[]
    self._BranchLineStageGrids = {}

    ---@type XUiBWPanelAsset
    self._PanelAsset = XUiBWPanelAsset.New(self.PanelSpecialTool, self, self._Control:GetShopItemIds())
    self._PanelAsset:Open()

    local layout = self.PanelChapter.gameObject:GetComponent(typeof(CS.UnityEngine.UI.GridLayoutGroup))

    if layout then
        layout.enabled = true
    end

    self:_InitUi()
    self:_RegisterButtonClicks()

    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SKY_GARDEN_DRONE_GAME_STAGE_UI_REFRESH,
        self.OnRefresh, self)
end

---@param chapterEntity XSGDroneChapterEntity
function XUiSkyGardenSGDroneStage:OnStart(chapterEntity)
    self._ChapterEntity = chapterEntity

    self:_TryOpenTeachUi()
end

function XUiSkyGardenSGDroneStage:OnEnable()
    self._IsShow = true

    self._Control:SendSwitchChapterViewCmd(self._ChapterEntity:GetChapterId())
    self:_RefreshTitle()
    self:_RefreshStages()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneStage:OnDisable()
    self._IsShow = false

    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneStage:OnDestroy()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SKY_GARDEN_DRONE_GAME_STAGE_UI_REFRESH,
        self.OnRefresh, self)
end

---@param chapterEntity XSGDroneChapterEntity
function XUiSkyGardenSGDroneStage:OnRefresh(chapterEntity)
    self._ChapterEntity = chapterEntity

    if self._IsShow then
        return
    end

    self._Control:SendSwitchChapterViewCmd(self._ChapterEntity:GetChapterId())
    self:_TryOpenTeachUi()
    self:_RefreshStages()
    self:_RefreshTitle()
end

---@param chapterId number
function XUiSkyGardenSGDroneStage:OnChapterSelectViewSwitchComplete(chapterId)
    if not self._ChapterEntity or chapterId ~= self._ChapterEntity:GetChapterId() then
        return
    end

    self:_RefreshStagePosition()
end

function XUiSkyGardenSGDroneStage:OnOpenTeachUi()
    self:_OpenTeachUi()
end

function XUiSkyGardenSGDroneStage:OnBtnTeachClick()
    self:_OpenTeachUi()
end

function XUiSkyGardenSGDroneStage:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnBack:AddEventListener(Handler(self, self.Close))
    self.BtnTeach:AddEventListener(Handler(self, self.OnBtnTeachClick))
end

function XUiSkyGardenSGDroneStage:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId
                                       .EVENT_SKY_GARDEN_DRONE_CHAPTER_SELECT_VIEW_SWITCH_COMPLETE,
        self.OnChapterSelectViewSwitchComplete, self)

    XEventManager.AddEventListener("EVENT_SKYGARDEN_GUIDE_DRONEGAME_OPEN_TEACH", self.OnOpenTeachUi, self)
end

function XUiSkyGardenSGDroneStage:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId
                                       .EVENT_SKY_GARDEN_DRONE_CHAPTER_SELECT_VIEW_SWITCH_COMPLETE,
        self.OnChapterSelectViewSwitchComplete, self)

    XEventManager.RemoveEventListener("EVENT_SKYGARDEN_GUIDE_DRONEGAME_OPEN_TEACH", self.OnOpenTeachUi, self)
end

function XUiSkyGardenSGDroneStage:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneStage:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDroneStage:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenSGDroneStage:_OpenTeachUi()
    if not self._ChapterEntity then
        return
    end

    local teachDroneId = self._ChapterEntity:GetTeachDroneId()

    if XTool.IsNumberValid(teachDroneId) then
        XMVCA.XBigWorldUI:Open("UiSkyGardenSGDronePopupDetail", teachDroneId)
    end
end

function XUiSkyGardenSGDroneStage:_TryOpenTeachUi()
    if not self._ChapterEntity then
        return
    end

    if self._ChapterEntity:IsFirstUnlock() then
        self:_OpenTeachUi()
        self._ChapterEntity:RecordUnlock()
    end
end

function XUiSkyGardenSGDroneStage:_InitUi()
    self.BtnTeach:ShowReddot(false)
    self.StageNormalUp.gameObject:SetActiveEx(false)
    self.StageNormalDown.gameObject:SetActiveEx(false)
    self.StageSpecial.gameObject:SetActiveEx(false)
    self.StageBranchLine.gameObject:SetActiveEx(false)
    self.StageMainLine.gameObject:SetActiveEx(false)
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
end

function XUiSkyGardenSGDroneStage:_RefreshStages()
    if not self._ChapterEntity then
        return
    end

    local stageEntities = self._ChapterEntity:GetStageList()
    local normalStageIndex = 1
    local normalStageUpIndex = 1
    local normalStageDownIndex = 1
    local specialStageIndex = 1
    local mainLineStageIndex = 1
    local branchLineStageIndex = 1

    self._StageGridMap = {}
    for index, stageEntity in ipairs(stageEntities) do
        local grid = nil

        if stageEntity:GetType() == XMVCA.XSkyGardenDroneGame.StageType.Normal then
            if normalStageIndex % 2 == 0 then
                grid = self._NormalStageUpGrids[normalStageUpIndex]

                if not grid then
                    local gridUi = XUiHelper.Instantiate(self.StageNormalUp, self.PanelChapter)

                    ---@type XUiSkyGardenDroneStageGrid
                    grid = XUiSkyGardenDroneStageGrid.New(gridUi, self)
                    self._NormalStageUpGrids[normalStageUpIndex] = grid
                end

                normalStageUpIndex = normalStageUpIndex + 1
            else
                grid = self._NormalStageDownGrids[normalStageDownIndex]

                if not grid then
                    local gridUi = XUiHelper.Instantiate(self.StageNormalDown, self.PanelChapter)

                    ---@type XUiSkyGardenDroneStageGrid
                    grid = XUiSkyGardenDroneStageGrid.New(gridUi, self)
                    self._NormalStageDownGrids[normalStageDownIndex] = grid
                end

                normalStageDownIndex = normalStageDownIndex + 1
            end

            normalStageIndex = normalStageIndex + 1
        elseif stageEntity:GetType() == XMVCA.XSkyGardenDroneGame.StageType.Special then
            grid = self._SpecialStageGrids[specialStageIndex]

            if not grid then
                local gridUi = XUiHelper.Instantiate(self.StageSpecial, self.PanelChapter)

                ---@type XUiSkyGardenDroneStageGrid
                grid = XUiSkyGardenDroneStageGrid.New(gridUi, self)
                self._SpecialStageGrids[specialStageIndex] = grid
            end

            specialStageIndex = specialStageIndex + 1
        elseif stageEntity:GetType() == XMVCA.XSkyGardenDroneGame.StageType.MainLine then
            grid = self._MainLineStageGrids[mainLineStageIndex]

            if not grid then
                local gridUi = XUiHelper.Instantiate(self.StageMainLine, self.PanelChapter)

                ---@type XUiSkyGardenDroneStageGrid
                grid = XUiSkyGardenDroneStageGrid.New(gridUi, self)
                self._MainLineStageGrids[mainLineStageIndex] = grid
            end

            mainLineStageIndex = mainLineStageIndex + 1
        elseif stageEntity:GetType() == XMVCA.XSkyGardenDroneGame.StageType.BranchLine then
            grid = self._BranchLineStageGrids[branchLineStageIndex]

            if not grid then
                local gridUi = XUiHelper.Instantiate(self.StageBranchLine, self.PanelChapter)

                ---@type XUiSkyGardenDroneStageGrid
                grid = XUiSkyGardenDroneStageGrid.New(gridUi, self)
                self._BranchLineStageGrids[branchLineStageIndex] = grid
            end

            branchLineStageIndex = branchLineStageIndex + 1
        end

        self._StageGridMap[stageEntity:GetStageId()] = grid

        grid:Close()
    end
    for i = normalStageUpIndex, #self._NormalStageUpGrids do
        self._NormalStageUpGrids[i]:Close()
    end
    for i = normalStageDownIndex, #self._NormalStageDownGrids do
        self._NormalStageDownGrids[i]:Close()
    end
    for i = specialStageIndex, #self._SpecialStageGrids do
        self._SpecialStageGrids[i]:Close()
    end
    for i = mainLineStageIndex, #self._MainLineStageGrids do
        self._MainLineStageGrids[i]:Close()
    end
    for i = branchLineStageIndex, #self._BranchLineStageGrids do
        self._BranchLineStageGrids[i]:Close()
    end
end

function XUiSkyGardenSGDroneStage:_RefreshStagePosition()
    local chapterId = self._ChapterEntity:GetChapterId()
    local stageEntities = self._ChapterEntity:GetStageList()
    local uiType = CS.XUiType.Normal

    for _, stageEntity in ipairs(stageEntities) do
        local grid = self._StageGridMap[stageEntity:GetStageId()]

        if grid and stageEntity:GetType() == XMVCA.XSkyGardenDroneGame.StageType.Normal then
            local position = self._Control:SendRequestStagePositionCmd(stageEntity:GetStageId())

            if position then
                local anchoredPosition = CS.XAxisConverter.Instance:ScreenToUILocalPoint(self.PanelChapter, position,
                    uiType)

                grid.Transform.anchoredPosition = anchoredPosition
            end
        elseif stageEntity:GetType() == XMVCA.XSkyGardenDroneGame.StageType.MainLine then
            local parent = self["PanelMainLine" .. tostring(chapterId)]

            if parent then
                grid.Transform:SetParent(parent)
                grid.Transform:Reset()
            end
        end

        if stageEntity:IsUnlock() then
            grid:Open()
            grid:Refresh(stageEntity)
        end
    end
end

function XUiSkyGardenSGDroneStage:_RefreshTitle()
    if not self._ChapterEntity then
        return
    end

    self.TxtChapterTitle.text = self._ChapterEntity:GetName()
end

return XUiSkyGardenSGDroneStage
