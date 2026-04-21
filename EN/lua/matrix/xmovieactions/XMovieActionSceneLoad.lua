local XMovieActionSceneLoad = XClass(XMovieActionBase,"XMovieActionSceneLoad")
function XMovieActionSceneLoad:OnInit(actionData)
    local params        = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    local Vector3       = CS.UnityEngine.Vector3
    self.ScenePath      = params[1]
    local pos           = string.Split(params[2], "|")
    local rotation      = string.Split(params[3], "|")
    local scale         = string.Split(params[4], "|")
    self.ScenePos       = Vector3(paramToNumber(pos[1]), paramToNumber(pos[2]), paramToNumber(pos[3]))
    self.SceneRotation  = Vector3(paramToNumber(rotation[1]), paramToNumber(rotation[2]), paramToNumber(rotation[3]))
    self.SceneScale     = Vector3(paramToNumber(scale[1]), paramToNumber(scale[2]), paramToNumber(scale[3]))
end

function XMovieActionSceneLoad:OnEnter()
    self.UiRoot:Switch3DMovie()
    local root = self.UiRoot.UiModelGo.transform
    local obj = CS.LoadHelper.InstantiateScene(self.ScenePath)
    obj.transform.parent = root.parent.parent
    obj.transform.localScale = self.SceneScale
    obj.transform.localPosition = self.ScenePos
    obj.transform.localEulerAngles = self.SceneRotation
end

function XMovieActionSceneLoad:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

function XMovieActionSceneLoad:IsAdvanceStartAction()
    return true
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionSceneLoad:IsPassedActionCovered(action)
    return action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.BG_SWITCH
end


return XMovieActionSceneLoad