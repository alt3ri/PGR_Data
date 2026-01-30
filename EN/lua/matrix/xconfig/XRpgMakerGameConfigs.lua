local tableInsert = table.insert
local tableSort = table.sort
local ipairs = ipairs
local pairs = pairs

XRpgMakerGameConfigs = XRpgMakerGameConfigs or {}

function XRpgMakerGameConfigs.Init()

end

--#region -----------------RpgMakerGameHintIcon 通关提示图标-----------------------
function XRpgMakerGameConfigs.GetRpgMakerGameHintIconKeyList()
    local hintIconKeyList = {}
    local RpgMakerGameHintIconConfigs = XMVCA.XRpgMakerGame:GetConfig():GetConfigHintIcon()
    for k in pairs(RpgMakerGameHintIconConfigs) do
        tableInsert(hintIconKeyList, k)
    end
    return hintIconKeyList
end

--只获取该地图上有对应对象的图标
function XRpgMakerGameConfigs.GetRpgMakerGameHintIconKeyListByMapId(mapId, isNotShowLine)
    local hintIconKeyList = {}
    if not XTool.IsNumberValid(mapId) then
        return hintIconKeyList
    end

    -- 不同属性库洛洛不同图标
    local isHaveNormalMonster, isHaveCrystalMonsterIcon, isHaveFlameMonsterIcon, isHaveRaidenMonsterIcon, isHaveDarkMonsterIcon
        = XMVCA.XRpgMakerGame:GetConfig():IsMapHaveMonster(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.Normal)
    local isHaveNormalBoss, isHaveCrystalBossIcon, isHaveFlameBossIcon, isHaveRaidenBossIcon, isHaveDarkBossIcon
        = XMVCA.XRpgMakerGame:GetConfig():IsMapHaveMonster(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.BOSS)
    local isHaveHuman = XMVCA.XRpgMakerGame:GetConfig():IsMapHaveMonster(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.Human)

    local isHaveType1Trigger, isHaveType2Trigger, isHaveType3Trigger, isHaveElectricFencTrigger = XMVCA.XRpgMakerGame:GetConfig():IsMapHaveTrigger(mapId)

    -- local isHaveBlock = XRpgMakerGameConfigs.IsRpgMakerGameHaveBlock(mapId)
    -- local isHaveGap = not XTool.IsTableEmpty(XRpgMakerGameConfigs.GetRpgMakerGameMapIdToGapIdList(mapId))
    -- local isHaveShadow = not XTool.IsTableEmpty(XRpgMakerGameConfigs.GetRpgMakerGameMapIdToShadowIdList(mapId))
    -- local isHaveElectricFence = not XTool.IsTableEmpty(XRpgMakerGameConfigs.GetRpgMakerGameMapIdToElectricFenceIdList(mapId))
    -- local isHaveTrap = not XTool.IsTableEmpty(XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTrapIdList(mapId))
    -- -- 地图实体：1 水面、2 冰面、3 草圃、4 钢板
    -- local isHaveEntity1, isHaveEntity2, isHaveEntity3, isHaveEntity4 = XRpgMakerGameConfigs.IsRpgMakerGameHaveEntity(mapId)
    -- local isHaveTransferPoint1, isHaveTransferPoint2, isHaveTransferPoint3 = XRpgMakerGameConfigs.IsRpgMakerGameHaveTransferPoint(mapId)

    local isHaveBlock = XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.BlockType)
    local isHaveGap = XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Gap)
    local isHaveShadow = XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Shadow)
    local isHaveElectricFence = XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.ElectricFence)
    local isHaveTrap = XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Trap)
    -- 地图实体：1 水面、2 冰面、3 草圃、4 钢板
    local isHaveEntity1 = XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Water)
    local isHaveEntity2 = XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Ice)
    local isHaveEntity3 = XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Grass)
    local isHaveEntity4 = XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Steel)
    local isHaveTransferPoint1, isHaveTransferPoint2, isHaveTransferPoint3 = XRpgMakerGameConfigs.IsHaveTransferPointByColor(mapId)

    local isHaveBubble = XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Bubble)
    local isHaveMagic = XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Magic)
    local isHaveSwitchMagic = XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.SwitchSkillType)
    local isHaveDrop = XRpgMakerGameConfigs.IsHaveDropByType(mapId)

    local isInsert = true
    local RpgMakerGameHintIconConfigs = XMVCA.XRpgMakerGame:GetConfig():GetConfigHintIcon()
    for k in pairs(RpgMakerGameHintIconConfigs) do
        if k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.BlockIcon then
            isInsert = isHaveBlock
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.CrystalMonsterIcon then
            isInsert = isHaveCrystalMonsterIcon
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.FlameMonsterIcon then
            isInsert = isHaveFlameMonsterIcon
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.RaidenMonsterIcon then
            isInsert = isHaveRaidenMonsterIcon
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.DarkMonsterIcon then
            isInsert = isHaveDarkMonsterIcon
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.NormalMonsterIcon then
            isInsert = isHaveNormalMonster
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.CrystalBossIcon then
            isInsert = isHaveCrystalBossIcon
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.FlameBossIcon then
            isInsert = isHaveFlameBossIcon
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.RaidenBossIcon then
            isInsert = isHaveRaidenBossIcon
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.DarkBossIcon then
            isInsert = isHaveDarkBossIcon
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.BossIcon then
            isInsert = isHaveNormalBoss
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TriggerIcon1 then
            isInsert = isHaveType1Trigger
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TriggerIcon2 then
            isInsert = isHaveType2Trigger
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TriggerIcon3 then
            isInsert = isHaveType3Trigger
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.ElectricFencTrigger then
            isInsert = isHaveElectricFencTrigger
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.GapIcon then
            isInsert = isHaveGap
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.ShadowIcon then
            isInsert = isHaveShadow
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.ElectricFenceIcon then
            isInsert = isHaveElectricFence
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.HumanIcon then
            isInsert = isHaveHuman
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TrapIcon then
            isInsert = isHaveTrap
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.EntityIcon1 then
            isInsert = isHaveEntity1
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.EntityIcon2 then
            isInsert = isHaveEntity2
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.EntityIcon3 then
            isInsert = isHaveEntity3
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.EntityIcon4 then
            isInsert = isHaveEntity4
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TransferPointIcon1 then
            isInsert = isHaveTransferPoint1
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TransferPointIcon2 then
            isInsert = isHaveTransferPoint2
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TransferPointIcon3 then
            isInsert = isHaveTransferPoint3
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Bubble then
            isInsert = isHaveBubble
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Drop1 then
            isInsert = isHaveDrop[1]
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Drop2 then
            isInsert = isHaveDrop[2]
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Drop3 then
            isInsert = isHaveDrop[3]
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Drop4 then
            isInsert = isHaveDrop[4]
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Magic then
            isInsert = isHaveMagic
        elseif k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.SwitchSkillPoint then
            isInsert = isHaveSwitchMagic
        elseif isNotShowLine and k == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.MoveLineIcon then
            isInsert = false
        end

        if isInsert then
            tableInsert(hintIconKeyList, k)
        end
        isInsert = true
    end
    return hintIconKeyList
end

function XRpgMakerGameConfigs.GetMonsterIconKey(monsterType, skillType)
    if XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.BOSS == monsterType then
        if skillType then
            if skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Crystal then
                return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.CrystalBossIcon
            elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Flame then
                return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.FlameBossIcon
            elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Thunder then
                return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.RaidenBossIcon
            elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Dark then
                return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.DarkBossIcon
            end
        end
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.BossIcon
    elseif XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.Human == monsterType then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.HumanIcon
    elseif XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.Sepaktakraw == monsterType then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Sepaktakraw
    end

    if skillType then
        if skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Crystal then
            return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.CrystalMonsterIcon
        elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Flame then
            return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.FlameMonsterIcon
        elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Thunder then
            return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.RaidenMonsterIcon
        elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Dark then
            return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.DarkMonsterIcon
        end
    end

    return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.NormalMonsterIcon
end

function XRpgMakerGameConfigs.GetTriggerIconKey(triggerType)
    if triggerType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameTriggerType.Trigger1 then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TriggerIcon1
    end

    if triggerType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameTriggerType.Trigger2 then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TriggerIcon2
    end

    if triggerType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameTriggerType.TriggerElectricFence  then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.ElectricFencTrigger
    end

    return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TriggerIcon3
end

function XRpgMakerGameConfigs.GetEntityIconKey(entityType)
    if entityType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Water then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.EntityIcon1
    end

    if entityType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Ice then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.EntityIcon2
    end

    if entityType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Grass  then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.EntityIcon3
    end

    return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.EntityIcon4
end

function XRpgMakerGameConfigs.GetTransferPointIconKey(transferPointColor)
    if transferPointColor == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerTransferPointColor.Green then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TransferPointIcon1
    end

    if transferPointColor == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerTransferPointColor.Yellow then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TransferPointIcon2
    end

    return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TransferPointIcon3
end

function XRpgMakerGameConfigs.GetDropIconKey(dropType)
    if dropType == XMVCA.XRpgMakerGame.EnumConst.DropType.Type1 then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Drop1
    end
    if dropType == XMVCA.XRpgMakerGame.EnumConst.DropType.Type2 then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Drop2
    end
    if dropType == XMVCA.XRpgMakerGame.EnumConst.DropType.Type3 then
        return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Drop3
    end
    return XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Drop4
end
--#endregion


--#region -----------------RpgMakerGameHintDialogBox 点击头像提示-----------------------
local GetRpgMakerGameHintDialogBoxConfigs = function(id)
    return XMVCA.XRpgMakerGame:GetConfig():GetConfigHintDialogBox(id)
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxText(id)
    local config = GetRpgMakerGameHintDialogBoxConfigs(id)
    return config and config.Text or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxBackCount(id)
    local config = GetRpgMakerGameHintDialogBoxConfigs(id)
    return config and config.BackCount or 0
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxResetCount(id)
    local config = GetRpgMakerGameHintDialogBoxConfigs(id)
    return config.ResetCount
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxTotalLoseCount(id)
    local config = GetRpgMakerGameHintDialogBoxConfigs(id)
    return config.TotalLoseCount
end
--#endregion


--#region -----------------RpgMakerGameModel 模型相关-----------------------
function XRpgMakerGameConfigs.GetRpgMakerGameTriggerKey(triggerType, isOpen)
    if triggerType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameTriggerType.Trigger1 then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.TriggerType1
    end

    if triggerType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameTriggerType.Trigger2 then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.TriggerType2
    end

    if triggerType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameTriggerType.Trigger3 then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.TriggerType3
    end

    if triggerType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameTriggerType.TriggerElectricFence then
        return isOpen and XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.TriggerElectricFenceOpen or XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.TriggerElectricFenceClose
    end
end

function XRpgMakerGameConfigs.GetTransferPointLoopColorKey(colorIndex)
    return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps["TransferPointLoopColor" .. colorIndex]
end

function XRpgMakerGameConfigs.GetTransferPointColorKey(colorIndex)
    return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps["TransferPointColor" .. colorIndex]
end

function XRpgMakerGameConfigs.GetModelEntityKey(entityType)
    if entityType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Water then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.WaterRipper
    elseif entityType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Ice then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Freeze
    elseif entityType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Grass then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Grass
    elseif entityType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Steel then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Steel
    end
end

function XRpgMakerGameConfigs.GetModelSkillEffctKey(skillType)
    if skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Crystal then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.CrystalSkillEffect
    elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Flame then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.FlameSkillEffect
    elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Thunder then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.RaidenSkillEffect
    elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Dark then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.DarkSkillEffect
    elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Physics then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.PhysicsSkillEffect
    else
        if XTool.IsNumberValid(skillType) then
            XLog.Error("XRpgMakerGameConfigs.GetModelSkillEffctKey()Error 该技能类型没有特效! SkillType:" .. skillType)
        end
    end
end

function XRpgMakerGameConfigs.GetModelSkillShadowEffctKey(skillType)
    if skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Crystal then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.CrystalSkillShadowEffect
    elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Flame then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.FlameSkillShadowEffect
    elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Thunder then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.RaidenSkillShadowEffect
    elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Dark then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.DarkSkillShadowEffect
    elseif skillType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Physics then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.PhysicsSkillShadowEffect
    else
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.NoneSkillShadowEffect
    end
end
--#endregion


--#region -----------------RpgMakerGameHintLine 通关提示线路--------------------
local GetRpgMakerGameHintLineConfig = function(mapId)
    return XMVCA.XRpgMakerGame:GetConfig():GetConfigHintLine(mapId)
end

local GetStringSplitTwoNumParam = function(text)
    local textList = string.Split(text, "|")
    return textList[1] and tonumber(textList[1]) or 0, textList[2] and tonumber(textList[2]) or 0
end

function XRpgMakerGameConfigs.GetHintLineHintTitle(mapId)
    local config = GetRpgMakerGameHintLineConfig(mapId)
    return config.HintTitle or ""
end

--获得开始绘制线的格子行和列
function XRpgMakerGameConfigs.GetHintLineStartRowAndCol(mapId)
    local config = GetRpgMakerGameHintLineConfig(mapId)
    local row, line = GetStringSplitTwoNumParam(config.StartRowAndCol)
    return row, line
end

function XRpgMakerGameConfigs.GetHintLineStartGridPercent(mapId)
    local config = GetRpgMakerGameHintLineConfig(mapId)
    local widthPercent, heightPercent = GetStringSplitTwoNumParam(config.StartGridPercent)
    return widthPercent, heightPercent
end

--获得格子中从哪一点开始
function XRpgMakerGameConfigs.GetHintLineStartGridPos(mapId, width, height)
    local percentWidth, percentHeight = XRpgMakerGameConfigs.GetHintLineStartGridPercent(mapId)
    local x = width and width * percentWidth or 0
    local y = height and height * percentHeight or 0
    return x, y
end

function XRpgMakerGameConfigs.GetHintLineNextRowAndColList(mapId)
    local config = GetRpgMakerGameHintLineConfig(mapId)
    return config.NextRowAndCol
end

function XRpgMakerGameConfigs.GetHintLineNextRowAndCol(mapId, index)
    local row, line = 0, 0
    local config = GetRpgMakerGameHintLineConfig(mapId)
    local nextRowAndCol = config.NextRowAndCol[index]
    if not nextRowAndCol then
        return row, line
    end

    row, line = GetStringSplitTwoNumParam(nextRowAndCol)
    return row, line
end

function XRpgMakerGameConfigs.GetHintLineNextGridPercent(mapId, index)
    local widthPercent, heightPercent = 0, 0
    local config = GetRpgMakerGameHintLineConfig(mapId)
    local nextGridPercent = config.NextGridPercent[index]
    if not nextGridPercent then
        return widthPercent, heightPercent
    end

    widthPercent, heightPercent = GetStringSplitTwoNumParam(nextGridPercent)
    return widthPercent, heightPercent
end

--获得格子中终点位置的宽度和高度百分比
--direction：方向
--isEnd：是否为绘制一条线的最后一个格子
--endWidthPercent：绘制一条线的最后一个格子的宽度百分比
--endHeightPercent：绘制一条线的最后一个格子的高度百分比
local GetEndPercent = function(direction, isEnd, endWidthPercent, endHeightPercent)
    if isEnd then
        return endWidthPercent, endHeightPercent
    end

    endWidthPercent = (direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft and 0) or (direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight and 1) or endWidthPercent
    endHeightPercent = (direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown and 0) or (direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp and 1) or endHeightPercent
    return endWidthPercent, endHeightPercent
end

--获得格子中起点位置的宽度和高度百分比
--direction：方向
--startWidthPercent：绘制一条线的第一个格子的宽度百分比
--startHeightPercent：绘制一条线的第一个格子的高度百分比
local GetStartPercent = function(direction, startWidthPercent, startHeightPercent)
    startWidthPercent = (direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft and 1) or (direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight and 0) or startWidthPercent
    startHeightPercent = (direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown and 1) or (direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp and 0) or startHeightPercent
    return startWidthPercent, startHeightPercent
end

--获得各个格子绘制线的数据
function XRpgMakerGameConfigs.GetHintLineMap(mapId)
    local hintLineMap = {}
    local mapId = mapId
    local lineId = 0

    local InsertHintLineMap = function(row, col, widthPercent, heightPercent, direction, isStart, endWidthPercent, endHeightPercent)
        lineId = lineId + 1
        if not hintLineMap[row] then
            hintLineMap[row] = {}
        end
        if not hintLineMap[row][col] then
            hintLineMap[row][col] = {}
        end

        local param = {
            IsStart = isStart,              --是否是第一条绘制的线
            WidthPercent = widthPercent,    --格子宽度百分比，用来计算线在格子中的起始位置
            HeightPercent = heightPercent,  --格子高度百分比，用来计算线在格子中的起始位置
            EndWidthPercent = endWidthPercent,      --格子宽度百分比，用来计算线在格子中的终点位置
            EndHeightPercent = endHeightPercent,    --格子高度百分比，用来计算线在格子中的终点位置
            Direction = direction,          --箭头方向
            Id = lineId,
        }

        table.insert(hintLineMap[row][col], param)
    end

    local startRow, startCol = XRpgMakerGameConfigs.GetHintLineStartRowAndCol(mapId)
    local startWidthPercent, startHeightPercent = XRpgMakerGameConfigs.GetHintLineStartGridPercent(mapId)
    local nextRow, nextCol = XRpgMakerGameConfigs.GetHintLineNextRowAndCol(mapId, 1)
    local endWidthPercent, endHeightPercent = XRpgMakerGameConfigs.GetHintLineNextGridPercent(mapId, 1)
    local direction = XRpgMakerGameConfigs.GetHintLineDirection(startRow, startCol, nextRow, nextCol, startWidthPercent, startHeightPercent, endWidthPercent, endHeightPercent)
    local isSameGrid = startRow == nextRow and startCol == nextCol and (startWidthPercent ~= endWidthPercent or startHeightPercent ~= endHeightPercent) --前后两点是否在同一格子里，且宽高百分比至少有一个不同
    local distance = (nextCol ~= startCol and nextRow ~= startRow) and 0 or math.floor(math.sqrt((nextCol - startCol) ^ 2 + (nextRow - startRow) ^ 2))  --前后两点的距离，不在一条直线上时为0
    if distance ~= 0 or isSameGrid then
        endWidthPercent, endHeightPercent = GetEndPercent(direction, distance == 0, endWidthPercent, endHeightPercent)
        InsertHintLineMap(startRow, startCol, startWidthPercent, startHeightPercent, direction, true, endWidthPercent, endHeightPercent)
    end

    local nextRowAndColList = XRpgMakerGameConfigs.GetHintLineNextRowAndColList(mapId)
    local isStart
    local isEnd
    local startWidthPercentTemp
    local startHeightPercentTemp
    local endWidthPercentTemp
    local endHeightPercentTemp
    local row
    local col
    for nextRowAndColIndex in ipairs(nextRowAndColList) do
        isStart = nextRowAndColIndex == 1
        endWidthPercent, endHeightPercent = XRpgMakerGameConfigs.GetHintLineNextGridPercent(mapId, nextRowAndColIndex)
        nextRow, nextCol = XRpgMakerGameConfigs.GetHintLineNextRowAndCol(mapId, nextRowAndColIndex)
        direction = XRpgMakerGameConfigs.GetHintLineDirection(startRow, startCol, nextRow, nextCol, startWidthPercent, startHeightPercent, endWidthPercent, endHeightPercent)

        distance = (nextCol ~= startCol and nextRow ~= startRow) and 0 or math.floor(math.sqrt((nextCol - startCol) ^ 2 + (nextRow - startRow) ^ 2))
        isEnd = distance == 0
        isSameGrid = startRow == nextRow and startCol == nextCol and (startWidthPercent ~= endWidthPercent or startHeightPercent ~= endHeightPercent)
        if (not isStart) and (distance ~= 0 or isSameGrid) then
            endWidthPercentTemp, endHeightPercentTemp = GetEndPercent(direction, isEnd, endWidthPercent, endHeightPercent)
            InsertHintLineMap(startRow, startCol, startWidthPercent, startHeightPercent, direction, false, endWidthPercentTemp, endHeightPercentTemp)
        end

        for i = 1, distance do
            isEnd = i == distance
            startWidthPercentTemp, startHeightPercentTemp = GetStartPercent(direction, startWidthPercent, startHeightPercent)
            endWidthPercentTemp, endHeightPercentTemp = GetEndPercent(direction, isEnd, endWidthPercent, endHeightPercent)

            if isEnd then
                InsertHintLineMap(nextRow, nextCol, startWidthPercentTemp, startHeightPercentTemp, direction, isStart, endWidthPercentTemp, endHeightPercentTemp)
            else
                row = (startRow - nextRow == 0 and startRow) or (startRow > nextRow and startRow - i or startRow + i)
                col = (startCol - nextCol == 0 and startCol) or (startCol > nextCol and startCol - i or startCol + i)
                InsertHintLineMap(row, col, startWidthPercentTemp, startHeightPercentTemp, direction, isStart, endWidthPercentTemp, endHeightPercentTemp)
            end
        end

        startRow, startCol = nextRow, nextCol
        startWidthPercent, startHeightPercent = XRpgMakerGameConfigs.GetHintLineNextGridPercent(mapId, nextRowAndColIndex)
    end

    return hintLineMap, lineId
end

--获得一条线的方向
--startRow, startCol：起点的行数和列数
--endRow, endCol：终点的行数和列数
--startWidthPercent, startHeightPercent：起点在格子中的宽度百分比和高度百分比
--endWidthPercent, endHeightPercent：终点在格子中的宽度百分比和高度百分比
function XRpgMakerGameConfigs.GetHintLineDirection(startRow, startCol, endRow, endCol, startWidthPercent, startHeightPercent, endWidthPercent, endHeightPercent)
    local horizontalDistance = startRow - endRow      --垂直方向距离
    local verticalDistance = startCol - endCol        --水平方向距离
    local widthPercentDistance = (startWidthPercent and endWidthPercent) and startWidthPercent - endWidthPercent or 0
    local heightPercentDistance = (startHeightPercent and endHeightPercent) and startHeightPercent - endHeightPercent or 0
    if horizontalDistance ~= 0 and verticalDistance ~= 0 then
        return
    end

    if horizontalDistance ~= 0 then
        return horizontalDistance > 0 and XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown or XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp
    end

    if verticalDistance ~= 0 then
        return verticalDistance > 0 and XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft or XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight
    end

    if widthPercentDistance ~= 0 then
        return widthPercentDistance > 0 and XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft or XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight
    end

    if heightPercentDistance ~= 0 then
        return heightPercentDistance > 0 and XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown or XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp
    end
end
--#endregion

--#region -----------------RpgMakerGameMixBlock 对象合表-----------------

---是否存在某类型的合表对象
---@param mapId number
---@param type number
---@return boolean
function XRpgMakerGameConfigs.IsHaveMixBlockDataListByType(mapId, type)
    local dataList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByType(mapId, type)
    return not XTool.IsTableEmpty(dataList)
end

function XRpgMakerGameConfigs.IsHaveTransferPointByColor(mapId)
    local isHaveTransferPoint1 = false
    local isHaveTransferPoint2 = false
    local isHaveTransferPoint3 = false
    local entityIdList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.TransferPoint)
    local colorCfg
    for _, data in ipairs(entityIdList) do
        colorCfg = data:GetParams()[1]
        if colorCfg == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerTransferPointColor.Green then
            isHaveTransferPoint1 = true
        elseif colorCfg == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerTransferPointColor.Yellow then
            isHaveTransferPoint2 = true
        elseif colorCfg == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerTransferPointColor.Purple then
            isHaveTransferPoint3 = true
        end

        if isHaveTransferPoint1 and isHaveTransferPoint2 and isHaveTransferPoint3 then
            break
        end
    end
    return isHaveTransferPoint1, isHaveTransferPoint2, isHaveTransferPoint3
end

function XRpgMakerGameConfigs.IsHaveDropByType(mapId)
    local result = {}
    local dropType
    local dropList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Drop)
    for _, data in ipairs(dropList) do
        dropType = data:GetParams()[2]
        result[dropType] = true
    end
    return result
end

function XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, x, y, type)
    local colDataList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByPosition(mapId, x, y)
    for _, data in ipairs(colDataList) do
        if data:GetType() == type then
            return data
        end
    end
end

function XRpgMakerGameConfigs.GetEntityInPositionByType(mapId, x, y)
    local result = {}
    local colDataList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByPosition(mapId, x, y)
    for _, data in ipairs(colDataList) do
        if data:GetType() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Water
        or data:GetType() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Ice
        or data:GetType() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Grass
        or data:GetType() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Steel then
            table.insert(result, data)
        end
    end
    return result
end

function XRpgMakerGameConfigs.GetGapInPositionByType(mapId, x, y)
    local result = {}
    local colDataList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByPosition(mapId, x, y)
    for _, data in ipairs(colDataList) do
        if data:GetType() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Gap then
            table.insert(result, data)
        end
    end
    return result
end

function XRpgMakerGameConfigs.GetGapDirection(data)
    return data:GetParams()[1]
end

function XRpgMakerGameConfigs.GetElectricFenceInPositionByType(mapId, x, y)
    local result = {}
    local colDataList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByPosition(mapId, x, y)
    for _, data in ipairs(colDataList) do
        if data:GetType() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.ElectricFence then
            table.insert(result, data)
        end
    end
    return result
end

function XRpgMakerGameConfigs.GetElectricFenceDirection(data)
    return data:GetParams()[1]
end

---@param mapId number
---@param x number
---@param y number
---@param type number XRpgMakeBlockMetaType
---@return boolean
function XRpgMakerGameConfigs.IsSameMixBlock(mapId, x, y, type)
    local mixBlockList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByPosition(mapId, x, y)
    if XTool.IsTableEmpty(mixBlockList) then
        return false
    end
    for _, mixBlockData in ipairs(mixBlockList) do
        if mixBlockData:GetType() == type then
            return true
        end
    end
    return false
end

function XRpgMakerGameConfigs.GetMixTransferPointIndexByPosition(mapId, x, y)
    local mapTransferPointDataList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.TransferPoint)
    for index, data in ipairs(mapTransferPointDataList) do
        if data:GetX() == x and data:GetY() == y then
            return index
        end
    end
    return XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByPosition(mapId, x, y)
end

function XRpgMakerGameConfigs.GetMixBlockEntityListByPosition(mapId, x, y)
    return XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByPosition(mapId, x, y)
end

function XRpgMakerGameConfigs.GetEntityIndex(mapId, data)
    local EntityList = XRpgMakerGameConfigs.GetMixBlockEntityList(mapId)
    return table.indexof(EntityList, data)
end

---@param mapId number
---@return XMapObjectData[]
function XRpgMakerGameConfigs.GetMixBlockEntityList(mapId)
    local result = {}
    local mapGrassDataList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Grass)
    for _, data in ipairs(mapGrassDataList) do
        tableInsert(result, data)
    end
    local mapSteelDataList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Steel)
    for _, data in ipairs(mapSteelDataList) do
        tableInsert(result, data)
    end
    local mapWaterDataList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Water)
    for _, data in ipairs(mapWaterDataList) do
        tableInsert(result, data)
    end
    local mapIceDataList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Ice)
    for _, data in ipairs(mapIceDataList) do
        tableInsert(result, data)
    end
    return result
end

function XRpgMakerGameConfigs.GetMixBlockModelEntityKey(type)
    if type == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Water then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.WaterRipper
    elseif type == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Ice then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Freeze
    elseif type == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Grass then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Grass
    elseif type == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Steel then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Steel
    end
end

function XRpgMakerGameConfigs.GetMixBlockModelDropKey(dropType)
    local type = "Drop" .. dropType
    local result = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps[type]
    if string.IsNilOrEmpty(result) then
        return XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Drop1
    end
    return result
end
--#endregion
