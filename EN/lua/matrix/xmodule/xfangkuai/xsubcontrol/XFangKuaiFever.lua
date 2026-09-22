---@class XFangKuaiFever : XControl 狂热状态管理类
---@field _MainControl XFangKuaiControl
---@field _Model XFangKuaiModel
---@field _FevRadio number 狂热得分倍率=A+B×狂热阶段数
---@field _IsFev boolean 是否进入狂热状态（步数=0时可能还处于狂热状态 等棋盘静止后才会退出）
local XFangKuaiFever = XClass(XControl, "XFangKuaiFever")

function XFangKuaiFever:OnInit()
    
end

function XFangKuaiFever:AddAgencyEvent()

end

function XFangKuaiFever:RemoveAgencyEvent()

end

function XFangKuaiFever:OnRelease()

end

function XFangKuaiFever:InitData()
    local stageData = self._MainControl:GetCurStageData()
    self._IsFev = stageData and stageData:GetFevLevel() > 0
    self:UpdateRadio()
    XLog.Debug(string.format("初始化狂热状态 当前狂热倍率:%s 是否进入狂热状态:%s", self._FevRadio, self._IsFev and "是" or "否"))
end

function XFangKuaiFever:ResetFeverData()
    self._IsFev = false
    self._FevRadio = 1
end

-- 道具消除N个combo时，狂热值获取应该从1加到N，而不是直接加N
function XFangKuaiFever:AddFevValueByCombo(i)
    local combo = self._MainControl:GetComboNum() + i
    local comboGain = self._MainControl:GetFevComboGain(combo)
    local multi = self:GetStageMulti()
    local add = comboGain * multi
    local value = self._MainControl:GetCurStageData():AddFevValue(add)
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_FEVER_VALUE)
    XLog.Debug(string.format("当前combo:%s 增加狂热值:[%s × %s = %s] 总狂热值:%s", combo, comboGain, multi, add, value))
end

function XFangKuaiFever:AddFevValueByItem()
    local score = self:GetItemScore()
    local multi = self:GetStageMulti()
    local add = score * multi
    local value = self._MainControl:GetCurStageData():AddFevValue(add)
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_FEVER_VALUE)
    XLog.Debug(string.format("丢弃/移除道具 增加狂热值:[%s × %s = %s] 总狂热值:%s", score, multi, add, value))
end

function XFangKuaiFever:CheckEnterFever()
    local isEnterFev, isExitFev = false, false
    local maxValue = self._MainControl:GetFevExcitedValue()
    local maxLevel = self._MainControl:GetMaxFevLevel()
    
    local fevValue = self._MainControl:GetFeverValue()
    local stageData = self._MainControl:GetCurStageData()

    if fevValue >= maxValue then
        local addLevel = math.floor(fevValue / maxValue)
        stageData:SetFevValue(fevValue % maxValue)
        stageData:SetFevStep(self._MainControl:GetMaxEnhanceTimes())
        stageData:AddFevLevel(addLevel, maxLevel)
        isEnterFev = not self._IsFev
        self._IsFev = true
        --self._MainControl:TransformItems()
        if isEnterFev then
            stageData:RecordFeverRound()
        end
    elseif self._IsFev and stageData:GetFevStep() <= 0 then
        stageData:RecordFeverMaxLevel()
        stageData:SetFevLevel(0)
        self._IsFev = false
        --self._MainControl:TransformItems()
        isExitFev = true
    end
    self:UpdateRadio()
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_FEVER_VALUE)
    return isEnterFev, isExitFev
end

function XFangKuaiFever:UpdateRadio()
    if self._IsFev then
        local scoreValue = self._MainControl:GetFevScoreGainCoefficient()
        local scoreRadio = self._MainControl:GetFevScoreGainCoefficientRate()
        local fevLevel = self._MainControl:GetFevLevel()
        self._FevRadio = scoreValue + (scoreRadio * fevLevel) / 10000
    else
        self._FevRadio = 1
    end
end

function XFangKuaiFever:GetFevRadio()
    return self._FevRadio
end

function XFangKuaiFever:IsFever()
    return self._IsFev
end

function XFangKuaiFever:GetStageMulti()
    local stageId = self._MainControl:GetCurStageData():GetStageId()
    return self._MainControl:GetStageConfig(stageId).FevStageMulti / 10000
end

function XFangKuaiFever:GetItemScore()
    return self._MainControl:GetActivityConfig().FevItemGain
end

return XFangKuaiFever