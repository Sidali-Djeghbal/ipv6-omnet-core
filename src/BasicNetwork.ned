// ============================================================
// BasicNetwork.ned — Part I: Network Architecture Design
// Advanced Networks Course Project — OMNeT++ / INET Framework
// Team: @3boudi, @mamouneabdelli, @midouuk
//
// Topology:
//   6 core routers (R1–R6) forming a mesh with a deliberate
//   bottleneck link between R2 and R5.
//   2 client hosts + 2 server hosts in stub LANs.
//   IPv6 addressing via Ipv6NetworkConfigurator.
//   Supports RIPng and OSPFv3 via omnetpp.ini [Config] sections.
// ============================================================

package src;

import inet.networklayer.configurator.ipv6.Ipv6FlatNetworkConfigurator;
import inet.node.inet.StandardHost;
import inet.node.inet.Router;
import inet.common.misc.ThruputMeteringChannel;

// ----------------------------------------------------------
// Define named channel types to avoid repeating parameters
// ----------------------------------------------------------

channel LanLink extends ned.DatarateChannel
{
    delay    = 2ms;
    datarate = 100Mbps;
    @display("ls=#00aa00,3");   // Green, thickness 3
}

channel CoreLink extends ned.DatarateChannel
{
    delay    = 10ms;
    datarate = 100Mbps;
    @display("ls=#2255cc,2");   // Blue, thickness 2
}

channel BottleneckLink extends ned.DatarateChannel
{
    delay    = 20ms;
    datarate = 10Mbps;
    @display("ls=#cc0000,4,da"); // Red, thickness 4, dashed
}

// ----------------------------------------------------------
// Network Definition
// ----------------------------------------------------------

network BasicNetwork
{
    parameters:
        @display("bgb=1100,700;bgi=background/terrain");

    submodules:

        // ── IPv6 Auto-Configurator ──────────────────────────
        // Assigns global unicast addresses (2001:db8::/32 range)
        // and installs static routes on all nodes automatically.
        configurator: Ipv6FlatNetworkConfigurator {
            parameters:
                @display("p=80,60;is=s");
        }

        // ── Core Routers ────────────────────────────────────
        // All routers run a routing daemon selected in omnetpp.ini
        // via the **.routingProtocol parameter.

        r1: Router {
            parameters:
                @display("p=300,220;i=abstract/router");
        }
        r2: Router {
            parameters:
                @display("p=520,220;i=abstract/router");
        }
        r3: Router {
            parameters:
                @display("p=740,220;i=abstract/router");
        }
        r4: Router {
            parameters:
                @display("p=300,460;i=abstract/router");
        }
        r5: Router {
            parameters:
                @display("p=520,460;i=abstract/router");
        }
        r6: Router {
            parameters:
                @display("p=740,460;i=abstract/router");
        }

        // ── Client Hosts ─────────────────────────────────────
        client1: StandardHost {
            parameters:
                @display("p=100,220;i=device/pc");
        }
        client2: StandardHost {
            parameters:
                @display("p=100,460;i=device/pc");
        }

        // ── Server Hosts ─────────────────────────────────────
        server1: StandardHost {
            parameters:
                @display("p=960,220;i=device/server");
        }
        server2: StandardHost {
            parameters:
                @display("p=960,460;i=device/server");
        }

    connections allowunconnected:

        // ── Left LAN Segments ────────────────────────────────
        client1.ethg++ <--> LanLink <--> r1.ethg++;
        client2.ethg++ <--> LanLink <--> r4.ethg++;

        // ── Core Mesh Connections ────────────────────────────
        // Top row
        r1.ethg++ <--> CoreLink <--> r2.ethg++;
        r2.ethg++ <--> CoreLink <--> r3.ethg++;

        // Bottom row
        r4.ethg++ <--> CoreLink <--> r5.ethg++;
        r5.ethg++ <--> CoreLink <--> r6.ethg++;

        // Vertical cross-links (provides redundancy and alternate paths)
        r1.ethg++ <--> CoreLink <--> r4.ethg++;
        r3.ethg++ <--> CoreLink <--> r6.ethg++;

        // ── Bottleneck Link (KEY for congestion experiments) ──
        // R2 <-> R5 is deliberately constrained: 5 Mbps, 20 ms RTT.
        // Both TCP and UDP traffic must cross this link, creating
        // the congestion scenario required in Part II.
        r2.ethg++ <--> BottleneckLink <--> r5.ethg++;

        // ── Right LAN Segments ───────────────────────────────
        r3.ethg++ <--> LanLink <--> server1.ethg++;
        r6.ethg++ <--> LanLink <--> server2.ethg++;
}
