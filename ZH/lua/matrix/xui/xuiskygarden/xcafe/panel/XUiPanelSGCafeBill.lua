---@class XUiGridSGCafeTarget : XUiNode
---@field _Control XSkyGardenCafeControl
---@field Parent XUiSkyGardenCafeGame
---@field StateControl XUiComponent.XUiStateControl
local XUiGridSGCafeTarget = XClass(XUiNode, "XUiGridSGCafeTarget")

local CSStopAudioByCueId = CS.XAudioManager.StopAudioByCueId

function XUiGridSGCafeTarget:OnStart()
    self._ActiveName = "On"
    self._InActiveName = "Off"
end

function XUiGridSGCafeTarget:Refresh(value, isActive)
    self.TxtNumOn.text = value
    self.TxtNumOff.text = value
    
    local name = isActive and self._ActiveName or self._InActiveName
    self.StateControl:ChangeState(name)
    self:Open()
end


---@class XUiPanelSGCafeBill : XUiNode
---@field _Control XSkyGardenCafeControl
---@field Parent XUiSkyGardenCafeGame
local XUiPanelSGCafeBill = XClass(XUiNode, "XUiPanelSGCafeBill")

local Duration = 0.8
local tableRemove = table.remove

function XUiPanelSGCafeBill:OnStart()
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGCafeBill:OnDestroy()
    local agency = XMVCA.XSkyGardenCafe
    agency:RemoveInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EFFECT_FLY_COMPLETE, self.Dequeue, self)
    agency:RemoveInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ROUND_BEGIN, self.Refresh, self)
    agency:RemoveInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EFFECT_BEGIN_FLY, self.Enqueue, self)
    agency:RemoveInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_SETTLEMENT, self.OnSettlement, self)

    if self._CoffeeTimer then
        XScheduleManager.UnSchedule(self._CoffeeTimer)
    end
    
    if self._ReviewTimer then
        XScheduleManager.UnSchedule(self._ReviewTimer)
    end
    self:TryStopPlayingSound()
end

function XUiPanelSGCafeBill:InitUi()
    self._DataPool = {}
    self._DataQueue = {}
    self._GridTargets = {}
    local battleInfo = self._Control:GetBattle():GetBattleInfo()
    
    local stageId = battleInfo:GetStageId()
    self.TxtTarget.text = self._Control:GetStageName(stageId)
    self._CurTotalCafe = battleInfo:GetTotalScore()
    self._LastCafe = battleInfo:GetScore()
    self._CurCafe = battleInfo:GetAddScore()
    local nextTarget, maxTarget = self._Control:GetNextTargetAndMaxTargetByCoffee(stageId, self._CurTotalCafe)
    --self._NextTarget = nextTarget
    self._MaxTarget = maxTarget
    
    self._CurTotalReview = battleInfo:GetTotalReview()

    self._IsReviewStage = self._Control:IsReviewStage()
    self.PanelFavorability.gameObject:SetActiveEx(self._IsReviewStage)

    if self._IsReviewStage then
        self.TxtReviewNum.text = self._CurTotalReview
    end
    
    self.ImgTargetYuan.fillAmount = self._CurTotalCafe / maxTarget
    self.TxtTotalNum.text = self._CurTotalCafe
    self.TxtTargetNum.text = string.format("<color=#FF000>/%s</color>", maxTarget)
    self.TxtHistoryNum.text = self._LastCafe
    self.TxtCurrentNum.text = self._CurCafe
    
    self:RefreshTarget(stageId, self._CurTotalCafe)
end

function XUiPanelSGCafeBill:InitCb()
    local agency = XMVCA.XSkyGardenCafe
    agency:AddInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EFFECT_FLY_COMPLETE, self.Dequeue, self)
    agency:AddInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ROUND_BEGIN, self.Refresh, self)
    agency:AddInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EFFECT_BEGIN_FLY, self.Enqueue, self)
    agency:AddInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_SETTLEMENT, self.OnSettlement, self)
end

function XUiPanelSGCafeBill:Refresh()
    if not XTool.IsTableEmpty(self._DataQueue) then
        for i =#self._DataQueue, 1, -1 do
            local data = self._DataQueue[i]
            self:RecycleData(data)
            tableRemove(self._DataQueue, i)
        end
    end
    self:TryStopPlayingSound()
    self:Enqueue()
    self:Dequeue(true)
end

---@param data XSkyGardenCafeBillData
function XUiPanelSGCafeBill:RefreshCoffee(data, isForce)
    --最新账单数据
    local total = data.TotalCoffee
    local last = data.LastCoffee
    --当前显示账单数据
    local totalInView = self._CurTotalCafe
    local lastInView = self._LastCafe
    local currentInView = self._CurCafe
    
    local sameTotal = totalInView == total
    if not isForce and sameTotal and lastInView == last then
        return
    end
    local stageId = self._Control:GetBattle():GetBattleInfo():GetStageId()
    
    if self._CoffeeTimer then --动画还在播放，直接停止播放，采用最新的
        self:OnCoffeeAnimationComplete(stageId, total)
    end

    self:PlayResourceChangeSound(totalInView, total, true)
    
    local cur = data.CurrentCoffee
    --更新数据
    self:UpdateCoffee(total, cur, last)
    local maxTarget = self._MaxTarget
    if not sameTotal then
        self.Parent:SetBillEffect(true, true)
    end
    local mathFloor = math.floor
    local duration = self:GetDuration(total - totalInView)
    self._CoffeeTimer = self:Tween(duration, function(dt)
        local t = (total - totalInView) * dt + totalInView
        self.TxtTotalNum.text = mathFloor(t)
        self.ImgTargetYuan.fillAmount = t / maxTarget
        self.TxtHistoryNum.text = mathFloor((last - lastInView) * dt + lastInView)
        self.TxtCurrentNum.text = mathFloor((cur - currentInView) * dt + currentInView)
        
    end, function()
        self._CoffeeTimer = nil
        self:OnCoffeeAnimationComplete(stageId, total)
    end)
end

function XUiPanelSGCafeBill:OnCoffeeAnimationComplete(stageId, total)
    if self._CoffeeTimer then
        XScheduleManager.UnSchedule(self._CoffeeTimer)
    end
    self._CoffeeTimer = nil
    self.Parent:SetBillEffect(true, false)
    self:RefreshTarget(stageId, total)
    self:StopResourceChangeSound(true)
end

function XUiPanelSGCafeBill:UpdateCoffee(total, current, last)
    self._CurTotalCafe = total
    self._LastCafe = last
    self._CurCafe = current
end

---@param data XSkyGardenCafeBillData
function XUiPanelSGCafeBill:RefreshReview(data, isForce)
    if not self._IsReviewStage then
        return
    end
    local total = data.TotalReview
    local totalInView = self._CurTotalReview
    if not isForce and total == totalInView then
        return
    end
    if self._ReviewTimer then --动画还在播放，直接停止播放，采用最新的
        self:OnReviewAnimationComplete()
    end
    self:PlayResourceChangeSound(totalInView, total, false)
    self._CurTotalReview = total
    self.Parent:SetBillEffect(false, true)
    local mathFloor = math.floor
    local duration = self:GetDuration(total - totalInView)
    self._ReviewTimer = self:Tween(duration, function(dt)
        self.TxtReviewNum.text = mathFloor((total - totalInView) * dt + totalInView)
    end, function()
        self._ReviewTimer = nil
        self:OnReviewAnimationComplete()
    end)
end

function XUiPanelSGCafeBill:OnReviewAnimationComplete()
    if self._ReviewTimer then
        XScheduleManager.UnSchedule(self._ReviewTimer)
    end
    self._ReviewTimer = nil
    self.Parent:SetBillEffect(false, false)
    self:StopResourceChangeSound(false)
end

function XUiPanelSGCafeBill:Enqueue()
    local data = self:CreateData()
    local battleInfo = self._Control:GetBattle():GetBattleInfo()
    data.TotalCoffee = battleInfo:GetTotalScore()
    data.CurrentCoffee = battleInfo:GetAddScore()
    data.LastCoffee = battleInfo:GetScore()
    data.TotalReview = battleInfo:GetTotalReview()
    self._DataQueue[#self._DataQueue + 1] = data
end

function XUiPanelSGCafeBill:OnSettlement()
    self:TryStopPlayingSound()
end

function XUiPanelSGCafeBill:Dequeue(isForce)
    ---@type XSkyGardenCafeBillData
    local data = tableRemove(self._DataQueue, 1)
    if not data then
        return
    end
    if data.TotalCoffee - self._CurTotalCafe > 0 then
        self._Control:ChangeGamePetState(XMVCA.XSkyGardenCafe.GamePetState.AddCoffee)
    elseif data.TotalReview - self._CurTotalReview > 0 then
        self._Control:ChangeGamePetState(XMVCA.XSkyGardenCafe.GamePetState.AddReview)
    end
    self:RefreshCoffee(data, isForce)
    self:RefreshReview(data, isForce)
    
    self:RecycleData(data)
end

---@return XSkyGardenCafeBillData
function XUiPanelSGCafeBill:CreateData()
    if not XTool.IsTableEmpty(self._DataPool) then
        return tableRemove(self._DataPool)
    end
    return {
        TotalCoffee = 0,
        CurrentCoffee = 0,
        LastCoffee = 0,
        --NextTarget = 0,
        TotalReview = 0,
    }
end

function XUiPanelSGCafeBill:RecycleData(data)
    self._DataPool[#self._DataPool + 1] = data
end

function XUiPanelSGCafeBill:RefreshTarget(stageId, score)
    local targets = self._Control:GetStageTarget(stageId)
    for i = 1, 3 do
        local panel = self._GridTargets[i]
        if not panel then
            panel = XUiGridSGCafeTarget.New(self["Tar"..i], self)
            self._GridTargets[i] = panel
        end
        local value = targets and targets[i] or -1
        if value < 0 then
            panel:Close()
        else
            panel:Refresh(value, value <= score)
        end
    end
end

function XUiPanelSGCafeBill:GetDuration(count)
    count = math.abs(count)
    if count == 0 or count > 8then
        return Duration
    end
    return count * 0.1
end

function XUiPanelSGCafeBill:PlayResourceChangeSound(cur, next, isCoffee)
    local isAdd = next > cur
    local isSub = next < cur
    self:StopResourceChangeSound(isCoffee)
    if isCoffee then
        local cueKey
        if isAdd then
            cueKey = XMVCA.XSkyGardenCafe.CafeCueKey.AddCoffeeCueKey
        elseif isSub then
            cueKey = XMVCA.XSkyGardenCafe.CafeCueKey.SubCoffeeCueKey
        end
        if cueKey then
            self._CoffeeAudioInfo = self.AudioPlayer:PlayByKeyName(cueKey)
        end
    else
        local cueKey
        if isAdd then
            cueKey = XMVCA.XSkyGardenCafe.CafeCueKey.AddReviewCueKey
        elseif isSub then
            cueKey = XMVCA.XSkyGardenCafe.CafeCueKey.SubReviewCueKey
        end
        if cueKey then
            self._ReviewAudioInfo = self.AudioPlayer:PlayByKeyName(cueKey)
        end
    end
end

function XUiPanelSGCafeBill:StopResourceChangeSound(isCoffee)
    if isCoffee then
        if self._CoffeeAudioInfo then
            self._CoffeeAudioInfo:Stop()
            self._CoffeeAudioInfo = nil
        end
    else
        if self._ReviewAudioInfo then
            self._ReviewAudioInfo:Stop()
            self._ReviewAudioInfo = nil
        end
    end
end

function XUiPanelSGCafeBill:TryStopPlayingSound()
    if self._ReviewAudioInfo then
        self._ReviewAudioInfo:Stop()
    end

    if self._CoffeeAudioInfo then
        self._CoffeeAudioInfo:Stop()
    end
end

---@class XSkyGardenCafeBillData
---@field TotalCoffee number
---@field CurrentCoffee number
---@field LastCoffee number
---@field TotalReview number

return XUiPanelSGCafeBill