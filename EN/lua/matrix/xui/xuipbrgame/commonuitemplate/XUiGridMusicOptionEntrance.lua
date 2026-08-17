--- BGM设置入口
---@class XUiGridMusicOptionEntrance: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
---@field GridBtn XUiComponent.XUiButton
---@field TxtMask UnityEngine.RectTransform
---@field Txt UnityEngine.UI.Text
local XUiGridMusicOptionEntrance = XClass(XUiNode, "XUiGridMusicOptionEntrance")
local XUiTextScrolling = require("XUi/XUiTaikoMaster/XUiTaikoMasterFlowText")

function XUiGridMusicOptionEntrance:OnStart()
    ---@type XUiTaikoMasterFlowText
    self._TextScrolling = XUiTextScrolling.New(self.Txt, self.TxtMask)
end

function XUiGridMusicOptionEntrance:OnEnable()
    self._TextScrolling:Play()
end

function XUiGridMusicOptionEntrance:OnDisable()
    self._TextScrolling:Stop()
end

function XUiGridMusicOptionEntrance:AddEventListener(callback)
    self.GridBtn:AddEventListener(callback)
end

function XUiGridMusicOptionEntrance:RefreshBgmName(stageId)
    self.GridBtn:SetNameByGroup(0, self._Control.MusicControl:GetCurrentSelectBgmName(stageId))
end

return XUiGridMusicOptionEntrance