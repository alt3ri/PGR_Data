---@class XUiFubenBossSingleDetailAutoFight : XUiNode
---@field TxtScore UnityEngine.UI.Text
---@field TxtCount UnityEngine.UI.Text
---@field BtnAutoFight XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field GridBossAutoFight1 UnityEngine.RectTransform
---@field GridBossAutoFight2 UnityEngine.RectTransform
---@field GridBossAutoFight3 UnityEngine.RectTransform
---@field BtnHelp XUiComponent.XUiButton
---@field TxtScoreDesc UnityEngine.UI.Text
---@field Parent XUiFubenBossSingleDetail
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleDetailAutoFight = XClass(XUiNode, "XUiFubenBossSingleDetailAutoFight")
local XUiFubenBossSingleHeadGrid = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleHeadGrid")

local Pairs = pairs

--region 生命周期
function XUiFubenBossSingleDetailAutoFight:OnStart()
    ---@type XUiFubenBossSingleHeadGrid[]
    self._TeamMemberList = {
        XUiFubenBossSingleHeadGrid.New(self.GridBossAutoFight1, self),
        XUiFubenBossSingleHeadGrid.New(self.GridBossAutoFight2, self),
        XUiFubenBossSingleHeadGrid.New(self.GridBossAutoFight3, self),
    }
    self._IsStaminaEnough = false
    self._IsChallengeCountEnough = false
    self._StageId = nil
    self:_RegisterButtonClicks()
end

--endregion

--region 按钮事件
function XUiFubenBossSingleDetailAutoFight:OnAutoFightSureClick()
    XMVCA.XFubenBossSingle:RequestAutoFight(self._StageId, function(isTip)
        XEventManager.DispatchEvent(XEventId.EVENT_BOSS_SINGLE_GET_REWARD)
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_AUTO_FIGHT, isTip)
    end)
end

function XUiFubenBossSingleDetailAutoFight:OnBtnAutoFightClick()

    local function callAdditionalOp(self)
        if self._BtnAutoFightAdditionalOperation then
            self._BtnAutoFightAdditionalOperation()
        end
    end

    if self._AutoFightPreCheck then
        if not self._AutoFightPreCheck() then
            callAdditionalOp(self)
            return
        end
    end

    if not self._IsStaminaEnough then
        XUiManager.TipText("BossSingleAutoFightDesc7")
        callAdditionalOp(self)
        return
    end

    -- （兼容重置后的自动作战）把今天的三次首通次数消耗 ，再去重置骑士关，再去点自动挑战
    local stageId = self._StageId
    local hasStageRecord, stage = self._Control:HasStageRecord(stageId)
    if hasStageRecord then
        local score = self._Control:GetBossStageScore(stageId)
        if score == 0 then
            self:OnAutoFightSureClick()
        end

        callAdditionalOp(self)
        return
    end

    if not self._IsChallengeCountEnough then
        XUiManager.TipText("BossSingleAutoFightDesc8")
        callAdditionalOp(self)
        return
    end

    local titletext = XUiHelper.GetText("TipTitle")
    local stageData = XMVCA.XFuben:GetStageData(self._StageId)
    local curScore = stageData and stageData.Score or 0
    local contentText = curScore > 0 and XUiHelper.GetText("BossSingleAutoFightDesc11") or
        XUiHelper.GetText("BossSingleAutoFightDesc9")

    XUiManager.DialogTip(titletext, contentText, XUiManager.DialogType.Normal, nil,
        Handler(self, self.OnAutoFightSureClick))

    callAdditionalOp(self)
end

function XUiFubenBossSingleDetailAutoFight:OnBtnCloseClick()
    self:_TipClose()
    self:Close()
end

function XUiFubenBossSingleDetailAutoFight:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", XUiHelper.GetText("BossSingleAutoFightDesc") or "")
end

--endregion

---@param autoFightData XBossSingleStageHistory
function XUiFubenBossSingleDetailAutoFight:Refresh(autoFightData, challengeCount, config)
    self._IsStaminaEnough = true
    self._IsChallengeCountEnough = true
    self._StageId = autoFightData:GetStageId()

    local score = config.Score + self._Control:GetBaseScoreByStageId(self._StageId)
    local curScore = autoFightData:GetScore() or 0
    local autoFightRebate = self._Control:GetAutoFightRebate()
    local scoreDesc = autoFightRebate .. "%"
    
    local autoFightCount = self._Control:GetAutoFightCount()
    -- 设置自动按钮状态
    local allCount = autoFightCount
    local leftCount = autoFightCount - challengeCount

    curScore = math.floor(autoFightRebate * curScore / 100)

    self.TxtScore.text = XUiHelper.GetText("BossSingleAutoFightDesc3", curScore, score)
    self.TxtScoreDesc.text = XUiHelper.GetText("BossSingleAutoFightRateDesc", scoreDesc)
    self.TxtCount.text = XUiHelper.GetText("BossSingleAutoFightDesc4", leftCount, allCount)

    if leftCount <= 0 then
        self._IsChallengeCountEnough = false
    end

    for _, grid in Pairs(self._TeamMemberList) do
        grid:Close()
    end

    for i, characterId in Pairs(autoFightData:GetCharacterList()) do
        if characterId > 0 then
            local grid = self._TeamMemberList[i]
            local maxStamina = self._Control:GetMaxStamina()
            local curStamina = maxStamina - self._Control:GetCharacterChallengeCount(characterId)

            grid:SetCharacterId(characterId)
            grid:Open()

            if curStamina <= 0 then
                self._IsStaminaEnough = false
            end
        end
    end
end

function XUiFubenBossSingleDetailAutoFight:SetBtnAutoFightAdditionalOperation(op)
    self._BtnAutoFightAdditionalOperation = op
end

function XUiFubenBossSingleDetailAutoFight:SetAutoFightPreCheck(check)
    self._AutoFightPreCheck = check
end

--region 私有方法
function XUiFubenBossSingleDetailAutoFight:_TipClose()
    self.Parent:RefreshToggleGroup()
end

function XUiFubenBossSingleDetailAutoFight:_RegisterButtonClicks()
    --在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnAutoFight, self.OnBtnAutoFightClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelpClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnBtnCloseClick, true)

    if self.BtnManuallyFight then
        XUiHelper.RegisterClickEvent(
            self,
            self.BtnManuallyFight,
            self.OnBtnManuallyFightClick,
            true)
    end
end

function XUiFubenBossSingleDetailAutoFight:OnBtnManuallyFightClick()
    self:Close()
    self.Parent:StartManuallyFight()
end


--endregion

return XUiFubenBossSingleDetailAutoFight
