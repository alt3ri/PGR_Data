---@class XMusicSceneAgency : XAgency
---@field private _Model XMusicSceneModel
local XMusicSceneAgency = XClass(XAgency, "XMusicSceneAgency", false)

function XMusicSceneAgency:OnInit()
    --初始化一些变量
    self:InitConfig()
end

function XMusicSceneAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX or self:AddRpc
end

function XMusicSceneAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XMusicSceneAgency:InitConfig()
    --初始化配置表
end


--region ----------public start----------

function XMusicSceneAgency:GetCurPlayMode(sceneId)
    return self._Model:GetCurPlayMode(sceneId)
end

function XMusicSceneAgency:SavePlayMode(sceneId, mode)
    self._Model:SetPlayMode(sceneId, mode)
end

---是否音乐场景
function XMusicSceneAgency:IsMusicScene(sceneId)
    return XPhotographConfigs.GetBackgroundTypeById(sceneId) == XPhotographConfigs.BackGroundType.Music
end

---获取音乐场景的专属CueId
function XMusicSceneAgency:GetSpecialCueId(sceneId)
    local cfg = self:GetMusicSceneConfig(sceneId)
    if not XTool.IsNumberValid(cfg.MusicId) then
        return nil
    end
    return XMVCA.XMusicPlayer:COGetMusicPlayerAlbumCOByid(cfg.MusicId).CueId
end

---外部通过设置按钮修改音乐场景播放模式
function XMusicSceneAgency:UpdateMusicSceneMode(sceneId, mode)
    self:SavePlayMode(sceneId, mode)
    XEventManager.DispatchEvent(XEventId.EVENT_MUSIC_SCENE_SETTING_CHANGE, sceneId, mode)
end

---@return XTableMusicScene
function XMusicSceneAgency:GetMusicSceneConfig(sceneId)
    return self._Model:GetMusicSceneConfig(sceneId)
end

---@return string[]
function XMusicSceneAgency:GetClientConfigValues(id)
    local cfg = self._Model:GetClientConfig(id)
    return cfg.Values
end

---@return string
function XMusicSceneAgency:GetClientConfigValue(id, index)
    index = index or 1
    local values = self:GetClientConfigValues(id)
    return values[index]
end

---@return number
function XMusicSceneAgency:GetIntClientConfigValue(id, index)
    return tonumber(self:GetClientConfigValue(id, index))
end

---显示音乐场景提示玩家切换音乐的弹窗
function XMusicSceneAgency:ShowSwitchMusicPopup(sceneId)
    if not self:IsMusicScene(sceneId) then
        return
    end
    if self._Model:IsSwitchMusicPopupShow(sceneId) then
        return
    end
    local bgmCO = XMVCA.XMusicPlayer:GetCurCommonBgnCO()
    local curCueId = bgmCO and bgmCO.CueId
    local cueId = self:GetSpecialCueId(sceneId)
    if cueId == curCueId then
        self._Model:SetSwitchMusicPopupShow(sceneId)
        return
    end
    local title = self:GetClientConfigValue("DialogTitle")
    local content = self:GetClientConfigValue("DialogContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        self._Model:SetSwitchMusicPopupShow(sceneId)
        XLuaUiManager.Open("UiMusicPlayerMain")
    end)
end

--endregion ----------public end----------

--region ----------private start----------


--endregion ----------private end----------

return XMusicSceneAgency