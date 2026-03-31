---@class XFashionSuitControl : XControl
---@field private _Model XFashionSuitModel
local XFashionSuitControl = XClass(XControl, "XFashionSuitControl")
XFashionSuitControl.FashionSuitType = {
    Lock = 1,
    Unlock = 2,
}
function XFashionSuitControl:OnInit()

end

function XFashionSuitControl:AddAgencyEvent()

end

function XFashionSuitControl:RemoveAgencyEvent()

end

function XFashionSuitControl:OnRelease()

end

--region 配置

---@return string
function XFashionSuitControl:GetClientConfig(key, index)
    index = index or 1
    local config = self._Model:GetClientConfigById(key)
    if config then
        return config.Values[index]
    end
    return nil
end

---@return number
function XFashionSuitControl:GetIntClientConfig(key, index)
    local value = self:GetClientConfig(key, index)
    if value then
        return tonumber(value)
    end
    return nil
end

---@return XTableFashionSuit
function XFashionSuitControl:GetFashionSuitById(id)
    return self._Model:GetFashionSuitById(id)
end

--endregion

function XFashionSuitControl:IsSuitRewardGain(id)
    return self._Model:IsSuitRewardGain(id)
end

function XFashionSuitControl:GetCollectCount(suitId)
    local count = 0
    local fashionIds = self:GetFashionSuitById(suitId).FashionIds
    for _, fashionId in pairs(fashionIds) do
        if XDataCenter.FashionManager.CheckHasFashion(fashionId) then
            count = count + 1
        end
    end
    return count
end

function XFashionSuitControl:SetFashionViewed(fashionId)
    if not fashionId or XWeaponFashionConfigs.IsWeaponFashion(fashionId) then
        return
    end
    self._Model:SetFashionViewed(fashionId)
end

function XFashionSuitControl:IsFashionViewed(fashionId)
    if not fashionId or XWeaponFashionConfigs.IsWeaponFashion(fashionId) then
        return false
    end
    return self._Model:IsFashionViewed(fashionId)
end

---领取涂装套装奖励
function XFashionSuitControl:RequestGetSuitReward(suitId, cb)
    local req = {}
    req.SuitId = suitId
    XNetwork.CallWithAutoHandleErrorCode("FashionGetSuitRewardRequest", req, function(res)
        self._Model:SetSuitRewardGain(suitId)
        XUiManager.OpenUiObtain(res.RewardGoodsList)
        if cb then
            cb()
        end
    end)
end

function XFashionSuitControl:GetFashionSuitConfigsSort()
    local cfgsDict = self._Model:GetFashionSuitConfigs()
    -- 将字典转换为数组
    local cfgs = {}
    for _, cfg in pairs(cfgsDict) do
        table.insert(cfgs, cfg)
    end
    --配置表排序 按照Sort降序 如果Sort相同则按照Id升序
    local function sortFunc(a, b)
        if a.Sort ~= b.Sort then
            return a.Sort > b.Sort
        end
        return a.Id < b.Id
    end
    table.sort(cfgs, sortFunc)
    return cfgs
end

--region 打脸弹窗相关

function XFashionSuitControl:GetShowFashionSuitNotice(noticeIds)
    local cfgs = {}
    if noticeIds then
        for _, noticeId in pairs(noticeIds) do
            local cfg = self._Model:GetFashionSuitNoticeConfigById(noticeId)
            if cfg then
                table.insert(cfgs, cfg)
            end
        end
    else
        cfgs = self._Model:GetFashionSuitNoticeConfigs()
    end

    local showFashions = {}
    for _, cfg in pairs(cfgs) do
        local beginTime, endTime = XFunctionManager.GetTimeByTimeId(cfg.TimeId)
        local now = XTime.GetServerNowTimestamp()
        if cfg.TimeId == 0 or (now >= beginTime and now < endTime) then
            for _, fashionId in pairs(cfg.FashionIds) do
                table.insert(showFashions, fashionId)
            end
        end
    end
    return showFashions
end

function XFashionSuitControl:GetNoticeFashionSuitIds()
    local cfgs = self._Model:GetFashionSuitNoticeConfigs()
    local noticeSuitIds = {}
    local saveData = XSaveTool.GetData("NoticeFashionSuitIds") or {}
    for _, cfg in pairs(cfgs) do
        local beginTime, endTime = XFunctionManager.GetTimeByTimeId(cfg.TimeId)
        local now = XTime.GetServerNowTimestamp()
        local today = XTime.GetTodayTime()
        if not saveData[cfg.Id] or today ~= saveData[cfg.Id] then
            if cfg.TimeId == 0 or (now >= beginTime and now < endTime) then
                table.insert(noticeSuitIds, cfg.Id)
            end
        end
    end
    return #noticeSuitIds > 0 and noticeSuitIds or nil
end

function XFashionSuitControl:MarkNoticeFashionSuitIdIsRead(noticeSuitId)
    local saveData = XSaveTool.GetData("NoticeFashionSuitIds") or {}
    saveData[noticeSuitId] = XTime.GetTodayTime()
    XSaveTool.SaveData("NoticeFashionSuitIds", saveData)
end

function XFashionSuitControl:GetNoticeIdByFashionId(fashionId)
    local cfgs = self._Model:GetFashionSuitNoticeConfigs()
    for _, cfg in pairs(cfgs) do
        for _, id in pairs(cfg.FashionIds) do
            if id == fashionId then
                return cfg.Id
            end
        end
    end
    return nil
end
--endregion
return XFashionSuitControl
