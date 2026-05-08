---@class XAprilFoolDayControl : XControl
---@field private _Model XAprilFoolDayModel
local XAprilFoolDayControl = XClass(XControl, "XAprilFoolDayControl")
function XAprilFoolDayControl:OnInit()
    --初始化内部变量
end

function XAprilFoolDayControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XAprilFoolDayControl:RemoveAgencyEvent()

end

function XAprilFoolDayControl:OnRelease()

end

function XAprilFoolDayControl:GetCurFoolsDaySceneUrl()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValidEx(activityId) then
        local cfg = self._Model:GetFoolsDayMainInterfaceConfigById(activityId)

        if cfg then
            return cfg.SceneId
        end
    end
    
    return 0
end

function XAprilFoolDayControl:GetCurFoolsDayRoleId()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValidEx(activityId) then
        local cfg = self._Model:GetFoolsDayMainInterfaceConfigById(activityId)

        if cfg then
            return cfg.RoleId
        end
    end

    return 0
end

function XAprilFoolDayControl:GetCurClearOutActionIdByTimes(times)
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValidEx(activityId) then
        local cfg = self._Model:GetFoolsDayMainInterfaceConfigById(activityId)

        if cfg then
            return cfg.ClearOutActionIds[times] or ''
        end
    end

    return ''
end

function XAprilFoolDayControl:GetCurClearOutContentByTimes(times)
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValidEx(activityId) then
        local cfg = self._Model:GetFoolsDayMainInterfaceConfigById(activityId)

        if cfg then
            return cfg.ClearOutContents[times] or ''
        end
    end

    return ''
end

function XAprilFoolDayControl:GetCurClearOutContentShowTimeByTimes(times)
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValidEx(activityId) then
        local cfg = self._Model:GetFoolsDayMainInterfaceConfigById(activityId)

        if cfg then
            return cfg.ContentShowTimeList[times] or 1
        end
    end

    return 1
end

---@return XTableFoolsDayActivityBroadcast
function XAprilFoolDayControl:GetFoolsDayActivityBroadcastCfgById(id)
    return self._Model:GetFoolsDayActivityBroadcastCfgById(id)
end

--- 获取本地缓存，愚人节踢飞次数
function XAprilFoolDayControl:GetPlayerTickOutTimes()
    return self._Model:GetPlayerTickOutTimes()
end

--- 愚人节踢飞次数 + 1到本地缓存
function XAprilFoolDayControl:AddPlayerTickOutTimes()
    return self._Model:AddPlayerTickOutTimes()
end

--- 检查踢飞次数是否达最大
function XAprilFoolDayControl:CheckClearOutIsMax()
    return self._Model:CheckClearOutIsMax()
end

--- 更换模型和加载展示状态机，完成后调用回调。
---@param panelRoleModel XUiPanelRoleModel
function XAprilFoolDayControl:UpdateRoleModel(panelRoleModel, resId, cb)
    if not panelRoleModel or not resId then
        if cb then
            cb()
        end
        return
    end
    
    local state = {}

    -- 初始化信息
    state.Panel = panelRoleModel
    state.Id = resId
    --state.Callback = cb
    state.IsLoading = true
    state.ModelName = XMVCA.XCharacter:GetCharResModel(resId)

    state.RerollData = function()
        state.RollData = XDataCenter.DisplayManager.RandBehavior(state.ModelName)
    end
    
    --获取Controller名字
    state.RuntimeControllerName = XModelManager.GetUiDisplayControllerPath(state.ModelName)

    -- 更换模型
    local callback = function(model)
        state.Model = model
        state.Animator = state.Model:GetComponent("Animator")
        XDataCenter.DisplayManager.OnAssetLoaded(state)
    end
    state.Callback = function()
        if cb then cb() end
    end
    
    panelRoleModel:UpdateRoleModel(state.ModelName, nil, panelRoleModel.RefName, callback, true, true)

    -- 加载animationController
    if not string.IsNilOrEmpty(state.RuntimeControllerName) then
        local animator = panelRoleModel:GetAnimator()
        if not animator then
            return
        end

        local runtimeController = CS.LoadHelper.LoadUiController(state.RuntimeControllerName, animator.gameObject)
        if runtimeController == nil or not runtimeController:Exist() then
            XLog.Error("XUiPanelDisplay RefreshSelf 错误: 展示角色的动画状态机加载失败: 状态机名称 " .. state.RuntimeControllerName .. " Ui名称：" .. panelRoleModel.RefName)
            return
        end

        state.RunTimeController = runtimeController
        animator.runtimeAnimatorController = runtimeController
        ---@type UnityEngine.GameObject
        local loadAnimationClip = animator.gameObject:GetComponent(typeof(CS.XLoadAnimationClip))
        if loadAnimationClip then
            CS.UnityEngine.Component.Destroy(loadAnimationClip)
        end
    end
    
    if not state.Model then
        return
    end

    XDataCenter.DisplayManager.OnAssetLoaded(state)

    -- 两个都OK的时候触发回调
    return state
end


--- 2026愚人节假看板点击事件埋点
function XAprilFoolDayControl:RecordAprilFoolDayMainUiBtnClick(btnIndex)
    -- 记录埋点
    local dict = {}

    dict["BtnId"] = btnIndex

    if XMain.IsWindowsEditor then
        CS.XRecord.RecordTest(dict, "1000026", "AprilFoolsDayMainUi")
    else
        CS.XRecord.Record(dict, "1000026", "AprilFoolsDayMainUi")
    end
end

return XAprilFoolDayControl