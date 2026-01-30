---@class XUiFashionSuitPopupPic : XLuaUi
---@field _Control XFashionSuitControl
local XUiFashionSuitPopupPic = XLuaUiManager.Register(XLuaUi, "UiFashionSuitPopupPic")

function XUiFashionSuitPopupPic:OnAwake()
    self.BtnClose.CallBack = handler(self, self.Close)
end

function XUiFashionSuitPopupPic:OnStart(fashionId)
    local config = XFashionConfigs.GetFashionTemplate(fashionId)
    if not string.IsNilOrEmpty(config.FashionSuitPic) then
        self.RImgPic:SetRawImage(config.FashionSuitPic)
    end
end

return XUiFashionSuitPopupPic