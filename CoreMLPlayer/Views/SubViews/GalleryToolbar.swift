//
//  GalleryToolbar.swift
//  CoreML Player
//
//  Created by NA on 1/28/23.
//

import SwiftUI

struct GalleryToolbar<T: Gallery>: ToolbarContent {
    @StateObject var gallery: T
    @State private var isPresentingRemoveConfirm: Bool = false

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(role: .destructive) {
                isPresentingRemoveConfirm = true
            } label: {
                Image(systemName: "trash.square").styledToolbarIcon()
            }
            .confirmationDialog("Are you sure?", isPresented: $isPresentingRemoveConfirm) {
                Button("Remove all items", role: .destructive) {
                    gallery.files.removeAll()
                }
            }
            
            Button(action: gallery.selectFiles) {
                Image(systemName: "plus.square").styledToolbarIcon()
            }
        }
    }
}
