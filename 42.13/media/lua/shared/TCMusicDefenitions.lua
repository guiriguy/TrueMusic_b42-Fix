require "TCM/Bootstrap"
do return end

-- @filename - TCMusicDefenitions.lua
-- require "TCMusicDefenitions"

--- Активирует отображение WO-бумбокса
-- @warning при включении данной функции нельзя вставлять кассеты
local DEBUG = false

if not TCMusic then TCMusic = {} end
if (TCMusic.ItemMusicPlayer == nil) then TCMusic.ItemMusicPlayer = {} end
if (TCMusic.VehicleMusicPlayer == nil) then TCMusic.VehicleMusicPlayer = {} end
if (TCMusic.WorldMusicPlayer == nil) then TCMusic.WorldMusicPlayer = {} end
if (TCMusic.WalkmanPlayer == nil) then TCMusic.WalkmanPlayer = {} end
if (GlobalMusic == nil) then GlobalMusic = {} end

if DEBUG then
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoombox"] = "tsarcraft_music_01_35"
    TCMusic.WorldMusicPlayer["tsarcraft_music_01_34"] = "tsarcraft_music_01_35"
    TCMusic.WorldMusicPlayer["tsarcraft_music_01_35"] = "tsarcraft_music_01_35"
    TCMusic.WorldMusicPlayer["tsarcraft_music_01_62"] = "tsarcraft_music_01_35"
    TCMusic.WorldMusicPlayer["tsarcraft_music_01_36"] = "tsarcraft_music_01_36"
    TCMusic.WorldMusicPlayer["tsarcraft_music_01_37"] = "tsarcraft_music_01_36"
    TCMusic.WorldMusicPlayer["tsarcraft_music_01_63"] = "tsarcraft_music_01_36"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoombox"] = "tsarcraft_music_01_35"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCVinylplayer"] = "tsarcraft_music_01_36"
    TCMusic.VehicleMusicPlayer["Base.HamRadio1"] = "tsarcraft_music_01_35"
    TCMusic.VehicleMusicPlayer["Base.HamRadio2"] = "tsarcraft_music_01_35"
    TCMusic.VehicleMusicPlayer["Base.RadioBlack"] = "tsarcraft_music_01_35"
    TCMusic.VehicleMusicPlayer["Base.RadioRed"] = "tsarcraft_music_01_35"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkman"] = "tsarcraft_music_01_62"
else
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoombox"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["tsarcraft_music_01_34"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["tsarcraft_music_01_35"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["tsarcraft_music_01_62"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["tsarcraft_music_01_36"] = "tsarcraft_music_01_63"
    TCMusic.WorldMusicPlayer["tsarcraft_music_01_37"] = "tsarcraft_music_01_63"
    TCMusic.WorldMusicPlayer["tsarcraft_music_01_63"] = "tsarcraft_music_01_63"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoombox"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCVinylplayer"] = "tsarcraft_music_01_63"
    TCMusic.VehicleMusicPlayer["Base.HamRadio1"] = "tsarcraft_music_01_62"
    TCMusic.VehicleMusicPlayer["Base.HamRadio2"] = "tsarcraft_music_01_62"
    TCMusic.VehicleMusicPlayer["Base.RadioBlack"] = "tsarcraft_music_01_62"
    TCMusic.VehicleMusicPlayer["Base.RadioRed"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkman"] = "tsarcraft_music_01_62"
end

GlobalMusic["CassetteMainTheme"] = "tsarcraft_music_01_62"
GlobalMusic["VinylMainTheme"] = "tsarcraft_music_01_63"
