REM Delete everything that could be in the target folder, including debug items.
REM If something is not there, the DEL skips without error.
REM Also deletes the ShaderCache, ShaderFixes, ShaderFromGame folders

del d3d9.dll
del d3d9_log.txt
del d3d9.exp
del d3d9.pdb
del d3d9.ilk
del d3d9.lib

del d3d10.dll
del d3d10_log.txt
del d3d10.exp
del d3d10.pdb
del d3d10.ilk
del d3d10.lib

del d3d11.dll
del d3d11_log.txt
del d3d11.exp
del d3d11.pdb
del d3d11.ilk
del d3d11.lib

del D3DCompiler_39.dll
del D3DCompiler_39_org.dll
del D3DCompiler_39_log.txt
del D3DCompiler_39.exp
del D3DCompiler_39.pdb
del D3DCompiler_39.ilk
del D3DCompiler_39.lib

del D3DCompiler_41.dll
del D3DCompiler_41_org.dll
del D3DCompiler_41_log.txt
del D3DCompiler_41.exp
del D3DCompiler_41.pdb
del D3DCompiler_41.ilk
del D3DCompiler_41.lib

del D3DCompiler_42.dll
del D3DCompiler_42_org.dll
del D3DCompiler_42_log.txt
del D3DCompiler_42.exp
del D3DCompiler_42.pdb
del D3DCompiler_42.ilk
del D3DCompiler_42.lib

del D3DCompiler_43.dll
del D3DCompiler_43_org.dll
del D3DCompiler_43_log.txt
del D3DCompiler_43.exp
del D3DCompiler_43.pdb
del D3DCompiler_43.ilk
del D3DCompiler_43.lib

del D3DCompiler_46.dll
del D3DCompiler_46_org.dll
del D3DCompiler_46_log.txt
del D3DCompiler_46.exp
del D3DCompiler_46.pdb
del D3DCompiler_46.ilk
del D3DCompiler_46.lib

del dxgi.dll
del dxgi_log.txt
del dxgi.exp
del dxgi.pdb
del dxgi.ilk
del dxgi.lib

del nvapi.dll
del nvapi_log.txt
del nvapi.exp
del nvapi.pdb
del nvapi.ilk
del nvapi.lib

del XInput9_1_0.dll
del d3dx.ini

del D3D_Shaders.exe
del D3D_Shaders.pdb
del D3D_Shaders.ilk

del BinaryDecompiler.lib

del ShaderUsage.txt

rmdir /s /q ShaderFixes
rmdir /s /q ShaderCache
rmdir /s /q ShaderFromGame

del uninstall.bat