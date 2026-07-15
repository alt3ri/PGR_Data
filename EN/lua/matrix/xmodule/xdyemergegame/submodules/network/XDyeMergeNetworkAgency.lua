---@class XDyeMergeNetworkAgency : XAgency
---@field private _Model XDyeMergeGameModel
---@field private _MainAgency XDyeMergeGameAgency
local XDyeMergeNetworkAgency = XClass(XAgency, "XDyeMergeNetworkAgency")

-- 请求锁是内部用的，在内部定义枚举即可
local NetworkLockFlagEnum = {
    DyeMergeTryEnterStageRequest = 1,
    DyeMergeTryCompleteStageRequest = 2,
}

function XDyeMergeNetworkAgency:OnInit()
    self._NetworkRequestLock = nil
end

function XDyeMergeNetworkAgency:InitRpc()
    XRpc.DyeMergeStagesRecordNotify = handler(self, self.OnDyeMergeStagesRecordNotify)
end

function XDyeMergeNetworkAgency:InitEvent()

end

function XDyeMergeNetworkAgency:ResetAll()
    self._NetworkRequestLock = nil
end

function XDyeMergeNetworkAgency:OnRelease()

end

--region Lock - 简单的逻辑锁，主要是控制协议请求频率

function XDyeMergeNetworkAgency:CheckFlagIsLock(flag)
    return self._NetworkRequestLock and self._NetworkRequestLock[flag] or false
end

function XDyeMergeNetworkAgency:LockWithFlag(flag)
    if self._NetworkRequestLock == nil then
        self._NetworkRequestLock = {}
    end
    
    self._NetworkRequestLock[flag] = true
end

function XDyeMergeNetworkAgency:UnlockWithFlag(flag)
    if XTool.IsTableEmpty(self._NetworkRequestLock) then
        return
    end

    self._NetworkRequestLock[flag] = false
end

--endregion

--region Network Request

--- 进入关卡
function XDyeMergeNetworkAgency:DoDyeMergeTryEnterStageRequest(stageId, cb)
    if self:CheckFlagIsLock(NetworkLockFlagEnum.DyeMergeTryEnterStageRequest) then
        return
    end
    
    -- 保底检查在不在活动时间内
    if not XMVCA.XDyeMergeGame:GetIsActivityOpen(true) then
        return
    end
    
    self:LockWithFlag(NetworkLockFlagEnum.DyeMergeTryEnterStageRequest)
    
    XNetwork.Call("DyeMergeTryEnterStageRequest", { StageId = stageId }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.DyeMergeTryEnterStageRequest)

        if res.Code ~= XCode.Success then
            if cb then
                cb(false)
            end
            XUiManager.TipCode(res.Code)
            return
        end
        
        if cb then
            cb(true)
        end
    end, nil, function(exception) 
        self:UnlockWithFlag(NetworkLockFlagEnum.DyeMergeTryEnterStageRequest)

        -- 因为重写了这个回调，所以这里要手动处理错误提示，与C#端逻辑一致
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 完成关卡
function XDyeMergeNetworkAgency:DoDyeMergeTryCompleteStageRequest(stageId, cb)
    if self:CheckFlagIsLock(NetworkLockFlagEnum.DyeMergeTryCompleteStageRequest) then
        return
    end

    -- 保底检查在不在活动时间内
    if not XMVCA.XDyeMergeGame:GetIsActivityOpen(true) then
        return
    end

    self:LockWithFlag(NetworkLockFlagEnum.DyeMergeTryCompleteStageRequest)
    
    XNetwork.Call("DyeMergeTryCompleteStageRequest", { StageId = stageId }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.DyeMergeTryCompleteStageRequest)

        if res.Code ~= XCode.Success then
            if cb then
                cb(false)
            end
            XUiManager.TipCode(res.Code)
            return
        end

        -- 更新通关缓存
        self._Model:UpdateStageRecord(stageId)
        
        if cb then
            cb(true)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.DyeMergeTryCompleteStageRequest)

        -- 因为重写了这个回调，所以这里要手动处理错误提示，与C#端逻辑一致
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--endregion

--region RPC

function XDyeMergeNetworkAgency:OnDyeMergeStagesRecordNotify(data)
    self._Model:UpdateFUllActivityData(data)
end

--endregion

return XDyeMergeNetworkAgency