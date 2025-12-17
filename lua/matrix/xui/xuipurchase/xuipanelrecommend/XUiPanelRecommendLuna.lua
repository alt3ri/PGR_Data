local XUiPanelRecommendBase = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendBase")

---@class XUiPanelRecommendLuna : XUiPanelRecommendBase 新手超S限定补给包（露娜）
local XUiPanelRecommendLuna = XClass(XUiPanelRecommendBase, "XUiPanelRecommendLuna")

function XUiPanelRecommendLuna:SetData(data, skipFunc, buyFinished)
    self.Super.SetData(self, data, skipFunc, buyFinished)
    self.BtnCharacterGo.CallBack = handler(self, self.OnBtnCharacterGoClick)
    self.CharacterId = CS.XGame.ClientConfig:GetInt("IceBreakingCharacterId")
    local package = self.Recommend:GetPurchasePackage()[1]
    local rewards = package:GetRewardGoodsList()
    for i, v in ipairs(rewards) do
        local btn = self[string.format("BtnGift%s", i)]
        if btn then
            btn:SetNameByGroup(0, string.format("x%s", v.Count))
            btn.CallBack = function()
                XLuaUiManager.Open("UiTip", v.TemplateId)
            end
        end
    end
end

function XUiPanelRecommendLuna:OnBtnCharacterGoClick()
    if XTool.IsNumberValid(self.CharacterId) then
        XLuaUiManager.Open("UiCharacterDetail", self.CharacterId)
    end
end

return XUiPanelRecommendLuna