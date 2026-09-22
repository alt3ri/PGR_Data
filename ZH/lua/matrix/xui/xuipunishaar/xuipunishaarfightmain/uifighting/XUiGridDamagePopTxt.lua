--- 战斗受伤飘字（图片字方案：按位分解数字 + Image SetSprite，零 tostring/Text 顶点重建 GC）。
--- 池化管理：DamageNumberPlayer 的 XPool 管 grid 生命周期 + ImgDigit 外部池管数字位 Image。
--- grid Play 时从外部池按位取 Image，回收前归还（跨 grid 共享 Image 池）。
--- 颜色/样式由 DamageNumIcons1/2/3 三套图片字 + DamageNumIconIndex 位序→套索引 区分（无 Image.color 染色）。
---@class XUiGridDamagePopTxt: XUiNode
---@field protected _Control
---@field Parent
---@field PnlList UnityEngine.RectTransform 数字位容器（左对齐起点）
local XUiGridDamagePopTxt = XClass(XUiNode, "XUiGridDamagePopTxt")

local DAMAGE_ANIM_NAME = "Enable"
local DAMAGE_FALLBACK_MS = 10 * XScheduleManager.SECOND
local DIGIT_WIDTH = 0  -- 单数字位宽度(默认值）

-- sprite 路径缓存：[setIdx][digit] = path（首次读 ClientConfig 后缓存，后续零读取 GC）
local _SpritePathCache = {}
-- 套索引缓存：[digitCount] = setIdx（DamageNumIconIndex 按总位数→套，同飘字所有位共用一套，首次读后缓存）
local _IconIndexCache = {}

--- 取数字位 sprite 路径（缓存命中零开销）。
--- 套图按**总位数** digitCount 选（DamageNumIconIn dex[digitCount]=套索引），同飘字所有位共用一套图。
---@param digit number 数字 0-9
---@param digitCount number 总位数（如 3 位数 "125" → DamageNumIconIndex[3]）
---@return string sprite 路径
local function GetDigitSpritePath(digit, digitCount)
    local setIdx = _IconIndexCache[digitCount]
    if not setIdx then
        setIdx = XMVCA.XPunishaar:GetClientNumberByKey("DamageNumIconIndex", digitCount) or 1
        _IconIndexCache[digitCount] = setIdx
    end
    local setCache = _SpritePathCache[setIdx]
    if not setCache then
        setCache = {}
        _SpritePathCache[setIdx] = setCache
    end
    local path = setCache[digit]
    if not path then
        path = XMVCA.XPunishaar:GetClientStringByKey("DamageNumIcons" .. tostring(setIdx), digit + 1)
        setCache[digit] = path
    end
    return path
end

function XUiGridDamagePopTxt:OnStart()
    self._ActiveImgs = {}       -- 当前激活 Image 列表（从外部池取，回收归还）
    self._ActiveDigitCount = 0  -- 当前激活位数
    self._DigitBuf = {}         -- 数字分解 buffer（倒序 buf[1]=个位..buf[count]=最高位，零 GC）
end

--- 注入 ImgDigit 外部池取/还回调（DamageNumberPlayer 在 grid Play 前注入）。
---@param acquireCb function() → Image|nil
---@param releaseCb function(img)
function XUiGridDamagePopTxt:SetDigitPoolHandler(acquireCb, releaseCb)
    self._AcquireCb = acquireCb
    self._ReleaseCb = releaseCb
end

--- 按位分解数字到 _DigitBuf（倒序：buf[1]=个位 ... buf[count]=最高位），返位数。
function XUiGridDamagePopTxt:_SplitDigits(value)
    local buf = self._DigitBuf
    if value <= 0 then
        buf[1] = 0
        return 1
    end
    local count = 0
    local v = value
    while v > 0 do
        count = count + 1
        buf[count] = v % 10
        v = math.floor(v / 10)
    end
    return count
end

--- 播放一次飘字。
---@param value number 单段伤害值 atkPerHit
---@param isCrit boolean|nil 暴击态（预留，由套图区分，不染色）
function XUiGridDamagePopTxt:Play(value, isCrit)
    self:Open()
    if not self.PnlList or not self._AcquireCb then
        -- prefab 未配图位节点 或 池未注入：no-op + 直接触发完播回池
        -- （不播动画则 _OnFinished 不触发→grid 卡 _ActiveNumbers 不回池→池耗尽泄漏）
        self:_OnFinished()
        return
    end
    -- 按位分解（零字符串 GC）
    local count = self:_SplitDigits(value)
    -- 归还多余位（上次数 > 本次，先归还再重取，保证 Image 数量=本次 count）
    for i = count + 1, self._ActiveDigitCount do
        local img = self._ActiveImgs[i]
        if img and self._ReleaseCb then
            self._ReleaseCb(img)
        end
        self._ActiveImgs[i] = nil
    end
    -- 各位取 Image + 赋 sprite + 排列（高位在左：buf[count]..buf[1] → 位 1..count）
    for i = 1, count do
        local digit = self._DigitBuf[count - i + 1]  -- 高位在前
        local img = self._ActiveImgs[i]
        if not img then
            img = self._AcquireCb()
            if not img then
                break  -- 池空，缺位跳过
            end
            img.transform:SetParent(self.PnlList, false)
            self._ActiveImgs[i] = img

            if DIGIT_WIDTH == 0 then
                DIGIT_WIDTH = img.transform:GetUISizeDelta()
            end
        end
        local path = GetDigitSpritePath(digit, count)
        if not string.IsNilOrEmpty(path) then
            img:SetSprite(path)
        end
        
        img.transform:SetAnchoredPositionX((i - 1) * DIGIT_WIDTH)
        img.gameObject:SetActiveEx(true)
    end
    self._ActiveDigitCount = count

    self._OnFinishedHandler = self._OnFinishedHandler or handler(self, self._OnFinished)
    self:StopFallbackTimer()
    self._FallbackTimerId = XScheduleManager.ScheduleOnce(self._OnFinishedHandler, DAMAGE_FALLBACK_MS)

    self:PlayAnimation(DAMAGE_ANIM_NAME, self._OnFinishedHandler)
end

--- 注册完播回调（控制器注入，须 Play 前调，一次性）。
---@param cb function|nil cb(self)
function XUiGridDamagePopTxt:SetFinishedCallback(cb)
    self._OnFinishedCb = cb
end

--- 完播通知（PlayAnimation finCb 或超时兜底触发；幂等：双触发 cb 已清则 no-op）。
function XUiGridDamagePopTxt:_OnFinished()
    self:StopFallbackTimer()
    local cb = self._OnFinishedCb
    if cb then
        self._OnFinishedCb = nil
        cb(self)
    end
end

function XUiGridDamagePopTxt:StopFallbackTimer()
    if self._FallbackTimerId then
        XScheduleManager.UnSchedule(self._FallbackTimerId)
        self._FallbackTimerId = nil
    end
end

function XUiGridDamagePopTxt:_StopAnim()
    self:StopAnimation(DAMAGE_ANIM_NAME)
end

--- 入池前清理（XPool onRelease）：归还 Image 到外部池 + 清 grid 引用。
function XUiGridDamagePopTxt:ResetForReuse()
    self._OnFinishedCb = nil
    self:StopFallbackTimer()
    self:_StopAnim()
    -- 归还各位 Image 到外部池（sprite 不清——顶点固定无重建）
    if self._ReleaseCb then
        for i = 1, self._ActiveDigitCount do
            local img = self._ActiveImgs[i]
            if img then
                self._ReleaseCb(img)
            end
            self._ActiveImgs[i] = nil
        end
    end
    self._ActiveDigitCount = 0
    self:Close()
end

function XUiGridDamagePopTxt:OnDisable()
    self:_StopAnim()
    self:StopFallbackTimer()
end

function XUiGridDamagePopTxt:OnDestroy()
    self:_StopAnim()
    self:StopFallbackTimer()
    self._OnFinishedCb = nil
end

return XUiGridDamagePopTxt
