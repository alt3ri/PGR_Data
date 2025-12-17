--- 玩法内实体控制器
---@class XTheatre5GameEntityControl: XEntityControl
---@field private _Model XTheatre5Model
---@field private _MainControl XTheatre5Control
---@field protected _CurGameEntity XTheatre5GameEntityBase
---@field protected _PVPGameEntity XTheatre5PVPGameEntity
---@field protected _PVEGameEntity XTheatre5PVEGameEntity
local XTheatre5GameEntityControl = XClass(XEntityControl, 'XTheatre5GameEntityControl')

function XTheatre5GameEntityControl:OnInit()
    self._CurGameEntity = nil
    self._PVPGameEntity = nil
    self._PVEGameEntity = nil
    
    self:OnModeChanged(true)
end

function XTheatre5GameEntityControl:AddAgencyEvent()
    XMVCA.XTheatre5:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_GAME_MODE_CHANGED, self.OnModeChanged, self)
end

function XTheatre5GameEntityControl:RemoveAgencyEvent()
    XMVCA.XTheatre5:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_GAME_MODE_CHANGED, self.OnModeChanged, self)
end

function XTheatre5GameEntityControl:OnRelease()

end

function XTheatre5GameEntityControl:OnModeChanged(noTips)
    local curMode = self._Model:GetCurPlayingMode()

    if curMode == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        if not self._PVPGameEntity then
            self._PVPGameEntity = self:AddEntity(require('XModule/XTheatre5/ControlEntity/XTheatre5PVPGameEntity'))
        end

        self._CurGameEntity = self._PVPGameEntity
    elseif curMode == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
        if not self._PVEGameEntity then
            self._PVEGameEntity = self:AddEntity(require('XModule/XTheatre5/ControlEntity/XTheatre5PVEGameEntity'))
        end

        self._CurGameEntity = self._PVEGameEntity
    else
        if not noTips then
            XLog.Error('当前未处于有效的模式，mode: '..tostring(curMode))
        end
    end
end

function XTheatre5GameEntityControl:GetCurRoundGridUnlockCostReduce()
    if not self._CurGameEntity then
        return 0
    end
    
    return self._CurGameEntity:GetCurRoundGridUnlockCostReduce()
end

function XTheatre5GameEntityControl:GetRuneGridInitCount()
    if not self._CurGameEntity then
        return 0
    end
    
    return self._CurGameEntity:GetRuneGridInitCount()
end

return XTheatre5GameEntityControl