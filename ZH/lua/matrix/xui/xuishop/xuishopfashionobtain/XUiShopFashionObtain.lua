local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@field _Control XShopControl
---@class XUiShopFashionObtain : XLuaUi
local XUiShopFashionObtain = XLuaUiManager.Register(XLuaUi, "UiShopFashionObtain")

local ConditionId = 601000
local SkipId = 89076
function XUiShopFashionObtain:OnAwake()
    self:InitComponents()
end

function XUiShopFashionObtain:InitComponents()
    -- Button
    -- 这个是真<Button>
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.BtnGo:AddEventListener(handler(self, self.OnBtnGoClick))
    ---@type XUiGridCommon
    self.GridFashion = XUiGridCommon.New(self, self.GridCommon)
end

function XUiShopFashionObtain:OnStart(rewardGoodsList)
    self.goodsInfo = rewardGoodsList and rewardGoodsList[1]
    if self.goodsInfo then
        self:Update()
        self.GridFashion:Refresh(self.goodsInfo)
    end
    self.BtnGo.gameObject:SetActiveEx(XConditionManager.CheckCondition(ConditionId))
end

function XUiShopFashionObtain:OnEnable()
end

function XUiShopFashionObtain:OnDisable()
end

function XUiShopFashionObtain:OnDestroy()
end

function XUiShopFashionObtain:Update()
    -- self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.goodsInfo.TemplateId)
    self.TxtDesc.text = XMVCA.XBigWorldCommanderDIY:GetDlcPlayerFashionPartConfigById(self.goodsInfo.TemplateId)
                            .ObtainDesc
    self.BtnGo:SetButtonState(CS.UiButtonState.Normal)
end

function XUiShopFashionObtain:OnBtnCloseClick(eventData)
    self:Close()
end

function XUiShopFashionObtain:OnBtnGoClick(eventData)
    self:Close()
    XFunctionManager.SkipInterface(SkipId)
end

return XUiShopFashionObtain
