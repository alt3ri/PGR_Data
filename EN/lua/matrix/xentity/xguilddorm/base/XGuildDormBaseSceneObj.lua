--============
--公会宿舍场景实体基类
--============
---@class XGuildDormBaseSceneObj
local XGuildDormBaseSceneObj = XClass(nil, "XGuildDormBaseSceneObj")
--============
--将GameObject移动到root根节点
--============
local function BindToRoot(model, root)
    model.transform:SetParent(root)
    model.transform.localPosition = CS.UnityEngine.Vector3.zero
    model.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    model.transform.localScale = CS.UnityEngine.Vector3.one
end

function XGuildDormBaseSceneObj:Ctor()
    
end
--============
--为实体设置场景GameObject
--============
function XGuildDormBaseSceneObj:SetGameObject(go)
    self.GameObject = go
    self.Transform = go.transform
    XDataCenter.GuildDormManager.SceneManager.AddSceneObj(self.GameObject, self)
    self:OnLoadComplete()
end
--============
--当GameObject设置好后回调
--虚方法
--============
function XGuildDormBaseSceneObj:OnLoadComplete()
    
end
return XGuildDormBaseSceneObj
