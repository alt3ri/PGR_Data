local Vector3 = CS.UnityEngine.Vector3
local UiFarMask = CS.UnityEngine.LayerMask.GetMask("UiFar")
local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
---@class XGDInteractCheckAudioFloorComponent : XGDComponet
local XGDInteractCheckAudioFloorComponent = XClass(XGDComponet, "XGDInteractCheckAudioFloorComponent")

---@param role XGuildDormRole
---@param room XGuildDormRoom
function XGDInteractCheckAudioFloorComponent:Ctor(role, room)
    self.Role = role
    self.Transform = nil    
    self.NpcPhysicastOffset = Vector3(0, 0.5, -0.5)
    self.AudioFloorLockDic = {} -- 音乐地板触发锁
end

function XGDInteractCheckAudioFloorComponent:Init()
    XGDInteractCheckAudioFloorComponent.Super.Init(self)
    self:UpdateRoleDependence()
end

function XGDInteractCheckAudioFloorComponent:UpdateRoleDependence()
    self.Transform = self.Role:GetRLRole():GetTransform()
end

function XGDInteractCheckAudioFloorComponent:Update(dt)
    if self.Role:GetInteractStatus() ~= XGuildDormConfig.InteractStatus.End then
        return
    end
    --判断射线碰到家私 后期策划可能会需要这段需求，面向家具检测交互
    if UiFarMask == nil then 
        return 
    end
    if XTool.UObjIsNil(self.Transform) then 
        return
    end
    local hit = self.Transform:PhysicsRayCast(self.Transform.rotation * self.NpcPhysicastOffset, self.Transform.rotation * Vector3.down, UiFarMask, 1)
    if XTool.UObjIsNil(hit) then 
        hit = self.Transform:PhysicsRayCast(Vector3.zero, Vector3.down, UiFarMask, 1)
        if XTool.UObjIsNil(hit) then 
            self.AudioFloorLockDic = {}
            return 
        end
    end
    if hit.gameObject.tag == "AudioFloor" and not self.AudioFloorLockDic[hit.gameObject:GetInstanceID()] then
        self.AudioFloorLockDic = {}
        self.AudioFloorLockDic[hit.gameObject:GetInstanceID()] = true
        local floorPerformanceComp = hit.gameObject:GetComponent(typeof(CS.XGuildDormFloorInteractivePerformance))
        floorPerformanceComp:DoPlay()
        return
    end
end

return XGDInteractCheckAudioFloorComponent