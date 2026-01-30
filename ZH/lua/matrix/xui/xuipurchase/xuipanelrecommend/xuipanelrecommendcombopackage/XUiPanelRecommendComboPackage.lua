local XUiPanelRecommendBase = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendBase")
local XUiPanelRecommendComboPackageGrid = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendComboPackage/XUiPanelRecommendComboPackageGrid")

---@class XUiPanelRecommendComboPackage : XUiPanelRecommendBase@捆绑包
local XUiPanelRecommendComboPackage = XClass(XUiPanelRecommendBase, "XUiPanelRecommendComboPackage")

function XUiPanelRecommendComboPackage:SetData(data, skipFunc, buyFinished)
    --XLog.Debug(data)
    --XUiPanelRecommendBase.SetData(self, data, skipFunc, buyFinished)
    ---@type XPurchaseRecommend
    self.Recommend = data
    self.SkipFunc = skipFunc
    self.BuyFinished = buyFinished
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnClickHelp)

    -- 捆绑包
    local uiDataCombo = XDataCenter.PurchaseManager.GetComboPurchaseData(XPurchaseConfigs.UiType.ComboPackage)

    if XTool.IsTableEmpty(uiDataCombo) then
        XLog.Error('对应UiType类型的捆绑包数据不存在，UiType：' .. tostring(XPurchaseConfigs.UiType.ComboPackage))
        return
    end
    
    local comboPackageIds = self.Recommend:GetCfgComboPackageIds()

    if XTool.IsTableEmpty(comboPackageIds) then
        XLog.Error('捆绑包关联字段为空，RecommendId：' .. tostring(self.Recommend.Config.Id))
        return
    end
    
    -- 4.0 现在显示貌似不支持多个捆绑包，先只按一个捆绑包处理
    local comboPackageId = comboPackageIds[1]
    local firstUiData = nil

    for i, v in pairs(uiDataCombo) do
        if v.Id == comboPackageId then
            firstUiData = v
            break
        end 
    end
    
    if not firstUiData then
        XLog.Error("对应礼包数据不存在，comboPackageId：" .. tostring(comboPackageId))
        return
    end

    -- 跳转其实是通过BtnBuy，而不是BtnHelp，目前的BtnHelp是无反应的
    ---@type XUiPanelRecommendComboPackageGrid
    self._BtnGiftBuy1 = XUiPanelRecommendComboPackageGrid.New(self.BtnGiftBuy1, self, self.BuyFinished, self.SkipFunc)
    self._BtnGiftBuy1:Update(firstUiData)
    if firstUiData.Discount and firstUiData.Discount > 0 then
        self.TxtDiscount.gameObject:SetActiveEx(true)
        self.TxtDiscount.text = XUiHelper.GetText("PurchaseDiscount", 100 - firstUiData.Discount)
    else
        self.TxtDiscount.gameObject:SetActiveEx(false)
    end

    for i = 2, 4 do
        local subData = firstUiData.SubDatas[i - 1]
        if subData then
            local btnName = "BtnGiftBuy" .. i
            local btn = self[btnName]
            if not XTool.UObjIsNil(btn) then
                local gridName = "_BtnGiftBuy" .. i
                self[gridName] = self[gridName] or XUiPanelRecommendComboPackageGrid.New(btn, self, self.BuyFinished, self.SkipFunc)
                self[gridName]:Update(firstUiData.SubDatas[i - 1])
            else
                -- 美术去掉按钮，但是没有删除引用导致的报错，兼容一下
                XLog.Error("[XUiPanelRecommendBase] 找不到对应的btn:" .. btnName)
            end
        else
            local btnName = "BtnGiftBuy" .. i
            local btn = self[btnName]
            if not XTool.UObjIsNil(btn) then
                btn.gameObject:SetActiveEx(false)
            else
                -- 美术去掉按钮，但是没有删除引用导致的报错，兼容一下
                XLog.Error("[XUiPanelRecommendBase] 找不到对应的btn:" .. btnName)
            end
        end
    end
    
    self.ComboData = firstUiData
end

function XUiPanelRecommendComboPackage:OnClickHelp()
    XLuaUiManager.Open("UiFubenDialog", XUiHelper.GetText("PurchaseComboTitle"), XUiHelper.GetText("PurchaseComboContent"))
end

return XUiPanelRecommendComboPackage