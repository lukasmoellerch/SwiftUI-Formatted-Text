//
//  ContentView.swift
//  SwiftUIRenderer
//
//  Created by Lukas Möller on 19.06.19.
//  Copyright © 2019 Lukas Möller. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    @State var string: String = "Type some text here..."
    var body: some View {
        HStack {
            TextField($string)
                .lineLimit(nil)
            AttributedText(formatted: $string)
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
