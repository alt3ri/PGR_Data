local XMovieActionEffectMove = XClass(XMovieActionBase, "XMovieActionEffectMove")

function XMovieActionEffectMove:OnInit(actionData)
    local params = actionData.Params

    self.EffectKey = params[1]
    self.Time = XMVCA.XMovie:ParamToNumber(params[2])
    self.PosParams = params[3] and XMVCA.XMovie:SplitParam(params[3], "|",true) or nil
    self.Rotation = params[4] and XMVCA.XMovie:ParamToNumber(params[4]) or nil
    self.CurveType = XMVCA.XMovie:ParamToCurveType(params[6])
end

function XMovieActionEffectMove:OnEnter()
    XLuaUiManager.SetMask(true)
end

function XMovieActionEffectMove:OnRunning()
    local effectLink = self.UiRoot.EffectGoDic[self.EffectKey]
    if effectLink.transform.childCount == 0 then
        return
    end

    -- 不能使用挂点移动，部分挂点的父节点Pivot非(0.5, 0.5)
    local effectGo = effectLink.transform:GetChild(0)
    local ease = XMVCA.XMovie:GetDOTweenEase(self.CurveType)

    -- 移动
    if self.PosParams then
        local pos = XLuaVector3.New(self.PosParams[1], self.PosParams[2], self.PosParams[3])
        if self.Time == 0 then
            effectGo.transform.localPosition = pos
        else
            local tween = effectGo.transform:DOLocalMove(pos, self.Time)
            if ease and tween then
                tween:SetEase(ease)
            end
        end
    end
    -- 旋转
    if self.Rotation then
        local addRotate = XLuaVector3.New(0, 0, self.Rotation)
        local tween = effectGo.transform:DORotate(addRotate, self.Time, CS.DG.Tweening.RotateMode.LocalAxisAdd)
        if ease and tween then
            tween:SetEase(ease)
        end
    end
end

function XMovieActionEffectMove:OnExit()
    XLuaUiManager.SetMask(false)
end

function XMovieActionEffectMove:IsPassedActionRun(index)
    return true
end

function XMovieActionEffectMove:OnPassedActionRun()
    local effectLink = self.UiRoot.EffectGoDic[self.EffectKey]
    if not effectLink or effectLink.transform.childCount == 0 then
        return
    end

    local effectGo = effectLink.transform:GetChild(0)
    -- 移动
    if self.PosParams then
        local pos = XLuaVector3.New(self.PosParams[1], self.PosParams[2], self.PosParams[3])
        effectGo.transform.localPosition = pos
    end
    -- 旋转
    if self.Rotation then
        local eulerAngles = effectGo.transform.eulerAngles
        eulerAngles = XLuaVector3.New(eulerAngles.x, eulerAngles.y, eulerAngles.z + self.Rotation)
        effectGo.transform.eulerAngles = eulerAngles
    end
end

return XMovieActionEffectMove