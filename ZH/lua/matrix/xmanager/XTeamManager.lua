local XTeam = require("XEntity/XTeam/XTeam")
local XTeamPrefab = require("XEntity/XTeam/XTeamPrefab")
local XPartnerPrefab = require("XEntity/XPartner/XPartnerPrefab")
XTeamManagerCreator = function()
    ---@class XTeamManager XTeamManager
    local XTeamManager = {}

    local TeamDataKey = "STAGE_TEAM_DATA_"

    local MaxPos = CS.XGame.Config:GetInt("TeamMaxPos")   -- 默认一个队伍的位置数
    local CaptainPos -- 队长位
    local FirstFightPos -- 首发位
    local EmptyTeam = {
        TeamData = {},
        CaptainPos = 1,
        FirstFightPos = 1,
        -- 0表示仅保存在本地
        TeamId = 0,
    }

    local PlayerTeamGroupData = {}
    local PlayerTeamPrefabData = {}
    local EquipIdToPrefabTeamDic = {}
    local PartnerIdToPrefabTeamDic = {}
    local GeneralSkillRefreshTrigger = false

    local METHOD_NAME = {
        SetTeam = "TeamSetTeamRequest",
        SetPrefabTeam = "TeamPrefabSetTeamRequest"
    }

    -- XTeam
    -- 缓存队伍数据
    local TeamDic = {}

    -- 缓存预设队伍数据
    ---@type XTeamPrefab[]
    local TeamPrefabList = {}
    ---@type XTeam
    local BattleRoomCacheTeam = nil

    --SetTeamPos
    function XTeamManager.Init()
        CaptainPos = 0
        FirstFightPos = 0
        for _, cfg in pairs(XTeamConfig.GetTeamCfg()) do
            if cfg.IsCaptain and CaptainPos == 0 then
                CaptainPos = cfg.Id
            end

            if cfg.IsFirstFight and FirstFightPos == 0 then
                FirstFightPos = cfg.Id
            end
        end

        for i = 1, MaxPos do
            EmptyTeam.TeamData[i] = 0
        end
        --EmptyTeam = XReadOnlyTable.Create(EmptyTeam)
        XTeamManager.EmptyTeam = EmptyTeam

        if CS.XApplication.Debug then
            CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_DEBUGGERCHEAT_SERVER_RESPON_TEXT, XTeamManager.OnDebuggerCheatServerResponText)
        end
    end

    function XTeamManager.OnDebuggerCheatServerResponText(eventName, arg)
        -- 先判断是否包含TeamName字符串
        if not arg[0] or not string.find(arg[0], "TeamName") then
            return
        end
        
        local serverTeams = XTool.Json2LuaTable(arg[0])
        local localTeams = XDataCenter.TeamManager.GetTeamPrefabList()
    
        -- 转换服务器数据为便于对比的格式（将数组转为按TeamId映射的表）
        local serverTeamMap = {}
        for _, serverTeam in ipairs(serverTeams) do
            serverTeamMap[serverTeam.TeamId] = serverTeam
        end
        XLog.Debug("[TeamPrefab]ServerTeam ", serverTeamMap)
    
        -- 转换本地数据为便于对比的格式（将数组转为按TeamId映射的表）
        local localTeamMap = {}
        for _, localTeam in ipairs(localTeams) do
            localTeamMap[localTeam.Id] = localTeam
        end
        XLog.Debug("[TeamPrefab]LocalTeam ", localTeamMap)
    
        local allMatch = true
        local mismatchInfoList = {}
    
        -- 遍历所有服务器队伍进行对比
        for teamId, serverTeam in pairs(serverTeamMap) do
            local localTeam = localTeamMap[teamId]
            if not localTeam then
                allMatch = false
                table.insert(mismatchInfoList, string.format(
                    "队伍不存在 - 服务器存在该队伍但本地不存在，TeamId: %d, 队伍名: %s",
                    teamId, serverTeam.TeamName or "未知"
                ))
                goto continue  -- 跳过不存在的本地队伍的后续对比
            end
    
            -- 对比基础字段（非Pos相关）
            local baseFields = {
                {name = "TeamId", serverVal = serverTeam.TeamId, localVal = localTeam.Id},
                {name = "TeamName", serverVal = serverTeam.TeamName, localVal = localTeam.TeamName},
                {name = "CaptainPos", serverVal = serverTeam.CaptainPos, localVal = localTeam.CaptainPos},
                {name = "FirstFightPos", serverVal = serverTeam.FirstFightPos, localVal = localTeam.FirstFightPos},
                {name = "EnterCgIndex", serverVal = serverTeam.EnterCgIndex, localVal = localTeam.EnterCgIndex},
                {name = "SettleCgIndex", serverVal = serverTeam.SettleCgIndex, localVal = localTeam.SettleCgIndex},
                {name = "SelectedGeneralSkill", serverVal = serverTeam.SelectedGeneralSkill, localVal = localTeam.SelectedGeneralSkill or 0}
            }
    
            for _, field in ipairs(baseFields) do
                if field.serverVal ~= field.localVal then
                    allMatch = false
                    table.insert(mismatchInfoList, string.format(
                        "字段不一致 - TeamId: %d, 队伍名: %s, 字段: %s, 服务器值: %s, 本地值: %s",
                        teamId, serverTeam.TeamName or "未知", field.name,
                        tostring(field.serverVal), tostring(field.localVal)
                    ))
                end
            end
    
            -- 对比角色数据（按位置）
            local maxPos = XDataCenter.TeamManager.GetMaxPos() or 3  -- 使用配置的最大位置数，默认3
            for pos = 1, maxPos do
                -- 角色ID对比
                local serverCharId = serverTeam.TeamData and serverTeam.TeamData[tostring(pos)] or 0
                local localCharId = localTeam.EntitiyIds and localTeam.EntitiyIds[pos] or 0
                if serverCharId ~= localCharId then
                    allMatch = false
                    table.insert(mismatchInfoList, string.format(
                        "角色不一致 - TeamId: %d, 队伍名: %s, 位置: %d, 服务器角色Id: %d, 本地角色Id: %d",
                        teamId, serverTeam.TeamName or "未知", pos, serverCharId, localCharId
                    ))
                end
    
                -- 武器数据对比（slot=0）
                local serverEquipData = serverTeam.EquipData and serverTeam.EquipData[tostring(pos)] or {}
                local serverWeapon = serverEquipData.EquipDataDict and serverEquipData.EquipDataDict["0"] or {}
                local serverWeaponId = serverWeapon.EquipId or 0
                local serverOverrunSuitId = serverWeapon.WeaponOverrunSuitId or 0
    
                local localWeapon = localTeam.WeaponData and localTeam.WeaponData[pos] or {}
                local localWeaponId = localWeapon.EquipId or 0
                local localOverrunSuitId = localWeapon.WeaponOverrunSuitId or 0
    
                if serverWeaponId ~= localWeaponId then
                    allMatch = false
                    table.insert(mismatchInfoList, string.format(
                        "武器不一致 - TeamId: %d, 队伍名: %s, 位置: %d, 服务器武器Id: %d, 本地武器Id: %d",
                        teamId, serverTeam.TeamName or "未知", pos, serverWeaponId, localWeaponId
                    ))
                end
    
                if serverOverrunSuitId ~= localOverrunSuitId then
                    allMatch = false
                    table.insert(mismatchInfoList, string.format(
                        "武器超频套装不一致 - TeamId: %d, 队伍名: %s, 位置: %d, 服务器套装Id: %d, 本地套装Id: %d",
                        teamId, serverTeam.TeamName or "未知", pos, serverOverrunSuitId, localOverrunSuitId
                    ))
                end
    
                -- 意识数据对比（slot=1-6）
                local serverAwarenessDict = serverEquipData.EquipDataDict or {}
                local localAwarenessData = localTeam.AwarenessData and localTeam.AwarenessData[pos] or {}
    
                -- 收集所有需要对比的意识槽位（服务器和本地的并集）
                local slotsToCheck = {}
                for slotStr in pairs(serverAwarenessDict) do
                    local slot = tonumber(slotStr)
                    if slot and slot >= 1 and slot <= 6 then  -- 意识槽位范围1-6
                        slotsToCheck[slot] = true
                    end
                end
                for slot in pairs(localAwarenessData) do
                    if slot >= 1 and slot <= 6 then
                        slotsToCheck[slot] = true
                    end
                end
    
                -- 对比每个意识槽位
                for slot in pairs(slotsToCheck) do
                    local serverAwareness = serverAwarenessDict[tostring(slot)] or {}
                    local localAwareness = localAwarenessData[slot] or {}
    
                    local serverEquipId = serverAwareness.EquipId or 0
                    local localEquipId = localAwareness.EquipId or 0
    
                    if serverEquipId ~= localEquipId then
                        allMatch = false
                        table.insert(mismatchInfoList, string.format(
                            "意识不一致 - TeamId: %d, 队伍名: %s, 位置: %d, 槽位: %d, 服务器意识Id: %d, 本地意识Id: %d",
                            teamId, serverTeam.TeamName or "未知", pos, slot, serverEquipId, localEquipId
                        ))
                    end
                end
            end
    
            ::continue::
        end
    
        -- 检查本地存在但服务器不存在的队伍
        for teamId, localTeam in pairs(localTeamMap) do
            if not serverTeamMap[teamId] then
                allMatch = false
                table.insert(mismatchInfoList, string.format(
                    "队伍不存在 - 本地存在该队伍但服务器不存在，TeamId: %d, 队伍名: %s",
                    teamId, localTeam.TeamName or "未知"
                ))
            end
        end
    
        -- 输出结果
        if allMatch then
            print("[TeamPrefab]数据对比成功：服务器与本地队伍数据完全一致")
        else
            XLog.Error("[TeamPrefab]数据对比失败，不一致项如下：\n", mismatchInfoList)
        end
    end
    
    function XTeamManager.SetGeneralSkillRefreshTrigger()
        GeneralSkillRefreshTrigger = true
    end

    function XTeamManager.GetGeneralSkillRefreshTrigger()
        local value = GeneralSkillRefreshTrigger
        GeneralSkillRefreshTrigger = false
        return value
    end

    function XTeamManager.GetTeamId(typeId, stageId)
        local teams = XTeamConfig.GetTeamsByTypeId(typeId)
        if teams == nil then
            return nil
        end

        local sectionId = 0
        local chapterId = 0
        if stageId ~= nil then
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            sectionId = stageInfo.SectionId
            chapterId = stageInfo.ChpaterId
            if sectionId == nil or chapterId == nil then
                return nil
            end
        end

        -- 匹配规则：chapterId, sectionId, stageId 逐级查找，某一项为 nil 时，表示匹配上一级
        for _, val in pairs(teams) do
            if #val.ChapterId <= 0 then
                return val.TeamId         -- 匹配 TypeId
            end

            for _, cId in pairs(val.ChapterId) do
                if chapterId > 0 and cId == chapterId then
                    if #val.SectionId <= 0 then
                        return val.TeamId         -- 匹配 chapterId
                    end

                    for _, sId in pairs(val.SectionId) do
                        if sectionId > 0 and sId == sectionId then
                            if #val.StageId <= 0 then
                                return val.TeamId     -- 匹配 sectionId
                            end

                            for _, stId in pairs(val.StageId) do
                                if stId == stageId then
                                    return val.TeamId     -- 匹配 stageId
                                end
                            end
                        end
                    end
                end
            end
        end

        return nil
    end

    -- 玩家队伍中队长的位置Id
    -- 已废弃
    function XTeamManager.GetTeamCaptainKey(teamId)
        return teamId << 8
    end

    -- 已废弃
    function XTeamManager.GetValidPos(teamData)
        local posId = 1
        for k, v in pairs(teamData) do
            if v > 0 then
                posId = k
                break
            end
        end
        return posId
    end

    local function GetTeamKey(stageId)
        local stageType = XMVCA.XFuben:GetStageType(stageId)
        if not stageType then
            XLog.Warning("[XTeamManager] 找不到这个关卡对应的stageType" .. tostring(stageId))
            stageType = 0
        end
        return string.format("%s%s_%d_%s", TeamDataKey, tostring(XPlayer.Id), stageType, tostring(stageId))
    end

    -- 使用stageId作为Key本地保存编队信息
    function XTeamManager.SaveTeamLocal(curTeam, stageId)
        if not stageId then
            XLog.Warning("stageId is nil !!")
            return
        end
        XSaveTool.SaveData(GetTeamKey(stageId), curTeam)
    end

    -- 使用stageId作为Key读取本地编队信息
    function XTeamManager.LoadTeamLocal(stageId)
        if not stageId then
            XLog.Warning("stageId is nil")
            return EmptyTeam
        end

        local team = XSaveTool.GetData(GetTeamKey(stageId)) or EmptyTeam
        for _, v in ipairs(team.TeamData) do
            if v ~= 0 and not XRobotManager.CheckIsRobotId(v) and not XMVCA.XCharacter:IsOwnCharacter(v) then
                return EmptyTeam
            end
        end

        return team
    end

    -- 使用TeamSetTeamRequest协议保存使用TeamId的XTeamData
    function XTeamManager.SetPlayerTeam(curTeam, isPrefab, cb)
        local curTeamId = curTeam.TeamId
        if curTeamId == 0 then
            XTeamManager.SetPlayerTeamLocal(curTeam, isPrefab, cb)
            return
        end

        local params = {}
        params.TeamData = {}
        params.TeamId = curTeamId
        XMessagePack.MarkAsTable(params.TeamData)
        for k, v in pairs(curTeam.TeamData) do
            params.TeamData[k] = v
        end
        params.CaptainPos = curTeam.CaptainPos
        params.FirstFightPos = curTeam.FirstFightPos
        params.TeamName = curTeam.TeamName
        params.SelectedGeneralSkill = curTeam.SelectedGeneralSkill
        params.EnterCgIndex = curTeam.EnterCgIndex
        params.SettleCgIndex = curTeam.SettleCgIndex
        local methodName, req
        if isPrefab then
            local partnerPrefab = XTeamManager.GetPartnerPrefab(curTeamId)
            params.PartnerData = partnerPrefab:GetPartnerData()
            XMessagePack.MarkAsTable(params.PartnerData)
            methodName = METHOD_NAME.SetPrefabTeam
            req = { TeamPrefabData = params }
        else
            methodName = METHOD_NAME.SetTeam
            req = { TeamData = params }
        end

        --local req = { TeamData = params, IsPrefab = isPrefab }
        XNetwork.Call(methodName, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XTeamManager.SetPlayerTeamLocal(curTeam, isPrefab, cb)
        end)
    end

    function XTeamManager.GetNewTeamPrfabTeamId()
        local targetTeamId = nil
        local teamIdSet = {}
        local maxTeamId = 0
        
        -- 收集现有 TeamId，并记录最大值
        for _, xTeamPrefab in pairs(TeamPrefabList) do
            local teamId = xTeamPrefab:GetId()
            teamIdSet[teamId] = true
            if teamId > maxTeamId then
                maxTeamId = teamId
            end
        end
        
        -- 查找最小缺失的TeamId
        for i = 1, maxTeamId do
            if not teamIdSet[i] then
                targetTeamId = i
                break
            end
        end
        
        -- 如果没有缺失，取最大值+1
        if not targetTeamId then
            targetTeamId = maxTeamId + 1
        end
        return targetTeamId
    end

    function XTeamManager.TeamPrefabMoveForwardRequest(teamId, cb)
        XNetwork.Call("TeamPrefabMoveForwardRequest", {TeamId = teamId}, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end

            for i = 2, #TeamPrefabList do
                local prefab = TeamPrefabList[i]
                if prefab:GetId() == teamId then
                    -- 交换当前位置 prefab 与前一个位置 prefab
                    TeamPrefabList[i], TeamPrefabList[i - 1] = TeamPrefabList[i - 1], TeamPrefabList[i]
                end
            end

            if cb then cb() end
        end)
    end

    function XTeamManager.TeamPrefabAddRequestV4P0(cb)
        local teamId = XTeamManager.GetNewTeamPrfabTeamId()

        local teamData = {}
        for i = 1, MaxPos do
            teamData[i] = 0
        end

        local equipData = {}
        for i = 1, MaxPos do
            equipData[i] = {}
        end

        -- 构造请求
        local request = {
            TeamId = teamId,
            TeamName = CS.XTextManager.GetText("TeamPrefabDefaultName", teamId),
            TeamData = teamData,
            CaptainPos = 1,
            FirstFightPos = 1,
            EnterCgIndex = 0,
            SettleCgIndex = 0,
            EquipData = equipData,
        }
        XMessagePack.MarkAsTable(request.TeamData)
        XMessagePack.MarkAsTable(request.EquipData)

        XNetwork.Call("TeamPrefabSetTeamRequest", {TeamPrefabData = request}, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
            
            table.insert(TeamPrefabList, XTeamPrefab.New(request))

            XUiManager.PopupLeftTip(XUiHelper.GetText("TeamPrefabCreated", request.TeamName))
            if cb then cb() end
        end)
    end

    function XTeamManager.TeamPrefabDelRequest(teamId, cb)
        local request = {TeamId = teamId}
        XNetwork.Call("TeamPrefabDelRequest", request, function (response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end

            for index, xTeamPrefab in ipairs(TeamPrefabList) do
                if xTeamPrefab:GetId() == teamId then
                    table.remove(TeamPrefabList, index)
                    break  -- 删除成功
                end
            end

            XTeamManager.RefreshEquipIdAndPartnerIdToPrefabTeamDic()

            if cb then cb() end
        end)
    end

    --- 完整修改单个TeamPrefab数据
    ---@param xTeamPrefab XTeamPrefab
    ---@param cb fun
    function XTeamManager.TeamPrefabSetTeamRequestV4P40(xTeamPrefab, cb)
        local equipData = {}
        for i = 1, MaxPos do
            equipData[i] = {}
        end

        local request = {
            TeamId = xTeamPrefab.Id,
            TeamName = xTeamPrefab.TeamName,
            TeamData = xTeamPrefab:GetEntityIds(), -- table<int>
            CaptainPos = xTeamPrefab:GetCaptainPos(),
            FirstFightPos = xTeamPrefab:GetFirstFightPos(),
            EquipData = equipData,   -- table<int, TeamEquipData>
            SelectedGeneralSkill = xTeamPrefab:GetCurGeneralSkill(),
            EnterCgIndex = xTeamPrefab.EnterCgIndex,
            SettleCgIndex = xTeamPrefab.SettleCgIndex,
        }
        XMessagePack.MarkAsTable(request.TeamData)
        XMessagePack.MarkAsTable(request.EquipData)

        ----------------------------------------
        -- 【构建辅助机数据 PartnerData】
        ----------------------------------------
        local partnerData = xTeamPrefab:GetPartnerData()
        if partnerData then
            for pos = 1, MaxPos, 1 do
                local curPosEntityId = xTeamPrefab:GetEntityIdByTeamPos(pos)
                if XTool.IsNumberValid(curPosEntityId) then
                    local requestPartnerData = partnerData:GetPartnerRequestDataByPos(pos)
                    if requestPartnerData then
                        request.PartnerData = request.PartnerData or {}
                        request.PartnerData[pos] = requestPartnerData
                        XMessagePack.MarkAsTable(requestPartnerData)
                        if requestPartnerData.SkillData then
                            XMessagePack.MarkAsTable(requestPartnerData.SkillData)
                        end
                    end
                end
            end
            if request.PartnerData then
                XMessagePack.MarkAsTable(request.PartnerData)
            end
        end

        ----------------------------------------
        -- 【构建装备数据 EquipData】
        ----------------------------------------
        for pos = 1, MaxPos do
            local weapon = xTeamPrefab:GetWeaponData(pos)
            local awareness = xTeamPrefab:GetAllAwarenessData(pos)

            request.EquipData[pos] = request.EquipData[pos] or {}
            request.EquipData[pos]["EquipDataDict"] = request.EquipData[pos]["EquipDataDict"] or {}
            XMessagePack.MarkAsTable(request.EquipData[pos]["EquipDataDict"])

            if weapon then
                request.EquipData[pos]["EquipDataDict"][0] = weapon
                XMessagePack.MarkAsTable(request.EquipData[pos])
                XMessagePack.MarkAsTable(request.EquipData[pos]["EquipDataDict"][0])
                if request.EquipData[pos]["EquipDataDict"][0].ResonanceDict then
                    XMessagePack.MarkAsTable(request.EquipData[pos]["EquipDataDict"][0].ResonanceDict)
                end
            end

            if awareness then
                for i, v in pairs(awareness) do
                    request.EquipData[pos]["EquipDataDict"][i] = v
                    XMessagePack.MarkAsTable(request.EquipData[pos]["EquipDataDict"][i])
                    if request.EquipData[pos]["EquipDataDict"][i].ResonanceDict then
                        XMessagePack.MarkAsTable(request.EquipData[pos]["EquipDataDict"][i].ResonanceDict)
                    end
                end
            end
        end

        ----------------------------------------
        -- 【构建标签数据 TagSet】
        ----------------------------------------
        request.TagsSet = xTeamPrefab:GetTagsList()

        ----------------------------------------
        -- 【构建形态技能数据 SwitchSkills】
        ----------------------------------------
        request.SwitchSkills = xTeamPrefab:GetSwitchSkills()
        XMessagePack.MarkAsTable(request.SwitchSkills)

        ----------------------------------------
        -- ✅ 发送请求
        ----------------------------------------
        XNetwork.Call("TeamPrefabSetTeamRequest", {TeamPrefabData = request}, function(response)
            xTeamPrefab:EndSnapshotBatch()
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                xTeamPrefab:RestoreFromSnapshot()
                return
            end

            -- 刷新equip预设缓存
            XTeamManager.RefreshEquipIdAndPartnerIdToPrefabTeamDic()

            if cb then cb() end
        end)
    end

    ---@param xTeamPrefab XTeamPrefab
    function XTeamManager.TeamPrefabUpdateEquipRequest(xTeamPrefab, pos, cb)
        local request = 
        {
            TeamId = xTeamPrefab:GetId(),
            TeamPos = pos,
            TeamPrefabEquipData = 
            {
                EquipDataDict = {}
            }
        }
        XMessagePack.MarkAsTable(request.TeamPrefabEquipData)
        XMessagePack.MarkAsTable(request.TeamPrefabEquipData["EquipDataDict"])

        local weapon = xTeamPrefab:GetWeaponData(pos)
        if weapon then
            request.TeamPrefabEquipData["EquipDataDict"][0] = weapon
            XMessagePack.MarkAsTable(request.TeamPrefabEquipData["EquipDataDict"][0])
            if request.TeamPrefabEquipData["EquipDataDict"][0].ResonanceDict then
                XMessagePack.MarkAsTable(request.TeamPrefabEquipData["EquipDataDict"][0].ResonanceDict)
            end
        end

        local awareness = xTeamPrefab:GetAllAwarenessData(pos)
        if awareness then
            for i, v in pairs(awareness) do
                request.TeamPrefabEquipData["EquipDataDict"][i] = v
                XMessagePack.MarkAsTable(request.TeamPrefabEquipData["EquipDataDict"][i])
                if request.TeamPrefabEquipData["EquipDataDict"][i].ResonanceDict then
                    XMessagePack.MarkAsTable(request.TeamPrefabEquipData["EquipDataDict"][i].ResonanceDict)
                end
            end
        end

        XNetwork.Call("TeamPrefabUpdateEquipRequest", request, function(res)
            xTeamPrefab:EndSnapshotBatch()
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                xTeamPrefab:RestoreFromSnapshot()
                return
            end
            
            -- 刷新equip预设缓存
            XTeamManager.RefreshEquipIdAndPartnerIdToPrefabTeamDic()

            -- 提示成功
            XUiManager.TipText("TeamPrefabEquipModifySuccess")
            if cb then cb() end
        end)
    end

    -- 应用当前编队的穿戴同步至角色
    ---@param teamId number
    function XTeamManager.TeamPrefabApplyRequest(teamId, cb)
        local request = {TeamId = teamId}
        XNetwork.Call("TeamPrefabApplyRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local xTeamPrefab = XTeamManager.GetTeamPrefabDataByTeamId(teamId)
            if xTeamPrefab then
                for pos = 1, MaxPos, 1 do
                    local entityId = xTeamPrefab:GetEntityIdByTeamPos(pos)
                    if XTool.IsNumberValid(entityId) then
                        -- 穿武器
                        local weaponData = xTeamPrefab:GetWeaponData(pos)
                        local weaponEquipId = weaponData and weaponData.EquipId
                        if XTool.IsNumberValid(weaponEquipId) then
                            XMVCA.XEquip:OnEquipPutOnSuccess(entityId, weaponEquipId, true)
                        end

                        -- 穿意识
                        local allAwarenessData = xTeamPrefab:GetAllAwarenessData(pos)
                        if allAwarenessData then
                            for slot, v in pairs(allAwarenessData) do
                                local awarenessEquipId = v.EquipId
                                if XTool.IsNumberValid(awarenessEquipId) then
                                    XMVCA.XEquip:OnEquipPutOnSuccess(entityId, awarenessEquipId, true)
                                end
                            end
                        end

                    end
                end
            end

            -- 提示成功
            XUiManager.TipText("TeamPrefabApplySuccess")
            if cb then cb() end
        end)
    end
    
    ---@param xTeamPrefab XTeamPrefab
    function XTeamManager.TeamPrefabUpdateMetadataRequest(xTeamPrefab, cb)
        local request = 
        {
            TeamId = xTeamPrefab:GetId(),
            PrefabTeamInfo = 
            {
                TeamName = xTeamPrefab:GetName(),
                CaptainPos = xTeamPrefab:GetCaptainPos(),
                FirstFightPos = xTeamPrefab:GetFirstFightPos(),
                EnterCgIndex = xTeamPrefab:GetEnterCgIndex(),
                SettleCgIndex = xTeamPrefab:GetSettleCgIndex(),
                SelectedGeneralSkill = xTeamPrefab:GetCurGeneralSkill()
            }
        }
        XMessagePack.MarkAsTable(request.PrefabTeamInfo)

        XNetwork.Call("TeamPrefabUpdateMetadataRequest", request, function(res)
            xTeamPrefab:EndSnapshotBatch()
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                xTeamPrefab:RestoreFromSnapshot()
                return
            end
            
            if cb then cb() end
        end)
    end

    --- 设置编队预设标签
    ---@param teamId number 预设队伍Id
    ---@param tags table 数组形式 {tagId1, tagId2}
    ---@param cb function 成功回调
    function XTeamManager.TeamPrefabSetTagsRequest(teamId, tags, cb)
        local request = {
            TeamId = teamId,
            Tags = tags or {}
        }

        XNetwork.Call("TeamPrefabSetTagsRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local xTeamPrefab = XTeamManager.GetTeamPrefabDataByTeamId(teamId)
            if xTeamPrefab then
                xTeamPrefab:InitTagsData(tags)
            end

            if cb then cb() end
        end)
    end

    -- 更新TeamId的数据缓存，服务器的XTeamData只在登录的时候下发
    function XTeamManager.SetPlayerTeamLocal(curTeam, isPrefab, cb, saveXTeam)
        if saveXTeam == nil then saveXTeam = true end

        if saveXTeam then
            XTeamManager.SaveXTeam(curTeam.TeamId)
        end

        local curTeamId = curTeam.TeamId
        local characterCheckTable = {}

        local changeCharacter = {}      -- 更改成员的Id数组
        local playCvCharacterInfo = {}  -- 要播放语音的角色信息
        playCvCharacterInfo.Id = 0
        playCvCharacterInfo.IsCaptain = false

        -- 更改成员数，数量等于1，播放该角色的入队语音，数量大于等于2，只播放队长语音，没有队长就不播放语音
        local changeCount = 0

        local playerTeamData = isPrefab and PlayerTeamPrefabData or PlayerTeamGroupData
        -- 更新客户端队伍缓存
        if playerTeamData[curTeamId] == nil then
            playerTeamData[curTeamId] = {}
        else
            for _, characterId in pairs(playerTeamData[curTeamId].TeamData) do
                characterCheckTable[characterId] = true
            end

            for pos, characterId in pairs(curTeam.TeamData) do
                if (not characterCheckTable[characterId]) and (characterId ~= 0) then

                    changeCount = changeCount + 1
                    if pos == curTeam.CaptainPos then
                        playCvCharacterInfo.Id = characterId
                        playCvCharacterInfo.IsCaptain = true
                        break
                    end

                    table.insert(changeCharacter, characterId)
                end
            end

            -- 更改角色不是队长，但只更改了一个角色，播放该角色的入队语音
            if playCvCharacterInfo.Id == 0 and changeCount == 1 then
                playCvCharacterInfo.Id = changeCharacter[1]
            end

            XEventManager.DispatchEvent(XEventId.EVENT_TEAM_MEMBER_CHANGE, curTeamId, playCvCharacterInfo.Id, playCvCharacterInfo.IsCaptain)
        end
        playerTeamData[curTeamId].TeamId = curTeamId
        playerTeamData[curTeamId].CaptainPos = curTeam.CaptainPos
        playerTeamData[curTeamId].FirstFightPos = curTeam.FirstFightPos
        playerTeamData[curTeamId].TeamData = curTeam.TeamData
        playerTeamData[curTeamId].TeamName = curTeam.TeamName
        playerTeamData[curTeamId].SelectedGeneralSkill = curTeam.SelectedGeneralSkill
        playerTeamData[curTeamId].EnterCgIndex = curTeam.EnterCgIndex
        playerTeamData[curTeamId].SettleCgIndex = curTeam.SettleCgIndex
        if isPrefab then
            playerTeamData[curTeamId].PartnerPrefab = XDataCenter.TeamManager.GetPartnerPrefab(curTeamId)
        end
        if cb then cb() end

        XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_CHANGE, curTeamId, playerTeamData[curTeamId])
    end

    -- todo  特别优化
    --function XTeamManager.SetExpeditionTeamData(curTeam, cb)
    --    local curTeamId = curTeam.TeamId
    --    local params = {}
    --    params.TeamData = {}
    --    params.TeamId = curTeamId
    --    XMessagePack.MarkAsTable(params.TeamData)
    --    for k, v in pairs(curTeam.TeamData) do
    --        params.TeamData[k] = v
    --    end
    --    params.CaptainPos = curTeam.CaptainPos
    --    params.FirstFightPos = curTeam.FirstFightPos
    --    local req = { TeamData = params}
    --    XNetwork.Call(METHOD_NAME.SetTeam, req, function(res)
    --        if res.Code ~= XCode.Success then
    --            XUiManager.TipCode(res.Code)
    --            return
    --        end
    --        local characterCheckTable = {}
    --        local playerTeamData = PlayerTeamGroupData
    --        -- 更新客户端队伍缓存
    --        if playerTeamData[curTeamId] == nil then
    --            playerTeamData[curTeamId] = {}
    --        else
    --            for _, baseId in pairs(playerTeamData[curTeamId].TeamData) do
    --                characterCheckTable[baseId] = true
    --            end
    --
    --            for pos, baseId in pairs(curTeam.TeamData) do
    --                if not characterCheckTable[baseId] then
    --                    local charId = XExpeditionConfig.GetCharacterIdByBaseId(baseId)
    --                    XEventManager.DispatchEvent(XEventId.EVENT_TEAM_MEMBER_CHANGE, curTeamId, charId, pos == curTeam.CaptainPos)
    --                end
    --            end
    --        end
    --        playerTeamData[curTeamId].TeamId = curTeamId
    --        playerTeamData[curTeamId].CaptainPos = curTeam.CaptainPos
    --        playerTeamData[curTeamId].FirstFightPos = curTeam.FirstFightPos
    --        playerTeamData[curTeamId].TeamData = curTeam.TeamData
    --        playerTeamData[curTeamId].TeamName = curTeam.TeamName
    --
    --        if cb then cb() end
    --
    --        XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_CHANGE, curTeamId, playerTeamData[curTeamId])
    --    end)
    --end

    function XTeamManager.GetPlayerTeamData(teamId)
        return PlayerTeamGroupData[teamId] or false
    end

    function XTeamManager.GetTeamPrefabDataByIndex(index)
        return TeamPrefabList[index] or false
    end

    function XTeamManager.GetTeamPrefabDataByTeamId(teamId)
        for _, teamPrefab in ipairs(TeamPrefabList) do
            if teamPrefab:GetId() == teamId then
                return teamPrefab
            end
        end
    end

    function XTeamManager.GetTeamPrefabList()
        return TeamPrefabList
    end

    function XTeamManager.GetTeamData(teamId, noTips)
        local teamData = XTeamManager.GetXTeamEntityIds(teamId)
        if teamData then return teamData end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            if not noTips then
                XLog.Error("XTeamManager.GetTeamCaptainPos, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            end
            return
        end

        if PlayerTeamGroupData[teamId] ~= nil then
            teamData = PlayerTeamGroupData[teamId].TeamData
        end

        if teamData == nil or next(teamData) == nil then
            teamData = {}
            for i = 1, MaxPos do
                teamData[i] = 0
            end
        end
        return teamData
    end

    function XTeamManager.GetTeamCaptainPos(teamId)
        local captainPos = XTeamManager.GetXTeamCaptainPos(teamId)
        if captainPos then return captainPos end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamCaptainPos, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        captainPos = XTeamManager.GetCaptainPos()
        if PlayerTeamGroupData[teamId] ~= nil then
            captainPos = PlayerTeamGroupData[teamId].CaptainPos
        end
        return captainPos
    end

    ---==========================================
    --- 根据'teamId'得到当前的首发位置，中间是1，左边是2，右边是3
    --- 若第一次进入玩法，没有设置相应的'teamId‘数据，则初始位置为1
    ---@param teamId number
    ---@return number
    ---==========================================
    function XTeamManager.GetTeamFirstFightPos(teamId)
        local posId = XTeamManager.GetXTeamFirstFightPos(teamId)
        if posId then return posId end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamFirstFightPos, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        -- 初始位置为1
        posId = 1

        -- 是否设置过该teamId数据
        if PlayerTeamGroupData[teamId] ~= nil then
            posId = PlayerTeamGroupData[teamId].FirstFightPos
        end
        return posId
    end

    function XTeamManager.GetTeamEnterCgIndex(teamId)
        local index = XTeamManager.GetXTeamEnterCgIndex(teamId)
        if index then return index end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamFirstFightPos, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        -- 默认位置为0
        index = 0

        -- 是否设置过该teamId数据
        if PlayerTeamGroupData[teamId] ~= nil then
            index = PlayerTeamGroupData[teamId].EnterCgIndex
        end
        return index
    end

    function XTeamManager.GetTeamSettleCgIndex(teamId)
        local index = XTeamManager.GetXTeamSettleCgIndex(teamId)
        if index then return index end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamFirstFightPos, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        -- 默认位置为0
        index = 0

        -- 是否设置过该teamId数据
        if PlayerTeamGroupData[teamId] ~= nil then
            index = PlayerTeamGroupData[teamId].SettleCgIndex
        end
        return index
    end
    
    function XTeamManager.GetTeamSelectedGeneralSkill(teamId)
        local selectedGeneralSkill = XTeamManager.GetXTeamSelectGeneralSkill(teamId)
        if XTool.IsNumberValid(selectedGeneralSkill) then
            return selectedGeneralSkill
        end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamFirstFightPos, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        selectedGeneralSkill = 0
        -- 是否设置过该teamId数据
        if PlayerTeamGroupData[teamId] ~= nil then
            selectedGeneralSkill = PlayerTeamGroupData[teamId].SelectedGeneralSkill
        end
        return selectedGeneralSkill
    end

    function XTeamManager.GetTeamCaptainId(teamId)
        local xTeam = XTeamManager.GetXTeam(teamId)
        if xTeam then
            return xTeam:GetCaptainPosEntityId()
        end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamCaptainId, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        if PlayerTeamGroupData[teamId] == nil then
            return nil
        end

        local captainPos = PlayerTeamGroupData[teamId].CaptainPos
        return PlayerTeamGroupData[teamId].TeamData[captainPos]
    end

    ---==========================================
    --- 根据'teamId'得到当前的首发位的角色Id
    ---@param teamId number
    ---@return number
    ---==========================================
    function XTeamManager.GetTeamFirstFightId(teamId)
        local xTeam = XTeamManager.GetXTeam(teamId)
        if xTeam then
            return xTeam:GetFirstFightPosEntityId()
        end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamFirstFightId, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        if PlayerTeamGroupData[teamId] == nil then
            return nil
        end

        local firstFightPos = PlayerTeamGroupData[teamId].FirstFightPos
        return PlayerTeamGroupData[teamId].TeamData[firstFightPos]
    end

    -- 得到对应玩法的TeamId与Team数据
    -- stageId : 获取stageInfo后找到TeamType相匹配的TeamId
    function XTeamManager.GetPlayerTeam(typeId, stageId)
        local curTeamId = XTeamManager.GetTeamId(typeId, stageId)
        if curTeamId == nil then
            XLog.ErrorTableDataNotFound("XTeamManager.GetPlayerTeam", "curTeamId",
            TABLE_PATH, "typeId ：   stageId ：", tostring(typeId) .. tostring(stageId))
            return nil
        end

        local CurTeam = {
            ["TeamId"] = curTeamId,
            ["TeamData"] = XTeamManager.GetTeamData(curTeamId),
            ["CaptainPos"] = XTeamManager.GetTeamCaptainPos(curTeamId),
            ["FirstFightPos"] = XTeamManager.GetTeamFirstFightPos(curTeamId),
            ["SelectedGeneralSkill"] = XTeamManager.GetTeamSelectedGeneralSkill(curTeamId),
            ["EnterCgIndex"] = XTeamManager.GetTeamEnterCgIndex(curTeamId),
            ["SettleCgIndex"] = XTeamManager.GetTeamSettleCgIndex(curTeamId),
        }
        return CurTeam
    end

    function XTeamManager.CheckInTeam(characterId)
        local typeId = CS.XGame.Config:GetInt("TypeIdMainLine")
        local curTeamId = XTeamManager.GetTeamId(typeId)
        if curTeamId == nil then
            XLog.ErrorTableDataNotFound("XTeamManager.CheckInTeam", "curTeamId", TABLE_PATH, "typeId ：   stageId ：", tostring(typeId))
            return nil
        end

        local teamData = XTeamManager.GetTeamData(curTeamId)
        for _, v in pairs(teamData) do
            if characterId == v then
                return true
            end
        end
        return false
    end

    function XTeamManager.GetInTeamCheckTable()
        local inTeamCheckTable = {}

        local typeId = CS.XGame.Config:GetInt("TypeIdMainLine")
        local curTeamId = XTeamManager.GetTeamId(typeId)
        local teamData = XTeamManager.GetTeamData(curTeamId)
        for _, v in pairs(teamData) do
            if v > 0 then
                inTeamCheckTable[v] = true
            end
        end

        return inTeamCheckTable
    end

    -- 在NotifyLogin中获取队伍数据
    function XTeamManager.InitTeamGroupData(teamGroupData)
        if teamGroupData == nil then
            return
        end

        for key, value in pairs(teamGroupData) do
            local teamTemp = {}
            for teamDataKey, teamDataValue in pairs(value.TeamData) do
                teamTemp[teamDataKey] = teamDataValue
            end

            PlayerTeamGroupData[key] = {}
            PlayerTeamGroupData[key].TeamId = value.TeamId
            PlayerTeamGroupData[key].CaptainPos = value.CaptainPos
            PlayerTeamGroupData[key].FirstFightPos = value.FirstFightPos
            PlayerTeamGroupData[key].TeamData = teamTemp
            PlayerTeamGroupData[key].SelectedGeneralSkill = value.SelectedGeneralSkill
            PlayerTeamGroupData[key].EnterCgIndex = value.EnterCgIndex
            PlayerTeamGroupData[key].SettleCgIndex = value.SettleCgIndex
        end
    end

    function XTeamManager.RefreshEquipIdAndPartnerIdToPrefabTeamDic()
        -- 每次刷新前清空缓存
        for k, v in pairs(EquipIdToPrefabTeamDic) do
            EquipIdToPrefabTeamDic[k] = nil
        end

        for k, v in pairs(PartnerIdToPrefabTeamDic) do
            PartnerIdToPrefabTeamDic[k] = nil
        end

        for i, v in ipairs(TeamPrefabList) do
            local teamPrefab = v
            for pos = 1, MaxPos do
                -- 武器
                local weapon = teamPrefab:GetWeaponData(pos)
                if weapon and XTool.IsNumberValid(weapon.EquipId) then
                    local charId = teamPrefab:GetEntityIdByTeamPos(pos)
                    EquipIdToPrefabTeamDic[weapon.EquipId] = EquipIdToPrefabTeamDic[weapon.EquipId] or {}
                    EquipIdToPrefabTeamDic[weapon.EquipId][charId] = EquipIdToPrefabTeamDic[weapon.EquipId][charId] or {}
                    EquipIdToPrefabTeamDic[weapon.EquipId][charId][teamPrefab:GetId()] = true
                end
                
                -- 意识
                local awarenessList = teamPrefab:GetAllAwarenessData(pos)
                if awarenessList then
                    for _, v in pairs(awarenessList) do
                        if XTool.IsNumberValid(v.EquipId) then
                            local charId = teamPrefab:GetEntityIdByTeamPos(pos)
                            EquipIdToPrefabTeamDic[v.EquipId] = EquipIdToPrefabTeamDic[v.EquipId] or {}
                            EquipIdToPrefabTeamDic[v.EquipId][charId] = EquipIdToPrefabTeamDic[v.EquipId][charId] or {}
                            EquipIdToPrefabTeamDic[v.EquipId][charId][teamPrefab:GetId()] = true
                        end
                    end
                end

                -- 辅助机
                local partnerData = teamPrefab:GetPartnerData()
                local partnerId = partnerData:GetPartnerIdByPos(pos)
                if XTool.IsNumberValid(partnerId) then
                    PartnerIdToPrefabTeamDic[partnerId] = true
                end
            end
        end
    end

    -- 在NotifyLogin中获取预编译队伍
    function XTeamManager.InitTeamPrefabData(teamPrefabData)
        if teamPrefabData == nil then
            return
        end

        TeamPrefabList = {}
        EquipIdToPrefabTeamDic = {} -- 初始化清空缓存
        PartnerIdToPrefabTeamDic = {}
        for key, value in ipairs(teamPrefabData) do
            -- 新队伍预设
            local prefab = XTeamPrefab.New(value)
            table.insert(TeamPrefabList, prefab)

            local teamTemp = {}
            for teamDataKey, teamDataValue in pairs(value.TeamData) do
                teamTemp[teamDataKey] = teamDataValue
            end
            local partnerPrefab = XPartnerPrefab.New(key, value.PartnerData)
            
            PlayerTeamPrefabData[key] = {}
            PlayerTeamPrefabData[key].TeamId = value.TeamId
            PlayerTeamPrefabData[key].CaptainPos = value.CaptainPos
            PlayerTeamPrefabData[key].FirstFightPos = value.FirstFightPos
            PlayerTeamPrefabData[key].TeamData = teamTemp
            PlayerTeamPrefabData[key].TeamName = value.TeamName
            PlayerTeamPrefabData[key].PartnerPrefab = partnerPrefab
            PlayerTeamPrefabData[key].SelectedGeneralSkill = value.SelectedGeneralSkill
            PlayerTeamPrefabData[key].EnterCgIndex = value.EnterCgIndex
            PlayerTeamPrefabData[key].SettleCgIndex = value.SettleCgIndex
        end

        XTeamManager.RefreshEquipIdAndPartnerIdToPrefabTeamDic()
    end
    
    --==============================
     ---@desc 获取辅助机预设
     ---@teamId teamId
     ---@return XPartnerPrefab
    --==============================
    function XTeamManager.GetPartnerPrefab(teamId)
        local teamData = PlayerTeamPrefabData[teamId]
        if not teamData then
            local maxPos = XTeamManager.GetMaxPos()
            teamData = {}
            teamData.TeamId = teamId
            teamData.CaptainPos = XTeamManager.GetCaptainPos()
            teamData.FirstFightPos = XTeamManager.GetFirstFightPos()
            teamData.TeamName = CS.XTextManager.GetText("TeamPrefabDefaultName", teamId)
            teamData.TeamData = {}
            for idx = 1, maxPos do
                teamData.TeamData[idx] = 0 
            end
            PlayerTeamPrefabData[teamId] = teamData
        end
        
        local partnerPrefab = teamData.PartnerPrefab
        if not partnerPrefab then
            partnerPrefab = XPartnerPrefab.New(teamId)
            PlayerTeamPrefabData[teamId].PartnerPrefab = partnerPrefab
        end
        
        return partnerPrefab
    end

    function XTeamManager.CheckEquipIdIsInTeamPrefab(equipId)
        local data = EquipIdToPrefabTeamDic[equipId]
        return not XTool.IsTableEmpty(data)
    end

    function XTeamManager.CheckEquipIdCharIdIsInTeamPrefab(equipId, charId)
        if not EquipIdToPrefabTeamDic[equipId] then
            return false
        end
        local data = EquipIdToPrefabTeamDic[equipId][charId]
        return not XTool.IsTableEmpty(data)
    end

    function XTeamManager.CheckEquipIdCharIdTeamIdIsInTeamPrefab(equipId, charId, teamId)
        if not EquipIdToPrefabTeamDic[equipId] then
            return false
        end

        if not EquipIdToPrefabTeamDic[equipId][charId] then
            return false
        end

        local data = EquipIdToPrefabTeamDic[equipId][charId][teamId]
        return data ~= nil
    end


    function XTeamManager.CheckPartnerIdIsInTeamPrefab(partnerId)
        return PartnerIdToPrefabTeamDic[partnerId] ~= nil
    end

    function XTeamManager.GetCaptainPos()
        return CaptainPos
    end

    function XTeamManager.GetFirstFightPos()
        return FirstFightPos
    end

    function XTeamManager.GetMaxPos()
        return MaxPos
    end

    function XTeamManager.GetTeamMemberColor(id)
        local colorStr = XTeamConfig.GetTeamCfgById(id).Color
        local color = XUiHelper.Hexcolor2Color(colorStr)
        return color
    end

    function XTeamManager.GetTeamMemberSelectColor(id)
        local colorStr = XTeamConfig.GetTeamCfgById(id).SelectColor
        local color = XUiHelper.Hexcolor2Color(colorStr)
        return color
    end

    function XTeamManager.GetTeamMemberDiagonalColor(id)
        local colorStr = XTeamConfig.GetTeamCfgById(id).DiagonalColor
        local color = XUiHelper.Hexcolor2Color(colorStr)
        return color
    end

    function XTeamManager.GetTeamMemberEffectPath(id)
        local effectPath = XTeamConfig.GetTeamCfgById(id).EffectPath
        return effectPath
    end

    function XTeamManager.GetTeamPrefabData()
        return PlayerTeamPrefabData
    end

    function XTeamManager.ResetTeamData(teamId)
        local teamInfos = XTeamManager.GetPlayerTeamData(teamId)
        if not teamInfos then return end
        teamInfos.CaptainPos = 1
        for index in pairs(teamInfos.TeamData) do
            teamInfos.TeamData[index] = 0
        end
    end

    --######################## 新队伍逻辑代码 ########################
    ---@return XTeam
    function XTeamManager.GetMainLineTeam()
        return XTeamManager.GetXTeamByTypeId(CS.XGame.Config:GetInt("TypeIdMainLine"))
    end

    ---@return XTeam
    function XTeamManager.GetXTeamByTypeId(typeId)
        local teamData = XTeamManager.GetPlayerTeam(typeId)
        local result = TeamDic[teamData.TeamId]
        if result == nil then
            result = XTeam.New(teamData.TeamId)
            result:UpdateSaveCallback(function(inTeam)
                XTeamManager.RequestSaveTeam(inTeam)
            end)
            TeamDic[teamData.TeamId] = result
        end
        result:UpdateFromTeamData(teamData)
        return result
    end

    ---@return XTeam
    function XTeamManager.GetXTeamByStageId(stageId)
        --- GetTeamKey接口获取的TeamId和XTeam内部自动保存时用的Id不一致（详见XTeam内GetSaveKey接口）
        --- 如果没有配套使用SaveTeamLocal接口，teamData将始终为空
        local teamData = XTeamManager.LoadTeamLocal(stageId)
        local teamId = GetTeamKey(stageId)
        local result = TeamDic[teamId]
        if result == nil then
            -- 如果Xteam此前执行了内部变更保存，构造函数执行期间将正常加载本地缓存的队伍数据（详见XTeam内LoadTeamData接口)
            result = XTeam.New(teamId)
            -- 此处teamData数据覆盖，teamData始终为空时，无论XTeam内部缓存结果，最终始终读取空队伍
            result:UpdateFromTeamData(teamData)
            TeamDic[teamId] = result
        end
        return result
    end

    function XTeamManager.GetXTeamSpeedrun(stageId)
        local groupId = XMVCA.XPlotExhibition:GetSpeedrunStageGroupId(stageId)
        local teamId = string.format("%s%s_%s", TeamDataKey, tostring(XPlayer.Id), groupId)
        ---@type XTeam
        local result = TeamDic[teamId]
        if result == nil then
            result = XTeam.New(teamId)
            result:UpdateAutoSave(true)
            TeamDic[teamId] = result
        end
        return result
    end
    
    --- 该接口获取的XTeam启用内部变更自动保存，无需外部手动调用保存接口
    function XTeamManager.GetXTeamByStageIdEx(stageId)
        local teamId = GetTeamKey(stageId)
        ---@type XTeam
        local result = TeamDic[teamId]
        if result == nil then
            result = XTeam.New(teamId)
            result:UpdateAutoSave(true)
            TeamDic[teamId] = result
        end
        return result
    end

    --根据teamID从内存获取XTeam
    ---@return XTeam
    function XTeamManager.GetXTeam(teamId)
        return TeamDic[teamId]
    end

    --把XTeam根据其TeamID存到内存
    ---@param xTeam
    function XTeamManager.SetXTeam(xTeam)
        TeamDic[xTeam:GetId()] = xTeam
    end

    --把XTeam从内存引用中移除
    ---@param xTeam
    function XTeamManager.RemoveXTeam(xTeam)
        TeamDic[xTeam:GetId()] = nil
    end

    function XTeamManager.GetXTeamEntityIds(teamId)
        -- 截断旧队伍逻辑处理
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            return team:GetEntityIds()
        end
        local tempTeam = XTeamManager.GetTempTeam(teamId)
        if tempTeam then
            return tempTeam:GetEntityIds()
        end
        return nil
    end

    function XTeamManager.GetXTeamCaptainPos(teamId)
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            return team:GetCaptainPos()
        end
        return nil
    end

    function XTeamManager.GetXTeamFirstFightPos(teamId)
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            return team:GetFirstFightPos()
        end
        return nil
    end

    function XTeamManager.GetXTeamEnterCgIndex(teamId)
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            return team:GetEnterCgIndex()
        end
        return nil
    end

    function XTeamManager.GetXTeamSettleCgIndex(teamId)
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            return team:GetSettleCgIndex()
        end
        return nil
    end

    function XTeamManager.GetXTeamSelectGeneralSkill(teamId)
        ---@type XTeam
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            return team:GetCurGeneralSkill()
        end
        return 0
    end

    function XTeamManager.SaveXTeam(teamId)
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            team:ManualSave()
        end
    end
    
    local _TempTeam

    -- 创建临时使用的队伍实体
    function XTeamManager.CreateTempTeam(entityIds)
        local result = XTeam.New(XTime.GetServerNowTimestamp())
        result:UpdateAutoSave(false)
        result:UpdateEntityIds(entityIds)
        _TempTeam = result
        return result
    end

    function XTeamManager.ClearTempTeam()
        _TempTeam = nil
    end
    
    function XTeamManager.GetTempTeam(teamId)
        if _TempTeam and _TempTeam.Id == teamId then
            return _TempTeam
        end
    end
    
    function XTeamManager.GetTempTeamForce()
        return _TempTeam
    end

    function XTeamManager.CreateTeam(teamId)
        local result = XTeam.New(teamId)
        result:UpdateLocalSave(false)
        return result
    end
    
    function XTeamManager.GetXTeamWithPrefab(teamId)
        local result
        for _, teamData in pairs(PlayerTeamPrefabData) do
            if teamData.TeamId == teamId then
                result = XTeam.New(XTime.GetServerNowTimestamp())
                result:UpdateAutoSave(false)
                result:UpdateFromTeamData(teamData)
                return result
            end
        end
        return result
    end

    ---@param team XTeam
    function XTeamManager.RequestSaveTeam(team)
        local entityIds = {}
        XMessagePack.MarkAsTable(entityIds)
        for i, v in ipairs(team:GetEntityIds()) do
            entityIds[i] = v
        end
        local requestBody = {
            TeamData = {
                TeamData = entityIds,
                TeamId = team:GetId(),
                CaptainPos = team:GetCaptainPos(),
                FirstFightPos = team:GetFirstFightPos(),
                TeamName = team:GetName(),
                SelectedGeneralSkill = team:GetIsEmpty() and 0 or team:GetCurGeneralSkill(),
                EnterCgIndex = team:GetEnterCgIndex(),
                SettleCgIndex = team:GetSettleCgIndex(),
            }
        }
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.SetTeam, requestBody)
    end

    --- 根据传入的限定可选角色，对上阵队伍进行筛选剔除掉无效实体(提供通用接口用于支持那些非XTeam类型管理的队伍）
    ---@param entityIds @队伍上阵实体的id列表（自机id或机器人id。按通用标准，无角色位填充0）
    ---@param limitEntityIds @限定的可选实体id列表
    ---@param captainPos @队伍的队长位，不填则不判断队长变更的情况
    ---@return any @是否实体有变化, 是否队长位变更，过滤后的实体表
    function XTeamManager.GetValidEntitiesByLimitEntityIds(entityIds, limitEntityIds, captainPos)
        if not XTool.IsTableEmpty(entityIds) and not XTool.IsTableEmpty(limitEntityIds) then
            if not XTool.IsNumberValid(captainPos) or captainPos > 3 then
                captainPos = 0
            end
            
            local needChangeCaptainPos = false
            local entityChanged = false
            -- 剔除不在可选角色列表中的id
            for i = 1, #entityIds do
                if XTool.IsNumberValid(entityIds[i]) and not table.contains(limitEntityIds, entityIds[i]) then
                    entityIds[i] = 0
                    entityChanged = true
                    if captainPos == i then
                        needChangeCaptainPos = true
                    end
                end
            end
            
            return entityChanged, needChangeCaptainPos, entityIds
        end
        
        return false, false, nil
    end

    --- 根据传入的实体Id列表, 按照既定规则返回一个默认效应技能id(提供通用接口用于支持那些不会转换到XTeam处理的情况）
    --- 需注意本接口仅一次性查找、不能用于查其他玩家角色的数据，不会收集和处理可选技能，无法用于“效应选择”功能
    ---@param entityIds @队伍上阵实体的id列表（自机id或机器人id。按通用标准，无角色位填充0）
    ---@param lastGeneralSkillId @该队伍变更前所选择的效应技能Id, 缺省时为0
    ---@return number @新选择的效应技能Id
    function XTeamManager.GetTeamDefaultGeneralSkillId(entityIds, lastGeneralSkillId)
        if XTool.IsTableEmpty(entityIds) then
            return 0
        end

        if lastGeneralSkillId == nil then
            lastGeneralSkillId = 0
        end
        
        -- 判断新队伍产生的可选技能是否包含旧选择的技能
        local containsLastGeneralSkillId = false
        -- 优先选人数多的，其次选id小的
        -- 根据以下编码，值最大的即为选择的generalSkillId
        local generalSkillMap = {} -- <key: id, value: 100000 + characterCount*1000 + (999 - id) >

        for i, entityId in pairs(entityIds) do
            -- 获取角色已激活的效应技能列表（自机和机器人）
            local skillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(entityId)
            if not XTool.IsTableEmpty(skillIds) then
                for i, skillId in pairs(skillIds) do
                    if generalSkillMap[skillId] == nil then
                        generalSkillMap[skillId] = 100000 + 999 - skillId
                    end

                    generalSkillMap[skillId] = generalSkillMap[skillId] + 1000

                    if skillId == lastGeneralSkillId then
                        containsLastGeneralSkillId = true
                    end
                end
            end
        end

        -- 如果新队伍可选的效应技能包括旧选择的，那么仍使用旧的
        if containsLastGeneralSkillId then
            return lastGeneralSkillId
        end

        -- 按照规则选择新效应技能
        if not XTool.IsTableEmpty(generalSkillMap) then
            local maxKey = 1
            local maxValue = 0

            for i, v in pairs(generalSkillMap) do
                if v > maxValue then
                    maxKey = i
                    maxValue = v
                end
            end

            return maxKey
        end

        return 0
    end

    function XTeamManager.SetBattleRoomCacheTeam(xTeam)
        if not xTeam then
            return
        end
        BattleRoomCacheTeam = xTeam
    end

    function XTeamManager.ClearBattleRoomCacheTeam()
        BattleRoomCacheTeam = nil
    end

    function XTeamManager.GetBattleRoomCacheTeam()
        return BattleRoomCacheTeam
    end

    -- 涂装回退位下标是否为空：无表或全 0（没有任何位需要回退）时返回 true
    function XTeamManager.IsNoFashionResPositionsEmpty(positions)
        if not positions then
            return true
        end
        for _, v in ipairs(positions) do
            if v ~= 0 then
                return false
            end
        end
        return true
    end

    XTeamManager.Init()
    return XTeamManager
end

XRpc.NotifyTeamClear = function(data)
    XDataCenter.TeamManager.ResetTeamData(data.TeamId)
end