---@class UiTheatre5ChooseCharacter: XLuaUi
---@field private _Control XTheatre5Control
local UiTheatre5ChooseCharacter = XLuaUiManager.Register(XLuaUi, 'UiTheatre5ChooseCharacter')
local XUiComTheatre5ChooseCharacter = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/XUiComTheatre5ChooseCharacter')
local XUiComTheatre5PVPChooseCharacter = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/PVP/XUiComTheatre5PVPChooseCharacter')
local XUiComTheatre5PVEChooseCharacter = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/PVE/XUiComTheatre5PVEChooseCharacter')
local XUiTheatre5CharacterTeaching = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/PVE/XUiTheatre5CharacterTeaching')

function UiTheatre5ChooseCharacter:OnAwake()
    self.BtnBack.CallBack = handler(self, self.OnBtnBackClickEvent)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    self:BindHelpBtn(self.BtnHelp, 'Theatre5')

    -- v3.8 新增跳转时装
    self.BtnCostume = self.BtnCostume or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/DetailRoot/BtnCostume", "XUiButton")
    if self.BtnCostume then
        XUiHelper.RegisterClickEvent(self, self.BtnCostume, self.OnClickSkipFashion)
    end
end

function UiTheatre5ChooseCharacter:OnStart(gameMode)
    self:ResetShow()
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_PVE_OPEN_OR_CLOSE_CHAT, self.OnPveOpenOrCloseChat, self)
    if gameMode == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        ---@type XUiComTheatre5ChooseCharacter
        self.ComChooseCharacter = XUiComTheatre5PVPChooseCharacter.New(self.GameObject, self)
        self.ComChooseCharacter:Open()
    elseif gameMode == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
        ---@type XUiComTheatre5PVEChooseCharacter
        self.ComChooseCharacter = XUiComTheatre5PVEChooseCharacter.New(self.GameObject, self)
        self.ComChooseCharacter:Open()
    end

    self.ComChooseCharacter:Init()

    if gameMode == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
        --教学线逻辑放在最后面，要做特殊梳理
        ---@type XUiTheatre5CharacterTeaching
        self.CharacterTeaching = XUiTheatre5CharacterTeaching.New(self.GameObject, self)
        self.CharacterTeaching:Open()
    end
end

function UiTheatre5ChooseCharacter:OnEnable()
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_GUIDE_THEATRE5_RETURN_MAIN, self.PlayReturnMainGuide, self)
    self:PVEStoryNodeCheck()
end

function UiTheatre5ChooseCharacter:OnDisable()
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_GUIDE_THEATRE5_RETURN_MAIN, self.PlayReturnMainGuide, self)
end

function UiTheatre5ChooseCharacter:OnPveOpenOrCloseChat(isOpen, characters)
    local enable = not isOpen
    if self.SafeAreaContentPane then
        self.SafeAreaContentPane.gameObject:SetActiveEx(enable)
    end

    --教学线没有角色，不操作对话对角色显隐
    local isTeaching = self._Control.PVEControl:IsInTeachingStoryLine()
    if isTeaching then
        return
    end

    if not characters then
        --不配角色，就对话时全部隐藏
        characters = {}
    end
    local operateCharacters = {}
    local characterCfgs = self._Control:GetTheatre5CharacterCfgs()
    for _, cfg in pairs(characterCfgs) do
        local operate = true
        for _, characterId in pairs(characters) do
            if cfg.Id == characterId then
                operate = false
                break
            end
        end
        if operate then
            table.insert(operateCharacters, cfg.Id)
        end
    end
    --打开时需要隐藏的角色，或关闭时需要显示的角色
    self.ComChooseCharacter:SetCharactersVisible(operateCharacters, enable)
end

function UiTheatre5ChooseCharacter:PVEStoryNodeCheck()
    local mode = self._Control:GetCurPlayingMode()
    if mode ~= XMVCA.XTheatre5.EnumConst.GameMode.PVE then
        return
    end
    --先触发ending
    local isTrigger = self._Control.FlowControl:CheckEndingTrigger()
    if isTrigger then
        return
    end

    --再触发对话    
    local success = self._Control.FlowControl:CheckChatTrigger(XMVCA.XTheatre5.EnumConst.ChatTriggerType.UIPanel, self.Name, function()
        if self.SafeAreaContentPane then
            self.SafeAreaContentPane.gameObject:SetActiveEx(true)
        end
    end)
    if success and self.SafeAreaContentPane then
        self.SafeAreaContentPane.gameObject:SetActiveEx(false)
    end

end

function UiTheatre5ChooseCharacter:ResetShow()
    -- 集中隐藏分散的非通用UI，在各自组件里按需显示
    if self.BtnRank then
        self.BtnRank.gameObject:SetActiveEx(false)
    end

    if self.PanelCommonStory then
        self.PanelCommonStory.gameObject:SetActiveEx(false)
    end

    if self.BtnDeduction then
        self.BtnDeduction.gameObject:SetActiveEx(false)
    end

    if self.BtnTalk then
        self.BtnTalk.gameObject:SetActiveEx(false)
    end

    if self.BtnAVG then
        self.BtnAVG.gameObject:SetActiveEx(false)
    end

    if self.BtnReward then
        self.BtnReward.gameObject:SetActiveEx(false)
    end

    if self.PanelClue then
        self.PanelClue.gameObject:SetActiveEx(false)
    end
end

function UiTheatre5ChooseCharacter:OnBtnBackClickEvent()
    if self.ComChooseCharacter:CheckIsShowDetail() then
        self.ComChooseCharacter:SwitchToFullView()
    else
        self._Control:ReturnTheatre5Main()
    end
end

function UiTheatre5ChooseCharacter:PlayReturnMainGuide()
    self._Control:ReturnTheatre5Main()
end

function UiTheatre5ChooseCharacter:OnDestroy()
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_PVE_OPEN_OR_CLOSE_CHAT, self.OnPveOpenOrCloseChat, self)
end

function UiTheatre5ChooseCharacter:OnClickSkipFashion()
    -- 跳转到时装
    if self._SkipId and self._SkipId > 0 then
        if XFunctionManager.IsCanSkipCheckTime(self._SkipId) then
            XFunctionManager.SkipInterface(self._SkipId)
        else
            XUiManager.TipText("Theatre5FashionOutOfDate")
        end
    else
        XLog.Error("[UiTheatre5ChooseCharacter] skipId有问题:" .. tostring(self._SkipId))
    end
end

function UiTheatre5ChooseCharacter:SetSkipId(skipId)
    self._SkipId = skipId
    if not skipId or skipId <= 0 then
        self.BtnCostume.gameObject:SetActiveEx(false)
    else
        if XFunctionManager.IsCanSkipCheckTime(skipId) then
            self.BtnCostume.gameObject:SetActiveEx(true)
        else
            self.BtnCostume.gameObject:SetActiveEx(false)
        end
    end
end

return UiTheatre5ChooseCharacter