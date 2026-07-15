---@class XMonsterArchiveControl : XControl
---@field _MainControl XArchiveControl
---@field private _Model XArchiveModel
local XMonsterArchiveControl = XClass(XControl, "XMonsterArchiveControl")

local tableInsert = table.insert

function XMonsterArchiveControl:OnInit()
end

function XMonsterArchiveControl:AddAgencyEvent()
end

function XMonsterArchiveControl:RemoveAgencyEvent()
end

function XMonsterArchiveControl:OnRelease()
end

--region --------------------------------怪物图鉴，数据获取相关------------------------------------------>>>

function XMonsterArchiveControl:GetArchiveMonsterEvaluate(npcId)
    return self._Model.MonsterArchiveModel:GetArchiveMonsterEvaluate(npcId)
end

function XMonsterArchiveControl:GetArchiveMonsterMySelfEvaluate(npcId)
    return self._Model.MonsterArchiveModel:GetArchiveMonsterMySelfEvaluate(npcId)
end

function XMonsterArchiveControl:GetArchiveMonsterEvaluateList()
    return self._Model.MonsterArchiveModel:GetArchiveMonsterEvaluateList()
end

function XMonsterArchiveControl:GetArchiveMonsterMySelfEvaluateList()
    return self._Model.MonsterArchiveModel:GetArchiveMonsterMySelfEvaluateList()
end

function XMonsterArchiveControl:GetMonsterArchiveName(monster)
    if monster:GetName() then
        return monster:GetName()
    end
    if monster:GetNpcId(1) then
        return XMVCA.XArchive.MonsterArchiveAgency:GetMonsterRealName(monster:GetNpcId(1))
    end
    return "NULL"
end

function XMonsterArchiveControl:GetArchiveMonsterList(type)
    if type then
        return self._Model.MonsterArchiveModel:GetArchiveMonsterList()[type] or {}
    end
    local list = {}
    for _, tmpType in pairs(self._Model.MonsterArchiveModel:GetArchiveMonsterList()) do
        for _, monster in pairs(tmpType) do
            tableInsert(list, monster)
        end
    end
    return self._Model:SortByOrder(list)
end

function XMonsterArchiveControl:GetArchiveMonsterInfoList(groupId, type)
    local monsterInfoGroup = self._Model.MonsterArchiveModel:GetArchiveMonsterInfoList()[groupId]
    if type then
        return monsterInfoGroup and monsterInfoGroup[type] or {}
    end


    local list = {}
    
    if not XTool.IsTableEmpty(monsterInfoGroup) then
        for _, tmpType in pairs(monsterInfoGroup) do
            for _, monster in pairs(tmpType) do
                tableInsert(list, monster)
            end
        end

        list =  self._Model:SortByOrder(list)
    end
    
    return list
end

function XMonsterArchiveControl:GetArchiveMonsterSkillList(groupId)
    if groupId then
        return self._Model.MonsterArchiveModel:GetArchiveMonsterSkillList()[groupId] or {}
    end
    local list = {}
    for _, group in pairs(self._Model.MonsterArchiveModel:GetArchiveMonsterSkillList()) do
        for _, monster in pairs(group) do
            tableInsert(list, monster)
        end
    end
    return self._Model:SortByOrder(list)
end

function XMonsterArchiveControl:GetArchiveMonsterSettingList(groupId, type)
    local monsterSettingGroup = self._Model.MonsterArchiveModel:GetArchiveMonsterSettingList()[groupId]
    if type then
        return monsterSettingGroup and monsterSettingGroup[type] or {}
    end
    local list = {}
    for _, tmpType in pairs(monsterSettingGroup) do
        for _, monster in pairs(tmpType) do
            tableInsert(list, monster)
        end
    end
    return self._Model:SortByOrder(list)
end

function XMonsterArchiveControl:GetMonsterCompletionRate(type)
    local unlocked, total = self._Model.MonsterArchiveModel:GetMonsterCompletionCount(type)
    if total < 1 then return 0 end
    return self._MainControl:GetPercent((unlocked / total) * 100)
end

--endregion

--region --------------------------------网络请求------------------------------------------>>>

function XMonsterArchiveControl:MonsterGiveEvaluate(npcId, score, difficulty, tags, cbBefore, cbAfter)
    local type = XEnumConst.Archive.SubSystemType.Monster
    local tb = { Id = npcId, Type = type, Score = score, Difficulty = difficulty, Tags = tags }
    local monsterModelRef = self._Model.MonsterArchiveModel
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.ArchiveEvaluateRequest, tb, function(res)
        if cbBefore then cbBefore() end
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        monsterModelRef:SetArchiveMonsterMySelfEvaluateDifficulty(npcId, score, difficulty, tags)
        if cbAfter then cbAfter() end
    end)
end

function XMonsterArchiveControl:MonsterGiveLike(likeList, cb)
    local type = XEnumConst.Archive.SubSystemType.Monster
    local monsterModelRef = self._Model.MonsterArchiveModel
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.ArchiveGiveLikeRequest, { LikeList = likeList, Type = type }, function(res)
        if cb then cb() end
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if XTool.IsTableEmpty(res.SuccessIds) or XTool.IsTableEmpty(likeList) then return end

        for _, id in pairs(res.SuccessIds) do
            for _, like in pairs(likeList) do
                if id == like.Id then
                    monsterModelRef:SetArchiveMonsterMySelfEvaluateLikeStatus(id, like.LikeStatus)
                end
            end
        end
    end)
end

function XMonsterArchiveControl:UnlockArchiveMonster(ids, cb)
    local list = self._Model.MonsterArchiveModel:GetLockMonsterIdsFromIdList(ids)
    if #list == 0 then
        return
    end
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockArchiveMonsterRequest, { Ids = list }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

function XMonsterArchiveControl:UnlockMonsterInfo(ids, cb)
    local list = self._Model.MonsterArchiveModel:GetLockMonsterInfoIdsFromIdList(ids)
    if #list == 0 then
        return
    end
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockMonsterInfoRequest, { Ids = list }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

function XMonsterArchiveControl:UnlockMonsterSkill(ids, cb)
    local list = self._Model.MonsterArchiveModel:GetLockMonsterSkillIdsFromIdList(ids)
    if #list == 0 then
        return
    end
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockMonsterSkillRequest, { Ids = list }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

function XMonsterArchiveControl:UnlockMonsterSetting(ids, cb)
    local list = self._Model.MonsterArchiveModel:GetLockMonsterSettingIdsFromIdList(ids)
    if #list == 0 then
        return
    end
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockMonsterSettingRequest, { Ids = list }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

--endregion

--region --------------------------------红点清除------------------------------------------>>>

function XMonsterArchiveControl:ClearMonsterNewTag(datas)
    local idList = {}

    if not datas then
        return
    end

    local IsHasNew = false
    for _, data in pairs(datas) do
        if XMVCA.XArchive.MonsterArchiveAgency:IsMonsterHaveNewTagById(data.Id) then
            IsHasNew = true
            break
        end
    end
    if not IsHasNew then return end

    for _, data in pairs(datas) do
        if not data.IsLockMain then
            tableInsert(idList, data.Id)
        end
    end

    if #idList < 1 then
        return
    end

    local monsterModelRef = self._Model.MonsterArchiveModel
    self:UnlockArchiveMonster(idList, function()
        for _, id in pairs(idList) do
            XMVCA.XArchive.MonsterArchiveAgency:ClearMonsterRedPointDic(id, XEnumConst.Archive.MonsterRedPointType.Monster)
        end
        monsterModelRef:SetArchiveMonsterUnlockIdsList(idList)
        XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTER)
    end)
end

function XMonsterArchiveControl:ClearDetailRedPoint(type, datas)
    local idList = {}
    if not datas then
        return
    end
    --------------------检测各类型是否有新增记录------------------
    if type == XEnumConst.Archive.MonsterDetailType.Info then
        local IsHasNew = false
        for _, data in pairs(datas) do
            if XMVCA.XArchive.MonsterArchiveAgency:IsHaveNewMonsterInfoByNpcId(data:GetId()) then
                IsHasNew = true
                break
            end
        end
        if not IsHasNew then return end
    elseif type == XEnumConst.Archive.MonsterDetailType.Setting then
        local IsHasNew = false
        for _, data in pairs(datas) do
            if XMVCA.XArchive.MonsterArchiveAgency:IsHaveNewMonsterSettingByNpcId(data:GetId()) then
                IsHasNew = true
                break
            end
        end
        if not IsHasNew then return end
    elseif type == XEnumConst.Archive.MonsterDetailType.Skill then
        local IsHasNew = false
        for _, data in pairs(datas) do
            if XMVCA.XArchive.MonsterArchiveAgency:IsHaveNewMonsterSkillByNpcId(data:GetId()) then
                IsHasNew = true
                break
            end
        end
        if not IsHasNew then return end
    end
    --------------------将各类型新增记录的ID放入一个List------------------
    for _, data in pairs(datas) do
        local npcIds = data:GetNpcId()
        if XTool.IsTableEmpty(npcIds) then
            goto continue
        end

        for _, npcId in pairs(npcIds) do
            if type == XEnumConst.Archive.MonsterDetailType.Info then
                local list = self:GetArchiveMonsterInfoList(npcId, nil)

                if not XTool.IsTableEmpty(list) then
                    for _, info in pairs(list) do
                        if not info:GetIsLock() then
                            tableInsert(idList, info:GetId())
                        end
                    end
                end
            elseif type == XEnumConst.Archive.MonsterDetailType.Setting then
                local list = self:GetArchiveMonsterSettingList(npcId, nil)
                for _, setting in pairs(list) do
                    if not setting:GetIsLock() then
                        tableInsert(idList, setting:GetId())
                    end
                end
            elseif type == XEnumConst.Archive.MonsterDetailType.Skill then
                local list = self:GetArchiveMonsterSkillList(npcId)
                for _, skill in pairs(list) do
                    if not skill:GetIsLock() then
                        tableInsert(idList, skill:GetId())
                    end
                end
            end
        end
        :: continue ::
    end

    if #idList < 1 then
        return
    end
    --------------------将各类型新增记录的红点取消通知服务器-----------------
    local monsterModelRef = self._Model.MonsterArchiveModel

    if type == XEnumConst.Archive.MonsterDetailType.Info then
        self:UnlockMonsterInfo(idList, function()
            for _, data in pairs(datas) do
                XMVCA.XArchive.MonsterArchiveAgency:ClearMonsterRedPointDic(data:GetId(), XEnumConst.Archive.MonsterRedPointType.MonsterInfo)
            end
            monsterModelRef:SetArchiveMonsterInfoUnlockIdsList(idList)
            XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERINFO)
        end)
    elseif type == XEnumConst.Archive.MonsterDetailType.Setting then
        self:UnlockMonsterSetting(idList, function()
            for _, data in pairs(datas) do
                XMVCA.XArchive.MonsterArchiveAgency:ClearMonsterRedPointDic(data:GetId(), XEnumConst.Archive.MonsterRedPointType.MonsterSetting)
            end
            monsterModelRef:SetArchiveMonsterSettingUnlockIdsList(idList)
            XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSETTING)
        end)
    elseif type == XEnumConst.Archive.MonsterDetailType.Skill then
        self:UnlockMonsterSkill(idList, function()
            for _, data in pairs(datas) do
                XMVCA.XArchive.MonsterArchiveAgency:ClearMonsterRedPointDic(data:GetId(), XEnumConst.Archive.MonsterRedPointType.MonsterSkill)
            end
            monsterModelRef:SetArchiveMonsterSkillUnlockIdsList(idList)
            XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSKILL)
        end)
    end
end

--endregion

--region 配置表



--endregion

return XMonsterArchiveControl
