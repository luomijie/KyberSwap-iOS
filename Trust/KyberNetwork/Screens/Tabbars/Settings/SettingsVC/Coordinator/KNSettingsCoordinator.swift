// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNSettingsCoordinatorDelegate: class {
  func settingsCoordinatorUserDidSelectNewWallet(_ wallet: Wallet)
  func settingsCoordinatorUserDidSelectExit()
  func settingsCoordinatorUserDidRemoveWallet(_ wallet: Wallet)
  func settingsCoordinatorUserDidUpdateWalletObjects()
}

class KNSettingsCoordinator: Coordinator {

  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  private(set) var session: KNSession

  weak var delegate: KNSettingsCoordinatorDelegate?

  lazy var rootViewController: KNSettingsViewController = {
    let controller = KNSettingsViewController(
      address: self.session.wallet.address.description
    )
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var listWalletsCoordinator: KNListWalletsCoordinator = {
    return KNListWalletsCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      delegate: self
    )
  }()

  lazy var passcodeCoordinator: KNPasscodeCoordinator = {
    let coordinator = KNPasscodeCoordinator(
      navigationController: self.navigationController,
      type: .setPasscode
    )
    coordinator.delegate = self
    return coordinator
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.applyStyle()
    self.session = session
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() {
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    if resetRoot {
      self.navigationController.popToRootViewController(animated: false)
    }
    self.listWalletsCoordinator.updateNewSession(self.session)
    self.rootViewController.userDidSelectNewWallet(with: self.session.wallet.address.description)
  }
}

extension KNSettingsCoordinator: KNSettingsViewControllerDelegate {
  func settingsViewController(_ controller: KNSettingsViewController, run event: KNSettingsViewEvent) {
    switch event {
    case .exit:
      self.settingsViewControllerDidClickExit()
    case .clickWallets:
      self.settingsViewControllerWalletsButtonPressed()
    case .passcodeDidChange(let isOn):
      self.settingsViewControllerPasscodeDidChange(isOn)
    case .backUp:
      self.settingsViewControllerBackUpButtonPressed()
    case .close:
      self.navigationController.dismiss(animated: true, completion: nil)
    }
  }

  func settingsViewControllerDidClickExit() {
    self.delegate?.settingsCoordinatorUserDidSelectExit()
  }

  func settingsViewControllerWalletsButtonPressed() {
    self.listWalletsCoordinator.start()
  }

  func settingsViewControllerPasscodeDidChange(_ isOn: Bool) {
    if isOn {
      self.passcodeCoordinator.start()
    } else {
      KNPasscodeUtil.shared.deletePasscode()
    }
  }

  func settingsViewControllerBackUpButtonPressed() {
    let alertController = UIAlertController(title: "Backup", message: nil, preferredStyle: .actionSheet)
    alertController.addAction(UIAlertAction(title: "Backup Keystore", style: .default, handler: { _ in
      self.backupKeystore()
    }))
    alertController.addAction(UIAlertAction(title: "Backup Private Key", style: .default, handler: { _ in
      self.backupPrivateKey()
    }))
    alertController.addAction(UIAlertAction(title: "Copy Address", style: .default, handler: { _ in
      self.copyAddress()
    }))
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    self.navigationController.topViewController?.present(alertController, animated: true, completion: nil)
  }

  fileprivate func backupKeystore() {
    let createPassword = KNCreatePasswordViewController(delegate: self)
    createPassword.modalPresentationStyle = .overCurrentContext
    createPassword.modalTransitionStyle = .crossDissolve
    self.navigationController.topViewController?.present(createPassword, animated: true, completion: nil)
  }

  fileprivate func backupPrivateKey() {
    if case .real(let account) = self.session.wallet.type {
      let result = self.session.keystore.exportPrivateKey(account: account)
      switch result {
      case .success(let data):
        self.exportDataString(data.hexString)
      case .failure(let error):
        self.navigationController.topViewController?.displayError(error: error)
      }
    }
  }

  fileprivate func copyAddress() {
    UIPasteboard.general.string = self.session.wallet.address.description
  }

  fileprivate func exportDataString(_ value: String) {
    let dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd_HH:mm"
      return formatter
    }()
    let fileName = "kyber_network_backup\(self.session.wallet.address.description)_\(dateFormatter.string(from: Date())).json"
    let url = URL(fileURLWithPath: NSTemporaryDirectory().appending(fileName))
    do {
      try value.data(using: .utf8)!.write(to: url)
    } catch { return }

    let activityViewController = UIActivityViewController(
      activityItems: [url],
      applicationActivities: nil
    )
    activityViewController.completionWithItemsHandler = { _, result, _, error in
      do { try FileManager.default.removeItem(at: url)
      } catch { }
    }
    activityViewController.popoverPresentationController?.sourceView = navigationController.view
    activityViewController.popoverPresentationController?.sourceRect = navigationController.view.centerRect
    self.navigationController.topViewController?.present(activityViewController, animated: true, completion: nil)
  }
}

extension KNSettingsCoordinator: KNCreatePasswordViewControllerDelegate {
  func createPasswordUserDidFinish(_ password: String) {
    if case .real(let account) = self.session.wallet.type {
      if let currentPassword = self.session.keystore.getPassword(for: account) {
        self.navigationController.topViewController?.displayLoading(text: "Preparing data...", animated: true)
        self.session.keystore.export(account: account, password: currentPassword, newPassword: password, completion: { [weak self] result in
          self?.navigationController.topViewController?.hideLoading()
          switch result {
          case .success(let value):
            self?.exportDataString(value)
          case .failure(let error):
            self?.navigationController.topViewController?.displayError(error: error)
          }
        })
      }
    }
  }
}

extension KNSettingsCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCreatePasscode() {
  }

  func passcodeCoordinatorDidCancel() {
    self.rootViewController.userDidCancelCreatePasscode()
  }
}

extension KNSettingsCoordinator: KNListWalletsCoordinatorDelegate {
  func listWalletsCoordinatorDidClickBack() {
    self.listWalletsCoordinator.stop()
  }

  func listWalletsCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.listWalletsCoordinator.stop()
    if wallet == self.session.wallet { return }
    self.rootViewController.userDidSelectNewWallet(with: wallet.address.description)
    self.delegate?.settingsCoordinatorUserDidSelectNewWallet(wallet)
  }

  func listWalletsCoordinatorDidSelectRemoveWallet(_ wallet: Wallet) {
    self.delegate?.settingsCoordinatorUserDidRemoveWallet(wallet)
  }

  func listWalletsCoordinatorDidUpdateWalletObjects() {
    self.delegate?.settingsCoordinatorUserDidUpdateWalletObjects()
  }
}