---@class XUiRadioSignRMSStrip : XUiNode
---@field PanelStrip1 UnityEngine.GameObject
---@field ImgStrip1 UnityEngine.UI.Image
---@field ImgStrip2 UnityEngine.UI.Image
---@field ImgStrip3 UnityEngine.UI.Image
---@field ImgStrip4 UnityEngine.UI.Image
---@field ImgStrip5 UnityEngine.UI.Image
---@field ImgStrip6 UnityEngine.UI.Image
---@field ImgStrip7 UnityEngine.UI.Image
local XUiRadioSignRMSStrip = XClass(XUiNode, "XUiRadioSignRMSStrip")

-- RMS 值范围：0-3
local RMS_MIN = 0
local RMS_MAX = 0.3
-- 格子数量
local STRIP_COUNT = 7
-- 随机模式更新间隔（毫秒）
local RANDOM_UPDATE_INTERVAL = 100

-- region 生命周期

function XUiRadioSignRMSStrip:OnStart()
    -- 缓存所有 ImgStrip 引用，使用 FindTransform 查找
    self._ImgStrips = {}
    for i = 1, STRIP_COUNT do
        local stripName = "ImgStrip" .. i
        local stripTransform = self.Transform:FindTransform(stripName)
        if stripTransform then
            self._ImgStrips[i] = stripTransform:GetComponent(typeof(CS.UnityEngine.UI.Image))
        end
    end
    
    -- 随机模式相关
    self._IsRandomMode = false              -- 是否处于随机模式
    self._RandomScheduleId = nil            -- 随机模式定时器ID
    self._CurrentRandomRms = 0              -- 当前随机 RMS 值
    
    -- 初始化所有格子为隐藏状态
    self:UpdateStrips(0)
end

-- endregion

-- region 公共方法

---更新 RMS 可视化显示
---@param rms number RMS 值（范围 0-3）
function XUiRadioSignRMSStrip:UpdateStrips(rms)
    -- 如果处于随机模式，使用随机值
    if self._IsRandomMode then
        rms = self._CurrentRandomRms
    end
    
    -- 将 RMS 值（0-3）映射到格子数量（0-7）
    -- 使用线性映射：rms / RMS_MAX * STRIP_COUNT
    local activeCount = math.floor((rms / RMS_MAX) * STRIP_COUNT + 0.5) -- 四舍五入
    -- 限制在 0-7 范围内
    activeCount = math.max(0, math.min(STRIP_COUNT, activeCount))
    
    -- 更新每个格子的显隐状态
    for i = 1, STRIP_COUNT do
        local imgStrip = self._ImgStrips[i]
        if imgStrip and imgStrip.gameObject then
            local shouldShow = i <= activeCount
            imgStrip.gameObject:SetActiveEx(shouldShow)
        end
    end
end

---启动随机模式（视频播放时使用）
function XUiRadioSignRMSStrip:StartRandomMode()
    if self._IsRandomMode then
        return -- 已经在随机模式
    end
    
    self._IsRandomMode = true
    self._CurrentRandomRms = 0
    
    -- 启动随机值更新定时器
    self._RandomScheduleId = XScheduleManager.ScheduleForever(function()
        -- 生成随机 RMS 值（0 到 RMS_MAX）
        -- 使用平滑的随机变化，避免跳跃太大
        local targetRms = math.random() * RMS_MAX
        -- 平滑过渡到目标值
        local diff = targetRms - self._CurrentRandomRms
        self._CurrentRandomRms = self._CurrentRandomRms + diff * 0.3 -- 每次更新30%的差值
        
        -- 更新显示
        self:UpdateStrips(self._CurrentRandomRms)
    end, RANDOM_UPDATE_INTERVAL, 0)
end

---停止随机模式（视频播放结束后恢复）
function XUiRadioSignRMSStrip:StopRandomMode()
    if not self._IsRandomMode then
        return -- 不在随机模式
    end
    
    self._IsRandomMode = false
    
    -- 停止随机值更新定时器
    if self._RandomScheduleId then
        XScheduleManager.UnSchedule(self._RandomScheduleId)
        self._RandomScheduleId = nil
    end
    
    -- 重置显示为 0
    self._CurrentRandomRms = 0
    self:UpdateStrips(0)
end

-- endregion

return XUiRadioSignRMSStrip

