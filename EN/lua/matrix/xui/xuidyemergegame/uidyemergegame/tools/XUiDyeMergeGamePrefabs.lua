--- 管理预制引用的类
---@class XUiDyeMergeGamePrefabs: XUiNode
local XUiDyeMergeGamePrefabs = XClass(XUiNode, "XUiDyeMergeGamePrefabs")

function XUiDyeMergeGamePrefabs:GetPrefabByName(name)
    local prefab = self[name]

    if not prefab then
        XLog.Error("不存在指定名称的格子预制，name：" .. tostring(name))        
    end
    
    return prefab
end

return XUiDyeMergeGamePrefabs