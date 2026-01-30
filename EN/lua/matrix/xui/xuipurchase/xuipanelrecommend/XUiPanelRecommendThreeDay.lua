---@class XUiPanelRecommendThreeDay 新手三日限定补给
local XUiPanelRecommendThreeDay = XClass(nil, "XUiPanelRecommendThreeDay")

function XUiPanelRecommendThreeDay:Ctor(ui, parent)
    ---@type UnityEngine.GameObject
    self.GameObject = ui.gameObject
    ---@type UnityEngine.RectTransform
    self.Transform = ui.transform
    self.RootUi = parent
    XTool.InitUiObject(self)

    if self.BtnHelp then
        self.BtnHelp.CallBack = handler(self, self.OnBtnHelpClick)
    end
    ---@type XUiGridPurchaseThreeDay[]
    self.Grids = {}
    
    XEventManager.BindEvent(self.GameObject, XEventId.EVENT_DAYLY_REFESH_RECHARGE_BTN, self.RefreshByPurchasePackageData, self)
end

---@param isShow boolean 福利界面打开时'isShow'为false，打脸打开时为true
function XUiPanelRecommendThreeDay:Refresh(signId, purchaseData)
    self.SignId = signId
    self.PurchaseData = purchaseData
    self.BetterIndexDic = {}

    if purchaseData and purchaseData.PurchaseSignInInfo then
        local batterIndexStr = purchaseData.PurchaseSignInInfo.BetterIndexStr
        if not string.IsNilOrEmpty(batterIndexStr) then
            local betterIndexList = string.Split(batterIndexStr, "|")
            for _, index in ipairs(betterIndexList) do
                self.BetterIndexDic[tonumber(index)] = true
            end
        end
    end
    self:RefreshByPurchasePackageData()
end

function XUiPanelRecommendThreeDay:RefreshByPurchasePackageData()
    local icon = XDataCenter.ItemManager.GetItemIcon(self.PurchaseData.ConsumeId)
    if icon then
        self.BtnBuyLB:SetRawImage(icon)
    end
    self.BtnBuyLB:SetName(self.PurchaseData.ConsumeCount)
    self.IsSellOut = self.PurchaseData.BuyLimitTimes > 0 and self.PurchaseData.BuyTimes == self.PurchaseData.BuyLimitTimes
    if self.PurchaseData.BuyTimes < self.PurchaseData.BuyLimitTimes then
        self.BtnBuyLB:SetDisable(false)
    else
        self.BtnBuyLB:SetDisable(true)
    end
    self.TxtTips.text = self.PurchaseData.Desc
    self:SetRewardInfos()
end

function XUiPanelRecommendThreeDay:SetRewardInfos()
    local rewardInfos = self.PurchaseData.PurchaseSignInInfo.PurchaseSignInRewardInfos
    for index, rewardInfo in ipairs(rewardInfos) do
        local rewardList = XRewardManager.GetRewardList(rewardInfo)
        local reward = rewardList[1]
        local grid = self.Grids[index]
        if not grid then
            local go = self[string.format("PanelGift%s", index)]
            if XTool.UObjIsNil(go) then
                goto continue
            end
            grid = require("XUi/XUiPurchase/Grid/XUiGridPurchaseThreeDay").New(go, self)
            self.Grids[index] = grid
        end
        grid:UpdateData(self.PurchaseData.Id, reward, true, false, index, self.IsSellOut)
        :: continue ::
    end
end

function XUiPanelRecommendThreeDay:OnBtnHelpClick()
    local sigInCfg = XSignInConfigs.GetSignInConfig(self.SignId)
    local subRoundCfg = XSignInConfigs.GetSubRoundConfig(sigInCfg.SubRoundId[1])
    XUiManager.UiFubenDialogTip("", subRoundCfg.SubRoundDesc or "")
end

return XUiPanelRecommendThreeDay