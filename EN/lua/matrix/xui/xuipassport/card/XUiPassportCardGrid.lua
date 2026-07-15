local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@field _Control XPassportControl
---@class XUiPassportCardGrid:XUiNode
local XUiPassportCardGrid = XClass(XUiNode, "XUiPassportCardGrid")

local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiPassportCardGrid:Init(rootUi)
    self.RootUi = rootUi
    self.RewardPanelList = {}
end

function XUiPassportCardGrid:Refresh(passportBuyRewardShowId)
    local level = self._Control:GetPassportBuyRewardShowLevel(passportBuyRewardShowId)
    if XTool.IsNumberValid(level) then
        self.TextUnLock.text = CSXTextManagerGetText("PassportLevelUnLockDesc", level)
        self.RImgUnLock.gameObject:SetActiveEx(true)
    else
        self.RImgUnLock.gameObject:SetActiveEx(false)
    end

    if not self.GridCommon then
        self.GridCommon = XUiGridCommon.New(self.RootUi, self.Gridicon)
    end

    local rewardData = self._Control:GetPassportBuyRewardShowRewardData(passportBuyRewardShowId, true)
    self.GridCommon:Refresh(rewardData)

    local showCount = self._Control:GetPassportBuyRewardShowCount(passportBuyRewardShowId)
    self.TxtCount.text = CSXTextManagerGetText("ShopGridCommonCount", showCount)

    local enableCountDisplay = XTool.IsNumberValid(showCount)
    self.TxtCount.gameObject:SetActiveEx(enableCountDisplay)
    self.PanelTxt.gameObject:SetActiveEx(enableCountDisplay)
end

return XUiPassportCardGrid