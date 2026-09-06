local XUiGachaFashionSelfChoiceEntrance = XLuaUiManager.Register(XLuaUi, "UiGachaFashionSelfChoiceEntrance")

function XUiGachaFashionSelfChoiceEntrance:OnAwake()
    self.CurSelectGridIndex = 1
    self.LastClickTime = 0 -- 添加：上次点击时间戳
    self.SelectCDMs = CS.XGame.ClientConfig:GetInt("XUiGachaFashionSelectGridCD")
    self.CurSelectGrid = nil
    self.GridRewardDic = {}
    self:InitButton()
    self:InitDynamicTable()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnBeginBattleAutoRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnBeginBattleAutoRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_BEGIN, self.OnBeginBattleAutoRemove, self)
end

function XUiGachaFashionSelfChoiceEntrance:OnStart(groupId, isChangeMode)
    self.GroupId = groupId
    -- isChangeMode=true：从卡池界面 BtnChange 跳回，跳过 OnEnable 的"已选过自动关闭"
    self.IsChangeMode = isChangeMode and true or false
    self.ActivityId = XDataCenter.GachaManager.GetCurGachaFashionSelfChoiceActivityId()
    self.GroupConfig = XDataCenter.GachaManager.GetGroupConfig(groupId)
    if not self.GroupConfig then
        XLog.Error("XUiGachaFashionSelfChoiceEntrance: invalid GroupId: " .. tostring(groupId))
        self:Close()
        return
    end
    self:InitTimes()
    self.CurSelectGridIndex = self:GetDefaultSelectIndex()
    -- 监听常驻整个生命周期（而非 OnEnable/OnDisable）：切换入口跳回时本界面处于 disable 态，
    -- 若监听随 OnDisable 移除，DispatchEvent 会落空，导致 IsChangeMode 翻不起来被 OnEnable 直接关闭
    XEventManager.AddEventListener(XEventId.EVENT_GACHA_SELF_CHOICE_ENTER_CHANGE_MODE, self.EnterChangeMode, self)
end

-- 切换模式下定位玩家上次选择，否则回到首项
function XUiGachaFashionSelfChoiceEntrance:GetDefaultSelectIndex()
    if not self.IsChangeMode then return 1 end
    local targetGachaId = XDataCenter.GachaManager.GetCurSelfChoiceSelectGachId(self.GroupId)
    if not XTool.IsNumberValid(targetGachaId) then
        return 1
    end
    for i, gachaId in ipairs(self.GroupConfig.GachaIds) do
        if gachaId == targetGachaId then
            return i
        end
    end
    return 1
end

-- 走唤醒路径时 OnStart 不会再跑，需外部显式调用以翻起 IsChangeMode + 刷新选中态
function XUiGachaFashionSelfChoiceEntrance:EnterChangeMode()
    if not self.GroupConfig then return end
    self.IsChangeMode = true
    self.CurSelectGachaId = nil
    self.CurSelectGrid = nil
    self.CurSelectGridIndex = self:GetDefaultSelectIndex()
    self:RefreshDynamicTable()
end

function XUiGachaFashionSelfChoiceEntrance:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_GACHA_SELF_CHOICE_ENTER_CHANGE_MODE, self.EnterChangeMode, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.OnBeginBattleAutoRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.OnBeginBattleAutoRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MOVIE_BEGIN, self.OnBeginBattleAutoRemove, self)
end

function XUiGachaFashionSelfChoiceEntrance:OnBeginBattleAutoRemove()
    self:Remove()
end

function XUiGachaFashionSelfChoiceEntrance:InitButton()
    self.BtnHelp:AddEventListener(handler(self, self.OnBtnHelpClick))
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainUiClick))
    self.BtnChoose:AddEventListener(handler(self, self.OnBtnChooseClick))
    self.BtnAudio:AddEventListener(handler(self, self.OnBtnAudioClick))
    self.AssetPanel = XUiHelper.XUiPanelAsset(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa)
end

function XUiGachaFashionSelfChoiceEntrance:OnBtnHelpClick()
    XLuaUiManager.Open("UiGachaFashionSelfChoiceDescribe", self.GroupId)
end

function XUiGachaFashionSelfChoiceEntrance:OnBtnBackClick()
    self:Close()
end

function XUiGachaFashionSelfChoiceEntrance:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGachaFashionSelfChoiceEntrance:OnBtnAudioClick()
    XLuaUiManager.Open("UiSet")
end

function XUiGachaFashionSelfChoiceEntrance:InitDynamicTable()
    local grid = require("XUi/XUiGachaFashionSelfChoice/Grid/XUiDTGridGachaSelect")
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.GachaList, grid, function (index, gachaId, gridProxy)
        self:OnGridGachaSelect(index, gachaId, gridProxy)
    end)
end

function XUiGachaFashionSelfChoiceEntrance:InitTimes()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.GroupConfig.TimeId) or 0
    self.EndTime = endTime
    self:RefreshTitleByTimeId() -- 计时器启动比较慢 先提前刷新一次
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        else
            self:RefreshTitleByTimeId()
        end
    end)
end

function XUiGachaFashionSelfChoiceEntrance:RefreshTitleByTimeId()
    local timeSecond =  self.EndTime - XTime.GetServerNowTimestamp()
    self.TxtLeftTime.text = XUiHelper.GetTime(timeSecond, XUiHelper.TimeFormatType.CHATEMOJITIMER)
end

function XUiGachaFashionSelfChoiceEntrance:OnEnable()
    -- 切换模式：从已打开的卡池界面跳回来，跳过"已选过自动关闭"逻辑
    if not self.IsChangeMode then
        local curSelectGachaId = XDataCenter.GachaManager.GetCurSelfChoiceSelectGachId(self.GroupId)
        if XTool.IsNumberValid(curSelectGachaId) then
            self:Close()
            return
        end
    end

    -- 进入枢纽即停掉上一个卡池残留的 BGM，避免在下一个卡池 BGM 起来前的间隙里漏出。
    -- 副作用：StopMusic 只是停止、等 LateUpdate 回收，若在回收前快速返回同一个卡池、且新 BGM 用相同 cueId，
    -- 会复用这个待回收实例后被同帧误回收，导致该卡池 BGM 丢失。
    -- 兜底：若某个卡池出现 BGM 丢失，给它负责播放 BGM 的 XPlayMusic 组件配一个较小的 Delay，
    -- 把新 BGM 的启动时机推迟到旧实例回收之后即可绕开；各卡池预制结构不同，生效的 XPlayMusic 组件位置需在对应卡池里排查。
    XLuaAudioManager.StopCurrentBGM()

    self:RefreshDynamicTable()
    local saveKey = "OpenUiGachaFashionSelfChoiceEntrance_" .. tostring(self.GroupId)
    XSaveTool.SaveData(saveKey, {NextCanShowTimeStamp = XTime.GetSeverTomorrowFreshTime()})
end

function XUiGachaFashionSelfChoiceEntrance:RefreshDynamicTable()
    local dataList = self.GroupConfig.GachaIds
    self.DynamicTable:SetDataSource(dataList)
    self.DynamicTable:ReloadDataSync()
end

---@param event any
---@param index any
---@param grid XUiDTGridGachaSelect
function XUiGachaFashionSelfChoiceEntrance:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local gachaId = self.DynamicTable.DataSource[index]
        grid:Refresh(gachaId, index, self.GroupId)
        if self.CurSelectGridIndex == index then
            if self.CurSelectGrid then
                self.CurSelectGrid:SetUnSelect()
            end
            self.CurSelectGrid = grid
            self.CurSelectGridIndex = index
            -- 默认/切换态的程序化选中：直接完整刷新并回填 CurSelectGachaId（对齐 lotto），
            -- 传 ignoreCD 绕过防连点，否则切换态快速跳回时会被 CD 早退跳过回填，导致 BtnChoose 拿到 nil 崩溃
            self:OnGridGachaSelect(index, gachaId, grid, true)
            grid:SetSelect()
        else
            grid:SetUnSelect()
        end
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    -- 点击由Btn的回调去处理
    end
end

function XUiGachaFashionSelfChoiceEntrance:OnGridGachaSelect(index, gachaId, grid, ignoreCD)
    -- ignoreCD：程序化默认选中不是玩家连点，不受防连点限制
    if not ignoreCD then
        local now = XTime.GetServerNowTimestamp()
        if now - self.LastClickTime < (self.SelectCDMs / 1000) then
            -- 冷却中，忽略点击
            return
        end
        self.LastClickTime = now -- 更新点击时间
    end

    if self.CurSelectGachaId == gachaId then
        self.CurSelectGrid:SetSelect()
        return
    end

    -- 格子被选中后的切换逻辑
    self:PlayAnimation("QieHuan")
    grid:SetSelect()
    if self.CurSelectGrid then
        self.CurSelectGrid:SetUnSelect()
    end
    self.CurSelectGrid = grid
    self.CurSelectGridIndex = index
    self.CurSelectGachaId = gachaId

    -- 同步其他ui显示的信息的逻辑
    ---@type XTableGachaFashionSelfChoiceResources
    local gachaConfig = XGachaConfigs.GetAllConfigs(XGachaConfigs.TableKey.GachaFashionSelfChoiceResources)[gachaId]
    self.VideoPlayer:SetInfoByVideoId(gachaConfig.VideoConfigId)
    self.VideoPlayer:RePlay()

    local fashionId = gachaConfig.SpecialRewardTemplateIds[1] -- 第1个默认是涂装id(写死)
    local fashionConfig = XFashionConfigs.GetFashionTemplate(fashionId)
    local backgroundId = gachaConfig.SpecialRewardTemplateIds[2] -- 第2个默认是场景id(写死)
    local backgroundName = XPhotographConfigs.GetBackgroundNameById(backgroundId)
    local characterId = fashionConfig.CharacterId
    self.TxtCharacterName.text = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
    self.TxtFashionName.text = fashionConfig.Name
    self.TxtSceneName.text = backgroundName

    -- 奖励
    local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
    for k, templateId in ipairs(gachaConfig.SpecialRewardTemplateIds) do
        local grid = self.GridRewardDic[k]
        if not grid then
            local ui = (k == 1) and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.Grid256New.parent)
            grid = XUiGridCommon.New(self, ui)
            self.GridRewardDic[k] = grid
        end

        grid:Refresh({ TemplateId = templateId })
    end
end

function XUiGachaFashionSelfChoiceEntrance:OnBtnChooseClick()
    ---@type XTableGachaFashionSelfChoiceResources
    local gachaConfig = XGachaConfigs.GetAllConfigs(XGachaConfigs.TableKey.GachaFashionSelfChoiceResources)[self.CurSelectGachaId]
    local isAllRewardGet = self.CurSelectGrid and self.CurSelectGrid.IsAllRewardGet or false

    local doConfirm = function()
        XDataCenter.GachaManager.ChoiceGachaRequest(self.CurSelectGachaId, function ()
            XFunctionManager.SkipInterface(gachaConfig.SkipId)
        end)
    end

    -- 已全收奖励时弹确认 Dialog，避免误切换；否则直跳卡池
    if isAllRewardGet then
        XLuaUiManager.Open("UiGachaFashionSelfChoiceDialog", self.CurSelectGachaId, isAllRewardGet, doConfirm, self.IsChangeMode)
    else
        doConfirm()
    end
end