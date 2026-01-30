local XUiSkyGardenSGDroneFailureSettlementGrid = require(
    "XUi/XUiSkyGarden/XDroneGame/Settlement/XUiSkyGardenSGDroneFailureSettlementGrid")

---@class XUiSkyGardenSGDroneFailureSettlement : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field ProgressContent UnityEngine.RectTransform
---@field LayoutElement UnityEngine.RectTransform
---@field TxtTeach UnityEngine.UI.Text
---@field ImgRewardBar UnityEngine.UI.Image
---@field BtnCancel XUiComponent.XUiButtonExt
---@field BtnConfirm XUiComponent.XUiButtonExt
---@field Visual UnityEngine.RectTransform
---@field BtnVideo XUiComponent.XUiButton
---@field VideoPlayer XVideoPlayerUGUI
---@field ImgPlay UnityEngine.UI.Image
---@field _Control XSkyGardenDroneGameControl
---@field Parent XUiSkyGardenSGDronePopupSettlement
local XUiSkyGardenSGDroneFailureSettlement = XClass(XUiNode, "XUiSkyGardenSGDroneFailureSettlement")

function XUiSkyGardenSGDroneFailureSettlement:OnStart()
    ---@type XUiSkyGardenSGDroneFailureSettlementGrid[]
    self._ProgressGrids = {}

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDroneFailureSettlement:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneFailureSettlement:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneFailureSettlement:OnDestroy()
end

function XUiSkyGardenSGDroneFailureSettlement:OnBtnCancelClick()
    self.Parent:Close()
    CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.RestartGame()
end

function XUiSkyGardenSGDroneFailureSettlement:OnBtnConfirmClick()
    self.Parent:Close()
    CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.RestoreGame()
end

function XUiSkyGardenSGDroneFailureSettlement:Refresh(droneId, progressCount, currentProgress, hasArchive)
    if not hasArchive then
        self.BtnConfirm:SetDisable(true, false)
    else
        self.BtnConfirm:SetDisable(false)
    end

    self:_RefreshDrone(droneId)
    self:_RefreshProgress(progressCount, currentProgress)
end

function XUiSkyGardenSGDroneFailureSettlement:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnCancel:AddEventListener(Handler(self, self.OnBtnCancelClick))
    self.BtnConfirm:AddEventListener(Handler(self, self.OnBtnConfirmClick))
end

function XUiSkyGardenSGDroneFailureSettlement:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDroneFailureSettlement:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDroneFailureSettlement:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneFailureSettlement:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDroneFailureSettlement:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenSGDroneFailureSettlement:_InitUi()
    self.LayoutElement.gameObject:SetActiveEx(false)
end

function XUiSkyGardenSGDroneFailureSettlement:_RefreshProgress(progressCount, currentProgress)
    for index = 1, progressCount do
        local gridUi = self._ProgressGrids[index]

        if not gridUi then
            local grid = XUiHelper.Instantiate(self.LayoutElement, self.ProgressContent)

            gridUi = XUiSkyGardenSGDroneFailureSettlementGrid.New(grid, self)
            self._ProgressGrids[index] = grid
        end

        gridUi:Refresh(index <= currentProgress, index == currentProgress)
    end
    for i = progressCount + 1, #self._ProgressGrids do
        self._ProgressGrids[i]:Close()
    end

    self.ImgRewardBar.fillAmount = currentProgress / progressCount
end

function XUiSkyGardenSGDroneFailureSettlement:_RefreshDrone(droneId)
    local videoId = self._Control:GetDroneTeachingVideoId(droneId)

    self.BtnVideo.gameObject:SetActiveEx(false)
    self.ImgPlay.gameObject:SetActiveEx(false)
    if XTool.IsNumberValid(videoId) then
        self.VideoPlayer.VideoPlayerInst.loop = true
        self.Visual.gameObject:SetActiveEx(true)
        self.VideoPlayer:SetInfoByVideoId(videoId)
        self.VideoPlayer:Prepare()
    end

    self.TxtTeach.text = self._Control:GetDroneDescription(droneId)
end

return XUiSkyGardenSGDroneFailureSettlement
