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