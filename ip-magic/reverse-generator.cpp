#include <assert.h>
#include <iostream>
#include <json/json.h>
#include <arpa/inet.h>
#include <stdio.h>

using namespace std;

int main(int argc, char **argv) {
    assert(argc == 3);
    Json::Reader reader;
    Json::Value root;
    string domain = argv[2];
    if (!reader.parse(argv[1], root)) {
        cerr << "unable to parse json\n";
        return 1;
    }
    assert(root.isArray());
    for (unsigned int i=0; i<root.size(); i++) {
        Json::Value host = root[i];
        assert(host.isObject());
        if (host.isMember("v6")) {
            struct in6_addr result;
            if (inet_pton(AF_INET6, host["v6"].asCString(), &result) == 1) {
                for (int x = 15; x >= 0; x--) {
                    printf("%x.%x.", result.s6_addr[x] & 0xf, result.s6_addr[x] >> 4);
                }
                cout << "ip6.arpa. IN PTR " << host["name"].asString() << "." << domain << "\n";
            } else {
                cerr << "unable to parse '" << host["v6"].asString() << "' as a valid IPv6 addr\n";
                return 2;
            }
        }
        if (host.isMember("v4")) {
            unsigned char buf[4];
            if (inet_pton(AF_INET, host["v4"].asCString(), &buf) == 1) {
                for (int x = 3; x >= 0; x--) {
                    printf("%d.", buf[x]);
                }
                cout << "in-addr.arpa. IN PTR " << host["name"].asString() << "." << domain << "\n";
            } else {
                cerr << "unable to parse '" << host["v4"].asString() << "' as a valid IPv4 addr\n";
                return 3;
            }
        }
    }
    return 0;
}