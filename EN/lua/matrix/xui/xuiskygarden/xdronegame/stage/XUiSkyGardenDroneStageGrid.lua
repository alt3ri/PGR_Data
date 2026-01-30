local XUiSkyGardenDroneStageStar = require("XUi/XUiSkyGarden/XDroneGame/Stage/XUiSkyGardenDroneStageStar")

---@class XUiSkyGardenDroneStageGrid : XUiNode
---@field BtnStage XUiComponent.XUiButtonExt
---@field PanelClear UnityEngine.RectTransform
---@field PanelStarReward UnityEngine.RectTransform
---@field IconStar UnityEngine.RectTransform
---@field Parent XUiSkyGardenSGDroneStage
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenDroneStageGrid = XClass(XUiNode, "XUiSkyGardenDroneStageGrid")

function XUiSkyGardenDroneStageGrid:OnStart()
    ---@type XSGDroneStageEntity
    self._StageEntity = false
    ---@type XUiSkyGardenDroneStageStar[]
    self._StarList = {}

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenDroneStageGrid:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenDroneStageGrid:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenDroneStageGrid:OnDestroy()
end

function XUiSkyGardenDroneStageGrid:OnBtnStageClick()
    self:OpenDetail()
end

---@param stageEntity XSGDroneStageEntity
function XUiSkyGardenDroneStageGrid:Refresh(stageEntity)
    if not stageEntity then
        return
    end

    self._StageEntity = stageEntity
    self.BtnStage:SetNameByGroup(0, stageEntity:GetName())
    self.BtnStage:ShowTag(stageEntity:IsComplete())
    self.BtnStage:ShowReddot(stageEntity:IsNew())
    self.BtnStage:SetSprite(stageEntity:GetIcon())
    self.PanelClear.gameObject:SetActiveEx(stageEntity:IsComplete())

    self:_RefreshStar(stageEntity)
end

function XUiSkyGardenDroneStageGrid:SetSelect(isSelect)
    if isSelect then
        self.BtnStage:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnStage:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiSkyGardenDroneStageGrid:OpenDetail()
    if not self._StageEntity then
        return
    end

    XMVCA.XBigWorldUI:Open("UiSkyGardenSGDroneStageDetail", self._StageEntity)
end

function XUiSkyGardenDroneStageGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnStage:AddEventListener(Handler(self, self.OnBtnStageClick))
end

function XUiSkyGardenDroneStageGrid:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenDroneStageGrid:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenDroneStageGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenDroneStageGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenDroneStageGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenDroneStageGrid:_InitUi()
    self.IconStar.gameObject:SetActiveEx(false)
end

---@param stageEntity XSGDroneStageEntity
function XUiSkyGardenDroneStageGrid:_RefreshStar(stageEntity)
    if stageEntity:GetType() == XMVCA.XSkyGardenDroneGame.StageType.MainLine then
        if not XTool.IsTableEmpty(self._StarList) then
            for _, star in pairs(self._StarList) do
                star:Close()
            end
        end

        self.PanelStarReward.gameObject:SetActiveEx(false)
    else
        local starCount = stageEntity:GetTotalStarCount()
        local currentStarCount = stageEntity:GetCurrentStarCount()

        self.PanelStarReward.gameObject:SetActiveEx(true)
        for i = 1, starCount do
            local star = self._StarList[i]

            if not star then
                local starUi = XUiHelper.Instantiate(self.IconStar, self.PanelStarReward)

                star = XUiSkyGardenDroneStageStar.New(starUi, self)
                self._StarList[i] = star
            end

            star:Open()
            star:Refresh(i <= currentStarCount)
        end
    end
end

return XUiSkyGardenDroneStageGrid
