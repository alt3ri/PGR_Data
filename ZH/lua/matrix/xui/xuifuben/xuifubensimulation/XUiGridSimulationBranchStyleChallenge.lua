local XUiGridFubenChapter = require('XUi/XUiFuben/UiDynamicList/XUiGridFubenChapter')
---@class XUiGridSimulationBranchStyleChallenge
---@field GameObject UnityEngine.GameObject
local XUiGridSimulationBranchStyleChallenge = XClass(XUiGridFubenChapter, 'XUiGridSimulationBranchStyleChallenge')

function XUiGridSimulationBranchStyleChallenge:Ctor(ui, clickFunc, openCb)
    XUiHelper.InitUiClass(self, ui)
    self.ClickFunc = clickFunc
    self.Manager = nil
    XUiHelper.RegisterClickEvent(self, self.BtnSelf, self.OnBtnSelfClicked)
    self:SetOpenCallback(openCb)

    --- 层级太深了，暂时不好按XUiNode改造，先利用Mono的生命周期
    ---@type XLuaBehaviour
    self._BehaviorImp = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    self._BehaviorImp.LuaOnEnable = handler(self, self.OnEnable)
    self._BehaviorImp.LuaOnDisable = handler(self, self.OnDisable)
end

function XUiGridSimulationBranchStyleChallenge:OnEnable()
    -- 刷新蓝点
    if self._NeedRefreshShow then
        self:RefreshRedPoint()
        self._NeedRefreshShow = false
    end
end

function XUiGridSimulationBranchStyleChallenge:OnDisable()
    self._NeedRefreshShow = true
end

---@param manager XFubenBaseAgency
function XUiGridSimulationBranchStyleChallenge:SetData(index, manager)
    self._NeedRefreshShow = false
    
    XUiGridFubenChapter.SetData(self, index)

    self.Manager = manager
    
    self.PanelTag.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)

    -- 背景图
    self.RImgBigIcon:SetRawImage(self.Manager:ExGetIcon())
    -- 名字
    self.TxtName.text = self.Manager:ExGetName()
    self.TxtName2.text = self.TxtName.text
    
    -- 锁
    local isLocked = self.Manager:ExGetIsLocked()
    self.PanelChapterLock.gameObject:SetActiveEx(isLocked)
    self.RImgLockMask.gameObject:SetActiveEx(isLocked)

    self.TxtLock1.text = XUiHelper.GetText("CommonLockedTip") --2是放大的，1是缩小的
    self.TxtLock2.text = self.Manager:ExGetLockTip()

    -- 隐藏进度条
    self.ImgProgress.gameObject:SetActiveEx(false)
    self.BgProgress.gameObject:SetActiveEx(false)

    if manager.ExGetProgressTip then
        local text = manager:ExGetProgressTip()
        if text then
            self.TxtPercentNormal.gameObject:SetActiveEx(true)
            self.TxtPercentNormal.text = text
        else
            self.TxtPercentNormal.gameObject:SetActiveEx(false)
        end
    else
        self.TxtPercentNormal.gameObject:SetActiveEx(false)
    end
    
    -- 普通模式(之后不再需要普通模式标签)
    self.PanelNormal.gameObject:SetActiveEx(false)
    local chapterType = self.Manager:ExGetChapterType()
    self.ImgKuai.gameObject:SetActiveEx(chapterType == XEnumConst.FuBen.ChapterType.Prequel)

    -- 限时开放页签
    if self.Manager:ExCheckHasTimeLimitTag() then
        self.PanelTag.gameObject:SetActiveEx(true)
        self.TagImage.color = XUiHelper.Hexcolor2Color(XEnumConst.MAINLINE2.MAIN_TAG_COLOR.LIMIT_TIME)
        self.TagText.text = XUiHelper.GetText("MainLineChapterTimeLimitTag")
    end
    
    -- 限时时间显示
    self:_HideTimeShow()
    if self.Manager.ExCheckInTimerShow and self.Manager:ExCheckInTimerShow() then
        self:StartTimer()
    end

    -- 红点处理
    self:RefreshRedPoint()
end

function XUiGridSimulationBranchStyleChallenge:OnBtnSelfClicked()
    if not XMVCA.XSubPackage:CheckSubpackage(self.Manager:ExGetFunctionNameType()) then
        return
    end
    if self.ClickFunc then
        self.ClickFunc(self.Index, self.Manager)
    end
end

function XUiGridSimulationBranchStyleChallenge:RefreshRedPoint()
    self.ImgRedDot.gameObject:SetActiveEx(self.Manager:ExCheckIsShowRedPoint())
end

--region 时间定时器相关

function XUiGridSimulationBranchStyleChallenge:_HideTimeShow()
    if self.ImgTime and not XTool.UObjIsNil(self.ImgTime) then
        self.ImgTime.gameObject:SetActiveEx(false)
    end
end

function XUiGridSimulationBranchStyleChallenge:StopTimer()
    if self._TimeShowTimer then
        XScheduleManager.UnSchedule(self._TimeShowTimer)
        self._TimeShowTimer = nil

        self:_HideTimeShow()
    end
end

function XUiGridSimulationBranchStyleChallenge:StartTimer()
    self:StopTimer()

    if self.ImgTime then
        self.ImgTime.gameObject:SetActiveEx(true)
    end
    
    self:UpdateTimer(nil, true)
    self._TimeShowTimer = XScheduleManager.ScheduleForever(handler(self, self.UpdateTimer), XScheduleManager.SECOND)
end

function XUiGridSimulationBranchStyleChallenge:UpdateTimer(timeId, forceUpdate)
    --todo UI嵌套层级太深了，并且没有XUiNode生命周期控制支持，目前直接判断节点是否销毁来关闭定时器
    if XTool.UObjIsNil(self.GameObject) then
        self:StopTimer()
        return
    elseif not self.GameObject.activeInHierarchy and not forceUpdate then
        -- 暂时不方便动态控制定时器的开始关闭，先针对节点隐藏做跳过处理
        return
    end
    local showTimeStr = self.Manager.ExGetTimerShowStr and self.Manager:ExGetTimerShowStr() or nil
    if self.TxtTime then
        if string.IsNilOrEmpty(showTimeStr) then
            self.TxtTime.gameObject:SetActiveEx(false)
        else
            self.TxtTime.gameObject:SetActiveEx(true)
            self.TxtTime.text = showTimeStr
        end
    end

    if self.ImgTimeIcon then
        local icon = self.Manager.ExGetTimerShowIcon and self.Manager:ExGetTimerShowIcon() or nil

        if icon then
            self.ImgTimeIcon.gameObject:SetActiveEx(true)
            self.ImgTimeIcon:SetImage(icon)
        else
            self.ImgTimeIcon.gameObject:SetActiveEx(false)
        end
    end

    if self.Manager.ExCheckInTimerShow and not self.Manager:ExCheckInTimerShow() then
        self:StopTimer()
    end
end

--endregion

return XUiGridSimulationBranchStyleChallenge