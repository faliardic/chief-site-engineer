@echo off
setlocal
cd /d "%~dp0"

where python >nul 2>nul
if errorlevel 1 (
  echo HATA: Python bulunamadi. Python 3.12 veya daha yeni bir surum kurun.
  pause
  exit /b 1
)

python -c "import flask, werkzeug" >nul 2>nul
if errorlevel 1 (
  echo HATA: Gerekli Python paketleri eksik.
  echo Once su komutu calistirin: python -m pip install -r requirements.txt
  pause
  exit /b 1
)

python -m app.launcher %*
if errorlevel 1 (
  echo CSE baslatilamadi. Ayrinti icin LOCALAPPDATA altindaki launcher.log dosyasina bakin.
  pause
  exit /b 1
)
