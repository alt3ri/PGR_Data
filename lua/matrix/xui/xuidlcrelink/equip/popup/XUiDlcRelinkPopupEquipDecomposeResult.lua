local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiDlcRelinkPopupEquipDecomposeResult : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupEquipDecomposeResult = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupEquipDecomposeResult")

function XUiDlcRelinkPopupEquipDecomposeResult:OnAwake()
    self.GridReward.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    ---@type XUiGridCommon[]
    self.RewardGridList = {}
end

function XUiDlcRelinkPopupEquipDecomposeResult:OnStart(rewardGoodsList)
    self:Refresh(rewardGoodsList)
    self:PlayAnimation("AniObtain")
end

function XUiDlcRelinkPopupEquipDecomposeResult:OnEnable()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Common_UiObtain)
end

function XUiDlcRelinkPopupEquipDecomposeResult:Refresh(rewardGoodsList)
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

function XUiDlcRelinkPopupEquipDecomposeResult:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
end

function XUiDlcRelinkPopupEquipDecomposeResult:OnBtnBackClick()
    self:Close()
end

return XUiDlcRelinkPopupEquipDecomposeResult
