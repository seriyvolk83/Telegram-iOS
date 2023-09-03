//
//  ContentView.swift
//  SampleApp
//
//  Created by Volkov Alexander on 27.08.2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            CustomTable()
            Text("table")
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
