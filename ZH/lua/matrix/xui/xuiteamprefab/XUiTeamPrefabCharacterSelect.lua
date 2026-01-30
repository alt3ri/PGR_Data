local XUiBattleRoomRoleDetail = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetail")
local XUiTeamPrefabCharacterSelect = XLuaUiManager.Register(XUiBattleRoomRoleDetail, "UiTeamPrefabCharacterSelect")

function XUiTeamPrefabCharacterSelect:Close()
    self.Super.Super.Close(self)
end

return XUiTeamPrefabCharacterSelect