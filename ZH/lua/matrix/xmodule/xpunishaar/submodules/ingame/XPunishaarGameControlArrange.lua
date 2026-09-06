--- Control部分类（编排 partial，#72 从 Shop.lua 抽离）。
--- 承载：编排策略链框架（ArrangeDomain + _ArrangeStrategies 注册表 + _SelectArrangeStrategy）
---   + 编排提交入口（_SubmitCardPosList / _BuildCardPosList，复用 buffer）
---   + 编排算法层（找位/repack/升级链预判，self 不变行为零变化）
---   + 编排辅助（ctx 构造/可行性判定/reject tip）
---   + 公开编排方法（InsertCard / BuyGoods / MoveCard，签名不变）
---   + 奖励入位骨架（ArrangeRewardCard，#72 新增，复用编排策略链）
--- self 不变（仍是 GameControl 实例），跨 partial 同类调用 self:Method() 直达，无 self._Control 跳转、无性能损耗。
local XList = require("XCommon/XList")
local XDictionary = require("XCommon/XDictionary")

local XPunishaarGameControl = XClassPartial('XPunishaarGameControl')

--region ----------编排策略链框架（domain + 注册表 + 选择器）#72----------

-- 编排策略适用域（#72 domain 硬隔离：购买域无互换能力，满区即拒；编排域含 Swap 互换）
local ArrangeDomain = {
    Buy = 0,
    Arrange = 1,
    Sell = 2,
}
XPunishaarGameControl.ArrangeDomain = ArrangeDomain

--endregion

--region ----------编排提交入口（复用 buffer）#72----------

--- 编排提交统一入口：包装 DoSetCardPos + 成功派发 BuySuccess + cb（#72-B 消除 InsertCard/MoveCard 提交段重复）。
--- 缓冲区引用安全（#72 精审 G3）：cardPosList 是 self._CardPosListBuffer 引用，DoSetCardPos 调
---   XNetwork.Call("XPunishaarSetCardPosRequest", { CardPosList = cardPosList }, cb) **同步 marshal** ——
---   调用内立即把 cardPosList 的 Id/AreaType/StartPos 标量序列化进 C# 请求体，C# 不持 Lua table/元素引用，
---   网络发包不依赖调用后 Lua table 状态，故 buffer 引用对 C# send 安全，无需拷贝。
---   回调闭包内 Model:UpdateCardPositions(cardPosList) 读 buffer 的副作用：受 NetworkLockFlagEnum.SetCardPos
---   拒并发提交 + 单线程下回包（ms 级）远快于玩家下次拖拽（秒级）保护，无实际别名 race。
---@param cardPosList table[{Id,AreaType,StartPos}] 全量位置快照（由策略构建，复用 _CardPosListBuffer）
---@param cb function(success: boolean)|nil
function XPunishaarGameControl:_SubmitCardPosList(cardPosList, cb)
    XMVCA.XPunishaar.NetworkAgency:DoSetCardPos(cardPosList, function(success)
        if success then
            self:DispatchEvent(self.ShopEventId.BuySuccess)
        end
        if cb then
            cb(success)
        end
    end)
end

--- 全量位置快照构建辅助：遍历 TotalMasterCards 输出 {Id,AreaType,StartPos}，复用 self._CardPosListBuffer
--- （元素 table 复用：清旧+按需扩容，与 _TgtCardsList/_SizeCacheDict 范式对齐，#72 6.3-3）。
--- applyFn 由调用方按策略算出的新位覆盖 entry.AreaType/StartPos（如 newPosMap 命中/Swap 互换/MoveCard 单卡改位）。
---@param applyFn function(card, entry)|nil 命中需改位时填 entry 字段
---@return table cardPosList（self._CardPosListBuffer 引用）
function XPunishaarGameControl:_BuildCardPosList(applyFn)
    if not self._CardPosListBuffer then
        self._CardPosListBuffer = {}
    end
    local buf = self._CardPosListBuffer
    -- 清旧键（手算 for-k nil，避免上轮残留）
    for k in pairs(buf) do
        buf[k] = nil
    end
    local stage = self._Model:GetCurrentStage()
    local cards = stage and stage.TotalMasterCards
    local idx = 0
    if cards then
        for _, card in pairs(cards) do
            idx = idx + 1
            local entry = buf[idx]
            if not entry then
                entry = { Id = 0, AreaType = 0, StartPos = 0 }
                buf[idx] = entry
            end
            entry.Id = card.Id
            entry.AreaType = card.AreaType
            entry.StartPos = card.StartPos
            if applyFn then
                applyFn(card, entry)
            end
        end
    end
    -- 清超出本次使用的尾部残留（buf 可能上轮更长，防别名残留 #72 6.3-3）
    for i = idx + 1, #buf do
        buf[i] = nil
    end
    return buf
end

--endregion

--region ----------编排算法层（找位/repack/升级链预判）----------

--- 取目标区已解锁槽位数（stage.*GridLimit；落点容器把含锁定在内的全槽注册为 drop zone，故 dropPos 可能 > gridLimit 落在锁定槽上）。
---@param targetArea number CardAreaType
---@return number
function XPunishaarGameControl:_GetAreaGridLimit(targetArea)
    local stage = self._Model:GetCurrentStage()
    if not stage then
        return 0
    end
    local CardAreaType = XMVCA.XPunishaar.EnumConst.CardAreaType
    return targetArea == CardAreaType.FightArea
            and (stage.FightAreaGridLimit or 0)
            or (stage.BagGridLimit or 0)
end

--- 按区域 + 格位反查占据该格的主卡（主卡 Size≥2 占多格：StartPos..StartPos+Size-1）。
--- 用于副卡拖拽落点：落到某格 → 反查该格的主卡作为宿主候选。占格算法与 _FindPlacementForDirectBuy 一致。
---@param cardAreaType number CardAreaType（FightArea/Bag）
---@param startPos number 落点格位（1-based）
---@return table|nil 占据该格的主卡（Server.XPunishaarMasterCard），无则 nil
function XPunishaarGameControl:GetMasterCardByAreaPos(cardAreaType, startPos)
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.TotalMasterCards then
        return nil
    end
    for _, card in pairs(stage.TotalMasterCards) do
        if card.AreaType == cardAreaType then
            local cfg = self:GetTablePunishaarCard(card.TemplateId, true)
            local size = cfg and cfg.Size or 1
            if startPos >= card.StartPos and startPos < card.StartPos + size then
                return card
            end
        end
    end
    return nil
end

--- 判定某副卡是否可装配到指定主卡上（宿主合法性三条判据全满足）。
--- 供拖拽落点校验 / 主卡格置灰判定共用。判空保护齐全，数据/配置缺失一律安全返回 false。
--- 判据：1) masterCard 存在且是主卡；2) 副卡与主卡类型匹配。
--- （旧判据2"未携带副卡"已放宽 #51：已有副卡可替换装配，二次确认由 _DropAction_Buy 弹窗处理）
---@param subCardId number 拖拽/购买的副卡模板 Id
---@param masterCard table|nil 目标宿主主卡（Server.XPunishaarMasterCard），空位传 nil
---@return boolean
function XPunishaarGameControl:CanMountSubCardOnMaster(subCardId, masterCard)
    -- 空位：无卡可作宿主
    if not masterCard then
        return false
    end
    -- 判据1：目标必须是主卡
    if not self:GetControl():IsMasterCard(masterCard.TemplateId) then
        return false
    end
    -- 判据2（旧"未携带副卡"已删 #51）：已有副卡的主卡也允许（替换装配，由调用方二次确认）
    -- 判据3：类型匹配（意识→角色 / 共鸣→武器）
    local subCfg = self:GetTablePunishaarCard(subCardId, true)
    local masterCfg = self:GetTablePunishaarCard(masterCard.TemplateId, true)
    if not subCfg or not masterCfg then
        return false
    end
    return XMVCA.XPunishaar:IsSubCardTypeMatchMaster(subCfg.Type, masterCfg.Type)
end

--- 在指定区域寻找能容纳 size 格的起始位置（构建该区占格集 + 扫描）。
--- 复用 _OccupiedFightDict/_OccupiedBagDict（lazy init + Clear），零热路径分配。
---@param areaType number CardAreaType
---@param size number 卡占格数
---@return number|nil 起始格位，无空位返回 nil
function XPunishaarGameControl:_FindFreePosInArea(areaType, size)
    local stage = self._Model:GetCurrentStage()
    if not stage then
        return nil
    end
    local limit = self:_GetAreaGridLimit(areaType)

    -- 构建目标区已占用格子集合（XDictionary 复用，lazy init + Clear）
    if not self._OccupiedFightDict then
        self._OccupiedFightDict = XDictionary.New()
    end
    if not self._OccupiedBagDict then
        self._OccupiedBagDict = XDictionary.New()
    end
    local occupied = areaType == XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea
            and self._OccupiedFightDict or self._OccupiedBagDict
    occupied:Clear()

    local cards = stage.TotalMasterCards
    if cards then
        for _, card in pairs(cards) do
            if card.AreaType == areaType then
                local cfg = self:GetTablePunishaarCard(card.TemplateId, true)
                local cardSize = cfg and cfg.Size or 1
                for i = card.StartPos, card.StartPos + cardSize - 1 do
                    occupied:SetValueByKey(i, true)
                end
            end
        end
    end

    for pos = 1, limit - size + 1 do
        local fits = true
        for i = pos, pos + size - 1 do
            if occupied:ContainsKey(i) then
                fits = false;
                break
            end
        end
        if fits then
            return pos
        end
    end
    return nil
end

--- 判定落点范围 [startPos, startPos+size-1] 是否被任意已存在主卡占据。
--- 用于拖拽购买精确落点前的"位置重叠"预判，避免服务端返回"卡牌位置重叠"错误码。
---@param areaType number CardAreaType
---@param startPos number 落点起始格（1-based）
---@param size number 卡占格数
---@return boolean true=有重叠（不可放）
function XPunishaarGameControl:_IsDropPosOccupied(areaType, startPos, size)
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.TotalMasterCards then
        return false
    end
    local endPos = startPos + size - 1
    for _, card in pairs(stage.TotalMasterCards) do
        if card.AreaType == areaType then
            local cfg = self:GetTablePunishaarCard(card.TemplateId, true)
            local cardSize = cfg and cfg.Size or 1
            local cardEnd = card.StartPos + cardSize - 1
            -- 区间重叠：max(start1, start2) <= min(end1, end2)
            if math.max(startPos, card.StartPos) <= math.min(endPos, cardEnd) then
                return true
            end
        end
    end
    return false
end

--- 判定 [startPos, startPos+size-1] 范围内是否无"其他卡"占据（排除 excludeIds 集合的卡，供紧凑推移 B 新位合法性校验）。
--- 与 _IsDropPosOccupied 区别：后者判任意卡占（含 D/B 原位），本函数排除将移走的 D/B，避免误判 B 新位与 D/B 原位重叠。
---@param areaType number CardAreaType
---@param startPos number 起始格（1-based）
---@param size number 占格数
---@param excludeIds table|nil {[cardId]=true} 排除的卡 Id 集合
---@return boolean true=范围空闲（无其他卡占据，可落）
function XPunishaarGameControl:_IsSlotRangeFree(areaType, startPos, size, excludeIds)
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.TotalMasterCards then
        return true
    end
    local endPos = startPos + size - 1
    for _, card in pairs(stage.TotalMasterCards) do
        if card.AreaType == areaType and not (excludeIds and excludeIds[card.Id]) then
            local cfg = self:GetTablePunishaarCard(card.TemplateId, true)
            local cardSize = cfg and cfg.Size or 1
            local cardEnd = card.StartPos + cardSize - 1
            if math.max(startPos, card.StartPos) <= math.min(endPos, cardEnd) then
                return false
            end
        end
    end
    return true
end

--- 为直接购买的卡牌在局内找放置位置（优先对战区，其次背包）。
--- 返回 XPunishaarRewardCardDetailInfo 结构体，无空位返回 nil。
---@param cardId number 卡牌模板 Id
---@return table|nil { AreaType, StartPos, SubCardId=0, MasterCardId=0 }
function XPunishaarGameControl:_FindPlacementForDirectBuy(cardId)
    local cardCfg = self:GetTablePunishaarCard(cardId, true)
    local size = cardCfg and cardCfg.Size or 1
    local fightPos = self:_FindFreePosInArea(XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea, size)
    if fightPos then
        return { AreaType = XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea, StartPos = fightPos, SubCardId = 0, MasterCardId = 0 }
    end
    local bagPos = self:_FindFreePosInArea(XMVCA.XPunishaar.EnumConst.CardAreaType.Bag, size)
    if bagPos then
        return { AreaType = XMVCA.XPunishaar.EnumConst.CardAreaType.Bag, StartPos = bagPos, SubCardId = 0, MasterCardId = 0 }
    end
    return nil
end

--- 【临时方案】为购买的副卡寻找宿主主卡：取第一个尚未携带副卡的主卡自动装配。
--- 返回 XPunishaarRewardCardDetailInfo（MasterCardId 指向宿主主卡），无可装配主卡返回 nil。
--- 正式方案应由玩家手动指定宿主，见待办；此处仅为跑通购买+装配链路。
---@return table|nil { AreaType=nil, StartPos=0, SubCardId=0, MasterCardId=宿主主卡Id }
function XPunishaarGameControl:_FindHostForSubCardBuy()
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.TotalMasterCards then
        return nil
    end

    -- 第一个"是主卡且未携带副卡"的持有卡作为宿主
    for _, card in pairs(stage.TotalMasterCards) do
        if self:GetControl():IsMasterCard(card.TemplateId)
                and (not card.SubCardId or card.SubCardId == 0) then
            return { StartPos = 0, SubCardId = 0, MasterCardId = card.Id }
        end
    end
    return nil
end

--- 落点合法性校验 + 拒绝提示（锁定槽 / 越解锁边界），供 InsertCard（移动）与 BuyGoods（拖拽精确购买主卡）共用。
--- rejectOverflow=false 时只拒锁定槽（N≥1 移动用——overflow 交 _RepackInsert 可能左推重定位，不在此拒）；
--- rejectOverflow=true 时锁定+越界都拒（卡须落 dropPos、无 repack 重定位场景：N=0 移动 / 拖拽精确购买主卡）。
---@param dropPos number 落点格（1-based）
---@param dSize number 卡占格数
---@param gridLimit number 目标区已解锁槽位数（_GetAreaGridLimit）
---@param cb function|nil
---@param rejectOverflow boolean
---@return boolean true=合法可继续；false=已拒绝（已 Tip+cb(false)）
function XPunishaarGameControl:_RejectDropPosIfInvalid(dropPos, dSize, gridLimit, cb, rejectOverflow)
    local tipKey
    if dropPos > gridLimit then
        tipKey = "PunishaarDropPosLocked"
    elseif rejectOverflow and dropPos + dSize - 1 > gridLimit then
        tipKey = "PunishaarDropPosOverflow"
    end
    if tipKey then
        local tip = XMVCA.XPunishaar:GetClientStringByKey(tipKey)
        if not string.IsNilOrEmpty(tip) then
            XUiManager.TipMsg(tip)
        end
        if cb then
            cb(false)
        end
        return false
    end
    return true
end

--- 准备 repack 上下文：构造目标区卡列表 + sizeCache + insertIdx + gridLimit + newPosMap（成员复用，零 per-call GC）。
--- InsertCard（移动，excludedId=D.Id）与 _ComputeBuyRepack（购买，excludedId=nil 新卡不在 TotalMasterCards）共用。
---@param targetArea number CardAreaType
---@param dropPos number 落点格（1-based）
---@param excludedId any|nil 排除的卡 Id（移动=D.Id；购买=nil 新卡不在列表）
---@return table|nil ctx {tgtCards, sizeCache, insertIdx, gridLimit, newPosMap}；stage 无 TotalMasterCards 返回 nil
function XPunishaarGameControl:_PrepareRepackCtx(targetArea, dropPos, excludedId, allowBackInsert)
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.TotalMasterCards then
        return nil
    end
    if not self._TgtCardsList then
        self._TgtCardsList = XList.New()
    end
    if not self._SizeCacheDict then
        self._SizeCacheDict = XDictionary.New()
    end
    if not self._NewPosMapDict then
        self._NewPosMapDict = XDictionary.New()
    end
    local tgtCards = self._TgtCardsList
    local sizeCache = self._SizeCacheDict
    local newPosMap = self._NewPosMapDict
    tgtCards:Clear()
    sizeCache:Clear()
    newPosMap:Clear()

    for _, card in pairs(stage.TotalMasterCards) do
        if card.AreaType == targetArea and card.Id ~= excludedId then
            tgtCards:Append(card)
            local sz = (self:GetTablePunishaarCard(card.TemplateId, true) or {}).Size or 1
            sizeCache:SetValueByKey(card.Id, sz)
        end
    end
    tgtCards:Sort(function(a, b)
        return a.StartPos < b.StartPos
    end)

    -- dropPos→insertIdx：dropPos 落某卡占格内→D 插其前(前插)或后(后插，按 dropPos 相对卡中点 #127)
    -- allowBackInsert=true 时多格卡偏右落点后插(D插卡后)；偏左/单格/不允许→前插(D插卡前)；Buy 域传 false 保购买前插
    local insertIdx = tgtCards:GetCount() + 1
    for i = 1, tgtCards:GetCount() do
        local card = tgtCards:GetValueByIndex(i)
        local cardSize = sizeCache:GetValueByKey(card.Id) or 1
        if dropPos < card.StartPos + cardSize then
            -- dropPos 落 card 占格 [StartPos, StartPos+cardSize-1] 内
            if allowBackInsert and cardSize > 1
                and dropPos * 2 > card.StartPos * 2 + cardSize - 1 then
                insertIdx = i + 1  -- 偏右后插(D 插 card 后)
            else
                insertIdx = i  -- 偏左前插 / 单格 / 不允许后插
            end
            break
        end
    end

    return {
        tgtCards = tgtCards,
        sizeCache = sizeCache,
        insertIdx = insertIdx,
        gridLimit = self:_GetAreaGridLimit(targetArea),
        newPosMap = newPosMap,
    }
end

--- 插入式编排：拖卡 D 到 dropPos，统一 repack 找位（优先右推→不够左推→仍不够拒不插入 #58）。
--- 客户端算 layout → 全量 cardPosList 提交 SetCardPos（无 insert 协议，服务端只校验最终布局）。
--- 规则：①dropPos→insertIdx 映射（落点卡前半段前插/后半段后插/落空格末尾入）
--- ②同区 D 回原位 no-op 不发包 ③repack 后无位置变化 no-op 不发包
--- ④跨区源区留间隙（不主动紧凑源区）⑤容量超拒不自动溢出（锁定槽/越解锁边界/真·区域满 三种文案区分）⑥MoveCard 保留（button 路径用）
--- 不变量：同区总能找到 repack 方案（前段紧凑后必能让出空间），新卡（跨区/新购）才可能拒，no-op 不发包。
---@param masterCardId number 拖拽的主卡唯一 Id
---@param targetArea number CardAreaType 目标区域
---@param dropPos number 落点格（1-based）
---@param cb function(success: boolean)
---@param direction number|nil 1=右拖先右推；-1=左拖先左推；nil=先右推（旧序，§7 透传 _RepackInsert）
function XPunishaarGameControl:InsertCard(masterCardId, targetArea, dropPos, cb, direction)
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.TotalMasterCards then
        if cb then
            cb(false)
        end
        return
    end
    local D = stage.TotalMasterCards[masterCardId]
    if not D then
        if cb then
            cb(false)
        end
        return
    end

    local srcArea = D.AreaType
    local dCfg = self:GetTablePunishaarCard(D.TemplateId, true)
    local dSize = (dCfg and dCfg.Size) or 1
    local dOrigStartPos = D.StartPos

    -- 前置 no-op：同区 D 回原位（dropPos == D 原起点）→ 不发包（精确等值，size>1 自身占格内位移非 no-op）
    if srcArea == targetArea and dropPos == dOrigStartPos then
        if cb then
            cb(false)
        end
        return
    end

    -- repack 上下文（公共 _PrepareRepackCtx：tgtCards/sizeCache/insertIdx/gridLimit/newPosMap，移除 D）
    local ctx = self:_PrepareRepackCtx(targetArea, dropPos, masterCardId, true)  -- allowBackInsert=true（Move 路径支持后插 #127）
    if not ctx then
        if cb then
            cb(false)
        end
        return
    end
    local tgtCards = ctx.tgtCards
    local insertIdx = ctx.insertIdx
    local gridLimit = ctx.gridLimit
    local newPosMap = ctx.newPosMap

    if tgtCards:GetCount() == 0 then
        -- N=0 短路：目标区移除 D 后为空（仅 D 一张或跨区拖入空区），D 直接落 dropPos，跳过 _RepackInsert。
        -- 卡须落 dropPos、无 repack 重定位 → 锁定槽/越界都拒（rejectOverflow=true）。
        -- 必要性：放不下时须拒"此处放不下"，不能 fall-through 到 _RepackInsert 左推 fallback（那会把 D 重定位 pos1，违落点意图）。
        if not self:_RejectDropPosIfInvalid(dropPos, dSize, gridLimit, cb, true) then
            return
        end
        -- 同区 D 回原位（dropPos==dOrigStartPos）已由前置 no-op 兜底；走到此处的同区场景 dropPos≠原位 → D 移到 dropPos，仅 D 入 map，后置 no-op 不触发（count=1）。
        newPosMap:SetValueByKey(D.Id, dropPos)
    else
        -- N≥1：锁定槽拒（dropPos 在锁定槽不重定位，给明确反馈）；overflow 交 _RepackInsert 可能左推重定位，不在此拒（rejectOverflow=false）。
        if not self:_RejectDropPosIfInvalid(dropPos, dSize, gridLimit, cb, false) then
            return
        end
        local ok = self:_RepackInsert(tgtCards, insertIdx, D.Id, dSize, dOrigStartPos, dropPos,
                srcArea, targetArea, gridLimit, newPosMap, direction)
        if not ok then
            XUiManager.TipMsg(XMVCA.XPunishaar:GetClientStringByKey("BagFullWhenInsert"))
            if cb then
                cb(false)
            end
            return
        end
    end

    -- 后置 no-op：同区且无位置变化 → 不发包（D 回原位且他卡未动）
    if srcArea == targetArea and newPosMap:GetCount() == 0 then
        if cb then
            cb(false)
        end
        return
    end

    -- 构建全量 cardPosList（newPosMap 中的卡 area=targetArea+新位，其余原位；源区留间隙不左移）
    -- 复用 _CardPosListBuffer（#72 提交段统一入口）
    local cardPosList = self:_BuildCardPosList(function(card, entry)
        if newPosMap:ContainsKey(card.Id) then
            entry.AreaType = targetArea
            entry.StartPos = newPosMap:GetValueByKey(card.Id)
        end
    end)

    self:_SubmitCardPosList(cardPosList, cb)
end

--- 拖拽购买主卡精确落点冲突时，repack 算被推开卡的新位置 → CardPosList（BuyGoods.CardDetail.CardPosList 用）。
--- 复用 _PrepareRepackCtx + _RepackInsert，新卡用哨兵 Id=0（不在 TotalMasterCards，过滤哨兵得被推开卡）。
--- srcArea 用哨兵 -1（≠任何 CardAreaType）使 _RepackInsert 内 srcArea==targetArea 判断 false，D(哨兵)总入 map 后过滤。
---@param targetArea number CardAreaType
---@param dropPos number 落点格（1-based）
---@param dSize number 新卡占格数
---@return table|nil cardPosList [{Id, AreaType, StartPos}]；nil=repack 失败（区域满放不下）或目标区空无冲突
function XPunishaarGameControl:_ComputeBuyRepack(targetArea, dropPos, dSize)
    local ctx = self:_PrepareRepackCtx(targetArea, dropPos, nil, false)  -- excludedId=nil（新卡不在 TotalMasterCards）+ allowBackInsert=false（购买保前插 #127）
    if not ctx then
        return nil
    end
    if ctx.tgtCards:GetCount() == 0 then
        return nil  -- 目标区空，无冲突，新卡直落 dropPos（BuyGoods 不带 CardPosList）
    end
    local ok = self:_RepackInsert(ctx.tgtCards, ctx.insertIdx, 0, dSize, 0, dropPos,
            -1, targetArea, ctx.gridLimit, ctx.newPosMap, 0)  -- direction=0 右推优先（购买精确落点，零回归）
    if not ok then
        return nil  -- repack 失败（区域满放不下）
    end
    -- 左推 fallback 会把 D(哨兵0) 定位 frontSum+1（≠dropPos）；购买路径 D 位置=StartPos(dropPos) 单独发不在 CardPosList，
    -- 左推结果与服务端落位不一致 → 只接受右推（D 落 dropPos），左推改位则拒绝走"库存已满" #H1
    if not ctx.newPosMap:ContainsKey(0) or ctx.newPosMap:GetValueByKey(0) ~= dropPos then
        return nil  -- 左推改了 D 位置，购买精确落点不支持
    end
    -- 构建目标分区全量 CardPosList（所在分区所有已有卡，含未推开卡原位）；
    -- 新卡 D 哨兵0 不在 TotalMasterCards 自然排除，D 位置由 detail.StartPos 单独发不入 list（沿用哨兵排除设计）；
    -- IsCardsPosChange=true 表示客户端上报该分区全部已有主卡位置，服务端据全量快照应用 #购买Repack_CardPosList
    local stage = self._Model:GetCurrentStage()
    local cardPosList = {}
    for _, card in pairs(stage.TotalMasterCards) do
        if card.AreaType == targetArea then
            local newPos
            if ctx.newPosMap:ContainsKey(card.Id) then
                newPos = ctx.newPosMap:GetValueByKey(card.Id)  -- 被推开→新位
            else
                newPos = card.StartPos  -- 未推开→原位
            end
            table.insert(cardPosList, { Id = card.Id, AreaType = targetArea, StartPos = newPos })
        end
    end
    if #cardPosList == 0 then
        return nil  -- 目标分区无已有卡（理论不可达：BuyRepack canExecute 要求 _IsDropPosOccupied true 必有卡），防御区分 nil=失败 #L3
    end
    return cardPosList
end

--- 统一 repack 找位：D 插入 tgtCards 的 insertIdx 位，按 direction 选侧尝试右推/左推（§7 方向选侧 Q3）。
--- 算法两步尝试（顺序由 direction 决定）：①右推（dropPos 精确落位：D 落 dropPos，前段不动，后段被动右移保留间隙）
--- ②左推（前段主动紧凑贴 pos1 压缩间隙，D 接前段末尾，后段重新被动右移）——先试侧越限 fallback 另一侧。
--- 选侧：direction>=0 先右推失败左推（=旧序，右拖/购买默认）；direction<0 先左推失败右推（左拖，左推 D 落 frontSum+1 是固有接受 Q3）。
--- 不变量：①新位==原位的卡不入 map（保留间隙，不产生无意义变动）
--- ②D 同区回原位不入 map（由前后置 no-op 兜底）
--- ③同区总能找到方案（前段紧凑后必能让出空间），跨区/新购才可能拒。
---@param tgtCards XList 区域卡升序（已移除 D）
---@param insertIdx number D 插入序列位 [1, N+1]（dropPos-exact：第一个 dropPos 落其占位或之前的卡序号）
---@param dId number D 的 Id
---@param dSize number D 占格数
---@param dOrigStartPos number D 原 StartPos
---@param dropPos number 落点格（1-based，D 精确落位目标）
---@param srcArea number D 源区
---@param targetArea number 目标区
---@param gridLimit number 目标区容量上限
---@param outNewPosMap XDictionary 输出：id → 新 StartPos（仅位置/区域变化项）
---@param direction number|nil 1=右拖先右推；-1=左拖先左推；nil/0=先右推（=旧序，零回归）
---@return boolean success
function XPunishaarGameControl:_RepackInsert(tgtCards, insertIdx, dId, dSize, dOrigStartPos, dropPos, srcArea, targetArea, gridLimit, outNewPosMap, direction)
    -- §7 方向选侧已回退（direction 不选侧，右推优先）；前/后插由 insertIdx+_TryRightPush dNewPos=max(dropPos,frontEnd) 处理（#127）
    if self:_TryRightPush(tgtCards, insertIdx, dId, dSize, dOrigStartPos, dropPos, srcArea, targetArea, gridLimit, outNewPosMap) then
        return true
    end
    -- 右推溢出兜底：同尺寸落卡不左一格（让 Swap 互换 #规格1a）；非同尺寸走左一格（bug2 非同尺寸保留）
    -- 规格1a: 同尺寸落卡右推溢出（D 无法落 dropPos）→ Swap 直接交换（D@B位 B@D源），不左一格兜底抢先
    -- 非同尺寸右推溢出 → 左一格（D@dropPos-dSize，目标左一格）；购买域 acceptLeftPush=false 检查 D==dropPos 拒左一格（零回归）
    local B = self:GetMasterCardByAreaPos(targetArea, dropPos)
    if B and B.Id ~= dId then
        local bCfg = self:GetTablePunishaarCard(B.TemplateId, true)
        local bSize = (bCfg and bCfg.Size) or 1
        if bSize == dSize then
            return false  -- 同尺寸落卡右推溢出 → 让 Swap 互换（不左一格兜底 #规格1a）
        end
    end
    local leftPos = dropPos - dSize
    if leftPos >= 1 and self:_IsSlotRangeFree(targetArea, leftPos, dSize, { [dId] = true }) then
        outNewPosMap:Clear()
        outNewPosMap:SetValueByKey(dId, leftPos)
        return true
    end
    return false  -- 左一格也不空闲/越界 → 拒（调用方 tip+归位，不 cram 最左）
end

--- 右推尝试：dropPos 精确落位——D 新位 = dropPos，前段不动，后段从 prevEnd=dropPos+dSize 被动右移，间隙吸收 max(origStart, prevEnd)。
--- 新位==原位不入 map（保留间隙）。返回 true=右推成功（prevEnd-1<=gridLimit）。内部 Clear outNewPosMap 后写。
---@param tgtCards XList 区域卡升序（已移除 D）
---@param insertIdx number D 插入序列位
---@param dId number D 的 Id
---@param dSize number D 占格数
---@param dOrigStartPos number D 原 StartPos
---@param dropPos number 落点格（1-based，D 精确落位目标）
---@param srcArea number D 源区
---@param targetArea number 目标区
---@param gridLimit number 目标区容量上限
---@param outNewPosMap XDictionary 输出（内部 Clear 后写）
---@return boolean 右推是否成功
function XPunishaarGameControl:_TryRightPush(tgtCards, insertIdx, dId, dSize, dOrigStartPos, dropPos, srcArea, targetArea, gridLimit, outNewPosMap)
    outNewPosMap:Clear()
    local N = tgtCards:GetCount()
    local sizeCache = self._SizeCacheDict   -- 已由 InsertCard 填好（仅含 tgtCards，不含 D；D 用 dSize 参数）
    -- dNewPos=max(dropPos, 前段末卡之后)：保证 D 不与前段重叠（后插 insertIdx=B+1 时 dropPos 落 B 占位内，
    -- D 须落 B 后=前段末卡之后；前插 frontEnd<=dropPos 不变 #127 后插重叠修复）
    local frontEnd = 1
    if insertIdx > 1 then
        local prevCard = tgtCards:GetValueByIndex(insertIdx - 1)
        frontEnd = prevCard.StartPos + (sizeCache:GetValueByKey(prevCard.Id) or 1)
    end
    local dNewPos = math.max(dropPos, frontEnd)
    if not (srcArea == targetArea and dNewPos == dOrigStartPos) then
        outNewPosMap:SetValueByKey(dId, dNewPos)
    end
    local prevEnd = dNewPos + dSize  -- D 实际落 dNewPos，后段从 dNewPos+dSize 起（前插 dNewPos=dropPos 不变）
    for i = insertIdx, N do
        local card = tgtCards:GetValueByIndex(i)
        local sz = sizeCache:GetValueByKey(card.Id) or 1
        local newPos = math.max(card.StartPos, prevEnd)
        if newPos ~= card.StartPos then
            outNewPosMap:SetValueByKey(card.Id, newPos)
        end
        prevEnd = newPos + sz
    end
    return prevEnd - 1 <= gridLimit
end

--region ----------卡牌升级链预判（Buy 域策略用）----------

--- 判断指定 CardId 的指定等级是否存在下一级（PunishaarCardLevel 表 cardId*100+(level+1) 行存在）。
--- 合成升级 Rule1 前置校验：两张同 CardId 同等级牌合成下一级，须确认下一级配置存在（到顶则不可合成）。
---@param cardId number 卡牌模板 Id
---@param level number 当前等级
---@return boolean 存在下一级
function XPunishaarGameControl:HasNextCardLevel(cardId, level)
    if not cardId or cardId == 0 or not level or level <= 0 then
        return false
    end
    local nextCfg = self:GetTablePunishaarCardLevel(cardId * 100 + level + 1, true)
    return nextCfg ~= nil
end

--- 【#61 链式·策划需求】按 CardId+Level 找首张持有卡（链式合成取首张=决策①多匹配取首张）。
---@param cardId number
---@param level number
---@return table|nil Server.XPunishaarMasterCard
function XPunishaarGameControl:_FindOwnedCardByLevel(cardId, level)
    local stage = self._Model:GetCurrentStage()
    local cards = stage and stage.TotalMasterCards
    if not cards then
        return nil
    end
    for _, owned in pairs(cards) do
        if owned.TemplateId == cardId and (owned.Level or 0) == level then
            return owned
        end
    end
    return nil
end

--- 【#61 链式·策划需求】返回购买商品可触发的连续升级链：被消耗的持有卡列表（链序：商品级→商品级+1→…→最终级-1）+ 最终合成等级。
--- 链式规则（最大等级 3）：买 Lv1 goods，背包有 Lv1+Lv2 → 三张合成 Lv3（goods Lv1 + 持有 Lv1 + 持有 Lv2）；
--- 买 Lv1 + 背包仅 Lv1 → 单合 Lv2（链长 1）；买 Lv1 + 背包 Lv1+Lv3(无 Lv2) → 单合 Lv2（链断，Lv3 不参与）。
--- 算法：链首=商品同级持有卡（须 HasNextLevel，到顶不合成）→ 结果级+1，递归找下一级持有卡（须 HasNextLevel 可继续升）→ 无匹配/到顶止。
--- 单卡合并是链长=1 的特例。纯读判断，无副作用。nil=非升级（无同级持有/到顶共存/非主卡商品）。
---@param goods table Server.XPunishaarGoods（主卡商品，含 CardId/Level）
---@return table|nil chainConsumed 持有被消耗卡列表（按链序，每级一张）；nil=非升级
---@return number finalLevel 最终合成等级（chainConsumed 非 nil 时有效）
function XPunishaarGameControl:GetGoodsUpgradeChain(goods)
    if not goods or not goods.CardId or goods.CardId == 0 then
        return nil
    end
    if not self:GetControl():IsMasterCard(goods.CardId) then
        return nil
    end  -- 仅主卡适用升级规则

    local cardId = goods.CardId
    local goodsLevel = goods.Level or 0
    if goodsLevel <= 0 then
        return nil
    end
    -- 链首：商品同级持有卡（须 HasNextLevel，到顶不合成）
    if not self:HasNextCardLevel(cardId, goodsLevel) then
        return nil
    end
    local first = self:_FindOwnedCardByLevel(cardId, goodsLevel)
    if not first then
        return nil
    end

    local chain = { first }
    local level = goodsLevel + 1
    -- 链式递归：结果级有持有卡且 HasNextLevel（可继续升）→ 入链；到顶（HasNextLevel=false）或无匹配则止
    while self:HasNextCardLevel(cardId, level) do
        local nextCard = self:_FindOwnedCardByLevel(cardId, level)
        if not nextCard then
            break
        end
        table.insert(chain, nextCard)
        level = level + 1
    end

    return chain, level
end

--endregion

--endregion

--region ----------编排辅助（ctx 构造/可行性/reject tip）----------

--- 副卡宿主解析（BuySubCardMount/Replace 共用）。
--- Drag 路径经 _DropAction_Buy 反查宿主后传 overrideCardDetail.MasterCardId；
--- Click 路径（PickingHost）overrideCardDetail.MasterCardId 直取；
--- Click 副卡无 PickingHost（overrideDetail=nil）走 _FindHostForSubCardBuy 临时自动找位。
---@param ctx PunishaarArrangeCtx
---@return table|nil host masterCard（Server.XPunishaarMasterCard）
function XPunishaarGameControl:_ResolveSubCardHost(ctx)
    if ctx.overrideCardDetail and ctx.overrideCardDetail.MasterCardId
            and ctx.overrideCardDetail.MasterCardId ~= 0 then
        local stage = self._Model:GetCurrentStage()
        local cards = stage and stage.TotalMasterCards
        return cards and cards[ctx.overrideCardDetail.MasterCardId] or nil
    end
    local detail = self:_FindHostForSubCardBuy()
    if not detail then
        return nil
    end
    local stage = self._Model:GetCurrentStage()
    return stage and stage.TotalMasterCards
            and stage.TotalMasterCards[detail.MasterCardId] or nil
end

--- repack 可行性判定 canExecute 入口（#72 6.3-5）。
--- 方案 B（#72 精审修正）：直接调 _RepackInsert 复用算法层，零复刻，消除"dry-run 维护两份相同算法"的同步负担。
--- 副作用说明：_RepackInsert 会写 self._NewPosMapDict，但同轮 execute 调 _PrepareRepackCtx 会 Clear 重填，
---   canExecute→execute 在 _SelectArrangeStrategy 内同步串行（同帧无穿插、无 yield），无外部可见副作用。
--- G1 修正（canExecute/execute 一致契约）：acceptLeftPush 参数对齐 _ComputeBuyRepack #H1 ——
---   - false（BuyRepack 购买精确落点）：只接受右推 D 落 dropPos；左推 fallback 把 D 重定位 base_min（≠dropPos）则拒，
---     避免"canExecute=true→execute 防御性拒 CardFull"的判可行但执行拒。
---   - true（Insert 移动）：接受左推 fallback（D 重定位合法），与 InsertCard.execute 一致。
---@param targetArea number CardAreaType
---@param dropPos number 落点格（1-based）
---@param dSize number D 占格数
---@param excludedId number|nil D.Id（移动排 D）/ nil（购买新卡）
---@param acceptLeftPush boolean false=只接受右推 D 落 dropPos（购买精确落点）；true=接受左推 fallback（移动）
---@return boolean repack 可行
function XPunishaarGameControl:_RepackFeasible(targetArea, dropPos, dSize, excludedId, acceptLeftPush, allowBackInsert)
    local ctx = self:_PrepareRepackCtx(targetArea, dropPos, excludedId, allowBackInsert)
    if not ctx then
        return false
    end
    -- dId：移动路径 D.Id，购买路径哨兵 0（不在 TotalMasterCards，与 _ComputeBuyRepack 一致）
    local dId = excludedId or 0
    -- srcArea=-1 哨兵（≠任何 CardAreaType）使 _RepackInsert 内 srcArea==targetArea 判定 false，
    -- D 总入 newPosMap（供 acceptLeftPush=false 校验 D 落位）；srcArea 仅参与 no-op 判定，不影响 prevEnd 计算。
    -- dOrigStartPos=-1 与 srcArea=-1 双保险，避免 D 同区原位 no-op 短路不入 map（_RepackInsert 本身不做外层 no-op，此处保险）。
    local ok = self:_RepackInsert(ctx.tgtCards, ctx.insertIdx, dId, dSize, -1, dropPos,
            -1, targetArea, ctx.gridLimit, ctx.newPosMap, 0)  -- direction=0 右推优先（对齐 _ComputeBuyRepack，零回归）
    if not ok then
        return false  -- 右推+左推均越限，区域放不下
    end
    if not acceptLeftPush then
        -- 购买精确落点：只接受右推 D 落 dropPos；左推 fallback 改了 D 位置（base_min≠dropPos）则拒
        if not ctx.newPosMap:ContainsKey(dId) or ctx.newPosMap:GetValueByKey(dId) ~= dropPos then
            return false
        end
    end
    return true
end

--- Swap 可行性纯读（#72 Q4 简化：跨 Size 互换不支持，D.Size==B.Size 硬条件）。
--- §5 就近断言：B = GetMasterCardByAreaPos(targetArea, dropPos) 取的是 dropPos 落点格所占据的卡，
---   即"距落点最近"的卡（dropPos 必落 B 占格内才进 Swap；dropPos 落空格时 Swap canExecute 的
---   _IsDropPosOccupied 判 false 不进 Swap）。故 B 即最近卡，隐式就近正确，不扩展空格扫最近卡。
---@param ctx PunishaarArrangeCtx
---@param D table 拖拽主卡
---@param dSize number D 占格数
---@return boolean
function XPunishaarGameControl:_SwapFeasible(ctx, D, dSize)
    local B = self:GetMasterCardByAreaPos(ctx.targetArea, ctx.dropPos)
    if not B then
        return false
    end
    if B.Id == D.Id then
        return false  -- dropPos 落 D 自身占格（no-op 应已拦，防御）
    end
    local bCfg = self:GetTablePunishaarCard(B.TemplateId, true)
    local bSize = (bCfg and bCfg.Size) or 1
    if bSize ~= dSize then
        return false  -- 跨 Size 不互换（#72 Q4 用户定）
    end
    return true
end

--- R3 同尺寸紧凑推移求解：D 落 dropPos，占 dropPos 的同尺寸 B 被推 1 格紧贴 D 一侧（§7 按方向选侧）。
--- 独立于 _RepackInsert（不级联 repack，仅 B 单卡位移），跨尺寸返 nil 交 Insert/Swap（Q1 R3 限同尺寸）。
--- canExecute/execute 共用本函数（R1 一致，零两套算法）：canExecute 判返回 ~=nil，execute 拿返回 newPosMap。
---@param targetArea number CardAreaType
---@param dropPos number D 落点格（1-based）
---@param D table 拖拽主卡（Server.XPunishaarMasterCard）
---@param dSize number D 占格数
---@param direction number 1=右拖 B 推右紧贴 D 右；-1=左拖 B 推左紧贴 D 左
---@param gridLimit number 目标区已解锁槽位数
---@return table|nil newPosMap {[D.Id]=dropPos,[B.Id]=bNewPos}；nil=不可紧凑推移（无B/落D自身/跨尺寸/D或B移后越界/被第三方占）
function XPunishaarGameControl:_CompactedPushSolve(targetArea, dropPos, D, dSize, direction, gridLimit)
    direction = direction or 1  -- 自守卫（调用方 ctx.direction or 1 已兜，防未来新调用方传 nil 崩 #L2）
    -- D 落点合法性：dropPos 不越界/不落锁定槽（>gridLimit 即锁定槽，交 Insert 兜底）
    if dropPos < 1 or dropPos + dSize - 1 > gridLimit then
        return nil
    end
    local B = self:GetMasterCardByAreaPos(targetArea, dropPos)
    if not B or B.Id == D.Id then
        return nil  -- dropPos 无卡或落 D 自身占格（no-op 应已拦）
    end
    local bCfg = self:GetTablePunishaarCard(B.TemplateId, true)
    local bSize = (bCfg and bCfg.Size) or 1
    if bSize ~= dSize then
        return nil  -- 跨尺寸不紧凑推移（Q1 R3 限同尺寸，交 Insert/Swap repack）
    end
    -- D 新位 [dropPos, dropPos+dSize-1] 不与第三方卡重叠（排除 D 自身原位 + B 原位，B 将被推走）#H1
    -- 防 dropPos 落 B 非首格时 D 右延伸撞 B 右侧第三方卡（refuter H1：B@[3,4]+C@[5]+D size2 dropPos=4→D@[4,5]撞C@5）
    if not self:_IsSlotRangeFree(targetArea, dropPos, dSize, { [D.Id] = true, [B.Id] = true }) then
        return nil
    end
    -- B 新位：按方向紧贴 D 一侧（direction>=0 推右贴 D 右；<0 推左贴 D 左）
    local bNewPos
    if direction >= 0 then
        bNewPos = dropPos + dSize  -- D 占 [dropPos, dropPos+dSize-1]，B 紧贴右
    else
        bNewPos = dropPos - bSize  -- B 占 [dropPos-bSize, dropPos-1]，紧贴 D 左
    end
    -- 合法性：B 新位不越界 / 不落锁定槽
    if bNewPos < 1 or bNewPos + bSize - 1 > gridLimit then
        return nil
    end
    -- 不与第三方卡重叠（排除 D 将移走 + B 将移走，二者原位不算阻碍）
    if not self:_IsSlotRangeFree(targetArea, bNewPos, bSize, { [D.Id] = true, [B.Id] = true }) then
        return nil
    end
    return { [D.Id] = dropPos, [B.Id] = bNewPos }
end

--- Buy 域 ctx 构造辅助（gold 预判 + 升级链预判 + ctx 标量字段，#72 ArrangeCtx 构造辅助）。
--- BuyGoods(Click) 与 _DropAction_Buy(Drag 经 BuyGoods) 共用。失败已 cb(false) 返 nil。
---@param goodsIndex number
---@param source string "Click"|"Drag"
---@param overrideCardDetail table|nil
---@param cb function|nil
---@return table|nil ctx
function XPunishaarGameControl:_BuildBuyCtx(goodsIndex, source, overrideCardDetail, cb)
    local goods = self:GetControl():GetCurrentShopGoods()
    local item = goods and goods[goodsIndex]
    if not item then
        XLog.Error("[Punishaar] BuyGoods: 商品不存在，index=" .. tostring(goodsIndex))
        if cb then
            cb(false)
        end
        return nil
    end
    -- 客户端金币预判：不足直接拒，减少无意义请求（钱判断优先于找位）
    local priceCardCfg = self:GetTablePunishaarCard(item.CardId)
    if not priceCardCfg then
        XLog.Error("[Punishaar] BuyGoods: 卡牌配置缺失 cardId=" .. tostring(item.CardId) .. "，拒绝购买 #L2")
        if cb then
            cb(false)
        end
        return nil
    end
    local saleKey = priceCardCfg.Type * 100 + priceCardCfg.Size * 10 + item.Level
    local saleCfg = self:GetTablePunishaarCardSale(saleKey, true)
    local price = saleCfg and saleCfg.Buy or 0
    local gold = self:GetControl():GetCurrentGold() or 0
    if gold < price then
        local tip = XMVCA.XPunishaar:GetClientStringByKey("PunishaarShopBuyGoldNotEnough")
        if not string.IsNilOrEmpty(tip) then
            XUiManager.TipMsg(tip)
        end
        if cb then
            cb(false)
        end
        return nil
    end
    -- 升级链预判（纯读，结果填 ctx 供 BuyUpgradeChain canExecute 用）
    local chainConsumed, finalLevel = self:GetGoodsUpgradeChain(item)
    local keptMasterId, subCardIds
    if chainConsumed then
        keptMasterId = chainConsumed[1].Id
        subCardIds = {}
        if item.SubCardId and item.SubCardId ~= 0 then
            table.insert(subCardIds, item.SubCardId)
        end
        for _, consumedCard in ipairs(chainConsumed) do
            if consumedCard.SubCardId and consumedCard.SubCardId ~= 0 then
                table.insert(subCardIds, consumedCard.SubCardId)
            end
        end
    end
    local isSubCard = self:GetControl():IsSubCard(item.CardId)
    local hasDropPos = overrideCardDetail ~= nil and overrideCardDetail.AreaType ~= nil
    local dropPos, targetArea
    if hasDropPos then
        dropPos = overrideCardDetail.StartPos
        targetArea = overrideCardDetail.AreaType
    end
    return {
        domain = ArrangeDomain.Buy,
        source = source,
        dragCardId = 0,
        goodsIndex = goodsIndex,
        goodsItem = item,
        isSubCard = isSubCard,
        isSell = false,
        hasDropPos = hasDropPos,
        dropPos = dropPos,
        targetArea = targetArea,
        overrideCardDetail = overrideCardDetail,
        upgradeChain = chainConsumed,
        finalLevel = finalLevel,
        keptMasterId = keptMasterId,
        subCardIds = subCardIds,
    }
end

--- 购买域选择器返回 nil 的兜底提示（满区 / 无合法宿主，#72 购买域满区仍拒不 fallback Swap）。
--- 主卡拖拽精确落点失败时区分锁定槽/越界/真·满区 3 文案（对齐空区退化方案不变量）。
---@param ctx PunishaarArrangeCtx
---@param cb function|nil
function XPunishaarGameControl:_RejectBuyFail(ctx, cb)
    local tipKey
    if ctx.isSubCard then
        tipKey = "BuySubCardNoTargetMainCard"
    elseif ctx.hasDropPos then
        -- 主卡拖拽精确落点失败：区分锁定槽/越界/真·满区
        local item = ctx.goodsItem
        local dCfg = self:GetTablePunishaarCard(item.CardId, true)
        local dSize = (dCfg and dCfg.Size) or 1
        local gridLimit = self:_GetAreaGridLimit(ctx.targetArea)
        if ctx.dropPos > gridLimit then
            tipKey = "PunishaarDropPosLocked"
        elseif ctx.dropPos + dSize - 1 > gridLimit then
            tipKey = "PunishaarDropPosOverflow"
        else
            tipKey = "PunishaarShopCardFull"  -- 落点合法但 repack 不可行（真·满区 S3）
        end
    else
        tipKey = "PunishaarShopCardFull"  -- 点击购买主卡无空位（S9）
    end
    local tip = XMVCA.XPunishaar:GetClientStringByKey(tipKey)
    if not string.IsNilOrEmpty(tip) then
        XUiManager.TipMsg(tip)
    end
    if cb then
        cb(false)
    end
end

--- 编排域选择器返回 nil 的兜底提示（3 种文案区分：锁定槽/越界/真·区域满，#72 保留空区退化方案不变量）。
---@param ctx PunishaarArrangeCtx
---@param cb function|nil
function XPunishaarGameControl:_ArrangeRejectTip(ctx, cb)
    local stage = self._Model:GetCurrentStage()
    local D = stage and stage.TotalMasterCards and stage.TotalMasterCards[ctx.dragCardId]
    if not D then
        if cb then
            cb(false)
        end
        return
    end
    local dCfg = self:GetTablePunishaarCard(D.TemplateId, true)
    local dSize = (dCfg and dCfg.Size) or 1
    local gridLimit = self:_GetAreaGridLimit(ctx.targetArea)
    -- N = 目标区移除 D 后卡数（区分 N=0 越界 vs N≥1 真·满区）
    local N = 0
    if stage.TotalMasterCards then
        for _, card in pairs(stage.TotalMasterCards) do
            if card.AreaType == ctx.targetArea and card.Id ~= ctx.dragCardId then
                N = N + 1
            end
        end
    end
    local tipKey
    if ctx.dropPos > gridLimit then
        tipKey = "PunishaarDropPosLocked"
    elseif N == 0 then
        tipKey = "PunishaarDropPosOverflow"
    else
        tipKey = "BagFullWhenInsert"
    end
    local tip = XMVCA.XPunishaar:GetClientStringByKey(tipKey)
    if not string.IsNilOrEmpty(tip) then
        XUiManager.TipMsg(tip)
    end
    if cb then
        cb(false)
    end
end

--endregion

--region ----------公开编排方法（InsertCard / BuyGoods / MoveCard，签名不变）----------

--- 购买商店指定槽位商品（#72 退化薄包装）。
--- 流程：_BuildBuyCtx 预判 gold+升级链 → _SelectArrangeStrategy 选策略 → strat.execute；
--- 升级链/副卡挂宿主/精确落点/自动找位等策略细节见 _ArrangeStrategies 注册表（domain 硬隔离，购买域不含 Swap）。
--- 策略 execute 构造 cardDetail 时新建 table，禁 mutate ctx.overrideCardDetail（#72 6.3-7）。
---@param goodsIndex number 服务端槽位索引（1-based，底层统一约定）
---@param cb function(success: boolean)
---@param overrideCardDetail table|nil 可选：精确落点 { AreaType, StartPos, SubCardId=0, MasterCardId=0 }；nil=自动找位
function XPunishaarGameControl:BuyGoods(goodsIndex, cb, overrideCardDetail)
    -- 退化薄包装（#72）：gold 预判 + 升级链预判 → 构造 ArrangeCtx → 选策略 → execute
    -- 购买域策略子集不含 Swap（domain 硬隔离，满区即拒 S3/S9）；副卡替换二次确认归位 BuySubCardReplace.execute
    -- 策略 execute 构造 cardDetail 时新建 table，禁 mutate ctx.overrideCardDetail（#72 6.3-7）
    local ctx = self:_BuildBuyCtx(goodsIndex, "Click", overrideCardDetail, cb)
    if not ctx then
        return  -- _BuildBuyCtx 已 cb(false)
    end
    local strat = self:_SelectArrangeStrategy(ctx)
    if not strat then
        -- 购买域无策略可处理（满区 / 无合法宿主）
        self:_RejectBuyFail(ctx, cb)
        return
    end
    strat.execute(self, ctx, cb)
end

--- 移动卡牌位置（对战区↔背包换位）：提交全量位置快照，仅替换目标卡的区域与起始格。
--- 全量覆盖是服务端协议要求（XPunishaarSetCardPosRequest.CardPosList 须覆盖全部主卡）。
---@param masterCardId number 主卡唯一 Id
---@param targetArea number CardAreaType（FightArea=1 / Bag=2）
---@param targetStartPos number 目标起始格（1-based）
---@param cb function(success: boolean)
function XPunishaarGameControl:MoveCard(masterCardId, targetArea, targetStartPos, cb)
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.TotalMasterCards then
        if cb then
            cb(false)
        end
        return
    end
    -- 全量位置快照：仅替换目标卡 area/pos，其余原位（复用 _CardPosListBuffer，#72 提交段统一入口）
    local cardPosList = self:_BuildCardPosList(function(card, entry)
        if card.Id == masterCardId then
            entry.AreaType = targetArea
            entry.StartPos = targetStartPos
        end
    end)
    self:_SubmitCardPosList(cardPosList, cb)
end

--endregion

--region ----------编排策略注册表 + 选择器 #72----------

-- 策略注册表（按 domain 分组，组内按数组顺序遍历——选择器不读 priority 不排序，priority 仅作文档定位；
-- 新增策略须按意图优先级插正确数组位置，#72 OCP #L1）。
-- canExecute(ctx, owner) 纯读无副作用；execute(owner, ctx, cb) 内含 1 次协议提交，失败 Model 不动（无显式 rollback，#72 Q2）。
-- 选择器 _SelectArrangeStrategy 按 ctx.domain 过滤 + ipairs 数组顺序取首个 canExecute=true 即 return（break，不读 priority 不排序，#72 6.3-4 #L1）。
XPunishaarGameControl._ArrangeStrategies = {
    -- ━━ 购买域（Buy）：无互换能力，满区即拒（S3/S9 仍拒）━━
    {
        name = "BuyUpgradeChain", domain = ArrangeDomain.Buy, priority = 0,
        canExecute = function(ctx)
            return ctx.upgradeChain ~= nil
        end,
        execute = function(owner, ctx, cb)
            -- 设升级动画缓存（保留卡 TemplateId=商品 TemplateId + finalLevel；BuySuccess 后 grid RefreshAsEquipped 查匹配播+清）#升级动画
            owner._PendingLevelupAnimTemplateId = ctx.goodsItem.CardId
            owner._PendingLevelupAnimLevel = ctx.finalLevel
            local subCardIds = ctx.subCardIds
            if subCardIds and #subCardIds >= 2 then
                -- ≥2 副卡：异步开保留 UI，列全部副卡供玩家选保留 1 张
                owner.RunControl:OpenMainCardLevelupTip(subCardIds, ctx.goodsItem.CardId, ctx.finalLevel, function(chosenSubCardId)
                    local detail = { MasterCardId = ctx.keptMasterId, SubCardId = chosenSubCardId }
                    owner:_DoBuyGoodsFinal(ctx.goodsIndex, detail, cb)
                end, function()
                    -- 玩家取消：清缓存（未升级）+ 终止本次购买
                    owner._PendingLevelupAnimTemplateId = nil
                    owner._PendingLevelupAnimLevel = nil
                    if cb then
                        cb(false)
                    end
                end)
                return
            end
            -- ≤1 副卡：默认继承（有则那张，无则 0），不开 UI
            local detail = { MasterCardId = ctx.keptMasterId, SubCardId = (subCardIds and subCardIds[1]) or 0 }
            owner:_DoBuyGoodsFinal(ctx.goodsIndex, detail, cb)
        end,
    },
    {
        name = "BuySubCardMount", domain = ArrangeDomain.Buy, priority = 10,
        canExecute = function(ctx, owner)
            if not ctx.isSubCard then
                return false
            end
            local host = owner:_ResolveSubCardHost(ctx)
            return host ~= nil and (not host.SubCardId or host.SubCardId == 0)
        end,
        execute = function(owner, ctx, cb)
            local host = owner:_ResolveSubCardHost(ctx)
            local detail = { StartPos = 0, SubCardId = 0, MasterCardId = host.Id }
            owner:_DoBuyGoodsFinal(ctx.goodsIndex, detail, cb)
        end,
    },
    {
        name = "BuySubCardReplace", domain = ArrangeDomain.Buy, priority = 11,
        canExecute = function(ctx, owner)
            if not ctx.isSubCard then
                return false
            end
            local host = owner:_ResolveSubCardHost(ctx)
            return host ~= nil and host.SubCardId ~= nil and host.SubCardId ~= 0
        end,
        execute = function(owner, ctx, cb)
            -- 副卡替换二次确认归位策略 execute（#72，自 _DropAction_Buy 迁入）
            -- 仅拖拽路径二次确认；Click 路径（PickingHost _OnBtnBuyReplace）Q2 定案覆盖不二次确认
            if ctx.source == "Drag" then
                local host = owner:_ResolveSubCardHost(ctx)
                XUiManager.DialogTip(
                    CS.XTextManager.GetText("TipTitle"),
                    XMVCA.XPunishaar:GetClientStringByKey("TipsSubCardReplace"),
                    XUiManager.DialogType.Normal,
                    function()  -- closeCb（取消/关闭）→ 归位不购买
                        if cb then
                            cb(false)
                        end
                    end,
                    function()  -- sureCb（确认替换）→ 购买（旧副卡直接丢弃 #51）
                        local detail = { StartPos = 0, SubCardId = 0, MasterCardId = host.Id }
                        owner:_DoBuyGoodsFinal(ctx.goodsIndex, detail, cb)
                    end)
                return
            end
            -- Click 路径：直接购买（Q2 定案覆盖不二次确认）
            local host = owner:_ResolveSubCardHost(ctx)
            local detail = { StartPos = 0, SubCardId = 0, MasterCardId = host.Id }
            owner:_DoBuyGoodsFinal(ctx.goodsIndex, detail, cb)
        end,
    },
    {
        name = "BuyExact", domain = ArrangeDomain.Buy, priority = 20,
        canExecute = function(ctx, owner)
            if ctx.isSubCard or not ctx.hasDropPos then
                return false
            end
            local item = ctx.goodsItem
            local dCfg = owner:GetTablePunishaarCard(item.CardId, true)
            local dSize = (dCfg and dCfg.Size) or 1
            local gridLimit = owner:_GetAreaGridLimit(ctx.targetArea)
            -- 锁定/越界都不可精确落点（与 _RejectDropPosIfInvalid(true) 同构）
            if ctx.dropPos > gridLimit or ctx.dropPos + dSize - 1 > gridLimit then
                return false
            end
            return not owner:_IsDropPosOccupied(ctx.targetArea, ctx.dropPos, dSize)
        end,
        execute = function(owner, ctx, cb)
            -- 构造新 cardDetail（不 mutate ctx.overrideCardDetail，#72 6.3-7）
            local detail = { AreaType = ctx.targetArea, StartPos = ctx.dropPos, SubCardId = 0, MasterCardId = 0 }
            owner:_DoBuyGoodsFinal(ctx.goodsIndex, detail, cb)
        end,
    },
    {
        name = "BuyRepack", domain = ArrangeDomain.Buy, priority = 21,
        canExecute = function(ctx, owner)
            if ctx.isSubCard or not ctx.hasDropPos then
                return false
            end
            local item = ctx.goodsItem
            local dCfg = owner:GetTablePunishaarCard(item.CardId, true)
            local dSize = (dCfg and dCfg.Size) or 1
            local gridLimit = owner:_GetAreaGridLimit(ctx.targetArea)
            if ctx.dropPos > gridLimit then
                return false
            end
            if not owner:_IsDropPosOccupied(ctx.targetArea, ctx.dropPos, dSize) then
                return false
            end
            return owner:_RepackFeasible(ctx.targetArea, ctx.dropPos, dSize, nil, false, false)  -- allowBackInsert=false（购买保前插 #127）
        end,
        execute = function(owner, ctx, cb)
            local item = ctx.goodsItem
            local dCfg = owner:GetTablePunishaarCard(item.CardId, true)
            local dSize = (dCfg and dCfg.Size) or 1
            local cardPosList = owner:_ComputeBuyRepack(ctx.targetArea, ctx.dropPos, dSize)
            if not cardPosList then
                -- repack 失败（canExecute 已判可行，理论不可达，防御 #L3）
                XUiManager.TipMsg(XMVCA.XPunishaar:GetClientStringByKey("PunishaarShopCardFull"))
                if cb then
                    cb(false)
                end
                return
            end
            -- 构造新 cardDetail（不 mutate ctx.overrideCardDetail，#72 6.3-7）
            local detail = {
                AreaType = ctx.targetArea,
                StartPos = ctx.dropPos,
                SubCardId = 0,
                MasterCardId = 0,
                CardPosList = cardPosList,
                IsCardsPosChange = true,
            }
            owner:_DoBuyGoodsFinal(ctx.goodsIndex, detail, cb)
        end,
    },
    {
        name = "BuyAutoPlace", domain = ArrangeDomain.Buy, priority = 30,
        canExecute = function(ctx, owner)
            if ctx.isSubCard or ctx.hasDropPos then
                return false
            end
            local item = ctx.goodsItem
            return owner:_FindPlacementForDirectBuy(item.CardId) ~= nil
        end,
        execute = function(owner, ctx, cb)
            local item = ctx.goodsItem
            local detail = owner:_FindPlacementForDirectBuy(item.CardId)
            if not detail then
                -- canExecute 已判非 nil，防御
                XUiManager.TipMsg(XMVCA.XPunishaar:GetClientStringByKey("PunishaarShopCardFull"))
                if cb then
                    cb(false)
                end
                return
            end
            owner:_DoBuyGoodsFinal(ctx.goodsIndex, detail, cb)
        end,
    },
    -- ━━ 编排域（Arrange）：含互换能力 ━━
    {
        name = "CompactedPush", domain = ArrangeDomain.Arrange, priority = 9.5,
        -- 数组位在 Insert 前（选择器 _SelectArrangeStrategy 按数组顺序遍历，不读 priority，priority 仅作文档定位）
        -- R3 同尺寸紧凑推移：dropPos 落同尺寸 B → B 推 1 格紧贴 D 一侧；跨尺寸/无B/B移后非法返 nil fall-through Insert repack
        canExecute = function(ctx, owner)
            if not ctx.hasDropPos then
                return false
            end
            local stage = owner._Model:GetCurrentStage()
            local D = stage and stage.TotalMasterCards and stage.TotalMasterCards[ctx.dragCardId]
            if not D then
                return false
            end
            -- R3 仅同区紧凑推移（跨区交 Swap 互换：B 留 targetArea 挤 vs Swap B 搬 D 源区换位，语义不同 #M2）
            if D.AreaType ~= ctx.targetArea then
                return false
            end
            local dCfg = owner:GetTablePunishaarCard(D.TemplateId, true)
            local dSize = (dCfg and dCfg.Size) or 1
            local gridLimit = owner:_GetAreaGridLimit(ctx.targetArea)
            local direction = ctx.direction or 1
            return owner:_CompactedPushSolve(ctx.targetArea, ctx.dropPos, D, dSize, direction, gridLimit) ~= nil
        end,
        execute = function(owner, ctx, cb)
            local stage = owner._Model:GetCurrentStage()
            local D = stage.TotalMasterCards[ctx.dragCardId]
            local dCfg = owner:GetTablePunishaarCard(D.TemplateId, true)
            local dSize = (dCfg and dCfg.Size) or 1
            local gridLimit = owner:_GetAreaGridLimit(ctx.targetArea)
            local direction = ctx.direction or 1
            local newPosMap = owner:_CompactedPushSolve(ctx.targetArea, ctx.dropPos, D, dSize, direction, gridLimit)
            if not newPosMap then
                -- canExecute 已判非 nil，理论不可达，防御
                XUiManager.TipMsg(XMVCA.XPunishaar:GetClientStringByKey("BagFullWhenInsert"))
                if cb then
                    cb(false)
                end
                return
            end
            -- cardPosList：D→dropPos、B→bNewPos（均 area=targetArea），其余原位（源区留间隙不左移）
            local cardPosList = owner:_BuildCardPosList(function(card, entry)
                local newPos = newPosMap[card.Id]
                if newPos then
                    entry.AreaType = ctx.targetArea
                    entry.StartPos = newPos
                end
            end)
            owner:_SubmitCardPosList(cardPosList, cb)
        end,
    },
    {
        name = "Insert", domain = ArrangeDomain.Arrange, priority = 10,
        canExecute = function(ctx, owner)
            if not ctx.hasDropPos then
                return false
            end
            local stage = owner._Model:GetCurrentStage()
            local D = stage and stage.TotalMasterCards and stage.TotalMasterCards[ctx.dragCardId]
            if not D then
                return false
            end
            local dCfg = owner:GetTablePunishaarCard(D.TemplateId, true)
            local dSize = (dCfg and dCfg.Size) or 1
            return owner:_RepackFeasible(ctx.targetArea, ctx.dropPos, dSize, ctx.dragCardId, true, true)  -- allowBackInsert=true（Move 支持后插 #127）
        end,
        execute = function(owner, ctx, cb)
            -- 复用既有 InsertCard 算法（no-op/N=0/repack 不变量保留，#72 选项A 最小改动）
            -- ctx.direction 透传（§7 选侧，Drag 经 _DropAction_Move 填；Click/button 无 direction 走 nil=旧序）
            owner:InsertCard(ctx.dragCardId, ctx.targetArea, ctx.dropPos, cb, ctx.direction)
        end,
    },
    {
        name = "Swap", domain = ArrangeDomain.Arrange, priority = 11,
        -- 注：Swap canExecute 不重判 _RepackFeasible——Insert(priority 10) 在前已判 false 才轮到本策略
        -- （选择器 ipairs 数组顺序+break，不读 priority，#72 6.3-4/6.3-5 避免重复调算法层）
        canExecute = function(ctx, owner)
            if not ctx.hasDropPos then
                return false
            end
            local stage = owner._Model:GetCurrentStage()
            local D = stage and stage.TotalMasterCards and stage.TotalMasterCards[ctx.dragCardId]
            if not D then
                return false
            end
            local dCfg = owner:GetTablePunishaarCard(D.TemplateId, true)
            local dSize = (dCfg and dCfg.Size) or 1
            if not owner:_IsDropPosOccupied(ctx.targetArea, ctx.dropPos, dSize) then
                return false
            end
            return owner:_SwapFeasible(ctx, D, dSize)
        end,
        execute = function(owner, ctx, cb)
            local stage = owner._Model:GetCurrentStage()
            local D = stage.TotalMasterCards[ctx.dragCardId]
            local dCfg = owner:GetTablePunishaarCard(D.TemplateId, true)
            local dSize = (dCfg and dCfg.Size) or 1
            local srcArea = D.AreaType
            local dOrigStartPos = D.StartPos
            local B = owner:GetMasterCardByAreaPos(ctx.targetArea, ctx.dropPos)
            -- canExecute 已判 _SwapFeasible（含 D.Size==B.Size），B 必非 nil
            -- cardPosList：D→B 位(area=targetArea,dropPos)，B→D 原位(area=srcArea,dOrigStartPos)，其余原位
            -- 复用 _CardPosListBuffer（#72 6.3-3）
            local cardPosList = owner:_BuildCardPosList(function(card, entry)
                if card.Id == D.Id then
                    entry.AreaType = ctx.targetArea
                    entry.StartPos = ctx.dropPos
                elseif card.Id == B.Id then
                    entry.AreaType = srcArea  -- 跨区时 B 搬到 D 源区；同区时 srcArea==targetArea 不变
                    entry.StartPos = dOrigStartPos
                end
            end)
            owner:_SubmitCardPosList(cardPosList, cb)
        end,
    },
    -- ━━ 卖出域（Sell）━━
    {
        name = "Sell", domain = ArrangeDomain.Sell, priority = 0,
        canExecute = function(ctx)
            return ctx.dragCardId ~= nil and ctx.dragCardId ~= 0
        end,
        execute = function(owner, ctx, cb)
            owner:SellCard(ctx.dragCardId, cb)
        end,
    },
}

--- 策略选择器：按 ctx.domain 选域子集，遍历取首个 canExecute=true 即 return（break，#72 6.3-4）。
--- 返回 nil 表示无策略可处理 → 调用方按域给兜底提示（购买域 _RejectBuyFail / 编排域 _ArrangeRejectTip）。
---@param ctx PunishaarArrangeCtx
---@return table|nil strategy
function XPunishaarGameControl:_SelectArrangeStrategy(ctx)
    for _, strat in ipairs(self._ArrangeStrategies) do
        if strat.domain == ctx.domain and strat.canExecute(ctx, self) then
            return strat
        end
    end
    return nil
end

--endregion

--region ----------奖励入位骨架（ArrangeRewardCard）#72----------

--- 【#72 骨架】战前/剧情面板获卡奖励入位入口（复用编排策略链，不扣金币非商店购买）。
--- 与 BuyGoods 区别：奖励入位无金币扣费、无商品槽位（非商店购买），新卡由服务端奖励下发，
--- 落点策略复用编排域（domain=Arrange，含 Swap 互换能力）。
--- TODO（Reward 域策略细节，后续接）：
---   1) 新卡入 Model（奖励下发回流，非 DoBuyGoods 路径，需服务端奖励协议或本地预入位）
---   2) cardPosList 须含新卡（新卡不在 TotalMasterCards，哨兵 Id=0 仿 _ComputeBuyRepack）
---   3) 不扣金币提交（非 _DoBuyGoodsFinal，走 _SubmitCardPosList 或独立提交入口）
---   4) Arrange 域现有 Insert/Swap 策略 canExecute 依 TotalMasterCards[ctx.dragCardId]，新卡哨兵 0 查无 →
---      骨架阶段 _SelectArrangeStrategy 必返回 nil → cb(false)，不破坏现状（无调用方）；
---      后续接 Reward 域专用策略（如 RewardPlace）后此处才能真正入位。
---@param cardData table 奖励卡数据（模板 Id + 落点信息，结构后续定）
---@param targetArea number CardAreaType 目标区域
---@param dropPos number 落点格（1-based）
---@param cb function(success: boolean)|nil
function XPunishaarGameControl:ArrangeRewardCard(cardData, targetArea, dropPos, cb)
    -- 骨架：构造 ArrangeCtx（domain=Arrange 复用编排策略链），dragCardId=0 新卡哨兵
    -- TODO: 新卡入 Model + cardPosList 含新卡 + 不扣金币提交，后续接 Reward 域策略细节
    local ctx = {
        domain = ArrangeDomain.Arrange,
        source = "Reward",
        dragCardId = 0,  -- 新卡哨兵（不在 TotalMasterCards，仿 _ComputeBuyRepack；现有 Arrange 策略查无 → nil）
        hasDropPos = dropPos ~= nil,
        dropPos = dropPos,
        targetArea = targetArea,
        cardData = cardData,
    }
    local strat = self:_SelectArrangeStrategy(ctx)
    if not strat then
        -- 编排域无策略可处理（新卡哨兵 0 不在 TotalMasterCards，现有 Insert/Swap canExecute 查无 → nil）
        -- 骨架阶段：直接 cb(false) 不破坏现状；后续接 Reward 域策略后此处改调 strat.execute
        if cb then
            cb(false)
        end
        return
    end
    strat.execute(self, ctx, cb)
end

--endregion

return XPunishaarGameControl
