local XUiSkyGardenSGDroneCheckpointSettlement = require(
    "XUi/XUiSkyGarden/XDroneGame/Settlement/XUiSkyGardenSGDroneCheckpointSettlement")
local XUiSkyGardenSGDroneFailureSettlement = require(
    "XUi/XUiSkyGarden/XDroneGame/Settlement/XUiSkyGardenSGDroneFailureSettlement")

---@class XUiSkyGardenSGDronePopupSettlement : XBigWorldUi
---@field BtnTanchuangClose XUiComponent.XUiButtonExt
---@field PanelSettlement UnityEngine.RectTransform
---@field PanelLostUAV UnityEngine.RectTransform
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenSGDronePopupSettlement = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenSGDronePopupSettlement")

function XUiSkyGardenSGDronePopupSettlement:OnAwake()
    ---@type XUiSkyGardenSGDroneCheckpointSettlement
    self._CheckpointUi = XUiSkyGardenSGDroneCheckpointSettlement.New(self.PanelSettlement, self)
    ---@type XUiSkyGardenSGDroneFailureSettlement
    self._FailureUi = XUiSkyGardenSGDroneFailureSettlement.New(self.PanelLostUAV, self)

    self._IsWin = false
    self._StageId = 0

    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDronePopupSettlement:OnStart(settleData)
    self._IsWin = settleData.IsWin
    self._StageId = settleData.StageId

    if self._IsWin then
        self._CheckpointUi:Open()
        self._FailureUi:Close()
        self._CheckpointUi:Refresh(self._StageId, settleData.Score, settleData.TargetMap, settleData.AchieveTargetMap)
    else
        self._CheckpointUi:Close()
        self._FailureUi:Open()
        self._FailureUi:Refresh(settleData.DroneId, settleData.RelayPointCount, settleData.CurrentRelayPointIndex, settleData.HasArchive)
    end
end

function XUiSkyGardenSGDronePopupSettlement:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDronePopupSettlement:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDronePopupSettlement:OnDestroy()
end

function XUiSkyGardenSGDronePopupSettlement:OnBtnTanchuangCloseClick()
    if not self._IsWin then
        self._Control:RequestStageGiveUp(function()
            self:_ReleaseGame()
        end)
    else
        self:_ReleaseGame()
    end
end

function XUiSkyGardenSGDronePopupSettlement:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnTanchuangClose:AddEventListener(Handler(self, self.OnBtnTanchuangCloseClick))
end

function XUiSkyGardenSGDronePopupSettlement:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDronePopupSettlement:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDronePopupSettlement:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDronePopupSettlement:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDronePopupSettlement:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenSGDronePopupSettlement:_ReleaseGame()
    local stageEntity = self._Control:GetStageEntity(self._StageId)

    if stageEntity then
        self._Control:TryRestoreStageUI(stageEntity)
    end

    self._Control:OpenBlackMask()

    self:Close()
    CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.ReleaseGame()
end

return XUiSkyGardenSGDronePopupSettlement
