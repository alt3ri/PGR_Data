---@class XUiBigWorldLoadingPartial : XLuaUi
---@field ImgLoading UnityEngine.UI.RawImage
---@field Desc UnityEngine.UI.Text
---@field TitleText UnityEngine.UI.Text
---@field SpineRoot XUiLoadPrefab
---@field Loading UnityEngine.RectTransform
---@field _Control XBigWorldLoadingControl
local XUiBigWorldLoading = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldLoading")

function XUiBigWorldLoading:OnAwake()
    ---@type XTableBigWorldLoading
    self._Loading = false

    self._PopupBegin = XMVCA.XBigWorldQuest.QuestOpType.PopupBegin
    self._PopupEnd = XMVCA.XBigWorldQuest.QuestOpType.PopupEnd
    XMVCA.XBigWorldUI:SetMaskActive(true)
end

function XUiBigWorldLoading:OnStart(config)
    self._Loading = config
end

function XUiBigWorldLoading:OnEnable()
    self:_RefreshBackground()
    -- 进入空花前关闭音乐
    XLuaAudioManager.StopCurrentBGM()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self._PopupBegin)
end

function XUiBigWorldLoading:OnDisable()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self._PopupEnd)
end

function XUiBigWorldLoading:OnDestroy()
    --Loading 过程中退出游戏，不设置mask
    if not XLoginManager.IsLogin() then
        return
    end
    XMVCA.XBigWorldUI:SetMaskActive(false)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CHECK_FUNCTION_POPUP)
end

function XUiBigWorldLoading:_RefreshBackground()
    local config = self._Loading

    if config then
        self.Desc.text = XUiHelper.ReplaceTextNewLine(config.Desc)
        self.TitleText.text = XUiHelper.ReplaceTextNewLine(config.Name)
        self.ImgLoading:SetRawImage(config.ImageUrl)
    end
end

return XUiBigWorldLoading
