---@class XUiBigWorldShowLoading : XBigWorldUi
---@field SpineRoot XUiLoadPrefab
---@field Loading UnityEngine.RectTransform
---@field _Control XBigWorldLoadingControl
local XUiBigWorldShowLoading = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldShowLoading")

function XUiBigWorldShowLoading:OnStart()
    XMVCA.XBigWorldUI:SetMaskActive(true)
end

function XUiBigWorldShowLoading:OnEnable()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, XMVCA.XBigWorldQuest.QuestOpType.PopupBegin)
end

function XUiBigWorldShowLoading:OnDisable()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, XMVCA.XBigWorldQuest.QuestOpType.PopupEnd)
end

function XUiBigWorldShowLoading:OnDestroy()
    XMVCA.XBigWorldUI:SetMaskActive(false)
end

return XUiBigWorldShowLoading
