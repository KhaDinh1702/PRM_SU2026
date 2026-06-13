# Script build APK tối ưu hóa cho FlowMate
# Chạy script bằng PowerShell trong thư mục 'mobile/'

Write-Host "=== Bắt đầu build APK tối ưu hóa dung lượng cho FlowMate ===" -ForegroundColor Cyan

# 1. Clean build trước đó
Write-Host "[1/3] Đang dọn dẹp các tệp tin build cũ..." -ForegroundColor Yellow
flutter clean

# 2. Lấy lại các packages
Write-Host "[2/3] Đang tải các packages..." -ForegroundColor Yellow
flutter pub get

# 3. Chạy lệnh build tối ưu hóa
Write-Host "[3/3] Đang bắt đầu biên dịch APK với phân tách ABI và mã hóa code..." -ForegroundColor Yellow
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols

Write-Host "=== Hoàn thành build APK! ===" -ForegroundColor Green
Write-Host "Các tệp tin APK tối ưu theo kiến trúc chip đã được lưu tại: build/app/outputs/flutter-apk/" -ForegroundColor Green
