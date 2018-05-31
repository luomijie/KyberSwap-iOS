// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore

protocol KNExchangeTokenCoordinatorDelegate: class {
  func exchangeTokenCoordinatorDidSelectWallet(_ wallet: KNWalletObject)
}

class KNExchangeTokenCoordinator: Coordinator {

  let navigationController: UINavigationController
  fileprivate(set) var session: KNSession
  let tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens
  var isSelectingSourceToken: Bool = true

  var coordinators: [Coordinator] = []

  weak var delegate: KNExchangeTokenCoordinatorDelegate?

  lazy var rootViewController: KNExchangeTabViewController = {
    let viewModel = KNExchangeTabViewModel(
      wallet: self.session.wallet,
      from: tokens.first(where: { $0.isETH })!,
      to: tokens.first(where: { $0.isKNC })!,
      supportedTokens: tokens
    )
    let controller = KNExchangeTabViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  fileprivate var qrcodeCoordinator: KNWalletQRCodeCoordinator? {
    guard let walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.session.wallet.address.description) else { return nil }
    let qrcodeCoordinator = KNWalletQRCodeCoordinator(
      navigationController: self.navigationController,
      walletObject: walletObject
    )
    return qrcodeCoordinator
  }

  lazy var searchTokensViewController: KNSearchTokenViewController = {
    let viewModel = KNSearchTokenViewModel(supportedTokens: self.tokens)
    let controller = KNSearchTokenViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var pendingTransactionListCoordinator: KNPendingTransactionListCoordinator = {
    let coordinator = KNPendingTransactionListCoordinator(
      navigationController: self.navigationController,
      storage: self.session.transactionStorage
    )
    coordinator.delegate = self
    return coordinator
  }()

  fileprivate var confirmTransactionViewController: KNConfirmTransactionViewController!

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.session = session
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() {
  }
}

// MARK: Update from app coordinator
extension KNExchangeTokenCoordinator {
  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
    self.rootViewController.coordinatorUpdateNewSession(wallet: session.wallet)
    self.navigationController.popToRootViewController(animated: false)
  }

  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    self.rootViewController.coordinatorUpdateTokenBalance(otherTokensBalance)
  }

  func appCoordinatorETHBalanceDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, ethBalance: Balance) {
    if let eth = self.tokens.first(where: { $0.isETH }) {
      self.rootViewController.coordinatorUpdateTokenBalance([eth.contract: ethBalance])
    }
  }

  func appCoordinatorUSDRateDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt) {
    // No need
  }

  func appCoordinatorShouldOpenExchangeForToken(_ token: TokenObject, isReceived: Bool = false) {
    self.rootViewController.coordinatorUpdateSelectedToken(token, isSource: !isReceived)
    self.rootViewController.tabBarController?.selectedIndex = 0
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.searchTokensViewController.updateListSupportedTokens(tokenObjects)
  }
}

// MARK: Network requests
extension KNExchangeTokenCoordinator {
  fileprivate func didConfirmSendExchangeTransaction(_ exchangeTransaction: KNDraftExchangeTransaction) {
    self.navigationController.topViewController?.displayLoading()
    self.session.externalProvider.getAllowance(token: exchangeTransaction.from) { [weak self] getAllowanceResult in
      guard let `self` = self else { return }
      switch getAllowanceResult {
      case .success(let res):
        if res {
          self.sendExchangeTransaction(exchangeTransaction)
        } else {
          self.navigationController.topViewController?.hideLoading()
          self.showAlertRequestApprovalForExchange(exchangeTransaction)
        }
      case .failure(let error):
        self.navigationController.topViewController?.hideLoading()
        self.rootViewController.displayError(error: error)
      }
    }
  }

  fileprivate func sendExchangeTransaction(_ exchangeTransaction: KNDraftExchangeTransaction) {
    // Lock all data for exchange transaction first
    KNTransactionCoordinator.requestDataPrepareForExchangeTransaction(
      exchangeTransaction,
      provider: self.session.externalProvider) { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let tx):
        guard let exchange = tx else {
          // Return nil when balance is too low compared to the amoun
          // Show error balance insufficient
          self.navigationController.topViewController?.hideLoading()
          self.navigationController.topViewController?.showInsufficientBalanceAlert()
          return
        }
        self.session.externalProvider.exchange(exchange: exchange) { [weak self] result in
          guard let `self` = self else { return }
          self.navigationController.topViewController?.hideLoading()
          self.rootViewController.coordinatorExchangeTokenDidReturn(result: result)
          if case .success(let txHash) = result {
            let transaction = exchange.toTransaction(
              hash: txHash,
              fromAddr: self.session.wallet.address,
              toAddr: self.session.externalProvider.networkAddress,
              nounce: self.session.externalProvider.minTxCount
            )
            self.session.addNewPendingTransaction(transaction)
          }
        }
      case .failure(let error):
        self.navigationController.topViewController?.hideLoading()
        self.navigationController.topViewController?.displayError(error: error)
      }
    }
  }

  fileprivate func sendApproveForExchangeTransaction(_ exchangeTransaction: KNDraftExchangeTransaction) {
    self.navigationController.topViewController?.displayLoading()
    self.session.externalProvider.sendApproveERC20Token(exchangeTransaction: exchangeTransaction) { [weak self] result in
      switch result {
      case .success:
        self?.sendExchangeTransaction(exchangeTransaction)
      case .failure(let error):
        self?.navigationController.topViewController?.hideLoading()
        self?.navigationController.topViewController?.displayError(error: error)
      }
    }
  }

  fileprivate func showAlertRequestApprovalForExchange(_ exchangeTransaction: KNDraftExchangeTransaction) {
    let alertController = UIAlertController(title: "", message: "We need your approval to exchange \(exchangeTransaction.from.symbol)", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Approve", style: .default, handler: { [weak self] _ in
      self?.sendApproveForExchangeTransaction(exchangeTransaction)
    }))
    self.navigationController.topViewController?.present(alertController, animated: true, completion: nil)
  }
}

// MARK: Confirm transaction
extension KNExchangeTokenCoordinator: KNConfirmTransactionViewControllerDelegate {
  func confirmTransactionDidCancel() {
    self.navigationController.topViewController?.dismiss(animated: false, completion: {
      self.confirmTransactionViewController = nil
    })
  }

  func confirmTransactionDidConfirm(type: KNTransactionType) {
    self.navigationController.topViewController?.dismiss(animated: false, completion: {
      self.confirmTransactionViewController = nil
      if case .exchange(let exchangeTransaction) = type {
        self.didConfirmSendExchangeTransaction(exchangeTransaction)
      }
    })
  }
}

// MARK: Pending transaction list
extension KNExchangeTokenCoordinator: KNPendingTransactionListCoordinatorDelegate {
  func pendingTransactionListDidSelectTransferNow() {
    self.rootViewController.tabBarController?.selectedIndex = 1
  }

  func pendingTransactionListDidSelectExchangeNow() {
    self.rootViewController.tabBarController?.selectedIndex = 0
  }

  func pendingTransactionListDidSelectTransaction(_ transaction: Transaction) {
    KNNotificationUtil.postNotification(
      for: kTransactionDidUpdateNotificationKey,
      object: transaction.id,
      userInfo: nil
    )
  }
}

// MARK: Exchange tab (root view controller)
extension KNExchangeTokenCoordinator: KNExchangeTabViewControllerDelegate {
  func exchangeTabViewControllerFromTokenPressed(sender: KNExchangeTabViewController, from: TokenObject, to: TokenObject) {
    self.isSelectingSourceToken = true
    self.navigationController.pushViewController(
      self.searchTokensViewController,
      animated: true
    )
  }

  func exchangeTabViewControllerToTokenPressed(sender: KNExchangeTabViewController, from: TokenObject, to: TokenObject) {
    self.isSelectingSourceToken = false
    self.navigationController.pushViewController(
      self.searchTokensViewController,
      animated: true
    )
  }

  func exchangeTabViewControllerExchangeButtonPressed(sender: KNExchangeTabViewController, data: KNDraftExchangeTransaction) {
    let transactionType = KNTransactionType.exchange(data)
    self.confirmTransactionViewController = KNConfirmTransactionViewController(
      delegate: self,
      type: transactionType
    )
    self.confirmTransactionViewController.modalPresentationStyle = .overCurrentContext
    self.confirmTransactionViewController.modalTransitionStyle = .crossDissolve
    self.navigationController.topViewController?.present(
      self.confirmTransactionViewController,
      animated: true,
      completion: nil
    )
  }

  func exchangeTabViewControllerShouldUpdateEstimatedRate(from: TokenObject, to: TokenObject, amount: BigInt) {
    self.session.externalProvider.getExpectedRate(
      from: from,
      to: to,
      amount: amount) { [weak self] (result) in
        var estRate: BigInt = BigInt(0)
        var slippageRate: BigInt = BigInt(0)
        if case .success(let data) = result {
          estRate = data.0
          slippageRate = data.1
        }
        // fallback to rate from CMC
        if estRate.isZero, let cmcRate = KNRateCoordinator.shared.getRate(from: from, to: to) {
          estRate = cmcRate.rate
          slippageRate = cmcRate.minRate
        }
        self?.rootViewController.coordinatorDidUpdateEstimateRate(
          from: from,
          to: to,
          amount: amount,
          rate: estRate,
          slippageRate: slippageRate
        )
        if self?.confirmTransactionViewController != nil {
          self?.confirmTransactionViewController.updateExpectedRateData(
            source: from,
            dest: to,
            amount: amount,
            expectedRate: estRate
          )
        }
    }
  }

  func exchangeTabViewControllerShouldUpdateEstimatedGasLimit(from: TokenObject, to: TokenObject, amount: BigInt, gasPrice: BigInt) {
    let exchangeTx = KNDraftExchangeTransaction(
      from: from,
      to: to,
      amount: amount,
      maxDestAmount: BigInt(2).power(255),
      expectedRate: BigInt(0),
      minRate: .none,
      gasPrice: gasPrice,
      gasLimit: .none
    )
    self.session.externalProvider.getEstimateGasLimit(for: exchangeTx) { [weak self] result in
      if case .success(let estimate) = result {
        self?.rootViewController.coordinatorDidUpdateEstimateGasUsed(
          from: from,
          to: to,
          amount: amount,
          gasLimit: estimate
        )
      }
    }
  }

  func exchangeTabViewControllerDidPressedQRcode(sender: KNExchangeTabViewController) {
    self.qrcodeCoordinator?.start()
  }

  func exchangeTabViewControllerDidPressedSlippageRate(slippageRate: Double) {
    let slippageRateVC: KNSetSlippageRateViewController = {
      let viewModel = KNSetSlippageRateViewModel(slippageRate: slippageRate)
      let controller = KNSetSlippageRateViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.pushViewController(slippageRateVC, animated: true)
  }

  func exchangeTabViewControllerDidPressedGasPrice(gasPrice: BigInt, estGasLimit: BigInt) {
    let setGasPriceVC: KNSetGasPriceViewController = {
      let viewModel = KNSetGasPriceViewModel(gasPrice: gasPrice, estGasLimit: estGasLimit)
      let controller = KNSetGasPriceViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.pushViewController(setGasPriceVC, animated: true)
  }

  func exchangeTabViewControllerDidPressedSettings(sender: KNExchangeTabViewController) {
    //TODO: Open settings
  }

  func exchangeTabViewControllerDidPressedManageWallet(sender: KNExchangeTabViewController) {
    //TODO: Open manage wallet
  }

  func exchangeTabViewControllerDidPressedWallet(_ wallet: KNWalletObject, sender: KNExchangeTabViewController) {
    self.delegate?.exchangeTokenCoordinatorDidSelectWallet(wallet)
  }
}

// MARK: Search token
extension KNExchangeTokenCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewControllerDidCancel() {
    self.navigationController.popViewController(animated: true)
  }

  func searchTokenViewControllerDidSelect(token: TokenObject) {
    self.navigationController.popViewController(animated: true) {
      self.rootViewController.coordinatorUpdateSelectedToken(
        token,
        isSource: self.isSelectingSourceToken
      )
    }
  }
}

// MARK: Set gas price
extension KNExchangeTokenCoordinator: KNSetGasPriceViewControllerDelegate {
  func setGasPriceViewControllerDidReturn(gasPrice: BigInt?) {
    self.navigationController.popViewController(animated: true) {
      guard let gasPrice = gasPrice else { return }
      self.rootViewController.coordinatorExchangeTokenDidUpdateGasPrice(gasPrice)
    }
  }
}

// MARK: Set slippage rate
extension KNExchangeTokenCoordinator: KNSetSlippageRateViewControllerDelegate {
  func setSlippageRateViewControllerDidReturn(slippageRate: Double?) {
    self.navigationController.popViewController(animated: true) {
      guard let rate = slippageRate else { return }
      self.rootViewController.coordinatorExchangeTokenDidUpdateSlippageRate(rate)
    }
  }
}
