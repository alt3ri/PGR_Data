--- CG图鉴数据实体
---@class XArchiveCGData
---@field private _Owner XArchiveModel
local XArchiveCGData = XClass(nil, 'XArchiveCGData')

function XArchiveCGData:Ctor(owner)
    self._Owner = owner
    self._CGReddotKey = nil
end

function XArchiveCGData:Release()
    self._Owner = nil
end

function XArchiveCGData:ResetData()
    self._CGReddotKey = nil
end

--region ---------- 红点相关 ---------->>>

function XArchiveCGData:GetCGRedPointSaveKey()
    if string.IsNilOrEmpty(self._CGReddotKey) then
        self._CGReddotKey = string.format("%d%s", XPlayer.Id, "ArchiveCG_Reddot")
    end
    return self._CGReddotKey
end

function XArchiveCGData:SetCGReddot(groupId, cgDetailId, isHide)
    local reddotTable = XSaveTool.GetData(self:GetCGRedPointSaveKey())

    if reddotTable == nil then
        reddotTable = {}
        XSaveTool.SaveData(self:GetCGRedPointSaveKey(), reddotTable)
    end

    -- 如果该CG隐藏，则暂时不作为红点
    if isHide then
        if reddotTable.WaitToShow == nil then
            reddotTable.WaitToShow = {}
        end

        table.insert(reddotTable.WaitToShow, cgDetailId)
        return
    end
    
    if reddotTable.GroupReddot == nil then
        reddotTable.GroupReddot = {}
    end

    if reddotTable.CGReddot == nil then
        reddotTable.CGReddot = {}
    end

    -- 组红点通过计数的方式
    if XTool.IsNumberValid(reddotTable.GroupReddot[groupId]) then
        reddotTable.GroupReddot[groupId] = reddotTable.GroupReddot[groupId] + 1
    else
        reddotTable.GroupReddot[groupId] = 1
    end
    
    reddotTable.CGReddot[cgDetailId] = true
end

---@return boolean @表示是否消除存在的红点缓存
function XArchiveCGData:ClearCGReddot(groupId, cgDetailId)
    local reddotTable = XSaveTool.GetData(self:GetCGRedPointSaveKey())
    
    -- 没有红点数据或指定的CG红点无缓存，则不执行清除逻辑
    if reddotTable == nil or XTool.IsTableEmpty(reddotTable.GroupReddot) or XTool.IsTableEmpty(reddotTable.CGReddot) then
        return false
    end

    if not reddotTable.CGReddot[cgDetailId] then
        return false
    end

    -- 组红点通过计数的方式
    if XTool.IsNumberValid(reddotTable.GroupReddot[groupId]) then
        local groupReddotCounter = reddotTable.GroupReddot[groupId] - 1
        reddotTable.GroupReddot[groupId] = groupReddotCounter > 0 and groupReddotCounter or nil
    else
        XLog.Error('CG图鉴组红点计数错误，或错误地重复移除红点')
    end

    reddotTable.CGReddot[cgDetailId] = nil
    
    return true
end

function XArchiveCGData:ClearAllCGReddot()
    local reddotTable = XSaveTool.GetData(self:GetCGRedPointSaveKey())

    if reddotTable == nil then
        return
    end
    
    if not XTool.IsTableEmpty(reddotTable.CGReddot) then
        if XTool.IsTableEmpty(reddotTable.WaitToShow) then
            XSaveTool.SaveData(self:GetCGRedPointSaveKey(), false)
        else
            reddotTable.GroupReddot = nil
            reddotTable.CGReddot = nil
            reddotTable.HasAnyReddot = false

            XSaveTool.SaveData(self:GetCGRedPointSaveKey(), reddotTable)
        end
    end
end

function XArchiveCGData:SaveCGReddot()
    local reddotTable = XSaveTool.GetData(self:GetCGRedPointSaveKey())

    if not XTool.IsTableEmpty(reddotTable) then
        reddotTable.HasAnyReddot = not XTool.IsTableEmpty(reddotTable.GroupReddot)
    end
    
    XSaveTool.SaveData(self:GetCGRedPointSaveKey(), reddotTable)
end

--- 检查指定的CGDetail是否有红点缓存
function XArchiveCGData:CheckCGRedPointIsExistById(id)
    local reddotTable = XSaveTool.GetData(self:GetCGRedPointSaveKey())
    self:CheckHideCGIsCanShow(reddotTable and reddotTable.WaitToShow or nil)
    
    if XTool.IsTableEmpty(reddotTable) or XTool.IsTableEmpty(reddotTable.CGReddot) then
        return false
    end
    
    return reddotTable.CGReddot[id]
end

--- 检查指定的CG组是否有红点缓存
function XArchiveCGData:CheckCGGroupRedPointIsExistById(groupId)
    local reddotTable = XSaveTool.GetData(self:GetCGRedPointSaveKey())
    self:CheckHideCGIsCanShow(reddotTable and reddotTable.WaitToShow or nil)
    
    if XTool.IsTableEmpty(reddotTable) or XTool.IsTableEmpty(reddotTable.GroupReddot) then
        return false
    end

    return XTool.IsNumberValid(reddotTable.GroupReddot[groupId])
end

--- 检查CG图鉴是否存在任意红点
function XArchiveCGData:CheckCGAnyRedPointIsExist()
    local reddotTable = XSaveTool.GetData(self:GetCGRedPointSaveKey())
    self:CheckHideCGIsCanShow(reddotTable and reddotTable.WaitToShow or nil)
    
    return reddotTable and reddotTable.HasAnyReddot or false
end

--- 检查隐藏的已解锁CG图鉴，是否达到显示时间
function XArchiveCGData:CheckHideCGIsCanShow(waitToShow)
    if not XTool.IsTableEmpty(waitToShow) then
        local timeStamp = XTime.GetServerNowTimestamp()
        local anyReddotShow = false

        for i = 1, #waitToShow do
            local chapterId = waitToShow[i]
            ---@type XTableArchiveCGDetail
            local cfg = self._Owner:GetCGDetail()[chapterId]

            if cfg then
                if string.IsNilOrEmpty(cfg.ShowTimeStr) then
                    XLog.Error('漫画图鉴章节Id：'..tostring(chapterId)..' 的显示时间配置字段错误: '..tostring(cfg.ShowTimeStr))
                elseif timeStamp >= XTime.ParseToTimestamp(cfg.ShowTimeStr) then
                    self:SetCGReddot(cfg.GroupId, cfg.Id)
                    table.remove(waitToShow, i)
                    anyReddotShow = true
                end
            end
        end

        if anyReddotShow then
            self:SaveCGReddot()
            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_CG)
        end
    end
end
--endregion <<<-------------------------

return XArchiveCGData