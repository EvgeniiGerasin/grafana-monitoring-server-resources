#!/bin/bash

# Function to check if Grafana is installed
check_grafana_installed() {
    if command -v grafana-server &> /dev/null; then
        echo "Grafana is already installed."
        return 0
    else
        return 1
    fi
}

# Function to check if Prometheus is installed
check_prometheus_installed() {
    if [[ -f /opt/prometheus/prometheus ]]; then
        echo "Prometheus is already installed."
        return 0
    else
        return 1
    fi
}

# Function to check if Node Exporter is installed
check_node_exporter_installed() {
    if [[ -f /opt/node_exporter/node_exporter ]]; then
        echo "Node Exporter is already installed."
        return 0
    else
        return 1
    fi
}

# Function to handle dpkg lock issue
handle_dpkg_lock() {
    if lsof /var/lib/dpkg/lock-frontend > /dev/null 2>&1 || lsof /var/lib/dpkg/lock > /dev/null 2>&1; then
        echo "Another process is using the package system. Please wait or terminate it manually."
        exit 1
    fi
}

# Function to install Grafana, Prometheus, and Node Exporter
install() {
    # Check for dpkg lock
    handle_dpkg_lock

    # Install Grafana
    if check_grafana_installed; then
        read -p "Grafana is already installed. Do you want to reinstall? (y/n): " REINSTALL_GRAFANA
        if [[ "$REINSTALL_GRAFANA" != "y" && "$REINSTALL_GRAFANA" != "Y" ]]; then
            echo "Skipping Grafana installation."
        else
            echo "Reinstalling Grafana..."
            sudo apt remove -y --purge grafana
            sudo apt install -y apt-transport-https software-properties-common wget
            curl https://packages.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/grafana.gpg
            echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null
            sudo apt update
            sudo apt install -y grafana
            sudo systemctl start grafana-server
            sudo systemctl enable grafana-server
        fi
    else
        echo "Installing Grafana..."
        sudo apt install -y apt-transport-https software-properties-common wget
        curl https://packages.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/grafana.gpg
        echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null
        sudo apt update
        sudo apt install -y grafana
        sudo systemctl start grafana-server
        sudo systemctl enable grafana-server
    fi

    # Install Prometheus
    if check_prometheus_installed; then
        read -p "Prometheus is already installed. Do you want to reinstall? (y/n): " REINSTALL_PROMETHEUS
        if [[ "$REINSTALL_PROMETHEUS" != "y" && "$REINSTALL_PROMETHEUS" != "Y" ]]; then
            echo "Skipping Prometheus installation."
        else
            echo "Reinstalling Prometheus..."
            sudo rm -rf /opt/prometheus
            wget https://github.com/prometheus/prometheus/releases/download/v2.30.3/prometheus-2.30.3.linux-amd64.tar.gz
            tar xvfz prometheus-2.30.3.linux-amd64.tar.gz
            sudo mv prometheus-2.30.3.linux-amd64 /opt/prometheus

            echo "Configuring Prometheus..."
            cat <<EOL | sudo tee /opt/prometheus/prometheus.yml > /dev/null
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOL

            echo "Starting Prometheus..."
            sudo nohup /opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml > /opt/prometheus/prometheus.log 2>&1 &
        fi
    else
        echo "Installing Prometheus..."
        wget https://github.com/prometheus/prometheus/releases/download/v2.30.3/prometheus-2.30.3.linux-amd64.tar.gz
        tar xvfz prometheus-2.30.3.linux-amd64.tar.gz
        sudo mv prometheus-2.30.3.linux-amd64 /opt/prometheus

        echo "Configuring Prometheus..."
        cat <<EOL | sudo tee /opt/prometheus/prometheus.yml > /dev/null
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOL

        echo "Starting Prometheus..."
        sudo nohup /opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml > /opt/prometheus/prometheus.log 2>&1 &
    fi

    # Install Node Exporter
    if check_node_exporter_installed; then
        read -p "Node Exporter is already installed. Do you want to reinstall? (y/n): " REINSTALL_NODE_EXPORTER
        if [[ "$REINSTALL_NODE_EXPORTER" != "y" && "$REINSTALL_NODE_EXPORTER" != "Y" ]]; then
            echo "Skipping Node Exporter installation."
        else
            echo "Reinstalling Node Exporter..."
            sudo rm -rf /opt/node_exporter
            wget https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-amd64.tar.gz
            tar xvfz node_exporter-1.2.2.linux-amd64.tar.gz
            sudo mv node_exporter-1.2.2.linux-amd64 /opt/node_exporter

            echo "Starting Node Exporter..."
            sudo nohup /opt/node_exporter/node_exporter > /opt/node_exporter/node_exporter.log 2>&1 &
        fi
    else
        echo "Installing Node Exporter..."
        wget https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-amd64.tar.gz
        tar xvfz node_exporter-1.2.2.linux-amd64.tar.gz
        sudo mv node_exporter-1.2.2.linux-amd64 /opt/node_exporter

        echo "Starting Node Exporter..."
        sudo nohup /opt/node_exporter/node_exporter > /opt/node_exporter/node_exporter.log 2>&1 &
    fi

    echo "Configuring Grafana..."
    echo "Waiting for Grafana to become available..."
    until curl -s -o /dev/null -w "%{http_code}" http://admin:admin@localhost:3000/api/health | grep -q "200"; do
        sleep 2
    done

    echo "Grafana is ready. Configuring Prometheus data source..."

    # Создание источника данных
    DATASOURCE_JSON='{
        "name": "Prometheus",
        "type": "prometheus",
        "access": "proxy",
        "url": "http://localhost:9090",
        "isDefault": true
    }'

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$DATASOURCE_JSON" http://admin:admin@localhost:3000/api/datasources)

if [[ "$RESPONSE" == "200" || "$RESPONSE" == "201" ]]; then
    echo "Prometheus data source created successfully."
else
    echo "Failed to create Prometheus data source. Response code: $RESPONSE"
    exit 1
fi

    # Configure Prometheus data source in Grafana
    echo "Configuring Prometheus data source..."
    curl -X POST -H "Content-Type: application/json" -d '{"name":"Prometheus","type":"prometheus","access":"proxy","url":"http://localhost:9090","isDefault":true}' http://admin:admin@localhost:3000/api/datasources

    echo "Installation complete!"
    echo "Grafana is available at: http://localhost:3000"
    echo "Prometheus is available at: http://localhost:9090"
    echo "Node Exporter is available at: http://localhost:9100/metrics"
}

# Function to uninstall Grafana, Prometheus, and Node Exporter
uninstall() {
    echo "Stopping and removing services..."
    sudo systemctl stop grafana-server
    sudo systemctl disable grafana-server
    sudo pkill -f prometheus
    sudo pkill -f node_exporter

    echo "Removing Grafana..."
    sudo apt remove -y --purge grafana
    sudo rm -rf /etc/grafana
    sudo rm -rf /var/lib/grafana

    echo "Removing Prometheus..."
    sudo rm -rf /opt/prometheus

    echo "Removing Node Exporter..."
    sudo rm -rf /opt/node_exporter

    echo "Removing configuration files..."
    sudo rm -rf /etc/prometheus.yml
    sudo rm -rf /etc/systemd/system/prometheus.service
    sudo rm -rf /etc/systemd/system/node_exporter.service

    echo "Cleaning up logs..."
    sudo rm -rf /var/log/grafana
    sudo rm -rf /var/log/prometheus
    sudo rm -rf /var/log/node_exporter

    echo "Removing dependencies..."
    sudo apt autoremove -y
    sudo apt autoclean -y

    echo "All monitoring components have been removed!"
}

# Function to import dashboards into Grafana
import_dashboards() {
    # Check if Grafana is installed
    if ! check_grafana_installed; then
        echo "Grafana is not installed. Please install Grafana before importing dashboards."
        return
    fi

    # Check if Grafana is running
    if ! systemctl is-active --quiet grafana-server; then
        echo "Grafana is not running. Please start Grafana before importing dashboards."
        return
    fi

    # Ask for the path to the dashboard JSON file
    read -p "Enter the path to the dashboard JSON file: " DASHBOARD_PATH
    if [[ -f "$DASHBOARD_PATH" ]]; then
        DASHBOARD_JSON=$(cat "$DASHBOARD_PATH")
        # Use Grafana API to import the dashboard
        curl -X POST -H "Content-Type: application/json" -d "$DASHBOARD_JSON" http://admin:admin@localhost:3000/api/dashboards/db
        echo "Dashboard imported successfully!"
    else
        echo "Dashboard file not found. Import skipped."
    fi
}

# Main menu
echo "Choose an action:"
echo "1) Install"
echo "2) Uninstall"
echo "3) Import dashboards from a file"
read -p "Enter the action number: " ACTION

if [[ "$ACTION" == "1" ]]; then
    install
elif [[ "$ACTION" == "2" ]]; then
    # Check if monitoring components are installed
    if [[ -f /etc/grafana/grafana.ini || -f /opt/prometheus/prometheus || -f /opt/node_exporter/node_exporter ]]; then
        uninstall
    else
        echo "Monitoring components not found. Uninstallation is not required."
    fi
elif [[ "$ACTION" == "3" ]]; then
    import_dashboards
else
    echo "Invalid choice. Exiting."
fi