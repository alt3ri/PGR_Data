--- 局内控制器
---@type XDyeMergeGamingControl
local XDyeMergeGamingControl = XClassPartial("XDyeMergeGamingControl")

local TableKey = {
    DyeMergeBlocks = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    DyeMergeColorMapper = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Color' },
    DyeMergeBlocksConfig = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    DyeMergeColorMix = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
}

local TableArgsMapper = {
    StageMap = { XConfigUtil.ReadType.Int, XTable.XTableDyeMergeMap, "Row", XConfigUtil.TabScope.Control }
}

function XDyeMergeGamingControl:InitConfig()
    --初始化配置表
    self:InitConfigByTabKey("MiniActivity/DyeMerge", TableKey)
    
    --- 颜色字符串到颜色的映射，减少每次转换
    self._Str2Color = {}
end

function XDyeMergeGamingControl:_GetStageMapPath(stageId)
    local path = "Client/MiniActivity/DyeMerge/Maps/DyeMergeMap" .. tostring(stageId) .. ".tab"
    return path
end

---@return XTableDyeMergeMap[]
function XDyeMergeGamingControl:GetTableDyeMergeMapById(stageId)
    if XTool.IsNumberValid(stageId) then
        local path = self:_GetStageMapPath(stageId)
        
        if not self._TabConfig:ContainArgs(path) then
            self._TabConfig:AddSingleConfig(path, TableArgsMapper.StageMap)
        end
        
        local configs = self:GetAllConfigByPath(path)
        
        if not configs then
            XLog.Debug("[XTableDyeMergeMap] 文件尚不存在:", stageId)
            return
        end
        
        return configs
    end
end

---@return XTableDyeMergeBlocks
function XDyeMergeGamingControl:GetTableDyeMergeBlockById(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.DyeMergeBlocks, id, notips)
end

---@return XTableDyeMergeColorMapper
function XDyeMergeGamingControl:GetTableDyeMergeColorMapper(colorId, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.DyeMergeColorMapper, colorId, notips)
end

---@return XTableDyeMergeBlocksConfig
function XDyeMergeGamingControl:GetTableDyeMergeBlocksConfig(colorId, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.DyeMergeBlocksConfig, colorId, notips)
end

---@return XTableDyeMergeColorMix
function XDyeMergeGamingControl:GetTableDyeMergeColorMix(colorId, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.DyeMergeColorMix, colorId, notips)
end

function XDyeMergeGamingControl:GetCfgDyeMergeBlocksColor(colorId, isLineColor)
    local cfg = self:GetTableDyeMergeBlocksConfig(colorId)

    if not cfg then
        return CS.UnityEngine.Color.white
    end
    
    local colorStr = isLineColor and cfg.LineColor or cfg.ToggleColor

    if not self._Str2Color[colorStr] then
        local fixedColorStr = string.gsub(colorStr, "#", "")

        local color = XUiHelper.Hexcolor2Color(fixedColorStr)

        self._Str2Color[colorStr] = color
    end
    
    return self._Str2Color[colorStr]
end

--- 根据来源颜色列表和目标颜色，验证混色结果是否命中
--- 直接按 targetColor 查对应 ColorMapper 条目，比较 FromColors 是否匹配
--- 命中返回 targetColor，未命中返回 nil
---@param fromColors number[]
---@param targetColor number 目标方块的配置颜色 ID
---@return number|nil
function XDyeMergeGamingControl:GetMixedColorByFromColors(fromColors, targetColor)
    if XTool.IsTableEmpty(fromColors) then
        return nil
    end

    -- targetColor=0：接受任意有效颜色
    if targetColor == 0 then
        if #fromColors == 1 then
            return fromColors[1]
        end
        -- 多色：遍历所有 ColorMapper 条目，查找任意可合成的颜色
        local allMappers = self:GetAllConfigByTabKey(TableKey.DyeMergeColorMapper)
        if allMappers then
            for outputColorId, _ in pairs(allMappers) do
                if outputColorId ~= 0 then
                    local result = self:GetMixedColorByFromColors(fromColors, outputColorId)
                    if result then
                        return result
                    end
                end
            end
        end
        return nil
    end

    if not XTool.IsNumberValidEx(targetColor) then
        return nil
    end

    local cfg = self:GetTableDyeMergeColorMapper(targetColor)
    if not cfg or XTool.IsTableEmpty(cfg.FromColors) then
        return nil
    end

    local fromList = cfg.FromColors
    if #fromList ~= #fromColors then
        return nil
    end

    local sortedInput = {}
    for _, v in ipairs(fromColors) do
        table.insert(sortedInput, v)
    end
    table.sort(sortedInput)

    local sortedCfg = {}
    for _, v in ipairs(fromList) do
        table.insert(sortedCfg, v)
    end
    table.sort(sortedCfg)

    for i = 1, #sortedInput do
        if sortedInput[i] ~= sortedCfg[i] then
            return nil
        end
    end

    return targetColor
end

--- 尝试将两个颜色混合，遍历所有 ColorMapper 条目查找匹配
--- 返回混合后的颜色 ID，无法混合时返回 nil
---@param color1 number
---@param color2 number
---@return number|nil
function XDyeMergeGamingControl:TryMixTwoColors(color1, color2)
    local allMappers = self:GetAllConfigByTabKey(TableKey.DyeMergeColorMapper)
    if not allMappers then return nil end

    local pair = { color1, color2 }
    for outputColorId, _ in pairs(allMappers) do
        local result = self:GetMixedColorByFromColors(pair, outputColorId)
        if result then
            return result
        end
    end
    return nil
end

--- 判断地图格值是否为有效的方块配置 ID（严格正整数）
--- 仅正整数 id 对应方块配置表中的有效条目
---@param id any
---@return boolean
function XDyeMergeGamingControl:IsValidBlockId(id)
    return type(id) == 'number' and id > 0
end

--- 判断棋盘格 (x, y) 在配置中是否为有效格（配置值 >= -1）
--- 有效格包含：空格（id=0）、替代地板格（id=-1）和有方块的格（id>0）
--- 无效格（id<-1）表示棋盘"洞"，不生成地板也不放方块
---@param x number 列号（1-based）
---@param y number 行号（1-based）
---@return boolean isValid, number|nil id
function XDyeMergeGamingControl:IsGridValid(x, y)
    local stageCfg = self:GetTableDyeMergeMapById(self._CurStageId)
    if not stageCfg then return false end
    local row = stageCfg[y]
    if not row or not row.Columns then return false end
    local id = row.Columns[x]
    return type(id) == 'number' and id >= -1, id
end

--- 判断坐标 (x, y) 是否存在不可移动方块
--- 供 UI 层 InitFloorMap 在生成地板时跳过不可移动方块占据的格子
---@param x number 列号（1-based）
---@param y number 行号（1-based）
---@return boolean
function XDyeMergeGamingControl:IsImmovableBlockAt(x, y)
    return self.BlocksControl:CheckIsImmovableBlockAtPos(self:Vec2ToIndex(x, y))
end

return XDyeMergeGamingControl