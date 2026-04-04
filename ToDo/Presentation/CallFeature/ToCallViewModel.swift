import Combine
import Foundation

@MainActor
final class ToCallViewModel: ObservableObject {
    private enum LoadTrigger {
        case userInitiated
        case automaticRetry
    }

    @Published private(set) var people: [PersonToCall] = []
    @Published var filter = ""
    @Published private(set) var page = 1
    @Published private(set) var totalPages = 1
    @Published private(set) var lastSyncedAt: Date?
    @Published private(set) var isLoading = false
    @Published private(set) var retryStatusMessage: String?
    @Published var errorMessage: String?

    private let loadPage: LoadToCallPageUseCase
    private let connectivityMonitor: ConnectivityMonitoring
    private let pageSize = 3
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?
    private var requestGeneration = 0
    private var lastRequestedPage = 1
    private lazy var retryCoordinator = AutoRetryCoordinator(
        connectivityMonitor: connectivityMonitor,
        isRetryableError: { error in
            if let appError = error as? AppError {
                return appError.isTransientNetworkFailure
            }
            return false
        },
        statusHandler: { [weak self] message in
            self?.retryStatusMessage = message
        }
    )

    init(loadPage: LoadToCallPageUseCase, connectivityMonitor: ConnectivityMonitoring) {
        self.loadPage = loadPage
        self.connectivityMonitor = connectivityMonitor
        bindFilter()
    }

    func refresh() async {
        startLoad(page: page, trigger: .userInitiated)
    }

    func retry() async {
        startLoad(page: page, trigger: .userInitiated)
    }

    func nextPage() async {
        guard page < totalPages else { return }
        startLoad(page: page + 1, trigger: .userInitiated)
    }

    func previousPage() async {
        guard page > 1 else { return }
        startLoad(page: page - 1, trigger: .userInitiated)
    }

    private func startLoad(page: Int, trigger: LoadTrigger) {
        loadTask?.cancel()
        requestGeneration += 1
        let generation = requestGeneration
        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.load(page: page, trigger: trigger, generation: generation)
        }
    }

    private func load(page: Int, trigger: LoadTrigger, generation: Int) async {
        lastRequestedPage = page
        if trigger == .userInitiated {
            retryCoordinator.reset()
        }
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await loadPage.execute(page: page, pageSize: pageSize, filter: filter)
            guard !Task.isCancelled, generation == requestGeneration else { return }
            self.page = response.page
            totalPages = response.totalPages
            people = response.items
            lastSyncedAt = response.lastSyncedAt
            errorMessage = nil
            retryCoordinator.reset()
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, generation == requestGeneration else { return }
            errorMessage = error.localizedDescription
            _ = retryCoordinator.handleFailure(error) { [weak self] in
                guard let self else { return }
                await self.startLoad(page: self.lastRequestedPage, trigger: .automaticRetry)
            }
        }
    }

    private func bindFilter() {
        $filter
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                self.startLoad(page: 1, trigger: .userInitiated)
            }
            .store(in: &cancellables)
    }
}
