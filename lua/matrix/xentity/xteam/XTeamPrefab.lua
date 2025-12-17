local XTeam = require("XEntity/XTeam/XTeam")
---@class XTeamPrefab:XTeam 队伍预设 全部都是假数据
local XTeamPrefab = XClass(XTeam, "XTeamPrefab")

--- 初始化所有字段数据
---@param data table 原始预设数据
function XTeamPrefab:Ctor(data)
    self.Id = data.TeamId
    self.CaptainPos = data.CaptainPos or 1
    self.FirstFightPos = data.FirstFightPos or 1
    self.TeamName = data.TeamName
    self.SelectedGeneralSkill = data.SelectedGeneralSkill
    self.EnterCgIndex = data.EnterCgIndex
    self.SettleCgIndex = data.SettleCgIndex
    self._InSnapshotBatch = nil

    -- 空位初始
    self.EntitiyIds = {0,0,0}
    if data.TeamData then
        for idx, v in pairs(data.TeamData) do
            self.EntitiyIds[idx] = v
        end
    end

    -- 调用 InitXX 进行本地初始化
    self:InitPartnerData(data.PartnerData)
    self:InitEquipData(data.EquipData)
    self:RefreshGeneralSkills(true, true)  -- 假设此方法本身不需要上行
end

function XTeamPrefab:UpdateEntityIds(value)
    if not self.IsStandAlone then
        local isSameEntityId, index = XMVCA.XCharacter:HasDuplicateCharId(value)
        if isSameEntityId then
            value[index] = 0
        end
    end

    for pos, entityId in ipairs(value) do
        self.EntitiyIds[pos] = entityId
    end

    self:RefreshGeneralSkills(true)
end

--- 更新伙伴预设数据
---@param partnerData table
function XTeamPrefab:InitPartnerData(partnerData)
    local XPartnerPrefab = require("XEntity/XPartner/XPartnerPrefab")
    self.PartnerPrefab = self.PartnerPrefab or XPartnerPrefab.New(self.Id, partnerData)
end

--- 更新伙伴预设（触发上行）
---@param partnerData table
function XTeamPrefab:UpdatePartnerData(partnerData)
    if not self.PartnerPrefab then return end
    self.PartnerPrefab:UpdateAll(partnerData)
end

--- 单位置伙伴更新（触发上行）
function XTeamPrefab:UpdatePartnerDataAtPos(pos, data)
    if not self.PartnerPrefab then return end
    self.PartnerPrefab:UpdatePartnerDataAtPos(pos, data)
end

--- 更新装备和意识数据
---@param equipData table
function XTeamPrefab:InitEquipData(equipData)
    if not equipData then
        XLog.Warning("XTeamPrefab:InitEquipData equipData is nil, Id:", self.Id)
        return
    end

    self.WeaponData = self.WeaponData or {}
    self.AwarenessData = self.AwarenessData or {}

    for position, equipGroup in pairs(equipData) do
        self.WeaponData[position] = self.WeaponData[position] or nil
        self.AwarenessData[position] = self.AwarenessData[position] or {}

        if equipGroup.EquipDataDict then
            for slot, item in pairs(equipGroup.EquipDataDict) do
                if slot == 0 then
                    self.WeaponData[position] = item
                else
                    self.AwarenessData[position][slot] = item
                end
            end
        end
    end
end

function XTeamPrefab:ClearAllData()
    self.WeaponData = {}
    self.AwarenessData = {}
    self:UpdateEntityIds({0,0,0})
end

function XTeamPrefab:ClearPosData(pos)
    self.WeaponData[pos] = nil
    self.AwarenessData[pos] = nil
    local charId = self:GetEntityIdByTeamPos(pos)
    self:UpdateEntityTeamPos(charId, pos)
end

function XTeamPrefab:ClearAwarenessData(pos, notSyncToServer)
    self:BeginSnapshotBatch()

    for i = 1, 6, 1 do
        self:UpdateEquipAt(pos, i, nil, true)
    end

    if not notSyncToServer then
        self:SyncEquipDataToServer(pos)
    end
end

--- 单独更新某个位置某槽位的装备
function XTeamPrefab:UpdateEquipAt(pos, slot, item, notSyncToServer, cb)
    self.WeaponData = self.WeaponData or {}
    self.AwarenessData = self.AwarenessData or {}

    local curEquipId = item and item.EquipId
    local isConflict, conflictPos, conflictSlot = self:CheckEquipIdConflict(curEquipId, pos)
    -- 如果冲突，把被冲突的位置的意识给扒下来
    -- 如果是武器冲突则替换，因为武器是一定要穿戴的
    if slot == 0 then
        if isConflict then
            self.WeaponData[conflictPos] = self.WeaponData[pos]
        end
        self.WeaponData[pos] = item
    else
        if isConflict then
            self.AwarenessData[conflictPos][conflictSlot] = nil
        end
        self.AwarenessData[pos] = self.AwarenessData[pos] or {}
        self.AwarenessData[pos][slot] = item
    end

    if not notSyncToServer then
        self:SyncEquipDataToServer(pos, cb)
    end
end

--- 检查装备ID是否已在队伍预设中使用
---@param equipId number 装备ID
---@return boolean 是否存在
function XTeamPrefab:CheckEquipIdInTeam(equipId)
    if not equipId then return false end

    -- 获取队伍位置数量（通过接口获取实体ID列表）
    local entityIds = self:GetEntityIds()
    if not entityIds then return false end

    -- 检查所有位置的武器数据
    for pos = 1, #entityIds do
        local weapon = self:GetWeaponData(pos)
        if weapon and weapon.EquipId == equipId then
            return true
        end
    end

    -- 检查所有位置的意识数据
    for pos = 1, #entityIds do
        local awarenessData = self:GetAllAwarenessData(pos)
        if awarenessData then
            for slot = 1, 6 do  -- 假设意识槽位固定为1-6
                local awareness = self:GetAwarenessData(pos, slot)
                if awareness and awareness.EquipId == equipId then
                    return true
                end
            end
        end
    end

    return false
end

function XTeamPrefab:CheckEquipIdConflict(equipId, targetPos)
    local curPos, slot = self:GetPosByEquipId(equipId)
    if not curPos then
        return false
    end

    return curPos ~= targetPos, curPos, slot
end

--- 更新指定位置的意识装备列表，并处理位置冲突与穿脱(这个接口目前专为意识预设套装穿戴使用)
---@param targetPos number 目标位置（self.CurrentPos 原本位置）
---@param equipList table slot->EquipId
function XTeamPrefab:UpdateAwarenessEquipList(targetPos, equipList)
    local conflictInfoList = {}
    local characterType = XMVCA.XCharacter:GetCharacterType(self:GetEntityIdByTeamPos(targetPos))
    local count = 0
    for k, equipId in pairs(equipList) do count = count + 1 end

    for k, equipId in pairs(equipList) do
        -- 类型不匹配检查
        if not XMVCA.XEquip:IsCharacterTypeFit(equipId, characterType) then
            XUiManager.TipText("EquipAwarenessSuitPrefabCharacterTypeWrong")
            return
        end

        -- 冲突检测
        local slot = XMVCA.XEquip:GetEquip(equipId):GetSite()
        local curPos = self:GetPosByEquipId(equipId)
        if XTool.IsNumberValid(curPos) and curPos ~= targetPos then
            table.insert(conflictInfoList, {
                EquipId = equipId,
                CharacterId = self:GetEntityIdByTeamPos(curPos),
                TeamPos = curPos,
                Slot = slot,
            })
        end
    end

    table.sort(conflictInfoList, function(a, b)
        return XMVCA.XEquip:GetEquipSiteByEquipId(a.EquipId) < XMVCA.XEquip:GetEquipSiteByEquipId(b.EquipId)
    end)

    local isConflict = not XTool.IsTableEmpty(conflictInfoList)

    local function doUpdate()
        -- 直接穿 冲突的意识已经在UpdateEquipAt里处理了，会先将被冲突的角色的装备脱掉
        local count2 = 0
        for k, equipId in pairs(equipList) do
            count2 = count2 + 1
            local notSync = (count2 ~= count)
            local slot = XMVCA.XEquip:GetEquip(equipId):GetSite()
            -- 有冲突就不要单独发装备信息 而是发全部的信息
            self:UpdateEquipAt(targetPos, slot, {EquipId = equipId}, notSync or isConflict)
        end

        if isConflict then
            self:SyncFullDataToServer(function ()
                XUiManager.TipText("TeamPrefabEquipModifySuccess")
            end)
        end
    end

    if not isConflict then
        doUpdate()
    else
        return conflictInfoList, doUpdate
    end

    return true
end

-- 获取指定位置的武器数据
function XTeamPrefab:GetWeaponData(pos)
    return self.WeaponData and self.WeaponData[pos] or nil
end

-- 获取指定位置的武器共鸣数据表
function XTeamPrefab:GetWeaponResonance(pos)
    local weapon = self:GetWeaponData(pos)
    return weapon and weapon.ResonanceDict or nil
end

-- 获取指定位置武器的超频套装ID
function XTeamPrefab:GetWeaponOverrunSuitId(pos)
    local weapon = self:GetWeaponData(pos)
    return weapon and weapon.WeaponOverrunSuitId or 0
end

-- 获取指定位置指定槽位的意识数据
function XTeamPrefab:GetAwarenessData(pos, slot)
    if self.AwarenessData and self.AwarenessData[pos] then
        return self.AwarenessData[pos][slot]
    end
    return nil
end

function XTeamPrefab:GetWearingSuitInfoListByPos(pos)
    local equipList = {}
    
    local awarenessData = self:GetAllAwarenessData(pos)
    if awarenessData then
        for _, v in pairs(awarenessData) do
            local equip = XMVCA.XEquip:GetEquip(v.EquipId)
            if equip then
                table.insert(equipList, equip)
            end
        end
    end

    -- 获取意识套装信息列表（不含武器）
    local suitInfoList = XMVCA.XEquip:GetWearingSuitInfoListByEquipListAndWeapon(equipList)

    -- 处理武器超频套装
    local weaponData = self:GetWeaponData(pos)
    if not weaponData then
        return suitInfoList
    end

    local usingWeaponId = weaponData.EquipId
    local overrunSuitId = weaponData.WeaponOverrunSuitId
    if not (XTool.IsNumberValid(usingWeaponId) and XTool.IsNumberValid(overrunSuitId)) then
        return suitInfoList
    end

    -- 获取武器实体并检查是否可超限
    local weaponEquip = XMVCA.XEquip:GetEquip(usingWeaponId)
    if not weaponEquip or not weaponEquip:CanOverrun() then
        return suitInfoList
    end

    -- 构建武器套装信息基础数据
    local suitName = XMVCA.XEquip:GetSuitName(overrunSuitId)
    local weaponEquipSuitInfo = {
        SuitId = overrunSuitId,
        Name = suitName,
        Count = 0,
        IsOverrun = true
    }

    -- 获取技能描述表（用于判断有效计数）
    local skillDescs = XMVCA.XEquip:GetEquipSuitSkillDescription(overrunSuitId)
    if not skillDescs then
        return suitInfoList
    end

    -- 查找是否有相同套装ID的意识套装
    local targetSuitInfo = nil
    for _, suitInfo in pairs(suitInfoList) do
        if suitInfo.SuitId == overrunSuitId then
            targetSuitInfo = suitInfo
            break
        end
    end

    -- 计算可叠加的有效计数（仿照XEquipAgency的逻辑）
    local curCnt = targetSuitInfo and targetSuitInfo.Count or 0
    local maxAddCnt = 0
    for addCnt = 1, XEnumConst.EQUIP.OVERRUN_ADD_SUIT_CNT do
        -- 关键判断：只有技能描述存在时才认为计数有效
        if skillDescs[curCnt + addCnt] then
            maxAddCnt = addCnt
        end
    end

    if maxAddCnt <= 0 then
        return suitInfoList
    end

    -- 应用计数叠加
    if targetSuitInfo then
        targetSuitInfo.Count = curCnt + maxAddCnt
        targetSuitInfo.IsOverrun = true
    else
        weaponEquipSuitInfo.Count = maxAddCnt
        table.insert(suitInfoList, weaponEquipSuitInfo)
    end

    return suitInfoList
end

-- 获取指定位置所有意识槽位数据
function XTeamPrefab:GetAllAwarenessData(pos)
    return self.AwarenessData and self.AwarenessData[pos] or nil
end

--- 获取某个装备ID所在的预设位置
---@param equipId number
---@return number|nil 找不到则返回 nil
function XTeamPrefab:GetPosByEquipId(equipId)
    if not equipId then return nil end

    -- 检查武器数据
    if self.WeaponData then
        for pos, weapon in pairs(self.WeaponData) do
            if weapon and weapon.EquipId == equipId then
                return pos
            end
        end
    end

    -- 检查意识数据
    if self.AwarenessData then
        for pos, slotDict in pairs(self.AwarenessData) do
            if slotDict then
                for slot, item in pairs(slotDict) do
                    if item and item.EquipId == equipId then
                        return pos, slot
                    end
                end
            end
        end
    end

    return nil
end

-- 获取指定位置的伙伴数据
---@return XPartnerPrefab
function XTeamPrefab:GetPartnerData()
    return self.PartnerPrefab
end

-- 每次换人调用，检测当前首发位和队长位是否为空，空的话找到按顺序找到最近的一个有角色的pos,自动换上去
function XTeamPrefab:CheckOnlyOneEntityToSyncFirstAndCaptainPos()
    -- 找第一个有效角色位置
    local firstValidPos = nil
    for pos, charId in ipairs(self:GetEntityIds()) do
        if XTool.IsNumberValid(charId) then
            firstValidPos = pos
            break
        end
    end

    if not firstValidPos then
        return -- 队伍完全没角色，直接返回
    end

    -- 队长位
    if not XTool.IsNumberValid(self:GetCaptainPosEntityId()) then
        self:UpdateCaptainPos(firstValidPos, true)
    end

    -- 首发位
    if not XTool.IsNumberValid(self:GetFirstFightPosEntityId()) then
        self:UpdateFirstFightPos(firstValidPos, true)
    end
end

function XTeamPrefab:SwapPosData(posA, posB, notSyncToServer)
    if not posA or not posB or posA == posB then
        return
    end

    self:BeginSnapshotBatch()

    -- 1. 交换角色 ID
    self.EntitiyIds[posA], self.EntitiyIds[posB] = self.EntitiyIds[posB], self.EntitiyIds[posA]

    -- 2. 交换武器数据
    self.WeaponData[posA], self.WeaponData[posB] = self.WeaponData[posB], self.WeaponData[posA]

    -- 3. 交换意识数据
    self.AwarenessData[posA], self.AwarenessData[posB] = self.AwarenessData[posB], self.AwarenessData[posA]

    -- 4. 交换伙伴数据
    if self.PartnerPrefab then
        self.PartnerPrefab:SwapPosData(posA, posB)
    end

    self:CheckOnlyOneEntityToSyncFirstAndCaptainPos()

    -- 5. 同步到服务器
    if not notSyncToServer then
        self:SyncFullDataToServer()
    end
end

-- 将对应角色实际穿戴的装备数据复制到预设中
function XTeamPrefab:CopyRealCharacterEquipData(characterId, pos, notSyncToServer)
    -- 检查队伍里对应的角色，并拿到
    if not characterId then return end
    if not XTool.IsNumberValid(pos) then return end

    self:BeginSnapshotBatch()

    local equipData = XMVCA.XEquip:GetCharacterEquips(characterId)
    local hasDataAwarenessSiteDic = {}
    for k, xEquip in pairs(equipData) do
        if xEquip:IsWeapon() then
            self:CopyRealWeaponData(xEquip.Id, pos, true)
        else
            self:UpdateEquipAt(pos, xEquip:GetSite(), {EquipId = xEquip.Id, ResonanceDict = {}, WeaponOverrunSuitId = 0}, true)
            hasDataAwarenessSiteDic[xEquip:GetSite()] = true
        end
    end
    -- 单独检测空的意识槽位
    for i = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT, 1 do
        if not hasDataAwarenessSiteDic[i] then
            self:UpdateEquipAt(pos, i, nil, true)
        end
    end
    -- 检测 如果没有成功复制武器 说明复制有问题 中断并清空所有数据
    local weaponData = self:GetWeaponData(pos)
    if not weaponData or (not XTool.IsNumberValid(weaponData.EquipId)) then
        self:ClearPosData(pos)
        XLog.Error("XTeamPrefab:CopyRealCharacterEquipData:TeamPrefabId = %s, characterId = %s, pos = %s, 复制失败", self:GetId(), characterId, pos)
    end

    if not notSyncToServer then
        self:SyncFullDataToServer()
    end
end

--- 将拥有的实际的武器数据复制到预设中对应的位置
function XTeamPrefab:CopyRealWeaponData(equipId, pos, notSyncToServer, cb)
    -- 判断这个装备是否可以由该角色装备
    if not equipId or not pos then 
        return 
    end

    local xEquip = XMVCA.XEquip:GetEquip(equipId)
    if not xEquip:IsWeapon() then 
        return 
    end
    
    local characterId = self:GetEntityIdByTeamPos(pos)
    if not XTool.IsNumberValid(characterId) then 
        return 
    end

    if not xEquip:CheckCanCharWear(characterId) then
        XLog.Error("XTeamPrefab:CopyRealWeaponData:TeamPrefabId = %s, equipId = %s, characterId = %s, pos = %s, 不能装备", self:GetId(), equipId, characterId, pos)
        return
    end

    self:BeginSnapshotBatch()

    local data = 
    {
        EquipId = equipId,
        ResonanceDict = XMVCA.XEquip:GetResonanceSkillDic(equipId),
        WeaponOverrunSuitId = xEquip:GetOverrunChoseSuit(),
    }

    self:UpdateEquipAt(pos, 0, data, notSyncToServer, cb)
end

function XTeamPrefab:CopyRealWeaponResonance(resonanceDict, pos, notSyncToServer)
    self:BeginSnapshotBatch()

    local weaponData = self:GetWeaponData(pos)
    if not weaponData then return end
    weaponData.ResonanceDict = resonanceDict
    self:UpdateEquipAt(pos, 0, weaponData, notSyncToServer)
end

function XTeamPrefab:CopyRealWeaponWeaponOverrunSuitId(weaponOverrunSuitId, pos, notSyncToServer)
    self:BeginSnapshotBatch()

    local weaponData = self:GetWeaponData(pos)
    if not weaponData then return end
    weaponData.WeaponOverrunSuitId = weaponOverrunSuitId
    self:UpdateEquipAt(pos, 0, weaponData, notSyncToServer)
end

-- 将角色数据复制到对应位置（武器、意识、辅助机），角色Id为空时卸载对应位置
function XTeamPrefab:CopyRealCharacterToPos(characterId, pos, notSyncToServer)
    local getCurPosEntityId = self:GetEntityIdByTeamPos(pos)
    if getCurPosEntityId ~= characterId then
        local isCharIdValid = XTool.IsNumberValid(characterId)
        self:UpdateEntityTeamPos(characterId, pos, isCharIdValid)
    end
    if XTool.IsNumberValid(characterId) then
        self:CopyRealCharacterEquipData(characterId, pos, true)
        local realTeamPartner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(characterId)
        local newPartnerId = realTeamPartner and realTeamPartner:GetId()
        if XTool.IsNumberValid(newPartnerId) then
            self:GetPartnerData():EquipWithRealSkill(pos, newPartnerId)
        else
            self:GetPartnerData():Unload(pos)
        end
    else
        -- 卸载
        -- 清空武器
        self:UpdateEquipAt(pos, 0, nil, true)
        -- 清空意识
        self:ClearAwarenessData(pos, true)
        -- 清空辅助机
        self:GetPartnerData():Unload(pos)
    end
    
    if not notSyncToServer then
        self:CheckOnlyOneEntityToSyncFirstAndCaptainPos()
        self:RefreshGeneralSkills(true)
        self:SyncFullDataToServer()
    end
end

--- 用真正的队伍数据xTeam覆盖当前预设数据(from)
---@param xTeam XTeam
function XTeamPrefab:CoverFromRealTeamData(xTeam, cb, notSyncToServer)
    self:BeginSnapshotBatch()
    self:ClearAllData()
    self:UpdateCaptainPosAndFirstFightPos(xTeam:GetCaptainPos(), xTeam:GetFirstFightPos())
    self:SetEnterCgIndex(xTeam:GetEnterCgIndex(), true)
    self:SetSettleCgIndex(xTeam:GetSettleCgIndex(), true)
    for pos, characterId in ipairs(xTeam:GetEntityIds()) do
        self:CopyRealCharacterToPos(characterId, pos, true)
    end
    if xTeam:GetCurGeneralSkill() then -- 所有数据相信原队伍 它选效应Id = 0 也要相信
        self.SelectedGeneralSkill = xTeam:GetCurGeneralSkill()
    end

    if not notSyncToServer then
        self:SyncFullDataToServer(cb)
    end
end

--- 应用当前预设到真正的队伍XTeam中(to)
---@param xTeam XTeam
function XTeamPrefab:CoverToRealTeamData(xTeam)
    xTeam:UpdateEntityIds(self.EntitiyIds)
    xTeam:UpdateCaptainPosAndFirstFightPos(self.CaptainPos, self.FirstFightPos)
    xTeam:SetEnterCgIndex(self.EnterCgIndex)
    xTeam:SetSettleCgIndex(self.SettleCgIndex)
    xTeam:RefreshGeneralSkills(true, true)  -- 假设此方法本身不需要上行
    if XTool.IsNumberValid(xTeam.SelectedGeneralSkill) then -- 必须要判断，因为有可能是0
        xTeam.SelectedGeneralSkill = self.SelectedGeneralSkill
    end
end

function XTeamPrefab:UpdateSelectGeneralSkill(skillId, notSyncToServer, cb)
    self:BeginSnapshotBatch()
    self.SelectedGeneralSkill = skillId or 0
    if not notSyncToServer then
        self:SyncMetaDataToServer(cb)
    end
end

function XTeamPrefab:UpdateTeamName(name, cb)
    local oldName = self.TeamName
    self.TeamName = name
    self:SyncMetaDataToServer(function ()
        self.TeamName = name
        if cb then
            cb()
        end
    end)
    self.TeamName = oldName
end

function XTeamPrefab:UpdateFirstFightPos(value, notSyncToServer, cb)
    self:BeginSnapshotBatch()
    self.FirstFightPos = value
    if not notSyncToServer then
        self:SyncMetaDataToServer(cb)
    end
end

function XTeamPrefab:UpdateCaptainPos(value, notSyncToServer, cb)
    self:BeginSnapshotBatch()
    self.CaptainPos = value
    if not notSyncToServer then
        self:SyncMetaDataToServer(cb)
    end
end

function XTeamPrefab:SetEnterCgIndex(index, notSyncToServer, cb)
    self:BeginSnapshotBatch()
    self.EnterCgIndex = index
    if not notSyncToServer then
        self:SyncMetaDataToServer(cb)
    end
end

function XTeamPrefab:SetSettleCgIndex(index, notSyncToServer, cb)
    self:BeginSnapshotBatch()
    self.SettleCgIndex = index
    if not notSyncToServer then
        self:SyncMetaDataToServer(cb)
    end
end

-- 加一层“快照保护模式”
function XTeamPrefab:BeginSnapshotBatch()
    self:GetFullSnapshot()
    self._InSnapshotBatch = true
end

function XTeamPrefab:EndSnapshotBatch()
    self._InSnapshotBatch = false
end

-- 修改GetFullSnapshot方法以减少GC
function XTeamPrefab:GetFullSnapshot()
    if self._InSnapshotBatch then
        return
    end

    -- 初始化快照结构（仅在首次调用或结构变更时创建）
    if not self._LastSnapshot then
        self._LastSnapshot = {
            EntityIds = {},
            WeaponData = {},
            AwarenessData = {},
            PartnerData = nil,
            CaptainPos = 0,
            FirstFightPos = 0,
            TeamName = "",
            SelectedGeneralSkill = 0,
            EnterCgIndex = 0,
            SettleCgIndex = 0
        }
    end
    local snapshot = self._LastSnapshot

    -- 1. 处理角色ID列表（循环赋值复用table）
    local entityIds = self:GetEntityIds()
    -- 先清空现有数据
    for i = 1, #snapshot.EntityIds do
        snapshot.EntityIds[i] = nil
    end
    -- 再填充新数据
    for i = 1, #entityIds do
        snapshot.EntityIds[i] = entityIds[i]
    end

    -- 2. 处理武器数据（复用一级table，仅深拷贝二级数据）
    -- 先清空现有位置数据
    for pos in pairs(snapshot.WeaponData) do
        snapshot.WeaponData[pos] = nil
    end
    -- 再填充新数据
    if self.WeaponData then
        for pos, data in pairs(self.WeaponData) do
            if data then
                -- 复用或创建二级table
                local target = snapshot.WeaponData[pos] or {}
                -- 复制基础字段
                target.EquipId = data.EquipId
                target.WeaponOverrunSuitId = data.WeaponOverrunSuitId
                -- 处理ResonanceDict（复用table）
                if not target.ResonanceDict then
                    target.ResonanceDict = {}
                else
                    -- 清空现有共鸣数据
                    for k in pairs(target.ResonanceDict) do
                        target.ResonanceDict[k] = nil
                    end
                end
                -- 填充新共鸣数据
                if data.ResonanceDict then
                    for k, v in pairs(data.ResonanceDict) do
                        target.ResonanceDict[k] = v
                    end
                end
                snapshot.WeaponData[pos] = target
            end
        end
    end

    -- 3. 处理意识数据（复用多级table）
    -- 先清空现有位置数据
    for pos in pairs(snapshot.AwarenessData) do
        snapshot.AwarenessData[pos] = nil
    end
    -- 再填充新数据
    if self.AwarenessData then
        for pos, slotDict in pairs(self.AwarenessData) do
            if slotDict then
                -- 复用或创建位置级table
                local posTable = snapshot.AwarenessData[pos] or {}
                -- 清空槽位数据
                for slot in pairs(posTable) do
                    posTable[slot] = nil
                end
                -- 填充槽位数据
                for slot, data in pairs(slotDict) do
                    if data then
                        -- 复用或创建槽位级table
                        local slotData = posTable[slot] or {}
                        slotData.EquipId = data.EquipId
                        -- 处理ResonanceDict（复用table）
                        if not slotData.ResonanceDict then
                            slotData.ResonanceDict = {}
                        else
                            for k in pairs(slotData.ResonanceDict) do
                                slotData.ResonanceDict[k] = nil
                            end
                        end
                        if data.ResonanceDict then
                            for k, v in pairs(data.ResonanceDict) do
                                slotData.ResonanceDict[k] = v
                            end
                        end
                        posTable[slot] = slotData
                    end
                end
                snapshot.AwarenessData[pos] = posTable
            end
        end
    end

    -- 4. 处理其他基础数据（直接赋值）
    snapshot.PartnerData = self:GetPartnerData()
    snapshot.CaptainPos = self.CaptainPos
    snapshot.FirstFightPos = self.FirstFightPos
    snapshot.TeamName = self.TeamName
    snapshot.SelectedGeneralSkill = self.SelectedGeneralSkill
    snapshot.EnterCgIndex = self.EnterCgIndex
    snapshot.SettleCgIndex = self.SettleCgIndex

    return snapshot
end

-- 从最近一次保存的快照还原数据
function XTeamPrefab:RestoreFromSnapshot()
    local snapshot = self._LastSnapshot
    if not snapshot then return end
    
    -- 还原角色ID列表（循环赋值减少GC）
    for i = 1, #snapshot.EntityIds do
        self.EntitiyIds[i] = snapshot.EntityIds[i]
    end
    -- 清理原列表中可能存在的多余元素（如果快照长度更短）
    for i = #snapshot.EntityIds + 1, #self.EntitiyIds do
        self.EntitiyIds[i] = nil
    end
    
    -- 还原武器数据
    self.WeaponData = {}
    if snapshot.WeaponData then
        for pos, data in pairs(snapshot.WeaponData) do
            if data then
                local clonedData = XTool.Clone(data)
                if clonedData.ResonanceDict then
                    clonedData.ResonanceDict = XTool.Clone(clonedData.ResonanceDict)
                end
                self.WeaponData[pos] = clonedData
            end
        end
    end
    
    -- 还原意识数据
    self.AwarenessData = {}
    if snapshot.AwarenessData then
        for pos, slotDict in pairs(snapshot.AwarenessData) do
            if slotDict then
                self.AwarenessData[pos] = {}
                for slot, data in pairs(slotDict) do
                    local clonedData = XTool.Clone(data)
                    if clonedData.ResonanceDict then
                        clonedData.ResonanceDict = XTool.Clone(clonedData.ResonanceDict)
                    end
                    self.AwarenessData[pos][slot] = clonedData
                end
            end
        end
    end
    
    -- 还原其他核心数据
    self.CaptainPos = snapshot.CaptainPos
    self.FirstFightPos = snapshot.FirstFightPos
    self.TeamName = snapshot.TeamName
    self.SelectedGeneralSkill = snapshot.SelectedGeneralSkill
    self.EnterCgIndex = snapshot.EnterCgIndex
    self.SettleCgIndex = snapshot.SettleCgIndex
end

--- 同步接口
function XTeamPrefab:SyncFullDataToServer(cb)
    XDataCenter.TeamManager.TeamPrefabSetTeamRequestV4P40(self, cb)
end

function XTeamPrefab:SyncEquipDataToServer(pos, cb)
    XDataCenter.TeamManager.TeamPrefabUpdateEquipRequest(self, pos, cb)
end

function XTeamPrefab:SyncPartnerDataToServer(pos, cb)
    local partnerData = self:GetPartnerData()
    if not partnerData or not pos then return end

    local partnerId = partnerData:GetPartnerIdByPos(pos)
    XDataCenter.PartnerManager.TeamPreSetPartnerRequest(self:GetId(), pos, partnerId, partnerData:GetSkillData(partnerId), cb)
end

function XTeamPrefab:SyncMetaDataToServer(cb)
    local name = self:GetName()
    if string.IsNilOrEmpty(name) then 
        return 
    end

    XDataCenter.TeamManager.TeamPrefabUpdateMetadataRequest(self, cb)
end

--region 禁用方法
function XTeamPrefab:LoadTeamData() end
function XTeamPrefab:Save() end
function XTeamPrefab:GetSaveKey() end
function XTeamPrefab:LoadEntitiyIds() end
function XTeamPrefab:ManualSave() end
function XTeamPrefab:_Save() end
function XTeamPrefab:UpdateSaveCallback(callback) end
function XTeamPrefab:UpdateAutoSave(value) end
function XTeamPrefab:UpdateLocalSave(value) end
--endregion

return XTeamPrefab
