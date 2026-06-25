local vector = CS.UnityEngine.Vector3

---@class XMovieActionActorAppear
---@field UiRoot XUiMovie
local XMovieActionActorAppear = XClass(XMovieActionBase, "XMovieActionActorAppear")

function XMovieActionActorAppear:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_ACTOR_NUM then
        XLog.Error("XMovieActionActorAppear:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex

    self.ActorId = paramToNumber(params[2])
    self.FaceId = paramToNumber(params[3])
    self.PosX = paramToNumber(params[4])
    self.PosY = paramToNumber(params[5])
    self.PosZ = paramToNumber(params[6])

    self.SkipRoleAnim = paramToNumber(params[7]) ~= 0
    self.IsReverse = paramToNumber(params[8]) ~= 0
end

function XMovieActionActorAppear:GetActorIndex()
    return self.ActorIndex
end

function XMovieActionActorAppear:OnEnter()
    ---@type XUiGridMovieActor
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    self.Record = {
        ActorId = actor:GetActorId(),
        FaceId = actor:GetFaceId(),
        ImagePos = actor:GetImagePos(),
        IsHide = actor:IsHide()
    }
    local fixPos = self:GetFixPos()
    -- 演员（重新）出现时把常规演员缩放重置为1：必须放在这里而不是 UpdateActor，
    -- 因为同一角色再次出现时 UpdateActor 会因 actorId 相同早返回，重置不会执行。
    -- 18号大头像缩放由 AvatarScale 专属管理（下方 UpdateActor 之后重设），这里不能碰。
    if self.ActorIndex ~= XMVCA.XMovie.EnumConst.ACTOR_AVATAR_INDEX then
        actor:SetImageScale(1)
    end
    actor:UpdateActor(self.ActorId)
    actor:SetImagePos(fixPos)
    actor:SetFace(self.FaceId)
    -- 18号头像专属：用真实 Scale 控制大小（须在 UpdateActor 之后，因换角色会重置 CustomScale）
    if self.ActorIndex == XMVCA.XMovie.EnumConst.ACTOR_AVATAR_INDEX then
        actor:SetImageScale(XMovieConfigs.GetActorAvatarScale(self.ActorId))
    end
end

function XMovieActionActorAppear:OnRunning()
    local actor = self.IsInTip and self.UiRoot:GetTipActor(self.ActorIndex) or self.UiRoot:GetActor(self.ActorIndex)
    actor:PlayAnimEnable(self.SkipRoleAnim)
    actor:Reverse(self.IsReverse)
end

function XMovieActionActorAppear:OnUndo()
    local actor = self.IsInTip and self.UiRoot:GetTipActor(self.ActorIndex) or self.UiRoot:GetActor(self.ActorIndex)
    if self.Record.IsHide then
        actor:PlayAnimDisable(self.SkipRoleAnim)
    else
        if self.Record.ActorId ~= 0 then
            actor:UpdateActor(self.Record.ActorId)
        end
        actor:SetFace(self.Record.FaceId)
        if self.Record.ImagePos then
            actor:SetImagePos(self.Record.ImagePos)
        end
    end
end

function XMovieActionActorAppear:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionActorAppear:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then
        return self.ActorIndex == action:GetActorIndex()
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.ACTOR_DISAPPEAR then
        return action:IsDisappear(self.ActorIndex)
    end
    return false
end

function XMovieActionActorAppear:OnPassedActionRun()
    self:OnEnter()
    self:OnRunning()
end

function XMovieActionActorAppear:GetFixPos()
    local fixPosX = XDataCenter.MovieManager.Fit(self.PosX)
    -- 演员位置为18号(左下角头像专属位置)时，需要读取配置表位置
    if self.ActorIndex == XMVCA.XMovie.EnumConst.ACTOR_AVATAR_INDEX then
        local avatarPos = XMovieConfigs.GetActorAvatarPosVector3(self.ActorId)
        return vector(fixPosX + avatarPos.x, self.PosY + avatarPos.y, self.PosZ + avatarPos.z)
    else
        return vector(fixPosX, self.PosY, self.PosZ)
    end
end

return XMovieActionActorAppear