---@class XGame2048ActionParams: XGame2048AnimationParams
---@field GridUidA
---@field GridUidB
---@field MoveFromX
---@field MoveFromY
---@field MoveToX
---@field MoveToY
---@field TempGridData
---@field EventId
---@field EventArgs
---@field MergeEffectType

local XGame2048Animation = require('XModule/XGame2048/AnimationGroup/XGame2048Animation')
---@class XGame2048Action: XGame2048Animation
local XGame2048Action = XClass(XGame2048Animation ,'XGame2048Action')

function XGame2048Action:Ctor()
    
end

function XGame2048Action:SetActionType(type)
    self._Type = type
    self:OnResetData()
end

function XGame2048Action:SetMoveAction(moveGridUid, fromx, fromy, tox,     -- 如果有关联的移动行为，后续需更新关联行为的目的地坐标
                                       toy, followUid)
    self:_OnParamsInnerSetBegin()
    
    self._Params.GridUidA = moveGridUid
    self._Params.MoveFromX = fromx
    self._Params.MoveFromY = fromy
    self._Params.MoveToX = tox
    self._Params.MoveToY = toy
    -- 如果有关联的移动行为，后续需更新关联行为的目的地坐标
    self._Params.GridUidB = followUid
    
    self:_OnParamsInnerSetEnd()
end

function XGame2048Action:SetTempGridData(gridData)
    self:SetParam('TempGridData', gridData)
end

function XGame2048Action:SetMergeAction(mergeFromUid, mergeToUid, mergeToBlockId)
    self:_OnParamsInnerSetBegin()

    self._Params.GridUidA = mergeFromUid
    self._Params.GridUidB = mergeToUid
    self._Params.GridIdB = mergeToBlockId

    self:_OnParamsInnerSetEnd()
end

function XGame2048Action:SetDispelAction(gridUid)
    self:SetParam('GridUidA', gridUid)
end

function XGame2048Action:SetReduceAction(gridUid)
    self:SetParam('GridUidA', gridUid)
end

function XGame2048Action:SetNewBornAction(gridUid)
    self:SetParam('GridUidA', gridUid)
end 

function XGame2048Action:SetCurGridUid(gridUid)
    self:SetParam('GridUidA', gridUid)
end

function XGame2048Action:SetLevelUpAction(gridUid)
    self:SetParam('GridUidA', gridUid)
end

function XGame2048Action:SetPosAimAction(x, y)
    self:SetParam('MoveFromX', x)
    self:SetParam('MoveFromY', y)
end

function XGame2048Action:SetEventCall(eventId, ...)
    self:SetParam('EventId', eventId)
    self:SetParam('EventArgs', {...})
end

function XGame2048Action:SetMergeEffectType(type)
    self:SetParam('MergeEffectType', type)
end

function XGame2048Action:OnResetData()
    self._Params.MoveFromX = 0
    self._Params.MoveFromY = 0
    self._Params.MoveToX = 0
    self._Params.MoveToY = 0
    self._Params.GridUidA = nil
    self._Params.GridUidB = nil
    self._Params.EventId = nil
    self._Params.EventArgs = nil
    self._Params.GridIdB = nil
    self._Params.TempGridData = nil
    self._Params.MergeEffectType = nil
end

function XGame2048Action:GetActionType()
    return self._Type or XMVCA.XGame2048.EnumConst.ActionType.None
end

return XGame2048Action