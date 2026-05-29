local SceneIds = require("XModule/XScene/XScene/XLuaSceneDefine").SceneIds

---@class XUiTheatre6ChooseCharacter : XLuaUi 选人界面
---@field _Control XTheatre6Control
---@field _BuffDetail XUiPanelTheatre6BuffDetail
---@field _TagBuffGrids XUiGridTheatre6Buff[]
local XUiTheatre6ChooseCharacter = XLuaUiManager.Register(XLuaUi, "UiTheatre6ChooseCharacter")

local Story = XEnumConst.Theatre6.PlayMode.Story
local GamePlay = XEnumConst.Theatre6.PlayMode.GamePlay

local FuncName = {
    Init = 1,
    UpdateDetail = 2,
    UpdateBattle = 3,
    GetFashionId = 4,
}

function XUiTheatre6ChooseCharacter:OnAwake()
    self:InitData()
    self:InitHandler()
    self:InitComponents()
    self:Init3DPanel()
    self.BtnTalent:AddEventListener(handler(self, self.OnBtnTalentClick))
    self.BtnStoryReview:AddEventListener(handler(self, self.OnBtnStoryReviewClick))
    self.BtnFile:AddEventListener(handler(self, self.OnBtnFileClick))
    self.BtnBuy:AddEventListener(handler(self, self.OnBtnBuyClick))
    self.BtnChange:AddEventListener(handler(self, self.OnBtnChangeClick))
    self.BtnCost:AddEventListener(handler(self, self.OnBtnCostClick))
    self.BtnStartStory:AddEventListener(handler(self, self.OnBtnStartStoryClick))
    self.BtnFight:AddEventListener(handler(self, self.OnBtnFightClick))
end

function XUiTheatre6ChooseCharacter:InitData()
    self._BuildTagGrids = {}
    self._TagBuffGrids = {}
    self._ConsumeId = self._Control:GetTheatre6Coin()
    self._TalentCoinId = self._Control:GetTalentCoinId()
    self._TagBuffChooseDict = {}
    self._TagBuffUseDict = {}
    self._RoleGrids = {}
    self._JumpGroupId = self._Control:GetIntClientConfigValue("JumpStoryGroupId")
end

function XUiTheatre6ChooseCharacter:InitHandler()
    local storyHandlers = {}
    storyHandlers[FuncName.Init] = handler(self, self.InitStory)
    storyHandlers[FuncName.UpdateDetail] = handler(self, self.UpdateDetailOnStory)
    storyHandlers[FuncName.UpdateBattle] = handler(self, self.UpdateBattleOnStory)
    storyHandlers[FuncName.GetFashionId] = handler(self, self.GetFashionIdOnStory)

    local gamePlayHandlers = {}
    gamePlayHandlers[FuncName.Init] = handler(self, self.InitGamePlay)
    gamePlayHandlers[FuncName.UpdateDetail] = handler(self, self.UpdateDetailOnPlayMode)
    gamePlayHandlers[FuncName.UpdateBattle] = handler(self, self.UpdateBattleOnPlayMode)
    gamePlayHandlers[FuncName.GetFashionId] = handler(self, self.GetFashionIdOnPlayMode)

    self._Handlers = {}
    self._Handlers[Story] = storyHandlers
    self._Handlers[GamePlay] = gamePlayHandlers
end

function XUiTheatre6ChooseCharacter:InitComponents()
    self:BindHelpBtn(self.BtnHelp, "UiTheatre6ChooseCharacterHelpKey")
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    self._Asset = XUiHelper.NewPanelActivityAssetSafe({ self._ConsumeId }, self.PanelSpecialTool, self, nil, function(_, _)
        XLuaUiManager.Open("UiTheatre6PopupRewardDetail", self._ConsumeId)
    end)
end

function XUiTheatre6ChooseCharacter:Init3DPanel()
    ---@type XTheatre6Scene
    self._Scene = XMVCA.XScene:GetScene(SceneIds.XTheatre6Scene)
    if not self._Scene then
        XMVCA.XScene:LoadScene(SceneIds.XTheatre6Scene, false, function()
            ---@type XTheatre6Scene
            self._Scene = XMVCA.XScene:GetScene(SceneIds.XTheatre6Scene)
        end)
    end
end

function XUiTheatre6ChooseCharacter:OnStart(playMode)
    self._PlayMode = playMode
    self:ApplyStatus(FuncName.Init)
    self:InitCommon()
end

function XUiTheatre6ChooseCharacter:OnEnable()
    self._JumpToArchiveStory = false
    self._Scene:ShowScene()
    self.CharacterGroup:SelectIndex(self._Control:GetModeSelectRoleIndex(self._PlayMode, self._RoleConfigs))
    self:UpdateBuyFashion()
    XDataCenter.ItemManager.AddCountUpdateListener({ self._ConsumeId, self._TalentCoinId }, handler(self, self.OnItemCountUpdate), self.Transform)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_TALENT_LEVEL_CHANGE, self.UpdateTalent, self)
end

function XUiTheatre6ChooseCharacter:OnDisable()
    self._Scene:ClearSelectIndex()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self.Transform)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_TALENT_LEVEL_CHANGE, self.UpdateTalent, self)
end

function XUiTheatre6ChooseCharacter:OnDestroy()
    self._Scene:DestroyHuanRenFx()
    self._Scene:BackToMain()
    self._Scene.CurSelectIndex = self._CurRoleIndex --为了回到主界面时NoChoose动画
    --从剧情回顾出去看pv再回来 这时UiTheatre6Main已经没了 再次从剧情回顾出去看pv时 就没法通过 UiTheatre6Main的OnDestroy来销毁场景了
    --PS：另一个方法是XLuaScene里不要引用Control，在Control的OnRelease里自动销毁XLuaScene
    if self._JumpToArchiveStory then
        XMVCA.XScene:ExitScene(SceneIds.XTheatre6Scene)
    end
end

function XUiTheatre6ChooseCharacter:InitCommon()
    local isGamePlay = self._PlayMode == GamePlay
    self.BtnStoryReview.gameObject:SetActiveEx(not isGamePlay)
    self.BtnTalent.gameObject:SetActiveEx(isGamePlay)
    self.BtnChange.gameObject:SetActiveEx(isGamePlay)
    self.PanelStory.gameObject:SetActiveEx(not isGamePlay)
    self.PanelGamePlay.gameObject:SetActiveEx(isGamePlay)

    if isGamePlay then
        self._BuffDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6BuffDetail").New(self.BuffDetail, self)
        self._BuffDetail:SetBtnUseVisible(handler(self, self.OnBuffDetailClick))
    end

    ---@type XTableTheatre6Character[]
    self._RoleConfigs = {}
    for _, v in pairs(self._Control:GetCharacterConfigs()) do
        if XTool.IsNumberValid(v.Priority) then
            table.insert(self._RoleConfigs, v)
        end
    end
    table.sort(self._RoleConfigs, function(a, b)
        return a.Priority > b.Priority
    end)
    
    local unlockIndexDict = {}

    ---@type XUiComponent.XUiButton[]
    self._RoleTabs = {}
    for i = 1, #self._RoleConfigs do
        local config = self._RoleConfigs[i]
        local grid = self._RoleGrids[i]
        if not grid then
            grid = {}
            ---@type XUiComponent.XUiButton
            local tab = i == 1 and self.GridCharacter or XUiHelper.Instantiate(self.GridCharacter, self.GridCharacter.transform.parent)
            XUiHelper.InitUiClass(grid, tab)
            self._RoleGrids[i] = grid
        end
        local fashionId = self:ApplyStatus(FuncName.GetFashionId, config) --Theatre6CharacterFashion表Id
        local isUnlock = not XTool.IsNumberValid(config.ConditionId) or XConditionManager.CheckCondition(config.ConditionId)
        grid.GridCharacter:SetRawImage(self:GetHeadIcon(fashionId))
        grid.Disable.gameObject:SetActiveEx(not isUnlock)
        grid.GridCharacter:SetDisable(not isUnlock, isUnlock)
        table.insert(self._RoleTabs, grid.GridCharacter)
        unlockIndexDict[i] = isUnlock
    end

    self.CharacterGroup:Init(self._RoleTabs, function(i)
        if not unlockIndexDict[i] then
            local desc = XConditionManager.GetConditionDescById(self._RoleConfigs[i].ConditionId)
            self._Control:TipError(desc)
            return
        end
        self:UpdateRole(i)
        self:UpdateDetail()
    end)
    if isGamePlay then
        self._Scene:UpdateCustomRogueModel()
    else
        self._Scene:UpdateNormalModel()
    end
end

function XUiTheatre6ChooseCharacter:UpdateRole(index)
    ---@type XTableTheatre6Character
    self._CurRole = self._RoleConfigs[index]
    self._RoleId = self._CurRole.Id
    self._CurRoleIndex = index
    self:UpdateFashionId()
    self:ApplyStatus(FuncName.UpdateBattle)
    self._Control:SetSelectRoleId(self._PlayMode, self._RoleId)
    self._Scene:SetChangeByRoleBtn(index)
end

function XUiTheatre6ChooseCharacter:UpdateFashionId()
    self._CurFashionId = self:ApplyStatus(FuncName.GetFashionId, self._CurRole)
    self:UpdateBuyFashion()
end

function XUiTheatre6ChooseCharacter:UpdateBuyFashion()
    local skipId = self._Control:GetFashionConfig(self._CurFashionId).SkipId
    self.BtnBuy.gameObject:SetActiveEx(XTool.IsNumberValid(skipId))
end

function XUiTheatre6ChooseCharacter:UpdateDetail()
    self.TxtName.text = self._CurRole.Name
    self._GridTags = XUiHelper.RefreshUiObjectList(self._GridTags, self.BuildTag.parent, self.BuildTag, #self._CurRole.BuildTags, function(i, grid)
        local tagId = self._CurRole.BuildTags[i]
        local config = self._Control:GetBuildTagConfig(tagId)
        grid.UiTxtTitle.text = config.Name
        grid.UiRImgIcon:SetRawImage(config.Icon)
    end)
    self:ApplyStatus(FuncName.UpdateDetail)
end

--region 状态

function XUiTheatre6ChooseCharacter:ApplyStatus(funcName, ...)
    return self._Handlers[self._PlayMode][funcName](...)
end

function XUiTheatre6ChooseCharacter:InitStory()
    self.BtnCost:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self._ConsumeId))
end

function XUiTheatre6ChooseCharacter:InitGamePlay()
    self._Asset:Close()
    self:UpdateTalent()
end

function XUiTheatre6ChooseCharacter:UpdateTalent()
    local level = self._Control:GetTalentLv()
    local maxLevel = self._Control:GetMaxTalentLv()
    local cur, total = self._Control:GetTalentProgress()
    self.BtnTalent:SetNameByGroup(0, XUiHelper.GetText("Theatre6TalentLvRichText", level))
    self.BtnTalent:SetNameByGroup(1, level >= maxLevel and "MAX" or string.format("%s/%s", cur, total))
    self.UiImgBar.fillAmount = level >= maxLevel and 1 or cur / total
end

---@param config XTableTheatre6Character
function XUiTheatre6ChooseCharacter:GetFashionIdOnStory(config)
    return config.FashionIds[1]
end

---@param config XTableTheatre6Character
function XUiTheatre6ChooseCharacter:GetFashionIdOnPlayMode(config)
    return self._Control:IsUseRogueFashion(config.Id) and config.FashionIds[1] or config.FashionIds[2]
end

function XUiTheatre6ChooseCharacter:UpdateDetailOnStory()
    local cur, total = self._Control:GetStoryProgress(self._RoleId)
    local isStoryEnd = cur >= total

    self.TxtDes.text = self._CurRole.Info
    self.TxtStoryEndBg.gameObject:SetActiveEx(isStoryEnd)
    self.TxtProgress.gameObject:SetActiveEx(not isStoryEnd)
    self.TxtProgress.text = string.format("%s/%s", cur, total)
end

function XUiTheatre6ChooseCharacter:UpdateDetailOnPlayMode()
    local tagBuffIds = self._CurRole.TagBuffIds
    local useBuffId = self._TagBuffUseDict[self._RoleId]
    local selectIndex = self._TagBuffChooseDict[self._RoleId] or self._Control:GetBuffChooseIndex(self._PlayMode, self._RoleId)
    if selectIndex and not useBuffId then
        useBuffId = tagBuffIds[selectIndex]
    end

    self._TagBuffGrids = {}
    XUiHelper.RefreshCustomizedList(self.GridBuff.transform.parent, self.GridBuff.transform, #tagBuffIds, function(i, go)
        ---@type XUiGridTheatre6Buff
        local grid = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Buff").New(go, self)
        grid:UpdateByChoose(tagBuffIds[i], self._RoleId, i)
        table.insert(self._TagBuffGrids, grid)
        if grid:IsUnlock() then
            if not useBuffId then
                useBuffId = tagBuffIds[i]
            end
            if not selectIndex then
                selectIndex = i
            end
        end
    end)

    selectIndex = selectIndex or 1
    useBuffId = useBuffId or tagBuffIds[selectIndex]
    self._TagBuffUseDict[self._RoleId] = useBuffId
    
    local tabs = {}
    for i = 1, #tagBuffIds do
        local buffId = tagBuffIds[i]
        local grid = self._TagBuffGrids[i]
        grid:SetRedPoint(grid:IsUnlock() and not self._Control:IsBuffBeViewed(buffId))
        grid:InsertTab(tabs)
        grid:SetChooseBuff(useBuffId)
    end
    
    self.BuffGroup:Init(tabs, function(i)
        self._TagBuffChooseDict[self._RoleId] = i
        self._BuffDetail:SetBuffIdToChoose(self._RoleId, i)
        self._BuffDetail:SetCurChooseBuff(useBuffId)
        self._TagBuffGrids[i]:SetRedPoint(false)
        self._Control:SetBuffBeViewed(tagBuffIds[i])
    end)
    self.BuffGroup:SelectIndex(selectIndex)
    self._BuffDetail:SetCurChooseBuff(useBuffId)
end

function XUiTheatre6ChooseCharacter:UpdateBattleOnStory()
    self._BattleTip = nil
    self._StoryLineStageId = nil
    self._CurStoryStageIndex = self._Control:GetPlayStoryStageIndex(self._RoleId)

    self.BtnCost.gameObject:SetActiveEx(false)
    self.TxtCharacterLockBg.gameObject:SetActiveEx(false)

    self.BtnStartStory.gameObject:SetActiveEx(not self._Control:IsAllStoryPass(self._RoleId))
    self.BtnStartStory:SetButtonState(XUiButtonState.Normal)

    local status = self._Control:GetStoryLineStatus(self._RoleId, self._CurStoryStageIndex)
    self._StoryLineId = self._Control:GetStoryLineId(self._CurRole.Id)
    local config = self._Control:GetStoryLineConfig(self._StoryLineId)

    if status == XEnumConst.Theatre6.StageStatus.Purchased then --进入关卡自动扣钱
        local consumeCount = config.ConsumeCounts[self._CurStoryStageIndex]
        local isEnought = XDataCenter.ItemManager.CheckItemCountById(self._ConsumeId, consumeCount)
        self.BtnCost.gameObject:SetActiveEx(true)
        self.BtnCost:SetName(consumeCount)
        self.BtnCost:SetButtonState(isEnought and XUiButtonState.Normal or XUiButtonState.Disable)
        if not isEnought then
            self.BtnStartStory:SetButtonState(XUiButtonState.Disable)
            self._BattleTip = XUiHelper.GetText("Theatre6StoryPurchaseTip", XDataCenter.ItemManager.GetItemName(self._ConsumeId))
            return
        end
    end

    self._StoryLineStageId = config.StageIds[self._CurStoryStageIndex]
end

function XUiTheatre6ChooseCharacter:UpdateBattleOnPlayMode()
    if #self._CurRole.FashionIds < 2 then
        self.BtnChange.gameObject:SetActiveEx(false)
    else
        local isUseRogue = self._Control:IsUseRogueFashion(self._RoleId)
        self.BtnChange:SetButtonState(isUseRogue and XUiButtonState.Select or XUiButtonState.Normal)
    end
    self.BtnFight.gameObject:SetActiveEx(true)
end

--endregion

function XUiTheatre6ChooseCharacter:GetHeadIcon(fashionId)
    return self._Control:GetFashionConfig(fashionId).Portrait
end

---天赋
function XUiTheatre6ChooseCharacter:OnBtnTalentClick()
    XLuaUiManager.Open("UiTheatre6PopupUpgradePreview")
end

---剧情回顾
function XUiTheatre6ChooseCharacter:OnBtnStoryReviewClick()
    if not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.Archive) then
        return
    end
    self._Scene:HideScene()
    XLuaUiManager.OpenWithCallback("UiArchiveStory", function()
        self._JumpToArchiveStory = true
    end, self._JumpGroupId)
end

---存档
function XUiTheatre6ChooseCharacter:OnBtnFileClick()
    XLuaUiManager.Open("UiTheatre6Archive", self._RoleId)
end

---涂装购买
function XUiTheatre6ChooseCharacter:OnBtnBuyClick()
    local dict = {}
    dict.role_id = self._RoleId
    dict.fashion_id = self._CurFashionId
    CS.XRecord.Record(dict, "1000043", "Theatre6FashionSkip")

    local skipId = self._Control:GetFashionConfig(self._CurFashionId).SkipId
    XFunctionManager.SkipInterface(skipId, "UiTheatre6ChooseCharacter")
    self._Scene:HideScene()
end

---切换涂装（仅针对当前选中的角色）
function XUiTheatre6ChooseCharacter:OnBtnChangeClick()
    local useRogue = self.BtnChange.ButtonState == CS.UiButtonState.Select
    self._Control:SetUseRogueFashion(self._RoleId, useRogue)
    self:UpdateFashionId()
    self:UpdateBuyFashion()

    -- 只刷当前角色的头像
    local grid = self._RoleTabs[self._CurRoleIndex]
    if grid then
        grid:SetRawImage(self:GetHeadIcon(self._CurFashionId))
    end
    -- 只刷当前角色的模型
    self._Scene:UpdateSingleRougeRoleModel(self._RoleId)
end

---剧情模式进入战斗花费
function XUiTheatre6ChooseCharacter:OnBtnCostClick()
    self._Control:UiTip(self._ConsumeId)
end

---剧情模式进入战斗
function XUiTheatre6ChooseCharacter:OnBtnStartStoryClick()
    if self._BattleTip then
        self._Control:TipError(self._BattleTip)
        return
    end
    if not self._StoryLineStageId then
        return
    end
    local replayStageId = self._Control:IsAllStoryPass(self._RoleId) and self._StoryLineStageId or nil
    self._Control:RequestEnterStoryLine(self._StoryLineId, replayStageId, function()
        self._Scene:HideScene()
        self:Close()
    end)
end

---玩法模式进入难度选择
function XUiTheatre6ChooseCharacter:OnBtnFightClick()
    local params = {}
    params.GroupId = self._CurRole.PlayDiffGroupIds[1] --第一期特殊处理
    params.RoleId = self._RoleId
    params.FashionId = self._CurFashionId
    params.InitBuffId = self._TagBuffUseDict[self._RoleId]
    XLuaUiManager.Open("UiTheatre6ChooseDifficulty", params)
    self._Scene:HideScene()
end

---玩法模式选择初始Buff
function XUiTheatre6ChooseCharacter:OnBuffDetailClick(buffId)
    self._TagBuffUseDict[self._RoleId] = buffId
    self._Control:SaveBuffChooseIndex(self._PlayMode, self._RoleId, table.indexof(self._CurRole.TagBuffIds, buffId))
    self:ApplyStatus(FuncName.UpdateDetail)
end

function XUiTheatre6ChooseCharacter:OnItemCountUpdate(itemId)
    if itemId == self._ConsumeId then
        self:ApplyStatus(FuncName.UpdateBattle)
    elseif itemId == self._TalentCoinId then
        self:UpdateTalent()
    end
end

return XUiTheatre6ChooseCharacter
