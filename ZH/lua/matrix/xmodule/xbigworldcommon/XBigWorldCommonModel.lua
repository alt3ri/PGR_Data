local XBWCommonSequentialData = require("XModule/XBigWorldCommon/XData/XSequentialData/XBWCommonSequentialData")

---@class XBigWorldCommonModel : XModel
local XBigWorldCommonModel = XClass(XModel, "XBigWorldCommonModel")

local TableKey = {
    BigWorldCommonValues = {
        Identifier = "Key",
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XBigWorldCommonModel:OnInit()
    self._IsRegisterSequentialExecute = false
    ---@type table<number, XBWSequentialDataBase>
    self._SequentialJobs = {}

    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common", TableKey)
end

function XBigWorldCommonModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldCommonModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self:ClearAllSequentialJob()
end

---@return XBWSequentialDataBase
function XBigWorldCommonModel:GetSequentialJob(id)
    return self._SequentialJobs[id]
end

function XBigWorldCommonModel:ClearAllSequentialJob()
    if not XTool.IsTableEmpty(self._SequentialJobs) then
        for id, job in pairs(self._SequentialJobs) do
            self:ClearSequentialJob(id)
        end
    end
    self._SequentialJobs = {}
    self:RemoveSequentialExecute()
end

function XBigWorldCommonModel:AddSequentialJob(class, id)
    if class and XTool.IsNumberValid(id) then
        local job = class.New(id)

        if job then
            self._SequentialJobs[id] = job
            self:RegisterSequentialExecute()
        end
    end
end

function XBigWorldCommonModel:AddCommonSequentialJob(id)
    self:AddSequentialJob(XBWCommonSequentialData, id)
end

function XBigWorldCommonModel:AddSequentialJobBehavior(id, behavior)
    local job = self:GetSequentialJob(id)

    if job then
        job:AddBehavior(behavior)
    end
end

function XBigWorldCommonModel:RemoveSequentialJobBehavior(id, behavior)
    local job = self:GetSequentialJob(id)

    if job then
        job:RemoveBehavior(behavior)
    end
end

function XBigWorldCommonModel:ClearSequentialJob(id)
    local job = self:GetSequentialJob(id)

    if job then
        job:Clear()
        self._SequentialJobs[id] = nil
    end
    if XTool.IsTableEmpty(self._SequentialJobs) then
        self:RemoveSequentialExecute()
    end
end

function XBigWorldCommonModel:FinishSequentialJob(id)
    local job = self:GetSequentialJob(id)

    if job then
        job:Finish()
        self:ClearSequentialJob(id)
    end
end

function XBigWorldCommonModel:ExecuteSequentialJob(id, ...)
    local job = self:GetSequentialJob(id)

    if job then
        job:Execute(...)
    end
end

function XBigWorldCommonModel:RegisterSequentialExecute()
    if not self._IsRegisterSequentialExecute then
        self._ExecuteHandler = Handler(self, self.OnSequentialExecute)
        CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_COMMON_SEQUENTIAL_JOB_EXECUTE, self._ExecuteHandler)
        self._IsRegisterSequentialExecute = true
    end
end

function XBigWorldCommonModel:RemoveSequentialExecute()
    if self._IsRegisterSequentialExecute then
        CsXGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_COMMON_SEQUENTIAL_JOB_EXECUTE,
            self._ExecuteHandler)
        self._IsRegisterSequentialExecute = false
        self._ExecuteHandler = nil
    end
end

function XBigWorldCommonModel:OnSequentialExecute(_, args)
    if args and args.Length > 0 then
        local id = args[0] or 0

        if XTool.IsNumberValid(id) then
            self:ExecuteSequentialJob(id)
        end
    end
end

---@return string[]
function XBigWorldCommonModel:GetCommonValues(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldCommonValues, key)

    return config and config.Values or nil
end

return XBigWorldCommonModel
