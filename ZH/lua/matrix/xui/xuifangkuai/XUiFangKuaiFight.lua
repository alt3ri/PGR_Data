---@class XUiFangKuaiFight : XLuaUi 大方块棋盘
---@field _Game XFangKuaiGame
---@field _Control XFangKuaiControl
---@field _Panel3D XUiPanelFangKuaiFight3D
---@field _Bubble XUiFangKuaiFightBubble
---@field _NoticeBlocks table<number,XUiGridFangKuaiNoticeBlock[]>
---@field _BlockPool XObjectPool 方块池
---@field _BlockNoticePool XObjectPool 预告方块池
---@field _Speed number
---@field _BlockMap table<number, XUiGridFangKuaiBlock>
---@field _TopBlock XUiGridFangKuaiNoticeBlock
---@field _CommanderPop XUiPanelFangKuaiCommander
---@field _Effects table<number,FKEffectData>
local XUiFangKuaiFight = XLuaUiManager.Register(XLuaUi, "UiFangKuaiFight")

local ItemType = XEnumConst.FangKuai.ItemType
local NoticeLine = {
    First = 1,
    Second = 2,
}

function XUiFangKuaiFight:TryExitToCollection(score)
    if not XMVCA.XGameCollection or not XMVCA.XGameCollection.EnumConst then
        return false
    end

    local gameType = XMVCA.XGameCollection.EnumConst.GameType.FangKong
    if not XMVCA.XGameCollection:IsLaunchedFromCollection(gameType) then
        return false
    end

    XMVCA.XGameCollection:OnGameExitToCollection(gameType, {
        Score = score,
        IsSettled = false,
    })
    return true
end

function XUiFangKuaiFight:OnAwake()
    self._BlockMap = {}
    self._NoticeBlocks = {}
    self._Effects = {}
    self._EffectTimer = {}
    self._UltimaSlashEffectTimer = {}
    self._ItemGrids = {}
    self._FlyingItemMap = {}
    self._EnhanceEffectPool = {}
    self._EnhanceEffectRoot = self.PanelTailEffect.parent
    self._MinShowCombo = self._Control:GetMinShowCombo()
    self._WarnDistance = self._Control:GetBlockWarnDistance()
    self._Alpha = self._Control:GetCannotUseAlpha()
    self._FrozenEffectTime = self._Control:GetFrozenEffectTime()
    self._Panel3D = require("XUi/XUiFangKuai/XUiPanelFangKuaiFight3D").New(self)
    self._Bubble = require("XUi/XUiFangKuai/XUiFangKuaiFightBubble").New(self.BubbleProp, self)
    self._TopBlock = require("XUi/XUiFangKuai/XUiGrid/XUiGridFangKuaiNoticeBlock").New(self.GridTop, self)
    self._CommanderPop = require("XUi/XUiFangKuai/XUiPanel/XUiPanelFangKuaiCommander").New(self.PanelCommanderToast, self)

    --self._FevLineTop = tonumber(self._Control:GetClientConfig("FevLineTop"))
    --self._FevLineBottom = tonumber(self._Control:GetClientConfig("FevLineBottom"))
    self._ClearBlockTime = tonumber(self._Control:GetClientConfig("ClearBlockTime")) * 1000
    self._EnhanceAccumulateLimit = tonumber(self._Control:GetClientConfig("ItemEnhanceAccumulateLimit"))

    self._BlockPool = XObjectPool.New(function()
        return self:OnBlockCreate()
    end)

    self._BlockNoticePool = XObjectPool.New(function(lineIndex)
        return self:OnNoticeBlockCreate(lineIndex)
    end)

    self:RegisterClickEvent(self.BtnResetting, self.OnClickReset)
    self:RegisterClickEvent(self.BtnExit, self.OnClickExit)
    self:RegisterClickEvent(self.BtnScore, self.OnClickHelp)
    self:RegisterClickEvent(self.BtnClosePropOther, self.OnClickCancelUseItem)
    self:RegisterClickEvent(self.BtnSettlement, self.OnClickSettlement)
end

---@param game XFangKuaiGame
function XUiFangKuaiFight:OnStart(game, isNewGame)
    self._Game = game
    self._IsNewGame = isNewGame
    self._StageId = game:GetCurFightStageId()
    self._ChapterId = game:GetCurFightChapterId()
    self._StageConfig = self._Control:GetStageConfig(self._StageId)
    self._IsNormal = self._Control:IsStageNormal(self._StageId)
    self._SettleRound = tonumber(self._Control:GetClientConfig("SettleRound"))

    self:InitBlockPanel()
    self._Panel3D:InitSceneRoot()
    self._Bubble:SetStageId(self._StageId)

    local roleNpcId = self._Control:GetCurShowNpcId()
    local role = self._Control:GetNpcActionConfig(roleNpcId)
    local boss = self._Control:GetNpcActionConfig(self._StageConfig.NpcId)
    self._Panel3D:ShowCharacterModel(role, boss)

    self._IsBigMap = self._StageConfig.SizeX == 9 -- 有9×9和8×9两种规格
    self.Block.gameObject:SetActiveEx(false)
    self.GridHeraldFangKuai.gameObject:SetActiveEx(false)
    self.RImgFlyItem.gameObject:SetActiveEx(false)
    self.PanelTs.gameObject:SetActiveEx(false)
    self.EffectAddFevNine.gameObject:SetActiveEx(false)
    self.EffectAddFevEight.gameObject:SetActiveEx(false)
    self.PanelTailEffect.gameObject:SetActiveEx(false)
    self.PaneSingleLineRemoveEffect.gameObject:SetActiveEx(false)
    self.ImgRound1.gameObject:SetActiveEx(self._IsNormal)
    self.ImgRound2.gameObject:SetActiveEx(not self._IsNormal)
    self.TxtNum.gameObject:SetActiveEx(self._IsNormal)
    self.TxtNum2.gameObject:SetActiveEx(not self._IsNormal)
    self.PanelNine.gameObject:SetActiveEx(self._IsBigMap)
    self.PanelEight.gameObject:SetActiveEx(not self._IsBigMap)
    self.PanelCheckerboard.anchoredPosition = Vector2(self._IsBigMap and 1.5 or 40, self.PanelCheckerboard.anchoredPosition.x)
    self._TopBlock:Close()
    self._CommanderPop:Close()
    self.PanelFevMove.gameObject:SetActiveEx(false)

    self:OnClickCancelUseItem()
    self:ForbidClick(false)
    self:HideOriginalBlock()
    self:HideCompareBg()
    self:HideHorizontalTip()
    self:ShowWarnEffect()
    self:HideSwordTrailEffect()
    self:HideFevTailEffect()

    self.EndTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
    self._Control:SaveEnterStageRecord(self._StageId)
end

function XUiFangKuaiFight:OnEnable()
    self.Super.OnEnable(self)
    self:InitFrozen()
    self:UpdateRound()
    self:UpdateScore()
    self:UpdateFrozen()
    self:UpdateFeverProgress()
    --self:UpdateFevLineState()
    self:UpdateEnhanceCount()
    self:AddEventListener()
    self:StartCreateInitBlock(self._IsNewGame)
    self._Game:InitExitFevGuideFlag()
end

function XUiFangKuaiFight:OnDisable()
    self.Super.OnDisable(self)
    self:RemoveEventListener()
end

function XUiFangKuaiFight:OnDestroy()
    self._Panel3D:Destroy()
    self._BlockPool:Clear()
    self._BlockNoticePool:Clear()
    self._BlockMap = {}
    self._NoticeBlocks = {}
    self:RemoveTimer()
    self:StopAnimation("GameStarEnable")
    CS.XAudioManager.DisposeVPTimeStretch()
end

function XUiFangKuaiFight:InitBlockPanel()
    local blockDatas = self._Game:GetBlockMap()
    for blockData, _ in pairs(blockDatas) do
        self:AddBlock(blockData)
        self:OnLineAdd()
    end
end

function XUiFangKuaiFight:StartCreateInitBlock(isNewGame)
    if self._Game:IsBlockEmpty() then
        if isNewGame then
            self.GameStar.gameObject:SetActiveEx(true)
            self:PlayAnimationWithMask("GameStarEnable", handler(self, self.PlayGameStarEnableCb))
        else
            self.GameStar.gameObject:SetActiveEx(false)
            self._Game:StartCreateInitBlock()
            self:ForbidClick(true)
        end
    else
        self:OnTopPreviewBlockShow()
    end
end

function XUiFangKuaiFight:PlayGameStarEnableCb()
    if not self.Herald1 then
        -- v2.15有个无法复现的报错 进入游戏时Herald1为空
        XLog.Error("1、Herald1为空")
        return
    end
    self._Game:StartCreateInitBlock()
    self:ForbidClick(true)
    self.GameStar.gameObject:SetActiveEx(false)
end

--region 事件

function XUiFangKuaiFight:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_TOPPREVIEW, self.OnTopPreviewBlockShow, self)
    --XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_FEVER_VALUE, self.UpdateFeverProgress, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_STARTDRAG, self.OnBlockDragStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_UPDATESCORE, self.OnScoreUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_TRANSITEM, self.OnItemTransform, self)
    --XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_FEVMOVEY, self.OnBlockFevMoveY, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_SRARTROUND, self.OnStartRound, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_USEITEMEND, self.OnUseItemEnd, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_REMOVEITEM, self.OnItemRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_ERROR_RESET, self.RestartGame, self)
    --XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_LINE_MOVE, self.OnFevLineMove, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_TOPDROP, self.OnTopBlockDrop, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_ENDDRAG, self.OnBlockDragEnd, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_CHIEF_TIP, self.ShowChiefTip, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_REMOVE, self.OnBlockRemove, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_GUIDE_MOVE, self.PlayGuide, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_GAMEOVER, self.OnGameOver, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_MOVEX, self.OnBlockMoveX, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_MOVEY, self.OnBlockMoveY, self)
    --XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_EXITFEV, self.OnFevDestory, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_ADDLINE, self.OnLineAdd, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_CLEAR, self.OnLineClear, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_ADDITEM, self.OnItemAdd, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_WANE, self.OnBlockWane, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_GROW, self.OnBlockGrow, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_RESET, self.OnRestart, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_ADD, self.OnBlockAdd, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_HIT, self.OnBlockHit, self)
    XEventManager.AddEventListener(XEventId.EVENT_FANGKUAI_DROP, self.OnDrop, self)
end

function XUiFangKuaiFight:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_TOPPREVIEW, self.OnTopPreviewBlockShow, self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_FEVER_VALUE, self.UpdateFeverProgress, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_STARTDRAG, self.OnBlockDragStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_UPDATESCORE, self.OnScoreUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_TRANSITEM, self.OnItemTransform, self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_FEVMOVEY, self.OnBlockFevMoveY, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_REMOVEITEM, self.OnItemRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_SRARTROUND, self.OnStartRound, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_USEITEMEND, self.OnUseItemEnd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_ERROR_RESET, self.RestartGame, self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_LINE_MOVE, self.OnFevLineMove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_ENDDRAG, self.OnBlockDragEnd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_TOPDROP, self.OnTopBlockDrop, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_CHIEF_TIP, self.ShowChiefTip, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_REMOVE, self.OnBlockRemove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_GUIDE_MOVE, self.PlayGuide, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_GAMEOVER, self.OnGameOver, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_MOVEX, self.OnBlockMoveX, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_MOVEY, self.OnBlockMoveY, self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_EXITFEV, self.OnFevDestory, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_ADDLINE, self.OnLineAdd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_CLEAR, self.OnLineClear, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_ADDITEM, self.OnItemAdd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_WANE, self.OnBlockWane, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_GROW, self.OnBlockGrow, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_RESET, self.OnRestart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_ADD, self.OnBlockAdd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_HIT, self.OnBlockHit, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FANGKUAI_DROP, self.OnDrop, self)
end

---开始新回合
function XUiFangKuaiFight:OnStartRound()
    self:UpdateRound()
    self:UpdateFrozen()
    self:ForbidClick(false)
    self:ShowWarnEffect()
    self:OnLineAdd()
end

---开始移动
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockDragStart(blockData)
    self._Panel3D:PlayRoleAnimation(XEnumConst.FangKuai.RoleAnim.Move)
    self:ShowOriginalBlock(blockData)
    self:ShowCompareBg(blockData)
    self.PanelBtnMask.gameObject:SetActiveEx(true)
    self.PanelScoreMask.gameObject:SetActiveEx(true)
end

---移动结束
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockDragEnd(blockData, isMoved, direction)
    self.PanelBtnMask.gameObject:SetActiveEx(false)
    self._Panel3D:PlayRoleAnimation(XEnumConst.FangKuai.RoleAnim.Standby)
    if isMoved then
        self._Control:ReduceFevStep()
        self._Game:StartRound(blockData, direction)
        self:ForbidClick(true)
    end
    self:HideOriginalBlock()
    self:HideCompareBg()
    self.PanelScoreMask.gameObject:SetActiveEx(false)
end

---消除
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockRemove(blockData, isImmediately, itemIdx, isEnhanced)
    local block = self:GetBlock(blockData)
    if block then
        if isImmediately then
            self:BlockPoolRecycle(block)
            block:Recycle()
        else
            block:PlayClearUp(function()
                self:BlockPoolRecycle(block)
            end)
        end
        if blockData:IsBoss() then
            self:PlayEnhanceEffect(block, itemIdx, isEnhanced)
        end
        self._Panel3D:PlayRoleAnimation(XEnumConst.FangKuai.RoleAnim.Attack, 2000)
    end
    self:UpdateEnhanceCount()
    self:RemoveBlock(blockData)
end

--[[---销毁
function XUiFangKuaiFight:OnFevDestory(isUp)
    local map = {}
    local line = self._Game:GetFevDestoryMaxLine(isUp)
    for id, block in pairs(self._BlockMap) do
        local gridY = block.BlockData:GetHeadGrid().y
        if gridY <= line then
            self:BlockPoolRecycle(block)
            block:Recycle()
        else
            map[id] = block
        end
    end
    self._BlockMap = map
end]]

---变短
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockWane(blockData, isClear)
    local block = self:GetBlock(blockData)
    if block then
        block:PlayBossWane(isClear)
    end
end

---变长
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockGrow(blockData)
    local block = self:GetBlock(blockData)
    if block then
        block:UpdateBlockLen()
    end
end

---上/下移N行
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockMoveY(blockData, gridY)
    local block = self:GetBlock(blockData)
    self._Control:MoveY(block, gridY)
    self:ShowWarnEffect()
end

---左/右移N格
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockMoveX(blockData, gridX)
    local block = self:GetBlock(blockData)
    self._Control:MoveX(block, gridX)
end

---添加新方块
---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockAdd(blockData)
    self:AddBlock(blockData)
    self._Panel3D:PlayBossAnimation(XEnumConst.FangKuai.BossAnim.BossAttack, 2000)
end

---新行生成
function XUiFangKuaiFight:OnLineAdd()
    local noticeBlocks = self._Game:GetNewBlockNotice()
    self:ShowNoticeBlock(noticeBlocks)
end

---战斗结束
function XUiFangKuaiFight:OnGameOver(isAdvanceEnd)
    local settleData = self._Control:GetCurStageSettleData()
    if not settleData then
        -- 等待服务端返回协议
        return
    end
    if not XLuaUiManager.IsUiShow("UiFangKuaiSettlement") then
        -- 延迟1秒 等所有表现播放再弹
        local delay = isAdvanceEnd and 0 or self._Control:GetOpenSettleDelay()
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.SetMask(false)
            XLuaUiManager.Open("UiFangKuaiSettlement", self._StageId, function()
                -- 重新开始
                self:RestartGame()
            end, isAdvanceEnd)
        end, delay)
    end
end

---播消除行特效
function XUiFangKuaiFight:OnLineClear(operate, argsDict)
    if operate == XEnumConst.FangKuai.OperateMode.Clear then
        self:OnNormalLineClear(argsDict)
    elseif operate == XEnumConst.FangKuai.OperateMode.DirClear then
        self:OnDirLineClear(argsDict)
    end
end

---播放普通消除特效
function XUiFangKuaiFight:OnNormalLineClear(argsDict)
    for _, args in ipairs(argsDict) do
        local gridY, op = args[1], args[2]
        local normalOp = op & XEnumConst.FangKuai.ClearType.Normal
        local chiefOp = op & XEnumConst.FangKuai.ClearType.Chief
        local ultimaSlashOp = op & XEnumConst.FangKuai.ClearType.UltimaSlash

        if ultimaSlashOp ~= 0 then
            -- 真意斩特效只会有一个
            self:OnUltimaSlashLineClear(gridY)
            -- 真意斩和首席特效可能同时播放
            if chiefOp == 0 then
                goto CONTINUE
            end
        end

        -- 首席特效优先级高于普通特效
        local clearType = chiefOp == 0 and normalOp or chiefOp
        local effectData = self._Effects[gridY]
        if not effectData then
            effectData = {}
            effectData.Effects = {}
            effectData.Root = CS.UnityEngine.GameObject(string.format("Line%s", gridY)).transform
            local parent = self.PaneSingleLineRemoveEffect.parent
            effectData.Root:SetParent(parent, false)
            effectData.Root:SetLayerRecursively(parent.gameObject.layer)
            local posX = effectData.Root.localPosition.x
            local posY = self._Control:GetPosByGridY(gridY)
            effectData.Root.localPosition = CS.UnityEngine.Vector3(posX, posY - 10, 0)
            self._Effects[gridY] = effectData
        end

        local effect = effectData.Effects[clearType]
        if XTool.UObjIsNil(effect) then
            local effectName = self._Control:GetSingleLineRemoveEffect(self._IsBigMap, clearType)
            effect = XUiHelper.Instantiate(self.PaneSingleLineRemoveEffect, effectData.Root).gameObject
            effect:LoadUiEffect(effectName)
            effectData.Effects[clearType] = effect
        end

        if self._EffectTimer[gridY] then
            XScheduleManager.UnSchedule(self._EffectTimer[gridY])
            self._EffectTimer[gridY] = nil
        end

        effectData.Root.gameObject:SetActiveEx(true)
        effect:SetActiveEx(true)
        self._EffectTimer[gridY] = XScheduleManager.ScheduleOnce(function()
            for _, effect in pairs(effectData.Effects) do
                if not XTool.UObjIsNil(effect) then
                    effect:SetActiveEx(false)
                end
            end
            effectData.Root.gameObject:SetActiveEx(false)
        end, self._ClearBlockTime)
        :: CONTINUE ::
    end
end

---播放同侧消除特效
function XUiFangKuaiFight:OnDirLineClear()
    self:HideSwordTrailEffect()
end

function XUiFangKuaiFight:OnUltimaSlashLineClear(gridY)
    local v3 = self.PanelUltimaSlashEffect.localPosition
    v3.y = self._Control:GetPosByGridY(gridY)
    self.PanelUltimaSlashEffect.localPosition = v3

    if self._UltimaSlashEffectTimer[gridY] then
        XScheduleManager.UnSchedule(self._UltimaSlashEffectTimer[gridY])
        self._UltimaSlashEffectTimer[gridY] = nil
    end

    self:HideSwordTrailEffect()
    self.PanelUltimaSlashEffect.gameObject:SetActiveEx(true)
    self._UltimaSlashEffectTimer[gridY] = XScheduleManager.ScheduleOnce(function()
        self.PanelUltimaSlashEffect.gameObject:SetActiveEx(false)
    end, self._ClearBlockTime)
end

-- 执行道具操作期间 屏蔽方块和道具点击
function XUiFangKuaiFight:OnUseItemEnd()
    self:ForbidClick(false)
end

function XUiFangKuaiFight:RestartGame()
    self._Round = nil
    self._Control:RestartGame(self._StageId, handler(self, self.OnRestart))
    self:ShowWarnEffect()
end

function XUiFangKuaiFight:OnScoreUpdate(isShowCombo)
    self:UpdateScore()
    if isShowCombo then
        self:ShowCombo()
    end
end

function XUiFangKuaiFight:OnBlockCreate()
    local cell = XUiHelper.Instantiate(self.Block, self.BlockContent)
    return require("XUi/XUiFangKuai/XUiGrid/XUiGridFangKuaiBlock").New(cell, self)
end

function XUiFangKuaiFight:OnNoticeBlockCreate(lineIndex)
    local content = lineIndex == NoticeLine.First and self.Herald1 or self.Herald2
    local cell = XUiHelper.Instantiate(self.GridHeraldFangKuai, content)
    return require("XUi/XUiFangKuai/XUiGrid/XUiGridFangKuaiNoticeBlock").New(cell, self)
end

function XUiFangKuaiFight:OnClear()
    for _, block in pairs(self._BlockMap) do
        block:Close()
        self:BlockPoolRecycle(block)
    end
    for _, notices in pairs(self._NoticeBlocks) do
        for _, notice in pairs(notices) do
            notice:Close()
            self._BlockNoticePool:Recycle(notice)
        end
    end
    self._BlockMap = {}
    self._NoticeBlocks = {}
    self._TopBlock:Close()
end

function XUiFangKuaiFight:OnRestart()
    self._FlyingItemMap = {}
    self:OnClear()
    self:InitFrozen()
    self:InitBlockPanel()
    self:OnClickCancelUseItem()
    self:UpdateScore()
    self:UpdateRound()
    self:UpdateFrozen()
    self:UpdateItem()
    self:StartCreateInitBlock(true)
    self:UpdateFeverProgress()
    --self:UpdateFevLineState()
    self._Game:InitExitFevGuideFlag()
end

function XUiFangKuaiFight:OnDrop()
    self._Control:PlayDropSound()
end

function XUiFangKuaiFight:OnItemAdd(itemIdx, blockData, isFull)
    local block = self:GetBlock(blockData)
    if block and XTool.IsNumberValid(itemIdx) then
        self:PlayFlyItem(itemIdx, block)
    end
    if isFull then
        self:ShowTip(XUiHelper.GetText("FangKuaiItemFull"))
    end
end

function XUiFangKuaiFight:OnItemRemove()
    self:UpdateItem()
end

function XUiFangKuaiFight:OnItemTransform()
    self:UpdateItem()
end

function XUiFangKuaiFight:OnBlockHit(blockData)
    local block = self:GetBlock(blockData)
    if block then
        block:UpdateBlock() -- 临时代码
    end
end

function XUiFangKuaiFight:OnTopPreviewBlockShow()
    if self._Control:IsFever() then
        self._TopBlock:Close()
    else
        local blockData = self._Control:GetCurStageData():GetTopPreviewBlock()
        if blockData then
            self._TopBlock:Open()
            self._TopBlock:Update(blockData)
        end
    end
end

function XUiFangKuaiFight:OnTopBlockDrop(blockData)
    self._TopBlock:Close()
    self:AddBlock(blockData)
end

--[[---预览线动画（固定从第3行移动到第9行，或者反过来）
function XUiFangKuaiFight:OnFevLineMove(isUp)
    self:SetFevLineState(true)
    self:SetFevLineArrow(true, isUp)

    local dimGridY = isUp and self._FevLineTop or self._FevLineBottom
    local lineTrans = self._IsBigMap and self._FevLineMove.PanelShashaNine or self._FevLineMove.PanelShashaEight
    self._Control:FevMoveY(lineTrans, dimGridY, isUp, self._FevLineTop - self._FevLineBottom, function()
        if not isUp then
            self:SetFevLineState(false)
        end
        self:SetFevLineArrow(false)
    end)
end

---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:OnBlockFevMoveY(blockData, gridY, isUp)
    local block = self:GetBlock(blockData)
    local curGridY = block:GetCurGridY()
    self._Control:FevMoveY(block.Transform, gridY, isUp, math.abs(curGridY - gridY), function()
        if not isUp and gridY <= 0 then
            self:OnBlockRemove(blockData, true)
        end
    end)
    self:ShowWarnEffect()
end]]

--endregion

---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:GetBlock(blockData)
    local block = self._BlockMap[blockData:GetId()]
    if not block then
        local curGrid = blockData:GetHeadGrid()
        XLog.Error(string.format("没有找到 id=%s x=%s,y=%s 所属的方块", blockData:GetId(), curGrid.x, curGrid.y))
    end
    if not block.BlockData then
        XLog.Error("BlockData null")
    end
    return block
end

---@param blockData XFangKuaiBlock
---@return XUiGridFangKuaiBlock
function XUiFangKuaiFight:AddBlock(blockData)
    local block = self._BlockPool:Create(blockData)
    self._BlockMap[block.BlockData:GetId()] = block
    return block
end

---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:RemoveBlock(blockData)
    self._BlockMap[blockData:GetId()] = nil
end

-- 使用道具时方块不接受长按事件；移动方块时不接受点击事件
function XUiFangKuaiFight:ForbidBlock(canMove, canClick)
    for _, block in pairs(self._BlockMap) do
        block:AllowLongClick(canMove)
        block:AllowClick(canClick)
    end
end

function XUiFangKuaiFight:GetBlockMoveArea(blockData)
    return self._Game:GetBlockMoveArea(blockData)
end

--region 方块预告

---@param blockDatas table<number,XFangKuaiBlock[]>
function XUiFangKuaiFight:ShowNoticeBlock(blockDatas)
    self:RecycleNoticeBlock(NoticeLine.First)
    self:RecycleNoticeBlock(NoticeLine.Second)

    if not self.Herald1 then
        XLog.Error("2、Herald1为空")
        return
    end

    if blockDatas[NoticeLine.First] then
        self.Herald1.gameObject:SetActiveEx(true)
        self:CreateNoticeBlock(blockDatas[NoticeLine.First], NoticeLine.First)
    else
        self.Herald1.gameObject:SetActiveEx(false)
    end

    if blockDatas[NoticeLine.Second] then
        self.Herald2.gameObject:SetActiveEx(true)
        self:CreateNoticeBlock(blockDatas[NoticeLine.Second], NoticeLine.Second)
    else
        self.Herald2.gameObject:SetActiveEx(false)
    end
end

function XUiFangKuaiFight:RecycleNoticeBlock(lineIndex)
    local blocks = self._NoticeBlocks[lineIndex]
    if not XTool.IsTableEmpty(blocks) then
        for _, block in pairs(blocks) do
            block:Close()
            self._BlockNoticePool:Recycle(block)
        end
        self._NoticeBlocks[lineIndex] = {}
    end
end

function XUiFangKuaiFight:CreateNoticeBlock(blockDatas, lineIndex)
    if not XTool.IsTableEmpty(blockDatas) then
        for _, blockData in pairs(blockDatas) do
            local block = self._BlockNoticePool:Create(lineIndex)
            if lineIndex == 1 then
                block.Transform:SetParent(self.Herald1, false)
            else
                block.Transform:SetParent(self.Herald2, false)
            end
            block:Open()
            block:Update(blockData)
            if not self._NoticeBlocks[lineIndex] then
                self._NoticeBlocks[lineIndex] = {}
            end
            table.insert(self._NoticeBlocks[lineIndex], block)
        end
    end
end

--endregion

--region 道具

function XUiFangKuaiFight:OnClickDeleteItem()
    self._Control:RemoveItemId(self._StageId, self._CurChooseIndex, true)
    self:OnClickCancelUseItem()
end

function XUiFangKuaiFight:UpdateItem()
    local isFev = self._Control:IsFever()
    local items = self._Control:GetAllItems()
    for index = 1, 4 do
        local uiObject = self._ItemGrids[index]
        local grid = self["BtnProp" .. index]
        if not uiObject then
            uiObject = { Index = index }
            XUiHelper.InitUiClass(uiObject, grid)
            self._ItemGrids[index] = uiObject
        end
        local itemId = items and items[index]
        local item = XTool.IsNumberValid(itemId) and self._Control:GetItemConfig(itemId) or nil
        -- 正在等待道具飞过来的槽位先不刷新状态
        if item and not self._FlyingItemMap[index] then
            uiObject.RImgProp:SetRawImage(item.Icon)
            uiObject.RImgProp2:SetRawImage(item.Icon)
            uiObject.Unactivated.gameObject:SetActiveEx(false)
            uiObject.Unactivated2.gameObject:SetActiveEx(self._CurChooseIndex and self._CurChooseIndex ~= index)
            uiObject.Activate.gameObject:SetActiveEx(not self._CurChooseIndex or self._CurChooseIndex == index)
            uiObject.Effect.gameObject:SetActiveEx(self._CurChooseIndex and self._CurChooseIndex == index and not isFev)
            uiObject.FevEffect.gameObject:SetActiveEx(self._CurChooseIndex and self._CurChooseIndex == index and isFev)
            XUiHelper.RegisterClickEvent(uiObject, uiObject.BtnProp, function()
                self:ShowItemTip(index, item, grid.transform)
            end)
        else
            uiObject.Unactivated.gameObject:SetActiveEx(true)
            uiObject.Unactivated2.gameObject:SetActiveEx(false)
            uiObject.Activate.gameObject:SetActiveEx(false)
        end
    end
end

---@param origin XUiGridFangKuaiBlock
function XUiFangKuaiFight:PlayFlyItem(itemIdx, origin)
    if not self._FlyItemPool then
        self._FlyItemPool = {}
        table.insert(self._FlyItemPool, self.RImgFlyItem)
    end
    local itemId = origin.BlockData:GetItemId()
    local dimObj = self._ItemGrids[itemIdx]
    if dimObj then
        local itemConfig = self._Control:GetItemConfig(itemId)
        local flyItem = #self._FlyItemPool > 0 and table.remove(self._FlyItemPool, 1)
        if not flyItem then
            flyItem = XUiHelper.Instantiate(self.RImgFlyItem, self.RImgFlyItem.transform.parent)
        end
        local dimPos = flyItem.transform.parent:InverseTransformPoint(dimObj.Transform.position)
        flyItem.gameObject:SetActiveEx(true)
        flyItem:SetRawImage(itemConfig.Icon)
        flyItem.transform.localPosition = self.RImgFlyItem.transform.parent:InverseTransformPoint(origin.RImgItem.transform.position)
        flyItem.transform:DOLocalMove(dimPos, self._Control:GetItemFlyTime()):OnComplete(function()
            flyItem.gameObject:SetActiveEx(false)
            table.insert(self._FlyItemPool, flyItem)
            self._FlyingItemMap = {}
            self:PlayAnimation(string.format("BtnProp%sActivate", dimObj.Index))
            self:UpdateItem()
        end)
        self._FlyingItemMap[dimObj.Index] = true
    end
end

---@param item XTableFangKuaiItem
function XUiFangKuaiFight:ShowItemTip(index, item, content)
    if not self._Control:CheckExistItem(index) then
        return
    end

    if self._FlyingItemMap[index] then
        return
    end

    -- 再次点击则关闭该弹框
    if self._CurChooseIndex == index then
        self:OnClickCancelUseItem()
        return
    end

    local isNeedChooseColor = self._Control:IsItemNeedChooseColor(item.Kind)
    local isNeedUseBtn = self._Control:IsItemNeedUseBtn(item.Kind)

    self._CurChooseIndex = index
    self._CurChooseKind = item.Kind
    self._CurChooseItemParams = item.Params
    self.BtnClosePropOther.gameObject:SetActiveEx(true)

    self:UpdateItem() -- 未被选中的道具需要变灰
    self._Bubble:ShowItemTip(index, item, content)

    if isNeedUseBtn then
        self._Bubble:UpdateShowUseBtnView(item)
        self:ForbidBlock(false, false)
    elseif isNeedChooseColor then
        self._Bubble:UpdateChooseColorView(item)
        self:ForbidBlock(false, false)
    else
        self._FirstBlock = nil
        self._SecondBlock = nil
        self._Bubble:UpdateNormalView(item)
        self:ForbidBlock(false, true)
    end

    if (item.Kind == ItemType.Frozen or item.Kind == ItemType.FrozenPlus) and not self._Control:CanAddFrozenRound(self._ChapterId) then
        self._Bubble:SetUseButtonDisable(XUiHelper.GetText("FangKuaiItemUseLimitBtn"))
    end
end

function XUiFangKuaiFight:OnClickCancelUseItem()
    self._CurChooseIndex = nil
    self._CurChooseKind = nil
    self._CurChooseItemParams = nil
    self.BtnClosePropOther.gameObject:SetActiveEx(false)
    self._Bubble:HideBubble()
    self:ForbidBlock(true, false)
    self:HideOriginalBlock()
    self:RecoverBlockAlpha()
    self:UpdateItem() -- 道具取消选中后需要把置灰取消掉
end

function XUiFangKuaiFight:OnClickAddRound()
    self._Game:StartAddRoundItem(self._CurChooseIndex, self._CurChooseItemParams)
    self:OnClickCancelUseItem()
    self:UpdateRound()
    -- 增加回合数道具没有执行方块操作的阶段（只有回合数增加） 不需要屏蔽点击
end

function XUiFangKuaiFight:OnClickFrozenRound(isPlus)
    self._Game:StartUseFrozenRoundItem(self._CurChooseIndex, isPlus)
    self:OnClickCancelUseItem()
    self:UpdateFrozen()
end

function XUiFangKuaiFight:OnClickRandomBlock()
    local colors = self._Control:GetStageColorIds(self._StageId)
    local items = self._Control:GetRandomPropToBlock()
    local randomColorId = colors[XTool.Random(1, #colors)]
    local randomItemId = tonumber(items[XTool.Random(1, #items)])
    local item = self._Control:GetItemConfig(randomItemId)
    self._CurChooseKind = item.Kind
    self._CurChooseItemParams = item.Params
    self:OnClickColor(randomColorId)
    self:ShowHorizontalTip(XUiHelper.GetText("FangKuaiRandomBlock1"), XUiHelper.GetText("FangKuaiRandomBlock2", item.Name), randomColorId)
end

function XUiFangKuaiFight:OnClickRandomLine()
    local items = self._Control:GetRandomPropToLine()
    local randomItemId = tonumber(items[XTool.Random(1, #items)])
    local item = self._Control:GetItemConfig(randomItemId)
    self._CurChooseKind = item.Kind
    self._CurChooseItemParams = item.Params

    local randomLines = {}
    for i = 1, self._Game:GetExistBlockLayerNum() do
        table.insert(randomLines, i)
    end
    local randomLine1 = randomLines[XTool.Random(1, #randomLines)]
    self._FirstBlock = self:GetBlock(next(self._Game:GetLayerBlocks(randomLine1)))

    if self._CurChooseKind == ItemType.TwoLineExChange then
        table.remove(randomLines, randomLine1)
        local randomLine2 = randomLines[XTool.Random(1, #randomLines)]
        local block2 = self:GetBlock(next(self._Game:GetLayerBlocks(randomLine2)))
        -- 只有1行 交换不了 但是道具正常被消耗
        self:OnClickBlock(block2, true)
    elseif self._CurChooseKind == ItemType.Alignment then
        self:DoAlignmentBlock(XTool.Random(0, 1))
    else
        self:OnClickBlock(self._FirstBlock)
    end
    self:ShowHorizontalTip(XUiHelper.GetText("FangKuaiRandomLine1", item.Name))
end

function XUiFangKuaiFight:OnClickConvertionBlock(isPlus)
    local bossBlocks = self._Game:StartUseConvertionItem(self._CurChooseIndex, isPlus)
    if not XTool.IsTableEmpty(bossBlocks) then
        for _, blockData in ipairs(bossBlocks) do
            local block = self:GetBlock(blockData)
            block:UpdateBlock()
            block:PlayExpression(XEnumConst.FangKuai.Expression.Standby)
        end
    else
        self:ShowTip(XUiHelper.GetText("FangKuaiUseConvertTip"))
    end
    self:OnClickCancelUseItem()
end

function XUiFangKuaiFight:OnClickColor(color)
    self._Game:StartUseColorItem(self._CurChooseIndex, self._CurChooseKind, color, self._CurChooseItemParams)
    self:OnClickCancelUseItem()
    self:ForbidClick(true)
end

function XUiFangKuaiFight:OnClickExItem()
    self._Control:ReduceFevStep()
    self._Game:StartUseExItem(self._CurChooseIndex, self._CurChooseKind)
    self:OnClickCancelUseItem()
    self:ForbidClick(true)
end

---@param block XUiGridFangKuaiBlock
---@param isIgnoreLimit boolean 是否忽略条件限制 直接使用道具（如果不符合条件 道具不会生效 但是会被消耗掉）
function XUiFangKuaiFight:OnClickBlock(block, isIgnoreLimit)
    local isSuccess = false
    if self._CurChooseKind == ItemType.SingleLineRemove then
        isSuccess = self:DoSingleLineRemove(block)
    elseif self._CurChooseKind == ItemType.TwoLineExChange or self._CurChooseKind == ItemType.TwoLineRemove then
        isSuccess = self:DoTwoLineExChange(block, isIgnoreLimit, self._CurChooseKind)
    elseif self._CurChooseKind == ItemType.AdjacentExchange then
        isSuccess = self:DoAdjacentExchange(block)
    elseif self._CurChooseKind == ItemType.Alignment then
        isSuccess = self:DoShowChooseDirTip(block)
    end
    if not isSuccess then
        return
    end
    self:OnClickCancelUseItem()
    self:ForbidClick(true)
end

---@param block XUiGridFangKuaiBlock
function XUiFangKuaiFight:DoSingleLineRemove(block)
    self._Game:StartUseRemoveItem(self._CurChooseIndex, block.BlockData)
    return true
end

---@param block XUiGridFangKuaiBlock
function XUiFangKuaiFight:DoTwoLineExChange(block, isIgnoreLimit, itemType)
    local blockData = block.BlockData
    if not self._FirstBlock or self._FirstBlock == block then
        self._FirstBlock = block
        self:ShowOriginalLayer(blockData:GetHeadGrid().y)
        return false
    end
    if self._FirstBlock.BlockData:GetHeadGrid().y == blockData:GetHeadGrid().y and not isIgnoreLimit then
        return false
    end
    self._Game:StartUseExchangeItem(self._CurChooseIndex, itemType, self._FirstBlock.BlockData, blockData)
    return true
end

---@param block XUiGridFangKuaiBlock
function XUiFangKuaiFight:DoAdjacentExchange(block)
    local blockData = block.BlockData
    if not self._FirstBlock or self._FirstBlock == block then
        self._FirstBlock = block
        self:ShowOriginalBlock(blockData)
        self:ChangeBlockAlpha(blockData)
        return false
    end
    -- 方块必须相邻
    if not self:CheckBlockNear(self._FirstBlock.BlockData, blockData) then
        self._FirstBlock = block
        self:ShowOriginalBlock(blockData)
        self:ChangeBlockAlpha(blockData)
        return false
    end
    self._Game:StartUseExchangeItem(self._CurChooseIndex, ItemType.AdjacentExchange, self._FirstBlock.BlockData, blockData)
    return true
end

-- 磁吸道具比较特殊 需要依次打开两个弹框
---@param block XUiGridFangKuaiBlock
function XUiFangKuaiFight:DoShowChooseDirTip(block)
    if not self._FirstBlock then
        local itemId = self._Control:GetAllItems()[self._CurChooseIndex]
        local item = self._Control:GetItemConfig(itemId)
        self._Bubble:UpdateAlignmentView(item)
    end
    self._FirstBlock = block
    self:ShowOriginalLayer(block.BlockData:GetHeadGrid().y)
    return false
end

function XUiFangKuaiFight:DoAlignmentBlock(direction)
    self._Game:StartUseAlignmentItem(self._CurChooseIndex, self._FirstBlock.BlockData:GetHeadGrid().y, direction)
    self:OnClickCancelUseItem()
    self:ForbidClick(true)
end

---@param blockData1 XFangKuaiBlock
---@param blockData2 XFangKuaiBlock
function XUiFangKuaiFight:CheckBlockNear(blockData1, blockData2)
    if blockData1:GetId() == blockData2:GetId() then
        return true
    end
    local firstGrid = blockData1:GetHeadGrid()
    local firstLen = blockData1:GetLen()
    local secondGrid = blockData2:GetHeadGrid()
    local secondLen = blockData2:GetLen()
    return (secondGrid.x + secondLen == firstGrid.x or firstGrid.x + firstLen == secondGrid.x) and (firstGrid.y == secondGrid.y)
end

--endregion

--region 显示方块原先位置

function XUiFangKuaiFight:InitOriginalBlock(len)
    if not self._Original then
        self._Original = {}
        XUiHelper.InitUiClass(self._Original, self.OriginalBlock)
    end
    self._Original.ImgOne.gameObject:SetActiveEx(len == 1)
    self._Original.ImgHead.gameObject:SetActiveEx(len > 1)
    self._Original.ImgTail.gameObject:SetActiveEx(len > 1)
    if len > 1 then
        local tailX = self._Control:GetPosByGridX(len) - 10
        local posY = self._Original.ImgTail.transform.anchoredPosition.y
        self._Original.ImgTail.transform.anchoredPosition = CS.UnityEngine.Vector2(tailX, posY)
    end
end

---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:ShowOriginalBlock(blockData)
    self:InitOriginalBlock(blockData:GetLen())
    local posX, posY = self._Control:GetPosByBlock(blockData)
    self.OriginalBlock.localPosition = CS.UnityEngine.Vector3(posX, posY, 0)
    self.OriginalBlock.gameObject:SetActiveEx(true)
end

function XUiFangKuaiFight:ShowOriginalLayer(gridY)
    self:InitOriginalBlock(self._StageConfig.SizeX)
    local posY = self._Control:GetPosByGridY(gridY)
    self.OriginalBlock.localPosition = CS.UnityEngine.Vector3(0, posY, 0)
    self.OriginalBlock.gameObject:SetActiveEx(true)
end

function XUiFangKuaiFight:HideOriginalBlock()
    self.OriginalBlock.gameObject:SetActiveEx(false)
end

--endregion

--region 显示方块所在列

---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:ShowCompareBg(blockData)
    local w = self._Control:GetPosByGridX(blockData:GetLen() + 1)
    local h = self.ImageCompare.sizeDelta.y
    local x = self._Control:GetPosByGridX(blockData:GetHeadGrid().x)
    self.PanelCompare.gameObject:SetActiveEx(true)
    self.ImageCompare.sizeDelta = CS.UnityEngine.Vector2(w, h)
    self.PanelCompare.anchoredPosition = CS.UnityEngine.Vector2(x, 0)
end

function XUiFangKuaiFight:UpdateCompareBgPos(posX)
    self.PanelCompare.anchoredPosition = CS.UnityEngine.Vector2(posX, 0)
end

function XUiFangKuaiFight:HideCompareBg()
    self.PanelCompare.gameObject:SetActiveEx(false)
end

--endregion

--region 特效

function XUiFangKuaiFight:ShowWarnEffect()
    --[[if self._Control:IsFever() then
        -- 狂热状态下 屏蔽警戒特效
        self.PanelEffect.gameObject:SetActiveEx(false)
        self.PanelEffect2.gameObject:SetActiveEx(false)
        return
    end]]
    local isWarn = false
    local maxY = self._StageConfig.SizeY
    for y = maxY - self._WarnDistance, maxY do
        local blocks = self._Control:GetLayerBlocks(y)
        if not XTool.IsTableEmpty(blocks) then
            isWarn = true
            break
        end
    end
    self.PanelEffect.gameObject:SetActiveEx(isWarn and self._IsBigMap) -- 这里使用的是缩放特效的方法 不是两个不同的特效
    self.PanelEffect2.gameObject:SetActiveEx(isWarn and not self._IsBigMap)
end

function XUiFangKuaiFight:InitFrozen()
    local effectX = self._IsBigMap and 20 or -43
    self.FxUiFangKuaiFrozen01.anchoredPosition = CS.UnityEngine.Vector2(effectX, self.FxUiFangKuaiFrozen01.anchoredPosition.y)
    self.FxUiFangKuaiFrozen02.anchoredPosition = CS.UnityEngine.Vector2(effectX, self.FxUiFangKuaiFrozen02.anchoredPosition.y)
    self.FxUiFangKuaiFrozen03.anchoredPosition = CS.UnityEngine.Vector2(effectX, self.FxUiFangKuaiFrozen03.anchoredPosition.y)
    self._TempFrozenRound = self._Control:GetCurStageData():GetFrozenRound()
end

-- 01生成 02常驻 03溶解
function XUiFangKuaiFight:UpdateFrozen()
    self:RemoveFrozenTimer()
    local times = self._Control:GetCurStageData():GetFrozenRound()
    self.TxtFrozen.text = times > 0 and times or ""
    if self._TempFrozenRound > 0 and times > 0 then
        self.FxUiFangKuaiFrozen02:LoadUiEffect(self._Control:GetFrozenKeepEffect(self._IsBigMap))
    elseif self._TempFrozenRound <= 0 and times > 0 then
        self.FxUiFangKuaiFrozen01:LoadUiEffect(self._Control:GetFrozenCreateEffect(self._IsBigMap))
        self._FrozenTimer = XScheduleManager.ScheduleOnce(function()
            self.FxUiFangKuaiFrozen02:LoadUiEffect(self._Control:GetFrozenKeepEffect(self._IsBigMap))
            self.FxUiFangKuaiFrozen01:UnLoadUiEffect()
        end, self._FrozenEffectTime)
    elseif self._TempFrozenRound > 0 and times <= 0 then
        self.FxUiFangKuaiFrozen03:LoadUiEffect(self._Control:GetFrozenRemoveEffect(self._IsBigMap))
        self.FxUiFangKuaiFrozen02:UnLoadUiEffect()
        self._FrozenTimer = XScheduleManager.ScheduleOnce(function()
            self.FxUiFangKuaiFrozen03:UnLoadUiEffect()
        end, self._FrozenEffectTime)
    else
        self.FxUiFangKuaiFrozen01:UnLoadUiEffect()
        self.FxUiFangKuaiFrozen02:UnLoadUiEffect()
        self.FxUiFangKuaiFrozen03:UnLoadUiEffect()
    end
    self._TempFrozenRound = times
end

--[[---@param block XUiGridFangKuaiBlock
function XUiFangKuaiFight:ShowFevTailEffect(block)
    if not self._Control:IsFever() then
        return
    end
    self.PanelTailEffect:SetParent(block.Transform, false)
    self.PanelTailEffect:SetSiblingIndex(0)
    self.PanelTailEffect.gameObject:SetActiveEx(true)
end]]

---剑痕特效（狂热状态 or 刀锋方块）
---@param block XUiGridFangKuaiBlock
function XUiFangKuaiFight:ShowSwordTrailEffect(initGridX, curGridX, block)
    if not self._FevDragEffect then
        self._FevDragEffectV3 = self.PanelFevDragEffect.localPosition
        self._FevDragEffect = {}
        XUiHelper.InitUiClass(self._FevDragEffect, self.PanelFevDragEffect)
    end

    initGridX = math.floor(initGridX)
    curGridX = math.floor(curGridX)

    if initGridX == curGridX then
        self:HideSwordTrailEffect()
        return
    end

    local gridY = block.BlockData:GetHeadGrid().y
    self.PanelFevDragEffect.gameObject:SetActiveEx(true)
    self._FevDragEffectV3.y = self._Control:GetPosByGridY(gridY)
    self.PanelFevDragEffect.localPosition = self._FevDragEffectV3

    local left = math.min(initGridX, curGridX)
    local right = math.max(initGridX, curGridX)
    for i = 1, 9 do
        local isShow = i >= left and i <= right
        self._FevDragEffect["DragEffect" .. i].gameObject:SetActiveEx(isShow)
    end
end

function XUiFangKuaiFight:HideSwordTrailEffect()
    if self._FevDragEffect then
        for i = 1, 9 do
            self._FevDragEffect["DragEffect" .. i].gameObject:SetActiveEx(false)
        end
    end
    self.PanelFevDragEffect.gameObject:SetActiveEx(false)
end

function XUiFangKuaiFight:HideFevTailEffect()
    self.PanelTailEffect.gameObject:SetActiveEx(false)
end

--endregion

--region 分数

function XUiFangKuaiFight:UpdateScore()
    local score = self._Control:GetScore()
    local scoreIcon = self._Control:GetStageRankIcon(self._StageId, score)
    self.TxtScore.text = score
    self.RImgRankA:SetRawImage(scoreIcon)
end

function XUiFangKuaiFight:ShowCombo()
    local combo = self._Control:GetComboNum()
    if combo >= self._MinShowCombo and combo ~= self._CurShowCombo then
        self:RemoveComboTimer()
        self._CurShowCombo = combo
        self.PanelCombo.gameObject:SetActiveEx(true)
        self.ComboCountText:TextToSprite(combo)
        self._ComboTimer = XScheduleManager.ScheduleOnce(function()
            self._CurShowCombo = nil
            self.PanelCombo.gameObject:SetActiveEx(false)
        end, 1000)
        self._Control:PlayComboSound(combo)
    end
end

--endregion

function XUiFangKuaiFight:UpdateRound()
    local round
    if self._Control:IsStageNormal(self._StageId) then
        round = self._Game:GetLeaveRound()
    else
        round = string.format("%s/%s", self._Control:GetCurRound(), self._StageConfig.MaxRound)
    end
    if round then
        if self._IsNormal then
            self.TxtNum.text = round
        else
            self.TxtNum2.text = round
        end
        if self._Round and self._Round ~= round then
            self:PlayAnimation("TxtNumQieHuan")
        end
        self._Round = round
        local isTargetRound = self._Control:GetCurRound() >= self._SettleRound
        local isTargetGrade = self._Control:IsSettleScoreGrade(self._StageId)
        self.BtnSettlement.gameObject:SetActiveEx(isTargetRound or isTargetGrade)
    else
        self.BtnSettlement.gameObject:SetActiveEx(false)
    end
end

function XUiFangKuaiFight:OnClickReset()
    self._Control:OpenTip(nil, XUiHelper.GetText("FangKuaiReset"), handler(self, self.RestartGame))
end

function XUiFangKuaiFight:OnClickHelp()
    XLuaUiManager.Open("UiFangKuaiRankDetails", self._StageId)
end

function XUiFangKuaiFight:OnClickExit()
    if self._IsForbidClick then
        return -- 避免正在拖动方块时点ESC关闭界面
    end
    self._Control:RecordStage(XEnumConst.FangKuai.RecordUiType.Fight, XEnumConst.FangKuai.RecordButtonType.Leave, self._StageId)
    if not self:TryExitToCollection() then
        XLuaUiManager.Remove("UiFangKuaiChapterDetail")
    end
    self:Close()
end

function XUiFangKuaiFight:OnClickSettlement()
    if self._Game:IsGameOver() then
        return
    end
    self._Control:OpenTip(nil, XUiHelper.GetText("FangKuaiAdvanceSettle"), function()
        self._Game:OnGameOver(true)
    end)
end

-- 方块掉落、生成和上移期间不能移动和使用道具
function XUiFangKuaiFight:ForbidClick(bo)
    self._IsForbidClick = bo
    self.PanelBlockMask.gameObject:SetActiveEx(bo)
    self.PanelItemMask.gameObject:SetActiveEx(bo)
    self.PanelBtnMask.gameObject:SetActiveEx(bo)
end

function XUiFangKuaiFight:RemoveTimer()
    self:RemoveComboTimer()
    self:RemoveTipTimer()
    self:RemoveEffectTimer()
    self:RemoveCreateTimer()
    self:RemoveHorizontalTipTimer()
    self:RemoveFrozenTimer()
end

function XUiFangKuaiFight:RemoveComboTimer()
    if self._ComboTimer then
        XScheduleManager.UnSchedule(self._ComboTimer)
        self._ComboTimer = nil
    end
end

function XUiFangKuaiFight:RemoveTipTimer()
    if self._TipTimer then
        XScheduleManager.UnSchedule(self._TipTimer)
        self._TipTimer = nil
    end
end

function XUiFangKuaiFight:RemoveEffectTimer()
    for _, timer in pairs(self._EffectTimer) do
        XScheduleManager.UnSchedule(timer)
    end
    for _, timer in pairs(self._UltimaSlashEffectTimer) do
        XScheduleManager.UnSchedule(timer)
    end
    self._EffectTimer = {}
    self._UltimaSlashEffectTimer = {}
end

function XUiFangKuaiFight:RemoveCreateTimer()
    if self._CreateTimer then
        XScheduleManager.UnSchedule(self._CreateTimer)
        self._CreateTimer = nil
    end
end

function XUiFangKuaiFight:RemoveHorizontalTipTimer()
    if self._HorizontalTipTimer then
        XScheduleManager.UnSchedule(self._HorizontalTipTimer)
        self._HorizontalTipTimer = nil
    end
end

function XUiFangKuaiFight:RemoveFrozenTimer()
    if self._FrozenTimer then
        XScheduleManager.UnSchedule(self._FrozenTimer)
        self._FrozenTimer = nil
    end
end

---@param block XUiGridFangKuaiBlock
function XUiFangKuaiFight:BlockPoolRecycle(block)
    self._BlockPool:Recycle(block)
end

function XUiFangKuaiFight:ShowChiefTip()
    -- 弹首席弹框
    self._CommanderPop:Open()
end

function XUiFangKuaiFight:ShowTip(desc)
    self:RemoveTipTimer()
    self.PanelTs.gameObject:SetActiveEx(true)
    self.TxtDesc.text = XUiHelper.ReplaceTextNewLine(desc)
    self._TipTimer = XScheduleManager.ScheduleOnce(function()
        self.PanelTs.gameObject:SetActiveEx(false)
    end, 1500)
end

function XUiFangKuaiFight:GetChapterId()
    return self._ChapterId
end

--region 透明度变化

---@param blockData XFangKuaiBlock
function XUiFangKuaiFight:ChangeBlockAlpha(blockData)
    for _, block in pairs(self._BlockMap) do
        local isNear = self:CheckBlockNear(blockData, block.BlockData)
        block:ChangeAlpha(isNear and 1 or self._Alpha)
    end
end

function XUiFangKuaiFight:RecoverBlockAlpha()
    for _, block in pairs(self._BlockMap) do
        block:ChangeAlpha(1)
    end
end

--endregion

--region 引导

function XUiFangKuaiFight:PlayGuide(x, y, dir)
    local gridX = tonumber(x)
    local gridY = tonumber(y)
    local dimGridX = gridX + tonumber(dir)
    local blockData = self._Game:FindGuideBlock(gridX, gridY)
    if not blockData then
        return
    end
    local block = self:GetBlock(blockData)
    if not block then
        return
    end
    block:ForceMoveX(dimGridX)
end

function XUiFangKuaiFight:GetExitFevGuideFlag()
    return self._Game:GetExitFevGuideFlag()
end

--endregion

--region 限制多点触屏

function XUiFangKuaiFight:SetCurClickBlockId(id)
    self._CurClickBlock = id
end

function XUiFangKuaiFight:IsOtherClicking(id)
    return self._CurClickBlock and self._CurClickBlock ~= id
end

function XUiFangKuaiFight:ClearClickBlockId()
    self._CurClickBlock = nil
end

--endregion

--region 横幅

function XUiFangKuaiFight:ShowHorizontalTip(desc1, desc2, colorId)
    self:RemoveHorizontalTipTimer()
    if not self._HorizontalTip then
        self._HorizontalTip = {}
        self._HorizontalTipTime = tonumber(self._Control:GetClientConfig("HorizontalTipCloseTime"))
        XUiHelper.InitUiClass(self._HorizontalTip, self.PanelRollTips)
    end
    self.PanelRollTips.gameObject:SetActiveEx(true)
    self._HorizontalTip.TxtTips.text = desc1 or ""
    self._HorizontalTip.TxtDetail.text = desc2 or ""
    if XTool.IsNumberValid(colorId) then
        local textureConfig = self._Control:GetBlockTextureConfig(colorId)
        self._HorizontalTip.Block.gameObject:SetActiveEx(true)
        self._HorizontalTip.ImgOne:SetRawImage(textureConfig.StandaloneImage)
        self._HorizontalTip.RImgExpression:SetRawImage(textureConfig.Standby[1])
    else
        self._HorizontalTip.Block.gameObject:SetActiveEx(false)
    end
    self._HorizontalTipTimer = XScheduleManager.ScheduleOnce(function()
        self.PanelRollTips.gameObject:SetActiveEx(false)
    end, self._HorizontalTipTime)
end

function XUiFangKuaiFight:HideHorizontalTip()
    self.PanelRollTips.gameObject:SetActiveEx(false)
end

--endregion

--region 狂热

function XUiFangKuaiFight:UpdateFeverProgress()
    self.PanelStep.gameObject:SetActiveEx(false)
    self.PanelFeverLv.gameObject:SetActiveEx(false)
    self.PanelScoreUp.gameObject:SetActiveEx(false)
    self.PanelFeverEffect.gameObject:SetActiveEx(false)
    self.PanelFeverEffect2.gameObject:SetActiveEx(false)
    --[[-- 狂热值
    local value = self._Control:GetFeverValue()
    local maxValue = self._Control:GetFevExcitedValue()
    local fevLv = self._Control:GetFevLevel()
    self.ImgFeverBar.fillAmount = math.min(1, value / maxValue)
    -- 强化步数
    local fevStep = self._Control:GetFevStep()
    local isFev = self._Control:IsFever()
    if not isFev then
        self.PanelStep.gameObject:SetActiveEx(false)
        self.PanelFeverLv.gameObject:SetActiveEx(false)
        self.PanelScoreUp.gameObject:SetActiveEx(false)
        self.PanelFeverEffect.gameObject:SetActiveEx(false)
        self.PanelFeverEffect2.gameObject:SetActiveEx(false)
    else
        self.PanelStep.gameObject:SetActiveEx(true)
        self.PanelFeverLv.gameObject:SetActiveEx(true)
        self.PanelScoreUp.gameObject:SetActiveEx(true)
        local maxStep = self._Control:GetMaxEnhanceTimes()
        if not self._FevStepGrids then
            self._FevStepGrids = {}
            for i = 1, maxStep do
                local go = i == 1 and self.GridStep or XUiHelper.Instantiate(self.GridStep, self.GridStep.parent)
                local uiObject = {}
                XUiHelper.InitUiClass(uiObject, go)
                uiObject.ImgOn.gameObject:SetActiveEx(fevStep >= i)
                uiObject.ImgOff.gameObject:SetActiveEx(fevStep < i)
                self._FevStepGrids[i] = uiObject
            end
        else
            for i = 1, maxStep do
                local grid = self._FevStepGrids[i]
                grid.ImgOn.gameObject:SetActiveEx(fevStep >= i)
                grid.ImgOff.gameObject:SetActiveEx(fevStep < i)
            end
        end
        -- 狂热等级
        self.TxtFeverLv.text = string.format("Lv%s", fevLv)
        -- 得分倍率
        self.TxtScoreUpNum.text = self._Control:GetFevRadio()
        -- 狂热特效
        self.PanelFeverEffect.gameObject:SetActiveEx(self._IsBigMap)
        self.PanelFeverEffect2.gameObject:SetActiveEx(not self._IsBigMap)
    end
    -- 屏蔽顶部方块掉落
    self:OnTopPreviewBlockShow()
    -- 警戒特效
    self:ShowWarnEffect()
    -- debug
    if self._Control:IsDebug() then
        self.PanelFeverLv.gameObject:SetActiveEx(true)
        self.TxtFeverLv.text = string.format("Lv%s(%s)", fevLv, self._Control:GetFeverValue())
    end
    -- 播放狂热值达到上限特效
    if self._TempFevLv and fevLv > self._TempFevLv then
        local effect = self._IsBigMap and self.EffectAddFevNine or self.EffectAddFevEight
        effect.gameObject:SetActiveEx(false)
        effect.gameObject:SetActiveEx(true)
    end
    self._TempFevLv = fevLv]]
end

--region 预览线

--[[function XUiFangKuaiFight:UpdateFevLineState()
    if not self._FevLineMove then
        self._FevLineMove = {}
        XUiHelper.InitUiClass(self._FevLineMove, self.PanelFevMove)
    end

    local isFev = self._Control:IsFever()
    local posY = self._Control:GetPosByGridY(isFev and self._FevLineTop or self._FevLineBottom)
    if not self._FevLineLocalPosV3 then
        self._FevLineLocalPosV3 = CS.UnityEngine.Vector3(0, posY, 0)
    else
        self._FevLineLocalPosV3.y = posY
    end
    self._FevLineMove.PanelShashaNine.localPosition = self._FevLineLocalPosV3
    self._FevLineMove.PanelShashaEight.localPosition = self._FevLineLocalPosV3

    self._FevLineMove.PanelShashaEight.gameObject:SetActiveEx(not self._IsBigMap)
    self._FevLineMove.PanelShashaNine.gameObject:SetActiveEx(self._IsBigMap)

    self:SetFevLineState(isFev)
end

function XUiFangKuaiFight:SetFevLineState(isFev)
    if self._IsBigMap then
        self._FevLineMove.NineUp.gameObject:SetActiveEx(false)
        self._FevLineMove.NineDown.gameObject:SetActiveEx(false)
        self._FevLineMove.Line9.gameObject:SetActiveEx(isFev)
        self._FevLineMove.Shasha91.gameObject:SetActiveEx(not isFev)
        self._FevLineMove.Shasha92.gameObject:SetActiveEx(isFev)
    else
        self._FevLineMove.EightUp.gameObject:SetActiveEx(false)
        self._FevLineMove.EightDown.gameObject:SetActiveEx(false)
        self._FevLineMove.Line8.gameObject:SetActiveEx(isFev)
        self._FevLineMove.Shasha81.gameObject:SetActiveEx(not isFev)
        self._FevLineMove.Shasha82.gameObject:SetActiveEx(isFev)
    end
end

function XUiFangKuaiFight:SetFevLineArrow(isShow, isUp)
    if isShow then
        self._FevLineMove.EightDown.gameObject:SetActiveEx(not self._IsBigMap and not isUp)
        self._FevLineMove.EightUp.gameObject:SetActiveEx(not self._IsBigMap and isUp)
        self._FevLineMove.NineDown.gameObject:SetActiveEx(self._IsBigMap and not isUp)
        self._FevLineMove.NineUp.gameObject:SetActiveEx(self._IsBigMap and isUp)
    else
        self._FevLineMove.EightDown.gameObject:SetActiveEx(false)
        self._FevLineMove.EightUp.gameObject:SetActiveEx(false)
        self._FevLineMove.NineDown.gameObject:SetActiveEx(false)
        self._FevLineMove.NineUp.gameObject:SetActiveEx(false)
    end
end]]

--endregion

--endregion

function XUiFangKuaiFight:UpdateEnhanceCount()
    self.TxtEnhanceCount.text = string.format("%s/%s", self._Control:GetAccumulatedEnhanceCount(), self._EnhanceAccumulateLimit)
end

---@param block XUiGridFangKuaiBlock
---@param itemIdx number
---@param isEnhanced boolean
function XUiFangKuaiFight:PlayEnhanceEffect(block, itemIdx, isEnhanced)
    if XTool.UObjIsNil(block.Transform) then
        return
    end

    local targetTransform
    if isEnhanced then
        local itemGrid = self[string.format("BtnProp%s", itemIdx)]
        targetTransform = itemGrid.transform
    end
    -- 没有强化背包道具时，本次强化次数会累计到积累条
    targetTransform = targetTransform or self.TxtEnhanceCount.transform

    -- PanelTailEffect保留给狂热逻辑使用，这里只将它作为模板创建拖尾实例
    local effect
    if #self._EnhanceEffectPool > 0 then
        effect = table.remove(self._EnhanceEffectPool, 1)
    end
    if XTool.UObjIsNil(effect) then
        effect = XUiHelper.Instantiate(self.PanelTailEffect, self._EnhanceEffectRoot)
    end

    local parent = effect.parent
    effect:DOKill()
    effect.gameObject:SetActiveEx(true)
    effect:SetAsLastSibling()
    -- block.Transform的位置即方块数据中HeadGrid（第一格）对应的UI位置
    effect.localPosition = parent:InverseTransformPoint(block.Transform.position)
    local targetPosition = parent:InverseTransformPoint(targetTransform.position)
    effect:DOLocalMove(targetPosition, self._Control:GetItemFlyTime()):OnComplete(function()
        if not XTool.UObjIsNil(effect) then
            effect.gameObject:SetActiveEx(false)
            table.insert(self._EnhanceEffectPool, effect)
        end
    end)
end

---@class FKEffectData
---@field Root UnityEngine.RectTransform
---@field Effects UnityEngine.GameObject[]

return XUiFangKuaiFight
