local XUiPanelCharacterFileMain = require('XUi/XUiCharacterFiles/Default/XUiPanelCharacterFileMain')

--- 约战狂三联动
---@class XUiPanelCharacterFileDALMain: XUiPanelCharacterFileMain
---@field protected _Control
---@field Parent
local XUiPanelCharacterFileDALMain = XClass(XUiPanelCharacterFileMain, "XUiPanelCharacterFileDALMain")

---@overload
function XUiPanelCharacterFileDALMain:OnBtnStoryClick()
    local skipId = XFubenNewCharConfig.GetClientConfigNumByKey("DALStorySkipId")

    if XTool.IsNumberValidEx(skipId) then
        XFunctionManager.SkipInterface(skipId)
    else
        local result = XMVCA.XFavorability:OpenUiStory(self.ActivityCfg.CharacterId, XEnumConst.Favorability.FavorabilityStoryEntranceType.CharacterFile)

        if result == -2 then
            XLog.Error('配置的角色Id无效, TeachingActivity配置 Id:'..tostring(self.ActivityCfg.Id))
        end
    end
end

return XUiPanelCharacterFileDALMain