# Monitoring Setup Script

This script automates the installation, uninstallation, and dashboard import for a monitoring stack consisting of **Grafana**, **Prometheus**, and **Node Exporter**. It is designed to simplify the setup process for monitoring server resources.

---

## Features

- **Installation**: Installs Grafana, Prometheus, and Node Exporter.
- **Uninstallation**: Removes Grafana, Prometheus, and Node Exporter along with their configurations and logs.
- **Dashboard Import**: Imports Grafana dashboards from a JSON file.
- **Dependency Checks**: Ensures components are not already installed before proceeding.
- **Reinstallation**: Allows reinstallation of components if they are already installed.

---

## Prerequisites

- **Operating System**: Ubuntu/Debian (tested on Ubuntu 20.04 and Debian 11).
- **Dependencies**:
  - `wget`
  - `curl`
  - `systemd`
- **Permissions**: The script requires `sudo` privileges to install and configure components.

---

## Supported Versions

The script uses the following versions of the monitoring tools:

- **Grafana**: Latest stable version (installed via APT repository).
- **Prometheus**: `v2.30.3` (Linux AMD64).
- **Node Exporter**: `v1.2.2` (Linux AMD64).

---

## Usage

### 1. Clone the Repository

```bash
git clone https://github.com/EvgeniiGerasin/grafana-monitoring-server-resources.git
cd grafana-monitoring-server-resources
```

### 2. Make the Script Executable

```bash
chmod +x setup.sh
```

### 3. Run the Script

```bash
./setup.sh
```

---

## Script Options

When you run the script, you will be presented with the following options:

1. **Install**: Installs Grafana, Prometheus, and Node Exporter.
2. **Uninstall**: Removes Grafana, Prometheus, and Node Exporter.
3. **Import Dashboards**: Imports a Grafana dashboard from a JSON file.

---

## Example Workflow

### 1. Installation

```bash
$ ./setup.sh
Choose an action:
1) Install
2) Uninstall
3) Import dashboards from a file
Enter the action number: 1

Installing Grafana...
Installing Prometheus...
Installing Node Exporter...
Configuring Grafana...
Do you want to import dashboards for Grafana? (y/n): y
Enter the path to the dashboard JSON file: /path/to/dashboard.json
Dashboard imported successfully!
Installation complete!
Grafana is available at: http://localhost:3000
Prometheus is available at: http://localhost:9090
Node Exporter is available at: http://localhost:9100/metrics
```

### 2. Uninstallation

```bash
$ ./setup.sh
Choose an action:
1) Install
2) Uninstall
3) Import dashboards from a file
Enter the action number: 2

Stopping and removing services...
Removing Grafana...
Removing Prometheus...
Removing Node Exporter...
Removing configuration files...
Cleaning up logs...
Removing dependencies...
All monitoring components have been removed!
```

### 3. Import Dashboards

```bash
$ ./setup.sh
Choose an action:
1) Install
2) Uninstall
3) Import dashboards from a file
Enter the action number: 3

Enter the path to the dashboard JSON file: /path/to/dashboard.json
Dashboard imported successfully!
```

---

## Configuration Files

### Prometheus Configuration

The script generates a basic `prometheus.yml` configuration file:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
```

### Grafana Configuration

Grafana is installed using the official APT repository. The script does not modify Grafana's default configuration but provides an option to import dashboards.

---

## Logs

Logs for each component are stored in the following locations:

- **Grafana**: `/var/log/grafana/`
- **Prometheus**: `./prometheus.log` (in the Prometheus installation directory).
- **Node Exporter**: `./node_exporter.log` (in the Node Exporter installation directory).

---

## Dependencies

The script installs the following dependencies:

- **Grafana**: Installed via the official Grafana APT repository.
- **Prometheus**: Downloaded from the [Prometheus releases page](https://github.com/prometheus/prometheus/releases).
- **Node Exporter**: Downloaded from the [Node Exporter releases page](https://github.com/prometheus/node_exporter/releases).

---

## Compatibility

This script is compatible with the following Linux distributions:

- **Ubuntu**: Tested on Ubuntu 20.04 LTS and Ubuntu 22.04 LTS.
- **Debian**: Tested on Debian 11 (Bullseye).

---

## Troubleshooting

### Grafana Not Running

If Grafana is not running, ensure the service is started:

```bash
sudo systemctl start grafana-server
```

### Prometheus or Node Exporter Not Running

Check the logs for errors:

```bash
cat /path/to/prometheus.log
cat /path/to/node_exporter.log
```

### Dashboard Import Fails

Ensure the JSON file is valid and Grafana is running before importing.

---

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Grafana](https://grafana.com/)
- [Prometheus](https://prometheus.io/)
- [Node Exporter](https://github.com/prometheus/node_exporter)

---

## Example Output

### Installation Output

```plaintext
Installing Grafana...
Installing Prometheus...
Installing Node Exporter...
Configuring Grafana...
Do you want to import dashboards for Grafana? (y/n): y
Enter the path to the dashboard JSON file: /path/to/dashboard.json
Dashboard imported successfully!
Installation complete!
Grafana is available at: http://localhost:3000
Prometheus is available at: http://localhost:9090
Node Exporter is available at: http://localhost:9100/metrics
```

### Uninstallation Output

```plaintext
Stopping and removing services...
Removing Grafana...
Removing Prometheus...
Removing Node Exporter...
Removing configuration files...
Cleaning up logs...
Removing dependencies...
All monitoring components have been removed!
```

### Dashboard Import Output

```plaintext
Enter the path to the dashboard JSON file: /path/to/dashboard.json
Dashboard imported successfully!
```