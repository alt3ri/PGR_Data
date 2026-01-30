local XUiFunctionShowControl = require('XUi/XUiCommon/XUiFunctionShow/XUiFunctionShowControl')
--- 主界面左侧右上角通用入口面板
---@class XUiPanelMainLeftTopActivityBtns: XUiFunctionShowControl
local XUiPanelMainLeftTopActivityBtns = XClass(XUiFunctionShowControl, 'XUiPanelMainLeftTopActivityBtns')


function XUiPanelMainLeftTopActivityBtns:OnStart(rootUi)
    self.RootUi = rootUi
    
    XUiFunctionShowControl.OnStart(self)

    self.GridActivityButtonDic = {}
    self.ActiveGridActivityButtonDic = {} -- 显示中的活动按钮
    self.ActiveGridActivityCount = 0 -- 显示中的活动按钮数量
    self.WaitForOpenGridActivityCount = 0
    self.WaitForGridActivityButtonDic = {}

    self.GridBtnActivity.gameObject:SetActiveEx(false)
end

function XUiPanelMainLeftTopActivityBtns:InitActivityBtns()
    -- 批量按钮处理
    local XUiGridActivityButton = require("XUi/XUiMain/XUiChildItem/XUiGridActivityButton")
    local dataSource = XMVCA.XUiMain:GetActivityBtnListByOrder()
    if XTool.IsTableEmpty(dataSource) then
        return
    end

    local uitheme = self.Parent.Transform:GetComponent("XUiTheme")
    XUiHelper.RefreshCustomizedList(self.PanelActivityBtn.transform, self.GridBtnActivity.transform, #dataSource, function (i, transform)
        ---@type XUiGridActivityButton
        local grid = self.GridActivityButtonDic[i]
        local config = dataSource[i]
        if not grid then
            grid = XUiGridActivityButton.New(transform, self, config, self.RootUi)
            self.GridActivityButtonDic[i] = grid
            grid:InitEvent(function ()
                if grid:CheckShow() then
                    self:AddActiveGridActivityButtonDic(grid)
                end
            end)
        end
        if grid:CheckShow() then
            self:AddActiveGridActivityButtonDic(grid)
        end

        --判断是否是待开发状态的按钮
        if XTool.IsNumberValid(config.TimeId) then
            local endTime = XFunctionManager.GetEndTimeByTimeId(config.TimeId)
            local now = XTime.GetServerNowTimestamp()

            if now < endTime then
                self.WaitForGridActivityButtonDic[grid] = true
                self.WaitForOpenGridActivityCount = self.WaitForOpenGridActivityCount + 1
            end
        end

        local targetItem = transform:Find("Red/Image1"):GetComponent("Image")
        local targetItem2 = transform:Find("Red/Image2"):GetComponent("Image")
        if not targetItem or not targetItem2 then
            return
        end
        uitheme:AddThemeColorsItem(targetItem, 0)
        uitheme:AddThemeColorsItem(targetItem2, 0)
    end)
end

--region Timer

function XUiPanelMainLeftTopActivityBtns:CheckActivityBtnTimerStart()
    if self.ActiveGridActivityCount <= 0 and self.WaitForOpenGridActivityCount <= 0 then
        self:StopActivityButtonsTimer()
    elseif (self.ActiveGridActivityCount > 0 or self.WaitForOpenGridActivityCount > 0) and not self.ActivityButtonDicTimer then
        self:StartActivityButtonsTimer()
    end
end


function XUiPanelMainLeftTopActivityBtns:StartActivityButtonsTimer()
    self.ActivityButtonDicTimer = XScheduleManager.ScheduleForever(function()
        -- wait列表判断开启
        for grid, v in pairs(self.WaitForGridActivityButtonDic) do
            if grid:CheckShow() then
                self:AddActiveGridActivityButtonDic(grid)
            end
        end

        -- 激活列表判断关闭
        for grid, v in pairs(self.ActiveGridActivityButtonDic) do
            grid:RefreshByTimeUpdate()
            if not grid:CheckShow() then
                self:RemoveActiveGridActivityButtonDic(grid)
            end
        end

    end, XScheduleManager.SECOND, 0)
end

function XUiPanelMainLeftTopActivityBtns:StopActivityButtonsTimer()
    if self.ActivityButtonDicTimer then
        XScheduleManager.UnSchedule(self.ActivityButtonDicTimer)
        self.ActivityButtonDicTimer = nil
    end
end

--endregion

function XUiPanelMainLeftTopActivityBtns:AddActiveGridActivityButtonDic(grid)
    if self.ActiveGridActivityButtonDic[grid] then
        return
    end

    self.ActiveGridActivityButtonDic[grid] = true
    self.ActiveGridActivityCount = self.ActiveGridActivityCount + 1
    self:RemoveWaitForGridActivityButtonDic(grid) --每次激活的时候一定要把wait队列的保底剔除
    self:CheckActivityBtnTimerStart()
end

function XUiPanelMainLeftTopActivityBtns:RemoveActiveGridActivityButtonDic(grid)
    if not self.ActiveGridActivityButtonDic[grid] then
        return
    end

    self.ActiveGridActivityButtonDic[grid] = nil
    self.ActiveGridActivityCount = self.ActiveGridActivityCount - 1
    self:CheckActivityBtnTimerStart()
end

function XUiPanelMainLeftTopActivityBtns:RemoveWaitForGridActivityButtonDic(grid)
    if not self.WaitForGridActivityButtonDic[grid] then
        return
    end

    self.WaitForGridActivityButtonDic[grid] = nil
    self.WaitForOpenGridActivityCount = self.WaitForOpenGridActivityCount - 1
    self:CheckActivityBtnTimerStart()
end

return XUiPanelMainLeftTopActivityBtns