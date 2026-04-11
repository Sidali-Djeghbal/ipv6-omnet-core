# Part I — Network Architecture Design
**Advanced Networks Course Project · OMNeT++ / INET Framework**  
**Team:** @3boudi · @mamouneabdelli · @midouuk

---

## What We Built

This part implements the **baseline IPv6 routed network** that all other sub-teams (II–V) will build on. It provides:

- A **6-router mesh topology** with deliberate redundancy and a constrained bottleneck link
- **IPv6 addressing** using the `2001:db8::/32` documentation prefix
- **Two dynamic routing protocols** — RIPng and OSPFv3 — selectable via separate INI configs
- **TCP + UDP traffic** from the project template, preserved and ready for Part II analysis

---

## File Structure

```
AdvancedNetworksProject/
├── src/
│   └── BasicNetwork.ned        ← Topology definition (nodes + links)
├── omnetpp.ini                 ← All simulation configs (RIPng, OSPFv3, sweep)
├── results/                    ← Auto-created; holds .sca and .vec output files
├── network_topology.html       ← Visual topology diagram (open in browser)
└── README_PartI.md             ← This file
```

---

## Topology Overview

```
[Client1]──100Mbps──[R1]──10Mbps──[R2]──10Mbps──[R3]──100Mbps──[Server1]
                     |              |               |
                  10Mbps       5Mbps(BN)        10Mbps
                     |              |               |
[Client2]──100Mbps──[R4]──10Mbps──[R5]──10Mbps──[R6]──100Mbps──[Server2]
```

**BN** = Bottleneck link (R2–R5): 5 Mbps, 20 ms — this is where congestion happens.

### Design Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| IP version | IPv6 | Required for advanced work; enables RIPng and OSPFv3 |
| Topology | 6-router mesh with 2 stub LANs | Satisfies minimum 6 routers, adds redundancy for OSPF cost comparison |
| Bottleneck | R2–R5 @ 5 Mbps | Forces congestion when both flows compete — needed by Part II |
| LAN links | 100 Mbps | Ensures LAN is never the bottleneck |
| Core links | 10 Mbps | Creates realistic WAN-style constraints |

---

## IPv6 Addressing Plan

The `Ipv6FlatNetworkConfigurator` automatically assigns addresses in the `2001:db8::/32` block. The logical plan is:

| Subnet | Prefix | Nodes |
|--------|--------|-------|
| Client1 LAN | `2001:db8:0:10::/64` | Client1, R1 eth0 |
| Client2 LAN | `2001:db8:0:20::/64` | Client2, R4 eth0 |
| Server1 LAN | `2001:db8:0:30::/64` | Server1, R3 eth2 |
| Server2 LAN | `2001:db8:0:40::/64` | Server2, R6 eth2 |
| R1–R2 core  | `2001:db8:0:12::/64` | R1 eth1, R2 eth0 |
| R2–R3 core  | `2001:db8:0:23::/64` | R2 eth1, R3 eth0 |
| R1–R4 core  | `2001:db8:0:14::/64` | R1 eth2, R4 eth1 |
| R4–R5 core  | `2001:db8:0:45::/64` | R4 eth2, R5 eth0 |
| R5–R6 core  | `2001:db8:0:56::/64` | R5 eth2, R6 eth0 |
| R3–R6 core  | `2001:db8:0:36::/64` | R3 eth1, R6 eth1 |
| R2–R5 (BN)  | `2001:db8:0:25::/64` | R2 eth2, R5 eth1 |

---

## How to Run

### 1. Import into OMNeT++ IDE
1. `File → Import → General → Existing Projects into Workspace`
2. Select the `AdvancedNetworksProject/` directory
3. Make sure the **INET Framework** is in your workspace

### 2. Run the RIPng Config
```
Right-click omnetpp.ini → Run As → OMNeT++ Simulation
Select config: RIPng
```
Or from the terminal:
```bash
opp_run -u Cmdenv -c RIPng omnetpp.ini
```

### 3. Run the OSPFv3 Config
```bash
opp_run -u Cmdenv -c OSPFv3 omnetpp.ini
```

### 4. Run the Bottleneck Parameter Study
This automatically runs 3 simulations (1 Mbps, 5 Mbps, 10 Mbps):
```bash
opp_run -u Cmdenv -c Bottleneck_Study omnetpp.ini
```
Results land in `results/bottleneck-1Mbps-0.sca`, `bottleneck-5Mbps-0.sca`, etc.

---

## What to Observe

After running, open **OMNeT++ IDE's Analysis Tool** and load the `.sca`/`.vec` files from `results/`.

### Key measurements for Part I report:

1. **Routing Convergence Time**  
   Plot `routeAdded` vector on any router — the time until it stabilises shows how fast the protocol converges.  
   *RIPng typically takes 90–150 s; OSPFv3 converges in under 30 s.*

2. **Routing Table Size**  
   Check `numRoutes` scalar on each router — both protocols should discover all 11 subnets.

3. **TCP Throughput**  
   `client1.app[0].throughput` — observe difference between RIPng and OSPFv3 runs.  
   OSPFv3 may find a better path through lower-cost links.

4. **UDP Packet Loss at Bottleneck**  
   `server2.app[0].dropPk` — shows congestion severity.

### Comparing RIPng vs OSPFv3

| Metric | RIPng | OSPFv3 |
|--------|-------|--------|
| Convergence speed | Slow (up to 180 s) | Fast (< 30 s) |
| Metric | Hop count | Link cost (bandwidth-based) |
| Optimal path selection | Suboptimal (counts hops) | Better (prefers high-BW links) |
| Scalability | Limited to 15 hops | Unlimited |
| Overhead | Low (simple updates) | Higher (LSA flooding) |

---

## For Other Sub-Teams

### Part II (Transport Protocol Analysis)
- Use `[Config RIPng]` or `[Config OSPFv3]` as your base
- The bottleneck is already set up at R2–R5 (5 Mbps)
- TCP flows on port 1000, UDP on port 2000

### Part III (QoS)
- Add your DiffServ/IntServ configs as new `[Config]` sections in `omnetpp.ini`
- Do **not** modify `[General]` — extend it

### Part IV (Advanced — IPv6)
- IPv6 is already enabled (`**.hasIpv6 = true`)
- Extend `BasicNetwork.ned` with mobility modules if needed

### Part V (Data Analytics)
- All result files go to `results/` — load them in the IDE Analysis Tool
- Use `opp_scavetool` for batch extraction to CSV

---

## Dependencies

- OMNeT++ 6.x (tested on 6.0.3)
- INET Framework 4.4+ (for `Ipv6FlatNetworkConfigurator`, `TcpSessionApp`, `UdpBasicApp`)

---

## References

- RFC 2080 — RIPng for IPv6
- RFC 5340 — OSPFv3 for IPv6
- INET Docs: https://inet.omnetpp.org/docs/users-guide/ch-routing.html
- OMNeT++ Manual: https://doc.omnetpp.org
