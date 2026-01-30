---@class XUiSkyGardenSGDronePopupDetail : XBigWorldUi
---@field TagNew UnityEngine.RectTransform
---@field ImagePlay UnityEngine.RectTransform
---@field BtnVideo XUiComponent.XUiButton
---@field VideoPlayer XVideoPlayerUGUI
---@field TxtTeach UnityEngine.UI.Text
---@field TxtTeachTitle UnityEngine.UI.Text
---@field BtnClose XUiComponent.XUiButtonExt
---@field Visual UnityEngine.RectTransform
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenSGDronePopupDetail = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenSGDronePopupDetail")

function XUiSkyGardenSGDronePopupDetail:OnAwake()
    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDronePopupDetail:OnStart(droneId)
    self:_Refresh(droneId)
    self:_RefreshVideo(droneId)
end

function XUiSkyGardenSGDronePopupDetail:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDronePopupDetail:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDronePopupDetail:OnDestroy()
end

function XUiSkyGardenSGDronePopupDetail:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose:AddEventListener(Handler(self, self.Close))
end

function XUiSkyGardenSGDronePopupDetail:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDronePopupDetail:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDronePopupDetail:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDronePopupDetail:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDronePopupDetail:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenSGDronePopupDetail:_InitUi()
    self.TagNew.gameObject:SetActiveEx(false)
end

function XUiSkyGardenSGDronePopupDetail:_Refresh(droneId)
    self.TxtTeach.text = self._Control:GetDroneDescription(droneId)
    self.TxtTeachTitle.text = self._Control:GetDroneName(droneId)
end

function XUiSkyGardenSGDronePopupDetail:_RefreshVideo(droneId)
    local videoId = self._Control:GetDroneTeachingVideoId(droneId)

    self.BtnVideo.gameObject:SetActiveEx(false)
    self.ImagePlay.gameObject:SetActiveEx(false)
    if XTool.IsNumberValid(videoId) then
        self.Visual.gameObject:SetActiveEx(true)
        self.BtnVideo.gameObject:SetActiveEx(true)
        self.VideoPlayer.VideoPlayerInst.loop = true
        self.VideoPlayer:SetInfoByVideoId(videoId)
        self.VideoPlayer:Prepare()
    end
end

return XUiSkyGardenSGDronePopupDetail
