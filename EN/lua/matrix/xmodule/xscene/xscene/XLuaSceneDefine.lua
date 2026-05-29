local XLuaSceneDefine = {}

-- 场景control绑定
local sceneBindControl = {
    -- SceneName -> ModuleId
    --E.G.: Restaurant = ModuleId.XUiMain
    XRaceScene = ModuleId.XRace,
    XTheatre6Scene = ModuleId.XTheatre6,
}

-- 场景注册文件
local sceneRegistry = {
    -- SceneName -> ModulePath
    --E.G.: Restaurant = "XModule/XRestaurant/XSceneRestaurant",
    XRaceScene = "XModule/XRace/XRaceScene",
    XTheatre6Scene = "XModule/XTheatre6/XTheatre6Scene",
}

-- 场景id
local sceneIds = {
    -- SceneId -> SceneId
    --E.G.: Restaurant = 11,
    XRaceScene = 1,
    XTheatre6Scene = 2,
}

XLuaSceneDefine.SceneBindControl = sceneBindControl
XLuaSceneDefine.SceneRegistry = sceneRegistry
XLuaSceneDefine.SceneIds = sceneIds

return XLuaSceneDefine