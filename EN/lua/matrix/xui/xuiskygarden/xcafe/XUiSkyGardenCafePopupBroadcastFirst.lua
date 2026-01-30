
---@class XUiSkyGardenCafePopupBroadcastFirst : XBigWorldUi
---@field _Control XSkyGardenCafeControl
local XUiSkyGardenCafePopupBroadcastFirst = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenCafePopupBroadcastFirst")

function XUiSkyGardenCafePopupBroadcastFirst:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafePopupBroadcastFirst:OnStart(stageId)
    self._StageId = stageId
    self:InitView()
end

function XUiSkyGardenCafePopupBroadcastFirst:InitUi()
end

function XUiSkyGardenCafePopupBroadcastFirst:InitCb()
end

function XUiSkyGardenCafePopupBroadcastFirst:InitView()
    local targetIds = self._Control:GetStageTarget(self._StageId)
    for i, target in pairs(targetIds) do
        self["TxtPoints" .. i].text = target
    end
    self.TxtTime.text = self._Control:GetStageRounds(self._StageId)
    self:PlayAnimationWithMask("Enable", function() 
        self:Close()
    end)
end