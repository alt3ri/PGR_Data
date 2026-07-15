--- 肉鸽6单次战斗结算界面
---@class XUiTheatre6RoundSettlement : XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6RoundSettlement = XLuaUiManager.Register(XLuaUi, "UiTheatre6RoundSettlement")
local XUiPanelTheatre6RoundLeft = require("XUi/XUiTheatre6/Settlement/Panel/XUiPanelTheatre6RoundLeft")
local XUiPanelTheatre6TagDetail = require("XUi/XUiTheatre6/Settlement/Panel/XUiPanelTheatre6TagDetail")
local XUiPanelTheatre6AttackDetail = require("XUi/XUiTheatre6/Settlement/Panel/XUiPanelTheatre6AttackDetail")

local Settlement = XEnumConst.Theatre6.Settlement

function XUiTheatre6RoundSettlement:OnAwake()
    self.BtnContinue:AddEventListener(handler(self, self.OnBtnContinueClick))
    ---@type XUiPanelTheatre6TagDetail
    self._BubbleTagDetail = XUiPanelTheatre6TagDetail.New(self.BubbleTagDetail, self)
    ---@type XUiPanelTheatre6AttackDetail
    self._BubbleAttackDetail = XUiPanelTheatre6AttackDetail.New(self.BubbleAttackDetail, self)

    self.BubbleSkillDetail.gameObject:SetActiveEx(false)
    self._BubbleTagDetail:Close()
    self._BubbleAttackDetail:Close()
end

---@param settleData table DlcFightSettleData
function XUiTheatre6RoundSettlement:OnStart(settleData, monsterId, totalScore, status)
    self.SettleData = settleData
    self._Status = status
    if status == Settlement.Pvp then
        ---@type XUiPanelTheatre6PvpRoundLeft
        self._PvpPanelLeft = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpRoundLeft").New(self.PanelLeft, self)
        self._PvpPanelLeft:Refresh(settleData.Theatre6PvpFightResult)
    else
        ---@type XUiPanelTheatre6RoundLeft
        local panelLeft = XUiPanelTheatre6RoundLeft.New(self.PanelLeft, self)
        panelLeft:Refresh(settleData, monsterId, totalScore, status == Settlement.ChooseRoom)
    end
    self:ShowPvpRoundTab()
end

function XUiTheatre6RoundSettlement:OnBtnContinueClick()
    if self._Status == XEnumConst.Theatre6.Settlement.Pvp then
        XLuaUiManager.Open("UiTheatre6PVPSettlement", self.SettleData.Theatre6PvpFightResult)
    else
        local rewardGoodsList = self.SettleData.Theatre6FightResult.RewardGoodsList or table.empty
        XLuaUiManager.Open("UiTheatre6FightReward", rewardGoodsList)
    end
    self:Close()
end

---打开技能详情Bubble
---@param skillId number
---@param target UnityEngine.Transform
function XUiTheatre6RoundSettlement:OpenSkillDetailBubble(skillId, target)
    self._Control:OpenSkillTip(skillId, target, { ReadOnly = true })
end

---打开Buff详情Bubble
---@param buffId number
---@param target UnityEngine.Transform
function XUiTheatre6RoundSettlement:OpenBuffDetailBubble(buffId, target)
    self._BubbleTagDetail:Open()
    self._BubbleTagDetail:Refresh({ buffId })
    self._BubbleTagDetail.Transform.position = target.position
end

---关闭所有Bubble
function XUiTheatre6RoundSettlement:CloseAllBubbles()
    self._BubbleTagDetail:Close()
    self._BubbleAttackDetail:Close()
end

--region pvp

function XUiTheatre6RoundSettlement:ShowPvpRoundTab()
    if self._Status ~= XEnumConst.Theatre6.Settlement.Pvp then
        self.ListTab.gameObject:SetActiveEx(false)
        return
    end

    local pvpResultData = self.SettleData.Theatre6PvpFightResult
    local tabs = {}
    local count = #pvpResultData.RoundResults

    self.ListTab.gameObject:SetActiveEx(true)
    self.GridTabWin.gameObject:SetActiveEx(false)
    self.GridTabLose.gameObject:SetActiveEx(false)

    for i = 1, count do
        local gridTab = pvpResultData.RoundResults[i] and self.GridTabWin or self.GridTabLose
        local tab = XUiHelper.Instantiate(gridTab, self.ListTab.transform)
        tab:SetName(XUiHelper.GetText("Theatre6PvpRoundName", XTool.ConvertNumberString(i)))
        tab.ExitCheck = false
        tab.gameObject:SetActiveEx(true)
        table.insert(tabs, tab)
    end

    self.ListTab:Init(tabs, function(i)
        self._PvpPanelLeft:UpdateRoundData(i)
    end)
    self.ListTab:SelectIndex(count)
end

--endregion

return XUiTheatre6RoundSettlement