---@class XUiSkyGardenShoppingStreetSettlement : XLuaUi
---@field TxtRound UnityEngine.UI.Text
---@field ListAsset UnityEngine.RectTransform
---@field GridTarget UnityEngine.RectTransform
---@field TxtNum UnityEngine.UI.Text
---@field UiBigWorldItemGrid UnityEngine.RectTransform
---@field BtnLeave XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetSettlement = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetSettlement")

local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")
local XUiSkyGardenShoppingStreetTargetGridTarget = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetTargetGridTarget")
local XUiSkyGardenShoppingStreetAssetTag = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetAssetTag")

--region 生命周期
function XUiSkyGardenShoppingStreetSettlement:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetSettlement:OnStart(rewardGoodsList, isNewSagePassed)
    local stageId = self._Control:GetCurrentStageId()
    local config = self._Control:GetStageConfigsByStageId(stageId)
    self._Targets = {}
    XTool.UpdateDynamicItem(self._Targets, config.TargetTaskIds, self.GridTarget, XUiSkyGardenShoppingStreetTargetGridTarget, self)

    for i = 1, #self._Targets do
        if self._Control:GetRewardIndexRecordAndIndex(stageId, i) then
            self._Targets[i]:SetFinish()
        end
    end

    local hasReward = rewardGoodsList and #rewardGoodsList > 0
    self.PanelReward.gameObject:SetActive(hasReward)
    self.AllRewardTxtTips.gameObject:SetActive(not hasReward)
    if hasReward then
        local extRewardShowList
        self.ListReward.gameObject:SetActive(isNewSagePassed)
        self.ListRewardFirst.gameObject:SetActive(isNewSagePassed)
        if isNewSagePassed then
            local UiBigWorldItemShoppingStreetGridGridUi = XUiGridBWItem.New(self.UiBigWorldItemShoppingStreetGridGrid, self)
            UiBigWorldItemShoppingStreetGridGridUi:Refresh(rewardGoodsList[1])
    
            extRewardShowList = {}
            for i = 2, #rewardGoodsList do
                table.insert(extRewardShowList, rewardGoodsList[i])
            end
        else
            extRewardShowList = rewardGoodsList
        end
    
        self._isFinishExit = isNewSagePassed and config.IsFinishExit
        local isShowReward = extRewardShowList and #extRewardShowList > 0
        self.ListReward.gameObject:SetActive(isShowReward)
        XTool.UpdateDynamicItem({}, extRewardShowList, self.UiBigWorldItemGrid, XUiGridBWItem, self)
    end

    self.TxtRound.text = XMVCA.XBigWorldService:GetText("SG_SS_RoundText", self._Control:GetRunRound())
    self.TxtNum.text = self._Control:GetAccumulativeGold()
    local resCfgs = self._Control:GetStageResConfigs()
    local resCfg = resCfgs[XMVCA.XSkyGardenShoppingStreet.StageResType.InitGold]
    self.ImgAsset:SetSprite(resCfg.Icon)
    -- self.ImgAsset.color = XUiHelper.Hexcolor2Color(resCfg.IconColor)

    local StageResType = XMVCA.XSkyGardenShoppingStreet.StageResType
    XTool.UpdateDynamicItem({}, {
        StageResType.InitGold, 
        StageResType.InitFriendly, 
        StageResType.InitCustomerNum, 
        StageResType.InitEnvironment, }, self.GridGold, 
        XUiSkyGardenShoppingStreetAssetTag, self)
end

function XUiSkyGardenShoppingStreetSettlement:GetStageId()
    return self._Control:GetCurrentStageId()
end

--endregion

--region 按钮事件
function XUiSkyGardenShoppingStreetSettlement:OnBtnLeaveClick()
    local clickTime = CS.UnityEngine.Time.realtimeSinceStartup
    if self._ClickTime and clickTime - self._ClickTime < 5 then return end
    self._ClickTime = clickTime
    self._Control:X3CSetVirtualCameraByCameraIndex(4)
    XMVCA.XBigWorldUI:CloseAllUpperUiWithCallback("UiSkyGardenShoppingStreetMain", function()
        if self._isFinishExit then
            XMVCA.XSkyGardenShoppingStreet:ExitGameLevel()
        end
    end)
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetSettlement:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnLeave:AddEventListener(handler(self, self.OnBtnLeaveClick))
end
--endregion

return XUiSkyGardenShoppingStreetSettlement
