local XUiFashionDetail = require("XUi/XUiFashion/XUiFashionDetail")

local XUiPassportFashionDetail = XLuaUiManager.Register(
    XUiFashionDetail,
    "UiPassportFashionDetail")

function XUiPassportFashionDetail:OnAwake()
    self.BtnBuy.gameObject:SetActiveEx(false)
    self.BtnBuy = self.BtnPassport
    XUiFashionDetail.OnAwake(self)
end

--- 执行正常购买流程前的处理，用于特殊逻辑
function XUiPassportFashionDetail:OnBeforeBtnBuyClick(cb)
    --3.1莉莉丝可肝卡池特殊涂装
    local lilithFashionId = XGachaConfigs.GetClientConfigNumber('SpeicalFashionFromPurchaseToGachaShop', 1)

    if XTool.IsNumberValid(lilithFashionId) and lilithFashionId == self.FashionId and not self.BuyData.FromGachaShop then
        local skipCondition = XGachaConfigs.GetClientConfigNumber('SpecialConditionFromPurchaseToGachaShop', 1)
        -- 判断条件满足，因为具有特殊性，未配置视为不可跳转
        if XTool.IsNumberValid(skipCondition) and XConditionManager.CheckCondition(skipCondition) then
            local skipId = XGachaConfigs.GetClientConfigNumber('SpecialSkipToGachaShop', 1)
            if XTool.IsNumberValid(skipId) then
                XLuaUiManager.Open('UiGachaCanLiverDialog', cb, skipId)
                return
            end
        end
    end

    if cb then
        cb()
    end
end

return XUiPassportFashionDetail
