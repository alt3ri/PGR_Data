local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
---@class XUiDlcRelinkPopupGetReward : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupGetReward = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupGetReward")

function XUiDlcRelinkPopupGetReward:OnAwake()
    self.GridReward.gameObject:SetActiveEx(false)
    self.GridEquipment.gameObject:SetActiveEx(false)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    ---@type XUiGridCommon[]
    self.RewardGridList = {}
    ---@type XUiGridDlcRelinkEquipment[]
    self.EquipGridList = {}
end

function XUiDlcRelinkPopupGetReward:OnStart(rewardGoodsList, equipUidList)
    self:RefreshReward(rewardGoodsList)
    self:RefreshEquip(equipUidList)
    self:PlayAnimation("AniObtain")
end

function XUiDlcRelinkPopupGetReward:OnEnable()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Common_UiObtain)
end

function XUiDlcRelinkPopupGetReward:RefreshReward(rewardGoodsList)
    if XTool.IsTableEmpty(rewardGoodsList) then
        return
    end

    rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    for index, rewardGoods in pairs(rewardGoodsList) do
        local grid = self.RewardGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridReward, self.PanelContent)
            grid = XUiGridCommon.New(self, go)
            self.RewardGridList[index] = grid
        end
        grid:Refresh(rewardGoods)
        grid:SetProxyClickFunc(function()
            XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", grid.TemplateId)
        end)
        grid.GameObject:SetActiveEx(true)
    end

    for i = #rewardGoodsList + 1, #self.RewardGridList do
        self.RewardGridList[i].GameObject:SetActiveEx(false)
    end
end

function XUiDlcRelinkPopupGetReward:RefreshEquip(equipUidList)
    if XTool.IsTableEmpty(equipUidList) then
        return
    end

    for index, equipUid in pairs(equipUidList) do
        local grid = self.EquipGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridEquipment, self.PanelContent)
            grid = XUiGridDlcRelinkEquipment.New(go, self)
            self.EquipGridList[index] = grid
        end
        grid:Open()
        grid:Refresh(equipUid)
    end

    for i = #equipUidList + 1, #self.EquipGridList do
        local grid = self.EquipGridList[i]
        if grid then
            grid:Close()
        end
    end
end

function XUiDlcRelinkPopupGetReward:OnBtnBackClick()
    self:Close()
end

return XUiDlcRelinkPopupGetReward
