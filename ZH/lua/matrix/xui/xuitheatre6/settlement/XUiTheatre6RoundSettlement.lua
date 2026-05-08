--- 肉鸽6单次战斗结算界面
---@class XUiTheatre6RoundSettlement : XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6RoundSettlement = XLuaUiManager.Register(XLuaUi, "UiTheatre6RoundSettlement")
local XUiPanelTheatre6RoundLeft = require("XUi/XUiTheatre6/Settlement/Panel/XUiPanelTheatre6RoundLeft")
local XUiPanelTheatre6SkillDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6SkillDetail")
local XUiPanelTheatre6TagDetail = require("XUi/XUiTheatre6/Settlement/Panel/XUiPanelTheatre6TagDetail")
local XUiPanelTheatre6AttackDetail = require("XUi/XUiTheatre6/Settlement/Panel/XUiPanelTheatre6AttackDetail")

function XUiTheatre6RoundSettlement:OnAwake()
    self.BtnContinue:AddEventListener(handler(self, self.OnBtnContinueClick))
    ---@type XUiPanelTheatre6RoundLeft
    self._PanelLeft = XUiPanelTheatre6RoundLeft.New(self.PanelLeft, self)
    ---@type XUiPanelTheatre6TagDetail
    self._BubbleTagDetail = XUiPanelTheatre6TagDetail.New(self.BubbleTagDetail, self)
    ---@type XUiPanelTheatre6AttackDetail
    self._BubbleAttackDetail = XUiPanelTheatre6AttackDetail.New(self.BubbleAttackDetail, self)

    self.BubbleSkillDetail.gameObject:SetActiveEx(false)
    self._BubbleTagDetail:Close()
    self._BubbleAttackDetail:Close()
end

---@param settleData table DlcFightSettleData
function XUiTheatre6RoundSettlement:OnStart(settleData, monsterId, totalScore, isChooseRoom)
    self.SettleData = settleData
    self._PanelLeft:Refresh(settleData, monsterId, totalScore, isChooseRoom)
end

function XUiTheatre6RoundSettlement:OnBtnContinueClick()
    local rewardGoodsList = self.SettleData.Theatre6FightResult.RewardGoodsList or table.empty
    XLuaUiManager.Open("UiTheatre6FightReward", rewardGoodsList)
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

return XUiTheatre6RoundSettlement