---@class XUiBigWorldNarrative : XBigWorldUi
---@field TitleText UnityEngine.UI.Text
---@field ContentText UnityEngine.UI.Text
---@field BtnClose XUiComponent.XUiButton
---@field PanelPhoto UnityEngine.Transform
---@field PanelNarrative UnityEngine.Transform
local XUiBigWorldNarrative = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldNarrative")

local NarrativeType = {
    Text = 1,
    Photo = 2,
    Spine = 3
}

function XUiBigWorldNarrative:OnAwake()
    self._OpType = XMVCA.XBigWorldQuest.QuestOpType or {
        PopupBegin = 2,
        PopupEnd = 3,
    }
    self._currentId = 0
    self._closedCallback = nil
    ---@type XUiBigWorldNarrativePanel
    self._panelNarrative = require("XUi/XUiBigWorld/XNarrative/XUiBigWorldNarrativePanel").New(self.PanelNarrative, self)
    ---@type XUiBigWorldNarrativePhotoPanel
    self._panelPhoto = require("XUi/XUiBigWorld/XNarrative/XUiBigWorldNarrativePhotoPanel").New(self.PanelPhoto, self)
    ---@type XUiBigWorldSpinePanel
    self._panelSpine = require("XUi/XUiBigWorld/XNarrative/XUiBigWorldSpinePanel").New(self.PanelPhotoSpine, self)
    self._panelNarrative:Close()
    self._panelPhoto:Close()
    self._panelSpine:Close()
end

function XUiBigWorldNarrative:OnStart()
   
end

function XUiBigWorldNarrative:OnEnable(id, closedCallback)
    self._currentId = id
    self._curNarrativeType = XMVCA.XBigWorldService:GetNarrativeType(self._currentId)
    self._closedCallback = closedCallback

    self:Refresh()

    -- 通用的ui流程不支持子UI，所以这里需要自己手动调用
    self:ChangePauseFight(true)
    self:ChangeInput(true)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self._OpType.PopupBegin)
end

function XUiBigWorldNarrative:OnDisable()
    self._currentId = 0
    self._closedCallback = nil
    self:ChangePauseFight(false)
    self:ChangeInput(false)

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self._OpType.PopupEnd)
end

function XUiBigWorldNarrative:Refresh()
    if self._curNarrativeType == NarrativeType.Text then
        self._panelNarrative:Refresh(self._currentId)
        self._panelPhoto:Close()
        self._panelSpine:Close()
    elseif self._curNarrativeType == NarrativeType.Photo then
        self._panelPhoto:Refresh(self._currentId)
        self._panelNarrative:Close()
        self._panelSpine:Close()
    elseif self._curNarrativeType == NarrativeType.Spine then
        self._panelSpine:Refresh(self._currentId)
        self._panelNarrative:Close()
        self._panelPhoto:Close()
    end
end

function XUiBigWorldNarrative:OnBtnCloseClick()
    local cb = self._closedCallback
    local id = self._currentId
    self._closedCallback = nil
    self:Close()
    if cb then
        cb(id)
    end
end
