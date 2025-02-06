
import Foundation
import Combine
import CoreData

@Observable final class SampleViewModel {
    
    let container: NSPersistentContainer
    var savedEntities: [Birds] = []
    
    var response: [Birds]?
    var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager()
    
    init() {
        container = NSPersistentContainer(name: "ArchitectureTestProject")
        container.loadPersistentStores { [weak self] description, error in
            if error == nil {
                self?.loadData()
            }
        }
    }
    
    func loadData() {
//        let fetchRequest = NSFetchRequest<Birds>(entityName: "Birds")
//        do {
//            savedEntities = try container.viewContext.fetch(fetchRequest)
//        } catch {
//            print(error.localizedDescription)
//        }
    }
    
    func saveData() {
//        let fruitEntity = Birds(context: container.viewContext)
//        fruitEntity.name = "Test"
//        do {
//            try container.viewContext.save()
//            loadData()
//        } catch {
//            print(error.localizedDescription)
//        }
    }
    
    func fetchExampleData() {
        networkManager.combineRequest(pathUrl: .birds, httpMethod: .GET, resultType: [Birds].self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.response = response
            }
            .store(in: &cancellables)
    }
}
