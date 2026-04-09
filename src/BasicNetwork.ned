package src;

import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.StandardHost;
import inet.node.inet.Router;
import inet.node.ethernet.EthernetLink;

network BasicNetwork
{
    parameters:
        @display("bgb=900,600");
    submodules:
        configurator: Ipv4NetworkConfigurator {
            parameters:
                @display("p=100,50");
        }
        // Routers
        r1: Router { @display("p=300,200"); }
        r2: Router { @display("p=500,200"); }
        r3: Router { @display("p=700,200"); }
        r4: Router { @display("p=300,400"); }
        r5: Router { @display("p=500,400"); }
        r6: Router { @display("p=700,400"); }

        // Clients
        client1: StandardHost { @display("p=100,200"); }
        client2: StandardHost { @display("p=100,400"); }

        // Servers
        server1: StandardHost { @display("p=850,200"); }
        server2: StandardHost { @display("p=850,400"); }

    connections allowunconnected:
        // Left LAN
        client1.ethg++ <--> EthernetLink { delay = 2ms; datarate = 100Mbps; } <--> r1.ethg++;
        client2.ethg++ <--> EthernetLink { delay = 2ms; datarate = 100Mbps; } <--> r4.ethg++;

        // Core topology
        r1.ethg++ <--> EthernetLink { delay = 10ms; datarate = 10Mbps; } <--> r2.ethg++;
        r2.ethg++ <--> EthernetLink { delay = 10ms; datarate = 10Mbps; } <--> r3.ethg++;
        r4.ethg++ <--> EthernetLink { delay = 10ms; datarate = 10Mbps; } <--> r5.ethg++;
        r5.ethg++ <--> EthernetLink { delay = 10ms; datarate = 10Mbps; } <--> r6.ethg++;

        // Bottleneck link (for congestion experiments) - Fixed to 10Mbps
        r2.ethg++ <--> EthernetLink { delay = 20ms; datarate = 10Mbps; } <--> r5.ethg++;

        // Right LAN
        r3.ethg++ <--> EthernetLink { delay = 2ms; datarate = 100Mbps; } <--> server1.ethg++;
        r6.ethg++ <--> EthernetLink { delay = 2ms; datarate = 100Mbps; } <--> server2.ethg++;
}