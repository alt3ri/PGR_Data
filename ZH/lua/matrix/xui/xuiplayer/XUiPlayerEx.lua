--============
--新玩家信息界面
--============
local XUiPlayerEx = XLuaUiManager.Register(XLuaUi, "UiPlayer")

function XUiPlayerEx:OnStart()
    self:PlayAnimation("PanelAnimEnable")
    --self:PlayAnimation("PanelPlayerGloryExpEnable")
    self:InitTopButtons()
    self:InitPanelPlayerInfo()
end

function XUiPlayerEx:InitTopButtons()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        self:OnClickBtnMainUi()
    end
    self.BtnAchievement.CallBack = function()
        self:OnClickBtnAchievement()
    end
    self.BtnArchive.CallBack = function()
        self:OnClickBtnArchive()
    end
    self.BtnExhibition.CallBack = function()
        self:OnClickBtnExhibition()
    end
    self.BtnSkinSeries:AddEventListener(function()
        self.PanelPlayerInfoEx:RecordAnimation()
        XMVCA.XFashionSuit:OpenMain()
    end)
end

function XUiPlayerEx:Close()
    if self.IsOpenSetting then
        if self.NeedSave then
            self:CheckSave(function()
                self:Close()
            end)
            return
        end
        self:CloseChildUi("UiPanelSetting")
        self.IsOpenSetting = false
        self.PanelPlayerInfoEx:Open()
    else
        self.Super.Close(self)
    end
end

function XUiPlayerEx:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiPlayerEx:InitPanelPlayerInfo()
    local XUiPanelPlayerInfoEx = require("XUi/XUiPlayer/XUiPanelPlayerInfoEx")
    self.PanelPlayerInfoEx = XUiPanelPlayerInfoEx.New(self.UiPanelPlayerInfo, self)
end

function XUiPlayerEx:OnEnable()
    self.BtnAchievement:ShowReddot(XDataCenter.MedalManager.CheckHaveNewMedal() or XDataCenter.AchievementManager.CheckHasReward())
    self.BtnExhibition:ShowReddot(XDataCenter.ExhibitionManager.CheckNewCharacterReward())
    --IOS提审屏蔽涂装套装入口
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FashionSuit) and not XUiManager.IsHideFunc then
        self.BtnSkinSeries.gameObject:SetActiveEx(true)
        self.BtnSkinSeries:ShowReddot(XMVCA.XFashionSuit:IsRed())
    else
        self.BtnSkinSeries.gameObject:SetActiveEx(false)
    end
end

function XUiPlayerEx:OnDisable()
    
end

function XUiPlayerEx:OnDestroy()
    self.PanelPlayerInfoEx:OnDestroy()
end

function XUiPlayerEx:OnClickBtnAchievement()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PlayerAchievement) then
        self.PanelPlayerInfoEx:RecordAnimation()
        XLuaUiManager.Open("UiAchievementSystem")
    end
end

function XUiPlayerEx:OnClickBtnArchive()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Archive) then
        self.PanelPlayerInfoEx:RecordAnimation()
        XMVCA.XArchive:OpenUiArchiveMain()
    end
end

function XUiPlayerEx:OnClickBtnExhibition()
    -- 如果军团开启时，替代掉原本的剧情展示
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PlotExhibition) then
        XMVCA.XPlotExhibition:OpenMain()
        return
    end
    
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterExhibition) then
        self.PanelPlayerInfoEx:RecordAnimation()
        XLuaUiManager.Open("UiExhibition", true)
    end
end

function XUiPlayerEx:ShowSetting()
    self.PanelPlayerInfoEx:Close()
    self:OpenOneChildUi("UiPanelSetting", self)
    self.UiPanelSetting:InitCollectionWallShow()
    self.UiPanelSetting:UpdateCharacterHead()
    self.IsOpenSetting = true
end

function XUiPlayerEx:CheckSave(cb)
    self.NeedSave = false
    XUiManager.DialogTip(
            CS.XTextManager.GetText("TipTitle"),
            CS.XTextManager.GetText("SaveShowSetting"),
            XUiManager.DialogType.Normal,
            function()
                self.UiPanelSetting.CharacterList = XPlayer.ShowCharacters
                self.UiPanelSetting:InitAppearanceSetting()
                if cb then
                    cb()
                end
            end,
            function()
                self.UiPanelSetting:OnBtnSave()
                if cb then
                    cb()
                end
            end)
end