/*

	SmarterTDP Script by Bill-P
	
	This script takes the current CPU and GPU usage statistics of
  an AMD APU and determines an appropriate TDP limit amount to set 
	to the APU to maximize battery life and performance.
  
  Lightning icon created by Aldo Cervantes on FlatIcon:
  https://www.flaticon.com/free-icons/lightning
  
	This program is free software: you can redistribute it and/or 
	modify it under the terms of the GNU General Public License as
	published by the Free Software Foundation, either version 3 of
	the License, or (at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see
	<http://www.gnu.org/licenses/>.
  
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
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
DetectHiddenWindows, On
CoordMode, ToolTip, Screen

global DEFAULT_TDP := 10000
global MAX_CPU_TDP := 15000 ; watts
global MAX_GPU_TDP := 15000 ; watts

global RYZENADJ_DELAY := 4000 ; min delay between each adjustment (too fast can cause microstutter)
global TIMER_RESOLUTION := 2000

; Make sure script is ran as admin
if (!A_IsAdmin) {
  Run *RunAs "%A_ScriptFullPath%"
}

aboutText := "SmarterTDP v0.0.7"

; Replace default AHK menu
Menu, Tray, Tip , Current TDP: 10W
Menu, Tray, NoStandard
Menu, Tray, Add, %aboutText%, About
Menu, Tray, Disable, %aboutText%
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
SetTDP(DEFAULT_TDP)
OnExit("CleanUp")

; WM_POWERBROADCAST
OnMessage(0x218, "OnPowerBroadcast")

LoadSettings()
SaveSettings()
SetPowerSettings()

global FN_MONITOR := Func("MonitorAndAdjust")
StartMonitoring()
return

/*
 | MENU OPTIONS
 */
About:
  return

FavorPerformance:
  MAX_CPU_TDP := 36000 ; watts
  MAX_GPU_TDP := 28000 ; watts
  SaveSettings()
  return
  
FavorBalance:
  MAX_CPU_TDP := 22000 ; watts
  MAX_GPU_TDP := 22000 ; watts
  SaveSettings()
  return

FavorEfficiency:
  MAX_CPU_TDP := 15000 ; watts
  MAX_GPU_TDP := 15000 ; watts
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
  ; PBT_APMSUSPEND or PBT_APMSTANDBY? -> System will sleep
  if (wParam = 4 OR wParam = 5) {
    ; not fast enough
  }
  ; PBT_APMRESUMESUSPEND or PBT_APMRESUMESTANDBY -> device wakes up
  if (wParam = 7 OR wParam = 8) {
    StopMonitoring()
    SetTDP(CURRENT)
    SetPowerSettings()
    
    time := RYZENADJ_DELAY - TIMER_RESOLUTION
    Sleep %time%
    StartMonitoring()
  }
  ; PBT_APMPOWERSTATUSCHANGE -> battery vs charger
  else if (wParam = 10) {
    StopMonitoring()
    SetPowerSettings()
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
  UpdateMenu()
}

SaveSettings()
{
  IniWrite, %MAX_CPU_TDP%, config.ini, Power, cpuTDP
  IniWrite, %MAX_GPU_TDP%, config.ini, Power, gpuTDP
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
}

CleanUp()
{
  StopMonitoring()
  SetTimer, MonitorAndAdjust, Delete
  Sleep %RYZENADJ_DELAY%
  SetTDP(DEFAULT_TDP)
  RestorePowerSettings()
  PDHCloseQuery(PDH_QUERY)
}