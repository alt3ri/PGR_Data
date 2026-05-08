---@class XUiTheatre6PopupBuffDetail : XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6PopupBuffDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupBuffDetail")

local EffectTab = 1
local DestoryTab = 2

function XUiTheatre6PopupBuffDetail:OnAwake()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnTanchuangCloseWhite:AddEventListener(handler(self, self.Close))
end

---@param buffSaveDatas XTheatre6BuffSaveDataProtocol[] 存档Buff数据，为空时显示当前关卡Buff数据
function XUiTheatre6PopupBuffDetail:OnStart(buffSaveDatas)
    if buffSaveDatas then
        --显示存档Buff数据
        self._BuffSaveDatas = buffSaveDatas
        return
    end
    
    local modelData = self._Control:GetCurPlayModeData()

    self._TabInfo = {}

    local buffs = self._Control:FilterCharacterShowBuffs(modelData.Buffs)
    self._TabInfo[EffectTab] = {}
    self._TabInfo[EffectTab].Count = XTool.GetTableCount(buffs)
    self._TabInfo[EffectTab].Datas = buffs

    buffs = self._Control:FilterCharacterShowBuffs(modelData.DestroyedBuffs)
    self._TabInfo[DestoryTab] = {}
    self._TabInfo[DestoryTab].Count = XTool.GetTableCount(buffs)
    self._TabInfo[DestoryTab].Datas = buffs
end

function XUiTheatre6PopupBuffDetail:OnEnable()
    if self._BuffSaveDatas then
        self:ShowFileSaveBuff()
    else
        self:ShowModelDataBuff()
    end
end

function XUiTheatre6PopupBuffDetail:ShowFileSaveBuff()
    local buffs = self._Control:FilterFileSaveBuffs(self._BuffSaveDatas)
    local count = buffs and #buffs or 0
    local isEmpty = count == 0

    self.ListTab.gameObject:SetActiveEx(false)
    self.TxtEmptyStat.gameObject:SetActiveEx(isEmpty)
    self.ListBuff.gameObject:SetActiveEx(not isEmpty)

    if isEmpty then
        return
    end

    XUiHelper.RefreshCustomizedList(self.GridBuffDetail.parent, self.GridBuffDetail, count, function(i, go)
        local buffData = buffs[i]
        ---@type XUiPanelTheatre6BuffDetail
        local buffDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6BuffDetail").New(go, self)
        buffDetail:SetFileSaveBuff(buffData)
        buffDetail:IsBuffCanClick(false)
    end)
end

function XUiTheatre6PopupBuffDetail:ShowModelDataBuff()
    local effectCount, destoryCount = self._TabInfo[EffectTab].Count, self._TabInfo[DestoryTab].Count

    self.BtnEffectTab:SetName(effectCount)
    self.BtnDistoryTab:SetName(destoryCount)

    self.ListTab:Init({ self.BtnEffectTab, self.BtnDistoryTab }, function(index)
        self:ShowBuffList(index)
    end)
    self.ListTab:SelectIndex(effectCount > 0 and 1 or 2)
end

function XUiTheatre6PopupBuffDetail:ShowBuffList(index)
    local count = self._TabInfo[index].Count
    local isEmpty = count == 0

    self.TxtEmptyStat.gameObject:SetActiveEx(isEmpty)
    self.ListBuff.gameObject:SetActiveEx(not isEmpty)

    if isEmpty then
        return
    end
    
    local buffDatas = self._TabInfo[index].Datas
    XUiHelper.RefreshCustomizedList(self.GridBuffDetail.parent, self.GridBuffDetail, #buffDatas, function(i, go)
        local buffData = buffDatas[i]
        ---@type XUiPanelTheatre6BuffDetail
        local buffDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6BuffDetail").New(go, self)
        buffDetail:SetBuffInfo(buffData)
        buffDetail:IsBuffCanClick(false)
        buffDetail:SetBuffDestory(index == DestoryTab)
    end)
end

return XUiTheatre6PopupBuffDetail