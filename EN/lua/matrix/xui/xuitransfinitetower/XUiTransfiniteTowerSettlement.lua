---超限启航·每层战斗胜利结算界面（复用超限连战结算 UI 结构 + 新增累计时间/下一层提示节点）
---与 UiTransfiniteTowerLastSettlement（15层MVP荣誉结算）是不同界面：本界面是每层通用胜利结算。
---@class XUiTransfiniteTowerSettlement : XLuaUi
---@field _Control XTransfiniteTowerControl
---@field TxtWinNumber UnityEngine.UI.Text
---@field PanelBattleTime UnityEngine.RectTransform
---@field TxtBattelTime UnityEngine.UI.Text
---@field TxtNew UnityEngine.GameObject
---@field PanelClearTime UnityEngine.RectTransform
---@field TxtClearTime UnityEngine.UI.Text
---@field PanelNextTip UnityEngine.RectTransform
---@field TxtNextTip UnityEngine.UI.Text
---@field BtnAgain XUiComponent.XUiButton
---@field BtnContinue XUiComponent.XUiButton
---@field BtnBack XUiComponent.XUiButton
local XUiTransfiniteTowerSettlement = XLuaUiManager.Register(XLuaUi, "UiTransfiniteTowerSettlement")

function XUiTransfiniteTowerSettlement:OnAwake()
    self.BtnAgain:AddEventListener(handler(self, self.OnClickAgain))
    self.BtnContinue:AddEventListener(handler(self, self.OnClickContinue))
    self.BtnBack:AddEventListener(handler(self, self.OnClickBack))
    self:SetMouseVisible()
end

---照抄模板：PC 端结算界面强制显示鼠标
function XUiTransfiniteTowerSettlement:SetMouseVisible()
    if CS.XFight.Instance and CS.XFight.Instance.InputSystem then
        local inputKeyboard = CS.XFight.Instance.InputSystem:GetDevice(typeof(CS.XInputKeyboard))
        inputKeyboard.HideMouseEvenByDrag = false
    end
    CS.UnityEngine.Cursor.lockState = CS.UnityEngine.CursorLockMode.None
    CS.UnityEngine.Cursor.visible = true
end

---@param towerCfgId number 章节塔配置id
---@param stageCfgId number 本层关卡配置id
---@param order number 本层层序号（战斗结算下发）
---@param spendTime number 本层通关用时（秒，战斗结算下发）
function XUiTransfiniteTowerSettlement:OnStart(towerCfgId, stageCfgId, order, spendTime)
    self._TowerCfgId = towerCfgId
    self._StageCfgId = stageCfgId
    self._Order = order or 0
    self._SpendTime = spendTime or 0
end

function XUiTransfiniteTowerSettlement:OnEnable()
    self:Refresh()
    CS.XInputManager.SetCurInputMap(CS.XInputMapId.System)
    CS.XJoystickLSHelper.ForceResponse = true
end

function XUiTransfiniteTowerSettlement:OnDisable()
    CS.XJoystickLSHelper.ForceResponse = false
end

--region 刷新

function XUiTransfiniteTowerSettlement:Refresh()
    self:RefreshWin()
    self:RefreshStageTime()
    self:RefreshTotalTime()
    self:RefreshNextTip()
    self:RefreshButtons()
end

---连胜数（= 本层层序号）
function XUiTransfiniteTowerSettlement:RefreshWin()
    self.TxtWinNumber:TextToSprite(self._Order)
end

---单层通关时间 + 新纪录：仅 15 层塔显示
function XUiTransfiniteTowerSettlement:RefreshStageTime()
    local isShow = self._Control:IsSettleShowStageTime(self._TowerCfgId)
    self.PanelBattleTime.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtBattelTime.text = XUiHelper.GetTime(self._SpendTime)
        self.TxtNew.gameObject:SetActiveEx(self._Control:IsSettleNewRecord(self._StageCfgId, self._SpendTime))
    end
end

---累计通关时间：仅 15 层塔的最后一层显示
function XUiTransfiniteTowerSettlement:RefreshTotalTime()
    local isShow = self._Control:IsSettleShowStageTime(self._TowerCfgId)
        and self._Control:IsSettleFinalStage(self._TowerCfgId, self._StageCfgId)
    self.PanelClearTime.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtClearTime.text = XUiHelper.GetTime(
            self._Control:GetSettleTotalClearTime(self._TowerCfgId, self._SpendTime))
    end
end

---下一层提示：三层教学塔不显示；其余有词缀 / 队伍需求变化则显示，都无则隐藏
function XUiTransfiniteTowerSettlement:RefreshNextTip()
    local tipKey
    if not self._Control:IsTeachTower(self._TowerCfgId) then
        if self._Control:IsNextStageHasTrait(self._StageCfgId) then
            tipKey = "TransfiniteTowerSettleNextTrait"
        elseif self._Control:IsNextStageTeamChange(self._StageCfgId) then
            tipKey = "TransfiniteTowerSettleNextTeamChange"
        end
    end
    local isShow = tipKey ~= nil
    self.PanelNextTip.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtNextTip.text = XUiHelper.GetText(tipKey)
    end
end

---按钮：3/8 层塔仅 BtnContinue；15 层塔 BtnAgain + BtnContinue；最后一层 BtnContinue 文案变【结算】
function XUiTransfiniteTowerSettlement:RefreshButtons()
    self.BtnAgain.gameObject:SetActiveEx(self._Control:IsSettleShowBtnAgain(self._TowerCfgId))
    if self._Control:IsSettleFinalStage(self._TowerCfgId, self._StageCfgId) then
        self.BtnContinue:SetNameByGroup(0, XUiHelper.GetText("TransfiniteSettle"))
    end
end

--endregion

--region 按钮回调

function XUiTransfiniteTowerSettlement:OnClickAgain()
    self._Control:SettleRechallenge(self._TowerCfgId, self._StageCfgId)
end

function XUiTransfiniteTowerSettlement:OnClickContinue()
    if self._Control:IsSettleFinalStage(self._TowerCfgId, self._StageCfgId) then
        if self._Control:IsTeachTower(self._TowerCfgId) then
            self:EnterFinalSettle()
        else
            local titleKey = "TransfiniteTowerSettlementTitle"
            local contentKey = "TransfiniteTowerSettlementContent"
            XUiManager.DialogTip(XUiHelper.GetText(titleKey), XUiHelper.GetText(contentKey),
                    XUiManager.DialogType.Normal, nil, handler(self, self.EnterFinalSettle))
        end
    else
        self._Control:SettleChallengeNext(self._TowerCfgId, self._StageCfgId)
    end
end

function XUiTransfiniteTowerSettlement:EnterFinalSettle()
    self._Control:EnterFinalSettle(self._TowerCfgId)
end

---返回：二次确认是否保存记录（保存扣体力），保存/取消都退回选关界面
function XUiTransfiniteTowerSettlement:OnClickBack()
    XUiManager.DialogTip(nil, XUiHelper.GetText("TransfiniteTowerSettleSaveConfirm"),
        nil, nil, handler(self, self.OnBackSaveConfirm), nil, handler(self, self.OnBackNoSave))
end

function XUiTransfiniteTowerSettlement:OnBackSaveConfirm()
    self._Control:SettleSaveAndExit(self._TowerCfgId, self._StageCfgId)
end

function XUiTransfiniteTowerSettlement:OnBackNoSave()
    self._Control:SettleExitNoSave(self._TowerCfgId, self._StageCfgId)
end

--endregion

return XUiTransfiniteTowerSettlement
