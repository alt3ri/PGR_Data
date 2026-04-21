local XLevel6001Present = XDlcScriptManager.RegLevelPresentScript(600101)

---@param proxy XDlcCSharpFuncs
function XLevel6001Present:Ctor(proxy)
    --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy
end

function XLevel6001Present:Init()
    --初始化逻辑
    --region 响应事件注册
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectMoveStop)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectActionFinish)
    self._proxy:RegisterEvent(EWorldEvent.DramaCaptionBegin)
    self._proxy:RegisterEvent(EWorldEvent.DramaCaptionEnd)
    --endregion

    --region 交互事件参数初始化
    self:InitWishingPond() --许愿池打捞
    --endregion

end

---@param dt number @ delta time
function XLevel6001Present:Update(dt)
    --每帧更新逻辑,暂时没有需要tick的内容，需要的话去抄5001
end


--region 响应事件
---@param eventType number
---@param eventArgs userdata
function XLevel6001Present:HandleEvent(eventType, eventArgs)
    --Trigger相关逻辑暂无，需要时抄5001的。
    XLog.Debug("触发响应事件")
    --交互事件
    if eventType == EWorldEvent.NpcInteractStart and self._proxy:IsPlayerNpc(eventArgs.LauncherId) then
        self:OnWishingPondNpcInteractStart(eventType, eventArgs) --许愿池打捞交互
    end

    --监听底端字幕（简易台词）播放完成后，恢复对应物件交互
    if eventType == EWorldEvent.DramaCaptionEnd then
        local caption = eventArgs.CaptionName
        XLog.Debug(caption)
        --恢复许愿池可交互性
        if caption =="Caption600112" or self:IsInclude(caption,self._WishPondCaptionPool) then
            self._proxy:SetActorInteractableComponentEnableByPlaceId(2,self._WishPondPlaceID,true)
        end
        --其他还没写
    end


end
--endregion


--------------事件本体---------------

--region 许愿池打捞
function XLevel6001Present:InitWishingPond() --初始化参数
    self._WishPondPlaceID = 3900004
    self._WishPondCaptionPool= {
        "Caption600106",
        "Caption600107",
        "Caption600108",
        "Caption600109",
        "Caption600110",
        "Caption600111",
    }
    self._WishPondPlayedCaptions={}
    self._WishPondCurrentCaptionIndex= 1
    self._WishPondFinalCaption="Caption600112"
    for i = #self._WishPondCaptionPool, 2, -1 do
        local j = math.random(i)
        self._WishPondCaptionPool[i], self._WishPondCaptionPool[j] = self._WishPondCaptionPool[j], self._WishPondCaptionPool[i]
    end
    ---DS写的 #应该是代表元素数量。这一整段是通过洗牌算法预先随机好，打乱原pool的排序（因此没有创建一个新的数组来存新顺序）。
    XLog.Debug("许愿池随机对话初始化完成")
    XLog.Debug(self._WishPondCaptionPool[1],self._WishPondCaptionPool[2],self._WishPondCaptionPool[3],self._WishPondCaptionPool[4],self._WishPondCaptionPool[5],self._WishPondCaptionPool[6])
end

--许愿池随机台词
function XLevel6001Present:OnWishingPondNpcInteractStart(eventType, eventArgs)
    if eventArgs.TargetPlaceId == self._WishPondPlaceID then
        --self._proxy:PlayDramaCaption(self._WishPondCaptionPool[self._proxy:Random(1, 6)]) --纯随机，会随到重复的

        if #self._WishPondPlayedCaptions >= #self._WishPondCaptionPool then --如果播完了，就播最后一句
            self._proxy:PlayDramaCaption(self._WishPondFinalCaption)
            XLog.Debug("许愿池-播放最后一句对话".."已播对话"..#self._WishPondPlayedCaptions.."总对话数"..#self._WishPondCaptionPool)
        else
            local dialog = self._WishPondCaptionPool[self._WishPondCurrentCaptionIndex]
            self._proxy:PlayDramaCaption(dialog)
            table.insert(self._WishPondPlayedCaptions, dialog)
            self._WishPondCurrentCaptionIndex = self._WishPondCurrentCaptionIndex + 1
            ---DS写的，按顺序播
            XLog.Debug("许愿池-播放已随机好的对话"..dialog)
        end

        ---暂时关闭交互
        self._proxy:SetActorInteractableComponentEnableByPlaceId(2,self._WishPondPlaceID,false)
    end
end

--重新开启交互

--endregion


--region （通用函数）查找table中是否包含某元素
function XLevel6001Present:IsInclude(value,tab)
    for k,v in  ipairs(tab)do
        if v == value then
            XLog.Debug("该表中包含对应元素")
            return true
        end
    end
    XLog.Debug("该表中不包含对应元素")
    return false
end
--endregion


return XLevel6001Present
