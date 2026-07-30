local XUiPBRCharacterDetail = require('XUi/XUiPBRGame/XUiPBRCharacterDetail/XUiPBRCharacterDetail')

--- 进关卡前的角色选择界面，预制体用的是 UiPBRCharacterDetail
---@class XUiPBRCharacterSelection: XUiPBRCharacterDetail
---@field protected _Control XPBRGameControl
local XUiPBRCharacterSelection = XLuaUiManager.Register(XUiPBRCharacterDetail, "UiPBRCharacterSelection")
local XUiGridMusicOptionEntrance = require("XUi/XUiPBRGame/CommonUiTemplate/XUiGridMusicOptionEntrance")

function XUiPBRCharacterSelection:OnStart(stageId)
    self.CurStageId = stageId

    local stageCfg = self._Control:GetStageCfgById(stageId)

    -- 如果有推荐角色，选择推荐角色，否则选择顺位第一个
    if XTool.IsNumberValidEx(stageCfg.RecommendChar) then
        self.PanelPick:ShowAndSelectRecommendChar(stageCfg.RecommendChar)
    else
        self.PanelPick:SelectByIndex(1)
    end

    if self.UiGridMusic then
        self.UiGridMusic:SetVisible(self._Control:CheckIsEndlessStagePassed(self.CurStageId))
    end

    if self.PanelStage then
        self.PanelStage.gameObject:SetActiveEx(true)

        if self.TxtStageName then
            self.TxtStageName.text = XUiHelper.FormatTextEx(self._Control:GetClientPBRText("StageNameInSelection"), stageCfg.StageName)
        end
    end
end

function XUiPBRCharacterSelection:InitComponents()
    -- 父类方法
    XUiPBRCharacterDetail.InitComponents(self)
    self.BtnEnterB.gameObject:SetActiveEx(true)
    self.BtnEnterB:AddEventListener(function() self:OnBtnEnterBClick() end)
    
    -- 选关界面需要开放天赋入口
    if self.BtnGenius then
        self.BtnGenius.gameObject:SetActiveEx(true)
        self.BtnGenius:AddEventListener(function() self:OnBtnGeniusClick() end)
    end

    if self.BtnMusic then
        ---@type XUiGridMusicOptionEntrance
        self.UiGridMusic = XUiGridMusicOptionEntrance.New(self.BtnMusic, self)
        self.UiGridMusic:AddEventListener(handler(self, self.OnBtnMusicClick))
    end
end

function XUiPBRCharacterSelection:OnEnable()
    XUiPBRCharacterDetail.OnEnable(self)
    self:RefreshReddot()

    if XTool.IsNumberValidEx(self.CurCharacterId) then
        local charCfg = self._Control.CharacterControl:GetCharacterCfg(self.CurCharacterId)

        if charCfg then
            self.PanelAttribute:RefreshStatusShow(charCfg.CharacterId)
            self.PanelExclusive:RefreshCharacterExclusiveDesc(charCfg.CharacterId)
        end
    end

    if self.UiGridMusic then
        self.UiGridMusic:RefreshBgmName(self.CurStageId)
    end
    
    self._Control:AddEventListener(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_MUSIC_POPUP_CLOSED, self.OnMusicChooseClose, self)
end

function XUiPBRCharacterSelection:OnDisable()
    XUiPBRCharacterDetail.OnDisable(self)

    self._Control:RemoveEventListener(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_MUSIC_POPUP_CLOSED, self.OnMusicChooseClose, self)
end

---@overload
function XUiPBRCharacterSelection:GetCharacterListCls()
    return require('XUi/XUiPBRGame/XUiPBRCharacterSelection/XUiPBRCharacterSelectionPanelPick')
end


function XUiPBRCharacterSelection:OnBtnEnterBClick()
    local customCharId = self._Control.InGameControl:GetCurSelectCharId()

    if self._Control.CharacterControl:GetIsCharacterUnlock(customCharId) then
        self._Control.InGameControl:SetSegmentSettleDataCacheInBegin(self.CurStageId, customCharId)
        self:Close()
        XMVCA.XFuben:EnterFightByStageId(self.CurStageId, nil, false, 1, nil)
    else
        XUiManager.TipMsg(self._Control:GetClientPBRText('StageEnterFailWithLockChar'))
    end
end

function XUiPBRCharacterSelection:OnBtnGeniusClick()
    XLuaUiManager.Open('UiPBRGenius')
end

function XUiPBRCharacterSelection:RefreshReddot()
    if self.BtnGenius then
        self.BtnGenius:ShowReddot(XMVCA.XPBRGame:ReddotIsAnyGeniusNodeCanUnlock())
    end
end

function XUiPBRCharacterSelection:OnBtnMusicClick()
    -- 打开弹窗前快照当前正在播的 BGM（选人界面默认 bgm1，由 prefab 组件播放、
    -- 不在 MusicControl 托管内），弹窗试听会顶掉它，关闭弹窗时按此 CueId 恢复
    self._BgmBeforeCueId = self._Control.MusicControl:GetCurrentSystemMusicCueId()
    XLuaUiManager.Open("UiPBRPopupMusicChoose", self.CurStageId)
end

function XUiPBRCharacterSelection:OnMusicChooseClose()
    -- 选人界面无条件恢复 bgm1：弹窗里选的曲只存不播（供后续商店使用），
    -- 界面自身始终回到默认 BGM
    self._Control.MusicControl:StopPreviewAndRestoreByCueId(self._BgmBeforeCueId)

    if self.UiGridMusic then
        self.UiGridMusic:RefreshBgmName(self.CurStageId)
    end
end

return XUiPBRCharacterSelection