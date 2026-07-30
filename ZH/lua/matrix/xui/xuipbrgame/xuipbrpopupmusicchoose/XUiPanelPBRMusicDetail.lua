--- Bgm详情面板
---@class XUiPanelPBRMusicDetail: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
---@field TxtMusicName UnityEngine.UI.Text 选中的Bgm名称
---@field PanelRhythmCommon UnityEngine.RectTransform 常态节奏面板节点
---@field PanelRhythmFever UnityEngine.RectTransform Fever节奏面板节点
local XUiPanelPBRMusicDetail = XClass(XUiNode, "XUiPanelPBRMusicDetail")

local XUiPanelPBRMusicRhythmShow = require("XUi/XUiPBRGame/XUiPBRPopupMusicChoose/XUiPanelPBRMusicRhythmShow")

function XUiPanelPBRMusicDetail:OnStart()
    ---@type XUiPanelPBRMusicRhythmShow
    self._RhythmCommon = XUiPanelPBRMusicRhythmShow.New(self.PanelRhythmCommon, self)
    ---@type XUiPanelPBRMusicRhythmShow
    self._RhythmFever = XUiPanelPBRMusicRhythmShow.New(self.PanelRhythmFever, self)
end

--- 刷新详情面板
---@param bgmCfg XTablePBRBgmList
function XUiPanelPBRMusicDetail:Refresh(bgmCfg)
    if not bgmCfg then
        return
    end
    self.TxtMusicName.text = bgmCfg.Name
    self._RhythmCommon:SetBgmCfg(bgmCfg, false)
    self._RhythmFever:SetBgmCfg(bgmCfg, true)
end

function XUiPanelPBRMusicDetail:SetPlaying(playing)
    self._RhythmCommon:SetPlaying(playing)
    self._RhythmFever:SetPlaying(playing)
end

return XUiPanelPBRMusicDetail
