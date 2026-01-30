---@class XMainLineLuosaitaAgency : XAgency
---@field private _Model XMainLineLuosaitaModel
local XMainLineLuosaitaAgency = XClass(XAgency, "XMainLineLuosaitaAgency")
function XMainLineLuosaitaAgency:OnInit()
    -- EnumConst
    self.EnumConst = require("XModule/XMainLineLuosaita/XMainLineLuosaitaEnumConst")
end

function XMainLineLuosaitaAgency:InitRpc()
    XRpc.NotifyMainLineLuosaitaData = handler(self, self.NotifyMainLineLuosaitaData)
    XRpc.NotifyMainLineLuosaitaSectionInfo = handler(self, self.NotifyMainLineLuosaitaSectionInfo)
    self.RequestName = {
        MainLineLuosaitaEnterRequest = "MainLineLuosaitaEnterRequest",                      -- 阶段进入请求
        MainLineLuosaitaMoveRequest = "MainLineLuosaitaMoveRequest",                        -- 移动请求
        MainLineLuosaitaCharacterMoveRequest = "MainLineLuosaitaCharacterMoveRequest",      -- 请求角色移动
        MainLineLuosaitaUseDocRequest = "MainLineLuosaitaUseDocRequest",                    -- 使用文件请求
    }
end

function XMainLineLuosaitaAgency:InitEvent()

end

--region rpc
-- NotifyLogin数据
function XMainLineLuosaitaAgency:OnLoginNotify(data)
    if not data then return end
    self._Model:RefreshActivityData(data)
end

-- 下推更新所有数据
function XMainLineLuosaitaAgency:NotifyMainLineLuosaitaData(data)
    self._Model:RefreshActivityData(data.FubenMainLineLuosaitaData)
end

-- 下推更新单个Section数据
function XMainLineLuosaitaAgency:NotifyMainLineLuosaitaSectionInfo(data)
    self._Model:RefreshSectionInfo(data.SectionInfo)
end

-- 请求进入阶段
function XMainLineLuosaitaAgency:RequestMainLineLuosaitaEnter(sectionId, cb)
    local sectionInfo = self._Model:GetSectionInfo(sectionId)
    if sectionInfo then
        if cb then cb() end
        return
    end

    local req = { SectionId = sectionId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.MainLineLuosaitaEnterRequest, req, function(res)
        self._Model:RefreshSectionInfo(res.SectionInfo)
        if cb then cb() end
    end)
end

-- 请求移动
function XMainLineLuosaitaAgency:RequestMainLineLuosaitaMove(sectionId, posId, targetPosId, cb)
    local positionInfo = self._Model:GetPositionInfo(targetPosId)
    local enemyId = positionInfo:GetEnemyId()
    local req = { SectionId = sectionId, PosId = posId, TargetPosId = targetPosId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.MainLineLuosaitaMoveRequest, req, function(res)
        self._Model:RefreshSectionInfo(res.SectionInfo)
        self._Model:SetKillEnemy(enemyId)
        if cb then cb() end
    end)
end

-- 请求角色移动
function XMainLineLuosaitaAgency:RequestMainLineLuosaitaCharacterMove(sectionId, moveId, cb)
    local req = { SectionId = sectionId, MoveId = moveId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.MainLineLuosaitaCharacterMoveRequest, req, function(res)
        self._Model:RefreshSectionInfo(res.SectionInfo)
        if cb then cb() end
    end)
end

-- 请求使用文件
function XMainLineLuosaitaAgency:RequestMainLineLuosaitaUseDoc(sectionId, docId, cb)
    local req = { SectionId = sectionId, DocId = docId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.MainLineLuosaitaUseDocRequest, req, function(res)
        self._Model:RefreshSectionInfo(res.SectionInfo)
        if cb then cb() end
    end)
end
--endregion

-- 打开玩法主界面
function XMainLineLuosaitaAgency:ExOpenMainUi()
    XLuaUiManager.Open("UiMainLineLuosaitaMain")
end

-- 是否击败敌人
function XMainLineLuosaitaAgency:IsKillEnemy(enemyId)
    return self._Model:IsKillEnemy(enemyId)
end

return XMainLineLuosaitaAgency