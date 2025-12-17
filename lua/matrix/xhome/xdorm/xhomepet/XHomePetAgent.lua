
---@class XHomePetAgent : XLuaBehaviorAgent
---@field HomePetObj XHomePetObj
local XHomePetAgent = XLuaBehaviorManager.RegisterAgent(XLuaBehaviorAgent, "HomePet")

function XHomePetAgent:SetHomePetObj(petObj)
    self.HomePetObj = petObj
end

--状态改变
function XHomePetAgent:ChangeStatus(state)
    self.HomePetObj:ChangeStatus(state)
end

--状态机改变
function XHomePetAgent:ChangeStateMachine(state)
    self.HomePetObj:ChangeStateMachine(state)
end

--获取属性 例如心情值
function XHomePetAgent:GetAtrributeValue(attributeKey)
    return self.HomePetObj:GetAtrributeValue(attributeKey)
end

--播放动作
function XHomePetAgent:DoAction(actionId, needFadeCross, crossDuration)
    self.HomePetObj:DoAction(actionId, needFadeCross, crossDuration)
end

--显示特定气泡
function XHomePetAgent:ShowBubble(id, callback)
    self.HomePetObj:ShowBubble(id, callback)
end

--显示随机气泡
function XHomePetAgent:ShowRandomBubble(callback)
    self.HomePetObj:ShowRandomBubble(callback)
end

--隐藏气泡
function XHomePetAgent:HideBubble()
    self.HomePetObj:HideBubble()
end

--寻路
function XHomePetAgent:DoPathFind(minDistance, maxDistance)
    self.HomePetObj:DoPathFind(minDistance, maxDistance)
    return true
end

--显示特效
function XHomePetAgent:PlayEffect(effectId, bindWorldPos)
    self.HomePetObj:PlayEffect(effectId, bindWorldPos)
end

--隐藏特效
function XHomePetAgent:HideEffect()
    self.HomePetObj:HideEffect()
end

function XHomePetAgent:PlayFurnitureEffect(effectId)
    return self.HomePetObj:PlayFurnitureEffect(effectId)
end

--检测交互
function XHomePetAgent:CheckFurnitureInteract()
    return self.HomePetObj:CheckFurnitureInteract()
end

--检测事件完成
function XHomePetAgent:CheckEventCompleted(completeType, callback)
    return self.HomePetObj:CheckEventCompleted(completeType, callback)
end

--家具交互
function XHomePetAgent:InteractFurniture()
    return self.HomePetObj:InteractFurniture()
end

--家具交互动画
function XHomePetAgent:PlayInteractFurnitureAnimation()
    return self.HomePetObj:PlayInteractFurnitureAnimation()
end

--检测人物交互
function XHomePetAgent:CheckCharacterInteracter()
    return self.HomePetObj:CheckCharacterInteracter()
end

--获取爱抚类型
function XHomePetAgent:GetFondleType()
    return self.HomePetObj:GetFondleType()
end

--出列爱抚类型
function XHomePetAgent:DequeueFondleType()
    return self.HomePetObj:DequeueFondleType()
end

--到达家具交互
function XHomePetAgent:ReachFurniture()
    self.HomePetObj:ReachFurniture()
end

--检测能否取消家具交互
function XHomePetAgent:CheckDisInteractFurniture()
    return self.HomePetObj:CheckDisInteractFurniture()
end

--显示奖励
function XHomePetAgent:ShowEventReward()
    self.HomePetObj:ShowEventReward()
end

--检测是否在家具上方
function XHomePetAgent:CheckRayCastFurnitureNode()
    return self.HomePetObj:CheckRayCastFurnitureNode()
end

--获取状态
function XHomePetAgent:GetState()
    return self.HomePetObj:GetState()
end

--检测事件存在
function XHomePetAgent:CheckEventExist(eventId)
    return self.HomePetObj:CheckEventExist(eventId)
end

--检测是否正在播放指定动画
function XHomePetAgent:CheckIsPlayingAnimation(animationName)
    return self.HomePetObj:CheckIsPlayingAnimation(animationName)
end

--设置是否阻挡
function XHomePetAgent:SetObstackeEnable(obstackeEnable)
    self.HomePetObj:SetObstackeEnable(obstackeEnable)
end

--朝向交互家具
function XHomePetAgent:SetForwardToFurniture(forward)
    return self.HomePetObj:SetForwardToFurniture(forward)
end

function XHomePetAgent:PlayFurnitureAction(actionId, needFadeCross, crossDuration, needReplayAnimation)
    return self.HomePetObj:PlayFurnitureAction(actionId, needFadeCross, crossDuration, needReplayAnimation)
end

--获取ID
function XHomePetAgent:GetId()
    return self.HomePetObj.Id
end

-- --设置停留点偏移
-- function XHomePetAgent:SetStayOffset()
--     return self.HomePetObj:SetStayPosOffest()
-- end
--设置构造体交互开关
function XHomePetAgent:SetCharInteractTrigger(isOn)
    return self.HomePetObj:SetCharInteractTrigger(isOn)
end

--设置构造体长按开关
function XHomePetAgent:SetCharLongPressTrigger(isOn)
    return self.HomePetObj:SetCharLongPressTrigger(isOn)
end

-- 检测构造体是否在坐标索引上
function XHomePetAgent:CheckCharInteractPosByIndex(index)
    return self.HomePetObj:CheckCharInteractPosByIndex(index)
end