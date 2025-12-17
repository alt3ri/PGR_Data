---@class XUiRaceFightSettlement : XLuaUi 结算
---@field _Control XRaceControl
---@field _3DCamera XUiPanelRace3DCamera
local XUiRaceFightSettlement = XLuaUiManager.Register(XLuaUi, "UiRaceFightSettlement")

function XUiRaceFightSettlement:OnAwake()
    self.BtnNext.CallBack = handler(self, self.OnBtnNextClick)
    self.BtnNext.gameObject:SetActive(false)
    -- local tr = self.Transform:Find("SafeAreaContentPane/UiRaceTransition")
    -- if tr then
    --     tr.gameObject:SetActive(false)
    -- end
end

function XUiRaceFightSettlement:OnStart(roundId)
    self._ResultRoundId = roundId
    local roundCfg = self._Control:GetRaceRoundById(self._ResultRoundId)
    local etcd = self._Control:GetEtcdRoundConfig(self._ResultRoundId)
    local isPointsRace = etcd.TypeId == XEnumConst.Race.Format.PointsRace
    self.TxtTitle01.text = roundCfg.Name
    self.TxtTitle02.text = roundCfg.SubTitle
    self._IsShowChampion = roundCfg.EndShowType == XEnumConst.Race.RankTag.Champion
    self._Timelines = {}
    if isPointsRace then
        local data = self._Control:GetPointsRaceData(etcd.PointGroupId)
        self._RoleIds = data:GetRankRoleIds()
    else
        local data = self._Control:GetEliminatorData(self._ResultRoundId)
        self._RoleIds = data:GetRankRoleIds()
    end

    self.GridData.gameObject:SetActiveEx(false)
    local timerId = XScheduleManager.ScheduleOnce(function()
        if isPointsRace then
            self:ShowPointsRaceResult(etcd.PointGroupId)
        else
            self:ShowEliminatorResult()
        end
    end, 1000)
    self:_AddTimerId(timerId)

    -- 按键延迟点击
    local timerId2 = XScheduleManager.ScheduleOnce(function()
        self.BtnNext.gameObject:SetActive(true)
    end, 2000)
    self:_AddTimerId(timerId2)

    self._3DCamera = require("XUi/XUiRace/Panel/XUiPanelRace3DCamera").New(self.UiModelGo.transform, self, XEnumConst.Race.SceneType.Settlement)
    self._3DCamera:LookAt(self._RoleIds and self._RoleIds[1])
    self._3DCamera:PlaySettleEffect()

    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
    end)

    self:PlayPlatformUp()

    --关闭其他弹窗和预测界面
    XLuaUiManager.Remove("UiRaceCourse")
    XLuaUiManager.Remove("UiRaceMemberDetail")
    XLuaUiManager.Remove("UiRacePopupCommon")
    XLuaUiManager.Remove("UiRacePopupResultDetail")
    XLuaUiManager.Remove("UiRacePredict")
    XLuaUiManager.Remove("UiRaceProjectChose")
end

function XUiRaceFightSettlement:OnDestroy()
    for _, timeLine in pairs(self._Timelines) do
        timeLine:StopTimelineAnimation()
    end
end

function XUiRaceFightSettlement:ShowPointsRaceResult(pointGroupId)
    local data = self._Control:GetPointsRaceData(pointGroupId)
    local historyRoleIds = XTool.Clone(self._RoleIds)
    local roundIds = data:GetRounds()
    local curIndex = table.indexof(roundIds, self._ResultRoundId) --当前轮次
    self._NumberTweenInfos = {}

    if curIndex > 1 then
        --计算上一轮的排名
        table.sort(historyRoleIds, function(a, b)
            local aRank = data:GetOutRoleRank(a, curIndex - 1)
            local bRank = data:GetOutRoleRank(b, curIndex - 1)
            return aRank < bRank
        end)
    end

    --1、显示原先积分和增加的积分
    self._Count = #historyRoleIds
    self:RefreshCustomizedList(historyRoleIds, function(i, roleId, grid)
        local addPoint = data:GetSinglePoint(roleId, curIndex) --当前场次增加的积分
        local point --上一场积分
        if curIndex == 1 then
            point = 0
        else
            point = data:GetSinglePoint(roleId, curIndex - 1)
        end
        grid.TxtAdd1.gameObject:SetActiveEx(true)
        grid.TxtAdd2.gameObject:SetActiveEx(true)
        grid.TxtTotal1.gameObject:SetActiveEx(true)
        grid.TxtTotal2.gameObject:SetActiveEx(true)
        grid.TxtWinTime.gameObject:SetActiveEx(false)
        grid.TxtFailTime.gameObject:SetActiveEx(false)
        grid.TxtAdd1.text = string.format("+%s", addPoint)
        grid.TxtAdd2.text = string.format("+%s", addPoint)
        grid.TxtTotal1.text = point
        grid.TxtTotal2.text = point
        grid.Result.gameObject:SetActiveEx(false)
        grid.WinTxtName.gameObject:SetActiveEx(true)
        grid.FailTxtName.gameObject:SetActiveEx(false)
        grid.ImgWinBgResult01.gameObject:SetActiveEx(false)
        grid.ImgFailBgResult01.gameObject:SetActiveEx(false)
        grid.ImgFailBg01.gameObject:SetActiveEx(false)
        grid.ImgWinBg01.gameObject:SetActiveEx(true)
        table.insert(self._NumberTweenInfos, { addPoint, point, grid })

        --错帧动画
        local gridDataEnable = grid.Transform:FindTransform("GridDataEnable")
        table.insert(self._Timelines, gridDataEnable)
        grid.GameObject:SetActiveEx(false)
        local timerId = XScheduleManager.ScheduleOnce(function()
            grid.GameObject:SetActiveEx(true)
            if not XTool.UObjIsNil(gridDataEnable) then
                gridDataEnable:PlayTimelineAnimation(function()
                    if i == self._Count then
                        self:PlayPointsRaceNumberAnim(data, curIndex)
                    end
                end)
            end
        end, 50 * i)
        self:_AddTimerId(timerId)
    end)
end

---播放积分赛数字变化动画
function XUiRaceFightSettlement:PlayPointsRaceNumberAnim(data, curIndex)
    --延迟1s让玩家看清数值
    local timerId = XScheduleManager.ScheduleOnce(function()
        for i, info in ipairs(self._NumberTweenInfos) do
            local addPoint = info[1]
            local lastPoint = info[2]
            local grid = info[3]
            local numTimerId = XUiHelper.Tween(1, function(progress)
                -- 插值计算
                local currentA = math.floor(addPoint - addPoint * progress)
                local currentB = math.floor(lastPoint + addPoint * progress)
                -- 更新UI
                grid.TxtAdd1.text = string.format("+%s", currentA)
                grid.TxtAdd2.text = string.format("+%s", currentA)
                grid.TxtTotal1.text = currentB
                grid.TxtTotal2.text = currentB
            end, function()
                -- 动画结束时，确保数值是最终值
                grid.TxtAdd1.text = ""
                grid.TxtAdd2.text = ""
                grid.TxtTotal1.text = lastPoint + addPoint
                grid.TxtTotal2.text = lastPoint + addPoint
                if i == self._Count then
                    self:PlayRankChangeAnim(data, curIndex)
                end
            end)
            self:_AddTimerId(numTimerId)
        end
    end, 1000)
    self:_AddTimerId(timerId)
end

---再次播放错帧动画
---@param data XRacePointsRaceData
function XUiRaceFightSettlement:PlayRankChangeAnim(data, curIndex)
    --延迟1s让玩家看清数值
    local timerId = XScheduleManager.ScheduleOnce(function()
        self:RefreshCustomizedList(self._RoleIds, function(i, roleId, grid)
            local point = 0
            for i = 1, curIndex do
                point = point + data:GetSinglePoint(roleId, i)
            end
            grid.TxtTotal1.text = point
            grid.TxtTotal2.text = point
            -- 只有最后一轮才显示晋升和淘汰
            local isUp = data:IsRoleUp(roleId)
            local isDown = data:IsRoleDown(roleId)
            local isGroupEnd = data:IsGroupEnd()
            grid.Result.gameObject:SetActiveEx(true)
            grid.WinTxtName.gameObject:SetActiveEx(isUp or not isGroupEnd)
            grid.FailTxtName.gameObject:SetActiveEx(isDown)
            grid.Win.gameObject:SetActiveEx(isUp)
            grid.Fail.gameObject:SetActiveEx(isDown)
            grid.Champion.gameObject:SetActiveEx(false)
            grid.TxtAdd1.gameObject:SetActiveEx(false)
            grid.TxtAdd2.gameObject:SetActiveEx(false)
            grid.ImgWinBgResult01.gameObject:SetActiveEx(false)
            grid.ImgFailBgResult01.gameObject:SetActiveEx(false)
            grid.ImgFailBg01.gameObject:SetActiveEx(isDown)
            grid.ImgWinBg01.gameObject:SetActiveEx(isUp or not isGroupEnd)

            local gridDataEnable = grid.Transform:FindTransform("GridDataEnable")
            grid.GameObject:SetActiveEx(false)
            local timerId = XScheduleManager.ScheduleOnce(function()
                grid.GameObject:SetActiveEx(true)
                if not XTool.UObjIsNil(gridDataEnable) then
                    gridDataEnable:PlayTimelineAnimation()
                end
            end, 50 * i)
            self:_AddTimerId(timerId)
        end)
    end, 1000)
    self:_AddTimerId(timerId)
end

function XUiRaceFightSettlement:ShowEliminatorResult()
    local data = self._Control:GetEliminatorData(self._ResultRoundId)
    self:RefreshCustomizedList(self._RoleIds, function(i, roleId, grid)
        local timeStr = self._Control:GetPassTimeStr(data:GetRolePassTime(roleId))
        grid.TxtAdd1.gameObject:SetActiveEx(false)
        grid.TxtAdd2.gameObject:SetActiveEx(false)
        grid.TxtTotal1.gameObject:SetActiveEx(false)
        grid.TxtTotal2.gameObject:SetActiveEx(false)
        grid.TxtWinTime.gameObject:SetActiveEx(true)
        grid.TxtFailTime.gameObject:SetActiveEx(true)
        grid.TxtWinTime.text = timeStr
        grid.TxtFailTime.text = timeStr
        grid.Result.gameObject:SetActiveEx(true)
        grid.ImgFailBg01.gameObject:SetActiveEx(false)
        grid.ImgWinBg01.gameObject:SetActiveEx(false)
        if self._IsShowChampion then
            local isChampion = i == 1
            grid.Win.gameObject:SetActiveEx(false)
            grid.Fail.gameObject:SetActiveEx(false)
            grid.Champion.gameObject:SetActiveEx(isChampion)
            grid.WinTxtName.gameObject:SetActiveEx(isChampion)
            grid.FailTxtName.gameObject:SetActiveEx(not isChampion)
            grid.ImgWinBgResult01.gameObject:SetActiveEx(isChampion)
            grid.ImgFailBgResult01.gameObject:SetActiveEx(not isChampion)
        else
            local isUp = data:IsRoleUp(roleId)
            local isDown = data:IsRoleDown(roleId)
            grid.Win.gameObject:SetActiveEx(isUp)
            grid.Fail.gameObject:SetActiveEx(isDown)
            grid.WinTxtName.gameObject:SetActiveEx(isUp)
            grid.FailTxtName.gameObject:SetActiveEx(isDown)
            grid.Champion.gameObject:SetActiveEx(false)
            grid.ImgWinBgResult01.gameObject:SetActiveEx(isUp)
            grid.ImgFailBgResult01.gameObject:SetActiveEx(isDown)
        end

        local gridDataEnable = grid.Transform:FindTransform("GridDataEnable")
        grid.GameObject:SetActiveEx(false)
        local timerId = XScheduleManager.ScheduleOnce(function()
            grid.GameObject:SetActiveEx(true)
            if not XTool.UObjIsNil(gridDataEnable) then
                gridDataEnable:PlayTimelineAnimation()
            end
        end, 50 * i)
        self:_AddTimerId(timerId)
    end)
end

function XUiRaceFightSettlement:RefreshCustomizedList(roleIds, func)
    XUiHelper.RefreshCustomizedList(self.GridData.parent, self.GridData, #roleIds, function(i, go)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.ImgRank:SetSprite(self._Control:GetClientConfig("RankNumIcon", i))

        local roleId = roleIds[i]
        local roleCfg = self._Control:GetRaceCharacterById(roleId)
        uiObject.WinTxtName.text = roleCfg.Name
        uiObject.FailTxtName.text = roleCfg.Name
        uiObject.BtnHead:SetRawImage(roleCfg.Icon)
        uiObject.BtnHead.CallBack = function()
            XLuaUiManager.Open("UiRaceMemberDetail", roleId, uiObject.BtnHead.transform)
        end

        func(i, roleId, uiObject)
    end)
end

function XUiRaceFightSettlement:OnBtnNextClick()
    self._Control:RequestGuessSingleRoundResult(self._ResultRoundId, function()
        XLuaUiManager.Open("UiRaceFightPredictSettlement", self._ResultRoundId)
        XLuaUiManager.Remove("UiRaceFightSettlement")
    end)
end

function XUiRaceFightSettlement:PlayPlatformUp()
    local platform = self.UiSceneInfo.Transform:FindTransform("Racing_BanjiangtaiAni")
    if not XTool.UObjIsNil(platform) then
        ---@type UnityEngine.Animator
        local animator = platform:GetComponent("Animator")
        if not XTool.UObjIsNil(animator) then
            animator:Play("FloorUpLoop")
        end
    end
end

return XUiRaceFightSettlement