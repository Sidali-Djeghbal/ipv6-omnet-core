package src;

import inet.networklayer.configurator.ipv6.Ipv6FlatNetworkConfigurator;
import inet.networklayer.configurator.ipv6.Ipv6NetworkConfigurator;
import inet.node.inet.StandardHost;
import inet.node.inet.Router;

network BasicNetwork
{
    parameters:
        @display("bgb=1000,650");

    types:
        channel AccessLink extends ned.DatarateChannel
        {
            delay = 2ms;
            datarate = 100Mbps;
        }
        channel CoreLink extends ned.DatarateChannel
        {
            delay = 10ms;
            datarate = 100Mbps;
        }
        channel BottleneckLink extends ned.DatarateChannel
        {
            delay = 20ms;
            datarate = 10Mbps;
        }

    submodules:
        // Routers
        r1: Router {
            @display("p=300,200;i=device/router");
        }
        r2: Router {
            @display("p=500,200;i=device/router");
        }
        r3: Router {
            @display("p=700,200;i=device/router");
        }
        r4: Router {
            @display("p=300,420;i=device/router");
        }
        r5: Router {
            @display("p=500,420;i=device/router");
        }
        r6: Router {
            @display("p=700,420;i=device/router");
        }

        // Clients
        client1: StandardHost {
            @display("p=100,200;i=device/laptop");
        }
        client2: StandardHost {
            @display("p=100,420;i=device/laptop");
        }

        // Servers
        server1: StandardHost {
            @display("p=880,200;i=device/server");
        }
        server2: StandardHost {
            @display("p=880,420;i=device/server");
        }

        Configurator: Ipv6FlatNetworkConfigurator {
            @display("p=85,48");
        }
    connections allowunconnected:
        // Access links (100 Mbps / 2 ms)
        client1.ethg++ <--> AccessLink <--> r1.ethg++;
        client2.ethg++ <--> AccessLink <--> r4.ethg++;
        server1.ethg++ <--> AccessLink <--> r3.ethg++;
        server2.ethg++ <--> AccessLink <--> r6.ethg++;

        // Upper core row (100 Mbps / 10 ms)
        r1.ethg++ <--> CoreLink <--> r2.ethg++;
        r2.ethg++ <--> CoreLink <--> r3.ethg++;

        // Lower core row (100 Mbps / 10 ms)
        r4.ethg++ <--> CoreLink <--> r5.ethg++;
        r5.ethg++ <--> CoreLink <--> r6.ethg++;

        // Vertical inter-row links (100 Mbps / 10 ms)
        r1.ethg++ <--> CoreLink <--> r4.ethg++;
        r3.ethg++ <--> CoreLink <--> r6.ethg++;

        // Bottleneck link r2 <-> r5 (10 Mbps / 20 ms)
        r2.ethg++ <--> BottleneckLink <--> r5.ethg++;
}
