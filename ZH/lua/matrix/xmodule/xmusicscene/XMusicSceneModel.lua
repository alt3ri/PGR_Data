---@class XMusicSceneModel : XModel
local XMusicSceneModel = XClass(XModel, "XMusicSceneModel")

local SAVE_KEY_PERSISTENT = "SAVE_KEY_PERSISTENT"

local TableKey = {
    MusicScene = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client },
    MusicSceneClientConfig = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String },
}

function XMusicSceneModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MusicScene", TableKey)
    self._SaveUtil:SetCustomVersionGetFunc(handler(self, self.GetPersistentVersion), SAVE_KEY_PERSISTENT)
end

function XMusicSceneModel:ClearPrivate()
    --这里执行内部数据清理
end

function XMusicSceneModel:ResetAll()
    self._CurPlayMode = nil
end

--region ----------public start----------

function XMusicSceneModel:GetCurPlayMode(sceneId)
    if not self._CurPlayMode then
        self._CurPlayMode = {}
    end
    if not self._CurPlayMode[sceneId] then
        self._CurPlayMode[sceneId] = self._SaveUtil:GetDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("CurPlayMode_%s", sceneId)) or XEnumConst.MusicScene.Mode.Music
    end
    return self._CurPlayMode[sceneId]
end

function XMusicSceneModel:SetPlayMode(sceneId, mode)
    self._CurPlayMode[sceneId] = mode
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("CurPlayMode_%s", sceneId), mode)
end

---提示玩家切换音乐的弹窗是否已经显示过了
function XMusicSceneModel:IsSwitchMusicPopupShow(sceneId)
    return self._SaveUtil:GetDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("SwitchMusicPopup_%s", sceneId))
end

function XMusicSceneModel:SetSwitchMusicPopupShow(sceneId)
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_PERSISTENT, string.format("SwitchMusicPopup_%s", sceneId), true)
end

---@return XTableMusicScene
function XMusicSceneModel:GetMusicSceneConfig(sceneId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MusicScene, sceneId)
end

---@return XTableMusicSceneClientConfig
function XMusicSceneModel:GetClientConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MusicSceneClientConfig, id)
end

--endregion ----------public end----------

--region ----------private start----------

function XMusicSceneModel:GetPersistentVersion()
    return 1
end

--endregion ----------private end----------


return XMusicSceneModel