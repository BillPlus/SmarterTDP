/*
 | Copyright (C) 2023 BillPlus
 */

global PDH_MODULE := LoadPDH()

global PDH_ERROR_SUCCESS  := 0
global PDH_FMT_LONG   := 0x00000100
global PDH_FMT_DOUBLE := 0x00000200
global PDH_FMT_LARGE  := 0x00000400
global PDH_MORE_DATA := 0x800007D2

global FN_PDH_COLLECT_QUERY_DATA := DllCall("GetProcAddress", "Ptr", PDH_MODULE, "AStr", "PdhCollectQueryData", "Ptr")
global FN_PDH_FORMAT_COUNTER_VALUE := DllCall("GetProcAddress", "Ptr", PDH_MODULE, "AStr", "PdhGetFormattedCounterValue", "Ptr")
global FN_PDH_FORMAT_COUNTER_ARRAY := DllCall("GetProcAddress", "Ptr", PDH_MODULE, "AStr", "PdhGetFormattedCounterArray", "Ptr")

LoadPDH()
{
  PDH_PATH := "C:\Windows\System32\pdh.dll"
  hModule := DllCall("LoadLibrary", "Str", PDH_PATH, "Ptr")
  
  if (!hModule) {
    MsgBox, pdh.dll not found
    ExitApp
  }
  
  return hModule
}

PDHOpenQuery()
{
  VarSetCapacity(hQuery, A_PtrSize, 0)
  status := DllCall("pdh\PdhOpenQuery", "Ptr", 0, "UPtr", 0, "Ptr", &hQuery, "UInt")
  if (status > 1) {
    code := Format("0x{1:02x}", status)
    MsgBox, PdhOpenQuery failed with %code%
    ExitApp
  }
  
  return NumGet(&hQuery + 0, 0, "Ptr")
}

PDHAddCounter(hQuery, counterName)
{
  VarSetCapacity(hCounter, A_PtrSize, 0)
  status := DllCall("pdh\PdhAddEnglishCounter", "Ptr", hQuery, "Str", counterName, "Ptr", 0, "Ptr", &hCounter, "UInt")
  if (status > 1) {
    code := Format("0x{1:02x}", status)
	  MsgBox, PdhAddEnglishCounter("%counterName%") failed with %code%
    ExitApp
  }
  return NumGet(&hCounter + 0, 0, "Ptr")
}

PDHRemoveCounter(hCounter)
{
  status := DllCall("pdh\PdhRemoveCounter", "Ptr", hCounter, "UInt")
  if (status > 1) {
    code := Format("0x{1:02x}", status)
	  MsgBox, PdhAddEnglishCounter("%counterName%") failed with %code%
    ExitApp
  }
}

PDHCollectQueryData(hQuery)
{
  status := DllCall("pdh\PdhCollectQueryData", "Ptr", hQuery, "UInt")
  if (status > 1) {
    code := Format("0x{1:02x}", status)
    MsgBox, PdhCollectQueryData failed with %code%
    ExitApp
  }
}

PDHFormatCounterValueFromDoubleArray(hCounter)
{
  bufferSize := 0
  itemCount := 0
  status := DllCall("pdh\PdhGetFormattedCounterArray", "Ptr", hCounter, "UInt", PDH_FMT_DOUBLE, "Int*", bufferSize, "Int*", itemCount, "Ptr", 0, "UInt")
  
  if (status & 0xffffffff != PDH_MORE_DATA && status != PDH_ERROR_SUCCESS) {
    code := Format("0x{1:02x}", status)
    MsgBox, PDHFormatCounterValueFromDoubleArray(%hCounter%) failed with %code%
    ExitApp
  }
  
  VarSetCapacity(itemBuffer, bufferSize, 0)
  DllCall("pdh\PdhGetFormattedCounterArray", "Ptr", hCounter, "UInt", PDH_FMT_DOUBLE, "Int*", bufferSize, "Int*", itemCount, "Ptr", &itemBuffer, "UInt")
  
  if (itemCount > 0) {
    sum := 0.0
    addr := 0
    Loop, %itemCount% {
      fmtValue := NumGet(&itemBuffer + 0, addr + A_PtrSize + 8, "Double")
      sum += fmtValue
      addr += A_PtrSize + 16
    }
    return sum
  }
  
  return -1
}

PDHFormatCounterValueDouble(hCounter)
{
  VarSetCapacity(value, 16, 0)
  status := DllCall("pdh\PdhGetFormattedCounterValue", "Ptr", hCounter, "UInt", PDH_FMT_DOUBLE, "Ptr", 0, "Ptr", &value, "UInt")
	if (status > 0) {
    code := Format("0x{1:02x}", status)
    return -1000
  }
	return NumGet(&value, 8, "Double")
}

PDHCloseQuery(hQuery)
{
  DllCall("pdh\PdhCloseQuery", "Ptr", hQuery)
}