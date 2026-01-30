--- 与其他物体相连的组件
---@class XGoldenMinerComponentLink: XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityStone
local XGoldenMinerComponentLink = XClass(XEntity, 'XGoldenMinerComponentLink')
local Vec3Lerp = CS.UnityEngine.Vector3.Lerp

function XGoldenMinerComponentLink:OnInit()
    -- 相连的实体uid，所有相连的组件引用同一份list
    self._LinkList = nil
    self._MarkStatus = self._ParentEntity:GetStatus()
    self:InitLinkPoint()
    self._ParentEntity:GetComponentStone():SetLinkStyleShow(true)
end

function XGoldenMinerComponentLink:OnRelease()
    self:_RecycleLinkRope()
    self:StopTween()
    self._LinkList = nil
end

function XGoldenMinerComponentLink:InitLinkPoint()
    --- 手动创建一个居中的点作为连接点
    ---@type UnityEngine.RectTransform
    local transform = self._ParentEntity:GetTransform()

    if transform then
        local point = transform:Find('LinkPoint')

        if not point then
            point = CS.UnityEngine.GameObject('LinkPoint', typeof(CS.UnityEngine.RectTransform))
            point.transform:SetParent(transform)
            point.transform:SetLocalPosition(0, 0, 0)
            point.transform:SetLocalScale(1, 1, 1)
        end
        
        self._LinkPoint = point.transform
    end
end

function XGoldenMinerComponentLink:GetLinkPoint()
    return self._LinkPoint or self._ParentEntity:GetTransform()
end

function XGoldenMinerComponentLink:OnStatusChanged(newStatus)
    if self._MarkStatus == newStatus then
        return
    end

    if XMVCA.XGoldenMiner.EnumConst.GameLinkStoneCanSyncStates[newStatus] then
        self:SetLinkUidStatus(newStatus)
        
        -- 如果未存活，则需要回收链接
        if not self._ParentEntity:IsAlive() then
            self:_RecycleLinkRope()
            self:StopTween()
        end
    end

    self._MarkStatus = newStatus

    if self._MarkStatus == XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.DESTROY then
        self:UnLinkSelf()
    end
end

--- 设置链接列表引用，这个引用链接在一起的物体共享，列表中的顺序是坐标x轴自左向右的顺序
function XGoldenMinerComponentLink:SetLinkList(linkList)
    self._LinkList = linkList
end

function XGoldenMinerComponentLink:GetLinkList()
    return XTool.Clone(self._LinkList)
end

function XGoldenMinerComponentLink:_RecycleLinkRope()
    if XTool.IsNumberValid(self._LinkRopeUid) then
        -- 回收
        self._OwnControl.SystemMap:RecycleLinkRope(self._LinkRopeUid)
        self._LinkRopeUid = nil
    end
end

function XGoldenMinerComponentLink:InitLinkRopeShow(force)
    self:_RecycleLinkRope()

    local nextLinkUid = self:GetNextLinkUid()

    if not XTool.IsNumberValid(nextLinkUid) then
        return
    end

    -- 链接的物品总是与右边的相连
    local rightEntity = self._OwnControl:GetStoneEntityByUid(nextLinkUid)

    if rightEntity and (rightEntity:IsAlive() or force) then
        local rightLinkCom = rightEntity:GetComponentLink()

        if not rightLinkCom then
            if not rightEntity:IsInvalid() then
                rightLinkCom = rightEntity:AddChildEntity(self._OwnControl.COMPONENT_TYPE.LINK)
            end 
        end

        if rightLinkCom then
            self._LinkRopeUid = self._OwnControl.SystemMap:CreateAndSetLinkRope(self._ParentEntity:GetTransform(), rightEntity:GetTransform(), self:GetLinkPoint(), rightLinkCom:GetLinkPoint())
        end
    end
end

---@param force @刷新忽略资源的状态
---@param refreshFrom @是否刷新前一个链接物对自己的连线
function XGoldenMinerComponentLink:RefreshLinkRopeShow(force, refreshFrom)
    if refreshFrom then
        local lastLinkUid = self:GetLastLinkUid()

        if XTool.IsNumberValidEx(lastLinkUid) then
            local leftEntity = self._OwnControl:GetStoneEntityByUid(lastLinkUid)

            if leftEntity then
                local leftLinkCom = leftEntity:GetComponentLink()

                if leftLinkCom then
                    leftLinkCom:RefreshLinkRopeShow()
                end
            end
        end
    end
    
    local nextLinkUid = self:GetNextLinkUid()

    if not XTool.IsNumberValid(nextLinkUid) then
        self:_RecycleLinkRope()
        return
    end
    
    if not XTool.IsNumberValidEx(self._LinkRopeUid) then
        self:InitLinkRopeShow(force)
        return
    end
    
    -- 链接的物品总是与右边的相连
    local rightEntity = self._OwnControl:GetStoneEntityByUid(nextLinkUid)

    if rightEntity then
        local rightLinkCom = rightEntity:GetComponentLink()
        
        self._OwnControl.SystemMap:UpdateLinkRope(self._LinkRopeUid, self._ParentEntity:GetTransform(), rightEntity:GetTransform(), self:GetLinkPoint(), rightLinkCom:GetLinkPoint())
    end
end

function XGoldenMinerComponentLink:GetNextLinkUid()
    if not self._ParentEntity then
        return
    end
    
    local selfUid = self._ParentEntity:GetUid()
    
    for i = 1, #self._LinkList do
        if self._LinkList[i] == selfUid then
            return self._LinkList[i + 1]
        end
    end
end

function XGoldenMinerComponentLink:GetLastLinkUid()
    if not self._ParentEntity then
        return
    end

    local selfUid = self._ParentEntity:GetUid()

    for i = 1, #self._LinkList do
        if self._LinkList[i] == selfUid then
            return self._LinkList[i - 1]
        end
    end
end

function XGoldenMinerComponentLink:SetLinkUidStatus(status)
    if not XTool.IsTableEmpty(self._LinkList) then
        local selfUid = self._ParentEntity:GetUid()
        
        for i, v in pairs(self._LinkList) do
            if v ~= selfUid then
                local entity = self._OwnControl:GetStoneEntityByUid(v)

                if entity then
                    entity:SetStatus(status)
                end
            end
        end
    end
end

---@param follow UnityEngine.RectTransform
function XGoldenMinerComponentLink:StartMoveToFollowerPos(follow, duration, updateCb, finishCb)
    ---@type UnityEngine.RectTransform
    local selfTrans = self._ParentEntity:GetTransform()
    
    self._TweenTimeId = self._OwnControl.CalculateHelper:SetGoMoveToAnotherWithDuration(selfTrans, follow, duration, function(curTime)
        self:RefreshLinkRopeShow(true)

        if updateCb then
            updateCb(curTime)
        end
    end, function()
        self:StopTween()
        self:_RecycleLinkRope()

        if finishCb then
            finishCb()
        end
    end)
end

function XGoldenMinerComponentLink:StartUpdateLinkRope(duration)
    self:RefreshLinkRopeShow(true)
    self._TweenTimeId = XScheduleManager.ScheduleForever(function() 
        self:RefreshLinkRopeShow(true)
        duration = duration - CS.UnityEngine.Time.deltaTime

        if duration <= 0 then
            self:StopTween()
            self:_RecycleLinkRope()
        end
    end, 0, 0)
end

function XGoldenMinerComponentLink:StopTween()
    if self._TweenTimeId then
        XScheduleManager.UnSchedule(self._TweenTimeId)
    end
end

function XGoldenMinerComponentLink:UnLinkSelf()
    if not self._ParentEntity then
        return
    end

    local selfUid = self._ParentEntity:GetUid()
    
    -- 将自己在缓存中设置为false
    for i = 1, #self._LinkList do
        if self._LinkList[i] == selfUid then
            self._LinkList[i] = false
        end
    end
    
    -- 请求重新分配链接
    self._OwnControl.SystemPartner:ReallocateLinkByOldLinkList(self._LinkList)

    -- 移除自己
    self._ParentEntity:RemoveComponentLink(self)
end

return XGoldenMinerComponentLink