---@class XRpgMakerGameControl : XControl
---@field _Model XRpgMakerGameModel
---@field _Scene XRpgMakerGameScene
local XRpgMakerGameControl = XClass(XControl, "XRpgMakerGameControl")
function XRpgMakerGameControl:OnInit()
    
end

function XRpgMakerGameControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XRpgMakerGameControl:RemoveAgencyEvent()

end

function XRpgMakerGameControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

---@return XRpgMakerGameConfig
function XRpgMakerGameControl:GetConfig()
    return self._Model:GetConfig()
end

-- 加载场景
function XRpgMakerGameControl:LoadScene()
    self:ReleaseScene()
    
    local XRpgMakerGameScene = require("XModule/XRpgMakerGame/XRpgMakerGameScene")
    self._Scene = self:AddSubControl(XRpgMakerGameScene)
    XDataCenter.RpgMakerGameManager.SetCurrentScene(self._Scene) -- TODO MVCA改造中 临时赋值
    self._Scene:LoadScene()
end

-- 获取场景
---@return XRpgMakerGameScene
function XRpgMakerGameControl:GetScene()
    return self._Scene
end

-- 释放场景
function XRpgMakerGameControl:ReleaseScene()
    if self._Scene then
        self:RemoveSubControl(self._Scene)
        self._Scene = nil
        XDataCenter.RpgMakerGameManager.SetCurrentScene() -- TODO MVCA改造中 临时赋值
    end
end

--region 引导
-- 设置当前关卡Id
function XRpgMakerGameControl:SetCurrentStageId(stageId)
    self._Model:SetCurrentStageId(stageId)
end
--endregion

return XRpgMakerGameControl