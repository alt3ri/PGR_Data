---@class XSignBoardCamAnimEntity
---@field _SignBoardCamAnim XSignBoardCamAnim
---@field _SignBoardCamAnimNew XSignBoardCamAnimNew 新组件 卡池和看板共用一套预制体
local XSignBoardCamAnimEntity = XClass(nil, "XSignBoardCamAnimEntity")

function XSignBoardCamAnimEntity:Ctor()
    -- todo:由于原先代码是New出来后一直持有 没有释放 且看板代码杂乱 所以此处也暂时没有释放
    self._SignBoardCamAnim = require("XEntity/XSignBoard/XSignBoardCamAnim").New()
    self._SignBoardCamAnimNew = require("XEntity/XSignBoard/XSignBoardCamAnimNew").New()
end

---@param ui XLuaUi
function XSignBoardCamAnimEntity:UpdateData(sceneId, signBoardId, ui)
    local configs = XMVCA.XFavorability:GetSignBoardConfig()
    local config = configs[signBoardId]

    self._IsUseNewCamAnim = config.IsUseStoryCamera == 1 and not string.IsNilOrEmpty(config.SceneCamAnimPrefab)

    if self._IsUseNewCamAnim then
        self._SignBoardCamAnimNew:UpdateData(sceneId, signBoardId, ui)
    else
        self._SignBoardCamAnim:UpdateData(sceneId, signBoardId, ui)
    end
end

function XSignBoardCamAnimEntity:IsUseStoryCamera()
    return self._IsUseNewCamAnim
end

function XSignBoardCamAnimEntity:GetStoryNearCamera()
    if self._IsUseNewCamAnim then
        return self._SignBoardCamAnimNew.UiNearCamera
    end
    return nil
end

function XSignBoardCamAnimEntity:UpdateAnim(animRootNode, animNode, farCam, nearCam, uiFarCam, uiNearCam)
    if self._IsUseNewCamAnim then
        self._SignBoardCamAnimNew:UpdateAnim(animRootNode, animNode, uiFarCam, uiNearCam)
    else
        self._SignBoardCamAnim:UpdateAnim(animNode, farCam, nearCam)
    end
end

function XSignBoardCamAnimEntity:UnloadAnim()
    if self._IsUseNewCamAnim then
        self._SignBoardCamAnimNew:UnloadAnim()
    else
        self._SignBoardCamAnim:UnloadAnim()
    end
end

function XSignBoardCamAnimEntity:IsAnimPlaying()
    if self._IsUseNewCamAnim then
        return self._SignBoardCamAnimNew:IsAnimPlaying()
    else
        return self._SignBoardCamAnim:IsAnimPlaying()
    end
end

function XSignBoardCamAnimEntity:CheckIsSameAnim(sceneId, signBoardId, rootNode)
    if self._IsUseNewCamAnim then
        return self._SignBoardCamAnimNew:CheckIsSameAnim(sceneId, signBoardId, rootNode)
    else
        return self._SignBoardCamAnim:CheckIsSameAnim(sceneId, signBoardId, rootNode)
    end
end

function XSignBoardCamAnimEntity:GetSignBoardId()
    if self._IsUseNewCamAnim then
        return self._SignBoardCamAnimNew.SignBoardId
    else
        return self._SignBoardCamAnim.SignBoardId
    end
end

function XSignBoardCamAnimEntity:GetNodeTransform()
    if self._IsUseNewCamAnim then
        return self._SignBoardCamAnimNew:GetNodeTransform()
    else
        return self._SignBoardCamAnim:GetNodeTransform()
    end
end

function XSignBoardCamAnimEntity:Play()
    if self._IsUseNewCamAnim then
        self._SignBoardCamAnimNew:Play()
    else
        self._SignBoardCamAnim:Play()
    end
end

function XSignBoardCamAnimEntity:Pause()
    if self._IsUseNewCamAnim then
        self._SignBoardCamAnimNew:Pause()
    else
        self._SignBoardCamAnim:Pause()
    end
end

function XSignBoardCamAnimEntity:Resume()
    if self._IsUseNewCamAnim then
        self._SignBoardCamAnimNew:Resume()
    else
        self._SignBoardCamAnim:Resume()
    end
end

function XSignBoardCamAnimEntity:Close()
    if self._IsUseNewCamAnim then
        self._SignBoardCamAnimNew:Close()
    else
        self._SignBoardCamAnim:Close()
    end
end

return XSignBoardCamAnimEntity