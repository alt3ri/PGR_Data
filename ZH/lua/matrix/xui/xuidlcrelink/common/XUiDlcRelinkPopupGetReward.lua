local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
---@class XUiDlcRelinkPopupGetReward : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupGetReward = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupGetReward")

function XUiDlcRelinkPopupGetReward:OnAwake()
    self.GridReward.gameObject:SetActiveEx(false)
    self.GridEquipment.gameObject:SetActiveEx(false)
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))

    ---@type XUiGridCommon[]
    self.RewardGridList = {}
    ---@type XUiGridDlcRelinkEquipment[]
    self.EquipGridList = {}

    self.CurSelectGrid = nil
    self.CurSelectEquipUid = 0
end

function XUiDlcRelinkPopupGetReward:OnStart(rewardGoodsList, equipUidList)
    self:RefreshReward(rewardGoodsList)
    self:RefreshEquip(equipUidList)
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
            local rewardType = XArrangeConfigs.GetType(grid.TemplateId)
            if rewardType == XRewardManager.XRewardType.Nameplate then
                XLuaUiManager.Open("UiNameplateTip", grid.TemplateId, true, true, true)
            else
                XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", grid.TemplateId)
            end
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
            grid = XUiGridDlcRelinkEquipment.New(go, self, handler(self, self.OnEquipGridCallBack))
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

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkPopupGetReward:OnEquipGridCallBack(grid)
    local equipUid = grid:GetEquipUid()
    if equipUid == self.CurSelectEquipUid then
        return
    end
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    grid:SetSelect(true)
    self.CurSelectEquipUid = equipUid
    self.CurSelectGrid = grid
    XLuaUiManager.Open("UiDlcRelinkBubbleEquipDetail", equipUid, grid.Transform, handler(self, self.OnBubbleEquipDetailClose))
end

function XUiDlcRelinkPopupGetReward:OnBubbleEquipDetailClose()
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    self.CurSelectEquipUid = 0
    self.CurSelectGrid = nil
end

function XUiDlcRelinkPopupGetReward:OnBtnBackClick()
    self:Close()
end

return XUiDlcRelinkPopupGetReward
