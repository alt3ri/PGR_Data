--- 大巴扎战斗倍速外壳（Control 子控，挂 FightControl，battle-scoped）。
--- 职责：档位管理 + 持久化（经 Model._SaveUtil）+ GetSpeed 供 UI 显态。
--- 不驱动 updater——变速驱动归 FightControl:SetUpdaterSpeed（base 帧率在 updater/FightControl 内）。
--- 未来表现层动效契合经此扩展。
---@class XPunishaarSpeedController : XControl
---@field private _Speeds number[] 档位循环表（两档 1↔2）
---@field private _SpeedIndex number 当前档位索引
---@field private _Speed number 当前倍数
local XPunishaarSpeedController = XClass(XControl, "XPunishaarSpeedController")

local SPEEDS = { 1, 2 }       -- 倍速档位（两档 toggle 1↔2）
local DEFAULT_SPEED_INDEX = 1

function XPunishaarSpeedController:OnInit()
    self._Speeds = SPEEDS
    self._SpeedIndex = DEFAULT_SPEED_INDEX
    self._Speed = SPEEDS[DEFAULT_SPEED_INDEX]
end

function XPunishaarSpeedController:AddAgencyEvent()

end

function XPunishaarSpeedController:RemoveAgencyEvent()

end

function XPunishaarSpeedController:OnRelease()

end

--- 从持久化读取玩家偏好应用（FightControl:InitNewGame 调，跨局/跨登录偏好生效）。非法/缺失→默认档（#20）。
--- 只设本外壳档位状态，不驱动 updater（驱动由 FightControl:SetUpdaterSpeed 负责）。
function XPunishaarSpeedController:InitFromSave()
    local savedIndex = self._Model and self._Model:GetSavedSpeedIndex()
    if not XTool.IsNumberValidEx(savedIndex)
            or savedIndex < 1 or savedIndex > #self._Speeds then
        savedIndex = DEFAULT_SPEED_INDEX
    end
    self._SpeedIndex = savedIndex
    self._Speed = self._Speeds[savedIndex]
end

--- 设倍速（设档位 + 写持久化）。不驱动 updater。幂等：相同档位不重复写持久化（#40）。
---@param speed number 目标倍数（必须在 _Speeds 档位表内）
function XPunishaarSpeedController:SetSpeed(speed)
    if not XTool.IsNumberValidEx(speed) then
        return
    end
    local newIndex
    for i, s in ipairs(self._Speeds) do
        if s == speed then
            newIndex = i
            break
        end
    end
    if not newIndex then
        return
    end
    local sameSpeed = (self._SpeedIndex == newIndex)
    self._SpeedIndex = newIndex
    self._Speed = self._Speeds[newIndex]
    if not sameSpeed and self._Model then
        self._Model:SetSavedSpeedIndex(newIndex)
    end
end

--- 切换到下一档（UI toggle 1↔2 循环）
function XPunishaarSpeedController:ToggleSpeed()
    local nextIndex = (self._SpeedIndex % #self._Speeds) + 1
    self:SetSpeed(self._Speeds[nextIndex])
end

---@return number 当前倍数
function XPunishaarSpeedController:GetSpeed()
    return self._Speed
end

return XPunishaarSpeedController
