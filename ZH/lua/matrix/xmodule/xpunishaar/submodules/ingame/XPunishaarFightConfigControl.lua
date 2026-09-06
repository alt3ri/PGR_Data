--- 局内战斗控制器
---@type XPunishaarFightControl
---@field private _MainControl XPunishaarControl
local XPunishaarFightControl = XClassPartial("XPunishaarFightControl")

local TableKey = {
    -- Fight/Enemy/EnemySkill/Effect/EffectGroup/Trigger 已上提到 GameControl（GameConfigControl）单点登记，
    -- FightControl 经 _MainControl(=GameControl) 借用；本 Control 仅自登记 Buff（battle-only）
    PunishaarBuff = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
}

function XPunishaarFightControl:InitConfig()
    --初始化配置表
    self:InitConfigByTabKey("Punishaar", TableKey)
    
    --- 内部事件枚举定义（须与 STECustomEnum.EventEnum 对齐：Drain 出的枚举键即经 DispatchEvent 派发）
    self.EventIds = {
        PlayerHPChanged = 1,
        EnemyHPChanged = 2,
        BallListChanged = 3,
        CardCdChanged = 4,
        PlayerShieldChanged = 5,
        EnemyShieldChanged = 6,
        CardBallProductChanged = 7,
        CardBallConsumeChanged = 8,
        CardAttackAnim = 9,  -- 卡牌攻击动画（Pipeline 善后派发，与 STECustomEnum.EventEnum 对齐）#71
        AttackEffect = 10,  -- 攻击特效（AttackTarget 内 Emit，payload 含 ownerId/targetId，与 STECustomEnum.EventEnum 对齐）#73
        DeathAnim = 11,  -- 死亡动画触发（CheckBattleEnd death gate 帧末直接 DispatchEvent，与 STECustomEnum.EventEnum 对齐）#75
        FatigueAnim = 12,  -- 疲劳弹窗动画（EffectGroup 组末尾 EmitEvent 派发，与 STECustomEnum.EventEnum 对齐）#80
        EnemyAttackPrepare = 13,  -- 敌人准备攻击（ExecuteEnemyEffects 激发时 Emit，与 STECustomEnum.EventEnum 对齐）#EnemyAttack
        DotBuffLayerChanged = 14,  -- buff Layer 变化（SnapshotFieldToBuff 值变/销毁前 Emit，与 STECustomEnum.EventEnum 对齐；PanelEnemyHp buff 图标列表订阅）

        -- 战斗流程事件（非 STE present 事件，直接由 FightControl 派发；号段与上面 present 事件错开避免撞号）
        BattleEnded = 101,      -- 战斗结束，携带 result（见 XPunishaarFightControl.BattleResult）
        SpawnDamageNumber = 102,  -- 受伤飘字（coordinator=PanelFighting 派发，payload: pos/atkPerHit/attackTimes/isCrit；飘字系统 DamageNumberPlayer 订阅）#飘字

        OnPause = 201,  -- 打开暂停界面
        OnResume = 202, -- 关闭暂停界面（非退出）
    }
end

---@return XTablePunishaarCard
function XPunishaarFightControl:GetTablePunishaarCard(id, notips)
    -- Card 表在根 Control（ConfigControl）；FightControl 经 typed 祖父接口借（_MainControl 现指 GameControl 非根）
    return self._GameControl:GetControl():GetTablePunishaarCard(id, notips)
end

---@return XTablePunishaarCardLevel
function XPunishaarFightControl:GetTablePunishaarCardLevel(id, notips)
    return self._GameControl:GetControl():GetTablePunishaarCardLevel(id, notips)
end

---@return XTablePunishaarEffect
function XPunishaarFightControl:GetTablePunishaarEffect(id, notips)
    -- Effect 表单点登记在 GameControl（GameConfigControl）；FightControl 经 _MainControl(=GameControl) 借用
    return self._MainControl:GetTablePunishaarEffect(id, notips)
end

---@return XTablePunishaarEffectGroup
function XPunishaarFightControl:GetTablePunishaarEffectGroup(id, notips)
    return self._MainControl:GetTablePunishaarEffectGroup(id, notips)
end

---@return XTablePunishaarTrigger
function XPunishaarFightControl:GetTablePunishaarTrigger(id, notips)
    return self._MainControl:GetTablePunishaarTrigger(id, notips)
end

---@return XTablePunishaarBuff
function XPunishaarFightControl:GetTablePunishaarBuff(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarBuff, id, notips)
end

---@return XTablePunishaarFight
function XPunishaarFightControl:GetTablePunishaarFight(id, notips)
    -- Fight 表单点登记在 GameControl；FightControl 经 _MainControl(=GameControl) 借用
    return self._MainControl:GetTablePunishaarFight(id, notips)
end

---@return XTablePunishaarEnemy
function XPunishaarFightControl:GetTablePunishaarEnemy(id, notips)
    return self._MainControl:GetTablePunishaarEnemy(id, notips)
end

---@return XTablePunishaarEnemySkill
function XPunishaarFightControl:GetTablePunishaarEnemySkill(id, notips)
    return self._MainControl:GetTablePunishaarEnemySkill(id, notips)
end

function XPunishaarFightControl:GetConfigCardEffectGroupId(cardId)
    local cardCfg = self:GetTablePunishaarCard(cardId)
    return cardCfg and cardCfg.EffectGroupId
end

function XPunishaarFightControl:GetConfigCardColor(cardId)
    local cardCfg = self:GetTablePunishaarCard(cardId)
    return cardCfg and cardCfg.Color
end

--- 取本场敌人（Fight）的 EffectGroupId 列表：Fight.EnemySkill[] → 各 EnemySkill.Effect(EffectGroupId 数组)。
--- 填充式：写入调用方提供的 out 表并返回个数（out 调用方自清）。
--- 注：EnemySkill.Effect 字段类型为数组（Type1ValueTypeint），逐个展开为 EffectGroupId。
---@param fightId number 本场 Fight.Id
---@param out table 调用方提供并自清的容器，按序写入 EffectGroupId
---@return number count
function XPunishaarFightControl:GetEnemyEffectGroupIds(fightId, out)
    local fightCfg = self:GetTablePunishaarFight(fightId)
    if not fightCfg or not fightCfg.EnemySkill then
        return 0
    end
    local count = 0
    for _, skillId in ipairs(fightCfg.EnemySkill) do
        local skillCfg = self:GetTablePunishaarEnemySkill(skillId)
        if skillCfg and skillCfg.Effect then
            for _, groupId in ipairs(skillCfg.Effect) do   -- Effect 为 EffectGroupId 数组
                count = count + 1
                out[count] = groupId
            end
        end
    end
    return count
end

--- 敌人头像
--- 找不到返回空串。
---@return string
function XPunishaarFightControl:GetEnemyRImg()
    if not self._BattleInitData then
        return ""
    end
    local fightCfg = self:GetTablePunishaarFight(self._BattleInitData:GetFightId())
    if not fightCfg then
        return ""
    end
    local enemyCfg = self:GetTablePunishaarEnemy(fightCfg.EnemyId)
    return enemyCfg and enemyCfg.EnemyHead or ""
end

return XPunishaarFightControl