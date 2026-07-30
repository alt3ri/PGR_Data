--- 通用BGM节奏面板
--- 左右对称向中心汇聚动画：圆点从两侧边缘向 ImgBase(中心) 移动，到达后消失并从边缘重新出发
---@class XUiPanelPBRMusicRhythm: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
---@field ImgBase @重音节拍点，固定在视图中心作为汇聚目标
---@field ImgYuan @节拍点预制，克隆为左右对称的一对，从两侧向中心移动
local XUiPanelPBRMusicRhythm = XClass(XUiNode, "XUiPanelPBRMusicRhythm")

local MS_PER_MINUTE = 60000
-- 配表 AccentBeatIndex 是 1-indexed（1=第一拍）
local ACCENT_INDEX_BASE = 1
-- 定时器间隔（ms），约60fps
local UPDATE_INTERVAL_MS = 16

function XUiPanelPBRMusicRhythm:OnStart()
    self._DotPool = {}
    self._DotCount = 0
    self._Timer = nil
    self._IsPlaying = false
    self._BgmCfg = nil
    self._IsFever = false

    -- 缓存模板 Y/Z
    local pos = self.ImgYuan.transform.localPosition
    self._DotPosY = pos.y
    self._DotPosZ = pos.z

    -- 隐藏预制体模板
    self.ImgYuan.gameObject:SetActiveEx(false)
end

function XUiPanelPBRMusicRhythm:OnDisable()
    self:_StopTimer()
end

--region 公开接口

--- 设置BGM配置并初始化节拍点布局
function XUiPanelPBRMusicRhythm:SetBgmCfg(bgmCfg, isFever)
    if not bgmCfg then
        return
    end
    self._BgmCfg = bgmCfg
    self._IsFever = isFever or false
    self:_CacheLayoutParams()
    self:_EnsureDotPool()
    self:_PositionImgBase()
end

--- 控制节拍动画播放/停止
function XUiPanelPBRMusicRhythm:SetPlaying(playing)
    self._IsPlaying = playing
    if playing then
        self:_StartTimer()
        self:_SetDotsVisible(true)
    else
        self:_StopTimer()
        self:_SetDotsVisible(false)
    end
end

--endregion

--region 布局参数

function XUiPanelPBRMusicRhythm:_CacheLayoutParams()
    local bgmCfg = self._BgmCfg

    -- 可视区域宽度
    local parentRect = self.ImgYuan.transform.parent:GetComponent(typeof(CS.UnityEngine.RectTransform))
    self._ViewWidth = parentRect.rect.width
    self._HalfViewWidth = self._ViewWidth / 2

    self._BeatsPerLoop = bgmCfg.BeatsPerLoop
    local bpm = bgmCfg.BeatsPerMinute or 0
    local beatInterval = bpm > 0 and (MS_PER_MINUTE / bpm) or 0
    self._LoopDurationMs = beatInterval * self._BeatsPerLoop
    self._Offset = bgmCfg.Offset or 0
    self._AccentOffset = math.max(0, ((bgmCfg.AccentBeatIndex or ACCENT_INDEX_BASE) - ACCENT_INDEX_BASE)) * beatInterval
end

--endregion

--region 对象池

function XUiPanelPBRMusicRhythm:_EnsureDotPool()
    -- 每个拍点需要左右一对：Common 1对(2个)，Fever BeatsPerLoop对(2N个)
    local numBeats = self._IsFever and self._BeatsPerLoop or 1
    local required = numBeats * 2
    local parent = self.ImgYuan.transform.parent

    for i = #self._DotPool + 1, required do
        local go = CS.UnityEngine.Object.Instantiate(self.ImgYuan.gameObject, parent)
        go:SetActiveEx(false)
        self._DotPool[i] = {
            gameObject = go,
        }
    end

    for i = required + 1, #self._DotPool do
        self._DotPool[i].gameObject:SetActiveEx(false)
    end

    self._DotCount = required
    self._NumBeats = numBeats
end

function XUiPanelPBRMusicRhythm:_SetDotsVisible(visible)
    for i = 1, self._DotCount do
        self._DotPool[i].gameObject:SetActiveEx(visible)
    end
end

--endregion

--region ImgBase 定位

function XUiPanelPBRMusicRhythm:_PositionImgBase()
    local pos = self.ImgBase.transform.localPosition
    XTool.SetLocalPosition(self.ImgBase, 0, pos.y, pos.z)
end

--endregion

--region 每帧更新

--- 核心动画公式：
--- 每个拍点 k 到达中心的时刻 = loopProgress = k / beatsPerLoop
--- travelFraction = (loopProgress - k/beatsPerLoop + 1) % 1
---   0 = 刚从边缘出发，1 = 到达中心（modulo 回到 0 = 重置到边缘）
--- distance = halfView * (1 - travelFraction)
--- 左点 posX = -distance，右点 posX = +distance
function XUiPanelPBRMusicRhythm:_Update()
    if not self._IsPlaying or not self._BgmCfg then
        return
    end

    local musicControl = self._Control.MusicControl
    if not musicControl:IsPlaying() then
        return
    end

    local elapsedMs = musicControl:GetPlayElapsedMs()
    local adjustedMs = elapsedMs - self._Offset - self._AccentOffset

    -- 循环进度 [0, 1)
    local loopDuration = self._LoopDurationMs
    local loopProgress = (adjustedMs % loopDuration) / loopDuration

    local beatsPerLoop = self._BeatsPerLoop
    local halfView = self._HalfViewWidth
    local posY = self._DotPosY
    local posZ = self._DotPosZ
    local numBeats = self._NumBeats

    for k = 0, numBeats - 1 do
        -- 该拍点的行进分数：0=边缘，接近1=中心
        local travelFraction = (loopProgress - k / beatsPerLoop + 1) % 1
        local distance = halfView * (1 - travelFraction)

        -- 左侧点
        local leftDot = self._DotPool[k * 2 + 1]
        XTool.SetLocalPosition(leftDot.gameObject, -distance, posY, posZ)

        -- 右侧点
        local rightDot = self._DotPool[k * 2 + 2]
        XTool.SetLocalPosition(rightDot.gameObject, distance, posY, posZ)
    end
end

--endregion

--region 定时器

function XUiPanelPBRMusicRhythm:_StartTimer()
    if self._Timer then
        return
    end
    self._Timer = XScheduleManager.ScheduleForever(handler(self, self._Update), UPDATE_INTERVAL_MS)
end

function XUiPanelPBRMusicRhythm:_StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

--endregion

return XUiPanelPBRMusicRhythm
