local XUiPaintingExperiencePassV4P2 = require("XUi/XUiPaintingExperiencePassV4P2/XUiPaintingExperiencePassV4P2")

---@class XUiPaintingExperiencePassV407Kalie : XUiPaintingExperiencePassV4P2 卡列特殊试玩关界面
local XUiPaintingExperiencePassV407Kalie = XLuaUiManager.Register(XUiPaintingExperiencePassV4P2, "UiPaintingExperiencePassV407Kalie")

function XUiPaintingExperiencePassV407Kalie:OnEnable()
    --首次打开时OnStart已加载模型，无需重复刷新
    if not self.IsEnabled then
        self.IsEnabled = true
        return
    end
    if self.RoleModelPanel then
        -- 如果界面被隐藏C#里的回调会被清空，再次显示的时候需要重新调用刷新模型，如果不刷新会导致特效不会重复播放。
        self:UpdateModelRole()
    end
end

return XUiPaintingExperiencePassV407Kalie
