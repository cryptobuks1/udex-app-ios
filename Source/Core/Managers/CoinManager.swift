import Foundation
import RxSwift

class CoinManager {
  private let disposeBag = DisposeBag()
  private let subject = PublishSubject<Void>()
  private var _coins: [Coin] {
    didSet {
      subject.onNext(())
    }
  }
  private let baseCoins = ["BTC", "ETH"]
  private let appConfigProvider: IAppConfigProvider
  private let enabledCoinsStorage: IEnabledCoinsStorage
  
  var allCoins: [Coin] {
    appConfigProvider.coins
  }
  
  init(appConfigProvider: IAppConfigProvider, enabledCoinsStorage: IEnabledCoinsStorage) {
    self.appConfigProvider = appConfigProvider
    self.enabledCoinsStorage = enabledCoinsStorage
    _coins = []
    
    enabledCoinsStorage.enabledCoinsObservable.subscribe(onNext: { (enabledCoins) in
      self.setup(enabledCoins)
    }).disposed(by: disposeBag)
    setup(try! enabledCoinsStorage.getEnabledCoins())
  }
  
  private func setup(_ enabledCoins: [EnabledCoin]) {
    if enabledCoins.isEmpty {
      self.enableDefaultCoins()
      return
    }
    
    var enabled = [Coin]()
    enabledCoins.forEach { (enabledCoin) in
      if let addingCoin = self.allCoins.first(where: { (coin) -> Bool in
        coin.code == enabledCoin.coinCode
      }) {
        enabled.append(addingCoin)
      }
    }
    self._coins = enabled
  }
}

extension CoinManager: ICoinManager {
  var coins: [Coin] {
    return _coins
  }
  
  var coinsUpdateSubject: Observable<Void> {
    return subject.asObserver()
  }
  
  func enableDefaultCoins() {
    var enabledCoins = [EnabledCoin]()
    appConfigProvider.featuredCoins.enumerated().forEach { (order, coin) in
      enabledCoins.append(EnabledCoin(coinCode: coin.code, order: order))
    }
    try! enabledCoinsStorage.insertCoins(enabledCoins)
    
  }
  
  func getErcCoinForAddress(address: String) -> Coin? {
    _coins.filter { coin -> Bool in
      switch coin.type {
      case .erc20(let filterAddress, _, _, _, _):
        return filterAddress.lowercased() == address.lowercased()
      case .ethereum:
        return false
      }
    }
    .first
  }
  
  func getCoin(code: String) -> Coin {
    let coinOrNull = allCoins.first { (coin) -> Bool in
      coin.code == code
    }
    
    if coinOrNull != nil {
      return coinOrNull!
    } else {
      fatalError() // Throw exception
    }
  }
  
  func cleanCoinCode(coinCode: String) -> String {    
    let baseIndex = baseCoins.firstIndex { (baseCoin) -> Bool in
      coinCode.starts(with: "W") && coinCode.substr(1, coinCode.count - 1) == baseCoin
    }
    
    if baseIndex != nil {
      return baseCoins[baseIndex!]
    } else if coinCode == "SAI" {
      return "DAI"
    } else {
      return coinCode
    }
  }
  
  func clear() {
    _coins = []
  }
}
