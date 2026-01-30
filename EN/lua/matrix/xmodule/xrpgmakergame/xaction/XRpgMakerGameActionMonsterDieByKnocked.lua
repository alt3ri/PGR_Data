local XRpgMakerGameActionBase = require("XModule/XRpgMakerGame/XAction/XRpgMakerGameActionBase")

---@class XRpgMakerGameActionMonsterDieByKnocked:XRpgMakerGameActionBase
local XRpgMakerGameActionMonsterDieByKnocked = XClass(XRpgMakerGameActionBase, "XRpgMakerGameActionMonsterDieByKnocked")

-- 继承类初始化
function XRpgMakerGameActionMonsterDieByKnocked:OnInit()
    
end

-- 执行
function XRpgMakerGameActionMonsterDieByKnocked:Execute()
    ---@type XRpgMakerGameMonsterData
    local monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(self.ActionData.MonsterId)
    if monsterObj then
        monsterObj:LoadDieEffect(function()
            self:Complete()
        end)
    else
        XLog.Error("未找到怪物对象！ActionData = " .. XLog.Dump(self.ActionData))
        self:Complete()
    end
end

return XRpgMakerGameActionMonsterDieByKnocked