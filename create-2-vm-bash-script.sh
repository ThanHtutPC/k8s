#!/bin/bash

# Path to your ISO - CHANGE THIS TO YOUR ACTUAL PATH
ISO_PATH="/home/thanhtut/Downloads/ISO/ubuntu-24.04.3-live-server-amd64.iso"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to create VMs
create_vms() {
    echo -e "${GREEN}Creating VMs...${NC}"
    
    # Check if ISO exists
    if [ ! -f "$ISO_PATH" ]; then
        echo -e "${RED}Error: ISO file not found at $ISO_PATH${NC}"
        exit 1
    }
    
    # Create VM1
    echo -e "${YELLOW}Creating VM1...${NC}"
    sudo virt-install \
        --name vm1 \
        --memory 1024 \
        --vcpus 2 \
        --disk size=40,path=/var/lib/libvirt/images/vm1.qcow2 \
        --cdrom "$ISO_PATH" \
        --os-variant ubuntu24.04 \
        --network network=default \
        --graphics vnc,listen=0.0.0.0 \
        --console pty,target_type=serial \
        --noautoconsole
    
    # Create VM2
    echo -e "${YELLOW}Creating VM2...${NC}"
    sudo virt-install \
        --name vm2 \
        --memory 1024 \
        --vcpus 2 \
        --disk size=40,path=/var/lib/libvirt/images/vm2.qcow2 \
        --cdrom "$ISO_PATH" \
        --os-variant ubuntu24.04 \
        --network network=default \
        --graphics vnc,listen=0.0.0.0 \
        --console pty,target_type=serial \
        --noautoconsole
    
    echo -e "${GREEN}VMs created successfully!${NC}"
    show_vms
}

# Function to delete VMs
delete_vms() {
    echo -e "${RED}Deleting VMs...${NC}"
    
    # Stop and delete VM1
    if sudo virsh dominfo vm1 &>/dev/null; then
        echo -e "${YELLOW}Stopping VM1...${NC}"
        sudo virsh destroy vm1 2>/dev/null
        echo -e "${YELLOW}Deleting VM1...${NC}"
        sudo virsh undefine vm1 --remove-all-storage
    else
        echo -e "VM1 not found"
    fi
    
    # Stop and delete VM2
    if sudo virsh dominfo vm2 &>/dev/null; then
        echo -e "${YELLOW}Stopping VM2...${NC}"
        sudo virsh destroy vm2 2>/dev/null
        echo -e "${YELLOW}Deleting VM2...${NC}"
        sudo virsh undefine vm2 --remove-all-storage
    else
        echo -e "VM2 not found"
    fi
    
    # Also remove disk files if they exist
    echo -e "${YELLOW}Removing disk files...${NC}"
    sudo rm -f /var/lib/libvirt/images/vm1.qcow2
    sudo rm -f /var/lib/libvirt/images/vm2.qcow2
    
    echo -e "${GREEN}VMs deleted successfully!${NC}"
}

# Function to list VMs
list_vms() {
    echo -e "${GREEN}Current VMs:${NC}"
    sudo virsh list --all
}

# Function to show VM details
show_vms() {
    echo -e "${GREEN}VM Details:${NC}"
    for vm in vm1 vm2; do
        if sudo virsh dominfo $vm &>/dev/null; then
            echo -e "${YELLOW}$vm:${NC}"
            sudo virsh dominfo $vm | grep -E "State|CPU|Memory"
            echo "---"
        fi
    done
}

# Function to start VMs
start_vms() {
    echo -e "${GREEN}Starting VMs...${NC}"
    sudo virsh start vm1 2>/dev/null || echo "VM1 already running or not found"
    sudo virsh start vm2 2>/dev/null || echo "VM2 already running or not found"
}

# Function to stop VMs
stop_vms() {
    echo -e "${RED}Stopping VMs...${NC}"
    sudo virsh shutdown vm1 2>/dev/null || echo "VM1 not running"
    sudo virsh shutdown vm2 2>/dev/null || echo "VM2 not running"
}

# Function to force stop VMs
force_stop_vms() {
    echo -e "${RED}Force stopping VMs...${NC}"
    sudo virsh destroy vm1 2>/dev/null || echo "VM1 not running"
    sudo virsh destroy vm2 2>/dev/null || echo "VM2 not running"
}

# Function to show VNC ports
show_vnc_ports() {
    echo -e "${GREEN}VNC ports:${NC}"
    for vm in vm1 vm2; do
        if sudo virsh dominfo $vm &>/dev/null; then
            vnc_port=$(sudo virsh vncdisplay $vm 2>/dev/null)
            echo "$vm: $vnc_port"
        fi
    done
}

# Function to show help
show_help() {
    echo -e "${GREEN}VM Management Script${NC}"
    echo "Usage: ./manage-vms.sh [command]"
    echo ""
    echo "Commands:"
    echo "  create    - Create both VMs"
    echo "  delete    - Delete both VMs (with disks)"
    echo "  list      - List all VMs"
    echo "  show      - Show VM details"
    echo "  start     - Start both VMs"
    echo "  stop      - Shutdown both VMs gracefully"
    echo "  force-stop - Force stop both VMs"
    echo "  vnc       - Show VNC ports"
    echo "  restart   - Restart both VMs"
    echo "  status    - Show VM status"
    echo "  help      - Show this help"
}

# Function to show status
show_status() {
    echo -e "${GREEN}VM Status:${NC}"
    for vm in vm1 vm2; do
        if sudo virsh dominfo $vm &>/dev/null; then
            state=$(sudo virsh domstate $vm)
            echo "$vm: $state"
        else
            echo "$vm: Not found"
        fi
    done
}

# Function to restart VMs
restart_vms() {
    echo -e "${YELLOW}Restarting VMs...${NC}"
    stop_vms
    sleep 5
    start_vms
}

# Main script
case "${1:-help}" in
    create)
        create_vms
        ;;
    delete)
        echo -e "${RED}Are you sure you want to delete both VMs? (y/N)${NC}"
        read -r confirm
        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            delete_vms
        else
            echo "Deletion cancelled"
        fi
        ;;
    list)
        list_vms
        ;;
    show)
        show_vms
        ;;
    start)
        start_vms
        ;;
    stop)
        stop_vms
        ;;
    force-stop)
        force_stop_vms
        ;;
    vnc)
        show_vnc_ports
        ;;
    restart)
        restart_vms
        ;;
    status)
        show_status
        ;;
    help|*)
        show_help
        ;;
esac
