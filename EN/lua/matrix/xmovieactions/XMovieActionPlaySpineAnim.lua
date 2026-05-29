local tableInsert = table.insert

---@class XMovieActionPlaySpineAnim : XMovieActionBase
local XMovieActionPlaySpineAnim = XClass(XMovieActionBase, "XMovieActionPlaySpineAnim")

function XMovieActionPlaySpineAnim:OnInit(actionData)
    self.AnimationName = actionData.Params[1]
    self.IsLoop = XDataCenter.MovieManager.ParamToNumber(actionData.Params[2]) == 1
    self.ComponentPath = actionData.Params[3]
    self.IsSwitchImmediately = actionData.Params[4] == "1" -- 是否立刻切换
end

function XMovieActionPlaySpineAnim:OnEnter()
    ---@type Spine.Unity.SkeletonAnimation
    local spineComponents = self:GetSpineComponents()
    if not spineComponents or #spineComponents == 0 then return end
    
    for _, spineComponent in ipairs(spineComponents) do
        if self.IsSwitchImmediately then
            spineComponent.AnimationState:SetAnimation(0, self.AnimationName, self.IsLoop)
        else
            local cb
            cb = function(track)
                spineComponent.AnimationState:SetAnimation(0, self.AnimationName, self.IsLoop)
                spineComponent.AnimationState:Complete('-', cb)
            end
            spineComponent.AnimationState:Complete('+', cb)
        end
    end
end

---@return Spine.Unity.SkeletonAnimation
function XMovieActionPlaySpineAnim:GetSpineComponents()
    ---@type table<number, CS.Spine.Unity.ISkeletonAnimation> 统一接口
    local spineComponents = {}

    ---@type UnityEngine.RectTransform
    local spineRoot = self.UiRoot.PanelSpine
    if string.IsNilOrEmpty(self.ComponentPath) then
        -- 获取所有 SkeletonGraphic 组件
        local skeletonGraphics = spineRoot.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonGraphic))
        for i = 0, skeletonGraphics.Length - 1 do
            tableInsert(spineComponents, skeletonGraphics[i])
        end
        -- 获取所有 SkeletonAnimation 组件
        local skeletonAnimations = spineRoot.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
        for i = 0, skeletonAnimations.Length - 1 do
            tableInsert(spineComponents, skeletonAnimations[i])
        end
    else
        local spine = spineRoot.transform:GetChild(0)
        if spine then
            local target = spine:Find(self.ComponentPath)
            if target then
                -- 先尝试 SkeletonGraphic
                local sg = target:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic))
                if sg then
                    tableInsert(spineComponents, sg)
                else
                    -- 回退尝试 SkeletonAnimation
                    local sa = target:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
                    if sa then
                        tableInsert(spineComponents, sa)
                    end
                end
            end
        end
    end
    return spineComponents
end

function XMovieActionPlaySpineAnim:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionPlaySpineAnim:IsPassedActionCovered(action)
    return action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SPINE_LOAD
end

function XMovieActionPlaySpineAnim:OnPassedActionRun()
    self:OnEnter()
end

return XMovieActionPlaySpineAnim
