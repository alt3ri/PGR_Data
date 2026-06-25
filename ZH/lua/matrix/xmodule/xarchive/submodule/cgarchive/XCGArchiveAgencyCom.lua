--- CG图鉴Agency组件
---@class XCGArchiveAgencyCom
---@field private _OwnerAgency XArchiveAgency
---@field private _Model XArchiveModel
local XCGArchiveAgencyCom = XClass(nil, 'XCGArchiveAgencyCom')

function XCGArchiveAgencyCom:Ctor(agency, model)
    self._OwnerAgency = agency
    self._Model = model
end

function XCGArchiveAgencyCom:Release()
    self._OwnerAgency = nil
    self._Model = nil
end

--region ---------- 配置表相关 ---------->>>

--- 获取对应CG组的CGDetail列表
---@return table<XArchiveCGEntity>
function XCGArchiveAgencyCom:GetArchiveCGDetailGroup(group)
    if XTool.IsNumberValid(group) then
        return self._Model:GetArchiveCGDetailList()[group]
    end
end

--- 获取所有CGDetail实体的列表
---@return table<XArchiveCGEntity>
function XCGArchiveAgencyCom:GetArchiveCGDetailList()
    return self._Model:GetArchiveCGDetailData()
end

--endregion <<<---------------------------

--region ---------- 红点相关 ---------->>>

--- 检查指定CG组是否有蓝点，如果未指定groupId，则判断整个CG图鉴是否存在任意红点
function XCGArchiveAgencyCom:CheckCGRedPointByGroup(groupId)
    local hasReddot = false
    
    if XTool.IsNumberValid(groupId) then
        hasReddot = self._Model.ArchiveCGData:CheckCGGroupRedPointIsExistById(groupId)
    else
        hasReddot = self._Model.ArchiveCGData:CheckCGAnyRedPointIsExist()
    end
    
    return hasReddot
end

function XCGArchiveAgencyCom:CheckCGRedPoint(id)
    return self._Model.ArchiveCGData:CheckCGRedPointIsExistById(id)
end

function XCGArchiveAgencyCom:AddNewCGRedPoint(idList)
    if XTool.IsTableEmpty(idList) then
        return
    end

    local timestamp = XTime.GetServerNowTimestamp()

    for _,id in pairs(idList) do
        local shouldShow, isHide, groupId = self._Model:CheckCGShouldShowRedPoint(id, timestamp)
        if shouldShow then
            self._Model.ArchiveCGData:SetCGReddot(groupId, id, isHide)
        end
    end

    self._Model.ArchiveCGData:SaveCGReddot()
end
--endregion <<<-------------------------


return XCGArchiveAgencyCom