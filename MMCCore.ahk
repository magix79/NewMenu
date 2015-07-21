;номера окон:
;2-радио
;3-заставка
;4-диалоговое окно (да/нет)
;5-камера
;6-настройки звука
;7-настройки видео
;8-громкость
;9-mute
;10-трек
;11-частота
;12-входящий/активный/исходящий вызов
;13-выбор телефона для звонка
;14-настройка часов
;15-телефон
;16-кан панель
;18-окно уведомления
;19-настройки кан
;20-индикатор заданной температуры
;21-диалог редактирования значений
;22-SleepMessage
;23-ScrollMSG
;24-настройка уровней звука

#NoEnv
#SingleInstance ignore
SetBatchLines, 20ms
ListLines Off
SetControlDelay, 100
SetMouseDelay, 100
DetectHiddenWindows, on
CoordMode, Mouse, Screen

RegRead, InternalPath, HKEY_LOCAL_MACHINE, SOFTWARE\LadaTools, InternalPath
if InternalPath=
{
Run, \Windows\explorer.exe, , UseErrorLevel  
exitapp
}

RegRead, InstallPath, HKEY_LOCAL_MACHINE, SOFTWARE\LadaTools, InstallPath
if InstallPath=
{
Run, \Windows\explorer.exe, , UseErrorLevel
exitapp
}

RegRead, SplashScreen, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\LadaTools, SplashScreen

;создадим  MMCCore гуи
gosub MMCCoreGuiCreate

Volume(100)

RegRead, CarModel, HKEY_LOCAL_MACHINE, SOFTWARE\LadaTools, CarModel
IF(CarModel=)
	{
	CarModel=Other
	}
if (CarModel="Emu")
	{
	mmc21=
	}
else
	{
	IfExist, Program Files\MMC\MMC21.dll
	mmc21=Program Files\MMC\MMC21.dll
	IfExist, Program Files\MMC\MMC21v42.dll
	mmc21=Program Files\MMC\MMC21v42.dll
	IfExist, Program Files\MMC\MMC23.dll
	mmc21=Program Files\MMC\MMC23.dll
	}
	
if (CarModel<>"Emu")
	{
	IfExist, %A_ScriptDir%\OnError.ahk
	Run, \%InternalPath%\Start\AHK2THREAD.exe  %A_ScriptDir%\OnError.ahk, , UseErrorLevel
	}
	
MMC21_init=%mmc21%\MMC21_init
MMC21_uninit=%mmc21%\MMC21_uninit
Api_SetHwnd=%mmc21%\Api_SetHwnd
Api_SetActivateMode=%mmc21%\Api_SetActivateMode
Api_GetCurrentTime=%mmc21%\Api_GetCurrentTime
Api_SetCurrentTime=%mmc21%\Api_SetCurrentTime

mmc21hwnd:=DllCall("LoadLibrary", "Str", mmc21) ;загружаем
sleep, 250
DllCall(MMC21_init) ;инициализируем
sleep, 2250
gosub sethwnd

;зарегим сообщения
msg_ID := DllCall("RegisterWindowMessage", "str", "UWM_KEY-{20E33C37-C776-40ad-9AB0-D80BD031DB13}")
msgC_ID := DllCall("RegisterWindowMessage", "str", "UWM_COMAND-{20E33C37-C776-40ad-9AB0-D80BD031DB13}")
msg_AUD_VOL_ID := DllCall("RegisterWindowMessage", "str", "UWM_AUD_VOL-{20E33C37-C776-40ad-9AB0-D80BD031DB13}")
msg_KEY_MODE_ID := DllCall("RegisterWindowMessage", "str", "UWM_KEY_MODE-{20E33C37-C776-40ad-9AB0-D80BD031DB13}")
msg_PUSHENC_ID := DllCall("RegisterWindowMessage", "str", "UWM_KEY_PUSHENC-{20E33C37-C776-40ad-9AB0-D80BD031DB13}")
msg_POWERUP_ID := DllCall("RegisterWindowMessage", "str", "UWM_SYS_POWER_UP-{20E33C37-C776-40ad-9AB0-D80BD031DB13}")
msg_mute_ID := DllCall("RegisterWindowMessage", "str", "UWM_AUD_MUTE-{20E33C37-C776-40ad-9AB0-D80BD031DB13}")
msg_POWERDOWN_ID := DllCall("RegisterWindowMessage", "str", "UWM_SYS_POWER_DOWN-{20E33C37-C776-40ad-9AB0-D80BD031DB13}")

OnMessage(33541, "UWM_Nitrogen")
OnMessage(33550, "UWM_NitrogenState")

OnMessage(33533, "GPSReceive")

OnMessage(msg_ID, "UWM_KEY")
OnMessage(msgC_ID, "UWM_COMAND")
OnMessage(msg_AUD_VOL_ID, "UWM_AUD_VOL")
OnMessage(msg_KEY_MODE_ID, "UWM_KEY_MODE")
OnMessage(msg_PUSHENC_ID, "UWM_MessageENC")
OnMessage(msg_POWERUP_ID, "UWM_POWERUP")
OnMessage(msg_POWERDOWN_ID, "UWM_POWERDOWN")
OnMessage(msg_mute_ID, "UWM_MUTE")
OnMessage(0x4a, "Receive_WM_COPYDATA") 

;читаем ини
GuiControl,, CoreGUIText, Reading settings...
GuiControl,, LoadProgress, 40

#Include %A_ScriptDir%\MMCCoreIniRead.ahk

GuiControl,, CoreGUIText, Loading can and bt -dll...
GuiControl,, LoadProgress, 60
MMCCOREDLLHWND:=DllCall("LoadLibrary", "Str", MMCCoredll) ;загружаем MMCCoredll
DllCall("LoadLibrary", "Str", CanMMCdll) ;загружаем
DllCall("LoadLibrary", "Str", BluetoothMMCdll) ;загружаем

BT_Init_result:=DllCall(BT_Init, "Int", sethwnd) ;инициализируем
Can_Init_result:=DllCall(Can_Init, "Int", sethwnd) ;инициализируем

DllCall(Bt_Reset)
settimer, SetVisibleBT, -5000

;задаем сохраненные настройки звука и экрана
GuiControl,, CoreGUIText, Restore settings...
GuiControl,, LoadProgress, 80

ActivateMode=1
SetActivateMode(1)

gosub FistInit
gosub caminit
ChangeVolFromScript=1
DllCall(Aud_SetVolume,Int,SoundVolume)
IfExist, %A_ScriptDir%\MortScript\PlaySoundRun.mscr
Run, \%InternalPath%\Start\MortScript.exe  %A_ScriptDir%\MortScript\PlaySoundRun.mscr, , UseErrorLevel
GuiControl,, CoreGUIText, Searching update...
GuiControl,, LoadProgress, 100
gosub AutoUpdateCheck
;допы
#IncludeAgain %A_ScriptDir%\MMCCoreAddonsAutoRun.ahk
gosub SetTimeFromeMMC
gosub createsavertimer
gosub startclock

;прячем контролы MMCCore гуи
GuiControl, Hide, CoreGUISplash
GuiControl, Hide, CoreGUIText
GuiControl, Hide, LoadProgress

Process, Exist, NewMenu.exe
	if ErrorLevel=0
		{
		IfExist, \%InstallPath%\Menu\NewMenu.exe
		Run, \%InstallPath%\Menu\NewMenu.exe, , UseErrorLevel
		}

;прячем MMCCore гуи
Gui, Cancel

gosub ShowBTMuteIcon
gosub GPSAutoTimeUpdate
settimer,  GPSAutoTimeUpdate, 3600000
AUD_VOL:=DllCall(Aud_GetVolume)
AutoVolMin:=AUD_VOL
return

#IncludeAgain %A_ScriptDir%\MMCCoreMode_ENC.ahk

GPSReceive(wParam, lParam)
{
global
if(A_EventInfo<>0)
	{
	rstring=
	GPSTime=
	GPSDate=
	GPSCyrSpeed=
	GPSLat=
	GPSLon=
	GPSLatP=
	GPSLonP=
	GPSTrack=
	GPSStreeng:=clipboard
	if(GPSStreeng<>"NoGPSdata" and GPSStreeng)
		{
		StringSplit, word_array, GPSStreeng, `,
		if(word_array1="$GPRMC")
			{
				GPSTime=%word_array2%
				GPSDate=%word_array10%
				GPSCyrSpeed=%word_array8%
				GPSLat=%word_array4%
				GPSLatP=%word_array5%
				GPSLon=%word_array6%
				GPSLonP=%word_array7%
				GPSTrack=%word_array9%
				if (GosubOnGPSReceive)
					{
					gosub %GosubOnGPSReceive%
					}
			}

		}
	}
}

Receive_WM_COPYDATA(wParam, lParam)
{
global
if(SaverRuning=1 and SaverShowFreqAndTrack=1)
	{
	ControlGetText, active_title, static1, ahk_id %wparam%
	GuiControl, 3:, STrackText, %active_title%
	}
}

UWM_Nitrogen(wParam, lParam) 
{
if(A_EventInfo<>0)
	{
	;GuiControl,, CoreGUIText, nitro %wParam% %lParam% %A_EventInfo%
	if(wParam=80) ;Кнопка минимизации
		{
		}
	if(wParam=81) ;Кнопка закрытия
		{
		}
	if(wParam=82) ;Кнопка эквалайзера
		{
		gosub SoundSettingsStartGui
		}
	if(wParam=83) ;Кнопка бланк скрин
		{
		IfExist, %A_ScriptDir%\DelTrack.ahk
			Run, \%InternalPath%\Start\AHK2THREAD.exe  %A_ScriptDir%\DelTrack.ahk, , UseErrorLevel
		}
	}
}

UWM_NitrogenState(wParam, lParam) 
{
global
if(A_EventInfo<>0)
	{
	if(wParam=160) ;текущий трек
		{
		NitroCurTrack:=lParam
		if(TrackGuiRunning=1)
			{
			gosub updatetrackpos
			}
		if(SaverShowFreqAndTrack=1)
			{
			gosub RefreshSaverTrackPos
			}
		}
	if(wParam=161) ;всего треков
		{
		NitroAllTrack:=lParam
		if(SaverShowFreqAndTrack=1)
			{
			gosub RefreshSaverTrackPos
			}
		}
	if(wParam=162) ;стоп/след. трек
		{
		NitroTrackLen:=FormatSeconds(lParam) ;длина трека
		NitroTrackCurPos=00:00
		if(TrackGuiRunning=1)
			{
			gosub updatetracktime
			}
		if(SaverShowFreqAndTrack=1)
			{
			gosub RefreshSaverTrackTime
			}
		}
	if(wParam=165) ;воспроизведение
		{
		if(SaverShowFreqAndTrack=1)
			{
			NitroTrackCurPos:=FormatSeconds(lParam) ;текущее позиция проигрывания 
			gosub RefreshSaverTrackTime
			if(lParam<=3)
				{
				gosub RefreshSaverTrack
				}
			}
		}
		;GuiControl,, CoreGUIText, %NitroCurTrack% %NitroAllTrack% %NitroTrackLen% %NitroTrackCurPos%
	}
}

;смена громкости
UWM_AUD_VOL(wParam, lParam)
{
global
if(A_EventInfo<>0)
	{
	AUD_VOL:=DllCall(Aud_GetVolume)
	if(ActivateMode>2)
		{
		VolumeGain:=GetVolumeGain(AUD_VOL)
		DllCall(Audi_SetSetting, Int, 12, Int, VolumeGain)
		DllCall(Audi_SetSetting, Int, 13, Int, VolumeGain)
		}
	if (DashBoardRuning=1 and VIn7)
			{
			GuiControl, 17:, VolumeLevel, %AUD_VOL%
			}
	if(btvolchange=0)
			{
			SoundVolume:=AUD_VOL
			}
	if(ChangeVolFromScript=0)
		{
		ManualVolChange=1
		if(btvolchange=1)
			{
			BtVolume:=AUD_VOL
			}
		gosub NewAutoVolMin
		gosub RefreshVol
		}
	else
		{
		ChangeVolFromScript=0
		}
		;--------------------отладочная инфа
		;	GuiControl,, CoreGUIText, %AUD_VOL% %ChangeVolFromScript% %AutoVolMin% %AutoVolMax% %AutoVolMaxSpeed%
		;--------------------отладочная инфа
	}
}

NewAutoVolMin:
		if(AutoVolAllow=1 and btvolchange=0 and ChangeVolFromScript=0)
			{
			if(CanSpeed<AutoVolFromSpeed or CanSpeed=0)
				{
				AutoVolMin:=AUD_VOL
				}
			else 
				{
				AutoVolMin:=Round(AUD_VOL-(CanSpeed-AutoVolFromSpeed)/AutoVolSteep)
				}
			}
			
return

UWM_MUTE(wParam, lParam)
{
global
if(A_EventInfo<>0)
	{
		gosub Mute
		if(A_EventInfo<LastMuteEvent+1500)
			{
			gosub VolumeModeSwitch
			PlaySound("silent",0)
			}
		LastMuteEvent:=A_EventInfo
	}
}

UWM_POWERDOWN(wParam, lParam)
{
global
if(TripAutoResetOnPowerOFF=1)
{
gosub EndTrip
}
if(A_EventInfo<>0)
	{
		IF(NitrogenAutoClose=1)
		{
		AudioRunningOnExit=0
		Process, Exist, audio.exe
		if ErrorLevel<>0
			{
			AudioRunningOnExit=1
			}
		Process, Exist, NaviPlayer.exe
		if ErrorLevel<>0
			{
			AudioRunningOnExit=1
			}
		Process, Exist, LadaSound.exe
		if ErrorLevel<>0
			{
			AudioRunningOnExit=1
			}
		Process, Exist, LPlayer.exe
		if ErrorLevel<>0
			{
			AudioRunningOnExit=1
			}
		Process, Exist, itelmamenu.exe
		if ErrorLevel<>0
			{
			AudioRunningOnExit=1
			}
		IF (AudioRunningOnExit=1)
			{
			IfExist, %A_ScriptDir%\MortScript\Audiooff.mscr
			Run, \%InternalPath%\Start\MortScript.exe  %A_ScriptDir%\MortScript\Audiooff.mscr
			}
		}
		
		;DllCall("FreeLibrary", "UInt", BTDLLHWND) ;выгружаем
		;DllCall("FreeLibrary", "UInt", CANDLLHWND) ;выгружаем
		
		gosub ResetVar
		gosub StopSaver
		gosub DashBoardHide
		gosub resetallcanvalue
		gosub caminit
		DllCall(Api_SetSleepReady)
	}
}

UWM_POWERUP(wParam, lParam)
{
global
if(A_EventInfo<>0)
	{
		;DllCall(Api_Reset)
		gosub FistInit
		gosub caminit
		gosub AutoUpdateCheck
		;CANDLLHWND:=DllCall("LoadLibrary", "Str", CanMMCdll) ;загружаем
		;Can_Init_result:=DllCall(Can_Init, "Int", sethwnd) ;инициализируем
		gosub CANCHANGEACTIVE
		;BTDLLHWND:=DllCall("LoadLibrary", "Str", BluetoothMMCdll) ;загружаем
		;BT_Init_result:=DllCall(BT_Init, "Int", sethwnd) ;инициализируем
		gosub SetVisibleBT
		if(TripAutoResetOnPowerOFF=1)
			{
			settimer, savetrip, -2000
			}
		if(AudioRunningOnExit=1 and NitrogenAutoClose=1)
			{
			settimer, RunAudio, -3000
			}
		settimer,  GPSAutoTimeUpdate, -30000
		AUD_VOL:=DllCall(Aud_GetVolume)
	gosub NewAutoVolMin
	}
}

RunAudio:
IfExist, %A_ScriptDir%\MortScript\audio.mscr
			Run, \%InternalPath%\Start\MortScript.exe  %A_ScriptDir%\MortScript\audio.mscr
return

;команды ядру
UWM_COMAND(wParam, lParam)
{
global
if(A_EventInfo<>0)
	{
	SaverTickCount=0
		if (SaverRuning=1 and lParam <> 6 and lParam <> 8 and lParam <> 9)
			{
			gosub StopSaver
			}
;--------------------отладочная инфа
;	GuiControl,, CoreGUIText, Com %wParam% %lParam%
;--------------------отладочная инфа
		if (wParam=1 and lParam =1) ;запускаем настройки видео
			{
				gosub VideoSettingsStartGui
			}
		if (wParam=1 and lParam =2) ;запускаем настройки звука
			{
				gosub SoundSettingsStartGui
			}
		if (wParam=1 and lParam =4) ;запускаем настройки задней камеры
			{
				gosub RearCamSettingsStartGui
			}
		if (wParam=1 and lParam =5) ;навигация запустилась
			{
				NaviProgRuning=1
				gosub CheckNaviToSoundActivate
				RegRead, NaviProgRuningName, HKEY_LOCAL_MACHINE, SOFTWARE\LadaTools, NaviRuning
				SetTimer, NaviMove, -30000
				if(SoftKeyRuning=1)
					{
					gosub restartsoftkey
					}
			}
		if (wParam=1 and lParam =6) ;навигация закрылась
			{
				NaviProgRuning=0
				gosub CheckNaviToSoundActivate
				settimer,  GPSAutoTimeUpdate, -10000
				if(SoftKeyRuning=1)
					{
					gosub restartsoftkey
					}
			}
		if (wParam=1 and lParam =7) ;медиа запустилась
			{
				MediaProgRuning=1
				gosub HideCanOnMediaRun
			}
		if (wParam=1 and lParam =8) ;медиа закрылась
			{
				MediaProgRuning=0
				gosub HideCanOnMediaRun
			}
		if (wParam=1 and lParam =9) ;пустить сейвер
			{
				if (MediaProgRuning=0 and SaverRunAllow=1 and SaverRuning=0)
					{
					if (SaverActivate=1)
						{
						imediatlysaverrun=0
						SaverTickCount=0
						SetTimer, startsavertimer, off
						gosub startsaver
						}
					else if (SaverActivate=0)
						{
						SetTimer, startsaver, -1000
						}
					}
			}
		if (wParam=1 and lParam =10) ;выключить радио
			{
			gosub radiooff
			}
		if (wParam=1 and lParam =11) ;переключить звук бт
			{
			gosub BTSoundSwitch
			}
		if (wParam=1 and lParam =12) ;настройки бт
			{
			DllCall(BT_ShowWndSettings)
			}
		if (wParam=1 and lParam =13) ;настройки часов
			{
			gosub StartClockSettings
			}
		if (wParam=1 and lParam =14) ;запрет запуска сейвера
			{
			SaverRunAllow=0
			}
		if (wParam=1 and lParam =15) ;снять запрет запуска сейвера
			{
			SaverRunAllow=1
			}
		if (wParam=1 and lParam =16) ;закрыть настройки маршрутного компа
			{
			IniRead, TripAutoResetOnPowerOFF, %CanDashboardINI%, DashboardSettings, TripAutoResetOnPowerOFF
			IniRead, TripAutoResetOnCanOff, %CanDashboardINI%, DashboardSettings, TripAutoResetOnCanOff
			IniRead, TripSave, %CanDashboardINI%, DashboardSettings, TripSave
			}
		if (wParam=1 and lParam =18) ;запустились софт-кнопки
			{
			SoftKeyRuning=1
			if(NaviProgRuning=1)
				{
				gosub NaviMove
				}
			}
		if (wParam=1 and lParam =19) ;закрылись софт-кнопки
			{
			SoftKeyRuning=0
			if(NaviProgRuning=1)
				{
				gosub NaviMove
				}
			}
		if (wParam=1 and lParam =0) ;завершение работы скрипта
			{
			gosub GuiClose
			}
			gosub createsavertimer
			settimer, ShowBTMuteIcon, -3000
	}
}
return

UWM_KEY(wParam, lParam)
{
global
if(A_EventInfo<>0)
	{
	SaverTickCount=0
		if (SaverRuning=1 and wParam <> 4 and wParam <> 7 and wParam <> 8 and wParam <> 9 and wParam <> 11 and wParam <> 14 and wParam <> 0)
			{
			gosub StopSaver
			}
;--------------------отладочная инфа
;			GuiControl,, CoreGUIText, Key %wParam% %lParam%
;--------------------отладочная инфа
		Action:=Action_%wParam%_%lParam%
		Path:=Path_%wParam%_%lParam%
		if (Action="Run")
			{
			IfExist, %A_ScriptDir%\MortScript\%Path%
			Run, \%InternalPath%\Start\MortScript.exe  %A_ScriptDir%\MortScript\%Path%
			}
		if (Action="GoSub")
			{
			 Gosub %Path%
			}
		gosub createsavertimer
		settimer, ShowBTMuteIcon, -3000
		}
}

startsoftkey:
if(SoftKeyRuning=0)
	{		
	IfExist, %A_ScriptDir%\SoftKey.ahk
	Run, \%InternalPath%\Start\AHK2THREAD.exe  %A_ScriptDir%\SoftKey.ahk
	}
	else
	{
	IfExist, %A_ScriptDir%\MortScript\SoftKeyClose.mscr
	Run, \%InternalPath%\Start\MortScript.exe  %A_ScriptDir%\MortScript\SoftKeyClose.mscr
	SoftKeyRuning=0
		if(NaviProgRuning=1)
			{
			gosub NaviMove
			}
	}

return

restartsoftkey:
	IfExist, %A_ScriptDir%\MortScript\restartsoftkey.mscr
		Run, \%InternalPath%\Start\MortScript.exe  %A_ScriptDir%\MortScript\restartsoftkey.mscr
return

MuteApply:
MuteState:=DllCall(Api_GetMuteState)
if (MuteState=1)
{
DllCall(Api_SetMuteState, int, 0)
gosub mutehide
}
else
{
DllCall(Api_SetMuteState, int, 1)
gosub muteshow
}
return

VolUp:
AUD_VOL:=DllCall(Aud_GetVolume)
if (AUD_VOL<100)
{
ChangeVolFromScript=1
AUD_VOL+=1
DllCall(Aud_SetVolume, int, AUD_VOL)
}
return

VolDown:
AUD_VOL:=DllCall(Aud_GetVolume)
if (AUD_VOL>0)
{
ChangeVolFromScript=1
AUD_VOL-=1
DllCall(Aud_SetVolume, int, AUD_VOL)
}
return

Mute:
MuteState:=DllCall(Api_GetMuteState)
if (MuteState=1)
{
gosub muteshow
}
else
{
gosub mutehide
}
return

ButtonPress(CName, CVal1, CVal2, guinumber)
	{
	GuiControl, %guinumber%:Hide, %CName%
	GuiControl, %guinumber%:, %CName%, %CVal1%
	GuiControl, %guinumber%:Show, %CName%
	}

ButtonPressF(CName, CVal1, CVal2, guinumber)
	{
	GuiControl, %guinumber%:Hide, %CName%
	GuiControl, %guinumber%:, %CName%, %CVal2%
	GuiControl, %guinumber%:Show, %CName%
	Sleep, 200
	GuiControl, %guinumber%:Hide, %CName%
	GuiControl, %guinumber%:, %CName%, %CVal1%
	GuiControl, %guinumber%:Show, %CName%
	}

PlaySound(SoundName, InstantPlay)
	{
	global
	if (CSound=1 and BTActive=0 and InitState=0)
		{
		IfExist, %A_ScriptDir%\Sounds\%SoundName%.wav
			{
			IF(ActivateMode=0 and NaviSoundsOnRadio<>0)
				{
				if(NaviSoundsOnRadio=2)
					{
					SetActivateMode(8)
					}
					else if(NaviSoundsOnRadio=1)
					{
					SetActivateMode(7)
					}
					SetTimer, ReturnActivateModeLastState, -3500 
					SoundPlay, %A_ScriptDir%\Sounds\%SoundName%.wav
				}
			}
		else
			{
			IfExist, %A_ScriptDir%\Sounds\%SoundName%.wav
				{
				if(InstantPlay=1)
					{
					SoundPlay, %A_ScriptDir%\Sounds\%SoundName%.wav
					}
					else
					{
					RegNewSound(SoundName)
					}
				}
			}
		}
	}

RegNewSound(SoundName)
	{
	RegRead, PlaySoundNum, HKEY_LOCAL_MACHINE, SOFTWARE\LadaTools\PlaySound, SoundNum
	PlaySoundNum++
	RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\LadaTools\PlaySound, SoundNum, %PlaySoundNum%
	RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\LadaTools\PlaySound, SoundName%PlaySoundNum%, %SoundName%
	}

ReturnActivateModeLastState:
SetActivateMode(ActivateModeLastState)
return

GetVolumeGain(AUD_VOL)
{
VolumeGain:=94-AUD_VOL
if(VolumeGain>=0)
	{
	return VolumeGain
	}
	else
	{
	return 0
	}
}

SetActivateMode(mode)
{
;0-радио, 1-медиа, 2-бт, 3-бт фронт+радио тыл, 4-бт тыл+радио фронт, 5-бт фронт+медиа тыл, 6-бт тыл+медиа фронт, 7-медиа фронт+радио тыл, 8-медиа тыл+радио фронт,
global
ActivateModeLastState:=ActivateMode
if(mode=0)
	{
	DllCall(Audi_SetSetting, Int, 10, Int, 96)
	DllCall(Audi_SetSetting, Int, 11, Int, 96)
	DllCall(Audi_SetSetting, Int, 12, Int, 96)
	DllCall(Audi_SetSetting, Int, 13, Int, 96)
	DllCall(Audi_SetSetting, Int, 0, Int, 3)
	DllCall(Audi_SetSetting, Int, 7, Int, 3)
	VolumeGain:=GetVolumeGain(AUD_VOL)
	DllCall(Audi_SetSetting, Int, 10, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 11, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 12, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 13, Int, VolumeGain)
	}
else if(mode=1)
	{
	DllCall(Audi_SetSetting, Int, 10, Int, 96)
	DllCall(Audi_SetSetting, Int, 11, Int, 96)
	DllCall(Audi_SetSetting, Int, 12, Int, 96)
	DllCall(Audi_SetSetting, Int, 13, Int, 96)
	DllCall(Audi_SetSetting, Int, 0, Int, 1)
	DllCall(Audi_SetSetting, Int, 7, Int, 1)
	VolumeGain:=GetVolumeGain(AUD_VOL)
	DllCall(Audi_SetSetting, Int, 10, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 11, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 12, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 13, Int, VolumeGain)
	}
else if(mode=2)
	{
	DllCall(Audi_SetSetting, Int, 10, Int, 96)
	DllCall(Audi_SetSetting, Int, 11, Int, 96)
	DllCall(Audi_SetSetting, Int, 12, Int, 96)
	DllCall(Audi_SetSetting, Int, 13, Int, 96)
	DllCall(Audi_SetSetting, Int, 0, Int, 2)
	DllCall(Audi_SetSetting, Int, 7, Int, 2)
	VolumeGain:=GetVolumeGain(AUD_VOL)
	DllCall(Audi_SetSetting, Int, 10, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 11, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 12, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 13, Int, VolumeGain)
	}
else if(mode=3)
	{
	}
else if(mode=4)
	{
	}
else if(mode=5)
	{
	}
else if(mode=6)
	{
	}
else if(mode=7)
	{
	DllCall(Audi_SetSetting, Int, 10, Int, 96)
	DllCall(Audi_SetSetting, Int, 11, Int, 96)
	DllCall(Audi_SetSetting, Int, 12, Int, 96)
	DllCall(Audi_SetSetting, Int, 13, Int, 96)
	DllCall(Audi_SetSetting, Int, 0, Int, 1)
	DllCall(Audi_SetSetting, Int, 7, Int, 131)
	VolumeGain:=GetVolumeGain(AUD_VOL)
	DllCall(Audi_SetSetting, Int, 10, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 11, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 12, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 13, Int, VolumeGain)
	}
else if(mode=8)
	{
	DllCall(Audi_SetSetting, Int, 10, Int, 96)
	DllCall(Audi_SetSetting, Int, 11, Int, 96)
	DllCall(Audi_SetSetting, Int, 12, Int, 96)
	DllCall(Audi_SetSetting, Int, 13, Int, 96)
	DllCall(Audi_SetSetting, Int, 0, Int, 3)
	DllCall(Audi_SetSetting, Int, 7, Int, 129)
	VolumeGain:=GetVolumeGain(AUD_VOL)
	DllCall(Audi_SetSetting, Int, 10, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 11, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 12, Int, VolumeGain)
	DllCall(Audi_SetSetting, Int, 13, Int, VolumeGain)
	}
ActivateMode:=mode
}

CheckNaviToSoundActivate:
if(ActivateMode=0 and NaviSoundsOnRadio<>0)
	{
	if(NaviProgRuning=1)
		{
		if(NaviSoundsOnRadio=2)
			{
			SetActivateMode(8)
			}
			else if(NaviSoundsOnRadio=1)
			{
			SetActivateMode(7)
			}
		}
		else
		{
		SetActivateMode(0)
		}
	}
return

StartMainMenu:
if (MediaProgRuning=0)
{
IfExist, %A_ScriptDir%\MortScript\Menu.exe
			 run %A_ScriptDir%\MortScript\Menu.exe, , UseErrorLevel
}
return

StartMedia:
if (MediaProgRuning=0 and NaviProgRuning=0)
	{
	MediaProgRuning=1
	gosub radiooff
	IfExist, %A_ScriptDir%\MortScript\media.mscr
		Run, \%InternalPath%\Start\MortScript.exe  %A_ScriptDir%\MortScript\media.mscr
	gosub HideCanOnMediaRun
	}
else if (MediaProgRuning=1)
	{
	MediaProgRuning=0
	IfExist, %A_ScriptDir%\MortScript\mediaoff.mscr
		Run, \%InternalPath%\Start\MortScript.exe  %A_ScriptDir%\MortScript\mediaoff.mscr
	gosub HideCanOnMediaRun
	}
return

NaviStart:
gosub StopSaver
IfExist, %A_ScriptDir%\MortScript\NaviStart.exe
			 run %A_ScriptDir%\MortScript\NaviStart.exe, , UseErrorLevel
return

Navi2Start:
gosub StopSaver
IfExist, %A_ScriptDir%\MortScript\NaviStart2.exe
			 run %A_ScriptDir%\MortScript\NaviStart2.exe, , UseErrorLevel
return

StopSaver:
if (SaverRuning=1)
	{
	gosub SaverClose
	}
return

MMCCoreGuiCreate:
if(SplashScreen=1)
{
	Gui, -SysMenu -Caption +AlwaysOnTop
	Gui, Color, c000000
	Gui, Font, cFFFFFF s18
	Gui, Add, Picture, vCoreGUISplash x200 y50 w400 h246, %A_ScriptDir%\Skin\About\logo.bmp
	Gui, Add, Text, vCoreGUIText x5 y445 w295 h30, MMCCore Starting...
	Gui, Add, Progress, x300 y445 w495 h30 vLoadProgress, 20
	Gui, Show, x0 y0 w800 h480, MMCCore
	RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\LadaTools, SplashScreen, 0
	SplashScreen=0
}
else
{
	Gui, -SysMenu -Caption +AlwaysOnTop
	Gui, Color, c000000
	Gui, Font, cFFFFFF s18
	Gui, Add, Text, vCoreGUIText x5 y5 w295 h30, MMCCore Starting...
	Gui, Add, Progress, x300 y5 w495 h30 vLoadProgress, 20
	Gui, Show, x0 y440 w800 h40, MMCCore
}
return

sethwnd:
WinGet, active_id, ID, A ;получаем хэндл окна
sethwnd:=active_id 
sethwnd:= sethwnd + 0 ;переводим хэндл в десятичный вид
DllCall(Api_SetHwnd, "Int", sethwnd) ;задаем хэндл
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\LadaTools, CoreHWND, %sethwnd%
return

;создать таймер хранителя
createsavertimer:
SaverTickCount=0
if (SaverActivate=1 and NaviProgRuning=0 and MediaProgRuning=0 and SaverRunAllow=1)
	{
	MouseGetPos, xs, ys
	SetTimer, startsavertimer, 1000
	}
else
	{
	SetTimer, startsavertimer, off
	}
return

runsaver:
if (SaverActivate=1 and NaviProgRuning=0 and MediaProgRuning=0  and SaverRuning=0 and SaverRunAllow=1)
	{
	imediatlysaverrun=1
	}
else if (SaverActivate=0 and NaviProgRuning=0 and MediaProgRuning=0  and SaverRuning=0 and SaverRunAllow=1)
	{
	gosub startsaver
	}
return

switchsaver:
if(SaverRuning=0)
	{
	gosub runsaver
	}
else
	{
	gosub SaverClose
	}
return

;таймер хранителя
startsavertimer:

if (SaverActivate=1 and NaviProgRuning=0 and MediaProgRuning=0  and SaverRuning=0 and imediatlysaverrun=0 and SaverRunAllow=1)
	{
	MouseGetPos, xn, yn
	if  (xn=xs and yn=ys)
		{
		SaverTickCount += 1
		}
	else
		{
		gosub createsavertimer
		}
	if (SaverTickCount>IdleTime)
		{
		SaverTickCount=0
		SetTimer, startsavertimer, off
		gosub startsaver
		}
	}
else
	{
	SaverTickCount=0
	SetTimer, startsavertimer, off
	}
	
if(SaverActivate=1 and NaviProgRuning=0 and MediaProgRuning=0  and SaverRuning=0 and imediatlysaverrun=1 and SaverRunAllow=1)
	{
	imediatlysaverrun=0
	SaverTickCount=0
	SetTimer, startsavertimer, off
	gosub startsaver
	}

;--------------------отладочная инфа
;	GuiControl,, CoreGUIText, %SaverActivate% %SaverRuning% %NaviProgRuning% %MediaProgRuning% %SaverTickCount%
;--------------------отладочная инфа
return

startclock:
if (RadioRuning=1 or SaverRuning=1)
{
firstclockstart=1
SetTimer, RefreshClock, 1000
}
return

stopclock:
if (RadioRuning=0 and SaverRuning=0)
{
SetTimer, RefreshClock, off
}
return

RefreshClock:
	;обновление часов
	if(firstclockstart=1)
		{
		FSec2= -1
		FMin2= -1
		FDay2= -1
		lasts=1
		firstclockstart=0
		}
	FSec=%A_Sec%
	 if (FSec<>FSec2) 
		{
		gosub changeslider
		FSec2=%FSec%
		}
		
	FMin = %A_Min%
	if (FMin<>FMin2) 
		{
		if (RadioRuning=1)
			{
			GuiControl, 2:, MyTime, %A_Hour%:%A_Min%
			}
		if (SaverRuning=1)
			{
			GuiControl, 3:, MyTimeH, %A_Hour%
			GuiControl, 3:, MyTimeDD, :
			GuiControl, 3:, MyTimeM, %A_Min%
			}
		FMin2=%FMin%
		;обновление даты
		FDay = %A_DD%
		if (FDay<>FDay2) 
			{
			Wday:=Day%A_WDay%
			Mon:=Mon%A_Mon%
			Day:=floor(FDay)
			if (RadioRuning=1)
			{
			GuiControl, 2:, MyDate, %Wday%, %Day% %Mon% %A_YYYY%
			}
			if (SaverRuning=1)
			{
			GuiControl, 3:, MyDateS, %Day% %Mon% %A_YYYY%
			GuiControl, 3:, MyDayS, %Wday%
			}
			FDay2=%FDay%
			}
		}
	if (SaverRuning=1)
		{
		gosub findmousemove
		}
return

findmousemove:
	MouseGetPos, xns, yns
		if  (xns<>xss or yns<>yss)
			{
			gosub SaverClose
			}
return

AutoUpdateCheck:
;читаем ини версии
IfNotExist, %NewMenuVersionini%
	{
	FileAppend,, %NewMenuVersionini%
	IniWrite, 0, %NewMenuVersionini%, NewMenu, Version
	}
IniRead, NewMenuVersion, %NewMenuVersionini%, NewMenu, Version
IniRead, NewMenuVersionTime, %NewMenuVersionini%, NewMenu, VersionTime

;автообновление 
AutoUpdate=0
IfExist, \SDMMC\Install\Menu\LadaTools\INI\NewMenuVersion.ini
	AutoUpdate=1
IfExist, \USB Disk\Install\Menu\LadaTools\INI\NewMenuVersion.ini
	AutoUpdate=2
	
if (AutoUpdate=1)
	{
	IniRead, NewMenuVersionNew, \SDMMC\Install\Menu\LadaTools\INI\NewMenuVersion.ini, NewMenu, Version
	IniRead, NewMenuVersionTimeNew, \SDMMC\Install\Menu\LadaTools\INI\NewMenuVersion.ini, NewMenu, VersionTime
	if (NewMenuVersionNew<>NewMenuVersion or NewMenuVersionTimeNew<>NewMenuVersionTime)
		{
		IfExist, \SDMMC\Install\UpDate.exe
			{
			run \SDMMC\Install\UpDate.exe, , UseErrorLevel
			}
		else
			{
			IfExist, \SDMMC\Install\Install.exe
				run \SDMMC\Install\Install.exe, , UseErrorLevel
			}
		}
	}
	
if (AutoUpdate=2)
	{
	IniRead, NewMenuVersionNew, \USB Disk\Install\Menu\LadaTools\INI\NewMenuVersion.ini, NewMenu, Version
	IniRead, NewMenuVersionTimeNew, \USB Disk\Install\Menu\LadaTools\INI\NewMenuVersion.ini, NewMenu, VersionTime
	if (NewMenuVersionNew<>NewMenuVersion or NewMenuVersionTimeNew<>NewMenuVersionTime)
		{
		IfExist, \USB Disk\Install\UpDate.exe
			{
			run \USB Disk\Install\UpDate.exe, , UseErrorLevel
			}
		else
			{
			IfExist, \USB Disk\Install\Install.exe
				run \USB Disk\Install\Install.exe, , UseErrorLevel
			}
		}
	}		 
return		

ActivateLastActiveWindow(active_id)
{
activewnd:=active_id 
activewnd:= activewnd + 0 ;переводим хэндл в десятичный вид
WinActivate, ahk_id %activewnd%
}

ActivateCenterWindow:
if (SaverRuning=0)
	{
	Random, MouseX, 380, 420
	Random, MouseY, 100, 150
	MouseMove, MouseX, MouseY
	MouseGetPos, , , centerwin, control
	centerwin+=0 ;переводим хэндл в десятичный вид
	;WinGet, CenterwinName , ProcessName, ahk_id %centerwin%
	;NitrogenWinName:="Audio.exe"
	;if(CenterwinName=NitrogenWinName)
		;{
		;WinActivate, ahk_id %centerwin%
		;}
		WinActivate, ahk_id %centerwin%
	}
return

FormatSeconds(NumberOfSeconds)
	{
	LH:=Floor(NumberOfSeconds/3600)
	LM:=Floor((NumberOfSeconds-LH*3600)/60)
	LS:=NumberOfSeconds-LH*3600-LM*60
	TS=
	if (LH>0)
		{ 
		TS=%LH%`:`
		}
		
	if (LM<10)
		{
		TS=%TS%0%LM%`:`
		}
	else
		{
		TS=%TS%%LM%`:`
		}

	if (LS<10)
		{
		TS=%TS%0%LS%
		}
	else
		{
		TS=%TS%%LS%
		}
	
    return TS
	}

NaviMove:
if(NaviMoveAllow=1)
{

	navi_pid=0
	if(NaviProgRuningName="Navitel")
			{
			Process, Exist, navitel.exe
			if ErrorLevel<>0 
				{
				navi_pid:=ErrorLevel
				}
			}

	if(NaviProgRuningName="YandexMaps")
			{
			Process, Exist, yandexmapsCE.exe
			if ErrorLevel<>0 
				{
				navi_pid:=ErrorLevel
				}
			}

	if(NaviProgRuningName="7ways")
			{
			Process, Exist, 7ways.exe
			if ErrorLevel<>0 
				{
				navi_pid:=ErrorLevel
				}
			}

	if(NaviProgRuningName="ProGorod")
			{
			Process, Exist, progorod.exe
			if ErrorLevel<>0 
				{
				navi_pid:=ErrorLevel
				}
			}

	if(NaviProgRuningName="Navitel" or NaviProgRuningName="7ways" or NaviProgRuningName="YandexMaps" or NaviProgRuningName="ProGorod")
		{
			if (navi_pid<>0)
			{
			WinGet, navi_hwnd, id, ahk_pid %navi_pid%
			navi_hwnd+=0
			
			IF(DashBoardRuning=1)
				{
				IF(SoftKeyRuning=1)
					{
					WinMove, ahk_id %navi_hwnd%, , 180, 0, 620, 440
					}
				else
					{
					WinMove, ahk_id %navi_hwnd%, , 0, 0, 800, 440
					}
				}
			else
				{
				IF(SoftKeyRuning=1)
					{
					WinMove, ahk_id %navi_hwnd%, , 180, 0, 620, 480
					}
				else
					{
					WinMove, ahk_id %navi_hwnd%, , 0, 0, 800, 480
					}
				}
			}
		}
}
gosub ShowBTMuteIcon
return

ShowBTMuteIcon:
DllCall(BT_ShowIcon, "Int", 1)
if (MuteState=1)
{
	Gui, 9:Show, x0 y440 w40 h40, Mute
}
return

AboutGuiShow:
IfExist, %A_ScriptDir%\About.ahk
	Run, \%InternalPath%\Start\AHK2THREAD.exe  %A_ScriptDir%\About.ahk
return

;окно уведомления SleepMsg("MsgText",idletime)
SleepMsg(MsgText, idletime)
{
global
if(Gui22Created=0)
{
Gui22Created=1
Gui, 22:-SysMenu -Caption +AlwaysOnTop
Gui, 22:Color, c010101
Gui, 22:Font, cFFFFFF s24
Gui, 22:Add, Text, gSleepMsgClose vMsgTextv 0x1 x10 y10 w280 h180, %MsgText%
}
GuiControl, 22:, MsgTextv, %MsgText%
Gui, 22:Show, w300 h200, Message
idletime:=idletime*1000
SetTimer, SleepMsgClose, -%idletime%
return
}

SleepMsgClose:
;gui, 22:Hide
GuiDestroy(22)
return
;-----------------------------------------окно уведомления SleepMsg


;окно уведомления Message("MsgText")
Message(MsgText)
{
global
if(Gui18Created=0)
{
Gui18Created=1
Gui, 18:-SysMenu -Caption +AlwaysOnTop
Gui, 18:Color, c010101
Gui, 18:Font, cFFFFFF s24
Gui, 18:Add, Picture, gMsgOk x75 y140 w150 h60, %A_ScriptDir%\Skin\RearCam\Yes.bmp
Gui, 18:Add, Text, vMsgTextv 0x1 x10 y30 w280 h100, %MsgText%
}
GuiControl, 18:, MsgTextv, %MsgText%
Gui, 18:Show, w300 h200, Message
return
}

MsgOk:
;gui, 18:Hide
GuiDestroy(18)
return
;-----------------------------------------окно уведомления SleepMsg

;окно уведомления ScrollMSG("MsgText", "OnOK")
ScrollMSG(MsgText, OnOK = "")
{
global
ScrollMSGGosubOnOk:=OnOK
if(Gui23Created=0)
{
Gui23Created=1
Gui, 23:-SysMenu -Caption +AlwaysOnTop
Gui, 23:Color, c010101
Gui, 23:Font, cFFFFFF s16
Gui, 23:Add, Picture, gScrollMSGOk x275 y315 w150 h60, %A_ScriptDir%\Skin\RearCam\Yes.bmp
Gui, 23:Add, Edit, vScrollMSGTextv x10 y10 w680 h300 ReadOnly
}
GuiControl, 23:, ScrollMSGTextv, %MsgText%
Gui, 23:Show, w700 h380, ScrollMSG
return
}

ScrollMSGOk:
;gui, 23:Hide
GuiDestroy(23)
if ScrollMSGGosubOnOk
{
goto %ScrollMSGGosubOnOk%
}
return
;-----------------------------------------окно уведомления ScrollMSG


;диалог редактирования значений. EditDialogText - "текст", EditVariableName-"имя" редактируемой переменной, EditVariableNameSteep- имя переменной с шагом, EditMin-минимальное значение, EditMax-максимальное значение, EditDigit-число знаков после запятой
EditDialog(EditDialogText, EditVariableName, EditGosubOnOk, EditVariableNameSteep, EditMin, EditMax, EditDigit, EditSteepSteep, EditSteepMin, EditSteepMax)
{
global
EditDialogTextG:=EditDialogText
EditDigitG:=EditDigit
EditVariableNameG:=EditVariableName
EditVarG:=%EditVariableName%
EditVarG:=round(EditVarG,EditDigitG)

EditVariableNameSteepG:=EditVariableNameSteep
EditVarSteepG:=%EditVariableNameSteep%
EditVarSteepG:=round(EditVarSteepG,EditDigitG)

EditSteepSteepG:=EditSteepSteep
EditMinG:=EditMin
EditMaxG:=EditMax
EditSteepMinG:=EditSteepMin
EditSteepMaxG:=EditSteepMax
EditGosubOnOkG:=EditGosubOnOk

if(Gui21Created=0)
{
Gui21Created=1
Gui, 21:-SysMenu -Caption +AlwaysOnTop
Gui, 21:Color, c010101
Gui, 21:Font, cFFFFFF s24
Gui, 21:Add, Text, vEditDialogTextv 0x1 x10 y10 w280 h50, %EditDialogTextG%

Gui, 21:Add, Picture, gEditDialogOkDown x20 y60 w50 h50, %A_ScriptDir%\Skin\ClockSet\down.bmp
Gui, 21:Add, Text, vEditDialogVar 0x1 x90 y60 w140 h50, %EditVarG%
Gui, 21:Add, Picture, gEditDialogOkUp x250 y60 w50 h50, %A_ScriptDir%\Skin\ClockSet\up.bmp

Gui, 21:Add, Text, 0x1 x10 y140 w280 h50, Шаг:

Gui, 21:Add, Picture, gEditDialogOkDownSteep x20 y190 w50 h50, %A_ScriptDir%\Skin\ClockSet\down.bmp
Gui, 21:Add, Text, vEditDialogVarSteep 0x1 x90 y190 w140 h50, %EditVarSteepG%
Gui, 21:Add, Picture, gEditDialogOkUpSteep x250 y190 w50 h50, %A_ScriptDir%\Skin\ClockSet\up.bmp


Gui, 21:Add, Picture, gEditDialogOk x10 y260 w150 h60, %A_ScriptDir%\Skin\ClockSet\apply.bmp
Gui, 21:Add, Picture, gEditDialogCancel x160 y260 w150 h60, %A_ScriptDir%\Skin\ClockSet\Close.bmp
}
else
{
GuiControl, 21:, EditDialogTextv, %EditDialogTextG%
GuiControl, 21:, EditDialogVar, %EditVarG%
}
Gui, 21:Show, w320 h320, EditDialog
return
}

EditDialogOkDownSteep:
if(EditVarSteepG-EditSteepSteepG>=EditSteepMinG)
{
EditVarSteepG:=round((EditVarSteepG-EditSteepSteepG),EditDigitG)
GuiControl, 21:, EditDialogVarSteep, %EditVarSteepG%
}
return

EditDialogOkUpSteep:
if(EditVarSteepG+EditSteepSteepG<=EditSteepMaxG)
{
EditVarSteepG:=round((EditVarSteepG+EditSteepSteepG),EditDigitG)
GuiControl, 21:, EditDialogVarSteep, %EditVarSteepG%
}
return


EditDialogOkDown:
if(EditVarG-EditVarSteepG>=EditMinG)
{
EditVarG:=round((EditVarG-EditVarSteepG),EditDigitG)
GuiControl, 21:, EditDialogVar, %EditVarG%
}
return

EditDialogOkUp:
if(EditVarG+EditVarSteepG<=EditMaxG)
{
EditVarG:=round((EditVarG+EditVarSteepG),EditDigitG)
GuiControl, 21:, EditDialogVar, %EditVarG%
}
return

EditDialogOk:
;gui, 21:Hide
GuiDestroy(21)
%EditVariableNameG%:=EditVarG
%EditVariableNameSteepG%:=EditVarSteepG
GuiControl, 21:, vEditDialogTextv

EditDialogTextG=
EditDialogText=
EditDigitG=
EditDigit=
EditVariableNameG=
EditVariableName=
EditVarG=
EditVariableNameSteepG=
EditVariableNameSteep=
EditVarSteepG=
EditSteepSteepG=
EditSteepSteep=
EditMinG=
EditMin=
EditMaxG=
EditMax=
EditSteepMinG=
EditSteepMin=
EditSteepMaxG=
EditSteepMax=
EditGosubOnOk=

goto %EditGosubOnOkG%
return

EditDialogCancel:
;gui, 21:Hide
GuiDestroy(21)
return
;-----------------------------------------диалог редактирования значений.

;диалоговое окно (да/нет) Dialog("DialogText", "OnOK", "OnNo")
Dialog(DialogText, OnOK = "", OnNo = "")
{
global
DialogGosubOnOk:=OnOK
DialogGosubOnNo:=OnNo
if(Gui4Created=0)
{
Gui4Created=1
Gui, 4:-SysMenu -Caption +AlwaysOnTop
Gui, 4:Color, c010101
Gui, 4:Font, cFFFFFF s24
Gui, 4:Add, Picture, gDialogOk x0 y140 w150 h60, %A_ScriptDir%\Skin\RearCam\Yes.bmp
Gui, 4:Add, Picture, gDialogCancel x150 y140 w150 h60, %A_ScriptDir%\Skin\RearCam\No.bmp
Gui, 4:Add, Text, vDialogTextv 0x1 x10 y30 w280 h100, %DialogText%
}
GuiControl, 4:, DialogTextv, %DialogText%
Gui, 4:Show, w300 h200, Dialog
return
}

DialogOk:
;gui, 4:Hide
GuiDestroy(4)
if DialogGosubOnOk
{
goto %DialogGosubOnOk%
}
return

DialogCancel:
;gui, 4:Hide
GuiDestroy(4)
if DialogGosubOnNo
{
goto %DialogGosubOnNo%
}
return

DialogNoAction:
return
;----------------------------------------диалоговое окно 

Volume(vol) 
{
    v := vol*655.35
    DllCall("waveOutSetVolume", "int", 0, "uint", v|(v<<16))
}

trim(Text)
{
text := regexreplace(text, "^\s+") ;trim beginning whitespace
text := regexreplace(text, "\s+$") ;trim ending whitespace
return text
}

GuiDestroy(GNum)
	{
		global
		if(Gui%GNum%Created=1)
			{
			;gui, %GNum%:destroy
			;Gui%GNum%Created=0
			gui, %GNum%:hide
			GuiControl, %GNum%:, Gui%GNum%BCGRND
			}
	}
	
;скринсейвер
#IncludeAgain %A_ScriptDir%\MMCCoreSaver.ahk

;настройки видео
#IncludeAgain %A_ScriptDir%\MMCCoreVideoSettings.ahk

;настройки звука
#IncludeAgain %A_ScriptDir%\MMCCoreSoundSettings.ahk
#IncludeAgain %A_ScriptDir%\MMCCoreSoundInputLevel.ahk

;камера заднего вида
#IncludeAgain %A_ScriptDir%\MMCCoreRearViewCam.ahk

;радио
#IncludeAgain %A_ScriptDir%\MMCCoreRadio.ahk

;задаем сохраненные настройки звука и экрана
#IncludeAgain %A_ScriptDir%\MMCCoreAudioVideoInit.ahk

;окно громкости
#IncludeAgain %A_ScriptDir%\MMCCoreVolShow.ahk

;окно mute
#IncludeAgain %A_ScriptDir%\MMCCoreMuteShow.ahk

;окно трека
#IncludeAgain %A_ScriptDir%\MMCCoreShowTrack.ahk

;окно частоты
#IncludeAgain %A_ScriptDir%\MMCCoreShowFreq.ahk

;окно частоты
#IncludeAgain %A_ScriptDir%\MMCCorePlayerControl.ahk

;синий зуб
#IncludeAgain %A_ScriptDir%\MMCCoreBt.ahk

;can
#IncludeAgain %A_ScriptDir%\MMCCoreCan.ahk
#IncludeAgain %A_ScriptDir%\MMCCoreCanSettings.ahk

;окно смены температуры
#IncludeAgain %A_ScriptDir%\MMCCoreTempShow.ahk

;допы
#IncludeAgain %A_ScriptDir%\MMCCoreAddons.ahk

;обнуляемые переменные при старте ммс
#IncludeAgain %A_ScriptDir%\MMCCoreResetVar.ahk

;GDI
#IncludeAgain %A_ScriptDir%\MMCCoreGDI.ahk

;телефон
#IncludeAgain %A_ScriptDir%\MMCCorePhone.ahk
#IncludeAgain %A_ScriptDir%\keyboard.ahk

;Clock
#IncludeAgain %A_ScriptDir%\MMCCoreClock.ahk

DeBugMe:
;ListVars
;Pause
return

GuiClose:
gosub SetTimeToMMC
gosub EndTrip
DllCall(MMC21_uninit)
DllCall("FreeLibrary", "UInt", mmc21hwnd) ;выгружаем
DllCall("FreeLibrary", "UInt", BTDLLHWND) ;выгружаем
DllCall("FreeLibrary", "UInt", CANDLLHWND) ;выгружаем
DllCall("FreeLibrary", "UInt", MMCCOREDLLHWND)
if (CarModel="Emu")
	{
	NewMenuVersionTime = %A_DD%.%A_MM%.%A_YYYY% %A_Hour%:%A_Min%
	IniWrite, %NewMenuVersionTime%, %NewMenuVersionini%, NewMenu, VersionTime
	}
ExitApp
