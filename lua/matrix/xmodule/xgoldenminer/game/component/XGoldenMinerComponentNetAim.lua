--- 弹网钩爪的组件，用于弹网位置瞄准相关逻辑
--- 瞄准支持反射，但是因为该钩爪与弹射互斥，因此抓取先不支持弹射
---@class XGoldenMinerComponentNetAim: XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityHook
---@field RopeCordNet UnityEngine.RectTransform
---@field RopeCordNetCollider2D UnityEngine.CircleCollider2D
local XGoldenMinerComponentNetAim = XClass(XEntity, 'XGoldenMinerComponentNetAim')

local MoveDirection = {
    Forward = 1,
    Back = 2
}

function XGoldenMinerComponentNetAim:OnInit()
    self._MovePathPoint = {}
    self._MovePathPointCount = 0
    self._CurMovingTargetIndex = 0
    self._MoveDir = MoveDirection.Forward
    self._VirtualMoveSpeedFix = self._OwnControl:GetClientNetHookVirtualMoveSpeedFix()
    
    self._CurGrabRadius = 0
    self._CurWeightCalRule = XMVCA.XGoldenMiner.EnumConst.NETHOOK_WEIGHTRULE.OnlyOneMaxWeight
end

function XGoldenMinerComponentNetAim:OnRelease()
    self._MovePathPoint = nil
end

function XGoldenMinerComponentNetAim:SetTransform(obj)
    XTool.InitUiObjectByUi(self, obj)
    self._RopeCordIndicatorDefaultZ = self.RopeCordIndicator.position.z
    self._HookStartPos = self.Hook.localPosition
    self.RopeCordIndicator.gameObject:SetActiveEx(false)
    self.RopeCollider.gameObject:SetActiveEx(false)
    
    -- 网的局部坐标不变，先存起来
    self._RopeCordNetLocalPos = self.RopeCordNet.localPosition
    
    -- 缓存抓网尺寸和碰撞盒尺寸
    self._DefaultNetSize = self.RopeCordNet.sizeDelta
    self._DefaultGrabRadius = self.RopeCordNetCollider2D.radius
    self._DefaultIndicatorSize = self.RopeCordIndicator.sizeDelta
    
    -- 初始化设置
    self:SetGrabSize(1)
end

function XGoldenMinerComponentNetAim:SetGrabSize(percent)
    self.RopeCordNet:SetUISizeDelta(self._DefaultNetSize.x * percent, self._DefaultNetSize.y * percent)
    self.RopeCordNetCollider2D.radius = self._DefaultGrabRadius * percent
    self.RopeCordIndicator:SetUISizeDelta(self._DefaultIndicatorSize.x * percent, self._DefaultIndicatorSize.y * percent)
    
    -- 碰撞盒的偏移量根据网的锚点相对于居中的偏移来计算
    local pivotX, pivotY = self.RopeCordNet:GetPivot()
    local offsetX = 0.5 - pivotX 
    local offsetY = 0.5 - pivotY

    self.RopeCordNetCollider2D.offset = CS.UnityEngine.Vector2(offsetX * self.RopeCordNetCollider2D.radius * 2, offsetY * self.RopeCordNetCollider2D.radius * 2)
    
    -- 抓取物中心与网的中心保持一致
    local x, y, z = self.TriggerFollowPoint:GetPosition()
    self.TriggerObjs:SetPosition(x, y, z)
end

function XGoldenMinerComponentNetAim:SetGrabWeightRule(rule)
    self._CurWeightCalRule = rule
end

--- 刷新弹网钩爪的起始坐标（基于世界坐标）
function XGoldenMinerComponentNetAim:RefreshMovePathPointWithoutReflect()
    self:ClearMovePathPoint()
    -- 获取当前虚拟钩爪所处的位置
    local posX, posY = self.Hook:GetPosition()
    -- 虚拟钩爪的角度不变，变的是整体的旋转
    local direX, direY, direZ = self.Hook.parent:GetTransUp()
    
    self:AddMovePathPoint(posX, posY, direX, direY)
    
    -- 计算视野有效范围区间
    local minX, minY = self._OwnControl.SystemHook.ViewValidLeftDown:GetPosition()
    local maxX, maxY = self._OwnControl.SystemHook.ViewValidRightUp:GetPosition()
    
    -- 获取延长线所处的位置
    -- 方向取反是因为实际的up和射线方向是相反的
    local fixedX, fixedY = self._OwnControl.CalculateHelper:CalculateRayEndPoint(posX, posY, -direX, -direY, minX, maxX, minY, maxY)

    self:AddMovePathPoint(fixedX, fixedY)
end

function XGoldenMinerComponentNetAim:ClearMovePathPoint()
    self._MovePathPointCount = 0
end

function XGoldenMinerComponentNetAim:AddMovePathPoint(x, y, direX, direY)
    self._MovePathPointCount = self._MovePathPointCount + 1
    
    local data = self._MovePathPoint[self._MovePathPointCount]

    if not data then
        data = {}
        self._MovePathPoint[self._MovePathPointCount] = data
    end
    
    data.X = x
    data.Y = y
    data.DireX = direX
    data.DireY = direY
end

function XGoldenMinerComponentNetAim:OnVirtualMoveStart()
    -- 发射瞬间和上一次刷新，可能角度产生了细微变化，所以这里也刷新一次
    self:RefreshMovePathPointWithoutReflect()
    self._IsVirtualMoving = true
    self.RopeCordIndicator.gameObject:SetActiveEx(true)
    self._ParentEntity:GetComponentHook():UpdateHitColliderEnable(false)
    XMVCA.XGoldenMiner:DebugLogWithType(XMVCA.XGoldenMiner.EnumConst.DebuggerLogType.HookSpeed, '黄金矿工Debug:弹网钩爪虚拟钩爪发射速度='..tostring(self._ParentEntity:GetComponentHook():GetShootSpeed()))
end

function XGoldenMinerComponentNetAim:OnVirtualMoveEnd()
    self.RopeCordIndicator.gameObject:SetActiveEx(false)
    self.RopeCordIndicator:SetLocalPosition(0, 0, 0)
    self._ParentEntity:GetComponentHook():UpdateHitColliderEnable(true)
    CS.UnityEngine.Physics2D.SyncTransforms()
    self._IsVirtualMoving = false
    
    self.IsDuraingGrab = true
    
    XScheduleManager.ScheduleOnce(function()
        self.IsDuraingGrab = false
    end, 0.1 * XScheduleManager.SECOND)
    
    self._CurMovingTargetIndex = 1
end

function XGoldenMinerComponentNetAim:OnHookRevokeStart()
    -- 获取抓取的所有资源
    local stoneUidList = self._ParentEntity:GetGrabbingStoneUidList()

    if not XTool.IsTableEmpty(stoneUidList) then
        local aimUid = 0
        local markWeight = 0
        
        -- 筛选抓取的物品，默认时仅最重的单件启用重量
        if self._CurWeightCalRule == XMVCA.XGoldenMiner.EnumConst.NETHOOK_WEIGHTRULE.OnlyOneMaxWeight then
            for i, uid in pairs(stoneUidList) do
                local stoneEntity = self._OwnControl:GetStoneEntityByUid(uid)

                -- 只在没有被忽略重量的资源中找
                if stoneEntity and not stoneEntity:GetComponentStone():GetIsIgnoreWeight() then
                    local weight = stoneEntity:GetComponentStone():GetCurWeight()

                    if weight > markWeight then
                        markWeight = weight
                        aimUid = uid
                    end
                end
            end
        else
            markWeight = math.maxinteger
            
            for i, uid in pairs(stoneUidList) do
                local stoneEntity = self._OwnControl:GetStoneEntityByUid(uid)

                -- 只在没有被忽略重量的资源中找
                if stoneEntity and not stoneEntity:GetComponentStone():GetIsIgnoreWeight() then
                    local weight = stoneEntity:GetComponentStone():GetCurWeight()

                    if weight < markWeight then
                        markWeight = weight
                        aimUid = uid
                    end
                end
            end
        end

        for i, uid in pairs(stoneUidList) do
            if uid ~= aimUid then
                local stoneEntity = self._OwnControl:GetStoneEntityByUid(uid)

                if stoneEntity then
                    stoneEntity:GetComponentStone():SetIgnoreWeight(true)
                end
            else
                local stoneEntity = self._OwnControl:GetStoneEntityByUid(uid)

                if stoneEntity then
                    stoneEntity:GetComponentStone():SetIgnoreWeight(false)
                end
            end
        end
    end
end

function XGoldenMinerComponentNetAim:OnHookRevokeEnd()
    self._OwnControl.SystemTimeLine:PlayAnim(self._ParentEntity, XEnumConst.GOLDEN_MINER.GAME_ANIM.NET_HOOK_OPEN, nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
end

function XGoldenMinerComponentNetAim:GetIsVirtualMoving()
    return self._IsVirtualMoving
end

--- 刷新路径显示
function XGoldenMinerComponentNetAim:UpdateMovePath(time)
    -- 虚拟抓钩沿着路径往返移动

    if not XTool.IsTableEmpty(self._MovePathPoint) and self._MovePathPointCount > 0 then
        if self._CurMovingTargetIndex == 0 and self._MoveDir == MoveDirection.Forward then
            self._CurMovingTargetIndex = 1
        end
        
        local target = self._MovePathPoint[self._CurMovingTargetIndex]

        if self._OwnControl.CalculateHelper:CheckIsAchieved(self.RopeCordIndicator, target.X, target.Y, self._RopeCordIndicatorDefaultZ, 0.1) then -- 距离过大
            -- 目标变更
            if self._MoveDir == MoveDirection.Forward then
                self._CurMovingTargetIndex = self._CurMovingTargetIndex + 1

                if self._CurMovingTargetIndex > self._MovePathPointCount then
                    self._MoveDir = MoveDirection.Back
                    self._CurMovingTargetIndex = self._MovePathPointCount - 1
                end
            else
                self._CurMovingTargetIndex = self._CurMovingTargetIndex - 1

                if self._CurMovingTargetIndex < 1 then
                    self._MoveDir = MoveDirection.Forward
                    self._CurMovingTargetIndex = 1
                end
            end
        else
            -- 沿着目标方向移动
            local curShootSpeed = self._ParentEntity:GetComponentHook():GetShootSpeed()-- 弹网钩爪发射速度不受buff加成
            self._OwnControl.CalculateHelper:MoveLerp(self.RopeCordIndicator, target.X, target.Y, self._RopeCordIndicatorDefaultZ, curShootSpeed * time * self._VirtualMoveSpeedFix)
        end
    end
    
end

function XGoldenMinerComponentNetAim:UpdateRoleLength(length, isRevoke, time)
    if self.IsDuraingGrab then
        return
    end
    
    if not self:GetIsVirtualMoving() then
        -- 无论有没有抓到东西，都切换为返回
        self._OwnControl.SystemHook:HookRevoke(self._ParentEntity:GetComponentHook())
        return
    end
    
    local targetX, targetY, targetZ = self.RopeCordIndicator:GetLocalPosition()

    -- 实际中心是网的图标中心，要减去它的局部坐标偏差
    targetX = targetX - self._RopeCordNetLocalPos.x
    targetY = targetY - self._RopeCordNetLocalPos.y
    
    -- 先直接向虚的位置移动
    if not self._OwnControl.CalculateHelper:CheckIsAchievedLocalPos(self.Hook, targetX, targetY, targetZ, 0.1) then
        -- 沿着目标方向移动
        local curShootSpeed = self._ParentEntity:GetComponentHook():GetShootSpeed() -- 弹网钩爪发射速度不受buff加成

        self._OwnControl.CalculateHelper:MoveLerpLocalPos(self.Hook, self._HookStartPos.x, self._HookStartPos.y, targetX, targetY, curShootSpeed * time)

        local curX, curY = self.Hook:GetLocalPosition()
        local length = XLuaVector2.DistanceNoVec(self._HookStartPos.x, self._HookStartPos.y, curX, curY)
        local baseLength = self._ParentEntity:GetComponentHook():GetRopeMinLength()
        self._ParentEntity:GetComponentHook():UpdateRopeLengthOnly(baseLength + length)
    else
        self._OwnControl.SystemTimeLine:PlayAnim(self._ParentEntity, XEnumConst.GOLDEN_MINER.GAME_ANIM.NET_HOOK_CLOSE, function()
            self:OnVirtualMoveEnd()
        end, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
    end

    XMVCA.XGoldenMiner:DebugLogWithType(XMVCA.XGoldenMiner.EnumConst.DebuggerLogType.HookSpeed, '黄金矿工Debug:弹网钩爪出爪发射速度='..tostring(self._ParentEntity:GetComponentHook():GetShootSpeed()))

end


return XGoldenMinerComponentNetAim