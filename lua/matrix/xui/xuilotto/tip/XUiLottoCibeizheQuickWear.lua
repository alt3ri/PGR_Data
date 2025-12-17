local XUiLottoQuickWearBase = require("XUi/XUiLotto/Tip/XUiLottoQuickWearBase")
---@class XUiLottoCibeizheQuickWear : XUiLottoQuickWearBase
local XUiLottoCibeizheQuickWear = XLuaUiManager.Register(XUiLottoQuickWearBase, "UiLottoCibeizheQuickWear")

function XUiLottoCibeizheQuickWear:DoGetCharacterId()
    return XLottoConfigs.GetLottoClientConfigNumber("CibeizheWeaponCharacter")
end

return XUiLottoCibeizheQuickWear