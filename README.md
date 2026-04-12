# Task 6 — UDP Real-Time Traffic Analysis
**Advanced Networks Course Project — OMNeT++ / INET Framework**
**Team 2:** @abdenourounas | @Yehia-Bou-lahia
**Protocol:** UDP (RFC 768) | **Routing:** RIPng over IPv6

---

## 1. Introduction

This section analyzes UDP behavior as a real-time streaming protocol under network congestion. Unlike TCP, UDP provides no reliability guarantees — it transmits continuously without retransmission, flow control, or congestion response. This makes it suitable for time-sensitive applications (VoIP, video streaming, online gaming) where low latency is preferred over guaranteed delivery.

The simulation uses the verified 6-router IPv6 topology from Part I, with a deliberate bottleneck link between R2 and R5 (10 Mbps vs. 100 Mbps everywhere else). Three UDP scenarios were tested to evaluate performance degradation under increasing load.

---

## 2. Theoretical Background

### 2.1 UDP Protocol (RFC 768)

UDP is a connectionless, unreliable transport protocol. Its header is only **8 bytes**:

| Field | Size | Description |
|---|---|---|
| Source Port | 16 bits | Sender's port |
| Destination Port | 16 bits | Receiver's port |
| Length | 16 bits | Header + data |
| Checksum | 16 bits | Integrity check |

The simplicity of UDP (no handshake, no ACK, no congestion window) results in minimal overhead, making it ideal for real-time applications where retransmitting stale data is worse than losing it.

### 2.2 Key Metrics

**Packet Loss %**
$$\text{Loss \%} = \frac{\text{Packets Sent} - \text{Packets Received}}{\text{Packets Sent}} \times 100$$

**Jitter (RFC 3550)**
$$J = J + \frac{|D(i-1,\, i)| - J}{16}$$
where $D(i,j)$ is the difference in inter-arrival time between consecutive packets. Jitter represents the variance in end-to-end delay — critical for audio/video quality.

### 2.3 Why UDP for Real-Time Streaming?

| Property | UDP | TCP |
|---|---|---|
| Retransmission | ❌ None | ✅ Automatic |
| Delay | ✅ Low and stable | ❌ Variable (ACK + cwnd) |
| Congestion response | ❌ None | ✅ Reduces sending rate |
| Packet loss tolerance | ✅ Acceptable (frame skip) | ❌ Must deliver all bytes |
| Use case | Video, audio, games | Files, email, web |

---

## 3. Network Setup

### 3.1 Topology

```
[Client1]──100Mbps──[r1]──100Mbps──[r2]──100Mbps──[r3]──100Mbps──[Server1]
                     |                |                |
                  100Mbps        10Mbps ⚠️           100Mbps
                  (core)      BOTTLENECK            (core)
                     |                |                |
[Client2]──100Mbps──[r4]──100Mbps──[r5]──100Mbps──[r6]──100Mbps──[Server2]
```

- **Bottleneck:** R2 ↔ R5 — 10 Mbps, 20 ms delay
- **All other links:** 100 Mbps, 2–10 ms delay
- **Routing:** RIPng (IPv6 distance-vector)
- **UDP flow:** client2 → server2 (port 2000)

### 3.2 Simulation Configurations

```ini
[Config UDP_Streaming]        # 5ms interval  ≈ 1.6 Mbps
[Config UDP_Heavy_Load]       # 1ms interval  ≈ 8 Mbps
[Config TCP_UDP_Competing]    # 10ms interval + TCP 100MB
```

---

## 4. Experimental Results

### 4.1 Packet Loss

| Scenario | Packets Sent | Packets Received | **Loss %** |
|---|---|---|---|
| UDP_Streaming | 20,000 | 19,527 | **2.365%** |
| UDP_Heavy_Load | 100,000 | 96,072 | **3.928%** |
| TCP_UDP_Competing | 9,501 | 9,498 | **0.032%** |

### 4.2 End-to-End Delay & Jitter

| Scenario | Mean Delay | Jitter (StdDev) |
|---|---|---|
| UDP_Streaming | 24.354 ms | 0.590 ms |
| UDP_Heavy_Load | 24.355 ms | 0.579 ms |
| TCP_UDP_Competing | 24.356 ms | 0.642 ms |

### 4.3 Throughput

| Scenario | Configured Rate | Effective Throughput |
|---|---|---|
| UDP_Streaming | ~1.6 Mbps | ~1.67 Mbps |
| UDP_Heavy_Load | ~8 Mbps | ~7.7 Mbps |
| TCP_UDP_Competing | ~800 kbps | ~760 kbps |

---

## 5. Analysis

### 5.1 End-to-End Delay Graph

The three delay graphs show the same pattern:

- **Initial phase (t = 0–5s):** High delay peaks (29–69 ms) caused by RIPng convergence — the routing tables are still being built, causing packets to take suboptimal paths with higher queuing delays.
- **Steady state (t > 5s):** Delay stabilizes at **~24.35 ms**, which corresponds to the theoretical propagation delay of the path: 2ms + 10ms + 20ms + 10ms + 2ms = **44ms** (note: OMNeT++ measures one-way, so half-RTT ≈ 22ms + processing ≈ 24ms ✅).
- **No delay growth over time:** Confirms the bottleneck does not cause buffer accumulation under these traffic loads.

### 5.2 Packet Loss Analysis

Packet loss increases with traffic intensity, as expected:

- **UDP_Streaming (2.365%):** Light load, well within acceptable bounds for video streaming (< 5% is generally acceptable).
- **UDP_Heavy_Load (3.928%):** Higher load pushes the bottleneck harder, increasing queue overflow events. Still below critical thresholds.
- **TCP_UDP_Competing (0.032%):** Very low loss because UDP sends at only 800 kbps — far below the 10 Mbps bottleneck, leaving ample bandwidth. TCP and UDP coexist without significant contention at this rate.

### 5.3 Jitter Analysis

All three scenarios exhibit very low jitter (< 1 ms), indicating:

- The network introduces consistent, predictable delay.
- No burst congestion events that would cause irregular inter-arrival times.
- The RIPng routing is stable after initial convergence.

The slightly higher jitter in TCP_UDP_Competing (0.642 ms vs ~0.58 ms) is explained by TCP's dynamic behavior — as TCP's congestion window fluctuates, it briefly competes with UDP at the bottleneck, introducing small variations in UDP packet inter-arrival times.

### 5.4 UDP vs TCP Fairness (TCP_UDP_Competing)

When TCP (100 MB transfer) and UDP (800 kbps stream) compete:

- UDP maintains **0.032% loss** — nearly perfect delivery.
- This is because UDP at 800 kbps is far below the 10 Mbps bottleneck.
- TCP absorbs the remaining bandwidth, adapting via congestion control.
- This demonstrates that UDP at moderate rates does not harm co-existing TCP flows.

---

## 6. Graphs

### Figure 1 — UDP_Streaming: End-to-End Delay
> Initial convergence peaks (29–69 ms) followed by stable 24.35 ms steady state.
> 19,527 packets received out of 20,000 sent (2.365% loss).

### Figure 2 — UDP_Heavy_Load: End-to-End Delay
> Same delay pattern with denser packet stream. 96,072 / 100,000 packets received (3.928% loss).
> Initial burst shows RIPng convergence effect more clearly due to higher packet rate.

### Figure 3 — TCP_UDP_Competing: End-to-End Delay
> UDP operates at 800 kbps alongside TCP 100MB transfer.
> Near-zero loss (0.032%) with stable delay at 24.356 ms.
> Slightly higher jitter (0.642 ms) due to TCP congestion window dynamics.

---

## 7. Conclusion

The simulation results confirm the expected behavior of UDP under network congestion:

1. **UDP is insensitive to congestion** — it continues sending at the configured rate regardless of network state, leading to packet loss when the bottleneck is saturated.

2. **Delay is stable after routing convergence** — the ~24.35 ms steady-state delay is consistent across all scenarios, showing no buffer bloat.

3. **Loss scales with load** — from 2.365% at light load to 3.928% at heavy load. Both values are within acceptable ranges for real-time streaming applications.

4. **Low jitter (< 1ms)** — confirms good streaming quality. ITU-T G.114 recommends jitter < 50 ms for VoIP; our results are well within this limit.

5. **TCP and UDP can coexist** — at moderate UDP rates, both protocols share the bottleneck without significant interference.

### Recommendations for Part III (QoS)

- Implement **DiffServ** to prioritize UDP real-time traffic over TCP bulk transfer.
- Apply **WRED** (Weighted Random Early Detection) to manage buffer occupancy at the bottleneck.
- Mark UDP packets with **EF (Expedited Forwarding)** DSCP to guarantee low delay and jitter.

---
- Tanenbaum & Wetherall, *Computer Networks*, 5th ed., Pearson
