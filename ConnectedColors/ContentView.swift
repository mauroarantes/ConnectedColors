//
//  ContentView.swift
//  ConnectedColors
//
//  Created by Mauro Arantes on 05/10/2023.
//

import SwiftUI

struct ContentView: View {
    @StateObject var colorSession = ColorMultipeerSession()

    var body: some View {
        VStack(alignment: .leading) {
            Text("Connected Devices:")
            Text(String(describing: colorSession.connectedPeers.map(\.displayName)))

            Divider()

            HStack {
                ForEach(NamedColor.allCases, id: \.self) { color in
                    Button(color.rawValue) {
                        colorSession.send(color: color)
                    }
                    .padding()
                }
            }
            Spacer()
        }
        .padding()
        .background((colorSession.currentColor.map(\.color) ?? .clear).ignoresSafeArea())
    }
}

extension NamedColor {
    var color: Color {
        switch self {
        case .red:
            return .red
        case .green:
            return .green
        case .yellow:
            return .yellow
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
