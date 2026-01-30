---@class XUiMainLine2EggsTreasureMail:XLuaUi
---@field private _Control XMainLine2Control
local XUiMainLine2EggsTreasureMail = XLuaUiManager.Register(XLuaUi, "UiMainLine2EggsTreasureMail")

function XUiMainLine2EggsTreasureMail:OnAwake()
    self.GridItem.gameObject:SetActiveEx(false)
    self.RewardGrids = {}
    self:RegisterUiEvents()
end

function XUiMainLine2EggsTreasureMail:OnStart(chapterId, eggId)
    self.ChapterId = chapterId
    self.EggId = eggId
    self:Refresh()
end

function XUiMainLine2EggsTreasureMail:OnEnable()
    
end

function XUiMainLine2EggsTreasureMail:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiMainLine2EggsTreasureMail:OnBtnCloseClick()
    local chapterId = self.ChapterId
    self:Close()
    XMVCA.XMainLine2:CheckOpenUiEggsTreasureTips(chapterId)
end

function XUiMainLine2EggsTreasureMail:Refresh()
    self.TxtTitle.text = self._Control:GetEggTitle(self.EggId)
    local desc = self._Control:GetEggDesc(self.EggId)
    self.TxtDesc.text = XUiHelper.ReplaceTextNewLine(desc)
    
    -- 奖励
    XMVCA.XMainLine2:RequestMainLine2ReceiveEggsTreasure(self.ChapterId, self.EggId, function(rewardGoodsList)
        self:RefreshRewardGrids(rewardGoodsList)
    end)
end

function XUiMainLine2EggsTreasureMail:RefreshRewardGrids(rewardGoodsList)
    if not rewardGoodsList or #rewardGoodsList == 0 then
        return
    end
    
    self.RewardGrids = self.RewardGrids or {}
    local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
    XUiHelper.CreateTemplates(self, self.RewardGrids, rewardGoodsList, XUiGridCommon.New, self.GridItem, self.GridItem.transform.parent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)
end

return XUiMainLine2EggsTreasureMail