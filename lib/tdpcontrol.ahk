global POWERCFG_PPSUB_PROCESSOR := "54533251-82be-4824-96c1-47b60b740d00"
global POWERCFG_MAX_PROC_STATE  := "bc5038f7-23e0-4960-96da-33abaf5935ec"
global POWERCFG_PERF_BOOST_MODE := "be337238-0d82-4146-a960-4f3749d470c7"
global POWERCFG_PERF_ENERG_PREF := "36687f9e-e3a5-4dbf-b1dc-15eb381c6863"
global POWERCFG_PERF_ENERG_PRF1 := "36687f9e-e3a5-4dbf-b1dc-15eb381c6864"
global POWERCFG_PERF_AUTONOMOUS := "8baa4a8a-14c6-4451-8e8b-14bdbd197537"

; Note: don't go below 3W as it is detrimental and can crash the device
global MIN_TDP := 3500
global MIN_DEC_TDP := 5000
global LOW_CPU_TDP_THRESHOLD := 5000
global LOW_GPU_TDP_THRESHOLD := 8000

global CPU_INC_THRESHOLD := 65
global CPU_DEC_THRESHOLD := 12
global GPU_INC_THRESHOLD := 75
global GPU_DEC_THRESHOLD := 45
global COMBO_THRESHOLD := 65 ; weird condition where CPU and GPU are bottlenecked at low power
global COMBO_CPU_THRESHOLD := 8 ; only occurs when CPU usage is above this
global CPU_INC_THRESHOLD_LOW := 12
global CPU_DEC_THRESHOLD_LOW := 5
global GPU_INC_THRESHOLD_LOW := 72
global GPU_DEC_THRESHOLD_LOW := 16
global CPU_OVERHEAD := 5
global GPU_OVERHEAD := 12

global HIGH_MULTIPLIER := 0.75 ; adjust how fast TDP scales up
global LOW_MULTIPLIER := 0.45 ; adjust how fast TDP scales down
global DIFF_RATIO := 1.1
global THROTTLE_RATIO := 1.5 ; don't drop performance abruptly by this amount

global GPU_INC_RATIO := 0.3
global GPU_INC_MULTIPLIER := 1.25
global GPU_DEC_RATIO := 0.15
global GPU_DEC_MULTIPLIER := 0.9
global DECODER_THRESHOLD := 45

global TDP_HEADROOM_RATIO := 2.0
global TDP_HEADROOM_MIN := 7000

global ACTIVE_POWER_PROFILE := GetActivePowerProfile()
global MAX_CPU_STATE := GetACPowerSetting(ACTIVE_POWER_PROFILE, POWERCFG_PPSUB_PROCESSOR, POWERCFG_MAX_PROC_STATE)
global DEFAULT_BOOST_MODE := GetACPowerSetting(ACTIVE_POWER_PROFILE, POWERCFG_PPSUB_PROCESSOR, POWERCFG_PERF_BOOST_MODE)

GetActivePowerProfile()
{
  RegRead, activeProfile, HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes, ActivePowerScheme
  return activeProfile
}

GetACPowerSetting(activeProfile, subCat, setting)
{
  RegRead, value, HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\%activeProfile%\%subCat%\%setting%, ACSettingIndex
  return value
}

GetDCPowerSetting(activeProfile, subCat, setting)
{
  RegRead, value, HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\%activeProfile%\%subCat%\%setting%, DCSettingIndex
  return value
}

SetPowerSettings()
{
  Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_AUTONOMOUS% 1, , Hide
  Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_AUTONOMOUS% 1, , Hide
  Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_ENERG_PREF% 0x21, , Hide
  Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_ENERG_PREF% 0x21, , Hide
  Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_ENERG_PRF1% 0x21, , Hide
  Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_ENERG_PRF1% 0x21, , Hide
  Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_AUTONOMOUS% 0, , Hide
  Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_AUTONOMOUS% 0, , Hide
}

RestorePowerSettings()
{
  Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_MAX_PROC_STATE% %MAX_CPU_STATE%, , Hide
  Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_MAX_PROC_STATE% %MAX_CPU_STATE%, , Hide
  Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_BOOST_MODE% %DEFAULT_BOOST_MODE%, , Hide
  Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_BOOST_MODE% %DEFAULT_BOOST_MODE%, , Hide
  ; just set default for hidden settings
  Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_ENERG_PREF% 0x21, , Hide
  Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_ENERG_PREF% 0x32, , Hide
  Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_ENERG_PRF1% 0x21, , Hide
  Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_ENERG_PRF1% 0x32, , Hide
  Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_AUTONOMOUS% 1, , Hide
  Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_AUTONOMOUS% 1, , Hide
}

DetermineTDP(pName, cpuLoad, gpuLoad, decLoad, currentTDP, maxCPUTDP, maxGPUTDP)
{
  static lastTDP := -1
  static lastGPU := -1
  
  combinedLoad := (cpuLoad > COMBO_CPU_THRESHOLD ? cpuLoad : 0) + gpuLoad
  lastTDP := currentTDP
  newTDP := 0
  boostTDP := 0
  
  cpuLoad += currentTDP > LOW_CPU_TDP_THRESHOLD ? CPU_OVERHEAD : 0
  gpuLoad += currentTDP > LOW_GPU_TDP_THRESHOLD ? GPU_OVERHEAD : 0
  
  if (lastGPU != -1) {
    if (gpuLoad > lastGPU && ((gpuLoad - lastGPU) / 100) > GPU_INC_RATIO) {
      gpuLoad := gpuLoad * GPU_INC_MULTIPLIER > 100 ? 100 : gpuLoad * GPU_INC_MULTIPLIER
    }
    else if (gpuLoad < lastGPU && ((lastGPU - gpuLoad) / 100) > GPU_DEC_RATIO) {
      gpuLoad := lastGPU * GPU_DEC_MULTIPLIER
    }
  }
  lastGPU := gpuLoad
  
  minTDP := decLoad > DECODER_THRESHOLD ? MIN_DEC_TDP : MIN_TDP
  cpuIncThreshold := currentTDP > LOW_CPU_TDP_THRESHOLD ? CPU_INC_THRESHOLD : CPU_INC_THRESHOLD_LOW
  cpuDecThreshold := currentTDP > LOW_CPU_TDP_THRESHOLD ? CPU_DEC_THRESHOLD : CPU_DEC_THRESHOLD_LOW
  gpuIncThreshold := currentTDP > LOW_GPU_TDP_THRESHOLD ? GPU_INC_THRESHOLD : GPU_INC_THRESHOLD_LOW
  gpuDecThreshold := currentTDP > LOW_GPU_TDP_THRESHOLD ? GPU_DEC_THRESHOLD : GPU_DEC_THRESHOLD_LOW
  
  isCPUIdle := cpuLoad <= cpuDecThreshold && combinedLoad < COMBO_THRESHOLD && gpuLoad <= gpuDecThreshold
  
  if (isCPUIdle || decLoad > DECODER_THRESHOLD) {
    newTDP := lastTDP
    
    loadDiff := 1 + Max(Abs(cpuLoad - cpuDecThreshold), Abs(gpuLoad - gpuDecThreshold)) / 100
    newTDP := newTDP - newTDP / loadDiff * LOW_MULTIPLIER
    newTDP := newTDP < minTDP ? minTDP : newTDP
    if (lastTDP * 1.0 / newTDP > THROTTLE_RATIO) {
      newTDP := (lastTDP + newTDP) / 2
    }
    boostTDP := newTDP * TDP_HEADROOM_RATIO > TDP_HEADROOM_MIN ? newTDP * TDP_HEADROOM_RATIO : TDP_HEADROOM_MIN
    
    Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_MAX_PROC_STATE% 20, , Hide
    Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_MAX_PROC_STATE% 20, , Hide
    Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_BOOST_MODE% 0, , Hide
    Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_BOOST_MODE% 0, , Hide
  }
  else if (cpuLoad >= cpuIncThreshold || gpuLoad >= gpuIncThreshold || (CURRENT <= LOW_CPU_TDP_THRESHOLD && combinedLoad > COMBO_THRESHOLD && cpuLoad > COMBO_CPU_THRESHOLD)) {
    newTDP := lastTDP
    
    loadDiffCPU := 1 + Abs(cpuLoad - cpuIncThreshold) / 100
    loadDiffGPU := 1 + Abs(gpuLoad - gpuIncThreshold) / 100
    maxTDP := 0
    
    if (cpuLoad >= cpuIncThreshold && loadDiffCPU > loadDiffGPU) {
      newTDP := newTDP + newTDP / loadDiffCPU * HIGH_MULTIPLIER
      maxTDP := maxCPUTDP
      Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_MAX_PROC_STATE% 100, , Hide
      Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_MAX_PROC_STATE% 100, , Hide
      Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_BOOST_MODE% 3, , Hide
      Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_BOOST_MODE% 3, , Hide
    }
    else {
      newTDP := newTDP + newTDP / loadDiffGPU * HIGH_MULTIPLIER
      maxTDP := maxGPUTDP
      Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_MAX_PROC_STATE% 20, , Hide
      Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_MAX_PROC_STATE% 20, , Hide
      Run, powercfg /SETACVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_BOOST_MODE% 0, , Hide
      Run, powercfg /SETDCVALUEINDEX %ACTIVE_POWER_PROFILE% %POWERCFG_PPSUB_PROCESSOR% %POWERCFG_PERF_BOOST_MODE% 0, , Hide
    }
    
    newTDP := newTDP > maxTDP ? maxTDP : newTDP
    boostTDP := newTDP * TDP_HEADROOM_RATIO > maxTDP ? maxTDP : (newTDP * TDP_HEADROOM_RATIO > TDP_HEADROOM_MIN ? newTDP * TDP_HEADROOM_RATIO : TDP_HEADROOM_MIN)
  }
  
  if (Max(newTDP, lastTDP) / Min(newTDP, lastTDP) > DIFF_RATIO) {
    lastTDP := newTDP
  }
  
  return lastTDP
}