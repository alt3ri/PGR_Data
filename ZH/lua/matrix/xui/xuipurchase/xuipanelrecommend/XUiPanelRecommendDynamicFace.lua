local XUiPanelRecommendBase = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendBase")

---@class XUiPanelRecommendDynamicFace : XUiPanelRecommendBase 动态表情包
local XUiPanelRecommendDynamicFace = XClass(XUiPanelRecommendBase, "XUiPanelRecommendDynamicFace")

-- 重写父类函数，使用表情包专属的Item模板
function XUiPanelRecommendDynamicFace:GetRecommendItemTemplate()
    local XUiPanelRecommendEmojiItem = require(
        "XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendItem/XUiPanelRecommendEmojiItem")
    return XUiPanelRecommendEmojiItem
end

-- 重写父类函数，捆绑包点击处理
function XUiPanelRecommendDynamicFace:OnClickPackage(package)
    local isComboPackage = XDataCenter.PurchaseManager.IsComboPackage(package)
    if isComboPackage then
        local comboSubData = XDataCenter.PurchaseManager.GetComboPackageSubData(package)
        --售罄处理
        if package:GetIsSellOut() then
            XUiManager.TipErrorWithKey("PurchaseSettOut")
            return
        end

        --弹出捆绑包界面
        XLuaUiManager.Open("UiPurchaseBuyTips", comboSubData, function(_, _, payCount)
            self.SkipFunc(XPurchaseConfigs.TabsConfig.Pay, nil, payCount)
        end, self.BuyFinished)
    else
        --非捆绑包， 调用父类处理逻辑
        self.Super.OnClickPackage(self, package)
    end
end

-- 重写父类函数，处理一键购买逻辑
function XUiPanelRecommendDynamicFace:SetData(data, skipFunc, buyFinished)
    self.Super.SetData(self, data, skipFunc, buyFinished)

    --一键购买价格
    local pckageList = data:GetPurchasePackage()
    if not pckageList or #pckageList <= 0 then
        return
    end
    local firstPackage = pckageList[1]
    local comboData = XDataCenter.PurchaseManager.GetComboPackageParentData(firstPackage)
    self.TxtConsume.text = comboData and comboData.Price or ""

    --一键购买
    self.BtnTongBlack:AddEventListener(function()
        XLuaUiManager.Open("UiPurchaseBuyTips", comboData, function(_, _, payCount)
            self.SkipFunc(XPurchaseConfigs.TabsConfig.Pay, nil, payCount)
        end, self.BuyFinished)
    end)

    --如果4个小礼包都买完了，隐藏一键购买
    local allSold = true
    for i=1,4 do
        local pkg = pckageList[i]
        if pkg and not pkg:GetIsSellOut() then
            allSold = false
            break
        end
    end
    self.BtnTongBlack.gameObject:SetActive(not allSold)

    --活动说明
    self.BtnHelp.CallBack = handler(self, self.OnRuleClick)
end

function XUiPanelRecommendDynamicFace:OnRuleClick()
    XLuaUiManager.Open("UiFubenDialog", XUiHelper.GetText("DynamicFaceRuleTitleTip"),
        XUiHelper.GetText("DynamicFaceRuleContentTip"))
end

return XUiPanelRecommendDynamicFace
