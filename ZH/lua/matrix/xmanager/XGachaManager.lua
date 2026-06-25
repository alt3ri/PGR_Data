XGachaManagerCreator = function()
    local GET_GACHA_DATA_INTERVAL = 15
    ---@class XGachaManager
    local XGachaManager = {}
    local ParseToTimestamp = XTime.ParseToTimestamp 

    -- 以下数据都要通过gachaId查找，因为可能同时开多个卡池 
    local LastGetGachaRewardInfoTimes = {}
    local GachaProbShows = {}
    local GachaLogList = {}
    local GachaRewardInfos = {}
    local IsInfinite = {}
    local CurCountOfAll = {}
    local MaxCountOfAll = {}
    local CurExchangeItemCount = {} -- 当前购买过的gacha币数量
    local TotalGachaTimes = {}
    local MissTimes = {} -- 保底次数
    local CurGachaFashionSelfChoiceActivityId = nil
    local CurGroupSelectMap = {}  -- GroupId -> SelectedGachaId
    --

    -- 卡池组状态
    -- Key:number OrganizeId
    -- Value:Table { gachaId = XGachaConfigs.OrganizeGachaStatus }
    local GachaOrganizeStatus = {}

    local METHOD_NAME = {
        GetGachaInfo = "GetGachaInfoRequest",
        Gacha = "GachaRequest",
        GetGachaOrganizeInfo = "GetGachaOrganizeInfoRequest",
        GachaItemExchangeRequest = "GachaItemExchangeRequest",
    }

    function XGachaManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, function ()
            XGachaManager.InitConfig()
        end)
    end
    
    -- 懒加载并返回 gachaId 的奖励 entry map
    -- 所有读取入口都应通过本接口获取，避免遗漏懒加载守卫
    local function GetGachaRewardMap(gachaId)
        if not GachaRewardInfos[gachaId] then
            XGachaManager.SetGachaRewardInfo(gachaId)
        end
        return GachaRewardInfos[gachaId]
    end

    function XGachaManager.InitConfig()
        -- 只初始化标量字段；entry map (GachaRewardInfos) 改为懒加载，详见 GetGachaRewardMap
        local gachaCfg = XGachaConfigs.GetGachas()
        for k, v in pairs(gachaCfg) do
            IsInfinite[k] = false
            CurCountOfAll[k] = 0
            MaxCountOfAll[k] = 0
            CurExchangeItemCount[k] = 0
            TotalGachaTimes[k] = 0
            MissTimes[k] = 0
        end
    end

    function XGachaManager.GetCurSelfChoiceSelectGachId(groupId)
        return CurGroupSelectMap[groupId]
    end

    function XGachaManager.GetCurGachaFashionSelfChoiceActivityId()
        return CurGachaFashionSelfChoiceActivityId
    end

    ---@return XTableGachaFashionSelfChoiceActivity
    function XGachaManager.GetCurGachaFashionSelfChoiceActivityConfig()
        local config = XGachaConfigs.GetAllConfigs(XGachaConfigs.TableKey.GachaFashionSelfChoiceActivity)
        return config[CurGachaFashionSelfChoiceActivityId]
    end

    -- gachaId -> GroupId 反查缓存（延迟构建）
    local GachaIdToGroupIdCache = nil

    -- 通过gachaId反查所属GroupId（gachaId跨Group唯一，使用缓存避免频繁遍历）
    function XGachaManager.GetGroupIdByGachaId(gachaId)
        if not GachaIdToGroupIdCache then
            GachaIdToGroupIdCache = {}
            local groupConfigs = XGachaConfigs.GetAllConfigs(XGachaConfigs.TableKey.GachaFashionSelfChoiceGroup)
            for groupId, config in pairs(groupConfigs) do
                for _, id in pairs(config.GachaIds) do
                    if XTool.IsNumberValid(id) then
                        GachaIdToGroupIdCache[id] = groupId
                    end
                end
            end
        end
        return GachaIdToGroupIdCache[gachaId]
    end

    -- 获取Group配置
    function XGachaManager.GetGroupConfig(groupId)
        local config = XGachaConfigs.GetAllConfigs(XGachaConfigs.TableKey.GachaFashionSelfChoiceGroup)[groupId]
        if not config then
            XLog.Error("GetGroupConfig: groupId not found: " .. tostring(groupId))
        end
        return config
    end

    -- 检查指定gachaId是否被任一Group选中
    function XGachaManager.IsGachaIdSelected(gachaId)
        for _, selectedId in pairs(CurGroupSelectMap) do
            if selectedId == gachaId then
                return true
            end
        end
        return false
    end

    -- 检查当前活动是否有任一（时间有效的）Group未选择
    function XGachaManager.HasUnselectedGroup()
        local activityConfig = XGachaManager.GetCurGachaFashionSelfChoiceActivityConfig()
        if not activityConfig then return false end
        for _, groupId in pairs(activityConfig.GachaGroupIds) do
            if XTool.IsNumberValid(groupId) then
                local groupConfig = XGachaManager.GetGroupConfig(groupId)
                -- 只检查时间有效的Group，过期Group不算"未选择"
                if groupConfig and XFunctionManager.CheckInTimeByTimeId(groupConfig.TimeId)
                        and not XTool.IsNumberValid(CurGroupSelectMap[groupId]) then
                    return true
                end
            end
        end
        return false
    end

    -- 检查当前活动是否所有（时间有效的）Group都已选择
    function XGachaManager.IsAllGroupsSelected()
        local activityConfig = XGachaManager.GetCurGachaFashionSelfChoiceActivityConfig()
        if not activityConfig then return false end
        for _, groupId in pairs(activityConfig.GachaGroupIds) do
            if XTool.IsNumberValid(groupId) then
                local groupConfig = XGachaManager.GetGroupConfig(groupId)
                -- 只检查时间有效的Group
                if groupConfig and XFunctionManager.CheckInTimeByTimeId(groupConfig.TimeId)
                        and not XTool.IsNumberValid(CurGroupSelectMap[groupId]) then
                    return false
                end
            end
        end
        return true
    end

    function XGachaManager.GetMissTimes(gachaId)
        return MissTimes[gachaId] or 0
    end

    function XGachaManager.GetCurExchangeItemCount(gachaId)
        return CurExchangeItemCount[gachaId] or 0
    end

    function XGachaManager.GetTotalGachaTimes(gachaId)
        return TotalGachaTimes[gachaId] or 0
    end

    function XGachaManager.GetGachaRewardInfoById(gaChaId)
        local gachaCfg = XGachaConfigs.GetGachas()
        MaxCountOfAll[gaChaId] = 0
        CurCountOfAll[gaChaId] = 0
        IsInfinite[gaChaId] = false
    
        local groupIdList = {}
        for _, groupId in pairs(gachaCfg[gaChaId].GroupId) do
            table.insert(groupIdList, groupId)
        end
    
        local list = {}
        local rewardMap = GetGachaRewardMap(gaChaId) or {}
        for id, entry in pairs(rewardMap) do
            if entry and entry.Cfg then
                for _, groupId in pairs(groupIdList) do
                    if entry.Cfg.GroupId == groupId then
                        table.insert(list, entry)
                        break
                    end
                end
            end
        end
    
        for _, entry in pairs(list) do
            if entry.Cfg.RewardType == XGachaConfigs.RewardType.NotCount then
                IsInfinite[gaChaId] = true
            end
            local usable = entry.Cfg.UsableTimes or 0
            MaxCountOfAll[gaChaId] = MaxCountOfAll[gaChaId] + usable
            CurCountOfAll[gaChaId] = CurCountOfAll[gaChaId] + (usable - (entry.CurCount or 0))
        end
    
        table.sort(list, function(a, b)
            local ap = a.Cfg.Priority or 0
            local bp = b.Cfg.Priority or 0
            if ap == bp then
                return (a.Cfg.Id or 0) < (b.Cfg.Id or 0)
            else
                return ap > bp
            end
        end)
        return list
    end

    function XGachaManager.IsClearMinimumGuarantee(gaChaId)
        local gachaCfg = XGachaConfigs.GetGachaCfgById(gaChaId)
        local data = XGachaManager.GetGachaRewardInfoById(gaChaId)
        local isAllClear = true
        for k, v in pairs(data) do
            if v.CurCount > 0 and v.Cfg.GroupId == gachaCfg.PropAddGroupId then
                isAllClear = false
            end
        end

        return isAllClear
    end
    -- 1核心层，2第一层、、、
    function XGachaManager.GetGachaRewardSplitByRareLevel(gaChaId)
        local list = XGachaManager.GetGachaRewardInfoById(gaChaId)
        local res = {}
        for _, v in pairs(list) do
            if XTool.IsNumberValid(v.Cfg.Rarelevel) then
                if not res[v.Cfg.Rarelevel] then
                    res[v.Cfg.Rarelevel] = {}
                end
                table.insert(res[v.Cfg.Rarelevel], v)
            end
        end
        return res
    end
    
    --- 根据是否是特殊奖励来区分
    function XGachaManager.GetGachaRewardSplitByRareType(gaChaId)
        local list = XGachaManager.GetGachaRewardInfoById(gaChaId)
        local res = {}
        for _, v in pairs(list) do
            local layer = v.Cfg.Rare and 1 or 2
            if not res[layer] then
                res[layer] = {}
            end
            table.insert(res[layer], v)
        end
        return res
    end
    
    function XGachaManager.GetGachaProbShowById(gaChaId)
        if GachaProbShows[gaChaId] then
            return GachaProbShows[gaChaId]
        end

        ---@type XTableGachaProbShow
        local gachaProbShowCfg = XGachaConfigs.GetGachaProbShows()[gaChaId]
        local res = {}
        for i = 1, #gachaProbShowCfg.Name, 1 do
            local probShowList = string.Split(gachaProbShowCfg.ProbShowList[i], '|')
            local config = {GachaId = gaChaId, IsRare = gachaProbShowCfg.IsRare[i], TemplateId = gachaProbShowCfg.TemplateId[i] or 0, Name = gachaProbShowCfg.Name[i], Type = gachaProbShowCfg.Type[i], ProbShow = probShowList}
            table.insert(res, config)
        end
        GachaProbShows[gaChaId] = res
        return res
    end

    function XGachaManager.GetCurCountOfAll(gachaId)
        return CurCountOfAll[gachaId] or 0
    end

    function XGachaManager.GetMaxCountOfAll(gachaId)
        return MaxCountOfAll[gachaId] or 0
    end
    
    function XGachaManager.GetIsInfinite(gachaId)
        return IsInfinite[gachaId] or false
    end

    function XGachaManager.GetGachaLogById(gachaId)
        return GachaLogList[gachaId] or {}
    end

    ---
    ---@param notCheckDraw boolean 是否检测活动研发功能开启，true:不检测，false:检测
    function XGachaManager.CheckGachaIsOpenById(id, IsShowText, notCheckDraw)
        if IsShowText then
            if not notCheckDraw and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ActivityDrawCard) then
                return false
            end
        else
            if not notCheckDraw and not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ActivityDrawCard) then
                return false
            end
        end

        local gachaCfg = XGachaConfigs.GetGachas()
        
        if not gachaCfg[id] then
            XLog.Error("GachaId Is Not Exist :"..id)
           return false
        end
        
        local timeId = gachaCfg[id].TimeId
        local IsInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
        if IsShowText and not IsInTime then
            local str = CS.XTextManager.GetText("GachaIsClose")
            XUiManager.TipMsg(str)
        end
        -- if IsShowText and IsClose then
        --     XUiManager.TipText("GachaIsClose")
        -- end
        return IsInTime
    end

    --- 检查gacha卡池是否过期
    ---@param notCheckDraw boolean 是否检测活动研发功能开启，true:不检测，false:检测
    function XGachaManager.CheckGachaIsOutTimeById(id, notCheckDraw)
        if not notCheckDraw and not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ActivityDrawCard) then
            return false
        end

        local gachaCfg = XGachaConfigs.GetGachas()

        if not gachaCfg[id] then
            XLog.Error("GachaId Is Not Exist :"..id)
            return false
        end

        local timeId = gachaCfg[id].TimeId

        if XTool.IsNumberValid(timeId) then
            local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)

            if XTool.IsNumberValid(endTime) then
                local now = XTime.GetServerNowTimestamp()
                return now >= endTime
            else
                -- 时间没配结束时间，则默认不过期
                return false
            end
        end
        -- 没配时间则默认过期
        return true
    end 

    ---
    --- 检测扭蛋组是否开启
    function XGachaManager.CheckGachaOrganizeIsOpen(organizeId, isShowText)
        local startTimeStr, endTimeStr = XGachaConfigs.GetOrganizeTime(organizeId)
        if not startTimeStr or not endTimeStr then
            return false
        end

        local nowTime = XTime.GetServerNowTimestamp()
        local startTime = ParseToTimestamp(startTimeStr)
        local endTime = ParseToTimestamp(endTimeStr)

        local IsNotOpen = startTime > nowTime
        if isShowText and IsNotOpen then
            local str = CS.XTextManager.GetText("GachaIsNotOpen", startTimeStr, endTimeStr)
            XUiManager.TipMsg(str)
        end

        local IsClose = nowTime > endTime
        if isShowText and IsClose then
            XUiManager.TipText("GachaIsClose")
        end

        return (not IsClose) and (not IsNotOpen)
    end

    function XGachaManager.UpdateGachaRewardInfo(gridInfoList, gachaId)
        local gachaMap = GetGachaRewardMap(gachaId)
        for _, v in pairs(gridInfoList or {}) do
            if gachaMap and gachaMap[v.Id] then
                local entry = gachaMap[v.Id]
                local usable = (entry.Cfg and entry.Cfg.UsableTimes) or 0
                entry.CurCount = usable - (v.Times or 0)
            else
                -- 如果找不到 entry，写个错误日志便于排查，但不要频繁 allocate
                XLog.Error(string.format("UpdateGachaRewardInfo 找不到 GachaId=%s RewardId=%s", tostring(gachaId), tostring(v.Id)))
            end
        end
    end
    
    function XGachaManager.UpdateGachaLog(gachaId, logList)
        GachaLogList = GachaLogList or {}
        GachaLogList[gachaId] = logList
    end

    --- 这个数据虽然初始化是静态读表 但是每次登录后会根据服务器下发的数据修改其封装的缓存内容（如剩余抽卡次数）
    --- 仅缓存属于该卡池 GroupId 集合内的奖励，避免 49 个卡池各持一份全量 GachaReward 表造成的内存膨胀
    function XGachaManager.SetGachaRewardInfo(gachaId)
        local gachaCfg = XGachaConfigs.GetGachas()
        local cfg = gachaCfg and gachaCfg[gachaId]
        if not cfg then
            XLog.Error("SetGachaRewardInfo gachaId 配置不存在: " .. tostring(gachaId))
            return
        end

        -- 构建该卡池的 GroupId 集合，O(1) 查询
        local groupIdSet = {}
        for _, groupId in pairs(cfg.GroupId or {}) do
            groupIdSet[groupId] = true
        end

        local gachaRewardCfg = XGachaConfigs.GetGachaReward()
        local tempGachaInfo = GachaRewardInfos[gachaId]
        if not tempGachaInfo then
            tempGachaInfo = {}
            GachaRewardInfos[gachaId] = tempGachaInfo
        end

        -- 仅写入属于本卡池 GroupId 的奖励；非命中行清掉，防止配置热更后残留
        for id, reward in pairs(gachaRewardCfg) do
            if groupIdSet[reward.GroupId] then
                local entry = tempGachaInfo[id]
                if not entry then
                    entry = { Cfg = reward, CurCount = reward.UsableTimes or 0 }
                    tempGachaInfo[id] = entry
                else
                    -- 就地更新引用与初始 CurCount（保留表，避免分配新表）
                    entry.Cfg = reward
                    entry.CurCount = reward.UsableTimes or 0
                end
            elseif tempGachaInfo[id] then
                tempGachaInfo[id] = nil
            end
        end
    end
    
    function XGachaManager.GetGachaRewardInfoRequest(gaChaId, cb)
        local now = XTime.GetServerNowTimestamp()
        if LastGetGachaRewardInfoTimes[gaChaId] and now - LastGetGachaRewardInfoTimes[gaChaId] <= GET_GACHA_DATA_INTERVAL then
            cb()
            return
        end
        XNetwork.Call(METHOD_NAME.GetGachaInfo, { Id = gaChaId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XGachaManager.UpdateGachaRewardInfo(res.GridInfoList, gaChaId)
            XGachaManager.UpdateGachaLog(gaChaId, res.GachaRecordList)
            LastGetGachaRewardInfoTimes[gaChaId] = XTime.GetServerNowTimestamp()
            CurExchangeItemCount[gaChaId] = res.CurExchangeItemCount
            TotalGachaTimes[gaChaId] = res.TotalTimes
            MissTimes[gaChaId] = res.MissTimes
            cb(res)
        end)
    end

    function XGachaManager.DoGacha(gaChaId, count, cb, errorCb, organizeId)
        XDataCenter.LottoManager.SetIsInterceptUiObtain(true)
        XNetwork.Call(METHOD_NAME.Gacha, { Id = gaChaId, Times = count }, function(res)
            XDataCenter.LottoManager.SetIsInterceptUiObtain(false)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if errorCb then
                    errorCb()
                end
                return
            end
            XGachaManager.UpdateGachaRewardInfo(res.GridInfoList, gaChaId)
            XGachaManager.UpdateGachaLog(gaChaId, res.GachaRecordList)
            TotalGachaTimes[gaChaId] = res.GachaCourseResult.TotalTimes
            MissTimes[gaChaId] = res.MissTimes

            local newUnlockGachaId
            if organizeId then
                newUnlockGachaId = XGachaManager.DrawUpdateOrganizeStatus(organizeId, gaChaId)
            end
            
            if cb then
                cb(res.RewardList, newUnlockGachaId, res)
            end
        end)
    end

    ---
    --- 在进入界面的时候请求'organizeId'卡池组里的已售罄池子，以及最新解锁的池子的奖励信息
    function XGachaManager.GetGachaOrganizeInfoRequest(organizeId, cb)
        XNetwork.Call(METHOD_NAME.GetGachaOrganizeInfo, { OrganizeId = organizeId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XGachaManager.UpdateGachaRewardInfo(res.GridInfoList, organizeId)
            XGachaManager.UpdateGachaLog(res.CurrentId, res.GachaRecordList)
            XGachaManager.OpenUpdateOrganizeStatus(organizeId, res.CurrentId, res.OutOfStockIdList)
            if cb then
                cb(res.CurrentId)
            end
        end)
    end

    function XGachaManager.ChoiceGachaRequest(gachaId, cb)
        XNetwork.Call("ChoiceGachaRequest", { Id = gachaId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 通过gachaId反查GroupId（gachaId跨Group唯一）
            local groupId = XGachaManager.GetGroupIdByGachaId(gachaId)
            if groupId then
                CurGroupSelectMap[groupId] = gachaId
            end

            if cb then
                cb()
            end
        end)
    end
    --------------------------------------------Organize卡池状态相关------------------------------------------------------

    ---
    --- 进入界面时更新卡池组的卡池状态
    ---
    --- 'newestGachaId'为最新解锁的卡池Id，它前面的卡池状态为正常或售罄，后面的卡池状态为锁定
    --- 'outSoldList'为已售罄卡池Id数组，这样就不用发送所有卡池的奖励信息，就能知道所有卡池的状态
    function XGachaManager.OpenUpdateOrganizeStatus(organizeId, newestGachaId, outSoldList)
        if not GachaOrganizeStatus[organizeId] then
            GachaOrganizeStatus[organizeId] = {}
        end

        -- 设置已售罄卡池
        for _, gachaId in ipairs(outSoldList) do
            if not GachaOrganizeStatus[organizeId][gachaId] then
                GachaOrganizeStatus[organizeId][gachaId] = XGachaConfigs.OrganizeGachaStatus.SoldOut
            end

            -- 进入界面时，客户端缓存的售馨卡池与服务器下发的售罄卡池不同步
            if GachaOrganizeStatus[organizeId][gachaId] ~= XGachaConfigs.OrganizeGachaStatus.SoldOut then
                XLog.Error(string.format("XGachaManager.UpdateOrganizeGachaStatus函数错误，服务器下发的最新卡池Id为%s，卡池组%s的卡池%s状态与服务器不同步，客户端的为未售罄状态",
                        tostring(newestGachaId), tostring(organizeId), tostring(gachaId)))
                GachaOrganizeStatus[organizeId][gachaId] = XGachaConfigs.OrganizeGachaStatus.SoldOut
            end
        end

        local organizeGachaIdList = XGachaConfigs.GetOrganizeGahcaIdList(organizeId)                -- organizeId组的所有gachaId数组，已根据Sort排序
        local newestGachaIndex = XGachaConfigs.GetOrganizeIndex(organizeId, newestGachaId)          -- 最新解锁卡池在organizeGachaIdList数组里的序号
        if not newestGachaIndex then
            return
        end
        -- 最新解锁卡池前面的卡池为已解锁或售罄，后面的为锁定
        for index, gachaId in ipairs(organizeGachaIdList) do
            if index <= newestGachaIndex then
                if not GachaOrganizeStatus[organizeId][gachaId] then
                    GachaOrganizeStatus[organizeId][gachaId] = XGachaConfigs.OrganizeGachaStatus.Normal
                end

                -- 进入界面时，客户端缓存的 newestGachaId卡池前面的卡池的状态 为锁定，说明状态与服务器不同步
                if GachaOrganizeStatus[organizeId][gachaId] == XGachaConfigs.OrganizeGachaStatus.Lock then
                    XLog.Error(string.format("XGachaManager.UpdateOrganizeGachaStatus函数错误，服务器下发的最新卡池Id为%s，卡池组%s的卡池%s状态与服务器不同步，客户端的为上锁状态",
                            tostring(newestGachaId), tostring(organizeId), tostring(gachaId)))
                    GachaOrganizeStatus[organizeId][gachaId] = XGachaConfigs.OrganizeGachaStatus.Normal
                end
            else
                if not GachaOrganizeStatus[organizeId][gachaId] then
                    GachaOrganizeStatus[organizeId][gachaId] = XGachaConfigs.OrganizeGachaStatus.Lock
                end

                -- 进入界面时，客户端缓存的 newestGachaId卡池后面的卡池的状态为正常，说明状态与服务器不同步
                if GachaOrganizeStatus[organizeId][gachaId] == XGachaConfigs.OrganizeGachaStatus.Normal then
                    XLog.Error(string.format("XGachaManager.UpdateOrganizeGachaStatus函数错误，服务器下发的最新卡池Id为%s，卡池组%s的卡池%s状态与服务器不同步，客户端的为正常状态",
                            tostring(newestGachaId), tostring(organizeId), tostring(gachaId)))
                    GachaOrganizeStatus[organizeId][gachaId] = XGachaConfigs.OrganizeGachaStatus.Lock
                end
            end
        end
    end

    --- 抽卡后更新卡池组的卡池状态
    --- 如果解锁了新卡池则返回该卡池Id
    ---@return number
    function XGachaManager.DrawUpdateOrganizeStatus(organizeId, DrawingGachaId)
        if not GachaOrganizeStatus[organizeId] then
            XLog.Error(string.format("XGachaManager.DrawUpdateOrganizeStatus函数错误，卡池组%s的状态数据为空",
                    tostring(organizeId)))
            GachaOrganizeStatus[organizeId] = {}
        end

        local isSoldOutRare = true  -- 特殊奖励是否售罄
        local isSoldOut = true      -- 全部奖励是否售罄
        local groupIdList = {}

        -- 是否无限次数
        if IsInfinite[DrawingGachaId] then
            isSoldOut = false
        else
            -- 找出DrawingGachaId的奖励
            local gachaCfg = XGachaConfigs.GetGachas()
            for _, groupId in pairs(gachaCfg[DrawingGachaId].GroupId) do
                table.insert(groupIdList, groupId)
            end

            for _, entry in pairs(GetGachaRewardMap(DrawingGachaId) or {}) do
                -- 是否属于DrawingGachaId的奖励组
                for _, groupId in pairs(groupIdList) do
                    if entry.Cfg and entry.Cfg.GroupId == groupId and entry.CurCount ~= 0 then
                        isSoldOut = false
                        if entry.Cfg.Rare then
                            isSoldOutRare = false
                        end
                        break
                    end
                end
            end
        end

        if isSoldOut then
            GachaOrganizeStatus[organizeId][DrawingGachaId] = XGachaConfigs.OrganizeGachaStatus.SoldOut
        end

        local isUnlockNext
        if isSoldOutRare then
            -- 是否解锁了新的卡池62504
            local nextGachaStatus, nextGachaId = XGachaManager.GetOrganizeNextGachaStatus(organizeId, DrawingGachaId)
            if nextGachaStatus and nextGachaId then
                if nextGachaStatus == XGachaConfigs.OrganizeGachaStatus.Lock then
                    GachaOrganizeStatus[organizeId][nextGachaId] = XGachaConfigs.OrganizeGachaStatus.Normal
                    isUnlockNext = nextGachaId
                end
            end
        end
        return isUnlockNext
    end

    ---
    --- 获取''organizeId'卡池组内'gachaId'卡池的状态
    function XGachaManager.GetOrganizeGachaStatus(organizeId, gachaId)
        if not gachaId or gachaId == 0 then
            return
        end
        if GachaOrganizeStatus[organizeId] then
            if GachaOrganizeStatus[organizeId][gachaId] then
                return GachaOrganizeStatus[organizeId][gachaId]
            else
                XLog.Error(string.format("XGachaManager.GetOrganizeGachaStatus函数错误，卡池%s的状态数据为空", gachaId))
            end
        else
            XLog.Error(string.format("XGachaManager.GetOrganizeGachaStatus函数错误，卡池组%s的状态数据为空", organizeId))
        end
        return XGachaConfigs.OrganizeGachaStatus.Lock
    end

    ---
    --- 获取''organizeId'卡池组内'gachaId'前一个卡池的状态与Id
    ---
    --- 如果'gachaId'是第一个卡池，则返回nil
    function XGachaManager.GetOrganizePreGachaStatus(organizeId, gachaId)
        local preGachaId = XGachaConfigs.GetOrganizePreGachaId(organizeId, gachaId)
        local status = XGachaManager.GetOrganizeGachaStatus(organizeId, preGachaId)
        if status then
            return status, preGachaId
        end
    end

    ---
    --- 获取''organizeId'卡池组内'gachaId'后一个卡池的状态与Id
    ---
    --- 如果'gachaId'是最后一个卡池，则返回nil
    function XGachaManager.GetOrganizeNextGachaStatus(organizeId, gachaId)
        local nextGachaId = XGachaConfigs.GetOrganizeNextGachaId(organizeId, gachaId)
        local status =  XGachaManager.GetOrganizeGachaStatus(organizeId, nextGachaId)
        if status then
            return status, nextGachaId
        end
    end

    function XGachaManager.BuyTicket(gachaId, buyCount, ticketKey, cb)
        XNetwork.Call(METHOD_NAME.GachaItemExchangeRequest, { Id = gachaId, ExchangeNum = buyCount, SelectIndex = ticketKey }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            CurExchangeItemCount[gachaId] = res.CurExchangeItemCount
            local reward = XRewardManager.CreateRewardGoodsByTemplate({ TemplateId = res.GainItemId, Count = res.GainItemCount })
            if cb then cb({ reward }) end
        end)
    end

    --- 特殊奖励是否售罄
    function XGachaManager.GetGachaIsSoldOutRare(gachaId)
        local isSoldOutRare = true
        local groupIdList = {}
        local gachaCfg = XGachaConfigs.GetGachas()
        for _, groupId in pairs(gachaCfg[gachaId].GroupId) do
            table.insert(groupIdList, groupId)
        end

        local gachaRewardInfos = GetGachaRewardMap(gachaId)
    
        if not XTool.IsTableEmpty(gachaRewardInfos) then
            for _, entry in pairs(gachaRewardInfos) do
                if entry and entry.Cfg then
                    for _, groupId in pairs(groupIdList) do
                        if entry.Cfg.GroupId == groupId and entry.CurCount ~= 0 then
                            if entry.Cfg.Rare then
                                isSoldOutRare = false
                            end
                            break
                        end
                    end
                end
            end
        else
            isSoldOutRare = false
            XLog.Error('尝试检查GachaId：'..tostring(gachaId)..' 卡池是否抽完特殊奖励时，奖励数据不存在')
        end
    
        return isSoldOutRare
    end

    function XGachaManager.NotifySelfChoiceGachaData(data)
        CurGachaFashionSelfChoiceActivityId = data.ActivityId
        CurGroupSelectMap = {}
        if not XTool.IsNumberValid(data.ActivityId) then
            return  -- 活动已结束，清空状态即可
        end
        if data.ChoiceGroupList then
            for _, groupInfo in pairs(data.ChoiceGroupList) do
                if XTool.IsNumberValid(groupInfo.SelectedGachaId) then
                    CurGroupSelectMap[groupInfo.GroupId] = groupInfo.SelectedGachaId
                end
            end
        end
    end
    --------------------------------------------------------------------------------------------------------------------


    XGachaManager.Init()
    return XGachaManager
end

XRpc.NotifySelfChoiceGachaData = function(data)
    XDataCenter.GachaManager.NotifySelfChoiceGachaData(data)
end