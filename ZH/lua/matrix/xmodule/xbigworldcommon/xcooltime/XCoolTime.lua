local CSTextManagerGetText = CS.XTextManager.GetText

local mathFloor = math.floor

local MIN = 60
local HOUR = 3600
local DAY = 86400

local STR_MONTH = CSTextManagerGetText("Mouth")
local STR_WEEK = CSTextManagerGetText("Week")
local STR_DAY = CSTextManagerGetText("Day")
local STR_HOUR = CSTextManagerGetText("Hour")
local STR_MINUTE = CSTextManagerGetText("Minute")   -- 分
local STR_MINUTES = CSTextManagerGetText("Minutes") -- 分钟
local STR_SECOND = CSTextManagerGetText("Second")
local LESS_THAN = CSTextManagerGetText("LessThan")  -- 小于

---@class XCoolTime
local XCoolTime = XClass(nil, "XCoolTime")

function XCoolTime:Ctor()
    local FormatType = XMVCA.XBigWorldCommon.CoolTimeFormat
    self._Format2Func = {
        [FormatType.Clock] = handler(self, self.GetClockTimeStr),
        [FormatType.NewsReward] = handler(self, self.GetNewsRewardTimeStr),
    }
end

function XCoolTime:GetTimeStr(second, timeFormatType)
    timeFormatType = timeFormatType or XMVCA.XBigWorldCommon.CoolTimeFormat.Clock
    if not timeFormatType then
        return second
    end
    local format = self._Format2Func[timeFormatType]
    if format then
        return format(second)
    end
    return second
end

function XCoolTime:GetClockTimeStr(second)
    local hour = mathFloor(second / HOUR)
    local min = mathFloor((second % HOUR) / MIN)
    local sec = mathFloor(second % MIN)
    --显示为: 00:00:00
    return string.format("%02d:%02d:%02d", hour, min, sec)
end

--- 新闻奖励时间格式化
---	x ≥ 24小时         :  显示为{0}天，舍弃小数
--- 1小时 ≤ x < 24小时 :  显示为{0}小时，舍弃小数
--- 1分钟 ≤ x < 1小时  :  显示为{0}分钟，舍弃小数
--- x < 1分钟          :  显示为"小于1分钟"
function XCoolTime:GetNewsRewardTimeStr(second)
    local days, hours, min, sec = self:SplitTime(second)

    if days > 0 then
        return string.format("%d%s", days, STR_DAY)
    elseif hours > 0 then
        return string.format("%d%s", hours, STR_HOUR)
    elseif min > 0 then
        return string.format("%d%s", min, STR_MINUTES)
    end

    return string.format("%s1%s", LESS_THAN, STR_SECOND)
end

function XCoolTime:GetPlayTimeStr(second)
    local min = mathFloor(second / MIN)
    local sec = mathFloor(second % MIN)
    local millisecond = mathFloor((second - mathFloor(second)) * 100)
    -- 00:00.0  精确到毫秒，不显示小时
    return string.format("%02d:%02d:%02d", min, sec, millisecond)
end

function XCoolTime:SplitTime(second)
    local days = mathFloor(second / DAY)
    local hours = mathFloor((second % DAY) / HOUR)
    local min = mathFloor((second % HOUR) / MIN)
    local sec = mathFloor(second % MIN)

    return days, hours, min, sec
end

return XCoolTime
