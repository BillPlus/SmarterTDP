/*
 | Copyright (C) 2023 BillPlus
 */

#NoEnv
#SingleInstance Force
#Persistent
#KeyHistory 0

ListLines Off
Process, Priority,, H
SetBatchLines, -1
SetWinDelay, -1
SetControlDelay, -1
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows, On
CoordMode, ToolTip, Screen

global DEFAULT_TDP := 10000
global MAX_CPU_TDP := 15000
global MAX_GPU_TDP := 15000

global RYZENADJ_DELAY := 4000 ; min delay between each adjustment (too fast can cause microstutter)
global TIMER_RESOLUTION := 2000

; Make sure script is ran as admin
if (!A_IsAdmin) {
  Run *RunAs "%A_ScriptFullPath%"
}

aboutText := "SmarterTDP v0.0.8"

; Replace default AHK menu
Menu, Tray, Tip , Current TDP: 10W
Menu, Tray, NoStandard
Menu, Tray, Add, %aboutText%, NoOp
Menu, Tray, Disable, %aboutText%
Menu, Tray, Add ; separator
Menu, Tray, Add, EPP Hack (beta), ToggleEppHack
Menu, Tray, Add ; separator
Menu, Tray, Add, Performance (36W), FavorPerformance
Menu, Tray, Add, Balance (22W), FavorBalance
Menu, Tray, Add, Efficiency (15W), FavorEfficiency
Menu, Tray, Add, Exit, MenuExit

#Include %A_ScriptDir%\lib\ryzenadj.ahk
#Include %A_ScriptDir%\lib\pdh.ahk
#Include %A_ScriptDir%\lib\tdpcontrol.ahk

global PDH_QUERY := PDHOpenQuery()
global CPU_COUNTER := PDHAddCounter(PDH_QUERY, "\Processor(_Total)\% Processor Time")
global GPU_COUNTER := PDHAddCounter(PDH_QUERY, "\GPU Engine(*engtype_3D)\Utilization Percentage")
global DEC_COUNTER := PDHAddCounter(PDH_QUERY, "\GPU Engine(*engtype_Video*)\Utilization Percentage")
PDHCollectQueryData(PDH_QUERY)

global CURRENT := DEFAULT_TDP
global CHOSEN := ""
global CUSTOM_CPU_TDP := 0
global CUSTOM_GPU_TDP := 0
global EPP_HACK := false
SetTDP(DEFAULT_TDP)
OnExit("CleanUp")

; WM_POWERBROADCAST
OnMessage(0x218, "OnPowerBroadcast")

LoadSettings()
SaveSettings()
if (EPP_HACK) {
  SetPowerSettings()
}

global FN_MONITOR := Func("MonitorAndAdjust")
StartMonitoring()
return

/*
 | MENU OPTIONS
 */
NoOp:
  return
  
ToggleEppHack:
  EPP_HACK := !EPP_HACK
  SaveSettings()
  if (EPP_HACK) {
    SetPowerSettings()
  }
  else {
    RestorePowerSettings()
  }
  return

FavorPerformance:
  MAX_CPU_TDP := 36000
  MAX_GPU_TDP := 28000
  SaveSettings()
  return
  
FavorBalance:
  MAX_CPU_TDP := 22000
  MAX_GPU_TDP := 22000
  SaveSettings()
  return

FavorEfficiency:
  MAX_CPU_TDP := 15000
  MAX_GPU_TDP := 15000
  SaveSettings()
  return
  
CustomTDP:
  MAX_CPU_TDP := CUSTOM_CPU_TDP
  MAX_GPU_TDP := CUSTOM_GPU_TDP
  SaveSettings()
  return

MenuExit:
  ExitApp

/*
 | MAIN LOOP
 */
MonitorAndAdjust()
{
  static lastAdjustment := 0
  
  PDHCollectQueryData(PDH_QUERY)
  prcName := WinGetActiveProcessName()
  
  sysLoad := CPULoad()
  pdhLoad := PDHFormatCounterValueDouble(CPU_COUNTER)
  cpuLoad := Max(sysLoad, pdhLoad)
  
  gpuLoad := PDHFormatCounterValueFromDoubleArray(GPU_COUNTER)
  decLoad := PDHFormatCounterValueFromDoubleArray(DEC_COUNTER)
  
  if (cpuLoad >= 0.0 && gpuLoad >= 0.0) {
    result := DetermineTDP(prcName, cpuLoad, gpuLoad, decLoad, CURRENT, MAX_CPU_TDP, MAX_GPU_TDP)
    
    if (result != CURRENT && A_TickCount - lastAdjustment >= RYZENADJ_DELAY) {
      SetTDP(result)
      CURRENT := result
      lastAdjustment := A_TickCount
    }
    
    resultTxt := Round(result / 1000, 1)
    ; Uncomment next line for debugging purposes only
    ;ToolTip %prcName%: %cpuLoad%`% | %gpuLoad%`% | %decLoad%`% | %resultTxt%W, 10, 50
    Menu, Tray, Tip , Current TDP: %resultTxt%W
  }
  
  StartMonitoring()
}

StartMonitoring()
{
  SetTimer, %FN_MONITOR%, -%TIMER_RESOLUTION%
}

StopMonitoring()
{
  SetTimer, %FN_MONITOR%, Off
}

CPULoad() ; CPULoad() by SKAN
{
  static PIT, PKT, PUT
  if (Pit = "") {
    return 0, DllCall("GetSystemTimes", "Int64P", PIT, "Int64P", PKT, "Int64P", PUT)
  }
  DllCall("GetSystemTimes", "Int64P", CIT, "Int64P", CKT, "Int64P", CUT)
  IdleTime := PIT - CIT, KernelTime := PKT - CKT, UserTime := PUT - CUT
  SystemTime := KernelTime + UserTime 
  return ((SystemTime - IdleTime) * 100) // SystemTime, PIT := CIT, PKT := CKT, PUT := CUT 
}

OnPowerBroadcast(wParam, lParam)
{
  ; PBT_APMRESUMESUSPEND or PBT_APMRESUMESTANDBY -> device wakes up
  if (wParam = 7 OR wParam = 8) {
    StopMonitoring()
    SetTDP(CURRENT)
    if (EPP_HACK) {
      SetPowerSettings()
    }
    
    time := RYZENADJ_DELAY - TIMER_RESOLUTION
    Sleep %time%
    StartMonitoring()
  }
  ; PBT_APMPOWERSTATUSCHANGE -> battery vs charger
  else if (wParam = 10) {
    StopMonitoring()
    if (EPP_HACK) {
      SetPowerSettings()
    }
    StartMonitoring()
  }

  Return
}

WinGetActiveProcessName()
{
  WinGet name, ProcessName, A
  if (name = "ApplicationFrameHost.exe") {
    ControlGet hwnd, Hwnd,, Windows.UI.Core.CoreWindow1, A
    if hwnd {
      WinGet name, ProcessName, ahk_id %hwnd%
    }
  }
  return name
}

SetTDP(value)
{
  ryaccess := RyzenAdjInit()
  RyzenAdjSetTDP(ryaccess, value)
  RyzenAdjSetTDPFast(ryaccess, value)
  RyzenAdjSetTDPSlow(ryaccess, value)
  RyzenAdjSetMaxPerformance(ryaccess)
  RyzenAdjCleanup(ryaccess)
}

LoadSettings()
{
  IniRead, maxCPUTDP, config.ini, Power, cpuTDP, %MAX_CPU_TDP%
  IniRead, maxGPUTDP, config.ini, Power, gpuTDP, %MAX_GPU_TDP%
  if (maxCPUTDP <= 5000 || maxGPUTDP <= 5000) {
    MsgBox, Custom TDP values too low. Using defaults.
    maxCPUTDP := 15000
    maxGPUTDP := 15000
  }
  MAX_CPU_TDP := maxCPUTDP
  MAX_GPU_TDP := maxGPUTDP
  IniRead, eppHack, config.ini, Power, eppHack, 0
  EPP_HACK := eppHack = 1
  UpdateMenu()
}

SaveSettings()
{
  IniWrite, %MAX_CPU_TDP%, config.ini, Power, cpuTDP
  IniWrite, %MAX_GPU_TDP%, config.ini, Power, gpuTDP
  eppHack := EPP_HACK ? 1 : 0
  IniWrite, %eppHack%, config.ini, Power, eppHack
  UpdateMenu()
}

UpdateMenu()
{
  if (CHOSEN != "") {
    Menu, Tray, Uncheck, %CHOSEN%
  }
  
  if (MAX_CPU_TDP = 36000 && MAX_GPU_TDP = 28000) {
    Menu, Tray, Check, Performance (36W)
    CHOSEN := "Performance (36W)"
  }
  else if (MAX_CPU_TDP = 22000 && MAX_GPU_TDP = 22000) {
    Menu, Tray, Check, Balance (22W)
    CHOSEN := "Balance (22W)"
  }
  else if (MAX_CPU_TDP = 15000 && MAX_GPU_TDP = 15000) {
    Menu, Tray, Check, Efficiency (15W)
    CHOSEN := "Efficiency (15W)"
  }
  else {
    maxCustom := Round(Max(MAX_CPU_TDP, MAX_GPU_TDP) / 1000, 1)
    if (CUSTOM_CPU_TDP = 0 && CUSTOM_GPU_TDP = 0) {
      Menu, Tray, Insert, Exit, Custom (%maxCustom%W), CustomTDP
      CUSTOM_CPU_TDP := MAX_CPU_TDP
      CUSTOM_GPU_TDP := MAX_GPU_TDP
    }
    Menu, Tray, Check, Custom (%maxCustom%W)
    CHOSEN := "Custom (" . maxCustom . "W)"
  }
  
  if (EPP_HACK) {
    Menu, Tray, Check, EPP Hack (beta)
  }
  else {
    Menu, Tray, Uncheck, EPP Hack (beta)
  }
}

CleanUp()
{
  StopMonitoring()
  SetTimer, MonitorAndAdjust, Delete
  Sleep %RYZENADJ_DELAY%
  SetTDP(DEFAULT_TDP)
  RestorePowerSettings()
  RestoreBoostSettings()
  PDHCloseQuery(PDH_QUERY)
}