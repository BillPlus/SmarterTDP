# SmarterTDP
 Auto TDP limit application for AMD Ryzen 6800U APU under Windows written using AutoHotKey v1

 Once launched, the app will reside in the tray area of taskbar. Right click the tray icon for more options.
 After the first launch, an ini file will be generated that contains the TDP limit values selected via right-click menu.
 If custom values are entered into ini file, the app will use those upon the next launch.
 
 To build, install AutoHotKey v1, then right click the main script (SmarterTDP.ahk) and select Compile.
 Once compiled, the executable should be combined with dll files in the include folder.
 
 These dll files came from RyzenAdj:
 [FlyGoat/RyzenAdj](https://github.com/FlyGoat/RyzenAdj)
 
 The default app icon is created by Aldo Cervantes on FlatIcon:
 https://www.flaticon.com/free-icons/lightning