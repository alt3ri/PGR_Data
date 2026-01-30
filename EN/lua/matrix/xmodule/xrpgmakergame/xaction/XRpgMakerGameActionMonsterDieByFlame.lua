local XRpgMakerGameActionBase = require("XModule/XRpgMakerGame/XAction/XRpgMakerGameActionBase")

---@class XRpgMakerGameActionMonsterDieByFlame:XRpgMakerGameActionBase
local XRpgMakerGameActionMonsterDieByFlame = XClass(XRpgMakerGameActionBase, "XRpgMakerGameActionMonsterDieByFlame")

-- 继承类初始化
function XRpgMakerGameActionMonsterDieByFlame:OnInit()
    
end

-- 执行
function XRpgMakerGameActionMonsterDieByFlame:Execute()
    ---@type XRpgMakerGameMonsterData
    local monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(self.ActionData.MonsterId)
    if monsterObj then
        monsterObj:LoadBurnedEffect()
        monsterObj:LoadDieEffect(function()
            self:Complete()
        end)
    else
        XLog.Error("未找到怪物对象！ActionData = " .. XLog.Dump(self.ActionData))
        self:Complete()
    end
end

return XRpgMakerGameActionMonsterDieByFlame