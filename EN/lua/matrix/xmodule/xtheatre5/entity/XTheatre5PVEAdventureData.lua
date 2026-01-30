local XTheatre5EnumConst = require("XModule/XTheatre5/XTheatre5EnumConst")
local XTheatre5AdventureDataBase = require('XModule/XTheatre5/Entity/XTheatre5AdventureDataBase')

---@class XTheatre5PVEAdventureData:XTheatre5AdventureDataBase
local XTheatre5PVEAdventureData = XClass(XTheatre5AdventureDataBase, 'XTheatre5PVEAdventureData')

function XTheatre5PVEAdventureData:Ctor(model)
    ---@type XTheatre5Model
    self.OwnerModel = model
    self.PveChapterData = nil --XTheatre5PveChapterData,当前是故事线战斗节点是有章节数据
    self.ItemBoxSelectData = nil
    self._TempChapterData = nil --章节数据由服务器下发的，但是最后一场服务器会清掉数据，只能本地记录
    self._GameMode = XTheatre5EnumConst.GameMode.PVE
    self._ChapterId = 0
end

--- PVE局内数据全量更新
function XTheatre5PVEAdventureData:UpdatePVEAdventureData(adventureData)
    self:ClearData()
    if not XTool.IsTableEmpty(adventureData) then
        for k, v in pairs(adventureData) do
            self[k] = v
        end

        self.HasData = true
        self:SetNeedUpdateAdds()
    end
end

--更新下一个事件
function XTheatre5PVEAdventureData:UpdatePVENextEvent(nextEventId)
    if XTool.IsNumberValid(nextEventId) then
        if XTool.IsTableEmpty(self.PveChapterData.CurPveChapterLevel.RunEvents) then
            self.PveChapterData.CurPveChapterLevel.RunEvents = {}
        end
        table.insert(self.PveChapterData.CurPveChapterLevel.RunEvents, 1, nextEventId)
        self.Status = XMVCA.XTheatre5.EnumConst.PlayStatus.PveEveHandle
    else
        self.Status = XMVCA.XTheatre5.EnumConst.PlayStatus.NotStart

    end
end

function XTheatre5PVEAdventureData:UpdatePVEChapterData(pveChapterData)
    self.PveChapterData = pveChapterData
    if pveChapterData then
        self._ChapterId = pveChapterData.ChapterId
    end
end

--有章节战斗数据，默认有执行中的战斗
function XTheatre5PVEAdventureData:GetCurChapterBattleData()
    return self.PveChapterData
end

--
function XTheatre5PVEAdventureData:CanPveBattle()
    local curPlayStatus = self:GetCurPlayStatus()
    if curPlayStatus > 0 and curPlayStatus ~= XMVCA.XTheatre5.EnumConst.PlayStatus.PveEveHandle then
        return true
    end
    return false
end

--事件还没有开始
function XTheatre5PVEAdventureData:IsEventNoStart()
    return self.PveChapterData and self.PveChapterData.CurPveChapterLevel and XTool.IsTableEmpty(self.PveChapterData.CurPveChapterLevel.RunEvents)
end

function XTheatre5PVEAdventureData:HaveChapterBattle()
    return not XTool.IsTableEmpty(self.PveChapterData)
end

--得到当前事件id
function XTheatre5PVEAdventureData:GetCurEventId()
    if self.PveChapterData and self.PveChapterData.CurPveChapterLevel and not self:CanPveBattle() then
        if not XTool.IsTableEmpty(self.PveChapterData.CurPveChapterLevel.RunEvents) then
            return self.PveChapterData.CurPveChapterLevel.RunEvents[1]
        end
    end
end

function XTheatre5PVEAdventureData:GetFirstEventId()
    if self.PveChapterData and self.PveChapterData.CurPveChapterLevel then
        if not XTool.IsTableEmpty(self.PveChapterData.CurPveChapterLevel.RunEvents) then
            local count = #self.PveChapterData.CurPveChapterLevel.RunEvents
            return self.PveChapterData.CurPveChapterLevel.RunEvents[count]
        end
    end
end

--获取制定关卡给敌人上的buff
function XTheatre5PVEAdventureData:GetLevelEnemyMagicDict(level)
    if not self.PveChapterData then
        return
    end
    local chapterCfg = self.OwnerModel:GetPveChapterCfg(self.PveChapterData.ChapterId)
    local chapterLevelCfg = self.OwnerModel:GetChapterLevelCfg(chapterCfg.LevelGroup, level)
    if XTool.IsTableEmpty(chapterLevelCfg.EnemyBuff) and XTool.IsTableEmpty(chapterLevelCfg.MonsterNerfBuff) then
        return
    end
    local buffDict = {}
    for i = 1, #chapterLevelCfg.EnemyBuff do
        buffDict[chapterLevelCfg.EnemyBuff[i]] = chapterLevelCfg.EnemyBuffLevel[i]
    end
    if not XTool.IsTableEmpty(chapterLevelCfg.MonsterNerfBuff) then
        local maxHealh = self.OwnerModel:GetTheatre5ConfigValByKey('PveHealth')
        local lostHealh = maxHealh - self:GetHealth()
        local continueWin = self.PveChapterData.ContinueWin and self.PveChapterData.ContinueWin or 0
        local buffLevel = lostHealh - continueWin
        if buffLevel <= 0 then
            return buffDict
        end
        for _, magicId in ipairs(chapterLevelCfg.MonsterNerfBuff) do
            buffDict[magicId] = buffLevel
        end
    end
    return buffDict
end

function XTheatre5PVEAdventureData:GetItemBoxSelectData()
    return self.ItemBoxSelectData
end

--宝箱三选一完成后更新宝箱数据
function XTheatre5PVEAdventureData:UpdateItemBoxSelectCompleted(boxInstanceId)
    if not XTool.IsTableEmpty(self.ItemBoxSelectData) and XTool.IsNumberValid(boxInstanceId) then
        for k, data in ipairs(self.ItemBoxSelectData) do
            if data.BoxInstanceId == boxInstanceId then
                table.remove(self.ItemBoxSelectData, k)
                break
            end
        end
    end
end

--打开的宝箱是选择宝箱时，把数据加到三选一中
function XTheatre5PVEAdventureData:UpdateAddItemBoxSelect(boxInstanceId, itemList)
    if not self.ItemBoxSelectData then
        self.ItemBoxSelectData = {}
    end
    for i, data in ipairs(self.ItemBoxSelectData) do
        if data.BoxInstanceId == boxInstanceId then
            table.remove(self.ItemBoxSelectData, i)
        end
    end
    table.insert(self.ItemBoxSelectData, { BoxInstanceId = boxInstanceId, ItemList = itemList })
end

--缓存章节结算时数据，用于结算界面显示
function XTheatre5PVEAdventureData:UpdateTempChapterData(isWin)
    if not self.PveChapterData then
        return
    end
    self._TempChapterData = self.PveChapterData
    if not self._TempChapterData.BattleStatus then
        self._TempChapterData.BattleStatus = {}
    end
    if not isWin then
        isWin = false
    end
    table.insert(self._TempChapterData.BattleStatus, isWin)
    if isWin then
        self._TempChapterData.CurPveChapterLevel.Level = -1 ---1表示全部通关
    end
end

--战斗流结果
---@return List<bool>
function XTheatre5PVEAdventureData:GetBattleStatus()
    if self.PveChapterData then
        return self.PveChapterData.BattleStatus
    end
    if self._TempChapterData then
        return self._TempChapterData.BattleStatus
    end
end

function XTheatre5PVEAdventureData:GetChapterLevelCompleted()
    if self.PveChapterData then
        return self.PveChapterData.CurPveChapterLevel.Level
    end
    if self._TempChapterData then
        return self._TempChapterData.CurPveChapterLevel.Level
    end
end

--章节完成后的拿不到，只能自己存
function XTheatre5PVEAdventureData:GetChapterIdCompleted()
    if self.PveChapterData then
        return self.PveChapterData.ChapterId
    end
    if self._TempChapterData then
        return self._TempChapterData.ChapterId
    end
end

--region 敌人数据

function XTheatre5PVEAdventureData:UpdateEnemyData(autoChessData)
    self._EnemyRuneIds = autoChessData.Runes
    self._EnemySkillIds = autoChessData.Skills
    self._EnemyCharacterId = autoChessData.CharacterId
end

function XTheatre5PVEAdventureData:GetEnemySkillIds()
    if not self._EnemySkillIds then
        return {}
    end
    return XTool.ToArray(self._EnemySkillIds)
end

--- 获取敌人宝珠栏宝珠Id的列表（合并同类宝珠）
function XTheatre5PVEAdventureData:GetEnemyRuneIds()
    if not XTool.IsTableEmpty(self._EnemyRuneIds) then
        -- 转换成有序列表
        local runeIds = {}

        for i, runeData in pairs(self._EnemyRuneIds) do
            if not runeIds[runeData.ItemId] then
                runeIds[runeData.ItemId] = { ItemId = runeData.ItemId, ItemType = XMVCA.XTheatre5:GetTheatre5ItemTypeById(runeData.ItemId), Index = i, IsStrengthen = runeData.IsStrengthen }
            end
        end

        return runeIds
    end
end

function XTheatre5PVEAdventureData:GetEnemyCharacterId()
    return self._EnemyCharacterId
end

--endregion

function XTheatre5PVEAdventureData:ClearData()
    XTheatre5PVEAdventureData.Super.ClearData(self)
    self.PveChapterData = nil
    self.ItemBoxSelectData = nil
    self._EnemyRuneIds = nil
    self._EnemySkillIds = nil
    self._EnemyCharacterId = nil
    self._TempChapterData = nil
end

function XTheatre5PVEAdventureData:GetChapterId()
    if self.PveChapterData and self.PveChapterData.ChapterId then
        return self.PveChapterData.ChapterId
    end
    -- 结算时，还需要chapterId，才能正常显示
    if self._ChapterId then
        return self._ChapterId
    end
    XLog.Error("[XUiTheatre5PVEGame] 获取章节id失败")
    return 0
end

return XTheatre5PVEAdventureData