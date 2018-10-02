// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNEditWalletViewEvent {
  case back
  case update(newWallet: KNWalletObject)
  case backup(wallet: KNWalletObject)
  case delete(wallet: KNWalletObject)
}

protocol KNEditWalletViewControllerDelegate: class {
  func editWalletViewController(_ controller: KNEditWalletViewController, run event: KNEditWalletViewEvent)
}

struct KNEditWalletViewModel {
  let wallet: KNWalletObject

  init(wallet: KNWalletObject) {
    self.wallet = wallet
  }
}

class KNEditWalletViewController: KNBaseViewController {

  @IBOutlet weak var nameWalletTextLabel: UILabel!
  @IBOutlet weak var walletNameTextField: UITextField!

  @IBOutlet weak var showBackupPhraseButton: UIButton!
  @IBOutlet weak var deleteButton: UIButton!

  @IBOutlet weak var saveButton: UIButton!

  fileprivate let viewModel: KNEditWalletViewModel
  weak var delegate: KNEditWalletViewControllerDelegate?

  init(viewModel: KNEditWalletViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNEditWalletViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.nameWalletTextLabel.text = "Name of your wallet (optional)".toBeLocalised()
    self.walletNameTextField.placeholder = "Give your wallet a name".toBeLocalised()
    self.walletNameTextField.text = self.viewModel.wallet.name
    self.showBackupPhraseButton.setTitle("Show Backup Phrase".toBeLocalised(), for: .normal)
    self.deleteButton.setTitle("Delete Wallet".toBeLocalised(), for: .normal)
    self.saveButton.rounded(radius: 4.0)
    self.saveButton.setTitle("Save".toBeLocalised(), for: .normal)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.editWalletViewController(self, run: .back)
  }

  @IBAction func showBackUpPhraseButtonPressed(_ sender: Any) {
    self.delegate?.editWalletViewController(self, run: .backup(wallet: self.viewModel.wallet))
  }

  @IBAction func deleteButtonPressed(_ sender: Any) {
    self.delegate?.editWalletViewController(self, run: .delete(wallet: self.viewModel.wallet))
  }

  @IBAction func saveButtonPressed(_ sender: Any) {
    let wallet = self.viewModel.wallet.copy(withNewName: self.walletNameTextField.text ?? "")
    self.delegate?.editWalletViewController(self, run: .update(newWallet: wallet))
  }

  @IBAction func edgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.editWalletViewController(self, run: .back)
    }
  }
}