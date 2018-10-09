// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import SafariServices

enum IEOListViewEvent {
  case dismiss
  case buy(object: IEOObject)
}

protocol IEOListViewControllerDelegate: class {
  func ieoListViewController(_ controller: IEOListViewController, run event: IEOListViewEvent)
}

class IEOListViewController: KNBaseViewController {

  fileprivate var isViewSetup: Bool = false
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var pagingLabel: UILabel!

  weak var delegate: IEOListViewControllerDelegate?
  fileprivate var viewModel: IEOListViewModel
  fileprivate var controllers: [KGOIEODetailsViewController] = []

  init(viewModel: IEOListViewModel) {
    self.viewModel = viewModel
    super.init(nibName: IEOListViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
    }
  }

  fileprivate func setupUI() {
    self.titleLabel.text = self.viewModel.title
    let width: CGFloat = self.view.frame.width - 30.0
    let height: CGFloat = self.view.frame.height - self.scrollView.frame.minY
    self.scrollView.frame = CGRect(
      x: 0,
      y: self.scrollView.frame.minY,
      width: self.view.frame.width,
      height: height
    )
    self.scrollView.delegate = self
    var padding: CGFloat = 15.0
    self.controllers = []
    for object in self.viewModel.objects {
      let viewModel = KGOIEODetailsViewModel(object: object, isFull: false)
      let controller = KGOIEODetailsViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      self.controllers.append(controller)
      let frame = CGRect(x: padding, y: 0, width: width, height: height)
      controller.view.frame = frame
      self.addChildViewController(controller)
      controller.willMove(toParentViewController: self)
      self.scrollView.addSubview(controller.view)
      padding += width + 30.0
    }
    self.scrollView.contentSize = CGSize(
      width: self.scrollView.frame.width * CGFloat(self.viewModel.objects.count),
      height: 1.0
    )
    if let id = self.viewModel.objects.index(of: self.viewModel.curObject) {
      let rect = CGRect(
        x: CGFloat(id) * self.scrollView.frame.width,
        y: 0,
        width: self.scrollView.frame.width,
        height: height
      )
      self.scrollView.scrollRectToVisible(rect, animated: false)
      self.pagingLabel.text = "\(id + 1)/\(self.viewModel.objects.count)"
    }
    self.automaticallyAdjustsScrollViewInsets = false

    for object in self.viewModel.objects {
      let halted: Bool = self.viewModel.isHalted[object.contract] ?? false
      self.coordinatorDidUpdateIsHalted(halted, object: object)
    }
    self.coordinatorDidUpdateListKyberGoTx(IEOTransactionStorage.shared.objects)
  }

  func coordinatorDidUpdateProgress() {
    self.controllers.forEach { $0.coordinatorDidUpdateProgress() }
    self.view.layoutIfNeeded()
  }

  func coordinatorDidUpdateRate(_ rate: BigInt, object: IEOObject) {
    guard let controller = self.controllers.first(where: { $0.viewModel.object.id == object.id }) else { return }
    controller.coordinatorDidUpdateRate(rate, object: object)
  }

  func coordinatorDidUpdateIsHalted(_ halted: Bool, object: IEOObject) {
    for controller in self.controllers {
      controller.coordinatorDidUpdateIsHalted(halted, object: object)
    }
  }

  func coordinatorDidUpdateListKyberGoTx(_ transactions: [IEOTransaction]) {
    var amounts: [Int: Double] = [:]
    transactions.forEach { tran in
      if tran.txStatus == .success {
        amounts[tran.ieoID] = (amounts[tran.ieoID] ?? 0.0) + tran.distributedTokensWei
      }
    }
    for controller in self.controllers {
      var amount: Double = amounts[controller.viewModel.object.id] ?? 0.0
      amount /= pow(10.0, Double(controller.viewModel.object.tokenDecimals))
      controller.coordinatorDidUpdateBoughtAmount(amount)
    }
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.delegate?.ieoListViewController(self, run: .dismiss)
  }
}

extension IEOListViewController: KGOIEODetailsViewControllerDelegate {
  func ieoDetailsViewControllerDidPressBuy(for object: IEOObject, sender: KGOIEODetailsViewController) {
    self.delegate?.ieoListViewController(self, run: .buy(object: object))
  }

  func ieoDetailsViewControllerDidPressWhitePaper(for object: IEOObject, sender: KGOIEODetailsViewController) {
    let urlString: String = {
      for id in 0..<object.customInfoFields.count {
        if object.customInfoFields[id].lowercased() == "whitepaper" {
          return object.customInfoValues[id]
        }
      }
      return ""
    }()
    self.openSafari(with: urlString)
  }
}

extension IEOListViewController: UIScrollViewDelegate {
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    let offsetX = scrollView.contentOffset.x
    let id = Int(round(offsetX / self.scrollView.frame.width))
    self.pagingLabel.text = "\(id + 1)/\(self.viewModel.objects.count)"
  }
}