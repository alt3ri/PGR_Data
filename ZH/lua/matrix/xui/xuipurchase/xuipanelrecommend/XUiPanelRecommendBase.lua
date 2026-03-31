---@class XUiPanelRecommendBase 通用礼包
local XUiPanelRecommendBase = XClass(nil, "XUiPanelRecommendBase")

function XUiPanelRecommendBase:Ctor()
    self.PurchaseManager = XDataCenter.PurchaseManager
    self.Recommend = nil
    self.SkipFunc = nil
    self.BuyFinished = nil
    self.BtnGiftNameList = {}
    self:OnInit()
end

---子类调用
function XUiPanelRecommendBase:OnInit()
    
end

function XUiPanelRecommendBase:SetUi(ui)
    -- 清除无用Btn引用
    for _, btnName in ipairs(self.BtnGiftNameList) do
        self[btnName] = nil
    end
    self.ImgSellOut = nil
    XUiHelper.InitUiClass(self, ui)
end

-- 子类可重写  可以指定专属的Item模板
function XUiPanelRecommendBase:GetRecommendItemTemplate()
    local XUiPanelRecommendItem = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendItem/XUiPanelRecommendItem")
    return XUiPanelRecommendItem
end

function XUiPanelRecommendBase:AddEditableTextComponent(btn, index, package)
    local recommendItem = self["RecommendItem" .. index]
    if not recommendItem then
        local XUiPanelRecommendItem = self:GetRecommendItemTemplate()
        recommendItem = XUiPanelRecommendItem.New(btn)
        self["RecommendItem" .. index] = recommendItem
    end
    recommendItem:Update(package)
end

-- 子类可重写 礼包点击处理
function XUiPanelRecommendBase:OnClickPackage(package)
    if package:GetIsSellOut() then
        XUiManager.TipErrorWithKey("PurchaseSettOut")
        return
    end
    local buyData = self.Recommend:GetPurchasePackage()
    if buyData then
        self.PurchaseManager.OpenPurchaseBuyUiByPurchasePackage(package, function(_, payCount)
            self.SkipFunc(XPurchaseConfigs.TabsConfig.Pay, nil, payCount)
        end, nil, self.BuyFinished)
    end
end

function XUiPanelRecommendBase:SetData(data, skipFunc, buyFinished)
    ---@type XPurchaseRecommend
    self.Recommend = data
    self.SkipFunc = skipFunc
    self.BuyFinished = buyFinished

    -- v1.28-采购优化-根据PurchasePackageId注册跳转方式
    local isHavePackageId = XTool.IsNumberValid(#self.Recommend:GetPurchasePackageIdList())
    local allSellOut = true
    if isHavePackageId and self.BtnGiftBuy1 then
        -- 配了PurchasePackageId且拥有礼包按钮
        --self.BtnBuy.gameObject:SetActiveEx(false)
        for index, _ in ipairs(self.Recommend:GetPurchasePackageIdList()) do
            local package = self.Recommend:GetPurchasePackage()[index]
            local btnName = "BtnGiftBuy" .. index
            local btn = self[btnName]
            
            self:AddEditableTextComponent(btn, index, package)
            
            if not XTool.UObjIsNil(btn) then
                if package == nil then
                    -- 页签显示时间内但找不到礼包数据则不显示
                    btn.gameObject:SetActiveEx(false)
                else
                    -- 保存已有Btn引用
                    self.BtnGiftNameList[index] = btnName
                    -- 设置礼包状态
                    if package:GetIsHave() then
                        btn:SetDisable(true)
                        self:ShowBuyBtnSoldOutOrOwned(btn.transform, false)
                    end
                    if package:GetIsSellOut() then
                        btn:SetDisable(true)
                        self:ShowBuyBtnSoldOutOrOwned(btn.transform, true)
                    else
                        allSellOut = false
                    end
                    -- 注册礼包购买
                    XUiHelper.RegisterClickEvent(self, btn, function()
                        self:OnClickPackage(package)
                    end)
                end
            else
                -- 美术去掉按钮，但是没有删除引用导致的报错，兼容一下
                XLog.Error("[XUiPanelRecommendBase] 找不到对应的btn:" .. btnName)
            end
        end
        -- else                                          -- 不配PurchasePackageId
        --     self.BtnBuy.gameObject:SetActiveEx(true)
        --     XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClicked)
    end

    if self.ImgSellOut then
        self.ImgSellOut.gameObject:SetActiveEx(allSellOut)
    end

    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClicked)

    -- self.TxtTime.gameObject:SetActiveEx(data:GetIsShowTimeTip())
    -- self.TxtTime.text = string.format("%s~%s", data:GetStartTimeDate(), data:GetEndTimeDate())
    -- self.ImgSellOut.gameObject:SetActiveEx(data:GetIsSellOut())
end

function XUiPanelRecommendBase:OnBtnBuyClicked()
    local skipSteps = self.Recommend:GetSkipSteps()
    if #skipSteps > 0 then
        if skipSteps[1] == XPurchaseConfigs.RecommendSkipType.Lb then
            self.SkipFunc(skipSteps[2], skipSteps[3])
        elseif skipSteps[1] == XPurchaseConfigs.RecommendSkipType.SkipId then
            XFunctionManager.SkipInterface(skipSteps[2])
        end
        return
    end
    if self.Recommend:GetIsSellOut() then
        XUiManager.TipErrorWithKey("PurchaseSettOut")
        return
    end
end

function XUiPanelRecommendBase:PlayEnableAnim()
    if not XTool.UObjIsNil(self.AnimEnable) then
        self.AnimEnable:Stop()
        self.AnimEnable:Play()
    end
end

-- v1.31显示购买按钮已售罄或者已拥有
function XUiPanelRecommendBase:ShowBuyBtnSoldOutOrOwned(btn, isSoldOut)
    local uiObject = btn:GetComponent("UiObject")
    if uiObject == nil then
        return
    end

    local txtSoldOut = uiObject:GetObject("TxtSoldOut", false)
    if txtSoldOut then
        txtSoldOut.gameObject:SetActiveEx(isSoldOut)
    end
    local rImgSoldOut = uiObject:GetObject("RImgSoldOut", false)
    if rImgSoldOut then
        rImgSoldOut.gameObject:SetActiveEx(isSoldOut)
    end
    local txtOwned = uiObject:GetObject("TxtOwned", false)
    if txtOwned then
        txtOwned.gameObject:SetActiveEx(not isSoldOut)
    end
    local rImgOwned = uiObject:GetObject("RImgOwned", false)
    if rImgOwned then
        rImgOwned.gameObject:SetActiveEx(not isSoldOut)
    end
end

return XUiPanelRecommendBase