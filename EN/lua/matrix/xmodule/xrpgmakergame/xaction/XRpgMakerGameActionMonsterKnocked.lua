local XRpgMakerGameActionBase = require("XModule/XRpgMakerGame/XAction/XRpgMakerGameActionBase")

---@class XRpgMakerGameActionMonsterKnocked:XRpgMakerGameActionBase
local XRpgMakerGameActionMonsterKnocked = XClass(XRpgMakerGameActionBase, "XRpgMakerGameActionMonsterKnocked")

-- 继承类初始化
function XRpgMakerGameActionMonsterKnocked:OnInit()
    
end

-- 执行
function XRpgMakerGameActionMonsterKnocked:Execute()
    ---@type XRpgMakerGameMonsterData
    local monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(self.ActionData.MonsterId)
    monsterObj:PlayFlyAwayAction(self.ActionData, function()
        self:Complete()
    end)
    if monsterObj.MonsterType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.Sepaktakraw then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_SepaktakrawKnock)
    else
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_MonsterKnock)
    end
end

return XRpgMakerGameActionMonsterKnocked