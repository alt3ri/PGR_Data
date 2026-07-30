--- BGM节奏显示包装类
---@class XUiPanelPBRMusicRhythmShow: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
---@field UiPBRPanelRhythm UnityEngine.RectTransform 通用节拍面板
local XUiPanelPBRMusicRhythmShow = XClass(XUiNode, "XUiPanelPBRMusicRhythmShow")

local XUiPanelPBRMusicRhythm = require("XUi/XUiPBRGame/XUiPBRPopupMusicChoose/XUiPanelPBRMusicRhythm")

function XUiPanelPBRMusicRhythmShow:OnStart()
    ---@type XUiPanelPBRMusicRhythm
    self._Rhythm = XUiPanelPBRMusicRhythm.New(self.UiPBRPanelRhythm, self)
end

function XUiPanelPBRMusicRhythmShow:SetBgmCfg(bgmCfg, isFever)
    self._Rhythm:SetBgmCfg(bgmCfg, isFever)
end

function XUiPanelPBRMusicRhythmShow:SetPlaying(playing)
    self._Rhythm:SetPlaying(playing)
end

return XUiPanelPBRMusicRhythmShow
