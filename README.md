# Part I — Network Architecture Design
![OMNeT++](https://img.shields.io/badge/OMNeT++-Simulation-4B5563?style=flat-square&logo=cplusplus&logoColor=white) ![INET Framework](https://img.shields.io/badge/INET-Framework-F59E0B?style=flat-square&logo=databricks&logoColor=white) ![C++](https://img.shields.io/badge/C++-Backend-2563EB?style=flat-square&logo=cplusplus&logoColor=white) ![Status](https://img.shields.io/badge/Status-Active_Development-10B981?style=flat-square&logo=github&logoColor=white)

**Advanced Networks Course Project · OMNeT++ 6.3 / INET 4.5**
**Team:** @3boudi · @mamouneabdelli · @midouuk
**Status:** ✅ Final version — cleaned & ready for submission

---

## Network Topology

![Network Topology](network_topology_diagram.png)

```
[Client1]──100Mbps──[R1]──100Mbps──[R2]──100Mbps──[R3]──100Mbps──[Server1]
                     |                |                |
                  100Mbps        10Mbps ⚠️          100Mbps
                   (BN)         BOTTLENECK           (BN)
                     |                |                |
[Client2]──100Mbps──[R4]──100Mbps──[R5]──100Mbps──[R6]──100Mbps──[Server2]
```

> ⚠️ Bottleneck link **R2↔R5: 10 Mbps / 20 ms** — intentionally constrained for congestion experiments.

---

## What This Part Does

This part builds the **core IPv6 network infrastructure** used by all other teams.

It includes:

* 6-router mesh topology with redundancy
* IPv6 addressing (`2001:db8::/32`)
* Dynamic routing: RIPng and OSPFv3
* Clean base config for Part II

No application logic here — only **topology + routing**.

---

## Project Structure

```
ipv6-omnet-core/
├── src/
│   └── BasicNetwork.ned
├── omnetpp.ini
├── ospfv3_config.xml
├── IPv6_Addressing_Plan.csv
├── network_topology_diagram.png
├── TESTING_RESULTS.txt
├── results/
```

---

## Routing Configurations

### RIPng

* Distance vector (RFC 2080)
* Slow convergence (~90–150s)
* Uses hop count

```
**.r[*].hasRip = true
**.r[*].rip.mode = "RIPng"
```

---

### OSPFv3

* Link-state (RFC 5340)
* Fast convergence (<30s)
* Uses bandwidth-based cost
* Avoids bottleneck via high metric

```
**.r[*].hasOspf = true
**.r[*].ospf.ospfConfig = xmldoc("ospfv3_config.xml")
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
