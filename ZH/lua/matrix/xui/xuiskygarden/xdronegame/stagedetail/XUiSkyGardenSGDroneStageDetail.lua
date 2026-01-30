local XUiSkyGardenDroneStageDetailGrid = require(
    "XUi/XUiSkyGarden/XDroneGame/StageDetail/XUiSkyGardenDroneStageDetailGrid")

---@class XUiSkyGardenSGDroneStageDetail : XBigWorldUi
---@field BtnClose XUiComponent.XUiButtonExt
---@field TxtTitle UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field PanelName UnityEngine.RectTransform
---@field TxtStoryDes UnityEngine.UI.Text
---@field PanelReward UnityEngine.RectTransform
---@field PanelItem UnityEngine.RectTransform
---@field ItemGrid UnityEngine.RectTransform
---@field PanelBottom UnityEngine.RectTransform
---@field BtnFight XUiComponent.XUiButtonExt
---@field BtnGo XUiComponent.XUiButtonExt
---@field ListStage UnityEngine.RectTransform
---@field GridStage UnityEngine.RectTransform
---@field PanelSwitch UnityEngine.RectTransform
---@field TogDifficulty XUiComponent.XUiButtonExt
---@field TxtDifficulty UnityEngine.UI.Text
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenSGDroneStageDetail = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenSGDroneStageDetail")

function XUiSkyGardenSGDroneStageDetail:OnAwake()
    ---@type XSGDroneStageEntity
    self._StageEntity = false
    ---@type XUiSkyGardenDroneStageDetailGrid[]
    self._GridList = {}

    self._IsShow = false

    self._IsCurrentDifficulty = false

    self:_InitUi()
    self:_RegisterButtonClicks()

    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SKY_GARDEN_DRONE_GAME_STAGE_DETAIL_UI_REFRESH,
        self.OnRefresh, self)
end

---@param stageEntity XSGDroneStageEntity
function XUiSkyGardenSGDroneStageDetail:OnStart(stageEntity)
    self._StageEntity = stageEntity
end

function XUiSkyGardenSGDroneStageDetail:OnEnable()
    self._IsShow = true

    self:_RefreshTitle()
    self:_RefreshButton()
    self:_RefreshReward()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneStageDetail:OnDisable()
    self._IsShow = false

    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneStageDetail:OnDestroy()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SKY_GARDEN_DRONE_GAME_STAGE_DETAIL_UI_REFRESH,
        self.OnRefresh, self)
end

---@param stageEntity XSGDroneStageEntity
function XUiSkyGardenSGDroneStageDetail:OnRefresh(stageEntity)
    self._StageEntity = stageEntity

    if self._IsShow then
        return
    end

    self:_RefreshTitle()
    self:_RefreshButton()
    self:_RefreshReward()
end

function XUiSkyGardenSGDroneStageDetail:OnClickBtnFight()
    local stageEntity = self._StageEntity

    if not stageEntity then
        return
    end

    local stageId = stageEntity:GetStageId()
    local isHardMode = self._IsCurrentDifficulty
    local easyDroneHp = stageEntity:GetEasyDroneHp()
    local isEnableAssistance = stageEntity:IsEnableAssistance()

    self._Control:RequestStageStart(stageId, isHardMode, function(stageData)
        CS.XAudioManager.BgmAreaTriggerEnable = false
        XMVCA.XBigWorldUI:Open("UiSkyGardenSGDroneLoading")
        XMVCA.XBigWorldUI:Open("UiSkyGardenSGDroneGame", stageId, stageEntity:GetMapId(), stageData, isHardMode,
            easyDroneHp, isEnableAssistance)
    end)
end

function XUiSkyGardenSGDroneStageDetail:OnClickBtnGo()
    local stageEntity = self._StageEntity

    if not stageEntity then
        return
    end

    if stageEntity:IsSkip() then
        local skipId = stageEntity:GetSkipId()

        if XMVCA.XBigWorldSkipFunction:SkipTo(skipId) then
            XMVCA.XBigWorldUI:SafeClose("UiSkyGardenSGDroneStageDetail")
            XMVCA.XBigWorldUI:SafeClose("UiSkyGardenSGDroneStage")
            XMVCA.XBigWorldUI:SafeClose("UiSkyGardenSGDroneChapter")
            XMVCA.XBigWorldUI:SafeClose("UiSkyGardenSGDroneMain")
        end
    end
end

function XUiSkyGardenSGDroneStageDetail:OnClickTogDifficulty()
    self._IsCurrentDifficulty = not self._IsCurrentDifficulty

    if self._IsCurrentDifficulty then
        self.TogDifficulty:SetButtonState(CS.UiButtonState.Select)
    else
        self.TogDifficulty:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiSkyGardenSGDroneStageDetail:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnClose:AddEventListener(Handler(self, self.Close))
    self.BtnFight:AddEventListener(Handler(self, self.OnClickBtnFight))
    self.BtnGo:AddEventListener(Handler(self, self.OnClickBtnGo))
    self.TogDifficulty:AddEventListener(Handler(self, self.OnClickTogDifficulty))
end

function XUiSkyGardenSGDroneStageDetail:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDroneStageDetail:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDroneStageDetail:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneStageDetail:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDroneStageDetail:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenSGDroneStageDetail:_InitUi()
    self.GridStage.gameObject:SetActiveEx(false)
end

function XUiSkyGardenSGDroneStageDetail:_RefreshTitle()
    local stageEntity = self._StageEntity

    if not stageEntity then
        return
    end

    self.TxtTitle.text = stageEntity:GetName()
    self.TxtStoryDes.text = stageEntity:GetDesc()
    self.TxtDifficulty.text = stageEntity:GetHardModeText()
end

function XUiSkyGardenSGDroneStageDetail:_RefreshButton()
    local stageEntity = self._StageEntity

    if not stageEntity then
        return
    end

    if stageEntity:GetType() == XMVCA.XSkyGardenDroneGame.StageType.Normal then
        self.BtnFight.gameObject:SetActiveEx(true)
        self.BtnGo.gameObject:SetActiveEx(false)
    else
        self.BtnFight.gameObject:SetActiveEx(false)
        self.BtnGo.gameObject:SetActiveEx(true)
    end
end

function XUiSkyGardenSGDroneStageDetail:_RefreshReward()
    local stageEntity = self._StageEntity

    if not stageEntity then
        return
    end

    if stageEntity:GetType() == XMVCA.XSkyGardenDroneGame.StageType.Normal then
        local count = 0
        local rewards = stageEntity:GetRewards()

        self.PanelSwitch.gameObject:SetActiveEx(true)
        self.ListStage.parent.gameObject:SetActiveEx(true)

        if not XTool.IsTableEmpty(rewards) then
            for index, reward in ipairs(rewards) do
                local targetId = stageEntity:GetStarTargetIdByIndex(index)
                local grid = self._GridList[index]

                if not grid then
                    local gridUi = XUiHelper.Instantiate(self.GridStage, self.ListStage)

                    grid = XUiSkyGardenDroneStageDetailGrid.New(gridUi, self)
                    self._GridList[index] = grid
                end

                grid:Open()
                grid:Refresh(targetId, reward, stageEntity:IsTargetComplete(targetId))
                count = count + 1
            end
        end

        for i = count + 1, #self._GridList do
            self._GridList[i]:Close()
        end
    elseif stageEntity:GetType() == XMVCA.XSkyGardenDroneGame.StageType.MainLine then
        for i = 1, #self._GridList do
            self._GridList[i]:Close()
        end

        self.PanelSwitch.gameObject:SetActiveEx(false)
        self.ListStage.parent.gameObject:SetActiveEx(false)
    end
end

return XUiSkyGardenSGDroneStageDetail
