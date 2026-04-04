import Foundation

extension AppContainer {
    func makeToSellViewModel() -> ToSellViewModel {
        let repository = makeSellRepository()
        return ToSellViewModel(
            loadItems: LoadSellItemsUseCase(repository: repository),
            createItem: CreateSellItemUseCase(mutationService: sellMutationService),
            updateItem: UpdateSellItemUseCase(repository: repository, mutationService: sellMutationService),
            deleteItems: DeleteSellItemsUseCase(mutationService: sellMutationService),
            restoreItems: RestoreSellItemsUseCase(repository: repository)
        )
    }
}
