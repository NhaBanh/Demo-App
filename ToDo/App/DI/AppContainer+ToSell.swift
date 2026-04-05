import Foundation

extension AppContainer {
    func makeToSellViewModel() -> ToSellViewModel {
        let dependencies = sellDependencies
        return ToSellViewModel(
            inventoryReader: dependencies.inventoryReader,
            inventoryWriter: dependencies.inventoryWriter,
            createItem: dependencies.createItem,
            updateItem: dependencies.updateItem,
            sellAmount: dependencies.sellAmount
        )
    }
}
