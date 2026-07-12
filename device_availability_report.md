# Device Availability Report

- **Active Heartbeats**: Periodic status pinging (configured interval 15 seconds)
- **Online Transition**: Database logged and event streamed immediately
- **Offline Transition**: Triggers "Device Lost" event if packet handshake fails
- **Subnet IP updates**: Resolves dynamic IP address changes without manual re-pairing
