--- 漫画图鉴Agency组件
---@class XComicArchiveAgencyCom
---@field private _OwnerAgency XArchiveAgency
---@field private _Model XArchiveModel
local XComicArchiveAgencyCom = XClass(nil, 'XComicArchiveAgencyCom')

function XComicArchiveAgencyCom:Ctor(agency, model)
    self._OwnerAgency = agency
    self._Model = model
end

function XComicArchiveAgencyCom:Release()
    self._OwnerAgency = nil
    self._Model = nil
end

function XComicArchiveAgencyCom:UpdateComicDataFromLoginNotify(data)
    self._Model.ArchiveComicData:UpdateUnlockComicChapter(data.UnlockComics)
end

function XComicArchiveAgencyCom:UpdateUnlockComicDataFromNewNotify(data)
    self:AddNewComicRedPoint(data.UnlockComics)
end

--region ---------- 红点 ---------->>>

function XComicArchiveAgencyCom:CheckComicGroupRedShow(groupId)
    local hasReddot = false
    
    if XTool.IsNumberValid(groupId) then
        hasReddot = self._Model.ArchiveComicData:CheckComicGroupRedPointIsExistById(groupId)
    else
        hasReddot = self._Model.ArchiveComicData:CheckComicAnyRedPointIsExist()
    end
    
    return hasReddot
end

function XComicArchiveAgencyCom:CheckComicChapterRedShow(chapterId)
    return self._Model.ArchiveComicData:CheckComicChapterRedPointIsExistById(chapterId)
end

function XComicArchiveAgencyCom:AddNewComicRedPoint(chapterIds)
    if XTool.IsTableEmpty(chapterIds) then
        return
    end
    
    local timestamp = XTime.GetServerNowTimestamp()
    
    for _, id in pairs(chapterIds) do
        ---@type XTableArchiveComicChapter
        local chapterCfg = self._Model:GetComicChapterCfgById(id)

        if chapterCfg and chapterCfg.IsShowRedPoint then
            local isHide = false

            if not string.IsNilOrEmpty(chapterCfg.ShowTimeStr) then
                isHide = timestamp < XTime.ParseToTimestamp(chapterCfg.ShowTimeStr)
            end
            
            self._Model.ArchiveComicData:SetComicReddot(chapterCfg.GroupId, chapterCfg.Id, isHide)
        end
        
        self._Model.ArchiveComicData:AddUnlockComicChapter(id)
    end
    self._Model.ArchiveComicData:SaveComicReddot()
    XEventManager.DispatchEvent(XEventId.EVENT_ARCHIVE_NEW_COMIC)
end

--endregion <<<----------------------

return XComicArchiveAgencyCom