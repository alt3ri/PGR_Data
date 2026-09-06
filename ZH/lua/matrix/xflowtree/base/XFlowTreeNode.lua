---@class XFlowTreeNode 行为树节点基类
---@field private _Context any 流程上下文
---@field private _Parent XFlowTreeCompositeBase 父节点
---@field private _Status XFlowTreeEnum.Status 节点状态
---@field private _Result XFlowTreeEnum.Result 执行结果
---@field private _TreeRoot XFlowTreeRoot 根节点管理者（Debug用）
---@field private _IsWorking boolean 是否正在生效
---@field private _DoneHandler function 流程完毕回调函数
---@field private _DoneHandlerObj any 流程完毕回调 self 句柄
local XFlowTreeNode = XClass(nil, "XFlowTreeNode")

XFlowTreeNode.XFlowTreeEnum = require("XFlowTree/XFlowTreeEnum")

 
function XFlowTreeNode:Ctor()
    self._Context = nil           -- 流程上下文
    self._Parent = nil            -- 父节点（XFlowTreeCompositeBase）
    self._Status = self.XFlowTreeEnum.Status.Init    -- 节点状态
    self._Result = self.XFlowTreeEnum.Result.Unknown -- 执行结果
    self._TreeRoot = nil          -- 根节点管理者（Debug用）
    self._IsWorking = false       -- 是否正在生效
    self._DoneHandler = nil       -- 流程完毕回调函数
    self._DoneHandlerObj = nil    -- 流程完毕回调 self 句柄
end


--region 使用者需要tobeoverrid 的方法

-- 子类重写：进入节点。 一般监听事件，和干活
function XFlowTreeNode:OnEnter(context)
end

-- 子类重写：离开节点。 取消监听事件，和干活
--@param isInterrupt boolean 是否被打断
function XFlowTreeNode:OnExit(isInterrupt)
end


-- 子类重写：销毁。 真正的清理字段，清理回调什么的。
function XFlowTreeNode:OnDestroy()
    if self._IsWorking then
        self._IsWorking = false
        self:OnExit(false)
    end
    self._Parent = nil
    self._TreeRoot = nil
    self._DoneHandler = nil
    self._DoneHandlerObj = nil
end
--endregion

--region 使用者子类调用方法

-- 完成节点，上报结果
function XFlowTreeNode:OnDone(result)
    if not self._IsWorking then
        return
    end

    if result == self.XFlowTreeEnum.Result.Succeed then
        self:InternalSetResult(self.XFlowTreeEnum.Result.Succeed)
    else
        self:InternalSetResult(self.XFlowTreeEnum.Result.Fail)
    end

    self:_OnStop()

    if self._DoneHandler then
        if self._DoneHandlerObj then
            self._DoneHandler(self._DoneHandlerObj, self:InternalGetResult())
        else
            self._DoneHandler(self:InternalGetResult())
        end
    end

    local parent = self:InternalGetParent()
    if parent then
        parent:OnChildDone(self)
    end
end
 
--endregion

--region 使用者外部使用方法

-- 设置完成回调（外部调用）
--@param handler function 回调函数 function(handlerObj, result) 或 function(result)
--@param handlerObj any 可选，self 句柄
function XFlowTreeNode:SetDoneCallback(handler, handlerObj)
    self._DoneHandler = handler
    self._DoneHandlerObj = handlerObj
end

--endregion



--region 行为树内部使用方法

function XFlowTreeNode:GetNodeType()
    return self.XFlowTreeEnum.NodeType.UnKnown
end

-- 断言：节点尚未启动（状态为 Init）。已启动则报错并返回 false
--@param funcName string 调用来源方法名，用于报错定位
--@return boolean 是否可继续（true=未启动可继续；false=已启动，调用方应 return）
function XFlowTreeNode:InternalAssertNotStarted(funcName)
    if self._Status ~= self.XFlowTreeEnum.Status.Init then
        XLog.Error(string.format("[XFlowTree] %s 失败：行为树已启动，不允许再修改结构", tostring(funcName)))
        return false
    end
    return true
end

function XFlowTreeNode:InternalGetStatus()
    return self._Status
end

function XFlowTreeNode:InternalSetStatus(status)
    self._Status = status
end

function XFlowTreeNode:InternalGetResult()
    return self._Result
end

function XFlowTreeNode:InternalSetResult(result)
    self._Result = result
end

function XFlowTreeNode:InternalGetParent()
    return self._Parent
end

function XFlowTreeNode:InternalSetParent(parent)
    self._Parent = parent
end

function XFlowTreeNode:InternalGetTreeRoot()
    return self._TreeRoot
end

function XFlowTreeNode:InternalSetTreeRoot(treeRoot)
    self._TreeRoot = treeRoot
end


-- 启动节点
function XFlowTreeNode:OnStart(context)
    self._TreeRoot:InternalRecordCurrentNode(self)
    self._Context = context
    self:InternalSetStatus(self.XFlowTreeEnum.Status.Running)
    self._IsWorking = true
    self:OnEnter(context)
end

-- 打断节点（运行中被外部停止）
function XFlowTreeNode:OnInterrupt()
    if not self._IsWorking then
        return
    end
    self._IsWorking = false
    self:OnExit(true)
    self._Context = nil
    self:InternalSetStatus(self.XFlowTreeEnum.Status.Stopped)
    self:InternalSetResult(self.XFlowTreeEnum.Result.Interrupt)
end


function XFlowTreeNode:_OnStop()
    if not self._IsWorking then
        return
    end
    self._IsWorking = false
    self:OnExit(false)
    self._Context = nil
    self:InternalSetStatus(self.XFlowTreeEnum.Status.Stopped)
end
--endregion

return XFlowTreeNode
