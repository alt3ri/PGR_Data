local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---【体力】属性>200时，获得<坚毅> TODO：确认是否要一开始就挂上这个buff
---@class XBuffScript.10251601 : XTheatre6SkillBase
local XBuff10251601 = XDlcScriptManager.RegBuffScript(10251601, "XBuffScript10251601", XTheatre6SkillBase)

function XBuff10251601:ScriptInit(isGainControl) --初始化
    ---坚毅BuffId，TODO: 修改为正式的坚毅调用后删除
    self.blockBuffId = 1025105

    ---初始化时，若体力满足条件，则获得<坚毅>
    local stamina = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.Stamina)
    if stamina > 200 then
        ---TODO: 修改为正式的坚毅管理调用
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.blockBuffId, 1)
    end
end

return XBuff10251601
