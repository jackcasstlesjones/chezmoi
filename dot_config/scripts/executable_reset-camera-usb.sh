#!/bin/bash
# Reset USB controller to restore camera after suspend
# Camera: SunplusIT Integrated RGB Camera (174f:11b4)
# USB Controller: 0000:c4:00.4 (usb1)

# Wait a moment for system to stabilize after resume
sleep 2

# Check if camera is missing
if ! lsusb | grep -q "174f:11b4"; then
    echo "Camera not found after resume, resetting USB controller..."

    # Unbind the USB controller
    echo "0000:c4:00.4" > /sys/bus/pci/drivers/xhci_hcd/unbind
    sleep 2

    # Rebind the USB controller
    echo "0000:c4:00.4" > /sys/bus/pci/drivers/xhci_hcd/bind
    sleep 2

    # Verify camera is back
    if lsusb | grep -q "174f:11b4"; then
        echo "Camera successfully restored"
        exit 0
    else
        echo "Camera still not detected"
        exit 1
    fi
else
    echo "Camera already present, no action needed"
    exit 0
fi
