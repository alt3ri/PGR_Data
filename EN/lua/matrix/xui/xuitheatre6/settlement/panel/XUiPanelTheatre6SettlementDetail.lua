--- 结算详情面板
---@class XUiPanelTheatre6SettlementDetail : XUiNode
---@field private _Control XTheatre6Control
---@field Parent XUiTheatre6Settlement
local XUiPanelTheatre6SettlementDetail = XClass(XUiNode, "XUiPanelTheatre6SettlementDetail")
local XUiGridTheatre6SettlementEnemy = require("XUi/XUiTheatre6/Settlement/Grid/XUiGridTheatre6SettlementEnemy")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiPanelTheatre6SettlementDetail:OnStart(mode)
    self._Mode = mode
    self._ListEnemy = {}
    ---@type XUiGridCommon[]
    self._ListReward = {}
    self.BtnNext:AddEventListener(handler(self, self.OnBtnNextClick))
    self._TalentCoin = self._Control:GetTalentCoinId()

    self.ImgIconHeart:SetRawImage(self._Control:GetHpIcon())
    self.ImgIconSan:SetRawImage(self._Control:GetSanIcon())
end

function XUiPanelTheatre6SettlementDetail:OnEnable()
    self._PanelRoleDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6CharacterAttrDetail").New(self.UiTheatre6PanelRoleDetail, self, self.Parent.SettleData and self.Parent.SettleData.FileData, self._Mode)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_TALENT_LEVEL_CHANGE, self.RefreshPanelReward, self)
end

function XUiPanelTheatre6SettlementDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_TALENT_LEVEL_CHANGE, self.RefreshPanelReward, self)
end

function XUiPanelTheatre6SettlementDetail:Refresh()
    self:RefreshPanelHealth()
    self:RefreshPanelEnemy()
    self:RefreshPanelReward()
end

function XUiPanelTheatre6SettlementDetail:RefreshPanelHealth()
    local settleData = self.Parent.SettleData
    if not settleData then
        return
    end

    self.UiTxtHeartLeft.text = tostring(settleData.CurHeath or 0)
    self.UiTxtHeartRight.text = "/" .. tostring(settleData.MaxHeath or 0)
    self.UiTxtSanLeft.text = tostring(settleData.CurSan or 0)
    self.UiTxtSanRight.text = "/" .. tostring(settleData.MaxSan or 0)

    local redColor = XUiHelper.Hexcolor2Color("FF0000")
    local defaultColor = XUiHelper.Hexcolor2Color("FFFFFF")
    self.UiTxtHeartLeft.color = (settleData.CurHeath == 0) and redColor or defaultColor
    self.UiTxtSanLeft.color = settleData.CurSan == 0 and redColor or defaultColor
end

function XUiPanelTheatre6SettlementDetail:RefreshPanelEnemy()
    local settleData = self.Parent.SettleData
    local fightRecords = settleData and settleData.FightRecords or table.empty

    self.GridEnemy.gameObject:SetActiveEx(false)
    XTool.UpdateDynamicItem(self._ListEnemy, fightRecords, self.GridEnemy, XUiGridTheatre6SettlementEnemy, self)
end

function XUiPanelTheatre6SettlementDetail:RefreshPanelReward()
    local settleData = self.Parent.SettleData
    local rewardList = settleData and settleData.RewardList or table.empty

    self.Grid256New.gameObject:SetActiveEx(false)
    XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, #rewardList, function(index, go)
        local grid = self._ListReward[go]
        if not grid then
            grid = XUiGridCommon.New(self.RootUi, go)
            self._ListReward[go] = grid
        end
        local rewardData = rewardList[index]
        grid:Refresh(rewardData)
        grid:SetProxyClickFunc(function()
            XLuaUiManager.Open("UiTheatre6PopupRewardDetail", rewardList[index])
        end)
        local isTagShow = self._TalentCoin == rewardData.TemplateId and self._Control:IsTalentMaxLv()
        grid:SetPanelTag(isTagShow)
    end)
end

function XUiPanelTheatre6SettlementDetail:OnBtnNextClick()
    self.Parent:ShowPanelSave()
    self.Parent:PlayAnimationWithMask("PanelSaveTab")
end

return XUiPanelTheatre6SettlementDetail