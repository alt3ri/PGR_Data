local XUiPBRBaseWaveGrid = require('XUi/XUiPBRGame/XUiPBRShopNew/RoundPanel/XUiPBRBaseWaveGrid')
---@class XUiPBRNormalWaveGrid: XUiPBRBaseWaveGrid
---@field protected _Control XPBRGameControl
---@field Parent
local XUiPBRNormalWaveGrid = XClass(XUiPBRBaseWaveGrid, "XUiPBRNormalWaveGrid")

function XUiPBRNormalWaveGrid:AOPBeforeRefresh(nextWaveIndex)
    self.ImgNormalBg.gameObject:SetActiveEx(false)
    self.TxtNum.gameObject:SetActiveEx(false)
    self.ImgEliteBg.gameObject:SetActiveEx(false)
    self.ImgEliteIcon.gameObject:SetActiveEx(false)
end

function XUiPBRNormalWaveGrid:AOPAfterRefresh(nextWaveIndex)
    local waveCfg = self._Control.InGameControl:GetTablePBRMonsterWaveCfgById(self.WaveId)

    if waveCfg then
        -- 如果已完成了，显示普通节点背景和完成图标即可
        if self.WaveIndex < nextWaveIndex then
            self.ImgNormalBg.gameObject:SetActiveEx(true)
            return
        end
        
        if waveCfg.IconType == XMVCA.XPBRGame.EnumConst.WaveShowType.Normal then
            self.ImgNormalBg.gameObject:SetActiveEx(true)
            self.TxtNum.gameObject:SetActiveEx(true)

            self.TxtNum.text = self.WaveIndex
        elseif waveCfg.IconType == XMVCA.XPBRGame.EnumConst.WaveShowType.Elite then
            self.ImgEliteBg.gameObject:SetActiveEx(true)
            self.ImgEliteIcon.gameObject:SetActiveEx(true)

            self.ImgEliteIcon:SetImage(waveCfg.IconAssets)
        elseif waveCfg.IconType == XMVCA.XPBRGame.EnumConst.WaveShowType.Boss then
            XLog.Error('波次节点是Boss节点，但使用了普通UI节点来显示')
        end
    end
end

return XUiPBRNormalWaveGrid