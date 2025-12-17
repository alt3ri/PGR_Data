local XUiBigWorldProcessCoreActivity = require("XUi/XUiBigWorld/XProcess/Core/XUiBigWorldProcessCoreActivity")

---@class XUiBigWorldProcessCoreStoryGrid : XUiBigWorldProcessCoreActivity
---@field ImgLock UnityEngine.UI.Image
---@field Parent XUiBigWorldProcessCoreStory
local XUiBigWorldProcessCoreStoryGrid = XClass(XUiBigWorldProcessCoreActivity, "XUiBigWorldProcessCoreStoryGrid")

function XUiBigWorldProcessCoreStoryGrid:OnBtnHelpClick()
end

function XUiBigWorldProcessCoreStoryGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnGo:AddEventListener(handler(self, self.OnBtnGoClick))
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreStoryGrid:_RefreshLocked(elementEntity)
    self.ImgLock.gameObject:SetActiveEx(elementEntity:IsLocked())
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreStoryGrid:_RefreshBackground(elementEntity)
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreStoryGrid:_RefreshHelp(elementEntity)
end

return XUiBigWorldProcessCoreStoryGrid
