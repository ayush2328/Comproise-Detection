#!/bin/bash

REPORT="android_security_report.txt"
echo "Android Device Security Assessment Report" > $REPORT
echo "========================================" >> $REPORT
echo "" >> $REPORT

# Check device connection
DEVICE=$(adb devices | sed -n '2p' | awk '{print $1}')
if [ -z "$DEVICE" ]; then
    echo "[!] No Android device detected"
    exit 1
fi

echo "[+] Device Connected: $DEVICE" | tee -a $REPORT

# Android version
ANDROID_VERSION=$(adb shell getprop ro.build.version.release)
echo "[+] Android Version: $ANDROID_VERSION" | tee -a $REPORT

# USB Debugging status
USB_DEBUG=$(adb shell settings get global adb_enabled)
if [ "$USB_DEBUG" == "1" ]; then
    echo "[!] USB Debugging ENABLED" | tee -a $REPORT
else
    echo "[+] USB Debugging DISABLED" | tee -a $REPORT
fi

# Root detection
ROOT_CHECK=$(adb shell which su)
if [ -n "$ROOT_CHECK" ]; then
    echo "[!] ROOT DETECTED: $ROOT_CHECK" | tee -a $REPORT
    ROOT_SCORE=3
else
    echo "[+] Root NOT detected" | tee -a $REPORT
    ROOT_SCORE=0
fi

# Dangerous apps check
echo "" >> $REPORT
echo "Checking installed apps for risk..." >> $REPORT
DANGEROUS_APPS=$(adb shell pm list packages --user 0 2>/dev/null | grep -E "supersu|magisk|frida")
if [ -n "$DANGEROUS_APPS" ]; then
    echo "[!] Suspicious apps found:" | tee -a $REPORT
    echo "$DANGEROUS_APPS" | tee -a $REPORT
    APP_SCORE=2
else
    echo "[+] No known dangerous apps found" | tee -a $REPORT
    APP_SCORE=0
fi

# Risk calculation
TOTAL_SCORE=$((ROOT_SCORE + APP_SCORE))

echo "" >> $REPORT
if [ $TOTAL_SCORE -ge 4 ]; then
    echo "FINAL RISK: HIGH" | tee -a $REPORT
elif [ $TOTAL_SCORE -ge 2 ]; then
    echo "FINAL RISK: MEDIUM" | tee -a $REPORT
else
    echo "FINAL RISK: LOW" | tee -a $REPORT
fi

echo "" >> $REPORT

echo ""
echo "================ ADDITIONAL SECURITY CHECKS ================" | tee -a $REPORT

# -------------------------------
# 1️⃣ Battery Percentage
# -------------------------------
echo "" | tee -a $REPORT
echo "Battery Information:" | tee -a $REPORT

BATTERY_LEVEL=$(adb shell dumpsys battery | awk '/level:/{print $2}')
BATTERY_STATUS=$(adb shell dumpsys battery | awk '/status:/{print $2}')

echo "[+] Battery Level: $BATTERY_LEVEL%" | tee -a $REPORT
echo "[+] Battery Status Code: $BATTERY_STATUS" | tee -a $REPORT


# -------------------------------
# 2️⃣ VPN Detection
# -------------------------------
echo "" | tee -a $REPORT
echo "VPN Status Check:" | tee -a $REPORT

VPN_ACTIVE=$(adb shell dumpsys connectivity | grep -i "vpn" | grep -i "active")

if [ -n "$VPN_ACTIVE" ]; then
    echo "[!] VPN is ACTIVE on device" | tee -a $REPORT
else
    echo "[+] No active VPN detected" | tee -a $REPORT
fi


# -------------------------------
# 3️⃣ IPv4 & IPv6 Address
# -------------------------------
echo "" | tee -a $REPORT
echo "IP Address Information:" | tee -a $REPORT

IP_INFO=$(adb shell ip addr | grep -E "inet |inet6" | grep -v "127.0.0.1")

if [ -n "$IP_INFO" ]; then
    echo "$IP_INFO" | tee -a $REPORT
else
    echo "[!] No active IP address detected" | tee -a $REPORT
fi

# -------------------------------
# 4️⃣ Camera Usage Detection (SAFE)
# -------------------------------
echo "" | tee -a $REPORT
echo "Camera Usage Detection:" | tee -a $REPORT

CAMERA_USAGE=$(adb shell appops get --uid CAMERA 2>/dev/null)

if echo "$CAMERA_USAGE" | grep -qi "allow"; then
    echo "[!] Camera was accessed recently" | tee -a $REPORT
    echo "$CAMERA_USAGE" | tee -a $REPORT
else
    echo "[+] No recent camera access detected" | tee -a $REPORT
fi


# -------------------------------
# 5️⃣ Screen Lock & Encryption Status
# -------------------------------
echo "" | tee -a $REPORT
echo "Device Protection Status:" | tee -a $REPORT

LOCK_STATUS=$(adb shell settings get secure lock_screen_lock_after_timeout)
if [ "$LOCK_STATUS" = "null" ]; then
    echo "[!] Screen lock NOT configured" | tee -a $REPORT
else
    echo "[+] Screen lock is enabled" | tee -a $REPORT
fi

ENCRYPTION_STATUS=$(adb shell getprop ro.crypto.state)
if [ "$ENCRYPTION_STATUS" = "encrypted" ]; then
    echo "[+] Device storage is encrypted" | tee -a $REPORT
else
    echo "[!] Device storage NOT encrypted" | tee -a $REPORT
fi

echo "Assessment completed successfully." | tee -a $REPORT

# Screen Share
share_screen() {
    echo "[*] Starting live screen sharing..."
    adb exec-out screenrecord --output-format=h264 - | ffplay -framerate 60 -probesize 32 -sync video -
}
echo ""
echo "================ ACTION MENU ================"
echo "1) View security report"
echo "2) Share connected device screen (LIVE)"
echo "3) Exit"
echo "============================================="
read -p "Choose an option: " CHOICE

case $CHOICE in
    1)
        echo ""
        echo "----- ANDROID SECURITY REPORT -----"
        cat $REPORT
        ;;
    2)
        share_screen
        ;;
    3)
        echo "Exiting tool."
        exit 0
        ;;
    *)
        echo "Invalid option."
        ;;
esac
