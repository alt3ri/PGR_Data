--- 商店/装备栏共用卡牌 grid：商品模式含购买按钮，装备栏模式隐藏购买按钮。
--- 卡牌内容显示委托给 XUiComShopCardShow。
--- 支持拖拽（Theatre5 假拖拽）：由容器调 EnableDrag(dragArea) 开启；
---   表现层跟手/归位，落点操作路由到 Control 的拖拽中枢（EndDragCard）。
---@class XUiGridShopCard: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field PanelNormal  @卡牌内容节点，挂唯一的 CardShow 实例（禁用态遮罩 PnlDisable 在其子树内，归 CardShow）
---@field PanelShopSubCard @副卡显示的节点，与 PanelNormal 互斥，仅商店栏售卖副卡时显示
---@field PanelCard    @卡牌内容根节点（CardId > 0 时显示）
---@field PanelBuy     @购买区根节点（商品模式可见）
---@field PanelLock    @锁定态节点（保留字段，暂无使用）
---@field TagDamage     @攻击力数值标签根节点（normal=TxtDamage / up=TxtDamageUp，current≈config 显 normal 否则 up #79）
---@field TagCD         @CD 数值标签根节点（normal=TxtCD / up=TxtCDUp，同 TagDamage #79）
---@field BtnClick     XUiComponent.XUiButton 卡牌按钮（透明点击区：打开详情 + IsBought 置灰；不显价格不控制货币 #78）
---@field TxtPrice     UnityEngine.UI.Text 购买价格文本（PanelBuy 子树内，商品态显；对称随 PanelBuy 隐藏）
---@field DetailRoot UnityEngine.RectTransform 详情浮窗定位锚点（Tips 悬浮基准；商品/对战区单锚点；prefab 未提供时回退 grid Transform）
---@field DetailRootLeft UnityEngine.RectTransform 详情浮窗左侧锚点（背包区 x-flip 用；prefab 未提供则走单 DetailRoot）
---@field DetailRootRight UnityEngine.RectTransform 详情浮窗右侧锚点（背包区 x-flip 用；prefab 未提供则走单 DetailRoot）
---@field RImgOutlineGroup @外描边选中态Group（点击打开 Tips 期间显）
---@field RImgOutline XUiComponent.XUiRawImage 外描边子图（Group 下，按 Size/Type 取 OutlineBgs 设图）
local XUiGridShopCard = XClass(XUiNode, "XUiGridShopCard")

local XUiComShopCardShow = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/Com/XUiComShopCardShow")
local XUiComShopSubCardShow = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/Com/XUiComShopSubCardShow")
local XUiCardDragHandler = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiCardDragHandler")
local XUiPunishaarCardValueTag = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarCardValueTag")
local CardBgSettingsReader = require("XModule/XPunishaar/SubModules/InGame/XPunishaarCardBgSettingsReader")

function XUiGridShopCard:OnStart()
    -- 单一 CardShow 实例挂 PanelNormal；禁用态改由 PnlDisable 半透明遮罩显隐表达（#71
    -- 弃用原 PanelDisable 整套重复节点 + 双实例喂两份数据的方案）
    if self.PanelNormal then
        ---@type XUiComShopCardShow
        self.CardShowNormal = XUiComShopCardShow.New(self.PanelNormal, self)
    end
    if self.PanelShopSubCard then
        ---@type XUiComShopSubCardShow
        self.SubCardShow = XUiComShopSubCardShow.New(self.PanelShopSubCard, self)
        -- 初始化默认隐藏（走 Close 而非 SetActiveEx：XUiNode 实例须 Close 隐藏，置 _IsNodeShow=false，
        -- 防框架 EnableChildNodes 自动重激活旧子面板；见 memory xluaui_close_vs_remove_stack）：
        -- 战斗区/背包暂存区的主卡（装备态 RefreshAsEquipped 不碰此节点）防露出；
        -- 商品栏由 Refresh 互斥控制覆盖（副卡商品 Open / 主卡商品 Close，见 :131-150）。
        self.SubCardShow:Close()
    end

    if self.BtnClick then
        -- 点击卡牌打开主卡详情 Tips（商品态→Buy / 装备态→Sell/Discard；购买确认弹窗随 _OnBtnBuy 移除，
        -- 改由 Tips 内 BtnBuy 直接 BuyGoods，如需保留确认弹窗在 Tips._OnBtnBuy 内补）
        self.BtnClick:AddEventListener(handler(self, self._OnCardClick))
    end

    -- 外发光选中态事件订阅移到 OnEnable（与 OnDisable 对称，避免 grid Close→Open 后监听丢失）
    -- 升级动画播放事件订阅（BuySuccess 刷新后 GameControl 派发 LevelupAnimPlay，检查缓存匹配+清+播）#升级动画
    -- 注意：LevelupAnimPlay 在 GameControl 事件系统派发（_DoBuyGoodsFinal self:DispatchEvent），须 gc:AddEventListener 非 self._Control（根 Control）
    local gc = self._Control.GameControl
    if gc then
        gc:AddEventListener(gc.ShopEventId.LevelupAnimPlay, self._OnLevelupAnimPlay, self)
    end

    -- 根节点数值标签（TagDamage/TagCD，atk/cd 计算归根节点避免子→父上行访问 #79）
    if self.TagDamage then
        ---@type XUiPunishaarCardValueTag
        self.TagDamageInst = XUiPunishaarCardValueTag.New(self.TagDamage, self)
    end
    if self.TagCD then
        ---@type XUiPunishaarCardValueTag
        self.TagCDInst = XUiPunishaarCardValueTag.New(self.TagCD, self)
    end

    -- 默认正常态（走 Open/Close 而非 SetActiveEx，触发对应 CardShow 的 OnEnable 补刷惰性数据）
    self:SetDisable(false)
end

function XUiGridShopCard:OnEnable()
    -- 选中态事件 OnEnable/OnDisable 对称注册注销（原 OnStart 注册+OnDisable 注销不对称，
    local EventId = self._Control.EventId
    self._Control:AddEventListener(EventId.CardOutlineSelect, self._OnOutlineSelect, self)
    self._Control:AddEventListener(EventId.CardOutlineDeselect, self._OnOutlineDeselect, self)
end

function XUiGridShopCard:OnDisable()
    local EventId = self._Control.EventId
    self._Control:RemoveEventListener(EventId.CardOutlineSelect, self._OnOutlineSelect, self)
    self._Control:RemoveEventListener(EventId.CardOutlineDeselect, self._OnOutlineDeselect, self)
    -- 隐藏时若仍在拖拽：强制归位并清会话。GO inactive 后 Unity 不再派发 EndDrag 回调，
    -- 不中断则节点永久滞留 DragRoot + 逻辑层拖拽会话残留致后续拖拽被 GetIsDraggingCard 拒。
    -- （销毁路径的 handler 清理见本文件已有的 OnDestroy，其内已调 _DragHandler:OnDestroy）
    if self._DragHandler then
        self._DragHandler:CancelDragIfDragging()
    end
end

--- SELECT 事件回调：非自己 → 隐外发光（单选，Tips 打开其他卡时隐当前）
function XUiGridShopCard:_OnOutlineSelect(transform)
    if self.Transform ~= transform then
        self:_SetOutlineSelected(false)
    end
end

--- DESELECT 事件回调：全隐（Tips 关闭）
function XUiGridShopCard:_OnOutlineDeselect()
    self:_SetOutlineSelected(false)
end

--- 显隐外发光选中态 + 设图（按 Type/Size 取 OutlineBgs）
--- RImgOutlineGroup/RImgOutline 在 CardShowNormal(ComShopCardShow) 子组件内，经 self.CardShowNormal 访问
---@param isSelected boolean
function XUiGridShopCard:_SetOutlineSelected(isSelected)
    local show = self.CardShowNormal
    if not show or not show.RImgOutlineGroup then
        return
    end
    if isSelected then
        local cardCfg = self._CardCfg
            or (self._Goods and self._Control:GetTablePunishaarCard(self._Goods.CardId, true))
            or (self._DragCardData and self._Control:GetTablePunishaarCard(self._DragCardData.TemplateId, true))
        if cardCfg then
            local gc = self._Control.GameControl
            local sprite = gc and CardBgSettingsReader.GetOutlineSprite(gc, cardCfg.Type, cardCfg.Size) or nil
            if sprite and show.RImgOutline then
                show.RImgOutline:SetRawImage(sprite)
            end
            show.RImgOutlineGroup.gameObject:SetActiveEx(sprite ~= nil)
        end
    else
        show.RImgOutlineGroup.gameObject:SetActiveEx(false)
    end
end

--- 切换正常态 / 禁用态：转发给 CardShow 控其内部 PnlDisable 半透明遮罩显隐（#71）。
--- 遮罩节点在 PanelNormal 子树内（与 GroupLevelup 同级），故归 CardShow 持有，grid 只转发。
--- 卡牌内容始终由唯一的 CardShowNormal 渲染，不再有双实例切换，故无"隐藏期置脏、切显补刷"问题。
--- 注意：当前装备栏 grid 的禁用态**仅由副卡宿主提示驱动**（拖副卡时不可作宿主的卡置灰、松手全量恢复
--- SetDisable(false)）。若将来 grid 新增其他置灰来源（如不可编队态），需区分来源、勿被"松手全量恢复"误清。
---@param isDisable boolean
function XUiGridShopCard:SetDisable(isDisable)
    -- 副卡商品无置灰（仅商店单独显示，其余依附主卡），跳过遮罩控制
    if self._IsSubCardGoods then
        return
    end
    if self.CardShowNormal then
        self.CardShowNormal:SetDisableMask(isDisable)
    end
end

---@param slot UnityEngine.RectTransform|XUiGridShopCardSlot|nil
---@return number|nil
function XUiGridShopCard:_GetSlotUnitWidth(slot)
    if not slot then
        return nil
    end
    local trans = slot.Transform or slot
    if not trans then
        return nil
    end
    return trans.sizeDelta.x
end

---@param unitWidth number|nil
---@param size number
function XUiGridShopCard:_ApplyWidthBySlot(unitWidth, size)
    if not unitWidth then
        return
    end
    self.Transform:SetSizeDeltaX(unitWidth * (size or 1))
end

--- 商品模式（来自 Server.XPunishaarGoods）
---@param goods table Server.XPunishaarGoods
---@param goodsIndex number 服务端槽位索引（0-based）
---@param slot XUiGridShopCardSlot|nil
function XUiGridShopCard:Refresh(goods, goodsIndex, slot)
    self._Goods = goods
    self._GoodsIndex = goodsIndex
    self._DragCardData = goods
    self._DragSourcePos = goodsIndex

    local isEmpty = not goods or goods.CardId == 0
            or not self._Control:GetTablePunishaarCard(goods.CardId, true)

    -- PanelCard/PanelBuy 为真实节点，空态隐藏卡内容（isEmpty 分支作为防御兜底保留）
    if self.PanelCard then
        self.PanelCard.gameObject:SetActiveEx(not isEmpty)
    end
    if self.PanelBuy then
        self.PanelBuy.gameObject:SetActiveEx(not isEmpty)
    end

    local unitWidth = self:_GetSlotUnitWidth(slot)
    if isEmpty then
        self:_ApplyWidthBySlot(unitWidth, 1)
        -- 空位：隐副卡显示 + 禁用 grid 拖拽（空位不可拖）
        if self.SubCardShow then
            self.SubCardShow:Close()
        end
        if self._DragHandler then
            self._DragHandler:SetEnabled(false)
        end
        self._IsSubCardGoods = false
        -- 空位隐数值标签 + 产球消球组（防 grid 复用残留 #79 #80）
        if self.TagDamageInst then
            self.TagDamageInst:Close()
        end
        if self.TagCDInst then
            self.TagCDInst:Close()
        end
        if self.CardShowNormal then
            self.CardShowNormal:SetBallGroupActive(false)
        end
        return
    end

    -- 商店冻结态已下沉到 CardShow head 的 ImgFrozen（弃用 PanelShopFreeze）#67
    if self.BtnClick then
        self.BtnClick:SetDisable(goods.IsBought == true)
    end

    local cardCfg = self._Control:GetTablePunishaarCard(goods.CardId)
    self:_ApplyWidthBySlot(unitWidth, cardCfg and cardCfg.Size or 1)

    local isSubCard = self._Control:IsSubCard(goods.CardId)
    self._IsSubCardGoods = isSubCard
    if isSubCard then
        -- 副卡商品：显 PanelShopSubCard（SubCardShow），隐主卡 CardShow；不喂主卡数据
        if self.SubCardShow then
            self.SubCardShow:Open()
            self.SubCardShow:Refresh(goods, goodsIndex)
        end
        if self.CardShowNormal then
            self.CardShowNormal:Close()
        end
        -- 遮罩随主卡内容一并隐（副卡商品无置灰态 #71）
        if self.CardShowNormal then
            self.CardShowNormal:SetDisableMask(false)
        end
        -- 副卡拖拽走 SubCardItem（UiPunishaarSubCard），禁用 grid 拖拽避免双拖拽源
        if self._DragHandler then
            self._DragHandler:SetEnabled(false)
        end
        -- 隐 grid top-level BtnClick（最高层级会遮挡 SubCardItem 拖拽/点击）；副卡点击走 SubCardItem 自身 BtnClick
        if self.BtnClick then
            self.BtnClick.gameObject:SetActiveEx(false)
        end
        -- 副卡不显主卡数值 + 产球消球组（防 grid 复用从主卡切副卡残留 #79 #80）
        if self.TagDamageInst then
            self.TagDamageInst:Close()
        end
        if self.TagCDInst then
            self.TagCDInst:Close()
        end
        if self.CardShowNormal then
            self.CardShowNormal:SetBallGroupActive(false)
        end
    else
        -- 主卡商品：隐 PanelShopSubCard，走主卡 CardShow 路径
        if self.SubCardShow then
            self.SubCardShow:Close()
        end
        if self._DragHandler then
            self._DragHandler:SetEnabled(true)
        end
        if self.BtnClick then
            self.BtnClick.gameObject:SetActiveEx(true)
        end
        -- 重新 Open CardShowNormal（对称副卡分支的 Close）：grid 复用从副卡切到主卡时，
        -- CardShowNormal 仍处副卡时 Close 态，不 Open 则主卡内容隐藏 #40
        if self.CardShowNormal then
            self.CardShowNormal:Open()
        end
        -- 商品态默认非置灰（遮罩复位，防 grid 复用残留 #71）
        self:SetDisable(false)
        if self.CardShowNormal then
            self.CardShowNormal:RefreshAsGoods(goods)
        end
        -- atk/cd 计算归根节点 Tag（商品态无 masterCard 走 base 无投影，current==config 恒 normal）#79
        self:_RefreshValueTags(goods.CardId, goods.Level, nil)
        -- 显产球消球组（主卡商品，对称副卡分支的隐 #80）
        if self.CardShowNormal then
            self.CardShowNormal:SetBallGroupActive(true)
        end
    end
    self:_RefreshPrice(goods)
end

--- 装备栏模式（来自 Server.XPunishaarMasterCard，不显示购买按钮）
---@param card table|nil Server.XPunishaarMasterCard
---@param size number|nil 卡牌格数（nil 按 1 处理）
---@param slot XUiGridShopCardSlot|nil
function XUiGridShopCard:RefreshAsEquipped(card, size, slot)
    self._Goods = nil
    self._GoodsIndex = nil
    self._DragCardData = card
    self._DragSourcePos = card and card.StartPos
    -- 装备态主卡非副卡商品，复位 _IsSubCardGoods（防 grid 复用时残留 #41）
    self._IsSubCardGoods = false

    self:_ApplyWidthBySlot(self:_GetSlotUnitWidth(slot), size or 1)

    if self.PanelBuy then
        self.PanelBuy.gameObject:SetActiveEx(false)
    end
    -- 装备态无商店冻结（冻结态已归 CardShow head 的 ImgFrozen，仅商品模式）#67

    local isEmpty = not card or card.TemplateId == 0
    -- PanelCard 空态隐藏卡内容（isEmpty 分支作为防御兜底保留）
    if self.PanelCard then
        self.PanelCard.gameObject:SetActiveEx(not isEmpty)
    end
    if isEmpty then
        if self.TagDamageInst then
            self.TagDamageInst:Close()
        end
        if self.TagCDInst then
            self.TagCDInst:Close()
        end
        if self.CardShowNormal then
            self.CardShowNormal:SetBallGroupActive(false)
        end
        return
    end

    -- 装备态从副卡商品态复用而来时 CardShowNormal 可能仍 Close，需重新 Open（对称 Refresh 副卡分支）
    if self.CardShowNormal then
        self.CardShowNormal:Open()
    end
    -- 遮罩复位为常态（置灰由容器随后按副卡宿主提示调 SetDisable 决定 #71）
    self:SetDisable(false)
    if self.CardShowNormal then
        self.CardShowNormal:RefreshAsEquipped(card)
    end
    -- atk/cd 计算归根节点 Tag（装备态传 masterCard 走投影 base+delta，delta≠0 显 up）#79
    self:_RefreshValueTags(card.TemplateId, card.Level, card)
    -- 显产球消球组（装备态主卡，对称空态的隐 #80）
    if self.CardShowNormal then
        self.CardShowNormal:SetBallGroupActive(true)
    end
    -- 升级动画播放改事件派发（LevelupAnimPlay 在 BuySuccess 刷新后派发，grid _OnLevelupAnimPlay 检查+清+播）
end

--- 当前 grid 渲染的装备态主卡（装备栏模式下有效；商品模式返回 nil）。
--- 供容器做副卡宿主置灰判定用，避免外部直接读 _DragCardData 私有字段（#75）。
---@return table|nil Server.XPunishaarMasterCard
function XUiGridShopCard:GetEquippedCard()
    return self._Goods == nil and self._DragCardData or nil
end

--- 显示购买价格：取 PunishaarCardSale.Buy，写 PanelBuy 子树的 TxtPrice 文本。
--- grid 的 BtnClick 是透明点击区（打开详情 + IsBought 置灰），不显价格不控制货币（#78 迁移：价格从 BtnClick group1 归 TxtPrice）。
--- 颜色差异化：金币不够取红色富文本模板、够取正常模板（策划在 ShopPriceText 配 <color> 标签，{0}=价格）#商品价格颜色
function XUiGridShopCard:_RefreshPrice(goods)
    if not self.TxtPrice then
        return
    end
    local cardCfg = self._Control:GetTablePunishaarCard(goods.CardId)
    if not cardCfg then
        self.TxtPrice.text = ""
        return
    end
    local saleKey = cardCfg.Type * 100 + cardCfg.Size * 10 + goods.Level
    local saleCfg = self._Control.GameControl:GetTablePunishaarCardSale(saleKey, true)
    if not saleCfg then
        self.TxtPrice.text = ""
        return
    end
    local price = saleCfg.Buy or 0
    local gold = self._Control:GetCurrentGold() or 0
    local fmt = self._Control:GetShopPriceText(gold >= price)
    
    if not string.IsNilOrEmpty(fmt) then
        self.TxtPrice.text = XUiHelper.FormatTextEx(fmt, tostring(price))
    else
        self.TxtPrice.text = tostring(price)
    end
end

--- 局部刷新价格显示（货币变动时容器遍历调，不重建列表）。转发 _RefreshPrice(self._Goods)。#商品价格颜色
function XUiGridShopCard:RefreshPrice()
    if self._Goods then
        self:_RefreshPrice(self._Goods)
    end
end

--- 刷根节点数值标签（TagDamage/TagCD）：atk/cd 计算归根节点（避免子→父上行访问，UI-Rule）。
--- current=base+delta（投影）；config=levelCfg 基础值。相等显 normal，否则显 up（delta≠0）。
---@param cardId number
---@param level number
---@param masterCard table|nil 装备态主卡（商品态 nil → 走 base 无投影，current==config 恒 normal）
function XUiGridShopCard:_RefreshValueTags(cardId, level, masterCard)
    if not self.TagDamageInst and not self.TagCDInst then
        return
    end
    -- 卡牌切换（grid 复用显示其他卡）或 cardId/level/masterCard 变：清 Tag 缓存 _LastCurrent，下次 Refresh 视 first 不播动画
    -- 只有同卡数值变换才播 Refresh 动画（跨卡切换数值不一致不播）#82
    if self._LastCardId ~= cardId or self._LastLevel ~= level or self._LastMasterCard ~= masterCard then
        if self.TagDamageInst then self.TagDamageInst:Clear() end
        if self.TagCDInst then self.TagCDInst:Clear() end
        self._LastCardId = cardId
        self._LastLevel = level
        self._LastMasterCard = masterCard
    end
    local levelCfg = self._Control:GetTablePunishaarCardLevel(cardId * 100 + level)
    if not levelCfg then
        if self.TagDamageInst then self.TagDamageInst:Clear() end
        if self.TagCDInst then self.TagCDInst:Clear() end
        return
    end
    local atkBase, atkDelta, cdBaseMs, cdDeltaMs
    local gc = self._Control.GameControl
    if masterCard and gc then
        local proj = gc:GetCardRealtimeAtkCd(masterCard.TemplateId, level, masterCard)
        atkBase, atkDelta = proj.atkBase, proj.atkDelta
        cdBaseMs, cdDeltaMs = proj.cdBaseMs, proj.cdDeltaMs
    else
        atkBase = levelCfg.ATK or 0
        atkDelta = 0
        cdBaseMs = levelCfg.CD or 0
        cdDeltaMs = 0
    end
    if self.TagDamageInst then
        local atkCur = atkBase + atkDelta
        self.TagDamageInst:Open()
        self.TagDamageInst:Refresh(atkCur, atkBase, tostring(math.floor(atkCur)))
    end
    if self.TagCDInst then
        local cdCur = (cdBaseMs + cdDeltaMs) / 1000

        -- 转换成秒显示的时候需要同时满足保留1位小数和向下取整
        cdCur = cdCur * 10
        cdCur = math.floor(cdCur)
        cdCur = cdCur / 10
        
        local cdCfg = cdBaseMs / 1000
        self.TagCDInst:Open()
        self.TagCDInst:Refresh(cdCur, cdCfg, string.format("%.1f", cdCur))
    end
end

--- 点击卡牌打开主卡详情 Tips。按 _Goods 是否 nil 区分商品/装备态传不同 data；
--- posUi 取 _PickDetailRoot 选出的锚点（背包区有 Left/Right 时 x-flip，否则单 DetailRoot）。
function XUiGridShopCard:_OnCardClick()
    local host = self:_GetTipsHost()
    if not host then
        return
    end
    if not host then
        return
    end
    local posUi = self:_PickDetailRoot(host)
    if self._Goods then
        -- 商品态：goods 不携带 GoodsIndex（容器单独传入存于 self._GoodsIndex），构造 tipsData 补上
        local goods = self._Goods
        local tipsData = {
            CardId = goods.CardId,
            Level = goods.Level,
            GoodsIndex = self._GoodsIndex,
            IsBought = goods.IsBought,
            Frozen = goods.Frozen,
        }
        -- 副卡商品 → 副卡详情；主卡商品 → 主卡详情
        if self._Control:IsSubCard(goods.CardId) then
            host:ShowSubCardTips(tipsData, posUi)
        else
            host:ShowMainCardTips(tipsData, posUi)
        end
    elseif self._DragCardData then
        -- 装备态：_DragCardData 即 Server.XPunishaarMasterCard（必为主卡；副卡非 MasterCard 不入装备态 grid）
        host:ShowMainCardTips(self._DragCardData, posUi)
    end
    -- 派发选中事件（通知其他 grid 隐外发光，自己显）
    self._Control:DispatchEvent(self._Control.EventId.CardOutlineSelect, self.Transform)
    self:_SetOutlineSelected(true)
end

--- 选详情浮窗定位锚点。
--- 背包区 prefab 提供 DetailRootLeft/Right → x-flip：卡牌中心偏离屏幕中心超过半个卡牌宽才翻向，
--- band 内（大致居中）默认 Right（符合习惯）；否则走单 DetailRoot（商品/对战区，prefab 摆下/上方）。
---@param host table 持有 ShowMainCardTips 的宿主（FightMain，提供 TipsRoot 壳中心）
---@return UnityEngine.RectTransform
function XUiGridShopCard:_PickDetailRoot(host)
    if self.DetailRootLeft and self.DetailRootRight then
        local cardCenterX = self.Transform.position.x
        local shellCenterX = (host.TipsRoot and host.TipsRoot.Transform.position.x) or cardCenterX
        local halfCardW = (self.Transform.sizeDelta.x or 0) * 0.5
        local diff = cardCenterX - shellCenterX
        if diff < -halfCardW then
            return self.DetailRootRight   -- 卡牌整体偏左 → 气泡右侧展开
        end
        if diff > halfCardW then
            return self.DetailRootLeft    -- 卡牌整体偏右 → 气泡左侧展开
        end
        return self.DetailRootRight       -- band 内默认右
    end
    return self.DetailRoot or self.Transform
end

--- 沿 Parent 链上溯找持有 ShowMainCardTips 的宿主（FightMain）。各容器层级不一，故走通用上溯。
---@return table|nil
function XUiGridShopCard:_GetTipsHost()
    local p = self.Parent
    while p do
        if p.ShowMainCardTips then
            return p
        end
        p = p.Parent
    end
    return nil
end

---@param gridSlot XUiGridShopCardSlot
function XUiGridShopCard:RefreshPosition(gridSlot)
    local posX, posY, posZ = gridSlot.Transform:GetPosition()
    self.Transform:SetPosition(posX, posY, posZ)
    -- SetPosition 改变了 localPosition，同步更新拖拽归位快照（handler 持有），防止拖拽后归位回错误坐标
    if self._DragHandler then
        self._DragHandler:UpdateSnapshot()
    end
end

--region 拖拽（Theatre5 假拖拽，委托 XUiCardDragHandler）

--- 由容器调用开启拖拽能力，声明来源区域。幂等：重复调只更新 area（机制 init 一次）。
--- 拖拽机制（XGoInputHandler 三阶段/CanvasGroup/归位快照/保底定时器）由 XUiCardDragHandler 持有；
--- host 持 _DragArea/_DragCardData/_DragSourcePos 供 handler + 落点共用。
---@param dragArea number Control.DragArea：Shop / FightArea / Bag
function XUiGridShopCard:EnableDrag(dragArea)
    self._DragArea = dragArea
    if not self._DragHandler then
        self._DragHandler = XUiCardDragHandler.New(self)
    end
    self._DragHandler:Enable()
    -- 首次初始化后按当前 _IsSubCardGoods 决定 enabled：副卡商品禁用 grid 拖拽
    -- （PanelTopShop 调用顺序 Refresh→EnableDrag，Refresh 时 _DragHandler 尚 nil 致 SetEnabled 跳过 #41）
    if self._IsSubCardGoods then
        self._DragHandler:SetEnabled(false)
    end
end

--endregion

--region 落点（副卡装配：主卡 grid 自身作落点，解决主卡 Image 拦截下方 slot 的 XUguiEventListener 致 focus 设不上 #36）

--- 由容器调用开启落点能力（副卡拖拽释放于此主卡→装配）。只需调一次（幂等）。
--- 用 XUguiEventListener OnEnter/Exit 联动 Control 焦点（对称 XUiGridShopCardSlot.EnableAsDropZone）。
--- OnEnter 用当前 _DragCardData.StartPos（装备态主卡位置）+ _DragArea（本卡所在区域），防卡牌移动后 stale。
function XUiGridShopCard:EnableAsDropZone()
    -- 栏级反算接管落点，旧单格 PointEnter 暂注释 #批次2（保留以备回退）
    --[[
    if self._DropInited then
        return
    end
    self._DropInited = true
    local com = self.GameObject:GetComponent(typeof(CS.XUguiEventListener))
    if XTool.UObjIsNil(com) then
        com = self.GameObject:AddComponent(typeof(CS.XUguiEventListener))
    end
    com.OnEnter = handler(self, self._OnDropPointerEnter)
    com.OnExit = handler(self, self._OnDropPointerExit)
    --]]
end

function XUiGridShopCard:_OnDropPointerEnter()
    if self._Control.GameControl:GetIsDraggingCard() then
        -- 主卡拖拽时 blocksRaycasts=false，Card 的 OnEnter 不触发（靠 Slot 报精确格位 #52）
        -- 副卡拖拽（Shop 来源）时 blocksRaycasts=true，Card.OnEnter 作 #36 落点（GetMasterCardByAreaPos 反查宿主）
        local pos = self._DragCardData and self._DragCardData.StartPos
        if pos and self._DragArea then
            self._Control.GameControl:SetDragFocusTarget(self._DragArea, pos)
        end
    end
end

function XUiGridShopCard:_OnDropPointerExit()
    if self._Control.GameControl:GetIsDraggingCard() then
        self._Control.GameControl:ClearDragFocusTarget()
    end
end

--- 切换 CanvasGroup.blocksRaycasts（主卡拖拽时关 false 让 Slot 射线穿透报精确格位 #52）
---@param value boolean
function XUiGridShopCard:SetBlocksRaycasts(value)
    if self._DragHandler then
        self._DragHandler:SetBlocksRaycasts(value)
    end
end

--endregion

function XUiGridShopCard:OnDestroy()
    if self._DragHandler then
        self._DragHandler:OnDestroy()
    end
    local gc = self._Control and self._Control.GameControl
    if gc then
        gc:RemoveEventListener(gc.ShopEventId.LevelupAnimPlay, self._OnLevelupAnimPlay, self)
    end
end

--- LevelupAnimPlay 事件回调：BuySuccess 刷新后派发，同步先检查缓存匹配当前卡 → 再清缓存 + 播升级动画。
--- 替代 ScheduleOnce 延迟（回调时间不可控）：事件派发在 BuySuccess 同步刷新完成后，grid 已重建 Open + 新 card。
--- 装备态 grid（_DragCardData 是 MasterCard 有 TemplateId+Level）匹配播；商品态 grid（goods 无 TemplateId）不匹配跳过。
function XUiGridShopCard:_OnLevelupAnimPlay()
    local gc = self._Control and self._Control.GameControl
    local pendingTid = gc and gc._PendingLevelupAnimTemplateId
    local pendingLevel = gc and gc._PendingLevelupAnimLevel
    local card = self._DragCardData
    if not pendingTid then return end  -- 无缓存（非升级购买）跳过
    if not card or not card.TemplateId then return end
    -- 同步先检查（匹配）再清缓存（一次性，防多 grid 重复播）
    if card.TemplateId == pendingTid and card.Level == pendingLevel then
        gc._PendingLevelupAnimTemplateId = nil
        gc._PendingLevelupAnimLevel = nil
        if self.CardShowNormal then
            self.CardShowNormal:OnLevelupEvent()
        end
    end
end

return XUiGridShopCard
