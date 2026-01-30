local XLuaSceneDefine = {}

-- 场景control绑定
local sceneBindControl = {
    -- SceneName -> ModuleId
    --E.G.: Restaurant = ModuleId.XUiMain
    XRaceScene = ModuleId.XRace,
}

-- 场景注册文件
local sceneRegistry = {
    -- SceneName -> ModulePath
    --E.G.: Restaurant = "XModule/XRestaurant/XSceneRestaurant",
    XRaceScene = "XModule/XRace/XRaceScene",
}

-- 场景id
local sceneIds = {
    -- SceneId -> SceneId
    --E.G.: Restaurant = 11,
    XRaceScene = 1,
}

XLuaSceneDefine.SceneBindControl = sceneBindControl
XLuaSceneDefine.SceneRegistry = sceneRegistry
XLuaSceneDefine.SceneIds = sceneIds

return XLuaSceneDefine