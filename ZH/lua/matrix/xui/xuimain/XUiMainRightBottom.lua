 local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")
local XUiMainRightBottom = XClass(XUiMainPanelBase, "XUiMainRightBottom")

local TipsMainViewTextMovePauseInterval = CS.XGame.ClientConfig:GetFloat("TipsMainViewTextMovePauseInterval")
local TipsMainViewTextMoveSpeed = CS.XGame.ClientConfig:GetFloat("TipsMainViewTextMoveSpeed")

local TipsType = {
    Normal = 1,
    Music  = 2,
}

--主界面会频繁打开，采用常量缓存
local RedPointConditionGroup = {
    --终端
    Terminal = {
        XRedPointConditions.Types.CONDITION_MAIN_TERMINAL
    }
}

function XUiMainRightBottom:OnStart(rootUi)
    -- self.Transform = rootUi.PanelRightBottom.gameObject.transform
    self.RootUi = rootUi
    -- XTool.InitUiObject(self)
    self.GridTips = {}
    --Filter
    self:CheckFilterFunctions()
    
    
    self.BtnTerminal.CallBack = function() self:OnBtnTerminalClick() end
    self:InitAudioCueEventListener()
    
    --RedPoint
    self.TerminalRedPoint = self:AddRedPointEvent(self.BtnTerminal, self.OnCheckBtnTerminalRedPoint, self, RedPointConditionGroup.Terminal)
    
    self.TxtTips.gameObject:SetActiveEx(false)
    self.TxtMusic.gameObject:SetActiveEx(false)
    
    self.LayoutGroup = self.TipsContent:GetComponent("XAutoLayoutGroup")
end

function XUiMainRightBottom:OnEnable()
    self:_SetEvent(true)
    self:ResetAudioCueEffectState()
    self:UpdateView()
    self:RefreshTips()
    self:CheckRedPoint()
    self:StartTimer()
end

function XUiMainRightBottom:OnDisable()
    self:_SetEvent(false)
    if self.ScrollSequence then
        self.ScrollSequence:Kill()
        self.ScrollSequence = nil
    end
    self:StopTimer()
    self:ClearGrids()

    self.ChangeColorFin = false
    self:ResetAudioCueEffectState()
end

function XUiMainRightBottom:OnDestroy()

end

--region event
function XUiMainRightBottom:_SetEvent(flag)
    if flag then
        --界面状态事件，也会触发红点检查
        XEventManager.AddEventListener(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE, self.RefreshTips, self)
        XEventManager.AddEventListener(XEventId.EVENT_MAINUI_EXPENSIVE_ITEM_CHANGE, self.RefreshTips, self)
        XEventManager.AddEventListener(XEventId.EVENT_DORM_NOTIFY_DORMITORY_DATA, self.RefreshTips, self)
        XEventManager.AddEventListener(XEventId.EVENT_MUSIC_PLAYER_CHANGE, self._OnMusicPlayerChange, self)
        XMVCA.XPreload:AddAgencyEvent(XAgencyEventId.EVENT_PRELOAD_DOWNLOAD_STATE, self.RefreshTips, self)
    else
        XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE, self.RefreshTips, self)
        XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_EXPENSIVE_ITEM_CHANGE, self.RefreshTips, self)
        XEventManager.RemoveEventListener(XEventId.EVENT_DORM_NOTIFY_DORMITORY_DATA, self.RefreshTips, self)
        XEventManager.RemoveEventListener(XEventId.EVENT_MUSIC_PLAYER_CHANGE, self._OnMusicPlayerChange, self)
        XMVCA.XPreload:RemoveAgencyEvent(XAgencyEventId.EVENT_PRELOAD_DOWNLOAD_STATE, self.RefreshTips, self)
    end
end

function XUiMainRightBottom:_OnMusicPlayerChange()
    self:RefreshTips()
end
--endregion

function XUiMainRightBottom:CheckFilterFunctions()

end

function XUiMainRightBottom:StartTimer()
 
end

function XUiMainRightBottom:StopTimer()
  
end

function XUiMainRightBottom:GetScrollTips()
    local tipList = XMVCA.XUiMain:GetScrollTipList(false)
    
    if XTool.IsTableEmpty(tipList) then
        local musicCO = XMVCA.XMusicPlayer:GetCurCommonBgnCO()
        if musicCO then
            local name = string.format("%s - %s",
                    string.gsub(XUiHelper.ReplaceTextNewLine(musicCO.Name), "\n", ""),
                    string.gsub(XUiHelper.ReplaceTextNewLine(musicCO.Composer), "\n", ""))
            table.insert(tipList, {
                Tips = name,
                Type = TipsType.Music
            })
        end
    end
    
    return tipList
end
 
function XUiMainRightBottom:UpdateView()
    local isPc = XDataCenter.UiPcManager.IsPc()
    self.ImgBattery.transform.parent.gameObject:SetActiveEx(not isPc)
end

function XUiMainRightBottom:RefreshTips()
    if not self.ChangeColorFin or not XDataCenter.DormManager.IsDormDataNotify then -- ChangeColorFin字段保证刷新在切换主题之后
        return
    end
    
    if self.ScrollSequence then
        self.ScrollSequence:Kill()
        self.ScrollSequence = nil
    end
   
    local tipList = self:GetScrollTips()
    
    self.NeedScroll = not XTool.IsTableEmpty(tipList)

    for _, map in pairs(self.GridTips) do
        for _, grid in pairs(map or {}) do
            if grid and not XTool.UObjIsNil(grid.GameObject) then
                grid.GameObject:SetActiveEx(false)
            end
        end
    end

    for i, tip in ipairs(tipList) do
        self.GridTips[tip.Type] = self.GridTips[tip.Type] or {}
        local grid = self.GridTips[tip.Type][i]
        if not grid then
            local tmpGrid = tip.Type == TipsType.Normal and self.TxtTips.gameObject or self.TxtMusic.gameObject
            local ui = XUiHelper.Instantiate(tmpGrid, self.TipsContent)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.GridTips[tip.Type][i] = grid
        end
        grid.TxtTips.text = tip.Tips
        grid.GameObject:SetActiveEx(true)
        if tip.Type == TipsType.Normal then
            grid.Image2.gameObject:SetActiveEx(true)
            grid.Image1.gameObject:SetActiveEx(true)
        elseif tip.Type == TipsType.Music then
            grid.IconMusic.gameObject:SetActiveEx(true)
        end
    end
    self:ScrollTips()
end

function XUiMainRightBottom:AfterChangeColorCb()
    self:RefreshTips()
end

function XUiMainRightBottom:ClearGrids()
    for _, map in pairs(self.GridTips) do
        for _, grid in pairs(map or {}) do
            if grid and not XTool.UObjIsNil(grid.GameObject) then
                XUiHelper.Destroy(grid.GameObject)
            end
        end
    end
    self.GridTips = {}
end

function XUiMainRightBottom:ScrollTips()
    if not self.NeedScroll then
        return
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.TipsContent)
    local width = self.TipsContent.rect.width + self.LayoutGroup.Padding.horizontal
    local maskWidth = self.PanelTipText.sizeDelta.x
    local distance = width + maskWidth
    local sequence = CS.DG.Tweening.DOTween.Sequence()
    local pos = self.TipsContent.localPosition
    pos.x = pos.x + maskWidth
    self.TipsContent.localPosition = pos
    sequence:Append(self.TipsContent:DOLocalMoveX(-width, distance / TipsMainViewTextMoveSpeed))
    sequence:AppendInterval(TipsMainViewTextMovePauseInterval)
    sequence:SetLoops(-1)
    self.ScrollSequence = sequence
end

function XUiMainRightBottom:OnBtnTerminalClick()
    self.RootUi:OnShowTerminal(true)
end

function XUiMainRightBottom:InitAudioCueEventListener()
    local audioCueEventListener = self.BtnTerminal.transform:GetComponent(typeof(CS.XAudioCueEventListener))
    if not audioCueEventListener then return end
    
    self.AudioCueEffectActiveIds = {}
    self.AudioCueEffectActiveCount = 0
    audioCueEventListener:AddCuePlayListener(handler(self, self.OnAudioCueEffectPlay))
    audioCueEventListener:AddCueStopListener(handler(self, self.OnAudioCueEffectStop))
end

function XUiMainRightBottom:ResetAudioCueEffectState()
    self.AudioCueEffectActiveIds = {}
    self.AudioCueEffectActiveCount = 0
    self.RootUi:StopAnimation("V4P7V‌EasterEgg‌On", true, false)
    self.RootUi:StopAnimation("V4P7V‌EasterEgg‌Off", true, false)
    self.RootUi:ForceSkipToEndAnimation("V4P7V‌EasterEgg‌Off")
    self.V4P7Background.gameObject:SetActiveEx(false)
    if self.EffectSoundGroup then
        self.EffectSoundGroup.gameObject:SetActiveEx(false)
    end
end

function XUiMainRightBottom:OnAudioCueEffectPlay(audioInfo)
    if not audioInfo then
        return
    end

    if self.AudioCueEffectActiveIds[audioInfo.Id] then
        return
    end

    self.AudioCueEffectActiveIds[audioInfo.Id] = true
    self.AudioCueEffectActiveCount = self.AudioCueEffectActiveCount + 1

    if self.AudioCueEffectActiveCount == 1 then
        self.RootUi:StopAnimation("V4P7V‌EasterEgg‌Off", false, false)
        self.V4P7Background.gameObject:SetActiveEx(true)
        self.EffectSoundGroup.gameObject:SetActiveEx(true)
        self.RootUi:PlayAnimation("V4P7V‌EasterEgg‌On")
    end
end

function XUiMainRightBottom:OnAudioCueEffectStop(audioInfo)
    if not audioInfo or not self.AudioCueEffectActiveIds[audioInfo.Id] then
        return
    end

    self.AudioCueEffectActiveIds[audioInfo.Id] = nil
    self.AudioCueEffectActiveCount = self.AudioCueEffectActiveCount - 1

    if self.AudioCueEffectActiveCount <= 0 then
        self.RootUi:StopAnimation("V4P7V‌EasterEgg‌On", false, false)
        self.RootUi:PlayAnimation("V4P7V‌EasterEgg‌Off", function()
            if self.AudioCueEffectActiveCount <= 0 then
                self.V4P7Background.gameObject:SetActiveEx(false)
                self.EffectSoundGroup.gameObject:SetActiveEx(false)
            end
        end)
    end
end

function XUiMainRightBottom:CheckRedPoint()
    XRedPointManager.Check(self.TerminalRedPoint)
end

function XUiMainRightBottom:OnCheckBtnTerminalRedPoint(count)
    if self.BtnTerminal then
        self.BtnTerminal:ShowReddot(count >= 0)
    end
end

return XUiMainRightBottom