local XBigWorldAgency = require("XModule/XBigWorld/XBigWorldAgency")

---@class XSkyGardenAgency : XBigWorldAgency
---@field private _Model XSkyGardenModel
local XSkyGardenAgency = XClass(XBigWorldAgency, "XSkyGardenAgency")

---@type X3CCommand
local X3C_CMD = CS.X3CCommand

function XSkyGardenAgency:OnInit()
    XBigWorldAgency.OnInit(self)
    self._ModuleList = {
        ModuleId.XSkyGardenCafe,
        ModuleId.XSkyGardenShoppingStreet,
        ModuleId.XSkyGardenDorm,
        ModuleId.XSkyGardenDroneGame,
    }
end

function XSkyGardenAgency:OnEnterFight()
    XMVCA.XFubenSkyGarden:ClearProgressTip()
    XMVCA.XBigWorldGamePlay:MarkSkyGardenEntryRedPoint()
    local graphicsQuality = CS.XQualityManager.Instance:GetCurQualitySettings()
    CS.XProfilingLuaUtils.PostValueI_1("SkyGarden", "QualitySetting", graphicsQuality)
end

function XSkyGardenAgency:OnExitFight()
end

function XSkyGardenAgency:OnInitX3C()
    local register = function(cmd, func, obj)
        XMVCA.X3CProxy:RegisterHandler(cmd, func, obj)
    end
    
    -- todo remove check 临时测试
    if X3C_CMD.CMD_SHOPSTREET_REQUEST_GAMEPLAY_DATA then
        register(X3C_CMD.CMD_SHOPSTREET_REQUEST_GAMEPLAY_DATA, XMVCA.XSkyGardenShoppingStreet.X3CSgRequestData, XMVCA.XSkyGardenShoppingStreet)
    end
    if X3C_CMD.CMD_SHOPSTREET_CUSTOMER_FINISH_TASK then
        register(X3C_CMD.CMD_SHOPSTREET_CUSTOMER_FINISH_TASK, XMVCA.XSkyGardenShoppingStreet.X3CSgCustomerFinishTask, XMVCA.XSkyGardenShoppingStreet)
    end


    --宿舍
    register(X3C_CMD.CMD_DORMITORY_GET_GAMEPLAY_DATA, XMVCA.XSkyGardenDorm.OnFightGetGamePlayData, XMVCA.XSkyGardenDorm)
    register(X3C_CMD.CMD_DORMITORY_PUSH_SPACE_DATA, XMVCA.XSkyGardenDorm.OnFightPushData, XMVCA.XSkyGardenDorm)
    register(X3C_CMD.CMD_DORMITORY_OPERATE_PHOTO_WALL, XMVCA.XSkyGardenDorm.OpenPhotoWall, XMVCA.XSkyGardenDorm)
    register(X3C_CMD.CMD_DORMITORY_OPERATE_FRAME_WALL, XMVCA.XSkyGardenDorm.OpenGiftWall, XMVCA.XSkyGardenDorm)
    register(X3C_CMD.CMD_DORMITORY_CHANGE_DORMITORY_SKIN, XMVCA.XSkyGardenDorm.OpenFashion, XMVCA.XSkyGardenDorm)

    --无人机
    register(X3C_CMD.CMD_UAV_CHAPTER_SELECT_VIEW_SWITCH_COMPLETE , XMVCA.XSkyGardenDroneGame.OnChapterSelectViewSwitchCompleteCmd, XMVCA.XSkyGardenDroneGame)
end

function XSkyGardenAgency:OnExit()
end

function XSkyGardenAgency:OnRegisterMVCA()
    for _, moduleId in pairs(self._ModuleList) do
        if not XMVCA:IsRegisterAgency(moduleId) then
            XMVCA:RegisterAgency(moduleId)
        end
    end

    for _, moduleId in pairs(self._ModuleList) do
        local agency = XMVCA:GetAgency(moduleId)
        if agency then
            agency:InitDynamicRegister()
        end
    end
end

function XSkyGardenAgency:OnUnRegisterMVCA()
    for i = #self._ModuleList, 1, -1 do
        local moduleId = self._ModuleList[i]    
        if XMVCA:IsRegisterAgency(moduleId) then
            XMVCA:ReleaseModule(moduleId)
        end
    end
end

function XSkyGardenAgency:LoadGuide()
    XLuaBehaviorManager.LoadBehaviorTree(CS.BehaviorTree.XGamePlayType.SkyGarden)
    XDataCenter.GuideManager.SwitchGuideProxy(XDataCenter.GuideManager.ProxyType.SkyGarden)
end

function XSkyGardenAgency:UnloadGuide()
    XLuaBehaviorManager.UnloadBehaviorTree(CS.BehaviorTree.XGamePlayType.SkyGarden)
    XDataCenter.GuideManager.RevertGuideProxy()
end

function XSkyGardenAgency:GetOpenGuideActionList()
    return XMVCA.XBigWorldGamePlay:GetSkyGardenOpenGuideIdList()
end

function XSkyGardenAgency:GetDefaultInputMapId()
    return CS.XInputMapId.SkyGarden
end

function XSkyGardenAgency:RecordHudClick(btnIndex)
    local dict = {}
    dict["btn_index"] = btnIndex
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "1100002", "SkyGardenUiOpen")
end

---@return XTableGuideText
function XSkyGardenAgency:GetBigWorldGuideTextTemplate(textId)
    return self._Model:GetGuideTextTemplate(textId)
end

---@return string
function XSkyGardenAgency:GetBigWorldGuideIcon(iconId)
    return self._Model:GetGuideIcon(iconId)
end

function XSkyGardenAgency:InitPerspective(perspectiveData)
    self._Model:InitPerspective(perspectiveData)
end

function XSkyGardenAgency:UpdatePerspective(groupId, perspectiveId)
    self._Model:UpdatePerspective(groupId, perspectiveId)
end

return XSkyGardenAgency