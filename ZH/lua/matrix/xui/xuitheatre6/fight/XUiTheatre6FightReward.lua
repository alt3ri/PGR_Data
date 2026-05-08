--- 肉鸽6战斗奖励界面
---@class XUiTheatre6FightReward : XLuaUi
---@field private _Control XTheatre6Control
local XUiTheatre6FightReward = XLuaUiManager.Register(XLuaUi, "UiTheatre6FightReward")
local XUiPanelTheatre6RewardRelic = require("XUi/XUiTheatre6/Fight/Panel/XUiPanelTheatre6RewardRelic")
local XUiPanelTheatre6RewardSkill = require("XUi/XUiTheatre6/Fight/Panel/XUiPanelTheatre6RewardSkill")
local XUiPanelTheatre6RewardBuff = require("XUi/XUiTheatre6/Fight/Panel/XUiPanelTheatre6RewardBuff")

local EventRewardType = XEnumConst.Theatre6.EventRewardType

function XUiTheatre6FightReward:OnAwake()
    self:InitButtonEvents()
    self:InitPanels()
end

---@param rewardGoodsList Theatre6RewardGoods[]
function XUiTheatre6FightReward:OnStart(rewardGoodsList)
    self._RewardGoodsList = rewardGoodsList or {}
    self.RImgIcon:SetRawImage(self._Control:GetCoinIcon())
end

function XUiTheatre6FightReward:OnEnable()
    self:Refresh()
end

function XUiTheatre6FightReward:OnDestroy()
    if XLuaUiManager.IsUiShow("UiTheatre6BubbleTagDetail") then
        XLuaUiManager.Close("UiTheatre6BubbleTagDetail")
    end
    CS.StatusSyncFight.XFightClient.RequestExitFight()
    --如果对局已经全部结束，显示结算界面
    if not XMVCA.XTheatre6:OpenSettle() then
        self._Control:TryOpenStageViewAfterFight()
    end
end

function XUiTheatre6FightReward:InitButtonEvents()
    self.BtnExit:AddEventListener(handler(self, self.OnBtnExitClick))
    self.UiTheatre6BtnCharacter:AddEventListener(handler(self, self.OnBtnCharacterClick))
end

function XUiTheatre6FightReward:InitPanels()
    self._PanelAsset = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6Asset").New(self.PanelAsset, self)
    ---@type XUiPanelTheatre6BubbleTag
    self._BubbleTagDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6BubbleTag").New(
    self.UiTheatre6BubbleTagDetail, self)
    self._BubbleTagDetail:Close()

    self._SkillCards = {}
    self._RelicCards = {}
    self._BuffCards = {}
end

function XUiTheatre6FightReward:Refresh()
    self:RefreshTitle()
    self._PanelAsset:Refresh()
    self:RefreshCharacter()
    self:RefreshRewardList()
end

function XUiTheatre6FightReward:RefreshTitle()
    -- 从奖励列表中查找金币奖励
    local goldReward = nil
    for _, reward in ipairs(self._RewardGoodsList) do
        if reward.RewardType == EventRewardType.Coin then
            goldReward = reward
            break
        end
    end

    if goldReward then
        self.UiTxtNum.text = tostring(goldReward.Amount or 0)
        -- TODO: 金币增加动效，使用 goldReward.AmountChange
    else
        self.UiTxtNum.text = "0"
    end
end

function XUiTheatre6FightReward:RefreshCharacter()
    local icon = self._Control:GetHeadIcon()
    self.UiRImgNormalHead:SetRawImage(icon)
    self.UiRImgPressHead:SetRawImage(icon)

    local score = self._Control:GetCurrentScore()
    self.UiTxtNormalScore.text = tostring(score)
    self.UiTxtPressScore.text = tostring(score)
end

function XUiTheatre6FightReward:RefreshRewardList()
    local skillList, relicList, buffList = self:ParseRewardData()

    self.PanelRewardSkill.gameObject:SetActiveEx(false)
    self.PanelRewardRelic.gameObject:SetActiveEx(false)
    self.PanelRewardBuff.gameObject:SetActiveEx(false)

    local isEmpty = #skillList == 0 and #relicList == 0 and #buffList == 0
    self.TxtEmptyStat.gameObject:SetActiveEx(isEmpty)

    XTool.UpdateDynamicItem(self._SkillCards, skillList, self.PanelRewardSkill, XUiPanelTheatre6RewardSkill, self)
    XTool.UpdateDynamicItem(self._RelicCards, relicList, self.PanelRewardRelic, XUiPanelTheatre6RewardRelic, self)
    XTool.UpdateDynamicItem(self._BuffCards, buffList, self.PanelRewardBuff, XUiPanelTheatre6RewardBuff, self)
end

---解析奖励数据，分类返回
---@return table, table, table skillList, relicList, buffList
function XUiTheatre6FightReward:ParseRewardData()
    local skillList = {}
    local relicList = {}
    local buffList = {}

    for _, reward in ipairs(self._RewardGoodsList) do
        if reward.RewardType == EventRewardType.SkillPool then
            if XTool.IsNumberValid(reward.SkillId) then
                table.insert(skillList, { SkillId = reward.SkillId, Level = 1 })
            elseif XTool.IsNumberValid(reward.AttrPack) then
                table.insert(relicList, { AttrPackId = reward.AttrPack })
            end
        elseif reward.RewardType == EventRewardType.BuffPool then
            local buffs = reward.BuffList or {}
            for _, buffData in ipairs(buffs) do
                if XTool.IsNumberValid(buffData.BuffId) then
                    table.insert(buffList, { BuffId = buffData.BuffId })
                end
            end
        end
    end

    return skillList, relicList, buffList
end

function XUiTheatre6FightReward:OnBtnExitClick()
    if self:TryOpenSellSkillPanel() then
        return
    end
    self:Close()
end

function XUiTheatre6FightReward:TryOpenSellSkillPanel()
    return self._Control:CheckForceSellSkillBlock()
end

function XUiTheatre6FightReward:OnBtnCharacterClick()
    XLuaUiManager.Open("UiTheatre6PopupRoleDetail", self.UiTheatre6BtnCharacter.transform)
end

return XUiTheatre6FightReward
