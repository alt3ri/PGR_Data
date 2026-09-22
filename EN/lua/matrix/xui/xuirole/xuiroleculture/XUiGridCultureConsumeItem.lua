-- 角色养成消耗材料 Grid：持有量 = 真实持有 + 自动兑换可补足量
local _, COLOR_CONDITION_OK = CS.UnityEngine.ColorUtility.TryParseHtmlString("#0f70bc")
local _, COLOR_CONDITION_LACK = CS.UnityEngine.ColorUtility.TryParseHtmlString("#E43730")
local DEFAULT_CONDITION_COLOR = {
    [true] = COLOR_CONDITION_OK,
    [false] = COLOR_CONDITION_LACK,
}

---@class XUiGridCultureConsumeItem : XUiNode
local XUiGridCultureConsumeItem = XClass(XUiNode, "XUiGridCultureConsumeItem")

function XUiGridCultureConsumeItem:OnStart()
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClickClick))
end

--- @param data table { ItemId 材料 id, NeedCount 需求数量, ExchangeGain 自动兑换可补足量 }
function XUiGridCultureConsumeItem:Update(data)
    self:RemoveCountListener()

    self.ItemId = data.ItemId
    self.NeedCount = data.NeedCount
    self.ExchangeGain = data.ExchangeGain or 0

    self:InitItemInfo()
    self:UpdateHaveCount()

    XDataCenter.ItemManager.AddCountUpdateListener(self.ItemId, function()
        self:UpdateHaveCount()
    end, self.TxtHaveCount)
end

function XUiGridCultureConsumeItem:RemoveCountListener()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self.TxtHaveCount)
end

function XUiGridCultureConsumeItem:InitItemInfo()
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.ItemId)

    self.RImgIcon:SetRawImage(goodsShowParams.Icon)
    XUiHelper.SetQualityIcon(self.Parent, self.ImgQuality, goodsShowParams.Quality)
    self.TxtNeedCount.text = "/" .. self.NeedCount
end

function XUiGridCultureConsumeItem:UpdateHaveCount()
    -- 持有量叠加自动兑换可补足量
    local haveCount = XDataCenter.ItemManager.GetCount(self.ItemId) + self.ExchangeGain

    self.TxtHaveCount.text = haveCount
    self.TxtHaveCount.color = DEFAULT_CONDITION_COLOR[haveCount >= self.NeedCount]
end

function XUiGridCultureConsumeItem:OnDisable()
    self:RemoveCountListener()
end

function XUiGridCultureConsumeItem:OnBtnClickClick()
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(self.ItemId))
end

return XUiGridCultureConsumeItem
