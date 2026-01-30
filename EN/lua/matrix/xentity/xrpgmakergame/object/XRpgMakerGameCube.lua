local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3

---地图格子对象
---@class XRpgMakerGameCube:XRpgMakerGameObject
local XRpgMakerGameCube = XClass(XRpgMakerGameObject, "XRpgMakerGameCube")

function XRpgMakerGameCube:Ctor(id, gameObject)

end

--获得格子对象上方中心的坐标
function XRpgMakerGameCube:GetGameObjUpCenterPosition()
    local transform = self:GetAssetTransform()
    local centerPoint = XUiHelper.TryGetComponent(transform, "CenterPoint")
    if not centerPoint then
        XLog.Error("未找到地面节点下名为CenterPoint的节点")
    end
    return centerPoint and centerPoint.transform.position
end

-- 切换格子
function XRpgMakerGameCube:ChangeCubeWithScaleAnim(modelPath)
    local scaleDown = 0.7 -- 缩小到0.7
    local scaleDownTime = 0.15
    local scaleUp = 1.2 -- 反弹到1.2
    local scaleUpTime = 0.25
    local scaleRevert = 1 -- scale还原
    local scaleRevertTime = 0.1
    
    self.Transform:DOScale(XLuaVector3.New(scaleDown, scaleDown, scaleDown), scaleDownTime):OnComplete(function()
        local localScale = self.Transform.localScale
        self:LoadModel(modelPath)
        self.Transform.localScale = localScale
        self.Transform:DOScale(XLuaVector3.New(scaleUp, scaleUp, scaleUp), scaleUpTime):OnComplete(function()
            self.Transform:DOScale(XLuaVector3.New(scaleRevert, scaleRevert, scaleRevert), scaleRevertTime)
        end)
    end)
end

return XRpgMakerGameCube