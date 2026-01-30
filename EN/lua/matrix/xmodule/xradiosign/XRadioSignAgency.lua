---@class XRadioSignAgency : XAgency
---@field private _Model XRadioSignModel
local XRadioSignAgency = XClass(XAgency, "XRadioSignAgency")
function XRadioSignAgency:OnInit()
    --初始化一些变量
end

function XRadioSignAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyRadioSignPlayerDataDb = Handler(self, self.NotifyRadioSignPlayerDataDb)
end

function XRadioSignAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

function XRadioSignAgency:OpenMain()
    if self:IsInTime(true) then
        XLuaUiManager.Open("UiRadioSignMain")
        return true
    end
    return false
end

function XRadioSignAgency:NotifyRadioSignPlayerDataDb(data)
    self._Model:SetDataFromServer(data.RadioSignDataDb)
end

function XRadioSignAgency:IsInTime(tipText)
    ---@type XTableRadioSignActivity
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        if tipText then
            XUiManager.TipText("ActivityBranchNotOpen")
        end
        return false
    end
    local timeId = activityConfig.TimeId
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        if tipText then
            XUiManager.TipText("ActivityBranchNotOpen")
        end
        return false
    end
    return true
end

function XRadioSignAgency:Popup()
    if self:IsInTime() then
        local contentOpened
        local contents = self._Model:GetContentConfigs()
        
        -- 获取已弹出过的contentId列表（从本地存储读取）
        local popupContentIds = self._Model:GetPopupContentIds()
        local popupContentIdsMap = {}
        for _, id in ipairs(popupContentIds) do
            popupContentIdsMap[id] = true
        end
        
        -- 将 contents 转换为数组并按 id 排序
        local sortedContents = {}
        for _, content in pairs(contents) do
            table.insert(sortedContents, content)
        end
        table.sort(sortedContents, function(a, b)
            return a.Id < b.Id
        end)
        
        -- 按 id 顺序遍历
        for i, content in ipairs(sortedContents) do
            local timeId = content.TimeId
            if XFunctionManager.CheckInTimeByTimeId(timeId) then
                if not self._Model:IsContentReceived(content.Id) then
                    -- 检查是否已经弹出过
                    if not popupContentIdsMap[content.Id] then
                        -- 检查解锁顺序：前一个尚未领取的，下一个就不进行popup判定
                        if i > 1 then
                            local prevContent = sortedContents[i - 1]
                            if prevContent and not self._Model:IsContentReceived(prevContent.Id) then
                                -- 前一个尚未领取，跳过当前content
                                break
                            end
                        end
                        
                        contentOpened = content
                        break
                    end
                end
            end
        end
        if contentOpened then
            -- 保存已弹出的contentId到本地
            self._Model:AddPopupContentId(contentOpened.Id)
            
            XLuaUiManager.Open("UiRadioSignPopupHall", contentOpened)
            return true
        end
    end
    return false
end

function XRadioSignAgency:DebugOpenPopup()
    if not XMain.IsEditorDebug then
        XLog.Error("[XRadioSignAgency] DebugOpenPopup: 此方法仅在编辑器调试模式下可用")
        return
    end
    
    local contentOpened
    local contents = self._Model:GetContentConfigs()
    
    -- 将 contents 转换为数组并按 id 排序
    local sortedContents = {}
    for _, content in pairs(contents) do
        table.insert(sortedContents, content)
    end
    table.sort(sortedContents, function(a, b)
        return a.Id < b.Id
    end)
    
    -- 按 id 顺序遍历
    for _, content in ipairs(sortedContents) do
        local timeId = content.TimeId
        if XFunctionManager.CheckInTimeByTimeId(timeId) then
            if not self._Model:IsContentReceived(content.Id) then
                contentOpened = content
                break
            end
        end
    end
    if not contentOpened then
        for _, content in ipairs(sortedContents) do
            contentOpened = content
            break
        end
    end
    if contentOpened then
        XLuaUiManager.Open("UiRadioSignPopupHall", contentOpened)
    end
end

function XRadioSignAgency:RadioSignGainRewardRequest(signContextId, callback, delayShowReward)
    XNetwork.Call("RadioSignGainRewardRequest", {
        SignContextId = signContextId
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if callback then
                callback(false, nil)
            end
            return
        end
        
        -- 请求成功后，更新model中的缓存
        self._Model:AddContentReceived(signContextId)
        XLog.Debug("[XRadioSignAgency] RadioSignGainRewardRequest: 请求成功，已更新缓存, signContextId =", signContextId)
        
        -- 如果不需要延后显示奖励，立即弹出
        if not delayShowReward and res.RewardGoodsList then
            XUiManager.OpenUiObtain(res.RewardGoodsList)
        end
        
        if callback then
            -- 将奖励列表通过回调返回，让调用方决定何时弹出
            callback(true, res.RewardGoodsList)
        end
    end)
end

-- 检查是否有可领取的奖励（用于红点系统）
-- @return boolean 如果有符合时间且未领取的奖励，返回true
function XRadioSignAgency:HasRewardAvailable()
    local contents = self._Model:GetContentConfigs()
    if not contents then
        return false
    end

    -- 遍历所有 content，检查是否有符合时间且未领取的奖励
    for _, content in pairs(contents) do
        if content and content.TimeId then
            -- 检查时间是否符合
            if XFunctionManager.CheckInTimeByTimeId(content.TimeId) then
                -- 检查是否已领取
                if not self._Model:IsContentReceived(content.Id) then
                    -- 符合时间且有奖励可领取，返回 true
                    return true
                end
            end
        end
    end

    return false
end

--- Debug方法：清空已弹出过的contentId本地缓存
function XRadioSignAgency:DebugClearPopupCache()
    if not XMain.IsEditorDebug then
        XLog.Error("[XRadioSignAgency] DebugClearPopupCache: 此方法仅在编辑器调试模式下可用")
        return
    end
    
    self._Model:ClearPopupContentIds()
    XUiManager.TipMsg("已清空RadioSign弹出缓存")
end

return XRadioSignAgency