local XUiGachaFashionSelfChoiceDialog = XLuaUiManager.Register(XLuaUi, "UiGachaFashionSelfChoiceDialog")

function XUiGachaFashionSelfChoiceDialog:OnAwake()
    self.GridRewardDic = {}
    self:InitButton()
    
    -- 二次弹窗cd，不能让玩家点太快
    self.EnableClickBtnYes = false
    local cdTime = CS.XGame.ClientConfig:GetInt("XUiGachaFashionSelfChoiceDialogConfirmCD")
    self.CDTime = cdTime
    self.BtnYes:SetNameByGroup(1, string.format("%dS", self.CDTime / XScheduleManager.SECOND))
    self.BtnYes:SetDisable(true)
    self.Timer = XScheduleManager.ScheduleForever(function() 
        self.CDTime = self.CDTime - XScheduleManager.SECOND

        if self.CDTime < 0 then
            self.EnableClickBtnYes = true
            self.BtnYes:SetDisable(false)
            self:StopTimer()
        else
            self.BtnYes:SetNameByGroup(1, string.format("%dS", self.CDTime / XScheduleManager.SECOND))
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiGachaFashionSelfChoiceDialog:InitButton()
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end
    self.BtnYes.CallBack = function() self:OnBtnYesClick() end
    self.BtnCancel.CallBack = function() self:Close() end
end

function XUiGachaFashionSelfChoiceDialog:OnBtnYesClick()
    if not self.EnableClickBtnYes then
        XUiManager.TipMsg(CS.XTextManager.GetText("ConfirmSpeedLimit"))
        return
    end

    if self.ConfirmCb then
        self.ConfirmCb(self.GachaId)
    end
    self:Close()
end

function XUiGachaFashionSelfChoiceDialog:OnStart(gachaId, isAllGet, confirmCb)
    self.GachaId = gachaId
    self.ConfirmCb = confirmCb

    ---@type XTableGachaFashionSelfChoiceResources
    local gachaConfig = XGachaConfigs.GetAllConfigs(XGachaConfigs.TableKey.GachaFashionSelfChoiceResources)[gachaId]
    local fashionId = gachaConfig.SpecialRewardTemplateIds[1] -- 第1个默认是涂装id(写死)
    local fashionConfig = XFashionConfigs.GetFashionTemplate(fashionId)

    local charId = fashionConfig.CharacterId
    local name = XMVCA.XCharacter:GetCharacterName(charId)
    local tradeName = XMVCA.XCharacter:GetCharacterTradeName(charId)
    local charName = XUiHelper.GetText("CharacterFullName2", name, tradeName)
    local text = nil
    if isAllGet then
        text = XUiHelper.FormatText(XGachaConfigs.GetClientConfig('GachaFashionSelfChoiceDialogText1'), charName, gachaConfig.Desc)
    else
        text = XUiHelper.FormatText(XGachaConfigs.GetClientConfig('GachaFashionSelfChoiceDialogText2'), charName, gachaConfig.Desc)
    end
    self.TxtInfo.text = XUiHelper.ConvertLineBreakSymbol(text)

    -- 奖励
    local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
    for k, templateId in ipairs(gachaConfig.SpecialRewardTemplateIds) do
        local grid = self.GridRewardDic[k]
        if not grid then
            local ui = (k == 1) and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.Grid256New.parent)
            grid = XUiGridCommon.New(self, ui)
            self.GridRewardDic[k] = grid
        end

        grid:Refresh({TemplateId = templateId}, nil, nil, nil, isAllGet and -1 or 1)
    end
end

function XUiGachaFashionSelfChoiceDialog:OnDestroy()
    self:StopTimer()
end

function XUiGachaFashionSelfChoiceDialog:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end