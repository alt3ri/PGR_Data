local XUiPunishaarFightMainPanelAsset = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiCommonTop/XUiPunishaarFightMainPanelAsset")

---@class XUiPunishaarStagePause : XLuaUi
---@field _Control XPunishaarControl
---@field TxtStageProgress UnityEngine.UI.Text
---@field BtnEndMatch XUiComponent.XUiButton   提前结束（放弃当局，不保留存档）
---@field BtnSaveMatch XUiComponent.XUiButton  保存并退出（存档保留，可继续）
---@field PanelAsset UnityEngine.RectTransform
local XUiPunishaarStagePause = XLuaUiManager.Register(XLuaUi, "UiPunishaarStagePause")

function XUiPunishaarStagePause:OnAwake()
    self:InitComponents()
end

function XUiPunishaarStagePause:InitComponents()
    self.BtnEndMatch:AddEventListener(handler(self, self.OnBtnEndMatchClick))
    self.BtnSaveMatch:AddEventListener(handler(self, self.OnBtnSaveMatchClick))
    self.BtnClose:AddEventListener(handler(self, self.Close))

    ---@type XUiPunishaarFightMainPanelAsset
    self.PanelAsset = XUiPunishaarFightMainPanelAsset.New(self.PanelAsset, self)
end

function XUiPunishaarStagePause:OnStart()
    self.PanelAsset:Open()
    self:Refresh()

    local fightControl = self._Control.GameControl and self._Control.GameControl.FightControl
    if fightControl then
        fightControl:DispatchEvent(fightControl.EventIds.OnPause)
    end
end

function XUiPunishaarStagePause:OnEnable()
end

function XUiPunishaarStagePause:OnDisable()
end

function XUiPunishaarStagePause:OnDestroy()
    local fightControl = not self.IsExit and self._Control.GameControl and self._Control.GameControl.FightControl
    if fightControl then
        fightControl:DispatchEvent(fightControl.EventIds.OnResume)
    end
end

function XUiPunishaarStagePause:Refresh()
    local stageId = self._Control:GetCurrentStageId() or 0
    local stageName = XMVCA.XPunishaar:GetCfgStageNameByStageId(stageId)
    local nodeIndex = self._Control:GetCurrentNodeIndex() or 0

    self.TxtStageProgress.text = XUiHelper.FormatTextEx(XMVCA.XPunishaar:GetClientStringByKey("FullStageProgressShow"), stageName, nodeIndex)
end

--- debug 模式判定（测试工具路径开战时 RunControl._IsTestMode=true）。
--- 暂停弹窗两按钮在 debug 下统一退出当前界面，不走服务端 QuitStage / ExitRun（Remove）。
--- 仅 Editor 环境认 _IsTestMode（非 Editor 静默返 false，走正常服务端路径——可能是 bug 误入）
---@return boolean
function XUiPunishaarStagePause:_IsTestMode()
    local rc = self._Control and self._Control.GameControl and self._Control.GameControl.RunControl
    return rc ~= nil and rc._IsTestMode == true and XMain.IsWindowsEditor
end

--- debug 统一退出：先关本弹窗（栈顶），回调里关 FightMain（此时已为栈顶，Close 可走栈）。
--- IsExit 置 true 跳过 OnDestroy 的 OnResume 派发（FightControl 随 FightMain 关闭释放，无需 Resume）。
function XUiPunishaarStagePause:_DebugExit()
    self.IsExit = true
    XLuaUiManager.CloseWithCallback(self.Name, function()
        XLuaUiManager.Close("UiPunishaarFightMain")
    end)
end

--- 保存并退出（暂离）：先请求 AwayStage 存档，成功后再关 FightMain + 本弹窗。
--- 对齐 OnBtnEndMatchClick（QuitStage 先请求成功再 ExitRun）范式：原直接 ExitRun 不走服务端，
--- 导致服务端无存档记录、下次无法 ContinueStage 续局。
function XUiPunishaarStagePause:OnBtnSaveMatchClick(eventData)
    if self:_IsTestMode() then
        self:_DebugExit()
        return
    end
    local stageId = self._Control:GetCurrentStageId() or 0
    self._Control:AwayStage(stageId, function(success)
        if not success then return end
        self.IsExit = true
        self._Control.GameControl.RunControl:ExitRun()
        self:Close()
    end)
end

--- 提前结束：放弃当局（QuitStage）。成功后关闭本弹窗，打开整局结算界面。
--- FightMain 作 #66 持久基底保持打开（不 ExitRun），ExitRun 移至 ChallengeSettlement:_OnBtnExit 退出时。
--- 对齐正常整局结束路径（FinishFight）：不在此清 run 数据，_CurrentStage 留给结算界面的
--- "重新挑战"（_OnBtnRestart 需 GetCurrentStageId）；清理由结算界面按钮各自触发。
function XUiPunishaarStagePause:OnBtnEndMatchClick(eventData)
    if self:_IsTestMode() then
        self:_DebugExit()
        return
    end
    self._Control:QuitStage(function(settleInfo)
        if not settleInfo then return end
        self.IsExit = true
        -- 不 ExitRun：FightMain 作 #66 持久基底贯穿结算期，ExitRun 移至 ChallengeSettlement:_OnBtnExit
        -- Close StagePause 先关（FightMain 基底盖住），再 Open ChallengeSettlement（Pop 叠 FightMain）
        self:Close()
        XLuaUiManager.Open("UiPunishaarChallengeSettlement", settleInfo)
    end)
end

return XUiPunishaarStagePause
