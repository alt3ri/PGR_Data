local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XRpgMakerGameAgency : XFubenActivityAgency
---@field private _Model XRpgMakerGameModel
local XRpgMakerGameAgency = XClass(XFubenActivityAgency, "XRpgMakerGameAgency")
function XRpgMakerGameAgency:OnInit()
    -- 初始化一些变量
    self:RegisterActivityAgency()
    -- EnumConst
    self.EnumConst = require("XModule/XRpgMakerGame/XRpgMakerGameEnumConst")
    -- RPC
    XRpc.NotifyRpgMakerGameActivityData = handler(self, self.NotifyRpgMakerGameActivityData)
    self.RPCRequest = {
        RpgMakerGameEnterStageRequest = "RpgMakerGameEnterStageRequest", -- 请求进入关卡
    }
end

function XRpgMakerGameAgency:InitRpc()
    -- 实现服务器事件注册
    -- TODO
end

--region 副本入口扩展
-- 获取进度
function XRpgMakerGameAgency:ExGetProgressTip()
    local chapterGroupId = XDataCenter.RpgMakerGameManager.GetDefaultChapterGroupId()
    local allStarCnt, curStarCnt = self._Model:GetChapterGroupStarCount(chapterGroupId)
    return XUiHelper.GetText("BossSingleProgress", curStarCnt, allStarCnt)
end
--endregion

---@return XRpgMakerGameConfig
function XRpgMakerGameAgency:GetConfig()
    return self._Model:GetConfig()
end

-- 延迟被攻击回调的时间
function XRpgMakerGameAgency:GetBeAtkEffectDelayCallbackTime()
    return CS.XGame.ClientConfig:GetInt("RpgMakerGamePlayBeAtkEffectDelayCallbackTime")
end

--region 协议
-- 通知玩法数据
function XRpgMakerGameAgency:NotifyRpgMakerGameActivityData(data)
    XDataCenter.RpgMakerGameManager.UpdateActivityData(data)
end

function XRpgMakerGameAgency:RequestRpgMakerGameEnterStage(stageId, selectRoleId, cb)
    local req = { StageId = stageId, SelectRoleId = selectRoleId }
    XNetwork.CallWithAutoHandleErrorCode(self.RPCRequest.RpgMakerGameEnterStageRequest, req, function(res)
        -- 旧manager设置数据(TODO 待改造)
        local RpgMakerGameEnterStageDb = XDataCenter.RpgMakerGameManager.GetRpgMakerGameEnterStageDb()
        RpgMakerGameEnterStageDb:UpdateData(res)
        XDataCenter.RpgMakerGameManager.SetCurrentCount(0)
        XDataCenter.RpgMakerGameManager.ResetActions()
        XDataCenter.RpgMakerGameManager.AddActions(res.Actions)
        -- 设置数据
        self._Model:OnEnterStage(res)

        if cb then cb() end
    end)
end
--endregion

--region 引导
-- 获取当前关卡Id
function XRpgMakerGameAgency:GetCurrentStageId()
    return self._Model:GetCurrentStageId()
end
--endregion

return XRpgMakerGameAgency
