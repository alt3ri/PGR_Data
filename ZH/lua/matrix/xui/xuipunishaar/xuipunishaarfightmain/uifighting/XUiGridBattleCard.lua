--- 主卡显示
---@class XUiGridBattleCard: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field BtnClick XUiComponent.XUiButton 战中点击按钮：对于手动激活的牌，可激活时点击激活
---@field BtnDetail XUiComponent.XUiButton 详情角标按钮（prefab 待美术提供；TODO 接入 ShowMainCardTips 只读详情。OnBtnClick 保持手动牌激活不变，详情入口走独立角标，不与激活争用 BtnClick）
---@field DetailRoot UnityEngine.RectTransform 详情浮窗定位锚点（TODO 接入时作 posUi 传 ShowMainCardTips；prefab 未提供时回退 grid Transform）
---@field PanelNormal @常态节点，内部包含了通用显示元素
---@field GroupInCD @战中CD相关信息显示的根节点
---@field ImgBlackMask UnityEngine.UI.Image CD遮罩，自上而下填充，填充百分比 = 剩余CD进度
---@field CDLight UnityEngine.RectTransform CD线条，对准最新CD在UI上的进度位置，与ImgBlackMask搭配
---@field CDTipsGroup @对于手动牌，当牌CD完成，等待点击激发时显示
---@field PnlMask UnityEngine.UI.RawImage @遮罩图，用于约束战斗的cd相关图片显示范围
---@field TagDamage     @攻击力数值标签根节点（normal=TxtDamage / up=TxtDamageUp，current≈config 显 normal 否则 up #79）
---@field TagCD         @CD 数值标签根节点（normal=TxtCD / up=TxtCDUp，同 TagDamage #79）
local XUiGridBattleCard = XClass(XUiNode, "XUiGridBattleCard")

local XUiComBattleCardShow = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/Com/XUiComBattleCardShow")
local CardBgSettingsReader = require("XModule/XPunishaar/SubModules/InGame/XPunishaarCardBgSettingsReader")
local XUiPunishaarCardValueTag = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarCardValueTag")

function XUiGridBattleCard:OnStart()
    local showRoot = self.PanelNormal or self.GameObject
    ---@type XUiComBattleCardShow
    self.CardShow = XUiComBattleCardShow.New(showRoot, self)
    self.CardShow:Open()

    if self.BtnClick then
        self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
    end

    -- 根节点数值标签（atk/cd 计算归根节点避免子→父上行访问 #79）
    if self.TagDamage then
        ---@type XUiPunishaarCardValueTag
        self.TagDamageInst = XUiPunishaarCardValueTag.New(self.TagDamage, self)
    end
    if self.TagCD then
        ---@type XUiPunishaarCardValueTag
        self.TagCDInst = XUiPunishaarCardValueTag.New(self.TagCD, self)
    end

    self.GroupInCD.gameObject:SetActiveEx(true)
end

--- 从槽位模板取标准单格宽度（槽位始终为标准格尺寸，不随卡内容变化）。
---@param slot UnityEngine.RectTransform|XUiGridBattleCardSlot|nil
---@return number|nil
function XUiGridBattleCard:_GetSlotUnitWidth(slot)
    if not slot then return nil end
    local trans = slot.Transform or slot
    if not trans then return nil end
    return trans.sizeDelta.x
end

---@param uid number 卡牌实体 uid
---@param slot UnityEngine.RectTransform|XUiGridBattleCardSlot|nil 槽位模板（取标准单格宽度用）
function XUiGridBattleCard:Refresh(uid, slot)
    self._Uid2Card = uid

    local reader = self._Control.GameControl.FightControl.STEReader
    local cardId = reader:GetCardId(uid)
    local cardCfg = self._Control.GameControl.FightControl:GetTablePunishaarCard(cardId)

    self._CardCfg = cardCfg
    -- 缓存 levelCfg 供 RefreshCd 每帧算 atk/cd config 值（base）喂 Tag，免每帧查表 #79
    local level = reader:GetCardLevel(uid)
    self._CardLevelCfg = self._Control.GameControl.FightControl:GetTablePunishaarCardLevel(cardId * 100 + level)

    self.CardShow:Refresh(uid, reader, cardCfg)

    -- 遮罩（grid 独有 PnlMask，Image 取 MaskBgs 图；不依赖 reader，grid 持 cardCfg）#64
    if self.PnlMask and cardCfg then
        local gc = self._Control.GameControl
        local maskSprite = gc and CardBgSettingsReader.GetMaskSprite(gc, cardCfg.Type, cardCfg.Size) or nil
        -- 图变跳过（per-card-change 非 hot path，仍加缓存对齐 GC 任务）
        if self._LastMaskSprite ~= maskSprite then
            self._LastMaskSprite = maskSprite
            if maskSprite then
                self.PnlMask:SetRawImage(maskSprite)
            end
            self.PnlMask.gameObject:SetActiveEx(maskSprite ~= nil)
        end
    end

    self:RefreshCd()

    local unitWidth = self:_GetSlotUnitWidth(slot)
    if unitWidth then
        self.Transform:SetSizeDeltaX(unitWidth * (cardCfg.Size or 1))
    end
end

---@param gridSlot XUiGridBattleCardSlot
function XUiGridBattleCard:RefreshPosition(gridSlot)
    local posX, posY, posZ = gridSlot.Transform:GetPosition()
    self.Transform:SetPosition(posX, posY, posZ)
end

--- 仅刷球数显示（消球/产球变化，转发 CardShow:RefreshBallCount，不全量 Refresh 避 Close all + 重建）。
function XUiGridBattleCard:RefreshBallCount()
    if not self._Uid2Card or not self._CardCfg then return end
    local reader = self._Control.GameControl.FightControl.STEReader
    if self.CardShow then
        self.CardShow:RefreshBallCount(self._Uid2Card, reader, self._CardCfg)
    end
end

function XUiGridBattleCard:RefreshCd()
    if not self._Uid2Card then
        if self.TagDamageInst then self.TagDamageInst:Clear() end
        if self.TagCDInst then self.TagCDInst:Clear() end
        return
    end

    local reader = self._Control.GameControl.FightControl.STEReader
    local cd = reader:GetCardTickCd(self._Uid2Card)
    local cdMax = reader:GetCardTickCdMax(self._Uid2Card)

    local percent = (cdMax and cdMax > 0) and (cd / cdMax) or 0

    if self.ImgBlackMask then
        self.ImgBlackMask.fillAmount = percent
    end

    if self.CDLight then
        local show = percent > 0
        self.CDLight.gameObject:SetActiveEx(show)
        if show then
            local height = self:_GetMaskHeight()
            -- SetAnchoredPositionY：C# 扩展用 tempVec2 setter(零装箱)，内部读对轴 .x 一次拆箱，避 Lua 侧 Vector2 构造+setter 双装箱 #向量GC
            self.CDLight:SetAnchoredPositionY(height * 0.5 - percent * height)
        end
    end

    if self.CDTipsGroup then
        local showTips = reader:IsCardByHand(self._Uid2Card) and reader:IsCardWaitingDone(self._Uid2Card)
        self.CDTipsGroup.gameObject:SetActiveEx(showTips)
    end

    if self.CardShow then
        self.CardShow:Refresh(self._Uid2Card, reader, self._CardCfg)
    end
    -- atk/cd 计算归根节点 Tag（每帧 reader:GetCardAtk / GetCardCdMaxSeconds 含 buff 最终值；
    -- Tag 内变更检测驱动 Refresh 动效，值不变不播）#79
    self:_RefreshValueTags(self._Uid2Card, reader)
end

function XUiGridBattleCard:_GetMaskHeight()
    if not self._MaskHeight then
        self._MaskHeight = self.ImgBlackMask and self.ImgBlackMask.rectTransform.rect.height or 0
    end
    return self._MaskHeight
end

--- 刷根节点数值标签（TagDamage/TagCD）：atk/cd 计算归根节点（避免子→父上行访问，UI-Rule）。
--- current=reader 运行时最终值（含 buff）；config=levelCfg 基础值（Refresh 缓存 _CardLevelCfg）。
--- 相等显 normal，否则显 up（buff 改 atk/cd 时）。每帧调，Tag 内变更检测驱动动效。
---@param uid number
---@param reader XPunishaarSTEReader
function XUiGridBattleCard:_RefreshValueTags(uid, reader)
    if not self.TagDamageInst and not self.TagCDInst then
        return
    end
    -- 卡牌切换（grid 复用显示其他卡）或 uid nil：清 Tag 缓存 _LastCurrent，下次 Refresh 视 first 不播动画
    -- 只有同卡数值变换才播 Refresh 动画（跨卡切换数值不一致不播）#82
    if self._LastUid2Card ~= uid then
        if self.TagDamageInst then self.TagDamageInst:Clear() end
        if self.TagCDInst then self.TagCDInst:Clear() end
        self._LastUid2Card = uid
    end
    if not uid or not self._CardLevelCfg then
        if self.TagDamageInst then self.TagDamageInst:Clear() end
        if self.TagCDInst then self.TagCDInst:Clear() end
        return
    end
    local levelCfg = self._CardLevelCfg

    if self.TagDamageInst then
        -- ATK 快照优先（buff 修正当帧值，无快照 nil 回退实时值；0 是有效修正值，Lua or 不回退 0、回退 nil）#buff修正快照
        local atkCur = reader:GetCardAtkSnapshot(uid) or reader:GetCardAtk(uid)
        local atkCfg = levelCfg.ATK or 0
        self.TagDamageInst:Refresh(atkCur, atkCfg, tostring(math.floor(atkCur)))
    end
    if self.TagCDInst then
        -- CD 上限快照优先（同上，Ms 单位）#buff修正快照
        local cdCur = (reader:GetCardTickCdMaxMsSnapshot(uid) or reader:GetCardTickCdMaxMs(uid)) / 1000

        -- 转换成秒显示的时候需要同时满足保留1位小数和向下取整
        cdCur = cdCur * 10
        cdCur = math.floor(cdCur)
        cdCur = cdCur / 10

        local cdCfg = (levelCfg.CD or 0) / 1000

        self.TagCDInst:Refresh(cdCur, cdCfg, string.format("%.1f", cdCur))
    end
end

function XUiGridBattleCard:OnBtnClick()
    -- 战中 BtnClick 专用于手动牌激活（CD完成等待激发时点击出牌），不接入详情 Tips。
    -- 详情查看走预留的 BtnDetail 角标（prefab 待美术提供），TODO 接入 ShowMainCardTips 只读详情：
    --   local host = self.Parent; while host and not host.ShowMainCardTips do host = host.Parent end
    --   host:ShowMainCardTips({ cardId = self._CardCfg.Id, level = <level>, operationMode = None }, self.DetailRoot or self.Transform)
    if not self._Uid2Card then return end
    local reader = self._Control.GameControl.FightControl.STEReader
    if not (reader:IsCardByHand(self._Uid2Card) and reader:IsCardWaitingDone(self._Uid2Card)) then
        return
    end
    self._Control.GameControl.FightControl.STEControl:ReceiveCardClick(self._Uid2Card)
end

return XUiGridBattleCard
