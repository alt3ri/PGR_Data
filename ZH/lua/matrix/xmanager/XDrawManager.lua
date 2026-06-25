local XDrawActivityTargetInfo = require("XEntity/XDraw/XDrawActivityTargetInfo")

XDrawManagerCreator = function()
    ---@class XDrawManager
    local XDrawManager = {}

    local tableInsert = table.insert
    local tableSort = table.sort

    local GET_DRAW_DATA_INTERVAL = 15

    --region Data Config
    local DrawCombinations = {}
    local DrawGroupRule = {}
    local DrawShow = {}
    local DrawShowCharacter = {}
    local DrawCamera = {}
    local DrawTabs = {}
    --endregion

    local DrawGroupInfos = {}
    local DrawInfos = {}
    local LastGetGroupInfoTime = 0
    local LastGetDropInfoTimes = {}
    
    ---@type table<number, XDrawActivityTargetInfo> key = activityId
    local _DrawActivityTargetInfoDir = {}
    ---@type table<number, number> key = groupId value = activityId
    local _DrawGroupActivityTargetDir = {}
    
    local OpenDevilMayCryDrawList = {}
    local IsDevilMayCryDrawOpen = false
    local ActivityDrawList = {}
    local ActivityDrawListByTag = {}
    local FreeDrawTicket = {}
    local DrawActivityCount = 0
    local IsHasNewActivityDraw = false
    local CurSelectTabInfo = nil
    local LostSelectDrawGroupId = 0
    local LostSelectDrawType = 0
    local DrawNewGroupIds = nil
    local DrawDiscountGroupIds = nil
    local DrawDevilMayCryGroupIds = nil
    local DrawHideOptionalBtnGroupIds = nil

    -- ExtraOption 相关数据
    local DisplayOptionCacheByGroup = {}
    local LostSelectOptionKey = ""

    -- 可肝卡池相关数据
    local CanLiverActivityId = nil
    local CanLiverDrawCount = nil
    local CanLiverRewardIndex = nil
    XDrawManager.DrawEventType = { Normal = 0, NewHand = 1, Activity = 2, OldActivity = 3 }

    function XDrawManager.Init()
        DrawCombinations = XDrawConfigs.GetDrawCombinations()
        DrawGroupRule = XDrawConfigs.GetDrawGroupRule()
        DrawShow = XDrawConfigs.GetDrawShow()
        DrawShowCharacter = XDrawConfigs.GetDrawShowCharacter()
        DrawCamera = XDrawConfigs.GetDrawCamera()
        DrawTabs = XDrawConfigs.GetDrawTabs()
    end

    --region Ui
    function XDrawManager.OpenDrawUi(ruleType, groupId, defaultDrawId, isPop, groupPool, optionKey)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DrawCard) then
            return
        end
        XDrawManager.GetDrawGroupList(function()
            -- 先确保目标 group 的 DrawInfo 就绪，再透传 optionKey 给 UI 层决定默认落点
            local function doOpen()
                if isPop then
                    XLuaUiManager.PopThenOpen("UiNewDrawMain", ruleType, groupId, defaultDrawId, groupPool, optionKey)
                else
                    XLuaUiManager.Open("UiNewDrawMain", ruleType, groupId, defaultDrawId, groupPool, optionKey)
                end
            end
            if groupId and groupId ~= 0 then
                XDrawManager.GetDrawInfoList(groupId, doOpen)
            else
                doOpen()
            end
        end)
    end
    --endregion

    function XDrawManager.GetFreeTicketIdByGroupId(groupId)
        local tickets = XDrawManager.GetTicketsByGroupId(groupId)
        local expireTime = math.huge
        local ticketId = 0
        -- 存在多个时，找出关联卡池数最少、剩余时间最少、Id最小的免费券
        local minDrawAssociate = 999
        local cfgId = math.maxinteger

        for _, ticketInfo in pairs(tickets) do
            if XTool.IsNumberValid(ticketInfo.ExpireTime) and ticketInfo.Count > 0 then
                local ticketCfg = XDrawConfigs.GetDrawTicketCfg(ticketInfo.CfgId)
                local drawGroupCount = #ticketCfg.DrawGroupIds

                -- 优先选卡池数最少的
                if drawGroupCount < minDrawAssociate then
                    minDrawAssociate = drawGroupCount
                    ticketId = ticketInfo.Id
                    expireTime = ticketInfo.ExpireTime
                elseif drawGroupCount == minDrawAssociate then
                    -- 其次选剩余时间最少的
                    if ticketInfo.ExpireTime < expireTime then
                        ticketId = ticketInfo.Id
                        expireTime = ticketInfo.ExpireTime
                    elseif ticketInfo.ExpireTime == expireTime then
                        -- 最后选Id最小的
                        if ticketInfo.CfgId < cfgId then
                            ticketId = ticketInfo.Id
                            cfgId = ticketInfo.CfgId
                        end
                    end
                end
            end
        end
        return ticketId
    end
    
    -- 获取该卡池中有效免费券中最少的剩余时间及数量
    ---@return @TicketId: 并列集中的代表， expireTime:剩余时间，count：所有相同最小剩余时间的免费券之和
    function XDrawManager.GetLeastExpireTimeFreeTicketIdByGroupId(groupId)
        local count = 0
        local expireTime = math.huge
        local representTicketId = 0
        
        local stack = {}
        local stackCount = 0

        local tickets = XDrawManager.GetTicketsByGroupId(groupId)

        for _, ticketInfo in pairs(tickets) do
            if XTool.IsNumberValid(ticketInfo.ExpireTime) and ticketInfo.Count > 0 then
                if ticketInfo.ExpireTime < expireTime then
                    expireTime = ticketInfo.ExpireTime
                    -- 清空栈
                    if stackCount > 0 then
                        for i = 1, stackCount do
                            stack[i] = nil
                        end
                    end
                    -- 入栈
                    stackCount = 1
                    stack[1] = ticketInfo.Count
                    representTicketId = ticketInfo.Id
                elseif ticketInfo.ExpireTime == expireTime then
                    -- 入栈
                    stackCount = stackCount + 1
                    stack[stackCount] = ticketInfo.Count
                end
            end
        end
        
        -- 出栈
        if stackCount > 0 then
            for i = stackCount, 1, -1 do
                count = count + stack[i]
                stack[i] = nil
            end
        end
        
        return representTicketId, expireTime, count
    end
    
    ---@return @param1:指定ticketId的数据, param2:是否有新的数据, param3... 多个新的数据
    function XDrawManager.GetTicketInfoForExpireTimeDisplay(ticketId, groupId)
        local ticketInfo = XDrawManager.GetTicketInfoById(ticketId)

        if ticketInfo and XTool.IsNumberValid(ticketInfo.ExpireTime) then
            return ticketInfo
        else
            -- 尝试查找新的最少剩余时间的免费券
            local representTicketId, expireTime, count = XDrawManager.GetLeastExpireTimeFreeTicketIdByGroupId(groupId)

            if XTool.IsNumberValid(representTicketId) then
                return nil, true, representTicketId, expireTime, count
            end
        end
    end

    function XDrawManager.GetTicketInfoById(id)
        return FreeDrawTicket[id]
    end

    function XDrawManager.GetTicketsByGroupId(groupId)
        local tickets = {}
        for _, ticketInfo in pairs(FreeDrawTicket) do
            local cfg = XDrawConfigs.GetDrawTicketCfg(ticketInfo.CfgId)
            if cfg then
                for _, gId in pairs(cfg.DrawGroupIds) do
                    if gId == groupId then
                        table.insert(tickets, ticketInfo)
                    end
                end
            end
        end
        return tickets
    end

    function XDrawManager.CheckHasFreeTicket(groupId)
        local now = XTime.GetServerNowTimestamp()
        local tickets = XDrawManager.GetTicketsByGroupId(groupId)
        local isHasTicket = false
        local groupInfo = XDrawManager.GetDrawGroupInfoByGroupId(groupId)
        if groupInfo then
            if now < groupInfo.StartTime or now > groupInfo.EndTime and groupInfo.EndTime ~= 0 then
                return false
            end
        end
        for _, ticketInfo in pairs(tickets) do
            if ticketInfo.Count > 0 or ticketInfo.ExpireTime > now then
                isHasTicket = true
                break
            end
        end
        return isHasTicket
    end
    
    function XDrawManager.GetFreeTicketCount(groupId)
        local count = 0
        
        local now = XTime.GetServerNowTimestamp()
        local tickets = XDrawManager.GetTicketsByGroupId(groupId)
        local isHasTicket = false
        local groupInfo = XDrawManager.GetDrawGroupInfoByGroupId(groupId)
        if groupInfo then
            if now < groupInfo.StartTime or now > groupInfo.EndTime and groupInfo.EndTime ~= 0 then
                return count
            end
        end
        for _, ticketInfo in pairs(tickets) do
            if ticketInfo.Count > 0 and ticketInfo.ExpireTime > now then
                count = count + ticketInfo.Count
            end
        end
        
        return count
    end
    
    function XDrawManager.CheckDrawFreeTicketTag()
        local now = XTime.GetServerNowTimestamp()
        for _, ticketInfo in pairs(FreeDrawTicket) do
            local cfg = XDrawConfigs.GetDrawTicketCfg(ticketInfo.CfgId)
            local isInTime = true
            if cfg then
                for _, gId in pairs(cfg.DrawGroupIds) do
                    local groupInfo = XDrawManager.GetDrawGroupInfoByGroupId(gId)
                    isInTime = isInTime and groupInfo and (now > groupInfo.StartTime and now < groupInfo.EndTime or groupInfo.EndTime == 0)
                end
            end
            if ticketInfo.Count > 0 and isInTime then
                return true
            end
        end
        return false
    end

    function XDrawManager.GetDrawPreview(drawId)
        return XDrawConfigs.GetDrawPreviews(drawId)
    end

    function XDrawManager.GetDrawCombination(drawId)
        return DrawCombinations[drawId]
    end

    ---@return XTableDrawProbShow
    function XDrawManager.GetDrawProb(drawId)
        return XDrawConfigs.GetDrawProbById(drawId)
    end

    function XDrawManager.GetDrawGroupRule(groupId)
        return DrawGroupRule[groupId]
    end

    function XDrawManager.GetDrawShow(type)
        return DrawShow[type - 1]
    end

    function XDrawManager.GetDrawCamera(id)
        return DrawCamera[id]
    end

    function XDrawManager.GetDrawInfo(drawId)
        return DrawInfos[drawId]
    end

    ---@return XTableDrawShowCharacter
    function XDrawManager.GetDrawShowCharacter(id)
        return DrawShowCharacter[id]
    end

    function XDrawManager.GetLostSelectDrawGroupId()
        return LostSelectDrawGroupId
    end

    function XDrawManager.SetLostSelectDrawGroupId(groupId)
        LostSelectDrawGroupId = groupId
    end

    function XDrawManager.GetLostSelectDrawType()
        return LostSelectDrawType
    end

    function XDrawManager.SetLostSelectDrawType(type)
        LostSelectDrawType = type
    end

    function XDrawManager.GetDrawInfoListByGroupId(groupId)
        local list = {}
        local drawAimProbability = XDrawConfigs.GetDrawAimProbability()

        for _, info in pairs(DrawInfos) do
            if info.GroupId == groupId then
                tableInsert(list, info)
            end
        end

        tableSort(list, function(a, b)
            local PriorityA = drawAimProbability[a.Id] and drawAimProbability[a.Id].Priority or 0
            local PriorityB = drawAimProbability[b.Id] and drawAimProbability[b.Id].Priority or 0

            if PriorityA == PriorityB then
                return a.Id < b.Id
            else
                return PriorityA > PriorityB
            end
        end)

        return list
    end

    function XDrawManager.GetUseDrawInfoByGroupId(groupId)
        local groupInfo = DrawGroupInfos[groupId]
        if not groupInfo then
            return nil
        end
        local dict = groupInfo.UseDrawIdDict or {}
        local useDrawId = dict[0] or 0
        if useDrawId > 0 then
            local drawInfo = XDrawManager.GetDrawInfo(useDrawId)
            if drawInfo then
                return drawInfo
            end
        end
        return nil
    end

    function XDrawManager.GetDrawGroupInfoByGroupId(groupId)
        return DrawGroupInfos[groupId]
    end

    function XDrawManager.CheckDrawIsTimeOver(drawId)
        if not DrawInfos[drawId] then
            return true
        end
        if DrawInfos[drawId].EndTime == 0 then
            return false
        end
        local nowTime = XTime.GetServerNowTimestamp()
        return DrawInfos[drawId].EndTime - nowTime <= 0
    end

    -- 查询相关begin --
    function XDrawManager.GetDrawGroupInfos()
        local list = {}

        for _, v in pairs(DrawGroupInfos) do
            tableInsert(list, v)
        end

        tableSort(list, function(a, b)
            return a.Priority > b.Priority
        end)
        --检测如果有过期的，下次请求跳过时间间隔检测
        for _, v in pairs(list) do
            if v.EndTime > 0 and v.EndTime - XTime.GetServerNowTimestamp() <= 0 then
                LastGetGroupInfoTime = 0
                CurSelectTabInfo = nil
            end
        end
        return list
    end

    function XDrawManager.GetGroupIdWithMaxOrder()
        local orderId = -1
        local groupId = -1
        for _, v in pairs(DrawGroupInfos) do
            if orderId < v.Order then
                orderId = v.Order
                groupId = v.Id
            end
        end
        return groupId
    end

    function XDrawManager.GetGroupIdWithFreeTicket()
        local max = -1
        local groupIdList = {}
        local ticketCountDic = {}
        for _, ticketInfo in pairs(FreeDrawTicket) do
            if not ticketCountDic[ticketInfo.CfgId] then
                ticketCountDic[ticketInfo.CfgId] = ticketInfo.Count
            else
                ticketCountDic[ticketInfo.CfgId] = ticketCountDic[ticketInfo.CfgId] + ticketInfo.Count
            end
        end

        for cfgId, count in pairs(ticketCountDic) do
            local cfg = XDrawConfigs.GetDrawTicketCfg(cfgId)
            if count > max then
                max = count
                groupIdList = {}
                for _,groupId in pairs(cfg.DrawGroupIds) do
                    table.insert(groupIdList,groupId)
                end
            elseif count == max then
                for _,groupId in pairs(cfg.DrawGroupIds) do
                    table.insert(groupIdList,groupId)
                end
            end
        end
        
        local order = -1
        local groupId
        for _, gId in pairs(groupIdList) do
            local groupInfo = XDrawManager.GetDrawGroupInfoByGroupId(gId)
            if groupInfo and groupInfo.Order > order then
                order = groupInfo.Order
                groupId = gId
            end
        end
        return groupId
    end

    function XDrawManager.GetDrawTicketCountByTemplateId(templateId)
        local count = 0

        if not XTool.IsTableEmpty(FreeDrawTicket) then
            for i, v in pairs(FreeDrawTicket) do
                if v.CfgId == templateId then
                    count = count + v.Count
                end
            end
        end
        
        return count
    end
    
    --==============================--
    --desc: 打乱奖励顺序，防止因规则造成顺序可循
    --@rewardGoodsList: 奖励列表
    --@return 处理后奖励列表
    --==============================--
    -- local function UpsetRewardGoodsList(rewardGoodsList)
    --     local list = {}

    --     local len = #rewardGoodsList
    --     if len <= 1 then
    --         return rewardGoodsList
    --     end

    --     for i = 1, len do
    --         local index = math.random(1, len)
    --         if index ~= i then
    --             local tmp = rewardGoodsList[i]
    --             rewardGoodsList[i] = rewardGoodsList[index]
    --             rewardGoodsList[index] = tmp
    --         end
    --     end

    --     return rewardGoodsList
    -- end

    -- 消息相关end --
    -- Wind --
    function XDrawManager.GetDrawTab(tabID)
        for _, tab in pairs(DrawTabs) do
            if tab.Id == tabID then
                return tab
            end
        end

        XLog.Error("XDrawManager.GetDrawTab ： Client/Draw/DrawTabs.tab 表中不存在 tabID：" .. tabID .. "检查参数或者配置表项")
        return nil
    end

    function XDrawManager.GetCurSelectTabInfo()
        return CurSelectTabInfo
    end

    function XDrawManager.SetCurSelectTabInfo(info)
        CurSelectTabInfo = info
    end

    function XDrawManager.UpdateDrawGroupByInfo(clientDrawInfo)
        for _, v in pairs(DrawGroupInfos) do
            -- 统一从 UseDrawIdDict 匹配（服务端已废弃 UseDrawId，全面转为 UseDrawIdDict）
            local isMatch = false
            if v.UseDrawIdDict then
                for _, useDrawId in pairs(v.UseDrawIdDict) do
                    if useDrawId == clientDrawInfo.Id then
                        isMatch = true
                        break
                    end
                end
            end
            if isMatch then
                v.BottomTimes = clientDrawInfo.MaxBottomTimes - clientDrawInfo.BottomTimes
                -- 更新十连抽已使用折扣次数
                v.UseTenDrawOnSaleTimes = clientDrawInfo.UseTenDrawOnSaleTimes
            end
        end
        -- 根据 GroupSubType 更新 UseDrawIdDict
        if clientDrawInfo.GroupSubType and clientDrawInfo.GroupSubType > 0 then
            local groupId = clientDrawInfo.GroupId
            if groupId and DrawGroupInfos[groupId] then
                local useDrawIdDict = DrawGroupInfos[groupId].UseDrawIdDict or {}
                useDrawIdDict[clientDrawInfo.GroupSubType] = clientDrawInfo.Id
                DrawGroupInfos[groupId].UseDrawIdDict = useDrawIdDict
                -- 失效该 group 的 DisplayOption 缓存
                XDrawManager._InvalidateDisplayOptionCacheForGroup(groupId)
            end
        end
    end

    function XDrawManager.GetActivityDrawMarkId(Id)
        --获取当前卡池ID的卡池在记录队列中的位置ID
        local countMax = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "ActivityDrawCountMax"))
        if countMax then
            for i = 1, countMax do
                local drawId = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "NewActivityDraw", i))
                if drawId then
                    if drawId == Id then
                        return i
                    end
                end
            end
        end
        return nil
    end

    function XDrawManager.MarkActivityDraw()
        --记录当前开放的活动卡池
        for _, Id in pairs(ActivityDrawList or {}) do
            if not XDrawManager.GetActivityDrawMarkId(Id) then
                local count = 1
                while true do
                    if not XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "NewActivityDraw", count)) then
                        XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "NewActivityDraw", count), Id)
                        local countMax = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "ActivityDrawCountMax"))
                        if (not countMax) or (countMax and countMax < count) then
                            XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "ActivityDrawCountMax"), count)
                        end
                        break
                    end
                    count = count + 1
                end
            end
        end
        IsHasNewActivityDraw = false
    end

    function XDrawManager.UnMarkOldActivityDraw(list)
        --消除已关闭卡池的记录
        local countMax = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "ActivityDrawCountMax"))
        if countMax then
            for i = 1, countMax do
                local drawId = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "NewActivityDraw", i))
                if drawId then
                    local IsInList = false
                    for _, v in pairs(list or {}) do
                        if drawId == v then
                            IsInList = true
                        end
                    end
                    if not IsInList then
                        XSaveTool.RemoveData(string.format("%d%s%d", XPlayer.Id, "NewActivityDraw", i))
                    end
                end
            end
        end
    end

    function XDrawManager.SetNewActivityDraw(list)
        --记录是否有新卡池开启
        IsHasNewActivityDraw = false
        for _, v in pairs(list or {}) do
            IsHasNewActivityDraw = IsHasNewActivityDraw or (not XDrawManager.GetActivityDrawMarkId(v))
        end
    end

    function XDrawManager.CheckNewActivityDraw()
        --检查是否有新卡池开启
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.DrawCard) then
            return false
        end
        return IsHasNewActivityDraw
    end

    function XDrawManager.UpdateDrawActivityCount(count)
        DrawActivityCount = count
    end

    function XDrawManager.UpdateActivityDrawList(list)
        ActivityDrawList = list
    end

    function XDrawManager.UpdateActivityDrawListByTag()
        for _, drawId in pairs(ActivityDrawList) do
            local drawInfo = XDrawManager.GetDrawInfo(drawId)
            local drawGroupInfo = XDrawManager.GetDrawGroupInfos()[drawInfo.GroupId]
            local tag = drawGroupInfo.Tag
            if not ActivityDrawListByTag[tag] then
                ActivityDrawListByTag[tag] = {}
            end
            table.insert(ActivityDrawListByTag[tag], drawInfo.Id)
        end
    end

    -- 联动卡池是否有开启
    function XDrawManager.CheckCollaborationDrawOpen()
        -- 目前只支持鬼泣卡池
        return XDrawManager.GetIsDevilMayCryDrawOpen()
    end

    function XDrawManager.CheckDrawActivityCount()
        return DrawActivityCount > 0
    end

    function XDrawManager.IsCanAutoOpenAimGroupSelect(time, groupId)
        --判断time时间以内是否可以自动打开狙击池组合选择界面
        local data = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "AimAutoOpenState", groupId))
        if data then
            if time > data then
                XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "AimAutoOpenState", groupId), time)
                return true
            else
                return false
            end
        else
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "AimAutoOpenState", groupId), time)
            return true
        end
    end

    function XDrawManager.IsShowNewTag(time, ruleType, groupId)
        --判断time时间以内是否显示新标签
        local data = XSaveTool.GetData(string.format("%d%s%d%d", XPlayer.Id, "DrawShowNewTag", ruleType, groupId))
        if data then
            if time > data then
                return true
            else
                return false
            end
        else
            return true
        end
    end

    function XDrawManager.MarkNewTag(time, ruleType, groupId)
        --标记新标签
        local data = XSaveTool.GetData(string.format("%d%s%d%d", XPlayer.Id, "DrawShowNewTag", ruleType, groupId))
        if data then
            if time > data then
                XSaveTool.SaveData(string.format("%d%s%d%d", XPlayer.Id, "DrawShowNewTag", ruleType, groupId), time)
            end
        else
            XSaveTool.SaveData(string.format("%d%s%d%d", XPlayer.Id, "DrawShowNewTag", ruleType, groupId), time)
        end
    end

    --region ExtraOption 新标记（option维度）
    --- option维度的新标记判断
    function XDrawManager.IsShowNewTagForOption(time, ruleType, optionKey)
        local groupId, groupSubtype = XDrawManager._ParseOptionKey(optionKey)
        -- 原始option(groupSubtype=0)兼容旧的group维度key
        if groupSubtype == 0 then
            return XDrawManager.IsShowNewTag(time, ruleType, groupId)
        end
        local data = XSaveTool.GetData(string.format("%d%s%d%s", XPlayer.Id, "DrawShowNewTag", ruleType, optionKey))
        if data then
            return time > data
        end
        return true
    end

    --- option维度的新标记写入
    function XDrawManager.MarkNewTagForOption(time, ruleType, optionKey)
        local groupId, groupSubtype = XDrawManager._ParseOptionKey(optionKey)
        -- 原始option(groupSubtype=0)兼容旧的group维度key
        if groupSubtype == 0 then
            XDrawManager.MarkNewTag(time, ruleType, groupId)
            return
        end
        local data = XSaveTool.GetData(string.format("%d%s%d%s", XPlayer.Id, "DrawShowNewTag", ruleType, optionKey))
        if data then
            if time > data then
                XSaveTool.SaveData(string.format("%d%s%d%s", XPlayer.Id, "DrawShowNewTag", ruleType, optionKey), time)
            end
        else
            XSaveTool.SaveData(string.format("%d%s%d%s", XPlayer.Id, "DrawShowNewTag", ruleType, optionKey), time)
        end
    end
    --endregion

    --region ExtraOption 核心：OptionKey 解析
    --- 解析 OptionKey -> groupId, groupSubtype
    function XDrawManager._ParseOptionKey(optionKey)
        if not optionKey or optionKey == "" then
            return 0, 0
        end
        local groupId, groupSubtype = string.match(optionKey, "^(%d+)_(%d+)$")
        groupId = tonumber(groupId) or 0
        groupSubtype = tonumber(groupSubtype) or 0
        return groupId, groupSubtype
    end

    --- 构建 OptionKey
    function XDrawManager._MakeOptionKey(groupId, groupSubtype)
        return string.format("%d_%d", groupId, groupSubtype or 0)
    end
    --endregion

    --region ExtraOption 核心：DisplayOption 构建系统
    --- 获取指定 Group 的所有可显示 Option（带缓存）
    function XDrawManager.GetDisplayOptionsByGroupId(groupId)
        if DisplayOptionCacheByGroup[groupId] then
            return DisplayOptionCacheByGroup[groupId]
        end
        local options = XDrawManager._BuildDisplayOptionsForGroup(groupId)
        DisplayOptionCacheByGroup[groupId] = options
        return options
    end

    --- 根据 OptionKey 获取 DisplayOption
    function XDrawManager.GetDisplayOptionByKey(optionKey)
        if not optionKey or optionKey == "" then
            return nil
        end
        local groupId, _ = XDrawManager._ParseOptionKey(optionKey)
        local options = XDrawManager.GetDisplayOptionsByGroupId(groupId)
        for _, option in ipairs(options) do
            if option.OptionKey == optionKey then
                return option
            end
        end
        return nil
    end

    --- 获取指定 Group 的默认 OptionKey
    function XDrawManager.GetDefaultOptionKeyByGroupId(groupId)
        local options = XDrawManager.GetDisplayOptionsByGroupId(groupId)
        if options and #options > 0 then
            return options[1].OptionKey
        end
        return nil
    end

    --- 构建 Group 的 DisplayOption 列表
    function XDrawManager._BuildDisplayOptionsForGroup(groupId)
        local groupInfo = DrawGroupInfos[groupId]
        if not groupInfo then
            return {}
        end

        local options = {}

        -- 1. 构建原选项（剔除黑名单 Draw）
        local originalOption = XDrawManager._BuildOriginalOption(groupId, groupInfo)
        if originalOption then
            tableInsert(options, originalOption)
        end

        -- 2. 构建 ExtraOptions
        local extraOptions = XDrawManager._BuildExtraOptions(groupId, groupInfo)
        for _, opt in ipairs(extraOptions) do
            tableInsert(options, opt)
        end

        -- 3. 按 Priority 降序排序
        tableSort(options, function(a, b)
            return a.Priority > b.Priority
        end)

        return options
    end

    --- 构建原选项（GroupSubtype=0）
    function XDrawManager._BuildOriginalOption(groupId, groupInfo)
        local allDrawList = XDrawManager.GetDrawInfoListByGroupId(groupId)
        if not allDrawList or #allDrawList == 0 then
            return nil
        end

        -- 获取黑名单
        local blackListSet = {}
        local blackList = groupInfo.TagBlackListDrawIds or {}
        for _, drawId in ipairs(blackList) do
            blackListSet[drawId] = true
        end

        -- 剔除黑名单 Draw
        local drawIdList = {}
        for _, drawInfo in ipairs(allDrawList) do
            if not blackListSet[drawInfo.Id] then
                tableInsert(drawIdList, drawInfo.Id)
            end
        end

        -- 如果全被剔除了，不创建空 option
        if #drawIdList == 0 then
            return nil
        end

        local groupRule = XDrawConfigs.GetDrawGroupRuleById(groupId)
        local option = {
            OptionKey = XDrawManager._MakeOptionKey(groupId, 0),
            GroupId = groupId,
            GroupSubtype = 0,
            Name = (groupRule and groupRule.TitleCN) or "",
            Tag = groupInfo.Tag,
            Priority = groupInfo.Priority or 0,
            DrawIdList = drawIdList,
            BannerBeginTime = groupInfo.BannerBeginTime or 0,
            BannerEndTime = groupInfo.BannerEndTime or 0,
            IsExtraOption = false,
        }
        return option
    end

    --- 构建 ExtraOption 列表（GroupSubtype>0）
    function XDrawManager._BuildExtraOptions(groupId, groupInfo)
        local allDrawList = XDrawManager.GetDrawInfoListByGroupId(groupId)
        if not allDrawList or #allDrawList == 0 then
            return {}
        end

        -- 按 GroupSubtype 分组聚合 Draw
        local subtypeToDrawList = {}
        for _, drawInfo in ipairs(allDrawList) do
            local subtype = drawInfo.GroupSubType or 0
            if subtype > 0 then
                subtypeToDrawList[subtype] = subtypeToDrawList[subtype] or {}
                tableInsert(subtypeToDrawList[subtype], drawInfo.Id)
            end
        end

        local options = {}

        for subtype, drawIdList in pairs(subtypeToDrawList) do
            local extraTagCfg = XDrawConfigs.GetDrawExtraTagGroupCfgById(subtype)
            if extraTagCfg then
                local timeId = extraTagCfg.TimeId or 0
                local isTimeValid = not XTool.IsNumberValid(timeId) or XFunctionManager.CheckInTimeByTimeId(timeId)

                if isTimeValid then
                    local startTime = XTool.IsNumberValid(timeId) and XFunctionManager.GetStartTimeByTimeId(timeId) or 0
                    local endTime = XTool.IsNumberValid(timeId) and XFunctionManager.GetEndTimeByTimeId(timeId) or 0
                    local option = {
                        OptionKey = XDrawManager._MakeOptionKey(groupId, subtype),
                        GroupId = groupId,
                        GroupSubtype = subtype,
                        Name = extraTagCfg.Name or "",
                        Tag = extraTagCfg.Tag or groupInfo.Tag,
                        Priority = extraTagCfg.Priority or 0,
                        DrawIdList = drawIdList,
                        BannerBeginTime = startTime,
                        BannerEndTime = endTime,
                        IsExtraOption = true,
                    }
                    tableInsert(options, option)
                end
            end
        end

        return options
    end

    --- 记录页专用：服务端 HistoryGroups 决定历史下拉入口，GroupSubTypes 只补子组选项展示信息
    function XDrawManager.GetDisplayOptionsForRecord(historyGroupInfos)
        local options = {}
        for _, historyGroupInfo in ipairs(historyGroupInfos) do
            local groupId = historyGroupInfo.DrawGroupId
            local groupRuleCfg = XDrawConfigs.GetDrawGroupRuleById(groupId)
            local groupName = groupRuleCfg and groupRuleCfg.TitleCN or ""
            local groupPriority = historyGroupInfo.Priority or 0

            -- 真 Option：服务端 HistoryGroups 下发的 DrawGroupId，对应 GroupSubType=0 的历史入口
            tableInsert(options, {
                DrawGroupId = groupId,
                GroupSubType = 0,
                OptionKey = XDrawManager._MakeOptionKey(groupId, 0),
                Name = groupName,
                Priority = groupPriority,
                IsExtraOption = false,
            })

            -- 假 Option：服务端 GroupSubTypes 下发子组类型，展示信息从 DrawExtraTagGroup 读取
            for _, groupSubType in ipairs(historyGroupInfo.GroupSubTypes) do
                local extraTagCfg = XDrawConfigs.GetDrawExtraTagGroupCfgById(groupSubType)
                tableInsert(options, {
                    DrawGroupId = groupId,
                    GroupSubType = groupSubType,
                    OptionKey = XDrawManager._MakeOptionKey(groupId, groupSubType),
                    Name = extraTagCfg and extraTagCfg.Name or groupName,
                    Priority = extraTagCfg and extraTagCfg.Priority or groupPriority,
                    IsExtraOption = true,
                })
            end
        end

        tableSort(options, function(a, b)
            if a.Priority ~= b.Priority then
                return a.Priority > b.Priority
            end
            if a.DrawGroupId ~= b.DrawGroupId then
                return a.DrawGroupId > b.DrawGroupId
            end
            return (a.GroupSubType or 0) < (b.GroupSubType or 0)
        end)

        return options
    end

    --- 失效指定 Group 的 DisplayOption 缓存
    function XDrawManager._InvalidateDisplayOptionCacheForGroup(groupId)
        DisplayOptionCacheByGroup[groupId] = nil
    end

    --- 失效所有 DisplayOption 缓存
    function XDrawManager._InvalidateAllDisplayOptionCache()
        DisplayOptionCacheByGroup = {}
    end
    --endregion

    --region ExtraOption 核心：Option 维度查询接口
    --- 获取 Option 当前使用的 DrawInfo（带fallback，用于展示）
    function XDrawManager.GetUseDrawInfoByOptionKey(optionKey)
        if not optionKey or optionKey == "" then
            return nil
        end
        local groupId, groupSubtype = XDrawManager._ParseOptionKey(optionKey)
        local groupInfo = DrawGroupInfos[groupId]
        if not groupInfo then
            return nil
        end

        -- 获取 UseDrawId（统一从 UseDrawIdDict 获取，服务端已废弃 UseDrawId）
        local dict = groupInfo.UseDrawIdDict or {}
        local useDrawId = dict[groupSubtype]

        -- 检查 useDrawId 是否有效
        if useDrawId and useDrawId > 0 then
            local drawInfo = XDrawManager.GetDrawInfo(useDrawId)
            if drawInfo then
                return drawInfo
            end
        end

        -- fallback：使用该 option 的第一个有效 draw
        local option = XDrawManager.GetDisplayOptionByKey(optionKey)
        if option and option.DrawIdList and #option.DrawIdList > 0 then
            return XDrawManager.GetDrawInfo(option.DrawIdList[1])
        end

        -- 最终兜底：直接使用 group 级（仅当 option 存在但 DrawIdList 为空时不兜底，避免黑名单 Draw 复活）
        if not option then
            return XDrawManager.GetUseDrawInfoByGroupId(groupId)
        end

        return nil
    end

    --- 获取 Option 真实选择的 drawId（不带fallback，用于状态判断）
    function XDrawManager.GetRealUseDrawIdByOptionKey(optionKey)
        if not optionKey or optionKey == "" then
            return 0
        end
        local groupId, groupSubtype = XDrawManager._ParseOptionKey(optionKey)
        local groupInfo = DrawGroupInfos[groupId]
        if not groupInfo then
            return 0
        end

        local dict = groupInfo.UseDrawIdDict or {}
        return dict[groupSubtype] or 0
    end

    --- 获取 Option 展示用 UseDrawId（带fallback）
    function XDrawManager.GetUseDrawIdByOptionKey(optionKey)
        local drawInfo = XDrawManager.GetUseDrawInfoByOptionKey(optionKey)
        if drawInfo then
            return drawInfo.Id
        end
        return 0
    end

    --- 获取 Option 包含的所有 DrawInfo 列表
    function XDrawManager.GetDrawInfoListByOptionKey(optionKey)
        if not optionKey or optionKey == "" then
            return {}
        end
        local option = XDrawManager.GetDisplayOptionByKey(optionKey)
        if not option or not option.DrawIdList then
            return {}
        end

        local list = {}
        for _, drawId in ipairs(option.DrawIdList) do
            local drawInfo = XDrawManager.GetDrawInfo(drawId)
            if drawInfo then
                tableInsert(list, drawInfo)
            end
        end
        return list
    end

    --- 判断 option 维度是否可自动打开狙击选择
    function XDrawManager.IsCanAutoOpenAimOptionSelect(time, optionKey)
        local data = XSaveTool.GetData(string.format("%d%s%s", XPlayer.Id, "AimAutoOpenOptionState", optionKey))
        if data then
            if time > data then
                XSaveTool.SaveData(string.format("%d%s%s", XPlayer.Id, "AimAutoOpenOptionState", optionKey), time)
                return true
            else
                return false
            end
        else
            XSaveTool.SaveData(string.format("%d%s%s", XPlayer.Id, "AimAutoOpenOptionState", optionKey), time)
            return true
        end
    end

    --- 获取 Option 名称
    function XDrawManager.GetOptionNameByKey(optionKey)
        local option = XDrawManager.GetDisplayOptionByKey(optionKey)
        if option then
            return option.Name
        end
        return ""
    end

    --- 检查 Option 维度是否为新
    function XDrawManager.CheckIsNewDrawForOption(optionKey)
        local groupId, _ = XDrawManager._ParseOptionKey(optionKey)
        return XDrawManager:CheckIsNewDraw(groupId)
    end
    --endregion

    --region ExtraOption：上次选中 OptionKey 记忆
    function XDrawManager.SetLostSelectOptionKey(optionKey)
        LostSelectOptionKey = optionKey or ""
    end

    function XDrawManager.GetLostSelectOptionKey()
        return LostSelectOptionKey
    end
    --endregion

    --region ExtraOption：DrawId 级特性判断
    --- 判断具体 Draw 是否为鬼泣卡池（draw级特性）
    function XDrawManager:CheckIsDevilMayCryDrawId(drawId)
        local drawInfo = XDrawManager.GetDrawInfo(drawId)
        if not drawInfo then
            return false
        end
        return XDrawManager:CheckIsDevilMayCryGroupId(drawInfo.GroupId)
    end
    --endregion

    function XDrawManager.GetDrawPurchase(drawId)
        local drawInfo = XDrawManager.GetDrawInfo(drawId)
        if not drawInfo then
            return {}
        end

        local purchaseIds = drawInfo.PurchaseId
        local drawPurchase = {}
        if purchaseIds and next(purchaseIds) then
            for _, purchaseId in ipairs(purchaseIds) do
                local purchaseData = XDataCenter.PurchaseManager.GetPurchaseDataById(purchaseId)
                if purchaseData then
                    tableInsert(drawPurchase, purchaseData)
                end
            end
        end

        return drawPurchase
    end
    
    --region ActivityTarget 狙击目标
    ---@return XDrawActivityTargetInfo
    function XDrawManager.GetDrawActivityTargetInfo(activityId)
        if _DrawActivityTargetInfoDir[activityId] and XTool.IsNumberValid(_DrawActivityTargetInfoDir[activityId]:GetTargetCount()) then
            return _DrawActivityTargetInfoDir[activityId]
        end
        return false
    end

    function XDrawManager.DebugActivityTargetInfo(groupId)
        if not XTool.IsNumberValid(groupId) then
            XLog.Error("[XUiDrawOptional]groupId为空.")
            return
        end
        local activityId = _DrawGroupActivityTargetDir[groupId]
        if not XTool.IsNumberValid(activityId) then
            XLog.Error("[XUiDrawOptional]活动Id为空.")
            return
        end
        local data = _DrawActivityTargetInfoDir[activityId]
        if not data then
            XLog.Error(string.format("[XUiDrawOptional]DrawActivityTargetInfoDir里找不到数据 activity=%s", activityId))
            return
        end
        if not XTool.IsNumberValid(data:GetTargetCount()) then
            XLog.Error(string.format("[XUiDrawOptional]AdjustTimes=%s TargetTimes=%s", data._AdjustTimes, data._TargetTimes))
            return
        end
    end

    ---@return number
    function XDrawManager.GetDrawActivityTargetIdByGroupId(groupId)
        return _DrawGroupActivityTargetDir[groupId]
    end

    ---@return XDrawActivityTargetInfo
    function XDrawManager.GetDrawGroupActivityTargetInfo(groupId)
        local activityId = _DrawGroupActivityTargetDir[groupId]
        if not activityId then
            return false
        end
        return XDrawManager.GetDrawActivityTargetInfo(activityId)
    end

    ---@return table
    function XDrawManager.GetDrawGroupActivityTargetInfoDir()
        return _DrawGroupActivityTargetDir
    end
    
    function XDrawManager._InitDrawGroupActivityTargetData()
        _DrawActivityTargetInfoDir = {}
        _DrawGroupActivityTargetDir = {}
    end
    
    ---更新指定抽奖校准
    function XDrawManager._UpdateDrawActivityTargetInfos(activityTargetInfoList)
        if XTool.IsTableEmpty(activityTargetInfoList) then
            return
        end
        XDrawManager._InitDrawGroupActivityTargetData()
        -- 保留并更新已有的
        for _, data in ipairs(activityTargetInfoList) do
            XDrawManager._TryToAddDrawActivityTargetInfo(data)
            _DrawActivityTargetInfoDir[data.ActivityId]:UpdateData(data)
        end
    end

    ---更新抽奖次数
    function XDrawManager._UpdateDrawActivityTimes(data)
        if XTool.IsTableEmpty(data) then
            return
        end
        -- 保留并更新已有的
        if _DrawActivityTargetInfoDir[data.ActivityId] then
            _DrawActivityTargetInfoDir[data.ActivityId]:SetTargetTimes(data.TargetTimes)
        end
    end

    ---@param infoList table
    function XDrawManager._UpdateDrawActivityStatus(infoList)
        if XTool.IsTableEmpty(infoList) then
            return
        end
        local tipType = 0
        local isHaveChange = false
        for _, data in ipairs(infoList) do
            if XTool.IsNumberValid(data.ActivityStatus) then
                if tipType < data.ActivityStatus then
                    tipType = data.ActivityStatus
                end
                if data.ActivityStatus == 2 then
                    XDrawManager._TryToRemoveDrawActivityTargetInfo(data)
                else
                    XDrawManager._TryToAddDrawActivityTargetInfo(data)
                end
                isHaveChange = true
            end
        end

        -- 如果不在抽卡相关界面不提示不踢回主界面
        if not XLuaUiManager.IsUiLoad("UiNewDrawMain") then
            return
        end
        -- 如果意外跳转其他ui直接踢回主界面
        if XLuaUiManager.IsUiShow("UiDrawLog") 
                or XLuaUiManager.IsUiShow("UiDrawOptional")
                or XLuaUiManager.IsUiShow("UiNewDrawMain")
                or XLuaUiManager.IsUiShow("UiDrawNew")
                or XLuaUiManager.IsUiShow("UiDrawShowNew")
        then
            if isHaveChange then
                XEventManager.DispatchEvent(XEventId.EVENT_DRAW_TARGET_ACTIVITY_CHANGE, tipType)
            end
            return
        end

        XLuaUiManager.RunMain()
        if tipType == XDrawConfigs.DrawTargetTipType.Open then
            XUiManager.TipErrorWithKey("DrawTargetActivityOpen")
        elseif tipType == XDrawConfigs.DrawTargetTipType.Close then
            XUiManager.TipErrorWithKey("DrawTargetActivityClose")
        elseif tipType == XDrawConfigs.DrawTargetTipType.Update then
            XUiManager.TipErrorWithKey("DrawTargetActivityUpdate")
        end
    end
    
    function XDrawManager._TryToAddDrawActivityTargetInfo(data)
        if XTool.IsNumberValid(data.ActivityId) and XTool.IsNumberValid(data.DrawGroupId) then
            -- 数据不存在则添加
            if not _DrawActivityTargetInfoDir[data.ActivityId] then
                _DrawActivityTargetInfoDir[data.ActivityId] = XDrawActivityTargetInfo.New()
                _DrawActivityTargetInfoDir[data.ActivityId]:UpdateData(data)
                _DrawGroupActivityTargetDir[data.DrawGroupId] = data.ActivityId
                return true
            end
            -- 数据存在则更新
            _DrawActivityTargetInfoDir[data.ActivityId]:UpdateData(data)
            _DrawGroupActivityTargetDir[data.DrawGroupId] = data.ActivityId
        end
        return false
    end

    function XDrawManager._TryToRemoveDrawActivityTargetInfo(data)
        if _DrawActivityTargetInfoDir[data.ActivityId] then
            _DrawActivityTargetInfoDir[data.ActivityId] = nil
        end
        if _DrawGroupActivityTargetDir[data.DrawGroupId] then
            _DrawGroupActivityTargetDir[data.DrawGroupId] = nil
        end
        return not _DrawGroupActivityTargetDir[data.DrawGroupId] and not _DrawActivityTargetInfoDir[data.ActivityId]
    end
    --endregion

    --region v2.14 活动新卡池

    function XDrawManager:CheckIsNewDraw(groupId)
        if not DrawNewGroupIds then
            DrawNewGroupIds = {}
            local ids = XDrawConfigs.GetDrawClientConfigs("DrawNewGroupIds")
            for _, v in pairs(ids) do
                DrawNewGroupIds[tonumber(v)] = true
            end
        end
        return DrawNewGroupIds[groupId]
    end

    function XDrawManager:CheckIsShowDiscount(groupId)
        if not DrawDiscountGroupIds then
            DrawDiscountGroupIds = {}
            local ids = XDrawConfigs.GetDrawClientConfigs("DrawDiscountGroupIds")
            for _, v in pairs(ids) do
                DrawDiscountGroupIds[tonumber(v)] = true
            end
        end
        return DrawDiscountGroupIds[groupId]
    end

    function XDrawManager:CheckIsDevilMayCryGroupId(groupId)
        if not DrawDevilMayCryGroupIds then
            DrawDevilMayCryGroupIds = {}
            local ids = XDrawConfigs.GetDrawClientConfigs("DrawDevilMayCryGroupIds")
            for _, v in pairs(ids) do
                DrawDevilMayCryGroupIds[tonumber(v)] = true
            end
        end
        return DrawDevilMayCryGroupIds[groupId]
    end

    function XDrawManager:CheckIsHideOptionalBtnGroupId(groupId)
        if not DrawHideOptionalBtnGroupIds then
            DrawHideOptionalBtnGroupIds = {}
            local ids = XDrawConfigs.GetDrawClientConfigs("DrawHideOptionalBtnGroupIds")
            if ids then
                for _, v in pairs(ids) do
                    DrawHideOptionalBtnGroupIds[tonumber(v)] = true
                end
            end
        end
        return DrawHideOptionalBtnGroupIds[groupId]
    end

    -- 可领次数，指立即点击按钮可领但是还没领的
    function XDrawManager:CheckIsCanReceiveCharacterByDrawId(drawId)
        local cfg = XDrawConfigs.GetDevilMayCryActivityCfgByDrawId(drawId)
        if not cfg then
            return
        end

        local taskGroupId = cfg.TaskGroupId
        local taskDataList = XDataCenter.TaskManager.GetTaskByTypeAndGroup(XDataCenter.TaskManager.TaskType.DevilMayCryDraw, taskGroupId)
        if XTool.IsTableEmpty(taskDataList) then
            return
        end
        
        local leftCount = 0 -- 剩余可领次数(已完成未领取)
        local taskList = {}
        for _, v in pairs(taskDataList) do
            if v.State == XDataCenter.TaskManager.TaskState.Achieved then
                leftCount = leftCount + 1
                table.insert(taskList, v.Id)
            end
        end

        return leftCount, taskList
    end

    -- 剩余次数，指还可以领取的次数，包括不能立即领取的和还没触发完成的
    function XDrawManager:GetLeftCanGetDevilCharacterCount(drawId)
        local cfg = XDrawConfigs.GetDevilMayCryActivityCfgByDrawId(drawId)
        if not cfg then
            return
        end

        local taskGroupId = cfg.TaskGroupId
        local taskDataList = XDataCenter.TaskManager.GetTaskByTypeAndGroup(XDataCenter.TaskManager.TaskType.DevilMayCryDraw, taskGroupId)
        if XTool.IsTableEmpty(taskDataList) then
            return
        end
        
        local leftCount = #taskDataList
        local taskList = {}
        for _, v in pairs(taskDataList) do
            if v.State == XDataCenter.TaskManager.TaskState.Finish then
                leftCount = leftCount - 1
                table.insert(taskList, v.Id)
            end
        end

        return leftCount, taskList
    end

    -- 刷新开启的鬼泣卡池
    function XDrawManager.UpdateDevilMayCryDraw(drawList)
        -- 清空OpenDevilMayCryDrawList
        for k, v in pairs(OpenDevilMayCryDrawList) do
            OpenDevilMayCryDrawList[k] = nil
        end

        for k, drawId in ipairs(drawList) do
            OpenDevilMayCryDrawList[drawId] = true
        end

        IsDevilMayCryDrawOpen = not XTool.IsTableEmpty(drawList)
    end

    function XDrawManager.GetIsDevilMayCryDrawOpen()
        return IsDevilMayCryDrawOpen
    end


    function XDrawManager.NotifyDrawCanLiverData(data)
        CanLiverActivityId = data.ActivityId
        CanLiverDrawCount = data.DrawCount or 0
        CanLiverRewardIndex = data.RewardIndex
        XEventManager.DispatchEvent(XEventId.EVENT_DRAW_CAN_LIVER_UPDATE)
    end

    function XDrawManager.GetCanLiverActivityId()
        return CanLiverActivityId
    end

    function XDrawManager.GetCanLiverDrawCount()
        return CanLiverDrawCount
    end

    function XDrawManager.GetCanLiverRewardIndex()
        return CanLiverRewardIndex
    end
    function XDrawManager.IsCanJourneyRewardGet(index)
        if not CanLiverRewardIndex then
            return false
        end

        -- 获取配置中的对应num
        local canLiverActivityId = XDrawManager.GetCanLiverActivityId()
        local config = XDrawConfigs.GetDrawCanLiverActivityCfgById(canLiverActivityId)
        if not config or not config.Schedules then
            return false
        end
        local num = config.Schedules[index]
        if not num then
            return false
        end

        return CanLiverDrawCount >= num and not table.contains(CanLiverRewardIndex, index - 1) -- RewardIndex是C#侧下标
    end

    function XDrawManager.IsJourneyRewardReceived(index)
        if not CanLiverRewardIndex then
            return false
        end
    
        -- RewardIndex 是 C# 的下标，所以要减 1
        return table.contains(CanLiverRewardIndex, index - 1)
    end

    -- 返回当前卡池中最小可领取奖励的index，没有则返回nil
    function XDrawManager.GetFirstCanJourneyRewardIndex()
        local canLiverActivityId = XDrawManager.GetCanLiverActivityId()
        if not canLiverActivityId then
            return nil
        end

        local config = XDrawConfigs.GetDrawCanLiverActivityCfgById(canLiverActivityId)
        if not config or not config.Schedules then
            return nil
        end

        for index, _ in ipairs(config.Schedules) do
            if XDrawManager.IsCanJourneyRewardGet(index) then
                return index
            end
        end
        return nil
    end

    -- 获取最近一个未领取奖励的index（无论是否可领，只要还没领）
    function XDrawManager.GetFirstUnGetJourneyRewardIndex()
        local canLiverActivityId = XDrawManager.GetCanLiverActivityId()
        if not canLiverActivityId then
            return nil
        end

        if not CanLiverRewardIndex then
            return nil
        end

        local config = XDrawConfigs.GetDrawCanLiverActivityCfgById(canLiverActivityId)
        if not config or not config.Schedules then
            return nil
        end

        for index, _ in ipairs(config.Schedules) do
            -- RewardIndex 是C#的下标
            if not table.contains(CanLiverRewardIndex, index - 1) then
                return index
            end
        end

        return nil
    end
    --endregion

    --region 标签折扣显示

    -- 检查是否显示十连抽折扣标签
    function XDrawManager.IsShowTagTenDiscount(groupId)
        local isDiscount, discountText = XDrawManager.CheckIsDiscountTenDraw(groupId, XDrawConfigs.DrawCountType.TenDraw)
        if isDiscount then
            return true, discountText
        end
        return false, ""
    end

    -- 主界面研发按钮是否显示折扣标签
    function XDrawManager.IsShowMainButtonDiscount()
        local drawGroupInfos = XDrawManager.GetDrawGroupInfos()
        for _, groupInfo in pairs(drawGroupInfos) do
            local isDiscount, _ = XDrawManager.CheckIsDiscountTenDraw(groupInfo.Id, XDrawConfigs.DrawCountType.TenDraw)
            if isDiscount then
                return true
            end
        end
        return false
    end

    --endregion

    --region 前X次十连抽打折功能

    local FULL_DISCOUNT = 100 -- 不打折的百分比

    -- 检查下一次十连抽是否打折
    ---@return boolean, string 是否打折, 折扣信息
    function XDrawManager.CheckIsDiscountTenDraw(groupId, drawCount)
        if drawCount ~= XDrawConfigs.DrawCountType.TenDraw then
            return false, ""
        end

        local discount = XDrawManager.GetTenDrawDiscount(groupId)
        return discount < FULL_DISCOUNT, XUiHelper.GetDiscountTextV3(discount)
    end

    -- 获取当前十连抽已使用的折扣次数和最大折扣次数
    function XDrawManager.GetTenDrawDiscountCount(groupId)
        local groupInfo = XDrawManager.GetDrawGroupInfoByGroupId(groupId)
        if not groupInfo or not groupInfo.TenDrawOnSales then
            return 0, 0
        end

        local useCount = groupInfo.UseTenDrawOnSaleTimes or 0
        local maxCount = #groupInfo.TenDrawOnSales
        return useCount, maxCount
    end

    -- 获取下一次十连抽折扣 -> 百分比，返回100表示不打折
    function XDrawManager.GetTenDrawDiscount(groupId)
        local groupInfo = XDrawManager.GetDrawGroupInfoByGroupId(groupId)
        local tenDrawOnSales = groupInfo and groupInfo.TenDrawOnSales
        if not tenDrawOnSales then
            return FULL_DISCOUNT
        end

        local nextCount = (groupInfo.UseTenDrawOnSaleTimes or 0) + 1
        return tenDrawOnSales[nextCount] or FULL_DISCOUNT
    end

    -- 获取折扣后的价格
    function XDrawManager.GetDiscountDrawPrice(groupId, useItemCount, drawCount)
        if drawCount == XDrawConfigs.DrawCountType.OneDraw then
            return useItemCount
        elseif drawCount == XDrawConfigs.DrawCountType.TenDraw then
            local discount = XDrawManager.GetTenDrawDiscount(groupId)
            if discount >= FULL_DISCOUNT then
                return useItemCount * drawCount
            end
            return math.floor(useItemCount * drawCount * discount / FULL_DISCOUNT)
        end
        return useItemCount * drawCount
    end

    --endregion

    --region ServerDataUpdate
    function XDrawManager.UpdateDrawGroupInfos(groupInfoList)
        DrawGroupInfos = {}

        local isExpired = true

        for _, info in pairs(groupInfoList) do
            -- 归一化 UseDrawIdDict 的 key 为 number，防止反序列化产生 string key
            if info.UseDrawIdDict then
                local normalized = {}
                for k, v in pairs(info.UseDrawIdDict) do
                    normalized[tonumber(k)] = v
                end
                info.UseDrawIdDict = normalized
            end
            DrawGroupInfos[info.Id] = info
            DrawGroupInfos[info.Id].BottomTimes = DrawGroupInfos[info.Id].MaxBottomTimes - DrawGroupInfos[info.Id].BottomTimes
            if CurSelectTabInfo then
                if info.Id == CurSelectTabInfo.Id then
                    isExpired = false
                end
            end
        end

        if isExpired then
            CurSelectTabInfo = nil
        end

        -- group 信息整体刷新后失效所有 DisplayOption 缓存
        XDrawManager._InvalidateAllDisplayOptionCache()
    end

    function XDrawManager.UpdateDrawInfos(drawInfoList)
        --每次更新一组info之前清空之前相同GroupId的信息
        local deleteKey = {}
        for k, v in pairs(DrawInfos) do
            if v.GroupId == drawInfoList[1].GroupId then
                deleteKey[k] = true
            end
        end
        for k, _ in pairs(deleteKey) do
            DrawInfos[k] = nil
        end

        for _, info in pairs(drawInfoList) do
            XDrawManager.UpdateDrawInfo(info)
        end

        -- DrawInfo 更新后失效对应 group 的 DisplayOption 缓存
        if drawInfoList[1] then
            XDrawManager._InvalidateDisplayOptionCacheForGroup(drawInfoList[1].GroupId)
        end
    end

    function XDrawManager.UpdateDrawInfo(drawInfo)
        DrawInfos[drawInfo.Id] = XTool.Clone(drawInfo)
        DrawInfos[drawInfo.Id].BottomTimes = DrawInfos[drawInfo.Id].MaxBottomTimes - DrawInfos[drawInfo.Id].BottomTimes
    end
    
    --- ticketInfo
    --- Id 
    --- CfgId 
    --- ExpireTime 
    --- Count
    function XDrawManager.UpdateDrawTicket(data, isClear)
        if isClear then
            FreeDrawTicket = {}
        end
        for _, ticketInfo in pairs(data) do
            FreeDrawTicket[ticketInfo.Id] = ticketInfo
        end
        XEventManager.DispatchEvent(XEventId.EVENT_DRAW_FREE_TICKET_UPDATE)
    end
    --endregion
    
    --region Proto
    -- 查询相关end --
    -- 消息相关begin --
    function XDrawManager.GetDrawInfoList(groupId, cb, IsNotDoCoolDown)
        local now = XTime.GetServerNowTimestamp()
        if LastGetDropInfoTimes[groupId] and now - LastGetDropInfoTimes[groupId] <= GET_DRAW_DATA_INTERVAL and not IsNotDoCoolDown then
            if cb then
                cb()
            end
            return
        end
        XNetwork.Call("DrawGetDrawInfoListRequest", { GroupId = groupId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if cb then
                    cb()
                end
                return
            end
            XDrawManager.UpdateDrawInfos(res.DrawInfoList)
            LastGetDropInfoTimes[groupId] = now
            if cb then
                cb()
            end
        end)
    end
    
    function XDrawManager.GetDrawGroupList(cb)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DrawCard) then
            return
        end

        local now = XTime.GetServerNowTimestamp()
        if now - LastGetGroupInfoTime <= GET_DRAW_DATA_INTERVAL then
            if cb then
                cb()
            end
            return
        end
        XNetwork.Call("DrawGetDrawGroupListRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDrawManager.UpdateDrawGroupInfos(res.DrawGroupInfoList)
            XDrawManager._UpdateDrawActivityTargetInfos(res.DrawAdjustActivityInfoList)
            LastGetGroupInfoTime = now
            if cb then
                cb()
            end
        end)
    end

    function XDrawManager.DrawCard(drawId, count, freeTicketId, cb)
        XDataCenter.KickOutManager.Lock(XEnumConst.KICK_OUT.LOCK.DRAW)
        XNetwork.Call("DrawDrawCardRequest", { DrawId = drawId, Count = count, UseDrawTicketId = freeTicketId }, function(res)
            if res.Code ~= XCode.Success then
                XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.DRAW, true)
                XUiManager.TipCode(res.Code)
                return
            end
            XDrawManager.UpdateDrawInfo(res.ClientDrawInfo)
            XDrawManager.UpdateDrawGroupByInfo(res.ClientDrawInfo)
            XDrawManager._UpdateDrawActivityTimes(res.DrawAdjustData)
            local drawInfo = XDrawManager.GetDrawInfo(res.ClientDrawInfo.Id)
            if cb then
                cb(drawInfo, res.RewardGoodsList, res.ExtraRewardList)
            else
                XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.DRAW, true)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_PGS_DRAW_RESULT, drawId, count, res.RewardGoodsList)
        end)
    end

    function XDrawManager.SaveDrawAimId(drawId, groupId, cb, groupSubtype)
        --保存狙击目标
        XNetwork.Call("DrawSetUseDrawIdRequest", { DrawId = drawId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local groupInfo = XDrawManager.GetDrawGroupInfoByGroupId(groupId)
            -- 统一更新 UseDrawIdDict（服务端已废弃 UseDrawId）
            local useDrawIdDict = groupInfo.UseDrawIdDict or {}
            local subtype = (groupSubtype and groupSubtype > 0) and groupSubtype or 0
            useDrawIdDict[subtype] = drawId
            groupInfo.UseDrawIdDict = useDrawIdDict
            groupInfo.SwitchDrawIdCount = res.SwitchDrawIdCount
            -- 失效该 group 的 DisplayOption 缓存
            XDrawManager._InvalidateDisplayOptionCacheForGroup(groupId)
            if cb then
                cb()
            end
        end)
    end
    
    function XDrawManager.RequestSelectTargetActivity(activityId, targetId, cb)
        local reqBody = {
            ActivityId = activityId;
            TargetId = targetId;
        }
        XNetwork.Call("DrawAdjustTargetRequest", reqBody, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDrawManager.GetDrawActivityTargetInfo(activityId):SetTargetId(targetId)
            if cb then
                cb()
            end
        end)
    end
    
    --- 获取指定卡池组的历史记录
    function XDrawManager.RequestDrawGroupGetHistory(groupId, groupSubType, successCb, errorCb)
        -- 兼容旧调用：第二个参数如果是 function 说明没传 groupSubType
        if type(groupSubType) == "function" then
            errorCb = successCb
            successCb = groupSubType
            groupSubType = 0
        end
        -- 始终发送 GroupSubType（含 0），服务端按 HistoryRewardDict[GroupSubType] 查询
        XNetwork.Call("DrawGroupGetHistoryRequest", {
            GroupId = groupId,
            GroupSubType = groupSubType or 0
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if errorCb then
                    errorCb()
                end
                return
            end

            if successCb then
                successCb(res)
            end
        end)
    end
    
    --- 获取开放记录抽卡组列表
    function XDrawManager.RequestDrawGetHistoryGroupList(successCb, errorCb)
        XNetwork.Call("DrawGetHistoryGroupListRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)

                if errorCb then
                    errorCb()
                end
                return
            end

            if successCb then
                successCb(res.HistoryGroups)
            end
        end)
    end

    -- 可肝卡池的奖励领取
    function XDrawManager.DrawCanLiverRewardRequest(cb)
        XNetwork.Call("DrawCanLiverRewardRequest", {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            CanLiverRewardIndex = XTool.MergeArray(CanLiverRewardIndex, res.RewardIndexSet)

            if cb then
                cb(res.RewardGoodsList)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_DRAW_CAN_LIVER_UPDATE)
        end)
    end
    --endregion

    function XDrawManager.CheckIsShowOptionDraw(drawGroupRuleId)
        local ids = XDrawConfigs.GetDrawClientConfigs("NotShowChooseDrawGroupRuleId")

        for _, id in pairs(ids) do
            if tonumber(id) == drawGroupRuleId then
                return false
            end
        end

        return true
    end

    -- WindEnd --

    --- 从奖励信息中提取物品ID（优先级：ConvertFrom > Id > TemplateId）
    function XDrawManager.GetRewardGoodsId(rewardInfo)
        if not rewardInfo then
            return nil
        end
        if rewardInfo.ConvertFrom and rewardInfo.ConvertFrom > 0 then
            return rewardInfo.ConvertFrom
        end
        if rewardInfo.Id and rewardInfo.Id > 0 then
            return rewardInfo.Id
        end
        return rewardInfo.TemplateId
    end

    --- 判断指定奖励是否有角色表演配置（S角色）
    function XDrawManager.CheckHasPerformance(rewardInfo)
        local id = XDrawManager.GetRewardGoodsId(rewardInfo)
        if not XTool.IsNumberValid(id) then
            return false
        end
        if XTypeManager.GetTypeById(id) ~= XArrangeConfigs.Types.Character then
            return false
        end
        return XDrawConfigs.GetDrawRolePerformance(id) ~= nil
    end

    XDrawManager.Init()
    return XDrawManager
end

XRpc.NotifyActivityDrawGroupCount = function(data)
    XDataCenter.DrawManager.UpdateDrawActivityCount(data.Count)
    XEventManager.DispatchEvent(XEventId.EVENT_DRAW_ACTIVITYCOUNT_CHANGE)
end

XRpc.NotifyActivityDrawList = function(data)
    XDataCenter.DrawManager.UpdateActivityDrawList(data.DrawIdList)
    XDataCenter.DrawManager.SetNewActivityDraw(data.DrawIdList)
    XDataCenter.DrawManager.UnMarkOldActivityDraw(data.DrawIdList)
    XEventManager.DispatchEvent(XEventId.EVENT_DRAW_ACTIVITYDRAW_CHANGE)
end

XRpc.NotifyDrawTicketData = function(data)
    XDataCenter.DrawManager.UpdateDrawTicket(data.DrawTicketInfos, true)
end

XRpc.NotifyUpdateDrawTicketData = function(data)
    XDataCenter.DrawManager.UpdateDrawTicket({ data.DrawTicketInfo }, false)
end

---刷新抽卡狙击瞄准规则
XRpc.NotifyDrawAdjustActivity = function(data)
    XDataCenter.DrawManager._UpdateDrawActivityStatus(data.DrawAdjustActivityInfoList)
end

XRpc.NotifyDevilMayCryDraw = function(data)
    XDataCenter.DrawManager.UpdateDevilMayCryDraw(data.OpenDraws)
end

XRpc.NotifyDrawCanLiverData = function(data)
    XDataCenter.DrawManager.NotifyDrawCanLiverData(data.DrawCanLiverData)
end
