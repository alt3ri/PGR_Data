local XUiDlcMultiPlayerCompetitionBulletChatGrid = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerDiscussion/XUiDlcMultiPlayerCompetitionBulletChatGrid")
---@class XUiDlcMultiPlayerCompetitionBulletChat : XUiNode
---@field private _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerCompetitionBulletChat = XClass(XUiNode, "XUiDlcMultiPlayerCompetitionBulletChat")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionCamp
-- 偏移量，用于弹幕初始和结束位置（像素）
local DanmakuOffsetX = 100
-- 弹幕宽度（像素）
local DanmakuWidth = 800

function XUiDlcMultiPlayerCompetitionBulletChat:OnStart()
    self.GridBulletChat.gameObject:SetActiveEx(false)
    -- 弹幕池数据
    ---@type XDlcMultiplayerDanmakuData[]
    self._DanmakuDataList1 = {}     -- 阵营1的弹幕数据列表
    ---@type XDlcMultiplayerDanmakuData[]
    self._DanmakuDataList2 = {}     -- 阵营2的弹幕数据列表
    self._CurrentPool1Index = 1     -- 当前发射的弹幕池1索引
    self._CurrentPool2Index = 1     -- 当前发射的弹幕池2索引
    self._CurrentPoolFlag = 1       -- 当前使用的弹幕池标志 (1或2)

    -- 轨道管理
    ---@type XUiDlcMultiPlayerCompetitionBulletChatRail[]
    self._Rails = {}        -- 轨道列表，每个轨道记录当前的弹幕数量
    self._RailHeight = 0    -- 轨道高度
    self._RailNum = 0       -- 轨道数量

    -- 弹幕对象池
    ---@type XUiDlcMultiPlayerCompetitionBulletChatActiveDanmaku[]
    self._ActiveDanmakuList = {}    -- 活跃的弹幕对象列表
    ---@type XUiDlcMultiPlayerCompetitionBulletChatGrid[]
    self._DanmakuGridPool = {}      -- 弹幕对象池

    -- 弹幕追踪（防止同一条弹幕重复出现在屏幕上）
    self._ActiveDanmakuKeys = {}    -- 当前活跃的弹幕唯一标识集合 {[key] = true}

    -- 定时器
    self._DanmakuShootTimer = nil

    -- 配置参数
    self._DanmakuPeriod = 0 -- 发射间隔
    self._DanmakuSpeed = 0  -- 飞行速度
    self._ScreenWidth = 0   -- 屏幕宽度
    self._ScreenHeight = 0  -- 屏幕高度

    -- 缓存配置
    self._CachedDanmakuDesc = nil -- 缓存弹幕描述配置

    -- 是否初始化完成
    self._IsInitialized = false
    -- 是否正在发射弹幕
    self._IsShooting = false
end

function XUiDlcMultiPlayerCompetitionBulletChat:OnDisable()
    self:_StopDanmakuShoot()
    self:_ClearAllDanmaku()
    self.Discussion = nil
    -- 重置状态标志
    self._IsInitialized = false
    self._IsShooting = false
    -- 清空弹幕池数据
    self._DanmakuDataList1 = {}
    self._DanmakuDataList2 = {}
    self._CurrentPool1Index = 1
    self._CurrentPool2Index = 1
    self._CurrentPoolFlag = 1
    -- 清空弹幕追踪
    self._ActiveDanmakuKeys = {}
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionBulletChat:Refresh(discussion)
    if not discussion then
        XLog.Error("XUiDlcMultiPlayerCompetitionBulletChat:Refresh - discussion is nil")
        return
    end

    self.Discussion = discussion
    -- 如果已经在发射，不重复请求
    if self._IsShooting then
        return
    end

    if self.RequestLock then
        return
    end
    self.RequestLock = true
    -- 请求弹幕数据
    XMVCA.XDlcMultiMouseHunter:RequestDlcMultiplayerDanmaku(function()
        self.RequestLock = false
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        if not self._IsInitialized then
            -- 初始化弹幕
            self:_InitDanmaku()
        end
        if not self._IsShooting then
            -- 加载弹幕池数据
            self:_LoadDanmakuPools()
            -- 开始发射弹幕
            self:_StartDanmakuShoot()
        end
    end)
end

--region 初始化弹幕
function XUiDlcMultiPlayerCompetitionBulletChat:_InitDanmaku()
    self:_LoadConfig()
    self:_InitRails()
    self._IsInitialized = true
end

function XUiDlcMultiPlayerCompetitionBulletChat:_LoadConfig()
    -- 从配置表获取参数
    local periodConfig = self._Control:GetDlcMultiplayerConfigConfigByKey("DanmakuPeriod")
    local speedConfig = self._Control:GetDlcMultiplayerConfigConfigByKey("DanmakuSpeed")
    local railNumConfig = self._Control:GetDlcMultiplayerConfigConfigByKey("DanmakuRailNum")
    local descConfig = self._Control:GetDlcMultiplayerConfigConfigByKey("DanmakuDesc")

    self._DanmakuPeriod = tonumber(periodConfig and periodConfig.Values[1]) or 1000
    self._DanmakuSpeed = tonumber(speedConfig and speedConfig.Values[1]) or 150
    self._RailNum = tonumber(railNumConfig and railNumConfig.Values[1]) or 6
    self._CachedDanmakuDesc = descConfig and descConfig.Values[1] or ""

    -- 获取屏幕尺寸
    self._ScreenWidth = self.PanelBulletChat.rect.width
    self._ScreenHeight = self.PanelBulletChat.rect.height
end

function XUiDlcMultiPlayerCompetitionBulletChat:_InitRails()
    self._Rails = {}
    self._RailHeight = self._ScreenHeight / self._RailNum

    for i = 1, self._RailNum do
        self._Rails[i] = {
            Index = i,
            Count = 0, -- 当前轨道上的弹幕数量
            YPosition = self._ScreenHeight - self._RailHeight * (i - 0.5), -- 轨道的Y位置
            LastDanmakuTime = 0, -- 上一个弹幕发射的时间戳
            LastDanmakuX = 0, -- 上一个弹幕发射时的X位置
            LastDanmakuWidth = DanmakuWidth -- 上一个弹幕的宽度
        }
    end
end

function XUiDlcMultiPlayerCompetitionBulletChat:_LoadDanmakuPools()
    local danmakuPools = self._Control:GetDanmakuPools()
    if XTool.IsTableEmpty(danmakuPools) then
        self._DanmakuDataList1 = {}
        self._DanmakuDataList2 = {}
        return
    end

    -- 加载阵营弹幕数据
    self:_LoadCampDanmaku(CampEnum.Camp1, danmakuPools)
    self:_LoadCampDanmaku(CampEnum.Camp2, danmakuPools)

    -- 随机排序两个弹幕池
    self:_ShuffleDanmakuPool(self._DanmakuDataList1)
    self:_ShuffleDanmakuPool(self._DanmakuDataList2)

    -- 重置索引和随机选择起始弹幕池
    self._CurrentPool1Index = 1
    self._CurrentPool2Index = 1
    self._CurrentPoolFlag = math.random(1, 2)
end

-- 加载指定阵营的弹幕数据
function XUiDlcMultiPlayerCompetitionBulletChat:_LoadCampDanmaku(camp, danmakuPools)
    local listKey = camp == CampEnum.Camp1 and "_DanmakuDataList1" or "_DanmakuDataList2"
    local campData = danmakuPools[camp]

    self[listKey] = {}
    if campData and campData.DanmakuList then
        for _, danmakuData in ipairs(campData.DanmakuList) do
            local newData = XTool.Clone(danmakuData)
            newData.Camp = camp
            table.insert(self[listKey], newData)
        end
    end
end

-- 随机排序弹幕池
function XUiDlcMultiPlayerCompetitionBulletChat:_ShuffleDanmakuPool(pool)
    if type(pool) ~= "table" or #pool <= 1 then
        return
    end

    local n = #pool
    for i = n, 2, -1 do
        local j = math.random(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
end
--endregion

--region 弹幕发射控制
-- 生成弹幕唯一标识
---@param danmakuData XDlcMultiplayerDanmakuData
function XUiDlcMultiPlayerCompetitionBulletChat:_GenerateDanmakuKey(danmakuData)
    return danmakuData.PlayerId
end

function XUiDlcMultiPlayerCompetitionBulletChat:_StartDanmakuShoot()
    self:_StopDanmakuShoot()
    if #self._DanmakuDataList1 == 0 and #self._DanmakuDataList2 == 0 then
        return
    end

    self:_ShootNextDanmaku()
    self._DanmakuShootTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:_StopDanmakuShoot()
            return
        end
        self:_ShootNextDanmaku()
    end, self._DanmakuPeriod)
    self._IsShooting = true
end

function XUiDlcMultiPlayerCompetitionBulletChat:_StopDanmakuShoot()
    if self._DanmakuShootTimer then
        XScheduleManager.UnSchedule(self._DanmakuShootTimer)
        self._DanmakuShootTimer = nil
    end
    self._IsShooting = false
end

function XUiDlcMultiPlayerCompetitionBulletChat:_ShootNextDanmaku()
    local danmakuData = self:_GetNextDanmakuData()
    if not danmakuData then
        return
    end

    -- 选择轨道
    local rail = self:_SelectRail()
    if not rail then
        return
    end

    -- 发射弹幕
    self:_ShootDanmaku(danmakuData, rail)
end

---@return XDlcMultiplayerDanmakuData
function XUiDlcMultiPlayerCompetitionBulletChat:_GetNextDanmakuData()
    -- 如果两个池子都为空，直接返回
    if #self._DanmakuDataList1 == 0 and #self._DanmakuDataList2 == 0 then
        return nil
    end

    -- 最多尝试的次数
    local maxAttempts = #self._DanmakuDataList1 + #self._DanmakuDataList2
    local attempts = 0

    while attempts < maxAttempts do
        attempts = attempts + 1

        -- 交替从两个弹幕池获取弹幕
        local danmakuData
        -- 尝试从当前池子获取
        if self._CurrentPoolFlag == 1 then
            danmakuData = self:_GetFromPool(self._DanmakuDataList1, "_CurrentPool1Index")
            self._CurrentPoolFlag = 2
        else
            danmakuData = self:_GetFromPool(self._DanmakuDataList2, "_CurrentPool2Index")
            self._CurrentPoolFlag = 1
        end
        -- 如果当前池子为空，从另一个池子获取
        if not danmakuData then
            if self._CurrentPoolFlag == 1 then
                danmakuData = self:_GetFromPool(self._DanmakuDataList1, "_CurrentPool1Index")
            else
                danmakuData = self:_GetFromPool(self._DanmakuDataList2, "_CurrentPool2Index")
            end
        end

        -- 如果获取到弹幕，检查是否已经在屏幕上
        if danmakuData then
            local danmakuKey = self:_GenerateDanmakuKey(danmakuData)
            if not self._ActiveDanmakuKeys[danmakuKey] then
                -- 这条弹幕不在屏幕上，可以发射
                return danmakuData
            end
            -- 这条弹幕已经在屏幕上，继续寻找下一条
        else
            -- 没有获取到弹幕，返回nil
            return nil
        end
    end

    -- 所有弹幕都在屏幕上，返回nil
    return nil
end

-- 从指定池子获取弹幕的辅助函数
function XUiDlcMultiPlayerCompetitionBulletChat:_GetFromPool(poolList, indexRef)
    if #poolList > 0 then
        local data = poolList[self[indexRef]]
        self[indexRef] = self[indexRef] + 1
        if self[indexRef] > #poolList then
            self[indexRef] = 1
        end
        return data
    end
    return nil
end

---@return XUiDlcMultiPlayerCompetitionBulletChatRail
function XUiDlcMultiPlayerCompetitionBulletChat:_SelectRail()
    if #self._Rails == 0 then
        return nil
    end

    local currentTime = XTime.GetServerNowTimestamp()
    local startX = DanmakuOffsetX

    -- 找出可用的轨道（不会发生重叠的轨道）
    local availableRails = {}
    for _, rail in ipairs(self._Rails) do
        if self:_CanShootOnRail(rail, startX, currentTime) then
            table.insert(availableRails, rail)
        end
    end

    -- 如果没有可用轨道，返回nil（稍后重试）
    if #availableRails == 0 then
        return nil
    end

    -- 找出弹幕数量最少的轨道
    local minCount = math.huge
    for _, rail in ipairs(availableRails) do
        if rail.Count < minCount then
            minCount = rail.Count
        end
    end

    -- 收集所有弹幕数量最少的可用轨道
    local candidateRails = {}
    for _, rail in ipairs(availableRails) do
        if rail.Count == minCount then
            table.insert(candidateRails, rail)
        end
    end

    -- 随机选择一个轨道
    if #candidateRails > 0 then
        return candidateRails[math.random(1, #candidateRails)]
    end
    return nil
end

-- 检查是否可以在指定轨道上发射弹幕（不会重叠）
---@param rail XUiDlcMultiPlayerCompetitionBulletChatRail
---@param startX number 弹幕起始X位置
---@param currentTime number 当前时间戳
---@return boolean
function XUiDlcMultiPlayerCompetitionBulletChat:_CanShootOnRail(rail, startX, currentTime)
    -- 如果轨道上没有弹幕，可以直接发射
    if rail.Count == 0 then
        return true
    end
    -- 计算上一个弹幕移动的时间（秒）
    local elapsedTime = currentTime - rail.LastDanmakuTime
    -- 计算上一个弹幕当前的位置（像素）
    local lastDanmakuCurrentX = rail.LastDanmakuX - (self._DanmakuSpeed * elapsedTime)
    -- 计算上一个弹幕的右边缘位置
    local lastDanmakuRightEdge = lastDanmakuCurrentX + rail.LastDanmakuWidth
    -- 检查是否有足够的空间发射新弹幕（需要有一定的间隔）
    return lastDanmakuRightEdge < startX
end

---@param danmakuData XDlcMultiplayerDanmakuData
---@param rail XUiDlcMultiPlayerCompetitionBulletChatRail
function XUiDlcMultiPlayerCompetitionBulletChat:_ShootDanmaku(danmakuData, rail)
    -- 从对象池获取或创建弹幕对象
    local danmakuGrid = self:_GetDanmakuObject()
    if not danmakuGrid then
        return
    end

    local danmakuKey = self:_GenerateDanmakuKey(danmakuData)
    -- 记录弹幕追踪，防止重复出现
    self._ActiveDanmakuKeys[danmakuKey] = true

    -- 刷新弹幕内容
    danmakuGrid:Open()
    danmakuGrid:Refresh(danmakuData, self.Discussion)

    -- 设置初始位置（屏幕右侧）
    local startX = DanmakuOffsetX
    local yPos = rail.YPosition
    danmakuGrid:SetAnchoredPosition(startX, yPos)

    -- 增加轨道计数，并记录发射时间和位置
    rail.Count = rail.Count + 1
    rail.LastDanmakuTime = XTime.GetServerNowTimestamp()
    rail.LastDanmakuX = startX
    rail.LastDanmakuWidth = danmakuGrid:GetWidth()
    -- 计算移动距离和时间   
    local endX = -self._ScreenWidth - danmakuGrid:GetWidth() - DanmakuOffsetX
    local distance = startX - endX
    local moveTime = distance / self._DanmakuSpeed

    -- 记录弹幕对象
    ---@type XUiDlcMultiPlayerCompetitionBulletChatActiveDanmaku
    local danmakuInfo = {
        DanmakuGrid = danmakuGrid,
        Rail = rail,
        DanmakuKey = danmakuKey
    }
    table.insert(self._ActiveDanmakuList, danmakuInfo)
    -- 显示弹幕对象
    danmakuGrid:Show()

    local playerName = danmakuData.PlayerName
    local railIndex = rail.Index

    -- 使用Tween移动弹幕
    danmakuGrid:MoveToX(endX, moveTime, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        -- 移动结束，减少轨道计数
        if rail and rail.Count > 0 then
            rail.Count = rail.Count - 1
        end
        -- 移除弹幕追踪
        self._ActiveDanmakuKeys[danmakuKey] = nil
        -- 回收弹幕对象
        self:_RecycleDanmakuObject(danmakuGrid)
        CS.UnityEngine.Debug.Log("测试-> 弹幕结束:" .. playerName .. " 轨道:" .. railIndex, danmakuGrid.GameObject)
    end)
    CS.UnityEngine.Debug.Log("测试-> 弹幕开始:" .. playerName .. " 轨道:" .. railIndex, danmakuGrid.GameObject)
end
--endregion

--region 弹幕对象池管理
---@return XUiDlcMultiPlayerCompetitionBulletChatGrid
function XUiDlcMultiPlayerCompetitionBulletChat:_GetDanmakuObject()
    local danmakuGrid
    -- 从对象池获取
    if #self._DanmakuGridPool > 0 then
        danmakuGrid = table.remove(self._DanmakuGridPool)
    else
        -- 创建新的弹幕对象
        local danmakuObj = XUiHelper.Instantiate(self.GridBulletChat, self.PanelBulletChat)
        danmakuGrid = XUiDlcMultiPlayerCompetitionBulletChatGrid.New(danmakuObj, self, self._CachedDanmakuDesc)
    end
    return danmakuGrid
end

---@param danmakuGrid XUiDlcMultiPlayerCompetitionBulletChatGrid
function XUiDlcMultiPlayerCompetitionBulletChat:_RecycleDanmakuObject(danmakuGrid)
    if not danmakuGrid then
        return
    end
    -- 从活跃列表移除
    local found = false
    for i = #self._ActiveDanmakuList, 1, -1 do
        if self._ActiveDanmakuList[i].DanmakuGrid == danmakuGrid then
            table.remove(self._ActiveDanmakuList, i)
            found = true
            break
        end
    end
    if found then
        -- 隐藏并放入对象池
        danmakuGrid:Hide()
        table.insert(self._DanmakuGridPool, danmakuGrid)
    end
end

function XUiDlcMultiPlayerCompetitionBulletChat:_ClearAllDanmaku()
    -- 停止所有弹幕的移动
    for _, danmakuInfo in ipairs(self._ActiveDanmakuList) do
        local grid = danmakuInfo.DanmakuGrid
        if grid then
            grid:Hide()
            table.insert(self._DanmakuGridPool, grid)
        end
        if danmakuInfo.Rail and danmakuInfo.Rail.Count > 0 then
            danmakuInfo.Rail.Count = danmakuInfo.Rail.Count - 1
        end
        if danmakuInfo.DanmakuKey then
            self._ActiveDanmakuKeys[danmakuInfo.DanmakuKey] = nil
        end
    end
    self._ActiveDanmakuList = {}
end
--endregion

--region 添加弹幕
-- 添加自己的弹幕数据
---@param camp number 阵营
function XUiDlcMultiPlayerCompetitionBulletChat:AddOwnDanmakuData(camp)
    local newDanmakuData = {
        PlayerId = XPlayer.Id,
        PlayerName = XPlayer.Name,
        HeadPortraitId = XPlayer.CurrHeadPortraitId,
        HeadFrameId = XPlayer.CurrHeadFrameId,
        BpLevel = self._Control:GetBpLevel(),
        Camp = camp
    }

    local listKey = camp == CampEnum.Camp1 and "_DanmakuDataList1" or "_DanmakuDataList2"
    local indexKey = camp == CampEnum.Camp1 and "_CurrentPool1Index" or "_CurrentPool2Index"

    if #self[listKey] == 0 then
        table.insert(self[listKey], newDanmakuData)
    else
        local insertIndex = self[indexKey]
        if insertIndex > #self[listKey] then
            insertIndex = 1
        end
        table.insert(self[listKey], insertIndex, newDanmakuData)
    end
    self:_StartDanmakuShoot()
end
--endregion

return XUiDlcMultiPlayerCompetitionBulletChat

---@class XUiDlcMultiPlayerCompetitionBulletChatRail
---@field Index number 轨道索引
---@field Count number 当前轨道上的弹幕数量
---@field YPosition number 轨道的Y位置
---@field LastDanmakuTime number 上一个弹幕发射的时间戳
---@field LastDanmakuX number 上一个弹幕发射时的X位置
---@field LastDanmakuWidth number 上一个弹幕的宽度

---@class XUiDlcMultiPlayerCompetitionBulletChatActiveDanmaku
---@field DanmakuGrid XUiDlcMultiPlayerCompetitionBulletChatGrid 弹幕对象
---@field Rail XUiDlcMultiPlayerCompetitionBulletChatRail 弹幕所在轨道
---@field DanmakuKey string 弹幕唯一标识
