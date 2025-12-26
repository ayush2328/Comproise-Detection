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
echo "Assessment completed successfully." | tee -a $REPORT
