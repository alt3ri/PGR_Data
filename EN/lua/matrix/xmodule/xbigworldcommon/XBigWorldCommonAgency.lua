---@class XBigWorldCommonAgency : XAgency
---@field private _Model XBigWorldCommonModel
---@field private KeyCode XBigWorldInputKeyCode
local XBigWorldCommonAgency = XClass(XAgency, "XBigWorldCommonAgency")

function XBigWorldCommonAgency:OnInit()
    -- 初始化一些变量
    ---@type XQueue
    self._ConfirmPopupDataPool = XQueue.New()
    ---@type XQueue
    self._QuitConfirmPopupDataPool = XQueue.New()
    
    self.CoolTimeFormat = {
        -- 显示为 00:00:01
        Clock = 1,
    }
    
    self.ModelInfoType = {
        LookAtIK = 1,
        AnimationIK = 2,
        Effect = 3,
    }
    
    self.KeyCode = require("XModule/XBigWorldCommon/XInput/XInputKeyCode")
end

function XBigWorldCommonAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
end

function XBigWorldCommonAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

---@return XBWPopupConfirmData
function XBigWorldCommonAgency:GetPopupConfirmData()
    if self._ConfirmPopupDataPool:IsEmpty() then
        local XBWPopupConfirmData = require("XModule/XBigWorldCommon/XData/XConfirmData/XBWPopupConfirmData")

        return XBWPopupConfirmData.New()
    end

    local confirmData = self._ConfirmPopupDataPool:Dequeue()

    confirmData:Clear()

    return confirmData
end

---@return XBWPopupQuitConfirmData
function XBigWorldCommonAgency:GetPopupQuitConfirmData()
    if self._QuitConfirmPopupDataPool:IsEmpty() then
        local XBWPopupQuitConfirmData = require("XModule/XBigWorldCommon/XData/XConfirmData/XBWPopupQuitConfirmData")

        return XBWPopupQuitConfirmData.New()
    end

    local confirmData = self._QuitConfirmPopupDataPool:Dequeue()

    confirmData:Clear()

    return confirmData
end

---@param data XBWPopupConfirmData
function XBigWorldCommonAgency:RepaidPopupConfirmData(data)
    data:Clear()
    self._ConfirmPopupDataPool:Enqueue(data)
end

---@param data XBWPopupQuitConfirmData
function XBigWorldCommonAgency:RepaidPopupQuitConfirmData(data)
    data:Clear()
    self._QuitConfirmPopupDataPool:Enqueue(data)
end

function XBigWorldCommonAgency:CreateShadyController(uiTransform, isAutoOpen)
    local transform = uiTransform:FindTransform("SafeAreaContentPane")

    if not transform then
        transform = uiTransform
    end

    local shadyUrl = XMVCA.XBigWorldResource:GetAssetUrl("Shady")
    local shady = transform:LoadPrefab(shadyUrl)
    local controller = shady.gameObject:GetComponent(typeof(CS.XUiShadyController))

    if XTool.UObjIsNil(controller) then
        controller = shady.gameObject:AddComponent(typeof(CS.XUiShadyController))
    end

    controller:SetTarget(shady.transform, "DarkEnable")

    if isAutoOpen then
        controller:Open()
    end

    return controller
end

---@return XCoolTime
function XBigWorldCommonAgency:GetCoolTime()
    if not self._CoolTime then
        self._CoolTime  = require("XModule/XBigWorldCommon/XCoolTime/XCoolTime").New()
    end
    return self._CoolTime
end

function XBigWorldCommonAgency:GetCoolTimeStr(second)
    return self:GetCoolTime():GetClockTimeStr(second)
end

-- region 任务流水线

function XBigWorldCommonAgency:AddCommonSequentialJob(serial)
    serial = serial or CS.StatusSyncFight.ESequentialJobsSerial.Main

    local id = CS.StatusSyncFight.XFightClient.DelayedJobManager:CreateAndExecuteCommonSequentialJob(serial)

    self._Model:AddCommonSequentialJob(id)

    return id
end

function XBigWorldCommonAgency:AddSequentialJobBehavior(id, behavior)
    self._Model:AddSequentialJobBehavior(id, behavior)
end

function XBigWorldCommonAgency:RemoveSequentialJobBehavior(id, behavior)
    self._Model:RemoveSequentialJobBehavior(id, behavior)
end

function XBigWorldCommonAgency:ExecuteSequentialJob(id, ...)
    self._Model:ExecuteSequentialJob(id, ...)
end

function XBigWorldCommonAgency:FinishSequentialJob(id)
    self._Model:FinishSequentialJob(id)
end

function XBigWorldCommonAgency:ClearSequentialJob(id)
    self._Model:ClearSequentialJob(id)
end

-- endregion

return XBigWorldCommonAgency
