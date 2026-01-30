---@class XMainLineLuosaitaPositionInfo
local XMainLineLuosaitaPositionInfo = XClass(nil, "XMainLineLuosaitaPositionInfo")

function XMainLineLuosaitaPositionInfo:Ctor(id)
    ---@type number 位置Id
    self._PosId = id
    ---@type number 节点类型
    self._Type = XMVCA.XMainLineLuosaita.EnumConst.POS_TYPE.EMPTY
    ---@type number 地块Id
    self._BlockId = 0
    ---@type number 关卡id
    self._StageId = 0
    ---@type number 角色id
    self._CharacterId = 0
    ---@type number 友军Id
    self._ArmyId = 0
    ---@type number 友军当前血量
    self._ArmyCurHp = 0
    ---@type number 友军额外攻击力
    self._ArmyExtraAttack = 0
    ---@type number 敌军Id
    self._EnemyId = 0
    ---@type number 敌军当前血量
    self._EnemyCurHp = 0
    ---@type number 敌军额外攻击力
    self._EnemyExtraAttack = 0
end

-- 刷新整个阶段数据
function XMainLineLuosaitaPositionInfo:RefreshData(data)
    self._Type = data.Type
    self._BlockId = data.BlockId
    self._StageId = data.StageId
    self._CharacterId = data.CharacterId
    
    -- 友军数据
    local armyInfo = data.ArmyInfo
    self._ArmyId = 0
    self._ArmyCurHp = 0
    self._ArmyExtraAttack = 0
    if armyInfo then
        self._ArmyId = armyInfo.Id
        self._ArmyCurHp = armyInfo.CurHp
        self._ArmyExtraAttack = armyInfo.ExtraAttack
    end
    
    -- 敌军数据
    local enemyInfo = data.EnemyInfo
    self._EnemyId = 0
    self._EnemyCurHp = 0
    self._EnemyExtraAttack = 0
    if enemyInfo then
        self._EnemyId = enemyInfo.Id
        self._EnemyCurHp = enemyInfo.CurHp
        self._EnemyExtraAttack = enemyInfo.ExtraAttack
    end
end

-- 获取位置Id
function XMainLineLuosaitaPositionInfo:GetPosId()
    return self._PosId
end

-- 获取节点类型
function XMainLineLuosaitaPositionInfo:GetType()
    return self._Type
end

-- 是否是我军
function XMainLineLuosaitaPositionInfo:IsArmy()
    return self._Type == XMVCA.XMainLineLuosaita.EnumConst.POS_TYPE.ARMY
end

-- 是否是敌军
function XMainLineLuosaitaPositionInfo:IsEnemy()
    return self._Type == XMVCA.XMainLineLuosaita.EnumConst.POS_TYPE.ENEMY
end

-- 是否是角色
function XMainLineLuosaitaPositionInfo:IsCharacter()
    return self._Type == XMVCA.XMainLineLuosaita.EnumConst.POS_TYPE.CHARACTER
end

-- 是否是关卡
function XMainLineLuosaitaPositionInfo:IsStage()
    return self._Type == XMVCA.XMainLineLuosaita.EnumConst.POS_TYPE.STAGE
end

function XMainLineLuosaitaPositionInfo:GetBlockId()
    return self._BlockId
end

-- 获取关卡Id
function XMainLineLuosaitaPositionInfo:GetStageId()
    return self._StageId
end

-- 获取角色Id
function XMainLineLuosaitaPositionInfo:GetCharacterId()
    return self._CharacterId
end

-- 获取友军Id
function XMainLineLuosaitaPositionInfo:GetArmyId()
    return self._ArmyId
end

-- 获取敌军Id
function XMainLineLuosaitaPositionInfo:GetEnemyId()
    return self._EnemyId
end

-- 获取额外攻击力
---@return number
function XMainLineLuosaitaPositionInfo:GetExtraAttack()
    if self:IsArmy() then
        return self._ArmyExtraAttack
    elseif self:IsEnemy() then
        return self._EnemyExtraAttack
    end
    return 0
end

-- 获取血量
---@return number
function XMainLineLuosaitaPositionInfo:GetCurHp()
    if self:IsArmy() then
        return self._ArmyCurHp
    elseif self:IsEnemy() then
        return self._EnemyCurHp
    end
    return 0
end

return XMainLineLuosaitaPositionInfo
