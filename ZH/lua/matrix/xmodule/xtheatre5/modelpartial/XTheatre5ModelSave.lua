--- Model分部类，此处用于定义和本地缓存相关的读写逻辑
---@type XTheatre5Model
local XTheatre5Model = XClassPartial('XTheatre5Model')

local SAVE_KEY_PVP = 'PVP' -- 版本周期跟随PVP活动Id的缓存数据块
local SAVE_KEY_LONGTERM = 'LONGT_TERM' -- 长期有效的数据块，因肉鸽5为常驻玩法而特别定义，版本变更由迭代过程中人工处理。存读该数据块时需要特别注意可能存在的跨版本数据遗留风险
local LONG_TERM_VERSION = 1

function XTheatre5Model:InitLocalSave()
    -- 初始化PVP活动本地缓存的自定义版本读取接口
    self._SaveUtil:SetCustomVersionGetFunc(handler(self, self.PVPVersionGetFunc), SAVE_KEY_PVP)
    -- 初始化长期本地缓存的自定义版本读取接口
    self._SaveUtil:SetCustomVersionGetFunc(handler(self, self.LongTermVersionGetFunc), SAVE_KEY_LONGTERM)
end

--region Long Term

--- 获取长期数据块当前期数的接口
function XTheatre5Model:LongTermVersionGetFunc()
    return LONG_TERM_VERSION
end

--- 活动初见未进入的蓝点
function XTheatre5Model:CheckHasNoEnterReddot()
    return not self._SaveUtil:GetDataByBlockKey(SAVE_KEY_LONGTERM, 'NoEnterActivityMark')
end

--- 消除活动初见未进入的蓝点
function XTheatre5Model:MarkHasNoEnterReddot()
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_LONGTERM, 'NoEnterActivityMark', true)
end

function XTheatre5Model:IsNewSeason()
    local oldPopUpversion = self._SaveUtil:GetDataByBlockKey(SAVE_KEY_LONGTERM, "PopUpversion") or 0
    local newPopUpversion = self:GetTheatre5ClientConfigNum('PopUpversion')

    if newPopUpversion > oldPopUpversion then
        self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_LONGTERM, "PopUpversion", newPopUpversion)
        return true
    end
    return false
end

--endregion

--region PVP

--- 获取PVP当前期数的接口
function XTheatre5Model:PVPVersionGetFunc()
    return self:GetActivityId()
end

--- 新赛季开放蓝点
function XTheatre5Model:CheckHasNewPVPActivityReddot()
    return not self._SaveUtil:GetDataByBlockKey(SAVE_KEY_PVP, 'NewActivityMark')
end

--- 消除新赛季开放蓝点
function XTheatre5Model:MarkNewPVPActivityReddot()
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_PVP, 'NewActivityMark', true)
end

--endregion

--region PVE

--PVE入口红点
function XTheatre5Model:CheckHasNewPVEActivityReddot()
    return not self._SaveUtil:GetDataByBlockKey(SAVE_KEY_LONGTERM, 'PVEActivityReddot')
end

function XTheatre5Model:MarkNewPVEActivityReddot()
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_LONGTERM, 'PVEActivityReddot', true)
end

--endregion

--region 商店红点
--一天提醒一次
function XTheatre5Model:CheckLimitShopReddot()
    local recordTimeStamp = self._SaveUtil:GetDataByBlockKey(SAVE_KEY_LONGTERM, 'Theatre5ShopReddot') or 0
    local curDay = XTime.GetServerNowTimestamp()
    return recordTimeStamp < curDay
end

function XTheatre5Model:MarkLimitShopReddot()
    local nextDay = XTime.GetSeverNextRefreshTime()
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_LONGTERM, 'Theatre5ShopReddot', nextDay)
end

function XTheatre5Model:CheckShopNewReddot(shopDataId)
    return not self._SaveUtil:GetDataByBlockKey(SAVE_KEY_LONGTERM, 'Theatre5ShopNewReddot' .. shopDataId)
end

function XTheatre5Model:MarkShopNewReddot(shopDataId)
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_LONGTERM, 'Theatre5ShopNewReddot' .. shopDataId, true)
end

function XTheatre5Model:CheckTaskNewReddot(taskId)
    return not self._SaveUtil:GetDataByBlockKey(SAVE_KEY_LONGTERM, 'Theatre5TaskNewReddot' .. taskId)
end

function XTheatre5Model:MarkTaskNewReddot(taskId)
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_LONGTERM, 'Theatre5TaskNewReddot' .. taskId, true)
end

--endregion

return XTheatre5Model