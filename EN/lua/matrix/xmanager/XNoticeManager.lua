local tableInsert = table.insert

XNoticeManagerCreator = function()
    local Json = require("XCommon/Json")
    local pcall = pcall
    ---@class XNoticeManager
    local XNoticeManager = {}

    local NoticePicList = {}

    local NowTextNotice = nil
    local NowPicNotice = nil
    local NowPcNotice = {}

    local InGameNoticeReadList = {}
    local InGameNoticeMap = {}
    local InGameNoticeReadKey = "_InGameNoticeReadKey"
    
    -- 服务端已读记录（用于判断蓝点）
    -- key: noticeId_modifyTime, value: true
    local _ServerGameNoticeRecords = {}
    
    -- 是否已执行首次同步
    local _HasSyncedGameNoticeToServer = false
    
    -- 公告同步队列（使用 serverKey 作为唯一标识）
    local _SyncQueue = {}
    -- 同步队列定时器
    local _SyncQueueTimer = nil
    -- 同步队列发送间隔（秒）
    local SYNC_QUEUE_INTERVAL = 1
    local InGameAutoPopupMap
    local PreloadNotice = nil --预下载公告
    
    -- 是否已执行本次登录的第一次请求清理
    local _HasCleanedOnFirstRequest = false

    local SubMenuNoticeReadList = {}
    local SubMenuNoticeMap = {}
    local SubMenuNoticeReadKey = "_SubMenuNoticeReadKey"

    local ScrollCountList = {}
    local ScrollCountSaveKey = "_NoticeScrollCountList"
    
    -- 复用table，减少 GC 压力（用于字符串拼接）
    local _TempKeyParts2 = {}  -- 用于 GetTextNoticeKey（2个元素）
    local _TempKeyParts3 = {}  -- 用于 GetGameNoticeReadDataKey（3个元素）

    local LoginNotice = nil
    local LoginNoticeTimeInfo = {}
    local LoginNoticeCacheKey = "LoginNotice"

    local TextNoticeHideCache = {}
    local TextNoticeHideCacheKey = "_TextNotice"

    ---@type XPopUpPicNotice
    local NowPopUpPicNotice
    -- 每次登录类型的展示记录（本次登录有效）
    local PopUpPicShownPerLogin = {}
    -- 拍脸图弹出队列与当前索引
    local PopUpPicQueue = {}
    local PopUpPicQueueIndex = 0
    -- 拍脸图弹出时机枚举（对应 XPopUpPicNoticeContent.AppearanceType）
    local PopUpPicAppearanceType = {
        EachLogin = 1, -- 每次登录弹出
        EachDay = 2, -- 每天首次登录弹出
    }

    local LoginNoticAutoOpenKey = "_LoginNoticeNotOpenKey"
    ------------------------------------------------------
    local NoticeRequestTimer = nil
    -- 向服务端请求数据的最小间隔周期（秒）
    local NoticeRequestTimerInterval = 10
    local NoticeRequestTimeOut = 30
    local DefaultTextScrollInterval = 10

    local ScreenShotFlag = false
    local DisableFunction = false    --功能屏蔽标记（调试模式时使用）

    local XNoticeType = {
        -- 顶部文字滚动公告
        ScrollText = 0,
        -- 主界面广告图
        ScrollPic = 1,
        -- 游戏内公告
        InGame = 2,
        -- 登陆公告
        Login = 3,
        -- 主界面二级菜单
        SubMenu = 4,
        -- 拍脸图公告
        PopUpPic = 5,
    }
    
    XNoticeManager.NoticeType = XNoticeType

    --游戏内公告类型
    local InGameNoticeType = {
        --活动
        Activity = 0,
        --游戏
        Game = 1,
        --外部链接
        Link = 2
    }

    XNoticeManager.GameNoticeType = InGameNoticeType

    -- 自动向服务端请求数据的间隔周期（秒）
    local RequestInterval = {
        [XNoticeType.ScrollText] = 30,
        [XNoticeType.ScrollPic] = 60,
        [XNoticeType.InGame] = 120,
        -- [XNoticeType.Login] = 0, Login公告有独立的处理逻辑，不应该在定时器中请求
        [XNoticeType.SubMenu] = 120,
        [XNoticeType.PopUpPic] = 120,
    }

    local LastRequestTime = {
        [XNoticeType.ScrollText] = 0,
        [XNoticeType.ScrollPic] = 0,
        [XNoticeType.InGame] = 0,
        [XNoticeType.SubMenu] = 0,
        [XNoticeType.PopUpPic] = 0,
    }

    local NoticeRequestHandler = {
        [XNoticeType.ScrollText] = function(notice)
            XNoticeManager.HandleRequestScrollTextNotice(notice)
        end,
        [XNoticeType.ScrollPic] = function(notice)
            XNoticeManager.HandleRequestScrollPicNotice(notice)
        end,
        [XNoticeType.InGame] = function(notice)
            XNoticeManager.HandleRequestInGameNotice(notice)
        end,
        [XNoticeType.SubMenu] = function(notice)
            XNoticeManager.HandleRequestSubMenuNotice(notice)
        end,
        [XNoticeType.PopUpPic] = function(notice)
            XNoticeManager.HandleRequestPopUpPicNotice(notice)
        end,
    }

    local NoticeRequestFailHandler = {
        [XNoticeType.ScrollText] = function()
            XNoticeManager.HandleRequestScrollTextNotice()
        end,
        [XNoticeType.ScrollPic] = function()
            XNoticeManager.HandleRequestScrollPicNoticeFail()
        end,
        [XNoticeType.InGame] = function()
            XNoticeManager.HandleRequestInGameNotice()
        end,
        [XNoticeType.SubMenu] = function()
            XNoticeManager.HandleRequestSubMenuNotice()
        end,
        [XNoticeType.PopUpPic] = function()
            XNoticeManager.HandleRequestPopUpPicNotice()
        end,
    }

    local IsCheckOutDateClear
    ----------------------------------初始化公告cdn路径 beg----------------------------------
    local NoticeCdnUrl = {}
    local NoticeFileName = {
        [XNoticeType.ScrollText] = "ScrollTextNotice.json",
        [XNoticeType.ScrollPic] = "ScrollPicNotice.json",
        [XNoticeType.InGame] = "GameNotice.json",
        [XNoticeType.Login] = "LoginNotice.json",
        [XNoticeType.SubMenu] = "SecondMenuNotice.json",
        [XNoticeType.PopUpPic] = "PopUpPicNotice.json",
    }

    function XNoticeManager.GetNoticeUrl(noticeType)
        return NoticeCdnUrl[noticeType]
    end

    function XNoticeManager.InitNoticeCdnUrl()
        local cdnKey = CS.XInfo.CDNKey
        local isEmptyCdnKey = string.IsNilOrEmpty(cdnKey)
        local noticePathPrefix = CS.XGame.ClientConfig:GetString("NoticePathPrefix")
        for k, v in pairs(NoticeFileName) do
            if isEmptyCdnKey then
                NoticeCdnUrl[k] = string.format("%s%s/%s/%s", noticePathPrefix, CS.XInfo.Identifier, CS.XRemoteConfig.ApplicationVersion, v)
            else
                NoticeCdnUrl[k] = string.format("%s%s/%s/%s/%s", noticePathPrefix, cdnKey, CS.XInfo.Identifier, CS.XRemoteConfig.ApplicationVersion, v)
            end
        end
    end
    ----------------------------------初始化公告cdn路径 end----------------------------------
    ----------------------------------获取公网ip地址 beg----------------------------------
    local Ip = ""
    local IpUrlIndex = 0
    local IpUrls = {
        "http://icanhazip.com/",
        "http://ifconfig.me/ip",
        "http://ifconfig.co/ip",
        "http://inet-ip.info/ip"
    }
    
    function XNoticeManager.RequestIp()
        if XOverseaManager.IsOverSeaRegion() then
            if XOverseaManager.IsTWRegion() then
                IpUrls = {
                "https://api.ipify.org/",
                "http://ipv4.icanhazip.com/"
                }
            else
                IpUrls = {
                "https://ipv4.icanhazip.com/",
                "https://api.ipify.org/"
                }
            end
        end
        IpUrlIndex = IpUrlIndex + 1
        if IpUrlIndex > #IpUrls then
            return
        end

        local request = CS.UnityEngine.Networking.UnityWebRequest.Get(IpUrls[IpUrlIndex])
        local requestEnd = function()
            if request.isNetworkError or request.isHttpError then
                XNoticeManager.RequestIp()
            end

            Ip = request.downloadHandler.text

            request:Dispose()
        end

        CS.XTool.WaitNativeCoroutine(request:SendWebRequest(), requestEnd)
    end

    function XNoticeManager.GetIp()
        return Ip
    end
    ----------------------------------获取公网ip地址 end----------------------------------
    --------------------------cache beg--------------------------
    function XNoticeManager.ReadTextNoticeHideCache()
        local cache = CS.UnityEngine.PlayerPrefs.GetString(tostring(XPlayer.Id) .. TextNoticeHideCacheKey)
        if string.IsNilOrEmpty(cache) then
            return
        end

        TextNoticeHideCache = Json.decode(cache)

        for k, v in pairs(TextNoticeHideCache) do
            if XTime.GetServerNowTimestamp() > v.EndTime then
                TextNoticeHideCache[k] = nil
            end
        end

    end

    function XNoticeManager.SaveTextNoticeHideCache()
        if not TextNoticeHideCache then
            return
        end

        CS.UnityEngine.PlayerPrefs.SetString(tostring(XPlayer.Id) .. TextNoticeHideCacheKey, Json.encode(TextNoticeHideCache))
        CS.UnityEngine.PlayerPrefs.Save()
    end

    function XNoticeManager.GetInGameNoticeReadKey()
        local key = XPlayer.Id and XPlayer.Id or "NotLoggedIn"
        return key .. InGameNoticeReadKey
    end

    -- v4.2 从4.2版本开始, 公告红点的数据保存到服务端, 此函数已废弃
    -- function XNoticeManager.SaveInGameNoticeReadList()
    --     if not InGameNoticeReadList then
    --         return
    --     end

    --     local saveContent = ""
    --     local splitMark = "\n"
    --     for _, v in pairs(InGameNoticeReadList) do
    --         local list = {}
    --         tableInsert(list, v.Id)
    --         tableInsert(list, v.Index)
    --         tableInsert(list, (v.IsRead and 1 or 0))
    --         tableInsert(list, v.EndTime)
    --         tableInsert(list, v.ModifyTime)

    --         local tempStr = table.concat(list, "\t")
    --         saveContent = string.format("%s%s%s", tempStr, splitMark, saveContent)
    --     end

    --     CS.UnityEngine.PlayerPrefs.SetString(XNoticeManager.GetInGameNoticeReadKey(), saveContent)
    --     CS.UnityEngine.PlayerPrefs.Save()

    --     XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_NOTICE_READ_CHANGE)
    -- end
    
    ---初始化服务端游戏公告已读记录
    ---@param gameNoticeRecords table 服务端返回的已读记录 {GameNoticeInfos = {{NoticeId = string, ModifyTime = int, EndTime = int}}}
    function XNoticeManager.InitGameNoticeRecordsFromServer(gameNoticeRecords)
        _ServerGameNoticeRecords = {}
        
        if not gameNoticeRecords or not gameNoticeRecords.GameNoticeInfos then
            return
        end
        
        -- 存储服务端已读记录（key: noticeId_modifyTime）
        for _, serverRecord in ipairs(gameNoticeRecords.GameNoticeInfos) do
            local noticeId = serverRecord.NoticeId
            local modifyTime = serverRecord.ModifyTime
            -- 服务端增加EndTime字段, 但是客户端暂时没有处理
            -- local endTime = serverRecord.EndTime
            local serverKey = string.format("%s_%s", noticeId or "", tostring(modifyTime or ""))
            _ServerGameNoticeRecords[serverKey] = true
        end
        
        -- 如果 InGameNoticeReadList 已存在，立即更新已读状态
        if InGameNoticeReadList then
            for dataKey, readInfo in pairs(InGameNoticeReadList) do
                local serverKey = string.format("%s_%s", readInfo.Id or "", tostring(readInfo.ModifyTime or ""))
                if _ServerGameNoticeRecords[serverKey] then
                    readInfo.IsRead = true
                end
            end
        end
        
        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_NOTICE_READ_CHANGE)
    end
    
    ---将公告加入同步队列
    ---@param serverKey string 服务端记录key
    ---@param noticeId string 公告ID
    ---@param modifyTime number 修改时间
    ---@param endTime number 结束时间
    local function AddToSyncQueue(serverKey, noticeId, modifyTime, endTime)
        -- 如果已经在队列中，不需要重复添加
        if _SyncQueue[serverKey] then
            return
        end
        
        -- 加入队列
        _SyncQueue[serverKey] = {
            NoticeId = noticeId,
            ModifyTime = modifyTime,
            EndTime = endTime
        }
        
        -- 启动定时器
        if not _SyncQueueTimer then
            _SyncQueueTimer = XScheduleManager.ScheduleForever(function()
                XNoticeManager.FlushSyncQueue()
            end, SYNC_QUEUE_INTERVAL * 1000)
        end
    end
    
    ---刷新同步队列，发送所有待同步的公告
    function XNoticeManager.FlushSyncQueue()
        if not _SyncQueue or not next(_SyncQueue) then
            -- 队列为空，停止定时器
            if _SyncQueueTimer then
                XScheduleManager.UnSchedule(_SyncQueueTimer)
                _SyncQueueTimer = nil
            end
            return
        end
        
        -- 在同步前清理过期已读公告
        XNoticeManager.CleanExpiredReadNotices()
        
        -- 收集队列中的所有公告
        local gameNoticeInfos = {}
        for serverKey, info in pairs(_SyncQueue) do
            table.insert(gameNoticeInfos, {
                NoticeId = info.NoticeId,
                ModifyTime = info.ModifyTime,
                EndTime = info.EndTime
            })
        end
        
        -- 清空队列
        _SyncQueue = {}
        
        -- 停止定时器
        if _SyncQueueTimer then
            XScheduleManager.UnSchedule(_SyncQueueTimer)
            _SyncQueueTimer = nil
        end
        
        -- 构造请求
        local req = {
            GameNoticeInfos = gameNoticeInfos
        }
        
        -- 发送到服务端
        XNetwork.Call("SyncReadGameNoticeRequest", req, function(res)
            if res.Code == XCode.Success then
                -- 同步成功，更新服务端记录缓存
                for _, info in ipairs(gameNoticeInfos) do
                    local serverKey = string.format("%s_%s", info.NoticeId, tostring(info.ModifyTime))
                    _ServerGameNoticeRecords[serverKey] = true
                end
            end
        end)
    end
    
    ---同步单个公告已读到服务端（加入队列，延迟发送）
    ---因为TabBtnList可以连续触发, 如果立即发送, 会引发服务端cd报错
    ---@param dataKey string 公告数据key
    function XNoticeManager.SyncGameNoticeReadToServer(dataKey)
        if not InGameNoticeReadList or not InGameNoticeReadList[dataKey] then
            return
        end
        
        local readInfo = InGameNoticeReadList[dataKey]
        if not readInfo.IsRead then
            return
        end
        
        -- 只同步未过期的公告
        if readInfo.EndTime <= XTime.GetServerNowTimestamp() then
            return
        end
        
        -- 检查是否正在首次同步中，如果是则等待首次同步完成（避免重复发送）
        if not _HasSyncedGameNoticeToServer then
            -- 首次同步还未完成，等待首次同步完成后再发送
            -- 首次同步会一次性发送所有已读公告，包括这个公告
            return
        end
        
        -- 检查是否已经同步过（避免重复发送）
        local serverKey = string.format("%s_%s", readInfo.Id, tostring(readInfo.ModifyTime))
        if _ServerGameNoticeRecords[serverKey] then
            -- 已经同步过，不需要再次发送
            return
        end
        
        -- 立即更新缓存，避免重复加入队列
        _ServerGameNoticeRecords[serverKey] = true
        
        -- 加入同步队列，延迟发送
        AddToSyncQueue(serverKey, readInfo.Id, readInfo.ModifyTime, readInfo.EndTime)
    end
    
    ---首次同步本地已读公告到服务端
    ---触发条件：版本更新后首次打开公告界面时
    function XNoticeManager.TryFirstSyncGameNoticeRead()
        if _HasSyncedGameNoticeToServer then
            return
        end
        
        -- 在同步前清理过期已读公告
        XNoticeManager.CleanExpiredReadNotices()
        
        if not InGameNoticeReadList then
            _HasSyncedGameNoticeToServer = true
            return
        end
        
        -- 收集已读且未过期的公告，但排除已经同步过的（避免重复发送）
        -- 使用 noticeId_modifyTime 作为唯一标识，避免同一个公告的多个 Content 项重复发送
        local seenKeys = {}
        local gameNoticeInfos = {}
        for dataKey, readInfo in pairs(InGameNoticeReadList) do
            if readInfo.IsRead and readInfo.EndTime > XTime.GetServerNowTimestamp() then
                local serverKey = string.format("%s_%s", readInfo.Id, tostring(readInfo.ModifyTime))
                -- 检查是否已经同步过或已经在待同步列表中
                if not _ServerGameNoticeRecords[serverKey] and not seenKeys[serverKey] then
                    -- 还没有同步过，加入待同步列表
                    table.insert(gameNoticeInfos, {
                        NoticeId = readInfo.Id,
                        ModifyTime = readInfo.ModifyTime,
                        EndTime = readInfo.EndTime
                    })
                    -- 标记已处理，避免重复
                    seenKeys[serverKey] = true
                    -- 立即更新缓存，避免在请求发送期间重复发送
                    _ServerGameNoticeRecords[serverKey] = true
                end
            end
        end
        
        if #gameNoticeInfos == 0 then
            _HasSyncedGameNoticeToServer = true
            return
        end
        
        -- 构造请求
        local req = {
            GameNoticeInfos = gameNoticeInfos
        }
        
        -- 发送到服务端
        XNetwork.Call("SyncReadGameNoticeRequest", req, function(res)
            if res.Code == XCode.Success then
                -- 同步成功，标记已同步
                _HasSyncedGameNoticeToServer = true
                -- 缓存已经在发送前更新，这里不需要再次更新
            else
                -- 如果同步失败，回滚缓存，允许下次重试
                for _, info in ipairs(gameNoticeInfos) do
                    local serverKey = string.format("%s_%s", info.NoticeId, tostring(info.ModifyTime))
                    _ServerGameNoticeRecords[serverKey] = nil
                end
                -- 不设置 _HasSyncedGameNoticeToServer = true，允许下次重试
            end
        end)
    end

    function XNoticeManager.ReadInGameNoticeReadList()
        InGameNoticeReadList = {}
        if not CS.UnityEngine.PlayerPrefs.HasKey(XNoticeManager.GetInGameNoticeReadKey()) then
            return
        end

        local dataStr = CS.UnityEngine.PlayerPrefs.GetString(XNoticeManager.GetInGameNoticeReadKey())

        local msgTab = string.Split(dataStr, '\n')
        if not msgTab or #msgTab <= 0 then
            return
        end

        for _, content in ipairs(msgTab) do
            if (not string.IsNilOrEmpty(content)) then
                local tab = string.Split(content, '\t')
                if tab then
                    local readInfo = {
                        Id = tostring(tab[1]),
                        Index = tonumber(tab[2]),
                        IsRead = (tonumber(tab[3]) or 0) > 0,
                        EndTime = tonumber(tab[4]),
                        ModifyTime = tonumber(tab[5]),
                    }
                    if readInfo.IsRead == nil then
                        readInfo.IsRead = false
                    end
                    if readInfo.ModifyTime and readInfo.EndTime and readInfo.EndTime > XTime.GetServerNowTimestamp() then
                        local dataKey = XNoticeManager.GetGameNoticeReadDataKey(readInfo, readInfo.Index)
                        InGameNoticeReadList[dataKey] = readInfo
                    end
                end
            end
        end
    end
    
    function XNoticeManager.GetInGameNoticeAutoPopupKey(noticeId, modifyTime)
        return string.format("%s_%s", noticeId, tostring(modifyTime))
    end
    
    function XNoticeManager.GetInGameNoticeAutoMap()
        if not InGameAutoPopupMap then
            local key = "XNoticeManager.GetInGameNoticeAutoMap_InGameNoticeAutoMap"
            InGameAutoPopupMap = XSaveTool.GetData(key) or {}
        end
        return InGameAutoPopupMap
    end

    function XNoticeManager.MarkInGameNoticeAutoMap(noticeId, modifyTime)
        InGameAutoPopupMap = XNoticeManager.GetInGameNoticeAutoMap()
        local noticeKey = XNoticeManager.GetInGameNoticeAutoPopupKey(noticeId, modifyTime)
        InGameAutoPopupMap[noticeKey] = true

        local key = "XNoticeManager.GetInGameNoticeAutoMap_InGameNoticeAutoMap"
        XSaveTool.SaveData(key, InGameAutoPopupMap)
    end

    function XNoticeManager.GetSubMenuNoticeReadKey()
        return tostring(XPlayer.Id) .. SubMenuNoticeReadKey
    end

    function XNoticeManager.SaveSubMenuNoticeReadList()
        if not SubMenuNoticeReadList then
            return
        end

        local saveContent = ""
        local splitMark = "\n"
        for _, v in pairs(SubMenuNoticeReadList) do
            local list = {}
            tableInsert(list, v.Id)
            tableInsert(list, v.EndTime)
            tableInsert(list, v.TipResetTime)
            tableInsert(list, v.LastReadTime)

            local tempStr = table.concat(list, "\t")
            saveContent = string.format("%s%s%s", tempStr, splitMark, saveContent)
        end
        -- XLog.Warning("save",saveContent)
        CS.UnityEngine.PlayerPrefs.SetString(XNoticeManager.GetSubMenuNoticeReadKey(), saveContent)
        CS.UnityEngine.PlayerPrefs.Save()

        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_SUBMENU_READ_CHANGE)
    end

    function XNoticeManager.ReadSubMenuNoticeReadList()
        SubMenuNoticeReadList = {}
        if not CS.UnityEngine.PlayerPrefs.HasKey(XNoticeManager.GetSubMenuNoticeReadKey()) then
            return
        end

        local dataStr = CS.UnityEngine.PlayerPrefs.GetString(XNoticeManager.GetSubMenuNoticeReadKey())

        local msgTab = string.Split(dataStr, '\n')
        if not msgTab or #msgTab <= 0 then
            return
        end

        for _, content in ipairs(msgTab) do
            if (not string.IsNilOrEmpty(content)) then
                local tab = string.Split(content, '\t')
                if tab then
                    local readInfo = {
                        Id = tostring(tab[1]),
                        EndTime = tonumber(tab[2]),
                        TipResetTime = tonumber(tab[3]),
                        LastReadTime = tonumber(tab[4]),
                    }
                    if readInfo.EndTime and readInfo.EndTime > XTime.GetServerNowTimestamp() then
                        SubMenuNoticeReadList[readInfo.Id] = readInfo
                    end
                end
            end
        end
        --XLog.Warning("ReadSubMenuNoticeReadList",SubMenuNoticeReadList)
    end

    function XNoticeManager.GetScrollCountSaveKey()
        return tostring(XPlayer.Id) .. ScrollCountSaveKey
    end

    function XNoticeManager.SaveScrollCountList()
        if not ScrollCountList then
            return
        end
        -- 使用 table.concat 替代循环中的多次 .. 拼接，减少 GC 压力
        local contentParts = {}
        for _, v in pairs(ScrollCountList) do
            tableInsert(contentParts, v.id)
            tableInsert(contentParts, '\t')
            tableInsert(contentParts, v.maxCount)
            tableInsert(contentParts, '\t')
            tableInsert(contentParts, v.nowCount)
            tableInsert(contentParts, '\t')
            tableInsert(contentParts, v.overTime)
            tableInsert(contentParts, '\n')
        end
        local saveContent = table.concat(contentParts)

        CS.UnityEngine.PlayerPrefs.SetString(XNoticeManager.GetScrollCountSaveKey(), saveContent)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    function XNoticeManager.ReadScrollCountList()
        ScrollCountList = {}
        if not CS.UnityEngine.PlayerPrefs.HasKey(XNoticeManager.GetScrollCountSaveKey()) then
            return
        end
        local dataStr = CS.UnityEngine.PlayerPrefs.GetString(XNoticeManager.GetScrollCountSaveKey())
        local msgTab = string.Split(dataStr, '\n')
        if not msgTab or #msgTab <= 0 then
            return
        end

        for _, content in ipairs(msgTab) do
            if (not string.IsNilOrEmpty(content)) then
                local tab = string.Split(content, '\t')
                if tab then
                    local countInfo = {
                        id = tostring(tab[1]),
                        maxCount = tonumber(tab[2]),
                        nowCount = tonumber(tab[3]),
                        overTime = tonumber(tab[4]),
                    }
                    if countInfo.overTime and countInfo.overTime > XTime.GetServerNowTimestamp() then
                        ScrollCountList[countInfo.id] = countInfo
                    end
                end
            end
        end
    end
    --------------------------cache end--------------------------
    --------------------------text beg--------------------------
    function XNoticeManager.HandleRequestScrollTextNotice(notice)
        -- XLog.Warning("new text notice",notice)
        NowTextNotice = notice

        if not XNoticeManager.CheckTextNoticeValid(notice) then
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_NOTICE_CLOSE_TEXT_NOTICE)
        else
            XLuaUiManager.Open("UiNoticeTips")
        end

        if NowTextNotice then
            local key = XNoticeManager.GetTextNoticeKey(NowTextNotice)
            if not ScrollCountList or not ScrollCountList[key] then
                XNoticeManager.CreateDefaultScrollCountData(NowTextNotice)
            end
        end
    end

    function XNoticeManager.GetTextNoticeKey(notice)
        -- 复用table减少 GC 压力，直接设置值避免创建新表
        _TempKeyParts2[1] = notice.Id
        _TempKeyParts2[2] = notice.ModifyTime
        return table.concat(_TempKeyParts2, "_", 1, 2)
    end

    function XNoticeManager.CreateDefaultScrollCountData(notice)
        local key = XNoticeManager.GetTextNoticeKey(notice)
        local countInfo = {
            id = key,
            maxCount = notice.ScrollTimes,
            nowCount = 0,
            overTime = notice.EndTime,
        }
        ScrollCountList[key] = countInfo
    end

    function XNoticeManager.CheckTextNoticeValid(notice)
        notice = notice or NowTextNotice

        if not XNoticeManager.CheckNoticeValid(notice) then
            return false
        end

        if not XNoticeManager.CheckTextNoticeHideCache(notice) then
            return false
        end

        if notice.ShowInFight < 1 and not CS.XFight.IsOutFight then
            return false
        end

        if notice.ShowInPhotograph < 1 and ScreenShotFlag then
            return false
        end

        local key = XNoticeManager.GetTextNoticeKey(notice)
        if ScrollCountList[key]
                and ScrollCountList[key].nowCount > ScrollCountList[key].maxCount then

            return false
        end

        return true
    end

    function XNoticeManager.GetTextNoticeContent()
        if not NowTextNotice then
            return
        end
        return NowTextNotice.Content
    end

    function XNoticeManager.AddTextNoticeCount()
        if not NowTextNotice then
            return
        end

        local key = XNoticeManager.GetTextNoticeKey(NowTextNotice)

        if not ScrollCountList[key] then
            XNoticeManager.CreateDefaultScrollCountData(NowTextNotice)
        end

        ScrollCountList[key].nowCount = ScrollCountList[key].nowCount + 1

        XNoticeManager.SaveScrollCountList()
    end

    function XNoticeManager.GetTextNoticeScrollInterval()
        if not NowTextNotice then
            return DefaultTextScrollInterval
        end
        return tonumber(NowTextNotice.ScrollInterval) or DefaultTextScrollInterval
    end

    function XNoticeManager.ChangeTextNoticeHideCache(notice)
        notice = notice or NowTextNotice
        if not notice then
            return
        end

        local key = XNoticeManager.GetTextNoticeKey(notice)
        if not TextNoticeHideCache[key] then
            TextNoticeHideCache[key] = {
                Id = key,
                IsHide = 1,
                EndTime = notice.EndTime
            }
        else
            TextNoticeHideCache[key].IsHide = not TextNoticeHideCache[key].IsHide
        end

        XNoticeManager.SaveTextNoticeHideCache()
    end

    function XNoticeManager.CheckTextNoticeHideCache(notice)
        notice = notice or NowTextNotice
        if not notice then
            return false
        end

        local key = XNoticeManager.GetTextNoticeKey(notice)
        if not TextNoticeHideCache[key] then
            return true
        end

        return TextNoticeHideCache[key].IsHide < 0
    end
    --------------------------text end--------------------------
    ----------------------Scroll Pic beg----------------------

    function XNoticeManager.HandleRequestScrollPicNoticeFail()
        if not NowPicNotice then
            return
        end

        NowPicNotice = nil

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_NOTICE_PIC_CHANGE)
    end

    function XNoticeManager.HandleRequestScrollPicNotice(notice)
        if not notice then
            return
        end
        
        if NowPicNotice and NowPicNotice.Id == notice.Id and NowPicNotice.ModifyTime == notice.ModifyTime then
            return
        end

        if not XNoticeManager.CheckNoticeValid(notice) then
            return
        end

        NowPicNotice = notice

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_NOTICE_PIC_CHANGE)
    end

    function XNoticeManager.GetScrollPicList()
        XNoticeManager.RequestNoticeByType(XNoticeType.ScrollPic, true)
        if not NowPicNotice then
            return
        end
        
        local now = XTime.GetServerNowTimestamp()
        local scrollPicList = {}
        for _, v in ipairs(NowPicNotice.Content) do
            local isOpen = true
            
            if not v.BeginTime or not v.EndTime or not v.AppearanceDay or not v.AppearanceTime
                    or not v.DisappearanceCondition or not v.AppearanceCondition then
                isOpen = false
            end

            if not XNoticeManager.CheckNoticeContentValid(v, now) then
                isOpen = false
            end

            if isOpen then
                v.Interval = tonumber(v.Interval)
                table.insert(scrollPicList, v)
            end
        end
        
        return scrollPicList
    end
    ----------------------Scroll Pic end----------------------
    ----------------------InGame Notice beg----------------------
    function XNoticeManager.HandleRequestInGameNotice(notice)
        InGameNoticeMap = {}
        if not notice then
            return
        end

        if type(notice) ~= "table" then
            XLog.Error("InGame notice invalid format: " .. tostring(notice))
            return
        end
        local timeOfNow = XLoginManager.IsLogin() and XTime.GetServerNowTimestamp() or os.time()

        for _, v in ipairs(notice) do
            if XNoticeManager.CheckNoticeValid(v, timeOfNow) then
                if not InGameNoticeMap[v.Type] then
                    InGameNoticeMap[v.Type] = {}
                end

                local content = {}
                for _, item in ipairs(v.Content) do
                    local isOpen = true
                    if not XNoticeManager.IsWhiteIp(item.WhiteLists) and not XNoticeManager.IsWhiteDevice(item.DeviceLists) then
                        isOpen = false
                    end

                    if isOpen then
                        table.insert(content, item)
                    end
                end

                if #content > 0 then
                    v.Content = content
                    if v.Preload == 1 then --这个是预下载的公告
                        PreloadNotice = v
                    else
                        table.insert(InGameNoticeMap[v.Type], v)
                    end
                end
            end
        end

        -- 只在本次登录第一次请求时清理过期已读公告
        -- 后续清理将在同步前执行，避免每次请求都执行清理逻辑
        if not _HasCleanedOnFirstRequest then
            XNoticeManager.CleanExpiredReadNotices()
            _HasCleanedOnFirstRequest = true
        end
        
        for _, v in pairs(InGameNoticeMap) do
            XNoticeManager.InitInGameReadList(v)

            local sortFunc = function(l, r)
                return l.Order > r.Order
            end
            table.sort(v, sortFunc)
        end
        
        -- 所有公告类型处理完成后，触发红点刷新事件
        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_NOTICE_READ_CHANGE)
    end

    ---清理过期已读公告记录（不在当前公告列表中的记录）
    ---在以下时机调用：
    ---1. 本次登录第一次请求时
    ---2. 发送给服务端同步前
    function XNoticeManager.CleanExpiredReadNotices()
        if not InGameNoticeMap then
            return
        end
        
        -- 先收集所有当前公告的 dataKey，用于清理已删除的公告记录
        local allCurrentDataKeys = {}
        for _, v in pairs(InGameNoticeMap) do
            for _, noticeData in pairs(v) do
                for i, _ in pairs(noticeData.Content) do
                    local dataKey = XNoticeManager.GetGameNoticeReadDataKey(noticeData, i)
                    allCurrentDataKeys[dataKey] = true
                end
            end
        end
        
        -- 清理已删除的公告记录（不在当前公告列表中的记录）
        if InGameNoticeReadList then
            for dataKey, _ in pairs(InGameNoticeReadList) do
                if not allCurrentDataKeys[dataKey] then
                    InGameNoticeReadList[dataKey] = nil
                end
            end
        end
        
        -- 清理已删除的公告在服务端记录中的缓存（不在当前公告列表中的记录）
        if _ServerGameNoticeRecords then
            for serverKey, _ in pairs(_ServerGameNoticeRecords) do
                -- serverKey 格式: "noticeId_modifyTime"
                -- 检查是否在当前公告列表中
                local found = false
                for _, v in pairs(InGameNoticeMap) do
                    for _, noticeData in pairs(v) do
                        _TempKeyParts2[1] = noticeData.Id
                        _TempKeyParts2[2] = noticeData.ModifyTime
                        local expectedServerKey = table.concat(_TempKeyParts2, "_", 1, 2)
                        if serverKey == expectedServerKey then
                            found = true
                            break
                        end
                        if found then break end
                    end
                    if found then break end
                end
                if not found then
                    _ServerGameNoticeRecords[serverKey] = nil
                end
            end
        end
    end

    function XNoticeManager.GetInGameNoticeMap(type)
        return InGameNoticeMap[type]
    end

    function XNoticeManager.CheckHaveNotice(type)
        --海外才有Link，国内不判断
        if XOverseaManager.IsOverSeaRegion() and not XOverseaManager.IsTWRegion() then
            if type == InGameNoticeType.Link then
                return true
            end
        end
        XNoticeManager.RequestNoticeByType(XNoticeType.InGame, true)
        if not InGameNoticeMap then
            return false
        end

        if not InGameNoticeMap[type] or not next(InGameNoticeMap[type]) then
            return false
        end

        return true
    end

    function XNoticeManager.GetPreloadNotice()
        return PreloadNotice
    end


    function XNoticeManager.CheckInGameNoticeRedPoint(type)
        if not InGameNoticeMap or not InGameNoticeMap[type] then
            return false
        end
        
        for _, notice in pairs(InGameNoticeMap[type]) do
            if notice and notice.Content then
                for i, _ in ipairs(notice.Content) do
                    if XNoticeManager.CheckInGameNoticeRedPointIndividual(notice, i) then
                        return true
                    end
                end
            end
        end
        return false
    end

    function XNoticeManager.InitInGameReadList(noticeList)
        if not noticeList then
            return
        end

        if not InGameNoticeReadList then
            InGameNoticeReadList = {}
        end

        -- 收集当前公告列表中的所有 dataKey
        local currentDataKeys = {}
        for _, noticeData in pairs(noticeList) do
            for i, _ in pairs(noticeData.Content) do
                local dataKey = XNoticeManager.GetGameNoticeReadDataKey(noticeData, i)
                currentDataKeys[dataKey] = true
                
                if not InGameNoticeReadList[dataKey] then
                    InGameNoticeReadList[dataKey] = {
                        Id = noticeData.Id,
                        EndTime = noticeData.EndTime,
                        Index = i,
                        ModifyTime = noticeData.ModifyTime,
                        IsRead = false
                    }
                else
                    -- 更新可能变化的字段
                    InGameNoticeReadList[dataKey].Id = noticeData.Id
                    InGameNoticeReadList[dataKey].EndTime = noticeData.EndTime
                    InGameNoticeReadList[dataKey].Index = i
                    InGameNoticeReadList[dataKey].ModifyTime = noticeData.ModifyTime
                    if InGameNoticeReadList[dataKey].IsRead == nil then
                        InGameNoticeReadList[dataKey].IsRead = false
                    end
                end
                
                -- 检查服务端数据，如果已读则更新状态（优先于本地数据）
                local serverKey = string.format("%s_%s", noticeData.Id or "", tostring(noticeData.ModifyTime or ""))
                if _ServerGameNoticeRecords[serverKey] then
                    InGameNoticeReadList[dataKey].IsRead = true
                end
            end
        end
        
        -- 注意：清理逻辑已改为在特定时机执行（首次请求和同步前），不再每次请求都执行

        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_NOTICE_READ_CHANGE)
    end

    function XNoticeManager.GetGameNoticeReadDataKey(noticeData, index)
        -- 复用table减少 GC 压力，直接设置值避免创建新表
        _TempKeyParts3[1] = noticeData.Id
        _TempKeyParts3[2] = noticeData.ModifyTime
        _TempKeyParts3[3] = index
        return table.concat(_TempKeyParts3, "_", 1, 3)
    end

    function XNoticeManager.CheckInGameNoticeRedPointIndividual(notice, index)
        -- 蓝点规则：通过（公告ID，ModifyTime）确认公告是否已读
        -- 优先使用服务端数据判断，如果没有则使用本地数据
        
        if not notice or notice.BluePoint ~= 1 then
            return false
        end
        
        local noticeId = notice.Id
        local modifyTime = notice.ModifyTime
        
        -- 优先检查服务端数据
        local serverKey = string.format("%s_%s", noticeId or "", tostring(modifyTime or ""))
        if _ServerGameNoticeRecords[serverKey] then
            return false
        end
        
        -- 如果没有服务端数据，使用本地数据判断
        if not InGameNoticeReadList then
            return true
        end

        local redPointKey = XNoticeManager.GetGameNoticeReadDataKey(notice, index)
        local readInfo = InGameNoticeReadList[redPointKey]
        
        if not readInfo then
            return true
        end
        
        -- 确保 IsRead 字段存在
        if readInfo.IsRead == nil then
            readInfo.IsRead = false
        end
        
        return not readInfo.IsRead
    end

    function XNoticeManager.ChangeInGameNoticeReadStatus(dataKey, isRead)
        if not InGameNoticeReadList then
            return
        end

        if not InGameNoticeReadList[dataKey] then
            return
        end
        
        InGameNoticeReadList[dataKey].IsRead = isRead
        -- 已读状态已同步到服务端，不再需要保存到本地 PlayerPrefs
        
        -- 如果标记为已读，立即同步到服务端
        if isRead then
            XNoticeManager.SyncGameNoticeReadToServer(dataKey)
        end
        
        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_NOTICE_READ_CHANGE)
    end
    ----------------------InGame Notice end----------------------
    -------------------------Sub Menu beg------------------------
    --[[ 二级菜单配置 json数据格式
            {"Id":每次生成配置时的唯一标识,
           "ModifyTime":配置最后修改时间,
           "Content":配置具体内容，可以包含多个按钮 [
           "Id":唯一按钮Id,
           "Title":按钮名称,
           "SubTitle":按钮描述（显示在第二行）,
           "JumpType":1表示网址，2表示游戏内跳转,
           "JumpAddr":跳转地址,
           "BeginTime":开始显示时间,
           "EndTime":结束显示时间,
           "AppearanceDay":一周内出现的日子，不填则为全部出现,
           "AppearanceTime":每天出现的时间段，不填则为全天出现,
           "TipResetTime":红点重置时间,
           "ModifyTime":最后修改时间 ] * N }
     --]]
    function XNoticeManager.HandleRequestSubMenuNotice(notice)
        SubMenuNoticeMap = {}
        if not notice then
            return
        end

        if type(notice) ~= "table" then
            XLog.Error("SubMenu notice invalid format: " .. tostring(notice))
            return
        end

        -- debug 内网 渠道id = -1, 总是显示
        if (XMain.IsDebug and CS.XHeroSdkAgent.GetChannelId() == -1) or
            XNoticeManager.CheckChannelAndPlatform(notice)
        then
            for _, v in ipairs(notice.Content) do
                if XNoticeManager.CheckNoticeValid(v) then
                    table.insert(SubMenuNoticeMap, v)
                end
            end
        end

        XNoticeManager.InitSubMenuReadList(notice)
    end

    function XNoticeManager.GetMainUiSubMenu()
        XNoticeManager.RequestNoticeByType(XNoticeType.SubMenu, true)
        if not SubMenuNoticeMap then
            return
        end

        --XLog.Warning("start",SubMenuNoticeMap)

        local subMenuList = {}
        for _, v in ipairs(SubMenuNoticeMap) do
            local isOpen = true

            if not v.BeginTime or not v.EndTime or not v.AppearanceDay or not v.AppearanceTime then
                isOpen = false
            end

            if isOpen then
                isOpen = false
                if XTime.GetServerNowTimestamp() >= tonumber(v.BeginTime) and XTime.GetServerNowTimestamp() < tonumber(v.EndTime) then
                    --是否在开放区间内（日期）
                    isOpen = true
                end
            end

            if isOpen then
                isOpen = false
                if #v.AppearanceDay > 0 then
                    for _, day in ipairs(v.AppearanceDay) do
                        if day == XDataCenter.FubenDailyManager.GetNowDayOfWeekByRefreshTime() then
                            --是否位于可以显示的周目
                            isOpen = true
                        end
                    end
                else
                    isOpen = true
                end
            end

            if isOpen then
                isOpen = false
                if #v.AppearanceTime > 0 then
                    for _, time in ipairs(v.AppearanceTime) do
                        if XTime.GetServerNowTimestamp() - XTime.GetTodayTime(0, 0, 0) >= time[1] and XTime.GetServerNowTimestamp() - XTime.GetTodayTime(0, 0, 0) < time[2] then
                            --是否位于可以显示的时间段
                            isOpen = true
                        end
                    end
                else
                    isOpen = true
                end
            end

            if isOpen then
                if v.DisappearanceCondition and #v.DisappearanceCondition > 0 then
                    for _, condition in ipairs(v.DisappearanceCondition) do
                        --是否符合不显示的条件
                        if XConditionManager.CheckCondition(condition) then
                            isOpen = false
                        end
                    end
                end
            end

            if isOpen then
                if v.AppearanceCondition and #v.AppearanceCondition > 0 then
                    for _, condition in ipairs(v.AppearanceCondition) do
                        if not XConditionManager.CheckCondition(condition) then
                            --是否不符合显示条件
                            isOpen = false
                        end
                    end
                end
            end

            if isOpen then
                if not XNoticeManager.IsWhiteIp(v.WhiteLists) and not XNoticeManager.IsWhiteDevice(v.DeviceLists) then
                    isOpen = false
                end
            end

            if isOpen then
                table.insert(subMenuList, v)
            end
        end

        return subMenuList
    end

    function XNoticeManager.CheckSubMenuRedPoint()
        if not SubMenuNoticeMap then
            return false
        end

        for _, data in pairs(SubMenuNoticeMap) do
            if XNoticeManager.CheckSubMenuRedPointIndividual(data.Id) then
                return true
            end
        end
        return false
    end

    function XNoticeManager.InitSubMenuReadList(notice)
        if not notice then
            return
        end

        if not SubMenuNoticeReadList then
            SubMenuNoticeReadList = {}
        end

        for _, noticeData in pairs(notice.Content) do
            local dataKey = noticeData.Id
            if not SubMenuNoticeReadList[dataKey] then
                SubMenuNoticeReadList[dataKey] = {}
                SubMenuNoticeReadList[dataKey].Id = noticeData.Id
                SubMenuNoticeReadList[dataKey].LastReadTime = 0
            end
            SubMenuNoticeReadList[dataKey].EndTime = noticeData.EndTime
            SubMenuNoticeReadList[dataKey].TipResetTime = noticeData.TipResetTime or 0
        end

        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_SUBMENU_READ_CHANGE)
        -- CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_SUBMENU_READ_CHANGE)
    end

    function XNoticeManager.CheckSubMenuRedPointIndividual(id)
        if not SubMenuNoticeReadList then
            return false
        end

        local data = SubMenuNoticeReadList[id]
        if not data then
            return false
        end

        if data.TipResetTime > XTime.GetServerNowTimestamp() then
            return false
        end
        return data.LastReadTime < data.TipResetTime
    end

    function XNoticeManager.ChangeSubMenuReadStatus(dataKey, time)
        if not SubMenuNoticeReadList then
            return
        end

        SubMenuNoticeReadList[dataKey].LastReadTime = time or XTime.GetServerNowTimestamp()
        --XLog.Warning("ChangeSubMenuReadStatus",SubMenuNoticeReadList)
        XNoticeManager.SaveSubMenuNoticeReadList()
    end
    -------------------------Sub Menu end------------------------

    ----------------------------------------login beg----------------------------------------

    function XNoticeManager.RequestLoginNotice(cb, ...)
        local requestCb = function(notice)
            local valid = XNoticeManager.CheckNoticeValid(notice, os.time())
            if not valid then
                if cb then
                    cb(valid)
                end

                local msgtab = {}
                msgtab.error = valid
                CS.XRecord.Record(msgtab, "24000", "RequestLoginNoticeError")
                return
            end

            if LoginNotice and LoginNotice.Id == notice.Id and LoginNotice.ModifyTime == notice.ModifyTime then
                if cb then
                    cb(valid)
                end

                local msgtab = {}
                msgtab.error = valid
                CS.XRecord.Record(msgtab, "24006", "RequestLoginNoticeError")
                return
            end

            LoginNotice = notice
            
            CS.XRecord.Record("24005", "RequestLoginNoticeEnd")
            if cb then
                if XOverseaManager.IsTWRegion() or XOverseaManager.IsKRRegion() then
                    local openNotice = false
                    if XNoticeManager.CheckLoginNoticeDailyAutoShow(notice) then
                        openNotice = true
                        XNoticeManager.OpenLoginNotice()
                        XNoticeManager.RefreshLoginNoticeTime()
                    end
                    cb(valid, openNotice)
                else
                    cb(valid)
                end
            end
        end
        CS.XRecord.Record("24004", "RequestLoginNoticeStart")
        XNoticeManager.RequestNotice(XNoticeType.Login, requestCb, requestCb)
    end

    function XNoticeManager.AutoOpenLoginNotice()
        if XNoticeManager.CheckLoginNoticeDailyAutoShow(LoginNotice) then
            if not XNoticeManager.CheckNoticeValid(LoginNotice, os.time()) then
                return false
            end

            -- 云游戏不弹出登录公告
            if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.CloudGame then
                return false
            end

            XLuaUiManager.Open("UiLoginNotice", LoginNotice, true)
            XNoticeManager.RefreshLoginNoticeTime()
            return true
        end
        return false
    end
    
    function XNoticeManager.CheckHasOpenLoginNotice()
        local isSelect = XSaveTool.GetData(LoginNoticAutoOpenKey)
        
        return isSelect or false
    end
    
    function XNoticeManager.SaveOpenLoginNoticeValue(value)
        XSaveTool.SaveData(LoginNoticAutoOpenKey, value)
    end

    function XNoticeManager.OpenLoginNotice()
        -- 云游戏不弹出登录公告
        if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.CloudGame then
            return
        end

        if not LoginNotice then
            XNoticeManager.RequestLoginNotice(function(isValid)
                if isValid then
                    XLuaUiManager.Open("UiLoginNotice", LoginNotice, true)
                    XNoticeManager.RefreshLoginNoticeTime()
                end
            end)
        else
            if not XNoticeManager.CheckNoticeValid(LoginNotice, os.time()) then
                return
            end

            XLuaUiManager.Open("UiLoginNotice", LoginNotice, true)
            XNoticeManager.RefreshLoginNoticeTime()
        end
    end

    function XNoticeManager.ReadLoginNoticeTime()
        local cache = CS.UnityEngine.PlayerPrefs.GetString(LoginNoticeCacheKey)
        if string.IsNilOrEmpty(cache) then
            return
        end

        LoginNoticeTimeInfo = Json.decode(cache)
    end

    function XNoticeManager.CheckLoginNoticeDailyAutoShow(notice)
        if not notice then
            return
        end

        -- 复用table减少 GC 压力
        _TempKeyParts2[1] = notice.Id
        _TempKeyParts2[2] = notice.ModifyTime
        local id = table.concat(_TempKeyParts2, "", 1, 2)
        local resetTime = CS.XReset.GetNextDailyResetTime() - CS.XDateUtil.ONE_DAY_SECOND
        if LoginNoticeTimeInfo[id] and LoginNoticeTimeInfo[id].Time > resetTime then
            return not XNoticeManager.CheckHasOpenLoginNotice()
        end

        return true
    end

    function XNoticeManager.RefreshLoginNoticeTime()
        if not LoginNotice then
            return
        end

        local id = LoginNotice.Id .. LoginNotice.ModifyTime
        LoginNoticeTimeInfo[id] = {
            Id = id,
            -- 此处有可能无法获取到真实时间（尚未与服务端同步时间）
            --Time = XTime.GetServerNowTimestamp()
            
            -- 既然如此， 用本地时间就好了
            Time = XTime.GetLocalNowTimestamp()
        }

        CS.UnityEngine.PlayerPrefs.SetString(LoginNoticeCacheKey, Json.encode(LoginNoticeTimeInfo))
        CS.UnityEngine.PlayerPrefs.Save()
    end
    
    function XNoticeManager.CheckLoginNoticeValid(time)
        return XNoticeManager.CheckNoticeValid(LoginNotice, time)
    end

    ----------------------------------------login end----------------------------------------
    --region 拍脸图公告

    ---@class XPopUpPicNotice 公告中用于拍脸图的Content结构
    ---@field ModifyTime number 公告修改时间
    ---@field Id string 公告Id
    ---@field LoginPlatformList number[] 登录平台列表，平台：0-桌面端  1-安卓端  2-苹果端
    ---@field PkgInfoList string[] 字段不存在或为空数组，则对所有pkgId可见，反之需要包含具体pkgId才可见
    ---@field ChannelInfoList number[] 字段不存在或为空数组，则对所有channelId可见，反之需要包含具体channelId才可见
    ---@field Content XPopUpPicNoticeContent[] 公告内容，数组顺序即为图片显示的先后顺序

    ---@class XPopUpPicNoticeContent 公告内容
    ---@field Id number
    ---@field PicType string
    ---@field PicAddr string 图片链接
    ---@field JumpType string 跳转类型：1-网页链接；2-游戏链接
    ---@field JumpAddr string 链接地址（外链或游戏链接）
    ---@field BeginTime number 开始时间（秒）
    ---@field EndTime number 结束时间（秒）
    ---@field AppearanceType number 弹出时机:1-每次登录;2-每天首次登录
    ---@field AppearanceDay number[] 星期几显示，1~7分别代表周一到周日
    ---@field AppearanceTime number[] 当天哪个时间段显示，二维数组：外层为有几个时间段，内层（数组长度为2）为开始时间（当天的秒数）和结束时间（当天的秒数）
    ---@field AppearanceCondition number[] 出现条件（同时满足才出现）
    ---@field DisappearanceCondition number[] 消失条件（满足任意一个就消失）
    ---@field WhiteLists string[] 白名单IP，字段不存在则不需要判断；字段为空数组，即对所有人都不可见；字段不为空数组，则包含的IP可见
    ---@field DeviceLists string[] 白名单设备ID，判断规则与白名单IP类似。并且满足白名单IP或白名单设备ID任意一个，即对该玩家可见

    ---处理拍脸图公告请求结果，更新当前拍脸图公告数据
    function XNoticeManager.HandleRequestPopUpPicNotice(notice)
        if not notice then
            NowPopUpPicNotice = nil
            return
        end

        if NowPopUpPicNotice and NowPopUpPicNotice.Id == notice.Id and NowPopUpPicNotice.ModifyTime == notice.ModifyTime then
            return
        end

        if not XNoticeManager.CheckNoticeValid(notice) then
            NowPopUpPicNotice = nil
            return
        end

        NowPopUpPicNotice = notice
    end

    --- 获取单条拍脸图内容的唯一标识，用于记录展示状态等
    ---@param content XPopUpPicNoticeContent
    ---@return string
    function XNoticeManager.GetPopUpPicContentKey(content)
        local noticeId = NowPopUpPicNotice and NowPopUpPicNotice.Id or ""
        local modifyTime = NowPopUpPicNotice and NowPopUpPicNotice.ModifyTime or ""
        return string.format("PopUpPic_%s_%s_%s", noticeId, modifyTime, content.Id or "")
    end

    --- 获取单条拍脸图内容每天展示的唯一标识，包含玩家ID和当天日期，用于记录每天展示状态
    ---@param contentKey string
    ---@return string
    function XNoticeManager.GetPopUpPicDailyKey(contentKey)
        local dayZero = XTime.GetTodayTime(0, 0, 0)
        return string.format("PopUpPicDaily_%s_%s_%s", XPlayer.Id, dayZero, contentKey)
    end

    --- 检查单条拍脸图内容是否需要展示
    ---@param content XPopUpPicNoticeContent
    ---@return boolean
    function XNoticeManager.CheckPopUpPicAppearance(content)
        local appearanceType = content.AppearanceType or PopUpPicAppearanceType.EachLogin
        local contentKey = XNoticeManager.GetPopUpPicContentKey(content)

        if appearanceType == PopUpPicAppearanceType.EachLogin then
            return not PopUpPicShownPerLogin[contentKey]
        elseif appearanceType == PopUpPicAppearanceType.EachDay then
            local dailyKey = XNoticeManager.GetPopUpPicDailyKey(contentKey)
            return not XSaveTool.GetData(dailyKey)
        end
        -- 未知类型默认展示
        return true
    end

    --- 标记单条拍脸图内容已展示
    ---@param content XPopUpPicNoticeContent
    function XNoticeManager.MarkPopUpPicAppearanceShown(content)
        local appearanceType = content.AppearanceType or PopUpPicAppearanceType.EachLogin
        local contentKey = XNoticeManager.GetPopUpPicContentKey(content)

        if appearanceType == PopUpPicAppearanceType.EachLogin then
            PopUpPicShownPerLogin[contentKey] = true
        elseif appearanceType == PopUpPicAppearanceType.EachDay then
            local dailyKey = XNoticeManager.GetPopUpPicDailyKey(contentKey)
            XSaveTool.SaveData(dailyKey, true)
        end
    end

    ---获取当前有效的拍脸图公告内容列表（保持数组顺序）
    ---@return table|nil
    function XNoticeManager.GetPopUpPicContentList()
        XNoticeManager.RequestNoticeByType(XNoticeType.PopUpPic, true)
        if not NowPopUpPicNotice or not NowPopUpPicNotice.Content then
            return nil
        end

        local now = XTime.GetServerNowTimestamp()
        local contentList = {}
        for _, v in ipairs(NowPopUpPicNotice.Content) do
            if XNoticeManager.CheckNoticeContentValid(v, now) and XNoticeManager.CheckPopUpPicAppearance(v) then
                tableInsert(contentList, v)
            end
        end

        return contentList
    end

    ---自动弹出拍脸图公告
    ---在OnFunctionEventValueChange中CheckAutoWindow之后调用
    ---@return boolean 是否弹出了拍脸图
    function XNoticeManager.AutoOpenPopUpPicNotice()
        local contentList = XNoticeManager.GetPopUpPicContentList()
        if XTool.IsTableEmpty(contentList) then
            return false
        end

        -- 保存队列，逐个弹出
        PopUpPicQueue = contentList
        PopUpPicQueueIndex = 1

        local content = PopUpPicQueue[PopUpPicQueueIndex]
        XNoticeManager.MarkPopUpPicAppearanceShown(content)
        XLuaUiManager.Open("UiAutoWindowNotice", content)
        return true
    end

    ---展示下一个拍脸图公告，如果队列中还有则继续弹出，否则触发结束事件
    ---@return boolean 是否继续弹出下一个拍脸图
    function XNoticeManager.ShowNextPopUpPicNotice()
        if XTool.IsTableEmpty(PopUpPicQueue) then
            return false
        end

        local now = XTime.GetServerNowTimestamp()
        for i = PopUpPicQueueIndex + 1, #PopUpPicQueue do
            local content = PopUpPicQueue[i]
            -- 重新校验有效性，跳过已过期或不符合条件的内容
            if XNoticeManager.CheckNoticeContentValid(content, now) then
                PopUpPicQueueIndex = i
                XNoticeManager.MarkPopUpPicAppearanceShown(content)
                XLuaUiManager.Open("UiAutoWindowNotice", content)
                return true
            end
        end

        -- 全部展示完毕或剩余内容均已失效，清理队列
        PopUpPicQueue = {}
        PopUpPicQueueIndex = 0
        XEventManager.DispatchEvent(XEventId.EVENT_AUTO_WINDOW_END)
        return false
    end

    ---停止拍脸图公告弹出，清理队列并触发结束事件
    function XNoticeManager.StopPopUpPicNotice()
        PopUpPicQueue = {}
        PopUpPicQueueIndex = 0
        XEventManager.DispatchEvent(XEventId.EVENT_AUTO_WINDOW_STOP)
    end
    --endregion
    --region   ------------------游戏公告 start-------------------

    ---@desc 打开公告界面，公告类型可能为空，只要有公告就打开界面
    ---@param announcementType number 游戏内公告类型
    function XNoticeManager.OpenGameNotice(announcementType, defaultId)
        local empty = true
        for _, noticeType in pairs(InGameNoticeType) do
            local hasNotice = XNoticeManager.CheckHaveNotice(noticeType)
            if hasNotice then
                empty = false
                break
            end
        end

        if empty then
            XUiManager.TipText("NoInGameNotice")
            return false
        end

        local _, infoList = XNoticeManager.GetAutoOpenNoticeInfos()
        --将所有需要弹出的公告标记为已弹出
        for _, info in ipairs(infoList) do
            XNoticeManager.MarkInGameNoticeAutoMap(info.Id, info.ModifyTime)
        end

        -- 首次打开公告界面时，尝试首次同步本地已读数据到服务端
        XNoticeManager.TryFirstSyncGameNoticeRead()

        XLuaUiManager.Open("UiAnnouncement", announcementType, defaultId)
        
        return true
    end

    ---@desc 获取游戏内需要展示的公告下标
    ---@param noticeType number 公告类型
    ---@return number
    function XNoticeManager.GetShowNoticeIndex(noticeType)
        local noticeInfo = XDataCenter.NoticeManager.GetInGameNoticeMap(noticeType)
        if not noticeInfo then
            XLog.Warning("XNoticeManager.GetShowNoticeIndex: not exist notice info!, noticeType = " .. noticeType)
            return nil
        end

        local index = 1
        --再判断红点
        for idx, info in pairs(noticeInfo) do
            for i, _ in ipairs(info.Content) do
                if XNoticeManager.CheckInGameNoticeRedPointIndividual(info, i) then
                    return idx
                end
            end
        end
        return index
    end

    --- 登陆界面请求游戏内公告
    ---@param cb function 回调
    ---@param timeStamp number 判断时间戳
    --------------------------
    function XNoticeManager.RequestInGameNotice(cb, timeStamp)

        --如果未登陆到游戏服，无法获取服务器时间
        local timeOfNow = timeStamp and timeStamp or XTime.GetServerNowTimestamp()

        local checkCb = function()
            local valid, _ = XNoticeManager.GetAutoOpenNoticeInfos()
            if cb then cb(valid) end
        end
        
        local handler = function(notice)
            InGameNoticeMap = {}
            notice = notice or {}

            for _, v in ipairs(notice) do
                if not XNoticeManager.CheckNoticeValid(v, timeOfNow) then
                    goto continue
                end

                if not InGameNoticeMap[v.Type] then
                    InGameNoticeMap[v.Type] = {}
                end

                local content = {}
                for _, item in ipairs(v.Content) do
                    local isOpen = true
                    if not XNoticeManager.IsWhiteIp(item.WhiteLists) and not XNoticeManager.IsWhiteDevice(item.DeviceLists) then
                        isOpen = false
                    end
                    if isOpen then
                        table.insert(content, item)
                    end
                end

                if #content > 0 then
                    v.Content = content
                    if v.Preload == 1 then --这个是预下载的公告
                        PreloadNotice = v
                    else
                        table.insert(InGameNoticeMap[v.Type], v)
                    end
                end

                ::continue::
            end

            for _, v in pairs(InGameNoticeMap) do
                XNoticeManager.InitInGameReadList(v)

                local sortFunc = function(l, r)
                    return l.Order > r.Order
                end
                table.sort(v, sortFunc)
            end
            
            checkCb()
        end
        
        XNoticeManager.RequestNotice(XNoticeType.InGame, handler, handler, NoticeRequestTimerInterval, checkCb)
    end
    
    function XNoticeManager.GetAutoOpenNoticeInfos()
        if XTool.IsTableEmpty(InGameNoticeMap) then
            return false, {}
        end

        local infoList = {}
        local autoMap = XNoticeManager.GetInGameNoticeAutoMap()
        for _, type in pairs(InGameNoticeType) do
            local noticeInfo = XDataCenter.NoticeManager.GetInGameNoticeMap(type)
            if noticeInfo then
                for _, info in pairs(noticeInfo) do
                    local autoKey = XNoticeManager.GetInGameNoticeAutoPopupKey(info.Id, info.ModifyTime)
                    if info.LoginEject and info.LoginEject == 1 and not autoMap[autoKey] then
                        tableInsert(infoList, info)
                    end
                end
            end
        end

        if XTool.IsTableEmpty(infoList) then
            return false, {}
        end

        local count = #infoList
        if count > 1 then
            table.sort(infoList, function(a, b)
                local timeA = a.BeginTime
                local timeB = b.BeginTime
                return timeA > timeB
            end)
        end
        
        return true, infoList
    end

    --- 自动打开公告界面，并选中对应公告。自动弹出时会将所有需要弹出公告标记为已弹出
    --------------------------
    function XNoticeManager.AutoOpenInGameNotice()
        local valid, infoList = XNoticeManager.GetAutoOpenNoticeInfos()
        if not valid then
            return false
        end
        
        --将所有需要弹出的公告标记为已弹出
        for _, info in ipairs(infoList) do
            XNoticeManager.MarkInGameNoticeAutoMap(info.Id, info.ModifyTime)
        end
        
        local selectInfo = infoList[1]
        local value = XNoticeManager.OpenGameNotice(selectInfo.Type, selectInfo.Id)
        return value
    end
    --endregion------------------游戏公告 finish------------------
    ----------------------------image process beg----------------------------
    function XNoticeManager.LoadPicFromLocal(url, successCb)
        if NoticePicList and NoticePicList[url] then
            if successCb then
                successCb(NoticePicList[url])
            end
            return NoticePicList[url]
        end

        local fileName = XNoticeManager.GetImgNameByUrl(url)
        CS.XTool.LoadLocalNoticeImg(fileName, function(texture)
            if not texture then
                XNoticeManager.LoadPic(url, successCb)
            else
                NoticePicList[url] = texture
                if successCb then
                    successCb(texture)
                end
            end
        end)
    end

    function XNoticeManager.LoadPic(url, successCb)
        local request = CS.XUriPrefixRequest.Get(url, function()
            return CS.UnityEngine.Networking.DownloadHandlerTexture(true)
        end, NoticeRequestTimeOut, false)

        CS.XTool.WaitCoroutine(request:SendWebRequest(true), function()
            if request.isNetworkError or request.isHttpError then
                return
            end

            local texture = request.downloadHandler.texture;
            if not texture then
                return
            end

            local fileName = XNoticeManager.GetImgNameByUrl(url)
            fileName = XTool.GetFileNameWithoutExtension(fileName)
            CS.XTool.SaveNoticeImg(fileName, texture)

            NoticePicList[url] = texture
            if successCb then
                successCb(texture)
            end

            request:Dispose()
        end)
    end

    function XNoticeManager.GetImgNameByUrl(url)
        local _, _, _, fileName = url:find("(.+)/(.+)")
        return fileName
    end
    
    
    function XNoticeManager.ClearOutdateNoticePic(adlist)
        --每个版本每次登录只删除一次
        if IsCheckOutDateClear or XSaveTool.GetData('ClearOutdateNoticePic') == CS.XRemoteConfig.ApplicationVersion then
            return
        end
        
        local imgNames = {}
        if not XTool.IsTableEmpty(adlist) then
            for i, v in ipairs(adlist) do
                if not string.IsNilOrEmpty(v.PicAddr) then
                    local fileName = XNoticeManager.GetImgNameByUrl(v.PicAddr)
                    imgNames[fileName] = true
                end
            end
        elseif not XTool.IsTableEmpty(NoticePicList) then
            for url, v in pairs(NoticePicList) do
                local fileName = XNoticeManager.GetImgNameByUrl(url)
                imgNames[fileName] = true
            end
        end
        
        local noticeImgPath = CS.XTool.NoticeImgPath
        
        local fileOperationFunc = function()
            if string.IsNilOrEmpty(noticeImgPath) or not CS.System.IO.Directory.Exists(noticeImgPath) then
                IsCheckOutDateClear = true
                XSaveTool.SaveData('ClearOutdateNoticePic', CS.XRemoteConfig.ApplicationVersion)
                return
            end

            local directory = CS.System.IO.DirectoryInfo(noticeImgPath)
            local files = directory:GetFiles("*.png")

            if files then
                for i = 0, files.Length -1 do
                    local fileName = string.sub(files[i].Name,1,#files[i].Name - #files[i].Extension)
                    if not imgNames[fileName] then
                        --表明不是最新的，需要删除
                        files[i]:Delete()
                    end
                end
            end
        end
        
        local result, msg = pcall(fileOperationFunc)

        if not result then
            XLog.Error('[过期轮播图片处理失败]', msg)
        end

        IsCheckOutDateClear = true
        XSaveTool.SaveData('ClearOutdateNoticePic', CS.XRemoteConfig.ApplicationVersion)
    end
    ----------------------------image process end----------------------------

    --function XNoticeManager.UrlDecode(s)
    --    s = string.gsub(s, '%%(%x%x)', function(h)
    --        return string.char(tonumber(h, 16))
    --    end)
    --    return s
    --end

    --- 检查公告是否有效
    ---【起始时间、白名单、渠道】
    function XNoticeManager.CheckNoticeValid(notice, nowTime)
        if not notice then
            return false
        end

        nowTime = nowTime or XTime.GetServerNowTimestamp()
        
        if XTool.IsNumberValidEx(notice.BeginTime) and nowTime < notice.BeginTime then
            return false
        end

        if XTool.IsNumberValidEx(notice.EndTime) and nowTime > notice.EndTime then
            return false
        end

        if not XNoticeManager.IsWhiteIp(notice.WhiteLists) and not XNoticeManager.IsWhiteDevice(notice.DeviceLists) then
            return false
        end

        if not XNoticeManager.CheckChannelAndPlatform(notice) then
            return false
        end
        
        return true
    end
    
    --- 检查公告内容有效性
    function XNoticeManager.CheckNoticeContentValid(content, nowTime)
        if not content then
            return false
        end

        nowTime = nowTime or XTime.GetServerNowTimestamp()

        -- 基本时间及白名单检查
        if XTool.IsNumberValidEx(content.BeginTime) and nowTime < content.BeginTime then
            return false
        end

        if XTool.IsNumberValidEx(content.EndTime) and nowTime > content.EndTime then
            return false
        end

        if not XNoticeManager.IsWhiteIp(content.WhiteLists) and not XNoticeManager.IsWhiteDevice(content.DeviceLists) then
            return false
        end
        
        -- 其他条件检查
        local isValid = true
        
        if isValid then
            if XTool.GetTableCount(content.AppearanceDay) > 0 then
                isValid = false
                for _, day in ipairs(content.AppearanceDay) do
                    if day == XDataCenter.FubenDailyManager.GetNowDayOfWeekByRefreshTime() then
                        --是否位于可以显示的周目
                        isValid = true
                    end
                end
            end
        end

        if isValid then
            if XTool.GetTableCount(content.AppearanceTime) > 0 then
                isValid = false
                
                local todayTime = XTime.GetTodayTime(0, 0, 0)
                local passTime = nowTime - todayTime
                
                for _, time in ipairs(content.AppearanceTime) do
                    if passTime >= time[1] and passTime < time[2] then
                        --是否位于可以显示的时间段
                        isValid = true
                    end
                end
            end
        end

        if isValid then
            if XTool.GetTableCount(content.DisappearanceCondition) > 0 then
                for _, condition in ipairs(content.DisappearanceCondition) do
                    --是否符合不显示的条件
                    if XConditionManager.CheckCondition(condition) then
                        isValid = false
                    end
                end
            end
        end

        if isValid then
            if XTool.GetTableCount(content.AppearanceCondition) > 0 then
                for _, condition in ipairs(content.AppearanceCondition) do
                    if not XConditionManager.CheckCondition(condition) then
                        --是否不符合显示条件
                        isValid = false
                    end
                end
            end
        end
        
        return isValid
    end
    
    function XNoticeManager.CheckChannelAndPlatform(notice)
        -- 发布渠道
        local channelInfoList = notice.ChannelInfoList
        if channelInfoList then
            local myChannel = CS.XHeroSdkAgent.GetChannelId()
            local isMyChannelInclude = false
            for i = 1, #channelInfoList do
                local channel = channelInfoList[i]
                if channel == myChannel then
                    isMyChannelInclude = true
                    break
                end
            end
            if not isMyChannelInclude then
                return false
            end
        end
        
        local pkgInfoList = notice.PkgInfoList

        if pkgInfoList then
            local myPkgId = XHeroSdkManager.GetCurPkgId()
            local isMyPkgIdInclude = false
            for i = 1, #pkgInfoList do
                local pkgId = pkgInfoList[i]
                if pkgId == myPkgId then
                    isMyPkgIdInclude = true
                    break
                end
            end

            if not isMyPkgIdInclude then
                return false
            end
        end

        local appChannelInfoList = notice.AppChannelInfoList
        if appChannelInfoList then
            local myAppChannel = CS.XHeroSdkAgent.GetAppChannelId()
            local isMyAppChannelInclude = false
            for i = 1, #appChannelInfoList do
                local appChannel = appChannelInfoList[i]
                if appChannel == myAppChannel then
                    isMyAppChannelInclude = true
                    break
                end
            end
            if not isMyAppChannelInclude then
                return false
            end
        end

        -- 发布平台 pc,ios,android
        local loginPlatformList = notice.LoginPlatformList
        if loginPlatformList then
            local myPlatform = XUserManager.Platform
            local isMyPlatformInclude = false
            for i = 1, #loginPlatformList do
                local platform = loginPlatformList[i]
                if platform == myPlatform then
                    isMyPlatformInclude = true
                    break
                end
            end
            if not isMyPlatformInclude then
                return false
            end
        end
        return true
    end

    function XNoticeManager.IsWhiteIp(whiteList)
        if not whiteList then
            return true
        end

        if string.IsNilOrEmpty(Ip) then
            return false
        end

        for _, whiteIp in pairs(whiteList) do
            if string.find(Ip, whiteIp) then
                return true
            end
        end

        return false
    end

    local DeviceId = nil
    --根据设备id判断是否是白名单
    function XNoticeManager.IsWhiteDevice(whiteList)
        if not whiteList then
            return true
        end

        if DeviceId == "0" then
            return false
        end

        for _, whiteId in pairs(whiteList) do
            if DeviceId == whiteId then
                return true
            end
        end
        return false
    end

    function XNoticeManager.RequestNoticeByType(noticeType, proactiveRequest)
        local successCb = NoticeRequestHandler[noticeType]
        local failCb = NoticeRequestFailHandler[noticeType]
        local interval = proactiveRequest and NoticeRequestTimerInterval or RequestInterval[noticeType]
        -- XLog.Warning("RequestNoticeByType", NoticeRequestTimerInterval, "type", RequestInterval[noticeType], "主动", proactiveRequest)
        XNoticeManager.RequestNotice(noticeType, successCb, failCb, interval)
    end

    function XNoticeManager.RequestNotice(noticeType, successCb, failCb, interval, unaskedCb)
        if DisableFunction or not noticeType then
            if unaskedCb then unaskedCb() end
            return
        end

        local nowTime = XTime.GetServerNowTimestamp()
        --if ((not nowTime) or (not noticeType) or (not interval)) then
        --    XLog.Warning("XNoticeManager nowTime", nowTime,"noticeType", noticeType,"LastRequestTime", LastRequestTime[noticeType],"interval", interval)
        --end
        -- 兼容 interval 为 0 的情况：如果 interval 为 0 或 nil，不进行时间间隔检查，直接请求
        if interval and interval > 0 then
            if LastRequestTime[noticeType] and LastRequestTime[noticeType] > 0
                    and nowTime - LastRequestTime[noticeType] < interval then
                if unaskedCb then unaskedCb() end
                return
            end
        end
        LastRequestTime[noticeType] = nowTime

        local url = XNoticeManager.GetNoticeUrl(noticeType)
        
        if string.IsNilOrEmpty(url) then
            if unaskedCb then unaskedCb() end
            return
        end
        local request = CS.XUriPrefixRequest.Get(url, nil, NoticeRequestTimeOut, false, true)
        CS.XTool.WaitCoroutine(request:SendWebRequest(true), function()
            if not request then
                if failCb then
                    failCb()
                end
                return
            end

            if request.isNetworkError or
                request.isHttpError or
                not request.downloadHandler or
                string.IsNilOrEmpty(request.downloadHandler.text) then
                if failCb then
                    failCb()
                end
                return
            end

            local ok, notice = pcall(Json.decode, request.downloadHandler.text)
            if not ok then
                XLog.Error("XNoticeManager json 解码失败. 数据是：", request.downloadHandler.data)
                if failCb then
                    failCb()
                end
                return
            end

            if not notice then
                if failCb then
                    failCb()
                end
                return
            end

            if successCb then
                successCb(notice)
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_NOTICE_REQUEST_SUCCESS, noticeType)

            request:Dispose()
        end)
    end

    function XNoticeManager.InitTimer()
        if NoticeRequestTimer then
            return
        end

        for noticeType, _ in pairs(RequestInterval) do
            XNoticeManager.RequestNoticeByType(noticeType)
        end

        NoticeRequestTimer = XScheduleManager.ScheduleForever(function()
            for noticeType, _ in pairs(RequestInterval) do
                XNoticeManager.RequestNoticeByType(noticeType)
            end
        end, NoticeRequestTimerInterval * 1000)
    end

    function XNoticeManager.OnLogin()
        XNoticeManager.ReadScrollCountList()
        --登录时刷新玩家的蓝点
        XNoticeManager.ReadInGameNoticeReadList()
        XNoticeManager.ReadTextNoticeHideCache()
        XNoticeManager.ReadSubMenuNoticeReadList()
        
        XNoticeManager.InitTimer()
    end

    function XNoticeManager.OnLogout()
        if NoticeRequestTimer then
            XScheduleManager.UnSchedule(NoticeRequestTimer)
            NoticeRequestTimer = nil
        end
        
        -- 清理同步队列
        if _SyncQueueTimer then
            XScheduleManager.UnSchedule(_SyncQueueTimer)
            _SyncQueueTimer = nil
        end
        _SyncQueue = {}
        _HasSyncedGameNoticeToServer = false
        _HasCleanedOnFirstRequest = false
        NowPopUpPicNotice = nil
        PopUpPicShownPerLogin = {}
        PopUpPicQueue = {}
        PopUpPicQueueIndex = 0

        for _, v in pairs(NoticePicList) do
            if v and v:Exist() then
                CS.UnityEngine.Object.Destroy(v)
            end
        end
        NoticePicList = {}
    end

    --检测请求开关
    function XNoticeManager.CheckFuncDisable()
        return XSaveTool.GetData(XPrefs.NoticeTrigger)
    end

    function XNoticeManager.ChangeFuncDisable(state)
        DisableFunction = state
        XSaveTool.SaveData(XPrefs.NoticeTrigger, DisableFunction)
    end

    function XNoticeManager.GetKRPCNotice()
        return NowPcNotice
    end

    function XNoticeManager.HandleKRPCNotice(data)
        if XDataCenter.UiPcManager.GetUiPcMode() ~= XDataCenter.UiPcManager.XUiPcMode.Pc then
            XLog.Error("not pc return")
            return
        end
        -- 延迟时间
        local DelayTime = XUiHelper.GetClientConfig("PCplaytimeShow", XUiHelper.ClientConfigType.Int)
        NowPcNotice.OnlineHour = data.OnlineHour
        NowPcNotice.EndTime = XTime.GetServerNowTimestamp() + DelayTime
        XLuaUiManager.Open("UiNoticeTipsPC")
    end

    function XNoticeManager.Init()
        DisableFunction = XMain.IsDebug and XNoticeManager.CheckFuncDisable()
        DeviceId = CS.XHeroSdkAgent.GetDeviceId() --获取设备id
        XNoticeManager.InitNoticeCdnUrl()
        XNoticeManager.RequestIp()
        XNoticeManager.ReadLoginNoticeTime()
        --未登陆时使用通用蓝点
        XNoticeManager.ReadInGameNoticeReadList()

        XEventManager.AddEventListener(XEventId.EVENT_USER_LOGOUT, XNoticeManager.OnLogout)
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, XNoticeManager.OnLogin)
        XEventManager.AddEventListener(XEventId.EVENT_PHOTO_ENTER, function()
            ScreenShotFlag = true
        end)
        XEventManager.AddEventListener(XEventId.EVENT_PHOTO_LEAVE, function()
            ScreenShotFlag = false
        end)
    end

    function XNoticeManager.DebugLogInGameNoticeReadList()
        if XMain.IsDebug then
            XLog.Debug(InGameNoticeMap)
        end
    end

    XNoticeManager.Init()
    return XNoticeManager
end
