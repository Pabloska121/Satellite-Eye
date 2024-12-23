import SwiftUI

struct SearchView: View {
    @ObservedObject var satelliteManager: SatelliteManager
    @State private var searchText: String = ""
    @State private var loadedSatellitesCount: Int = 0
    @State private var debouncedSearchText: String = ""
    @State private var selectedGroup: String = "all" // Nuevo estado para el filtro de tipo
    @FocusState private var isSearchFieldFocused: Bool  // Control del foco
    @Binding var selectedView: Int
    
    var filteredSatellites: [TLE] {
        let query = debouncedSearchText.lowercased()

        // Filtrar satélites por grupo
        let filteredByGroup = satelliteManager.allSatellites.filter { satellite in
            let matchesGroup: Bool
            if selectedGroup == "all" {
                matchesGroup = true
            } else {
                if let groupSatellites = satelliteManager.satellitesByGroup[selectedGroup] {
                    matchesGroup = groupSatellites.contains(where: { $0.OBJECT_NAME == satellite.OBJECT_NAME })
                } else {
                    matchesGroup = false
                }
            }
            return matchesGroup
        }

        // Si no hay texto de búsqueda, devolver todos los satélites del grupo seleccionado
        if query.isEmpty {
            return Array(filteredByGroup.prefix(loadedSatellitesCount)) // Convertimos a Array<TLE>
        }

        // Filtrar por texto de búsqueda y grupo seleccionado
        return Array(filteredByGroup.filter { satellite in
            let matchesSearchText = satellite.OBJECT_NAME.lowercased().contains(query) ||
                                    String(satellite.NORAD_CAT_ID).lowercased().contains(query)
            return matchesSearchText
        }.prefix(loadedSatellitesCount)) // Convertimos a Array<TLE>
    }

    var body: some View {
        NavigationView {
            VStack {
                // Picker para seleccionar el tipo de satélite
                Picker("Select Group", selection: $selectedGroup) {
                    Text("All").tag("all")
                    Text("Active").tag("active")
                    Text("Visual").tag("visual")
                    Text("Stations").tag("stations")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedGroup) {
                    print("Selected group changed to: \(selectedGroup)")

                    // Restablecer el contador de satélites cargados y el texto de búsqueda al cambiar el grupo
                    loadedSatellitesCount = 0
                    debouncedSearchText = ""  // Restablecer búsqueda
                    searchText = ""  // Limpiar texto de búsqueda
                    // Llamar para cargar los satélites del nuevo grupo
                    loadMoreSatellites()
                }

                List {
                    // Depurar el número de satélites a mostrar
                    ForEach(filteredSatellites, id: \.OBJECT_NAME) { satellite in
                        Button {
                            print("Selected Satellite: \(satellite.OBJECT_NAME)")
                            isSearchFieldFocused = false
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
                    
                    // Si estamos buscando pero no hemos cargado todos los satélites
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
                    print("Search text changed to: \(searchText)")
                    debounceSearch(query: searchText)
                }
            }
        }
    }

    private func loadMoreSatellites() {
        let filteredByGroup: [TLE]
        print(selectedGroup)
        // Si el grupo seleccionado es "all", filtrar solo por el grupo y cargarlos correctamente
        if selectedGroup == "all" {
            // Aquí estamos filtrando por todos los satélites, sin aplicar filtro de grupo
            filteredByGroup = satelliteManager.allSatellites
        } else {
            filteredByGroup = satelliteManager.allSatellites.filter { satellite in
                if let groupSatellites = satelliteManager.satellitesByGroup[selectedGroup] {
                    return groupSatellites.contains(where: { $0.OBJECT_NAME == satellite.OBJECT_NAME })
                }
                return false
            }
        }

        // Asegurarse de que no sobrepasemos el total de satélites disponibles
        let nextBatch = filteredByGroup.dropFirst(loadedSatellitesCount).prefix(100)
        loadedSatellitesCount += nextBatch.count
        print("Loaded more satellites, total: \(loadedSatellitesCount)")
    }

    private func debounceSearch(query: String) {
        print("Debouncing search with query: \(query)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if query == searchText {
                debouncedSearchText = query
                print("Debounced search text set to: \(debouncedSearchText)")  // Verifica que se actualice correctamente
            }
        }
    }
}
