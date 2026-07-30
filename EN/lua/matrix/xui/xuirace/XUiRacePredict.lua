---@class XUiRacePredict : XLuaUi 单场预测
---@field _Control XRaceControl
---@field _CharacterDetail XUiPanelRaceCharacterDetail
---@field _PredictChoose XUiPanelRaceChoose
---@field _3DCamera XUiPanelRace3DCamera
---@field _CurRound XTableRaceRoundClient
---@field _GuessTabs XUiGridRaceGuessTab[]
local XUiRacePredict = XLuaUiManager.Register(XLuaUi, "UiRacePredict")

local RoundState = XEnumConst.Race.RoundState

function XUiRacePredict:OnAwake()
    self:BindHelpBtn(self.BtnHelp, "RaceSingleGuessHelp")
    self.BtnGuess.CallBack = handler(self, self.OnBtnGuessClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBubbleClose, self.OnBtnBubbleCloseClick)
end

function XUiRacePredict:OnStart(roleId, isMatch, guessId)
    self._SelectRoleId = roleId
    self._SelectGuessId = guessId
    self._IsMatch = isMatch
    if not isMatch then
        self._RoundId = self._Control:GetCurRound()
    end
    self._ActivityConfig = self._Control:GetCurrentConfig()
    self._CharacterDetail = require("XUi/XUiRace/Panel/XUiPanelRaceCharacterDetail").New(self.PanelSkill, self)
    self._PredictChoose = require("XUi/XUiRace/Panel/XUiPanelRaceChoose").New(self.PanelChoose, self)
    self._3DCamera = require("XUi/XUiRace/Panel/XUiPanelRace3DCamera").New(self.UiModelGo.transform, self, XEnumConst.Race.SceneType.Predict)
    self._MatchPredictEndTime = XFunctionManager.GetEndTimeByTimeId(self._ActivityConfig.MatchGuessTime)
    self._GridProjectHeight = self.GridProject.rect.height
    self._LayoutSpaceY = self.PanelProjectLayout.spacing

    self:InitUi()
    self:CountDown()
    self:OnBtnBubbleCloseClick()
    self._3DCamera:LoadOption()
    self:PlayPlatformUp()
end

function XUiRacePredict:OnEnable()
    if self._IsMatch then
        self:InitMatch()
    else
        self:UpdateRound()
    end
end

function XUiRacePredict:OnDestroy()
    self:RemoverHudTimer()
end

function XUiRacePredict:InitUi()
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
end

function XUiRacePredict:UpdateRound()
    self._RoundInfo = self._Control:GetCurRoundInfo()
    if self._RoundInfo.State == XEnumConst.Race.RoundState.End then
        return
    end

    if not self._CurRound or self._RoundInfo.Round.Id ~= self._CurRound.Id then
        -- 显示赛事名称
        if string.IsNilOrEmpty(self._RoundInfo.Round.SubTitle) then
            self.TxtMatchName.text = self._RoundInfo.Round.Name
        else
            self.TxtMatchName.text = string.format("%s·%s", self._RoundInfo.Round.Name, self._RoundInfo.Round.SubTitle)
        end
        -- 显示预测项目
        self:ShowGuseeItem()
    end

    if self._RoundInfo.State == XEnumConst.Race.RoundState.Guess then
        self.TxtTimeLeft.text = XUiHelper.GetText("RaceMatchTimeLeft", XUiHelper.GetTime(self._RoundInfo.LeftTime, XUiHelper.TimeFormatType.CHATEMOJITIMER))
    else
        self.TxtTimeLeft.text = XUiHelper.GetText("RaceGuessBtn3") --预测已结束
    end
    self._CurRound = self._RoundInfo.Round
end

function XUiRacePredict:InitMatch()
    self.TxtMatchName.text = XUiHelper.GetText("RaceMatchGuessRange")
    self:ShowGuseeItem()
end

function XUiRacePredict:UpdateMatch()
    local nowTime = XTime.GetServerNowTimestamp()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self._ActivityConfig.MatchGuessTime)
    if endTime >= nowTime then
        self.TxtTimeLeft.text = XUiHelper.GetText("RaceMatchTimeLeft", XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.CHATEMOJITIMER))
    else
        self.TxtTimeLeft.text = XUiHelper.GetText("RaceMatchTimePlaying")
    end
end

--region 预测项目

function XUiRacePredict:ShowGuseeItem()
    self._GuessTabs = {}
    local buttons = {}
    local guesses = self._IsMatch and self._ActivityConfig.MatchGuess or self._RoundInfo.Etcd.Guess
    table.sort(guesses, function(a, b)
        local aCfg = self._Control:GetRaceGuessById(a)
        local bCfg = self._Control:GetRaceGuessById(b)
        if aCfg.Priority ~= bCfg.Priority then
            return aCfg.Priority > bCfg.Priority
        end
        return aCfg.Id < bCfg.Id
    end)
    XUiHelper.RefreshCustomizedList(self.GridProject.parent, self.GridProject, #guesses, function(i, go)
        ---@type XUiGridRaceGuessTab
        local tab = require("XUi/XUiRace/Grid/XUiGridRaceGuessTab").New(go, self)
        tab:SetGuessId(guesses[i])
        table.insert(buttons, tab.GridProject)
        table.insert(self._GuessTabs, tab)
    end)
    self.PanelProjectGroup:Init(buttons, function(index)
        self:OnSelectGuessTab(index)
    end)
    if self._SelectGuessId then
        local idx = table.indexof(guesses, self._SelectGuessId)
        self.PanelProjectGroup:SelectIndex(idx)
        -- 定位
        if idx > 1 then
            local transLayout = self.PanelProjectLayout.transform
            CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(transLayout)
            local contentH = self.ListProject.rect.height
            local scrollH = transLayout.rect.height
            if scrollH > contentH then
                local num = idx - 1
                local posX = transLayout.anchoredPosition.x
                local offsetY = num * self._GridProjectHeight + (num - 1) * self._LayoutSpaceY
                self.PanelProjectLayout.transform.anchoredPosition = CS.UnityEngine.Vector2(posX, offsetY)
            end
        end
    else
        self.PanelProjectGroup:SelectIndex(1)
    end
    self._SelectGuessId = nil
end

function XUiRacePredict:OnSelectGuessTab(i)
    local tab = self._GuessTabs[i]
    if self._CurGuessId == tab:GetGuessId() then
        return
    end
    local oldGuessId = self._CurGuessId
    self._CurGuessId = tab:GetGuessId()
    self._IsTabRole = tab:IsRole()
    self.RImgRoleDetailBg.gameObject:SetActiveEx(self._IsTabRole)
    -- 显示选项列表
    self._PredictChoose:ShowList(self._IsTabRole, self._CurGuessId)
    self._Control:SetEnterGuess(self._RoundId, self._CurGuessId)
    --动效
    for k, v in pairs(self._GuessTabs) do
        local guessId = v:GetGuessId()
        if not oldGuessId or guessId == oldGuessId or guessId == self._CurGuessId then
            v:PlayTween()
        end
    end
end

function XUiRacePredict:UpdateGuessTabState()
    for _, tab in pairs(self._GuessTabs) do
        tab:Update()
    end
    self:UpdatePredictBtn()
end

---点击选项
---@param id number 角色Id/选项索引
function XUiRacePredict:OnClickPredictOption(isRole, id)
    self:RemoverHudTimer()
    if isRole then
        self._CurRoleId = id
        self._CurOptionId = 0
        self:ShowRoleDetail(id)
        self.PanelRoleName.gameObject:SetActiveEx(true)
        self.TxtMemberName.text = self._Control:GetRaceCharacterById(id).Name
        self.PanelFail.gameObject:SetActiveEx(self:IsCharacterObsoleteNow(id))
        self._3DCamera:LookAt(id)
        self._HudTimer = XScheduleManager.ScheduleForever(function()
            self:UpdateHud()
        end, 10)
        self._3DCamera:PlayRoleEffect()
    else
        self._CurRoleId = 0
        self._CurOptionId = id
        self.PanelRoleName.gameObject:SetActiveEx(false)
        self:UpdateHud()
        self._3DCamera:ShowOption()
        self._3DCamera:PlayOptionEffect()
    end
    self:UpdatePredictBtn()
    local rate = self:GetVotingRate(id)
    local rateStr
    if XTool.IsNumberValid(rate) then
        rateStr = string.format("%s%%", rate)
    else
        rateStr = "-%"
    end
    self.TxtSupport.text = XUiHelper.GetText("RaceChooseSupport", rateStr)
end

function XUiRacePredict:UpdatePredictBtn()
    local id = XTool.IsNumberValid(self._CurRoleId) and self._CurRoleId or self._CurOptionId
    if self:IsInGuessTime() then
        local oldId = self:GetGuessProjectOption(self._CurGuessId)
        if id == oldId then
            -- 已预测
            self.BtnGuess:SetNameByGroup(0, XUiHelper.GetText("RaceGuessBtn2"))
        else
            -- 可以预测
            self.BtnGuess:SetNameByGroup(0, XUiHelper.GetText("RaceGuessBtn1"))
        end
        self.BtnGuess:SetButtonState(XUiButtonState.Normal)
    else
        -- 预测时间已结束
        self.BtnGuess:SetNameByGroup(0, XUiHelper.GetText("RaceGuessBtn3"))
        self.BtnGuess:SetButtonState(XUiButtonState.Disable)
    end
end

function XUiRacePredict:RemoverHudTimer()
    if self._HudTimer then
        XScheduleManager.UnSchedule(self._HudTimer)
        self._HudTimer = nil
    end
end

function XUiRacePredict:IsInGuessTime()
    if self._IsMatch then
        return XFunctionManager.CheckInTimeByTimeId(self._ActivityConfig.MatchGuessTime)
    end
    local roundInfo = self._Control:GetCurRoundInfo()
    return roundInfo.State == XEnumConst.Race.RoundState.Guess
end

--endregion

function XUiRacePredict:ShowRoleDetail(roleId)
    self._CharacterDetail:Open()
    self._CharacterDetail:ShowDetail(roleId)
end

function XUiRacePredict:CloseRoleDetail()
    self._CharacterDetail:Close()
end

function XUiRacePredict:CountDown()
    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
        -- 不在预测时间内 踢回主界面
        if not self:IsInGuessTime() then
            self._Control:OpenTip("RaceGuessFailTip")
            self:Close()
            return
        end
        
        if self._IsMatch then
            self:UpdateMatch()
        else
            self:UpdateRound()
        end
    end, nil, 0)
end

-- 更新HUD位置
function XUiRacePredict:UpdateHud()
    if not self._IsTabRole then
        self.PanelChoice.gameObject:SetActiveEx(false)
        return
    end

    local roleId = self._Control:GetGuessProjectOption(self._RoundId, self._CurGuessId)
    self.PanelChoice.gameObject:SetActiveEx(roleId == self._CurRoleId)
end

function XUiRacePredict:OnBtnBubbleCloseClick()
    self.BtnBubbleClose.gameObject:SetActiveEx(false)
    self._CharacterDetail:OnCloseDetail()
end

function XUiRacePredict:OnBtnGuessClick()
    local curChooseId = self:GetGuessProjectOption(self._CurGuessId)
    if XTool.IsNumberValid(curChooseId) and (curChooseId == self._CurRoleId or curChooseId == self._CurOptionId) then
        -- 已预测
        return
    end
    if self._IsMatch and self._Control:IsCharacterObsoleteNow(self._CurRoleId) then
        -- 预测已被淘汰的角色
        self._Control:OpenPopup("TipTitle", "RaceGuessObsolete", nil, handler(self, self.RequestGuess))
        return
    end
    if not self:IsInGuessTime() then
        -- 预测时间已过
        self._Control:OpenTip("RaceGuessFailTip")
        return
    end
    -- 预测成功
    self:RequestGuess()
end

function XUiRacePredict:RequestGuess()
    if self._IsMatch then
        self._Control:RequestGuessGlobal(self._CurGuessId, self._CurRoleId, self._CurOptionId, function()
            self:UpdateGuessTabState()
            self._Control:OpenTip("RaceGuessSuccessTip")
        end)
    else
        self._Control:RequestGuessSingleRound(self._CurGuessId, self._CurRoleId, self._CurOptionId, function()
            self:UpdateGuessTabState()
            self._Control:OpenTip("RaceGuessSuccessTip")
        end)
    end
end

function XUiRacePredict:GetVotingRate(id)
    return self._Control:GetVotingRate(self._RoundId, self._CurGuessId, id)
end

function XUiRacePredict:IsCharacterObsoleteNow(roleId)
    return self._IsMatch and self._Control:IsCharacterObsoleteNow(roleId)
end

function XUiRacePredict:GetGuessProjectOption(guessId)
    return self._Control:GetGuessProjectOption(self._RoundId, guessId)
end

function XUiRacePredict:IsPredict(guessId)
    return self._Control:IsPredict(self._RoundId, guessId)
end

function XUiRacePredict:PlayPlatformUp()
    local platform = self.UiSceneInfo.Transform:FindTransform("Racing_BanjiangtaiAni")
    if XTool.UObjIsNil(platform) then
        return
    end
    ---@type UnityEngine.Animator
    local animator = platform:GetComponent(typeof(CS.UnityEngine.Animator))
    if XTool.UObjIsNil(animator) then
        return
    end
    animator:Play("FloorUpLoop")
end

return XUiRacePredict