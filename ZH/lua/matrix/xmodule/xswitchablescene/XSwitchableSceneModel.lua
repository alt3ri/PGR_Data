---@class XSwitchableSceneModel : XModel
local XSwitchableSceneModel = XClass(XModel, "XSwitchableSceneModel")

local TableKey = {
    SwitchableSceneGyro = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, Identifier = "SceneId" },
    SwitchableSceneClientConfig = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String },
}

function XSwitchableSceneModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("SwitchableScene", TableKey)
    self._SaveUtil:SetVersionCheckEnable(false)
end

function XSwitchableSceneModel:ClearPrivate()
    --这里执行内部数据清理
end

function XSwitchableSceneModel:ResetAll()
    self._PlayProgress = 0
    self._SettingCache = nil
    self._LowPowerValue = nil
    self._BackgroundChangeTimeStr = nil
    self._BackgroundChangeTimeEnd = nil
    self._IsShowGyroTip = false
end

----------public start----------

function XSwitchableSceneModel:GetSpeedByAngle(sceneId, angle)
    local config = self:GetGyroById(sceneId)
    if not config then
        return nil
    end
    return self:GetSpeed(sceneId, angle, config.Angle)
end

function XSwitchableSceneModel:GetSpeedByDistance(sceneId, distance)
    local config = self:GetGyroById(sceneId)
    if not config then
        return nil
    end
    return self:GetSpeed(sceneId, distance, config.Distance)
end

function XSwitchableSceneModel:GetSpeed(sceneId, value, ranges)
    if XTool.IsTableEmpty(ranges) then
        return nil
    end
    
    local config = self:GetGyroById(sceneId)
    local low, high = 1, #ranges

    if value <= ranges[low] then
        return config.Speed[low]
    elseif value >= ranges[high] then
        return config.Speed[high]
    end

    local idx = nil
    while low <= high do
        local mid = math.floor((low + high) / 2)
        if ranges[mid] >= value then
            idx = mid
            high = mid - 1
        else
            low = mid + 1
        end
    end

    local idx = XMath.Clamp(idx, 1, #ranges)
    return config.Speed[idx]
end

function XSwitchableSceneModel:GetSetting(sceneId)
    if not self._SettingCache then
        self._SettingCache = {}
    end

    local datas = self._SettingCache[sceneId]
    if not datas then
        datas = self._SaveUtil:GetData(string.format("SwitchableScene_Setting_%s", sceneId)) or { 0, 0, 0 }
        self._SettingCache[sceneId] = datas
    end

    return datas
end

function XSwitchableSceneModel:SetSetting(sceneId, sceneOpIdx, musicOpIdx, gyroOpIdx)
    local datas = self:GetSetting(sceneId)
    if sceneOpIdx then
        datas[1] = sceneOpIdx
    end
    if musicOpIdx then
        datas[2] = musicOpIdx
    end
    if gyroOpIdx then
        datas[3] = gyroOpIdx
    end
    self._SaveUtil:SaveData(string.format("SwitchableScene_Setting_%s", sceneId), datas)
end

function XSwitchableSceneModel:GetLowPowerValue()
    if not self._LowPowerValue then
        self._LowPowerValue = CS.XGame.ClientConfig:GetFloat("UiMainLowPowerValue")
    end
    return self._LowPowerValue
end

function XSwitchableSceneModel:GetBackgroundChangeTimeStr()
    if not self._BackgroundChangeTimeStr then
        self._BackgroundChangeTimeStr = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeStr")
    end
    return self._BackgroundChangeTimeStr
end

function XSwitchableSceneModel:GetBackgroundChangeTimeEnd()
    if not self._BackgroundChangeTimeEnd then
        self._BackgroundChangeTimeEnd = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeEnd")
    end
    return self._BackgroundChangeTimeEnd
end

function XSwitchableSceneModel:SetShowGyroTip(isShow)
    self._IsShowGyroTip = isShow
end

function XSwitchableSceneModel:GetIsShowGyroTip()
    return self._IsShowGyroTip
end

----------public end----------

----------private start----------


----------private end----------

----------config start----------

---@return XTableSwitchableSceneClientConfig
function XSwitchableSceneModel:GetClientConfigById(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SwitchableSceneClientConfig, key)
end

---@return XTableSwitchableSceneGyro
function XSwitchableSceneModel:GetGyroById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SwitchableSceneGyro, id)
end

----------config end----------


return XSwitchableSceneModel