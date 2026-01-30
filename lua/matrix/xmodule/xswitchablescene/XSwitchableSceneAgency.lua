---@class XSwitchableSceneAgency : XAgency
---@field private _Model XSwitchableSceneModel
local XSwitchableSceneAgency = XClass(XAgency, "XSwitchableSceneAgency")

local PlayFull = 1
local PlayLow = 2

function XSwitchableSceneAgency:OnInit()
    
end

function XSwitchableSceneAgency:InitRpc()
    --实现服务器事件注册
end

function XSwitchableSceneAgency:InitEvent()
    --实现跨Agency事件注册
end

---设置当前播放进度，保证切换到其他界面时，场景动画能衔接上
function XSwitchableSceneAgency:SetPlayProgress(value)
    self._Model._PlayProgress = value
end

function XSwitchableSceneAgency:GetPlayProgress()
    return self._Model._PlayProgress or 0
end

function XSwitchableSceneAgency:GetSpeedByAngle(sceneId, angle)
    local value = self._Model:GetSpeedByAngle(sceneId, angle)
    if XTool.IsNumberValid(value) then
        return value / 10000
    end
    return 1
end

function XSwitchableSceneAgency:GetSpeedByDistance(sceneId, distance)
    local value = self._Model:GetSpeedByDistance(sceneId, distance)
    if XTool.IsNumberValid(value) then
        return value / 10000
    end
    return 1
end

function XSwitchableSceneAgency:GetClientConfig(key)
    local config = self._Model:GetClientConfigById(key)
    if config then
        return config.Values
    end
    return nil
end

function XSwitchableSceneAgency:GetClientConfigById(key, index)
    index = index or 1
    local config = self._Model:GetClientConfigById(key)
    if config then
        return config.Values[index]
    end
    return nil
end

function XSwitchableSceneAgency:GetIntClientConfigById(key, index)
    local value = self:GetClientConfigById(key, index)
    if value then
        return tonumber(value)
    end
    return nil
end

---[场景设置（昼夜/电量），环境音设置，交互设置]
function XSwitchableSceneAgency:GetSetting(sceneId)
    return self._Model:GetSetting(sceneId)
end

---场景设置（昼夜/电量）
function XSwitchableSceneAgency:GetSceneSetting(sceneId)
    local datas = self._Model:GetSetting(sceneId)
    return datas[1]
end

---环境音设置
function XSwitchableSceneAgency:GetEnvMusicSetting(sceneId)
    local datas = self._Model:GetSetting(sceneId)
    return datas[2]
end

---交互设置
function XSwitchableSceneAgency:GetGyroSetting(sceneId)
    local datas = self._Model:GetSetting(sceneId)
    return datas[3]
end

function XSwitchableSceneAgency:SetSceneSetting(sceneId, sceneOpIdx)
    self._Model:SetSetting(sceneId, sceneOpIdx, nil, nil)
end

function XSwitchableSceneAgency:SetMusicSetting(sceneId, musicOpIdx)
    self._Model:SetSetting(sceneId, nil, musicOpIdx, nil)
end

function XSwitchableSceneAgency:SetGyroSetting(sceneId, gyroOpIdx)
    self._Model:SetSetting(sceneId, nil, nil, gyroOpIdx)

    local curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    if sceneId == curSceneId then
        self:CheckSceneChange(curSceneId)
    end
end

function XSwitchableSceneAgency:PlaySceneAnim(sceneId, playFullCb, playLowCb)
    local option = self:GetSceneSetting(sceneId)
    local setting = XEnumConst.SwitchableScene.Setting
    local type = XPhotographConfigs.GetBackgroundTypeById(sceneId)
    local playMode

    if type == XPhotographConfigs.BackGroundType.Gyro then
        return
    elseif type == XPhotographConfigs.BackGroundType.PowerSaved then
        if option == setting.Power.Auto then
            if CS.XUiBattery.IsCharging then
                --充电状态
                playMode = PlayFull
            else
                -- 比较电量
                if CS.XUiBattery.BatteryLevel > self._Model:GetLowPowerValue() then
                    playMode = PlayFull
                else
                    playMode = PlayLow
                end
            end
        elseif option == setting.Power.Full then
            playMode = PlayFull
        elseif option == setting.Power.Low then
            playMode = PlayLow
        end
    else
        -- v1.29 场景预览 时间模式判断
        if option == setting.Data.Auto then
            local dateStartTime = self._Model:GetBackgroundChangeTimeStr()
            local dateEndTime = self._Model:GetBackgroundChangeTimeEnd()
            local startTime = XTime.ParseToTimestamp(dateStartTime)
            local endTime = XTime.ParseToTimestamp(dateEndTime)
            local nowTime = XTime.ParseToTimestamp(CS.System.DateTime.Now:ToLocalTime():ToString())
            -- 比较时间
            if startTime > nowTime and nowTime > endTime then
                playMode = PlayFull
            else
                playMode = PlayLow
            end
        elseif option == setting.Data.Day then
            playMode = PlayFull
        elseif option == setting.Data.Night then
            playMode = PlayLow
        end
    end

    if playMode == PlayFull then
        if playFullCb then
            playFullCb()
        end
    elseif playMode == PlayLow then
        if playLowCb then
            playLowCb()
        end
    end
end

function XSwitchableSceneAgency:CheckSceneChange(newSceneId)
    local isPcMode = XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc
    if isPcMode and self:IsSceneGyro(newSceneId) then
        local isShow = self:GetGyroSetting(newSceneId) == XEnumConst.SwitchableScene.Setting.Open
        self._Model:SetShowGyroTip(isShow)
    else
        self._Model:SetShowGyroTip(false)
    end
end

function XSwitchableSceneAgency:CheckShowGyroTip()
    if self._Model:GetIsShowGyroTip() then
        XUiManager.TipText("SwitchableScenePcTip")
        self._Model:SetShowGyroTip(false)
    end
end

---是否为支持陀螺仪的场景（该类型的场景没有昼夜/电量切换功能）
function XSwitchableSceneAgency:IsSceneGyro(sceneId)
    return XPhotographConfigs.GetBackgroundTypeById(sceneId) == XPhotographConfigs.BackGroundType.Gyro
end

---当前场景是否支持陀螺仪（该类型的场景没有昼夜/电量切换功能）
function XSwitchableSceneAgency:IsCurSceneGyro()
    local sceneId = XDataCenter.PhotographManager.GetCurSceneId()
    return self:IsSceneGyro(sceneId)
end

return XSwitchableSceneAgency