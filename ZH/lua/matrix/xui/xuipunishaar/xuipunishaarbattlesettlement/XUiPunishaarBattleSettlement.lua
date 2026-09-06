local XUiPunishaarFightMainPanelAsset = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiCommonTop/XUiPunishaarFightMainPanelAsset")

---
---@class XUiPunishaarBattleSettlement: XLuaUi
---@field protected _Control
---@field BtnConfirm XUiComponent.XUiButton 确认按钮
---@field PanelRewardList @奖励父节点
---@field GridReward @奖励UI
---@field GroupControl XUiComponent.XUiGroupControl 胜负状态控制器（Win/Lose）+ 文本组0=tips #69
---@field PanelAsset UnityEngine.RectTransform 资源显示（金币/耐久，复用 PanelAsset 组件）
local XUiPunishaarBattleSettlement = XLuaUiManager.Register(XLuaUi, "UiPunishaarBattleSettlement")

local XUiGridSettleReward = require("XUi/XUiPunishaar/XUiPunishaarBattleSettlement/XUiGridSettleReward")

local UiState = {
    Win = "Win",
    Lose = "Lose",
}

--region Ui生命周期

function XUiPunishaarBattleSettlement:OnAwake()
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))

    -- 保底判空：PanelAsset 引用未挂时跳过，不影响奖励/结算主流程
    if self.PanelAsset then
        ---@type XUiPunishaarFightMainPanelAsset
        self.PanelAsset = XUiPunishaarFightMainPanelAsset.New(self.PanelAsset, self)
    end

    self.GridReward.gameObject:SetActiveEx(false)
end

function XUiPunishaarBattleSettlement:OnStart(isWin, rewardList, onConfirm, hasRemedy, durabilityDelta)
    self._OnConfirm = onConfirm
    -- 耐久扣减量（FinishFight 算好传入：失败+扣减才 >0；UI 层合并显示，不写 Model）
    self._DurabilityDelta = durabilityDelta or 0
    self.GroupControl:ChangeGroup(isWin and UiState.Win or UiState.Lose)
    -- 文本组0=tips：胜利固定配置；失败按是否有补强商店分两个配置（hasRemedy 由 FinishFight 传）#69
    local tipsKey
    if isWin then
        tipsKey = "BattleSettleWinTips"
    else
        tipsKey = hasRemedy and "BattleSettleLoseRemedyTips" or "BattleSettleLoseTips"
    end
    self.GroupControl:SetText(0, XMVCA.XPunishaar:GetClientStringByKey(tipsKey) or "")

    if self.PanelAsset then
        self.PanelAsset:Open()
    end

    -- 奖励展示：rewardList 参数 Proto 不带（恒 nil），改拉 Model 缓存（NotifyPunishaarRewardResult 下发的 RewardGoodsList）
    self:_RefreshRewardList()
end

--- 刷新奖励列表：拉 Model 缓存，按 RewardType 实例化 grid 展示
function XUiPunishaarBattleSettlement:_RefreshRewardList()
    local rewardGoodsList = (self._Control and self._Control:GetLastRewardGoodsList()) or {}
    -- 追加耐久扣减项（UI 层合并，不写 Model，不依赖 Notify/Response 时序）。
    -- 失败+扣减才显；Amount=-delta，grid 走 else 分支 tostring 显 "-1"。
    -- 服务端失败 reward（如补偿金币）仍保留显示，耐久项追加到末尾。
    if self._DurabilityDelta and self._DurabilityDelta > 0 then
        local list = {}
        for i = 1, #rewardGoodsList do
            list[i] = rewardGoodsList[i]
        end
        list[#list + 1] = {
            RewardType = XMVCA.XPunishaar.EnumConst.RewardType.Durability,
            Amount = -self._DurabilityDelta,
        }
        rewardGoodsList = list
    end
    if #rewardGoodsList == 0 then
        if self.GridReward then self.GridReward.gameObject:SetActiveEx(false) end
        return
    end
    if not self.GridReward then return end
    self.GridReward.gameObject:SetActiveEx(false)
    if self._RewardGridDict == nil then self._RewardGridDict = {} end
    XUiHelper.RefreshCustomizedList(self.PanelRewardList, self.GridReward, #rewardGoodsList, function(index, go)
        local grid = self._RewardGridDict[go]
        if not grid then
            grid = XUiGridSettleReward.New(go, self)
            self._RewardGridDict[go] = grid
        end
        grid:Open()
        grid:Refresh(rewardGoodsList[index])
    end)
end

--endregion

function XUiPunishaarBattleSettlement:OnBtnConfirmClick()
    local onConfirm = self._OnConfirm
    self._OnConfirm = nil
    -- 必须等结算界面完全关闭后再推进后续流程：
    -- onConfirm 内部 SafeClose BattleSettlement（兜底，经 CloseWithCallback 已关则 no-op）+ Open ChallengeSettlement（Pop 叠 FightMain #66 基底）。
    -- 若在此界面退场动画播完前执行，栈顶仍是本结算界面，Open 会叠在未关的本界面之上。
    -- 故用 CloseWithCallback 等完全关闭后再回调 onConfirm，保证 BattleSettlement 退场完毕再 Open 结算。
    if onConfirm then
        XLuaUiManager.CloseWithCallback(self.Name, onConfirm)
    else
        self:Close()
    end
end

return XUiPunishaarBattleSettlement