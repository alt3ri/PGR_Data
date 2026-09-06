---@class XFlowTreeRequire 行为树统一 require 收口
-- 业务侧只需 require 此文件，无需写长路径
-- 用法：
--   local XFT = require("XFlowTree/XFlowTreeRequire")
--   local root = XFT.XFlowTreeRoot.New()
--   local seq = XFT.XFlowTreeSequence.New()
--   local enum = XFT.XFlowTreeEnum

local XFlowTreeRequire = {}

--region 类引用

--region 基础类 core
XFlowTreeRequire.XFlowTreeEnum          = require("XFlowTree/XFlowTreeEnum")
XFlowTreeRequire.XFlowTreeNode          = require("XFlowTree/Base/XFlowTreeNode")
XFlowTreeRequire.XFlowTreeCompositeBase = require("XFlowTree/Base/XFlowTreeCompositeBase")
XFlowTreeRequire.XFlowTreeConditionBase = require("XFlowTree/Base/XFlowTreeConditionBase")
XFlowTreeRequire.XFlowTreeAction        = require("XFlowTree/Base/XFlowTreeAction")
XFlowTreeRequire.XFlowTreeRoot          = require("XFlowTree/XFlowTreeRoot")
--endregion

--region 控制流程
XFlowTreeRequire.XFlowTreeSequence      = require("XFlowTree/Composite/XFlowTreeSequence")
XFlowTreeRequire.XFlowTreeSelector      = require("XFlowTree/Composite/XFlowTreeSelector")
XFlowTreeRequire.XFlowTreeParallel      = require("XFlowTree/Composite/XFlowTreeParallel")
XFlowTreeRequire.XFlowTreeBranch       = require("XFlowTree/Composite/XFlowTreeBranch")
--endregion

--region 行为节点
XFlowTreeRequire.XFlowTreeActionDelay   = require("XFlowTree/Action/XFlowTreeActionDelay")
XFlowTreeRequire.XFlowTreeActionFunCall = require("XFlowTree/Action/XFlowTreeActionFunCall")
XFlowTreeRequire.XFlowTreeActionLog     = require("XFlowTree/Action/XFlowTreeActionLog")
--endregion

--endregion

return XFlowTreeRequire
