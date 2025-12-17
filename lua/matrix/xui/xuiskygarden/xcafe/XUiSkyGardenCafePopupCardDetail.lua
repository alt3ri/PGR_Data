
---@class XUiSkyGardenCafePopupCardDetail : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XSkyGardenCafeControl
local XUiSkyGardenCafePopupCardDetail = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenCafePopupCardDetail")

function XUiSkyGardenCafePopupCardDetail:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafePopupCardDetail:OnStart(cardId)
    self._CardId = cardId
    self:InitView()
end

function XUiSkyGardenCafePopupCardDetail:InitUi()
    self._PanelCard = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGCardItem").New(self.UiSkyGardenCafeCard, self)
end

function XUiSkyGardenCafePopupCardDetail:InitCb()
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

function XUiSkyGardenCafePopupCardDetail:InitView()
    self._PanelCard:RefreshDetail(self._CardId)
end