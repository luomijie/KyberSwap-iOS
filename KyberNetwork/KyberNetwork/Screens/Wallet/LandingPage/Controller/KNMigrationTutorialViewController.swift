// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import FSPagerView

class KNMigrationTutorialViewModel {
  var currentStep: Int = 1
  
  var step1DataSource: [String: NSMutableAttributedString] {
    let step1AttributeString = NSMutableAttributedString(string: "Go to Settings → Manage Wallet.", attributes: [
      .font: UIFont(name: "Roboto-Regular", size: 14.0)!,
      .foregroundColor: UIColor(red: 20.0 / 255.0, green: 25.0 / 255.0, blue: 39.0 / 255.0, alpha: 1.0),
      .kern: 0.0
    ])
    step1AttributeString.addAttribute(.font, value: UIFont(name: "Roboto-Medium", size: 14.0)!, range: NSRange(location: 15, length: 1))
    
    let step2AttributeString = NSMutableAttributedString(string: "Choose the wallet you want to back up → Select Edit ", attributes: [
      .font: UIFont(name: "Roboto-Regular", size: 14.0)!,
      .foregroundColor: UIColor(red: 20.0 / 255.0, green: 25.0 / 255.0, blue: 39.0 / 255.0, alpha: 1.0),
      .kern: 0.0
    ])
    step2AttributeString.addAttribute(.font, value: UIFont(name: "Roboto-Medium", size: 14.0)!, range: NSRange(location: 38, length: 1))
    
    let step3AttributeString = NSMutableAttributedString(string: "Select Show Backup Phrase → Choose your desired back up method (Private key, Keystore, Mnemonic)", attributes: [
      .font: UIFont(name: "Roboto-Regular", size: 14.0)!,
      .foregroundColor: UIColor(red: 20.0 / 255.0, green: 25.0 / 255.0, blue: 39.0 / 255.0, alpha: 1.0),
      .kern: 0.0
    ])
    step3AttributeString.addAttribute(.font, value: UIFont(name: "Roboto-Medium", size: 14.0)!, range: NSRange(location: 26, length: 1))
    
    let step4AttributeString = NSMutableAttributedString(string: "Save your backup safely\nNEVER share your backup with anyone", attributes: [
      .font: UIFont(name: "Roboto-Regular", size: 14.0)!,
      .foregroundColor: UIColor(red: 20.0 / 255.0, green: 25.0 / 255.0, blue: 39.0 / 255.0, alpha: 1.0),
      .kern: 0.0
    ])
    step4AttributeString.addAttribute(.font, value: UIFont(name: "Roboto-Medium", size: 14.0)!, range: NSRange(location: 24, length: 5))
    
    return [
      "tutorial_1_1": step1AttributeString,
      "tutorial_1_2": step2AttributeString,
      "tutorial_1_3": step3AttributeString,
      "tutorial_1_4": step4AttributeString,
    ]
  }
  
  var step1HeaderTitle: String {
    return "In your old KyberSwap app"
  }
  
  var step1ToolBarTitle: String {
    return "Backup your wallets"
  }
  
  var step2DataSource: [String: NSMutableAttributedString] {
    let step1AttributeString = NSMutableAttributedString(string: "Select Import Wallet", attributes: [
      .font: UIFont(name: "Roboto-Regular", size: 14.0)!,
      .foregroundColor: UIColor(red: 20.0 / 255.0, green: 25.0 / 255.0, blue: 39.0 / 255.0, alpha: 1.0),
      .kern: 0.0
    ])
    
    let step2AttributeString = NSMutableAttributedString(string: "Choose your desired import method (Keystore, Private Key, Seeds)", attributes: [
      .font: UIFont(name: "Roboto-Regular", size: 14.0)!,
      .foregroundColor: UIColor(red: 20.0 / 255.0, green: 25.0 / 255.0, blue: 39.0 / 255.0, alpha: 1.0),
      .kern: 0.0
    ])
    return [
      "tutorial_2_1": step1AttributeString,
      "tutorial_2_2": step2AttributeString,
    ]
  }
  
  var step2HeaderTitle: String {
    return "Within this New KyberSwap app"
  }
  
  var step2ToolBarTitle: String {
    return "Use your backup to import wallet "
  }
  
  
  var step3HeaderTitle: String {
    return "Within this New KyberSwap app"
  }
  
  var step3ToolBarTitle: String {
    return "Check your Balance"
  }
  
}

class KNMigrationTutorialViewController: KNBaseViewController {
  @IBOutlet weak var headerTitleLabel: UILabel!
  @IBOutlet weak var stepIndicatorLabel: UILabel!
  @IBOutlet weak var pageNameLabel: UILabel!
  @IBOutlet weak var pagerContainerView: FSPagerView! {
    didSet {
      self.pagerContainerView.register(UINib(nibName: "KNTutorialPagerCell", bundle: .main), forCellWithReuseIdentifier: "tutorialCell")
    }
  }
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var previousButton: UIButton!
  @IBOutlet weak var nextBottomButton: UIButton!
  
  
  var viewModel: KNMigrationTutorialViewModel

  init(viewModel: KNMigrationTutorialViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNMigrationTutorialViewController.className, bundle: nil)
    self.modalPresentationStyle = .overFullScreen
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.stepIndicatorLabel.rounded(radius: self.stepIndicatorLabel.frame.size.height / 2)
  }
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.pagerContainerView.itemSize = self.pagerContainerView.frame.size.applying(CGAffineTransform(scaleX: 0.85, y: 1.0))
    self.pagerContainerView.interitemSpacing = 15
  }

  @IBAction func closeButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func previousStepButtonTapped(_ sender: UIButton) {
    guard self.viewModel.currentStep > 1 else {
      return
    }
    self.viewModel.currentStep -= 1
    self.nextButton.isEnabled = true
    if self.viewModel.currentStep == 1 {
      self.previousButton.isEnabled = false
    }
    self.refreshUI()
    self.pagerContainerView.reloadData()
  }
  
  @IBAction func nextStepButtonTapped(_ sender: UIButton) {
    guard self.viewModel.currentStep < 3 else {
      return
    }
    self.viewModel.currentStep += 1
    self.previousButton.isEnabled = true
    if self.viewModel.currentStep == 3 {
      self.nextButton.isEnabled = false
    }
    self.refreshUI()
    self.pagerContainerView.reloadData()
  }
  
  @IBAction func nextButtonTapped(_ sender: UIButton) {
    guard self.viewModel.currentStep < 3 else {
      return
    }
  }
  
  fileprivate func refreshUI() {
    switch self.viewModel.currentStep {
    case 1:
      self.stepIndicatorLabel.text = "1"
      self.pageNameLabel.text = self.viewModel.step1ToolBarTitle
    case 2:
      self.stepIndicatorLabel.text = "2"
      self.pageNameLabel.text = self.viewModel.step2ToolBarTitle
    default:
      break
    }
  }
}

extension KNMigrationTutorialViewController: FSPagerViewDataSource {
  public func numberOfItems(in pagerView: FSPagerView) -> Int {
    switch self.viewModel.currentStep {
    case 1:
      return self.viewModel.step1DataSource.keys.count
    case 2:
      return self.viewModel.step2DataSource.keys.count
    default:
      return 0
    }
  }

  public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
    let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "tutorialCell", at: index) as! KNTutorialPagerCell
    let step = self.viewModel.currentStep
    let imageName = "tutorial_\(step)_\(index + 1)"
    cell.contentImageView.image = UIImage(named: imageName)
    switch self.viewModel.currentStep {
    case 1:
      cell.headerTitleLabel.text = self.viewModel.step1HeaderTitle
      if let text = self.viewModel.step1DataSource[imageName] {
        cell.contentLabel.attributedText = text
      } else {
        cell.contentLabel.attributedText = NSAttributedString()
      }
    case 2:
      cell.headerTitleLabel.text = self.viewModel.step2HeaderTitle
      if let text = self.viewModel.step2DataSource[imageName] {
        cell.contentLabel.attributedText = text
      } else {
        cell.contentLabel.attributedText = NSAttributedString()
      }
    default:
      break
    }
    return cell
  }
}
