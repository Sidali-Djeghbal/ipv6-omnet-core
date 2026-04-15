# Part I — Network Architecture Design
![OMNeT++](https://img.shields.io/badge/OMNeT++-Simulation-4B5563?style=flat-square&logo=cplusplus&logoColor=white) ![INET Framework](https://img.shields.io/badge/INET-Framework-F59E0B?style=flat-square&logo=databricks&logoColor=white)

**Advanced Networks Course Project · OMNeT++ 6.3.0 / INET 4.6**

**Status:** ✅ Final version — Integrated and Tested

---

## Network Topology

```
[Client1]──100Mbps──[R1]──100Mbps──[R2]──100Mbps──[R3]──100Mbps──[Server1]
                     |                |                |
                  100Mbps       10Mbps/20ms        100Mbps
                   (Cross)       BOTTLENECK        (Cross)
                     |                |                |
[Client2]──100Mbps──[R4]──100Mbps──[R5]──100Mbps──[R6]──100Mbps──[Server2]
```

> ⚠️ Bottleneck link **r2↔r5: 10 Mbps / 20 ms** — intentionally constrained for congestion and QoS experiments in Part II and III.

---

## What This Part Does

This part builds the **core IPv6 network infrastructure** used by all other phases of the project.

It includes:
* 6-router mesh topology with redundancy
* IPv6 addressing architecture
* Dynamic routing: RIPng and OSPFv3
* Clean base configurations acting as the foundation for Transport and QoS testing.

---

##  What Part I Contains
 
### `src/BasicNetwork.ned` — Topology
 
Defines the full network structure:
 
| Element | Count | Detail |
|---------|-------|--------|
| Core Routers | 6 | r1, r2, r3, r4, r5, r6 |
| Client Hosts | 2 | client1 (TCP), client2 (UDP) |
| Server Hosts | 2 | server1, server2 |
| LAN Links | 4 | 100 Mbps / 2 ms |
| Core Links | 6 | 100 Mbps / 10 ms |
| Bottleneck Link | 1 | r2↔r5 (10 Mbps / 20 ms delay) |
 
**Design decisions:**
* **IPv6 only:** Required for modern protocol comparison.
* **6-router mesh:** Satisfies project requirements while providing multiple routing paths.
* **Central Bottleneck:** Forces congestion when multiple streams compete, strictly necessary for evaluating DiffServ vs IntServ in Part III.

---
 
### `omnetpp.ini` — Simulation Routing Foundation
 
The baseline routing structure provides two global routing families:
 
#### RIPng — Distance-Vector routing
Configures all routers to use `ipv6Rip`. RIPng counts hops and provides a baseline for stabilization delay.

#### OSPFv3 — Link-State routing
Configured through the INET 4.6 explicit Splitter mechanism and XML binding. The metric for the bottleneck link is artificially inflated to demonstrate OSPF's capacity-aware routing intelligence relative to RIPng.
 
---
 
### `ospfv3_splitter_config.xml` — OSPFv3 Area Configuration
 
Defines each router's interfaces in the OSPF backbone (Area 0.0.0.0). This uses the strict `<Interface>` binding required by newer INET versions:

```xml
<Router name="r2" RFC1583Compatible="true">
  <PointToPointInterface ifName="eth0" areaID="0.0.0.0" interfaceOutputCost="10" />
  <PointToPointInterface ifName="eth2" areaID="0.0.0.0" interfaceOutputCost="100" /> <!-- Bottleneck -->
</Router>
```
 
---
 
##  IPv6 Addressing Plan
 
All subnets are assigned cleanly within the topology. 
See the full assignment extraction: [`docs/IPv6_Addressing_Plan.csv`](docs/IPv6_Addressing_Plan.csv)
 
---
 
##  Project Structure Provided by Part I

```
ipv6-omnet-core/
├── src/
│   └── BasicNetwork.ned
├── omnetpp.ini
├── ospfv3_splitter_config.xml
└── docs/
    ├── network_topology_diagram.png
    ├── IPv6_Addressing_Plan.csv
    └── TESTING_RESULTS.txt
```

```
*.r*.hasRip = true
*.r*.rip.mode = "RIPng"
```

---

### OSPFv3

* Link-state (RFC 5340)
* Fast convergence (<30s)
* Uses bandwidth-based cost
* Avoids bottleneck via high metric

```
*.r*.hasOspf = true
*.r*.ospf.ospfConfig = xmldoc("ospfv3_config.xml")
```

---

## IPv6 Addressing

All subnets are auto-assigned using `Ipv6FlatNetworkConfigurator`.

Example:

| Subnet      | Prefix             |
| ----------- | ------------------ |
| Client1 LAN | 2001:db8:0:10::/64 |
| Client2 LAN | 2001:db8:0:20::/64 |
| Server1 LAN | 2001:db8:0:30::/64 |
| Server2 LAN | 2001:db8:0:40::/64 |
| Bottleneck  | 2001:db8:0:25::/64 |

---

## How to Run

### RIPng

```
opp_run -u Cmdenv -c RIPng omnetpp.ini
```

### OSPFv3

```
opp_run -u Cmdenv -c OSPFv3 omnetpp.ini
```

---

## Key Results

| Metric               | RIPng | OSPFv3  |
| -------------------- | ----- | ------- |
| Convergence          | Slow  | Fast    |
| Path quality         | Weak  | Optimal |
| Bottleneck avoidance | ❌     | ✅       |

---

## Notes for Next Parts

* **Part II:** extend configs, don’t modify base
* **Part III:** congestion happens at R2–R5
* **Part IV:** IPv6 already enabled
* **Part V:** use `results/` for analysis

---

## Dependencies

* OMNeT++ 6.3
* INET 4.5

---

## References

* RFC 2080 — RIPng
* RFC 5340 — OSPFv3
* OMNeT++ / INET docs
