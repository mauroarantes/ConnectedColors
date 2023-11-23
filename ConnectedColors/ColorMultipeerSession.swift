//
//  ColorMultipeerSession.swift
//  ConnectedColors
//
//  Created by Mauro Arantes on 05/10/2023.
//

import MultipeerConnectivity
import os

enum NamedColor: String, CaseIterable {
    case red, green, yellow
}

class ColorMultipeerSession: NSObject, ObservableObject {
    private let serviceType = "example-color"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let session: MCSession
    private let log = Logger()
    @Published var availablePeers: [MCPeerID] = []
    @Published var connectedPeer: MCPeerID?
    @Published var currentColor: NamedColor?

    override init() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

        super.init()

        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self

        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }

    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        session.disconnect()
    }
    
    func send(color: NamedColor) {
        log.info("sendColor: \(String(describing: color)) to \(self.session.connectedPeers.count) peers")
        self.currentColor = color
        
        if !session.connectedPeers.isEmpty {
            do {
                try session.send(color.rawValue.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            } catch {
                log.error("Error for sending: \(String(describing: error))")
            }
        }
    }
    
    func connect(peer: MCPeerID) {
        self.connectedPeer = peer
        serviceBrowser.invitePeer(peer, to: session, withContext: nil, timeout: 10)
        serviceBrowser.stopBrowsingForPeers()
        serviceAdvertiser.stopAdvertisingPeer()
    }
}

extension ColorMultipeerSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        log.error("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        log.info("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, session)
        connectedPeer = peerID
        serviceBrowser.stopBrowsingForPeers()
        serviceAdvertiser.stopAdvertisingPeer()
    }
}

extension ColorMultipeerSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        log.error("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        log.info("ServiceBrowser found peer: \(peerID)")
        availablePeers.append(peerID)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        log.info("ServiceBrowser lost peer: \(peerID)")
        availablePeers.removeAll { peer in
            peer == peerID
        }
        connectedPeer = nil
    }
}

extension ColorMultipeerSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        log.info("peer \(peerID) didChangeState: \(state.rawValue)")
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let string = String(data: data, encoding: .utf8), let color = NamedColor(rawValue: string) {
            log.info("didReceive color \(string)")
            DispatchQueue.main.async {
                self.currentColor = color
            }
        } else {
            log.info("didReceive invalid value \(data.count) bytes")
        }
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        log.error("Receiving streams is not supported")
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        log.error("Receiving resources is not supported")
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        log.error("Receiving resources is not supported")
    }
}
