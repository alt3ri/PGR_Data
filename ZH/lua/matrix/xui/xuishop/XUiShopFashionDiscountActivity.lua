local XUiShopFashionDiscountActivity = XClass(nil, "XUiShopFashionDiscountActivity")

function XUiShopFashionDiscountActivity:Ctor(base)
    self.Parent = base
end

function XUiShopFashionDiscountActivity:OnDestroy()
    if self._DiscountActivityTimeId then
        XScheduleManager.UnSchedule(self._DiscountActivityTimeId)
        self._DiscountActivityTimeId = nil
    end
    if self._DiscountActivityTagTimeId then
        XScheduleManager.UnSchedule(self._DiscountActivityTagTimeId)
        self._DiscountActivityTagTimeId = nil
    end
end

--region v4.3 商店折扣活动时间重置
function XUiShopFashionDiscountActivity:ResetDiscountActivityTime(shopId)
    if self._DiscountActivityTimeId then
        XScheduleManager.UnSchedule(self._DiscountActivityTimeId)
        self._DiscountActivityTimeId = nil
    end
    local activityStartTime = XShopManager.GetShopActivityStartTime(shopId)
    local activityEndTime = XShopManager.GetShopActivityEndTime(shopId)
    local now = XTime.GetServerNowTimestamp()
    if activityEndTime >= now then
        self:RefreshTimeStrFunc(shopId)
        self._DiscountActivityTimeId = XScheduleManager.ScheduleForever(function()
            self:RefreshTimeStrFunc(shopId)
        end, 1000)
    else
        self.Parent.TxtPanelFashionTime.gameObject:SetActiveEx(false)
    end
end

function XUiShopFashionDiscountActivity:RefreshTimeStrFunc(shopId)
    local nowTime = XTime.GetServerNowTimestamp()
    local activityEndTime = XShopManager.GetShopActivityEndTime(shopId)
    local activityOpen = XShopManager.GetShopActivityIsOpen(shopId)
    -- 更新倒计时文本显示
    self.Parent.TxtPanelFashionTime.gameObject:SetActiveEx(activityOpen)
    if activityOpen and activityEndTime and activityEndTime > 0 then
        local gameTime = activityEndTime - nowTime
        if gameTime > 0 then
            local leftTimeStr = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
            self.Parent.TxtPanelFashionTime.text = XUiHelper.GetText("DiscountActivityTip", leftTimeStr)
        else
            self.Parent.TxtPanelFashionTime.gameObject:SetActiveEx(false)
        end
    end
end

function XUiShopFashionDiscountActivity:ResetDiscountActivityTag()
    if self._DiscountActivityTagTimeId then
        XScheduleManager.UnSchedule(self._DiscountActivityTagTimeId)
        self._DiscountActivityTagTimeId = nil
    end
    self:RefreshTag()
    self._DiscountActivityTagTimeId = XScheduleManager.ScheduleForever(handler(self, self.RefreshTag), 1000)
end

function XUiShopFashionDiscountActivity:RefreshTag()
    for key, info in pairs(self.Parent.TagBtnShopGroup) do
        if XShopManager.GetShopActivityIsOpen(info.Id) then
            self:GroupBtnShowActivityTag(info.Id)
        end
        if info.ActivityStartTime ~= -1 and info.ActivityEndTime ~= -1 and not XShopManager.GetShopActivityIsOpen(info.Id) then
            self:GroupBtnHideActivityTag(info.Id)
        end
    end
end

function XUiShopFashionDiscountActivity:GroupBtnShowActivityTag(shopId)
    if not shopId then
        return
    end
    
    local parentBtn = nil
    local targetBtn = nil
    for i = 1, #self.Parent.BtnGoList do
        local btnUi = self.Parent.BtnGoList[i]
        if not btnUi then
            goto continue
        end
        
        local info = self.Parent.TagBtnShopGroup[btnUi]
        if not info then
            goto continue
        end

        if info.Id == 0 then
            parentBtn = btnUi
        elseif info.Id == shopId then
            targetBtn = btnUi
            break
        end
        ::continue::
    end
    
    if not targetBtn then
        return
    end
    
    if parentBtn then
        parentBtn:ShowTag(true)
        parentBtn:SetNameByGroup(1, XUiHelper.GetText("FashionActivitySecondTag"))
    end
    targetBtn:ShowTag(true)
    targetBtn:SetNameByGroup(1, XUiHelper.GetText("FashionActivityFirstTag"))
end

function XUiShopFashionDiscountActivity:GroupBtnHideActivityTag(shopId)
    if not shopId then
        return
    end
    
    local parentBtn = nil
    local targetBtn = nil
    for i = 1, #self.Parent.BtnGoList do
        local btnUi = self.Parent.BtnGoList[i]
        if not btnUi then
            goto continue
        end
        
        local info = self.Parent.TagBtnShopGroup[btnUi]
        if not info then
            goto continue
        end

        if info.Id == 0 then
            parentBtn = btnUi
        elseif info.Id == shopId then
            targetBtn = btnUi
            break
        end
        ::continue::
    end
    
    if not targetBtn then
        return
    end
    
    if parentBtn then
        parentBtn:ShowTag(false)
    end
    targetBtn:ShowTag(false)
end

--endregion
return XUiShopFashionDiscountActivity
