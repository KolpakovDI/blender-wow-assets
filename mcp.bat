@echo off
REM Wrapper so Cursor workspace MCP can spawn StudioMCP even if cwd is the repo root.
set "STUDIO_MCP=%LOCALAPPDATA%\Roblox\Versions\version-a57f2f633baf4a86\StudioMCP.exe"
if exist "%STUDIO_MCP%" (
  "%STUDIO_MCP%" %*
  exit /b %ERRORLEVEL%
)
if exist "%LOCALAPPDATA%\Roblox\mcp.bat" (
  call "%LOCALAPPDATA%\Roblox\mcp.bat" %*
  exit /b %ERRORLEVEL%
)
echo StudioMCP.exe not found. Open Roblox Studio first. 1>&2
exit /b 1
