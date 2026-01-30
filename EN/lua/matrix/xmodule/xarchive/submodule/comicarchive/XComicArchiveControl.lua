--- 漫画图鉴的子control
---@class XComicArchiveControl: XControl
---@field private _Model XArchiveModel
---@field private _MainControl XArchiveControl
local XComicArchiveControl = XClass(XControl, 'XComicArchiveControl')

function XComicArchiveControl:OnInit()

end

function XComicArchiveControl:AddAgencyEvent()

end

function XComicArchiveControl:RemoveAgencyEvent()

end

function XComicArchiveControl:OnRelease()

end

--- 漫画收集率
---@return string
function XComicArchiveControl:GetComicCompletionRate(groupId)
    local comicChapterList = self:GetComicChapterCfgsByGroupId(groupId)
    
    local totalCount = XTool.GetTableCount(comicChapterList)
    
    if totalCount <= 0 then
        return 0
    end
    
    local unLockCount = 0

    self._TmpChapterLockDescDict = nil

    for i, chapterCfg in pairs(comicChapterList) do
        if self:GetIsComicChapterUnlock(chapterCfg.Id) then
            unLockCount = unLockCount + 1
        end
    end

    if not XTool.IsTableEmpty(self._UnlockRequestList) then
        self:RequestUnlockArchiveComics(self._UnlockRequestList, function()
            self._UnlockRequestList = nil
        end)
    end
    
    return self._MainControl:GetPercent((unLockCount / totalCount) * 100)
end


function XComicArchiveControl:GetIsComicChapterUnlock(chapterId)
    -- 优先检查服务端缓存
    if self._Model.ArchiveComicData:CheckComicChapterIsMarkUnlock(chapterId) then
        return true
    end
    
    local comicChapterCfg = self._Model:GetComicChapterCfgById(chapterId)
    
    if not comicChapterCfg then 
        return false 
    end
    
    local IsUnLock, lockDes = false, ""
    
    --客户端判定
    local unLockTime = comicChapterCfg.UnLockTime
    unLockTime = unLockTime and XTime.ParseToTimestamp(unLockTime) or 0
    local conditionId = comicChapterCfg.Condition

    --- 如果有condition，那么需要分别判断unlocktime和condition
    if XTool.IsNumberValid(conditionId) then
        IsUnLock, lockDes = XConditionManager.CheckCondition(conditionId)

        -- 如果condition不满足，则判断是否满足解锁时间(无论时间是否满足，解锁条件文本均使用condition的
        if not IsUnLock and XTool.IsNumberValid(unLockTime) then
            local nowTime = XTime.GetServerNowTimestamp()
            IsUnLock = nowTime >= unLockTime
        end
    else
        IsUnLock, lockDes = true, ""
    end
    
    -- 如果客户端单方面解锁，需要请求
    if IsUnLock then
        if self._UnlockRequestList == nil then
            self._UnlockRequestList = {}
        end

        table.insert(self._UnlockRequestList, chapterId)
    else
        -- 记录未解锁描述，冻结此次检查的结果，直到再次执行该检查
        if self._TmpChapterLockDescDict == nil then
            self._TmpChapterLockDescDict = {}
        end

        self._TmpChapterLockDescDict[chapterId] = lockDes
    end

    return IsUnLock, lockDes
end

--- 专门给漫画动态列表中的单个章节使用
--- 因为动态列表的检查具有滞后性（显示该章节时才检查），当存在时间类的解锁条件时，滑动过程中突然解锁和收集率显示变化很突兀
--- 因此当切换页签后，冻结各章节解锁状态
function XComicArchiveControl:GetIsComicChapterUnlockForShow(chapterId)
    if not XTool.IsTableEmpty(self._TmpChapterLockDescDict) then
        if self._TmpChapterLockDescDict[chapterId] then
            return false, self._TmpChapterLockDescDict[chapterId]
        end 
    end
    
    return true
end

--region ---------- Configs ---------->>>
function XComicArchiveControl:GetComicGroupCfgs(isSort)
    local cfgs = self._Model:GetComicGroupCfgs()

    if not isSort then
        return self._Model:GetComicGroupCfgs()
    end
    
    local result = {}

    if not XTool.IsTableEmpty(cfgs) then
        for i, v in pairs(cfgs) do
            table.insert(result, v)
        end
        
        table.sort(result, function(a, b)
            if a.Order ~= b.Order then
                return a.Order < b.Order
            end
            
            return a.Id > b.Id
        end)
    end
    
    return result
end

function XComicArchiveControl:GetComicChapterCfgsByGroupId(groupId, ignoreTimeCheck)
    local cfgs = self._Model.ArchiveComicData:GetComicChapterCfgsByGroupId(groupId)

    if ignoreTimeCheck then
        return cfgs
    end
    
    local result = {}

    if not XTool.IsTableEmpty(cfgs) then
        local timeStamp = XTime.GetServerNowTimestamp()
        
        for i, chapterCfg in pairs(cfgs) do
            ---@type XTableArchiveComicGroup
            local groupCfg = self._Model:GetComicGroupCfgById(chapterCfg.GroupId)

            if not groupCfg or string.IsNilOrEmpty(groupCfg.ShowTimeStr) or timeStamp >= XTime.ParseToTimestamp(groupCfg.ShowTimeStr) then
                if string.IsNilOrEmpty(chapterCfg.ShowTimeStr) then
                    table.insert(result, chapterCfg)
                else
                    if timeStamp >= XTime.ParseToTimestamp(chapterCfg.ShowTimeStr) then
                        table.insert(result, chapterCfg)
                    end
                end
            end
        end
    end

    return result
end

function XComicArchiveControl:GetComicDetailCfgById(id)
    return self._Model:GetComicDetailCfgById(id)
end
--endregion <<<--------------------------

--region ---------- 红点 ---------->>>

function XComicArchiveControl:ClearAllComicGroupRedShow()
    self._Model.ArchiveComicData:ClearAllComicReddot()
    XEventManager.DispatchEvent(XEventId.EVENT_ARCHIVE_MARK_COMIC)
end

function XComicArchiveControl:ClearComicGroupRedShow(groupId)
    local comicChapterList = self:GetComicChapterCfgsByGroupId(groupId)

    if not XTool.IsTableEmpty(comicChapterList) then
        local anyRedClear = false
        
        for i, chapterCfg in pairs(comicChapterList) do
            if self._Model.ArchiveComicData:ClearComicReddot(groupId, chapterCfg.Id) then
                anyRedClear = true
            end
        end

        if anyRedClear then
            self._Model.ArchiveComicData:SaveComicReddot()
            XEventManager.DispatchEvent(XEventId.EVENT_ARCHIVE_MARK_COMIC)
        end
    end
end

function XComicArchiveControl:ClearComicChapterRedShow(chapterId)
    ---@type XTableArchiveComicChapter
    local chapterCfg = self._Model:GetComicChapterCfgById(chapterId)
    
    if chapterCfg and self._Model.ArchiveComicData:ClearComicReddot(chapterCfg.GroupId, chapterId) then
        self._Model.ArchiveComicData:SaveComicReddot()
        XEventManager.DispatchEvent(XEventId.EVENT_ARCHIVE_MARK_COMIC)
    end
end

--endregion <<<----------------------

--region ---------- 协议 ---------->>>

function XComicArchiveControl:RequestUnlockArchiveComics(ids, successCb)
    XNetwork.Call("UnlockArchiveComicsRequest", { Ids = ids }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        
        XMVCA.XArchive.ComicArchiveCom:AddNewComicRedPoint(res.SuccessIds)

        if successCb then
            successCb()
        end
    end)
end

--endregion <<<----------------------

return XComicArchiveControl