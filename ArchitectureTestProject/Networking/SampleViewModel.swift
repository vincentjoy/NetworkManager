
import Foundation
import Combine

@Observable final class SampleViewModel {
    var response: [Birds]?
    var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager()
    
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
