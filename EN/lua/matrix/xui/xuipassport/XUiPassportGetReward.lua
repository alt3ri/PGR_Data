---@class XUiPassportGetReward : XLuaUi
---@field _Control XPassportControl
local XUiPassportGetReward = XLuaUiManager.Register(XLuaUi, "UiPassportGetReward")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiPassportGetReward:OnAwake()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.BtnTongBlack:AddEventListener(handler(self, self.OnBtnBuyClick))

    self._RewardGrids = {}
    self._BuyGrids = {}
    self.GridCommon.gameObject:SetActiveEx(false)
    self.Gridicon.gameObject:SetActiveEx(false)
end

---@param rewardList table 服务器返回的实际获得奖励列表
function XUiPassportGetReward:OnStart(rewardList, uiPassport)
    if not rewardList then
        self._RewardList = table.empty
    else
        self._RewardList = XRewardManager.MergeAndSortRewardGoodsList(rewardList)
    end

    self:RefreshObtainedRewards()
    self:RefreshBuyPanel()
    self.UiPassport = uiPassport
end

function XUiPassportGetReward:RefreshObtainedRewards()
    XUiHelper.RefreshCustomizedList(
        self.GridCommon.transform.parent,
        self.GridCommon,
        #self._RewardList,
        function(index, go)
            local grid = self._RewardGrids[go]
            if not grid then
                grid = XUiGridCommon.New(self, go)
                self._RewardGrids[go] = grid
            end
            grid:Refresh(self._RewardList[index])
        end
    )
end

function XUiPassportGetReward:OnDestroy()
    self.UiPassport:Refresh()
end

function XUiPassportGetReward:RefreshBuyPanel()
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    local currentLevel = self._Control:GetPassportBaseInfo():GetLevel()

    local unownedTypeIds = {}
    for _, typeId in ipairs(typeInfoIdList) do
        if not self._Control:GetPassportInfos(typeId) then
            table.insert(unownedTypeIds, typeId)
        end
    end

    local buyRewardList = {}
    for _, typeId in ipairs(unownedTypeIds) do
        for level = 1, currentLevel do
            local passportRewardId = self._Control:GetRewardIdByPassportIdAndLevel(typeId, level)
            if XTool.IsNumberValid(passportRewardId) then
                local rewardData = self._Control:GetPassportRewardData(passportRewardId)
                if rewardData then
                    table.insert(buyRewardList, rewardData)
                end
            end
        end
    end

    self._BuyRewardList = XRewardManager.MergeAndSortRewardGoodsList(buyRewardList)

    XUiHelper.RefreshCustomizedList(
        self.Gridicon.transform.parent,
        self.Gridicon,
        #self._BuyRewardList,
        function(index, go)
            local grid = self._BuyGrids[go]
            if not grid then
                grid = XUiGridCommon.New(self, go)
                self._BuyGrids[go] = grid
            end
            grid:Refresh(self._BuyRewardList[index])
        end
    )
end

function XUiPassportGetReward:OnBtnBuyClick()
    XLuaUiManager.PopThenOpen("UiPassportCard", nil, self.UiPassport)
end

return XUiPassportGetReward