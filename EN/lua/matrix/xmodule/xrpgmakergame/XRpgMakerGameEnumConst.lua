local XRpgMakerGameEnumConst = {
    -- 关卡状态
    RpgMakerGameStageStatus = {
        Lock = 1,       --未开启
        UnLock = 2,     --已开启
        Clear = 3,      --已通关
        Perfect = 4,    --满星通关
    },
    -- 方向
    RpgMakerGameMoveDirection = {
        MoveLeft = 1,
        MoveRight = 2,
        MoveUp = 3,
        MoveDown = 4,
    },
    -- 特效方向旋转值，默认朝下
    RpgMakerGameDirectionRotation = {
        -90,
        90,
        0,
        180,
    },
    -- 行动类型
    RpgMakerGameActionType = {
        ActionNone = 0,
        ActionPlayerMove = 1,                   --玩家移动
        ActionKillMonster = 2,                  --杀死怪物
        ActionStageWin = 3,                     --关卡胜利
        ActionEndPointOpen = 4,                 --终点开启
        ActionMonsterRunAway = 5,               --怪物逃跑
        ActionMonsterChangeDirection = 6,       --怪物调整方向
        ActionMonsterKillPlayer = 7,            --怪物杀死玩家
        ActionTriggerStatusChange = 8,          --机关状态改变
        ActionMonsterPatrol = 9,                --怪物巡逻
        ActionUnlockRole = 10,                  --解锁角色
        ActionMonsterPatrolLine = 11,           --怪物巡逻路线
        ActionShadowMove = 12,                  --影子移动
        ActionShadowDieByTrap = 13,             --影子掉落陷阱
        ActionPlayerDieByTrap = 14,             --玩家掉落陷阱
        ActionMonsterDieByTrap = 15,            --怪物掉落陷阱
        ActionElectricStatusChange = 16,        --电墙状态改变
        ActionPlayerKillByElectricFence = 17,   --玩家被电墙杀死
        ActionMonsterKillByElectricFence = 18,  --怪物被电墙杀死
        ActionHumanKill = 19,                   --人类被杀，关卡失败
        ActionSentrySign = 20,                  --产生哨戒的标记
        ActionPlayerTransfer = 21,              --玩家传送
        ActionBurnGrass = 22,                   --燃烧草圃
        ActionGrowGrass = 23,                   --草圃生长
        ActionPlayerDrown = 24,                 --玩家淹死
        ActionMonsterDrown = 25,                --怪物淹死
        ActionSteelBrokenToTrap = 26,           --钢板破损变成陷阱
        ActionSteelBrokenToFlat = 27,           --钢板破损消失
        ActionMonsterTransfer = 28,             --怪物传送
        -- 4.0
        ActionShadowKillByElectricFence = 29,   --影子被电墙杀死
        ActionMonsterKillShadow = 30,           --怪物杀死影子
        ActionShadowDrown = 31,                 --影子淹死
        ActionBubbleBroken = 32,                --泡泡破裂
        ActionBubbleMove = 33,                  --泡泡移动
        ActionShadowPickupDrop = 34,            --影子拾取掉落物
        ActionPlayerPickupDrop = 35,            --玩家拾取掉落物
        ActionMagicTrigger = 36,                --魔法阵转换位置
        ActionShadowKillMonster = 37,           --影子击杀怪物
        -- 5.0
        ActionSkillTypeChange = 38,             -- 属性变化
        ActionMonsterKnocked = 39,              -- 怪物被击飞
        ActionWaterStatusChange = 40,           -- 水池状态改变
        ActionTorchStatusChange = 41,           -- 火炬状态改变
        ActionMonsterDieByFlame = 42,           -- 怪物被烧死
        ActionMonsterDieByKnocked = 43,         -- 怪物被物理撞死
    },
    -- 缝隙类型
    RpgMakerGapDirection = {
        GridLeft = 1,   --格子左边线
        GridRight = 2,  --格子右边线
        GridTop = 3,    --格子顶部线
        GridBottom = 4, --格子底部线
    },
    -- 终点类型
    XRpgMakerGameEndPointType = {
        DefaultClose = 0,  --默认关闭
        DefaultOpen = 1,    --默认开启
    },
    -- 阻挡状态
    XRpgMakerGameBlockStatus = {
        UnBlock = 0,    --不阻挡
        Block = 1,      --阻挡
    },
    -- 怪物类型
    XRpgMakerGameMonsterType = {
        Normal = 1,     --小怪
        BOSS = 2,
        Human = 3,      --人类
        Sepaktakraw = 4,     -- 藤球
    },
    -- 怪物攻击范围方向
    XRpgMakerGameMonsterViewAreaType = {
        ViewFront = 1,  --怪物的前方
        ViewBack = 2,   --怪物的后面
        ViewLeft = 3,   --怪物的左边
        ViewRight = 4,  --怪物的右边
    },
    -- 机关类型
    XRpgMakerGameTriggerType = {
        Trigger1 = 1,   --本身是不能阻挡，停在上面可以触发类型2的机关状态转变
        Trigger2 = 2,   --由类型1触发
        Trigger3 = 3,   --经过后，会从通过状态转变为阻挡状态
        TriggerElectricFence = 4,   --电围栏触发机关
    },
    -- 电墙机关（开关）状态
    XRpgMakerGameElectricStatus = {
        CloseElectricFence = 0,     --关闭电网
        OpenElectricFence = 1,      --开启电网
    },
    -- 电网状态
    XRpgMakerGameElectricFenceStatus = {
        Close = 0,      --关闭
        Open = 1,       --开启
    },
    -- 答案类型
    XRpgMakerGameRoleAnswerType = {
        Hint = 1,       --提示
        Answer = 2,     --答案
    },
    -- 属性类型
    XRpgMakerGameRoleSkillType = {
        Crystal = 1,    --冰
        Flame = 2,      --火
        Thunder = 3,    --雷
        Dark = 4,       --暗
        Physics = 5,    --物理
        Physics2 = 6,   --物理2 效果：撞到草回反弹
        Flame2 = 7,     --火2 效果：会点燃草/火炬
    },
    -- 实体类型
    XRpgMakerGameEntityType = {
        Water = 1,      --水
        Ice = 2,        --冰
        Grass = 3,      --草圃
        Steel = 4       --钢板
    },
    -- 水类型
    XRpgMakerGameWaterType = {
        Water = 1,      --水
        Ice = 2,        --冰
        Disappear = 3,  --消失
    },
    XRpgMakerTransferPointColor = {
        Green = 1,      --
        Yellow = 2,      --
        Purple = 3,      --
    },
    -- 钢板破损后的类型
    XRpgMakerGameSteelBrokenType = {
        Init = 0,       --默认状态
        Flat = 1,       --变成平地
        Trap = 2,       --变成陷阱
    },
    -- 地块合表分类
    XRpgMakeBlockMetaType = {
        BlockType = 1,
        StartPoint = 2,     -- 起点
        EndPoint = 3,       -- 终点
        Gap = 4,            -- 墙壁
        ElectricFence = 5,  -- 电墙
        Trap = 6,           -- 陷阱
        Shadow = 7,         -- 影子
        Trigger = 8,        -- 机关
        Water = 9,          -- 水
        Ice = 10,           -- 冰
        Grass = 11,         -- 草
        Steel = 12,         -- 钢板
        TransferPoint = 13, -- 传送点
        Monster = 14,       -- 怪物
        Bubble = 15,        -- 泡泡
        Drop = 16,          -- 凋落物
        Magic = 17,         -- 魔法阵
        SwitchSkillType = 18,-- 换属性阵
        Torch = 19,         -- 火炬
    },
    -- 小地图提示图标配置表的key
    RpgMakerGameHintIconKeyMaps = {
        BlockIcon = "BlockIcon",
        NormalMonsterIcon = "NormalMonsterIcon",
        BossIcon = "BossIcon",
        TriggerIcon1 = "TriggerIcon1",
        TriggerIcon2 = "TriggerIcon2",
        TriggerIcon3 = "TriggerIcon3",
        ElectricFencTrigger = "ElectricFencTrigger",
        GapIcon = "GapIcon",
        ShadowIcon = "ShadowIcon",
        ElectricFenceIcon = "ElectricFenceIcon",
        HumanIcon = "HumanIcon",
        Sepaktakraw = "Sepaktakraw",
        StartPointIcon = "StartPointIcon",
        EndPointIcon = "EndPointIcon",
        TrapIcon = "TrapIcon",
        MoveLineIcon = "MoveLineIcon",
        CrystalMonsterIcon = "CrystalMonsterIcon",
        FlameMonsterIcon = "FlameMonsterIcon",
        RaidenMonsterIcon = "RaidenMonsterIcon",
        DarkMonsterIcon = "DarkMonsterIcon",
        CrystalBossIcon = "CrystalBossIcon",
        FlameBossIcon = "FlameBossIcon",
        RaidenBossIcon = "RaidenBossIcon",
        DarkBossIcon = "DarkBossIcon",
        EntityIcon1 = "EntityIcon1",
        EntityIcon2 = "EntityIcon2",
        EntityIcon3 = "EntityIcon3",
        EntityIcon4 = "EntityIcon4",
        TransferPointIcon1 = "TransferPointIcon1",
        TransferPointIcon2 = "TransferPointIcon2",
        TransferPointIcon3 = "TransferPointIcon3",
        Bubble = "Bubble",
        Drop1 = "Drop1",
        Drop2 = "Drop2",
        Drop3 = "Drop3",
        Drop4 = "Drop4",
        Magic = "Magic",
        SwitchSkillPoint = "SwitchSkillPoint",
        Torch = "Torch",
    },
    -- 模型/特效的key（RpgMakerGameModel.tab）
    ModelKeyMaps = {
        GoldClose = "GoldClose",
        Gap = "Gap",
        TriggerType3 = "TriggerType3",
        ViewArea = "ViewArea",
        TriggerType1 = "TriggerType1",
        GoldOpen = "GoldOpen",
        MoveLine = "MoveLine",
        TriggerType2 = "TriggerType2",
        RoleMoveArrow = "RoleMoveArrow",
        MonsterTriggerEffect = "MonsterTriggerEffect",
        ElectricFence = "ElectricFence",
        Trap = "Trap",
        SentryLine = "SentryLine",
        Sentry = "Sentry",
        SentryRoand = "SentryRoand",
        TriggerElectricFenceOpen = "TriggerElectricFenceOpen",
        TriggerElectricFenceClose = "TriggerElectricFenceClose",
        ElectricFenceEffect = "ElectricFenceEffect",
        KillByElectricFenceEffect = "KillByElectricFenceEffect",
        BeAtkEffect = "BeAtkEffect",
        ShadowEffect = "ShadowEffect",
        Grass = "Grass",
        Pool = "Pool",
        TransferPointLoopColor1 = "TransferPointLoopColor1",
        TransferPointLoopColor2 = "TransferPointLoopColor2",
        TransferPointLoopColor3 = "TransferPointLoopColor3",
        TransferPointColor1 = "TransferPointColor1",
        TransferPointColor2 = "TransferPointColor2",
        TransferPointColor3 = "TransferPointColor3",
        Steel = "Steel",
        SteelBroken = "SteelBroken",
        Freeze = "Freeze",
        Melt = "Melt",
        Drown = "Drown",
        Burn = "Burn",
        WaterRipper = "WaterRipper",
        DarkSkillEffect = "DarkSkillEffect",
        CrystalSkillEffect = "CrystalSkillEffect",
        FlameSkillEffect = "FlameSkillEffect",
        RaidenSkillEffect = "RaidenSkillEffect",
        PhysicsSkillEffect = "PhysicsSkillEffect",
        NoneSkillShadowEffect = "NoneSkillShadowEffect",
        DarkSkillShadowEffect = "DarkSkillShadowEffect",
        CrystalSkillShadowEffect = "CrystalSkillShadowEffect",
        FlameSkillShadowEffect = "FlameSkillShadowEffect",
        RaidenSkillShadowEffect = "RaidenSkillShadowEffect",
        PhysicsSkillShadowEffect = "PhysicsSkillShadowEffect",
        Bubble = "Bubble",
        Drop1 = "Drop1",
        Drop2 = "Drop2",
        Drop3 = "Drop3",
        Drop4 = "Drop4",
        Magic = "Magic",
        MagicDisEffect = "MagicDisEffect",
        MagicShowEffect = "MagicShowEffect",
        BubbleBrokenEffect = "BubbleBrokenEffect",
        SwitchSkillPoint = "SwitchSkillPoint",
        Torch = "Torch",
        Flame2Effect = "FlameEffect", -- 火属性特效
        Physics2Effect = "PhysicsEffect", -- 物理属性特效
        GrassFlameEffect = "GrassFlameEffect", -- 草的燃烧特效
        TorchDisappearEffect = "TorchDisappearEffect", -- 火炬消失特效
        TorchBurnEffect = "TorchBurnEffect", -- 火炬点燃特效
        BurnedEffect = "BurnedEffect", -- 被烧死特效
        WaterVapor = "WaterVapor", -- 水蒸气特效
        DieEffect = "DieEffect", -- 死亡特效
    },
    DropType = {
        Type1 = 1,
        Type2 = 2,
        Type3 = 3,
        Type4 = 4,
    },
    -- 火炬状态类型
    TorchStateType = {
        Inactive = 0,   -- 熄灭
        Active = 1,     -- 激活
        Disappear = 2,  -- 消失
    },
    -- 一个关卡最多星星数
    MaxStarCount = 3,
    -- 草埔生长、燃烧等动画播放间隔（毫秒）
    PlayAnimaInterval = 50,
}

-- 获取属性类型对应的常驻特效Key
---@param monsterType number 怪物类型
function XRpgMakerGameEnumConst:GetSkillTypePermanentEffectKey(skillType, monsterType)
    if skillType == self.XRpgMakerGameRoleSkillType.Flame2 then
        if monsterType == self.XRpgMakerGameMonsterType.Sepaktakraw then
            return self.ModelKeyMaps.GrassFlameEffect
        else
            return self.ModelKeyMaps.Flame2Effect
        end
    end
end

return XRpgMakerGameEnumConst
