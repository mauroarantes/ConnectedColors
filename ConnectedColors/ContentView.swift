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
        Text("Hello, world!")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
