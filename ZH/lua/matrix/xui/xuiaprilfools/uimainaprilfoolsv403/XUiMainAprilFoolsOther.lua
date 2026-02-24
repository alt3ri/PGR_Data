local XUiPanelAprilFoolsSignBoard = require("XUi/XUiAprilFools/UiMainAprilFoolsV403/XUiPanelAprilFoolsSignBoard")

---@class XUiMainAprilFoolsOther:XUiNode
---@field _Control XAprilFoolDayControl
local XUiMainAprilFoolsOther = XClass(XUiNode, "XUiMainAprilFoolsOther")

function XUiMainAprilFoolsOther:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiMainAprilFoolsOther:OnEnable()
    if self.SignBoard then
        self.SignBoard:DoRandomAndChangeDisplayCharacter()
        self.SignBoard:OnEnable()
    end
end

function XUiMainAprilFoolsOther:OnDisable()
    if self.SignBoard then
        self.SignBoard:OnDisable()
    end
end

function XUiMainAprilFoolsOther:OnDestroy()
    if self.SignBoard then
        self.SignBoard:OnDestroy()
    end
    
    self.SignBoard = nil
end

function XUiMainAprilFoolsOther:SafeCreateSignBoard()
    if self.SignBoard then
        if self.SignBoard:IsPrepareDestory() then
            self.SignBoard:OnDestroy()
            self.SignBoard = nil
        else
            return
        end
    end
    ---@type XUiPanelSignBoard
    self.SignBoard = XUiPanelAprilFoolsSignBoard.New(self.PanelSignBoard, self.RootUi, XUiPanelAprilFoolsSignBoard.SignBoardOpenType.MAIN)
    self:OnEnable()
end

function XUiMainAprilFoolsOther:Stop()
    if not self.SignBoard then
        return
    end
    self.SignBoard:Stop()
end

function XUiMainAprilFoolsOther:ForceStop()
    if not self.SignBoard then
        return
    end
    self.SignBoard:Stop(true)
end

function XUiMainAprilFoolsOther:OnTickOutShow(times)
    if not self.SignBoard then
        return
    end

    local actionId = self._Control:GetCurClearOutActionIdByTimes(times)
    local content = self._Control:GetCurClearOutContentByTimes(times)
    local contentShowTime = math.floor(self._Control:GetCurClearOutContentShowTimeByTimes(times) * XScheduleManager.SECOND)

    local callback = nil
    
    if self._Control:CheckClearOutIsMax() then
        callback = function() 
            XMVCA.XAprilFoolDay:RequestFoolsDayClearOutComplete()
            --todo: 播放黑幕动画
            XLuaUiManager.RunMain()
        end
    end
    
    self.SignBoard:OnTickOutShow(actionId, content, contentShowTime, callback)
end

--region Getter

function XUiMainAprilFoolsOther:GetRoleModel()
    if self.SignBoard then
        return self.SignBoard.RoleModel
    end
    return false
end

function XUiMainAprilFoolsOther:ForceStopAnim()
    self.SignBoard:OnStop(self.SignBoard.SignBoardPlayer.PlayerData.PlayingElement, true)
end

---@return UnityEngine.Transform
function XUiMainAprilFoolsOther:GetRoleModelTransform()
    if self.SignBoard and self.SignBoard.DisplayState and not XTool.UObjIsNil(self.SignBoard.DisplayState.Model) then
        return self.SignBoard.DisplayState.Model.transform
    end
    return nil
end

--endregion

return XUiMainAprilFoolsOther
