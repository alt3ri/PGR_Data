local CSTextManagerGetText = CS.XTextManager.GetText

local mathFloor = math.floor 

local MIN = 60
local HOUR = 3600
local DAY = 86400

local STR_MONTH = CSTextManagerGetText("Mouth")
local STR_WEEK = CSTextManagerGetText("Week")
local STR_DAY = CSTextManagerGetText("Day")
local STR_HOUR = CSTextManagerGetText("Hour")
local STR_MINUTE = CSTextManagerGetText("Minute") -- 分
local STR_MINUTES = CSTextManagerGetText("Minutes") -- 分钟
local STR_SECOND = CSTextManagerGetText("Second")

---@class XCoolTime
local XCoolTime = XClass(nil, "XCoolTime")

function XCoolTime:Ctor()
    local FormatType = XMVCA.XBigWorldCommon.CoolTimeFormat
    self._Format2Func = {
        [FormatType.Clock] = handler(self.GetClockTimeStr, self)
    }
end

function XCoolTime:GetTimeStr(second, timeFormatType)
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
    local min =  mathFloor((second % HOUR) / MIN)
    local sec = mathFloor(second % MIN)
    --显示为: 00:00:00
    return string.format("%02d:%02d:%02d", hour, min, sec)
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