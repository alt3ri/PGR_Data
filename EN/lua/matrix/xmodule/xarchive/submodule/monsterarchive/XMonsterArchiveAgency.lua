---@class XMonsterArchiveAgency : XAgency
---@field _MainAgency XArchiveAgency
---@field private _Model XArchiveModel
local XMonsterArchiveAgency = XClass(XAgency, "XMonsterArchiveAgency")

function XMonsterArchiveAgency:OnInit()

end

function XMonsterArchiveAgency:InitRpc()
    
end

function XMonsterArchiveAgency:InitEvent()

end

function XMonsterArchiveAgency:OnRelease()

end

function XMonsterArchiveAgency:UpdateFullServerData(data)
    self._Model.MonsterArchiveModel:SetArchiveShowedMonsterList(data.Monsters)
    self._Model.MonsterArchiveModel:SetArchiveMonsterSettingUnlockIdsList(data.MonsterSettings)
    self._Model.MonsterArchiveModel:SetArchiveMonsterUnlockIdsList(data.MonsterUnlockIds)
    self._Model.MonsterArchiveModel:SetArchiveMonsterInfoUnlockIdsList(data.MonsterInfos)
    self._Model.MonsterArchiveModel:SetArchiveMonsterSkillUnlockIdsList(data.MonsterSkills)
end

--region --------------------------------怪物图鉴，数据获取相关------------------------------------------>>>
function XMonsterArchiveAgency:GetArchiveMonsterType(monsterId)
    local monsterCfg = self._Model.MonsterArchiveModel:GetMonster()[monsterId]
    return monsterCfg and monsterCfg.Type or nil
end

-- 根据npcId获取monsterId
-- PS:XArchiveAgency:GetSameNpcId该方法关联配置的Npc的会计入图鉴击杀计算内
-- PS:这里两张表的配置其实是强关联，详细配法最好问图鉴相关负责人
-- PS:以后根据NpcId获取MonsterId时不要直接走ArchiveNpcToMonster变量
function XMonsterArchiveAgency:GetMonsterIdByNpcId(npcId)
    local sameNpcId = self._Model.MonsterArchiveModel:GetSameNpcId(npcId)
    return self._Model.MonsterArchiveModel:GetArchiveNpcToMonster()[sameNpcId]
end

function XMonsterArchiveAgency:GetArchiveMonsterEntityByNpcId(npcId)
    local monsterId = self:GetMonsterIdByNpcId(npcId)
    if monsterId == nil then
        XLog.Error(string.format("npcId:%s没有在Share/Archive/Monster.tab或SameNpcGroup.tab配置", npcId))
        return nil
    end
    return self._Model.MonsterArchiveModel:GetArchiveMonsterData()[monsterId]
end

function XMonsterArchiveAgency:GetMonsterKillCount(npcId)
    local sameNpcId = self._Model.MonsterArchiveModel:GetSameNpcId(npcId)
    return self._Model.MonsterArchiveModel:GetMonsterKillCount(sameNpcId)
end

function XMonsterArchiveAgency:IsMonsterHaveRedPointByAll()
    local IsHaveRedPoint = false
    for type,_ in pairs(self._Model.MonsterArchiveModel:GetMonsterRedPointDic()) do
        if self:IsMonsterHaveRedPointByType(type) then
            IsHaveRedPoint = true
            break
        end
        if self:IsMonsterHaveNewTagByType(type) then
            IsHaveRedPoint = true
            break
        end
    end
    return IsHaveRedPoint
end

function XMonsterArchiveAgency:IsMonsterHaveNewTagByType(type)
    local IsHaveNewTag = false
    local monsterRedPointDict = self._Model.MonsterArchiveModel:GetMonsterRedPointDicByType(type)
    
    if not XTool.IsTableEmpty(monsterRedPointDict) then
        for monsterId,_ in pairs(monsterRedPointDict) do
            if self:IsMonsterHaveNewTagById(monsterId) then
                IsHaveNewTag = true
                break
            end
        end
    end
    return IsHaveNewTag
end

function XMonsterArchiveAgency:IsMonsterHaveRedPointByType(type)
    local IsHaveRedPoint = false
    local monsterRedPointDict=self._Model.MonsterArchiveModel:GetMonsterRedPointDicByType(type)
    if not XTool.IsTableEmpty(monsterRedPointDict) then
        for monsterId,_ in pairs(monsterRedPointDict) do
            if self:IsMonsterHaveRedPointById(monsterId) then
                IsHaveRedPoint = true
                break
            end
        end
    end
    return IsHaveRedPoint
end

function XMonsterArchiveAgency:IsMonsterHaveNewTagById(monsterId)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    if not monsterType then return false end
    local monsterRedPointDicWithType=self._Model.MonsterArchiveModel:GetMonsterRedPointDicByType(monsterType)
    if monsterRedPointDicWithType and monsterRedPointDicWithType[monsterId] then
        return monsterRedPointDicWithType[monsterId].IsNewMonster
    end
    return false
end

function XMonsterArchiveAgency:IsMonsterHaveRedPointById(monsterId)
    return self:IsHaveNewMonsterInfoByNpcId(monsterId) or
            self:IsHaveNewMonsterSkillByNpcId(monsterId) or
            self:IsHaveNewMonsterSettingByNpcId(monsterId)
end

function XMonsterArchiveAgency:IsHaveNewMonsterInfoByNpcId(monsterId)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    if not monsterType then return false end
    local monsterRedPointDicWithType=self._Model.MonsterArchiveModel:GetMonsterRedPointDicByType(monsterType)
    if monsterRedPointDicWithType and monsterRedPointDicWithType[monsterId] then
        return monsterRedPointDicWithType[monsterId].IsNewInfo
    end
    return false
end

function XMonsterArchiveAgency:IsHaveNewMonsterSkillByNpcId(monsterId)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    if not monsterType then return false end
    local monsterRedPointDicWithType=self._Model.MonsterArchiveModel:GetMonsterRedPointDicByType(monsterType)
    if monsterRedPointDicWithType and monsterRedPointDicWithType[monsterId] then
        return monsterRedPointDicWithType[monsterId].IsNewSkill
    end
    return false
end

function XMonsterArchiveAgency:IsHaveNewMonsterSettingByNpcId(monsterId)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    if not monsterType then return false end
    local monsterRedPointDicWithType=self._Model.MonsterArchiveModel:GetMonsterRedPointDicByType(monsterType)
    if monsterRedPointDicWithType and monsterRedPointDicWithType[monsterId] then
        return monsterRedPointDicWithType[monsterId].IsNewSetting
    end
    return false
end

function XMonsterArchiveAgency:IsArchiveMonsterUnlockByArchiveId(id)
    if XTool.IsNumberValid(id) then
        return self._Model.MonsterArchiveModel:GetMonsterUnlockById(id)
    end
    return false
end

--- 怪物在图鉴主界面是否解锁
function XMonsterArchiveAgency:GetMonsterUnlockMainById(monsterId)
    return self._Model.MonsterArchiveModel:GetMonsterUnlockMainById(monsterId)
end

function XMonsterArchiveAgency:GetMonsterEvaluateFromSever(NpcIds, cb)
    local now = XTime.GetServerNowTimestamp()
    local monsterId = self._Model.MonsterArchiveModel:GetArchiveNpcToMonster()[NpcIds[1]]
    local syscTime = self._Model.MonsterArchiveModel:GetLastSyncMonsterEvaluateTimeById(monsterId)

    if syscTime and now - syscTime < XEnumConst.Archive.SYNC_EVALUATE_SECOND then
        if cb then
            cb()
            return
        end
    end

    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.GetEvaluateRequest, {Ids = NpcIds}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:SetArchiveMonsterEvaluate(res.Evaluates)
        self:SetArchiveMonsterMySelfEvaluate(res.PersonalEvaluates)
        self._Model.MonsterArchiveModel:SetLastSyncMonsterEvaluateTimeById(monsterId, XTime.GetServerNowTimestamp())
        if cb then cb() end
    end)
end

function XMonsterArchiveAgency:SetArchiveMonsterEvaluate(evaluates)
    if not XTool.IsTableEmpty(evaluates) then
        for _,evaluate in pairs(evaluates) do
            if evaluate and evaluate.Id then
                self._Model.MonsterArchiveModel:SetMonsterEvaluateInListById(evaluate.Id, evaluate)
                for index,tag in pairs(evaluate.Tags) do
                    local tagCfg = self._Model:GetTag()[tag.Id]
                    if tagCfg and tagCfg.IsNotShow == 1 then
                        evaluate.Tags[index] = nil
                    end
                end
            end
        end
    end
end

function XMonsterArchiveAgency:SetArchiveMonsterMySelfEvaluate(mySelfEvaluates)
    if XTool.IsTableEmpty(mySelfEvaluates) then return end

    for _,mySelfEvaluate in pairs(mySelfEvaluates) do
        if mySelfEvaluate and mySelfEvaluate.Id then
            self._Model.MonsterArchiveModel:SetMonsterMySelfEvaluateInListById(mySelfEvaluate.Id, mySelfEvaluate)
            for index,tag in pairs(mySelfEvaluate.Tags) do
                local tagCfg = self._Model:GetTag()[tag]
                if tagCfg and tagCfg.IsNotShow == 1 then
                    mySelfEvaluate.Tags[index] = nil
                end
            end
        end
    end
end
--endregion

--region 配置表

function XMonsterArchiveAgency:GetArchiveMonsterConfigById(id)
    return self._Model.MonsterArchiveModel:GetMonster()[id]
end

function XMonsterArchiveAgency:GetArchiveMonsterInnerConfigById(id)
    return self._Model.MonsterArchiveModel:GetCfgMonsterInnerById(id)
end
--XMVCA.XArchive.MonsterArchiveAgency:GetArchiveMonsterInfoConfigById(0)
function XMonsterArchiveAgency:GetArchiveMonsterInfoConfigById(id)
    return self._Model.MonsterArchiveModel:GetMonsterInfo()[id]
end

function XMonsterArchiveAgency:GetArchiveMonsterInfoInnerConfigById(id)
    return self._Model.MonsterArchiveModel:GetCfgMonsterInfoInnerById(id)
end

function XMonsterArchiveAgency:GetArchiveMonsterSkillConfigById(id)
    return self._Model.MonsterArchiveModel:GetMonsterSkill()[id]
end

function XMonsterArchiveAgency:GetArchiveMonsterSettingConfigById(id)
    return self._Model.MonsterArchiveModel:GetMonsterSetting()[id]
end

function XMonsterArchiveAgency:GetArchiveMonsterSettingInnerConfigById(id)
    return self._Model.MonsterArchiveModel:GetCfgMonsterSettingInnerById(id)
end

function XMonsterArchiveAgency:GetMonsterEffectDatas(npcId, npcState)
    local archiveMonsterEffectData = self._Model.MonsterArchiveModel:GetArchiveMonsterEffectDatasDic()[npcId]
    return archiveMonsterEffectData and archiveMonsterEffectData[npcState]
end

function XMonsterArchiveAgency:GetMonsterNpcDataById(id)
    local npcData = self._Model.MonsterArchiveModel:GetMonsterNpcData()[id]
    if not npcData then
        XLog.ErrorTableDataNotFound("XMonsterArchiveAgency:GetMonsterNpcDataById", "配置表项", 'Client/Archive/MonsterNpcData.tab', "Id", tostring(id))
        return {}
    end
    return npcData
end

function XMonsterArchiveAgency:GetMonsterNpcIdByModelId(targetModelId)
    for npcId, data in pairs(self._Model.MonsterArchiveModel:GetMonsterNpcData()) do
        local modelIds = data.ModelId
        for _, modelId in pairs(modelIds) do
            if modelId == targetModelId then
                return data.Id
            end
        end
    end
    return false
end

function XMonsterArchiveAgency:GetMonsterRealName(id)
    local name = self:GetMonsterNpcDataById(id).Name
    if not name then
        XLog.ErrorTableDataNotFound("XMonsterArchiveAgency:GetMonsterRealName", "配置表项中的Name字段", 'Client/Archive/MonsterNpcData.tab', "id", tostring(id))
        return ""
    end
    return name
end

function XMonsterArchiveAgency:GetMonsterModel(id, index)
    return self:GetMonsterNpcDataById(id).ModelId[index or 1]
end

function XMonsterArchiveAgency:GetMonsterModelIds(id)
    return self:GetMonsterNpcDataById(id).ModelId
end

--endregion

--region --------------------------------怪物图鉴，数据更新相关------------------------------------------>>>

function XMonsterArchiveAgency:UpdateMonsterData()
    self._Model.MonsterArchiveModel:ResetMonsterRedPointDic()
    self:UpdateMonsterList()
    self:UpdateMonsterInfoList()
    self:UpdateMonsterSettingList()
    self:UpdateMonsterSkillList()
    XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_KILLCOUNTCHANGE)
end

function XMonsterArchiveAgency:UpdateMonsterList() --更新图鉴怪物列表数据
    local monsterModel = self._Model.MonsterArchiveModel
    local killCount = {}
    for _, showedMonster in pairs(monsterModel:GetShowedMonsterList()) do
        local sameNpcId = monsterModel:GetSameNpcId(showedMonster.Id)
        local monsterId = monsterModel:GetArchiveNpcToMonster()[sameNpcId]
        if monsterId then
            if not killCount[sameNpcId] then killCount[sameNpcId] = 0 end
            killCount[sameNpcId] = killCount[sameNpcId] + showedMonster.Killed
            monsterModel:SetMonsterKillCount(sameNpcId, killCount[sameNpcId])
            monsterModel:SetMonsterRedPointDic(monsterId, XEnumConst.Archive.MonsterRedPointType.Monster, nil)
            -- 若 Entity 已创建，同步写入（UI 已打开的场景）
            local monsterData = monsterModel:GetRawMonsterData()[monsterId]
            if monsterData then
                monsterData:UpdateData({ IsLockMain = false, Kill = { [sameNpcId] = killCount[sameNpcId] } })
            end
        end
    end
end

function XMonsterArchiveAgency:UpdateMonsterInfoList()--更新图鉴怪物信息列表数据
    local monsterModel = self._Model.MonsterArchiveModel
    for _, showedMonster in pairs(monsterModel:GetShowedMonsterList()) do
        local sameNpcId = monsterModel:GetSameNpcId(showedMonster.Id)
        local monsterId = monsterModel:GetArchiveNpcToMonster()[sameNpcId]
        if monsterId then
            local monsterCfg = monsterModel:GetMonster()[monsterId]
            local npcIds = monsterCfg and monsterCfg.NpcId
            if XTool.IsTableEmpty(npcIds) then
                goto continue1
            end
            for _, npcId in pairs(npcIds) do
                local typedCfgs = monsterModel:GetMonsterInfoCfgsByNpcId(npcId)
                if XTool.IsTableEmpty(typedCfgs) then
                    goto continue2
                end
                for _, cfgList in pairs(typedCfgs) do
                    for _, cfg in pairs(cfgList) do
                        local isUnLock = false
                        local lockDes  = ""
                        if cfg.Condition == 0 then
                            isUnLock = true
                        else
                            isUnLock, lockDes = XConditionManager.CheckCondition(cfg.Condition, cfg.GroupId)
                        end
                        monsterModel:SetMonsterInfoLockState(cfg.Id, not isUnLock, lockDes)
                        if isUnLock then
                            monsterModel:SetMonsterRedPointDic(monsterId, XEnumConst.Archive.MonsterRedPointType.MonsterInfo, cfg.Id)
                        end
                    end
                end
                :: continue2 ::
            end
            :: continue1 ::
        end
    end
end

function XMonsterArchiveAgency:UpdateMonsterSkillList()--更新图鉴怪物技能列表数据
    local monsterModel = self._Model.MonsterArchiveModel
    for _, showedMonster in pairs(monsterModel:GetShowedMonsterList()) do
        local sameNpcId = monsterModel:GetSameNpcId(showedMonster.Id)
        local monsterId = monsterModel:GetArchiveNpcToMonster()[sameNpcId]
        if monsterId then
            local monsterCfg = monsterModel:GetMonster()[monsterId]
            local npcIds = monsterCfg and monsterCfg.NpcId
            if XTool.IsTableEmpty(npcIds) then
                goto continue1
            end
            for _, npcId in pairs(npcIds) do
                local cfgList = monsterModel:GetMonsterSkillCfgsByNpcId(npcId)
                if XTool.IsTableEmpty(cfgList) then
                    goto continue2
                end
                for _, cfg in pairs(cfgList) do
                    local isUnLock = false
                    local lockDes  = ""
                    if cfg.Condition == 0 then
                        isUnLock = true
                    else
                        isUnLock, lockDes = XConditionManager.CheckCondition(cfg.Condition, cfg.GroupId)
                    end
                    monsterModel:SetMonsterSkillLockState(cfg.Id, not isUnLock, lockDes)
                    if isUnLock then
                        monsterModel:SetMonsterRedPointDic(monsterId, XEnumConst.Archive.MonsterRedPointType.MonsterSkill, cfg.Id)
                    end
                end
                :: continue2 ::
            end
            :: continue1 ::
        end
    end
end

function XMonsterArchiveAgency:UpdateMonsterSettingList()--更新图鉴怪物设定列表数据
    local monsterModel = self._Model.MonsterArchiveModel
    for _, showedMonster in pairs(monsterModel:GetShowedMonsterList()) do
        local sameNpcId = monsterModel:GetSameNpcId(showedMonster.Id)
        local monsterId = monsterModel:GetArchiveNpcToMonster()[sameNpcId]
        if monsterId then
            local monsterCfg = monsterModel:GetMonster()[monsterId]
            local npcIds = monsterCfg and monsterCfg.NpcId
            if XTool.IsTableEmpty(npcIds) then
                goto continue1
            end
            for _, npcId in pairs(npcIds) do
                local typedCfgs = monsterModel:GetMonsterSettingCfgsByNpcId(npcId)
                if XTool.IsTableEmpty(typedCfgs) then
                    goto continue2
                end
                for _, cfgList in pairs(typedCfgs) do
                    for _, cfg in pairs(cfgList) do
                        local isUnLock = false
                        local lockDes  = ""
                        if cfg.Condition == 0 then
                            isUnLock = true
                        else
                            isUnLock, lockDes = XConditionManager.CheckCondition(cfg.Condition, cfg.GroupId)
                        end
                        monsterModel:SetMonsterSettingLockState(cfg.Id, not isUnLock, lockDes)
                        if isUnLock then
                            monsterModel:SetMonsterRedPointDic(monsterId, XEnumConst.Archive.MonsterRedPointType.MonsterSetting, cfg.Id)
                        end
                    end
                end
                :: continue2 ::
            end
            :: continue1 ::
        end
    end
end

function XMonsterArchiveAgency:ClearMonsterRedPointDic(monsterId,type)
    local monsterType = self:GetArchiveMonsterType(monsterId)
    if not monsterType then return end
    self._Model.MonsterArchiveModel:ClearMonsterRedPointDic(monsterType,monsterId,type)
end

--endregion

--region Network - Request

--- 解锁图鉴怪物
function XMonsterArchiveAgency:DoUnlockArchiveMonsterRequest(id, cb)
    -- Id无效
    if not XTool.IsNumberValidEx(id) then
        return
    end
    
    -- 已解锁
    if self._Model.MonsterArchiveModel:GetMonsterUnlockById(id) then
        return
    end
    
    -- 请求解锁
    local req = { Ids = {id} }
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockArchiveMonsterRequest, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end
            
            return
        end

        self:ClearMonsterRedPointDic(id, XEnumConst.Archive.MonsterRedPointType.Monster)
        self._Model.MonsterArchiveModel:SetArchiveMonsterUnlockIdsList(req.Ids)
        
        XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTER)

        if cb then
            cb(true)
        end
    end)
end

--endregion

--region Rpc

function XMonsterArchiveAgency:OnNotifyArchiveLoginData(data)
    self:UpdateFullServerData(data)
end

function XMonsterArchiveAgency:OnNotifyArchiveMonsterRecord(data)
    self._Model.MonsterArchiveModel:AddArchiveShowedMonsterList(data.Monsters)
    self:UpdateMonsterData()
end

--endregion

return XMonsterArchiveAgency