local XUiLottoFashionSelfChoiceEntrance = XLuaUiManager.Register(XLuaUi, "UiLottoFashionSelfChoiceEntrance")

function XUiLottoFashionSelfChoiceEntrance:OnStart(isChangeMode)
    -- isChangeMode=true：从卡池界面 BtnChange 跳回，跳过 OnEnable 的"已选过自动关闭"
    self.IsChangeMode = isChangeMode and true or false
    -- OnAwake 时 IsChangeMode 还没传入，默认 index 在这里二次计算
    if not XTool.IsTableEmpty(self.LottoPrimaryCfg) then
        self.CurSelectGridIndex = self:GetDefaultSelectIndex()
    end
    -- 监听常驻整个生命周期（而非 OnEnable/OnDisable）：切换入口跳回时本界面处于 disable 态，
    -- 若监听随 OnDisable 移除，DispatchEvent 会落空，导致 IsChangeMode 翻不起来被 OnEnable 直接关闭
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_SELF_CHOICE_ENTER_CHANGE_MODE, self.EnterChangeMode, self)
end

function XUiLottoFashionSelfChoiceEntrance:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_SELF_CHOICE_ENTER_CHANGE_MODE, self.EnterChangeMode, self)
end

-- 走唤醒路径时 OnStart 不会再跑，需外部显式调用以翻起 IsChangeMode + 刷新默认选中
function XUiLottoFashionSelfChoiceEntrance:EnterChangeMode()
    if XTool.IsTableEmpty(self.LottoPrimaryCfg) then return end
    self.IsChangeMode = true
    self.CurSelectLottoId = nil
    self.CurSelectGrid = nil
    self.CurSelectGridIndex = self:GetDefaultSelectIndex()
    self:RefreshDynamicTable()
end

function XUiLottoFashionSelfChoiceEntrance:OnAwake()
    self.LottoPrimaryId = XDataCenter.LottoManager.GetCurSelfChoiceLottoPrimaryId()
    self.LottoPrimaryCfg = XLottoConfigs.GetLottoPrimaryCfgById(self.LottoPrimaryId)
    if not XTool.IsNumberValid(self.LottoPrimaryId) or XTool.IsTableEmpty(self.LottoPrimaryCfg) then
        return
    end
    self.CurSelectGridIndex = 1
    self.CurSelectGrid = nil
    self.GridRewardDic = {}
    self:InitButton()
    self:InitDynamicTable()
    self:InitTimes()
end

-- 切换模式下定位玩家上次选择，否则回到首项
function XUiLottoFashionSelfChoiceEntrance:GetDefaultSelectIndex()
    if not self.IsChangeMode then return 1 end
    local targetLottoId = XDataCenter.LottoManager.GetCurSelectedLottoIdByPrimartLottoId(self.LottoPrimaryId)
    if not XTool.IsNumberValid(targetLottoId) then
        return 1
    end
    for i, lottoId in ipairs(self.LottoPrimaryCfg.LottoIdList) do
        if lottoId == targetLottoId then
            return i
        end
    end
    return 1
end

function XUiLottoFashionSelfChoiceEntrance:InitButton()
    self.BtnHelp:AddEventListener(handler(self, self.OnBtnHelpClick))
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainUiClick))
    self.BtnChoose:AddEventListener(handler(self, self.OnBtnChooseClick))
    self.BtnAudio:AddEventListener(handler(self, self.OnBtnAudioClick))
    self.AssetPanel = XUiHelper.XUiPanelAsset(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa)
end

function XUiLottoFashionSelfChoiceEntrance:OnBtnHelpClick()
    XLuaUiManager.Open("UiLottoFashionSelfChoiceDescribe", self.LottoPrimaryId)
end

function XUiLottoFashionSelfChoiceEntrance:OnBtnBackClick()
    self:Close()
end

function XUiLottoFashionSelfChoiceEntrance:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiLottoFashionSelfChoiceEntrance:OnBtnAudioClick()
    XLuaUiManager.Open("UiSet")
end

function XUiLottoFashionSelfChoiceEntrance:InitDynamicTable()
    local grid = require("XUi/XUiLottoFashionSelfChoice/Grid/XUiDTGridLottoSelect")
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.LottoList, grid, function (index, lottoId, gridProxy)
        self:OnGridSelect(index, lottoId, gridProxy)
    end)
end

function XUiLottoFashionSelfChoiceEntrance:InitTimes()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.LottoPrimaryCfg.TimeId) or 0
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

function XUiLottoFashionSelfChoiceEntrance:RefreshTitleByTimeId()
    local timeSecond =  self.EndTime - XTime.GetServerNowTimestamp()
    self.TxtLeftTime.text = XUiHelper.GetTime(timeSecond, XUiHelper.TimeFormatType.CHATEMOJITIMER)
end

function XUiLottoFashionSelfChoiceEntrance:OnEnable()
    -- 切换模式：从已打开的卡池界面跳回来，跳过"已选过自动关闭"逻辑
    if not self.IsChangeMode then
        local curSelectLottoId = XDataCenter.LottoManager.GetCurSelectedLottoIdByPrimartLottoId(self.LottoPrimaryId)
        if XTool.IsNumberValid(curSelectLottoId) then
            self:CloseImmediately()
            return
        end
    end

    self:RefreshDynamicTable()
    XSaveTool.SaveData("OpenUiLottoFashionSelfChoiceEntrance", {NextCanShowTimeStamp = XTime.GetSeverTomorrowFreshTime()})
end

function XUiLottoFashionSelfChoiceEntrance:RefreshDynamicTable()
    local dataList = self.LottoPrimaryCfg.LottoIdList
    self.DynamicTable:SetDataSource(dataList)
    self.DynamicTable:ReloadDataSync()
end

---@param event any
---@param index any
---@param grid XUiDTGridLottoSelect
function XUiLottoFashionSelfChoiceEntrance:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local lottoId = self.DynamicTable.DataSource[index]
        grid:Refresh(lottoId, index, self.LottoPrimaryId)
        if self.CurSelectGridIndex == index then
            if self.CurSelectGrid then
                self.CurSelectGrid:SetUnSelect()
            end
            self.CurSelectGrid = grid
            self.CurSelectGridIndex = index

            grid:SetSelect()
            self:OnGridSelect(index, lottoId, grid)
        else
            grid:SetUnSelect()
        end
    -- 点击由Btn的回调去处理
    end
end

function XUiLottoFashionSelfChoiceEntrance:OnGridSelect(index, lottoId, grid)
    if self.CurSelectLottoId == lottoId then
        self.CurSelectGrid:SetSelect()
        return
    end
    self.CurSelectLottoId = lottoId

    -- 格子被选中后的切换逻辑
    self:PlayAnimation("QieHuan")

    -- 同步其他ui显示的信息的逻辑
    ---@type XTableLottoFashionSelfChoiceResources
    local lottoResConfig = XLottoConfigs.GetAllConfigs(XLottoConfigs.TableKey.LottoFashionSelfChoiceResources)[lottoId]
    self.VideoPlayer:SetInfoByVideoId(lottoResConfig.VideoConfigId)
    self.VideoPlayer:RePlay()

    local fashionId = lottoResConfig.SpecialRewardTemplateIds[1] -- 第1个默认是涂装id(写死)
    local fashionConfig = XFashionConfigs.GetFashionTemplate(fashionId)
    local characterId = fashionConfig.CharacterId
    self.TxtCharacterName.text = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
    self.TxtFashionName.text = fashionConfig.Name

    -- 奖励
    local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
    for k, templateId in ipairs(lottoResConfig.SpecialRewardTemplateIds) do
        local grid = self.GridRewardDic[k]
        if not grid then
            local ui = (k == 1) and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.Grid256New.parent)
            grid = XUiGridCommon.New(self, ui)
            self.GridRewardDic[k] = grid
        end

        grid:Refresh({ TemplateId = templateId })
    end
end

function XUiLottoFashionSelfChoiceEntrance:OnBtnChooseClick()
    ---@type XTableLottoFashionSelfChoiceResources
    local lottoResConfig = XLottoConfigs.GetAllConfigs(XLottoConfigs.TableKey.LottoFashionSelfChoiceResources)[self.CurSelectLottoId]
    local isAllRewardGet = self.CurSelectGrid and self.CurSelectGrid.IsAllRewardGet or false

    local doConfirm = function()
        XDataCenter.LottoManager.LottoSelfChoiceSelectRequest(self.LottoPrimaryId, self.CurSelectLottoId, function ()
            XFunctionManager.SkipInterface(lottoResConfig.SkipId)
        end)
    end

    -- 已全收奖励时弹确认 Dialog，避免误切换；否则直跳卡池
    if isAllRewardGet then
        XLuaUiManager.Open("UiLottoFashionSelfChoiceDialog", self.CurSelectLottoId, isAllRewardGet, doConfirm, self.IsChangeMode)
    else
        doConfirm()
    end
end