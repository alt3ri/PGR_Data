
---@class XUiMiniGamesCollectionRewardShop : XLuaUi
---@field _Control XGameCollectionControl

local SetUpType = {
    Task = 1,
    Shop = 2,
}
local XUiMiniGamesCollectionRewardShop = XLuaUiManager.Register(XLuaUi, "UiMiniGamesCollectionRewardShop")
local XUiPanelRewardShopTask = require("XUi/XUiGameCollection/XUiMiniGamesCollectionRewardShop/XUiPanelRewardShopTask")
local XUiPanelRewardShopShop = require("XUi/XUiGameCollection/XUiMiniGamesCollectionRewardShop/XUiPanelRewardShopShop")
function XUiMiniGamesCollectionRewardShop:OnAwake()
    self:InitComponents()
end

function XUiMiniGamesCollectionRewardShop:InitComponents()
    -- Back Mainui Help
    self:BindExitBtns()
    local itemId = tonumber(self._Control:GetGameCollectionConfig("ItemId"))
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({itemId}, self.PanelSpecialTool, self)
    self.BtnShop:AddEventListener(function() self:OnBtnSetUpTypeClick(SetUpType.Shop) end)
    self.BtnTask:AddEventListener(function() self:OnBtnSetUpTypeClick(SetUpType.Task) end)
    self.PanelRewardShopTask = XUiPanelRewardShopTask.New(self.PanelTaskStory, self)
    self.PanelRewardShopShop = XUiPanelRewardShopShop.New(self.PanelShopList, self)
    self.PanelRewardShopShop:Close()
    self.PanelRewardShopTask:Close()
end

function XUiMiniGamesCollectionRewardShop:OnEnable()
    self:UpdateReddot()
end
function XUiMiniGamesCollectionRewardShop:UpdateReddot()
    self.BtnTask:ShowReddot(XMVCA.XGameCollection:HasRewardCanGet())
    self.BtnShop:ShowReddot(XMVCA.XGameCollection:CheckActivityTips() and XMVCA.XGameCollection:HasGoodCanBuy())
end

function XUiMiniGamesCollectionRewardShop:OnBtnSetUpTypeClick(uiType)
   self.SetUpType = uiType
   self:Refresh()
end


function XUiMiniGamesCollectionRewardShop:OnStart(uiType)
    self.SetUpType = uiType
    self:Refresh()
end


function XUiMiniGamesCollectionRewardShop:Refresh()
    if self.SetUpType == SetUpType.Task then
        self.PanelRewardShopTask:Open()
        self.PanelRewardShopTask:Refresh()
        self.PanelRewardShopShop:Close()
    elseif self.SetUpType == SetUpType.Shop then
        
        self.PanelRewardShopShop:Open()
        self.PanelRewardShopShop:Refresh()
        self.PanelRewardShopTask:Close()
        
        XMVCA.XGameCollection:MarkRewardShopEntered()
        self:UpdateReddot()
    end
    self.BtnShop:SetButtonState(self.SetUpType == SetUpType.Shop and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.BtnTask:SetButtonState(self.SetUpType == SetUpType.Task and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end


return XUiMiniGamesCollectionRewardShop
