/*
 | Copyright (C) 2023 BillPlus
 */

global RYA_MODULE := LoadRyzenAdj()

global FN_RYA_INIT_ACCESS := DllCall("GetProcAddress", "Ptr", RYA_MODULE, "AStr", "init_ryzenadj", "Ptr")
global FN_RYA_CLEAN_UP := DllCall("GetProcAddress", "Ptr", RYA_MODULE, "AStr", "cleanup_ryzenadj", "Ptr")
global FN_RYA_INIT_TABLE := DllCall("GetProcAddress", "Ptr", RYA_MODULE, "AStr", "init_table", "Ptr")
global FN_RYA_REFRESH_TABLE := DllCall("GetProcAddress", "Ptr", RYA_MODULE, "AStr", "refresh_table", "Ptr")
global FN_RYA_GET_STAPM_VALUE := DllCall("GetProcAddress", "Ptr", RYA_MODULE, "AStr", "get_stapm_value", "Ptr")
global FN_RYA_GET_STAPM_LIMIT := DllCall("GetProcAddress", "Ptr", RYA_MODULE, "AStr", "get_stapm_limit", "Ptr")
global FN_RYA_GET_FAST_LIMIT := DllCall("GetProcAddress", "Ptr", RYA_MODULE, "AStr", "get_fast_limit", "Ptr")
global FN_RYA_GET_SLOW_LIMIT := DllCall("GetProcAddress", "Ptr", RYA_MODULE, "AStr", "get_slow_limit", "Ptr")
global FN_RYA_SET_STAPM_LIMIT := DllCall("GetProcAddress", "Ptr", RYA_MODULE, "AStr", "set_stapm_limit", "Ptr")
global FN_RYA_SET_FAST_LIMIT := DllCall("GetProcAddress", "Ptr", RYA_MODULE, "AStr", "set_fast_limit", "Ptr")
global FN_RYA_SET_SLOW_LIMIT := DllCall("GetProcAddress", "Ptr", RYA_MODULE, "AStr", "set_slow_limit", "Ptr")

LoadRyzenAdj()
{
  RYZENADJ_PATH := A_ScriptDir . "\libryzenadj.dll"
  RYA_MODULE := DllCall("LoadLibrary", "Str", RYZENADJ_PATH, "Ptr")
  if (!RYA_MODULE) {
    MsgBox, Failed to load RyzenAdj library from %RYZENADJ_PATH%
    ExitApp
  }
  
  return RYA_MODULE
}

RyzenAdjInit()
{
  return DllCall(FN_RYA_INIT_ACCESS)
}

RyzenAdjCleanup(ryaccess)
{
  DllCall(FN_RYA_CLEAN_UP, "Ptr", ryaccess)
}

RyzenAdjInitTable(ryaccess)
{
  DllCall(FN_RYA_INIT_TABLE, "Ptr", ryaccess)
}

RyzenAdjRefreshTable(ryaccess)
{
  DllCall(FN_RYA_REFRESH_TABLE, "Ptr", ryaccess)
}

RyzenAdjGetTDP(ryaccess)
{
  return DllCall(FN_RYA_GET_STAPM_LIMIT, "Ptr", ryaccess, "Float")
}

RyzenAdjGetTDPFast(ryaccess)
{
  return DllCall(FN_RYA_GET_FAST_LIMIT, "Ptr", ryaccess, "Float")
}

RyzenAdjGetTDPSlow(ryaccess)
{
  return DllCall(FN_RYA_GET_SLOW_LIMIT, "Ptr", ryaccess, "Float")
}

RyzenAdjSetTDP(ryaccess, value)
{
  DllCall(FN_RYA_SET_STAPM_LIMIT, "Ptr", ryaccess, "UInt", value)
}

RyzenAdjSetTDPFast(ryaccess, value)
{
  DllCall(FN_RYA_SET_FAST_LIMIT, "Ptr", ryaccess, "UInt", value)
}

RyzenAdjSetTDPSlow(ryaccess, value)
{
  DllCall(FN_RYA_SET_SLOW_LIMIT, "Ptr", ryaccess, "UInt", value)
}

RyzenAdjSetMaxPerformance(ryaccess)
{
  DllCall(FN_RYA_SET_MAX_PERF, "Ptr", ryaccess)
}