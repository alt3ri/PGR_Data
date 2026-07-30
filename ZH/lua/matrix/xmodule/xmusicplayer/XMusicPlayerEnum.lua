---@class XMusicPlayerEnum  
local XMusicPlayerEnum =  {}

XMusicPlayerEnum.TableKeyMusicPlayerAlbum = "MusicPlayerAlbum"

-- 播放循环模式
XMusicPlayerEnum.LoopType = {
    ListLoop   = 0, -- 列表循环
    SingleLoop = 1, -- 单曲循环
    RandomLoop = 2, -- 随机播放
}

-- 歌单类型
XMusicPlayerEnum.MusicListType = {
    unInit   = -1,
    Normal   = 0,
    Favorite = 1,
    BGM      = 2,
}

-- 切歌方向
XMusicPlayerEnum.MusicSwitchDirection = {
    Next = 1,   -- 下一首(正向)
    Prev = -1,  -- 上一首(反向)
    Jump = 0,   -- 跳转(最短路径)
}

XMusicPlayerEnum.MusicUsingStatus = {
    gain    = 0,
    NotGain = 1,
    TryOut  = 2,
}

XMusicPlayerEnum.MusicMainUIStatus = {
    mainCD = 0,
    musicList = 1,
    immerse = 2,
    immersePro = 3,
    CDListExpand = 4,
}

XMusicPlayerEnum.MusicListUIStatus = {
    normal = 0,
    manager = 1,
    search = 2
}

XMusicPlayerEnum.MusicUseStatus = {
    gain = 0,           -- 已获取
    unlock = 1,         -- 未获得
    limitedFree = 2     -- 限时免费
}

XMusicPlayerEnum.BgmMuiscTag = {
    AutoFinish = "bgm_autoFinish", -- 自动续播(本曲正常播完)
    Shutdown   = "bgm_shutdown",   -- 主动停止
}

-- UI按钮颜色
XMusicPlayerEnum.UiButtonColor = {
    Blue = "Blue", 
    Green   = "Green",
    Orange  = "Orange",
    Pink    = "Pink",
    Purple  = "Purple",
    Red     = "Red",
    Yellow  = "Yellow",
}

-- UiButtonColor 参考色 RGB 值（用于与背景主色做色相匹配）
XMusicPlayerEnum.UiButtonColorRgb = {
    Blue   = { 0.0, 0.5, 1.0 },
    Green  = { 0.0, 0.8, 0.2 },
    Orange = { 1.0, 0.6, 0.0 },
    Pink   = { 1.0, 0.4, 0.6 },
    Purple = { 0.6, 0.2, 0.9 },
    Red    = { 0.9, 0.2, 0.2 },
    Yellow = { 1.0, 0.9, 0.0 },
}

-- UI按钮控件键
XMusicPlayerEnum.UiSpriteKey = {
    BgmListBtn           = "BgmListBtnSprite",
    PlayMusicBtn         = "PlayMusicBtnSprite",
    StopMusicBtn         = "StopMusicBtnSprite",
    ListCellSelectedBg = "ListCellSelectedBgSprite",
}

-- UI材质控件键（与 MusicPlayerColorStyleRes 表字段名对应）
XMusicPlayerEnum.UiMaterialKey = {
    MusicCurve    = "MusicCurve",
    MusicCurve2   = "MusicCurve2",
    MusicCurve4   = "MusicCurve4",
    MusicHuan     = "MusicHuan",
    MusicHuan02   = "MusicHuan02",
    MusicHuan04   = "MusicHuan04",
    MusicGongxing = "MusicGongxing",
    Sanjiao2      = "Sanjiao2",
}

return XMusicPlayerEnum


