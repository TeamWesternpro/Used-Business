@echo off
title Used Dealership Website Server
echo ========================================
echo   Used Dealership Website
echo ========================================
echo.
echo Starting server from "website" folder...
echo.
echo Open these in your browser:
echo   http://localhost:3000          (Listings)
echo   http://localhost:3000/admin.html  (Admin Dashboard)
echo.
echo Login: admin / admin123
echo.
echo Press CTRL+C to stop the server.
echo ========================================
echo.
node server.js
pause
