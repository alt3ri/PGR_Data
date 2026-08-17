--- BGM选择弹窗
---@class XUiPBRPopupMusicChoose: XLuaUi
---@field protected _Control XPBRGameControl
---@field BtnSure XUiComponent.XUiButton 确认当前选择的按钮
---@field BtnCancel XUiComponent.XUiButton 取消按钮，关闭界面
---@field ListMusic UnityEngine.RectTransform Bgm选项列表节点
---@field PanelMusicDetail UnityEngine.RectTransform bgm详情界面节点
local XUiPBRPopupMusicChoose = XLuaUiManager.Register(XLuaUi, "UiPBRPopupMusicChoose")

local XUiPanelPBRMusicChooseList = require("XUi/XUiPBRGame/XUiPBRPopupMusicChoose/XUiPanelPBRMusicChooseList")
local XUiPanelPBRMusicDetail = require("XUi/XUiPBRGame/XUiPBRPopupMusicChoose/XUiPanelPBRMusicDetail")

--region Ui生命周期

function XUiPBRPopupMusicChoose:OnAwake()
    self:BindExitBtns()
    self.BtnSure:AddEventListener(handler(self, self.OnBtnSureClick))
    self.BtnCancel:AddEventListener(handler(self, self.Close))

    ---@type XUiPanelPBRMusicChooseList
    self._ListPanel = XUiPanelPBRMusicChooseList.New(self.ListMusic, self)
    ---@type XUiPanelPBRMusicDetail
    self._DetailPanel = XUiPanelPBRMusicDetail.New(self.PanelMusicDetail, self)
end

function XUiPBRPopupMusicChoose:OnStart(stageId)
    self._StageId = stageId
    local stageCfg = self._Control:GetStageCfgById(stageId)
    local bgmIds = stageCfg and stageCfg.BgmIds or {}
    local currentBgmId = self._Control.MusicControl:GetSelectedBgmIdByStageId(stageId)

    self._SelectedBgmId = currentBgmId
    self._CurrentBgmId = currentBgmId

    self._ListPanel:Init(bgmIds, currentBgmId, handler(self, self._OnMusicSelect))
end

function XUiPBRPopupMusicChoose:OnDestroy()
    -- 不在此处 StopPreview：保留活跃音频会话，让消费方（商店/选人界面）通过
    -- PlayBgmIfNotCurrent 处理——目标曲与正在播的相同则短路维持不打断，不同才切换。
    -- 否则先 Stop 会导致同曲也从 0:00 重播，体验差。
    self._Control:DispatchEvent(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_MUSIC_POPUP_CLOSED)
end

--endregion

--region 交互

function XUiPBRPopupMusicChoose:_OnMusicSelect(bgmId)
    self._SelectedBgmId = bgmId
    local bgmCfg = self._Control.MusicControl:GetTablePBRBgmCfgById(bgmId)
    self._DetailPanel:Refresh(bgmCfg)
    self._Control.MusicControl:PlayPreview(bgmId)
    self._DetailPanel:SetPlaying(true)
end

function XUiPBRPopupMusicChoose:OnBtnSureClick()
    if self._SelectedBgmId and self._SelectedBgmId ~= self._CurrentBgmId then
        self._Control.MusicControl:SetSelectedBgmIdByStageId(self._StageId, self._SelectedBgmId)
    end
    self:Close()
end

--endregion

return XUiPBRPopupMusicChoose
