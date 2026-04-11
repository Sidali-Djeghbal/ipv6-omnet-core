#  Part I — Network Architecture Design

**Advanced Networks Course Project · OMNeT++ 6.3 / INET 4.5**  
**Team 01:** @3boudi · @mamouneabdelli · @midouuk  
**Status:** ✅ All issues fixed — Ready for submission

---

##  Network Topology

![Network Topology](network_topology_diagram.png)

```
[Client1]──100Mbps──[R1]──100Mbps──[R2]──100Mbps──[R3]──100Mbps──[Server1]
                     |                |                |
                  100Mbps        10Mbps ⚠️          100Mbps
                   (BN)         BOTTLENECK           (BN)
                     |                |                |
[Client2]──100Mbps──[R4]──100Mbps──[R5]──100Mbps──[R6]──100Mbps──[Server2]
```

> ⚠️ **Bottleneck link R2↔R5:** 10 Mbps / 20 ms — deliberately constrained to force congestion for Parts II & III experiments.

---

##  Project File Structure

```
ipv6-omnet-core/
│
├── src/
│   └── BasicNetwork.ned            ← Network topology (routers, hosts, links)
│
├── omnetpp.ini                     ← All simulation configs
├── ospfv3_config.xml               ← OSPFv3 Area 0 interface definitions
│
├── network_topology_diagram.png    ← Visual topology diagram
├── IPv6_Addressing_Plan.csv        ← All 11 subnets documented
├── TESTING_RESULTS.txt             ← Verified test results
│
├── Makefile                        ← Build configuration (INET 4.5 path)
├── .project                        ← Eclipse/OMNeT++ IDE project file
│
└── results/                        ← Auto-generated simulation output
    ├── RIPng-0.sca
    ├── RIPng-0.vec
    ├── OSPFv3-0.sca
    └── OSPFv3-0.vec
```

---

##  What Part I Is About

Part I is the **foundation layer** of the entire project. Every other team (Parts II–V) builds directly on top of this infrastructure. Our job was to:

1. Design a realistic **6-router IPv6 mesh network** with redundant paths and a deliberate bottleneck
2. Configure **two dynamic routing protocols** — RIPng and OSPFv3 — selectable via separate simulation configs
3. Provide a clean **handoff scaffold** (`[Config Part_II_Base]`) for the transport protocol team

No application-level traffic belongs here. Part I owns only **topology, addressing, and routing**.

---

##  What Part I Contains

### `BasicNetwork.ned` — Topology

Defines the full network structure:

| Element | Count | Detail |
|---------|-------|--------|
| Core Routers | 6 | R1, R2, R3, R4, R5, R6 |
| Client Hosts | 2 | Client1 (TCP), Client2 (UDP) |
| Server Hosts | 2 | Server1 (port 1000), Server2 (port 2000) |
| LAN Links | 4 | 100 Mbps / 2 ms |
| Core Links | 6 | 100 Mbps / 10 ms |
| Bottleneck Link | 1 | R2↔R5 — 10 Mbps / 20 ms |

**Design decisions:**

| Decision | Choice | Reason |
|----------|--------|--------|
| IP version | IPv6 only | Required for RIPng and OSPFv3 |
| Topology | 6-router mesh | Satisfies requirements + redundancy for OSPF cost comparison |
| Bottleneck | R2–R5 @ 10 Mbps | Forces congestion when both flows compete — needed by Part II |
| LAN links | 100 Mbps | LAN is never the bottleneck |
| Core links | 100 Mbps | 10× faster than bottleneck |

---

### `omnetpp.ini` — Simulation Configs

Contains **4 configs** — each inheriting from `[General]`:

#### `[General]` — Infrastructure only (Part I owns this — do not modify)
- Sets `src.BasicNetwork` as the network
- 100s simulation time
- IPv6 enabled (`**.hasIpv6 = true`, `**.hasIpv4 = false`)
- `Ipv6FlatNetworkConfigurator` assigns `2001:db8::/32` addresses automatically
- TCP stack baseline: `TcpReno`
- Output files: `results/${configname}-${runnumber}.sca/.vec`

#### `[Config RIPng]` — Distance-Vector routing (RFC 2080)
```ini
**.r[*].hasRip          = true
**.r[*].rip.mode        = "RIPng"
**.r[*].rip.updateInterval   = 30s
**.r[*].rip.routeExpiryTime  = 180s
**.r[*].rip.routePurgeTime   = 120s
```
- Disables static routes — lets RIPng build the table dynamically
- Converges in ~90–150s (hop-count metric)

#### `[Config OSPFv3]` — Link-State routing (RFC 5340)
```ini
**.r[*].hasOspf                 = true
**.r[*].ospf.ospfConfig         = xmldoc("ospfv3_config.xml")
**.r[*].ospf.helloInterval      = 10s
**.r[*].ospf.deadInterval       = 40s
**.r[*].ospf.retransmitInterval = 5s
```
- All 6 routers in Area 0 (backbone)
- Bottleneck link gets `metric=100` → OSPFv3 avoids it when possible
- Converges in <30s (bandwidth-aware metric)

#### `[Config Part_II_Base]` — Scaffold for Part II team
- Extends `RIPng`
- Adds TCP (`TcpSessionApp`) and UDP (`UdpBasicApp`) traffic
- Part II team creates new configs that `extend = Part_II_Base`

---

### `ospfv3_config.xml` — OSPFv3 Area Configuration

Defines each router's interfaces in Area 0. Key detail: the bottleneck interfaces (R2 `eth2` and R5 `eth2`) are assigned `metric="100"` to make OSPFv3 prefer alternate paths:

```xml
<Router id="r2" ipv6="true">
  <Area id="0.0.0.0">
    <Interface name="eth0" type="PointToPoint"/>           <!-- → R1 -->
    <Interface name="eth1" type="PointToPoint"/>           <!-- → R3 -->
    <Interface name="eth2" type="PointToPoint" metric="100"/> <!-- → R5 BOTTLENECK -->
  </Area>
</Router>
```

---

##  IPv6 Addressing Plan

All 11 subnets assigned automatically by `Ipv6FlatNetworkConfigurator` in the `2001:db8::/32` block.  
See full table: [`IPv6_Addressing_Plan.csv`](IPv6_Addressing_Plan.csv)

| Subnet | Prefix | Connected Nodes |
|--------|--------|-----------------|
| Client1 LAN | `2001:db8:0:10::/64` | Client1 ↔ R1 eth0 |
| Client2 LAN | `2001:db8:0:20::/64` | Client2 ↔ R4 eth0 |
| Server1 LAN | `2001:db8:0:30::/64` | Server1 ↔ R3 eth1 |
| Server2 LAN | `2001:db8:0:40::/64` | Server2 ↔ R6 eth1 |
| R1–R2 Core | `2001:db8:0:12::/64` | R1 eth1 ↔ R2 eth0 |
| R2–R3 Core | `2001:db8:0:23::/64` | R2 eth1 ↔ R3 eth0 |
| R4–R5 Core | `2001:db8:0:45::/64` | R4 eth1 ↔ R5 eth0 |
| R5–R6 Core | `2001:db8:0:56::/64` | R5 eth1 ↔ R6 eth0 |
| R1–R4 Cross | `2001:db8:0:14::/64` | R1 eth2 ↔ R4 eth2 |
| R3–R6 Cross | `2001:db8:0:36::/64` | R3 eth2 ↔ R6 eth2 |
| R2–R5 Bottleneck ⚠️ | `2001:db8:0:25::/64` | R2 eth2 ↔ R5 eth2 |

---

## 🧪 Test Results

See full report: [`TESTING_RESULTS.txt`](TESTING_RESULTS.txt)

| Config | Result | Duration | Output Files |
|--------|--------|----------|--------------|
| `RIPng` | ✅ PASS | 100s | `RIPng-0.sca` + `RIPng-0.vec` |
| `OSPFv3` | ✅ PASS | 100s | `OSPFv3-0.sca` + `OSPFv3-0.vec` |

**How to run:**
```bash
# RIPng
opp_run -u Cmdenv -c RIPng omnetpp.ini

# OSPFv3
opp_run -u Cmdenv -c OSPFv3 omnetpp.ini
```

**RIPng vs OSPFv3 comparison:**

| Metric | RIPng | OSPFv3 |
|--------|-------|--------|
| Convergence speed | ~90–150s | <30s |
| Routing metric | Hop count | Link cost (bandwidth) |
| Path selection | Suboptimal | Optimal (avoids bottleneck) |
| Scalability | Max 15 hops | Unlimited |
| Overhead | Low | Higher (LSA flooding) |

---


### Part II — Transport Protocol Analysis
- Use `[Config Part_II_Base]` as your starting point
- Create new `[Config TCP_YourVariant]` sections — extend `Part_II_Base`
- **Do NOT modify** `[General]`, `[Config RIPng]`, or `[Config OSPFv3]`

```ini
[Config TCP_Cubic_Test]
extends = Part_II_Base
**.tcp.tcpAlgorithmClass = "TcpCubic"
```

### Part III — QoS
- Bottleneck is at R2↔R5 (10 Mbps / 20 ms) — that's where congestion occurs
- Extend Part II configs for DiffServ/IntServ experiments

### Part IV — Advanced Technologies
- IPv6 already enabled (`**.hasIpv6 = true`)
- Extend `BasicNetwork.ned` only if adding mobility modules

### Part V — Data Analytics
- All results in `results/` — use `opp_scavetool` for CSV extraction
- Config naming: `${configname}-${runnumber}.sca/.vec`

---

##  Dependencies

| Tool | Version |
|------|---------|
| OMNeT++ | 6.3.0 |
| INET Framework | 4.5 |
| Platform | Windows x86_64 |

**References:**
- RFC 2080 — RIPng for IPv6
- RFC 5340 — OSPFv3 for IPv6
- [INET Docs — Routing](https://inet.omnetpp.org/docs/users-guide/ch-routing.html)
- [OMNeT++ Manual](https://doc.omnetpp.org)
- [Project Review — Team 01](https://sidali-djeghbal.github.io/networkproject/team01.html)