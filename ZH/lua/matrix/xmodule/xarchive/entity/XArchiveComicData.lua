--- 漫画图鉴数据实体
---@class XArchiveComicData
---@field private _Owner XArchiveModel
---@field private _ComicChapterCfgGroups table @章节配置按组分类后的表
local XArchiveComicData = XClass(nil, 'XArchiveComicData')


function XArchiveComicData:Ctor(owner)
    self._Owner = owner
    self._CGReddotKey = nil
    self._UnlockComicChapterIdsFromServer = {}
end

function XArchiveComicData:Release()
    self._Owner = nil
end

function XArchiveComicData:ResetData()
    self._IsChapterCfgsGrouping = false
    self._ChapterCfgsGroups = nil
    self._CGReddotKey = nil
    self._UnlockComicChapterIdsFromServer = {}
end

--- 释放配置表数据引用（后续重新读配置表时重新触发遍历分组）
function XArchiveComicData:ResetCfgs()
    self._IsChapterCfgsGrouping = false
    self._ChapterCfgsGroups = nil
end

function XArchiveComicData:UpdateUnlockComicChapter(unlockList)
    if XTool.IsTableEmpty(unlockList) then
        return
    end
    
    -- 转成字典，加速解锁判断的全遍历检查。 不转字典或不使用服务端数据的话，每次的condition的检查导致的开销可能比这里的遍历还要大
    for i, v in pairs(unlockList) do
        self._UnlockComicChapterIdsFromServer[v] = true
    end
end

function XArchiveComicData:AddUnlockComicChapter(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return
    end

    self._UnlockComicChapterIdsFromServer[chapterId] = true
end

function XArchiveComicData:GetComicChapterCfgsByGroupId(groupId)
    -- 没有指定组Id时，不执行后续分组操作，直接返回原表配置
    if not XTool.IsNumberValid(groupId) then
        return self._Owner:GetComicChapterCfgs()
    end
    
    if not self._IsChapterCfgsGrouping then
        self._ChapterCfgsGroups = {}
        
        local cfgs = self._Owner:GetComicChapterCfgs()

        if not XTool.IsTableEmpty(cfgs) then
            -- 分组
            ---@param cfg XTableArchiveComicChapter
            for i, cfg in pairs(cfgs) do
                if self._ChapterCfgsGroups[cfg.GroupId] == nil then
                    self._ChapterCfgsGroups[cfg.GroupId] = {}
                end
                
                table.insert(self._ChapterCfgsGroups[cfg.GroupId], cfg)
            end
            
            -- 排序
            local sort = function(a, b)
                if a.Order ~= b.Order then
                    return a.Order < b.Order
                end
                
                return a.Id > b.Id
            end
            
            for i, group in pairs(self._ChapterCfgsGroups) do
                table.sort(group, sort)
            end
        end
        self._IsChapterCfgsGrouping = true
    end
    
    return self._ChapterCfgsGroups[groupId]
end

--- 检查指定漫画是否已经在服务端标记为已解锁了，已解锁则不必再手动判断condition和unlockTime
function XArchiveComicData:CheckComicChapterIsMarkUnlock(chapterId)
    return self._UnlockComicChapterIdsFromServer[chapterId]
end

--region ---------- 红点 ---------->>>

function XArchiveComicData:GetComicRedPointSaveKey()
    if string.IsNilOrEmpty(self._CGReddotKey) then
        self._CGReddotKey = string.format("%d%s", XPlayer.Id, "ArchiveComic_Reddot")
    end
    return self._CGReddotKey
end

function XArchiveComicData:SetComicReddot(groupId, comicChapterId, isHide)
    local reddotTable = XSaveTool.GetData(self:GetComicRedPointSaveKey())

    if reddotTable == nil then
        reddotTable = {}
        XSaveTool.SaveData(self:GetComicRedPointSaveKey(), reddotTable)
    end
    
    -- 如果该章节隐藏，则暂时不作为红点
    if isHide then
        if reddotTable.WaitToShow == nil then
            reddotTable.WaitToShow = {}
        end

        table.insert(reddotTable.WaitToShow, comicChapterId)
        return
    end

    if reddotTable.GroupReddot == nil then
        reddotTable.GroupReddot = {}
    end

    if reddotTable.ComicChapterReddot == nil then
        reddotTable.ComicChapterReddot = {}
    end

    -- 组红点通过计数的方式
    if XTool.IsNumberValid(reddotTable.GroupReddot[groupId]) then
        reddotTable.GroupReddot[groupId] = reddotTable.GroupReddot[groupId] + 1
    else
        reddotTable.GroupReddot[groupId] = 1
    end

    reddotTable.ComicChapterReddot[comicChapterId] = true
end

---@return boolean @表示是否消除存在的红点缓存
function XArchiveComicData:ClearComicReddot(groupId, comicChapterId)
    local reddotTable = XSaveTool.GetData(self:GetComicRedPointSaveKey())

    -- 没有红点数据或指定的CG红点无缓存，则不执行清除逻辑
    if reddotTable == nil or XTool.IsTableEmpty(reddotTable.GroupReddot) or XTool.IsTableEmpty(reddotTable.ComicChapterReddot) then
        return false
    end

    if not reddotTable.ComicChapterReddot[comicChapterId] then
        return false
    end

    -- 组红点通过计数的方式
    if XTool.IsNumberValid(reddotTable.GroupReddot[groupId]) then
        local groupReddotCounter = reddotTable.GroupReddot[groupId] - 1
        reddotTable.GroupReddot[groupId] = groupReddotCounter > 0 and groupReddotCounter or nil
    else
        XLog.Error('漫画图鉴组红点计数错误，或错误地重复移除红点')
    end

    reddotTable.ComicChapterReddot[comicChapterId] = nil

    return true
end

function XArchiveComicData:ClearAllComicReddot()
    local reddotTable = XSaveTool.GetData(self:GetComicRedPointSaveKey())

    if reddotTable == nil then
        return
    end

    if not XTool.IsTableEmpty(reddotTable.ComicChapterReddot) then
        if XTool.IsTableEmpty(reddotTable.WaitToShow) then
            XSaveTool.SaveData(self:GetComicRedPointSaveKey(), false)
        else
            reddotTable.ComicChapterReddot = nil
            reddotTable.GroupReddot = nil
            reddotTable.HasAnyReddot = false

            XSaveTool.SaveData(self:GetComicRedPointSaveKey(), reddotTable)
        end
    end
end

function XArchiveComicData:SaveComicReddot()
    local reddotTable = XSaveTool.GetData(self:GetComicRedPointSaveKey())

    if not XTool.IsTableEmpty(reddotTable) then
        reddotTable.HasAnyReddot = not XTool.IsTableEmpty(reddotTable.GroupReddot)
    end

    XSaveTool.SaveData(self:GetComicRedPointSaveKey(), reddotTable)
end

--- 检查指定的漫画Chapter是否有红点缓存
function XArchiveComicData:CheckComicChapterRedPointIsExistById(id)
    local reddotTable = XSaveTool.GetData(self:GetComicRedPointSaveKey())
    self:CheckHideComicIsCanShow(reddotTable and reddotTable.WaitToShow or nil)
    
    if XTool.IsTableEmpty(reddotTable) or XTool.IsTableEmpty(reddotTable.ComicChapterReddot) then
        return false
    end

    return reddotTable.ComicChapterReddot[id]
end

--- 检查指定的漫画组是否有红点缓存
function XArchiveComicData:CheckComicGroupRedPointIsExistById(groupId)
    local reddotTable = XSaveTool.GetData(self:GetComicRedPointSaveKey())
    self:CheckHideComicIsCanShow(reddotTable and reddotTable.WaitToShow or nil)
    
    if XTool.IsTableEmpty(reddotTable) or XTool.IsTableEmpty(reddotTable.GroupReddot) then
        return false
    end

    return XTool.IsNumberValid(reddotTable.GroupReddot[groupId])
end

--- 检查漫画图鉴是否存在任意红点
function XArchiveComicData:CheckComicAnyRedPointIsExist()
    local reddotTable = XSaveTool.GetData(self:GetComicRedPointSaveKey())
    self:CheckHideComicIsCanShow(reddotTable and reddotTable.WaitToShow or nil)

    return reddotTable and reddotTable.HasAnyReddot or false
end

--- 检查隐藏的已解锁漫画图鉴，是否达到显示时间
function XArchiveComicData:CheckHideComicIsCanShow(waitToShow)
    if not XTool.IsTableEmpty(waitToShow) then
        local timeStamp = XTime.GetServerNowTimestamp()
        local anyReddotShow = false
        
        for i = 1, #waitToShow do
            local chapterId = waitToShow[i]
            local cfg = self._Owner:GetComicChapterCfgById(chapterId)

            if cfg then
                if string.IsNilOrEmpty(cfg.ShowTimeStr) then
                    XLog.Error('漫画图鉴章节Id：'..tostring(chapterId)..' 的显示时间配置字段错误: '..tostring(cfg.ShowTimeStr))
                elseif timeStamp >= XTime.ParseToTimestamp(cfg.ShowTimeStr) then
                    self:SetComicReddot(cfg.GroupId, cfg.Id)
                    table.remove(waitToShow, i)
                    anyReddotShow = true
                end
            end
        end

        if anyReddotShow then
            self:SaveComicReddot()
            XEventManager.DispatchEvent(XEventId.EVENT_ARCHIVE_NEW_COMIC)
        end
    end
end
--endregion <<<---------------------

return XArchiveComicData