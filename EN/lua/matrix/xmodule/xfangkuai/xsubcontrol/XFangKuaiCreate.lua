---@class XFangKuaiCreate : XControl
---@field _MainControl XFangKuaiControl
---@field _Model XFangKuaiModel
local XFangKuaiCreate = XClass(XControl, "XFangKuaiCreate")

function XFangKuaiCreate:OnInit()

end

function XFangKuaiCreate:AddAgencyEvent()

end

function XFangKuaiCreate:RemoveAgencyEvent()

end

function XFangKuaiCreate:OnRelease()

end

function XFangKuaiCreate:GetBlockTemplateByLength(stageId, length, blockType)
    local templates = self._Model:GetBlockTemplates()
    local datas = templates[stageId]
    if XTool.IsTableEmpty(datas) or XTool.IsTableEmpty(datas[length]) then
        return nil
    end
    local ids = {}
    local weights = {}
    local blocks = datas[length]
    for _, config in pairs(blocks) do
        if blockType and config.Type ~= blockType then
            -- 允许只创建某种类型的方块
            goto continue
        end
        if config.Type == XEnumConst.FangKuai.BlockType.Chief and self:HasChiefBlock(stageId) then
            -- 场上只能有1个首席方块
            goto continue
        end
        if not XTool.IsNumberValid(config.UnBuild) then
            table.insert(ids, config)
            if XTool.IsNumberValid(config.Weight) then
                table.insert(weights, config.Weight)
            end
        end
        :: continue ::
    end
    if XTool.IsTableEmpty(ids) then
        if blockType then
            if blockType == XEnumConst.FangKuai.BlockType.Chief then
                -- 首席方块转化为类型1同长度的普通方块
                local replaceBlocks = {}
                for _, config in pairs(blocks) do
                    if config.Type == XEnumConst.FangKuai.BlockType.Normal then
                        table.insert(replaceBlocks, config)
                    end
                end
                if #replaceBlocks == 0 then
                    XLog.Error(string.format("首席方块替换失败，关卡%s里没有类型1长度1的配置"), stageId)
                else
                    table.insert(ids, replaceBlocks[XTool.Random(1, #replaceBlocks)])
                end
            else
                XLog.Error(string.format("创建方块失败:关卡%s没有类型为%s,长度为%s的方块", stageId, blockType, length))
            end
        else
            XLog.Error(string.format("创建方块失败:关卡%s没有长度为%s的方块", stageId, length))
        end
    end
    if #ids == 1 then
        return ids[1]
    else
        if #weights > 0 then
            return ids[XMath.RandByWeights(weights)]
        end
        return ids[XTool.Random(1, #ids)]
    end
end

-- 顶部预览、底部方块池和场上只能有1个首席方块
function XFangKuaiCreate:HasChiefBlock(stageId)
    local chapterId = self._MainControl:GetChapterIdByStage(stageId)
    local stageData = self._Model.ActivityData:GetStageData(chapterId)
    if not stageData then
        return false
    end
    
    -- 棋盘上
    local blockDatas = self._MainControl:GetBlockMap()
    for block, _ in pairs(blockDatas) do
        if block:IsChief() then
            return true
        end
    end

    -- 顶部预览
    local topPreviewBlock = stageData:GetTopPreviewBlock()
    if topPreviewBlock and topPreviewBlock:IsChief() then
        return true
    end

    -- 方块池
    local newBlockDatas = self._MainControl:GetNewBlockPool()
    for _, blocks in pairs(newBlockDatas) do
        for _, block in pairs(blocks) do
            if block:IsChief() then
                return true
            end
        end
    end

    -- 新创建的方块（还未入池）
    local blocks = self._MainControl:GetCurCreateBlocks(chapterId)
    for _, blockData in pairs(blocks) do
        if blockData:IsChief() then
            return true
        end
    end
    
    return false
end

--region 行生成

---@param stageData XFangKuaiStageData
---@return XFangKuaiBlock
function XFangKuaiCreate:AddBlock(stageData, length, x, y, blockType)
    local blockData = self:CreateBlock(stageData, length, x, y, blockType)
    stageData:AddBlock(blockData)
    return blockData
end

---@return XFangKuaiBlock
function XFangKuaiCreate:CreateBlock(stageData, length, x, y, blockType)
    local template = self:GetBlockTemplateByLength(stageData.StageId, length, blockType)
    if not template then
        XLog.Error(string.format("AddBlock failed. available blockTemplate not found, stageId:%s, length:%s", stageData.StageId, length))
        return
    end

    local color = #template.Colors > 1 and template.Colors[XTool.Random(1, #template.Colors)] or template.Colors[1]
    local direction = template.Direction == XEnumConst.FangKuai.DirectionType.Random and
            XTool.Random(XEnumConst.FangKuai.DirectionType.Left, XEnumConst.FangKuai.DirectionType.Right) or
            template.Direction

    stageData.LastBlockId = stageData.LastBlockId + 1

    ---@type XFangKuaiBlock
    local block = require("XUi/XUiFangKuai/XEntity/XFangKuaiBlock").New()
    block:SetBlockId(template.Id)
    block:SetLen(template.Length)
    block:SetTotalLen(template.Length)
    block:SetDirection(direction)
    block:SetBlockType(template.Type)
    block:SetColor(color)
    block:SetScore()
    block:SetGrid(x, y)
    block:SetMaxSize(stageData.StageId)
    block:SetHitTimes()
    block:SetId(stageData.LastBlockId)

    return block
end

---@return number
function XFangKuaiCreate:ReqStageStart(stageId, chapterId, characterId)
    local stageTemplate = self._MainControl:GetStageConfig(stageId)

    if not stageTemplate then
        XLog.Error("方块-无效关卡Id")
        return
    end

    if not self._MainControl:IsPreStagePass(stageId) then
        XLog.Error("方块-前置关卡未完成")
        return
    end
    
    if not XTool.IsNumberValid(chapterId) then
        XLog.Error("方块-无效关卡Id")
        return
    end
    
    local stageData = self._Model.ActivityData:GetStageData(chapterId)

    if not self:FillLines(stageData, stageTemplate) then
        XLog.Error(string.format("FillLines failed. stageId:%s", stageId))
        return
    end

    return chapterId
end

---@param stageData XFangKuaiStageData
---@param stageTemplate XTableFangKuaiStage
function XFangKuaiCreate:FillLines(stageData, stageTemplate, addLine)
    if not stageData or not stageTemplate then
        XLog.Error("FillLines failed. param error")
        return false
    end
    -- 方块生成规则展开表
    local blockRuleExpand = self._Model:GetBlockRuleExpand(stageData.StageId)
    if not blockRuleExpand then
        XLog.Error(string.format("FillLines failed. no expand block rule for stage. stageId:%s", stageData.StageId))
        return false
    end
    -- 方块生成规则循环表
    local blockRuleLoop = self._Model:GetBlockRuleLoop(stageData.StageId)
    if not blockRuleLoop then
        XLog.Error(string.format("FillLines failed. no loop block rule for stage. stageId:%s", stageData.StageId))
        return false
    end
    -- 道具生成规则
    local itemRuleExpand = self._Model:GetItemRuleExpand(stageData.StageId)
    local newLineCount = self._MainControl:GetNewLineCount()

    if stageData.LastLineNo == 0 then
        -- 初始化地面行
        for i = stageTemplate.InitLineCount, 1, -1 do
            self:AddLine(stageData, stageTemplate, blockRuleExpand, blockRuleLoop, itemRuleExpand, i)
        end
        -- 预览
        for i = 1, newLineCount do
            self:AddLine(stageData, stageTemplate, blockRuleExpand, blockRuleLoop, itemRuleExpand, -i)
        end
    else
        local lastY = self._MainControl:GetNewBlockLastY()
        if XTool.IsNumberValid(addLine) then
            -- 补齐被消除掉的行
            for i = 1, addLine do
                self:AddLine(stageData, stageTemplate, blockRuleExpand, blockRuleLoop, itemRuleExpand, -i - lastY)
            end
        else
            -- 新回合 上升newLineCount行
            for i = 1, newLineCount do
                self:AddLine(stageData, stageTemplate, blockRuleExpand, blockRuleLoop, itemRuleExpand, -i - lastY)
            end
        end
    end

    return true
end

---@param stageData XFangKuaiStageData
---@param stageTemplate XTableFangKuaiStage
---@param blockRuleExpand XFangKuaiRuleExpand
---@param blockRuleLoop XTableFangKuaiStageBlockRule[]
---@param itemRuleExpand XFangKuaiRuleExpand
---@param targetY number
function XFangKuaiCreate:AddLine(stageData, stageTemplate, blockRuleExpand, blockRuleLoop, itemRuleExpand, targetY)
    if not stageData or not stageTemplate then
        XLog.Error("AddLine failed. param error")
        return
    end
    -- 临时计算当前行数, 所有计算都完成才更新 stageData.LastLineNo
    local curLineNo = stageData.LastLineNo + 1

    ---@type XTableFangKuaiStageBlockRule
    local blockRuleTemplate = nil
    local ruleCount = XTool.GetTableCount(blockRuleExpand.Rules)
    if curLineNo <= ruleCount then
        blockRuleTemplate = blockRuleExpand.Rules[curLineNo]
    else
        -- 超出配置取循环表
        local index = (curLineNo - ruleCount) % #blockRuleLoop
        blockRuleTemplate = index == 0 and blockRuleLoop[#blockRuleLoop] or blockRuleLoop[index]
    end

    if not blockRuleTemplate then
        XLog.Error(string.format("AddLine failed. block rule not found for line %s, curLineNo:%s, stageId:%s", stageData.LastLineNo, curLineNo, stageData.StageId))
        return
    end

    ---@type XFangKuaiBlock[]
    local blocks = {}
    if blockRuleTemplate.Type == 1 then
        -- 固定方块
        for k, v in ipairs(blockRuleTemplate.FixBlockXs) do
            -- 策划表里的x坐标都是从0开始的
            local block = self:AddBlock(stageData, blockRuleTemplate.FixBlockLengths[k], v + 1, targetY, blockRuleTemplate.FixBlockType[k])
            if block then
                table.insert(blocks, block)
            end
        end
        if blocks[#blocks]:GetTailGrid().x > stageTemplate.SizeX then
            XLog.Error(string.format("关卡%s方块生成规则配置错误 最多%s个 但配置了%s个", stageTemplate.Id, stageTemplate.SizeX, blocks[#blocks]:GetTailGrid().x))
        end
    else
        -- 随机方块
        local maxBlockLength = XMath.RandomByDoubleList(blockRuleTemplate.MaxBlockLengths, blockRuleTemplate.MaxBlockLengthWeights)
        if maxBlockLength <= 0 then
            XLog.Error(string.format("AddLine failed. maxBlockLength <= 0, maxBlockLength:%s,stageId:%s", maxBlockLength, stageData.StageId))
            return
        end
        -- 最大空格数
        local maxSpaceCount = stageTemplate.SizeX - maxBlockLength
        if maxSpaceCount <= 0 then
            XLog.Error(string.format("AddLine failed. maxSpaceCount < 0, maxSpaceCount:%s,stageId:%s", maxSpaceCount, stageData.StageId))
            return
        end
        -- 随机空格
        local spaceCount = XMath.RandomByDoubleList(blockRuleTemplate.SpaceCounts, blockRuleTemplate.SpaceCountWeights, maxSpaceCount)
        if spaceCount <= 0 then
            XLog.Error(string.format("AddLine Error. spaceCount <= 0. spaceCount:%s, maxSpaceCount:%s, stageId:%s, lineNo:%s", spaceCount, maxSpaceCount, stageData.StageId, stageData.LastLineNo + 1))
            return
        end
        -- 所有参与洗牌的格子长度
        local blockLengths = { maxBlockLength }
        -- 加入空格
        for i = 1, spaceCount do
            table.insert(blockLengths, 0)
        end
        -- 有剩余长度，随机填充
        local fillBlockLength = stageTemplate.SizeX - maxBlockLength - spaceCount
        if fillBlockLength > 0 then
            local fillBlockCount = 1
            if fillBlockLength > 1 then
                -- 随机填充方块数
                fillBlockCount = XMath.RandomByDoubleList(blockRuleTemplate.FillBlockCounts, blockRuleTemplate.FillBlockCountWeights, fillBlockLength)
            end
            if fillBlockCount == fillBlockLength then
                -- 个数等于长度，全按1填充
                for i = 1, fillBlockCount do
                    table.insert(blockLengths, 1)
                end
            else
                -- 随机
                local remainLength = fillBlockLength
                for i = 0, fillBlockCount - 1 do
                    local maxLen = math.min(remainLength - (fillBlockCount - i) + 1, maxBlockLength)
                    local randomBlockLength = XTool.Random(1, maxLen)
                    table.insert(blockLengths, randomBlockLength)
                    remainLength = remainLength - randomBlockLength
                end
                -- 剩余长度, 按1填充
                if remainLength > 0 then
                    for i = 1, remainLength do
                        table.insert(blockLengths, 1)
                    end
                end
            end
        end

        XTool.Shuffle(blockLengths)
        -- 生成方块
        local x = 1
        for _, length in ipairs(blockLengths) do
            if length > 0 then
                local block = self:AddBlock(stageData, length, x, targetY)
                if block then
                    table.insert(blocks, block)
                end
            end
            x = x + (length > 0 and length or 1)
        end
    end
    -- 固定附加道具
    local remainBlocks = {}
    for _, block in pairs(blocks) do
        local itemId = self._MainControl:GetItemIdByBlockOnCreate(block:GetBlockType())
        if XTool.IsNumberValid(itemId) then
            block:SetItemId(itemId)
        else
            table.insert(remainBlocks, block)
        end
    end
    -- 随机附加道具
    self:AttachItemToBlocks(stageData, remainBlocks, itemRuleExpand)
    -- 更新生成行数
    stageData.LastLineNo = stageData.LastLineNo + 1
end

---@param stageData XFangKuaiStageData
---@param blocks XFangKuaiBlock[]
---@param itemRuleExpand XFangKuaiRuleExpand
function XFangKuaiCreate:AttachItemToBlocks(stageData, blocks, itemRuleExpand)
    if not itemRuleExpand then
        return
    end
    -- 大于等于最小行才执行逻辑
    local curLineNo = stageData.LastLineNo + 1
    if curLineNo < itemRuleExpand.MinKey then
        return
    end
    -- 从未生成道具, 初始化
    if stageData.NextItemLineNo == 0 then
        local minLineRuleTemplate = itemRuleExpand.Rules[itemRuleExpand.MinKey]
        stageData.NextItemLineNo = itemRuleExpand.MinKey + XTool.Random(minLineRuleTemplate.MinRefreshInterval, minLineRuleTemplate.MaxRefreshInterval)
    end
    -- 满足生成道具行数
    if curLineNo < stageData.NextItemLineNo then
        return
    end

    ---@type XTableFangKuaiStageItemRule
    local itemRuleTemplate = nil
    if curLineNo <= XTool.GetTableCount(itemRuleExpand.Rules) then
        itemRuleTemplate = itemRuleExpand.Rules[curLineNo]
    else
        itemRuleTemplate = itemRuleExpand.Rules[itemRuleExpand.MaxKey]
    end

    if not itemRuleTemplate then
        return
    end

    local itemIdx = XMath.RandByWeights(itemRuleTemplate.ItemIdWeights)
    local blockItemId = itemRuleTemplate.ItemIds[itemIdx]

    if not self._MainControl:GetItemConfig(blockItemId) then
        return
    end

    -- 选择随机一个方块进行附加
    ---@type XFangKuaiBlock[]
    local filteredBlocks = {}
    for _, block in pairs(blocks) do
        if block:GetBlockType() == XEnumConst.FangKuai.BlockType.Normal then
            table.insert(filteredBlocks, block)
        end
    end
    if #filteredBlocks == 0 then
        return
    end

    local blockIdx = XTool.Random(1, #filteredBlocks)
    local hitBlock = filteredBlocks[blockIdx]
    -- 设置道具
    hitBlock:SetItemId(blockItemId)
    -- 更新下次刷新行数
    stageData.NextItemLineNo = curLineNo + XTool.Random(itemRuleTemplate.MinRefreshInterval, itemRuleTemplate.MaxRefreshInterval)
end

--endregion

--region 填充新行

---方块消除使得场上方块少于两行 补充方块 && 进入下一回合 自动上升一行
---@return XFangKuaiStageData
function XFangKuaiCreate:CreateNewLines(chapterId, addLine)
    local stageData = self._Model.ActivityData:GetStageData(chapterId)
    local stageTemplate = self._MainControl:GetStageConfig(stageData.StageId)
    self:FillLines(stageData, stageTemplate, addLine)
    return stageData
end

--endregion

--region 道具：以大化小

---@param data XFangKuaiBlock
---@return XFangKuaiBlock
function XFangKuaiCreate:CreateCopyBlockData(len, pos, data, itemId, chapterId)
    local stageData = self._Model.ActivityData:GetStageData(chapterId)
    stageData.LastBlockId = stageData.LastBlockId + 1

    ---@type XFangKuaiBlock
    local block = require("XUi/XUiFangKuai/XEntity/XFangKuaiBlock").New()
    block:CopyBlockData(stageData.LastBlockId, len, pos, data, itemId)

    stageData:AddBlock(block)

    return block
end

--endregion

return XFangKuaiCreate