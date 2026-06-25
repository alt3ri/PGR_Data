--- 局内控制器——负责地块状态管理
---@class XDyeMergeMapControl : XControl
---@field _MainControl XDyeMergeGamingControl
---@field private _Model XDyeMergeGameModel
local XDyeMergeMapControl = XClass(XControl, "XDyeMergeMapControl")

local LockMeta = {
    __newindex = function()
        XLog.Error('数据锁定中，禁止修改')
    end
}

function XDyeMergeMapControl:OnInit()

end

function XDyeMergeMapControl:AddAgencyEvent()

end

function XDyeMergeMapControl:RemoveAgencyEvent()

end

function XDyeMergeMapControl:OnRelease()

end

function XDyeMergeMapControl:ResetData()
    if self._MapList then
        setmetatable(self._MapList, nil)
    end
    self._MapList = nil
    self._RayUidMap = nil
    self._RayColorMap = nil
    self._IsLockMap = false
end

function XDyeMergeMapControl:Init(mapSizeX, mapSizeY)
    self._MapSizeX = mapSizeX
    self._MapSizeY = mapSizeY

    if self._MapList then
        setmetatable(self._MapList, nil)
    end

    self._MapList = {}       -- posIndex → uid，仅物理方块占位
    self._RayUidMap = {}     -- rayKey(posIndex*10+rayDir) → uid，射线方向槽
    self._RayColorMap = {}   -- rayKey(posIndex*10+rayDir) → colorId，射线颜色槽
    self._IsLockMap = false
end

function XDyeMergeMapControl:GetMapSizeX()
    return self._MapSizeX
end

function XDyeMergeMapControl:GetMapSizeY()
    return self._MapSizeY
end

function XDyeMergeMapControl:GetMapList()
    setmetatable(self._MapList, LockMeta)
    self._IsLockMap = true

    return self._MapList
end

function XDyeMergeMapControl:_BeginMapListModify()
    if self._IsLockMap then
        setmetatable(self._MapList, nil)
    end
end

function XDyeMergeMapControl:_EndMapListModify()
    if self._IsLockMap then
        setmetatable(self._MapList, LockMeta)
    end
end

--- 对坐标的越界判断
function XDyeMergeMapControl:CheckPosInMapIsValid(posX, posY)
    if posX < 1 or posX > self._MapSizeX then
        return false
    end

    if posY < 1 or posY > self._MapSizeY then
        return false
    end

    return true
end

--- 添加方块的影响位置
--- 物理方块（rayDir=nil）写入 _MapList；射线延伸（rayDir~=nil）写入方向槽
--- 物理方块与射线分离存储，不同方向的射线可在同格共存
---@param uid number 方块 uid
---@param index number 一维坐标索引
---@param rayDir number|nil 射线行进方向（1~4），物理方块传 nil
---@param rayColor number|nil 射线颜色，物理方块传 nil
function XDyeMergeMapControl:AddBlockInfluence(uid, index, rayDir, rayColor)
    if rayDir ~= nil then
        -- 射线延伸：写入方向槽，同方向覆盖，不同方向共存
        local rayKey = index * 10 + rayDir
        self._RayUidMap[rayKey] = uid
        self._RayColorMap[rayKey] = rayColor
        return
    end

    -- 物理方块：检查是否已有物理占位
    if XTool.IsNumberValidEx(self._MapList[index]) then
        -- 目标格已有物理方块，冲突，静默跳过（上游 AddNewBlock 阶段已有冲突保护）
        return
    end

    self:_BeginMapListModify()
    self._MapList[index] = uid
    self:_EndMapListModify()
end

--- 移除方块的影响位置（单格精确移除）
---@param uid number 方块 uid
---@param index number 一维坐标索引
---@param rayDir number|nil 射线方向，物理方块传 nil
function XDyeMergeMapControl:RemoveBlockInfluence(uid, index, rayDir)
    if rayDir ~= nil then
        local rayKey = index * 10 + rayDir
        if self._RayUidMap[rayKey] ~= uid then
            return
        end
        self._RayUidMap[rayKey] = nil
        self._RayColorMap[rayKey] = nil
        return
    end

    if not XTool.IsNumberValidEx(self._MapList[index]) then
        XLog.Error("[DyeMerge]位置一维索引：" .. tostring(index) .. ' 位置不存在任何占位，请勿重复移除')
        return
    end

    if self._MapList[index] ~= uid then
        XLog.Error("[DyeMerge]位置一维索引：" .. tostring(index) .. ' 位置上占位的uid与目标uid不一致，请勿错误移除. < ' .. tostring(uid) .. ', ' .. tostring(self._MapList[index]) .. '>')
        return
    end

    self:_BeginMapListModify()
    self._MapList[index] = nil
    self:_EndMapListModify()
end

--- 通过遍历的方式，移除地图上所有同uid的物理占位和射线占位
--- 地图不大时可以考虑该接口处理比较方便
function XDyeMergeMapControl:RemoveBlockInfluences(uid)
    self:_BeginMapListModify()

    for x = 1, self._MapSizeX do
        for y = 1, self._MapSizeY do
            local index = self._MainControl:Vec2ToIndex(x, y)

            if self._MapList[index] == uid then
                self._MapList[index] = nil
            end

            -- 移除该 uid 在该格所有方向的射线槽
            for dir = 1, 4 do
                local rayKey = index * 10 + dir
                if self._RayUidMap[rayKey] == uid then
                    self._RayUidMap[rayKey] = nil
                    self._RayColorMap[rayKey] = nil
                end
            end
        end
    end

    self:_EndMapListModify()
end

--- 仅移除同uid的射线延伸格，保留物理占位
--- 专为 RefreshTurnableRayInfluences 阶段1使用
function XDyeMergeMapControl:RemoveRayExtensionInfluences(uid)
    for x = 1, self._MapSizeX do
        for y = 1, self._MapSizeY do
            local index = self._MainControl:Vec2ToIndex(x, y)

            for dir = 1, 4 do
                local rayKey = index * 10 + dir
                if self._RayUidMap[rayKey] == uid then
                    self._RayUidMap[rayKey] = nil
                    self._RayColorMap[rayKey] = nil
                end
            end
        end
    end
end

--- 查询指定格子指定方向的射线信息
---@param index number 一维坐标索引
---@param rayDir number 射线方向（1~4）
---@return number|nil uid, number|nil color
function XDyeMergeMapControl:GetRayInfoByDir(index, rayDir)
    local rayKey = index * 10 + rayDir
    return self._RayUidMap[rayKey], self._RayColorMap[rayKey]
end

return XDyeMergeMapControl
