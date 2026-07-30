--- 骨骼动画控制器
local XUiDyeMergeMainSpine = XClass(nil, 'XUiDyeMergeMainSpine')

function XUiDyeMergeMainSpine:Ctor(spineObj)
    self.SpineObj = spineObj
    self._SpineObjs = {}
    self:InitSpineObjs()
end

function XUiDyeMergeMainSpine:InitSpineObjs()
    if self._SpineInited then return end
    self._SpineInited = true
    if XTool.UObjIsNil(self.SpineObj) then return end

    local arr1 = self.SpineObj.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
    local arr2 = self.SpineObj.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonGraphic))
    for j = 0, arr1.Length - 1 do
        self._SpineObjs[#self._SpineObjs + 1] = arr1[j]
    end
    for j = 0, arr2.Length - 1 do
        self._SpineObjs[#self._SpineObjs + 1] = arr2[j]
    end
end

---Spine对象组播放动画
---每次调用自动清理上一轮注册的 Complete 回调，避免旧回调泄漏
function XUiDyeMergeMainSpine:PlaySpineAnimation(fromAnim, toAnim, cb)
    for _, spineObj in ipairs(self._SpineObjs) do
        self:_PlaySpineObjAnimation(spineObj, fromAnim, toAnim, cb)
    end
end

---spine对象播放动画（内部方法）
function XUiDyeMergeMainSpine:_PlaySpineObjAnimation(spineObject, fromAnim, toAnim, upCb)
    if XTool.UObjIsNil(spineObject) then return end

    self:_RemovePendingCb(spineObject)

    local isHaveFrom = fromAnim and spineObject.skeletonDataAsset:GetSkeletonData(false):FindAnimation(fromAnim)
    local isHaveTo = toAnim and spineObject.skeletonDataAsset:GetSkeletonData(false):FindAnimation(toAnim)
    if isHaveFrom then
        if not isHaveTo and not upCb then
            spineObject.AnimationState:SetAnimation(0, fromAnim, true)
        else
            local cb
            cb = function(track)
                if track.Animation.Name ~= fromAnim then return end
                if isHaveTo then
                    spineObject.AnimationState:SetAnimation(0, toAnim, true)
                end
                if upCb then
                    upCb()
                end
                self._PendingCbs[spineObject] = nil
                spineObject.AnimationState:Complete('-', cb)
            end
            self._PendingCbs = self._PendingCbs or {}
            self._PendingCbs[spineObject] = cb
            spineObject.AnimationState:Complete('+', cb)
            spineObject.AnimationState:SetAnimation(0, fromAnim, not isHaveTo)
        end
    elseif isHaveTo then
        spineObject.AnimationState:SetAnimation(0, toAnim, true)
    else
        spineObject.AnimationState:SetEmptyAnimation(0, 0)
    end
end

---移除指定 spineObject 上一轮注册的 Complete 回调（私有方法）
function XUiDyeMergeMainSpine:_RemovePendingCb(spineObject)
    if not self._PendingCbs then return end
    local oldCb = self._PendingCbs[spineObject]
    if oldCb then
        spineObject.AnimationState:Complete('-', oldCb)
        self._PendingCbs[spineObject] = nil
    end
end

return XUiDyeMergeMainSpine
