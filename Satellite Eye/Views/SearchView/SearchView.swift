import SwiftUI

struct SearchView: View {
    @ObservedObject var satelliteManager: SatelliteManager
    @State private var searchText: String = ""
    @State private var loadedSatellitesCount: Int = 0
    @State private var debouncedSearchText: String = ""
    @FocusState private var isSearchFieldFocused: Bool  // Control del foco
    @Binding var selectedView: Int
    
    var filteredSatellites: [TLE] {
        if debouncedSearchText.isEmpty {
            return satelliteManager.allSatellites.prefix(loadedSatellitesCount).map { $0 }
        } else {
            let query = debouncedSearchText.lowercased()
            return satelliteManager.allSatellites.filter { satellite in
                satellite.OBJECT_NAME.lowercased().contains(query) ||
                String(satellite.NORAD_CAT_ID).lowercased().contains(query)
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredSatellites, id: \.OBJECT_NAME) { satellite in
                    Button {
                        isSearchFieldFocused = false  // Cierra el teclado
                        satelliteManager.fetchSatelliteData(satelliteName: satellite.OBJECT_NAME)
                        selectedView = 1
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .foregroundColor(Color.gray.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "paperplane.fill")
                            }
                            Text(satellite.OBJECT_NAME)
                                .padding(.leading, 10)
                        }
                    }
                }
                if searchText.isEmpty && loadedSatellitesCount < satelliteManager.allSatellites.count {
                    ProgressView()
                        .onAppear {
                            loadMoreSatellites()
                        }
                }
            }
            .navigationTitle("Select Satellite")
            .searchable(text: $searchText, prompt: "Search Satellites")
            .focused($isSearchFieldFocused)  // Asociar el foco
            .onChange(of: searchText) {
                debounceSearch(query: searchText)
            }
        }
    }

    private func loadMoreSatellites() {
        let nextBatch = satelliteManager.allSatellites.dropFirst(loadedSatellitesCount).prefix(100)
        loadedSatellitesCount += nextBatch.count
    }
    
    private func debounceSearch(query: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if query == searchText {
                debouncedSearchText = query
            }
        }
    }
}
