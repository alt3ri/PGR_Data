local XUiPanelEnvelopeGuessingCharacterCard = require("XUi/XUiEnvelopeGuessing/XUiPanelEnvelopeGuessingCharacterCard")
---@class XUiEnvelopeGuessingOpenPackage : XLuaUi
---@field private _Card XUiPanelEnvelopeGuessingCharacterCard
local XUiEnvelopeGuessingOpenPackage = XLuaUiManager.Register(XLuaUi, "UiEnvelopeGuessingOpenPackage")

XUiEnvelopeGuessingOpenPackage.OpenType = {
    Clue = {
        GetCharacterConfig = function(openArg, openUi)
            local characterId = openArg.CharacterId
            return openUi._Control:GetCharacterConfig(characterId)
        end
    },
    Specify = {
        GetCharacterConfig = XTool.Id
    }
}

function XUiEnvelopeGuessingOpenPackage:OnStart(openType, openArg, isFastOpen)
    -- 设置参数
    self._OpenType = openType
    self._IsFastOpen = isFastOpen
    self._OpenArg = openArg

    self.PanelAfterOpen.gameObject:SetActiveEx(false)
    self.PanelName.gameObject:SetActiveEx(false)
    self.PanelBubbleDetail.gameObject:SetActiveEx(false)
    self.TxtTips.gameObject:SetActiveEx(false)

    -- 绑定事件
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self.BtnBack.gameObject:SetActiveEx(false)
    self.BtnContinue:AddEventListener(handler(self, self.Close))
    self.BtnStart:AddEventListener(handler(self, self._StartStory))

    self._CharConf = self._OpenType.GetCharacterConfig(openArg, self)
    self.OpenPackageEffectRoot = self.Transform:FindTransform("SafeAreaContentPane"):FindTransform("OpenPackageEffectRoot")  -- 临时
    local cardGo = self.OpenPackageEffectRoot:LoadPrefabEx(self._CharConf.OpenEffectAssetPath)
    self._Card = XUiPanelEnvelopeGuessingCharacterCard.New(cardGo, self, self._CharConf, handler(self, self._OpenPanelAfterOpen))

    if not self._JustOpened then
        self:PlayAnimationWithMask("Start", function()
            -- 快速开包
            if isFastOpen then
                self._Card:ForceOpen(true)
            end
        end)
    end

    -- 设置自动关闭
    self:SetAutoCloseInfo(XMVCA.XEnvelopeGuessing:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiEnvelopeGuessingOpenPackage:_OpenPanelAfterOpen()
    self.TxtName.text = self._CharConf.CharacterName
    self.PanelAfterOpen.gameObject:SetActiveEx(true)
    self.BtnBack.gameObject:SetActiveEx(true)
    self.BtnContinue.gameObject:SetActiveEx(not self._Control:IsAllCharactersOpened())
    self.PanelName.gameObject:SetActiveEx(true)
    self.PanelBubbleDetail.gameObject:SetActiveEx(not self._JustOpened)
    self.TxtTips.gameObject:SetActiveEx(not self._JustOpened)
end

function XUiEnvelopeGuessingOpenPackage:OnEnable()
    if self._JustOpened then
        self:_OpenPanelAfterOpen()
        self._Card:SetAsOpenedAndPlayUnlockAnimation(self._ResumeCount == 1)
    end
end

function XUiEnvelopeGuessingOpenPackage:OnGetLuaEvents()
    return {
        XEventId.EVENT_ENVELOPE_GUIDE_OPEN_PACKAGE,
    }
end

function XUiEnvelopeGuessingOpenPackage:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ENVELOPE_GUIDE_OPEN_PACKAGE then
        if not self._IsFastOpen then
            self._Card:ForceOpen(true)
        end
    end
end

function XUiEnvelopeGuessingOpenPackage:OnReleaseInst()
    return self._ResumeCount or 0
end

function XUiEnvelopeGuessingOpenPackage:OnResume(value)
    self._JustOpened = true
    self._ResumeCount = value + 1
end

function XUiEnvelopeGuessingOpenPackage:_StartStory()
    XMVCA.XEnvelopeGuessing:EnvelopeRecordAvgRequest(self._CharConf.Id, function()
        XDataCenter.MovieManager.PlayMovie(self._CharConf.StoryId)
    end)
end

return XUiEnvelopeGuessingOpenPackage
